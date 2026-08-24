import 'package:flutter/material.dart';

enum UrgencyStatus {
  expired,      // Rouge : Date d'échéance dépassée
  imminent,     // Orange : Moins ou égal à 15 jours
  active;       // Vert : Plus de 15 jours

  String get label {
    switch (this) {
      case UrgencyStatus.expired:
        return 'Expirée';
      case UrgencyStatus.imminent:
        return 'Échéance proche';
      case UrgencyStatus.active:
        return 'En cours';
    }
  }

  Color get color {
    switch (this) {
      case UrgencyStatus.expired:
        return const Color(0xFFD32F2F); // Rouge
      case UrgencyStatus.imminent:
        return const Color(0xFFF57C00); // Orange
      case UrgencyStatus.active:
        return const Color(0xFF388E3C); // Vert
    }
  }

  Color get backgroundColor {
    switch (this) {
      case UrgencyStatus.expired:
        return const Color(0xFFFFEBEE);
      case UrgencyStatus.imminent:
        return const Color(0xFFFFF3E0);
      case UrgencyStatus.active:
        return const Color(0xFFE8F5E9);
    }
  }
}

