import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scooby_app_new/services/auth_services.dart';
import 'package:scooby_app_new/views/login_screen.dart';

class ServiceProviderRegisterScreen extends StatefulWidget {
  const ServiceProviderRegisterScreen({super.key});

  @override
  State<ServiceProviderRegisterScreen> createState() => _ServiceProviderRegisterScreenState();
}

class _ServiceProviderRegisterScreenState extends State<ServiceProviderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _clinicOrSalonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _notesController = TextEditingController();
  final AuthService _authService = AuthService();

  File? _profileImage;
  List<File> _galleryImages = [];
  File? _qualificationFile;
  bool _obscurePassword = true;
  String? _selectedCity;
  String? _selectedServiceType;
  final List<String> _cities = ['Colombo', 'Kandy', 'Galle', 'Jaffna'];
  final List<String> _serviceTypes = ['Veterinarian', 'Pet Groomer', 'Pet Sitter'];

  void _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _galleryImages = picked.map((e) => File(e.path)).toList());
    }
  }

  void _pickQualification() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _qualificationFile = File(picked.path));
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
        await _authService.registerServiceProvider(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          address: _addressController.text.trim(),
          city: _selectedCity ?? '',
          serviceType: _selectedServiceType ?? '',
          clinicOrSalon: _clinicOrSalonController.text.trim(),
          profileImage: _profileImage,
          galleryImages: _galleryImages,
          qualificationFile: _qualificationFile,
          experience: _experienceController.text.trim(),
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service provider registered successfully.')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF842EAC), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF842EAC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset('assets/images/scooby_logo.jpeg', height: 160),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register as Service Provider',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: purple),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 4),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/default_user.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(controller: _nameController, decoration: _inputDecoration('Full Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone Number'), keyboardType: TextInputType.phone, validator: (val) => val!.length != 10 ? 'Enter valid number' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _emailController, decoration: _inputDecoration('Email'), keyboardType: TextInputType.emailAddress, validator: (val) => !val!.contains('@') ? 'Invalid email' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val!.length < 8 ? 'Min 8 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      items: _cities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedCity = val),
                      decoration: _inputDecoration('City'),
                      validator: (val) => val == null ? 'Select city' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _addressController, decoration: _inputDecoration('Address'), validator: (val) => val!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      items: _serviceTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedServiceType = val),
                      decoration: _inputDecoration('Service Type'),
                      validator: (val) => val == null ? 'Select service' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedServiceType == 'Veterinarian' || _selectedServiceType == 'Pet Groomer')
                      Column(children: [
                        TextFormField(controller: _clinicOrSalonController, decoration: _inputDecoration(_selectedServiceType == 'Veterinarian' ? 'Clinic Name' : 'Salon Name')),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickQualification,
                          icon: const Icon(Icons.file_present),
                          label: const Text('Upload Qualification'),
                          style: ElevatedButton.styleFrom(backgroundColor: purple),
                        ),
                      ]),
                    if (_selectedServiceType == 'Pet Sitter')
                      TextFormField(controller: _notesController, decoration: _inputDecoration('Notes or Preferences')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _experienceController, decoration: _inputDecoration('Years of Experience')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descriptionController, decoration: _inputDecoration('Service Description'), maxLines: 3),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Gallery Images'),
                      style: ElevatedButton.styleFrom(backgroundColor: purple),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Register', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
