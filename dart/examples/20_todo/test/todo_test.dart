import 'dart:io';

import 'package:test/test.dart';
import 'package:todo_cli/todo.dart';

void main() {
  group('parser', () {
    test('解析 add（默认数据文件）', () {
      final ok = parse(['add', '买牛奶']) as Ok;
      expect(ok.file, 'todo.json');
      expect((ok.command as AddCommand).title, '买牛奶');
    });

    test('-f 指定数据文件 + done 命令', () {
      final ok = parse(['-f', 'a.json', 'done', '3']) as Ok;
      expect(ok.file, 'a.json');
      expect((ok.command as DoneCommand).id, 3);
    });

    test('未知命令给错误提示', () {
      final err = parse(['fly']);
      expect(err, isA<ParseErr>());
    });

    test('done 缺 id 报错', () {
      expect(parse(['done']), isA<ParseErr>());
    });

    test('list --all 生效', () {
      final ok = parse(['list', '--all']) as Ok;
      expect((ok.command as ListCommand).showAll, isTrue);
    });
  });

  group('task 操作', () {
    test('nextId 从最大 id+1', () {
      final tasks = [Task(id: 2, title: 'a'), Task(id: 5, title: 'b')];
      expect(tasks.nextId(), 6);
    });

    test('toggle 找不到抛 TaskNotFound', () {
      final tasks = [Task(id: 1, title: 'a')];
      expect(() => tasks.toggle(9), throwsA(isA<TaskNotFound>()));
    });

    test('removeById 删除后长度变化', () {
      final tasks = [Task(id: 1, title: 'a'), Task(id: 2, title: 'b')];
      tasks.removeById(1);
      expect(tasks, hasLength(1));
      expect(tasks.single.id, 2);
    });
  });

  group('storage 往返', () {
    test('保存后能原样读回；缺文件视为空', () {
      final dir = Directory.systemTemp.createTempSync('todo_test_');
      final path = '${dir.path}/t.json';
      saveTasks(path, [
        Task(id: 1, title: '买牛奶'),
        Task(id: 2, title: '写周报', done: true),
      ]);
      final restored = loadTasks(path);
      expect(restored.length, 2);
      expect(restored[1].title, '写周报');
      expect(restored[1].done, isTrue);
      expect(loadTasks('${dir.path}/missing.json'), isEmpty);
      dir.deleteSync(recursive: true);
    });
  });
}
