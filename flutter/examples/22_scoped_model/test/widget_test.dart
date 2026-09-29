// 22 · 手写 scoped_model 的测试：模型军规 + 界面行为锁死。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoped_model_app/main.dart';

void main() {
  group('模型层（纯 Dart，不起界面）', () {
    test('添加、过滤 getter', () {
      final model = MainScopeModel();
      model.addNews(const NewsItem(title: 'A', score: 1));
      model.addNews(const NewsItem(title: 'B', score: 2));
      expect(model.displayNews.length, 2);

      model.toggleDisplayMode(); // 只看收藏：一条都没收藏
      expect(model.displayNews, isEmpty);
    });

    test('防御性拷贝：改返回的列表不影响内部', () {
      final model = MainScopeModel()..seed();
      final outside = model.displayNews;
      outside.clear();
      expect(model.displayNews.length, 3);
    });

    test('过滤模式下按实体删除不错位', () {
      final model = MainScopeModel()..seed();
      const favorite = NewsItem(title: 'X', score: 5, isFavorite: true);
      const plain = NewsItem(title: 'Y', score: 5);
      model.addNews(favorite);
      model.addNews(plain);
      model.toggleDisplayMode();
      expect(model.displayNews.length, 1); // 只有收藏的 X

      model.deleteNews(model.displayNews.first); // 删"过滤后第一项"
      model.toggleDisplayMode(); // 回到全部
      expect(model.totalCount, 4); // 3 种子 + Y——删的正是 X，没有错位
    });

    test('toggleFavorite 换新对象且通知', () {
      final model = MainScopeModel();
      const item = NewsItem(title: 'A', score: 1);
      model.addNews(item);
      var notified = 0;
      model.addListener(() => notified++);
      model.toggleFavorite(item);

      expect(model.displayNews.single.isFavorite, isTrue);
      expect(notified, 1);
    });
  });

  group('界面（widget 测试）', () {
    testWidgets('首屏：3 条种子 + 底部统计', (tester) async {
      await tester.pumpWidget(const ScopedModelApp());
      expect(find.text('滑动可以删除这条'), findsOneWidget);
      expect(find.textContaining('共 3 条'), findsOneWidget);
    });

    testWidgets('收藏：图标立刻变实心（notifyListeners 生效）', (tester) async {
      await tester.pumpWidget(const ScopedModelApp());

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget); // 卡片上的
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(3)); // 其余卡片+AppBar
    });

    testWidgets('过滤：只显示收藏的，再点恢复', (tester) async {
      await tester.pumpWidget(const ScopedModelApp());
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('只看收藏 / 全部'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byTooltip('只看收藏 / 全部'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('滑动删除（Dismissible + 按实体删）', (tester) async {
      await tester.pumpWidget(const ScopedModelApp());

      await tester.fling(find.text('滑动可以删除这条'), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text('滑动可以删除这条'), findsNothing);
      expect(find.textContaining('共 2 条'), findsOneWidget);
    });

    testWidgets('对话框添加：对话框内也能取到模型', (tester) async {
      await tester.pumpWidget(const ScopedModelApp());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '新增条目');
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await tester.pumpAndSettle();

      expect(find.text('新增条目'), findsOneWidget);
      expect(find.textContaining('共 4 条'), findsOneWidget);
    });
  });
}
