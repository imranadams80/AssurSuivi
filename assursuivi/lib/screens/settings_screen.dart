import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';
import '../services/cloud_sync_service.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final SubscriptionProvider subscriptionProvider;
  final ThemeProvider themeProvider;

  const SettingsScreen({
    super.key,
    required this.authProvider,
    required this.subscriptionProvider,
    required this.themeProvider,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final CloudSyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = CloudSyncService(
      dbService: widget.subscriptionProvider.dbService,
      authProvider: widget.authProvider,
    );
    _syncService.init();
  }

  Future<void> _exportBackup(BuildContext context) async {
    final backupService = BackupService(dbService: widget.subscriptionProvider.dbService);
    try {
      await backupService.exportDataBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final backupService = BackupService(dbService: widget.subscriptionProvider.dbService);
    try {
      await backupService.exportContractsCsv();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export CSV : $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    // 1. Demander le mode de restauration (Remplacement ou Fusion)
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore_page_rounded, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text('Restaurer une sauvegarde', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Comment souhaitez-vous intégrer les données du fichier de sauvegarde JSON ?\n\n'
          '• Remplacer : Efface la base actuelle et applique la sauvegarde.\n'
          '• Fusionner : Conserve vos données actuelles et ajoute les nouvelles.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Fusionner'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'overwrite'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            child: const Text('Remplacer tout'),
          ),
        ],
      ),
    );

    if (mode == null) return;

    final overwrite = (mode == 'overwrite');
    final backupService = BackupService(dbService: widget.subscriptionProvider.dbService);

    final result = await backupService.pickAndRestoreFile(overwrite: overwrite);

    if (!context.mounted) return;

    if (result.success) {
      await widget.subscriptionProvider.loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text(
            '${result.message}\n${result.clientsCount} clients, ${result.vehiclesCount} véhicules et ${result.subscriptionsCount} contrats restaurés avec succès.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(result.message),
        ),
      );
    }
  }

  Future<void> _triggerCloudSync(BuildContext context) async {
    final success = await _syncService.synchronize(force: true);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('Synchronisation Cloud réussie ! Toutes vos données sont à jour.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(_syncService.lastErrorMessage ?? 'Erreur lors de la synchronisation.'),
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter d\'AssurSuivi ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authProvider.logout();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.authProvider, widget.themeProvider, _syncService]),
      builder: (context, _) {
        final user = widget.authProvider.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Paramètres & Sécurité'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Profil Utilisateur
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark ? const Color(0xFF1E3A8A).withAlpha(80) : const Color(0xFFEFF6FF),
                      child: Text(
                        (user?.displayName.isNotEmpty == true) ? user!.displayName[0].toUpperCase() : 'A',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Gestionnaire AssurSuivi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'admin@assursuivi.com',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Section Apparence / Mode Sombre
              _buildSectionTitle('APPARENCE & THÈME'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_rounded, color: Color(0xFF3B82F6), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Mode d\'affichage',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Clair'),
                          icon: Icon(Icons.wb_sunny_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Sombre'),
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Système'),
                          icon: Icon(Icons.settings_suggest_rounded, size: 16),
                        ),
                      ],
                      selected: {widget.themeProvider.themeMode},
                      onSelectionChanged: (newSelection) {
                        widget.themeProvider.setThemeMode(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Section Sécurité & Biométrie
              _buildSectionTitle('SÉCURITÉ & ACCÈS'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: Color(0xFF3B82F6)),
                  title: const Text('Déverrouillage par empreinte digitale / PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Demande l\'empreinte à chaque ouverture', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  value: widget.authProvider.isBiometricEnabled,
                  onChanged: widget.authProvider.isBiometricAvailable
                      ? (val) => widget.authProvider.toggleBiometric(val)
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // 4. Section Synchronisation Cloud
              _buildSectionTitle('SYNCHRONISATION CLOUD & MULTI-APPAREILS'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A).withAlpha(80) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _syncService.status == SyncStatus.syncing
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded,
                            color: const Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sauvegarde Cloud continue',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _syncService.lastSyncTime != null
                                    ? 'Dernière synchro : ${AppFormatters.formatLongDate(_syncService.lastSyncTime!)}'
                                    : 'Synchronisation prête',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (_syncService.status == SyncStatus.syncing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.sync_rounded, color: Color(0xFF3B82F6)),
                            tooltip: 'Synchroniser maintenant',
                            onPressed: () => _triggerCloudSync(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Synchronisation automatique en arrière-plan', style: TextStyle(fontSize: 13)),
                      value: _syncService.isAutoSyncEnabled,
                      onChanged: (val) => _syncService.setAutoSyncEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Section Sauvegarde & Restauration Locale
              _buildSectionTitle('SAUVEGARDE & TRANSFERT DE FICHIER (JSON / CSV)'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withAlpha(80) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF3B82F6)),
                      ),
                      title: const Text('Exporter la sauvegarde complète (JSON)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Partager par WhatsApp, Email, Drive...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF3B82F6)),
                      onTap: () => _exportBackup(context),
                    ),
                    Divider(height: 1, indent: 60, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F766E).withAlpha(80) : const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restore_page_rounded, color: Color(0xFF0D9488)),
                      ),
                      title: const Text('Importer / Restaurer une sauvegarde (JSON)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Transférer vos données depuis un autre téléphone', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.file_open_rounded, size: 20, color: Color(0xFF0D9488)),
                      onTap: () => _importBackup(context),
                    ),
                    Divider(height: 1, indent: 60, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981)),
                      ),
                      title: const Text('Exporter le rapport des contrats (Excel / CSV)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tableau récapitulatif pour tableur Excel', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF10B981)),
                      onTap: () => _exportCsv(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Bouton de Déconnexion
              ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Se déconnecter de l\'application'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: Color(0xFF64748B),
      ),
    );
  }
}
