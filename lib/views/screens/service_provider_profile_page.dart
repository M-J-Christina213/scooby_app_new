// lib/views/screens/service_provider_profile_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scooby_app_new/models/service_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceProviderProfilePage extends StatefulWidget {
  final String serviceProviderEmail;

  const ServiceProviderProfilePage({
    super.key,
    required this.serviceProviderEmail,
  });

  @override
  State<ServiceProviderProfilePage> createState() =>
      _ServiceProviderProfilePageState();
}

class _ServiceProviderProfilePageState extends State<ServiceProviderProfilePage> {
  static const Color kPrimary = Color(0xFF842EAC);
  static const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(16, 16, 16, 24);

  final supabase = Supabase.instance.client;

  ServiceProvider? _provider;
  bool _loading = true;

  // Edit mode
  bool _editing = false;

  // Controllers (everything except email)
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _roleC = TextEditingController();
  final _cityC = TextEditingController();
  final _experienceC = TextEditingController();
  final _availableTimesC = TextEditingController();

  final _clinicNameC = TextEditingController();
  final _clinicAddressC = TextEditingController();
  final _aboutClinicC = TextEditingController();

  final _serviceDescC = TextEditingController();
  final _groomingServicesC = TextEditingController(); // comma-separated
  final _comfortableWithC = TextEditingController(); // comma-separated

  final _consultationFeeC = TextEditingController();
  final _pricingDetailsC = TextEditingController();
  final _rateC = TextEditingController();
  final _dislikesC = TextEditingController();

  final _qualificationUrlC = TextEditingController();
  final _verificationUrlC = TextEditingController();

  final _galleryImagesC = TextEditingController(); // comma-separated
  final _notesC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _roleC.dispose();
    _cityC.dispose();
    _experienceC.dispose();
    _availableTimesC.dispose();
    _clinicNameC.dispose();
    _clinicAddressC.dispose();
    _aboutClinicC.dispose();
    _serviceDescC.dispose();
    _groomingServicesC.dispose();
    _comfortableWithC.dispose();
    _consultationFeeC.dispose();
    _pricingDetailsC.dispose();
    _rateC.dispose();
    _dislikesC.dispose();
    _qualificationUrlC.dispose();
    _verificationUrlC.dispose();
    _galleryImagesC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final email = widget.serviceProviderEmail.trim();
      if (email.isEmpty) {
        _provider = null;
      } else {
        final resp = await supabase
            .from('service_providers')
            .select()
            .eq('email', email)
            .maybeSingle();
        if (resp != null) {
          _provider = ServiceProvider.fromMap(resp);
          _bindControllersFromProvider(_provider!);
        } else {
          _provider = null;
        }
      }
    } catch (_) {
      _provider = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bindControllersFromProvider(ServiceProvider p) {
    _nameC.text = p.name;
    _phoneC.text = p.phoneNo;
    _roleC.text = p.role;
    _cityC.text = p.city;
    _experienceC.text = p.experience;
    _availableTimesC.text = p.availableTimes;

    _clinicNameC.text = p.clinicOrSalonName;
    _clinicAddressC.text = p.clinicOrSalonAddress;
    _aboutClinicC.text = p.aboutClinicSalon;

    _serviceDescC.text = p.serviceDescription;
    _groomingServicesC.text = p.groomingServices.join(', ');
    _comfortableWithC.text = p.comfortableWith.join(', ');

    _consultationFeeC.text = p.consultationFee;
    _pricingDetailsC.text = p.pricingDetails;
    _rateC.text = p.rate;
    _dislikesC.text = p.dislikes;

    _qualificationUrlC.text = p.qualificationUrl;
    _verificationUrlC.text = p.verificationUrl;

    _galleryImagesC.text = p.galleryImages.join(', ');
    _notesC.text = p.notes;
  }

  List<String> _toList(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _saveEdits() async {
    if (_provider == null) return;
    setState(() => _loading = true);

    // Build update payload (email stays unchanged / not included)
    final payload = {
      'name': _nameC.text.trim(),
      'phone_no': _phoneC.text.trim(),
      'role': _roleC.text.trim(),
      'city': _cityC.text.trim(),
      'experience': _experienceC.text.trim(),
      'available_times': _availableTimesC.text.trim(),

      'clinic_or_salon_name': _clinicNameC.text.trim(),
      'clinic_or_salon_address': _clinicAddressC.text.trim(),
      'about_clinic_salon': _aboutClinicC.text.trim(),

      'service_description': _serviceDescC.text.trim(),
      'grooming_services': _toList(_groomingServicesC.text),
      'comfortable_with': _toList(_comfortableWithC.text),

      'consultation_fee': _consultationFeeC.text.trim(),
      'pricing_details': _pricingDetailsC.text.trim(),
      'rate': _rateC.text.trim(),
      'dislikes': _dislikesC.text.trim(),

      'qualification_url': _qualificationUrlC.text.trim(),
      'verification_url': _verificationUrlC.text.trim(),

      'gallery_images': _toList(_galleryImagesC.text),
      'notes': _notesC.text.trim(),
    };

    try {
      await supabase
          .from('service_providers')
          .update(payload)
          .eq('email', widget.serviceProviderEmail);

      // re-fetch to sync with DB
      await _fetchProfile();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  // ————————————————————————————————————————————————————————————————
  // UI helpers

  Widget _header(ServiceProvider p) {
    final name = _editing ? _nameC.text : (p.name.isNotEmpty ? p.name : 'Service Provider');
    final hasImage = p.profileImageUrl.isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7E2CCB), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(.2),
            backgroundImage: hasImage ? NetworkImage(p.profileImageUrl) : null,
            child: !hasImage
                ? Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _editing
                    ? TextField(
                  controller: _nameC,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Name',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                )
                    : Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(text: _editing ? _roleC.text : p.role, icon: Icons.work),
                    if ((_editing ? _cityC.text : p.city).isNotEmpty)
                      _chip(text: _editing ? _cityC.text : p.city, icon: Icons.location_on),
                    if ((_editing ? _experienceC.text : p.experience).isNotEmpty)
                      _chip(text: '${_editing ? _experienceC.text : p.experience} yrs exp', icon: Icons.school),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String text, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: kPrimary, size: 18),
                ),
              if (icon != null) const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _rowTile(String label, String value, {IconData? icon, bool copyable = false}) {
    final showValue = value.isNotEmpty ? value : 'Not specified';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        showValue,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (copyable && value.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Editable field row (styled)
  Widget _editField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _chipsWrap(List<String> items) {
    if (items.isEmpty) {
      return Text('Not specified', style: TextStyle(color: Colors.grey.shade700));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            s,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _gallery(List<String> urls) {
    if (urls.isEmpty) {
      return Text('No images uploaded', style: TextStyle(color: Colors.grey.shade700));
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final u = urls[i];
          final isNet = u.startsWith('http');
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isNet ? Image.network(u, fit: BoxFit.cover) : Image.asset(u, fit: BoxFit.cover),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNet
                  ? Image.network(u, width: 140, height: 110, fit: BoxFit.cover)
                  : Image.asset(u, width: 140, height: 110, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _docButtons(String qUrl, String vUrl) {
    final hasQ = qUrl.isNotEmpty;
    final hasV = vUrl.isNotEmpty;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: hasQ
              ? () {
            Clipboard.setData(ClipboardData(text: qUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Qualification URL copied')),
            );
          }
              : null,
          icon: const Icon(Icons.description),
          label: const Text('Qualification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasQ ? kPrimary : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        ElevatedButton.icon(
          onPressed: hasV
              ? () {
            Clipboard.setData(ClipboardData(text: vUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID Verification URL copied')),
            );
          }
              : null,
          icon: const Icon(Icons.verified_user),
          label: const Text('ID Verification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasV ? kPrimary : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ————————————————————————————————————————————————————————————————
  // Build

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_provider == null) {
      return Padding(
        padding: kScreenPadding,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Profile not found',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'We couldn\'t load this service provider.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    final p = _provider!;

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: ListView(
        padding: kScreenPadding,
        children: [
          // Edit / Save controls
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_editing)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _editing = false;
                        _bindControllersFromProvider(p);
                      }),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: _saveEdits,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          _header(p),

          // Contact & Basics
          _sectionCard(
            title: 'Contact & Basics',
            icon: Icons.info_outline,
            children: _editing
                ? [
              _editField(label: 'Email (read-only)', controller: TextEditingController(text: p.email), icon: Icons.alternate_email, enabled: false),
              _editField(label: 'Phone', controller: _phoneC, icon: Icons.call, keyboardType: TextInputType.phone),
              _editField(label: 'Role', controller: _roleC, icon: Icons.work),
              _editField(label: 'City', controller: _cityC, icon: Icons.location_city),
              _editField(label: 'Experience (years)', controller: _experienceC, icon: Icons.school, keyboardType: TextInputType.number),
              _editField(label: 'Available Times', controller: _availableTimesC, icon: Icons.schedule),
            ]
                : [
              _rowTile('Email', p.email, icon: Icons.alternate_email, copyable: true),
              _rowTile('Phone', p.phoneNo, icon: Icons.call, copyable: true),
              _rowTile('City', p.city, icon: Icons.location_city),
              _rowTile('Available Times', p.availableTimes, icon: Icons.schedule),
            ],
          ),

          // Clinic / Salon
          _sectionCard(
            title: p.role.toLowerCase() == 'pet groomer'
                ? 'Salon'
                : p.role.toLowerCase() == 'veterinarian'
                ? 'Clinic'
                : 'Workplace',
            icon: Icons.store_mall_directory_outlined,
            children: _editing
                ? [
              _editField(label: 'Name', controller: _clinicNameC, icon: Icons.badge),
              _editField(label: 'Address', controller: _clinicAddressC, icon: Icons.place, maxLines: 2),
              _editField(label: 'About', controller: _aboutClinicC, icon: Icons.notes, maxLines: 3),
            ]
                : [
              _rowTile('Name', p.clinicOrSalonName, icon: Icons.badge),
              _rowTile('Address', p.clinicOrSalonAddress, icon: Icons.place),
              if (p.aboutClinicSalon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(p.aboutClinicSalon),
                ),
            ],
          ),

          // Services
          _sectionCard(
            title: 'Services',
            icon: Icons.design_services_outlined,
            children: _editing
                ? [
              _editField(label: 'Service Description', controller: _serviceDescC, icon: Icons.text_snippet, maxLines: 3),
              _editField(label: 'Grooming Services (comma-separated)', controller: _groomingServicesC, icon: Icons.content_cut),
              _editField(label: 'Comfortable With (comma-separated)', controller: _comfortableWithC, icon: Icons.pets),
            ]
                : [
              if (p.serviceDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p.serviceDescription),
                ),
              if (p.groomingServices.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Grooming Services',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                _chipsWrap(p.groomingServices),
                const SizedBox(height: 10),
              ],
              if (p.comfortableWith.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Comfortable With',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                _chipsWrap(p.comfortableWith),
              ],
            ],
          ),

          // Pricing
          _sectionCard(
            title: 'Pricing',
            icon: Icons.payments_outlined,
            children: _editing
                ? [
              _editField(label: 'Consultation Fee', controller: _consultationFeeC, icon: Icons.local_hospital, keyboardType: TextInputType.number),
              _editField(label: 'Pricing Details', controller: _pricingDetailsC, icon: Icons.price_change, maxLines: 3),
              _editField(label: 'Rate (Sitter)', controller: _rateC, icon: Icons.timer, keyboardType: TextInputType.number),
              _editField(label: 'Dislikes / Exclusions', controller: _dislikesC, icon: Icons.block, maxLines: 2),
            ]
                : [
              _rowTile('Consultation Fee', p.consultationFee, icon: Icons.local_hospital),
              _rowTile('Pricing Details', p.pricingDetails, icon: Icons.price_change),
              _rowTile('Rate (Sitter)', p.rate, icon: Icons.timer),
              if (p.dislikes.isNotEmpty)
                _rowTile('Dislikes / Exclusions', p.dislikes, icon: Icons.block),
            ],
          ),

          // Documents
          _sectionCard(
            title: 'Documents',
            icon: Icons.folder_open_outlined,
            children: _editing
                ? [
              _editField(label: 'Qualification URL', controller: _qualificationUrlC, icon: Icons.description),
              _editField(label: 'Verification URL', controller: _verificationUrlC, icon: Icons.verified_user),
            ]
                : [
              _docButtons(p.qualificationUrl, p.verificationUrl),
            ],
          ),

          // Gallery
          _sectionCard(
            title: 'Gallery',
            icon: Icons.photo_library_outlined,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            children: _editing
                ? [
              _editField(
                label: 'Image URLs (comma-separated)',
                controller: _galleryImagesC,
                icon: Icons.image,
                maxLines: 3,
                hint: 'https://... , https://...',
              ),
            ]
                : [
              _gallery(p.galleryImages),
            ],
          ),

          // Notes
          _sectionCard(
            title: 'Notes',
            icon: Icons.sticky_note_2_outlined,
            children: _editing
                ? [
              _editField(label: 'Notes', controller: _notesC, icon: Icons.edit_note, maxLines: 4),
            ]
                : [
              Text(p.notes.isNotEmpty ? p.notes : 'Not specified'),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
