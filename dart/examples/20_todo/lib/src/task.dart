/// 一条待办。
class Task {
  final int id;
  String title;
  bool done;

  Task({required this.id, required this.title, this.done = false});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  @override
  String toString() => '${done ? "[x]" : "[ ]"} #$id $title';
}

/// 预期的业务失败（第 12 章：可预期失败用 Exception 而非 Error）。
class TaskNotFound implements Exception {
  final int id;
  TaskNotFound(this.id);

  @override
  String toString() => '找不到 id=$id 的待办';
}

/// 列表上的操作：命令处理的核心逻辑（纯内存，好测试）。
extension TaskListX on List<Task> {
  int nextId() => fold(0, (max, t) => t.id > max ? t.id : max) + 1;

  void toggle(int id) {
    for (final t in this) {
      if (t.id == id) {
        t.done = !t.done;
        return;
      }
    }
    throw TaskNotFound(id);
  }

  void removeById(int id) {
    final before = length;
    removeWhere((t) => t.id == id);
    if (length == before) {
      throw TaskNotFound(id);
    }
  }
}
