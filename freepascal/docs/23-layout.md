# 23 · 布局与锚定

## 1. 两套思路：Align/Anchors 半自动 + OnResize 手工

LCL 没有 WPF 那种布局面板系统（Grid/Stack/Dock），它的布局是两条路：

1. **半自动**：`Align`（占边）+ `Anchors`（锚定）+ `BorderSpacing`（留白）——
   覆盖 90% 界面，IDE 里点点鼠标就行。
2. **手工**：`OnResize` 事件里按 `ClientWidth/ClientHeight` 自己算——复杂布局
   （表格状、按内容测量）最终都回到这条路。

## 2. Align 家族：占边多米诺

```pascal
TopPanel.Align := alTop;      // 占顶：横向拉满，高度自己定（TopPanel.Height := 48）
BottomBar.Align := alBottom;  // 占底
LeftList.Align  := alLeft;    // 占左：纵向占剩余，宽度自己定（Width := 160）
Splitter.Align  := alLeft;    // 分隔条与被隔控件同侧
Pages.Align     := alClient;  // 客户区：吃掉所有剩余空间
```

五个值（`alTop/alBottom/alLeft/alRight/alClient`，另有 `alNone` 恢复自由、
`alCustom` 交给 OnAlignPosition 事件）。**对齐顺序 = 控件创建/z 顺序**——
alClient 的控件要先建顶条再建它才不会把顶条盖掉；乱序是对齐"叠罗汉"的原因。
`alCustom` 少用；需要精确控制 z 序时用 `Control.BringToFront/SendToBack`。

## 3. Anchors：相对父容器的四向锚

```pascal
InfoLabel.Anchors := [akTop, akRight];              // 锚右上：父变宽我只往右跟
Btn.Anchors := [akTop, akLeft, akRight, akBottom];  // 四向锚：跟随伸缩
```

默认 `[akTop, akLeft]`（钉死左上）。经典用法：

| 需求 | Anchors |
|---|---|
| 按钮钉右下（像对话框的"确定"） | `[akRight, akBottom]` |
| 输入框横向拉伸 | `[akTop, akLeft, akRight]` |
| 区块整体伸缩 | 四向全锚 |

Anchors 是**控件级**的（相对 Parent），Align 是**兄弟级**的（和兄弟控件分蛋糕）——
两者可叠加（Panel 占顶，Panel 里的按钮再锚定）。

## 4. BorderSpacing 与 Margins：留白

```pascal
LeftList.BorderSpacing.Around := 4;   // 四周各留 4px（Align 计算时扣除）
```

`BorderSpacing`（Around/Left/Top/Right/Bottom/InnerAlign）是 Align 体系内的留白；
`Margins` 是"期望别人离我多远"。配合 Align 用 BorderSpacing 居多。

## 5. TSplitter：可拖分隔

```pascal
LeftList.Align := alLeft;   LeftList.Width := 160;
Splitter.Align := alLeft;   Splitter.Width := 6;   // 紧跟其后、同侧
```

Splitter 夹在"占边控件"和剩余区之间，拖动改那个控件的 Width/Height。
**实测注**：VCL 的 `ResizeControl` 属性在 LCL 不保真（赋了值读不回）——LCL 的
Splitter **就近自动关联**同侧相邻控件，通常不用管。

## 6. OnResize 手工布局

```pascal
procedure TDemoForm.ManualLayout;
var w: Integer;
begin
  w := ClientWidth;                       // 客户区宽（去掉边框标题栏）
  BottomBar.Caption := Format('宽 %d：左 1/3=%d 中 1/3=%d 右 1/3=%d', ...);
end;

OnResize := @FormResize;                  // 尺寸变化时重排
```

要点：**用 `ClientWidth/ClientHeight` 不用 `Width/Height`**（后者含边框）；
布局函数独立成方法（可单测——本章 selftest 就直接调它断言输出）；
防抖（连续 resize 只算一次）用 30 章 QueueAsyncCall 或简单标志位。

## 7. 高 DPI 概念：PixelsPerInch 的世界（37 章深挖）

- 设计基准是 **96 DPI**（100% 缩放）；`PixelsPerInch` 是窗体的当前密度。
- Windows 下 LCL 程序默认**不声明 DPI 感知**→ 系统位图拉伸→ 发糊。
  现代程序应在 .lpi 的 manifest/`TKScalingMode` 或代码里声明 Per-Monitor 感知：
  - 简单路线：所有尺寸经 `ScaleX/ScaleY(96 值, 96, Screen.PixelsPerInch)` 换算；
  - LCL 内建：`AutoAdjustLayout`（窗体按设计 DPI 与当前 DPI 比例整体重排）。
- 字体走 `TFont.Size`（pt 语义）比像素值更耐缩放。
- 深度 DPI 适配（声明感知、Per-Monitor、暗色主题）在 37 章全章展开；本章记住起步姿势：**声明感知 + 尺寸走比例**。

> 无头验证注（本章 selftest 策略）：对齐/锚点做**属性级**断言、手工布局函数当纯计算验证
> ——不赌控件集布局引擎在未 Show 时的行为（不同控件集/平台时机不一致）。

## 8. 示例与验证

本章示例 `examples/23_layout`：Align 四向 + Splitter + PageControl 客户区 +
Anchors 演示 + ManualLayout 手工布局函数。

```powershell
pwsh -File build.ps1 -Example 23_layout
```

正常路径拖动窗口右下角：顶条/底条高度不变、左列宽度不变、Memo 区伸缩、
底条文字按 1/3 比例刷新。

## 9. 坑位清单（实测）

1. Align 的叠放次序 = 创建次序；alClient 控件要最后建（否则盖住先建的占边控件）。
2. `ClientWidth` 才是布局坐标系；`Width` 含边框——手工布局用错必然错位。
3. VCL 的 `Splitter.ResizeControl` 在 LCL 读不回（不保真）——靠就近自动关联。
4. Anchors 相对 Parent、Align 相对兄弟——混用时先想清楚参照系。
5. 无头/未 Show 环境别断言布局引擎的计算结果——断言属性与自己的布局函数。

---
上一章：[22 TFrame 与界面复用](22-frames.md) ｜ 下一章：[24 菜单与 Action](24-menus.md) ｜ 返回：[README](../README.md)
