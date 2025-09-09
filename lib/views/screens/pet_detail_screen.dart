// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/controllers/medical_records_controller.dart';
import 'package:scooby_app_new/controllers/pet_service.dart';
import 'package:scooby_app_new/models/medical_records.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:scooby_app_new/services/medical_record_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetDetailScreenModernIntegrated extends StatefulWidget {
  final String userId;
  final String petId;
  final String? imageUrl;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String gender;
  final String? color;
  final num? weight;
  final num? height;
  final String? allergies;
  final String? description;

  const PetDetailScreenModernIntegrated({
    super.key,
    required this.userId,
    required this.petId,
    required this.imageUrl,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    this.color,
    this.weight,
    this.height,
    this.allergies,
    this.description,
  });

  @override
  State<PetDetailScreenModernIntegrated> createState() =>
      _PetDetailScreenModernIntegratedState();
  State<PetDetailScreenModernIntegrated> createState() =>
      _PetDetailScreenModernIntegratedState();
}

class _PetDetailScreenModernIntegratedState
    extends State<PetDetailScreenModernIntegrated>
    with SingleTickerProviderStateMixin {
class _PetDetailScreenModernIntegratedState
    extends State<PetDetailScreenModernIntegrated>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MedicalRecordsController _controller;
  late TextEditingController _nameController;
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _colorController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _allergiesController;
  late TextEditingController _descController;

  // NEW: walking time display controllers
  final TextEditingController _startTimeCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();

  // NEW: store DB/submit values as 'HH:mm:ss'
  String? _startHms;
  String? _endHms;

  bool _editingPet = false;
  // NEW: walking time display controllers
  final TextEditingController _startTimeCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();

  // NEW: store DB/submit values as 'HH:mm:ss'
  String? _startHms;
  String? _endHms;

  bool _editingPet = false;

  final _primary = const Color(0xFF842EAC);
  final _df = DateFormat('yyyy-MM-dd');
  File? _imageFile;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = MedicalRecordsController(
      service: SupabaseMedicalRecordService(Supabase.instance.client),
      petId: widget.petId,
    );
    _controller.loadAll();

    // Initialize pet fields using widget properties
    _nameController = TextEditingController(text: widget.name);
    _typeController = TextEditingController(text: widget.type);
    _breedController = TextEditingController(text: widget.breed);
    _ageController = TextEditingController(text: widget.age.toString());
    _genderController = TextEditingController(text: widget.gender);
    _colorController = TextEditingController(text: widget.color ?? '');
    _weightController =
        TextEditingController(text: widget.weight?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.height?.toString() ?? '');
    _allergiesController =
        TextEditingController(text: widget.allergies ?? '');
    _descController =
        TextEditingController(text: widget.description ?? '');

    // Load walking times from DB
    _loadWalkingTimes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  // ========= WALKING TIME HELPERS =========

  Future<void> _loadWalkingTimes() async {
    final sb = Supabase.instance.client;
    try {
      final resp = await sb
          .from('pets')
          .select('start_walking_time, end_walking_time')
          .eq('id', widget.petId)
          .maybeSingle();

      _startHms = (resp?['start_walking_time'] as String?);
      _endHms = (resp?['end_walking_time'] as String?);

      _startTimeCtrl.text = _formatHmsForDisplay(_startHms) ?? '';
      _endTimeCtrl.text = _formatHmsForDisplay(_endHms) ?? '';

      if (mounted) setState(() {});
    } catch (e) {
      // ignore errors silently for now
    }
  }

  String? _formatHmsForDisplay(String? hms) {
    if (hms == null || hms.isEmpty) return null;
    final parts = hms.split(':');
    if (parts.length < 2) return hms;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    return tod.format(context);
  }

  String _fmtHms(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  int? _minutesFromHms(String? hms) {
    if (hms == null || hms.isEmpty) return null;
    final p = hms.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String? _walkRangeDisplay() {
    final s = _formatHmsForDisplay(_startHms);
    final e = _formatHmsForDisplay(_endHms);
    if (s == null || e == null) return null;
    return '$s – $e';
  }

  Future<void> _pickStartTime() async {
    final init = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _startHms = _fmtHms(picked);
      _startTimeCtrl.text = picked.format(context);
      setState(() {});
    }
  }

  Future<void> _pickEndTime() async {
    final init = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _endHms = _fmtHms(picked);
      _endTimeCtrl.text = picked.format(context);
      setState(() {});
    }
  }

  bool _validateWalkingTimesIfPresent() {
    // only validate when both are set
    if ((_startHms == null || _startHms!.isEmpty) &&
        (_endHms == null || _endHms!.isEmpty)) {
      return true; // nothing to validate
    }
    if (_startHms == null || _endHms == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Please set both start and end walking times')),
      );
      return false;
    }
    final sm = _minutesFromHms(_startHms);
    final em = _minutesFromHms(_endHms);
    if (sm == null || em == null) return true;

    if (em - sm < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'End walking time must be at least 10 minutes after start')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Pet Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_editingPet ? Icons.check : Icons.edit),
            onPressed: () async {
              if (_editingPet) {
                // Validate time range (if present)
                if (!_validateWalkingTimesIfPresent()) return;

                // Upload new image if changed
                if (_imageFile != null) {
                  final fileName =
                      'pet_${widget.petId}_${DateTime.now().millisecondsSinceEpoch}.png';
                  final url = await PetService.instance.uploadPetImage(
                    widget.userId,
                    _imageFile!.path,
                    fileName,
                  );
                  if (url != null) _uploadedImageUrl = url; // store in state
                  _imageFile = null; // reset picked file
                }

                // Update pet details (includes walking times)
                await PetService.instance.updatePet(
                  Pet(
                    id: widget.petId,
                    userId: widget.userId,
                    name: _nameController.text.trim(),
                    type: _typeController.text.trim(),
                    breed: _breedController.text.trim(),
                    age: int.tryParse(_ageController.text.trim()) ?? 0,
                    gender: _genderController.text.trim(),
                    color: _colorController.text.trim().isEmpty
                        ? null
                        : _colorController.text.trim(),
                    weight: _weightController.text.trim().isEmpty
                        ? null
                        : double.tryParse(_weightController.text.trim()),
                    height: _heightController.text.trim().isEmpty
                        ? null
                        : double.tryParse(_heightController.text.trim()),
                    allergies: _allergiesController.text.trim().isEmpty
                        ? null
                        : _allergiesController.text.trim(),
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                    imageUrl: _uploadedImageUrl ?? widget.imageUrl,
                    // NEW: send walking times to DB
                    startWalkingTime: _startHms,
                    endWalkingTime: _endHms,
                  ),
                  widget.userId,
                );

                _imageFile = null; // reset local image after save
              }
              setState(() => _editingPet = !_editingPet);
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroHeader(),
                const SizedBox(height: 12),
                _highlightChips(),
                const SizedBox(height: 12),
                _detailsCard(),
                const SizedBox(height: 16),
                _medicalRecordsInline(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======= UI SECTIONS =======

  Widget _heroHeader() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              image: _editingPet && _imageFile != null
                  ? DecorationImage(
                  image: FileImage(_imageFile!), fit: BoxFit.cover)
                  : (_uploadedImageUrl ?? widget.imageUrl) != null
                  ? DecorationImage(
                  image: NetworkImage(
                      _uploadedImageUrl ?? widget.imageUrl!),
                  fit: BoxFit.cover)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.92 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: _editingPet && _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_uploadedImageUrl ?? widget.imageUrl) != null
                          ? NetworkImage(
                          _uploadedImageUrl ?? widget.imageUrl!)
                          : null,
                      child: (_uploadedImageUrl ?? widget.imageUrl) == null &&
                          _imageFile == null
                          ? Icon(Icons.pets, color: _primary, size: 28)
                          : null,
                    ),
                    if (_editingPet)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: _primary,
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _editingPet
                      ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pet Name',
                    ),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('${widget.type} • ${widget.breed}',
                          style: TextStyle(
                              color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              image: _editingPet && _imageFile != null
                  ? DecorationImage(
                  image: FileImage(_imageFile!), fit: BoxFit.cover)
                  : (_uploadedImageUrl ?? widget.imageUrl) != null
                  ? DecorationImage(
                  image: NetworkImage(
                      _uploadedImageUrl ?? widget.imageUrl!),
                  fit: BoxFit.cover)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.92 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: _editingPet && _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_uploadedImageUrl ?? widget.imageUrl) != null
                          ? NetworkImage(
                          _uploadedImageUrl ?? widget.imageUrl!)
                          : null,
                      child: (_uploadedImageUrl ?? widget.imageUrl) == null &&
                          _imageFile == null
                          ? Icon(Icons.pets, color: _primary, size: 28)
                          : null,
                    ),
                    if (_editingPet)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: _primary,
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _editingPet
                      ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pet Name',
                    ),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('${widget.type} • ${widget.breed}',
                          style: TextStyle(
                              color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _highlightChips() {
    final items = <(IconData, TextEditingController)>[
      (Icons.cake, _ageController),
      (Icons.male, _genderController),
      (Icons.color_lens, _colorController),
      (Icons.monitor_weight, _weightController),
      (Icons.height, _heightController),
    ];
  Widget _highlightChips() {
    final items = <(IconData, TextEditingController)>[
      (Icons.cake, _ageController),
      (Icons.male, _genderController),
      (Icons.color_lens, _colorController),
      (Icons.monitor_weight, _weightController),
      (Icons.height, _heightController),
    ];

    // 👇 Force the map to produce Widgets, not GestureDetector specifically
    final List<Widget> chips = items.map<Widget>((it) => GestureDetector(
      onTap: _editingPet
          ? () async {
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Edit ${_getLabelFromIcon(it.$1)}'),
            content: TextField(
              controller: it.$2,
              keyboardType: (it.$1 == Icons.cake || it.$1 == Icons.monitor_weight || it.$1 == Icons.height)
                  ? TextInputType.number
                  : TextInputType.text,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, it.$2.text.trim()), child: const Text('Save')),
            ],
          ),
        );
        if (result != null) setState(() {}); // refresh chip text
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _primary.withAlpha((0.12 * 255).toInt())),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(it.$1, size: 18, color: _primary),
            const SizedBox(width: 6),
            Text(it.$2.text.isEmpty ? '—' : it.$2.text),
          ],
        ),
      ),
    )).toList();

    // Add the walking time chip (Container) safely now
    final walkText = _walkRangeDisplay() ?? '—';
    chips.add(Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _primary.withAlpha((0.12 * 255).toInt())),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk, size: 18, color: _primary),
          const SizedBox(width: 6),
          Text(walkText),
        ],
      ),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: chips),
    );
  }
    // 👇 Force the map to produce Widgets, not GestureDetector specifically
    final List<Widget> chips = items.map<Widget>((it) => GestureDetector(
      onTap: _editingPet
          ? () async {
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Edit ${_getLabelFromIcon(it.$1)}'),
            content: TextField(
              controller: it.$2,
              keyboardType: (it.$1 == Icons.cake || it.$1 == Icons.monitor_weight || it.$1 == Icons.height)
                  ? TextInputType.number
                  : TextInputType.text,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, it.$2.text.trim()), child: const Text('Save')),
            ],
          ),
        );
        if (result != null) setState(() {}); // refresh chip text
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _primary.withAlpha((0.12 * 255).toInt())),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(it.$1, size: 18, color: _primary),
            const SizedBox(width: 6),
            Text(it.$2.text.isEmpty ? '—' : it.$2.text),
          ],
        ),
      ),
    )).toList();

    // Add the walking time chip (Container) safely now
    final walkText = _walkRangeDisplay() ?? '—';
    chips.add(Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _primary.withAlpha((0.12 * 255).toInt())),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk, size: 18, color: _primary),
          const SizedBox(width: 6),
          Text(walkText),
        ],
      ),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: chips),
    );
  }


  String _getLabelFromIcon(IconData icon) {
    switch (icon) {
      case Icons.cake:
        return 'Age';
      case Icons.male:
        return 'Gender';
      case Icons.color_lens:
        return 'Color';
      case Icons.monitor_weight:
        return 'Weight';
      case Icons.height:
        return 'Height';
      default:
        return '';
    }
  }
  String _getLabelFromIcon(IconData icon) {
    switch (icon) {
      case Icons.cake:
        return 'Age';
      case Icons.male:
        return 'Gender';
      case Icons.color_lens:
        return 'Color';
      case Icons.monitor_weight:
        return 'Weight';
      case Icons.height:
        return 'Height';
      default:
        return '';
    }
  }

  Widget _detailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Widget _detailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: _primary),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Keep only the non-highlighted fields
            _editableRow('Allergies', _allergiesController),
            _editableRow('Description', _descController),

            const SizedBox(height: 12),
            // NEW: Walking Time fields
            _editableTimeRow(
              label: 'Start Walking Time',
              controller: _startTimeCtrl,
              onPick: _pickStartTime,
            ),
            const SizedBox(height: 12),
            _editableTimeRow(
              label: 'End Walking Time',
              controller: _endTimeCtrl,
              onPick: _pickEndTime,
            ),
          ]),
        ),
      ),
    );
  }

            const SizedBox(height: 12),
            // NEW: Walking Time fields
            _editableTimeRow(
              label: 'Start Walking Time',
              controller: _startTimeCtrl,
              onPick: _pickStartTime,
            ),
            const SizedBox(height: 12),
            _editableTimeRow(
              label: 'End Walking Time',
              controller: _endTimeCtrl,
              onPick: _pickEndTime,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _editableRow(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _editingPet
          ? TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
      )
          : Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800),
              )),
          Expanded(
              child: Text(
  Widget _editableRow(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _editingPet
          ? TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
      )
          : Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800),
              )),
          Expanded(
              child: Text(
                controller.text.isEmpty ? '—' : controller.text,
                style: const TextStyle(color: Colors.black87),
              )),
        ],
      ),
    );
  }
        ],
      ),
    );
  }

  // NEW: time row that uses a time picker when editing
  Widget _editableTimeRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _editingPet
          ? TextField(
        controller: controller,
        readOnly: true,
        onTap: onPick,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule),
        ),
      )
          : Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            child: Text(
              controller.text.isEmpty ? '—' : controller.text,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  // NEW: time row that uses a time picker when editing
  Widget _editableTimeRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _editingPet
          ? TextField(
        controller: controller,
        readOnly: true,
        onTap: onPick,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule),
        ),
      )
          : Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            child: Text(
              controller.text.isEmpty ? '—' : controller.text,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // === Inline Medical Records Tabs ===
  Widget _medicalRecordsInline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.health_and_safety, color: _primary),
                const SizedBox(width: 8),
                const Text('Medical Records',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w800))
              ]),
              Row(children: [
                Icon(Icons.health_and_safety, color: _primary),
                const SizedBox(width: 8),
                const Text('Medical Records',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: _primary,
                indicatorColor: _primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Vaccinations'),
                  Tab(text: 'Medical Checkups'),
                  Tab(text: 'Prescriptions'),
                ],
              ),
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _vaccinationsTabInline(),
                    _checkupsTabInline(),
                    _prescriptionsTabInline(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === Inline Vaccinations ===
  Widget _vaccinationsTabInline() {
    if (_controller.loadingVacc) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.loadingVacc) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _controller.vaccinations.cast<Vaccination>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((v) {
          final nameCtrl =
          TextEditingController(text: v.vaccinationName);
          final descCtrl =
          TextEditingController(text: v.description ?? '');
          final nameCtrl =
          TextEditingController(text: v.vaccinationName);
          final descCtrl =
          TextEditingController(text: v.description ?? '');
          DateTime? dateGiven = v.dateGiven;
          DateTime? nextDue = v.nextDueDate;
          bool editing = _vaccEditing[v.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(
                  controller: nameCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Name'))
                  ? TextField(
                  controller: nameCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Name'))
                  : Text(v.vaccinationName),
              subtitle: editing
                  ? Column(children: [
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _datePickerField('Date Given',
                          dateGiven, (d) => setState(() {
                            dateGiven = d;
                          }))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _datePickerField('Next Due', nextDue,
                              (d) => setState(() {
                            nextDue = d;
                          }))),
                ])
              ])
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _datePickerField('Date Given',
                          dateGiven, (d) => setState(() {
                            dateGiven = d;
                          }))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _datePickerField('Next Due', nextDue,
                              (d) => setState(() {
                            nextDue = d;
                          }))),
                ])
              ])
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_df.format(v.dateGiven)} - Next: ${v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—'}'),
                  if (v.description != null &&
                      v.description!.isNotEmpty)
                    Text(v.description!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600)),
                ],
              ),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          setState(() => _vaccEditing[v.id] = true)),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await _controller.addOrUpdateVaccination(
                          existing: v,
                          name: nameCtrl.text.trim(),
                          desc: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          dateGiven: dateGiven!,
                          nextDue: nextDue,
                        );
                        setState(() => _vaccEditing[v.id] = false);
                      }),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                              () => _vaccEditing[v.id] = false)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async =>
                    await _controller.deleteVaccination(v.id)),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_df.format(v.dateGiven)} - Next: ${v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—'}'),
                  if (v.description != null &&
                      v.description!.isNotEmpty)
                    Text(v.description!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600)),
                ],
              ),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          setState(() => _vaccEditing[v.id] = true)),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await _controller.addOrUpdateVaccination(
                          existing: v,
                          name: nameCtrl.text.trim(),
                          desc: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          dateGiven: dateGiven!,
                          nextDue: nextDue,
                        );
                        setState(() => _vaccEditing[v.id] = false);
                      }),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                              () => _vaccEditing[v.id] = false)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async =>
                    await _controller.deleteVaccination(v.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === Inline Checkups ===
  final Map<String, bool> _vaccEditing = {};
  final Map<String, bool> _checkEditing = {};
  final Map<String, bool> _rxEditing = {};

  Widget _checkupsTabInline() {
    if (_controller.loadingCheck) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _controller.checkups.cast<MedicalCheckup>();
  final Map<String, bool> _vaccEditing = {};
  final Map<String, bool> _checkEditing = {};
  final Map<String, bool> _rxEditing = {};

  Widget _checkupsTabInline() {
    if (_controller.loadingCheck) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _controller.checkups.cast<MedicalCheckup>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((c) {
          final reasonCtrl = TextEditingController(text: c.reason);
          final descCtrl =
          TextEditingController(text: c.description ?? '');
          DateTime date = c.date;
          bool editing = _checkEditing[c.id] ?? false;
    return SingleChildScrollView(
      child: Column(
        children: rows.map((c) {
          final reasonCtrl = TextEditingController(text: c.reason);
          final descCtrl =
          TextEditingController(text: c.description ?? '');
          DateTime date = c.date;
          bool editing = _checkEditing[c.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Reason'))
                  : Text(c.reason),
              subtitle: editing
                  ? Column(
                children: [
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description')),
                  const SizedBox(height: 8),
                  _datePickerField('Date', date, (d) => setState(() {
                    date = d;
                  })),
                ],
              )
                  : Text(_df.format(c.date)),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Reason'))
                  : Text(c.reason),
              subtitle: editing
                  ? Column(
                children: [
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description')),
                  const SizedBox(height: 8),
                  _datePickerField('Date', date, (d) => setState(() {
                    date = d;
                  })),
                ],
              )
                  : Text(_df.format(c.date)),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(
                              () => _checkEditing[c.id] = true)),
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(
                              () => _checkEditing[c.id] = true)),
                if (editing)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      await _controller.addOrUpdateCheckup(
                        existing: c,
                        reason: reasonCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        date: date,
                      );
                      setState(() => _checkEditing[c.id] = false);
                    },
                  ),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                              () => _checkEditing[c.id] = false)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async =>
                    await _controller.deleteCheckup(c.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

 

  // === Inline Prescriptions ===
  Widget _prescriptionsTabInline() {
    if (_controller.loadingRx) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _controller.prescriptions.cast<Prescription>();
  // === Inline Prescriptions ===
  Widget _prescriptionsTabInline() {
    if (_controller.loadingRx) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _controller.prescriptions.cast<Prescription>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((p) {
          final medCtrl =
          TextEditingController(text: p.medicineName);
          final descCtrl =
          TextEditingController(text: p.description ?? '');
          DateTime start = p.startDate;
          DateTime? end = p.endDate;
          bool editing = _rxEditing[p.id] ?? false;
    return SingleChildScrollView(
      child: Column(
        children: rows.map((p) {
          final medCtrl =
          TextEditingController(text: p.medicineName);
          final descCtrl =
          TextEditingController(text: p.description ?? '');
          DateTime start = p.startDate;
          DateTime? end = p.endDate;
          bool editing = _rxEditing[p.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(
                  controller: medCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Medicine'))
                  : Text(p.medicineName),
              subtitle: editing
                  ? Column(
                children: [
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _datePickerField('Start', start,
                                  (d) => setState(() {
                                start = d;
                              }))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _datePickerField('End', end,
                                  (d) => setState(() {
                                end = d;
                              }))),
                    ],
                  ),
                ],
              )
                  : Text(
                  '${_df.format(p.startDate)} - End: ${p.endDate != null ? _df.format(p.endDate!) : '—'}'),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          setState(() => _rxEditing[p.id] = true)),
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(
                  controller: medCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Medicine'))
                  : Text(p.medicineName),
              subtitle: editing
                  ? Column(
                children: [
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _datePickerField('Start', start,
                                  (d) => setState(() {
                                start = d;
                              }))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _datePickerField('End', end,
                                  (d) => setState(() {
                                end = d;
                              }))),
                    ],
                  ),
                ],
              )
                  : Text(
                  '${_df.format(p.startDate)} - End: ${p.endDate != null ? _df.format(p.endDate!) : '—'}'),
              trailing:
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing)
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          setState(() => _rxEditing[p.id] = true)),
                if (editing)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      await _controller.addOrUpdatePrescription(
                        existing: p,
                        med: medCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        desc: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        start: start,
                        end: end,
                      );
                      setState(() => _rxEditing[p.id] = false);
                    },
                  ),
                if (editing)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                              () => _rxEditing[p.id] = false)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async =>
                    await _controller.deletePrescription(p.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                              () => _rxEditing[p.id] = false)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async =>
                    await _controller.deletePrescription(p.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _datePickerField(
      String label, DateTime? date, Function(DateTime) onPick) {
  Widget _datePickerField(
      String label, DateTime? date, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(DateTime.now().year + 10));
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(date != null ? _df.format(date) : '—'),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }
}
