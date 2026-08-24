import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';
import '../models/periodicity.dart';
import '../models/vehicle_type.dart';
import '../models/subscription_model.dart';
import '../utils/formatters.dart';
import '../services/date_calculator.dart';
import '../widgets/urgency_badge.dart';
import 'subscription_form_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final String subscriptionId;
  final SubscriptionProvider provider;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    required this.provider,
  });

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de composer le numéro.')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _sendSms(BuildContext context, String phoneNumber, String message) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '');
    final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir l\'application SMS.')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _showRenewalDialog(BuildContext context, SubscriptionModel sub) async {
    final nextStartDate = DateCalculator.getNextRenewalStartDate(sub.endDate);
    Periodicity selectedPeriodicity = sub.periodicity;
    DateTime calculatedEnd = DateCalculator.calculateEndDate(nextStartDate, selectedPeriodicity);
    final amountController = TextEditingController(text: sub.amount.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.autorenew_rounded, color: Color(0xFF1E3A8A)),
                  SizedBox(width: 8),
                  Text('Renouveler le contrat'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Une nouvelle période sera créée automatiquement à la suite de l\'actuelle.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<Periodicity>(
                    initialValue: selectedPeriodicity,
                    decoration: const InputDecoration(labelText: 'Périodicité'),
                    items: Periodicity.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        setState(() {
                          selectedPeriodicity = p;
                          calculatedEnd = DateCalculator.calculateEndDate(nextStartDate, p);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouvelle date de début : ${AppFormatters.formatDate(nextStartDate)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Nouvelle date d\'échéance : ${AppFormatters.formatDate(calculatedEnd)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant (FCFA)',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newAmount = double.tryParse(amountController.text.replaceAll(' ', '')) ?? sub.amount;
                    Navigator.pop(ctx);

                    final newSub = await provider.renewSubscription(
                      sub,
                      newPeriodicity: selectedPeriodicity,
                      newAmount: newAmount,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Souscription renouvelée jusqu\'au ${AppFormatters.formatDate(newSub.endDate)} !'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                      Navigator.pop(context); // Retourne au dashboard avec les nouvelles données
                    }
                  },
                  child: const Text('Confirmer le renouvellement'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, SubscriptionModel sub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette souscription ?'),
        content: const Text('Cette action est irréversible. Les alertes associées seront également annulées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteSubscription(sub.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Souscription supprimée.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final sub = provider.subscriptions.where((s) => s.id == subscriptionId).firstOrNull;

        if (sub == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détail')),
            body: const Center(child: Text('Souscription introuvable ou supprimée.')),
          );
        }

        final client = provider.getClient(sub.clientId);
        final vehicle = provider.getVehicle(sub.vehicleId);
        final isMoto = vehicle?.type == VehicleType.moto;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détail de la souscription'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Modifier',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionFormScreen(
                        provider: provider,
                        existingSubscription: sub,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDelete(context, sub),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Statut d'échéance principal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statut d\'échéance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        UrgencyBadge(endDate: sub.endDate),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Date de début', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatDate(sub.startDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8)),
                        Column(
                          children: [
                            const Text('Date d\'échéance', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatDate(sub.endDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Fiche Véhicule
              _buildCard(
                context: context,
                title: 'Véhicule assuré',
                icon: isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Type :', isMoto ? 'Moto / Deux-roues' : 'Voiture'),
                    _buildDetailRow(context, 'Immatriculation :', vehicle?.registrationNumber ?? '-'),
                    _buildDetailRow(context, 'Marque & Modèle :', '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''}'),
                    if (vehicle?.fiscalPower != null && vehicle!.fiscalPower!.isNotEmpty)
                      _buildDetailRow(context, 'Puissance fiscale :', vehicle.fiscalPower!),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Fiche Client & Contact direct
              _buildCard(
                context: context,
                title: 'Client souscripteur',
                icon: Icons.person_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Nom complet :', client?.fullName ?? '-'),
                    _buildDetailRow(context, 'Téléphone :', client?.phoneNumber ?? '-'),
                    if (client?.email != null && client!.email!.isNotEmpty)
                      _buildDetailRow(context, 'Email :', client.email!),
                    const SizedBox(height: 12),
                    if (client != null && client.phoneNumber.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(context, client.phoneNumber),
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 18),
                              label: const Text('Appeler', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF16A34A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final message = 'Bonjour ${client.fullName}, nous vous informons que votre assurance pour le véhicule ${vehicle?.registrationNumber ?? ''} expire le ${AppFormatters.formatDate(sub.endDate)}. Pensez à la renouveler dès maintenant.';
                                _sendSms(context, client.phoneNumber, message);
                              },
                              icon: const Icon(Icons.message_rounded, size: 18),
                              label: const Text('Envoyer SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Détails Financiers & Paiement
              _buildCard(
                context: context,
                title: 'Modalités de la souscription',
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _buildDetailRow(context, 'Périodicité :', sub.periodicity.label),
                    _buildDetailRow(context, 'Montant de la prime :', AppFormatters.formatAmount(sub.amount)),
                    if (sub.notes != null && sub.notes!.isNotEmpty)
                      _buildDetailRow(context, 'Formule / Notes :', sub.notes!),
                    Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Statut du règlement :', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            Text(
                              sub.isPaid ? 'Règlement effectué' : 'En attente de paiement',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: sub.isPaid ? const Color(0xFF15803D) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: sub.isPaid,
                          activeThumbColor: const Color(0xFF16A34A),
                          onChanged: (_) => provider.togglePaymentStatus(sub),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Bouton d'action principal : RENOUVELER
              ElevatedButton.icon(
                onPressed: () => _showRenewalDialog(context, sub),
                icon: const Icon(Icons.autorenew_rounded, size: 22),
                label: const Text('Renouveler cette souscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
