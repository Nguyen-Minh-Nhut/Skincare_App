import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/data/default_products.dart';

void main() {
  test('bundled product catalog contains valid product details', () {
    expect(defaultProducts, hasLength(14));

    final ids = defaultProducts.map((product) => product['id']).toSet();
    expect(ids, hasLength(defaultProducts.length));

    for (final product in defaultProducts) {
      expect(product['name'], isNotEmpty);
      expect(product['image'], startsWith('assets/products/'));
      expect(
        product['price'],
        matches(r'^(Khoảng )?\d{1,3}(\.\d{3})*(–\d{1,3}(\.\d{3})*)?đ$'),
      );
      expect(product['description'], isNotEmpty);
      expect(product['isBundled'], isTrue);
    }
  });
}
