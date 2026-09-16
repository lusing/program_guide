import 'package:cart_demo/cart.dart';
import 'package:test/test.dart';

void main() {
  // group：把同一主题的用例聚在一起，共享 setUp 里的夹具
  group('Cart 合计', () {
    late Cart cart;

    setUp(() {
      cart = Cart();
      cart.add(const CartItem('书', 45.0, 2));
      cart.add(const CartItem('笔', 5.0, 3));
    });

    test('单价×数量后求和', () {
      expect(cart.total, closeTo(105.0, 0.001));
    });

    test('满 100 打九折', () {
      expect(cart.payable(), closeTo(94.5, 0.001));
    });

    test('空车不打折', () {
      expect(Cart().payable(), 0);
    });
  });

  group('CartItem.parse 校验', () {
    test('负数量抛 ArgumentError', () {
      expect(() => CartItem.parse('书', 45.0, -1), throwsA(isA<ArgumentError>()));
    });

    test('正常输入', () {
      final item = CartItem.parse('书', 45.0, 1);
      expect(item.name, '书');
      expect(item.subtotal, 45.0);
    });
  });

  test('集合匹配器', () {
    final cart = Cart()..add(const CartItem('书', 45.0, 1));
    expect(cart.items.map((i) => i.name), contains('书'));
    expect(cart.items, hasLength(1));
  });
}
