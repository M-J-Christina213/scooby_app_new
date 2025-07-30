// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scooby_app_new/views/home_screen.dart';
import 'package:scooby_app_new/views/register_pet_owner.dart';
import 'package:scooby_app_new/views/register_service_provider.dart';
import 'package:scooby_app_new/views/service_provider_home.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String selectedRole = '';

  Future<void> _loginAndRoute(String userId) async {
    try {
      final petOwnerRes = await supabase
          .from('pet_owners')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final serviceProviderRes = await supabase
          .from('service_providers')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (petOwnerRes != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (serviceProviderRes != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found in either collection.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error retrieving user role: $e")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF842EAC), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF842EAC),
      alignment: Alignment.center,
      child: const Text(
        "\u00a9 2025 Scooby. All rights reserved.",
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Center(
                      child: Image.asset('assets/images/scooby_logo.png', height: 100),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Enter your email'),
                      validator: (val) => val != null && val.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration('Enter your password'),
                      validator: (val) => val != null && val.length >= 8 ? null : 'Min 8 characters required',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF842EAC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);
                                  try {
                                    final response = await supabase.auth.signInWithPassword(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );
                                    final user = response.user;
                                    if (user != null) {
                                      await _loginAndRoute(user.id);
                                    }
                                  } on AuthException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message)),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Login failed: $e')),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              child: const Text('Login'),
                            ),
                          ),
                    const SizedBox(height: 20),
                    const Text('or connect with', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(FontAwesomeIcons.google, color: Colors.red),
                      label: const Text('Login with Google'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Register as Pet Owner'),
                          selected: selectedRole == 'owner',
                          selectedColor: const Color(0xFF842EAC),
                          labelStyle: TextStyle(
                            color: selectedRole == 'owner' ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPetOwner()));
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Register as Service Provider'),
                          selected: selectedRole == 'provider',
                          selectedColor: const Color(0xFF842EAC),
                          labelStyle: TextStyle(
                            color: selectedRole == 'provider' ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterServiceProvider()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }
}
