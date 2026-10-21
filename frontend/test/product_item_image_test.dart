import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/auditor_buy_model.dart';

void main() {
  group('ProductItem image resolution', () {
    test('resolves standard backend upload path', () {
      final item = ProductItem.fromJson({
        'id': 1,
        'name': 'Apple iPhone 16 Pro Max',
        'category': 'Electronics',
        'price': 149999.0,
        'image': 'api/uploads/products/1785129934_6a66ebce25612.png',
      });

      expect(
        item.imageUrl,
        '${ApiConfig.siteBaseUrl}/api/uploads/products/1785129934_6a66ebce25612.png',
      );
      expect(item.candidateImageUrls, contains(
        '${ApiConfig.siteBaseUrl}/uploads/products/1785129934_6a66ebce25612.png',
      ));
    });

    test('resolves image_url field when image is absent', () {
      final item = ProductItem.fromJson({
        'id': 2,
        'name': 'Samsung Galaxy S25 Ultra',
        'category': 'Electronics',
        'price': 134999.0,
        'image_url': 'uploads/products/1785130832_6a66ef509a1cc.png',
      });

      expect(
        item.imageUrl,
        '${ApiConfig.siteBaseUrl}/uploads/products/1785130832_6a66ef509a1cc.png',
      );
    });

    test('normalizes Windows backslashes and bare filenames', () {
      final item = ProductItem.fromJson({
        'id': 3,
        'name': 'Tata Harrier Adventure+',
        'category': 'Vehicles (2wheeler/4wheeler)',
        'price': 2849000.0,
        'image': r'api\uploads\products\1785131002_6a66effaba441.png',
      });

      expect(
        item.imageUrl,
        '${ApiConfig.siteBaseUrl}/api/uploads/products/1785131002_6a66effaba441.png',
      );
    });

    test('falls back to category default backend image when image is null', () {
      final item = ProductItem.fromJson({
        'id': 4,
        'name': '24K Gold Coin (1g)',
        'category': 'Gold',
        'price': 7850.0,
      });

      expect(item.imageUrl, isNotNull);
      expect(item.imageUrl, contains('1778586023_6a0311a7de7d4.png'));
    });
  });
}
