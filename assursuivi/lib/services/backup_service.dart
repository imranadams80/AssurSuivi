import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/subscription_model.dart';
import 'database_service.dart';
import 'date_calculator.dart';

class RestoreResult {
  final bool success;
  final String message;
  final int clientsCount;
  final int vehiclesCount;
  final int subscriptionsCount;

  RestoreResult({
    required this.success,
    required this.message,
    this.clientsCount = 0,
    this.vehiclesCount = 0,
    this.subscriptionsCount = 0,
  });
}

class BackupService {
  final DatabaseService dbService;

  BackupService({required this.dbService});

  /// Exporte toutes les données sous forme de fichier JSON et ouvre le menu de partage
  Future<void> exportDataBackup() async {
    final clients = await dbService.getClients();
    final vehicles = await dbService.getVehicles();
    final subscriptions = await dbService.getSubscriptions();

    final backupMap = {
      'appName': 'AssurSuivi',
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'summary': {
        'totalClients': clients.length,
        'totalVehicles': vehicles.length,
        'totalSubscriptions': subscriptions.length,
      },
      'clients': clients.map((c) => c.toJson()).toList(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
    };

    final jsonContent = const JsonEncoder.withIndent('  ').convert(backupMap);

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'AssurSuivi_Backup_$dateStr.json';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Sauvegarde AssurSuivi du ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      text: 'Fichier de sauvegarde sécurisé de l\'application AssurSuivi (${clients.length} clients, ${subscriptions.length} contrats).',
    );
  }

  /// Exporte un rapport synthétique CSV des contrats pour ouverture dans Excel
  Future<void> exportContractsCsv() async {
    final clients = await dbService.getClients();
    final vehicles = await dbService.getVehicles();
    final subscriptions = await dbService.getSubscriptions();

    final buffer = StringBuffer();
    // En-têtes CSV
    buffer.writeln('Client;Telephone;Immatriculation;Type;Marque_Modele;Date_Debut;Date_Echeance;Montant_FCFA;Statut_Paiement;Statut_Urgence');

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final sub in subscriptions) {
      final client = clients.where((c) => c.id == sub.clientId).firstOrNull;
      final vehicle = vehicles.where((v) => v.id == sub.vehicleId).firstOrNull;
      final urgency = DateCalculator.getUrgencyStatus(sub.endDate);

      final clientName = client?.fullName ?? 'Inconnu';
      final phone = client?.phoneNumber ?? '-';
      final plate = vehicle?.registrationNumber ?? '-';
      final type = vehicle?.type.name ?? '-';
      final brandModel = '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''}'.trim();
      final startDate = dateFormat.format(sub.startDate);
      final endDate = dateFormat.format(sub.endDate);
      final amount = sub.amount.toStringAsFixed(0);
      final paid = sub.isPaid ? 'PAYE' : 'NON_PAYE';
      final urgencyLabel = urgency.label;

      buffer.writeln('$clientName;$phone;$plate;$type;$brandModel;$startDate;$endDate;$amount;$paid;$urgencyLabel');
    }

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'AssurSuivi_Contrats_$dateStr.csv';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rapport Contrats AssurSuivi',
      text: 'Export Excel/CSV des contrats d\'assurance AssurSuivi.',
    );
  }

  /// Restaure les données à partir d'une chaîne JSON brute
  Future<RestoreResult> restoreFromJson(String jsonContent, {bool overwrite = true}) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return RestoreResult(success: false, message: 'Format de fichier invalide (doit être un objet JSON).');
      }

      if (decoded['appName'] != 'AssurSuivi' || !decoded.containsKey('clients')) {
        return RestoreResult(
          success: false,
          message: 'Ce fichier n\'est pas une sauvegarde valide de l\'application AssurSuivi.',
        );
      }

      final rawClients = decoded['clients'] as List<dynamic>? ?? [];
      final rawVehicles = decoded['vehicles'] as List<dynamic>? ?? [];
      final rawSubs = decoded['subscriptions'] as List<dynamic>? ?? [];

      final clients = rawClients.map((c) => ClientModel.fromJson(c as Map<String, dynamic>)).toList();
      final vehicles = rawVehicles.map((v) => VehicleModel.fromJson(v as Map<String, dynamic>)).toList();
      final subscriptions = rawSubs.map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>)).toList();

      await dbService.bulkRestoreData(
        clients: clients,
        vehicles: vehicles,
        subscriptions: subscriptions,
        overwrite: overwrite,
      );

      return RestoreResult(
        success: true,
        message: 'Restauration réussie !',
        clientsCount: clients.length,
        vehiclesCount: vehicles.length,
        subscriptionsCount: subscriptions.length,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Erreur lors de la lecture du fichier : $e',
      );
    }
  }

  /// Ouvre l'explorateur de fichiers de l'appareil et restaure le fichier JSON sélectionné
  Future<RestoreResult> pickAndRestoreFile({bool overwrite = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(success: false, message: 'Aucun fichier sélectionné.');
      }

      final file = result.files.first;
      String? jsonContent;

      if (file.bytes != null) {
        jsonContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          jsonContent = await ioFile.readAsString();
        }
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        return RestoreResult(success: false, message: 'Fichier vide ou inaccessible.');
      }

      return await restoreFromJson(jsonContent, overwrite: overwrite);
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Impossible d\'ouvrir le fichier : $e',
      );
    }
  }
}
