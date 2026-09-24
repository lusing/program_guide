# 16. 日期与时间族：DatePicker、TimePicker、CalendarDatePicker、CalendarView

上一篇：[15 AutoSuggestBox](./15-autosuggestbox.md) ｜ 下一篇：[17 ListView](./17-listview.md)

WinRT 的日期时间模型（`Windows::Foundation::DateTime` / `TimeSpan`）先在 02 篇讲过；本章讲四个让用户"选"它们的控件。它们长得不同，但值模型统一，而且有一个共同的新坑：**事件 args 的可空性**。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 16.1 一张表分家

| 控件 | 形态 | 值属性 | 类型 |
|------|------|--------|------|
| `DatePicker` | 日/月/年三个 spinner | `Date` | 可空日期 |
| `TimePicker` | 时/分 spinner | `Time` | `TimeSpan` |
| `CalendarDatePicker` | 点开是月历 | `Date` | `IReference<DateTime>`（可空） |
| `CalendarView` | 常驻月历（可多选） | `SelectedDates` | 集合 |

选择指南：**表单里要一行放下** → DatePicker/TimePicker；**日期本身就是内容**（行程、打卡日历）→ CalendarView；想要"点开挑一天"的轻量弹层 → CalendarDatePicker。

## 16.2 DatePicker：spinner 式与 DateChanged

```xml
<DatePicker x:Name="Pick" Header="Due date" DateChanged="OnDateChanged"/>
```

```cpp
void DateTimePage::OnDateChanged(IInspectable const&,
    DatePickerValueChangedEventArgs const& args)
{
    if (!StatusText()) return;
    // 元数据实测：args.NewDate() 返回裸 DateTime 结构体（编译级 C2451 教训：
    // 它不是 IReference，没有可空语义，直接用）
    auto date = args.NewDate();
    StatusText().Text(L"date ticks = "
        + winrt::to_hstring(date.time_since_epoch().count()));
}
```

> **实测坑（编译级）**：按 UWP 时代记忆写 `if (auto date = args.NewDate())` ——C2451"类型为 DateTime 的条件表达式无效"。1.8 的 `DatePickerValueChangedEventArgs.NewDate()` 是**裸 `DateTime` 结构体**，不是可空引用；"未选择"态在事件里不存在（事件只在有值变化时触发）。控件本身的 `Date` 属性倒是可空的——两个层次的可空性不一样，读属性要判空、读事件 args 不用。

日/月/年三段的显示顺序随系统区域设置（中文环境是年/月/日）。`YearVisible="False"` 可砍掉年段；`MinYear`/`MaxYear` 限定范围。

## 16.3 TimePicker 与 TimeSpan

```xml
<TimePicker x:Name="TimePick" Header="Reminder time"/>
```

`TimePicker.Time` 是 `TimeSpan`——从午夜起的 100ns 计数。互转：

```cpp
using namespace std::chrono;
auto ts = TimePick().Time();                       // winrt::Windows::Foundation::TimeSpan
auto minutes = duration_cast<minutes>(ts).count(); // 读
TimePick().Time(duration_cast<wf::TimeSpan>(30min)); // 写（std::chrono 直转）
```

`MinuteIncrement` 控制分钟步进（15 = 一刻一刻跳）。**没有秒段**——要秒就用两个 picker 或自定义。

## 16.4 CalendarDatePicker 与 CalendarView

```xml
<CalendarDatePicker x:Name="CalendarPick" Header="Calendar pick"
                    PlaceholderText="pick a date..."/>
```

CalendarDatePicker 的 `Date` 是 `IReference<DateTime>`：未选 = `nullptr`（读前判空），`DateChanged` 事件在选/清时触发。它是**单选**。

`CalendarView`（本页未摆，机制给出）是**常驻多选日历**：

```xml
<CalendarView x:Name="MonthCal" SelectionMode="Multiple"/>
```

```cpp
// SelectedDates 是 IVector<DateTime>，增删都带事件
auto dates = MonthCal().SelectedDates();
```

`SelectionMode="None/Single/Multiple"`；`BlackoutDates` 可以锁死不可选日期（如过去的日期）；`FirstDayOfWeek`、`IsTodayHighlighted` 做本地化与引导。

## 16.5 程序化设值（也是自动化验证的抓手）

```cpp
void DateTimePage::OnTodayClicked(IInspectable const&, RoutedEventArgs const&)
{
    if (!Pick()) return;
    // 程序化设值触发 DateChanged（与用户改 spinner 同一事件）
    Pick().Date(winrt::clock::now());
}
```

`winrt::clock::now()` 给出**本地墙上时间**的 DateTime（02 篇 2.6 讲过 WinRT 的 clock 语义：struct 里存的是 UTC 视角的 tick，投影层的 `clock` 帮你按本地时间构造）。程序化路径与用户交互走同一事件——"恢复上次选择的日期"代码天然复用 handler，也是 ui-smoke 无需操作 spinner 就能验证整条链路的原因。

## 16.6 实测坑位

1. **`args.NewDate()` 是裸 DateTime**（16.2，C2451 实测）——事件 args 与控件属性的可空性不同层。
2. **控件 `Date` 属性要判空**：`CalendarDatePicker.Date()` 未选时是 `nullptr`，直接 `time_since_epoch()` 会 AV。
3. **时区语义**：DateTime 的 tick 存的是 UTC 基准，`clock::now()` 按本地构造；格式化给用户看用 `clock` 相关工具，别自己除以 86400e7 换算"天数"。
4. **TimeSpan 与 std::chrono 互转**：直接 `duration_cast`，不要手撸 tick 除法。
5. **三段顺序随区域变**：自动化脚本别假设"第一段是月"。

## 16.6 实战：偏好页里的两个选择器（设置中心）

```xml
<DatePicker x:Name="WeekStart" Header="Week starts on" DateChanged="OnWeekStartChanged"/>
<TimePicker x:Name="ReminderTime" Header="Daily reminder at" MinuteIncrement="15"/>
```

`MinuteIncrement="15"` 是 TimePicker 在真实场景里最重要的属性：提醒时间几乎总是整点/一刻/半点/三刻，15 分钟步进把滚轮从 60 项砍到 4 项——**选项粒度本身是产品语言**（精确到分钟的提醒是日历事件，不是每日提醒）。

### 16.6.1 事件载荷：裸值不是可空引用

```cpp
void PreferencesPage::OnWeekStartChanged(IInspectable const&,
    DatePickerValueChangedEventArgs const& args)
{
    // 16 章实测：NewDate() 是裸 DateTime，不是 IReference
    StatusText().Text(L"week start ticks = "
        + to_hstring(args.NewDate().time_since_epoch().count()));
}
```

与 NumberBox 的 `NewValue()`（double，可能 NaN）对照着记：**WinUI 的事件载荷没有统一的可空策略**——DatePicker 给裸 `DateTime`，ComboBox 给 `SelectedItem`（IInspectable 可空），CheckBox 给 `IReference<bool>`。写处理器前先查载荷类型，别按上一个控件的经验类推。

### 16.6.2 值的落盘形态

TimePicker 的取值是 `TimeSpan`（自午夜的 100ns 计数），直接数字落盘：

```cpp
SettingsStore::Put(L"reminder", to_hstring(ReminderTime().Time().count()));
```

`count()` 给 int64——存的是 485400000000 这类数，人看不懂但**双向无损**（回读 `TimeSpan{ count }` 即可恢复）。日期同理走 ticks。反例是存格式化字符串（"08:05"）：解析回来要过一层文化区域设置（有的地方 24 小时制、有的 12 小时制），多出整整一类 bug。**序列化存机器格式、显示才格式化**，两者永不混用。

### 16.6.3 CalendarDatePicker 与联动的边界

裸 `DatePicker` 适合表单内嵌；要"弹层选日期"（点输入框出日历）用 CalendarDatePicker，或在 24 章的 ContentDialog 里放 DatePicker 组成日期选择对话框。设置中心只需要"一周从周几开始"——它的 UI 形态恰好是 DatePicker 的年/月/日三段轮盘（选 2026-09-21 那种完整日期），产品上更贴的其实是"周一/周日"两选项的 ComboBox——**但教程要覆盖日期选择器，且 DateChanged 管线与 TimePicker 对称**，工程取舍里教学权重也是权重。

### 16.6.4 文化区域设置的雷区

DatePicker 的三段轮盘（年/月/日）顺序与格式**跟随系统文化区域设置**——中文系统 年/月/日，美式 月/日/年。**不要假设段序**，也别在 UI 测试里按固定顺序找控件（自动化按 Header 或 AutomationId 定位）。存储侧 16.6.2 已用 ticks 避雷；显示侧 `DateTime` 转 `winrt::clock` 相关 API（或 std::format with locale）时同样显式传区域，别赌默认。

### 16.6.5 MinuteIncrement 的兄弟们

TimePicker 还有 `HourIncrement`（12/24 混排场景排 2 小时步）与 `ClockIdentifier`（"24HourClock"/"12HourClock"显式钉死——不给就随系统）。设置中心只调了分钟粒度；跨时区产品（提醒时间跟人走）还要想清楚存的是本地时间还是 UTC——本例存本地 TimeSpan（自午夜，无时区语义），换时区不重算，对"每天 9 点提醒我"恰好正确。

### 16.6.6 DatePicker 的钳制

`MinYear`/`MaxYear`（DateTime）给可选年份划界——周起始选择里年份其实无意义（产品上该用两选项 ComboBox，16.6.3 已自我检讨）；真用日期的表单（生日、预约）必设：**MinYear=今天**防选过去，预约类 MaxYear 防飘到下世纪。域外年份在下拉里直接不出现——又是"拒收优于提示"（13.5.2 同款纪律）。

### 16.6.7 日期算术：周起始的实现

"一周从周几开始"真的要算时（日历网格渲染）：

```cpp
auto now = winrt::clock::now();                       // 系统时钟 → DateTime
auto days = now.time_since_epoch().count() / 864000000000LL;   // 100ns → 天
auto weekday = (days + 4) % 7;                         // 1970-01-01 是周四
auto shifted = (weekday + 7 - firstDayOffset) % 7;     // 以周一起始为例
```

**月视图同理加一坨**（闰年、月长不齐）——`winrt::clock` 只做点转换，日历数学自己写或上 `Windows.Globalization.Calendar`（它懂一切历法：`ChangeCalendarSystem(L"ja-JP")` 直接和历）。教学工程存 ticks 避开了这些；真做日历功能，Globalization.Calendar 是唯一的正路。

### 16.6.8 CalendarView：月历网格

`CalendarView`（与 DatePicker 不同控件）渲染整月网格：可圈选日期范围（SelectedDates 集合）、`DisplayMode="Month/Year/Decade"` 钻取。它是"选日子"的重型形态（订机票、请假起止）——设置中心用不着；DataExplorer 若加"按日期过滤文件"也用 DatePicker 足矣。**CalendarView 的黑话日期格式**（FirstDayOfWeek/BlackoutStrikes）走 `CalendarViewDayItemChanging` 事件改样式——又是"数据驱动外观"的一课（17 章 ContainerContentChanging 的日历版）。

## 16.7 练习与思考

1. 16.6.7 的周历算术：写一个"本周一日期"的函数，输入周起始设置（周一/周日），输出 DatePicker 该显示的 Date。再用 Windows.Globalization.Calendar 重写一遍对比。
2. 把 ReminderTime 的存储从 TimeSpan.count() 换成 "HH:mm" 字符串——列出你要处理的区域/格式坑（16.6.2 反例实操）。
3. CalendarView（16.6.8）圈选本周：SelectedDates 的多选语义与 DatePicker 单选的转换在哪写？

### 16.6.9 时区与"每天 9 点"

提醒类时间的完整语义链：存储（本地 TimeSpan，16.6.2）→ 显示（TimePicker，随系统区域）→ 触发（DispatcherQueueTimer 到点）。**跨时区旅行的坑**：存的是"本地 9 点"，人飞到另一个时区后系统本地变了、存的 9 点不变——提醒会在"新的本地 9 点"响（大概率仍是用户要的：随人走的闹钟）。反例是会议时间（随地点走）：存 UTC + 显示时转本地。**两种"9 点"没有对错，只有选错场景**——写下你的应用属于哪种比任何代码都重要。

## 16.8 上生产前的审查清单

- [ ] 存储用 ticks/计数，显示才格式化（16.6.2）
- [ ] 时区语义明确（随人 vs 随地点，16.6.9）
- [ ] MinuteIncrement/HourIncrement 按产品粒度收紧
- [ ] 事件载荷类型核对（裸 DateTime vs IReference）
- [ ] 文化区域（段序/12-24h）不进测试假设

## 16.7 小结

| 需求 | 控件 + API |
|------|-----------|
| 表单选日期 | DatePicker：Date + DateChanged（args 是裸 DateTime） |
| 表单选时间 | TimePicker：Time(TimeSpan) + MinuteIncrement |
| 弹层挑日期 | CalendarDatePicker：Date(判空) + DateChanged |
| 常驻日历/多选 | CalendarView：SelectedDates + SelectionMode + BlackoutDates |
| 程序化设值 | `Pick().Date(winrt::clock::now())`，事件复用 |

PreferencesPage 的 WeekStart（DatePicker）与 ReminderTime（TimePicker，MinuteIncrement=15）：OnWeekStartChanged 读 `args.NewDate()`（裸 DateTime，不是 IReference——16 章实测坑），保存时 ReminderTime().Time().count() 落盘。运行时证据见 `.smoke/07-settings-hub/save/tap-2.png`。

---

上一篇：[15 AutoSuggestBox](./15-autosuggestbox.md) ｜ 下一篇：[17 ListView](./17-listview.md) ｜ 返回 [目录](../README.md)
