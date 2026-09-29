import 'package:flutter/material.dart';

/// 联系人（书 16.8.1 的 ContactVO 现代版）：
/// letter 是分组字母——真实应用里由拼音库算，教学数据手工给。
class Contact {
  const Contact(this.name, this.letter);

  final String name;
  final String letter;

  /// 头像底色：名字哈希落到调色板，同一人永远同色（确定性）。
  Color get avatarColor =>
      Colors.primaries[name.hashCode % Colors.primaries.length];

  /// 头像首字。
  String get initial => name.characters.first;
}

/// 一条聊天消息：自己/对方 + 文本 + 时间。
class Message {
  const Message({required this.fromMe, required this.text, required this.time});

  final bool fromMe;
  final String text;
  final String time;
}

/// 会话列表的一项：对方 + 最后一条 + 未读数。
class Conversation {
  const Conversation({
    required this.peer,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
  });

  final Contact peer;
  final String lastMessage;
  final String time;
  final int unread;
}

/// 确定性回声机器人：回复只取决于输入与第几轮，测试可精确断言。
class EchoBot {
  int _rounds = 0;

  Future<Message> reply(String userText) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _rounds++;
    return Message(
      fromMe: false,
      text: '收到「$userText」（第 $_rounds 轮）',
      time: '现在',
    );
  }
}

/// 好友名单：覆盖 A–Z 里出现过的字母，索引条才有得跳。
const List<Contact> kContacts = [
  Contact('阿伟', 'A'), Contact('安妮', 'A'),
  Contact('白展堂', 'B'), Contact('包拯', 'B'), Contact('冰冰', 'B'),
  Contact('曹操', 'C'), Contact('陈默', 'C'),
  Contact('杜甫', 'D'), Contact('丁力', 'D'),
  Contact('范进', 'F'),
  Contact('韩梅梅', 'H'),
  Contact('李白', 'L'), Contact('刘墉', 'L'),
  Contact('慕容复', 'M'),
  Contact('王语嫣', 'W'), Contact('吴用', 'W'),
  Contact('谢逊', 'X'),
  Contact('杨过', 'Y'),
  Contact('张三', 'Z'), Contact('赵敏', 'Z'), Contact('周伯通', 'Z'),
];

/// 会话种子数据（书 16.7.1 的 MessageData 简化版）。
const List<Conversation> kConversations = [
  Conversation(peer: Contact('张三', 'Z'), lastMessage: '明天见？', time: '09:12', unread: 2),
  Conversation(peer: Contact('韩梅梅', 'H'), lastMessage: '文档我改好了', time: '昨天', unread: 0),
  Conversation(peer: Contact('李白', 'L'), lastMessage: '飞流直下三千尺', time: '昨天', unread: 5),
  Conversation(peer: Contact('安妮', 'A'), lastMessage: '[图片]', time: '周一', unread: 0),
  Conversation(peer: Contact('王语嫣', 'W'), lastMessage: '琅嬛福地见', time: '周一', unread: 0),
  Conversation(peer: Contact('丁力', 'D'), lastMessage: '收到，谢啦', time: '上周', unread: 0),
];

/// 聊天页开场消息。
List<Message> seedMessages(Contact peer) => [
      Message(fromMe: false, text: '你好，我是${peer.name}', time: '09:00'),
      Message(fromMe: true, text: '你好！', time: '09:01'),
      Message(fromMe: false, text: '在忙吗？', time: '09:02'),
    ];
