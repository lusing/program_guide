// ═══ 30.2 手写 Localizations + Delegate ═══
// 书 9.2 的教学核心：一个类装字符串，一个 Delegate 负责装载（书的
// LanguagezhCnLocalizations 用 isZh 布尔 + SynchronousFuture，结构与本
// 文件同源）。现代化点：isZh 布尔换成按 languageCode 分发的 getter，
// 复数/日期/数字交给 intl 而不是手写三目。

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// 应用自有文案的载体：所有 getter 按 [locale] 分发。
///
/// 为什么不用 Map：getter 里可以放任意逻辑（复数、拼接、格式化），
/// Map 只能存静态串——这是手写方案比 arb 生成物灵活的地方。
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  bool get _zh => locale.languageCode == 'zh';

  /// 取用方：`AppLocalizations.of(context).title`
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  /// 注册进 MaterialApp.localizationsDelegates 的委托。
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppDelegate();

  /// MaterialApp.supportedLocales 必须与这里一致——isSupported 是守门员。
  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  String get title => _zh ? '国际化演示' : 'i18n Demo';

  String get pickLanguage => _zh ? '语言' : 'Language';

  String get systemOption => _zh ? '跟随系统' : 'System';

  String get increment => _zh ? '点我加一' : 'Increment';

  /// 复数：中文没有复数形态，恒为 other；英文按 1/other 分叉。
  /// Intl.plural 第一个参数必须传 locale，否则按英文规则渲染。
  String tapCount(int n) => Intl.plural(
        n,
        locale: locale.toString(),
        other: _zh ? '你点了 $n 次' : 'You tapped $n times',
        one: 'You tapped once',
      );

  /// 日期按 locale 格式化（初始化见 main.dart 的 initializeDateFormatting）。
  String today(DateTime now) => _zh
      ? '今天是 ${DateFormat.yMMMMd('zh').format(now)}'
      : 'Today is ${DateFormat.yMMMMd('en').format(now)}';

  /// 数字分组：1,234,567 与 1234567 的区别。
  String bigNumber(int n) => _zh
      ? '累计 ${NumberFormat.decimalPattern('zh').format(n)} 次'
      : '${NumberFormat.decimalPattern('en').format(n)} taps in total';

  /// 匹配报告：localeListResolutionCallback 的决策结果展示（书 9.1）。
  String matchReport(String system, String matched) => _zh
      ? '系统首选语言 $system → 匹配到 $matched'
      : 'System preference $system → matched $matched';
}

class _AppDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  /// Locale 变化时被框架调用，负责装载对应语言的资源。
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  /// build 重跑不等于要重载语言资源——false 是常规答案（书 9.2 原话）。
  @override
  bool shouldReload(_AppDelegate old) => false;
}
