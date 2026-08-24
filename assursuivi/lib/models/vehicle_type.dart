enum VehicleType {
  voiture,
  moto;

  String get label {
    switch (this) {
      case VehicleType.voiture:
        return 'Voiture / Véhicule';
      case VehicleType.moto:
        return 'Moto / Deux-roues';
    }
  }

  String get iconAsset {
    switch (this) {
      case VehicleType.voiture:
        return 'directions_car';
      case VehicleType.moto:
        return 'two_wheeler';
    }
  }

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VehicleType.voiture,
    );
  }
}

