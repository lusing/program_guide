import 'dart:async';

import 'package:flutter/material.dart';

import 'data.dart';

/// 聊天页：消息气泡列表 + 底部输入栏 + 确定性回声机器人。
///
/// 布局拆分（书 16.7 的方法论）：整页 Column，
/// 上段 Expanded(ListView) 管消息，下段输入栏贴底。
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});

  final Contact peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _bot = EchoBot();
  late final List<Message> _messages;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = seedMessages(widget.peer);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _sending = true;
    setState(() {
      _input.clear();
      _messages.add(Message(fromMe: true, text: text, time: '现在'));
    });
    _scrollToBottom();

    final reply = await _bot.reply(text); // 300ms 后回声
    if (!mounted) return;
    setState(() => _messages.add(reply));
    _scrollToBottom();
    _sending = false;
  }

  void _scrollToBottom() {
    // 下一帧再滚：新气泡此刻可能还没完成布局。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peer.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) =>
                  _BubbleRow(message: _messages[i], peer: widget.peer),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      // 手机键盘的"发送"键；桌面回车直接发出
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '说点什么…',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _input,
                    builder: (context, value, _) => IconButton.filled(
                      onPressed: value.text.trim().isEmpty ? null : _send,
                      icon: const Icon(Icons.send),
                      tooltip: '发送',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一行消息：头像 + 气泡。自己在右（绿底白字），对方在左（灰底）。
class _BubbleRow extends StatelessWidget {
  const _BubbleRow({required this.message, required this.peer});

  final Message message;
  final Contact peer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.fromMe ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          // 自己的气泡缺口朝右下，对方的朝左下（靠近头像一侧开口）
          bottomLeft:
              message.fromMe ? const Radius.circular(12) : Radius.zero,
          bottomRight:
              message.fromMe ? Radius.zero : const Radius.circular(12),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
            color: message.fromMe ? scheme.onPrimary : scheme.onSurface),
      ),
    );

    final avatar = CircleAvatar(
      backgroundColor: peer.avatarColor,
      foregroundColor: Colors.white,
      child: Text(peer.initial),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.fromMe
            ? [bubble, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), bubble],
      ),
    );
  }
}
