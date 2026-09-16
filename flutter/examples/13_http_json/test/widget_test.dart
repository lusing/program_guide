import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_json_app/main.dart';

void main() {
  testWidgets('注入假 fetcher：JSON 数据渲染成列表', (tester) async {
    await tester.pumpWidget(NewsApp(
      fetcher: () async => const [
        NewsItem(id: 1, title: '本地假数据 A', done: true),
        NewsItem(id: 2, title: '本地假数据 B', done: false),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('本地假数据 A'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('加载失败态', (tester) async {
    await tester.pumpWidget(NewsApp(
      fetcher: () => Future.error('网络不通'),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('加载失败'), findsOneWidget);
  });

  test('NewsItem.fromJson 解析', () {
    final n = NewsItem.fromJson({'id': 9, 'title': 't', 'done': false});
    expect(n.id, 9);
    expect(n.title, 't');
    expect(n.done, isFalse);
  });
}
