# Affiliate API Integration Guide

This document explains how to integrate real affiliate APIs (Amazon Product Advertising API and Walmart Affiliate API) to replace the placeholder URLs currently used in the Shopping List feature.

## Current Implementation

The shopping list feature currently uses placeholder URLs generated in `lib/services/firestore/firestore_service.dart`:

- **Amazon**: `_generateAmazonLink()` - Creates search URLs with placeholder affiliate tag
- **Walmart**: `_generateWalmartLink()` - Creates search URLs with placeholder affiliate ID

## Amazon Product Advertising API Integration

### 1. Get Amazon Associates Account

1. Sign up for [Amazon Associates](https://affiliate-program.amazon.com/)
2. Get your **Associate Tag** (e.g., `yourstore-20`)
3. Apply for **Product Advertising API** access

### 2. Get API Credentials

1. Go to [Product Advertising API](https://webservices.amazon.com/paapi5/documentation/)
2. Create IAM user with `ProductAdvertisingAPI` permissions
3. Get **Access Key ID** and **Secret Access Key**

### 3. Install Required Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  amazon_product_api: ^1.0.0  # Or use http package with manual API calls
  crypto: ^3.0.0  # For request signing
```

### 4. Update FirestoreService

Replace `_generateAmazonLink()` method:

```dart
import 'package:amazon_product_api/amazon_product_api.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

String _generateAmazonLink(String itemName) async {
  try {
    // Initialize API client
    final api = AmazonProductAPI(
      accessKey: 'YOUR_ACCESS_KEY',
      secretKey: 'YOUR_SECRET_KEY',
      associateTag: 'yourstore-20',
      region: 'us-east-1', // Change based on your region
    );

    // Search for products
    final response = await api.searchItems(
      keywords: itemName,
      searchIndex: 'Grocery', // or 'All'
      itemCount: 1,
    );

    if (response.items != null && response.items!.isNotEmpty) {
      // Return the first product's detail page URL with affiliate tag
      return response.items!.first.detailPageURL;
    }

    // Fallback to search URL if no products found
    final encodedName = Uri.encodeComponent(itemName);
    return 'https://www.amazon.com/s?k=$encodedName&tag=yourstore-20';
  } catch (e) {
    Logger.error('Failed to generate Amazon link', e, null, 'FirestoreService');
    // Fallback URL
    final encodedName = Uri.encodeComponent(itemName);
    return 'https://www.amazon.com/s?k=$encodedName&tag=yourstore-20';
  }
}
```

### 5. Make Method Async

Update the `generateShoppingList` method to handle async link generation:

```dart
// In generateShoppingList method, change:
final amazonLink = await _generateAmazonLink(ingredient.name);
final walmartLink = await _generateWalmartLink(ingredient.name);
```

## Walmart Affiliate API Integration

### 1. Get Walmart Affiliate Account

1. Sign up for [Walmart Affiliate Program](https://affiliates.walmart.com/)
2. Get your **Publisher ID** (affiliate ID)

### 2. Get API Credentials

1. Go to [Walmart Affiliate API](https://affiliates.walmart.com/api)
2. Register your application
3. Get **API Key**

### 3. Install Required Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0  # For API calls
```

### 4. Update FirestoreService

Replace `_generateWalmartLink()` method:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> _generateWalmartLink(String itemName) async {
  try {
    final apiKey = 'YOUR_WALMART_API_KEY';
    final publisherId = 'YOUR_PUBLISHER_ID';
    
    // Search for products
    final url = Uri.parse(
      'https://affiliate-api.walmart.com/v3/products?'
      'query=$itemName&'
      'format=json&'
      'apiKey=$apiKey'
    );

    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['items'] != null && data['items'].isNotEmpty) {
        // Get first product
        final product = data['items'][0];
        final productId = product['itemId'];
        
        // Return product URL with affiliate ID
        return 'https://www.walmart.com/ip/$productId?affp1=$publisherId';
      }
    }

    // Fallback to search URL
    final encodedName = Uri.encodeComponent(itemName);
    return 'https://www.walmart.com/search?q=$encodedName&affp1=$publisherId';
  } catch (e) {
    Logger.error('Failed to generate Walmart link', e, null, 'FirestoreService');
    // Fallback URL
    final encodedName = Uri.encodeComponent(itemName);
    return 'https://www.walmart.com/search?q=$encodedName&affp1=$publisherId';
  }
}
```

## Environment Variables

Store API credentials securely using environment variables:

### 1. Create `.env` file (add to `.gitignore`):

```
AMAZON_ACCESS_KEY=your_access_key
AMAZON_SECRET_KEY=your_secret_key
AMAZON_ASSOCIATE_TAG=yourstore-20
WALMART_API_KEY=your_walmart_key
WALMART_PUBLISHER_ID=your_publisher_id
```

### 2. Use `flutter_dotenv` package:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

### 3. Load in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ... rest of initialization
}
```

### 4. Access in FirestoreService:

```dart
final amazonAccessKey = dotenv.env['AMAZON_ACCESS_KEY']!;
final amazonSecretKey = dotenv.env['AMAZON_SECRET_KEY']!;
final amazonTag = dotenv.env['AMAZON_ASSOCIATE_TAG']!;
```

## Rate Limiting

Both APIs have rate limits:

- **Amazon**: 1 request per second per IP
- **Walmart**: Varies by plan

Implement caching to reduce API calls:

```dart
final _linkCache = <String, String>{};

Future<String> _generateAmazonLink(String itemName) async {
  // Check cache first
  if (_linkCache.containsKey(itemName)) {
    return _linkCache[itemName]!;
  }

  // Generate link...
  final link = await _generateLinkFromAPI(itemName);
  
  // Cache result
  _linkCache[itemName] = link;
  return link;
}
```

## Error Handling

Always provide fallback URLs:

```dart
try {
  // Try to get product link from API
  return await _getProductLinkFromAPI(itemName);
} catch (e) {
  // Fallback to search URL
  Logger.warning('API call failed, using search URL', e);
  return _generateSearchURL(itemName);
}
```

## Testing

Test with various ingredient names:

```dart
final testItems = [
  'tomato',
  'olive oil',
  'garlic cloves',
  'chicken breast',
  'all-purpose flour',
];

for (final item in testItems) {
  final link = await _generateAmazonLink(item);
  print('$item: $link');
}
```

## Additional Considerations

1. **Product Matching**: Consider using fuzzy matching or product categories to improve relevance
2. **Price Comparison**: Some APIs provide pricing - consider showing prices in the UI
3. **Product Images**: Display product images from API responses
4. **Multiple Results**: Allow users to choose from multiple product options
5. **Regional Support**: Handle different regions/stores (US, UK, etc.)

## Security Notes

- **Never commit API keys** to version control
- Use environment variables or secure storage
- Rotate keys regularly
- Monitor API usage for unusual activity
- Implement request signing for Amazon API (required)

## Resources

- [Amazon Product Advertising API Docs](https://webservices.amazon.com/paapi5/documentation/)
- [Walmart Affiliate API Docs](https://affiliates.walmart.com/api)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Environment Variables in Flutter](https://pub.dev/packages/flutter_dotenv)

