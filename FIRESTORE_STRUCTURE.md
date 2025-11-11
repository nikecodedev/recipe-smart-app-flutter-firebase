# Firestore Database Structure

This document outlines the complete Firestore database schema for the Smart Pantry Management App.

## Collections Overview

```
firestore/
├── users/                      # User profiles and settings
├── pantry_items/              # User pantry inventory
├── recipes/                   # Recipe database
├── shopping_lists/            # Shopping lists
├── shopping_items/            # Individual shopping list items
├── recommendations/           # AI-generated recipe recommendations
├── categories/                # Item and recipe categories
└── user_activity/             # User activity logs (optional)
```

---

## 1. Users Collection

**Collection:** `users`  
**Document ID:** User's Firebase Auth UID

### Document Structure:

```typescript
{
  userId: string;              // Firebase Auth UID
  email: string;               // User email
  displayName: string;         // User's display name
  photoURL?: string;           // Profile picture URL
  role: 'user' | 'admin';      // User role
  createdAt: Timestamp;        // Account creation date
  updatedAt: Timestamp;        // Last profile update
  preferences: {
    dietaryRestrictions: string[];  // e.g., ['vegetarian', 'gluten-free']
    allergies: string[];             // e.g., ['peanuts', 'shellfish']
    cuisinePreferences: string[];    // e.g., ['italian', 'mexican']
    notificationsEnabled: boolean;
    expiryAlerts: boolean;
    language: string;                // e.g., 'en', 'es'
  };
  stats: {
    totalRecipes: number;
    totalPantryItems: number;
    recipesCooked: number;
  };
}
```

### Example Document:

```json
{
  "userId": "abc123xyz",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoURL": "https://storage.googleapis.com/...",
  "role": "user",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-11-11T14:20:00Z",
  "preferences": {
    "dietaryRestrictions": ["vegetarian"],
    "allergies": ["peanuts"],
    "cuisinePreferences": ["italian", "mexican"],
    "notificationsEnabled": true,
    "expiryAlerts": true,
    "language": "en"
  },
  "stats": {
    "totalRecipes": 15,
    "totalPantryItems": 42,
    "recipesCooked": 8
  }
}
```

### Indexes:
- `email` (Ascending)
- `role` (Ascending)

---

## 2. Pantry Items Collection

**Collection:** `pantry_items`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  itemId: string;              // Auto-generated document ID
  userId: string;              // Owner's user ID
  name: string;                // Item name (e.g., "Milk")
  category: string;            // Category (e.g., "Dairy")
  quantity: number;            // Quantity available
  unit: string;                // Unit (e.g., "liters", "pieces", "grams")
  expiryDate?: Timestamp;      // Expiration date
  purchaseDate?: Timestamp;    // Purchase date
  location: string;            // Storage location (e.g., "Fridge", "Pantry")
  barcode?: string;            // Product barcode
  imageUrl?: string;           // Item image
  notes?: string;              // Additional notes
  isLowStock: boolean;         // Flag for low stock alert
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### Example Document:

```json
{
  "itemId": "item_001",
  "userId": "abc123xyz",
  "name": "Milk",
  "category": "Dairy",
  "quantity": 2,
  "unit": "liters",
  "expiryDate": "2025-11-20T00:00:00Z",
  "purchaseDate": "2025-11-10T00:00:00Z",
  "location": "Fridge",
  "barcode": "1234567890123",
  "imageUrl": "https://storage.googleapis.com/...",
  "notes": "Low-fat organic milk",
  "isLowStock": false,
  "createdAt": "2025-11-10T10:00:00Z",
  "updatedAt": "2025-11-11T15:00:00Z"
}
```

### Indexes:
- `userId` (Ascending), `expiryDate` (Ascending)
- `userId` (Ascending), `category` (Ascending)
- `userId` (Ascending), `isLowStock` (Ascending)

### Queries:
```dart
// Get user's pantry items
pantryItems.where('userId', isEqualTo: currentUserId);

// Get expiring items
pantryItems
  .where('userId', isEqualTo: currentUserId)
  .where('expiryDate', isLessThan: DateTime.now().add(Duration(days: 7)));

// Get items by category
pantryItems
  .where('userId', isEqualTo: currentUserId)
  .where('category', isEqualTo: 'Dairy');
```

---

## 3. Recipes Collection

**Collection:** `recipes`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  recipeId: string;            // Auto-generated document ID
  userId: string;              // Creator's user ID
  title: string;               // Recipe title
  description: string;         // Short description
  category: string;            // Category (e.g., "Main Course", "Dessert")
  cuisine: string;             // Cuisine type (e.g., "Italian", "Mexican")
  difficulty: 'easy' | 'medium' | 'hard';
  prepTime: number;            // Preparation time (minutes)
  cookTime: number;            // Cooking time (minutes)
  servings: number;            // Number of servings
  ingredients: Array<{
    name: string;
    quantity: number;
    unit: string;
    optional?: boolean;
  }>;
  instructions: Array<{
    step: number;
    description: string;
    imageUrl?: string;
  }>;
  imageUrl: string;            // Main recipe image
  tags: string[];              // Tags (e.g., ['quick', 'healthy'])
  nutritionInfo?: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
  };
  rating: number;              // Average rating (0-5)
  ratingCount: number;         // Number of ratings
  isPublic: boolean;           // Public or private recipe
  isApproved: boolean;         // Admin approval status
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### Example Document:

```json
{
  "recipeId": "recipe_001",
  "userId": "abc123xyz",
  "title": "Spaghetti Carbonara",
  "description": "Classic Italian pasta dish with eggs and bacon",
  "category": "Main Course",
  "cuisine": "Italian",
  "difficulty": "medium",
  "prepTime": 10,
  "cookTime": 20,
  "servings": 4,
  "ingredients": [
    {
      "name": "Spaghetti",
      "quantity": 400,
      "unit": "grams"
    },
    {
      "name": "Bacon",
      "quantity": 200,
      "unit": "grams"
    },
    {
      "name": "Eggs",
      "quantity": 4,
      "unit": "pieces"
    },
    {
      "name": "Parmesan cheese",
      "quantity": 100,
      "unit": "grams"
    }
  ],
  "instructions": [
    {
      "step": 1,
      "description": "Boil water and cook spaghetti according to package instructions"
    },
    {
      "step": 2,
      "description": "Fry bacon until crispy"
    },
    {
      "step": 3,
      "description": "Mix eggs and parmesan in a bowl"
    },
    {
      "step": 4,
      "description": "Combine hot pasta with bacon and egg mixture"
    }
  ],
  "imageUrl": "https://storage.googleapis.com/...",
  "tags": ["quick", "italian", "pasta"],
  "nutritionInfo": {
    "calories": 520,
    "protein": 25,
    "carbs": 55,
    "fat": 22
  },
  "rating": 4.5,
  "ratingCount": 12,
  "isPublic": true,
  "isApproved": true,
  "createdAt": "2025-01-20T10:00:00Z",
  "updatedAt": "2025-11-11T15:00:00Z"
}
```

### Indexes:
- `userId` (Ascending), `createdAt` (Descending)
- `category` (Ascending), `rating` (Descending)
- `isPublic` (Ascending), `isApproved` (Ascending)
- `tags` (Array-contains)

---

## 4. Shopping Lists Collection

**Collection:** `shopping_lists`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  listId: string;              // Auto-generated document ID
  userId: string;              // Owner's user ID
  name: string;                // List name (e.g., "Weekly Groceries")
  createdAt: Timestamp;
  updatedAt: Timestamp;
  isActive: boolean;           // Active or archived
}
```

### Example Document:

```json
{
  "listId": "list_001",
  "userId": "abc123xyz",
  "name": "Weekly Groceries",
  "createdAt": "2025-11-10T10:00:00Z",
  "updatedAt": "2025-11-11T15:00:00Z",
  "isActive": true
}
```

---

## 5. Shopping Items Collection

**Collection:** `shopping_items`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  itemId: string;              // Auto-generated document ID
  listId: string;              // Parent shopping list ID
  userId: string;              // Owner's user ID
  name: string;                // Item name
  category: string;            // Category
  quantity: number;
  unit: string;
  isPurchased: boolean;        // Purchase status
  notes?: string;
  estimatedPrice?: number;
  actualPrice?: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  purchasedAt?: Timestamp;
}
```

### Example Document:

```json
{
  "itemId": "item_001",
  "listId": "list_001",
  "userId": "abc123xyz",
  "name": "Milk",
  "category": "Dairy",
  "quantity": 2,
  "unit": "liters",
  "isPurchased": false,
  "notes": "Get organic if available",
  "estimatedPrice": 5.99,
  "createdAt": "2025-11-10T10:00:00Z",
  "updatedAt": "2025-11-11T15:00:00Z"
}
```

### Indexes:
- `listId` (Ascending), `isPurchased` (Ascending)
- `userId` (Ascending), `category` (Ascending)

---

## 6. Recommendations Collection

**Collection:** `recommendations`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  recommendationId: string;    // Auto-generated document ID
  userId: string;              // User ID
  recipeId: string;            // Recommended recipe ID
  matchScore: number;          // Match percentage (0-100)
  availableIngredients: string[];  // Ingredients user has
  missingIngredients: Array<{
    name: string;
    quantity: number;
    unit: string;
  }>;
  reason: string;              // Recommendation reason
  createdAt: Timestamp;
  expiresAt: Timestamp;        // Recommendation expiry
  isViewed: boolean;
  isAccepted: boolean;         // User accepted recommendation
}
```

### Example Document:

```json
{
  "recommendationId": "rec_001",
  "userId": "abc123xyz",
  "recipeId": "recipe_001",
  "matchScore": 85,
  "availableIngredients": ["Spaghetti", "Eggs", "Bacon"],
  "missingIngredients": [
    {
      "name": "Parmesan cheese",
      "quantity": 100,
      "unit": "grams"
    }
  ],
  "reason": "You have most ingredients and they're expiring soon",
  "createdAt": "2025-11-11T10:00:00Z",
  "expiresAt": "2025-11-18T10:00:00Z",
  "isViewed": false,
  "isAccepted": false
}
```

### Indexes:
- `userId` (Ascending), `matchScore` (Descending)
- `userId` (Ascending), `isViewed` (Ascending)

---

## 7. Categories Collection

**Collection:** `categories`  
**Document ID:** Category name (lowercase)

### Document Structure:

```typescript
{
  categoryId: string;          // Category name (lowercase)
  displayName: string;         // Display name
  type: 'pantry' | 'recipe';   // Category type
  icon: string;                // Icon name or URL
  sortOrder: number;           // Display order
}
```

### Example Document:

```json
{
  "categoryId": "dairy",
  "displayName": "Dairy",
  "type": "pantry",
  "icon": "milk",
  "sortOrder": 1
}
```

### Pre-populated Categories:

**Pantry Categories:**
- Dairy
- Fruits
- Vegetables
- Meat & Poultry
- Seafood
- Grains & Bread
- Canned Goods
- Spices & Condiments
- Beverages
- Frozen Foods
- Snacks
- Other

**Recipe Categories:**
- Breakfast
- Main Course
- Side Dish
- Dessert
- Appetizer
- Soup & Salad
- Beverages
- Snacks

---

## 8. User Activity Collection (Optional)

**Collection:** `user_activity`  
**Document ID:** Auto-generated

### Document Structure:

```typescript
{
  activityId: string;
  userId: string;
  action: string;              // e.g., 'recipe_viewed', 'item_added'
  entityType: string;          // e.g., 'recipe', 'pantry_item'
  entityId: string;
  metadata?: object;
  timestamp: Timestamp;
}
```

---

## Security Considerations

1. **User Data Isolation**: All collections use `userId` to ensure users only access their own data
2. **Admin Access**: Admin users have read/write access to all documents
3. **Public Recipes**: Recipes marked `isPublic: true` are readable by all authenticated users
4. **Validation**: Use Firebase Security Rules to validate data types and required fields
5. **Rate Limiting**: Implement rate limiting for write operations

---

## Cloud Functions Triggers (Optional)

### Auto-generate recommendations
```javascript
// Trigger: When pantry items change
exports.generateRecommendations = functions.firestore
  .document('pantry_items/{itemId}')
  .onWrite(async (change, context) => {
    // Generate recipe recommendations based on available ingredients
  });
```

### Clean expired recommendations
```javascript
// Trigger: Daily scheduled function
exports.cleanExpiredRecommendations = functions.pubsub
  .schedule('0 0 * * *')
  .onRun(async (context) => {
    // Delete expired recommendations
  });
```

### Send expiry notifications
```javascript
// Trigger: Daily scheduled function
exports.sendExpiryNotifications = functions.pubsub
  .schedule('0 9 * * *')
  .onRun(async (context) => {
    // Notify users about expiring items
  });
```

---

## Migration Scripts

If updating schema, use these patterns:

```dart
// Update all existing documents with new field
Future<void> migrateAddIsLowStock() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('pantry_items')
      .where('isLowStock', isNull: true)
      .get();
  
  final batch = FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    batch.update(doc.reference, {'isLowStock': false});
  }
  await batch.commit();
}
```

---

## Backup Strategy

1. **Automated Daily Backups**: Configure in Firebase Console
2. **Export Data**: Use Firebase Admin SDK for periodic exports
3. **Version Control**: Keep schema documentation in Git

---

## Next Steps

1. ✅ Firestore structure defined
2. ➡️ Create Dart models matching this schema
3. ➡️ Implement service classes for CRUD operations
4. ➡️ Set up Riverpod providers for state management
5. ➡️ Build UI components consuming this data

