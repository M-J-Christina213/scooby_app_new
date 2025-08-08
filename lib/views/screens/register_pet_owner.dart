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
  final AuthService _authService = AuthService();

  final List<String> _cities = [
    'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Anuradhapura', 'Kurunegala'
  ];
  String? _selectedCity;
  File? _profileImage;
  bool _obscurePassword = true;

  void _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
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
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: purple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
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
          // Centered logo
          Center(
              child: Image.asset(
                'assets/images/scooby_logo.jpeg',
                height: 180,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4), // Reduced from 12 to 4

            const Text(
              'Register as Pet Owner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
              textAlign: TextAlign.left,
            ),
 

          // Card-like form container
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
                              : const AssetImage('assets/images/default_user.png') as ImageProvider,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to change profile photo',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(label: 'Full Name'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(label: 'Phone Number'),
                    validator: (val) {
                      if (val == null || val.length != 10 || int.tryParse(val) == null) {
                        return 'Enter valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email Address',
                      prefixIcon: Icons.email,
                    ),
                    validator: (val) =>
                        val == null || !val.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      label: 'Password',
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 8) return 'Min 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    items: _cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCity = val),
                    decoration: _inputDecoration(label: 'Main City'),
                    validator: (val) => val == null ? 'Select city' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration(label: 'Address'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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