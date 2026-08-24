import 'package:flutter/material.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/urgency_status.dart';
import '../services/notification_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/subscription_card.dart';
import '../widgets/monthly_summary_card.dart';
import 'subscription_form_screen.dart';
import 'subscription_detail_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final SubscriptionProvider provider;
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  const DashboardScreen({
    super.key,
    required this.provider,
    required this.authProvider,
    required this.themeProvider,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.provider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final provider = widget.provider;

        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final filteredList = provider.filteredSubscriptions;
        final selectedFilter = provider.selectedUrgencyFilter;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('AssurSuivi'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded),
                tooltip: 'Tester une notification',
                onPressed: () async {
                  await NotificationService().showInstantNotification(
                    title: '🔔 Test AssurSuivi',
                    body: 'Les notifications d\'échéances sont actives sur votre appareil !',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification test envoyée !'),
                        backgroundColor: Color(0xFF1E3A8A),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.people_alt_rounded),
                tooltip: 'Gestion des clients',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientsScreen(provider: provider),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Paramètres & Sécurité',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        authProvider: widget.authProvider,
                        subscriptionProvider: provider,
                        themeProvider: widget.themeProvider,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualiser',
                onPressed: () => provider.loadData(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: CustomScrollView(
              slivers: [
                // 1. Barre de recherche
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un client, une plaque, un véhicule...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // 2. Bilan mensuel & Total financier
                SliverToBoxAdapter(
                  child: MonthlySummaryCard(provider: provider),
                ),

                // 3. Cartes de statistiques (Filtres d'urgence cliquables)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        StatCard(
                          title: 'Toutes',
                          count: '${provider.totalSubscriptions}',
                          icon: Icons.list_alt_rounded,
                          color: const Color(0xFF1E3A8A),
                          backgroundColor: const Color(0xFFEFF6FF),
                          isSelected: selectedFilter == null,
                          onTap: () => provider.setUrgencyFilter(null),
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          title: 'Expirées',
                          count: '${provider.expiredCount}',
                          icon: Icons.warning_rounded,
                          color: const Color(0xFFDC2626),
                          backgroundColor: const Color(0xFFFFEBEE),
                          isSelected: selectedFilter == UrgencyStatus.expired,
                          onTap: () => provider.setUrgencyFilter(
                            selectedFilter == UrgencyStatus.expired ? null : UrgencyStatus.expired,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          title: '≤ 15 jours',
                          count: '${provider.imminentCount}',
                          icon: Icons.access_time_filled_rounded,
                          color: const Color(0xFFEA580C),
                          backgroundColor: const Color(0xFFFFF3E0),
                          isSelected: selectedFilter == UrgencyStatus.imminent,
                          onTap: () => provider.setUrgencyFilter(
                            selectedFilter == UrgencyStatus.imminent ? null : UrgencyStatus.imminent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          title: 'Valides',
                          count: '${provider.activeCount}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF16A34A),
                          backgroundColor: const Color(0xFFE8F5E9),
                          isSelected: selectedFilter == UrgencyStatus.active,
                          onTap: () => provider.setUrgencyFilter(
                            selectedFilter == UrgencyStatus.active ? null : UrgencyStatus.active,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Titre de la section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedFilter == null
                                ? 'Toutes les échéances (${filteredList.length})'
                                : 'Échéances : ${selectedFilter.label} (${filteredList.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedFilter != null || _searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              provider.setUrgencyFilter(null);
                            },
                            child: const Text('Réinitialiser'),
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Liste des souscriptions
                if (filteredList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune souscription trouvée',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ajoutez une souscription avec le bouton ci-dessous.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sub = filteredList[index];
                        final client = provider.getClient(sub.clientId);
                        final vehicle = provider.getVehicle(sub.vehicleId);

                        return SubscriptionCard(
                          subscription: sub,
                          client: client,
                          vehicle: vehicle,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionDetailScreen(
                                  subscriptionId: sub.id,
                                  provider: provider,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredList.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionFormScreen(provider: provider),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nouvelle souscription'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

