// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scooby_app_new/services/auth_services.dart';
import 'package:scooby_app_new/views/screens/login_screen.dart';

class PetOwnerRegisterScreen extends StatefulWidget {
  const PetOwnerRegisterScreen({super.key});

  @override
  State<PetOwnerRegisterScreen> createState() => _PetOwnerRegisterScreenState();
}

class _PetOwnerRegisterScreenState extends State<PetOwnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  final List<String> _cities = [
    'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Anuradhapura', 'Kurunegala'
  ];
  String? _selectedCity;
  File? _profileImage;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _authService.registerPetOwner(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity ?? '',
        email: _emailController.text.trim(),
        // send plaintext; server (e.g., Supabase) will hash
        password: _passwordController.text.trim(),
        profileImage: _profileImage,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      Flushbar(
        message: 'Registered successfully. Please log in.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    const purple = Color(0xFF842EAC);
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: purple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // Simple strength check: 8+ chars, 1 upper, 1 lower
  String? _validatePassword(String? val) {
    final v = val?.trim() ?? '';
    if (v.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add at least one lowercase letter';
    // If you also want a digit, uncomment:
    // if (!RegExp(r'\d').hasMatch(v)) return 'Add at least one number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF842EAC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/scooby_logo.jpeg',
                height: 180,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Register as Pet Owner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
              textAlign: TextAlign.left,
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage('assets/images/default_user.png')
                            as ImageProvider,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to change profile photo',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(label: 'Full Name'),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(label: 'Phone Number'),
                      validator: (val) {
                        if (val == null ||
                            val.length != 10 ||
                            int.tryParse(val) == null) {
                          return 'Enter valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: 'Email Address',
                        prefixIcon: Icons.email,
                      ),
                      validator: (val) =>
                      val == null || !val.contains('@')
                          ? 'Invalid email'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmPasswordController,
                      textInputAction: TextInputAction.next,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration(
                        label: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (val.trim() != _passwordController.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _cities.contains(_selectedCity) ? _selectedCity : null,
                      hint: const Text('Select a city'),
                      items: _cities
                          .map((city) =>
                          DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCity = val),
                      decoration: _inputDecoration(label: 'Main City'),
                      validator: (val) => val == null ? 'Select city' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(label: 'Address'),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
