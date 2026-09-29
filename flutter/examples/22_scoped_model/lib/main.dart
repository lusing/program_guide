// 22 · 集中状态管理：手写 scoped_model 的资讯 App。
// 对照文档 docs/22-scoped-model.md 的 22.3 / 22.5 / 22.6 节。
// 注意：整个应用没有一个"业务 StatefulWidget"——状态全在模型里。
import 'package:flutter/material.dart';

import 'scoped_model.dart';

void main() => runApp(const ScopedModelApp());

// ═══ 22.3 实体类：final 字段 + required + 默认值 + copyWith ═══
class NewsItem {
  const NewsItem({required this.title, required this.score, this.isFavorite = false});

  final String title;
  final double score;
  final bool isFavorite;

  NewsItem copyWith({String? title, double? score, bool? isFavorite}) => NewsItem(
        title: title ?? this.title,
        score: score ?? this.score,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

// ═══ 22.5 模型层四军规：私有状态 / 防御性拷贝 / 按实体操作 / 改完必通知 ═══
mixin NewsPart on Model {
  final List<NewsItem> _news = [];
  bool _showFavorites = false;

  /// getter 出口做防御性拷贝：List.of 复制列表不复制元素。
  List<NewsItem> get displayNews => List.of(
        _showFavorites ? _news.where((n) => n.isFavorite).toList() : _news,
      );

  bool get showFavorites => _showFavorites;
  int get totalCount => _news.length;

  void seed() => _news.addAll(const [
        NewsItem(title: '滑动可以删除这条', score: 6.0),
        NewsItem(title: '点右上角星星试试过滤', score: 9.2),
        NewsItem(title: '收藏按钮演示精确重建', score: 8.5),
      ]);

  void addNews(NewsItem item) {
    _news.add(item);
    notifyListeners(); // 忘了这行：界面"切页才刷新"（书 11.7 的原版坑）
  }

  /// 按实体不按索引：过滤模式下展示索引 ≠ 内部索引，remove 走同一性匹配。
  void deleteNews(NewsItem item) {
    _news.remove(item);
    notifyListeners();
  }

  void toggleFavorite(NewsItem item) {
    final i = _news.indexOf(item);
    if (i < 0) return;
    _news[i] = item.copyWith(isFavorite: !item.isFavorite); // 换新对象
    notifyListeners();
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

// ═══ 22.6 第二个领域模型（用户），演示 mixin 合并 ═══
mixin UserPart on Model {
  String? _userName;

  String? get userName => _userName;

  void login(String name) {
    _userName = name;
    notifyListeners();
  }

  void logout() {
    _userName = null;
    notifyListeners();
  }
}

/// 书 11.10：with 把多个领域模型拍平成一个中央模型，一个 model 参数全带走。
class MainScopeModel extends Model with NewsPart, UserPart {}

class ScopedModelApp extends StatelessWidget {
  const ScopedModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainScopeModel>(
      model: MainScopeModel()..seed(), // ① 中央状态只在根创建一次
      child: MaterialApp(
        title: 'scoped_model 演示',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF00695C)),
        home: const NewsListPage(),
      ),
    );
  }
}

class NewsListPage extends StatelessWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资讯'),
        actions: [
          // ═══ 22.5 AppBar 过滤按钮（书 11.8）：实心=只看收藏 ═══
          ScopedModelDescendant<MainScopeModel>(
            builder: (context, _, model) => IconButton(
              tooltip: '只看收藏 / 全部',
              icon: Icon(model.showFavorites
                  ? Icons.favorite
                  : Icons.favorite_border),
              onPressed: model.toggleDisplayMode,
            ),
          ),
          ScopedModelDescendant<MainScopeModel>(
            builder: (context, _, model) => IconButton(
              tooltip: '登录 / 登出（UserPart 演示）',
              icon: Icon(model.userName == null ? Icons.person_outline : Icons.person),
              onPressed: () =>
                  model.userName == null ? model.login('书友') : model.logout(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddNewsDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      bottomNavigationBar: ScopedModelDescendant<MainScopeModel>(
        builder: (context, _, model) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('用户：${model.userName ?? '未登录'} · 共 ${model.totalCount} 条'),
        ),
      ),
      body: ScopedModelDescendant<MainScopeModel>(
        builder: (context, _, model) {
          final news = model.displayNews;
          if (news.isEmpty) {
            return const Center(child: Text('这里空空的：没有收藏，或没有资讯'));
          }
          return ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, i) => NewsCard(item: news[i]),
          );
        },
      ),
    );
  }
}

/// 单条资讯卡：书第 10 章的打磨件都在这——
/// CircleAvatar 头像、subtitle 分数、Dismissible 滑动删除（Key 是它的硬要求）。
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainScopeModel>(
      // notifyListeners 后只有这个 builder 重跑（精确重建，书 11.7）
      builder: (context, _, model) => Dismissible(
        key: ValueKey(item),
        background: Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete),
        ),
        onDismissed: (_) => model.deleteNews(item),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(item.score.toString())),
            title: Text(item.title),
            subtitle: Text('${item.score.toStringAsFixed(1)} 分'),
            trailing: IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => model.toggleFavorite(item),
            ),
          ),
        ),
      ),
    );
  }
}

class AddNewsDialog extends StatefulWidget {
  const AddNewsDialog({super.key});

  @override
  State<AddNewsDialog> createState() => _AddNewsDialogState();
}

class _AddNewsDialogState extends State<AddNewsDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加资讯'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '标题'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        // ═══ 对话框也在 ScopedModel 子树内：Descendant 照常取到模型 ═══
        ScopedModelDescendant<MainScopeModel>(
          builder: (context, _, model) => FilledButton(
            onPressed: () {
              final title = _controller.text.trim();
              if (title.isEmpty) return;
              model.addNews(NewsItem(title: title, score: 7.0));
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ),
      ],
    );
  }
}
