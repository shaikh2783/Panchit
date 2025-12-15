import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';
import 'package:snginepro/features/offers/data/services/offers_api_service.dart';
import 'package:snginepro/main.dart' show cfgP;
/// مفاتيح مشتركة مع المولّد (حافظ عليها سرية)
const String _kSiteEncryptKey = 'ef2ff48ada3d53fe';
const String _kApplicationId = 'com.fluttercrafters.app';
const String _kServerHmacKey = '43e4b116877a2543664ea0cb3c144f62';
const String _kPepper = 'c3e0f6f1-8c6a-4a21-9b6b-9c79f6c91f5d';
/// Base64 مخصصة + تبديل chunks
const String _stdAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
const String _customAlphabet = 'ZYXABCDEFGHIJKLMNOPQRSTUVWzyxabcdefghijklmnopqrstuvw0123456789-_=';
const int _chunkSize = 5;
Uint8List _sha256Bytes(List<int> data) => Uint8List.fromList(crypto.sha256.convert(data).bytes);
Uint8List _hmacSha256Bytes(String key, String message) {
  final h = crypto.Hmac(crypto.sha256, utf8.encode(key));
  return Uint8List.fromList(h.convert(utf8.encode(message)).bytes);
}
String _normalizeDomain(String domain) {
  var d = domain.trim().toLowerCase();
  if (d.startsWith('https://')) d = d.substring(8);
  if (d.startsWith('http://')) d = d.substring(7);
  if (d.endsWith('/')) d = d.substring(0, d.length - 1);
  return d;
}
Uint8List _baseKey() => _sha256Bytes(utf8.encode('$_kSiteEncryptKey$_kApplicationId$_kPepper'));
Uint8List _deriveKey(Uint8List salt, Uint8List domainHash) {
  final combo = <int>[]
    ..addAll(salt)
    ..addAll(_baseKey())
    ..addAll(domainHash);
  return _sha256Bytes(combo);
}
Uint8List _deriveKeyLegacy(Uint8List salt) {
  final ikm = _sha256Bytes(utf8.encode(_kSiteEncryptKey + _kApplicationId));
  final combo = <int>[]..addAll(salt)..addAll(ikm);
  return _sha256Bytes(combo);
}
String _swapChunks(String input) {
  final buf = StringBuffer();
  for (var i = 0; i < input.length; i += _chunkSize) {
    final end = (i + _chunkSize <= input.length) ? i + _chunkSize : input.length;
    buf.write(input.substring(i, end).split('').reversed.join());
  }
  return buf.toString();
}
String _translateAlphabet(String input, String from, String to) {
  final map = <String, String>{};
  for (var i = 0; i < from.length; i++) {
    map[from[i]] = to[i];
  }
  final buf = StringBuffer();
  for (final ch in input.split('')) {
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}
Uint8List _customBase64Decode(String data) {
  final back = _translateAlphabet(data, _customAlphabet, _stdAlphabet);
  final unswapped = _swapChunks(back);
  return Uint8List.fromList(base64.decode(unswapped));
}
String _customBase64Encode(Uint8List data) {
  final std = base64.encode(data);
  final swapped = _swapChunks(std);
  return _translateAlphabet(swapped, _stdAlphabet, _customAlphabet);
}
Map<String, dynamic> postsconst(String compactB64) {
  return _decodeV2(compactB64);
}
Map<String, dynamic> _decodeV2(String compactB64) {
  final envJsonStr = utf8.decode(_customBase64Decode(compactB64));
  final env = jsonDecode(envJsonStr);
  if (env is! Map) throw Exception('Envelope must be a Map');
  final blobEnc = env['blob'] as String?;
  final hmacEnc = env['hmac'] as String?;
  final domainHashB64 = env['domain_hash'] as String?;
  final issuedAt = env['issued_at']?.toString() ?? '';
  final nonce = env['nonce']?.toString() ?? '';
  if ([blobEnc, hmacEnc, domainHashB64].any((e) => e == null)) {
    throw Exception('Missing envelope fields');
  }
  final sigData = '$blobEnc|$domainHashB64|$issuedAt|$nonce';
  final expectedHmac = _hmacSha256Bytes('$_kServerHmacKey$_kPepper', sigData);
  final actualHmac = _customBase64Decode(hmacEnc!);
  _constantTimeAssert(expectedHmac, actualHmac, 'Invalid HMAC (v2)');
  final blob = _customBase64Decode(blobEnc!);
  if (blob.length < 16 + 12 + 16) throw Exception('Blob too short');
  final salt = blob.sublist(0, 16);
  final iv = blob.sublist(16, 28);
  final cipherPlusTag = blob.sublist(28);
  final domainHash = base64.decode(domainHashB64!);
  final key = Key(_deriveKey(Uint8List.fromList(salt), Uint8List.fromList(domainHash)));
  final encr = Encrypter(AES(key, mode: AESMode.gcm));
  final plain = encr.decrypt(
    Encrypted(Uint8List.fromList(cipherPlusTag)),
    iv: IV(Uint8List.fromList(iv)),
  );
  final decodedJson = jsonDecode(plain);
  if (decodedJson is! Map<String, dynamic>) {
    throw Exception('Expected Map<String, dynamic>, got ${decodedJson.runtimeType}');
  }
  final decoded = decodedJson;
  final w1 = decoded['w1']?.toString();
  if (w1 == null) throw Exception('Missing w1 (domain) in payload');
  final normalized = _normalizeDomain(w1);
  final computedDomainHash = base64.encode(_sha256Bytes(utf8.encode(normalized)));
  if (computedDomainHash != domainHashB64) {
    throw Exception('Domain mismatch/binding failed');
  }
  // ✅ تحقق صارم من التوقيع - أي تعديل يفشل
  final signature = decoded['signature']?.toString();
  if (signature == null) {
    throw Exception('🚨 LICENSE TAMPERING DETECTED - Missing signature');
  }
  final apiKey = decoded['1']?.toString();
  final apiSecret = decoded['2']?.toString();
  if (apiKey == null || apiSecret == null) {
    throw Exception('Missing API credentials in license');
  }
  if (!_verifySignature(
    website: w1,
    apiKey: apiKey,
    apiSecret: apiSecret,
    providedSignature: signature,
  )) {
    throw Exception('🚨 LICENSE TAMPERING DETECTED - Signature verification failed!');
  }
  final endpoints = _extractEndpoints(decoded);
  _updateCfg(decoded, endpoints);
  return decoded;
}
/// التحقق من التوقيع الصارم - أي تعديل يفشل
bool _verifySignature({
  required String website,
  required String apiKey,
  required String apiSecret,
  required String providedSignature,
}) {
  try {
    final normalized = _normalizeDomain(website);
    final sigData = '$normalized|$apiKey|$apiSecret';
    final expectedHmac = _hmacSha256Bytes(_kPepper, sigData);
    final expectedSig = base64.encode(expectedHmac);
    // مقارنة constant-time لمنع timing attacks
    if (expectedSig.length != providedSignature.length) return false;
    var match = true;
    for (int i = 0; i < expectedSig.length; i++) {
      if (expectedSig[i] != providedSignature[i]) match = false;
    }
    return match;
  } catch (e) {
    return false;
  }
}
void _constantTimeAssert(Uint8List expected, Uint8List actual, String error) {
  if (expected.length != actual.length) throw Exception(error);
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected[i] ^ actual[i];
  }
  if (diff != 0) throw Exception(error);
}
Map<String, dynamic> _extractEndpoints(Map<String, dynamic> decoded) {
  final endpointsData = decoded['endpoints'];
  if (endpointsData == null) throw Exception('endpoints field not found');
  if (endpointsData is List) {
    return {'list': endpointsData};
  } else if (endpointsData is Map<String, dynamic>) {
    return endpointsData;
  } else {
    throw Exception('endpoints must be List or Map, got ${endpointsData.runtimeType}');
  }
}
void _updateCfg(Map<String, dynamic> decoded, Map<String, dynamic> endpoints) {
  cfgP.clear();
  cfgP.add(decoded);
  saveEndpoints(endpoints);
}
