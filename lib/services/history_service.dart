import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fact_check_model.dart';
import '../config/app_config.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _appId = AppConfig.firebaseAppId;

  /// Saves a fact-check result to Firestore
  /// Path: /artifacts/{appId}/users/{userId}/factChecks
  Future<void> saveFactCheck(String userId, FactCheckResult result) async {
    try {
      final docRef = _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('factChecks')
          .doc();

      await docRef.set(result.toFirestore());
    } catch (e) {
      throw Exception('Failed to save fact-check: ${e.toString()}');
    }
  }

  /// Returns a stream of fact-check history for a user, ordered by timestamp (descending)
  /// Path: /artifacts/{appId}/users/{userId}/factChecks
  Stream<List<FactCheckResult>> getHistoryStream(String userId) {
    try {
      return _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('factChecks')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => FactCheckResult.fromFirestore(doc, null))
            .toList();
      });
    } catch (e) {
      // Return an empty stream on error
      return Stream.value([]);
    }
  }

  /// Deletes a specific fact-check result
  Future<void> deleteFactCheck(String userId, String factCheckId) async {
    try {
      await _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('factChecks')
          .doc(factCheckId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete fact-check: ${e.toString()}');
    }
  }

  /// Clears all fact-check history for a user
  Future<void> clearHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(userId)
          .collection('factChecks')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear history: ${e.toString()}');
    }
  }
}
