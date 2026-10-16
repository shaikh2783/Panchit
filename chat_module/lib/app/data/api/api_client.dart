import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../api_config.dart';
import '../../../settings.dart';
import '../../core/controllers/locale_controller.dart';
import '../../core/storage/app_preferences.dart';
import 'api_exception.dart';

class ChatModuleApiClient {
  ChatModuleApiClient(this._preferences, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final ChatAppPreferences _preferences;
  final http.Client _httpClient;

  /// Endpoint values resolved via [LicenseRuntime.endpoint] are not always
  /// relative paths -- some licensed deployments issue them as full
  /// absolute URLs. Treat `path` as absolute when it already is one instead
  /// of blindly prepending [ApiConfig.baseUrl], which would otherwise
  /// produce a malformed concatenated URL.
  Uri _resolveUri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    String? authTokenOverride,
  }) async {
    final uri = _resolveUri(path);
    final headers = _buildHeaders(
      authenticated: authenticated,
      authTokenOverride: authTokenOverride,
      includeJsonContentType: true,
    );
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});

    _logRequest(method: 'POST', uri: uri, headers: headers, body: encodedBody);

    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: encodedBody,
    );

    return _handleResponse(response, requestUri: uri);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    String? authTokenOverride,
  }) async {
    final uri = _resolveUri(path).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    final headers = _buildHeaders(
      authenticated: authenticated,
      authTokenOverride: authTokenOverride,
      includeJsonContentType: true,
    );

    _logRequest(method: 'GET', uri: uri, headers: headers);

    final response = await _httpClient.get(uri, headers: headers);

    return _handleResponse(response, requestUri: uri);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    String? authTokenOverride,
  }) async {
    final uri = _resolveUri(path).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    final headers = _buildHeaders(
      authenticated: authenticated,
      authTokenOverride: authTokenOverride,
      includeJsonContentType: true,
    );

    _logRequest(method: 'DELETE', uri: uri, headers: headers);

    final response = await _httpClient.delete(uri, headers: headers);

    return _handleResponse(response, requestUri: uri);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List fileBytes,
    required String filename,
    String fileField = 'file',
    Map<String, String>? fields,
    bool authenticated = false,
    String? authTokenOverride,
  }) async {
    final uri = _resolveUri(path);
    final headers = _buildHeaders(
      authenticated: authenticated,
      authTokenOverride: authTokenOverride,
      includeJsonContentType: false,
    );

    _logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body:
          'multipart/form-data {fileField: $fileField, filename: $filename, fields: ${fields ?? const <String, String>{}}}',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields ?? const <String, String>{})
      ..files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, requestUri: uri);
  }

  Map<String, String> _buildHeaders({
    required bool authenticated,
    String? authTokenOverride,
    required bool includeJsonContentType,
  }) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final signature = Hmac(
      sha256,
      utf8.encode(ApiConfig.secretKey),
    ).convert(utf8.encode(timestamp)).toString();

    final headers = <String, String>{
      'x-api-key': ApiConfig.apiKey,
      'x-timestamp': timestamp,
      'x-signature': signature,
      'x-lang': _resolveApiLanguage(),
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      final authToken = authTokenOverride?.trim().isNotEmpty == true
          ? authTokenOverride!.trim()
          : _preferences.getAuthToken()?.trim();
      if (authToken != null && authToken.isNotEmpty) {
        headers['x-auth-token'] = authToken;
      }
    }

    return headers;
  }

  String _resolveApiLanguage() {
    final currentLocale = Get.locale;
    if (currentLocale != null) {
      final apiCode = _matchApiLanguage(currentLocale);
      if (apiCode != null) {
        return apiCode;
      }
    }

    final savedLocale = _preferences.getLocaleValue()?.trim() ?? '';
    if (savedLocale.isNotEmpty) {
      for (final language in ChatLocaleController.supportedLanguages) {
        if (language.storageKey.toLowerCase() == savedLocale.toLowerCase()) {
          return language.apiCode;
        }
      }

      final languageCode = savedLocale.split('_').first.toLowerCase();
      for (final language in ChatLocaleController.supportedLanguages) {
        if (language.code.toLowerCase() == languageCode) {
          return language.apiCode;
        }
      }
    }

    return ChatLocaleController.supportedLanguages.first.apiCode;
  }

  String? _matchApiLanguage(Locale locale) {
    for (final language in ChatLocaleController.supportedLanguages) {
      if (_localeMatches(language.locale, locale)) {
        return language.apiCode;
      }
    }
    for (final language in ChatLocaleController.supportedLanguages) {
      if (language.code.toLowerCase() == locale.languageCode.toLowerCase()) {
        return language.apiCode;
      }
    }
    return null;
  }

  bool _localeMatches(Locale a, Locale b) {
    return a.languageCode == b.languageCode &&
        (a.countryCode ?? '') == (b.countryCode ?? '');
  }

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    Uri? requestUri,
  }) {
    Map<String, dynamic> json;
    try {
      json = _decodeJson(response.body);
    } on ApiException catch (error) {
      _logResponse(
        uri: requestUri,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );
      final message =
          _extractHttpFailureMessage(response, requestUri) ?? error.message;
      _logError(
        uri: requestUri,
        message: message,
        statusCode: response.statusCode,
        body: response.body,
      );
      throw ApiException(message, statusCode: response.statusCode);
    }

    final status = json['status']?.toString().toLowerCase();
    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        status != 'error';

    _logResponse(
      uri: requestUri,
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );

    if (isSuccess) {
      return json;
    }

    final message =
        _extractHttpFailureMessage(response, requestUri) ??
        _extractMessage(json);
    _logError(
      uri: requestUri,
      message: message,
      statusCode: response.statusCode,
      body: response.body,
    );

    throw ApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decodeJson(String body) {
    final normalizedBody = _normalizeJsonBody(body);
    if (normalizedBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(normalizedBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      final sanitizedBody = _extractJsonPayload(normalizedBody);
      if (sanitizedBody != null) {
        try {
          final decoded = jsonDecode(sanitizedBody);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {}
      }
    }

    throw const ApiException('Unexpected server response');
  }

  String _normalizeJsonBody(String body) {
    return body.replaceFirst('\uFEFF', '').trim();
  }

  String? _extractJsonPayload(String body) {
    final objectStart = body.indexOf('{');
    final objectEnd = body.lastIndexOf('}');
    if (objectStart >= 0 && objectEnd > objectStart) {
      return body.substring(objectStart, objectEnd + 1).trim();
    }

    final arrayStart = body.indexOf('[');
    final arrayEnd = body.lastIndexOf(']');
    if (arrayStart >= 0 && arrayEnd > arrayStart) {
      return body.substring(arrayStart, arrayEnd + 1).trim();
    }

    return null;
  }

  String _extractMessage(Map<String, dynamic> json) {
    final message = json['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final errors = json['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      return firstValue.toString();
    }

    return 'Request failed';
  }

  String? _extractHttpFailureMessage(http.Response response, Uri? requestUri) {
    final statusCode = response.statusCode;
    final location = response.headers['location']?.trim() ?? '';
    final redirectedToNotFound =
        statusCode >= 300 &&
        statusCode < 400 &&
        location.toLowerCase().contains('/404');

    if (redirectedToNotFound) {
      if (requestUri != null && _isGroupsChatUploadUri(requestUri)) {
        return _missingGroupsUploadMessage(requestUri);
      }
      return 'API route is missing on the server';
    }

    if (statusCode == 413) {
      return 'The selected file is larger than the server upload limit';
    }

    if (statusCode == 404 &&
        requestUri != null &&
        _isGroupsChatUploadUri(requestUri)) {
      return _missingGroupsUploadMessage(requestUri);
    }

    return null;
  }

  String _missingGroupsUploadMessage(Uri uri) {
    final path = uri.path.toLowerCase();
    final mediaKind = path.contains('/video')
        ? 'video'
        : path.contains('/voice-note')
        ? 'voice note'
        : path.contains('/file')
        ? 'file'
        : path.contains('/photo')
        ? 'photo'
        : 'media';
    return 'Group $mediaKind upload API is missing on the server. Deploy the updated api-addon-messangr groups_chat router/controller files.';
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    if (!_shouldLogRequest(uri)) {
      return;
    }

    final prefix = _logPrefix(uri);
    debugPrint('$prefix REQUEST [$method] $uri');
    debugPrint(
      '$prefix REQUEST HEADERS: ${_prettyJson(_redactHeaders(headers))}',
    );
    if (body != null && body.trim().isNotEmpty) {
      debugPrint(
        '$prefix REQUEST BODY: '
        '${_prettyBody(body, redactCallPayload: _isCallUri(uri))}',
      );
    }
  }

  void _logResponse({
    required Uri? uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    if (uri == null || !_shouldLogRequest(uri)) {
      return;
    }

    final prefix = _logPrefix(uri);
    debugPrint('$prefix RESPONSE STATUS: $statusCode');
    debugPrint(
      '$prefix RESPONSE HEADERS: ${_prettyJson(_redactHeaders(headers))}',
    );
    debugPrint(
      '$prefix RESPONSE BODY: '
      '${_prettyBody(body, redactCallPayload: _isCallUri(uri))}',
    );
  }

  void _logError({
    required Uri? uri,
    required String message,
    required int statusCode,
    required String body,
  }) {
    if (uri == null || !_shouldLogRequest(uri)) {
      return;
    }

    final prefix = _logPrefix(uri);
    debugPrint('$prefix ERROR STATUS: $statusCode');
    debugPrint('$prefix ERROR MESSAGE: $message');
    debugPrint(
      '$prefix ERROR BODY: '
      '${_prettyBody(body, redactCallPayload: _isCallUri(uri))}',
    );
  }

  String _prettyJson(Map<String, String> value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  bool _shouldLogRequest(Uri uri) {
    return callLoggingEnabled && _isCallUri(uri);
  }

  bool _isCallUri(Uri uri) {
    return uri.path.contains('/api-addon-messangr/chat/calls') ||
        uri.path.contains('/api-addon-messangr/web/call');
  }

  bool _isGroupsChatUri(Uri uri) {
    return uri.path.contains('/api-addon-messangr/groups-chat');
  }

  bool _isGroupsChatUploadUri(Uri uri) {
    return uri.path.contains('/api-addon-messangr/groups-chat/upload/');
  }

  String _logPrefix(Uri uri) {
    if (_isCallUri(uri)) {
      return 'CALL API';
    }
    return _isGroupsChatUri(uri) ? 'GROUPS API' : 'API';
  }

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      final normalized = key.toLowerCase();
      if (normalized == 'x-auth-token' ||
          normalized == 'x-signature' ||
          normalized == 'x-api-key' ||
          normalized == 'set-cookie') {
        return MapEntry(key, _redactValue(value));
      }
      return MapEntry(key, value);
    });
  }

  String _redactValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 8) {
      return '***';
    }
    return '${trimmed.substring(0, 4)}...${trimmed.substring(trimmed.length - 4)}';
  }

  String _prettyBody(String raw, {bool redactCallPayload = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    try {
      final decoded = jsonDecode(trimmed);
      final printable = redactCallPayload
          ? _redactCallPayload(decoded)
          : decoded;
      return const JsonEncoder.withIndent('  ').convert(printable);
    } catch (_) {
      return redactCallPayload
          ? '[unparseable call payload redacted]'
          : trimmed;
    }
  }

  dynamic _redactCallPayload(dynamic value) {
    if (value is List) {
      return value.map(_redactCallPayload).toList(growable: false);
    }
    if (value is! Map) {
      return value;
    }

    const sensitiveKeys = <String>{
      'access_token',
      'api_key',
      'authorization',
      'auth_token',
      'candidate',
      'candidates',
      'credential',
      'credentials',
      'ice_servers',
      'iceservers',
      'live_api_key',
      'live_secret',
      'own_stream_key',
      'password',
      'playback_url',
      'publish_url',
      'refresh_token',
      'remote_stream_key',
      'sdp',
      'secret',
      'stream_key',
      'token',
      'username',
      'x_auth_token',
    };
    final redacted = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final normalized = key.trim().replaceAll('-', '_').toLowerCase();
      redacted[key] = sensitiveKeys.contains(normalized)
          ? '[redacted]'
          : _redactCallPayload(entry.value);
    }
    return redacted;
  }
}
