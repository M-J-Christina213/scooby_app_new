// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/controllers/medical_records_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:scooby_app_new/services/medical_record_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String bookingId;
  final String providerEmail;
  final String userId;

  const AppointmentDetailScreen({
    super.key,
    required this.bookingId,
    required this.providerEmail,
    required this.userId,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? booking;
  Map<String, dynamic>? pet;
  bool loading = true;

  late final TabController _tabController;
  MedicalRecordsController? _controller;

  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _foodController;
  late TextEditingController _moodController;
  late TextEditingController _healthController;
  late TextEditingController _descController;

  final _df = DateFormat('yyyy-MM-dd');
  File? _imageFile;
  String? _uploadedImageUrl;

  // who creates/updates records
  String? _createdByName;

  // provider role -> controls edit ability
  String? _providerRole;
  bool get _canEdit => (_providerRole?.toLowerCase() == 'veterinarian');

  // Edit modes
  bool _petEditMode = false;
  final Map<String, bool> _vaccEditing = {};
  final Map<String, bool> _checkEditing = {};
  final Map<String, bool> _rxEditing = {};

  // Theme
  static const Color _primary = Color(0xFF6C4CCE);
  static const Color _primaryDark = Color(0xFF4B2DBE);
  static const Color _primaryLight = Color(0xFFEDE7FF);
  static const Color _cardSurface = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _fetchProviderMeta(),
      fetchBooking(),
    ]);
  }

  Future<void> _fetchProviderMeta() async {
    try {
      final row = await supabase
          .from('service_providers')
          .select('name, role')
          .eq('email', widget.providerEmail)
          .maybeSingle();

      setState(() {
        _createdByName = (row?['name'] as String?)?.trim();
        _createdByName ??= widget.providerEmail; // fallback
        _providerRole = (row?['role'] as String?)?.trim();
      });
    } catch (_) {
      setState(() {
        _createdByName = widget.providerEmail;
        _providerRole = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller?.removeListener(_onControllerChanged);
    try {
      _weightController.dispose();
      _heightController.dispose();
      _foodController.dispose();
      _moodController.dispose();
      _healthController.dispose();
      _descController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> fetchBooking() async {
    setState(() => loading = true);
    try {
      final resp = await supabase
          .from('bookings')
          .select('id, owner_name, owner_email, owner_phone, date, time, pets(*)')
          .eq('id', widget.bookingId)
          .maybeSingle();

      if (resp != null) {
        booking = Map<String, dynamic>.from(resp);

        if (booking!['pets'] != null) {
          if (booking!['pets'] is List && (booking!['pets'] as List).isNotEmpty) {
            pet = Map<String, dynamic>.from((booking!['pets'] as List)[0]);
          } else if (booking!['pets'] is Map<String, dynamic>) {
            pet = Map<String, dynamic>.from(booking!['pets']);
          }

          _weightController = TextEditingController(text: pet!['weight']?.toString() ?? '');
          _heightController = TextEditingController(text: pet!['height']?.toString() ?? '');
          _foodController = TextEditingController(text: pet!['food_preference'] ?? '');
          _moodController = TextEditingController(text: pet!['mood'] ?? '');
          _healthController = TextEditingController(text: pet!['health_status'] ?? '');
          _descController = TextEditingController(text: pet!['description'] ?? '');

          _controller = MedicalRecordsController(
            service: SupabaseMedicalRecordService(supabase),
            petId: pet!['id'],
          );
          _controller!.addListener(_onControllerChanged);
          await _controller!.loadAll();
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ========================= Pet Profile =========================
  Future<void> _updatePetDetails() async {
    if (pet == null) return;
    try {
      if (_imageFile != null) {
        final fileName = 'pet_${pet!['id']}_${DateTime.now().millisecondsSinceEpoch}.png';
        final url = await PetService.instance
            .uploadPetImage(widget.userId, _imageFile!.path, fileName);
        if (url != null) _uploadedImageUrl = url;
        _imageFile = null;
      }

      final updatedPet = Pet(
        id: pet!['id'],
        userId: widget.userId,
        name: pet!['name'],
        type: pet!['type'],
        breed: pet!['breed'],
        age: pet!['age'],
        gender: pet!['gender'],
        color: pet!['color'],
        weight: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
        height: _heightController.text.trim().isEmpty
            ? null
            : double.tryParse(_heightController.text.trim()),
        allergies: _foodController.text.trim().isEmpty
            ? null
            : _foodController.text.trim(),
       
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        imageUrl: _uploadedImageUrl ?? pet!['image_url'],
      );

      await PetService.instance.updatePet(updatedPet, widget.userId);

      pet = Map<String, dynamic>.from(pet!);
      pet!.addAll(updatedPet.toJson());

      if (mounted) {
        setState(() => _petEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet details saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pet details: $e')),
        );
      }
    }
  }

  

  // ========================= Build =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FA),
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: _primary,
        elevation: 6,
        shadowColor: _primary.withOpacity(0.5),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null || pet == null
          ? const Center(child: Text('Booking or Pet not found'))
          : AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SingleChildScrollView(
          key: ValueKey('loaded-${booking!['id']}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Pet Owner Info', Icons.person_outline),
              const SizedBox(height: 8),
              _ownerInfoCard(),
              const SizedBox(height: 20),
              _sectionTitle('Pet Profile', Icons.pets_outlined),
              const SizedBox(height: 8),
              _petInfoCard(),
              const SizedBox(height: 24),
              _sectionTitle('Medical Records', Icons.health_and_safety_outlined),
              const SizedBox(height: 8),
              _medicalRecordsCard(),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
      floatingActionButton: (_controller != null && _canEdit)
          ? AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) => _fabForTab(_tabController.index),
      )
          : null,
    );
  }

  // ========================= UI Pieces =========================
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: _cardSurface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _primaryLight),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
  );

  Widget _ownerInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarBadge(Icons.person_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking!['owner_name'] ?? '-',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _chip(
                      'Date',
                      booking!['date'] != null
                          ? DateFormat.yMMMd().format(DateTime.parse(booking!['date']))
                          : '—',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, booking!['owner_email']),
          _infoRow(Icons.phone_outlined, booking!['owner_phone']),
          _infoRow(Icons.access_time, booking!['time']),
        ],
      ),
    );
  }

  Widget _avatarBadge(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _primaryDark]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text ?? '-', style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _petInfoCard() {
    final imgProvider = _imageFile != null
        ? FileImage(_imageFile!) as ImageProvider
        : (pet!['image_url'] != null ? NetworkImage(pet!['image_url']) : null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'pet-${pet!['id']}',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: _primaryLight,
                      backgroundImage: imgProvider,
                      child: imgProvider == null
                          ? const Icon(Icons.pets, color: _primary, size: 36)
                          : null,
                    ),
                    if (_canEdit)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [_primary, _primaryDark]),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet!['name'] ?? '-',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _mini(label: 'Type', value: pet!['type']),
                        _mini(label: 'Breed', value: pet!['breed']),
                        _mini(label: 'Age', value: pet!['age']?.toString()),
                        _mini(label: 'Gender', value: pet!['gender']),
                        _mini(label: 'Color', value: pet!['color']),
                      ],
                    ),
                  ],
                ),
              ),
              if (_canEdit)
                _editIconButton(
                  active: _petEditMode,
                  onEdit: () => setState(() => _petEditMode = true),
                  onSave: _updatePetDetails,
                  onCancel: () => setState(() => _petEditMode = false),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 24),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _petEditMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _petReadonlyFields(),
            secondChild: _petEditableFields(),
          ),
        ],
      ),
    );
  }

  Widget _mini({required String label, String? value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _editIconButton({
    required bool active,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!active)
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit, color: _primary),
            onPressed: onEdit,
          ),
        if (active) ...[
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: onSave,
          ),
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: onCancel,
          ),
        ]
      ],
    );
  }

  Widget _petReadonlyFields() {
    final tiles = <Widget>[
      _kv('Weight', _weightController.text.isEmpty ? '—' : _weightController.text),
      _kv('Height', _heightController.text.isEmpty ? '—' : _heightController.text),
      _kv('Allergies', _foodController.text.isEmpty ? '—' : _foodController.text),
      
    
      _kv('Description', _descController.text.isEmpty ? '—' : _descController.text),
    ];

    return Column(
      children: tiles
          .map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: w))
          .toList(),
    );
  }

  Widget _kv(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _petEditableFields() {
    return Column(
      children: [
        _editableRow('Weight (kg)', _weightController, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _editableRow('Height (cm)', _heightController, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _editableRow('Allergies', _foodController),
        _editableRow('Description', _descController, maxLines: 3),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _editableRow(String label, TextEditingController controller,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit_outlined),
          filled: true,
          fillColor: const Color(0xFFF7F4FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryDark, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ========================= Medical Records =========================
  Widget _medicalRecordsCard() {
    final controller = _controller!;
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeader(),
          const SizedBox(height: 12),
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabController,
              children: [
                _vaccinationsTab(controller),
                _checkupsTab(controller),
                _prescriptionsTab(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: _primaryDark,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [_primary, _primaryDark]),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Vaccinations'),
          Tab(text: 'Checkups'),
          Tab(text: 'Prescriptions'),
        ],
      ),
    );
  }

  Widget _fabForTab(int index) {
    final labels = ['Add Vaccination', 'Add Checkup', 'Add Prescription'];
    return Tooltip(
      message: labels[index],
      child: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: _addMedicalRecord,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _addMedicalRecord() async {
    if (_controller == null) return;
    final index = _tabController.index;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? date1;
    DateTime? date2;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _primary.withOpacity(.12),
                    child: Icon(
                      index == 0
                          ? Icons.vaccines_outlined
                          : index == 1
                          ? Icons.medical_services_outlined
                          : Icons.receipt_long_outlined,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    index == 0
                        ? 'Add Vaccination'
                        : index == 1
                        ? 'Add Medical Checkup'
                        : 'Add Prescription',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.title_outlined),
                        labelText: index == 0
                            ? 'Vaccine Name'
                            : index == 1
                            ? 'Reason'
                            : 'Medicine Name',
                        filled: true,
                        fillColor: const Color(0xFFF7F4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.description_outlined),
                        labelText: 'Description',
                        filled: true,
                        fillColor: const Color(0xFFF7F4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (index == 0) ...[
                      _datePickerField(
                        'Date Given',
                        date1,
                            (d) {
                          date1 = d;
                          setLocal(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      _datePickerField(
                        'Next Due',
                        date2,
                            (d) {
                          date2 = d;
                          setLocal(() {});
                        },
                      ),
                    ],
                    if (index == 1) ...[
                      _datePickerField(
                        'Date',
                        date1,
                            (d) {
                          date1 = d;
                          setLocal(() {});
                        },
                      ),
                    ],
                    if (index == 2) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _datePickerField(
                              'Start Date',
                              date1,
                                  (d) {
                                date1 = d;
                                setLocal(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _datePickerField(
                              'End Date',
                              date2,
                                  (d) {
                                date2 = d;
                                setLocal(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      final createdBy = _createdByName ?? widget.providerEmail;

                      if (index == 0) {
                        await _controller!.addOrUpdateVaccination(
                          existing: null,
                          name: nameCtrl.text.trim(),
                          desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          dateGiven: date1 ?? DateTime.now(),
                          nextDue: date2,
                          createdBy: createdBy,
                        );
                      } else if (index == 1) {
                        await _controller!.addOrUpdateCheckup(
                          existing: null,
                          reason: nameCtrl.text.trim(),
                          desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          date: date1 ?? DateTime.now(),
                          createdBy: createdBy,
                        );
                      } else if (index == 2) {
                        await _controller!.addOrUpdatePrescription(
                          existing: null,
                          med: nameCtrl.text.trim(),
                          desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          start: date1 ?? DateTime.now(),
                          end: date2,
                          createdBy: createdBy,
                        );
                      }

                      if (mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === Tabs ===
  Widget _vaccinationsTab(MedicalRecordsController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loadingVacc) return const Center(child: CircularProgressIndicator());
        if (controller.vaccinations.isEmpty) return const Center(child: Text('No vaccinations found'));

        return SingleChildScrollView(
          child: Column(
            children: controller.vaccinations.map((v) {
              final nameCtrl = TextEditingController(text: v.vaccinationName);
              final descCtrl = TextEditingController(text: v.description ?? '');
              DateTime? dateGiven = v.dateGiven;
              DateTime? nextDue = v.nextDueDate;
              bool editing = _vaccEditing[v.id] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primaryLight),
                ),
                child: ListTile(
                  title: editing
                      ? TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  )
                      : Text(v.vaccinationName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_df.format(v.dateGiven)}  ·  Next: ${v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—'}',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Created by: ${v.createdBy ?? '—'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if ((v.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              v.description!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),
                    secondChild: Column(
                      children: [
                        TextField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _datePickerField(
                                'Date Given',
                                dateGiven,
                                    (d) {
                                  dateGiven = d;
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _datePickerField(
                                'Next Due',
                                nextDue,
                                    (d) {
                                  nextDue = d;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: _canEdit
                      ? _rowActions(
                    editing: editing,
                    onEdit: () => setState(() => _vaccEditing[v.id] = true),
                    onSave: () async {
                      await controller.addOrUpdateVaccination(
                        existing: v,
                        name: nameCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        dateGiven: dateGiven!,
                        nextDue: nextDue,
                        createdBy: _createdByName ?? widget.providerEmail,
                      );
                      _vaccEditing[v.id] = false;
                    },
                    onCancel: () => _vaccEditing[v.id] = false,
                    onDelete: () async => controller.deleteVaccination(v.id),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _checkupsTab(MedicalRecordsController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loadingCheck) return const Center(child: CircularProgressIndicator());
        if (controller.checkups.isEmpty) return const Center(child: Text('No checkups found'));

        return SingleChildScrollView(
          child: Column(
            children: controller.checkups.map((c) {
              final reasonCtrl = TextEditingController(text: c.reason);
              final descCtrl = TextEditingController(text: c.description ?? '');
              DateTime date = c.date;
              bool editing = _checkEditing[c.id] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primaryLight),
                ),
                child: ListTile(
                  title: editing
                      ? TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'))
                      : Text(c.reason, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_df.format(c.date)),
                        const SizedBox(height: 2),
                        Text(
                          'Created by: ${c.createdBy ?? '—'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    secondChild: Column(
                      children: [
                        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                        const SizedBox(height: 8),
                        _datePickerField('Date', date, (d) {
                          date = d;
                          setState(() {});
                        }),
                      ],
                    ),
                  ),
                  trailing: _canEdit
                      ? _rowActions(
                    editing: editing,
                    onEdit: () => setState(() => _checkEditing[c.id] = true),
                    onSave: () async {
                      await controller.addOrUpdateCheckup(
                        existing: c,
                        reason: reasonCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        date: date,
                        createdBy: _createdByName ?? widget.providerEmail,
                      );
                      _checkEditing[c.id] = false;
                    },
                    onCancel: () => _checkEditing[c.id] = false,
                    onDelete: () async => controller.deleteCheckup(c.id),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _prescriptionsTab(MedicalRecordsController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loadingRx) return const Center(child: CircularProgressIndicator());
        if (controller.prescriptions.isEmpty) return const Center(child: Text('No prescriptions found'));

        return SingleChildScrollView(
          child: Column(
            children: controller.prescriptions.map((p) {
              final medCtrl = TextEditingController(text: p.medicineName);
              final descCtrl = TextEditingController(text: p.description ?? '');
              DateTime start = p.startDate;
              DateTime? end = p.endDate;
              bool editing = _rxEditing[p.id] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primaryLight),
                ),
                child: ListTile(
                  title: editing
                      ? TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'Medicine'))
                      : Text(p.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_df.format(p.startDate)}  ·  End: ${p.endDate != null ? _df.format(p.endDate!) : '—'}'),
                        const SizedBox(height: 2),
                        Text(
                          'Created by: ${p.createdBy ?? '—'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    secondChild: Column(
                      children: [
                        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _datePickerField('Start', start, (d) {
                                start = d;
                                setState(() {});
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _datePickerField('End', end, (d) {
                                end = d;
                                setState(() {});
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: _canEdit
                      ? _rowActions(
                    editing: editing,
                    onEdit: () => setState(() => _rxEditing[p.id] = true),
                    onSave: () async {
                      await controller.addOrUpdatePrescription(
                        existing: p,
                        med: medCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        start: start,
                        end: end,
                        createdBy: _createdByName ?? widget.providerEmail,
                      );
                      _rxEditing[p.id] = false;
                    },
                    onCancel: () => _rxEditing[p.id] = false,
                    onDelete: () async => controller.deletePrescription(p.id),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _rowActions({
    required bool editing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required Future<void> Function() onDelete,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (!editing)
        IconButton(icon: const Icon(Icons.edit, color: _primary), onPressed: onEdit),
      if (editing) ...[
        IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: onSave),
        IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: onCancel),
      ],
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.black54),
        onPressed: () async {
          await onDelete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deleted')),
            );
          }
        },
      ),
    ]);
  }

  Widget _datePickerField(String label, DateTime? date, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(DateTime.now().year + 10),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: _primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF7F4FF),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(date != null ? _df.format(date) : '—'),
      ),
    );
  }
}
