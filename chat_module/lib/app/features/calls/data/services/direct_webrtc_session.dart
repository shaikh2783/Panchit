import 'dart:async';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../chat/data/services/chat_service.dart';
import '../models/chat_call_models.dart';

typedef DirectWebRtcLog = void Function(String message);
typedef DirectWebRtcTrackHandler = void Function(RTCTrackEvent event);
typedef DirectWebRtcFallbackHandler = Future<void> Function(String reason);
typedef DirectWebRtcIceRefresh = Future<List<Map<String, dynamic>>> Function();

/// Owns one standard WebRTC peer connection for a two-person call.
///
/// The API server transports only SDP/ICE messages. Audio and video use the
/// selected ICE candidate pair directly, with TURN acting as a packet relay
/// only when a direct candidate pair cannot be established.
class DirectWebRtcSession {
  static const Duration _initialConnectionTimeout = Duration(seconds: 12);
  static const int _maxInitialPollFailures = 3;

  DirectWebRtcSession({
    required ChatService chatService,
    required this.callId,
    required this.peerUserId,
    required this.isOfferer,
    required this.localStream,
    required List<Map<String, dynamic>> iceServers,
    required this.onTrack,
    required this.onFallbackRequested,
    required this.log,
    this.refreshIceServers,
  }) : _chatService = chatService,
       _iceServers = List<Map<String, dynamic>>.from(iceServers);

  final ChatService _chatService;
  final int callId;
  final int peerUserId;
  final bool isOfferer;
  final MediaStream localStream;
  final DirectWebRtcTrackHandler onTrack;
  final DirectWebRtcFallbackHandler onFallbackRequested;
  final DirectWebRtcLog log;
  final DirectWebRtcIceRefresh? refreshIceServers;

  List<Map<String, dynamic>> _iceServers;
  RTCPeerConnection? _peer;
  Future<void>? _pollFuture;
  Future<void> _signalSendTail = Future<void>.value();
  Timer? _candidateFlushTimer;
  Timer? _statsTimer;
  Timer? _recoveryTimer;
  final Completer<void> _connectedCompleter = Completer<void>();
  final List<_PendingDirectCandidate> _pendingRemoteCandidates =
      <_PendingDirectCandidate>[];
  final List<Map<String, dynamic>> _pendingLocalCandidates =
      <Map<String, dynamic>>[];
  final Random _secureRandom = Random.secure();

  int _afterSignalId = 0;
  int _lastAckedSignalId = 0;
  int _ackTargetSignalId = 0;
  int _generation = 1;
  int _restartAttempts = 0;
  int _pollFailures = 0;
  bool _closed = false;
  bool _connected = false;
  bool _remoteDescriptionReady = false;
  bool _localDescriptionSignaled = false;
  bool _iceCompletePending = false;
  bool _remoteFallbackReceived = false;
  bool _handlingOffer = false;
  bool _ackInFlight = false;
  bool _recoveryInFlight = false;
  String _terminationReason = '';

  bool get isConnected => _connected && !_closed;

  Future<void> connect({Duration timeout = _initialConnectionTimeout}) async {
    try {
      await _connectOnce().timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('Direct WebRTC negotiation timed out', timeout);
    }
  }

  Future<void> _connectOnce() async {
    if (_peer != null) {
      throw StateError('Direct WebRTC session is already started');
    }
    if (callId <= 0 || peerUserId <= 0) {
      throw ArgumentError('Direct WebRTC identifiers are incomplete');
    }

    final peer = await createPeerConnection(_peerConfiguration());
    if (_closed) {
      try {
        await peer.close();
      } catch (_) {}
      try {
        await peer.dispose();
      } catch (_) {}
      throw const DirectWebRtcFallbackException('session_closed');
    }
    _peer = peer;
    _attachPeerCallbacks(peer);
    for (final track in localStream.getTracks()) {
      final sender = await peer.addTrack(track, localStream);
      await _configureSender(sender);
    }

    _pollFuture = _pollSignals();
    if (isOfferer) {
      await _sendOffer(iceRestart: false);
    }

    await _connectedCompleter.future;
    if (_closed || _remoteFallbackReceived || !_connected) {
      throw DirectWebRtcFallbackException(
        _terminationReason.isNotEmpty ? _terminationReason : 'session_closed',
      );
    }
  }

  Future<void> announceFallback(String reason) async {
    if (_closed || _remoteFallbackReceived) return;
    try {
      // Bypass the ordered SDP/ICE queue: fallback must still reach the peer
      // if a previous signaling request is stalled.
      await _chatService
          .sendWebRtcCallSignal(
            callId: callId,
            toUserId: peerUserId,
            clientSignalId: _uuidV4(),
            generation: _generation,
            type: 'fallback',
            payload: <String, dynamic>{'reason': reason},
          )
          .timeout(const Duration(seconds: 2));
    } catch (error) {
      log('direct fallback signal failed: $error');
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _terminationReason = 'session_closed';
    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }
    _candidateFlushTimer?.cancel();
    _statsTimer?.cancel();
    _recoveryTimer?.cancel();
    _pendingLocalCandidates.clear();
    _pendingRemoteCandidates.clear();
    final peer = _peer;
    _peer = null;
    try {
      await peer?.close();
    } catch (_) {}
    try {
      await peer?.dispose();
    } catch (_) {}
    try {
      await _pollFuture?.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Map<String, dynamic> _peerConfiguration() => <String, dynamic>{
    'iceServers': _iceServers,
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'sdpSemantics': 'unified-plan',
  };

  void _attachPeerCallbacks(RTCPeerConnection peer) {
    peer.onTrack = onTrack;
    peer.onIceCandidate = (candidate) {
      final candidateText = candidate.candidate?.trim() ?? '';
      if (_closed || candidateText.isEmpty) return;
      _pendingLocalCandidates.add(<String, dynamic>{
        'candidate': candidateText,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
      _scheduleCandidateFlush();
    };
    peer.onIceGatheringState = (state) {
      log('direct ICE gathering state=$state generation=$_generation');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        _iceCompletePending = true;
        unawaited(_flushLocalCandidates());
        unawaited(_sendIceCompleteIfReady());
      }
    };
    peer.onIceConnectionState = (state) {
      log('direct ICE connection state=$state generation=$_generation');
    };
    peer.onConnectionState = (state) {
      log('direct peer connection state=$state generation=$_generation');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _markConnected();
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _scheduleRecovery(const Duration(seconds: 4));
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _scheduleRecovery(const Duration(milliseconds: 250));
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          break;
      }
    };
  }

  void _markConnected() {
    if (_closed || _remoteFallbackReceived) return;
    _connected = true;
    _restartAttempts = 0;
    _recoveryTimer?.cancel();
    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }
    _startStatsMonitoring();
  }

  void _scheduleRecovery(Duration delay) {
    if (_closed || _remoteFallbackReceived) return;
    _connected = false;
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(delay, () {
      unawaited(_recoverConnection());
    });
  }

  Future<void> _recoverConnection() async {
    if (_closed || _remoteFallbackReceived || _recoveryInFlight) return;
    _recoveryInFlight = true;
    try {
      final peer = _peer;
      if (peer == null) return;
      var state = await peer.getConnectionState();
      if (_closed || _remoteFallbackReceived || _peer != peer) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _markConnected();
        return;
      }

      _restartAttempts += 1;
      if (_restartAttempts > 2) {
        log('direct ICE recovery exhausted; requesting SFU fallback');
        try {
          await announceFallback(
            'ice_recovery_exhausted',
          ).timeout(const Duration(seconds: 2));
        } catch (_) {}
        await _handleRemoteFallback('ice_recovery_exhausted');
        return;
      }

      if (!isOfferer) {
        _scheduleRecovery(const Duration(seconds: 7));
        return;
      }

      final refreshed = await refreshIceServers?.call().timeout(
        const Duration(seconds: 3),
      );
      if (_closed || _remoteFallbackReceived || _peer != peer) return;
      state = await peer.getConnectionState();
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _markConnected();
        return;
      }
      if (refreshed != null && refreshed.isNotEmpty) {
        _iceServers = refreshed;
        await peer.setConfiguration(_peerConfiguration());
      }
      if (_closed || _remoteFallbackReceived || _peer != peer) return;
      _candidateFlushTimer?.cancel();
      _pendingLocalCandidates.clear();
      _iceCompletePending = false;
      _generation += 1;
      _remoteDescriptionReady = false;
      _localDescriptionSignaled = false;
      await peer.restartIce();
      await _sendOffer(iceRestart: true);
      _scheduleRecovery(const Duration(seconds: 10));
    } catch (error) {
      log('direct ICE restart attempt=$_restartAttempts failed: $error');
      _scheduleRecovery(const Duration(seconds: 3));
    } finally {
      _recoveryInFlight = false;
    }
  }

  Future<void> _sendOffer({required bool iceRestart}) async {
    final peer = _peer;
    if (peer == null || _closed) return;
    _localDescriptionSignaled = false;
    final offer = await peer.createOffer(<String, dynamic>{
      if (iceRestart) 'iceRestart': true,
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': localStream.getVideoTracks().isNotEmpty,
    });
    final tuned = RTCSessionDescription(
      _tuneOpusSdp(offer.sdp ?? ''),
      offer.type,
    );
    await peer.setLocalDescription(tuned);
    await _sendSignal(
      type: 'offer',
      payload: <String, dynamic>{
        'sdp': <String, dynamic>{'type': tuned.type, 'sdp': tuned.sdp},
        'ice_restart': iceRestart,
      },
    );
    _localDescriptionSignaled = true;
    await _flushLocalCandidates();
    await _sendIceCompleteIfReady();
  }

  Future<void> _pollSignals() async {
    while (!_closed) {
      try {
        final result = await _chatService
            .fetchWebRtcCallSignals(callId: callId, afterId: _afterSignalId)
            .timeout(const Duration(seconds: 5));
        _pollFailures = 0;
        for (final signal in result.items) {
          if (_closed) return;
          if (signal.signalId <= _afterSignalId ||
              signal.fromUserId != peerUserId) {
            continue;
          }
          try {
            await _handleSignal(signal);
          } catch (error) {
            // Replaying a stored SDP/protocol message rejected by the native
            // WebRTC stack only blocks all later ICE/fallback signals.
            log(
              'direct signaling message dropped id=${signal.signalId} '
              'type=${signal.type} error=$error',
            );
          } finally {
            if (signal.signalId > _afterSignalId) {
              _afterSignalId = signal.signalId;
            }
          }
        }
        if (result.nextAfterId > _afterSignalId) {
          _afterSignalId = result.nextAfterId;
        }
        _queueSignalAck(_afterSignalId);
      } catch (error) {
        _pollFailures += 1;
        if (_pollFailures <= 3 || _pollFailures % 10 == 0) {
          log('direct signaling poll failed count=$_pollFailures: $error');
        }
        // SDP/ICE cannot make progress while the signaling endpoint is down.
        // Fail over promptly instead of leaving the call on "Connecting" for
        // the full ICE timeout (server-side 4xx/5xx failures return quickly).
        if (!_connected && _pollFailures >= _maxInitialPollFailures) {
          _terminationReason = 'signaling_unavailable';
          log(
            'direct signaling unavailable after $_pollFailures failures; '
            'requesting SFU fallback',
          );
          if (!_connectedCompleter.isCompleted) {
            _connectedCompleter.complete();
          }
          return;
        }
      }
      await Future<void>.delayed(
        _connected
            ? const Duration(seconds: 2)
            : const Duration(milliseconds: 300),
      );
    }
  }

  void _queueSignalAck(int throughSignalId) {
    if (_closed || throughSignalId <= _lastAckedSignalId) return;
    if (throughSignalId > _ackTargetSignalId) {
      _ackTargetSignalId = throughSignalId;
    }
    if (_ackInFlight) return;
    _ackInFlight = true;
    unawaited(_flushSignalAcks());
  }

  Future<void> _flushSignalAcks() async {
    try {
      while (!_closed && _ackTargetSignalId > _lastAckedSignalId) {
        final target = _ackTargetSignalId;
        try {
          await _chatService
              .acknowledgeWebRtcCallSignals(
                callId: callId,
                throughSignalId: target,
              )
              .timeout(const Duration(seconds: 5));
          _lastAckedSignalId = target;
        } catch (error) {
          log('direct signaling ack failed: $error');
          return;
        }
      }
    } finally {
      _ackInFlight = false;
    }
  }

  Future<void> _handleSignal(ChatWebRtcSignalModel signal) async {
    if (signal.generation > 0 && signal.generation < _generation) return;
    switch (signal.type) {
      case 'offer':
        await _handleOffer(signal);
      case 'answer':
        await _handleAnswer(signal);
      case 'ice':
        await _handleRemoteIce(signal);
      case 'ice_complete':
        break;
      case 'fallback':
        await _handleRemoteFallback(
          signal.payload['reason']?.toString() ?? 'remote_requested',
        );
      case 'bye':
        break;
    }
  }

  Future<void> _handleOffer(ChatWebRtcSignalModel signal) async {
    if (_closed || isOfferer || _handlingOffer) return;
    final peer = _peer;
    if (peer == null) return;
    final description = _descriptionFromPayload(signal.payload['sdp']);
    if ((description.sdp ?? '').isEmpty) return;

    _handlingOffer = true;
    try {
      if (signal.generation > _generation) {
        _candidateFlushTimer?.cancel();
        _pendingLocalCandidates.clear();
        _iceCompletePending = false;
        _generation = signal.generation;
      }
      _localDescriptionSignaled = false;
      await peer.setRemoteDescription(description);
      _remoteDescriptionReady = true;
      await _drainRemoteCandidates();
      final answer = await peer.createAnswer();
      final tuned = RTCSessionDescription(
        _tuneOpusSdp(answer.sdp ?? ''),
        answer.type,
      );
      await peer.setLocalDescription(tuned);
      await _sendSignal(
        type: 'answer',
        payload: <String, dynamic>{
          'sdp': <String, dynamic>{'type': tuned.type, 'sdp': tuned.sdp},
        },
      );
      _localDescriptionSignaled = true;
      await _flushLocalCandidates();
      await _sendIceCompleteIfReady();
    } finally {
      _handlingOffer = false;
    }
  }

  Future<void> _handleAnswer(ChatWebRtcSignalModel signal) async {
    if (_closed || !isOfferer) return;
    final peer = _peer;
    if (peer == null) return;
    if (signal.generation != 0 && signal.generation != _generation) return;
    final description = _descriptionFromPayload(signal.payload['sdp']);
    if ((description.sdp ?? '').isEmpty) return;
    final signalingState = await peer.getSignalingState();
    if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      return;
    }
    await peer.setRemoteDescription(description);
    _remoteDescriptionReady = true;
    await _drainRemoteCandidates();
  }

  Future<void> _handleRemoteIce(ChatWebRtcSignalModel signal) async {
    final rawCandidates = signal.payload['candidates'];
    final candidates = rawCandidates is List
        ? rawCandidates
        : <dynamic>[signal.payload['candidate'] ?? signal.payload];
    for (final raw in candidates) {
      if (raw is! Map) continue;
      final candidate = Map<String, dynamic>.from(raw);
      if (!_remoteDescriptionReady) {
        _pendingRemoteCandidates.add(
          _PendingDirectCandidate(signal.generation, candidate),
        );
        continue;
      }
      await _addRemoteCandidate(candidate);
    }
  }

  Future<void> _drainRemoteCandidates() async {
    final candidates = List<_PendingDirectCandidate>.from(
      _pendingRemoteCandidates,
    );
    _pendingRemoteCandidates.clear();
    for (final pending in candidates) {
      if (pending.generation != 0 && pending.generation != _generation) {
        continue;
      }
      await _addRemoteCandidate(pending.candidate);
    }
  }

  Future<void> _addRemoteCandidate(Map<String, dynamic> raw) async {
    final peer = _peer;
    if (peer == null || _closed) return;
    final candidate = raw['candidate']?.toString().trim() ?? '';
    if (candidate.isEmpty || !candidate.contains('candidate:')) return;
    final sdpMid = raw['sdpMid']?.toString();
    final rawIndex = raw['sdpMLineIndex'];
    final sdpMLineIndex = rawIndex is int
        ? rawIndex
        : int.tryParse(rawIndex?.toString() ?? '') ?? 0;
    try {
      await peer.addCandidate(
        RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
      );
    } catch (error) {
      log('direct remote ICE candidate rejected: $error');
    }
  }

  void _scheduleCandidateFlush() {
    if (_closed) return;
    _candidateFlushTimer?.cancel();
    _candidateFlushTimer = Timer(const Duration(milliseconds: 120), () {
      unawaited(_flushLocalCandidates());
    });
  }

  Future<void> _flushLocalCandidates() async {
    if (_closed || !_localDescriptionSignaled) return;
    while (_pendingLocalCandidates.isNotEmpty && !_closed) {
      final count = min(10, _pendingLocalCandidates.length);
      final batch = _pendingLocalCandidates.sublist(0, count);
      _pendingLocalCandidates.removeRange(0, count);
      try {
        await _sendSignal(
          type: 'ice',
          payload: <String, dynamic>{'candidates': batch},
        );
      } catch (error) {
        _pendingLocalCandidates.insertAll(0, batch);
        log('direct local ICE batch send failed: $error');
        _scheduleCandidateFlush();
        return;
      }
    }
  }

  Future<void> _sendIceCompleteIfReady() async {
    if (_closed || !_localDescriptionSignaled || !_iceCompletePending) return;
    _iceCompletePending = false;
    try {
      await _sendSignal(
        type: 'ice_complete',
        payload: const <String, dynamic>{},
      );
    } catch (error) {
      _iceCompletePending = true;
      log('direct ICE-complete signal failed: $error');
    }
  }

  Future<void> _sendSignal({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    final completer = Completer<void>();
    _signalSendTail = _signalSendTail.catchError((_) {}).then((_) async {
      if (_closed) {
        completer.complete();
        return;
      }
      try {
        await _chatService
            .sendWebRtcCallSignal(
              callId: callId,
              toUserId: peerUserId,
              clientSignalId: _uuidV4(),
              generation: _generation,
              type: type,
              payload: payload,
            )
            .timeout(const Duration(seconds: 5));
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  RTCSessionDescription _descriptionFromPayload(dynamic raw) {
    if (raw is Map) {
      return RTCSessionDescription(
        raw['sdp']?.toString() ?? '',
        raw['type']?.toString() ?? 'offer',
      );
    }
    return RTCSessionDescription('', 'offer');
  }

  Future<void> _handleRemoteFallback(String reason) async {
    if (_closed || _remoteFallbackReceived) return;
    _remoteFallbackReceived = true;
    _terminationReason = reason;
    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }
    unawaited(
      onFallbackRequested(reason).catchError((Object error) {
        log('direct SFU fallback callback failed: $error');
      }),
    );
  }

  Future<void> _configureSender(RTCRtpSender sender) async {
    final kind = sender.track?.kind;
    if (kind != 'audio' && kind != 'video') return;
    try {
      final parameters = sender.parameters;
      final encodings = parameters.encodings;
      if (encodings == null || encodings.isEmpty) return;
      for (final encoding in encodings) {
        if (kind == 'audio') {
          encoding.maxBitrate = 64000;
          encoding.priority = RTCPriorityType.high;
          encoding.networkPriority = RTCPriorityType.high;
        } else {
          encoding.maxBitrate = 1200000;
          encoding.maxFramerate = 24;
          encoding.priority = RTCPriorityType.medium;
          encoding.networkPriority = RTCPriorityType.medium;
        }
      }
      if (kind == 'video') {
        parameters.degradationPreference = RTCDegradationPreference.BALANCED;
      }
      await sender.setParameters(parameters);
    } catch (error) {
      log('direct $kind sender tuning unavailable: $error');
    }
  }

  String _tuneOpusSdp(String sdp) {
    if (sdp.isEmpty) return sdp;
    final opus = RegExp(
      r'^a=rtpmap:(\d+) opus/48000(?:/2)?[ \t]*\r?$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(sdp);
    final payloadType = opus?.group(1);
    if (payloadType == null) return sdp;
    const options = <String>[
      'useinbandfec=1',
      'usedtx=1',
      'stereo=0',
      'sprop-stereo=0',
      'maxaveragebitrate=64000',
    ];
    final fmtpPattern = RegExp(
      '^a=fmtp:$payloadType ([^\\r\\n]*)',
      caseSensitive: false,
      multiLine: true,
    );
    final fmtp = fmtpPattern.firstMatch(sdp);
    if (fmtp == null) {
      final rtpLine = opus!.group(0)!;
      return sdp.replaceFirst(
        rtpLine,
        '$rtpLine\r\na=fmtp:$payloadType ${options.join(';')}',
      );
    }
    var parameters = fmtp.group(1) ?? '';
    for (final option in options) {
      final key = option.split('=').first;
      final pattern = RegExp(
        '(^|;)${RegExp.escape(key)}=[^;]*',
        caseSensitive: false,
      );
      if (pattern.hasMatch(parameters)) {
        parameters = parameters.replaceAllMapped(
          pattern,
          (match) => '${match.group(1) ?? ''}$option',
        );
      } else {
        parameters = parameters.trim().isEmpty ? option : '$parameters;$option';
      }
    }
    return sdp.replaceFirst(fmtp.group(0)!, 'a=fmtp:$payloadType $parameters');
  }

  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_logQualityStats());
    });
    unawaited(_logQualityStats());
  }

  Future<void> _logQualityStats() async {
    final peer = _peer;
    if (peer == null || _closed) return;
    try {
      final reports = await peer.getStats();
      Map<dynamic, dynamic>? inboundAudio;
      Map<dynamic, dynamic>? selectedPair;
      final reportsById = <String, Map<dynamic, dynamic>>{};
      for (final report in reports) {
        final values = report.values;
        reportsById[report.id] = values;
        final kind = (values['kind'] ?? values['mediaType'])
            ?.toString()
            .toLowerCase();
        if (report.type == 'inbound-rtp' && kind == 'audio') {
          inboundAudio = values;
        }
        if (report.type == 'candidate-pair' &&
            (values['selected'] == true || values['nominated'] == true) &&
            values['state']?.toString() == 'succeeded') {
          selectedPair = values;
        }
      }
      if (inboundAudio == null && selectedPair == null) return;
      final localCandidate =
          reportsById[selectedPair?['localCandidateId']?.toString() ?? ''];
      final remoteCandidate =
          reportsById[selectedPair?['remoteCandidateId']?.toString() ?? ''];
      log(
        'direct quality '
        'lost=${_stat(inboundAudio, 'packetsLost')} '
        'jitter=${_stat(inboundAudio, 'jitter')} '
        'concealed=${_stat(inboundAudio, 'concealedSamples')} '
        'jitterBufferDelay=${_stat(inboundAudio, 'jitterBufferDelay')} '
        'rtt=${_stat(selectedPair, 'currentRoundTripTime')} '
        'outBps=${_stat(selectedPair, 'availableOutgoingBitrate')} '
        'route=${_stat(localCandidate, 'candidateType')}/'
        '${_stat(localCandidate, 'protocol')}->'
        '${_stat(remoteCandidate, 'candidateType')}/'
        '${_stat(remoteCandidate, 'protocol')}',
      );
    } catch (error) {
      log('direct quality stats unavailable: $error');
    }
  }

  String _stat(Map<dynamic, dynamic>? values, String key) {
    final value = values?[key];
    return value?.toString() ?? '-';
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

class DirectWebRtcFallbackException implements Exception {
  const DirectWebRtcFallbackException(this.reason);

  final String reason;

  @override
  String toString() => 'Direct WebRTC fallback requested: $reason';
}

class _PendingDirectCandidate {
  const _PendingDirectCandidate(this.generation, this.candidate);

  final int generation;
  final Map<String, dynamic> candidate;
}
