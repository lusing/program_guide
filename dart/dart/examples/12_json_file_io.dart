// 12 JSON 编解码与文件 IO（dart:convert、dart:io）
import 'dart:convert';
import 'dart:io';

class Article {
  final String title;
  final List<String> tags;

  Article({required this.title, required this.tags});

  // 序列化
  Map<String, Object?> toJson() => {'title': title, 'tags': tags};

  // 反序列化
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      tags: (json['tags'] as List).cast<String>(),
    );
  }

  @override
  String toString() => 'Article(title=$title, tags=$tags)';
}

void main() async {
  // 对象 <-> JSON 字符串
  var article = Article(title: 'Dart 指南', tags: ['dart', 'tutorial']);
  var jsonText = jsonEncode(article);
  print('encoded: $jsonText');

  var decoded = Article.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
  print('decoded: $decoded');

  // 格式化输出
  var pretty = JsonEncoder.withIndent('  ').convert(article.toJson());
  print('pretty:\n$pretty');

  // 文件读写
  var dir = Directory.systemTemp.createTempSync('dart_guide_');
  var file = File('${dir.path}${Platform.pathSeparator}note.txt');

  await file.writeAsString('第一行\n第二行', encoding: utf8);
  var content = await file.readAsString(encoding: utf8);
  print('file content:\n$content');

  // 追加写入与按行读取
  await file.writeAsString('\n第三行', mode: FileMode.append, encoding: utf8);
  var lines = await file.readAsLines(encoding: utf8);
  print('lines = $lines');
  print('exists = ${await file.exists()}, size = ${await file.length()} bytes');

  // 清理
  await file.delete();
  await dir.delete();
  print('cleaned up: ${!await dir.exists()}');
}
