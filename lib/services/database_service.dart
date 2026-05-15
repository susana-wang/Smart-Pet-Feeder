import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String petsCollection = 'pets';
  static const String storageFolder = 'pets';

  /// Add a new pet to Firestore
  Future<void> addPet({
    required String name,
    required double feedAmount,
    required int age,
    required String breed,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection(petsCollection).add({
        'name': name,
        'feedAmount': feedAmount,
        'age': age,
        'breed': breed,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add pet: $e');
    }
  }

  /// Get all pets as a Stream for real-time updates
  Stream<QuerySnapshot> getPetsStream() {
    try {
      return _firestore
          .collection(petsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to get pets: $e');
    }
  }

  /// Update an existing pet
  Future<void> updatePet({
    required String petId,
    required String name,
    required double feedAmount,
    required int age,
    required String breed,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection(petsCollection).doc(petId).update({
        'name': name,
        'feedAmount': feedAmount,
        'age': age,
        'breed': breed,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update pet: $e');
    }
  }

  /// Delete a pet
  Future<void> deletePet(String petId) async {
    try {
      await _firestore.collection(petsCollection).doc(petId).delete();
    } catch (e) {
      throw Exception('Failed to delete pet: $e');
    }
  }

  /// Get a single pet by ID
  Future<DocumentSnapshot> getPetById(String petId) async {
    try {
      return await _firestore.collection(petsCollection).doc(petId).get();
    } catch (e) {
      throw Exception('Failed to get pet: $e');
    }
  }

  /// Upload image to Firebase Storage and return the download URL
  Future<String> uploadImage(File imageFile, String petName) async {
    try {
      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${petName}_$timestamp.jpg';
      final ref = _storage.ref().child(storageFolder).child(fileName);

      // Upload the file
      await ref.putFile(imageFile);

      // Get and return the download URL
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}

