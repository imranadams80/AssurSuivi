import 'package:flutter_test/flutter_test.dart';
import 'package:assursuivi/models/periodicity.dart';
import 'package:assursuivi/models/urgency_status.dart';
import 'package:assursuivi/services/date_calculator.dart';

void main() {
  group('DateCalculator - Calcul des échéances', () {
    test('Mensuelle normale (15 Janvier 2026 -> 14 Février 2026)', () {
      final start = DateTime(2026, 1, 15);
      final end = DateCalculator.calculateEndDate(start, Periodicity.mensuelle);
      expect(end.year, 2026);
      expect(end.month, 2);
      expect(end.day, 14);
    });

    test('Mensuelle à partir du 1er Février 2026 non bissextile (-> 28 Février 2026)', () {
      final start = DateTime(2026, 2, 1);
      final end = DateCalculator.calculateEndDate(start, Periodicity.mensuelle);
      expect(end.year, 2026);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('Mensuelle à partir du 1er Février 2028 bissextile (-> 29 Février 2028)', () {
      final start = DateTime(2028, 2, 1);
      final end = DateCalculator.calculateEndDate(start, Periodicity.mensuelle);
      expect(end.year, 2028);
      expect(end.month, 2);
      expect(end.day, 29);
    });

    test('Mensuelle à partir du 31 Janvier vers Février 2026 (-> 27 Février 2026)', () {
      final start = DateTime(2026, 1, 31);
      final end = DateCalculator.calculateEndDate(start, Periodicity.mensuelle);
      expect(end.year, 2026);
      expect(end.month, 2);
      expect(end.day, 27);
    });

    test('Bimensuelle (1er Janvier 2026 -> 28 Février 2026)', () {
      final start = DateTime(2026, 1, 1);
      final end = DateCalculator.calculateEndDate(start, Periodicity.bimensuelle);
      expect(end.year, 2026);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('Trimestrielle (10 Février 2026 -> 09 Mai 2026)', () {
      final start = DateTime(2026, 2, 10);
      final end = DateCalculator.calculateEndDate(start, Periodicity.trimestrielle);
      expect(end.year, 2026);
      expect(end.month, 5);
      expect(end.day, 9);
    });

    test('Annuelle (20 Février 2026 -> 19 Février 2027)', () {
      final start = DateTime(2026, 2, 20);
      final end = DateCalculator.calculateEndDate(start, Periodicity.annuelle);
      expect(end.year, 2027);
      expect(end.month, 2);
      expect(end.day, 19);
    });
  });

  group('DateCalculator - Calcul de l\'urgence', () {
    final today = DateTime(2026, 8, 23);

    test('Échéance passée = Expirée (Rouge)', () {
      final end = DateTime(2026, 8, 20);
      expect(DateCalculator.getUrgencyStatus(end, today), UrgencyStatus.expired);
      expect(DateCalculator.getRemainingDays(end, today), -3);
    });

    test('Échéance dans 5 jours = Imminente (Orange)', () {
      final end = DateTime(2026, 8, 28);
      expect(DateCalculator.getUrgencyStatus(end, today), UrgencyStatus.imminent);
      expect(DateCalculator.getRemainingDays(end, today), 5);
    });

    test('Échéance dans 25 jours = En cours (Vert)', () {
      final end = DateTime(2026, 9, 17);
      expect(DateCalculator.getUrgencyStatus(end, today), UrgencyStatus.active);
      expect(DateCalculator.getRemainingDays(end, today), 25);
    });
  });
}

