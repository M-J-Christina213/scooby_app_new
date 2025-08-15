import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  late final MedicalRecordsController _controller;

  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _foodController;
  late TextEditingController _moodController;
  late TextEditingController _healthController;
  late TextEditingController _descController;

  final _primary = Colors.deepPurple;
  final _df = DateFormat('yyyy-MM-dd');
  File? _imageFile;
  String? _uploadedImageUrl;

  final Map<String, bool> _vaccEditing = {};
  final Map<String, bool> _checkEditing = {};
  final Map<String, bool> _rxEditing = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchBooking();
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

          _weightController = TextEditingController(text: pet!['weight'] ?? '');
          _heightController = TextEditingController(text: pet!['height'] ?? '');
          _foodController = TextEditingController(text: pet!['food_preference'] ?? '');
          _moodController = TextEditingController(text: pet!['mood'] ?? '');
          _healthController = TextEditingController(text: pet!['health_status'] ?? '');
          _descController = TextEditingController(text: pet!['description'] ?? '');

          _controller = MedicalRecordsController(
            service: SupabaseMedicalRecordService(supabase),
            petId: pet!['id'],
          );
          _controller.loadAll();
        }
      }
    } catch (e) {
      debugPrint('Error fetching booking: $e');
    }
    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _updatePetDetails() async {
    if (_imageFile != null) {
      final fileName =
          'pet_${pet!['id']}_${DateTime.now().millisecondsSinceEpoch}.png';
      final url = await PetService.instance
          .uploadPetImage(widget.userId, _imageFile!.path, fileName);
      if (url != null) _uploadedImageUrl = url;
      _imageFile = null;
    }

    await PetService.instance.updatePet(
      Pet(
        id: pet!['id'],
        userId: widget.userId,
        name: pet!['name'],
        type: pet!['type'],
        breed: pet!['breed'],
        age: pet!['age'],
        gender: pet!['gender'],
        color: pet!['color'],
        weight: _weightController.text.trim().isEmpty ? null : double.tryParse(_weightController.text.trim()),
        height: _heightController.text.trim().isEmpty ? null : double.tryParse(_heightController.text.trim()),
        foodPreference: _foodController.text.trim().isEmpty ? null : _foodController.text.trim(),
        mood: _moodController.text.trim().isEmpty ? null : _moodController.text.trim(),
        healthStatus: _healthController.text.trim().isEmpty ? null : _healthController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        imageUrl: _uploadedImageUrl ?? pet!['image_url'],
      ),
      widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: _primary,
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null || pet == null
              ? const Center(child: Text('Booking or Pet not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ownerInfoCard(),
                      const SizedBox(height: 16),
                      _petInfoCard(),
                      const SizedBox(height: 24),
                      _medicalRecordsInline(),
                    ],
                  ),
                ),
      floatingActionButton: 
           FloatingActionButton(
              backgroundColor: _primary,
              onPressed: _addMedicalRecord,
              child: const Icon(Icons.add, color: Colors.white),
            )
           
    );
  }

  Widget _ownerInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking!['owner_name'] ?? '',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 8),
            _infoRow(Icons.email, booking!['owner_email']),
            _infoRow(Icons.phone, booking!['owner_phone']),
            _infoRow(Icons.calendar_today,
                booking!['date'] != null ? DateFormat.yMMMd().format(DateTime.parse(booking!['date'])) : ''),
            _infoRow(Icons.access_time, booking!['time']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 8),
          Text(text ?? '-', style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _petInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (pet!['image_url'] != null
                              ? NetworkImage(pet!['image_url'])
                              : null) as ImageProvider<Object>?,
                      child: pet!['image_url'] == null && _imageFile == null
                          ? Icon(Icons.pets, color: _primary, size: 40)
                          : null,
                    ),
                  
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: _primary,
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet!['name'] ?? '',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primary)),
                      const SizedBox(height: 4),
                      Text('Type: ${pet!['type'] ?? '-'}'),
                      Text('Breed: ${pet!['breed'] ?? '-'}'),
                      Text('Age: ${pet!['age'] ?? '-'}'),
                      Text('Gender: ${pet!['gender'] ?? '-'}'),
                      Text('Color: ${pet!['color'] ?? '-'}'),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 24),
         
              _editableRow('Weight', _weightController),
              _editableRow('Height', _heightController),
              _editableRow('Food Preference', _foodController),
              _editableRow('Mood', _moodController),
              _editableRow('Health Status', _healthController),
              _editableRow('Description', _descController),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _updatePetDetails,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Pet Details'),
              ),
            ],
          
        ),
      ),
    );
  }

  Widget _editableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Your medical records inline widget remains same
  Widget _medicalRecordsInline() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.health_and_safety, color: _primary),
              const SizedBox(width: 8),
              const Text('Medical Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: _primary,
              indicatorColor: _primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Vaccinations'),
                Tab(text: 'Checkups'),
                Tab(text: 'Prescriptions'),
              ],
            ),
            SizedBox(
              height: 450,
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
    );
  }

  void _addMedicalRecord() async {
    final index = _tabController.index;

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
              onPressed: () => Navigator.pop(dialogContext),
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
  }

  // === Tab Widgets ===
  Widget _vaccinationsTabInline() => _controller.vaccinations.isEmpty
      ? const Center(child: Text('No vaccinations found'))
      : SingleChildScrollView(
          child: Column(
            children: _controller.vaccinations.map((v) {
              final nameCtrl = TextEditingController(text: v.vaccinationName);
              final descCtrl = TextEditingController(text: v.description ?? '');
              DateTime? dateGiven = v.dateGiven;
              DateTime? nextDue = v.nextDueDate;
              bool editing = _vaccEditing[v.id] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: editing
                      ? TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'))
                      : Text(v.vaccinationName),
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
                                    child: _datePickerField(
                                        'Date Given', dateGiven, (d) {
                                  setState(() => dateGiven = d);
                                })),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _datePickerField(
                                        'Next Due', nextDue, (d) {
                                  setState(() => nextDue = d);
                                })),
                              ],
                            )
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${_df.format(v.dateGiven)} - Next: ${v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—'}'),
                            if (v.description != null && v.description!.isNotEmpty)
                              Text(v.description!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
                          onPressed: () =>
                              setState(() => _vaccEditing[v.id] = false)),
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

  Widget _checkupsTabInline() => _controller.checkups.isEmpty
      ? const Center(child: Text('No checkups found'))
      : SingleChildScrollView(
          child: Column(
            children: _controller.checkups.map((c) {
              final reasonCtrl = TextEditingController(text: c.reason);
              final descCtrl = TextEditingController(text: c.description ?? '');
              DateTime date = c.date;
              bool editing = _checkEditing[c.id] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: editing
                      ? TextField(
                          controller: reasonCtrl,
                          decoration: const InputDecoration(labelText: 'Reason'))
                      : Text(c.reason),
                  subtitle: editing
                      ? Column(
                          children: [
                            TextField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Description')),
                            const SizedBox(height: 8),
                            _datePickerField('Date', date, (d) => setState(() => date = d)),
                          ],
                        )
                      : Text(_df.format(c.date)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!editing)
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              setState(() => _checkEditing[c.id] = true)),
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
                              date: date,
                            );
                            setState(() => _checkEditing[c.id] = false);
                          }),
                    if (editing)
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _checkEditing[c.id] = false)),
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

  Widget _prescriptionsTabInline() => _controller.prescriptions.isEmpty
      ? const Center(child: Text('No prescriptions found'))
      : SingleChildScrollView(
          child: Column(
            children: _controller.prescriptions.map((p) {
              final medCtrl = TextEditingController(text: p.medicineName);
              final descCtrl = TextEditingController(text: p.description ?? '');
              DateTime start = p.startDate;
              DateTime? end = p.endDate;
              bool editing = _rxEditing[p.id] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: editing
                      ? TextField(
                          controller: medCtrl,
                          decoration: const InputDecoration(labelText: 'Medicine'))
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
                                        (d) => setState(() => start = d))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _datePickerField('End', end,
                                        (d) => setState(() => end = d))),
                              ],
                            )
                          ],
                        )
                      : Text(
                          '${_df.format(p.startDate)} - End: ${p.endDate != null ? _df.format(p.endDate!) : '—'}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
                              start: start,
                              end: end,
                            );
                            setState(() => _rxEditing[p.id] = false);
                          }),
                    if (editing)
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _rxEditing[p.id] = false)),
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(date != null ? _df.format(date) : '—'),
      ),
    );
  }
}
