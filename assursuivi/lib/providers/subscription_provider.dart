import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/subscription_model.dart';
import '../models/urgency_status.dart';
import '../models/periodicity.dart';
import '../services/database_service.dart';
import '../services/date_calculator.dart';
import '../services/notification_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final DatabaseService dbService;
  final NotificationService _notificationService = NotificationService();

  List<SubscriptionModel> _subscriptions = [];
  List<ClientModel> _clients = [];
  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UrgencyStatus? _selectedUrgencyFilter;
  DateTime _selectedStatsMonth = DateTime.now();

  SubscriptionProvider({required this.dbService});

  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<ClientModel> get clients => _clients;
  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  UrgencyStatus? get selectedUrgencyFilter => _selectedUrgencyFilter;
  DateTime get selectedStatsMonth => _selectedStatsMonth;

  // --- STATISTIQUES GLOBALES ---
  int get totalSubscriptions => _subscriptions.length;

  int get expiredCount => _subscriptions.where((s) =>
      DateCalculator.getUrgencyStatus(s.endDate) == UrgencyStatus.expired).length;

  int get imminentCount => _subscriptions.where((s) =>
      DateCalculator.getUrgencyStatus(s.endDate) == UrgencyStatus.imminent).length;

  int get activeCount => _subscriptions.where((s) =>
      DateCalculator.getUrgencyStatus(s.endDate) == UrgencyStatus.active).length;

  int get unpaidCount => _subscriptions.where((s) => !s.isPaid).length;

  double get totalRevenue => _subscriptions.fold(0.0, (sum, s) => sum + s.amount);

  // --- STATISTIQUES MENSUELLES (MOIS SÉLECTIONNÉ) ---
  List<SubscriptionModel> get monthSubscriptions {
    return _subscriptions.where((s) =>
        s.startDate.year == _selectedStatsMonth.year &&
        s.startDate.month == _selectedStatsMonth.month).toList();
  }

  int get monthSubscriptionsCount => monthSubscriptions.length;

  double get monthTotalAmount =>
      monthSubscriptions.fold(0.0, (sum, s) => sum + s.amount);

  double get monthPaidAmount => monthSubscriptions
      .where((s) => s.isPaid)
      .fold(0.0, (sum, s) => sum + s.amount);

  double get monthUnpaidAmount => monthSubscriptions
      .where((s) => !s.isPaid)
      .fold(0.0, (sum, s) => sum + s.amount);

  double get monthPaidPercentage =>
      monthTotalAmount > 0 ? (monthPaidAmount / monthTotalAmount) : 0.0;

  void nextStatsMonth() {
    _selectedStatsMonth = DateTime(
      _selectedStatsMonth.year,
      _selectedStatsMonth.month + 1,
      1,
    );
    notifyListeners();
  }

  void previousStatsMonth() {
    _selectedStatsMonth = DateTime(
      _selectedStatsMonth.year,
      _selectedStatsMonth.month - 1,
      1,
    );
    notifyListeners();
  }

  void resetStatsMonth() {
    _selectedStatsMonth = DateTime.now();
    notifyListeners();
  }

  // --- SOUSCRIPTIONS FILTRÉES & TRIÉES PAR URGENCE ---
  List<SubscriptionModel> get filteredSubscriptions {
    return _subscriptions.where((sub) {
      final client = getClient(sub.clientId);
      final vehicle = getVehicle(sub.vehicleId);
      final urgency = DateCalculator.getUrgencyStatus(sub.endDate);

      // Filtre d'urgence
      if (_selectedUrgencyFilter != null && urgency != _selectedUrgencyFilter) {
        return false;
      }

      // Filtre de recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final clientName = client?.fullName.toLowerCase() ?? '';
        final clientPhone = client?.phoneNumber.toLowerCase() ?? '';
        final regNum = vehicle?.registrationNumber.toLowerCase() ?? '';
        final brand = vehicle?.brand.toLowerCase() ?? '';
        final model = vehicle?.model.toLowerCase() ?? '';

        final matches = clientName.contains(query) ||
            clientPhone.contains(query) ||
            regNum.contains(query) ||
            brand.contains(query) ||
            model.contains(query);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  ClientModel? getClient(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  VehicleModel? getVehicle(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- ACTIONS ---
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await dbService.init();
    await _notificationService.init();

    _clients = await dbService.getClients();
    _vehicles = await dbService.getVehicles();
    final rawSubs = await dbService.getSubscriptions();

    // Tri par urgence :
    // 1. Expirées en premier (les plus urgentes)
    // 2. Imminentes (classées par échéance la plus proche)
    // 3. Valides (classées par date d'échéance croissante)
    rawSubs.sort((a, b) {
      final daysA = DateCalculator.getRemainingDays(a.endDate);
      final daysB = DateCalculator.getRemainingDays(b.endDate);
      return daysA.compareTo(daysB);
    });

    _subscriptions = rawSubs;
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setUrgencyFilter(UrgencyStatus? status) {
    _selectedUrgencyFilter = status;
    notifyListeners();
  }

  /// Création ou mise à jour complète d'une souscription (avec son client et véhicule)
  Future<void> createOrUpdateSubscription({
    required ClientModel client,
    required VehicleModel vehicle,
    required SubscriptionModel subscription,
  }) async {
    await dbService.saveClient(client);
    await dbService.saveVehicle(vehicle);
    await dbService.saveSubscription(subscription);

    // Planification des alertes
    await _notificationService.scheduleSubscriptionAlerts(
      subscription: subscription,
      vehicle: vehicle,
      client: client,
    );

    await loadData();
  }

  /// Renouvellement en 1 clic
  Future<SubscriptionModel> renewSubscription(
    SubscriptionModel oldSub, {
    Periodicity? newPeriodicity,
    double? newAmount,
  }) async {
    const uuid = Uuid();
    final periodicity = newPeriodicity ?? oldSub.periodicity;
    final amount = newAmount ?? oldSub.amount;

    final newStartDate = DateCalculator.getNextRenewalStartDate(oldSub.endDate);
    final newEndDate = DateCalculator.calculateEndDate(newStartDate, periodicity);

    final newSub = SubscriptionModel(
      id: uuid.v4(),
      clientId: oldSub.clientId,
      vehicleId: oldSub.vehicleId,
      periodicity: periodicity,
      startDate: newStartDate,
      endDate: newEndDate,
      amount: amount,
      isPaid: false,
      notes: 'Renouvellement de la souscription précédente',
      renewedFromId: oldSub.id,
      createdAt: DateTime.now(),
    );

    final client = getClient(oldSub.clientId);
    final vehicle = getVehicle(oldSub.vehicleId);

    await dbService.saveSubscription(newSub);

    if (client != null && vehicle != null) {
      await _notificationService.scheduleSubscriptionAlerts(
        subscription: newSub,
        vehicle: vehicle,
        client: client,
      );
    }

    await loadData();
    return newSub;
  }

  /// Basculer l'état payé / non payé
  Future<void> togglePaymentStatus(SubscriptionModel sub) async {
    final updated = sub.copyWith(isPaid: !sub.isPaid);
    await dbService.saveSubscription(updated);
    await loadData();
  }

  /// Supprimer une souscription
  Future<void> deleteSubscription(String id) async {
    await _notificationService.cancelSubscriptionAlerts(id);
    await dbService.deleteSubscription(id);
    await loadData();
  }

  /// Supprimer un client et ses véhicules/souscriptions
  Future<void> deleteClient(String id) async {
    await dbService.deleteClient(id);
    await loadData();
  }
}

