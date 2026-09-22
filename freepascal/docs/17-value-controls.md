# 17 · 数值与进度控件（⭐）

16 章的按钮/编辑框是"任意文本"控件；真实表单里一半的输入其实是**数值**——
数量、比例、分数。LCL 给这一类的答案是一套"值域控件"：TrackBar（滑）、
SpinEdit（步进输入）、ProgressBar（进度显示）。本章每个控件一个工程，
把值域、刻度、步进、事件触发面逐一实测。

## 1. 一张选择表

| 需求 | 控件 | 值类型 | 工程实例 |
|---|---|---|---|
| 直观调比例（音量/透明度） | `TTrackBar` | Integer | `17a_trackbar` |
| 精确输数字（件数/分数） | `TSpinEdit` | Integer | `17b_spinedit` |
| 输小数（单价/权重） | `TFloatSpinEdit` | Double | `17b_spinedit` |
| 只显示进度（不输入） | `TProgressBar` | Integer | `17c_progress` |

共同心智模型：`Min/Max/Position` 三件套 + 越界自动钳制。它们与 TEdit 的本质
区别：**值是类型安全的**（`Spinner.Value` 直接是 Integer，不存在"用户输了个
感叹号"的问题）。

## 2. TTrackBar：值域与刻度

```pascal
Track := TTrackBar.Create(Self);
Track.Min := 0;  Track.Max := 255;
Track.Position := 200;
Track.Frequency := 51;             // 每 51 一条刻度：0/51/…/255
Track.LineSize := 1;               // ←→ 方向键步长
Track.PageSize := 16;              // PgUp/PgDn 步长
Track.TickMarks := tmBottomRight;  // 刻度位置：tmTopLeft / tmBoth
Track.TickStyle := tsAuto;         // tsAuto 按 Frequency 自动 / tsNone / tsManual
Track.Orientation := trVertical;   // 纵向滑杆
```

三个实测语义（写在断言里的，不是猜的）：

1. **程序赋值触发 OnChange**——与 TEdit/Memo 的"程序赋值不触发"正相反。
   初始化代码里先赋 `Position` 再挂 `OnChange`，可以避开构造期的连发。
2. **改 Min/Max 会立即重钳 Position**，不是等下次赋值：
   Position=0 时 `Min := 10`，Position 马上变 10。
3. **越界赋值钳到边界**：`Position := 999`（Max=255）→ 读回 255。

`SelStart/SelEnd/ShowSelRange`（默认 True！）在滑道上画一段高亮——语义是
"当前值的合理区间"（比如阈值上下限），不影响 Position 本身。

## 3. OnChange 触发面横评（本教程实测汇总）

"程序赋值到底触不触发事件"是 LCL 控件最分裂的一件事，实测记录：

| 控件 | 程序赋值触发 OnChange？ | 章节 |
|---|---|---|
| `TTrackBar.Position` | **触发** | 本章 |
| `TSpinEdit.Value` | **触发** | 本章 |
| `TEdit.Text` | **触发** | 16 章 |
| `TMemo` 程序化修改 | **不触发**（Lines 改动也不发） | 16 章 |
| `TCalendar.DateTime` | **不触发**（OnDayChanged 更不触发） | 18 章 |
| `TTabControl.TabIndex` | **不触发**（要开 nboDoChangeOnSetIndex） | 20 章 |

规律：输入型控件（Edit/Spin/Track）把程序赋值当"变化"；展示型/复合型控件
（Memo/Calendar/Tab）把 OnChange 留给用户交互。没有统一理论，逐控件实测。

## 4. TSpinEdit：默认值域是"不限"！

```pascal
Spinner := TSpinEdit.Create(Self);    // unit Spin
Spinner.MinValue := 1;  Spinner.MaxValue := 99;
Spinner.Increment := 5;               // 上下箭头步长
Spinner.Value := 10;                  // 注意顺序：先值域后初值
```

**头号坑（实测）**：不设值域时 `MinValue=0、MaxValue=0`，而 **0 的语义是
"不限"**——赋 500 进去原样收下。表单里忘了设 `MaxValue` 的 SpinEdit 会放行
任意大的数，比"被钳掉"更危险（库存 99999 件就这么来的）。另一个方向也实测
过：设了值域后越界赋值钳到边界（999 → 99）。

`TFloatSpinEdit` 是同族浮点版：

```pascal
Price := TFloatSpinEdit.Create(Self);
Price.MinValue := 0;  Price.MaxValue := 10000;
Price.Increment := 0.5;          // 浮点步长
Price.DecimalPlaces := 2;        // 两位小数——影响取值不只显示
Price.Value := 3.14159;          // 读回 3.14（实测）
```

## 5. TProgressBar：步进与跑马灯

```pascal
Bar.Min := 0;  Bar.Max := 100;
Bar.Step := 4;
Bar.StepBy(4);                     // 等价 Position := Position + 4（含钳制）
Bar.Smooth := True;                // 平滑条（默认分块）
Bar.BarShowText := True;           // 条内百分比（部分 widgetset 忽略）
Bar.Style := pbstMarquee;          // 跑马灯："不知道总量"的不确定进度
```

实测语义：Position 越界钳、StepBy 越过 Max 钳到 Max、**Max 收窄后 Position
立即重钳**（与 TrackBar 同款）。`pbstMarquee` 下 Position 照常存储只是不
参与显示——切回 `pbstNormal` 立刻接上，示例 17c 的"准备中→安装中"两阶段
模式就靠这个。

进度回传的完整闭环（后台线程算、进度条显示）在 28 章。

## 6. 一个语言坑：Inc 不能用在属性上

```pascal
Inc(Tick.Tag);          // 编译错：Can't take the address of constant expressions
Tick.Tag := Tick.Tag + 1;   // ✔ 属性没有地址，Inc/Dec 这类 var 参数用不了
```

凡是属性（哪怕只是简单字段包装）都不能传给要求 var 参数的例程。

## 7. 示例与验证

本章三个工程（每控件一个，均为 lazbuild + `--selftest` 无头断言）：

```powershell
pwsh -File build.ps1 -Example 17a_trackbar   # RGB 调色台：三滑杆联动
pwsh -File build.ps1 -Example 17b_spinedit   # 预算计算器：整型×浮点
pwsh -File build.ps1 -Example 17c_progress   # 安装模拟：marquee→步进两阶段
```

selftest 断言了：初值回环、越界钳制、Min/Max 联动重钳、OnChange 计数、
默认值域 0/0=不限、DecimalPlaces 取值精度、StepBy 累计、Style 切换后
Position 语义恢复。

## 8. 坑位清单（实测）

1. **SpinEdit 默认 0/0 = 不限**——忘设 MaxValue 放行任意值（比钳制更危险）。
2. TrackBar/SpinEdit **程序赋值触发 OnChange**；初始化想安静就先赋值后挂事件。
3. 改 Min/Max **立即**重钳 Position（TrackBar 与 ProgressBar 一致）。
4. `Inc(属性)` 编译不过——属性无地址，var 参数类例程都不行。
5. `TFloatSpinEdit.DecimalPlaces` 影响取值（不只是显示）。
6. `pbstMarquee` 期间赋的 Position 切回 normal 后还在——可用于"暂停时记住进度"。
7. 赋值顺序是协议的一部分：先 `Min/Max` 再 `Value`（中间态会被钳掉）。

---
上一章：[16 基础控件与事件模型](16-controls.md) ｜ 下一章：[18 选择器控件](18-picker-controls.md) ｜ 返回：[README](../README.md)
