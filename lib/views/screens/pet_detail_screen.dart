import 'package:flutter/material.dart';
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
                ),
                widget.userId,
              );

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


   Widget _heroHeader() {
    return Stack(children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            image: widget.imageUrl != null ? DecorationImage(image: NetworkImage(widget.imageUrl!), fit: BoxFit.cover) : null,
          ),
        ),
      ),
      Positioned(
        bottom: 12, left: 16, right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.92 * 255).toInt()),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.08 * 255).toInt()), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
              child: widget.imageUrl == null ? Icon(Icons.pets, color: _primary, size: 28) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text('${widget.type} • ${widget.breed}', style: TextStyle(color: Colors.grey.shade700)),
            ])),
          ]),
        ),
      ),
    ]);
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
    final rows = <(String, String)>[
      ('Food Preference', widget.foodPreference ?? '—'),
      ('Mood', widget.mood ?? '—'),
      ('Health Status', widget.healthStatus ?? '—'),
      ('Description', widget.description ?? '—'),
    ];
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
            ...rows.map((r) => _kvRow(r.$1, r.$2)),
          ]),
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 140, child: Text(k, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800))),
      Expanded(child: Text(v, style: const TextStyle(color: Colors.black87))),
    ]),
  );


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

  
}
