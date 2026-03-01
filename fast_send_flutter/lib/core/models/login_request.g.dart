// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      captcha: json['captcha'] as String?,
      captchaId: (json['captchaId'] as num).toInt(),
      password: json['password'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{
      'captcha': instance.captcha,
      'captchaId': instance.captchaId,
      'password': instance.password,
      'username': instance.username,
    };
