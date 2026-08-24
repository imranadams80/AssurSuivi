import 'vehicle_type.dart';

class VehicleModel {
  final String id;
  final String clientId;
  final VehicleType type;
  final String registrationNumber; // Plaque d'immatriculation
  final String brand;              // Marque (ex: Toyota, Yamaha)
  final String model;              // Modèle (ex: Corolla, Crypton)
  final String? fiscalPower;       // Puissance fiscale (ex: 7 CV)
  final DateTime? firstRegistrationDate; // Date 1ère mise en circulation
  final String? notes;

  VehicleModel({
    required this.id,
    required this.clientId,
    required this.type,
    required this.registrationNumber,
    required this.brand,
    required this.model,
    this.fiscalPower,
    this.firstRegistrationDate,
    this.notes,
  });

  String get displayName => '$brand $model ($registrationNumber)';

  VehicleModel copyWith({
    String? id,
    String? clientId,
    VehicleType? type,
    String? registrationNumber,
    String? brand,
    String? model,
    String? fiscalPower,
    DateTime? firstRegistrationDate,
    String? notes,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      fiscalPower: fiscalPower ?? this.fiscalPower,
      firstRegistrationDate: firstRegistrationDate ?? this.firstRegistrationDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'type': type.name,
      'registrationNumber': registrationNumber,
      'brand': brand,
      'model': model,
      'fiscalPower': fiscalPower,
      'firstRegistrationDate': firstRegistrationDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      type: VehicleType.fromString(json['type'] as String),
      registrationNumber: json['registrationNumber'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      fiscalPower: json['fiscalPower'] as String?,
      firstRegistrationDate: json['firstRegistrationDate'] != null
          ? DateTime.parse(json['firstRegistrationDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

