# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 foreach：比 C 的 for 强一档

```d
auto langs = ["D", "Go", "Zig"];

foreach (lang; langs) { ... }              // 正向
foreach_reverse (lang; langs) { ... }      // 逆向
foreach (i, lang; langs) { ... }           // 带索引（自动解包）
foreach (n; 1 .. 5) { ... }                // 数字区间 [1, 5)
foreach (ref n; nums) n *= 10;             // ref：改元素本体
foreach (k, v; myAA) { ... }               // 关联数组解包键值
foreach (ch; "汉a".byDchar) { ... }        // 字符串按码点遍历
```

要点：

- 数组/区间/AA/结构体/输入源**全都用同一个 foreach**——这是 13 章 range 抽象的用户侧福利。
- 下标类型是 `size_t`（无符号）：`foreach (i, x; arr)` 里 `i` 不能和 `-1` 比较（无符号回绕）。
- 默认迭代值拷贝——想改元素要 `ref`。

## 4.2 if / else 与三元

```d
if (guess > 100) { ... }
else if (guess > 40) { ... }
else { ... }

auto parity = guess % 2 == 0 ? "偶" : "奇";   // 三元是表达式
```

D **没有** C++17 的 if-init（`if (auto x = f(); x)`）——先声明再用。

## 4.3 switch：范围、字符串与 final

```d
switch (score) {
    case 90: .. case 100: writeln("优秀"); break;   // 范围 case 的专用写法
    case 80: .. case 89:  writeln("良好"); break;
    default:              writeln("重修");
}

final switch (cmd) {          // final：禁止 default 时必须穷尽
    case "list": ...; break;
    case "add":  ...; break;
    case "del":  ...; break;
}
```

三大规则：

1. **范围语法是 `case a: .. case b:`**，不是 `case a .. b:`（解析报错）。
2. **没有隐式 break**：case 不写 break 会穿透到下一个（故意利用可以，误用是事故源）。
3. `final switch` 要求穷尽所有可能值——**配枚举是黄金组合**：加枚举成员忘了补 case，编译期直接报错。

## 4.4 标签 break/continue：跳出多层

```d
outer:
foreach (i; 0 .. 3)
    foreach (j; 0 .. 3) {
        if (i * j == 4) break outer;      // 一次跳出两层
        if (j > i) continue outer;        // 直接进外层下一轮
    }
```

## 4.5 with：省重复限定

```d
struct Point { int x, y; }
Point p = { x: 1, y: 2 };     // 结构体字面量支持字段名初始化
with (p) writeln(x + y);      // 这里 x/y 就是 p.x/p.y
```

## 4.6 goto：存在但基本不用

D 保留 goto（跳转不能越过变量初始化），实际代码里 foreach/标签/函数提取几乎总比 goto 干净。见到老代码里有它认得即可。

## 4.7 坑位清单

1. **范围 case 语法**是 `case 90: .. case 100:`——`case 90 .. 100:` 是编译错（`..` 那里解析不了）。
2. **case 穿透**：忘 break 不报错不警告，行为直接串到下一分支——final switch + 每支 break 是防呆姿势。
3. **foreach 下标是 size_t**：`foreach (i, x; arr) if (i == -1)` 永远为假（无符号比较回绕）；倒序遍历用 `foreach_reverse` 而不是 `i - 1`。
4. **`0 .. N` 只在 foreach 里合法**：它是循环专用语法，不是表达式——传给函数要用 `iota(0, N)`（13 章实测：`iota(0)` 单参数是"空区间"，无限流要用 `sequence!"n"`）。
5. 遍历字符串默认拿到的是**字节切片视图**；按字符遍历 `.byDchar`（06 章细讲 UTF-8 语义）。
6. `static foreach` 里裸 `break` 非法（必须带标签）——用生成 case 时记得 `return` 或标签 break（12 章完整示例）。

---
