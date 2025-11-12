import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/firebase_config.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/profile_model.dart';
import '../../core/utils/logger.dart';

/// Service for managing user profiles in Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Get user profile from Firestore
  /// Returns null if profile doesn't exist
  Future<ProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          return ProfileModel.fromFirestore(doc);
        } catch (e) {
          Logger.error('Failed to parse profile from Firestore', e, null, 'FirestoreService');
          // Return null on parsing error instead of crashing
          return null;
        }
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Create a new user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? location,
    String unitPreference = 'metric',
    int servingSize = 4,
    List<HouseholdMember> householdMembers = const [],
  }) async {
    try {
      final now = DateTime.now();
      final profileModel = ProfileModel(
        userId: userId,
        name: name,
        email: email,
        location: location,
        unitPreference: unitPreference,
        servingSize: servingSize,
        householdMembers: householdMembers,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .set(profileModel.toMap(), SetOptions(merge: false));

      Logger.success('User profile created: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to create user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? location,
    String? unitPreference,
    int? servingSize,
    List<HouseholdMember>? householdMembers,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) {
        updates['name'] = name;
      }
      if (email != null) {
        updates['email'] = email;
      }
      if (location != null) {
        updates['location'] = location;
      }
      if (unitPreference != null) {
        updates['unitPreference'] = unitPreference;
      }
      if (servingSize != null) {
        updates['servingSize'] = servingSize;
      }
      if (householdMembers != null) {
        updates['householdMembers'] =
            householdMembers.map((member) => member.toMap()).toList();
      }

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update(updates);

      Logger.success('User profile updated: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream user profile changes
  Stream<ProfileModel?> streamUserProfile(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return ProfileModel.fromFirestore(doc);
        } catch (e) {
          Logger.error('Failed to parse profile from Firestore', e, null, 'FirestoreService');
          // Return null on parsing error to prevent app crash
          return null;
        }
      }
      return null;
    }).handleError((error) {
      Logger.error('Error in profile stream', error, null, 'FirestoreService');
      return null;
    });
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      Logger.error('Failed to check user profile', e, null, 'FirestoreService');
      return false;
    }
  }
}

