import 'package:flutter_test/flutter_test.dart';
import 'package:state_sharing_app/main.dart';

void main() {
  testWidgets('子组件改、另一子组件显示：共享生效', (tester) async {
    await tester.pumpWidget(const StateSharingApp());
    expect(find.text('购物车：0 件'), findsOneWidget);
    await tester.tap(find.text('加入购物车'));
    await tester.pump(); // notifyListeners 触发依赖者重建
    expect(find.text('购物车：1 件'), findsOneWidget);
  });
}
