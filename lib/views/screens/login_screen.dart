// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/screens/register_pet_owner.dart';
import 'package:scooby_app_new/views/screens/register_service_provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String selectedRole = '';
  bool rememberMe = false;

  // NEW: toggle password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showFlushBar(String message, Color color) {
    Flushbar(
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showFlushBar("Please fill in all fields", Colors.red);
      return;
    }

    setState(() => isLoading = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      final session = authResponse.session;

      if (user != null && session != null) {
        showFlushBar("Login successful!", Colors.green);
        // Let your AuthGate / router handle navigation automatically.
      } else {
        showFlushBar("Login failed: Invalid credentials", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      showFlushBar("Login failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildRegisterOption(String text, String role, VoidCallback onTap) {
    final bool isSelected = selectedRole == role;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = role;
          });
          onTap();
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isSelected ? const Color(0xFF842EAC) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF842EAC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Image.asset(
                          'assets/images/scooby_logo.jpeg',
                          height: 240,
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          hintText: 'Email Address',
                          hintStyle: const TextStyle(color: Colors.grey),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: purple, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          // NEW: eye toggle
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[700],
                            ),
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: purple, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                activeColor: purple,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    rememberMe = newValue ?? false;
                                  });
                                },
                              ),
                              const Text('Remember me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // implement forgot-password flow
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'or connect with',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          //  implement Google sign-in if needed
                        },
                        icon: Image.asset('assets/images/google_logo.png', height: 24),
                        label: const Text('Sign-in with Google', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[400], thickness: 1),
                      const SizedBox(height: 20),
                      buildRegisterOption('Register as Pet Owner', 'pet_owner', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PetOwnerRegisterScreen()),
                        );
                      }),
                      const SizedBox(height: 10),
                      buildRegisterOption('Register as Service Provider', 'service_provider', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ServiceProviderRegisterScreen()),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: purple,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'All rights reserved © Scooby 2025',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
