import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/subscription_model.dart';

abstract class DatabaseService {
  Future<void> init();

  // Clients
  Future<List<ClientModel>> getClients();
  Future<ClientModel?> getClientById(String id);
  Future<void> saveClient(ClientModel client);
  Future<void> deleteClient(String id);

  // Véhicules
  Future<List<VehicleModel>> getVehicles();
  Future<VehicleModel?> getVehicleById(String id);
  Future<List<VehicleModel>> getVehiclesByClientId(String clientId);
  Future<void> saveVehicle(VehicleModel vehicle);
  Future<void> deleteVehicle(String id);

  // Souscriptions
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<SubscriptionModel?> getSubscriptionById(String id);
  Future<void> saveSubscription(SubscriptionModel subscription);
  Future<void> deleteSubscription(String id);

  // Restauration et Import en bloc
  Future<void> bulkRestoreData({
    required List<ClientModel> clients,
    required List<VehicleModel> vehicles,
    required List<SubscriptionModel> subscriptions,
    bool overwrite = false,
  });

  // Données de démonstration initiales si vide
  Future<void> seedInitialDataIfEmpty();
}
