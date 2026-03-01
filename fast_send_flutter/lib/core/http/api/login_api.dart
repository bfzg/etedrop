import 'package:flutter_app/core/utils/encrypt_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/login_request.dart';
import '../../models/login_response.dart';
import '../dio_provider.dart';
import '../http_service.dart';

part 'login_api.g.dart';

class LoginApi {
  final HttpService http;
  LoginApi(this.http);

  // 登录
  Future<LoginResponse> login(LoginRequest req) async {
    // 对密码进行加密
    final data = LoginRequest(
      captchaId: req.captchaId,
      password: sha256Encrypt(req.password),
      username: req.username,
    );
    final res = await http.post('/login', data: data.toJson());
    return LoginResponse.fromJson(res.data);
  }
}

@riverpod
LoginApi loginApi(Ref ref) {
  final http = ref.watch(httpServiceProvider);
  return LoginApi(http);
}
