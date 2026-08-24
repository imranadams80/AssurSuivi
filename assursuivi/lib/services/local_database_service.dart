import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type.dart';
import '../models/subscription_model.dart';
import '../models/periodicity.dart';
import 'database_service.dart';
import 'date_calculator.dart';

class LocalDatabaseService implements DatabaseService {
  static const String _clientsKey = 'assursuivi_clients';
  static const String _vehiclesKey = 'assursuivi_vehicles';
  static const String _subscriptionsKey = 'assursuivi_subscriptions';

  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await seedInitialDataIfEmpty();
  }

  // --- CLIENTS ---
  @override
  Future<List<ClientModel>> getClients() async {
    final String? jsonString = _prefs.getString(_clientsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ClientModel?> getClientById(String id) async {
    final clients = await getClients();
    try {
      return clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveClient(ClientModel client) async {
    final clients = await getClients();
    final index = clients.indexWhere((c) => c.id == client.id);
    if (index >= 0) {
      clients[index] = client;
    } else {
      clients.add(client);
    }
    await _prefs.setString(_clientsKey, jsonEncode(clients.map((c) => c.toJson()).toList()));
  }

  @override
  Future<void> deleteClient(String id) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == id);
    await _prefs.setString(_clientsKey, jsonEncode(clients.map((c) => c.toJson()).toList()));

    // Supprimer également les véhicules et souscriptions associés
    final vehicles = await getVehiclesByClientId(id);
    for (final v in vehicles) {
      await deleteVehicle(v.id);
    }
  }

  // --- VEHICULES ---
  @override
  Future<List<VehicleModel>> getVehicles() async {
    final String? jsonString = _prefs.getString(_vehiclesKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VehicleModel?> getVehicleById(String id) async {
    final vehicles = await getVehicles();
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<VehicleModel>> getVehiclesByClientId(String clientId) async {
    final vehicles = await getVehicles();
    return vehicles.where((v) => v.clientId == clientId).toList();
  }

  @override
  Future<void> saveVehicle(VehicleModel vehicle) async {
    final vehicles = await getVehicles();
    final index = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      vehicles[index] = vehicle;
    } else {
      vehicles.add(vehicle);
    }
    await _prefs.setString(_vehiclesKey, jsonEncode(vehicles.map((v) => v.toJson()).toList()));
  }

  @override
  Future<void> deleteVehicle(String id) async {
    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v.id == id);
    await _prefs.setString(_vehiclesKey, jsonEncode(vehicles.map((v) => v.toJson()).toList()));

    // Supprimer les souscriptions associées
    final subs = await getSubscriptions();
    subs.removeWhere((s) => s.vehicleId == id);
    await _prefs.setString(_subscriptionsKey, jsonEncode(subs.map((s) => s.toJson()).toList()));
  }

  // --- SOUSCRIPTIONS ---
  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final String? jsonString = _prefs.getString(_subscriptionsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SubscriptionModel?> getSubscriptionById(String id) async {
    final subs = await getSubscriptions();
    try {
      return subs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    final subs = await getSubscriptions();
    final index = subs.indexWhere((s) => s.id == subscription.id);
    if (index >= 0) {
      subs[index] = subscription;
    } else {
      subs.add(subscription);
    }
    await _prefs.setString(_subscriptionsKey, jsonEncode(subs.map((s) => s.toJson()).toList()));
  }

  @override
  Future<void> deleteSubscription(String id) async {
    final subs = await getSubscriptions();
    subs.removeWhere((s) => s.id == id);
    await _prefs.setString(_subscriptionsKey, jsonEncode(subs.map((s) => s.toJson()).toList()));
  }

  // --- DONNEES DE DEMO INITIALES ---
  @override
  Future<void> seedInitialDataIfEmpty() async {
    final existingSubs = await getSubscriptions();
    if (existingSubs.isNotEmpty) return;

    const uuid = Uuid();
    final now = DateTime.now();

    // Client 1 : Jean Kouassi
    final client1 = ClientModel(
      id: uuid.v4(),
      fullName: 'Jean Kouassi',
      phoneNumber: '+225 07 00 11 22 33',
      email: 'jean.kouassi@email.com',
      notes: 'Client régulier, toujours à l\'heure',
      createdAt: now.subtract(const Duration(days: 90)),
    );

    // Véhicule 1 : Voiture Toyota Corolla
    final vehicle1 = VehicleModel(
      id: uuid.v4(),
      clientId: client1.id,
      type: VehicleType.voiture,
      registrationNumber: '1234-AB-01',
      brand: 'Toyota',
      model: 'Corolla 2018',
      fiscalPower: '7 CV',
      notes: 'Carte grise à jour',
    );

    // Souscription 1 (Expire dans 5 jours => Imminente Orange)
    final startSub1 = now.subtract(const Duration(days: 25));
    final sub1 = SubscriptionModel(
      id: uuid.v4(),
      clientId: client1.id,
      vehicleId: vehicle1.id,
      periodicity: Periodicity.mensuelle,
      startDate: startSub1,
      endDate: DateCalculator.calculateEndDate(startSub1, Periodicity.mensuelle),
      amount: 25000.0,
      isPaid: true,
      notes: 'Formule Tiers Simple',
      createdAt: startSub1,
    );

    // Client 2 : Marie Dupont
    final client2 = ClientModel(
      id: uuid.v4(),
      fullName: 'Marie Dupont',
      phoneNumber: '+225 05 44 55 66 77',
      email: 'marie.dupont@email.com',
      createdAt: now.subtract(const Duration(days: 60)),
    );

    // Véhicule 2 : Moto Yamaha Crypton
    final vehicle2 = VehicleModel(
      id: uuid.v4(),
      clientId: client2.id,
      type: VehicleType.moto,
      registrationNumber: '5678-CD-02',
      brand: 'Yamaha',
      model: 'Crypton 110',
      fiscalPower: '4 CV',
    );

    // Souscription 2 (Expirée depuis 3 jours => Rouge)
    final startSub2 = now.subtract(const Duration(days: 34));
    final sub2 = SubscriptionModel(
      id: uuid.v4(),
      clientId: client2.id,
      vehicleId: vehicle2.id,
      periodicity: Periodicity.mensuelle,
      startDate: startSub2,
      endDate: DateCalculator.calculateEndDate(startSub2, Periodicity.mensuelle),
      amount: 15000.0,
      isPaid: false,
      notes: 'Relance effectuée hier',
      createdAt: startSub2,
    );

    // Client 3 : Paul Koffi
    final client3 = ClientModel(
      id: uuid.v4(),
      fullName: 'Paul Koffi',
      phoneNumber: '+225 01 23 45 67 89',
      createdAt: now.subtract(const Duration(days: 10)),
    );

    // Véhicule 3 : Voiture Hyundai Tucson
    final vehicle3 = VehicleModel(
      id: uuid.v4(),
      clientId: client3.id,
      type: VehicleType.voiture,
      registrationNumber: '9988-EF-03',
      brand: 'Hyundai',
      model: 'Tucson 2022',
      fiscalPower: '10 CV',
    );

    // Souscription 3 (Trimestrielle, valide encore 2 mois => Vert)
    final startSub3 = now.subtract(const Duration(days: 15));
    final sub3 = SubscriptionModel(
      id: uuid.v4(),
      clientId: client3.id,
      vehicleId: vehicle3.id,
      periodicity: Periodicity.trimestrielle,
      startDate: startSub3,
      endDate: DateCalculator.calculateEndDate(startSub3, Periodicity.trimestrielle),
      amount: 75000.0,
      isPaid: true,
      notes: 'Tous risques',
      createdAt: startSub3,
    );

    // Sauvegarde initiale
    await saveClient(client1);
    await saveClient(client2);
    await saveClient(client3);

    await saveVehicle(vehicle1);
    await saveVehicle(vehicle2);
    await saveVehicle(vehicle3);

    await saveSubscription(sub1);
    await saveSubscription(sub2);
    await saveSubscription(sub3);
  }

  @override
  Future<void> bulkRestoreData({
    required List<ClientModel> clients,
    required List<VehicleModel> vehicles,
    required List<SubscriptionModel> subscriptions,
    bool overwrite = false,
  }) async {
    if (overwrite) {
      await _prefs.setString(_clientsKey, jsonEncode(clients.map((c) => c.toJson()).toList()));
      await _prefs.setString(_vehiclesKey, jsonEncode(vehicles.map((v) => v.toJson()).toList()));
      await _prefs.setString(_subscriptionsKey, jsonEncode(subscriptions.map((s) => s.toJson()).toList()));
    } else {
      // Mode Fusion (Merge) : on ajoute ou met à jour
      final currentClients = await getClients();
      for (final client in clients) {
        final idx = currentClients.indexWhere((c) => c.id == client.id);
        if (idx >= 0) {
          currentClients[idx] = client;
        } else {
          currentClients.add(client);
        }
      }
      await _prefs.setString(_clientsKey, jsonEncode(currentClients.map((c) => c.toJson()).toList()));

      final currentVehicles = await getVehicles();
      for (final vehicle in vehicles) {
        final idx = currentVehicles.indexWhere((v) => v.id == vehicle.id);
        if (idx >= 0) {
          currentVehicles[idx] = vehicle;
        } else {
          currentVehicles.add(vehicle);
        }
      }
      await _prefs.setString(_vehiclesKey, jsonEncode(currentVehicles.map((v) => v.toJson()).toList()));

      final currentSubs = await getSubscriptions();
      for (final sub in subscriptions) {
        final idx = currentSubs.indexWhere((s) => s.id == sub.id);
        if (idx >= 0) {
          currentSubs[idx] = sub;
        } else {
          currentSubs.add(sub);
        }
      }
      await _prefs.setString(_subscriptionsKey, jsonEncode(currentSubs.map((s) => s.toJson()).toList()));
    }
  }
}

