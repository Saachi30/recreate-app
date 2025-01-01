import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  User? _user;
  User? get user => _user;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String propertyID,

  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception("Failed to create user.");
      }

      final initialUserData = {
        'name': name,
        'email': email,
        'propertyID': propertyID,
        'greenPoints': 0,
        'achievements': [],
        'events': [],
        'isProducer': false,
        'contractHistory': [],
      };

      await _firestore
          .collection('Consumers')
          .doc(userCredential.user!.uid)
          .set(initialUserData);

      _user = User(
        name: name,
        email: email,
        propertyID: propertyID,
        greenPoints: 0,
        achievements: const [],
        events: const [],
        isProducer: false,
        contractHistory: const [],
      );

      // Set up listener after registration
      _setupUserListener(userCredential.user!.uid);
      notifyListeners();
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception("Login failed: No user found.");
      }

      // Set up listener after login
      _setupUserListener(userCredential.user!.uid);
      
      // Initial data fetch
      final userData = await _firestore
          .collection('Consumers')
          .doc(userCredential.user!.uid)
          .get();

      if (userData.exists) {
        _user = User.fromMap(userData.data()!);
        notifyListeners();
      } else {
        throw Exception('User data not found.');
      }
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  void _setupUserListener(String userId) {
    // Cancel any existing subscription
    _userSubscription?.cancel();
    
    // Set up new listener
    _userSubscription = _firestore
        .collection('Consumers')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _user = User.fromMap(snapshot.data()!);
        notifyListeners(); // This will update the ProfileCard
      }
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    // Cancel the listener when logging out
    _userSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}