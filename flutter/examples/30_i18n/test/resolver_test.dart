// ═══ 30.2 匹配算法单测 ═══
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_app/main.dart';

void main() {
  const supported = [Locale('zh'), Locale('en')];

  test('完全匹配优先于语言码匹配', () {
    final r = resolveTeaching(
      const [Locale('zh', 'SG'), Locale('en', 'US')],
      supported,
    );
    // zh_SG 没有 countryCode 级匹配，但语言码 zh 命中 → zh。
    expect(r, const Locale('zh'));
  });

  test('系统列表逐个尝试，第一个命中的语言决定结果', () {
    final r = resolveTeaching(
      const [Locale('ja'), Locale('en', 'US')],
      supported,
    );
    // 日文不支持 → 退到列表第二项英文。
    expect(r, const Locale('en'));
  });

  test('全都不支持返回 null（交回框架默认）', () {
    expect(resolveTeaching(const [Locale('ko')], supported), isNull);
  });

  test('空列表/ null 返回 null', () {
    expect(resolveTeaching(const [], supported), isNull);
    expect(resolveTeaching(null, supported), isNull);
  });
}
