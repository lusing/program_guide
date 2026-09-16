/// 19 章 fixture：一个纯逻辑购物车，演示"可测试的代码"长什么样。
class CartItem {
  final String name;
  final double unitPrice;
  final int quantity;

  const CartItem(this.name, this.unitPrice, this.quantity);

  double get subtotal => unitPrice * quantity;

  /// 数量必须为正整数，否则抛 ArgumentError——负例测试的目标。
  static CartItem parse(String name, double price, int qty) {
    if (qty <= 0) {
      throw ArgumentError('数量必须是正数：$qty');
    }
    return CartItem(name, price, qty);
  }
}

class Cart {
  final List<CartItem> items = [];

  void add(CartItem item) {
    items.add(item);
  }

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  /// 满 [threshold] 元打 [rate] 折（0.9 = 九折）；空车或未达标不打折。
  double payable({double threshold = 100, double rate = 0.9}) {
    if (items.isEmpty || total < threshold) {
      return total;
    }
    return total * rate;
  }
}
