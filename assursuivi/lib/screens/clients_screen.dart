import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';
import '../models/client_model.dart';
import '../models/vehicle_type.dart';

class ClientsScreen extends StatelessWidget {
  final SubscriptionProvider provider;

  const ClientsScreen({super.key, required this.provider});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _confirmDeleteClient(BuildContext context, ClientModel client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${client.fullName} ?'),
        content: const Text(
          'Attention : Tous les véhicules et souscriptions liés à ce client seront également supprimés.',
        ),
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
      await provider.deleteClient(client.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final clients = provider.clients;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Annuaire des Clients'),
          ),
          body: clients.isEmpty
              ? const Center(
                  child: Text('Aucun client enregistré pour le moment.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final vehicles = provider.vehicles.where((v) => v.clientId == client.id).toList();
                    final subs = provider.subscriptions.where((s) => s.clientId == client.id).toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isDark ? const Color(0xFF1E3A8A).withAlpha(80) : const Color(0xFFEFF6FF),
                                      child: Text(
                                        client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.fullName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          client.phoneNumber,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A)),
                                      tooltip: 'Appeler',
                                      onPressed: () => _makeCall(client.phoneNumber),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _confirmDeleteClient(context, client),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            Text(
                              'Véhicules (${vehicles.length}) :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: vehicles.map((v) {
                                final isMoto = v.type == VehicleType.moto;
                                return Chip(
                                  avatar: Icon(
                                    isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                                  ),
                                  label: Text(
                                    '${v.brand} ${v.model} (${v.registrationNumber})',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Souscriptions actives : ${subs.length}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
