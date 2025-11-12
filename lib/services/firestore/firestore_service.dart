import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/firebase_config.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/profile_model.dart';
import '../../models/pantry_item_model.dart';
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

  // ==================== PANTRY ITEMS METHODS ====================

  /// Get all pantry items for a user, sorted by expiration date
  Future<List<PantryItem>> getPantryItems(String userId) async {
    try {
      // Get all items (can't use orderBy with null values, so we'll sort in code)
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('pantry_items')
          .get();

      final items = snapshot.docs
          .map((doc) => PantryItem.fromFirestore(doc))
          .toList();

      // Sort: items with expiration dates first (ascending), then items without dates
      items.sort((a, b) {
        if (a.expirationDate == null && b.expirationDate == null) {
          return b.addedAt.compareTo(a.addedAt); // Newest first for items without dates
        }
        if (a.expirationDate == null) return 1; // Items without dates go to end
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      Logger.success('Retrieved ${items.length} pantry items for user: $userId', 'FirestoreService');
      return items;
    } catch (e) {
      Logger.error('Failed to get pantry items', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream pantry items for real-time updates
  Stream<List<PantryItem>> streamPantryItems(String userId) {
    // Get all items (can't use orderBy with null values, so we'll sort in code)
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection('pantry_items')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            try {
              return PantryItem.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse pantry item', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<PantryItem>()
          .toList();

      // Sort: items with expiration dates first (ascending), then items without dates
      items.sort((a, b) {
        if (a.expirationDate == null && b.expirationDate == null) {
          return b.addedAt.compareTo(a.addedAt); // Newest first for items without dates
        }
        if (a.expirationDate == null) return 1; // Items without dates go to end
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      return items;
    }).handleError((error) {
      Logger.error('Error in pantry items stream', error, null, 'FirestoreService');
      return <PantryItem>[];
    });
  }

  /// Add a new pantry item
  Future<String> addPantryItem(String userId, PantryItem item) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('pantry_items')
          .add(item.toMap());

      Logger.success('Pantry item added: ${docRef.id}', 'FirestoreService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to add pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update an existing pantry item
  Future<void> updatePantryItem(String userId, PantryItem item) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('pantry_items')
          .doc(item.id)
          .update(item.toMap());

      Logger.success('Pantry item updated: ${item.id}', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete a pantry item
  Future<void> deletePantryItem(String userId, String itemId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('pantry_items')
          .doc(itemId)
          .delete();

      Logger.success('Pantry item deleted: $itemId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to delete pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }
}

