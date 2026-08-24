import 'package:flutter/material.dart';
import '../models/urgency_status.dart';
import '../services/date_calculator.dart';

class UrgencyBadge extends StatelessWidget {
  final DateTime endDate;
  final bool showDaysRemaining;

  const UrgencyBadge({
    super.key,
    required this.endDate,
    this.showDaysRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = DateCalculator.getUrgencyStatus(endDate);
    final daysText = DateCalculator.formatRemainingDaysText(endDate);

    IconData icon;
    switch (status) {
      case UrgencyStatus.expired:
        icon = Icons.warning_rounded;
        break;
      case UrgencyStatus.imminent:
        icon = Icons.access_time_filled_rounded;
        break;
      case UrgencyStatus.active:
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: status.color,
          ),
          const SizedBox(width: 5),
          Text(
            showDaysRemaining ? daysText : status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

