// ═══ 30 章 widget 层：双语料 / 复数 / 内置翻译 / 切换 / 持久化恢复 ═══
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_app/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:i18n_app/main.dart';

Future<void> pumpApp(WidgetTester tester, {SharedPreferences? prefs}) async {
  await tester.pumpWidget(I18nApp(prefs: prefs ?? await _fakePrefs()));
  // delegate 的 load 是 SynchronousFuture，一次 pump 就绪。
}

Future<SharedPreferences> _fakePrefs() async {
  SharedPreferences.setMockInitialValues(const {});
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('锁定中文：自家文案与内置按钮翻译都跟随', (tester) async {
    await pumpApp(tester);
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    // 测试环境系统语言默认 en_US → 跟随系统落在英文。
    expect(find.text('i18n Demo'), findsOneWidget);
    expect(find.text('You tapped 0 times'), findsOneWidget);
    // GlobalMaterialLocalizations 的内置文案（英文）。
    expect(find.text('built-in: OK'), findsOneWidget);

    // 切到中文（SegmentedButton 的中文段）。
    await tester.tap(find.text('中文'));
    await tester.pump();
    expect(find.text('国际化演示'), findsOneWidget);
    expect(find.text('你点了 0 次'), findsOneWidget);
    expect(find.text('built-in: 确定'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('复数：英文 once/times 分叉，中文恒为 other', (tester) async {
    await pumpApp(tester);
    expect(find.text('You tapped 0 times'), findsOneWidget);

    // 1 次 → one 分支。
    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('You tapped once'), findsOneWidget);

    // 2 次 → other 分支。
    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('You tapped 2 times'), findsOneWidget);

    // 中文无复数形态：0/1/2 同一文案。
    await tester.tap(find.text('中文'));
    await tester.pump();
    expect(find.text('你点了 2 次'), findsOneWidget);
  });

  testWidgets('数字分组随 locale：1,234,567', (tester) async {
    await pumpApp(tester);
    expect(find.text('1,234,567 taps in total'), findsOneWidget);
    await tester.tap(find.text('中文'));
    await tester.pump();
    expect(find.text('累计 1,234,567 次'), findsOneWidget);
  });

  testWidgets('选择持久化：重启后恢复英文锁定', (tester) async {
    SharedPreferences.setMockInitialValues(const {'selected_language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(tester, prefs: prefs);
    // 覆盖锁优先于测试环境的默认解析。
    expect(find.text('i18n Demo'), findsOneWidget);
  });

  testWidgets('isSupported 守门：不支持的语言由框架回落到首个支持项', (tester) async {
    var loaded = false;
    final probe = _ProbeDelegate(() => loaded = true);
    await tester.pumpWidget(MaterialApp(
      // MaterialApp 自己也要 Material 翻译才画得出 Scaffold——全家桶配齐。
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        probe,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      locale: const Locale('ja'),
      home: const Scaffold(body: SizedBox()),
    ));
    await tester.pump();
    // 框架默认算法在无匹配时回落 supported.first（zh），delegate 仍会 load。
    expect(loaded, isTrue);
  });

  testWidgets('AppLocalizations.of 在无 Localizations 祖先时炸空断言', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    // of 里的 ! 在 null 上抛的是 TypeError（_TypeError），不是 FlutterError。
    expect(
      () => AppLocalizations.of(tester.element(find.byType(Scaffold))),
      throwsA(isA<TypeError>()),
    );
  });
}

class _ProbeDelegate extends LocalizationsDelegate<String> {
  _ProbeDelegate(this.onLoad);
  final void Function() onLoad;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<String> load(Locale locale) async {
    onLoad();
    return locale.toString();
  }

  @override
  bool shouldReload(_ProbeDelegate old) => false;
}
