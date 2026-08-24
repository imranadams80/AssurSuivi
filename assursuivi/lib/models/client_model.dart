class ClientModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  ClientModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.notes,
    required this.createdAt,
  });

  ClientModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? notes,
    DateTime? createdAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

