import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/note.dart';
import 'package:notes_app/storage.dart';

/// 内存实现：widget 测试注入，零真实 IO。
class InMemoryStorage implements NotesStorage {
  InMemoryStorage([this.seed = const []]);

  final List<Note> seed;

  List<Note> saved = [];

  @override
  Future<List<Note>> load() async => [...seed]; // 返回拷贝：调用方要 insert/remove

  @override
  Future<void> save(List<Note> notes) async => saved = [...notes];
}

Note _note(int id, String title) => Note(id: id, title: title, body: '内容 $id');

void main() {
  test('Note JSON 往返', () {
    final n =
        Note(id: 1, title: 't', body: 'b', updatedAt: DateTime(2026, 1, 1));
    final restored = Note.fromJson(n.toJson());
    expect(restored.title, 't');
    expect(restored.updatedAt, DateTime(2026, 1, 1));
  });

  test('FileNotesStorage 往返与空文件', () async {
    final path = '${Directory.systemTemp.path}/notes20_test.json';
    final storage = FileNotesStorage(path);
    expect(await storage.load(), isEmpty);
    await storage.save([_note(1, '一'), _note(2, '二')]);
    final loaded = await storage.load();
    expect(loaded.length, 2);
    expect(loaded[1].title, '二');
    File(path).deleteSync();
  });

  testWidgets('初始加载渲染', (tester) async {
    await tester.pumpWidget(NotesApp(
      storage: InMemoryStorage([_note(1, '第一篇'), _note(2, '第二篇')]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('第一篇'), findsOneWidget);
    expect(find.text('第二篇'), findsOneWidget);
  });

  testWidgets('新建并保存', (tester) async {
    final storage = InMemoryStorage();
    await tester.pumpWidget(NotesApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '新笔记标题');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('新笔记标题'), findsOneWidget);
    expect(storage.saved.single.title, '新笔记标题'); // 真的存了
  });

  testWidgets('长按删除确认', (tester) async {
    final storage = InMemoryStorage([_note(1, '待删除')]);
    await tester.pumpWidget(NotesApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('待删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('待删除'), findsNothing);
    expect(storage.saved, isEmpty);
  });

  testWidgets('主题切换', (tester) async {
    await tester.pumpWidget(
      NotesApp(storage: InMemoryStorage([_note(1, 'x')])),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode), findsOneWidget); // 图标随主题翻转
  });
}
