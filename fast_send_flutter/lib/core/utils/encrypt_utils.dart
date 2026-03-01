import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 对字符串进行 SHA-256 加密
String sha256Encrypt(String input) {
  final inputBytes = utf8.encode(input);
  final digest = sha256.convert(inputBytes);
  return digest.toString();
}
