import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

LoginResponse loginResponseFromJson(String str) => LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required int expires,
    required bool isResetAccount,
    required String token,
    required User user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

///用户信息
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    required int rgroupId,
    required String username,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
