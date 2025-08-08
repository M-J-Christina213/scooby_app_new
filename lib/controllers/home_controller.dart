// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scooby_app_new/models/pet.dart';
import 'package:scooby_app_new/views/screens/add_pet_screen.dart';
import 'package:scooby_app_new/views/screens/login_screen.dart';
import 'package:scooby_app_new/views/screens/pet_profile_view.dart';
import 'package:scooby_app_new/views/screens/service_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allServices = [];
  List<Map<String, dynamic>> nearbyServices = [];
  List<Map<String, dynamic>> recommendedServices = [];

  // =========================
  // OWNER PROFILE STREAMS
  // =========================
  Stream<String> get ownerNameStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value('Guest');

    return _supabase
        .from('pet_owners')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) => data.isEmpty ? 'User' : (data.first['name'] ?? 'User'));
  }

  Stream<String?> get ownerImageStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _supabase
        .from('pet_owners')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) => data.isEmpty ? null : data.first['image_url']);
  }

  // =========================
  // OWNER PROFILE FETCH
  // =========================
  Future<String> fetchOwnerName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Guest';

    final response = await _supabase
        .from('pet_owners')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    return response?['name'] ?? 'User';
  }

  Future<String?> fetchOwnerImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('pet_owners')
        .select('image_url')
        .eq('id', user.id)
        .maybeSingle();

    return response?['image_url'];
  }

  // =========================
  // SIGN OUT & LOGOUT
  // =========================
  Future<void> signOut(BuildContext context) async {
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await signOut(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // =========================
  // PETS
  // =========================
  Stream<List<Pet>> get petListStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('pets')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.map((json) => Pet.fromJson(json)).toList());
  }

  void goToAddPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
  }

  void goToViewPetProfile(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
    );
  }

  // =========================
  // SERVICES
  // =========================
  Future<void> fetchAllServices() async {
    final data =
        await _supabase.from('service_providers').select('*').order('created_at');
    allServices = List<Map<String, dynamic>>.from(data);
  }

  Future<void> getNearbyServices() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final data = await _supabase
          .from('service_providers')
          .select('*')
          .order('created_at');

      // For now, filtering by same city name is simplest
      // Later, can add lat/lng & distance calculations
      final userCity = await _fetchUserCity(position);
      nearbyServices = data
          .where((service) =>
              (service['city'] ?? '').toString().toLowerCase() ==
              userCity.toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('Error getting nearby services: $e');
      nearbyServices = [];
    }
  }

  Future<void> getRecommendedServices() async {
    // Simple recommendation: top 5 rated
    final data = await _supabase
        .from('service_providers')
        .select('*')
        .order('rate', ascending: false)
        .limit(5);

    recommendedServices = List<Map<String, dynamic>>.from(data);
  }

  Future<String> _fetchUserCity(Position position) async {
    // Placeholder: In production, use a reverse geocoding API
    // For now, just return a fixed value
    return "New York";
  }

  Future<void> refreshData() async {
    await fetchAllServices();
    await getNearbyServices();
    await getRecommendedServices();
  }

  void goToServiceList(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceListScreen(category: category, services: [],),
      ),
    );
  }
}
