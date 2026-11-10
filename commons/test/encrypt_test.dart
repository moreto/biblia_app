import 'dart:convert';

import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

const _chave = '5oAaa+hIOTQzGUxHYn8o6mHfQqEi9PXb4kBGpCQ+fn0=';

void main() {
  final encrypt = Encrypt();

  test('criptografa e decriptografa o mesmo texto', () async {
    final payload = await encrypt.encryptString('senha çã 123', _chave);

    expect(await encrypt.decryptString(payload, _chave), 'senha çã 123');
  });

  test('payload é base64 de iv(12) + cifrado + tag(16), o formato da biblia_api', () async {
    final payload = await encrypt.encryptString('abc', _chave);

    expect(base64Decode(payload).length, 12 + 3 + 16);
  });

  test('o iv é aleatório: o mesmo texto gera payloads diferentes', () async {
    expect(await encrypt.encryptString('abc', _chave), isNot(await encrypt.encryptString('abc', _chave)));
  });

  test('chave errada não decriptografa', () async {
    final payload = await encrypt.encryptString('abc', _chave);
    final outraChave = base64Encode(List<int>.filled(32, 7));

    expect(() => encrypt.decryptString(payload, outraChave), throwsA(anything));
  });
}
