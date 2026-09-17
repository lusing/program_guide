# 19 · 格式化与字符串

> 对应示例：`examples/19_format/`

## 19.1 占位符全集（writef / format 同一引擎）

| 占位符 | 含义 | 例 |
|---|---|---|
| `%s` | 万能（任何类型默认格式） | `true`、`[1, 2]`、`nan` |
| `%d` `%x` `%o` `%b` | 整数：十/十六/八/二 | `255` `ff` `377` `11111111` |
| `%f` `%e` `%g` | 定点/科学/自适应 | `3.14` `1.23e+04` |
| `%.2f` | 精度 2 | `3.14` |
| `%08.3f` | 宽 8 补零 + 精度 3 | `0003.142` |
| `%10s` / `%-10s` | 宽 10 右/左对齐 | |
| `%+d` | 强制符号 | `+2` |
| `%%` | 百分号字面量 | `100%` |
| `%(...)  %)` | 数组/区间逐元素 | 见 19.2 |

**运行期检查**：占位符和实参不匹配抛 `FormatException`（不是编译错）——`format("%d", "字符串")` 编译通过、运行爆炸。

## 19.2 数组与元组的 %(...)

```d
writefln("%(%d, %)", [1, 2, 3]);              // 1, 2, 3
writefln("%(0x%02X %)", [0xde, 0xad, 0xbf]);  // 0xDE 0xAD 0xBF

// 元组数组：嵌套两层 %(...) —— 外层走数组，内层走 tuple 字段
auto rows = [tuple("D", 2001), tuple("Go", 2009)];
writefln("%(%(%s=%d; %)%)", rows);            // D=2001; Go=2009;
```

规则：**分隔符写在元素格式的尾部**（`%d, %` = 每个元素 `%d`，元素间 `, `）；tuple 的字段要自己的内层 `%(...)`——单个 `%s` 会把整个 tuple 按默认格式吞掉。

## 19.3 解析：formattedRead（format 的逆）

```d
int minutes, seconds;
formattedRead("8 分 30 秒", "%s 分 %s 秒", &minutes, &seconds);
// 返回吃掉的参数个数
```

## 19.4 std.conv：to! / parse / roundTo

```d
to!int("42");  to!double("3.5");  to!string(255);  // 全量转换，失败抛 ConvException
roundTo!int(2.7);                                  // 3（四舍五入；cast(int)2.7 是 2）

auto rest = "123abc";
auto n = parse!int(rest);                          // 只吃前缀！rest 变 "abc"
```

- `to!` 是**全有或全无**；`parse!` 是"能吃多少吃多少"（要传左值，剩余留在里面）。
- `to!int("  42  ")` **不容忍空白**——先 strip 再转（std.string）。
- 数字转字符串的 `to!string` 覆盖 `%d`、浮点给 `%.10g` 风格——要控制格式用 format。

## 19.5 std.string 工具箱

```d
"  x  ".strip;                    // 去两端空白（stripLeft/stripRight）
"a,b,c".split(",");               // 切数组
["D", "Go"].join("-");            // D-Go
"d language".capitalize;          // D language
"HELLO".toLower;  "hello".toUpper;
"a-b-c".replace("-", "+");
"abc".dup.reverse;                // reverse 要可变副本
indexOf("hello", "ll");           // 找不到 -1
"hello".count('l');               // 2
text.splitLines;                  // 按行切
```

大小写函数在 **std.uni**（全 Unicode）也有同名——中文场景注意 `toLower` 只处理 ASCII 之外看 std.uni。

## 19.6 UTF-8 复习（字符串安全）

```d
string zh = "汉字";
zh.length;                     // 6 —— 字节
zh.byDchar.walkLength;         // 2 —— 码点
format("%6s", zh);             // 宽度按字节算：中文对齐会歪
```

（06 章讲过原理——写 CLI 表格对齐时必踩。）

## 19.7 坑位清单

1. **tuple 数组格式必须嵌套 `%(%(...%)%)`**：`%(%s:%d; %)` 抛 FormatException（"Expected '%s' or '%(...%)'"）。
2. **format 匹配是运行期异常**：没有编译期检查（writef 同）——测试里对格式串补 `assertThrown!FormatException` 或多写 unittest。
3. **`to!int` 不吃空白**；**`parse!int` 要左值**（ref 参数），字面量直接传编译错。
4. `%^10s` 居中对齐**不存在**（2.113 实测 FormatException）——只有左右对齐。
5. `reverse`/`sort` 等就地操作要求可变数组：`"abc".reverse` 编译错（string 不可变）——`.dup.reverse`。
6. `approxEqual` 已弃用 → `isClose`（std.math）；浮点比较永远别用 `==`。
7. 多个选择性 import 不能逗号串一行：`import A : x, B : y;` 语法错——分开写两条 import。

---
