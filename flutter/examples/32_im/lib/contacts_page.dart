import 'package:flutter/material.dart';

import 'data.dart';

/// 通讯录页：字母分组列表 + 右侧 A–Z 拖拽索引条。
///
/// 书 16.8 的 ContactSiderList 只做了"字母分组 + Offstage 控制组头"；
/// 索引条（拖一下跳到对应组）是本教程补齐的实现——IM 的招牌交互。
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.contacts, this.onTapContact});

  final List<Contact> contacts;

  /// 点击联系人回调（不传则显示"点击了某某"的轻提示）。
  final ValueChanged<Contact>? onTapContact;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _scroll = ScrollController();

  /// 出现过的字母，按序（索引条只画这些）。
  late final List<String> _letters;

  /// 每个字母组顶部的列表偏移量（像素），与布局常量严格配套。
  late final List<double> _offsets;

  /// 拖拽索引条时当前停住的字母；null = 没在拖。
  String? _activeLetter;

  static const _sectionHeight = 32.0; // 字母组头高
  static const _tileHeight = 56.0; // 联系人行高

  @override
  void initState() {
    super.initState();
    _letters = widget.contacts.map((c) => c.letter).toSet().toList();
    _offsets = _computeOffsets();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<double> _computeOffsets() {
    final offsets = <double>[];
    var y = 0.0;
    var lastLetter = '';
    for (final c in widget.contacts) {
      if (c.letter != lastLetter) {
        offsets.add(y); // 新组：记下组头位置
        y += _sectionHeight;
        lastLetter = c.letter;
      }
      y += _tileHeight;
    }
    return offsets;
  }

  /// 索引条手势核心：本地坐标 → 按高度比例换算到字母下标。
  /// 收 Offset 而不是 Drag*Details——Start/Update 两种细节都喂得进来；
  /// barBox 是索引条自己的约束（LayoutBuilder 现场取，别拿外层的凑合）。
  void _onIndexPan(Offset localPosition, BoxConstraints barBox) {
    final dy = localPosition.dy.clamp(0.0, barBox.maxHeight);
    final idx = (dy / barBox.maxHeight * _letters.length)
        .clamp(0, _letters.length - 1)
        .toInt();
    final letter = _letters[idx];
    if (letter != _activeLetter) {
      setState(() => _activeLetter = letter);
      // jumpTo 而非 animateTo：拖拽跟手要" teleport"，滑动反而碍事。
      _scroll.jumpTo(_offsets[idx].clamp(
          0.0, // 偏移可能超出最大滚动范围（列表不满屏时）——clamp 收口
          _scroll.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 索引条贴列表右缘、上下留白；feedback 气泡盖在正中央。
          return Stack(
            children: [
              _buildList(),
              Positioned(
                top: 8,
                bottom: 8,
                right: 6,
                child: _buildIndexBar(constraints),
              ),
              if (_activeLetter != null)
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _activeLetter!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scroll,
      // 组头与行高是"合约"：偏移表按它们算，改一处必须两处同步。
      itemCount: widget.contacts.length,
      itemBuilder: (context, i) {
        final contact = widget.contacts[i];
        final isFirstOfGroup =
            i == 0 || widget.contacts[i - 1].letter != contact.letter;
        return Column(
          children: [
            if (isFirstOfGroup)
              SizedBox(
                height: _sectionHeight,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    contact.letter,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            SizedBox(
              height: _tileHeight,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: contact.avatarColor,
                  foregroundColor: Colors.white,
                  child: Text(contact.initial),
                ),
                title: Text(contact.name),
                onTap: () {
                  final cb = widget.onTapContact;
                  if (cb != null) {
                    cb(contact);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('点击了 ${contact.name}')));
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIndexBar(BoxConstraints outer) {
    return LayoutBuilder(
      builder: (context, barBox) => GestureDetector(
        key: const ValueKey('index_bar'),
        // onVerticalDragStart/Update/End 三件套：按下即选中、滑动换字母、松手收气泡
        onVerticalDragStart: (d) => _onIndexPan(d.localPosition, barBox),
        onVerticalDragUpdate: (d) => _onIndexPan(d.localPosition, barBox),
        onVerticalDragEnd: (_) => setState(() => _activeLetter = null),
        behavior: HitTestBehavior.opaque, // 空隙也算命中，好按
        child: Container(
        width: 24,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final letter in _letters)
              Text(
                letter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: letter == _activeLetter
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: letter == _activeLetter
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

/// 搜索页（书 16.6）：一进来就要焦点，键盘直接待命。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _focus = FocusNode();
  final _input = TextEditingController();
  late final List<Contact> _all = kContacts;
  List<Contact> _hits = const [];

  @override
  void initState() {
    super.initState();
    // 请求焦点要等第一帧布局完成，否则没有可聚焦的宿主。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() {
      _hits = q.isEmpty
          ? const []
          : _all.where((c) => c.name.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _input,
              focusNode: _focus,
              autofocus: false, // 焦点走 FocusNode.requestFocus 的显式路径
              onChanged: _onQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '输入姓名过滤',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_input.text.isNotEmpty && _hits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('没有匹配的联系人'),
            ),
          for (final c in _hits)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: c.avatarColor,
                foregroundColor: Colors.white,
                child: Text(c.initial),
              ),
              title: Text(c.name),
              trailing: Text(c.letter),
            ),
        ],
      ),
    );
  }
}
