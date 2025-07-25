import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sign In Method
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      log('Login Error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected login error: $e');
      rethrow;
    }
  }

  // Register Pet Owner
  Future<User?> registerPetOwner({
    required String name,
    required String phone,
    required String address,
    required String city,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        String? imageUrl;
        if (profileImage != null) {
          imageUrl = await _uploadImage(user.uid, profileImage);
        }

        await _firestore.collection('pet_owners').doc(user.uid).set({
          'uid': user.uid,
          'role': 'pet_owner',
          'name': name,
          'phone': phone,
          'address': address,
          'city': city,
          'email': email,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        log('Saved pet owner data to Firestore for UID: ${user.uid}');

        return user;
      }
    } on FirebaseAuthException catch (e, stacktrace) {
      log('Register PetOwner Error [${e.code}]: ${e.message}');
      log('Stacktrace: $stacktrace');
      rethrow;
    } catch (e, stacktrace) {
      log('Unexpected registration error: $e');
      log('Stacktrace: $stacktrace');
      rethrow;
    }
    return null;
  }

  // Register Service Provider
  Future<User?> registerServiceProvider({
    required String name,
    required String role,
    required String phone,
    required String address,
    required String city,
    required String email,
    required String password,
    required String description,
    required String experience,
    File? profileImage,
    File? qualificationFile,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        String? imageUrl;
        String? qualificationUrl;

        if (profileImage != null) {
          imageUrl = await _uploadImage(user.uid, profileImage);
        }

        if (qualificationFile != null) {
          qualificationUrl = await _uploadFile(user.uid, qualificationFile);
        }

        await _firestore.collection('service_providers').doc(user.uid).set({
          'uid': user.uid,
          'role': 'service_provider',
          'name': name,
          'providerRole': role,
          'phone': phone,
          'address': address,
          'city': city,
          'email': email,
          'description': description,
          'experience': experience,
          'imageUrl': imageUrl,
          'qualificationUrl': qualificationUrl,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        log('Saved service provider data to Firestore for UID: ${user.uid}');

        return user;
      }
    } on FirebaseAuthException catch (e, stacktrace) {
      log('Register ServiceProvider Error [${e.code}]: ${e.message}');
      log('Stacktrace: $stacktrace');
      rethrow;
    } catch (e, stacktrace) {
      log('Unexpected registration error: $e');
      log('Stacktrace: $stacktrace');
      rethrow;
    }
    return null;
  }

  Future<String> _uploadImage(String uid, File file) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'max-age=3600',
    );
    await ref.putFile(file, metadata);
    return await ref.getDownloadURL();
  }

  Future<String> _uploadFile(String uid, File file) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('qualifications/$uid-$fileName');
    final metadata = SettableMetadata(
      contentType: 'application/octet-stream',
      cacheControl: 'max-age=3600',
    );
    await ref.putFile(file, metadata);
    return await ref.getDownloadURL();
  }

  Future<String?> getUserRole(String uid) async {
    final petOwnerDoc = await FirebaseFirestore.instance.collection('pet_owners').doc(uid).get();
    if (petOwnerDoc.exists) return 'pet_owner';

    final providerDoc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
    if (providerDoc.exists) return 'service_provider';

    return null;
  }
}