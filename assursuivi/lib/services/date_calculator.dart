import 'dart:math';
import '../models/periodicity.dart';
import '../models/urgency_status.dart';

class DateCalculator {
  /// Calcule la date d'échéance selon la règle d'assurance (date anniversaire - 1 jour)
  /// Gère automatiquement février (28/29 jours), les mois de 30/31 jours et les années bissextiles.
  static DateTime calculateEndDate(DateTime startDate, Periodicity periodicity) {
    final int monthsToAdd = periodicity.months;

    final int rawMonth = startDate.month + monthsToAdd;
    final int targetYear = startDate.year + ((rawMonth - 1) ~/ 12);
    final int targetMonth = ((rawMonth - 1) % 12) + 1;

    // Nombre de jours réels dans le mois cible (ex: 28 ou 29 en fév, 30 ou 31)
    final int maxDaysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    // Si la date de début dépasse le max du mois cible (ex: 31 Janvier vers Février)
    final int targetDay = min(startDate.day, maxDaysInTargetMonth);

    // Date anniversaire exacte
    final DateTime anniversaryDate = DateTime(
      targetYear,
      targetMonth,
      targetDay,
      startDate.hour,
      startDate.minute,
    );

    // Date d'échéance = Anniversaire - 1 jour
    return anniversaryDate.subtract(const Duration(days: 1));
  }

  /// Normalise une date à minuit (00:00:00) pour des comparaisons de jours fiables
  static DateTime toMidnight(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calcule le nombre de jours restants jusqu'à l'échéance
  static int getRemainingDays(DateTime endDate, [DateTime? fromDate]) {
    final DateTime today = toMidnight(fromDate ?? DateTime.now());
    final DateTime target = toMidnight(endDate);
    return target.difference(today).inDays;
  }

  /// Détermine le statut d'urgence
  /// - Expirée : jours restants < 0
  /// - Imminente : 0 <= jours restants <= 15
  /// - En cours : jours restants > 15
  static UrgencyStatus getUrgencyStatus(DateTime endDate, [DateTime? fromDate]) {
    final int days = getRemainingDays(endDate, fromDate);
    if (days < 0) {
      return UrgencyStatus.expired;
    } else if (days <= 15) {
      return UrgencyStatus.imminent;
    } else {
      return UrgencyStatus.active;
    }
  }

  /// Libellé convivial du délai restant
  static String formatRemainingDaysText(DateTime endDate, [DateTime? fromDate]) {
    final int days = getRemainingDays(endDate, fromDate);
    if (days < 0) {
      final int overdue = days.abs();
      return overdue == 1 ? 'Expirée depuis 1 jour' : 'Expirée depuis $overdue jours';
    } else if (days == 0) {
      return 'Expire aujourd\'hui !';
    } else if (days == 1) {
      return 'Expire demain !';
    } else {
      return 'Dans $days jours';
    }
  }

  /// Prépare la prochaine souscription lors d'un renouvellement
  /// La nouvelle date de début est le lendemain de l'échéance actuelle (soit la date anniversaire)
  static DateTime getNextRenewalStartDate(DateTime currentEndDate) {
    return currentEndDate.add(const Duration(days: 1));
  }
}

