import '../models/user_model.dart';

abstract class AuthService {
  Future<void> init();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> logout();
}

