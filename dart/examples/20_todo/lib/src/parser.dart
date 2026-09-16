/// 命令解析：把 argv 变成类型安全的 Command（sealed + 模式匹配实战）。
sealed class Command {
  const Command();
}

class AddCommand extends Command {
  final String title;
  const AddCommand(this.title);
}

class ListCommand extends Command {
  final bool showAll;
  const ListCommand(this.showAll);
}

class DoneCommand extends Command {
  final int id;
  const DoneCommand(this.id);
}

class RemoveCommand extends Command {
  final int id;
  const RemoveCommand(this.id);
}

/// 解析结果：Ok(命令, 数据文件) 或 ParseErr(提示)——把错误当值传。
sealed class ParseResult {
  const ParseResult();
}

class Ok extends ParseResult {
  final Command command;
  final String file;
  const Ok(this.command, this.file);
}

class ParseErr extends ParseResult {
  final String message;
  const ParseErr(this.message);
}

const usageText = '''
用法：dart run bin/todo.dart [-f 数据文件] <命令>

命令：
  add <标题>        新增待办
  list [--all]      列出待办（默认只看未完成）
  done <id>         完成指定待办
  remove <id>       删除指定待办''';

/// 解析 [-f file] 前缀 + 子命令。
ParseResult parse(List<String> args) {
  var file = 'todo.json';
  var rest = args;
  if (rest.isNotEmpty && rest.first == '-f') {
    if (rest.length < 3) {
      return const ParseErr(usageText); // -f 之后必须有文件和命令
    }
    file = rest[1];
    rest = rest.sublist(2);
  }
  if (rest.isEmpty) {
    return const ParseErr(usageText);
  }
  final Command command;
  switch (rest[0]) {
    case 'add':
      if (rest.length < 2 || rest[1].isEmpty) {
        return const ParseErr('add 需要标题，例如：add 买牛奶');
      }
      command = AddCommand(rest[1]);
    case 'list':
      command = ListCommand(rest.contains('--all'));
    case 'done':
    case 'remove':
      final id = rest.length > 1 ? int.tryParse(rest[1]) : null;
      if (id == null) {
        return ParseErr('${rest[0]} 需要数字 id，例如：${rest[0]} 1');
      }
      command = rest[0] == 'done' ? DoneCommand(id) : RemoveCommand(id);
    default:
      return ParseErr('未知命令：${rest[0]}\n$usageText');
  }
  return Ok(command, file);
}
