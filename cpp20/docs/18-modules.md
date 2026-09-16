# 18 · 编译单元与模块：#include 的接班人

> 对应示例：`examples/18_modules/`（math.ixx + main.cpp）

## 18.1 翻译单元与 ODR：先补地基

第 01 章埋的编译模型在此展开。每个 .cpp 是一个**翻译单元**（TU），预处理→编译→.obj，链接器缝合。这个模型生出 C++ 的两条根本规则：

**声明 vs 定义**——声明说"有这个东西"（`int add(int, int);`），定义说"东西在这"（带函数体）。编译 main.cpp 只需要声明；链接期才去各 .obj 找定义。**头文件就是声明的快递包**：`#include "math.h"` 在预处理期做**纯文本粘贴**，把声明复制进当前 TU。

**ODR（单一定义规则）**——同一个东西在整个程序里：普通函数只能定义一次，类/inline 函数每个 TU 最多一次且**逐字相同**。违反 ODR 的报错发生在链接期（重定义/未定义符号），甚至**静默发生**（两份"应该相同"的头代码有细微差异——最阴险的一类 bug）。

```cpp
// math.h（声明）
int add(int a, int b);
// math.cpp（定义）
#include "math.h"
int add(int a, int b) { return a + b; }
```

## 18.2 include guard 与 inline 的真义

头文件被 include 两次（A.h 与 B.h 都 include 了 common.h）→ 声明重复。声明可以重复，定义不行——于是有了防御：

```cpp
#pragma once                 // 或传统三件套 #ifndef/#define/#endif
```

`inline` 在**定义出现在头文件**时救场：它对编译器的真实含义是"**允许多重定义**（链接期合并）"而非"请内联展开"——现代编译器自己决定内不解内联，inline 只是 ODR 的通行证。头文件里写 `inline int add(...)` 或类内定义的成员函数（隐式 inline），才能被多个 TU 安全 include。

## 18.3 C++20 模块：不是粘贴，是接口

三十年文本粘贴的账终于有人结了。模块（C++20）让编译器真正理解"边界"：

```cpp
// math.ixx —— 模块接口单元
export module math;                 // 模块名：math

export int add(int a, int b) {      // export：对 import 方可见
    return a + b;
}
export int sub(int a, int b) {
    return a - b;
}
export constexpr double pi = 3.14159265358979323846;
```

```cpp
// main.cpp —— 消费方
import math;                        // 不是文本粘贴：语义导入

#include <print>
int main() {
    std::println("math::add(2, 3) = {}", add(2, 3));  // 5
    std::println("math::sub(7, 4) = {}", sub(7, 4));  // 3
    std::println("math::pi = {:.5f}", pi);            // 3.14159
}
```

三件套：`export module 名字;` 开接口单元；`export` 标记要导出的声明（**没标 export 的名字对外真不可见**——比头文件的"都能看见"安全一档）；`import math;` 消费。与 include 的本质差异：

| | `#include` | `import` |
|---|---|---|
| 机制 | 预处理**文本粘贴** | 编译器**语义导入** |
| 未导出的辅助函数 | 会被顺带看见（宏污染、名字泄漏） | 真私有 |
| 同一模块被 N 个 TU 导入 | N 次重复解析 | **一次构建、到处复用** |
| 顺序敏感 | 是（宏先定义才生效） | 否 |
| 工具链支持 | 到处都是 | **尚在铺开**（MSVC 最成熟） |

## 18.4 编译流程：为什么 build.ps1 要特判 .ixx

模块的二进制中间格式（.ifc）让编译流程多一步——本教程示例的实际编译命令（build.ps1 内置，手敲长这样）：

```bash
# ① 编译模块接口：产出 math.obj + math.ifc（接口的二进制描述）
cl /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 ^
   /interface /c /Fo:build\18_modules_math.obj /ifcOutput build\18_modules_math.ifc math.ixx

# ② 编译消费方：/reference 指着 ifc，链接 math.obj
cl /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 ^
   /Fe:build\18_modules.exe /c /Fo:build\18_modules_main.obj ^
   /reference math=build\18_modules_math.ifc main.cpp
cl /Fe:build\18_modules.exe build\18_modules_main.obj build\18_modules_math.obj
```

两个实测经验（都踩过坑写进 build.ps1）：**`/reference` 必须空格分隔**（`/reference math=文件`——冒号连写形式 `"/reference:math=…"` 会被误读为"命名分区"触发 C5213）；`/ifcOutput` 指定 .ifc 的落点（默认跟 obj 走，显式写最稳）。所以 build.ps1 对含 .ixx 的目录做两步编译——示例跑通即证明该链路可用。

模块还分**接口单元**（.ixx，export 所在）与**实现单元**（`module math;` 开头的 .cpp，只实现不导出）、**分区**（`module math.core;`）——教程规模用不到，认得名词即可。`import std;`（标准库整体当模块）是 C++23 的方向，但需要额外构建 std 模块，本教程继续 `#include` 标准库头。

## 18.5 静态库/动态库：链接层的另一维度

多文件组织之外，代码还能按**产物形态**切分：静态库（.lib，链接期整块拷进 exe）与动态库（.dll，运行期加载、多个 exe 共享一份）。模块/头文件是**源码层**的事，lib/dll 是**产物层**的事——两套正交概念，别混淆。日常接触：第三方发你 `.h + .lib`（静态）或 `.h + .lib + .dll`（动态）。深入见第 23 章工具链。

## 18.6 坑位清单

1. **.ixx 没用 /interface 编译**：普通方式编 .ixx 会当成不明文件——找不到模块/接口不产出。模块单元必须走 `/interface`。
2. **模块名与文件名对不上**：build 脚本按"文件名=模块名"约定传 /reference——改名要两边一起改（或显式声明映射）。
3. **import 与 include 混排的顺序**：`import` 必须在"全局模块片段"（`module;` 之后）之外、且位于非预处理指令区——过渡期代码常见 `#include` 与 `import` 混用，紧跟 `module;` 的 include 才合法。
4. **头文件里 using namespace**：模块时代之前的经典灾难——污染所有 include 者。任何组织形式下都别这么写。
5. **忘了 #pragma once**：头文件被多路径 include → 重定义。新头文件第一行就是它。
6. **模块与宏**：宏不穿透模块边界（这是特性），指望"import 之后能用对方宏"的代码要重构。
