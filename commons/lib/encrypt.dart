import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class Encrypt {
  final _aes = AesGcm.with256bits();

  Future<String> encryptString(String plainText, String base64Key) async {
    final secretKey = SecretKey(base64Decode(base64Key));
    final box = await _aes.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey, // o nonce aleatório de 12 bytes é gerado automaticamente
    );
    // nonce + ciphertext + mac
    return base64Encode(box.concatenation());
  }

  // (opcional) para decriptar no próprio Flutter
  Future<String> decryptString(String payload, String base64Key) async {
    final secretKey = SecretKey(base64Decode(base64Key));
    final box = SecretBox.fromConcatenation(base64Decode(payload), nonceLength: 12, macLength: 16);
    final clear = await _aes.decrypt(box, secretKey: secretKey);
    return utf8.decode(clear);
  }
}
