# 27 · 预处理器与翻译单元：宏、ODR、链接性与头文件

> 对应示例：`examples/27_preproc/`（main.cpp + util.h + util.cpp 三个文件）

第 26 章讲了 C++20 模块这个"接班人"；本章补上它接的是谁的班——`#include` 时代的全套机制。**就算新代码全用模块，存量代码里你天天读的就是这些东西**；而且预处理器在模块时代也还活着（条件编译、特性探测）。

## 27.1 三阶段：预处理 → 编译 → 链接

源文件（.cpp）先由**预处理器**处理所有 `#` 开头的指令、展开宏，产物叫**翻译单元**（translation unit）；编译器把每个翻译单元独立编成目标文件（.obj/.o）；**链接器**把所有目标文件缝成 exe，找不到实现就报 `无法解析的外部符号`。两个直接后果（第 01 章的回声）：

1. **声明与定义分离**：编译 main.cpp 只需要函数的声明（签名），定义可以在别的翻译单元，链接期对接；
2. **每个翻译单元各自预处理**——`#include` 是**文本粘贴**，同一个头文件被包含 100 次就粘贴 100 次（下面 `<cmath>` 的数据：一次包含 ≈ 6000 行注入）。

## 27.2 宏：文本替换的三宗罪

```cpp
#define APP_NAME "guide"          // 对象式宏：标识符 → 文本
#define STR(x) #x                 // 函数式宏：# 把实参原样字符串化（不求值）
#define CAT(a, b) a##b            // ## 把两个 token 粘成一个
int CAT(my_, rank) = 9;           // 生成变量 my_rank
```

宏是"盲文本替换"：**没有类型、不守作用域、不懂 C++ 语法**。`#define PI 3.1415` 之后，代码里任何叫 PI 的东西（包括你写的变量名）都会被换掉；函数式宏 `MAX(a,b)` 的参数**出现几次就替换几次**（副作用double执行），还自带优先级炸弹（`MAX(x,y)*2` 展开成灾难）。三宗罪的解药全部是现代 C++ 特性：

| 宏的用法 | 现代替代 |
|---|---|
| `#define PI 3.14` | `constexpr double PI`（有类型、守作用域） |
| `#define MAX(a,b)` | 函数模板（类型安全、参数只求值一次） |
| `#define SHOW_TRACE 1` | 无法替代——条件编译是宏的正经领地 |

**`#include <Windows.h>` 后 `std::max(0, v)` 编译报错**就是这个家族的名场面：Windows 头文件定义了 `min`/`max` 宏，把 `std::max(...)` 替换成乱码——解药：包含前 `#define NOMINMAX`，或包含后 `#undef min` / `#undef max`。

## 27.3 条件编译与特性探测

```cpp
#ifdef SHOW_TRACE
#define TRACE(msg) std::println("[trace] {}", msg)
#else
#define TRACE(msg) ((void)0)
#endif
#if __has_include(<version>)          // 探测头文件存不存在
#ifdef __cpp_lib_ranges               // 特性测试宏：探测库特性及其版本
static_assert(sizeof(void*) >= 8, "需要 64 位平台");
```

`#if/#ifdef/#elif/#else/#endif` 让"某段代码编不编"由宏决定——未选中的分支**编译器根本看不见**（所以里面可以放当前编译器编不过的代码，只要条件不满足）。正经用途两大家：

- **配置开关**（NDEBUG、SHOW_TRACE）：一份源码出多个版本；`#error` 能在配错时直接叫停构建；
- **特性探测**：`__has_include(<header>)` 问头文件在不在；`__cpp_lib_*`（`<version>` 里约 200 个）/ `__cpp_*`（语言特性，约 70 个）问特性到没到——**值是"年月"数字**（`__cpp_lib_ranges = 202406`）。第 28/29/30 章示例里的 `__has_include(<generator>)` 探测就是这个用法。

预定义宏顺手认：`__LINE__`/`__FILE__`/`__func__`（现代替代 `std::source_location`，能拿列号还能存值）、`__cplusplus`（标准版本号，配 `/Zc:__cplusplus` 才如实）。**宏不被模块导出**——`import std;` 拿不到宏，要 `#include <cassert>` 或 `import <cassert>;`（头文件单元）。

## 27.4 ODR：一处定义规则

ODR 是两句话：**同一翻译单元内**，变量/函数/类/模板最多定义一次（声明随意重复）；**整个程序内**，普通函数和变量仍然只能定义一次——跨单元重定义是**链接期**错误（`pow 已在 util.obj 中定义`）。两个翻车现场：

```cpp
// ExA_06 风格：同文件两个 power() 定义 → 编译错（编译器不知道编哪份）
// ExA_08 风格：两个文件各定义 int visits; → 链接错（int visits; 是定义不是声明！）
extern int visits;    // ✔ 声明“定义在别处”——这才是跨单元引用变量的正写
```

**全局变量不带 extern 的"声明"其实是定义**（还会零初始化）——跨单元共享变量时，一个 .cpp 里定义、头文件里 `extern` 声明。三类"例外"允许每个用到的翻译单元各有一份定义（但必须逐字相同）：**inline 函数/变量、类/枚举定义、模板**——这正是头文件能放它们的原因。

## 27.5 链接性：名字归谁

| 链接性 | 意思 | 怎么来 |
|---|---|---|
| **外部** | 全程序可见 | 函数、非 const 全局变量默认；`extern` 强制 |
| **内部** | 只在本翻译单元 | `static` 函数/变量；**const 全局变量默认**；匿名命名空间 |
| 无 | 只在本作用域 | 局部变量 |

```cpp
static int checksum(int v) { … }     // 内部链接：只属于 util.cpp
namespace { int local_bonus = 5; }   // 匿名命名空间：现代 C++ 的“内部链接”首选
extern int visits;                   // 外部：定义在 util.cpp，别处可用
```

**const 全局变量默认内部链接**（每个单元一份自己的副本——想跨单元共享常量：头文件里 `inline constexpr`）；辅助函数加 `static`（或关进匿名命名空间）后，**每个翻译单元都能有自己的 `helper()` 互不冲突**——不然全程序的局部助手函数都得取唯一名。命名空间（第 26 章）管"名字的姓氏"，链接性管"名字的可见范围"，两者正交；模块里未导出的实体自动获得**模块链接**（模块内可见）——这正是模块化代码极少踩 ODR 的原因。

## 27.6 头文件的组织法（非模块时代）

```cpp
// util.h
#ifndef GUIDE_UTIL_H          // include guard：同一翻译单元二次包含只生效一次
#define GUIDE_UTIL_H
inline constexpr int k_max_retry = 3;    // 常量：inline constexpr（每个单元同一定义）
inline int twice(int x) { return 2*x; }  // 函数定义进头文件必须 inline
int shared_hits();                        // 普通函数：声明进头文件
extern int visits;                        // 变量：extern 声明，定义留 .cpp
#endif
```

`#include "util.h"`（引号：先找当前目录）与 `#include <cmath>`（尖括号：只找系统/配置的目录）的区别只在搜索路径。头文件的**军规**：声明进 .h、定义留 .cpp；要放定义只能放 inline/类/模板；**每个头文件都要 include guard**（`#ifndef/#define/#endif` 三连，或主流但不标准的 `#pragma once`）——没有它，"A.h 与 B.h 都包含 C.h、main 又同时包含 A/B" 的菱形包含立刻 ODR 爆炸。示例 main.cpp 故意 `#include "util.h"` 两次，guard 让它安然无恙。类模板/函数模板**必须**把完整定义给调用方可见——所以模板天生住头文件（第 20 章坑位的病根）。

## 27.7 模块为什么是接班人

对照一遍：`#include` 文本粘贴（同一头注入每个单元，`<cmath>` 一次约 6000 行）vs `import` 二进制接口（编一次、处处复用，还带 export 权限控制）；头文件 ODR 军规（inline、guard、声明定义分离全靠纪律）vs 模块天然单定义；宏污染全局 vs 模块**不导出宏**。新代码用模块（第 26 章），读旧代码靠本章——两边的语言其实都还活着。

## 27.8 坑位清单

1. **宏当常量/函数用**：无类型、无作用域、参数重复求值——constexpr 与模板全面替代。
2. **`int visits;` 当"声明"**：它是定义——跨单元引用写 `extern int visits;`，定义放一个 .cpp。
3. **const 全局想跨单元共享**：默认内部链接，每个单元一份——共享就 `inline constexpr` 进头文件。
4. **头文件里放非 inline 定义**：两个单元都包含 → 链接期重定义。函数加 inline，或挪进 .cpp。
5. **头文件忘 guard**：菱形包含 → 二次定义编译错——每个头文件都写（含第三方风格统一）。
6. **NDEBUG 的 assert 消失**：`assert(pop())` 在 Release 里不弹——assert 只放纯判断（第 10 章回锅）。
7. **Windows.h 的 min/max 宏炸掉 std::max**：`#define NOMINMAX` 或事后 `#undef`。
8. **模板定义藏在 .cpp**：调用方看不见定义 → 链接错——模板住头文件（或显式实例化，进阶）。
