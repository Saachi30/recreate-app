import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class PointsResult {
  final int points;
  final String breakdown;
  final Map<String, dynamic> details;

  PointsResult({
    required this.points,
    required this.breakdown,
    required this.details,
  });
}

class PointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static Future<PointsResult> calculatePointsFromBill(
    Map<String, dynamic> analysis, {
    bool isGridReturn = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    final userId = currentUser.uid;

    int totalPoints = 0;
    List<String> breakdownItems = [];
    Map<String, dynamic> details = {};

    try {
      final double usage = (analysis['usage'] as num?)?.toDouble() ?? 0.0;
      final double renewable = (analysis['renewable'] as num?)?.toDouble() ?? 0.0;
      final double improvement = (analysis['improvement'] as num?)?.toDouble() ?? 0.0;

      if (isGridReturn) {
        // Points for returning energy to grid (5 points per kWh)
        final returnedEnergy = (analysis['returnedEnergy'] as num?)?.toDouble() ?? 0.0;
        final gridPoints = (returnedEnergy * 5).round();
        totalPoints += gridPoints;
        breakdownItems.add('Grid Return: +$gridPoints points (${returnedEnergy.toStringAsFixed(1)} kWh)');
        details['gridPoints'] = gridPoints;
      } else {
        // Base points for low usage (max 500 points)
        if (usage < 1000) {
          final usagePoints = min(((1000 - usage) / 10).round(), 500);
          totalPoints += usagePoints;
          breakdownItems.add('Low Usage: +$usagePoints points');
          details['usagePoints'] = usagePoints;
        }

        // Points for renewable energy (max 300 points)
        if (renewable > 0) {
          final renewablePoints = min((renewable * 3).round(), 300);
          totalPoints += renewablePoints;
          breakdownItems.add('Renewable Usage: +$renewablePoints points (${renewable.toStringAsFixed(1)}%)');
          details['renewablePoints'] = renewablePoints;
        }

        // Points for improvement (max 200 points)
        if (improvement < 0) {
          final improvementPoints = min((improvement.abs() * 4).round(), 200);
          totalPoints += improvementPoints;
          breakdownItems.add('Usage Reduction: +$improvementPoints points (${improvement.abs().toStringAsFixed(1)}% reduction)');
          details['improvementPoints'] = improvementPoints;
        }
      }

      // First store points in history
      await _storePointsHistory(
        userId: userId,
        points: totalPoints,
        details: details,
        isGridReturn: isGridReturn,
      );

      // Then update the consumer's total points
      await _updateConsumerGreenPoints(userId, totalPoints);

      return PointsResult(
        points: totalPoints,
        breakdown: breakdownItems.join('\n'),
        details: details,
      );
    } catch (e) {
      print('Error calculating points: $e');
      throw Exception('Failed to calculate points: $e');
    }
  }

  // Helper method to update consumer's total green points
  static Future<void> _updateConsumerGreenPoints(String userId, int pointsToAdd) async {
    try {
      // Use a transaction to safely update points
      await _firestore.runTransaction((transaction) async {
        final consumerDoc = _firestore.collection('Consumers').doc(userId);
        final docSnapshot = await transaction.get(consumerDoc);
        
        if (!docSnapshot.exists) {
          throw Exception('Consumer document not found');
        }
        
        final currentPoints = (docSnapshot.data()?['greenPoints'] as num?)?.toInt() ?? 0;
        
        // Update points within the transaction
        transaction.update(consumerDoc, {
          'greenPoints': currentPoints + pointsToAdd,
        });
      });
    } catch (e) {
      print('Error updating greenPoints: $e');
      throw Exception('Failed to update greenPoints: $e');
    }
  }

  static Future<void> _storePointsHistory({
    required String userId,
    required int points,
    required Map<String, dynamic> details,
    required bool isGridReturn,
  }) async {
    try {
      await _firestore.collection('points_history').add({
        'userId': userId,
        'points': points,
        'details': details,
        'isGridReturn': isGridReturn,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to store points history: $e');
    }
  }
}