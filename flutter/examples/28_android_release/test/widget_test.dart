// 28 · 发布清单页：身份信息可见即可（构建链路由 flutter build apk 实测）。
import 'package:flutter_test/flutter_test.dart';

import 'package:android_release_app/main.dart';

void main() {
  testWidgets('发布身份与清单展示', (tester) async {
    await tester.pumpWidget(const ReleaseChecklistApp());

    expect(find.textContaining('com.guide.release_demo'), findsOneWidget);
    expect(find.text('version: 1.2.0+7'), findsOneWidget);
    expect(find.text('签名'), findsOneWidget);
    expect(find.text('上架'), findsOneWidget);
  });
}
