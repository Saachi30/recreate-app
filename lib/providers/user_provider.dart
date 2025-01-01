import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;

class UserProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = firebase_auth.FirebaseAuth.instance;

  Future<void> updateGreenPoints(int additionalPoints) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('Consumers').doc(userId).get();
      if (!userDoc.exists) return;

      final currentPoints = userDoc.data()?['greenPoints'] ?? 0;
      final newPoints = currentPoints + additionalPoints;

      await _firestore.collection('Consumers').doc(userId).update({
        'greenPoints': newPoints,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating points: $e');
      rethrow;
    }
  }
  Future<void> addContractToHistory(String contractId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('Consumers').doc(userId).get();
      if (!userDoc.exists) return;

      List<String> currentHistory = List<String>.from(userDoc.data()?['contractHistory'] ?? []);
      currentHistory.add(contractId);

      await _firestore.collection('Consumers').doc(userId).update({
        'contractHistory': currentHistory,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating contract history: $e');
      rethrow;
    }
  }

}