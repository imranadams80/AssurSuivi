import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type.dart';
import '../utils/formatters.dart';
import 'urgency_badge.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionModel subscription;
  final ClientModel? client;
  final VehicleModel? vehicle;
  final VoidCallback onTap;
  final ValueChanged<bool>? onTogglePaid;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.client,
    required this.vehicle,
    required this.onTap,
    this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMoto = vehicle?.type == VehicleType.moto;
    final vehicleIcon = isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded;
    final vehicleTitle = vehicle != null ? '${vehicle!.brand} ${vehicle!.model}' : 'Véhicule';
    final registration = vehicle?.registrationNumber ?? 'Sans plaque';
    final clientName = client?.fullName ?? 'Client inconnu';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : Icône, Véhicule & Plaque, Urgency Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A).withAlpha(60) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vehicleIcon,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            registration,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  UrgencyBadge(endDate: subscription.endDate),
                ],
              ),
              Divider(
                height: 24,
                thickness: 0.8,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),

              // Ligne centrale : Info Client & Périodicité
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        clientName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subscription.periodicity.shortLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Ligne inférieure : Dates, Montant & Badge Payé
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Échéance :',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        AppFormatters.formatDate(subscription.endDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatAmount(subscription.amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: subscription.isPaid
                              ? (isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF7F1D1D).withAlpha(80) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subscription.isPaid ? 'Payé' : 'Non payé',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: subscription.isPaid
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

