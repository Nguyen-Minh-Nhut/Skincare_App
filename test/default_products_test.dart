import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/data/default_products.dart';

void main() {
  test('bundled product catalog contains valid editable placeholders', () {
    expect(defaultProducts, hasLength(14));

    final ids = defaultProducts.map((product) => product['id']).toSet();
    expect(ids, hasLength(defaultProducts.length));

    for (final product in defaultProducts) {
      expect(product['name'], isNotEmpty);
      expect(product['image'], startsWith('assets/products/'));
      expect(product['price'], isEmpty);
      expect(product['description'], isEmpty);
      expect(product['isBundled'], isTrue);
    }
  });
}
