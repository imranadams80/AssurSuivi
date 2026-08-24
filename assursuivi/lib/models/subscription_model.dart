import 'periodicity.dart';

class SubscriptionModel {
  final String id;
  final String clientId;
  final String vehicleId;
  final Periodicity periodicity;
  final DateTime startDate;
  final DateTime endDate;       // Date d'échéance calculée
  final double amount;          // Montant de la prime
  final bool isPaid;            // Statut du paiement
  final String? notes;
  final String? renewedFromId;  // Lien vers la souscription précédente
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.clientId,
    required this.vehicleId,
    required this.periodicity,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.isPaid = false,
    this.notes,
    this.renewedFromId,
    required this.createdAt,
  });

  SubscriptionModel copyWith({
    String? id,
    String? clientId,
    String? vehicleId,
    Periodicity? periodicity,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    bool? isPaid,
    String? notes,
    String? renewedFromId,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      vehicleId: vehicleId ?? this.vehicleId,
      periodicity: periodicity ?? this.periodicity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      renewedFromId: renewedFromId ?? this.renewedFromId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vehicleId': vehicleId,
      'periodicity': periodicity.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'isPaid': isPaid,
      'notes': notes,
      'renewedFromId': renewedFromId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      vehicleId: json['vehicleId'] as String,
      periodicity: Periodicity.fromString(json['periodicity'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
      notes: json['notes'] as String?,
      renewedFromId: json['renewedFromId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

