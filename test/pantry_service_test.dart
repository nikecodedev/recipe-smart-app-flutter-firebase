import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/pantry_item_model.dart';
import '../lib/services/firestore/firestore_service.dart';

/// Test file for Pantry FirestoreService methods
/// 
/// Note: These tests require Firebase to be initialized and a test user ID.
/// For unit tests, you may need to mock Firestore or use Firebase emulators.
/// 
/// To run these tests:
/// 1. Ensure Firebase is initialized in your test setup
/// 2. Provide a valid test user ID
/// 3. Run: flutter test test/pantry_service_test.dart

void main() {
  group('PantryItem Model Tests', () {
    test('PantryItem should be created with all required fields', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 2.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        addedAt: DateTime.now(),
      );

      expect(item.id, 'test-id');
      expect(item.name, 'Milk');
      expect(item.quantity, 2.0);
      expect(item.unit, 'liters');
      expect(item.category, 'Dairy');
      expect(item.expirationDate, isNotNull);
      expect(item.addedAt, isNotNull);
    });

    test('PantryItem should handle null expiration date', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Salt',
        quantity: 1.0,
        unit: 'kilograms',
        category: 'Spices & Condiments',
        addedAt: DateTime.now(),
      );

      expect(item.expirationDate, isNull);
      expect(item.isExpired, false);
      expect(item.isExpiringSoon, false);
    });

    test('PantryItem should correctly identify expired items', () {
      final expiredItem = PantryItem(
        id: 'test-id',
        name: 'Expired Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
        addedAt: DateTime.now(),
      );

      expect(expiredItem.isExpired, true);
      expect(expiredItem.daysUntilExpiration, lessThan(0));
    });

    test('PantryItem should correctly identify expiring soon items', () {
      final expiringSoonItem = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 2)),
        addedAt: DateTime.now(),
      );

      expect(expiringSoonItem.isExpiringSoon, true);
      expect(expiringSoonItem.isExpired, false);
      expect(expiringSoonItem.daysUntilExpiration, lessThanOrEqualTo(3));
    });

    test('PantryItem toMap should convert to Firestore format', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 2.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now(),
        addedAt: DateTime.now(),
      );

      final map = item.toMap();

      expect(map['name'], 'Milk');
      expect(map['quantity'], 2.0);
      expect(map['unit'], 'liters');
      expect(map['category'], 'Dairy');
      expect(map['expirationDate'], isA<Timestamp>());
      expect(map['addedAt'], isA<Timestamp>());
    });

    test('PantryItem copyWith should create a copy with updated fields', () {
      final original = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 2.0,
        unit: 'liters',
        category: 'Dairy',
        addedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        name: 'Whole Milk',
        quantity: 3.0,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Whole Milk');
      expect(updated.quantity, 3.0);
      expect(updated.unit, original.unit);
      expect(updated.category, original.category);
    });
  });

  group('FirestoreService Pantry Methods Tests', () {
    // Note: These tests require Firebase to be initialized
    // In a real test environment, you would:
    // 1. Initialize Firebase with test configuration
    // 2. Use Firebase emulators or mock Firestore
    // 3. Clean up test data after each test

    late FirestoreService firestoreService;
    late String testUserId;

    setUp(() {
      firestoreService = FirestoreService();
      // Replace with a test user ID from your Firebase project
      testUserId = 'test-user-id';
    });

    test('addPantryItem should add item to Firestore', () async {
      final item = PantryItem(
        id: 'temp-id', // Will be replaced by Firestore
        name: 'Test Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        addedAt: DateTime.now(),
      );

      // Note: This test requires Firebase to be initialized
      // Uncomment and run with proper Firebase setup:
      /*
      final itemId = await firestoreService.addPantryItem(testUserId, item);
      expect(itemId, isNotEmpty);
      */
    }, skip: true); // Skip until Firebase is properly configured

    test('getPantryItems should retrieve items sorted by expiration date', () async {
      // Note: This test requires Firebase to be initialized
      // Uncomment and run with proper Firebase setup:
      /*
      final items = await firestoreService.getPantryItems(testUserId);
      expect(items, isA<List<PantryItem>>());
      
      // Verify sorting: items with expiration dates should come first
      for (int i = 0; i < items.length - 1; i++) {
        if (items[i].expirationDate != null && items[i + 1].expirationDate != null) {
          expect(
            items[i].expirationDate!.isBefore(items[i + 1].expirationDate!) ||
            items[i].expirationDate!.isAtSameMomentAs(items[i + 1].expirationDate!),
            true,
          );
        }
      }
      */
    }, skip: true); // Skip until Firebase is properly configured

    test('updatePantryItem should update existing item', () async {
      final item = PantryItem(
        id: 'existing-item-id',
        name: 'Updated Milk',
        quantity: 2.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        addedAt: DateTime.now(),
      );

      // Note: This test requires Firebase to be initialized
      // Uncomment and run with proper Firebase setup:
      /*
      await firestoreService.updatePantryItem(testUserId, item);
      
      final updatedItems = await firestoreService.getPantryItems(testUserId);
      final updatedItem = updatedItems.firstWhere((i) => i.id == item.id);
      expect(updatedItem.name, 'Updated Milk');
      expect(updatedItem.quantity, 2.0);
      */
    }, skip: true); // Skip until Firebase is properly configured

    test('deletePantryItem should remove item from Firestore', () async {
      const itemId = 'item-to-delete';

      // Note: This test requires Firebase to be initialized
      // Uncomment and run with proper Firebase setup:
      /*
      await firestoreService.deletePantryItem(testUserId, itemId);
      
      final items = await firestoreService.getPantryItems(testUserId);
      expect(items.any((item) => item.id == itemId), false);
      */
    }, skip: true); // Skip until Firebase is properly configured

    test('streamPantryItems should provide real-time updates', () async {
      // Note: This test requires Firebase to be initialized
      // Uncomment and run with proper Firebase setup:
      /*
      final stream = firestoreService.streamPantryItems(testUserId);
      
      await expectLater(
        stream,
        emits(isA<List<PantryItem>>()),
      );
      */
    }, skip: true); // Skip until Firebase is properly configured
  });

  group('PantryItem Expiration Logic Tests', () {
    test('Item expiring in 0 days should be expiring soon', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now(),
        addedAt: DateTime.now(),
      );

      expect(item.isExpiringSoon, true);
      expect(item.isExpired, false);
    });

    test('Item expiring in 3 days should be expiring soon', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 3)),
        addedAt: DateTime.now(),
      );

      expect(item.isExpiringSoon, true);
      expect(item.isExpired, false);
    });

    test('Item expiring in 4 days should not be expiring soon', () {
      final item = PantryItem(
        id: 'test-id',
        name: 'Milk',
        quantity: 1.0,
        unit: 'liters',
        category: 'Dairy',
        expirationDate: DateTime.now().add(const Duration(days: 4)),
        addedAt: DateTime.now(),
      );

      expect(item.isExpiringSoon, false);
      expect(item.isExpired, false);
    });
  });
}

