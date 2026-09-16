import 'dart:convert';
import 'dart:io';

import 'note.dart';

/// 存储抽象：页面依赖它而不是具体文件——测试注入内存实现（依赖注入）。
abstract class NotesStorage {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

/// JSON 文件实现（桌面演示：临时目录下固定文件）。
class FileNotesStorage implements NotesStorage {
  FileNotesStorage(this.path);

  final String path;

  @override
  Future<List<Note>> load() async {
    final file = File(path);
    if (!await file.exists()) return [];
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> save(List<Note> notes) async {
    final json = const JsonEncoder.withIndent('  ')
        .convert(notes.map((n) => n.toJson()).toList());
    await File(path).writeAsString('$json\n');
  }
}
