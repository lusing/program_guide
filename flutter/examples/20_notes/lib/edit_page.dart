import 'package:flutter/material.dart';

import 'note.dart';

/// 编辑页：新建收 note=null；返回时 pop 带保存后的 Note。
class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.note, required this.nextId});

  final Note? note;
  final int nextId;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
  late final _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final note = (widget.note ?? Note(id: widget.nextId, title: '', body: ''))
        .copyWith(
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        actions: [
          IconButton(
              icon: const Icon(Icons.check), tooltip: '保存', onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '标题'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: '正文',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
