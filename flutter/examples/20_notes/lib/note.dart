/// 一条笔记：纯数据模型（模板见 Dart 教程·第 18/20 章）。
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  final int id;
  final String title;
  final String body;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
