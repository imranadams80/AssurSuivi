import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../providers/subscription_provider.dart';
import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type.dart';
import '../models/subscription_model.dart';
import '../models/periodicity.dart';
import '../services/date_calculator.dart';
import '../utils/formatters.dart';

class SubscriptionFormScreen extends StatefulWidget {
  final SubscriptionProvider provider;
  final SubscriptionModel? existingSubscription;

  const SubscriptionFormScreen({
    super.key,
    required this.provider,
    this.existingSubscription,
  });

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Client
  String? _selectedClientId;
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();

  // Véhicule
  VehicleType _vehicleType = VehicleType.voiture;
  final _regNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _fiscalPowerController = TextEditingController();

  // Souscription
  Periodicity _periodicity = Periodicity.mensuelle;
  DateTime _startDate = DateTime.now();
  late DateTime _calculatedEndDate;
  final _amountController = TextEditingController();
  bool _isPaid = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recalculateEndDate();

    if (widget.existingSubscription != null) {
      final sub = widget.existingSubscription!;
      _selectedClientId = sub.clientId;
      final client = widget.provider.getClient(sub.clientId);
      if (client != null) {
        _clientNameController.text = client.fullName;
        _clientPhoneController.text = client.phoneNumber;
        _clientEmailController.text = client.email ?? '';
      }

      final vehicle = widget.provider.getVehicle(sub.vehicleId);
      if (vehicle != null) {
        _vehicleType = vehicle.type;
        _regNumberController.text = vehicle.registrationNumber;
        _brandController.text = vehicle.brand;
        _modelController.text = vehicle.model;
        _fiscalPowerController.text = vehicle.fiscalPower ?? '';
      }

      _periodicity = sub.periodicity;
      _startDate = sub.startDate;
      _calculatedEndDate = sub.endDate;
      _amountController.text = sub.amount.toStringAsFixed(0);
      _isPaid = sub.isPaid;
      _notesController.text = sub.notes ?? '';
    }
  }

  void _recalculateEndDate() {
    setState(() {
      _calculatedEndDate = DateCalculator.calculateEndDate(_startDate, _periodicity);
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _regNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _fiscalPowerController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'SÉLECTIONNER LA DATE DE DÉBUT',
      cancelText: 'ANNULER',
      confirmText: 'VALIDER',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _recalculateEndDate();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    const uuid = Uuid();
    final now = DateTime.now();

    // 1. Client
    final clientId = _selectedClientId ?? uuid.v4();
    final client = ClientModel(
      id: clientId,
      fullName: _clientNameController.text.trim(),
      phoneNumber: _clientPhoneController.text.trim(),
      email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
      createdAt: now,
    );

    // 2. Véhicule
    final vehicleId = widget.existingSubscription?.vehicleId ?? uuid.v4();
    final vehicle = VehicleModel(
      id: vehicleId,
      clientId: clientId,
      type: _vehicleType,
      registrationNumber: _regNumberController.text.trim().toUpperCase(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      fiscalPower: _fiscalPowerController.text.trim().isEmpty ? null : _fiscalPowerController.text.trim(),
    );

    // 3. Souscription
    final subId = widget.existingSubscription?.id ?? uuid.v4();
    final amount = double.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0.0;

    final subscription = SubscriptionModel(
      id: subId,
      clientId: clientId,
      vehicleId: vehicleId,
      periodicity: _periodicity,
      startDate: _startDate,
      endDate: _calculatedEndDate,
      amount: amount,
      isPaid: _isPaid,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.existingSubscription?.createdAt ?? now,
    );

    await widget.provider.createOrUpdateSubscription(
      client: client,
      vehicle: vehicle,
      subscription: subscription,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingSubscription != null
                ? 'Souscription mise à jour avec succès !'
                : 'Nouvelle souscription enregistrée avec succès !',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSubscription != null;
    final clients = widget.provider.clients;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la souscription' : 'Nouvelle souscription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- SECTION 1 : CLIENT ---
            _buildSectionHeader('1. Informations du Client', Icons.person_rounded),
            const SizedBox(height: 12),

            if (!isEditing && clients.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedClientId,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner un client existant',
                  prefixIcon: Icon(Icons.group_rounded),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('+ Nouveau client'),
                  ),
                  ...clients.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.fullName} (${c.phoneNumber})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedClientId = val;
                    if (val != null) {
                      final c = widget.provider.getClient(val);
                      if (c != null) {
                        _clientNameController.text = c.fullName;
                        _clientPhoneController.text = c.phoneNumber;
                        _clientEmailController.text = c.email ?? '';
                      }
                    } else {
                      _clientNameController.clear();
                      _clientPhoneController.clear();
                      _clientEmailController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom et Prénoms *',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone *',
                prefixIcon: Icon(Icons.phone_rounded),
                hintText: '+225 07 00 00 00 00',
              ),
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.trim().isEmpty ? 'Le téléphone est requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Email (optionnel)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            // --- SECTION 2 : VÉHICULE ---
            _buildSectionHeader('2. Caractéristiques du Véhicule', Icons.directions_car_rounded),
            const SizedBox(height: 12),

            // Type Voiture / Moto
            SegmentedButton<VehicleType>(
              segments: const [
                ButtonSegment(
                  value: VehicleType.voiture,
                  label: Text('Voiture'),
                  icon: Icon(Icons.directions_car_rounded),
                ),
                ButtonSegment(
                  value: VehicleType.moto,
                  label: Text('Moto / 2-roues'),
                  icon: Icon(Icons.two_wheeler_rounded),
                ),
              ],
              selected: {_vehicleType},
              onSelectionChanged: (newVal) {
                setState(() => _vehicleType = newVal.first);
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _regNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Immatriculation *',
                      prefixIcon: Icon(Icons.pin_rounded),
                      hintText: '1234-AB-01',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'La plaque est requise' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _fiscalPowerController,
                    decoration: const InputDecoration(
                      labelText: 'Puissance',
                      hintText: '7 CV',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      hintText: 'Toyota, Yamaha...',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle *',
                      hintText: 'Corolla, Crypton...',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- SECTION 3 : SOUSCRIPTION & CALCUL DE L'ÉCHÉANCE ---
            _buildSectionHeader('3. Souscription & Échéance', Icons.calendar_month_rounded),
            const SizedBox(height: 12),

            DropdownButtonFormField<Periodicity>(
              isExpanded: true,
              initialValue: _periodicity,
              decoration: const InputDecoration(
                labelText: 'Périodicité de l\'assurance *',
                prefixIcon: Icon(Icons.timelapse_rounded),
              ),
              items: Periodicity.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _periodicity = val;
                    _recalculateEndDate();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Sélecteur de date de début
            InkWell(
              onTap: _selectStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date de début :', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              AppFormatters.formatDate(_startDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF1E3A8A),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Encadré de prévisualisation de l'échéance calculée
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E3A8A).withAlpha(40)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF93C5FD),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date d\'échéance calculée automatiquement :',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatDate(_calculatedEndDate),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF1E3A8A),
                          ),
                        ),
                        const Text(
                          'Règle d\'assurance : Date de fin à périodicité - 1 jour',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Montant de la prime
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant de la prime (FCFA) *',
                prefixIcon: Icon(Icons.payments_rounded),
                hintText: '25000',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),

            // Statut du règlement (Payé / Non payé)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                        color: _isPaid ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPaid ? 'Prime payée par le client' : 'En attente de paiement',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isPaid ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isPaid,
                    activeThumbColor: const Color(0xFF16A34A),
                    onChanged: (val) => setState(() => _isPaid = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Formule (ex: Tous risques, Tiers...)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Bouton Enregistrer
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(isEditing ? 'Mettre à jour' : 'Enregistrer la souscription'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

