/// نظام تشويش وحماية البيانات الحساسة
/// يمنع المستخدم من تغيير المفاتيح والـ endpoints بسهولة

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

class Obfuscation {
  /// قائمة المفاتيح والقيم المشفرة (مخبأة)
  static const Map<String, String> _hiddenKeys = {
    'api_key': '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d',
    'api_secret': '9z8y7x6w5v4u3t2s1r0q9p8o7n6m5l4k',
    'app_id': 'com.fluttercrafters.sngine',
    'encryption_pepper': 'c3e0f6f1-8c6a-4a21-9b6b-9c79f6c91f5d',
  };

  /// Pepper سري لكل عملية فك
  static const String _runtimePepper = 'x9k2m5l8p1q4r7s0t3u6v9w2z5a8b1c4';

  /// فك تشفير بسيط معكوس (XOR + base64)
  static String _xorDecode(String encoded, String pepper) {
    try {
      final bytes = base64.decode(encoded);
      final pepperBytes = utf8.encode(pepper);
      
      final result = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        result.add(bytes[i] ^ pepperBytes[i % pepperBytes.length]);
      }
      
      return utf8.decode(result);
    } catch (e) {
      throw Exception('Decoding failed: $e');
    }
  }

  /// فك تشفير المفاتيح المخبأة
  static String getHiddenValue(String key) {
    try {
      final encoded = _hiddenKeys[key];
      if (encoded == null) {
        throw Exception('Unknown key: $key');
      }
      
      // فك التشفير باستخدام pepper
      final decoded = _xorDecode(encoded, _runtimePepper);
      
      // التحقق من السلامة
      final hash = sha256.convert(utf8.encode(decoded)).toString();
      
      return decoded;
    } catch (e) {
      throw Exception('Failed to get hidden value for $key: $e');
    }
  }

  /// فحص تكامل البيانات (منع التعديل)
  static bool verifyIntegrity(String key, String expectedValue) {
    try {
      final actual = getHiddenValue(key);
      return actual == expectedValue;
    } catch (e) {
      return false;
    }
  }

  /// إنشاء hash للتحقق من العبث
  static String getHash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  /// تشويش اسم الدالة/المتغير (compile-time obfuscation)
  /// استخدم أسماء مضللة داخل السورس
  static String _obfuscatedFunction1() => getHiddenValue('api_key');
  static String _obfuscatedFunction2() => getHiddenValue('api_secret');
  static String _obfuscatedFunction3() => getHiddenValue('app_id');
  static String _obfuscatedFunction4() => getHiddenValue('encryption_pepper');

  /// واجهة عامة آمنة
  static String getValue(String keyType) {
    switch (keyType) {
      case 'key':
        return _obfuscatedFunction1();
      case 'secret':
        return _obfuscatedFunction2();
      case 'app':
        return _obfuscatedFunction3();
      case 'pepper':
        return _obfuscatedFunction4();
      default:
        throw Exception('Invalid key type: $keyType');
    }
  }
}

/// SHA256 مختصر للراحة
final sha256 = crypto.sha256;
