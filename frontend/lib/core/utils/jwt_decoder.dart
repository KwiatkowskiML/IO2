import 'dart:convert';
import 'package:flutter/material.dart';

Map<String, dynamic>? tryDecodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

bool isTokenExpired(String token) {
  final jwtData = tryDecodeJwt(token);
  if (jwtData == null) return true;

  final exp = jwtData['exp'];
  if (exp == null) return true;

  final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  return expiryDate.isBefore(DateTime.now());
}

DateTime? getTokenExpiry(String token) {
  final jwtData = tryDecodeJwt(token);
  if (jwtData == null) return null;

  final exp = jwtData['exp'];
  if (exp == null) return null;

  return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
}
