# 21 · 调试与 DevTools：让代码开口说话

> 对应示例：examples/21_debugging/

## 21.1 解决什么问题

前 20 章的示例代码都是"写对的样子"，真实开发一半时间在处理**写错的样子**。错误分三层，每层有自己的武器：

| 层 | 特征 | 武器 |
|---|---|---|
| 语法错误 | 代码编译不过，IDE 标红 | analyzer、诊断码、`dart fix` |
| 运行时错误 | 跑起来才炸，红屏/控制台异常 | 读错误信息、错误面板 |
| 逻辑错误 | **不报错但行为不对** | print/debugPrint、断点、DevTools |

本章按这三层过一遍武器库，最后补齐 `flutter run` 的交互键位与多设备运行。示例工程是一个**故意埋了雷的演练场**：每类错误都有触发按钮，修好前的行为被 widget 测试锁住——"能被测试复现的 bug 才算被理解"。

## 21.2 语法错误：analyzer 先行

```dart
// ═══ 21.2 注释掉 import 后的三连锁诊断 ═══
// import 'package:flutter/material.dart';

class NewsManager extends StatefulWidget {   // ← extends_non_class
                                              // ← undefined_class: StatefulWidget
  State<NewsManager> createState() => _NewsManagerState();
}
```

漏一个 import 能炸出三个诊断：`extends_non_class`（StatefulWidget 不认识了）、`undefined_class`、连带 `undefined_identifier`（NewsManager 的使用者全报"没定义"）。**读诊断码而不是只看红波浪线**——每条诊断在 dart.dev 上都有专页，讲清成因与修法。IDE 把鼠标悬停在红线上就是同款内容（第 02 章用过）。

命令行侧两件套：

```bash
flutter analyze            # 全量静态检查（本教程标准：零告警）
dart fix --dry-run         # 列出可自动修复的诊断
dart fix --apply           # 一键修掉（废弃 API 迁移、缺 const 等）
```

`dart fix` 修的是**有明确改写公式**的诊断（`deprecated_member_use` 一类）；逻辑性的诊断（类型不符、未定义标识符）它不碰，也读一下它列出的 diff 再应用。

## 21.3 运行时错误：读错误的艺术

运行时错误的第一反应不是改代码，是**把错误信息读完**。Flutter 的错误信息是出了名的"话痨"——绝大多数直接给解法：

```text
A RenderFlex overflowed by 174 pixels on the bottom.
The relevant error-causing widget was:
  ...Column...
See also: https://flutter.dev/to/row_overflow
```

溢出错误（第 05 章 Row/Column 塞不下）会告诉你**超了多少像素、是谁超的、文档链接**——解法（Expanded 分配、ListView 滚动、Flexible 收缩）在 05/12 章都练过。再如给 `const` 列表 `add`：

```dart
const list = <int>[1, 2];
list.add(3);
// ═══ 21.3 运行时错误：编译期无感，运行时立刻炸 ═══
// Unsupported operation: Cannot add to an unmodifiable list
```

这条在 19 章测试里也撞过（fake 存储返回 const 原表）。要点：**从错误信息底部往上读**——Flutter 习惯把最相关的描述放最后段；widget 面板/屏幕上的红黄错误屏（debug 版专属）点开就有完整栈。

## 21.4 逻辑错误：print → debugPrint → 断点

最阴的一类：忘调 `setState()`（第 08 章），界面纹丝不动、零报错。排查阶梯：

```dart
void _addBroken(int n) {
  _brokenCount += n;   // ═══ 21.4 逻辑错误：改了数据没通知，界面不刷新 ═══
}
void _addFixed(int n) {
  setState(() => _fixedCount += n);   // 正解：改动包进 setState
}
```

1. **先读代码**：按钮 onPressed 连的对不对、参数传没传、方法里改的是不是界面读的那个字段；
2. **print 验证**：`print(_brokenCount)`——控制台变了、界面没变 = 忘 setState 实锤。长日志用 `debugPrint`（节流分片，避免移动端日志被截断）；
3. **断点精确制导**：debug 方式启动（`flutter run` 默认就是），在行号左侧点红点，触发后 IDE 停在该行——**单步进入/跳过**（Step Into/Over）、悬停看值、Watch 面板盯变量、调用栈看"谁把我叫来的"。VS Code 装 Dart 插件后全套免费。

print 治标（要改代码），断点治本（不改代码、随时增删观察点）。习惯：**短路径先 print，跨方法的数据流上断点**。

## 21.5 flutter run 键位与多设备

`flutter run` 启动后终端进入交互模式（`h` 随时列全部），高频键位（3.47 实测自 flutter_tools 源码）：

| 键 | 作用 | 键 | 作用 |
|---|---|---|---|
| `r` / `R` | 热重载 / 热重启 | `q` / `d` | 退出 / 断连（app 留着） |
| `p` | 构造线（debugPaintSize） | `P` | 性能 overlay |
| `i` | Widget Inspector | `o` | 模拟 Android/iOS 平台 |
| `b` | 深浅色切换 | `v` | **打开 DevTools** |
| `w` / `t` / `L` | dump widget/渲染/图层树 | `s` | 截图到 flutter.png |

多设备：`flutter devices` 列全部（Windows 桌面、Android 模拟器、USB 真机……），`flutter run -d <id>` 指定目标。Android 真机要开"开发者选项 → USB 调试"；iOS 真机/模拟器需要 Mac + Xcode 签名——Windows 主机上把 Windows 当主要目标即可（第 18 章）。

## 21.6 DevTools：Inspector 是主战场

`v` 键（或 IDE 里的调试图标）打开 **Flutter DevTools**——浏览器形态的开发者工具箱，`flutter run` 时自动挂到你的会话。当年这叫 Observatory（2020 书里还是它），如今整套被 DevTools 取代：

- **Widget Inspector**：点屏幕选 widget → 高亮它在树上的位置、约束、尺寸——"这玩意为什么在这"类问题的终点站。配合 **Layout Explorer** 直接拖 flex/alignment 参数实时看效果；
- **Performance / CPU**：帧时间线、火焰图（第 25 章性能专题主场）；
- **Memory**：内存曲线、对象快照（查泄漏）；
- **Network**：http 请求时间线（第 13 章的接口调试）。

Inspector 还有一条隐藏价值：**慢动画按钮**（Slow Animations）把动画放慢 5 倍，调 15 章那种交互动画时极好用。

## 21.7 视觉调试开关

一组 debug 全局变量，给 UI 开"透视"：

```dart
import 'package:flutter/rendering.dart';

// ═══ 21.7 视觉调试开关（改完必须热重启 R，不是热重载） ═══
debugPaintSizeEnabled = true;        // 所有盒子的边界+内边距线
debugPaintBaselinesEnabled = true;   // 文字基线（黄/绿双线）
debugPaintPointersEnabled = true;    // 点按命中区域高亮
MaterialApp(debugShowMaterialGrid: true);  // 栅格网格（Material 布局对位）
```

用途对号入座：怀疑两个元素没对齐 → baselines；怀疑点按落在父容器上 → pointers；对 Material 栅格 → grid。示例工程把四个开关都做进界面，同一屏上演对照：前三个是**启动期读取的全局量，拨完须热重启 `R`** 才生效（新手最常踩的"开关失灵"）；`debugShowMaterialGrid` 是 `MaterialApp` 的构造参数，回调改根组件状态、重建即生效。

## 坑位清单

- **错误信息只扫一眼就改代码**：底部往往写着解法与文档链接——先读完。
- **逻辑错误靠猜**：print/断点二选一，先证明"数据到底变没变"，再谈界面。
- **debug 开关拨了没反应**：热重载不重读全局 debug 变量——热重启 `R`。
- **release 包里找红屏**：错误屏/断言都是 debug 专属，release 只有无声失败——验收以 release 行为为准（18 章）。
- **移动端日志被截断**：长文本用 `debugPrint` 不用 `print`（自动分片）。
