# 43 · 常用工具类型：日期时间、Guid、Uri、Math、Random

> 对应示例：`examples/43_common_types`

> **本章你将学会**：DateTime/TimeSpan/DateOnly/TimeOnly 的构造、格式化、解析与时区规则，Guid 与 Uri 的日常用法，Math 里的银行家舍入与 Clamp，Random 的「同种子同序列」与安全随机的分界。
> **前置章节**：[03 变量与运算符](03-variables-operators.md)、[05 值与引用](05-value-reference.md)、[06 字符串](06-strings.md)、[33 JSON](33-json.md)。

四本参考教材（《从入门到项目实践》4.3 节、《程序设计教程》唐大仕版 5.1 节、蒙祖强版 4.8 节）都拿专门小节讲这批「天天用但没人系统讲」的类型——本教程此前只在各章顺带使用，本章一次补齐。

## 1. DateTime：一个时刻

```csharp
var release = new DateTime(2026, 11, 10, 9, 0, 0);
Console.WriteLine($"{release:yyyy/MM/dd HH:mm:ss}");   // 自定义格式串
```

三个易错点：

- **格式串大小写有语义**：`MM` 是月份、`mm` 是分钟、`HH` 是 24 小时制、`hh` 是 12 小时制
- **它是 struct**：不可变、赋值即拷贝（[05 章](05-value-reference.md)），`d.AddDays(1)` 返回新值不改原值
- **长短格式随文化**：`ToLongDateString()` 在 zh-CN 是「2026年11月10日」，en-US 是 "Tuesday, November 10, 2026"——给机器看永远用显式格式串

解析三件套的分工（与 `int.Parse/TryParse` 完全同构，[04 章](04-control-methods.md)）：

```csharp
DateTime.TryParse("2027年2月14日", zhCN, DateTimeStyles.None, out var d);   // 用户输入：不炸、返 bool
DateTime.TryParseExact("31/12/2026", "dd/MM/yyyy", null, ..., out var e);  // 机器格式：格式钉死
DateTime.ParseExact("2026-02-30", "yyyy-MM-dd", null);                     // → FormatException（日期本身非法）
```

## 2. Now / UtcNow / Kind：本地时间是个显示层概念

实测输出：

```text
Now    = 2026-09-28 23:30:04  Kind=Local
UtcNow = 2026-09-28 15:30:04  Kind=Utc
差值   = 8.0 小时（本机时区偏移，随夏令时变）
```

每个 DateTime 肩上贴着 Kind 标签（Unspecified/Local/Utc），`+`/`-` 混用不同 Kind 的值不做转换、直接算数值。**军规：存储、比较、跨系统传输一律 UtcNow；渲染给人的那一刻才转本地**。`SpecifyKind` 只贴标签不改数值；真转换用 `ToUniversalTime()`/`ToLocalTime()`。

时区换算用 `TimeZoneInfo`（示例实测：UTC 14:00 的会议 → 纽约 09:00，11 月已退出夏令时所以是 EST -5）：

```csharp
var ny = TimeZoneInfo.FindSystemTimeZoneById("America/New_York");   // .NET 6+ 双平台都认 IANA
var local = TimeZoneInfo.ConvertTimeFromUtc(utcTime, ny);
```

## 3. TimeSpan：一段时间

两个 DateTime 相减得到 TimeSpan；`FromHours/FromMinutes` 构造时长。**最高频踩坑**：

```csharp
var film = new TimeSpan(2, 21, 0);
film.Minutes       // 21 —— 只是「分钟位」的余数
film.TotalMinutes  // 141 —— 总时长才是你想要的
```

## 4. DateOnly / TimeOnly（.NET 6+）：纯日期、纯时间

生日、截止日这种「没有几点几秒也没有时区」的值，`new DateOnly(2027, 3, 14)` 比 DateTime 更诚实。TimeOnly 是 24 小时环：9:30 `AddHours(18)` 得到 3:30（自动回绕，示例实测）。两者与 DateTime 可互转。

## 5. Guid 与 Uri

**Guid**：122 位随机标识，`NewGuid()` 两次必不同（没有「种子」概念）；`ToString("N")` 去连字符做文件名/键。适合做无含义主键、请求 ID；**不要**用它表达「排序」「业务含义」。

**Uri**：构造一次后免费拆解出 `Scheme/Host/Port/AbsolutePath/Query/Fragment`；`new Uri(base, relative)` 做相对路径解析是爬虫/分页翻页的标准姿势；用户输入先过 `Uri.TryCreate` 再 `new`。

## 6. Math：三个被低估的成员

```csharp
Math.Round(2.5)        // 2 ！  Math.Round(3.5) → 4 —— 银行家舍入：.5 取偶数，不是四舍五入
Math.Truncate(-2.7)    // -2（向零截断）；(int)(-2.7) 同为 -2；四舍五入必须显式 Round
Math.Clamp(150, 0, 100) // 100 —— 限幅一行搞定（音量/进度/血条）
```

## 7. Random：同种子 = 同序列

示例最重要的实测——两个实例喂同一个种子，序列**逐位相同**：

```text
new Random(42) 实例A: [66, 14, 12, 52, 16, 26]
new Random(42) 实例B: [66, 14, 12, 52, 16, 26]
```

这就是「确定性回放」的原理基础：录下种子就复现整局游戏/整次抽样（贪吃蛇示例、单元测试造数据都靠它）。

**教材时代的坑，现代 .NET 已修**：老书警告「循环里 `new Random()` 用时钟做种，快速连建多个实例会同种子同序列」——.NET Core 2.0 起无参构造从全局熵取种，随便 new 不再重样。但**共享实例（`Random.Shared`）仍是好习惯**，还线程安全。

现代 API 三件（.NET 8+）：`Random.Shared.GetItems(数组, n)` 有放回抽样、`Shuffle(数组)` 原地洗牌、`Next(1, 7)` 注意**上界开区间**。

**安全边界**：验证码/密钥/令牌用 `RandomNumberGenerator`——Random 是统计随机、可被预测；安全随机没有种子、不可复现。

## 常见坑

**`mm` 写成月份**：`yyyyMMdd` 与 `yyyyMMdd` 天差地别——分钟小写、月份大写。

**跨时区存了本地时间**：服务器搬到另一个时区，所有「上午 9 点」全部错位——入库一律 UTC + ISO 8601。

**TimeSpan.Minutes 当总分钟**：2:21:00 的 Minutes 是 21 不是 141——要总量用 Total 系列。

**Math.Round 想要四舍五入**：默认银行家舍入（.5 取偶），`MidpointRounding.AwayFromZero` 才是小学四舍五入。

**Next 上界开区间**：`Next(1, 6)` 永远掷不出 6——骰子是 `Next(1, 7)`。

## 实战建议

- 日历值三选型：时刻 DateTime（内部 UTC）、纯日期 DateOnly、时长 TimeSpan；「这个瞬间在多个时区各是几点」上 DateTimeOffset
- 日志/数据库字段统一 UTC 存储；API 输出 ISO 8601；前端负责本地化显示
- 涉及钱的舍入用 `decimal` + 显式 `MidpointRounding`，别让银行家舍入替你做主
- 测试里所有随机数据先 `new Random(固定种子)`——失败可复现

## 自测

1. **Now 与 UtcNow 各该用在什么场合？** —— 存储/比较/传输用 UtcNow，展示给人用 Now（或 ConvertTimeFromUtc）。
2. **TimeSpan(2,21,0) 的 Minutes 与 TotalMinutes？** —— 21 与 141：分量 vs 总量。
3. **同种子的两个 Random 为什么序列相同？有什么正面用途？** —— 算法由种子决定；确定性回放/可复现测试。
4. **Math.Round(2.5) 等于几？为什么？** —— 2；银行家舍入取偶，降低累计偏置。
5. **什么场景必须用 RandomNumberGenerator？** —— 安全敏感：密钥、令牌、验证码——Random 可预测。

---
上一章：[42 Effective C#·异常设计](42-effective-exceptions.md) ｜ 下一章：[44 预处理指令与代码组织](44-preprocessing.md) ｜ 返回：[README](../README.md)
