# 04 · 表达式与控制流：让程序有分支

> 对应示例：`examples/04_control/`

## 4.1 if 与初始化语句

```cpp
std::string lang = "现代 C++";
if (auto pos = lang.find("C++"); pos != std::string::npos) {
    std::print("找到子串，位置 {}\n", pos);
} else {
    std::print("没找到\n");
}
```

C++17 起 if 可以带**初始化语句**（`auto pos = …;`）。价值不在少一行，而在**作用域**：`pos` 只活在 if/else 里，出来就消失——既不污染外层命名空间，也杜绝"if 之前残留的旧 pos 被误用"。判型准则：**变量用在哪就声明在哪**。

`find` 返回**字节偏移**——本例输出 `位置 7`：现代两字占 6 字节、空格 1 字节，`"C++"` 从第 7 字节开始。找不到返回 `std::string::npos`（"no position"哨兵值），判空就是这个固定姿势。switch 同样支持初始化语句（C++17 一起加的）。

## 4.2 switch：穿透必须显式

```cpp
for (int level = 1; level <= 3; ++level) {
    switch (level) {
        case 3:
            std::print("高级 → ");
            [[fallthrough]];
        case 2:
            std::print("中级 → ");
            [[fallthrough]];
        case 1:
            std::print("入门\n");
            break;
        default:
            break;
    }
}
```

输出（留意穿透效果）：

```text
入门
中级 → 入门
高级 → 中级 → 入门
```

switch 的经典暗坑是**隐式穿透**：忘写 `break`，匹配 3 会一路掉进 1——上面这个"级别越高头衔越多"正是主动利用穿透的合法场景。C++17 的 `[[fallthrough]]` 把意图翻到明面上：**想穿透就标注，不标注的穿透编译器直接警告**。新代码规矩：每个 case 结尾要么 `break;` 要么 `[[fallthrough]];`，二选一不许省。

switch 只接受整数/枚举/char 条件——**不能 switch 字符串**（对比 Java/C#）。string 的多路分发用 map（第 10 章）或一串 if；枚举配 switch 是天作之合（第 06 章 `enum class` 会回来）。

## 4.3 经典 for 与 while

```cpp
int sum = 0;
for (int i = 1; i <= 100; ++i) {
    sum += i;
}
// sum = 5050
int n = 1024, steps = 0;
while (n > 1) {
    n /= 2;
    ++steps;
}
// steps = 10：1024 连除 2 十次到 1——对数复杂度的直觉
```

三段式 for（初始化; 条件; 步进）与 while 等价，选用直觉：**次数已知用 for，条件驱动用 while**。`++i` 与 `i++` 对 int 无差别，但迭代器场景前置省一次拷贝——统一写 `++i` 是低成本好习惯。死循环惯用形 `for (;;)`（比 `while (true)` 少一次比较的传说已无意义，纯口味）。循环变量 `i` 的作用域止于循环体——两个循环都声明 `i` 不冲突。

## 4.4 range-for：遍历一切容器

C++11 的高频糖，**能 range-for 就不手写下标**：

```cpp
std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
int odd_count = 0;
for (int v : nums) {
    if (v % 2 == 1) {
        ++odd_count;
    }
}
for (char ch : std::string("C++")) {  // string 也能逐字符
    std::print("[{}] ", ch);          // [C] [+] [+] 
}
```

循环变量有三种接法，选型表：

| 写法 | 语义 | 用于 |
|---|---|---|
| `for (int v : xs)` | 拷贝 | 小类型（int/double/指针） |
| `for (auto& v : xs)` | 可写引用 | 要修改元素 |
| `for (const auto& v : xs)` | 只读引用 | 大对象（string、容器） |

**默认 `const auto&`，要改才 `auto&`，确认小才按值**——这条规则覆盖 90% 场景。range-for 配 ranges 视图（第 12 章）还能再进化一层（带索引的 `enumerate`、惰性过滤）。

## 4.5 break 与 continue

```cpp
int first_odd_gt3 = -1;
for (int v : nums) {
    if (v % 2 == 0) continue;  // 跳过偶数
    if (v > 3) {
        first_odd_gt3 = v;
        break;  // 找到即停：5
    }
}
```

`continue` 跳过本轮进下一轮，`break` 直接出循环。嵌套循环里 **break 只跳一层**——要跨层跳出，惯用法是提函数用 return（比标志位干净），C++ 没有带标签的 break。"找到即停"是 break 的正当场景：线性搜索的后半段不用跑。

## 4.6 运算符与隐式转换的坑

- `==` 与 `=`：`if (x = 0)` 把 x 赋 0 还恒假，/W4 警告（C4706）点名。
- **整数除法** `5 / 2 == 2`（第 03 章坑位回锅）；`%` 取余只用于整数，符号跟被除数（`-7 % 3 == -1`）。
- `&&`/`||` 短路求值：右侧可能不执行，别把副作用放右边。
- 位运算 `& | ^ ~ << >>`：掩码场景用 `()` 包好优先级——`x & 3 == 0` 实际是 `x & (3==0)`，即 `x & 0`，恒 0。经典坑，位运算两侧永远加括号。
- 三元 `cond ? a : b` 是表达式有值：`int m = a > b ? a : b;`，两个分支类型要能统一。

## 4.7 坑位清单

1. **switch 穿透漏 break**：本节开头的头号坑，`[[fallthrough]]` 纪律解决。
2. **range-for 里改容器**：遍历中 push_back/erase 会使迭代器失效（UB）。收集式改法：先遍历记录、后统一修改；过滤用 `std::erase_if`（第 10 章）。
3. **无符号倒序死循环**：`size_t i` 减到 0 再 `--` 回绕成最大值，`i >= 0` 永真。倒序用 `views::reverse`（第 12 章）或迭代器。
4. **浮点相等比较**：`0.1 + 0.2 == 0.3` 是 false（二进制表示误差）。判相等用差值 `< 1e-9` 一类容差。
5. **逗号表达式混入**：`for (i = 0, j = 9; ...)` 的逗号是"顺序求值"不是双变量声明——多变量分别声明。
6. **`v % 2 == 1` 判奇数遇到负数**：`-3 % 2 == -1`，负奇数漏判。判奇用 `v % 2 != 0`。
