# 18 · 桌面专题：Windows 的一等公民

> 对应示例：examples/18_desktop/

## 18.1 解决什么问题

前面 17 章的组件在手机和桌面上都成立，但桌面用户有一套自己的**肌肉记忆**：顶部菜单栏、可见的滚动条、可选中的文本、键盘直达。本章补齐这些"桌面标配"，并把 Windows 的构建与发布讲清楚。

桌面与移动的差异清单（写桌面应用前过一遍）：

| 维度 | 桌面预期 |
|---|---|
| 窗口 | 用户随便拉伸 → 响应式是刚需（16 章） |
| 指针 | 鼠标：悬停态、右键、滚轮；命中区域可以更紧凑 |
| 键盘 | Tab 焦点流转、快捷键（shortcuts/actions） |
| 文本 | 期望可选中复制 |

## 18.2 MenuBar：顶部菜单栏

```dart
          // ═══ 18.1 MenuBar：桌面级菜单栏（顶部） ═══
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '新建'),
                    child: const Text('新建'),
                  ),
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '退出'),
                    child: const Text('退出'),
                  ),
                ],
                child: const Text('文件'),
              ),
            ],
          ),
```

Material 3 的桌面菜单三件套：`MenuBar`（栏）→ `SubmenuButton`（"文件"这类可展开项）→ `MenuItemButton`（真命令）。键盘可达（方向键/首字母）免费获得——这是选它而不是自造 Row+PopupMenu 的理由。惯例：菜单触发命令而不是直接干活（命令再走快捷键系统）。

## 18.3 SelectionArea 与 Scrollbar：两条桌面铁律

```dart
          Expanded(
            // ═══ 18.3 Scrollbar + 滚轮：桌面用户 expect 可见滚动条 ═══
            child: Scrollbar(
              child: ListView.builder(
                itemCount: 40,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text('条目 $i'),
                ),
              ),
            ),
          ),
          // ═══ 18.2 SelectionArea：让文本可选中复制（桌面标配） ═══
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('菜单选择：$_selected（这段文字可以选中复制）'),
            ),
          ),
```

- **`SelectionArea`**：包住的区域里 Text 变为可选可复制（默认不可选——第 02 章的坑在这是正解）。整页包或局部包都行。
- **`Scrollbar`**：桌面滚动区应有可见滚动条；与 ScrollController 联动（16 章 ListView 处传 `controller:` 同款），滚轮支持原生自带。

## 18.4 构建与发布

```bash
flutter build windows --debug     # 开发/自测（带热重载符号，体积大）
flutter build windows --release   # 发布（AOT，体积小启动快）
```

- 产物在 `build\windows\x64\runner\Release\`，exe + dll 整目录拷走才能跑（缺 dll 是经典翻车）。
- 版本号在 pubspec 的 `version:`；图标与窗口标题在 `windows/runner/`（main.cpp 的 `ShowWindow` 控制初始尺寸，Runner.rc 控图标）——动 C++ 侧后要完全重跑。
- 正式分发可打 msix（`msix` 生态包）或做安装器；小工具直接 zip 整目录也常见。
- debug 与 release **行为有差**：断言只在 debug 生效、性能差距明显——验收以 release 为准（与 [Dart 教程·第 01 章](../dart/docs/01-overview.md) 的 JIT/AOT 对应）。

## 18.5 鼠标进阶一瞥

`MouseRegion`（悬停态）、`Listener`（原始指针事件）、`GestureDetector.onSecondaryTap`（右键）、`Shortcuts`/`Actions`/`MenuShortcut`（快捷键体系）——用到时按关键词查官方文档即可，机制都是第 07 章手势层的延伸。

## 坑位清单

- **exe 单文件拷走跑不起来**：Flutter Windows 产物是目录（exe+dll+data）——整目录打包。
- **改了 windows/runner 没生效**：原生侧改动不走热重载/热重启，完全停掉重跑。
- **滚动区没滚动条**：桌面观感差评——Scrollbar 包上。
- **触屏习惯带上桌面**：间距/字体/命中区域过小——桌面 `dense:` 列表、紧凑模式按需开。
