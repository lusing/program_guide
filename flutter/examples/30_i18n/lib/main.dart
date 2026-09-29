// ═══ 30.1/30.4/30.6 入口：识别系统语言 + 全家桶 + 运行时切换与持久化 ═══

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

Future<void> main() async {
  // DateFormat('yMMMMd', 'zh') 需要 locale 符号表先初始化，
  // 否则运行时抛 FormatException——放 main 里做一次。
  await initializeDateFormatting('zh', null);
  await initializeDateFormatting('en', null);

  // 23 章同款：真实存储在入口 await，让首帧就有语言偏好。
  final prefs = await SharedPreferences.getInstance();
  runApp(I18nApp(prefs: prefs));
}

class I18nApp extends StatefulWidget {
  const I18nApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<I18nApp> createState() => _I18nAppState();
}

/// 教学版匹配算法（框架的 basicLocaleListResolution 简化版）：
/// 逐个系统语言 → 先找完全匹配（zh_CN==zh_CN）→ 再退到语言码匹配。
/// 提为顶层纯函数，widget 测试可直接单测（见 test/resolver_test.dart）。
Locale? resolveTeaching(List<Locale>? system, Iterable<Locale> supported) {
  if (system == null || system.isEmpty) return null;
  for (final s in system) {
    for (final sup in supported) {
      if (s.languageCode == sup.languageCode &&
          s.countryCode == sup.countryCode) {
        return sup;
      }
    }
  }
  for (final s in system) {
    for (final sup in supported) {
      if (s.languageCode == sup.languageCode) return sup;
    }
  }
  return null;
}

class _I18nAppState extends State<I18nApp> {
  /// null = 跟随系统（默认）；非 null = 用户手动锁定的语言。
  Locale? _override;

  static const _prefKey = 'selected_language';

  @override
  void initState() {
    super.initState();
    final saved = widget.prefs.getString(_prefKey);
    if (saved != null &&
        AppLocalizations.supportedLocales
            .any((l) => l.languageCode == saved)) {
      _override = Locale(saved);
    }
  }

  void _setOverride(String? code) {
    setState(() => _override = code == null ? null : Locale(code));
    // null 也写：用户明确选择"跟随系统"，下次启动不应被旧值覆盖。
    code == null
        ? widget.prefs.remove(_prefKey)
        : widget.prefs.setString(_prefKey, code);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'i18n Demo',

      // ═══ 30.4 全家桶 ═══
      // 自家 delegate + Material/Widgets/Cupertino 三件套的 Global 翻译：
      // 它们让框架内置文案（日期选择器、tooltip、剪切板菜单……）跟随语言。
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // ═══ 30.6 运行时切换 ═══
      // locale 为 null 时框架走系统语言解析链；非 null 直接锁定。
      locale: _override,

      // ═══ 30.2 识别系统首选语言（书 9.1）═══
      // locales：系统语言偏好列表（新 Android 是列表，老设备是单值）。
      // 返回值决定 App 实际使用的 locale；不实现则用框架默认匹配算法。
      localeListResolutionCallback: (locales, supported) {
        final resolved = resolveTeaching(locales, supported);
        debugPrint('系统首选语言: $locales → 匹配: $resolved');
        return resolved;
      },

      onGenerateTitle: (context) => AppLocalizations.of(context).title,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: RootLocaleBinding(
        // 字段名不能叫 override：会在类作用域遮蔽 @override 注解名
        // （analyzer 报 "Undefined name 'override' used as an annotation"）。
        languageCode: _override?.languageCode,
        setOverride: _setOverride,
        child: const LanguagePlayground(),
      ),
    );
  }
}

/// 演示页 → 宿主（I18nApp）的窄接口，避免把整份 prefs 泄进 UI 层。
class RootLocaleBinding extends InheritedWidget {
  const RootLocaleBinding({
    super.key,
    required this.languageCode,
    required this.setOverride,
    required super.child,
  });

  final String? languageCode;
  final void Function(String?) setOverride;

  static RootLocaleBinding? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootLocaleBinding>();

  @override
  bool updateShouldNotify(RootLocaleBinding old) =>
      old.languageCode != languageCode;
}

class LanguagePlayground extends StatefulWidget {
  const LanguagePlayground({super.key});

  @override
  State<LanguagePlayground> createState() => _LanguagePlaygroundState();
}

class _LanguagePlaygroundState extends State<LanguagePlayground> {
  int _count = 0;
  String _matchReport = '';

  void _changeLanguage(String? code) {
    // 切换后把匹配结果落到 UI（书 9.1 的控制台输出改为界面展示）。
    final l10n = AppLocalizations.of(context);
    final locales = View.of(context).platformDispatcher.locales;
    final system = locales.isEmpty ? '?' : locales.first.toString();
    setState(() {
      _matchReport = l10n.matchReport(
        system,
        (code ?? system.split('_').first) == 'en' ? 'en' : 'zh',
      );
    });
    RootLocaleBinding.of(context)?.setOverride(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // MaterialLocalizations：flutter_localizations 提供的内置文案，
    // 这里借 okButtonLabel 验证 Global 翻译确实生效（en='OK' / zh='确定'）。
    final material = MaterialLocalizations.of(context);
    final override = RootLocaleBinding.of(context)?.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 30.6 语言选择：跟随系统 / 中文 / English ═══
          Text(l10n.pickLanguage,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'sys', label: Text(l10n.systemOption)),
              const ButtonSegment(value: 'zh', label: Text('中文')),
              const ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {override ?? 'sys'},
            onSelectionChanged: (sel) => _changeLanguage(
                sel.first == 'sys' ? null : sel.first),
          ),
          const Divider(height: 32),

          // ═══ 30.5 自家文案：普通 getter / 复数 / 日期 / 数字 ═══
          Text(l10n.tapCount(_count),
              style: Theme.of(context).textTheme.headlineSmall),
          Text(l10n.today(DateTime.now())),
          Text(l10n.bigNumber(1234567)),
          if (_matchReport.isNotEmpty) Text(_matchReport),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(() => _count++),
            icon: const Icon(Icons.add),
            label: Text(l10n.increment),
          ),

          // 框架内置翻译的证据：按钮默认文案也随语言变。
          OutlinedButton(
            onPressed: () {},
            child: Text('built-in: ${material.okButtonLabel}'),
          ),
        ],
      ),
    );
  }
}
