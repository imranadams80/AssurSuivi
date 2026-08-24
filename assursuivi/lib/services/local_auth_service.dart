import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  static const String _usersKey = 'assursuivi_auth_users';
  static const String _currentUserKey = 'assursuivi_auth_current_user';
  static const String _passwordsKey = 'assursuivi_auth_passwords';

  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedDefaultAdminIfEmpty();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final String? userJson = _prefs.getString(_currentUserKey);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return (await getCurrentUser()) != null;
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    final passwords = _getPasswordsMap();
    final users = await _getUsersList();

    if (!passwords.containsKey(cleanEmail) || passwords[cleanEmail] != password) {
      throw Exception('Email ou mot de passe incorrect.');
    }

    final user = users.firstWhere((u) => u.email.toLowerCase() == cleanEmail);
    final updatedUser = user.copyWith(lastLogin: DateTime.now());

    // Sauvegarde session courante
    await _prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    return updatedUser;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final passwords = _getPasswordsMap();

    if (passwords.containsKey(cleanEmail)) {
      throw Exception('Un compte existe déjà avec cette adresse email.');
    }

    const uuid = Uuid();
    final newUser = UserModel(
      id: uuid.v4(),
      email: cleanEmail,
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    // Sauvegarde nouvel utilisateur et mot de passe
    final users = await _getUsersList();
    users.add(newUser);
    passwords[cleanEmail] = password;

    await _prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
    await _prefs.setString(_passwordsKey, jsonEncode(passwords));
    await _prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

    return newUser;
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_currentUserKey);
  }

  // --- HELPERS INTERNES ---
  Map<String, String> _getPasswordsMap() {
    final String? jsonStr = _prefs.getString(_passwordsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      return raw.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<List<UserModel>> _getUsersList() async {
    final String? jsonStr = _prefs.getString(_usersKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> raw = jsonDecode(jsonStr);
      return raw.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _seedDefaultAdminIfEmpty() async {
    final users = await _getUsersList();
    if (users.isNotEmpty) return;

    const uuid = Uuid();
    final defaultAdmin = UserModel(
      id: uuid.v4(),
      email: 'admin@assursuivi.com',
      displayName: 'Administrateur',
      createdAt: DateTime.now(),
    );

    final passwords = {'admin@assursuivi.com': 'admin123'};

    await _prefs.setString(_usersKey, jsonEncode([defaultAdmin.toJson()]));
    await _prefs.setString(_passwordsKey, jsonEncode(passwords));
  }
}

