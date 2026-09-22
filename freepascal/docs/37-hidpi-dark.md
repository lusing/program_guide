# 37 · 高 DPI 深入与暗色主题

23 章埋的坑来兑现：DPI 不只是"字大了"——它是一套坐标系；暗色不只是
"黑底白字"——标题栏归系统、客户区归你。两件事本章一次讲透。

## 1. DPI 的坐标系：设计基准 96

Windows 的缩放世界以 **96 DPI = 100%** 为基准：

| 系统缩放 | PixelsPerInch | 你写的 100px 控件实际显示 |
|---|---|---|
| 100% | 96 | 100px |
| 125% | 120 | 125px |
| 150% | 144 | 144px |

LCL 程序默认**不声明 DPI 感知**（未感知进程）——系统对整个窗口位图拉伸：
不糊才怪。修复的层次：

1. **DPI aware（系统级）**：exe 清单声明 PerMonitorAware——LCL 4.x 起在
   .lpi 里 Project → Application → `DPI Awareness` 选项（存 manifest 设定）；
   声明后 LCL 按当前 DPI 自动缩放窗体（`Scaled=True` 时）。
2. **代码内手动**：`ScaleBy(乘, 除)` 整树缩放；`AutoAdjustLayout` 布局
   重算。
3. **写死像素的都换算**：`X := A * PixelsPerInch div 96`——高 DPI 代码
   审查的头号 grep 项。

## 2. ScaleBy：比例缩放的数学与代价

```pascal
ScaleBy(3, 2);     // 整棵控件树 ×1.5（字体、坐标、尺寸全跟）
ScaleBy(2, 3);     // ×2/3 放回去
```

实测（selftest.log 的证据）：本机 96 DPI 下按钮 110×32 → ScaleBy(3,2) →
**165×48**——精确的 3:2（取整四舍五入，`(W*3+1) div 2`）。

**代价**：往返不闭合——110×1.5=165，165×2/3=110 ✓ 整数恰好闭合；但 111×1.5
=166.5→167，167×2/3≈111.3→111 ✓……不保证的：37×1.5=55.5→56，56×2/3≈
37.3→37 ✓。缩放链上的**奇数尺寸在多轮往返后可能漂移 1px**——布局别依赖
"缩放后还差 1px"的精确值；需要精确恢复就存原值（35 章组件流）再整树重装。

## 3. 暗色的分界线：标题栏归 DWM，客户区归你

Windows 应用暗色化是两件事：

**标题栏/边框**——系统画的，走 DWM 属性（LCL 没封装，自己声明）：

```pascal
{$IFDEF MSWINDOWS}                        // ★ 整条包起来——原因见下
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD;
  pvAttribute: Pointer; cbAttribute: DWORD): LongInt;
  stdcall; external 'dwmapi';

const
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19;   // Win10 1809 前期
  DWMWA_USE_IMMERSIVE_DARK_MODE     = 20;   // Win10 1809+/Win11
{$ENDIF}

function THiDpiForm.ApplyDarkTitleBar(OnOff: Boolean): LongInt;
{$IFDEF MSWINDOWS}
var Flag: Integer;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Flag := IfThen(OnOff, 1, 0);
  Result := DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE,
    @Flag, SizeOf(Flag));
  if Result < 0 then                        // 新号失败退回旧号
    Result := DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD,
      @Flag, SizeOf(Flag));
{$ELSE}
  Result := 0;                              // cocoa：没有等价 API（见下）
{$ENDIF}
end;
```

⚠️ **`external 'dwmapi'` 必须包平台条件**（双平台回归实测）：Unix 上 `external`
的库名会在链接期展开成 `-ldwmapi`，而 cocoa 根本没有这个库——不包就死在
`ld: symbol(s) not found for architecture x86_64`。注意这是**构建期**失败，不是
运行期：示例连编都编不出来，跟"老系统不支持暗色属性"完全是两类问题。

**macOS 上这一半压根不存在**：标题栏外观由系统统一决定（NSAppearance / 系统设置里
的"外观"），没有"按窗口把标题栏改暗"的等价 API，LCL 也没抽这一层。cocoa 的示例里
`ApplyDarkTitleBar` 直接返回 0（保持调用方语义一致，selftest 日志会先打一行
`标题栏暗色 API=none(cocoa 无等价 API)`，免得 NoOp 的 0 被误读成"真调到了 DWM"）。
—于是 cocoa 上**暗色主题只剩"控件配色自管"那一半**，这恰好印证本节主旨：
LCL 没有全局主题，客户区永远归你。

实测：Windows 11 本机 HRESULT=0（成功）——标题栏立刻暗。返回负值=
系统不支持（老 Win10）或窗体未显示，代码要容错。

**客户区（控件配色）**——LCL **没有全局暗色主题**，自己管一套调色板：

```pascal
Color       := TColor($202020);   // 窗体底
Card.Color  := TColor($2D2D30);   // 卡片底
Font.Color  := clWhite;           // 字
```

工程做法：集中一个 `ApplyDarkMode(Form, OnOff)` 遍历控件树配色（或给每个
自定义控件留 35 章流可存的 `DarkMode` published 属性）——散落各处的
`Color :=` 是暗色功能的死穴。

## 4. 深浅模式联动（产品级姿势）

监听系统主题变化：注册窗口消息 `WM_SETTINGCHANGE`（30 章 WndProc 拦截，
lParam 指 `ImmersiveColorSet` 时重查注册表
`HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme`）
——系统切暗你也切。完整实现超出本章（注册表读取在 11 章工具箱），骨架：
WndProc 拦消息 → 读注册表 → ApplyDarkControls + ApplyDarkTitleBar。

## 5. 一张自查表

| 症状 | 病根 | 药 |
|---|---|---|
| 窗口整体发糊 | 未声明 DPI 感知 | .lpi 清单声明（§1） |
| 字大控件小（或反之） | 字体缩了布局没缩 | Scaled=True / AutoAdjustLayout |
| 换显示器后错位 | Per-Monitor 未处理 | DPI 改变消息时重算（进阶） |
| 标题栏白得刺眼 | 只改了客户区 | DWMWA_USE_IMMERSIVE_DARK_MODE（win32 专有） |
| 部件暗部分亮 | 配色散落 | 集中调色板函数 |

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 37_hidpi_dark
```

selftest 覆盖：PixelsPerInch 事实记录（本机 96）、ScaleBy 3:2 精确数学、
暗色调色板往返（改暗/复原）、标题栏暗色调用记录（先打一行"本平台走哪条 API"，
再记 HRESULT——win32 是真 DWM 返回值，cocoa 是 NoOp 的 0）、Scaled 默认值。

## 7. 坑位清单（实测）

1. **ScaleBy 往返有 1px 漂移风险**——整数取整的代价；精确恢复存原值重装。
2. DWM 暗色属性有两个号（19/20）——先试 20 退 19，返回值要检查。
3. LCL 没有全局暗色主题——客户区配色自管，集中成函数别散写。
4. 写死像素的代码在高 DPI 必错——一律 `* PixelsPerInch div 96` 换算。
5. DWM 调用要求窗口句柄已建（Handle 首访即建——30 章句柄懒加载）。
6. 本机实测 HRESULT=0 但老系统可能负值——暗色标题栏是渐进增强不是依赖。
7. **`external 'dwmapi'` 不包 `{$IFDEF MSWINDOWS}` 就死在链接期**——Unix 上库名
   展开成 `-ldwmapi`，cocoa 无此库 → `ld: symbol(s) not found`（**构建期**失败，
   不是运行期）；且 cocoa 没有"按窗口改标题栏暗色"的等价 API（外观由系统统一
   决定），只能给 NoOp 分支——暗色在这平台上只剩客户区配色自管。

---
上一章：[36 国际化](36-i18n.md) ｜ 下一章：[38 数据感知控件](38-data-aware.md) ｜ 返回：[README](../README.md)
