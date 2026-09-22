# 32 · 工具栏、图像列表与系统托盘

主界面三大件：工具栏（高频命令一击达）、状态栏（状态回显）、托盘图标
（后台常驻）。24 章教过"Action 统一命令"——本章补上它们的**宿主控件**本身。

## 1. TImageList：图标的中央仓库

工具栏/菜单/树/页签的图标都从同一个 TImageList 按 `ImageIndex` 取——
换一套主题改一个列表就行：

```pascal
Imgs := TImageList.Create(Self);
Imgs.Width := 16;  Imgs.Height := 16;
Imgs.Add(MakeIconBmp(clGreen), nil);   // 代码画图标入列（不依赖资源文件）
Imgs.Add(MakeIconBmp(clBlue), nil);
```

32 工程全程代码画图标（16×16 色块）——教程的可复现路线不引外部资源；
真实项目用 .res/.png 装载。图标不是黑盒：`GetBitmap(Index, Bmp)` 取回后
**像素可验**（selftest 断言中心点颜色）。

## 2. TToolBar 与 TToolButton

```pascal
Bar.Images := Imgs;               // 图标来源
Bar.ShowCaptions := True;         // 显示文字（占宽换直观——取舍）
Bar.List := True;                 // 图标+文字横排

B := TToolButton.Create(Bar);     // ★ Parent 是工具栏（容器收养）
B.Parent := Bar;
B.Style := tbsButton;             // 普通按钮
B.ImageIndex := 0;
B.OnClick := @BtnClick;
```

TToolButtonStyle 全家族：

| Style | 形态 |
|---|---|
| `tbsButton` | 普通按钮 |
| `tbsCheck` | 勾选型（`Down` 保持状态——程序可设可读） |
| `tbsDropDown` | 带下拉箭头（配 `DropdownMenu` 弹菜单） |
| `tbsSeparator` | 占位空隙 |
| `tbsDivider` | 带竖线的空隙 |

多个按钮一个处理器：`Tag` 当路由号（`BtnClick` 里 case Tag）——32 工程
的工具栏与托盘菜单共用同一个分发器。

**坑（实测）**：`TMenuItem.Add` 与 `TStatusBar.Panels.Add` 长得像、语义
不同——Panels.Add **是工厂**（建了返回），TMenuItem.Add **收已有项**
（先 `TMenuItem.Create` 再 Add）。另外 `with TMenuItem.Create(...)` 块里
写 `Items.Add(Self)` 会把**方法的 Self**（窗体）传进去——`with` 遮蔽，
老老实实用变量。

## 3. TStatusBar：多窗格与单行两形态

```pascal
with Status.Panels.Add do Width := 220;   // 多窗格（工厂式 Add）
with Status.Panels.Add do Width := 200;
Status.Panels[0].Text := '就绪';

Status.SimplePanel := True;               // 切单行
Status.SimpleText := '一条消息';
```

多窗格是默认形态（每格独立 Width/Text/Alignment/Style）；SimplePanel 一开
全栏变一条。40 章记事本+ 的"行列 | 字数 | 编码"三段状态就是三窗格。
自绘进度之类的高级窗格走 `OnDrawPanel`（27 章画布的活）。

## 4. TTrayIcon：后台常驻的骨架

```pascal
Tray := TTrayIcon.Create(Self);
Tray.Icon.Assign(MakeIconBmp(clMaroon));  // 图标（代码画的 16×16）
Tray.Hint := '32 示例在托盘';              // 悬停提示
Tray.PopUpMenu := Popup;                   // 右键菜单
Tray.BalloonHint := '通知内容';            // 气泡
Tray.BalloonFlags := bfInfo;               // bfNone/bfInfo/bfWarning/bfError
Tray.BalloonTimeout := 3000;               // 毫秒
Tray.Visible := True;                      // 上托盘
```

气泡：`Tray.ShowBalloonHint`（**需要 Visible=True**）。动画图标：
`Animate := True` + `AnimateInterval`（Icon 帧序列）。

托盘常驻型程序的完整闭环（与 29 章呼应）：

```pascal
// 关闭按钮 → 藏进托盘而不是退出
procedure TMainForm.FormClose(...);
begin
  CloseAction := caHide;      // 或 caMinimize——窗体留着
end;
// 托盘菜单"退出" → 真退
Tray.Visible := False; Application.Terminate;
```

selftest 纪律：托盘是**系统级副作用**——测完 `Visible := False`（finally
里兜底），不留残图标；气泡不真弹。

## 5. 一图流：命令的四个宿主

```text
TActionList（24 章：命令本体）
   ├── TMainMenu（菜单栏）
   ├── TToolBar（本章：一击达）
   ├── TPopUpMenu（右键/托盘菜单）
   └── 快捷键（ShortCut）
```

24 章的 Action 依然是对的做法；本章的控件是它的宿主。新项目：先 Action
后宿主，一处 Enabled/Checked 全宿主同步。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 32_toolbar_tray
```

selftest 覆盖：ImageList Count 与像素回读、按钮数/Style/ImageIndex/Down、
Tag 路由、Panels 多窗格与 SimplePanel 双形态、托盘属性与开关（测毕即收）。

## 7. 坑位清单（实测）

1. `TMenuItem.Add` 收**已有项**（先 Create 再 Add）；`Panels.Add` 是工厂
   ——同名不同义，IDE 里还会自动补全错的那种。
2. `with Obj do` 块里 `Self` 指**方法 Self**（窗体），不是 with 对象——
   Add(Self) 编译不过算运气好，过了才可怕。
3. ToolButton 的 Parent 是 TToolBar（不是窗体）；创建序=显示序。
4. ShowBalloonHint 前提是 TrayIcon.Visible=True。
5. 托盘图标/菜单是系统级副作用——selftest 必须 finally 收场。
6. ImageList 尺寸（Width/Height）要在 Add 之前定（入列后改=重排）。

---
上一章：[31 焦点、键盘与输入验证](31-focus-validation.md) ｜ 下一章：[33 剪贴板与拖放](33-clipboard-dnd.md) ｜ 返回：[README](../README.md)
