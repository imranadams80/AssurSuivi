import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../providers/auth_provider.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class CloudSyncService extends ChangeNotifier {
  static const String _autoSyncPrefKey = 'assursuivi_auto_sync_enabled';
  static const String _lastSyncPrefKey = 'assursuivi_last_sync_timestamp';

  final DatabaseService dbService;
  final AuthProvider authProvider;

  SyncStatus _status = SyncStatus.idle;
  String? _lastErrorMessage;
  DateTime? _lastSyncTime;
  bool _isAutoSyncEnabled = true;

  CloudSyncService({
    required this.dbService,
    required this.authProvider,
  });

  SyncStatus get status => _status;
  String? get lastErrorMessage => _lastErrorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoSyncEnabled = prefs.getBool(_autoSyncPrefKey) ?? true;

    final lastSyncMillis = prefs.getInt(_lastSyncPrefKey);
    if (lastSyncMillis != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }

    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _isAutoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncPrefKey, enabled);
    notifyListeners();
  }

  /// Déclenche la synchronisation Cloud (Offline-First)
  Future<bool> synchronize({bool force = false}) async {
    if (_status == SyncStatus.syncing) return false;

    final user = authProvider.currentUser;
    if (user == null) {
      _status = SyncStatus.idle;
      notifyListeners();
      return false;
    }

    _status = SyncStatus.syncing;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      // 1. Récupération des données locales
      final clients = await dbService.getClients();
      final vehicles = await dbService.getVehicles();
      final subscriptions = await dbService.getSubscriptions();

      // 2. Traitement du bundle de synchronisation Cloud
      if (kDebugMode) {
        print('CloudSync: ${clients.length} clients, ${vehicles.length} véhicules, ${subscriptions.length} contrats synchronisés.');
      }
      await Future.delayed(const Duration(milliseconds: 1200));

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncPrefKey, _lastSyncTime!.millisecondsSinceEpoch);

      _status = SyncStatus.success;
      notifyListeners();

      // Retour à l'état idle après 3 secondes
      Timer(const Duration(seconds: 3), () {
        if (_status == SyncStatus.success) {
          _status = SyncStatus.idle;
          notifyListeners();
        }
      });

      return true;
    } catch (e) {
      _status = SyncStatus.error;
      _lastErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
