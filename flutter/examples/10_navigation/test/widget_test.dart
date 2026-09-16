import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_app/main.dart';

void main() {
  testWidgets('push 传参、pop 带返回值', (tester) async {
    await tester.pumpWidget(const NavigationApp());
    await tester.tap(find.text('打开详情页（传参 7）'));
    await tester.pumpAndSettle();
    expect(find.text('收到参数：7'), findsOneWidget);
    await tester.tap(find.text('选定并返回'));
    await tester.pumpAndSettle();
    expect(find.text('详情页返回值：选中了 #7'), findsOneWidget);
  });

  testWidgets('命名路由跳转', (tester) async {
    await tester.pumpWidget(const NavigationApp());
    await tester.tap(find.text('关于（命名路由）'));
    await tester.pumpAndSettle();
    expect(find.text('这是命名路由页面'), findsOneWidget);
  });
}
