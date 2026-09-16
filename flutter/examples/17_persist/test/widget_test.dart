import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:persist_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 文件往返：真实 IO，放普通 test（不进 widget 测试的假时钟环境）
  test('FileCounter 写读往返', () async {
    final path = '${Directory.systemTemp.path}/guide17_test.json';
    final counter = FileCounter(path);
    await counter.write(41);
    expect(await counter.read(), 41);
    File(path).deleteSync();
  });

  test('FileCounter 缺文件返回 0', () async {
    final counter =
        FileCounter('${Directory.systemTemp.path}/guide17_missing.json');
    expect(await counter.read(), 0);
  });

  testWidgets('prefs mock：预置值渲染、+1 持久', (tester) async {
    SharedPreferences.setMockInitialValues({'prefs_count': 7});
    await tester.pumpWidget(const PersistApp());
    await tester.pumpAndSettle();
    expect(find.text('prefs 计数：7'), findsOneWidget);
    await tester.tap(find.text('prefs +1 并保存'));
    await tester.pumpAndSettle();
    expect(find.text('prefs 计数：8'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('prefs_count'), 8); // 真的存回去了
  });
}
