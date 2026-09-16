import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 17 数据持久化：文件（dart:io）与 shared_preferences
void main() async {
  runApp(const PersistApp());
}

class PersistApp extends StatelessWidget {
  const PersistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const PersistPage(),
    );
  }
}

// ═══ 17.1 文件存储：JSON 落盘（模板见 Dart 教程·第 18 章） ═══
class FileCounter {
  FileCounter(this.path);

  final String path;

  Future<int> read() async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return jsonDecode(await file.readAsString()) as int;
  }

  Future<void> write(int value) async {
    await File(path).writeAsString(jsonEncode(value));
  }
}

class PersistPage extends StatefulWidget {
  const PersistPage({super.key});

  @override
  State<PersistPage> createState() => _PersistPageState();
}

class _PersistPageState extends State<PersistPage> {
  static const _prefsKey = 'prefs_count';
  // 桌面演示用临时目录（真实应用建议 path_provider 取应用数据目录）
  late final FileCounter _file = FileCounter(
    '${Directory.systemTemp.path}/flutter_guide_17.json',
  );
  int _fileCount = 0;
  int _prefsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _prefsCount = prefs.getInt(_prefsKey) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据持久化')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 17.2 shared_preferences：键值对存取 ═══
          Text('prefs 计数：$_prefsCount',
              style: Theme.of(context).textTheme.titleLarge),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final next = (prefs.getInt(_prefsKey) ?? 0) + 1;
              await prefs.setInt(_prefsKey, next);
              if (!mounted) return;
              setState(() => _prefsCount = next);
            },
            child: const Text('prefs +1 并保存'),
          ),
          const Divider(height: 32),
          // ═══ 17.3 文件：读盘/写盘按钮 ═══
          Text('文件计数：$_fileCount',
              style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final v = await _file.read();
                  if (!mounted) return;
                  setState(() => _fileCount = v);
                },
                child: const Text('从文件读'),
              ),
              FilledButton(
                onPressed: () async {
                  await _file.write(_fileCount + 1);
                  if (!mounted) return;
                  setState(() => _fileCount++);
                },
                child: const Text('写入文件'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('选型：小键值用 prefs；结构化数据用 JSON 文件；大量数据上 sqflite（生态）'),
        ],
      ),
    );
  }
}
