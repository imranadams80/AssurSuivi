import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assursuivi/services/local_database_service.dart';
import 'package:assursuivi/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService Tests', () {
    late LocalDatabaseService dbService;
    late BackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dbService = LocalDatabaseService();
      await dbService.init();
      backupService = BackupService(dbService: dbService);
    });

    test('Validation de format de sauvegarde invalide', () async {
      final result = await backupService.restoreFromJson('{"invalid": true}');
      expect(result.success, isFalse);
      expect(result.message, contains('Ce fichier n\'est pas une sauvegarde valide'));
    });

    test('Restauration avec succès d\'une sauvegarde JSON valide', () async {
      final now = DateTime.now();
      final validJson = jsonEncode({
        'appName': 'AssurSuivi',
        'version': '1.0.0',
        'exportDate': now.toIso8601String(),
        'clients': [
          {
            'id': 'test-client-1',
            'fullName': 'Marc Dupont',
            'phoneNumber': '+225 07 00 00 00 00',
            'createdAt': now.toIso8601String(),
          }
        ],
        'vehicles': [
          {
            'id': 'test-veh-1',
            'clientId': 'test-client-1',
            'type': 'voiture',
            'registrationNumber': '1234-AB-01',
            'brand': 'Toyota',
            'model': 'Corolla',
            'fiscalPower': '7 CV',
          }
        ],
        'subscriptions': [
          {
            'id': 'test-sub-1',
            'clientId': 'test-client-1',
            'vehicleId': 'test-veh-1',
            'periodicity': 'mensuelle',
            'startDate': now.toIso8601String(),
            'endDate': now.add(const Duration(days: 30)).toIso8601String(),
            'amount': 25000.0,
            'isPaid': true,
            'notes': 'Test backup',
            'createdAt': now.toIso8601String(),
          }
        ]
      });

      final result = await backupService.restoreFromJson(validJson, overwrite: true);
      expect(result.success, isTrue);
      expect(result.clientsCount, 1);
      expect(result.vehiclesCount, 1);
      expect(result.subscriptionsCount, 1);

      final clients = await dbService.getClients();
      expect(clients.length, 1);
      expect(clients.first.fullName, 'Marc Dupont');

      final vehicles = await dbService.getVehicles();
      expect(vehicles.length, 1);
      expect(vehicles.first.registrationNumber, '1234-AB-01');

      final subs = await dbService.getSubscriptions();
      expect(subs.length, 1);
      expect(subs.first.amount, 25000.0);
    });
  });
}

