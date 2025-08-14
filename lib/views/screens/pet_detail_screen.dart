import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scooby_app_new/controllers/medical_records_controller.dart';
import 'package:scooby_app_new/models/medical_records.dart';
import 'package:scooby_app_new/services/medical_record_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetDetailScreenModernIntegrated extends StatefulWidget {
  // Basic pet fields from your existing Pet model (uuid ids etc.)
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
                _medicalRecords(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            color: Colors.white.withAlpha(0.92 as int),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(0.08 as int), blurRadius: 12, offset: const Offset(0, 6))],
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
            border: Border.all(color: _primary.withAlpha(0.12 as int)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(0.04 as int), blurRadius: 8, offset: const Offset(0, 4))],
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

  Widget _medicalRecords() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.health_and_safety, color: _primary), const SizedBox(width: 8), const Text('Medical Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 8),
            TabBar(controller: _tabController, labelColor: _primary, indicatorColor: _primary, unselectedLabelColor: Colors.grey, tabs: const [
              Tab(text: 'Vaccinations'), Tab(text: 'Medical Checkups'), Tab(text: 'Prescriptions'),
            ]),
            SizedBox(height: 440, child: TabBarView(controller: _tabController, children: [
              _vaccinationsTab(), _checkupsTab(), _prescriptionsTab(),
            ])),
          ]),
        ),
      ),
    );
  }

  // ---------------- Tabs (CRUD) ----------------
  Widget _vaccinationsTab() {
    if (_controller.loadingVacc) return const Center(child: CircularProgressIndicator());
    final rows = _controller.vaccinations.cast<Vaccination>();
    return Stack(children: [
      rows.isEmpty
          ? const Center(child: Text('No vaccinations yet'))
          : SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.purple.shade50),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Date Given')),
                  DataColumn(label: Text('Next Due')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map((v) => DataRow(cells: [
                          DataCell(Text(v.vaccinationName)),
                          DataCell(Text((v.description ?? '').trim().isEmpty ? '—' : v.description!)),
                          DataCell(Text(_df.format(v.dateGiven))),
                          DataCell(Text(v.nextDueDate != null ? _df.format(v.nextDueDate!) : '—')),
                          DataCell(Row(children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _openVaccForm(existing: v)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async { await _controller.deleteVaccination(v.id); }),
                          ])),
                        ]))
                    .toList(),
              ),
            ),
      Positioned(
        bottom: 12, right: 12,
        child: FloatingActionButton.extended(backgroundColor: _primary, onPressed: () => _openVaccForm(), icon: const Icon(Icons.add), label: const Text('Add Vaccination')),
      ),
    ]);
  }

  Future<void> _openVaccForm({Vaccination? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.vaccinationName ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    DateTime? dateGiven = existing?.dateGiven ?? DateTime.now();
    DateTime? nextDue = existing?.nextDueDate;

    await _bottomSheet(
      title: existing == null ? 'Add Vaccination' : 'Edit Vaccination',
      children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DatePickerTile(label: 'Date given *', date: dateGiven, onPick: (d) => dateGiven = d)),
          const SizedBox(width: 12),
          Expanded(child: _DatePickerTile(label: 'Next due', date: nextDue, onPick: (d) => nextDue = d)),
        ]),
        const SizedBox(height: 16),
        _saveBtn(onPressed: () async {
          if (nameCtrl.text.trim().isEmpty || dateGiven == null) return;
          await _controller.addOrUpdateVaccination(existing: existing, name: nameCtrl.text.trim(), desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), dateGiven: dateGiven!, nextDue: nextDue);
          if (!mounted) return; 
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _checkupsTab() {
    if (_controller.loadingCheck) return const Center(child: CircularProgressIndicator());
    final rows = _controller.checkups.cast<MedicalCheckup>();
    return Stack(children: [
      rows.isEmpty
          ? const Center(child: Text('No checkups yet'))
          : SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.purple.shade50),
                columns: const [
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map((c) => DataRow(cells: [
                          DataCell(Text(c.reason)),
                          DataCell(Text((c.description ?? '').trim().isEmpty ? '—' : c.description!)),
                          DataCell(Text(_df.format(c.date))),
                          DataCell(Row(children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _openCheckupForm(existing: c)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async { await _controller.deleteCheckup(c.id); }),
                          ])),
                        ]))
                    .toList(),
              ),
            ),
      Positioned(
        bottom: 12, right: 12,
        child: FloatingActionButton.extended(backgroundColor: _primary, onPressed: () => _openCheckupForm(), icon: const Icon(Icons.add), label: const Text('Add Checkup')),
      ),
    ]);
  }

  Future<void> _openCheckupForm({MedicalCheckup? existing}) async {
    final reasonCtrl = TextEditingController(text: existing?.reason ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    DateTime? date = existing?.date ?? DateTime.now();

    await _bottomSheet(
      title: existing == null ? 'Add Checkup' : 'Edit Checkup',
      children: [
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        _DatePickerTile(label: 'Date *', date: date, onPick: (d) => date = d),
        const SizedBox(height: 16),
        _saveBtn(onPressed: () async {
          if (reasonCtrl.text.trim().isEmpty || date == null) return;
          await _controller.addOrUpdateCheckup(existing: existing, reason: reasonCtrl.text.trim(), desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), date: date!);
          if (!mounted) return; 
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _prescriptionsTab() {
    if (_controller.loadingRx) return const Center(child: CircularProgressIndicator());
    final rows = _controller.prescriptions.cast<Prescription>();
    return Stack(children: [
      rows.isEmpty
          ? const Center(child: Text('No prescriptions yet'))
          : SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.purple.shade50),
                columns: const [
                  DataColumn(label: Text('Medicine')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Start')),
                  DataColumn(label: Text('End')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map((p) => DataRow(cells: [
                          DataCell(Text(p.medicineName)),
                          DataCell(Text((p.description ?? '').trim().isEmpty ? '—' : p.description!)),
                          DataCell(Text(_df.format(p.startDate))),
                          DataCell(Text(p.endDate != null ? _df.format(p.endDate!) : '—')),
                          DataCell(Row(children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _openRxForm(existing: p)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async { await _controller.deletePrescription(p.id); }),
                          ])),
                        ]))
                    .toList(),
              ),
            ),
      Positioned(
        bottom: 12, right: 12,
        child: FloatingActionButton.extended(backgroundColor: _primary, onPressed: () => _openRxForm(), icon: const Icon(Icons.add), label: const Text('Add Prescription')),
      ),
    ]);
  }

  Future<void> _openRxForm({Prescription? existing}) async {
    final medCtrl = TextEditingController(text: existing?.medicineName ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    DateTime? start = existing?.startDate ?? DateTime.now();
    DateTime? end = existing?.endDate;

    await _bottomSheet(
      title: existing == null ? 'Add Prescription' : 'Edit Prescription',
      children: [
        TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'Medicine name *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DatePickerTile(label: 'Start *', date: start, onPick: (d) => start = d)),
          const SizedBox(width: 12),
          Expanded(child: _DatePickerTile(label: 'End', date: end, onPick: (d) => end = d)),
        ]),
        const SizedBox(height: 16),
        _saveBtn(onPressed: () async {
          if (medCtrl.text.trim().isEmpty || start == null) return;
          await _controller.addOrUpdatePrescription(existing: existing, med: medCtrl.text.trim(), desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), start: start!, end: end);
          if (!mounted) return;
          Navigator.pop(context);
        }),
      ],
    );
  }

  Future<void> _bottomSheet({required String title, required List<Widget> children}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }

  Widget _saveBtn({required VoidCallback onPressed}) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
      child: const Text('Save'),
    ),
  );
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;
  const _DatePickerTile({required this.label, required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 10),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF842EAC))),
            child: child!,
          ),
        );
        onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(date != null ? df.format(date!) : '—'),
      ),
    );
  }
}
