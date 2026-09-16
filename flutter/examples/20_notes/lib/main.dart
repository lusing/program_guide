import 'dart:io';

import 'package:flutter/material.dart';

import 'edit_page.dart';
import 'note.dart';
import 'storage.dart';

// 20 实战记事本：列表 + 编辑 + 持久化 + 主题切换 + 删除确认
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await DirectoryWrapper.tempDir();
  runApp(NotesApp(storage: FileNotesStorage('${dir.path}/notes.json')));
}

/// 可替换的目录来源（保持 main 可测的薄封装）。
class DirectoryWrapper {
  static Future<Directory> tempDir() async => Directory.systemTemp;
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.storage});

  final NotesStorage storage;

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记事本',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: NotesHomePage(
        storage: widget.storage,
        onModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({
    super.key,
    required this.storage,
    required this.onModeChanged,
  });

  final NotesStorage storage;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final notes = await widget.storage.load();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _openEditor({Note? note}) async {
    final saved = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(note: note, nextId: _nextId()),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      final i = _notes.indexWhere((n) => n.id == saved.id);
      if (i >= 0) {
        _notes[i] = saved;
      } else {
        _notes.insert(0, saved);
      }
    });
    await widget.storage.save(_notes);
  }

  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「${note.title}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await widget.storage.save(_notes);
  }

  int _nextId() => _notes.fold(0, (max, n) => n.id > max ? n.id : max) + 1;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记事本'),
        actions: [
          IconButton(
            tooltip: dark ? '切换浅色' : '切换深色',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                widget.onModeChanged(dark ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('还没有笔记，点 + 新建'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, i) {
                    final n = _notes[i];
                    return ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: Text(n.title.isEmpty ? '（无标题）' : n.title),
                      subtitle: n.body.isEmpty
                          ? null
                          : Text(n.body,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _openEditor(note: n),
                      onLongPress: () => _confirmDelete(n),
                    );
                  },
                ),
    );
  }
}
