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
  final String? foodPreference;
  final String? mood;
  final String? healthStatus;
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
    this.foodPreference,
    this.mood,
    this.healthStatus,
    this.description,
  });

  @override
  State<PetDetailScreenModernIntegrated> createState() => _PetDetailScreenModernIntegratedState();
}

class _PetDetailScreenModernIntegratedState extends State<PetDetailScreenModernIntegrated> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MedicalRecordsController _controller;
  late String _name;
  late String _type;
  late String _breed;
  late int _age;
  late String _gender;
  late String? _color;
  late num? _weight;
  late num? _height;
  late String? _foodPreference;
  late String? _mood;
  late String? _healthStatus;
  late String? _description;
  bool _editingPet = false;

  // Editing states for inline tabs
  final Map<String, bool> _vaccEditing = {};
  final Map<String, bool> _checkEditing = {};
  final Map<String, bool> _rxEditing = {};

  final _primary = const Color(0xFF842EAC);
  final _df = DateFormat('yyyy-MM-dd');
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = MedicalRecordsController(
      service: SupabaseMedicalRecordService(Supabase.instance.client),
      petId: widget.petId,
    );
    _controller.loadAll();

    // Initialize pet fields
    _name = widget.name;
    _type = widget.type;
    _breed = widget.breed;
    _age = widget.age;
    _gender = widget.gender;
    _color = widget.color;
    _weight = widget.weight;
    _height = widget.height;
    _foodPreference = widget.foodPreference;
    _mood = widget.mood;
    _healthStatus = widget.healthStatus;
    _description = widget.description;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            String? uploadedImageUrl = widget.imageUrl;

            // Upload new image if changed
            if (_imageFile != null) {
              final fileName = 'pet_${widget.petId}_${DateTime.now().millisecondsSinceEpoch}.png';
              final url = await PetService.instance.uploadPetImage(widget.userId, _imageFile!.path, fileName);
              if (url != null) uploadedImageUrl = url;
            }

            await PetService.instance.updatePet(
              Pet(
                id: widget.petId,
                userId: widget.userId,
                name: _name,
                type: _type,
                breed: _breed,
                age: _age,
                gender: _gender,
                color: _color,
                weight: _weight?.toDouble(),
                height: _height?.toDouble(),
                foodPreference: _foodPreference,
                mood: _mood,
                healthStatus: _healthStatus,
                description: _description,
                imageUrl: uploadedImageUrl, // pass updated image URL
              ),
              widget.userId,
            );

            // reset local imageFile after save
            _imageFile = null;
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

    // 🔹 Floating Add Button
    floatingActionButton: FloatingActionButton(
    backgroundColor: _primary,
    child: const Icon(Icons.add, color: Colors.white),
    onPressed: () async {
      final index = _tabController.index;

      // Variables for form fields
      final nameCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      DateTime? date1;
      DateTime? date2;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              index == 0
                  ? 'Add Vaccination'
                  : index == 1
                      ? 'Add Medical Checkup'
                      : 'Add Prescription',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: index == 0
                          ? 'Vaccine Name'
                          : index == 1
                              ? 'Reason'
                              : 'Medicine Name',
                    ),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  if (index == 0) ...[
                    _datePickerField('Date Given', date1, (d) => date1 = d),
                    const SizedBox(height: 8),
                    _datePickerField('Next Due', date2, (d) => date2 = d),
                  ],
                  if (index == 1) ...[
                    _datePickerField('Date', date1, (d) => date1 = d),
                  ],
                  if (index == 2) ...[
                    _datePickerField('Start Date', date1, (d) => date1 = d),
                    const SizedBox(height: 8),
                    _datePickerField('End Date', date2, (d) => date2 = d),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                onPressed: () async {
                  if (index == 0) {
                    await _controller.addOrUpdateVaccination(
                      existing: null,
                      name: nameCtrl.text.trim(),
                      desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      dateGiven: date1 ?? DateTime.now(),
                      nextDue: date2,
                    );
                  } else if (index == 1) {
                    await _controller.addOrUpdateCheckup(
                      existing: null,
                      reason: nameCtrl.text.trim(),
                      desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      date: date1 ?? DateTime.now(),
                    );
                  } else if (index == 2) {
                    await _controller.addOrUpdatePrescription(
                      existing: null,
                      med: nameCtrl.text.trim(),
                      desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      start: date1 ?? DateTime.now(),
                      end: date2,
                    );
                  }

                  await _controller.loadAll();

                
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  )


  );
}



   Widget _heroHeader() {
  return Stack(
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            image: _editingPet && _imageFile != null
                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                : widget.imageUrl != null
                    ? DecorationImage(image: NetworkImage(widget.imageUrl!), fit: BoxFit.cover)
                    : null,
          ),
        ),
      ),
      Positioned(
        bottom: 12,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        : widget.imageUrl != null
                            ? NetworkImage(widget.imageUrl!)
                            : null,
                    child: widget.imageUrl == null && _imageFile == null
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
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _editingPet
                    ? TextField(
                        controller: TextEditingController(text: _name),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Pet Name',
                        ),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        onChanged: (val) => _name = val,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text('${widget.type} • ${widget.breed}',
                              style: TextStyle(color: Colors.grey.shade700)),
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
    final items = <(IconData, String)>[
      (Icons.cake, '${widget.age} yrs'),
      (Icons.male, widget.gender),
      (Icons.color_lens, widget.color ?? '—'),
      (Icons.monitor_weight, widget.weight != null ? '${widget.weight} kg' : '—'),
      (Icons.height, widget.height != null ? '${widget.height} cm' : '—'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: items.map((it) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _primary.withAlpha((0.12 * 255).toInt())),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04*255).toInt()), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(children: [Icon(it.$1, size: 18, color: _primary), const SizedBox(width: 6), Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w600))]),
        )).toList(),
      ),
    );
  }
Widget _detailsCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.info_outline, color: _primary), const SizedBox(width: 8), Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey.shade900))]),
          const SizedBox(height: 12),
          
          _editableRow('Name', _name, (val) => _name = val),
          _editableRow('Type', _type, (val) => _type = val),
          _editableRow('Breed', _breed, (val) => _breed = val),
          _editableRow('Age', '$_age', (val) => _age = int.tryParse(val) ?? _age, inputType: TextInputType.number),
          _editableRow('Gender', _gender, (val) => _gender = val),
          _editableRow('Color', _color ?? '', (val) => _color = val),
          _editableRow('Weight', _weight?.toString() ?? '', (val) => _weight = num.tryParse(val), inputType: TextInputType.number),
          _editableRow('Height', _height?.toString() ?? '', (val) => _height = num.tryParse(val), inputType: TextInputType.number),
          _editableRow('Food Preference', _foodPreference ?? '', (val) => _foodPreference = val),
          _editableRow('Mood', _mood ?? '', (val) => _mood = val),
          _editableRow('Health Status', _healthStatus ?? '', (val) => _healthStatus = val),
          _editableRow('Description', _description ?? '', (val) => _description = val),
        ]),
      ),
    ),
  );
}

Widget _editableRow(String label, String value, Function(String) onChanged, {TextInputType inputType = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: _editingPet
      ? TextField(
          controller: TextEditingController(text: value),
          keyboardType: inputType,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
        )
      : Row(
          children: [
            SizedBox(width: 140, child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800))),
            Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(color: Colors.black87))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.health_and_safety, color: _primary), const SizedBox(width: 8), const Text('Medical Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
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
    if (_controller.loadingVacc) return const Center(child: CircularProgressIndicator());
    final rows = _controller.vaccinations.cast<Vaccination>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((v) {
          final nameCtrl = TextEditingController(text: v.vaccinationName);
          final descCtrl = TextEditingController(text: v.description ?? '');
          DateTime? dateGiven = v.dateGiven;
          DateTime? nextDue = v.nextDueDate;
          bool editing = _vaccEditing[v.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing
                  ? TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'))
                  : Text(v.vaccinationName),
              subtitle: editing
                  ? Column(children: [
                      TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _datePickerField('Date Given', dateGiven, (d) => setState(() => dateGiven = d))),
                        const SizedBox(width: 12),
                        Expanded(child: _datePickerField('Next Due', nextDue, (d) => setState(() => nextDue = d))),
                      ])
                    ])
                  : Text('${_df.format(v.dateGiven)} - Next: ${v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—'}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _vaccEditing[v.id] = true)),
                if (editing) IconButton(icon: const Icon(Icons.check), onPressed: () async {
                  await _controller.addOrUpdateVaccination(
                    existing: v,
                    name: nameCtrl.text.trim(),
                    desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    dateGiven: dateGiven!,
                    nextDue: nextDue,
                  );
                  setState(() => _vaccEditing[v.id] = false);
                }),
                if (editing) IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _vaccEditing[v.id] = false)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () async => await _controller.deleteVaccination(v.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === Inline Checkups ===
  Widget _checkupsTabInline() {
    if (_controller.loadingCheck) return const Center(child: CircularProgressIndicator());
    final rows = _controller.checkups.cast<MedicalCheckup>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((c) {
          final reasonCtrl = TextEditingController(text: c.reason);
          final descCtrl = TextEditingController(text: c.description ?? '');
          DateTime date = c.date;
          bool editing = _checkEditing[c.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing ? TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')) : Text(c.reason),
              subtitle: editing ? Column(children: [
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                _datePickerField('Date', date, (d) => setState(() => date = d))
              ]) : Text(_df.format(c.date)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _checkEditing[c.id] = true)),
                if (editing) IconButton(icon: const Icon(Icons.check), onPressed: () async {
                  await _controller.addOrUpdateCheckup(
                    existing: c,
                    reason: reasonCtrl.text.trim(),
                    desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    date: date,
                  );
                  setState(() => _checkEditing[c.id] = false);
                }),
                if (editing) IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _checkEditing[c.id] = false)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () async => await _controller.deleteCheckup(c.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === Inline Prescriptions ===
  Widget _prescriptionsTabInline() {
    if (_controller.loadingRx) return const Center(child: CircularProgressIndicator());
    final rows = _controller.prescriptions.cast<Prescription>();

    return SingleChildScrollView(
      child: Column(
        children: rows.map((p) {
          final medCtrl = TextEditingController(text: p.medicineName);
          final descCtrl = TextEditingController(text: p.description ?? '');
          DateTime start = p.startDate;
          DateTime? end = p.endDate;
          bool editing = _rxEditing[p.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: editing ? TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'Medicine')) : Text(p.medicineName),
              subtitle: editing ? Column(children: [
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _datePickerField('Start', start, (d) => setState(() => start = d))),
                  const SizedBox(width: 12),
                  Expanded(child: _datePickerField('End', end, (d) => setState(() => end = d))),
                ])
              ]) : Text('${_df.format(p.startDate)} - End: ${p.endDate != null ? _df.format(p.endDate!) : '—'}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _rxEditing[p.id] = true)),
                if (editing) IconButton(icon: const Icon(Icons.check), onPressed: () async {
                  await _controller.addOrUpdatePrescription(
                    existing: p,
                    med: medCtrl.text.trim(),
                    desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    start: start,
                    end: end,
                  );
                  setState(() => _rxEditing[p.id] = false);
                }),
                if (editing) IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _rxEditing[p.id] = false)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () async => await _controller.deletePrescription(p.id)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _datePickerField(String label, DateTime? date, Function(DateTime) onPick) {
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
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked != null) {
    setState(() => _imageFile = File(picked.path));
  }
}

  
}
