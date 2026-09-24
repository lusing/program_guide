# 09-scratchpad（编辑器）

控件篇第二功能工程：多文档文本编辑器——页签、加粗、查找、未保存确认、落盘回读全是真功能。

## 承载章节

| 章 | 控件 | 在本工程的真实职责 |
|---|---|---|
| 9 | RichEditBox | 每页签一个编辑器（脏标记/取值/选区格式化） |
| 21 | TabView/Expander | 多文档 + 查找折叠板 |
| 23 | MenuBar/CommandBar | 三层命令入口共用处理器 |
| 24 | ContentDialog | 关闭未保存确认（Save/Discard/Cancel） |

## 架构

```text
MainWindow            菜单栏 + TabView + FindPane(Expander) + CommandBar + 状态行
├── AddTab()          代码造 TabViewItem（Content=RichEditBox）+ TabEntry{名/脏}
├── OnTabCloseRequested  协程：脏页签 → ContentDialog → Save/Discard/Cancel
└── OnSave/OnBold/OnFindNext  三入口共用的命令实现
DocStore              UTF-8 落盘 %LOCALAPPDATA%\ScratchPad（写后回读验证）
```

## 关键实现位

- **写后回读**：保存后 `Load` 回来，状态行报 "verified on disk (N chars)"——把"保存了但文件是空的"当场暴露
- **脏标记**：`TextChanged` 只在 false→true 边沿做事；lambda 按值捕获 TabViewItem（引用计数对象）
- **GetText 两参**：`(TextGetOptions, hstring&)`，且 TextGetOptions/FormatEffect 在 **Microsoft**.UI.Text 命名空间
- **全选**：`SetRange(0, INT32_MAX)`（投影无 DocumentRange）
- **加速器**：Ctrl+S/N/F/B 挂根 Grid，与菜单/命令栏同处理器；MenuFlyoutItem 的加速器槽是**复数** KeyboardAccelerators

## 冒烟

```powershell
pwsh tools\ui-smoke\smoke-scratchpad.ps1
```

四流程：save（回读铁证）/ bold（Ctrl+A+B+S 全链）/ find（"3 match(es)"）/ close（ContentDialog 实拍）。证据在 `.smoke/09-scratchpad/<流程>/tap-N.png`。
