# 31 · 焦点、键盘与输入验证

表单三问：用户现在在哪（焦点）、按了什么（键盘链）、输得对不对（验证）。
本章把这三件事的机制层讲透，并给出可无头测试的验证器写法。

## 1. 焦点：谁在接收键盘

焦点是一根"单链"：应用 → 活动窗体 → **ActiveControl**（一个 TWinControl）。
只有 TWinControl 系（有句柄的）能持焦点——TLabel/TImage 这些 TGraphicControl
不能（这就是为什么提示文字不能 Tab 进去）。

```pascal
EdName.TabOrder := 0;          // Tab 键顺序（容器内编号，创建序即默认序）
EdAge.TabStop := False;        // 从 Tab 链摘除（只读信息框的标配）
ActiveControl := EdAge;        // 设定初始焦点（程序版）
EdAge.SetFocus;                // 要求系统焦点（需要窗体处于活动态）
```

实测口径：selftest 里用 `ActiveControl`（LCL 层属性，确定可断言）；`SetFocus`
依赖窗体真的激活，无头环境不稳。`SelectNext(CurControl, GoForward,
CheckTabStop)` 手动按一次"Tab 键"（自定义回车跳格的经典配料）。

## 2. 键盘三事件链

一个字符键从按下到上抬：

```text
OnKeyDown(var Key: Word; Shift)   物理键（VK 码）——功能键/方向键在这拦
   ↓
OnKeyPress(var Key: Char)         字符（已翻译）——可打印字符在这过滤
   ↓
（字符进入编辑框）
   ↓
OnKeyUp(var Key: Word; Shift)
```

**吞键**：把 `var Key` 清零（KeyDown/KeyUp 用 `Key := 0`，KeyPress 用
`Key := #0`）——后续环节忽略。31 工程的年龄框就靠它在 KeyPress 里只放行
`'0'..'9'` 和退格。

**var 参数的语言坑（实测）**：直呼这些处理器做无头测试时，var 位不能传
常量——`f.AnyKeyPress(Ed, 'x')` 直接编译错（Variable identifier expected），
要 `C := 'x'; f.AnyKeyPress(Ed, C);`。集合常量 `[]` 同理（`Sh := []` 先行）。

## 3. KeyPreview：窗体先吃

```pascal
KeyPreview := True;             // 窗体的 OnKeyDown 先于活动控件收到
```

快捷键总机的开关：Esc 清提示、F1 帮助、Ctrl+S 保存——写在窗体 OnKeyDown
里，吞掉（Key := 0）后控件不再收到。不吞就"窗体看一眼、控件再处理"两级
都跑。31 工程的 Esc 分支就是这个结构。

## 4. 验证：三个时机与一个纯函数

| 时机 | 事件 | 体验 |
|---|---|---|
| 逐字符 | OnKeyPress/OnChange | 最严（输不进去），但打断感强 |
| 完成编辑 | **OnEditingDone**（回车或失焦都触发——实测） | 平衡点 |
| 离开字段 | **OnExit** | 传统时机；注意失焦可能因为"用户放弃了整个表单" |

**验证器写成纯函数**（无 Sender、无控件引用）——31 工程的全部验证逻辑：

```pascal
function ValidateAge(const S: string): string;   // '' = 合法，否则错误文案
var V: Integer;
begin
  Result := '';
  if not TryStrToInt(S, V) then Exit('年龄必须是数字');
  if (V < 0) or (V > 150) then Exit('年龄要在 0..150');
end;
```

为什么坚持纯函数：**selftest 能表驱动地测**（'30' 过、'abc' 与 '200' 各报
对应文案——六个断言六行）；OnExit/OnEditingDone 里只剩"取文本→调函数→显示
文案"三行胶水。这也是 25/29/40 章一以贯之的"可测逻辑剥出来"策略。

错误显示的温和做法：红字 TLabel + 不弹对话框（弹窗打断输入流；用户没
机会改就弹 Modal 是暴力美学）。要拦提交，在"确定"按钮里再全查一遍并
`SetFocus` 到第一个错处。

## 5. Tab 顺序的设计感

- TabOrder = 视觉顺序（从上到下、从左到右）——用户闭着眼 Tab 也能线性走完；
- 只读控件（TLabel/TImage）不占 Tab（TGraphicControl 无焦点）；
- "不参与但可点击"的（帮助链接）→ TabStop := False；
- 容器（TPanel/TTabSheet）有自己的 TabOrder 命名空间——外层先走完再进内层。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 31_focus_validation
```

selftest 覆盖：验证器表驱动（年龄/邮箱各三例）、TabOrder/TabStop 回环、
ActiveControl 指定、键盘链计数（Form 先吃 + 控件两级）、吞键留痕、
Esc 清提示（KeyPreview）、OnExit 校验报错与清错、OnEditingDone 置位。

## 7. 坑位清单（实测）

1. **var 参数不能传常量**——直呼事件处理器测试时 `'x'`、`[]` 都编译不过，
   先赋给变量。
2. `SetFocus` 要求窗体活动态——无头/后台不稳，程序内定位用 `ActiveControl`。
3. TGraphicControl（TLabel/TImage）不能持焦点、不占 Tab。
4. 吞键的位置：过滤字符在 **KeyPress**（Char），拦功能键在 **KeyDown**（VK 码）。
5. OnEditingDone 回车与失焦**都**触发——别在里做"只在回车时"的假设。
6. OnExit 里弹 Modal 要小心：用户可能正在点"取消"放弃表单——先判窗体状态。

---
上一章：[30 事件系统与消息循环](30-events-messages.md) ｜ 下一章：[32 工具栏、图像列表与系统托盘](32-toolbar-tray.md) ｜ 返回：[README](../README.md)
