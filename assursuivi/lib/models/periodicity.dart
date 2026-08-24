enum Periodicity {
  mensuelle,
  bimensuelle,
  trimestrielle,
  semestrielle,
  annuelle;

  int get months {
    switch (this) {
      case Periodicity.mensuelle:
        return 1;
      case Periodicity.bimensuelle:
        return 2;
      case Periodicity.trimestrielle:
        return 3;
      case Periodicity.semestrielle:
        return 6;
      case Periodicity.annuelle:
        return 12;
    }
  }

  String get label {
    switch (this) {
      case Periodicity.mensuelle:
        return 'Mensuelle (1 mois)';
      case Periodicity.bimensuelle:
        return 'Bimensuelle (2 mois)';
      case Periodicity.trimestrielle:
        return 'Trimestrielle (3 mois)';
      case Periodicity.semestrielle:
        return 'Semestrielle (6 mois)';
      case Periodicity.annuelle:
        return 'Annuelle (1 an)';
    }
  }

  String get shortLabel {
    switch (this) {
      case Periodicity.mensuelle:
        return '1 mois';
      case Periodicity.bimensuelle:
        return '2 mois';
      case Periodicity.trimestrielle:
        return '3 mois';
      case Periodicity.semestrielle:
        return '6 mois';
      case Periodicity.annuelle:
        return '1 an';
    }
  }

  static Periodicity fromString(String value) {
    return Periodicity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Periodicity.mensuelle,
    );
  }
}

