# 18 · 选择器控件：日期、时间与颜色

"选日期、选颜色"这类输入有专用控件：月历 `TCalendar`、下拉日期时间
`TDateTimePicker`、色板 `TColorBox`/`TColorListBox`。本章顺带打通两件
LCL 的底层知识：**包（package）与单元（unit）的对应关系**、**TColor 的
位布局**。

## 1. 日期控件选型

| 控件 | 单元 | 形态 | 工程实例 |
|---|---|---|---|
| `TCalendar` | `Calendar`（基础 LCL） | 月历整块显示 | `18a_calendar` |
| `TDateTimePicker` | `DateTimePicker`（**独立包**） | 一行下拉 | `18b_picker` |

经验法则：弹窗表单用 Picker（省地方）；主界面放日历（所见即所选）。

## 2. TCalendar：两个事件的分工

```pascal
Cal := TCalendar.Create(Self);          // unit Calendar
Cal.DateTime := EncodeDate(2026, 9, 22);
Cal.FirstDayOfWeek := dowMonday;        // 默认 dowLocale 跟系统区域
Cal.OnChange := @CalChange;             // 交互改了所选值
Cal.OnDayChanged := @CalDayChanged;     // 只有"日"变了
```

**实测**：程序赋值 `DateTime` 两个事件**都不发**（OnChange 计数=0、
OnDayChanged 计数=0）——展示型控件的事件留给用户（17 章横评表）。
翻月不动所选日时也连 OnChange 都没有。要"程序改值后刷新界面"，自己调
渲染函数。

日期语义配 DateUtils（11 章的 TDateTime 浮点：整数部分=天）：

```pascal
DayOfTheWeek(D)      // 1=周一 … 7=周日（不是 0..6！）
DayOfTheYear(D)      // 当年第几天
IncMonth(D, 3)       // 月份算术：1 月 31 日 +1 月 → 2 月 28 日（钳到月末，不溢出）
```

## 3. TDateTimePicker：第一个"包外"控件

这是教程里第一次走出基础 LCL——它住在**独立包**里，两步缺一不可：

```xml
<!-- .lpi 的 RequiredPackages：加"包" -->
<RequiredPackages Count="2">
  <Item1><PackageName Value="LCL"/></Item1>
  <Item2><PackageName Value="DateTimeCtrls"/></Item2>   <!-- 包名 -->
</RequiredPackages>
```

```pascal
uses DateTimePicker;     // 单元名≠包名！包 DateTimeCtrls 里的单元叫 DateTimePicker
```

**坑（实测）**：uses 写了包名 `DateTimeCtrls` 会报 Identifier not found
"TDateTimePicker"——那个单元只是注册包的壳，控件本体在 `DateTimePicker`
单元。IDE 里拖控件会自动把包加进 .lpi，这是 IDE 相对手写的真实优势。

```pascal
DatePick.Kind := dtkDate;               // dtkDate / dtkTime / dtkDateTime
DatePick.DateTime := EncodeDate(2026, 9, 22);
DatePick.MinDate := EncodeDate(2026, 1, 1);   // 值域：越界日历变灰
DatePick.MaxDate := EncodeDate(2026, 12, 31);

TimePick.Kind := dtkTime;
TimePick.TimeFormat := tf24;            // 只有 tf12/tf24（12/24 小时制）
                                    //   不是"时分秒粒度"——名字容易误会
OptionalPick.ShowCheckBox := True;      // 可空日期：勾选框
OptionalPick.Checked := False;          // 不勾 = 表单里的"无日期"
```

实测：`MinDate` 钳制生效（设 2025-06-01 读回 2026-01-01）。`Checked=False`
配 `NullInputAllowed` 是"可选日期"的标准做法——比拿 1899-12-30（TDateTime=0）
当空值干净得多。

## 4. TColorBox / TColorListBox：Style 决定内容

```pascal
Box := TColorBox.Create(Self);          // unit ColorBox
Box.OnGetColors := @BoxGetColors;       // 顺序：先挂事件
Box.Style := [cbStandardColors, cbExtendedColors, cbSystemColors,
              cbIncludeDefault, cbPrettyNames, cbCustomColors];
Box.Selected := clRed;                  // TColor 读写
```

`Style` 是集合，每一项加一类条目：

| 项 | 内容 |
|---|---|
| `cbStandardColors` | 16 标准色 |
| `cbExtendedColors` | 4 扩展色 |
| `cbSystemColors` | 系统色（clBtnFace 等，占条目大头） |
| `cbIncludeNone/cbIncludeDefault` | clNone / clDefault 两哨兵 |
| `cbPrettyNames` | 显示友好名——**实测是英文**（Black/Red），不随系统本地化 |
| `cbCustomColors` | 开了才回调 OnGetColors，往列表追加自定义色 |

**两个实测坑**：

1. **顺序坑**：`Style` 赋值会触发条目重建。先设 Style 再挂 OnGetColors，
   自定义色进不了首轮条目（18c 工程断言过条目数对不上）。
2. **签名坑**：LCL 的 `TGetColorsEvent` 首参是具体类型，不是 TObject：

```pascal
procedure(Sender: TCustomColorBox; Items: TStrings) of object;   // 不是 TObject！
```

自定义色的加法（TColor 就是 32 位整数，直接当对象指针塞）：

```pascal
Items.AddObject('品牌蓝', TObject(PtrUInt($CC6633)));   // BGR 十六进制
```

## 5. TColor 的位布局：$00BBGGRR

TColor 低 24 位按 **BGR** 排（Windows COLORREF 血统），不是 RGB：

```pascal
clRed  = $0000FF;      // 低字节是"红"分量
clBlue = $FF0000;      // 高字节是"蓝"
RGBToColor(51, 102, 204) = $CC6633;    // R=51(0x33) G=102(0x66) B=204(0xCC)
```

分解与合成：

```pascal
C := ColorToRGB(Box.Selected);     // 系统色（clBtnFace 等）解析成具体 RGB
R := (C shr 16) and $FF;
G := (C shr 8)  and $FF;
B := C and $FF;
```

名字体系互转：`ColorToString(clRed)` = `'clRed'`、`StringToColor('clRed')`
回 `clRed`——配置文件里存颜色名的标准通道（配 11 章 INI）。
注意 `ColorBox.Items` 里的显示名（cbPrettyNames 下是 "Red"）与识别名
（"clRed"）是两套字符串。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 18a_calendar   # 月历 + 日期算术
pwsh -File build.ps1 -Example 18b_picker     # 日期/时间/可空三 Picker
pwsh -File build.ps1 -Example 18c_colorbox   # 色板 + 位分解
```

selftest 覆盖：日期回环、程序赋值事件零触发、FirstDayOfWeek 回环、
IncMonth 月末钳制、MinDate 钳制、Kind/TimeFormat/Checked 回环、
Style 增减条目数、OnGetColors 自定义色出现、ColorToString/StringToColor
互逆、RGBToColor 位布局。

## 7. 坑位清单（实测）

1. **包名 ≠ 单元名**：包 `DateTimeCtrls`，单元 `DateTimePicker`——uses 写
   包名直接 Identifier not found。
2. TTimeFormat 只有 `tf12/tf24`（12/24 小时制），不是时分秒粒度。
3. ColorBox 的 **OnGetColors 先挂、Style 后设**（Style 赋值触发重建）。
4. `TGetColorsEvent` 首参是 `TCustomColorBox`（LCL 特例，多数事件首参是 TObject）。
5. `cbPrettyNames` 的友好名是**英文**（Black/Red），别指望本地化。
6. TColor 是 **BGR** 布局（$00BBGGRR）；clWhite=$FFFFFF、clBlack=$000000。
7. TCalendar 程序赋值任何事件都不发——要刷新自己调渲染。
8. `DayOfTheWeek` 返回 1..7（周一起），不是 0..6。

---
上一章：[17 数值与进度控件](17-value-controls.md) ｜ 下一章：[19 表格控件](19-grids.md) ｜ 返回：[README](../README.md)
