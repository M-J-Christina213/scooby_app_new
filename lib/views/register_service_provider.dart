import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterServiceProviderScreen extends StatefulWidget {
  const RegisterServiceProviderScreen({super.key});

  @override
  State<RegisterServiceProviderScreen> createState() => _RegisterServiceProviderScreenState();
}

class _RegisterServiceProviderScreenState extends State<RegisterServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _serviceDescriptionController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _serviceType;
  final List<String> _services = ['Veterinarian', 'Groomer'];

 Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    try {
      final response = await Supabase.instance.client.from('service_providers').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'service_type': _serviceType,
        'service_description': _serviceDescriptionController.text,
        'experience': _experienceController.text,
      });

      ('Insert status: ${response.status}, data: ${response.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully registered!')),
        );
      }
    } catch (e) {
      ('Submission failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting data')),
        );
      }
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Service Provider'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', inputType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildTextField(_phoneController, 'Phone Number', inputType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildTextField(_addressController, 'Address'),
              const SizedBox(height: 10),
              _buildTextField(_experienceController, 'Experience'),
              const SizedBox(height: 10),
              _buildTextField(_serviceDescriptionController, 'Service Description'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  filled: true,
                  fillColor: Colors.deepPurple.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _serviceType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a service type' : null,
                items: _services.map((String service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.deepPurple.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }
}
