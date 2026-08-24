import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final BiometricService biometricService;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = true;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider({
    required this.authService,
    BiometricService? biometricService,
  }) : biometricService = biometricService ?? BiometricService();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await authService.init();
    _isBiometricAvailable = await biometricService.isBiometricAvailable();
    _isBiometricEnabled = await biometricService.isBiometricEnabled();

    final user = await authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;

      // Si l'utilisateur a activé la biométrie et qu'elle est disponible
      if (_isBiometricAvailable && _isBiometricEnabled) {
        _isAuthenticated = false; // Nécessite déverrouillage biométrique
      } else {
        _isAuthenticated = true;
      }
    } else {
      _currentUser = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Déverrouillage par empreinte digitale / code PIN système
  Future<bool> unlockWithBiometrics() async {
    _errorMessage = null;
    notifyListeners();

    final bool success = await biometricService.authenticate(
      reason: 'Veuillez scanner votre empreinte pour déverrouiller AssurSuivi',
    );

    if (success) {
      _isAuthenticated = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Échec de l\'authentification biométrique.';
      notifyListeners();
      return false;
    }
  }

  /// Connexion classique par Email / Mot de passe
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authService.login(email: email, password: password);
      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inscription d'un nouveau compte gestionnaire
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Activer ou désactiver l'empreinte digitale
  Future<void> toggleBiometric(bool enabled) async {
    await biometricService.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

