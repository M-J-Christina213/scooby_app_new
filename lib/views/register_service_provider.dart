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
  final _clinicOrSalonController = TextEditingController();
  final _clinicNameController = TextEditingController();
 final _clinicAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _notesController = TextEditingController();
  final _pricingController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _aboutClinicOrSalonController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _rateController = TextEditingController();
  final _availableDaysTimesController = TextEditingController();
  final _authService = AuthService();

  File? _profileImage;
  List<File> _galleryImages = [];
  File? _qualificationFile;
  File? _idVerificationFile;
  bool _obscurePassword = true;
  String? _selectedCity;
  String? _selectedServiceType;
  final List<String> _selectedGroomingServices = [];
  final List<String> _selectedComfortableWith = [];

  final List<String> _cities = ['Colombo', 'Gampaha', 'Kandy', 'Galle', 'Matara', 'Jaffna', 'Anuradhapura'];
  final List<String> _serviceTypes = ['Veterinarian', 'Pet Groomer', 'Pet Sitter'];
  final List<String> _groomingServices = ['Bathing', 'Hair Trimming', 'Nail Clipping', 'Styling', 'Others'];
  final List<String> _comfortableWith = ['Dogs', 'Cats'];

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

  void _pickVerificationFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _idVerificationFile = File(picked.path));
    }
  }

  void _register() async {
    if (_formKey.currentState == null) {
      debugPrint('FormState is null, cannot validate.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _authService.registerServiceProvider(
  name: _nameController.text.trim(),
  phoneNo: _phoneController.text.trim(),
  email: _emailController.text.trim(),
  password: _passwordController.text.trim(),
  clinicOrSalon: _clinicNameController.text.trim(),
  address: _clinicAddressController.text.trim(),
  city: _selectedCity ?? '',
  role: _selectedServiceType ?? '',

  // Convert File? to XFile?
  profileImage: _profileImage != null ? XFile(_profileImage!.path) : null,

  // Convert List<File> to List<XFile>
  galleryImages: _galleryImages.map((file) => XFile(file.path)).toList(),

  qualificationFile: _qualificationFile != null ? XFile(_qualificationFile!.path) : null,
  idVerificationFile: _idVerificationFile != null ? XFile(_idVerificationFile!.path) : null,

  experience: _experienceController.text.trim(),
  serviceDescription: _descriptionController.text.trim(),
  notes: _notesController.text.trim(),
  pricingDetails: _pricingController.text.trim(),
  consultationFee: _consultationFeeController.text.trim(),
  aboutClinicOrSalon: _aboutClinicOrSalonController.text.trim(),
  groomingServices: _selectedGroomingServices,
  comfortableWith: _selectedComfortableWith,
  availableTimes: _availableDaysTimesController.text.trim(),
  dislikes: _dislikesController.text.trim(),
  rate: _rateController.text.trim(),
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
    labelStyle: const TextStyle(color: Colors.black87),
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
            Center(child: Image.asset('assets/images/scooby_logo.jpeg', height: 160)),
            const SizedBox(height: 8),
            const Text('Register as Service Provider', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: purple)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 4)],
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
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : const AssetImage('assets/images/default_user.png') as ImageProvider,
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
                    DropdownButtonFormField<String>(value: _selectedCity, items: _cities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _selectedCity = val), decoration: _inputDecoration('City'), validator: (val) => val == null ? 'Select city' : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _selectedServiceType, items: _serviceTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _selectedServiceType = val), decoration: _inputDecoration('Service Type'), validator: (val) => val == null ? 'Select service' : null),
                    const SizedBox(height: 16),

                    if (_selectedServiceType == 'Veterinarian' || _selectedServiceType == 'Pet Groomer') ...[
                      TextFormField(controller: _clinicOrSalonController, decoration: _inputDecoration(_selectedServiceType == 'Veterinarian' ? 'Clinic Name & Address' : 'Salon Name & Address'), validator: (val) => val!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _aboutClinicOrSalonController, decoration: _inputDecoration('About the Place'), maxLines: 2),
                      const SizedBox(height: 16),
                      TextFormField(controller: _experienceController, decoration: _inputDecoration('Years of Experience'), keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      TextFormField(controller: _descriptionController, decoration: _inputDecoration('Service Description'), maxLines: 3),
                      const SizedBox(height: 16),
                      TextFormField(controller: _selectedServiceType == 'Veterinarian' ? _consultationFeeController : _pricingController, decoration: _inputDecoration(_selectedServiceType == 'Veterinarian' ? 'Consultation Fee (Optional)' : 'Pricing Details (Optional)')),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _pickQualification, icon: const Icon(Icons.file_present), label: const Text('Upload Qualification', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: purple)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _pickGalleryImages, icon: const Icon(Icons.image), label: const Text('Upload Gallery Images', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: purple)),
                    ],

                    if (_selectedServiceType == 'Pet Groomer') ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _groomingServices.map((service) {
                          return FilterChip(
                            label: Text(service),
                            selected: _selectedGroomingServices.contains(service),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGroomingServices.add(service);
                                } else {
                                  _selectedGroomingServices.remove(service);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    if (_selectedServiceType == 'Pet Sitter') ...[
                      const SizedBox(height: 16),
                      TextFormField(controller: _availableDaysTimesController, decoration: _inputDecoration('Available Days & Times')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _dislikesController, decoration: _inputDecoration('Any Allergies or Pet Dislikes'), maxLines: 2),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _comfortableWith.map((animal) {
                          return FilterChip(
                            label: Text(animal),
                            selected: _selectedComfortableWith.contains(animal),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedComfortableWith.add(animal);
                                } else {
                                  _selectedComfortableWith.remove(animal);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: _notesController, decoration: _inputDecoration('Special Notes or Preferences'), maxLines: 2),
                      const SizedBox(height: 16),
                      TextFormField(controller: _experienceController, decoration: _inputDecoration('Years of Experience'), keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      TextFormField(controller: _descriptionController, decoration: _inputDecoration('Service Description'), maxLines: 3),
                      const SizedBox(height: 16),
                      TextFormField(controller: _rateController, decoration: _inputDecoration('Hourly / Daily Rate')),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _pickVerificationFile, icon: const Icon(Icons.file_copy), label: const Text('Upload ID / Verification Document (Optional)', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: purple)),
                    ],

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
            ),
          ],
        ),
      ),
    );
  }
}
