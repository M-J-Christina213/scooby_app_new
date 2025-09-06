import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/pet_owner_controller.dart';
import 'my_pets_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onGoToMyPets,});

  final VoidCallback? onGoToMyPets;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _primary = const Color(0xFF842EAC);
  final _sb = Supabase.instance.client;
  final _ownerCtrl = PetOwnerController();

  bool _loading = true;

  // Profile data
  String _name = '—';
  String _email = '—';
  String _phone = '—';
  String _address = '—';
  String _city = '—';
  String? _imageUrl;
  DateTime? _memberSince;
  int _petCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final owner = await _ownerCtrl.fetchCurrentOwner();
      if (owner != null) {
        _name = (owner['name'] as String?)?.trim() ?? '—';
        _email = (owner['email'] as String?)?.trim() ?? (user.email ?? '—');
        _phone = (owner['phone_number'] as String?)?.trim() ?? '—';
        _address = (owner['address'] as String?)?.trim() ?? '—';
        _city = (owner['city'] as String?)?.trim() ?? '—';
        _imageUrl = owner['image_url'] as String?;
        final created = owner['created_at'] as String?;
        _memberSince = created != null ? DateTime.tryParse(created) : null;

        // Count pets by pet_owners.id
        final ownerId = owner['id'] as String?;
        if (ownerId != null) {
          final pets = await _sb.from('pets').select('id').eq('user_id', ownerId);
          _petCount = (pets as List).length;
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    final a = parts.first[0].toUpperCase();
    final b = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return '$a$b';
  }

  Future<void> _openEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _name == '—' ? '' : _name);
    final phoneCtrl = TextEditingController(text: _phone == '—' ? '' : _phone);
    final addressCtrl = TextEditingController(text: _address == '—' ? '' : _address);
    final cityCtrl = TextEditingController(text: _city == '—' ? '' : _city);

    final formKey = GlobalKey<FormState>();
    XFile? pickedPhoto;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            bool isSaving = false;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, controller) {
                // Decide avatar image for the editor
                ImageProvider<Object>? avatarProvider;
                if (pickedPhoto != null) {
                  avatarProvider = FileImage(File(pickedPhoto!.path));
                } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                  avatarProvider = NetworkImage(_imageUrl!);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Header with avatar & title
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 42,
                                      backgroundImage: avatarProvider,
                                      backgroundColor: _primary.withOpacity(.1),
                                      child: avatarProvider == null
                                          ? Text(
                                        _initials,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: InkWell(
                                        onTap: isSaving
                                            ? null
                                            : () async {
                                          final img = await ImagePicker().pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 85,
                                          );
                                          if (img != null) {
                                            setSheetState(() => pickedPhoto = img);
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor:
                                          isSaving ? Colors.grey : _primary,
                                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _input(
                              label: 'Full Name',
                              controller: nameCtrl,
                              validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Name is required' : null,
                            ),
                            _input(
                              label: 'Phone',
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone is required';
                                }
                                final digits = v.replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 7) return 'Enter a valid phone number';
                                return null;
                              },
                            ),
                            _input(label: 'Address', controller: addressCtrl),
                            _input(label: 'City', controller: cityCtrl),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving ? null : () => Navigator.of(sheetCtx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                      if (!formKey.currentState!.validate()) return;

                                      try {
                                        setSheetState(() => isSaving = true);

                                        // Proceed with update (email is NOT editable)
                                        final newUrl =
                                        await _ownerCtrl.updateCurrentOwner(
                                          name: nameCtrl.text,
                                          phone: phoneCtrl.text,
                                          address: addressCtrl.text,
                                          city: cityCtrl.text,
                                          newProfileImage: pickedPhoto,
                                        );

                                        if (!mounted) return;

                                        // Close sheet first, then refresh UI
                                        Navigator.of(sheetCtx).pop();

                                        // Refresh profile data
                                        await _load();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Profile updated successfully'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.green.shade600,
                                          ),
                                        );

                                        if (newUrl != null) {
                                          setState(() => _imageUrl = newUrl);
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Update failed: $e'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.red.shade600,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setSheetState(() => isSaving = false);
                                        }
                                      }
                                    },
                                    child: Builder(
                                      builder: (_) => isSaving
                                          ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text('Saving...'),
                                        ],
                                      )
                                          : const Text('Save'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primary, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final memberText =
    _memberSince != null ? DateFormat('MMM d, yyyy').format(_memberSince!) : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty)
                        ? NetworkImage(_imageUrl!)
                        : null,
                    backgroundColor: _primary.withOpacity(.1),
                    child: (_imageUrl == null || _imageUrl!.isEmpty)
                        ? Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_city, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // THREE ROWS to prevent overflow
                  _statTile(Icons.pets, 'Pets', '$_petCount'),
                  const SizedBox(height: 8),
                  _statTile(Icons.apartment_rounded, 'City', _city),
                  const SizedBox(height: 8),
                  _statTile(Icons.event_available, 'Member Since', memberText),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact & address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: _primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Contact & Address',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email_outlined, 'Email', _email),
                  _infoRow(Icons.phone_outlined, 'Phone', _phone),
                  _infoRow(Icons.home_outlined, 'Address', _address),
                  _infoRow(Icons.location_city_outlined, 'City', _city),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            _primaryButton(
              label: 'Manage My Pets',
              icon: Icons.pets,
              onPressed: () {
                if (widget.onGoToMyPets != null) {
                  widget.onGoToMyPets!();              // ← switch tab inside HomeScreen
                } else {
                  // Fallback if ProfileScreen is ever used standalone
                  final uid = _sb.auth.currentUser?.id ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MyPetsScreen(userId: uid)),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _outlinedButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              onPressed: _openEditProfileDialog,
            ),
            const SizedBox(height: 12),
            _dangerButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await _sb.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // UI helpers
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _statTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _primary.withOpacity(.15),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _primary.withOpacity(.1),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _outlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: _primary),
        label: Text(label, style: TextStyle(color: _primary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _dangerButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          backgroundColor: Colors.red.withOpacity(.06),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
