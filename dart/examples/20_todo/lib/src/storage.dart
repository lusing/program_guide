import 'dart:convert';
import 'dart:io';

import 'task.dart';

/// 从 JSON 文件读取待办；文件不存在视为空列表（首次使用）。
List<Task> loadTasks(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return [];
  }
  final decoded = jsonDecode(file.readAsStringSync());
  return (decoded as List)
      .map((e) => Task.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 把待办写回 JSON 文件（缩进 2，方便人看）。
void saveTasks(String path, List<Task> tasks) {
  final json = const JsonEncoder.withIndent('  ')
      .convert(tasks.map((t) => t.toJson()).toList());
  File(path).writeAsStringSync('$json\n');
}
