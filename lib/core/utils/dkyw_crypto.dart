import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart';

/// 湖南农业大学一卡通财务服务平台 (dkyw.js) 动态 AES 加解密工具类。
class DkywCrypto {
  DkywCrypto._();

  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// 生成指定长度 (默认 16 位) 的随机 AES 密钥
  static String genKey([int length = 16]) {
    final random = Random();
    return List.generate(
      length,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }

  /// 对应前端 my-encryption.js 中的 handleKey 移位与字符反转逻辑
  static String handleKey(String key, bool isEncrypt) {
    if (isEncrypt) {
      final rotated = key.substring(10) + key.substring(0, 10);
      return rotated.split('').reversed.join();
    } else {
      final reversed = key.split('').reversed.join();
      return reversed.substring(6) + reversed.substring(0, 6);
    }
  }

  /// 请求加密：将对象或 JSON 字符串加密为「16 位编码后 Key + Base64 密文」
  static String encryptPayload(dynamic data) {
    final jsonStr = data is String ? data : jsonEncode(data);
    final keyStr = genKey(16);
    final key = Key.fromUtf8(keyStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(jsonStr);
    final handledKey = handleKey(keyStr, true);
    return handledKey + encrypted.base64;
  }

  /// 响应解密：解析前 16 位 Key 并对密文执行 AES 解密。
  static dynamic decryptPayload(String datajson) {
    if (datajson.length <= 16) return datajson;
    final keyPart = datajson.substring(0, 16);
    final cipherPart = datajson.substring(16);
    final realKey = handleKey(keyPart, false);
    final key = Key.fromUtf8(realKey);
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: 'PKCS7'));
    final decryptedStr = encrypter.decrypt(Encrypted.fromBase64(cipherPart));
    try {
      return jsonDecode(decryptedStr);
    } catch (_) {
      return decryptedStr;
    }
  }

  /// 从服务器原始响应中解密数据。
  ///
  /// 兼容标准 Map、JSON 字符串、HTML 转义（`&quot;`）以及带引号包裹的格式。
  static dynamic decryptServerResponse(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map) {
      if (responseData.containsKey('datajson')) {
        final decrypted = decryptPayload(responseData['datajson'].toString());
        if (decrypted is String) {
          try {
            return jsonDecode(decrypted);
          } catch (_) {}
        }
        return decrypted;
      }
      return responseData;
    }

    if (responseData is String) {
      String raw = responseData.trim();
      if (raw.startsWith('"') && raw.endsWith('"') && raw.length > 2) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {
          raw = raw.substring(1, raw.length - 1);
        }
      }

      if (raw.contains('&quot;')) {
        raw = raw.replaceAll('&quot;', '"');
      }

      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) {
          return decryptServerResponse(parsed);
        }
      } catch (_) {}

      final match =
          RegExp(r'datajson["\x27]?\s*[:=]\s*["\x27]?([A-Za-z0-9+/=]+)')
              .firstMatch(raw);
      if (match != null) {
        final cipher = match.group(1);
        if (cipher != null && cipher.isNotEmpty) {
          final decrypted = decryptPayload(cipher);
          if (decrypted is String) {
            try {
              return jsonDecode(decrypted);
            } catch (_) {}
          }
          return decrypted;
        }
      }
    }

    return responseData;
  }
}
