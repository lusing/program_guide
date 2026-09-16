# C++20/23 教程重写实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `cpp20/` 从"2467 行单文件特性手册 + 不参与编译的 snippets + 编号混乱的 examples"重写为 24 章从零教学的 C++ 教程（docs/ 分章 + 章号=示例目录 + 迷你 grep 实战），全部示例 MSVC 编译零告警 + 运行自检通过。

**Architecture:** 读者定位"会编程、初学 C++"，C++20/23 为主线标准；每章 150–250 行（用户明确要求内容厚实不压缩）、`examples/NN_name/main.cpp` 一目录一示例（18/24 多文件）；三层验证（编译零告警 + 运行 exit 0 + assert 自检）；旧 snippets/examples 吸收后删除；build.ps1 重写为 pwsh 7 目录式遍历 + 模块特判（.ixx 两步编译）。

**Tech Stack:** MSVC `cl /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`（VS 2026 工具集 14.51.36231）、C++23 标准库（print/expected/generator/mdspan/flat_map 等已实测可用）、PowerShell 7、Markdown。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-17-cpp20-tutorial-rewrite-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\cpp20`（bash 路径 `/g/code/guide/cpp20`）；仓库根 `G:\code\guide`。
- vcvars：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`。
  调用阶段的 `vswhere.exe 不是内部或外部命令` 警告**无害，忽略**。
- **编译参数铁律**（所有示例、文档中的编译命令一律用这套）：

  ```
  cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4
  ```

- **零告警规则**：/W4 下不允许任何 warning。未用参数用 `[[maybe_unused]]`；未用局部变量
  删掉或用起来；`size_t`/`int` 混算用显式 `static_cast`；**禁用 `fopen` 等 CRT 旧函数**
  （会触发 C4996）。
- **示例分节注释约定**：`// ═══ N.M 小节名 ═══`，N=章号、M 与本章文档小节号一致
  （docs 按小节号逐字摘录示例代码）。
- **示例自检约定**：输出确定性文本（线程示例须 join 完再打印汇总）；关键行为用
  `assert(...)`；结尾打印一句"自检通过"或等价汇总；不读 stdin；正常返回 0。
- **C++23 已核实事实**（2026-09-17 本机实测，执行者不得凭记忆改动）：

  | 特性 | 结论 |
  |---|---|
  | `std::print`/`std::println`（`<print>`） | ✅ |
  | `std::expected`（`<expected>`，含 `and_then`/`or_else`/`transform` 单子操作） | ✅ |
  | `std::generator`（`<generator>`） | ✅ |
  | `std::mdspan`（`<mdspan>`） | ✅，访问语法是 **`m[i, j]`**（没有 `m(i,j)`——那是 Kokkos 旧接口） |
  | `std::flat_map`（`<flat_map>`） | ✅ 有序（首键 a） |
  | `std::views::enumerate`、`std::ranges::to`、`std::string::contains` | ✅ |
  | deducing this（显式对象形参） | ✅ |
  | `std::stacktrace::current()`（`<stacktrace>`） | ✅ |
  | C++20 模块 | ✅ 两步编译：`cl /interface /c math.ixx` → `cl main.cpp math.obj`（同目录实测通过） |
  | 工具集 | 14.51.36231（VS 2026），`_MSVC_STL_UPDATE` 路径 `VC\Tools\MSVC\14.51.36231` |

- **章节写作模板**（每章必须遵守）：
  - 文件名 `NN-kebab-case.md`；首行 `# NN · 主题：副标题`；第二行
    `> 对应示例：examples/NN_name/`（01 章无此行，引用 `examples/02_hello/`）。
  - `## N.M` 编号小节；先讲"解决什么问题"再讲语法；对比用表格；结尾 `## 坑位清单`。
  - 代码片段与 examples 逐字一致（省略处标 `// …`）；每章 150–250 行；中文行文；
    C++23 特性处标注"（C++23）"。
  - 风格范本（每章动笔前先读）：`G:\code\guide\dotnet\docs\09-linq.md`（心智模型 +
    坑位清单写法）与 `G:\code\guide\dotnet\docs\03-types.md`。
  - 交叉引用格式：`[Win32 教程](../win32/README.md)`、`[boost 教程](../boost/README.md)`
    等；只链接、不重讲。
- **单示例手工调试命令**（写代码阶段快速迭代用；正式验证一律走 build.ps1）：

  ```bash
  cd /g/code/guide/cpp20/examples/03_types
  cat > /tmp/cc.bat << 'EOF'
  @echo off
  call "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
  cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 /Fe:demo.exe main.cpp
  EOF
  cmd //c "$(cygpath -w /tmp/cc.bat)" && ./demo.exe && rm -f demo.exe demo.obj
  ```

- build.ps1 验证命令（pwsh 7 必需，脚本无 BOM）：

  ```bash
  cd /g/code/guide/cpp20 && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  单示例：`... -Example 06_compound`；清理：`... -Clean`。
- 提交规范：`feat(cpp20):` / `docs(cpp20):` / `chore(cpp20):` 前缀 + 中文，结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- 每个 Task 结束时 `git status` 干净。**旧 `snippets/`、旧 `examples/*.cpp` 平文件、
  旧 README.md 在 Task 16 前一律保留**（docs 写作要从中吸收素材；build.ps1 只遍历
  examples 下的**目录**，与旧平文件互不干扰）。

---

### Task 1: build.ps1 重写（目录式示例 + 三层验证 + 模块特判）

**Files:**
- Modify: `build.ps1`（整体重写）

**Interfaces:**
- Produces: `-All` 全量流程（Task 9/17 终验依赖）：逐目录示例 编译（零告警目标）→ 运行 exe → 退出码 0 即过；`-Example <name>` 单示例全流程；`-Clean` 清根 build/。模块特判：目录含 `*.ixx` → 先 `/interface /c` 编成 `build/<示例名>_<模块名>.obj` + `/ifcOutput` 指定 .ifc，再编译 main.cpp 时带 `/reference:<模块名>=<ifc>` 并链接 .obj。

- [ ] **Step 1: 重写 build.ps1 全文**（保持无 BOM、UTF-8）

```powershell
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vcvars = "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "未找到 vcvars64.bat，请检查 VC 安装路径。"
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$commonFlags = "/nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4"

function Invoke-Cl {
    param([string[]]$ClArgs)
    $cmd = ('call "{0}" >nul && cl {1}' -f $vcvars, ($ClArgs -join ' '))
    & $env:ComSpec /c $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: cl $($ClArgs -join ' ')"
    }
}

function Invoke-Example {
    param([Parameter(Mandatory = $true)][string]$DirPath)

    $name = Split-Path -Leaf $DirPath
    $mainCpp = Join-Path $DirPath "main.cpp"
    if (-not (Test-Path -LiteralPath $mainCpp)) {
        throw "示例缺 main.cpp: $DirPath"
    }

    Write-Host "===== $name =====" -ForegroundColor Magenta

    # 编译 ①：模块接口（.ixx → .obj + .ifc）
    $linkArgs = @()
    $ixxFiles = @(Get-ChildItem -LiteralPath $DirPath -Filter "*.ixx" | Sort-Object Name)
    foreach ($m in $ixxFiles) {
        $module = $m.BaseName
        $obj = Join-Path $buildDir ($name + "_" + $module + ".obj")
        $ifc = [System.IO.Path]::ChangeExtension($obj, ".ifc")
        Write-Host "[Module] $($m.Name)" -ForegroundColor Cyan
        Invoke-Cl @($commonFlags, "/interface", "/c", "/Fo`"$obj`"", "/ifcOutput`"$ifc`"", "`"$($m.FullName)`"")
        $linkArgs += "/reference:$module=`"$ifc`""
        $linkArgs += "`"$obj`""
    }

    # 编译 ②：main.cpp（链接模块 obj）
    Write-Host "[Compile] $name" -ForegroundColor Cyan
    $obj = Join-Path $buildDir ($name + ".obj")
    $exe = Join-Path $buildDir ($name + ".exe")
    Invoke-Cl (@($commonFlags, "/Fo`"$obj`"", "/Fe`"$exe`"", "`"$mainCpp`"") + $linkArgs)

    # 运行：退出码 0 即通过（示例内置 assert 自检）
    Write-Host "[Run] $name" -ForegroundColor Cyan
    & $exe
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败（退出码 $LASTEXITCODE）：$name"
    }
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "找不到示例目录: $dir"
    }
    Invoke-Example -DirPath $dir
    Write-Host "[Done] 验证通过: $Example" -ForegroundColor Green
    exit 0
}

if ($All) {
    $dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name)
    if ($dirs.Count -eq 0) {
        throw "examples 目录下没有示例目录。"
    }
    foreach ($d in $dirs) {
        Invoke-Example -DirPath $d.FullName
    }
    Write-Host "[Done] 全部 $($dirs.Count) 个示例编译+运行通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                 全量：逐示例编译（零告警）+ 运行自检"
Write-Host "  .\build.ps1 -Example 06_compound 单示例编译+运行"
Write-Host "  .\build.ps1 -Clean               清理 build 目录"
```

- [ ] **Step 2: 烟测脚本**

```bash
cd /g/code/guide/cpp20
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean
```

预期：无参数打印用法；`-Clean` 打印"[Clean]"后退出 0。（examples 下暂无目录，`-All`
会 throw 属预期，Task 2 起消失。）

- [ ] **Step 3: Commit**

```bash
git add build.ps1 && git commit -m "feat(cpp20): 新 build.ps1 目录式三层验证（编译零告警+运行+模块特判）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 示例 02_hello / 03_types / 04_control

**Files:**
- Create: `examples/02_hello/main.cpp`
- Create: `examples/03_types/main.cpp`
- Create: `examples/04_control/main.cpp`

**Interfaces:**
- Produces: 第 02/03/04 章引用代码（docs 按小节注释号摘录）；02_hello 为 01 章引用对象。

- [ ] **Step 1: 写 examples/02_hello/main.cpp**

```cpp
#include <iostream>
#include <print>

// 02 第一个程序：main、std::print 与 iostream
int main() {
    // ═══ 2.1 最小的程序：main 与返回值 ═══
    std::println("你好，C++23！");  // println 自动换行

    // ═══ 2.2 std::print / std::println：占位符格式化 ═══
    std::print("姓名：{}，年龄：{}\n", "阿 C", 25);
    std::print("编号 {:03}，PI ≈ {:.2f}\n", 7, 3.14159);
    std::print("{:*^24}\n", "居中标题");  // 填充对齐

    // ═══ 2.3 老朋友 iostream：<< 链式输出 ═══
    std::cout << "iostream 也能输出："
              << "int " << 42 << "，double " << 3.14 << "\n";

    // ═══ 2.4 退出码：0 表示成功 ═══
    return 0;  // 脚本/CI 按退出码判断成败
}
```

- [ ] **Step 2: 写 examples/03_types/main.cpp**

```cpp
#include <cstdint>
#include <numbers>
#include <print>

// 03 类型与变量：基本类型、字面量、auto、初始化、constexpr
int main() {
    // ═══ 3.1 基本类型与固定宽度整数 ═══
    int pages = 420;
    double price = 89.5;
    char grade = 'A';
    bool published = true;
    std::print("int {} 字节，double {} 字节，char {} 字节\n",
               sizeof(int), sizeof(double), sizeof(char));
    std::int32_t exact = 1'000'000;      // 固定宽度：不猜平台
    std::int64_t big = 9'000'000'000LL;  // LL 后缀：字面量也得是 64 位
    std::print("pages={} price={} grade={} published={} exact={} big={}\n",
               pages, price, grade, published, exact, big);

    // ═══ 3.2 整数字面量：进制与分隔符 ═══
    auto bin = 0b1010;  // 二进制 10
    auto hex = 0xFF;    // 十六进制 255
    auto grouped = 1'234'567;
    std::print("bin={} hex={} grouped={}\n", bin, hex, grouped);

    // ═══ 3.3 auto：让编译器推导 ═══
    auto count = 42;   // int
    auto ratio = 0.5;  // double（不是 float！）
    auto letter = 'Z'; // char
    std::print("{} {} {}\n", count, ratio, letter);

    // ═══ 3.4 初始化三种写法与 narrowing ═══
    int a = 10;    // 拷贝初始化
    int b(10);     // 直接初始化
    int c{10};     // 列表初始化：不允许窄化
    double d = 3;  // 隐式转换：可以，但 {} 会拦
    // int bad{3.14};  // 编译错误：double → int 是 narrowing——{} 帮你把关
    std::print("{} {} {} {}\n", a, b, c, d);

    // ═══ 3.5 constexpr：编译期就定下来的值 ═══
    constexpr double tau = 2.0 * std::numbers::pi;  // <numbers> (C++20)
    constexpr int months = 12;
    int weekly[months]{};  // C 数组长度须是编译期常量（数组详见第 06 章）
    weekly[0] = 1;
    static_assert(months == 12);  // 编译期断言：免费的单测

    std::print("tau≈{:.4f}，首周 {}\n", tau, weekly[0]);
    std::println("自检通过");
}
```

- [ ] **Step 3: 写 examples/04_control/main.cpp**

```cpp
#include <cassert>
#include <print>
#include <string>
#include <vector>

// 04 表达式与控制流：if/switch/循环/range-for
int main() {
    // ═══ 4.1 if 与初始化语句 ═══
    std::string lang = "现代 C++";
    if (auto pos = lang.find("C++"); pos != std::string::npos) {
        std::print("找到子串，位置 {}\n", pos);
    } else {
        std::print("没找到\n");
    }

    // ═══ 4.2 switch：fallthrough 必须显式 [[fallthrough]] ═══
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

    // ═══ 4.3 经典 for 与 while ═══
    int sum = 0;
    for (int i = 1; i <= 100; ++i) {
        sum += i;
    }
    int n = 1024, steps = 0;
    while (n > 1) {
        n /= 2;
        ++steps;
    }

    // ═══ 4.4 range-for：遍历一切容器 ═══
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
    int odd_count = 0;
    for (int v : nums) {
        if (v % 2 == 1) {
            ++odd_count;
        }
    }
    for (char ch : std::string("C++")) {  // string 也能逐字符
        std::print("[{}] ", ch);
    }
    std::println("");

    // ═══ 4.5 break 与 continue ═══
    int first_odd_gt3 = -1;
    for (int v : nums) {
        if (v % 2 == 0) continue;  // 跳过偶数
        if (v > 3) {
            first_odd_gt3 = v;
            break;  // 找到即停
        }
    }

    // ═══ 4.6 自检 ═══
    std::print("sum={} steps={} odd_count={} first_odd_gt3={}\n",
               sum, steps, odd_count, first_odd_gt3);
    assert(sum == 5050 && steps == 10);
    assert(odd_count == 5 && first_odd_gt3 == 5);
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 03_types
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 04_control
```

预期：三例各 `[Compile]` → `[Run]` → 中文输出正常（pwsh 已设 UTF-8）→ `[Done]`；零 warning。
04 输出 `sum=5050 steps=10 odd_count=5 first_odd_gt3=5` + "自检通过"。

```bash
git add examples/02_hello examples/03_types examples/04_control
git commit -m "feat(cpp20): 示例 02_hello/03_types/04_control

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 示例 05_functions / 06_compound / 07_errors

**Files:**
- Create: `examples/05_functions/main.cpp`
- Create: `examples/06_compound/main.cpp`
- Create: `examples/07_errors/main.cpp`

**Interfaces:**
- Produces: 第 05/06/07 章引用代码。

- [ ] **Step 1: 写 examples/05_functions/main.cpp**

```cpp
#include <print>
#include <string>
#include <vector>

// 05 函数：参数传递、重载、默认实参、lambda

// ═══ 5.1 值传递：拿到的是副本，改不动原件 ═══
void double_it(int x) {
    x *= 2;
}

// ═══ 5.2 引用传递：真的改原件 ═══
void double_ref(int& x) {
    x *= 2;
}

// ═══ 5.3 const 引用：只读 + 不拷贝（大对象标配）═══
int total_length(const std::vector<std::string>& words) {
    int total = 0;
    for (const auto& w : words) {
        total += static_cast<int>(w.size());
    }
    return total;
}

// ═══ 5.4 默认实参与重载 ═══
void greet(const std::string& name, const std::string& greeting = "你好") {
    std::println("{}，{}！", greeting, name);
}
int twice(int v) { return v * 2; }
double twice(double v) { return v * 2; }  // 重载：同名不同参

// ═══ 5.5 [[nodiscard]]：返回值不许扔 ═══
[[nodiscard]] int square(int v) {
    return v * v;
}

int main() {
    int v = 21;
    double_it(v);   // 副本被翻倍，v 纹丝不动
    double_ref(v);  // 引用：v 真的变了
    std::println("v = {}", v);  // 42

    std::vector<std::string> words{"现代", "C++", "教程"};
    std::println("总字符数 = {}", total_length(words));

    greet("阿 C");            // 用默认问候
    greet("World", "Hello");  // 覆盖默认
    std::println("{} {}", twice(21), twice(1.5));

    // ═══ 5.6 lambda：就地写函数对象 ═══
    auto add = [](int a, int b) { return a + b; };
    int factor = 3;
    auto scale = [factor](int x) { return x * factor; };  // 按值捕获外部变量
    std::println("{} {}", add(2, 3), scale(7));

    std::println("square(9) = {}", square(9));  // 丢弃返回值会有 C4834 警告
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/06_compound/main.cpp**

```cpp
#include <array>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <vector>

// 06 复合类型：struct、enum class、string、string_view、span

// ═══ 6.1 struct：把相关数据打包 ═══
struct Book {
    std::string title;
    double price;
    int pages;
};

// ═══ 6.3 enum class：带作用域的枚举 ═══
enum class Format { paperback, hardcover, ebook };

// ═══ 6.6 span 求和工具：数组/vector 通吃 ═══
int sum_of(std::span<const int> values) {
    int total = 0;
    for (int v : values) {
        total += v;
    }
    return total;
}

int main() {
    // 6.1 指定初始化器 (C++20)：字段必须按声明顺序
    Book b{
        .title = "现代 C++ 实战",
        .price = 89.5,
        .pages = 420,
    };

    // ═══ 6.2 结构化绑定：一把拆出成员 ═══
    auto [title, price, pages] = b;
    std::println("{} / {:.1f} 元 / {} 页", title, price, pages);

    // 6.3 必须带作用域名访问
    Format f = Format::hardcover;
    std::println("格式编号 = {}", static_cast<int>(f));

    // ═══ 6.4 std::string：可变字符串 ═══
    std::string s = "C++";
    s += "20";
    s.push_back('!');
    std::println("{}（长度 {}）", s, s.size());
    std::println("包含 '20'？{}", s.contains("20"));  // contains (C++23)

    // ═══ 6.5 string_view：不拥有字符串的只读视图 ═══
    std::string_view sv = s;
    std::println("sv 前 4 个字符：{}", sv.substr(0, 4));

    // ═══ 6.6 span：一段内存的视图（C++20）═══
    std::array<int, 5> arr{1, 2, 3, 4, 5};
    std::vector<int> vec{10, 20, 30};
    std::println("sum(arr) = {}，sum(vec) = {}", sum_of(arr), sum_of(vec));
    std::span<int> middle = std::span{arr}.subspan(1, 3);  // 第 2–4 个
    middle[0] = 99;  // 非 const span 可写穿
    std::println("改写后 arr[1] = {}", arr[1]);
    std::println("自检通过");
}
```

- [ ] **Step 3: 写 examples/07_errors/main.cpp**

```cpp
#include <cassert>
#include <charconv>
#include <expected>
#include <optional>
#include <print>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

// 07 错误处理：异常、optional、expected、断言

// ═══ 7.1 异常：留给"真正的意外" ═══
double safe_divide(double a, double b) {
    if (b == 0.0) {
        throw std::invalid_argument("除数为零");
    }
    return a / b;
}

// ═══ 7.2 optional："可能没有"放进类型 ═══
std::optional<int> first_even(const std::vector<int>& xs) {
    for (int v : xs) {
        if (v % 2 == 0) {
            return v;
        }
    }
    return std::nullopt;  // 明确的"没有"
}

// ═══ 7.3 expected<T, E>："值或错误"都在类型里 (C++23) ═══
std::expected<int, std::string> parse_int(std::string_view text) {
    int value = 0;
    auto [ptr, ec] = std::from_chars(text.data(), text.data() + text.size(), value);
    if (ec != std::errc{} || ptr != text.data() + text.size()) {
        return std::unexpected("不是合法整数: " + std::string(text));
    }
    return value;
}

// ═══ 7.4 链式组合：monadic 风格，不抛不嵌套 (C++23) ═══
std::expected<double, std::string> parse_ratio(std::string_view a, std::string_view b) {
    return parse_int(a).and_then([b](int x) {
        return parse_int(b).and_then([x](int y) -> std::expected<double, std::string> {
            if (y == 0) {
                return std::unexpected("除数为零");
            }
            return static_cast<double>(x) / y;
        });
    });
}

int main() {
    // 异常：catch 住看信息
    try {
        std::println("10 / 3 = {}", safe_divide(10, 3));
        std::println("10 / 0 = {}", safe_divide(10, 0));  // 抛！
    } catch (const std::exception& e) {
        std::println("捕获异常：{}", e.what());
    }

    // optional：has_value / value_or
    std::vector<int> xs{3, 7, 8, 5};
    std::println("第一个偶数 = {}", first_even(xs).value_or(-1));
    std::println("空表兜底 = {}", first_even({}).value_or(-1));

    // expected：成功与失败两条路
    auto ok = parse_int("42");
    auto bad = parse_int("4x");
    std::println("parse(42) = {}", ok.value());
    if (!bad) {
        std::println("parse(4x) 失败：{}", bad.error());
    }

    // 链式组合
    auto r1 = parse_ratio("10", "4");
    auto r2 = parse_ratio("10", "0");
    auto r3 = parse_ratio("1o", "4");
    std::println("ratio(10,4) = {}", r1.value());  // 2.5
    std::println("ratio(10,0) 失败：{}", r2.error());
    std::println("ratio(1o,4) 失败：{}", r3.error());
    assert(r1.value() == 2.5);

    // ═══ 7.5 断言：开发期抓 bug 的地板 ═══
    int amount = 100;
    assert(amount > 0 && "金额必须为正");  // Release (NDEBUG) 下会被编译掉
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
for e in 05_functions 06_compound 07_errors; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：三例零告警通过；07 输出含 `捕获异常：除数为零`、`ratio(10,4) = 2.5`、"自检通过"。

```bash
git add examples/05_functions examples/06_compound examples/07_errors
git commit -m "feat(cpp20): 示例 05_functions/06_compound/07_errors

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 示例 08_classes / 09_smartptr / 10_containers

**Files:**
- Create: `examples/08_classes/main.cpp`
- Create: `examples/09_smartptr/main.cpp`
- Create: `examples/10_containers/main.cpp`

**Interfaces:**
- Produces: 第 08/09/10 章引用代码。

- [ ] **Step 1: 写 examples/08_classes/main.cpp**

```cpp
#include <cmath>
#include <compare>
#include <print>
#include <string>

// 08 类与 RAII：封装、构造析构、三路比较、运算符

class Vec2 {
public:
    Vec2(double x, double y) : x_{x}, y_{y} {}

    // ═══ 8.2 const 成员函数：只读接口 ═══
    double x() const { return x_; }
    double y() const { return y_; }
    double length() const { return std::sqrt(x_ * x_ + y_ * y_); }

    // ═══ 8.4 运算符重载：让类像内建类型 ═══
    Vec2 operator+(const Vec2& rhs) const { return {x_ + rhs.x_, y_ + rhs.y_}; }
    Vec2 operator*(double k) const { return {x_ * k, y_ * k}; }
    bool operator==(const Vec2&) const = default;  // C++20：默认相等

    // ═══ 8.5 三路比较 <=> (C++20)：一次定义全部关系 ═══
    std::partial_ordering operator<=>(const Vec2& o) const {
        if (auto c = x_ <=> o.x_; c != 0) {
            return c;
        }
        return y_ <=> o.y_;
    }

    // ═══ 8.7 deducing this (C++23)：显式对象形参 ═══
    Vec2& negate(this Vec2& self) {
        self.x_ = -self.x_;
        self.y_ = -self.y_;
        return self;
    }

private:
    double x_;
    double y_;
};

// ═══ 8.3 RAII：资源获取即初始化——析构就是"自动还" ═══
class Session {
public:
    explicit Session(std::string name) : name_{std::move(name)} {
        std::println("[{}] 进入会话", name_);
    }
    ~Session() {  // 作用域结束自动调用——异常也拦不住它
        std::println("[{}] 离开会话", name_);
    }
    Session(const Session&) = delete;  // 拷贝/移动见第 15 章
    Session& operator=(const Session&) = delete;

private:
    std::string name_;
};

// ═══ 8.6 inline 静态成员：类内直接初始化 ═══
class Counter {
public:
    static int next() { return ++count_; }

private:
    inline static int count_ = 0;  // C++17 起：不再需要类外定义
};

int main() {
    // ═══ 8.1 构造、成员访问 ═══
    Vec2 a{3.0, 4.0};
    Vec2 b{1.0, 1.0};
    Vec2 c = a + b;  // (4, 5)
    std::println("c = ({}, {})，|c| = {:.3f}", c.x(), c.y(), c.length());
    std::println("c * 2 = ({}, {})", (c * 2).x(), (c * 2).y());

    // 比较：== 与 <=> 都能用
    std::println("a == b? {}", a == b);
    std::println("a > b? {}", (a <=> b) > 0);

    // RAII：块结束自动清理（逆序析构）
    {
        Session s1{"外层"};
        {
            Session s2{"内层"};
            std::println("  工作中……");
        }  // s2 先析构
    }  // s1 后析构

    // 静态成员计数
    std::println("Counter: {} {} {}", Counter::next(), Counter::next(), Counter::next());

    // deducing this：显式对象形参
    Vec2 d = c;
    d.negate();
    std::println("d = ({}, {})", d.x(), d.y());
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/09_smartptr/main.cpp**

```cpp
#include <memory>
#include <print>
#include <string>
#include <vector>

// 09 动态内存与智能指针：所有权说话

struct Task {
    explicit Task(std::string n) : name{std::move(n)} {
        std::println("  + 构造 {}", name);
    }
    ~Task() { std::println("  - 析构 {}", name); }
    std::string name;
};

// unique_ptr 按值返回 = 转移所有权（工厂惯用法）
std::unique_ptr<Task> make_task(std::string name) {
    return std::make_unique<Task>(std::move(name));
}

int main() {
    // ═══ 9.1 unique_ptr：独占所有权 ═══
    auto t1 = make_task("调研");
    // auto t2 = t1;         // 编译错误：unique_ptr 不可拷贝
    auto t2 = std::move(t1);  // 只能转移；t1 变空
    std::println("t1 空了吗？{}", t1 == nullptr);
    std::println("t2 持有 {}", t2->name);

    // ═══ 9.2 作用域即生命周期 ═══
    {
        auto t3 = make_task("原型");
    }  // t3 在此自动析构——RAII 管理堆内存

    // ═══ 9.3 shared_ptr：共享所有权与引用计数 ═══
    auto shared1 = std::make_shared<Task>("发布");
    {
        auto shared2 = shared1;  // 拷贝：计数 +1
        std::println("引用计数 = {}", shared1.use_count());  // 2
    }  // shared2 析构：计数 -1
    std::println("引用计数 = {}", shared1.use_count());  // 1

    // ═══ 9.4 weak_ptr：观察但不拥有 ═══
    std::weak_ptr<Task> observer = shared1;
    if (auto locked = observer.lock()) {  // 尝试升级成 shared_ptr
        std::println("观察到 {}", locked->name);
    }
    shared1.reset();  // 释放最后一个强引用 → Task 立即析构
    std::println("对象还活着吗？{}", !observer.expired());  // false

    // ═══ 9.5 vector<unique_ptr>：多态持有的标配（见第 16 章）═══
    std::vector<std::unique_ptr<Task>> backlog;
    backlog.push_back(make_task("收尾"));
    backlog.push_back(make_task("复盘"));
    std::println("待办 {} 项", backlog.size());
    std::println("自检通过");
}  // backlog 析构 → 逐个释放 Task
```

- [ ] **Step 3: 写 examples/10_containers/main.cpp**

```cpp
#include <flat_map>
#include <map>
#include <print>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

// 10 容器与迭代器：vector、map/set、unordered、flat_map

int main() {
    // ═══ 10.1 vector：动态数组 ═══
    std::vector<std::string> tags{"cpp", "modern"};
    tags.push_back("tutorial");
    tags[1] = "modern-cpp";
    std::println("{} 个标签，第 2 个是 {}", tags.size(), tags[1]);

    // ═══ 10.2 map：有序键值对 ═══
    std::map<std::string, int> stock{{"cpp", 3}, {"rust", 5}};
    stock["go"] = 2;  // 不存在则插入
    ++stock["cpp"];   // 存在则修改
    if (auto it = stock.find("rust"); it != stock.end()) {  // 初始化语句 + find
        std::println("rust 库存 {}", it->second);
    }
    for (const auto& [lang, count] : stock) {  // 结构化绑定，按键有序
        std::println("  {}: {}", lang, count);
    }

    // ═══ 10.3 set：自动去重排序 ═══
    std::set<int> uniq{5, 3, 3, 1, 5, 9};
    std::print("set: ");
    for (int v : uniq) {
        std::print("{} ", v);  // 1 3 5 9
    }
    std::println("");

    // ═══ 10.4 unordered_map：哈希表，O(1) 平均 ═══
    std::unordered_map<std::string, int> votes;
    for (const std::string& w : {"cpp", "rust", "cpp", "go", "cpp", "rust"}) {
        ++votes[w];  // 不存在则从 0 起
    }
    std::println("cpp 得 {} 票", votes["cpp"]);  // 3

    // ═══ 10.5 迭代器：统一的遍历接口 ═══
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
    int max_v = nums.front();
    for (auto it = nums.begin(); it != nums.end(); ++it) {
        if (*it > max_v) {
            max_v = *it;
        }
    }
    std::println("最大值 = {}", max_v);

    // ═══ 10.6 删除惯用法：erase_if (C++20) 一行搞定 ═══
    std::erase_if(nums, [](int v) { return v <= 2; });
    std::print("过滤后: ");
    for (int v : nums) {
        std::print("{} ", v);  // 3 4 5 9 6
    }
    std::println("");

    // ═══ 10.7 flat_map 一瞥 (C++23)：排序 vector 实现的 map ═══
    std::flat_map<std::string, int> fm{{"b", 2}, {"a", 1}};
    fm["c"] = 3;
    std::println("flat_map 首键 = {}", fm.begin()->first);  // a：有序
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
for e in 08_classes 09_smartptr 10_containers; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：三例零告警通过。09 的构造/析构打印顺序固定；10 输出 `cpp 得 3 票`、
`flat_map 首键 = a`、"自检通过"。

```bash
git add examples/08_classes examples/09_smartptr examples/10_containers
git commit -m "feat(cpp20): 示例 08_classes/09_smartptr/10_containers

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 示例 11_algorithms / 12_ranges / 13_templates

**Files:**
- Create: `examples/11_algorithms/main.cpp`
- Create: `examples/12_ranges/main.cpp`
- Create: `examples/13_templates/main.cpp`

**Interfaces:**
- Produces: 第 11/12/13 章引用代码。

- [ ] **Step 1: 写 examples/11_algorithms/main.cpp**

```cpp
#include <algorithm>
#include <functional>
#include <numeric>
#include <print>
#include <string>
#include <vector>

// 11 算法与 lambda：谓词、捕获、std::function

int main() {
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6, 5, 3};

    // ═══ 11.1 sort：默认与自定义比较器 ═══
    std::vector<int> a = nums;
    std::sort(a.begin(), a.end());
    std::print("升序: ");
    for (int v : a) {
        std::print("{} ", v);
    }
    std::println("");

    std::vector<std::string> words{"pineapple", "fig", "banana", "kiwi"};
    std::sort(words.begin(), words.end(),
              [](const std::string& x, const std::string& y) {
                  return x.size() < y.size();  // 短的排前面
              });
    std::print("按长度: ");
    for (const auto& w : words) {
        std::print("{} ", w);  // fig kiwi banana pineapple
    }
    std::println("");

    // ═══ 11.2 查找与计数：谓词是核心 ═══
    auto it = std::find_if(nums.begin(), nums.end(), [](int v) { return v > 8; });
    std::println("第一个 >8 的数 = {}", *it);  // 9
    std::println("偶数 {} 个", std::count_if(nums.begin(), nums.end(),
                                             [](int v) { return v % 2 == 0; }));
    std::println("全是正数？{}",
                 std::all_of(nums.begin(), nums.end(), [](int v) { return v > 0; }));

    // ═══ 11.3 accumulate 与 transform ═══
    int sum = std::accumulate(nums.begin(), nums.end(), 0);
    std::vector<int> doubled(nums.size());
    std::transform(nums.begin(), nums.end(), doubled.begin(),
                   [](int v) { return v * 2; });
    std::println("sum = {}，doubled.back() = {}", sum, doubled.back());

    // ═══ 11.4 捕获：lambda 的记忆 ═══
    int threshold = 4;
    auto by_value = [threshold](int v) { return v > threshold; };  // 值捕获：快照
    auto by_ref = [&threshold](int v) { return v > threshold; };  // 引用捕获：实时
    threshold = 6;  // 改给引用捕获看
    std::println("值捕获 >4：{} 个；引用捕获 >6：{} 个",
                 std::count_if(nums.begin(), nums.end(), by_value),
                 std::count_if(nums.begin(), nums.end(), by_ref));

    // ═══ 11.5 泛型 lambda 与 std::function ═══
    auto show = [](const auto& x) { std::println("值 = {}", x); };
    show(42);
    show(3.5);
    show(std::string("文本"));
    std::function<int(int)> f = [](int v) { return v * v; };
    f = [sum](int v) { return v + sum; };  // std::function 可重新绑定
    std::println("f(3) = {}", f(3));
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/12_ranges/main.cpp**

```cpp
#include <algorithm>
#include <functional>
#include <print>
#include <ranges>
#include <string>
#include <vector>

// 12 Ranges：惰性视图管道

struct Student {
    std::string name;
    int score;
};

int main() {
    std::vector<Student> students{
        {"alice", 92}, {"bob", 78}, {"carol", 86}, {"dave", 64}, {"eve", 95},
    };

    // ═══ 12.1 管道：filter → transform → 收集 ═══
    auto passed = students
        | std::views::filter([](const Student& s) { return s.score >= 80; })
        | std::views::transform([](const Student& s) {
              return s.name + ":" + std::to_string(s.score);
          })
        | std::ranges::to<std::vector>();  // (C++23) 一行收集
    for (const auto& line : passed) {
        std::println("  {}", line);
    }

    // ═══ 12.2 惰性：不 take 就不算 ═══
    int visited = 0;
    auto first_two = students
        | std::views::filter([&visited](const Student& s) {
              ++visited;  // 打点：谓词每跑一次记一次
              return s.score >= 60;
          })
        | std::views::take(2)
        | std::ranges::to<std::vector>();
    std::println("取 2 个，但只访问了 {} 个元素", visited);  // 2：找到即停

    // ═══ 12.3 iota / take / drop / reverse：生成与裁剪 ═══
    std::print("平方: ");
    for (int v : std::views::iota(1, 6) | std::views::transform([](int i) { return i * i; })) {
        std::print("{} ", v);  // 1 4 9 16 25
    }
    std::println("");
    std::print("后两个倒序: ");
    for (const auto& s : students | std::views::drop(3) | std::views::reverse) {
        std::print("{} ", s.name);  // eve dave
    }
    std::println("");

    // ═══ 12.4 ranges 算法 + 投影 ═══
    std::ranges::sort(students, std::greater{}, &Student::score);  // 按分数降序
    std::print("排名: ");
    for (const auto& name : students | std::views::transform(&Student::name)) {
        std::print("{} ", name);
    }
    std::println("");
    std::println("自检通过");
}
```

- [ ] **Step 3: 写 examples/13_templates/main.cpp**

```cpp
#include <array>
#include <cstddef>
#include <print>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

// 13 模板基础：把类型当参数

// ═══ 13.1 函数模板：T 代替具体类型 ═══
template <typename T>
T max_of(const T& a, const T& b) {
    return (a < b) ? b : a;
}

// ═══ 13.2 类模板：类型参数化的容器 ═══
template <typename T>
class Stack {
public:
    void push(T value) {
        items_.push_back(std::move(value));
    }
    T pop() {
        if (items_.empty()) {
            throw std::out_of_range("stack is empty");
        }
        T top = std::move(items_.back());
        items_.pop_back();
        return top;
    }
    [[nodiscard]] bool empty() const { return items_.empty(); }
    [[nodiscard]] std::size_t size() const { return items_.size(); }

private:
    std::vector<T> items_;
};

// ═══ 13.3 非类型模板参数：编译期的"值参数" ═══
template <typename T, std::size_t N>
double average(const std::array<T, N>& arr) {
    double sum = 0;
    for (const T& v : arr) {
        sum += v;
    }
    return sum / static_cast<double>(N);
}

int main() {
    std::println("{} {}", max_of(3, 9), max_of(2.5, 1.5));
    std::println("{}", max_of<double>(3, 2.5));  // 混合类型要显式指定

    Stack<int> ints;
    ints.push(1);
    ints.push(2);
    ints.push(3);
    std::println("size = {}，弹出 {}", ints.size(), ints.pop());

    Stack<std::string> words;  // 同一套代码，第二种类型
    words.push("模板");
    std::println("弹出 {}", words.pop());

    Stack copied{ints};  // CTAD：从拷贝构造推导出 Stack<int>
    std::println("拷贝的栈大小 = {}", copied.size());

    std::array<int, 4> nums{2, 4, 6, 8};
    std::println("平均 = {}", average(nums));  // N=4 自动推导
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
for e in 11_algorithms 12_ranges 13_templates; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：三例零告警通过。12 输出 `取 2 个，但只访问了 2 个元素`、排名 `eve alice carol bob dave`；
13 输出 `平均 = 5`。

```bash
git add examples/11_algorithms examples/12_ranges examples/13_templates
git commit -m "feat(cpp20): 示例 11_algorithms/12_ranges/13_templates

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 示例 14_concepts / 15_moves / 16_inheritance

**Files:**
- Create: `examples/14_concepts/main.cpp`
- Create: `examples/15_moves/main.cpp`
- Create: `examples/16_inheritance/main.cpp`

**Interfaces:**
- Produces: 第 14/15/16 章引用代码。

- [ ] **Step 1: 写 examples/14_concepts/main.cpp**

```cpp
#include <concepts>
#include <print>
#include <string>
#include <type_traits>
#include <vector>

// 14 概念：给模板参数立规矩

// ═══ 14.1 自定义 concept：requires 表达式 ═══
template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;  // 要求 a+b 存在且结果能转回 T
};

// ═══ 14.2 用概念约束模板 ═══
template <Addable T>  // 写法一：直接当约束
T sum_all(const std::vector<T>& xs) {
    T total{};
    for (const T& v : xs) {
        total = total + v;
    }
    return total;
}

template <typename T>
    requires std::is_arithmetic_v<T>  // 写法二：requires 子句
T half(T v) {
    return v / 2;
}

// ═══ 14.3 约束重载：按能力分派 ═══
template <typename T>
    requires std::integral<T>
const char* kind(T) {
    return "整数";
}

template <typename T>
    requires std::floating_point<T>
const char* kind(T) {
    return "浮点";
}

template <typename T>
const char* kind(const T&) {
    return "其他（兜底）";
}

int main() {
    std::vector<int> nums{1, 2, 3, 4};
    std::vector<std::string> words{"a", "b"};
    std::vector<double> ratios{0.5, 1.5};
    std::println("sum(int) = {}", sum_all(nums));        // 10
    std::println("sum(string) = {}", sum_all(words));    // ab：string 也满足 +
    std::println("sum(double) = {}", sum_all(ratios));  // 2

    std::println("half(9) = {}，half(2.5) = {}", half(9), half(2.5));  // 4 / 1.25

    std::println("kind(42) = {}", kind(42));        // 整数
    std::println("kind(1.5) = {}", kind(1.5));      // 浮点
    std::println("kind('c') = {}", kind('c'));      // 整数！char 是整数类型
    std::println("kind(vector) = {}", kind(nums));  // 兜底

    // ═══ 14.4 编译期检查：static_assert 验证概念 ═══
    static_assert(Addable<int>);
    static_assert(Addable<std::string>);
    // static_assert(Addable<std::vector<int>>);  // 编译失败：vector 没有 +
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/15_moves/main.cpp**

```cpp
#include <print>
#include <string>
#include <utility>
#include <vector>

// 15 移动语义：值类别、std::move、完美转发、RVO

class Tracer {
public:
    explicit Tracer(std::string name) : name_{std::move(name)} {
        std::println("  构造 {}", name_);
    }
    Tracer(const Tracer& other) : name_{other.name_} {
        ++copies_;
        std::println("  拷贝 {}", name_);
    }
    Tracer(Tracer&& other) noexcept : name_{std::move(other.name_)} {
        ++moves_;
        std::println("  移动 {}", name_);
    }
    ~Tracer() = default;
    static int copies() { return copies_; }
    static int moves() { return moves_; }

private:
    std::string name_;
    inline static int copies_ = 0;
    inline static int moves_ = 0;
};

// ═══ 15.4 完美转发：保持调用方的值类别 ═══
void process(const Tracer&) { std::println("  process 收到左值"); }
void process(Tracer&&) { std::println("  process 收到右值"); }

template <typename T>
void relay(T&& arg) {
    process(std::forward<T>(arg));
}

int main() {
    // ═══ 15.1 拷贝 vs 移动 ═══
    std::println("-- 拷贝 --");
    Tracer a{"原件"};
    Tracer b = a;             // 拷贝构造
    std::println("-- 移动 --");
    Tracer c = std::move(a);  // 移动构造：a 进入"被搬空"状态

    // ═══ 15.2 容器操作：move 让插入便宜 ═══
    std::println("-- vector 插入 --");
    std::vector<Tracer> box;
    box.reserve(2);                 // 预留容量：排除扩容干扰
    box.push_back(Tracer{"临时"});  // 纯右值：直接落位（省掉移动）
    Tracer named{"具名"};
    box.push_back(std::move(named));  // 具名对象要显式 move

    // ═══ 15.3 RVO：返回纯右值，连移动都省 ═══
    auto make = []() -> Tracer { return Tracer{"返回值"}; };
    Tracer r = make();  // C++17 保证消除：0 次拷贝 0 次移动

    std::println("统计：拷贝 {} 次，移动 {} 次", Tracer::copies(), Tracer::moves());

    // ═══ 15.4 完美转发 ═══
    std::println("-- 转发 --");
    Tracer x{"左值源"};
    relay(x);                 // 左值 → process(const Tracer&)
    relay(Tracer{"右值源"});  // 右值 → process(Tracer&&)
    std::println("自检通过");
}
```

- [ ] **Step 3: 写 examples/16_inheritance/main.cpp**

```cpp
#include <memory>
#include <numbers>
#include <print>
#include <string>
#include <vector>

// 16 继承与多态：虚函数、override、抽象类、组合

// ═══ 16.1 抽象基类：纯虚函数定契约 ═══
class Shape {
public:
    explicit Shape(std::string name) : name_{std::move(name)} {}
    virtual ~Shape() = default;  // 虚析构：多态删除的生死线

    const std::string& name() const { return name_; }
    virtual double area() const = 0;   // 纯虚：本类不能实例化
    virtual void describe() const {    // 虚：子类可覆写
        std::println("{}：面积 {:.2f}", name_, area());
    }

private:
    std::string name_;
};

class Circle : public Shape {
public:
    explicit Circle(double r) : Shape{"圆"}, r_{r} {}
    double area() const override {  // override：拼错会编译报错
        return std::numbers::pi * r_ * r_;
    }

private:
    double r_;
};

class Rect : public Shape {
public:
    Rect(double w, double h) : Shape{"矩形"}, w_{w}, h_{h} {}
    double area() const override { return w_ * h_; }
    void describe() const override {  // 覆写并复用基类行为
        std::print("（宽 {:.0f} 高 {:.0f}）", w_, h_);
        Shape::describe();  // 显式调基类版本
    }

private:
    double w_;
    double h_;
};

// ═══ 16.3 切片演示用的具体基类 ═══
class Animal {
public:
    virtual std::string speak() const { return "……"; }
    virtual ~Animal() = default;
};

class Dog : public Animal {
public:
    std::string speak() const override { return "汪！"; }
};

int main() {
    // ═══ 16.1 多态容器：基类 unique_ptr 统一持有 ═══
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));
    shapes.push_back(std::make_unique<Rect>(3.0, 4.0));
    for (const auto& s : shapes) {
        s->describe();  // 动态分派：各自版本的 area/describe
    }

    // ═══ 16.2 dynamic_cast：带检查的下转 ═══
    Rect* rect = dynamic_cast<Rect*>(shapes[1].get());
    if (rect != nullptr) {
        std::println("确实是个矩形");
    }

    // ═══ 16.3 切片：按值收基类会"削平"子类部分 ═══
    Dog dog;
    Animal& ref = dog;
    Animal sliced = dog;  // 拷贝了 Animal 子对象，Dog 部分被丢掉
    std::println("引用说话：{}", ref.speak());    // 汪！（动态类型是 Dog）
    std::println("切片说话：{}", sliced.speak()); // ……（静态类型 Animal 的版本）

    // ═══ 16.4 组合优于继承：能力用成员"装进来" ═══
    struct Style {
        std::string color = "#333333";
    };
    Style st;
    std::println("样式颜色 {}（组合：成员即能力，不需要继承）", st.color);
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
for e in 14_concepts 15_moves 16_inheritance; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：三例零告警通过。15 输出 `统计：拷贝 1 次，移动 2 次`；16 输出 `引用说话：汪！`、
`切片说话：……`、"自检通过"。

```bash
git add examples/14_concepts examples/15_moves examples/16_inheritance
git commit -m "feat(cpp20): 示例 14_concepts/15_moves/16_inheritance

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 示例 17_compiletime / 18_modules / 19_threads

**Files:**
- Create: `examples/17_compiletime/main.cpp`
- Create: `examples/18_modules/math.ixx` + `examples/18_modules/main.cpp`
- Create: `examples/19_threads/main.cpp`

**Interfaces:**
- Produces: 第 17/18/19 章引用代码；18 章文档的模块编译命令以本示例为准。

- [ ] **Step 1: 写 examples/17_compiletime/main.cpp**

```cpp
#include <array>
#include <print>
#include <string>
#include <string_view>
#include <type_traits>

// 17 编译期编程：constexpr、if constexpr、变参模板、fold

// ═══ 17.1 constexpr 函数：同一份代码，两个世界都能跑 ═══
constexpr unsigned long long factorial(unsigned n) {
    unsigned long long r = 1;
    for (unsigned i = 2; i <= n; ++i) {
        r *= i;
    }
    return r;
}

// ═══ 17.2 consteval：只许编译期执行 (C++20) ═══
consteval int compile_time_square(int v) {
    return v * v;
}

// ═══ 17.3 if constexpr：编译期剪枝，未选中的分支不实例化 ═══
template <typename T>
std::string describe(const T& value) {
    if constexpr (std::is_arithmetic_v<T>) {
        return "数值: " + std::to_string(value);
    } else if constexpr (std::is_convertible_v<T, std::string_view>) {
        return "文本: " + std::string(value);
    } else {
        return "其他类型";
    }
}

// ═══ 17.4 变参模板 + fold 表达式 ═══
template <typename... Ts>
auto sum_all(Ts... values) {
    return (values + ...);  // 一元右折叠：((v1+v2)+v3)…
}

template <typename... Ts>
bool all_small(int limit, Ts... values) {
    return ((values < limit) && ...);  // 逻辑与折叠
}

int main() {
    // 编译期常量 + static_assert 当"免费单测"
    static_assert(factorial(10) == 3'628'800ULL);
    constexpr auto fact5 = factorial(5);
    int runtime_n = 6;  // 运行期输入也能调同一函数
    std::println("5! = {}，运行期 6! = {}", fact5, factorial(runtime_n));

    // consteval 结果能当数组长度
    constexpr int side = 12;
    std::array<int, compile_time_square(side)> table{};
    std::println("表格长度 = {}", table.size());  // 144

    std::println("{}", describe(3.14));
    std::println("{}", describe(std::string("文本")));
    struct Point {
        int x;
        int y;
    };
    std::println("{}", describe(Point{1, 2}));

    std::println("sum_all = {}", sum_all(1, 2, 3, 4.5));  // 10.5
    std::println("all_small = {}", all_small(3, 1, 2, 3));  // false
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/18_modules/math.ixx**

```cpp
export module math;

// 18 模块：模块接口单元——export 的名字才对 import 方可见

export int add(int a, int b) {
    return a + b;
}

export int sub(int a, int b) {
    return a - b;
}

export constexpr double pi = 3.14159265358979323846;
```

- [ ] **Step 3: 写 examples/18_modules/main.cpp**

```cpp
// 18 编译单元与模块：import 代替 #include
// 编译流程（两步，build.ps1 已自动处理）：
//   1) cl /std:c++latest /interface /c math.ixx        → math.obj + math.ifc
//   2) cl /std:c++latest main.cpp math.obj             → 链接成 exe
import math;

#include <print>

int main() {
    // ═══ 18.1 import：拿到模块导出的名字 ═══
    std::println("math::add(2, 3) = {}", add(2, 3));
    std::println("math::sub(7, 4) = {}", sub(7, 4));
    std::println("math::pi = {:.5f}", pi);
    std::println("自检通过");
}
```

- [ ] **Step 4: 写 examples/19_threads/main.cpp**

```cpp
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <print>
#include <queue>
#include <stop_token>
#include <thread>
#include <vector>

// 19 并发 I：jthread、mutex、条件变量

// ═══ 19.2 mutex 保护的共享计数 ═══
std::mutex counter_mtx;
long long counter = 0;

void bump(int times) {
    for (int i = 0; i < times; ++i) {
        std::lock_guard lock{counter_mtx};  // RAII 锁：构造即加，析构即解
        ++counter;
    }
}

// ═══ 19.3 条件变量：生产者-消费者 ═══
std::queue<int> channel;
std::mutex channel_mtx;
std::condition_variable cv;
bool done = false;

void producer(int count) {
    for (int i = 1; i <= count; ++i) {
        {
            std::lock_guard lock{channel_mtx};
            channel.push(i);
        }
        cv.notify_one();
    }
    {
        std::lock_guard lock{channel_mtx};
        done = true;
    }
    cv.notify_all();
}

int consume_all() {
    int sum = 0;
    while (true) {
        std::unique_lock lock{channel_mtx};
        cv.wait(lock, [] { return !channel.empty() || done; });  // 谓词防虚假唤醒
        while (!channel.empty()) {
            sum += channel.front();
            channel.pop();
        }
        if (done) {
            break;
        }
    }
    return sum;
}

int main() {
    // ═══ 19.1 jthread + stop_token：协作式取消 ═══
    {
        std::jthread worker{[](std::stop_token st) {
            while (!st.stop_requested()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            }
            std::println("worker：收到停止请求，退出");
        }};
        std::this_thread::sleep_for(std::chrono::milliseconds(30));
        worker.request_stop();  // jthread 析构时自动 join
    }

    // ═══ 19.2 四线程累加：无锁保护会丢更新 ═══
    {
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back(bump, 100'000);
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("counter = {}", counter);
        assert(counter == 400'000);
    }

    // ═══ 19.3 生产者 10 个数，消费者求和 ═══
    {
        std::jthread prod{producer, 10};
        std::jthread cons{[] {
            int sum = consume_all();
            std::println("consumer：sum = {}", sum);
            assert(sum == 55);
        }};
        prod.join();
        cons.join();
    }
    std::println("自检通过");
}
```

- [ ] **Step 5: 验证（18 为首次模块链路实测）+ Commit**

```bash
cd /g/code/guide/cpp20
for e in 17_compiletime 18_modules 19_threads; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：17 零告警，输出 `表格长度 = 144`、`sum_all = 10.5`；18 打印
`[Module] math.ixx` 后编译运行输出 `math::add(2, 3) = 5`；19 输出 `counter = 400000`、
`consumer：sum = 55`、"自检通过"。

**模块失败回退**：若 18 的 `/ifcOutput`+`/reference` 链路报错，改用同目录直编方案——
在 `examples/18_modules/` 内执行 Task 1 烟测的同款两步（`cl /interface /c math.ixx` 生成
obj/ifc 于当前目录，再 `cl main.cpp math.obj`），build.ps1 里对该目录退化为"进入目录执行
两步"，并在执行勘误表记录偏差。

```bash
git add examples/17_compiletime examples/18_modules examples/19_threads
git commit -m "feat(cpp20): 示例 17_compiletime/18_modules/19_threads

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: 示例 20_atomic / 21_coroutines / 22_textfiles

**Files:**
- Create: `examples/20_atomic/main.cpp`
- Create: `examples/21_coroutines/main.cpp`
- Create: `examples/22_textfiles/main.cpp`

**Interfaces:**
- Produces: 第 20/21/22 章引用代码；21 章 Generator<T> 手写实现供 docs 逐行讲解。

- [ ] **Step 1: 写 examples/20_atomic/main.cpp**

```cpp
#include <algorithm>
#include <atomic>
#include <execution>
#include <latch>
#include <barrier>
#include <numeric>
#include <print>
#include <thread>
#include <vector>

// 20 并发 II：atomic、latch/barrier、并行算法

// ═══ 20.1 atomic：免 mutex 的原子计数 ═══
std::atomic<long long> hits{0};

void click(int times) {
    for (int i = 0; i < times; ++i) {
        hits.fetch_add(1, std::memory_order_relaxed);  // 计数不需要同步序
    }
}

int main() {
    // ═══ 20.1 四线程原子累加 ═══
    {
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back(click, 100'000);
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("hits = {}", hits.load());
        assert(hits.load() == 400'000);
    }

    // ═══ 20.2 latch：一次性发令枪，四段并行求和 ═══
    {
        constexpr int workers = 4;
        std::vector<long long> partial(workers, 0);
        std::latch go{1};  // 单格闩：主线程 count_down 后全员放行
        std::vector<std::jthread> team;
        for (int w = 0; w < workers; ++w) {
            team.emplace_back([&, w] {
                go.wait();  // 等发令枪
                for (int i = w * 250'000 + 1; i <= (w + 1) * 250'000; ++i) {
                    partial[w] += i;  // 各写各的槽位：无竞争
                }
            });
        }
        go.count_down();  // 砰！
        for (auto& t : team) {
            t.join();
        }
        long long total = std::accumulate(partial.begin(), partial.end(), 0LL);
        std::println("分段总和 = {}", total);  // 500000500000
        assert(total == 500'000'500'000LL);
    }

    // ═══ 20.3 barrier：多阶段同步，两轮各翻十倍 ═══
    {
        std::vector<int> slots{1, 2, 3, 4};
        std::barrier phase_done{4};  // 可复用：每轮全员到齐才进下一轮
        std::vector<std::jthread> team;
        for (int w = 0; w < 4; ++w) {
            team.emplace_back([&, w] {
                for (int round = 0; round < 2; ++round) {
                    slots[w] *= 10;
                    phase_done.arrive_and_wait();
                }
            });
        }
        for (auto& t : team) {
            t.join();
        }
        std::print("两轮后: ");
        for (int v : slots) {
            std::print("{} ", v);  // 100 200 300 400
        }
        std::println("");
        assert(slots[0] == 100 && slots[3] == 400);
    }

    // ═══ 20.4 并行算法：execution::par ═══
    {
        std::vector<int> big(1'000'000, 1);
        std::atomic<long long> par_sum{0};
        std::for_each(std::execution::par, big.begin(), big.end(),
                      [&](int v) { par_sum += v; });
        std::println("par_sum = {}", par_sum.load());
        assert(par_sum.load() == 1'000'000);
    }
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/21_coroutines/main.cpp**

```cpp
#include <coroutine>
#include <exception>
#include <generator>
#include <iterator>
#include <print>
#include <utility>

// 21 协程：co_yield 惰性产出（生成器模式）

// ═══ 21.1 手写 Generator<T>：promise_type 三件套 ═══
template <typename T>
class Generator {
public:
    struct promise_type {
        T current_;
        Generator get_return_object() {
            return Generator{std::coroutine_handle<promise_type>::from_promise(*this)};
        }
        std::suspend_always initial_suspend() noexcept { return {}; }  // 先暂停：惰性
        std::suspend_always final_suspend() noexcept { return {}; }
        std::suspend_always yield_value(T value) {  // co_yield 落点
            current_ = value;
            return {};
        }
        void return_void() {}
        void unhandled_exception() { std::terminate(); }
    };

    explicit Generator(std::coroutine_handle<promise_type> h) : handle_{h} {}
    Generator(Generator&& other) noexcept
        : handle_{std::exchange(other.handle_, {})} {}
    Generator(const Generator&) = delete;
    Generator& operator=(const Generator&) = delete;
    ~Generator() {
        if (handle_) {
            handle_.destroy();  // 协程帧由我们负责销毁
        }
    }

    // 迭代器接口：让 range-for 能用
    struct iterator {
        std::coroutine_handle<promise_type> handle_;
        const T& operator*() const { return handle_.promise().current_; }
        iterator& operator++() {
            handle_.resume();  // 跑到下一个 co_yield（或结束）
            return *this;
        }
        bool operator==(std::default_sentinel_t) const { return handle_.done(); }
    };
    iterator begin() {
        handle_.resume();  // 先跑到第一个 co_yield
        return {handle_};
    }
    std::default_sentinel_t end() { return {}; }

private:
    std::coroutine_handle<promise_type> handle_;
};

// ═══ 21.2 用它：co_yield 惰性产出斐波那契 ═══
Generator<int> fibonacci(int limit) {
    int a = 0, b = 1;
    while (a <= limit) {
        co_yield a;  // 暂停点：交出一个值，下次从这继续
        int next = a + b;
        a = b;
        b = next;
    }
}

// ═══ 21.3 std::generator (C++23)：标准库替你写好了 ═══
std::generator<int> squares(int n) {
    for (int i = 1; i <= n; ++i) {
        co_yield i * i;
    }
}

int main() {
    std::print("手写 Generator 的斐波那契: ");
    for (int v : fibonacci(50)) {
        std::print("{} ", v);  // 0 1 1 2 3 5 8 13 21 34
    }
    std::println("");

    std::print("std::generator 的平方数: ");
    for (int v : squares(5)) {
        std::print("{} ", v);  // 1 4 9 16 25
    }
    std::println("");

    // 惰性证明：只取前 3 个，fibonacci 不会算到底
    int taken = 0, last = 0;
    for (int v : fibonacci(1'000'000)) {
        last = v;
        if (++taken == 3) {
            break;
        }
    }
    std::println("只取 3 个：最后拿到 {}（没算到百万级）", last);  // 1
    std::println("自检通过");
}
```

- [ ] **Step 3: 写 examples/22_textfiles/main.cpp**

```cpp
#include <algorithm>
#include <array>
#include <filesystem>
#include <fstream>
#include <mdspan>
#include <print>
#include <regex>
#include <string>
#include <vector>

namespace fs = std::filesystem;

// 22 文本与文件：format 深入、regex、filesystem、mdspan 一瞥

int main() {
    // ═══ 22.1 std::format 常用招式 ═══
    std::println("{:>10}|", "右对齐");
    std::println("{:<10}|", "左对齐");
    std::println("{:^10}|", "居中");
    std::println("保留两位：{:.2f}，百分比：{:.1%}", 3.14159, 0.856);
    std::println("十六进制 {:#x}，二进制 {:#b}", 255, 5);
    std::println("填充星号：{:*^14}", "标题");

    // ═══ 22.2 regex：正则匹配与捕获组 ═══
    std::string log = "2026-09-17 ERROR 磁盘不足; 2026-09-16 INFO 正常";
    std::regex date_re{R"((\d{4})-(\d{2})-(\d{2}))"};  // 原始字符串字面量
    for (std::sregex_iterator it{log.begin(), log.end(), date_re}, end; it != end; ++it) {
        std::println("日期 {}-{}-{}", it->str(1), it->str(2), it->str(3));  // str(n) 取捕获组
    }
    std::println("含 ERROR？{}", std::regex_search(log, std::regex{"ERROR"}));

    // ═══ 22.3 filesystem：目录与文件 ═══
    fs::path dir = fs::temp_directory_path() / "cpp_guide_22";
    fs::create_directories(dir / "sub");
    {
        std::ofstream{dir / "a.txt"} << "hello 文件系统";
        std::ofstream{dir / "sub" / "b.log"} << "日志内容";
    }
    std::vector<fs::path> entries;  // 收集后排序：目录遍历顺序不保证
    for (const auto& e : fs::recursive_directory_iterator{dir}) {
        entries.push_back(e.path());
    }
    std::sort(entries.begin(), entries.end());
    std::println("遍历 {}:", dir.string());
    for (const auto& p : entries) {
        std::println("  {}", p.string());
    }
    std::println("清理了 {} 个条目", fs::remove_all(dir));

    // ═══ 22.4 mdspan 一瞥 (C++23)：多维视图 ═══
    std::array<int, 6> data{1, 2, 3, 4, 5, 6};
    std::mdspan grid{data.data(), 2, 3};  // 2 行 3 列（访问用 grid[r, c]）
    for (std::size_t r = 0; r < grid.extent(0); ++r) {
        for (std::size_t c = 0; c < grid.extent(1); ++c) {
            std::print("{} ", grid[r, c]);
        }
        std::println("");
    }
    std::println("自检通过");
}
```

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
for e in 20_atomic 21_coroutines 22_textfiles; do
  "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example $e
done
```

预期：三例零告警通过。20 输出 `分段总和 = 500000500000`、`par_sum = 1000000`；
21 输出斐波那契 `0 1 1 2 3 5 8 13 21 34`；22 输出两个日期、遍历列表
（a.txt 在 sub 前）与 2×3 矩阵。

```bash
git add examples/20_atomic examples/21_coroutines examples/22_textfiles
git commit -m "feat(cpp20): 示例 20_atomic/21_coroutines/22_textfiles

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: 示例 23_tooling / 24_minigrep（实战）

**Files:**
- Create: `examples/23_tooling/main.cpp`
- Create: `examples/24_minigrep/search.h` + `search.cpp` + `output.h` + `output.cpp` + `main.cpp`

**Interfaces:**
- Produces: 第 23/24 章引用代码；`search_text`/`search_file`/`print_match` 为 24 章多文件分解教学素材。

- [ ] **Step 1: 写 examples/23_tooling/main.cpp**

```cpp
// 23 测试与调试：assert 自造单测、stacktrace
#include <cassert>
#include <cctype>
#include <functional>
#include <print>
#include <stacktrace>
#include <string>
#include <string_view>
#include <vector>

// ═══ 23.1 被测对象：一个纯函数 ═══
std::string slugify(std::string_view text) {
    std::string out;
    for (char ch : text) {
        auto uc = static_cast<unsigned char>(ch);
        if (std::isalnum(uc) != 0) {
            out.push_back(static_cast<char>(std::tolower(uc)));
        } else if (!out.empty() && out.back() != '-') {
            out.push_back('-');
        }
    }
    while (!out.empty() && out.back() == '-') {
        out.pop_back();
    }
    return out;
}

// ═══ 23.2 十行单测框架：名字 + 断言 lambda ═══
struct TestCase {
    std::string name;
    std::function<void()> run;
};

int run_tests() {
    std::vector<TestCase> tests{
        {"空串返回空", [] { assert(slugify("") == ""); }},
        {"标点转连字符", [] { assert(slugify("Hello, C++ World!") == "hello-c-world"); }},
        {"首尾不留连字符", [] { assert(slugify("--Hi--") == "hi"); }},
        {"非 ASCII 字节剔除", [] { assert(slugify("你好") == ""); }},
    };
    for (const auto& t : tests) {
        t.run();  // assert 失败会中止（真实框架会捕获并继续，见 docs）
        std::println("[PASS] {}", t.name);
    }
    return static_cast<int>(tests.size());
}

// ═══ 23.3 stacktrace：看出错时"从哪来" (C++23) ═══
int deep_c(int depth) {
    if (depth == 0) {
        auto st = std::stacktrace::current();
        std::println("调用栈帧数 = {}（≥3 才合理）", st.size());
        std::println("  第 1 帧大概长这样：{}", std::to_string(st[0]));
        return 42;
    }
    return deep_c(depth - 1);
}

int main() {
    int passed = run_tests();
    int result = deep_c(3);
    std::println("通过 {} 个用例，deep_c = {}", passed, result);
    std::println("自检通过");
}
```

- [ ] **Step 2: 写 examples/24_minigrep/search.h**

```cpp
#pragma once

#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

// 24 迷你 grep：搜索层（与输出层分离，便于测试）

struct Match {
    int line_no;
    std::string text;
};

// 在一段文本里逐行查找 pattern（可忽略大小写）
std::vector<Match> search_text(std::string_view content,
                               std::string_view pattern,
                               bool ignore_case);

// 找 pattern 在 line 中首次出现的位置；找不到返回 npos
std::size_t find_in_line(std::string_view line,
                         std::string_view pattern,
                         bool ignore_case);

// 搜索单个文件；打不开/读不了返回空
std::vector<Match> search_file(const std::filesystem::path& file,
                               std::string_view pattern,
                               bool ignore_case);
```

- [ ] **Step 3: 写 examples/24_minigrep/search.cpp**

```cpp
#include "search.h"

#include <cctype>
#include <fstream>
#include <sstream>
#include <utility>

namespace {

bool equal_ic(char a, char b) {
    if (a == b) {
        return true;
    }
    auto ua = static_cast<unsigned char>(a);
    auto ub = static_cast<unsigned char>(b);
    return std::tolower(ua) == std::tolower(ub);
}

}  // namespace

std::size_t find_in_line(std::string_view line, std::string_view pattern, bool ignore_case) {
    if (pattern.empty() || line.size() < pattern.size()) {
        return std::string_view::npos;
    }
    for (std::size_t p = 0; p + pattern.size() <= line.size(); ++p) {
        bool hit = true;
        for (std::size_t k = 0; k < pattern.size(); ++k) {
            char a = line[p + k];
            char b = pattern[k];
            if (ignore_case ? !equal_ic(a, b) : a != b) {
                hit = false;
                break;
            }
        }
        if (hit) {
            return p;
        }
    }
    return std::string_view::npos;
}

std::vector<Match> search_text(std::string_view content,
                               std::string_view pattern,
                               bool ignore_case) {
    std::vector<Match> hits;
    std::size_t line_start = 0;
    int line_no = 1;
    for (std::size_t i = 0; i <= content.size(); ++i) {
        if (i == content.size() || content[i] == '\n') {
            std::string_view line = content.substr(line_start, i - line_start);
            if (find_in_line(line, pattern, ignore_case) != std::string_view::npos) {
                hits.push_back({line_no, std::string(line)});
            }
            line_start = i + 1;
            ++line_no;
        }
    }
    return hits;
}

std::vector<Match> search_file(const std::filesystem::path& file,
                               std::string_view pattern,
                               bool ignore_case) {
    std::ifstream in{file};
    if (!in) {
        return {};  // 打不开就跳过（权限、被占用……）
    }
    std::ostringstream buffer;
    buffer << in.rdbuf();  // 整文件读入
    return search_text(buffer.str(), pattern, ignore_case);
}
```

- [ ] **Step 4: 写 examples/24_minigrep/output.h 与 output.cpp**

`output.h`：

```cpp
#pragma once

#include <filesystem>
#include <string_view>

#include "search.h"

// 24 迷你 grep：输出层——file:line:文本，命中段 ANSI 红色高亮
void print_match(const std::filesystem::path& file,
                 const Match& match,
                 std::string_view pattern,
                 bool ignore_case);
```

`output.cpp`：

```cpp
#include "output.h"

#include <print>

namespace {
constexpr std::string_view kRed = "\033[31;1m";
constexpr std::string_view kReset = "\033[0m";
}  // namespace

void print_match(const std::filesystem::path& file,
                 const Match& match,
                 std::string_view pattern,
                 bool ignore_case) {
    std::size_t pos = find_in_line(match.text, pattern, ignore_case);
    if (pos == std::string_view::npos) {
        std::println("{}:{}:{}", file.string(), match.line_no, match.text);
        return;
    }
    std::println("{}:{}:{}{}{}{}{}",
                 file.string(), match.line_no,
                 std::string_view{match.text}.substr(0, pos),
                 kRed,
                 std::string_view{match.text}.substr(pos, pattern.size()),
                 kReset,
                 std::string_view{match.text}.substr(pos + pattern.size()));
}
```

- [ ] **Step 5: 写 examples/24_minigrep/main.cpp**

```cpp
// 24 实战：迷你 grep —— 参数解析、目录递归、多线程搜索、高亮输出
#include "output.h"
#include "search.h"

#include <algorithm>
#include <atomic>
#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <print>
#include <string>
#include <thread>
#include <vector>

namespace fs = std::filesystem;

struct Options {
    fs::path dir;
    std::string pattern;
    bool ignore_case = false;
    int threads = 4;
};

// ═══ 24.1 参数解析：minigrep <dir> <pattern> [-i] [-t N] ═══
Options parse_args(int argc, char** argv) {
    if (argc < 3) {
        std::println("用法: minigrep <dir> <pattern> [-i] [-t N]");
        std::exit(2);
    }
    Options opt;
    opt.dir = argv[1];
    opt.pattern = argv[2];
    for (int i = 3; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-i") {
            opt.ignore_case = true;
        } else if (arg == "-t" && i + 1 < argc) {
            opt.threads = std::max(1, std::stoi(argv[++i]));
        }
    }
    return opt;
}

// ═══ 24.2 自检模式：内置样例目录验证核心行为（构建验证入口）═══
void run_self_test() {
    fs::path dir = fs::temp_directory_path() / "minigrep_selftest";
    fs::remove_all(dir);
    fs::create_directories(dir);
    {
        std::ofstream{dir / "alpha.txt"} << "normal line\n"
                                            "warning: disk almost full\n"
                                            "another WARNING here\n"
                                            "all good\n";
        std::ofstream{dir / "beta.md"} << "# notes\nthere is a Warning inside\n";
        std::ofstream{dir / "gamma.dat"} << "nothing to see\n";
    }
    auto hits_a = search_file(dir / "alpha.txt", "warning", true);
    auto hits_b = search_file(dir / "beta.md", "warning", true);
    auto hits_g = search_file(dir / "gamma.dat", "warning", true);
    assert(hits_a.size() == 2 && hits_a[0].line_no == 2 && hits_a[1].line_no == 3);
    assert(hits_b.size() == 1 && hits_b[0].line_no == 2);
    assert(hits_g.empty());
    assert(search_text("a\nbb\nabc\n", "ab", false).size() == 1);  // 恰好整段匹配
    fs::remove_all(dir);
    std::println("minigrep 自检通过");
}

// ═══ 24.3 多线程搜索：原子游标瓜分文件列表（线程池的极简形态）═══
int search_directory(const Options& opt) {
    std::vector<fs::path> files;
    for (const auto& e : fs::recursive_directory_iterator{opt.dir}) {
        if (e.is_regular_file()) {
            files.push_back(e.path());
        }
    }
    std::sort(files.begin(), files.end());  // 输出顺序稳定

    std::atomic<std::size_t> cursor{0};
    std::atomic<int> total{0};
    std::mutex print_mtx;  // 命中行整行打印，不许交错
    std::vector<std::jthread> team;
    for (int t = 0; t < opt.threads; ++t) {
        team.emplace_back([&] {
            std::size_t i;
            while ((i = cursor.fetch_add(1)) < files.size()) {  // 领下一个文件
                for (const auto& m : search_file(files[i], opt.pattern, opt.ignore_case)) {
                    {
                        std::lock_guard lock{print_mtx};
                        print_match(files[i], m, opt.pattern, opt.ignore_case);
                    }
                    total.fetch_add(1);
                }
            }
        });
    }
    for (auto& t : team) {
        t.join();
    }
    return total.load();
}

int main(int argc, char** argv) {
    if (argc < 2) {
        run_self_test();  // 无参数 = 自检（build.ps1 验证入口）
        return 0;
    }
    if (std::string_view{argv[1]} == "--self-test") {
        run_self_test();
        return 0;
    }
    Options opt = parse_args(argc, argv);
    int hits = search_directory(opt);
    std::println("共 {} 处命中", hits);
    return 0;
}
```

- [ ] **Step 6: 验证（全量）+ Commit**

```bash
cd /g/code/guide/cpp20
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 23_tooling
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 24_minigrep
```

预期：23 输出 4 行 `[PASS]` + 调用栈帧数 + "自检通过"；24 无参数运行即自检，输出
`minigrep 自检通过`。

```bash
# 手工试一把真搜索（可选，演示用）：
./build/24_minigrep.exe examples/24_minigrep warning -i
```

预期：命中 search.h/main.cpp 中含 "warning"/"Warning" 的行（ANSI 红色高亮，
pwsh 7 支持显示），末行汇总。

```bash
git add examples/23_tooling examples/24_minigrep
git commit -m "feat(cpp20): 示例 23_tooling/24_minigrep 实战搜索工具

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: docs/01–04 章

**Files:**
- Create: `docs/01-overview.md`（无示例，引用 `examples/02_hello/`）
- Create: `docs/02-hello.md`（示例 `examples/02_hello/`）
- Create: `docs/03-types.md`（示例 `examples/03_types/`）
- Create: `docs/04-control.md`（示例 `examples/04_control/`）

**Interfaces:**
- Consumes: Task 2 的三个示例（按 `// ═══ N.M` 摘录）。
- Produces: docs/ 目录与首批四章；旧 README 第 1–2 章（核心语言特性 1.1/1.5、标准库 2.2）素材吸收。

- [ ] **Step 1: 写 01-overview.md**（约 200 行）：
  1. `# 01 · C++ 全景：一门不断进化的语言`
  2. C++ 是什么：编译型、零开销抽象、系统级；"你不懂的每一步都由你负责"的心智准备
  3. 编译模型心智模型：源文件 → 预处理 → 编译 → 目标文件 → 链接 → exe（图/表）；
     与 Python/JS 解释执行对比表；第 18 章伏笔
  4. 标准演进表：98 → 11（现代 C++ 分水岭）→ 14 → 17 → 20（四大件：concepts/ranges/
     协程/模块）→ 23（print/expected/generator）→ 26 一句话；本教程主线 20/23
  5. 三大编译器与工具链：MSVC/GCC/Clang 对照表（版本要求给 cppreference 编译器支持
     链接，不维护具体矩阵——吸收旧 README 两张支持表并简化）；本教程用 MSVC
     `/std:c++latest`（路径与参数引用 build.ps1）
  6. 本教程工作流：读章 → 跑示例 → 改代码再跑；build.ps1 三层验证说明；pwsh 7 注意
  7. 直接跑 exe 的中文乱码问题：`chcp 65001`（build.ps1 已统一处理，直跑时才需要）
  8. 24 章路线图（起步 02–07 / 类型系统与资源 08–15 / 抽象 16–18 / 并发 19–21 / 收尾 22–24）
  9. 学习心态一段：C++ 是"多范式工具箱"，教程教的是现代子集，不是全部
  10. `## 坑位清单`：只学老式 C++（裸 new/printf/char*）、拿 C++11 前资料入门、
      忽略编译器版本（写了 C++23 却用旧标准编译）、Windows 直跑乱码没设 chcp

- [ ] **Step 2: 写 02-hello.md**（约 170 行）：
  1. `# 02 · 第一个程序：从源码到 exe`
  2. 最小 main（引用 2.1）：签名、返回值约定（return 0 可省略但教程显式写）
  3. `std::print`/`std::println`（引用 2.2，C++23）：`{}` 占位符、`{:03}`/`{:.2f}`/`{:*^24}`
     格式速查表；为什么教程用它而不是 `printf`（类型安全）和 `cout`（冗长）
  4. iostream（引用 2.3）：`<<` 链式；老代码里到处是它，认得即可、新代码用 print
  5. 编译运行全流程：手工命令（cl 参数逐个解释——对照 Global Constraints 的编译参数
     铁律）、build.ps1 -Example 02_hello；main.cpp → obj → exe
  6. 中文与 UTF-8：/utf-8 参数的作用；chcp 65001；源文件保存为 UTF-8
  7. 注释、`//` 与 `/* */`、示例的分节注释约定说明（`// ═══ N.M` 帮你在文档与代码间跳转）
  8. `## 坑位清单`：忘 `;`、中文引号/全角符号混入源码、cout 混用 print 时缓冲不同步
     （endl 刷新）、双击 exe 闪退（命令行里跑）

- [ ] **Step 3: 写 03-types.md**（约 200 行）：
  1. `# 03 · 类型与变量：把数据放进盒子里`
  2. 基本类型表（引用 3.1）：int/double/char/bool + sizeof；字节数平台相关性；
     固定宽度 `std::int32_t/int64_t`；`1'000'000` 分隔符与 `LL` 后缀
  3. 字面量（引用 3.2）：0b/0x/十进制；42u/3.0f/2.5L 后缀表；`auto x = 0.5` 是 double
  4. auto（引用 3.3）：推导规则直觉（右值什么类型 auto 就什么）；什么时候显式写类型
  5. 初始化三式（引用 3.4）：`=`/`()`/`{}` 对比表；narrowing 演示（`int bad{3.14}` 编译错）；
     **教程约定：新代码一律 `{}`**（吸收旧 1.5 指定初始化器的动机，完整形态见第 06 章 struct）
  6. constexpr 入门（引用 3.5）：编译期常量；`static_assert` 当免费单测；数组长度场景；
     `<numbers>` 的 pi（吸收旧 2.8）
  7. 类型转换速查：`static_cast<int>(3.14)` 显式转换是唯一该写的转换；C 风格 `(int)` 禁用
  8. `## 坑位清单`：整数溢出（int 乘大数）、`0.5f` 与 `0.5` 精度差、有符号/无符号比较、
     未初始化变量读值是 UB、`char` 是否有符号看平台

- [ ] **Step 4: 写 04-control.md**（约 180 行）：
  1. `# 04 · 表达式与控制流：让程序有分支`
  2. if 与初始化语句（引用 4.1）：变量作用域限定在 if/else 内——**变量用在哪就声明在哪**
  3. switch（引用 4.2）：case 穿透必须显式 `[[fallthrough]]`；break 忘写的经典 bug；
     switch 只收整数/枚举（string 不行——对比其他语言）；default 惯例
  4. for/while（引用 4.3）：`++i` vs `i++` 一句话；死循环 `for (;;)` 惯例
  5. range-for（引用 4.4，吸收旧 1.1）：容器/数组/string 都能遍历；`for (const auto& x : v)`
     三种形式（值/引用/const 引用）选型表；**修改元素用 `auto&`，只读大对象用 `const auto&`**
  6. break/continue（引用 4.5）；嵌套循环只跳一层
  7. 运算符与隐式转换坑：`==` 与 `=`、整数除法 `5/2==2`、`%` 只用于整数
  8. `## 坑位清单`：switch 穿透漏 break、range-for 里对 vector 做 push_back（迭代器失效，
     第 10 章展开）、`unsigned` 倒序循环 `i >= 0` 永真、浮点数用 `==` 比较

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/*.md
```

预期：各 150–250 行；抽查 2.2/3.4/4.4 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 01–04 章 全景、hello、类型、控制流

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: docs/05–08 章

**Files:**
- Create: `docs/05-functions.md`（示例 `examples/05_functions/`）
- Create: `docs/06-compound.md`（示例 `examples/06_compound/`）
- Create: `docs/07-errors.md`（示例 `examples/07_errors/`）
- Create: `docs/08-classes.md`（示例 `examples/08_classes/`）

**Interfaces:**
- Consumes: Task 3/4 的四个示例；旧 README 1.5/1.7/1.8/3.1/2.1 素材。

- [ ] **Step 1: 写 05-functions.md**（约 200 行）：
  1. `# 05 · 函数：程序的乐高积木`
  2. 三种传参（引用 5.1–5.3）：值/引用/const 引用对比表（能不能改、拷不拷贝、适用场景）；
     **默认姿势：小类型按值、大对象 const 引用、要改就引用**
  3. 返回值：按值返回 + RVO 一句话（第 15 章展开）；多返回值预告（结构化绑定在第 06 章）
  4. 默认实参与重载（引用 5.4）：重载解析直觉；默认参数只能靠右
  5. `[[nodiscard]]`（引用 5.5）：丢弃返回值 → C4834 警告，为什么它值得开
  6. lambda 入门（引用 5.6）：就地定义函数对象；捕获初见 `[factor]`（第 11 章展开）；
     与函数指针/std::function 关系一句话
  7. 作用域与生命周期：块作用域、名字遮蔽；声明放使用之前（或用原型）
  8. `## 坑位清单`：返回局部变量的引用/指针（悬垂）、默认参数写在头文件、重载歧义
     （`f(int)` vs `f(double)` 传字面量）、lambda 捕获引用后局部变量死亡（第 11 章伏笔）

- [ ] **Step 2: 写 06-compound.md**（约 220 行）：
  1. `# 06 · 复合类型：struct、枚举与字符串`
  2. struct（引用 6.1）：聚合多个值；指定初始化器 (C++20，吸收旧 1.5)——字段按声明顺序、
     可省略；与 class 的区别一句话（第 08 章）
  3. 结构化绑定（引用 6.2，吸收旧 3.1）：`auto [a, b, c] = obj`；配 pair/tuple 的场景预告
  4. enum class（引用 6.3）：强作用域、不会隐式转 int（对比旧式 enum 的坑）；
     `static_cast<int>` 显式取值；switch 配枚举的好搭档（第 04 章回扣）
  5. std::string（引用 6.4）：常用操作速查表（+=/push_back/find/substr/size）；
     `contains` (C++23)；与 C 字符串 `char*` 的关系（认清即可，新代码别用）
  6. string_view（引用 6.5）：不拥有的只读视图；**头号坑：指向临时字符串的 view 悬垂**
     （`std::string_view sv = std::string("x");` 经典错误演示）
  7. span（引用 6.6，C++20，吸收旧 2.1）：数组/vector 的统一视图；const span 只读、
     非 const 写穿；subspan 切片；"接口收 span 而不是 vector&"的 API 设计感
  8. C 数组 vs std::array 一览（何时还得见 C 数组：第 03 章的编译期长度）
  9. `## 坑位清单`：string_view/span 悬垂（指向已销毁对象）、指定初始化器乱序编译错、
     enum class 忘 cast 直接 cout、struct 大值按值传参（用 const 引用）

- [ ] **Step 3: 写 07-errors.md**（约 220 行）：
  1. `# 07 · 错误处理：异常、optional 与 expected`
  2. 三种错误模型选型表（先给结论）：**预期内的失败 → expected/optional；真正的意外 →
     异常；程序员 bug → assert**（吸收旧 5.2 的 C++23 素材并重组织）
  3. 异常（引用 7.1）：throw/try/catch；按 `const std::exception&` 捕获；what()；
     标准异常家族表；异常安全一句话（RAII 是底气——第 08 章伏笔）
  4. optional（引用 7.2）：`std::nullopt`、`value_or`、`has_value`；对比返回 -1 表示
     失败的老 C 风格；单子操作 and_then/or_else/transform 一段（C++23）
  5. expected（引用 7.3，C++23）：值或错误都进类型；`unexpected` 构造；`value()/error()`；
     与 optional 的关系（expected 是"带理由的 optional"）
  6. 链式组合（引用 7.4）：and_then/transform 串起解析→除法，无嵌套无异常；
     对比"异常版"与"错误码版"同一段逻辑的三种写法表
  7. 断言（引用 7.5）：assert 语义、NDEBUG 下消失、assert 里别放副作用
  8. `## 坑位清单`：catch 按值捕获切对象、optional 直接 value() 没检查（抛 bad_access）、
     异常当流程控制（性能与可读性）、构造函数里抛异常（RAII 反而安全——第 08 章回扣）

- [ ] **Step 4: 写 08-classes.md**（约 250 行）：
  1. `# 08 · 类与 RAII：C++ 资源管理的灵魂`
  2. 从 struct 到 class（引用 8.1）：封装动机；public/private；成员函数；
     构造函数与成员初始化列表
  3. const 成员函数（引用 8.2）：const 对象只能调 const 方法；"能 const 就 const"
  4. **RAII**（引用 8.3）：析构函数 = 自动归还；作用域结束/异常/提前 return 三种退出
     都触发；Session 示例走读；**RAII 是 C++ 与 GC 语言最大的思维差异**（一段心智模型）
  5. 三路比较 `<=>`（引用 8.5，C++20，吸收旧 1.7）：一次定义全部六个运算符；
     `= default` 的相等；strong/partial/weak ordering 三档直觉（partial 因 NaN）
  6. 运算符重载（引用 8.4）：+/*/==；什么时候该重载（数学语义类）
  7. 拷贝控制与 rule of zero/five 一节：五件套是什么；` = delete` 禁拷贝（Session 示例）；
     **rule of zero：能不写就不写**（移动语义第 15 章展开）
  8. inline 静态成员（引用 8.6，吸收旧 1.8）：类内初始化；static 的"属于类不属于对象"
  9. deducing this 一瞥（引用 8.7，C++23）：显式对象形参；链式调用场景
  10. `## 坑位清单`：忘虚析构（第 16 章伏笔）、构造函数里调虚函数（还没到子类）、
      成员初始化顺序按声明不按列表顺序、返回成员引用被外部改

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/05*.md docs/06*.md docs/07*.md docs/08*.md
```

预期：各 150–250 行（08 可到 250）；抽查 5.3/6.6/7.4/8.3 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 05–08 章 函数、复合类型、错误处理、类与 RAII

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: docs/09–12 章

**Files:**
- Create: `docs/09-smartptr.md`（示例 `examples/09_smartptr/`）
- Create: `docs/10-containers.md`（示例 `examples/10_containers/`）
- Create: `docs/11-algorithms.md`（示例 `examples/11_algorithms/`）
- Create: `docs/12-ranges.md`（示例 `examples/12_ranges/`）

**Interfaces:**
- Consumes: Task 4/5 的四个示例；旧 README 3.4/4.1–4.4/2.4/2.8 素材。

- [ ] **Step 1: 写 09-smartptr.md**（约 240 行，吸收旧"智能指针深度指南"压缩重讲）：
  1. `# 09 · 动态内存与智能指针：所有权说话`
  2. 为什么还要 new/delete：堆的生命周期独立于作用域；裸指针的三大坑（泄漏/悬垂/双删）
  3. 所有权心智模型：**每个资源只有一个 owner**——这是现代 C++ 内存管理的第一原则
     （吸收旧 4.4 的核心理念，删掉旧教程的 42 个片段式展开）
  4. unique_ptr（引用 9.1）：独占；不可拷贝只可 move；`make_unique` 工厂；按值返回 =
     转移；`->` 与解引用；空指针判空
  5. 作用域即生命周期（引用 9.2）：RAII 回扣第 08 章；"new 出来的对象活多久？看 owner"
  6. shared_ptr（引用 9.3）：引用计数；use_count；make_shared（一次分配）；
     **"能用 unique 就别用 shared"**（开销与所有权清晰度）
  7. weak_ptr（引用 9.4）：观察不拥有；lock() 升级；打破循环引用的经典场景（图示：
     A↔B 互持 shared 的死锁）；缓存场景
  8. vector<unique_ptr>（引用 9.5）：容器持有动态对象的标准姿势（第 16 章多态展开）
  9. 性能与迁移一段（吸收旧 4.5/4.6 精华）：智能指针零开销（unique_ptr 就是裸指针）；
     老代码迁移顺序（先 unique 后 shared；禁 delete）
  10. `## 坑位清单`：两个 shared_ptr 从同一裸指针构造（双计数）、循环引用、
      shared_ptr 按值传参拷贝计数（移动或 const 引用）、get() 裸指针存起来（悬垂）

- [ ] **Step 2: 写 10-containers.md**（约 230 行）：
  1. `# 10 · 容器与迭代器：数据住哪`
  2. 容器选型表（全章总纲）：vector（默认）/deque/list/map/set/unordered_map/set/
     flat_map (C++23)——查找/插入复杂度与内存连续性三列
  3. vector（引用 10.1）：push_back/[]/size；**size() 是无符号数**（倒序循环坑回扣）；
     capacity 与 realloc 一句话（迭代器失效伏笔）
  4. map（引用 10.2）：有序键值；`[]` 的双面性（查不到就插入！）；find + 初始化语句
     （回扣第 04 章）；结构化绑定遍历
  5. set（引用 10.3）：去重 + 自动排序
  6. unordered_map（引用 10.4）：哈希表；O(1) 平均 vs O(n) 最坏；与 map 选型表
  7. 迭代器（引用 10.5）：begin/end 心智模型（半开区间）；`*`/`++`；iterator 与
     const_iterator；五大类一表（输入/输出/前向/双向/随机——一句话各给一个容器例子）
  8. erase_if（引用 10.6，C++20）：对比旧 erase-remove 惯用法（一段历史课）
  9. flat_map 一瞥（引用 10.7，C++23）：底层是排序 vector；缓存友好换插入成本
  10. `## 坑位清单`：遍历中 push_back/erase（迭代器失效——收集再改或 erase_if）、
      `[]` 误插入、map 的 [] 需要 value 默认可构造、 unordered_map 无序却依赖顺序

- [ ] **Step 3: 写 11-algorithms.md**（约 200 行）：
  1. `# 11 · 算法与 lambda：STL 的武器库`
  2. 心智模型：**算法 + 谓词 = 声明式循环**；手写循环 vs 算法对比（吸收 dotnet 09 章风格）
  3. sort（引用 11.1）：默认升序；lambda 比较器（字符串按长度）；`std::greater`
  4. 查找与计数（引用 11.2）：find_if/count_if/all_of/any_of/none_of 一表；
     返回迭代器怎么用（`*it`、`it != end()` 先检查）
  5. 数值与变换（引用 11.3）：accumulate（初始值类型陷阱：0 vs 0.0）、transform
  6. lambda 捕获详解（引用 11.4，第 05 章伏笔回收）：值捕获快照 vs 引用捕获实时
     （示例的 threshold 实验走读）；`[=]`/`[&]` 全捕获为何不推荐；mutable 一句话
  7. 泛型 lambda 与 std::function（引用 11.5）：auto 参数；std::function 是"函数变量"
     但有开销（能 auto 就 auto）
  8. 算法一览表：拷贝/替换/去重/反转/最大最小/划分（一行一算法）
  9. `## 坑位清单`：find_if 没检查就解引用（空容器）、accumulate 用 0 累加 double
     （截断）、lambda 引用捕获局部变量后异步使用（悬垂）、谓词带状态改变遍历

- [ ] **Step 4: 写 12-ranges.md**（约 220 行，吸收旧 2.4 并大幅扩展）：
  1. `# 12 · Ranges：惰性流水线思维`
  2. 问题先行：算法嵌套（sort(find_if(...))) 的读法灾难 → 管道 `|` 从左到右
  3. 管道三件套（引用 12.1）：filter/transform/`ranges::to` (C++23)；
     与 LINQ/list-comprehension 对照一段（会其他语言的读者秒懂）
  4. **惰性求值**（引用 12.2，本章最重要的心智模型）：视图不存储数据、按需计算；
     visited 打点实验走读（取 2 个只访问 2 个）；两次消费视图 = 两次计算
  5. 生成与裁剪（引用 12.3）：iota（无限序列！配 take）/take/drop/reverse
  6. ranges 算法 + 投影（引用 12.4）：`sort(v, greater{}, &Student::score)`——
     投影消灭"写比较器 lambda"的样板；ranges 算法直接收容器（不用 begin/end）
  7. 常用视图速查表：filter/transform/take/drop/reverse/iota/enumerate (C++23)/
     split/join 一行一个
  8. `## 坑位清单`：视图悬垂（管道引用了临时 vector）、无限视图忘了 take、
     视图存下来想二次使用（被动过）、filter 后再改容器（底层迭代器失效）

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/09*.md docs/10*.md docs/11*.md docs/12*.md
```

预期：各 150–250 行；抽查 9.4/10.2/11.4/12.2 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 09–12 章 智能指针、容器、算法、Ranges

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: docs/13–16 章

**Files:**
- Create: `docs/13-templates.md`（示例 `examples/13_templates/`）
- Create: `docs/14-concepts.md`（示例 `examples/14_concepts/`）
- Create: `docs/15-moves.md`（示例 `examples/15_moves/`）
- Create: `docs/16-inheritance.md`（示例 `examples/16_inheritance/`）

**Interfaces:**
- Consumes: Task 5/6 的四个示例；旧 README 1.2/3.3/4.5 素材。

- [ ] **Step 1: 写 13-templates.md**（约 200 行，吸收旧 3.3 入门部分）：
  1. `# 13 · 模板基础：把类型当参数`
  2. 动机：为 int 和 double 写两遍 max？→ 函数模板（引用 13.1）；模板不是代码是
     "代码生成器"（实例化发生在编译期）
  3. 类模板（引用 13.2）：Stack<T> 走读；模板成员函数隐式 inline
  4. 非类型模板参数（引用 13.3）：`std::size_t N`；std::array 的长度为什么是模板参数
  5. CTAD（引用 13.3 末尾）：`Stack copied{ints}` 推导出 Stack<int>；
     `std::vector v{1,2,3}` 同理
  6. 编译期多态 vs 运行期多态：模板（静态分发、零开销、代码膨胀）vs 虚函数
     （动态分发、一个入口）选型表——**第 16 章的伏笔在此对照**
  7. 模板错误信息长什么样：贴一段真实的 vector<int> 无 + 报错，教读者"从最里面
     那行人话开始读"——引出第 14 章概念
  8. `## 坑位清单`：模板定义要可见（头文件原因，第 18 章展开）、隐式实例化的代码膨胀、
      `Stack<int>` 与 `Stack<double>` 是两个毫无关系的类型、声明依赖 template 关键字
      （一句话带过 `.template`）

- [ ] **Step 2: 写 14-concepts.md**（约 200 行，吸收旧 1.2 大幅扩展）：
  1. `# 14 · 概念：给模板参数立规矩`
  2. 痛点先行（回扣第 13 章末尾的报错墙）：约束写进类型系统，错误从"模板内部深处"
     提前到"调用点"
  3. requires 表达式（引用 14.1）：`{ a + b } -> std::convertible_to<T>` 逐词拆解；
     简单 requires（表达式合法性）一段
  4. 三种用法（引用 14.2）：`template<Addable T>` / `requires` 子句 / 简写
     `void f(std::integral auto x)`——三选一的风格建议
  5. 标准库概念速查表：same_as/convertible_to/integral/floating_point/
     equality_comparable/totally_ordered/range 一行一个
  6. 约束重载（引用 14.3）：integral vs floating_point vs 兜底——**用约束替代
     tag dispatch/enable_if 的老黑魔法**（吸收旧教程的"部分排序"并简化）
  7. static_assert 验证概念（引用 14.4）：概念是编译期布尔——能 assert、能 if constexpr
     （第 17 章伏笔）
  8. `## 坑位清单`：概念约束的是"能做什么"不是"是什么"（鸭子类型直觉）、
      重载约束有包含关系时选更严格的、auto 参数 + 概念的组合位置写错

- [ ] **Step 3: 写 15-moves.md**（约 230 行，吸收旧 4.5 性能部分）：
  1. `# 15 · 移动语义：别拷贝，搬走它`
  2. 值类别心智模型：lvalue（有名字、可取地址）vs rvalue（临时、将死）；
     一张"表达式左右"速查表——**记住直觉：能放左边的是 lvalue**
  3. 拷贝 vs 移动（引用 15.1，Tracer 走读）：移动 = 把资源"搬"走，源进入有效但未定状态；
     `std::move` 不移动任何东西，只是"改成右值"的类型转换（本章最反直觉的一点）
  4. 移动构造与 noexcept（示例代码）：为什么 noexcept 重要（vector 扩容才敢用移动）
  5. 容器场景（引用 15.2）：push_back 右值 vs std::move(具名)；reserve 排除扩容干扰
  6. RVO（引用 15.3）：C++17 保证的复制消除——**别写 `return std::move(local)`**
     （反而关闭 RVO 的经典错误）
  7. 完美转发（引用 15.4）：转发引用 `T&&` + `std::forward`；relay 左值/右值实验走读；
     为什么需要（保持值类别穿越模板）
  8. rule of five 收尾（回扣第 08 章）：五件套到此集齐；**rule of zero 仍是首选**
  9. `## 坑位清单`：move 后继续用源对象（未定状态）、`return std::move(local)`、
      成员该 move 却拷贝（在成员初始化列表用 std::move）、转发引用重载吞掉精确匹配

- [ ] **Step 4: 写 16-inheritance.md**（约 220 行）：
  1. `# 16 · 继承与多态：同一接口，多种实现`
  2. 基类与纯虚函数（引用 16.1）：抽象类定契约；override 显式覆写（拼错即编译错）
  3. **虚析构**（示例 16.1 注释）：为什么必须——unique_ptr<Shape> 删 Dog 时没虚析构
     = UB；=default 即可
  4. 动态分派机制一段（心智模型不展开汇编）：虚表 = 每类一张函数表，对象带指针
  5. 多态容器（引用 16.1）：vector<unique_ptr<Shape>>——第 09 章伏笔回收
  6. dynamic_cast（引用 16.2）：带检查下转；返回 nullptr 的处理；"需要 dynamic_cast
     通常是设计味道"
  7. 切片（引用 16.3）：按值收基类削平子类——sliced vs ref 输出对照走读
  8. **组合优于继承**（引用 16.4）：继承表达"是一个"、组合表达"有一个"；
     用组合 + 概念（第 14 章）替代部分继承场景的现代观
  9. `## 坑位清单`：忘虚析构、基类构造中调虚函数、公开继承却重写非虚函数（隐藏）、
      通过基类引用调赋值（切片）、深层继承链（>2 层 reconsider）

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/13*.md docs/14*.md docs/15*.md docs/16*.md
```

预期：各 150–250 行；抽查 13.2/14.3/15.4/16.3 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 13–16 章 模板、概念、移动语义、继承多态

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 14: docs/17–20 章

**Files:**
- Create: `docs/17-compiletime.md`（示例 `examples/17_compiletime/`）
- Create: `docs/18-modules.md`（示例 `examples/18_modules/`）
- Create: `docs/19-threads.md`（示例 `examples/19_threads/`）
- Create: `docs/20-atomic.md`（示例 `examples/20_atomic/`）

**Interfaces:**
- Consumes: Task 7/8 的四个示例；旧 README 1.3/1.4/1.6/6.1–6.3/6.5 素材。

- [ ] **Step 1: 写 17-compiletime.md**（约 200 行，吸收旧 1.6 深入部分）：
  1. `# 17 · 编译期编程：让计算发生在编译时`
  2. constexpr 函数（引用 17.1）：同一份代码两个世界；constexpr 变量强制编译期求值
  3. static_assert（引用 17.1）：编译期断言当单测；与运行时 assert 的分工表
  4. consteval（引用 17.2，C++20）：只许编译期——数组长度等硬约束场景
  5. if constexpr（引用 17.3，C++17）：编译期剪枝；未选中分支不实例化（模板里
     才显威力）；与概念联动（第 14 章回扣）
  6. 变参模板与 fold（引用 17.4，C++17）：参数包 `...`；四种 fold 一表（一元/二元 ×
     左/右）；`(values + ...)` 逐符号拆解
  7. 编译期编程的边界：constexpr 里能干什么（循环/分支/局部变量）/不能干什么
     （虚调用、IO）；模板元编程一句带过（旧时代黑魔法，现代用 constexpr + concepts）
  8. `## 坑位清单`：constexpr 函数偷偷依赖全局可变状态（不成立）、if constexpr 写在
      非模板里没意义、fold 空参数包（`+` 无单位元）、编译时间爆炸

- [ ] **Step 2: 写 18-modules.md**（约 220 行，吸收旧 1.4 并做真模块——旧示例造假问题
  在此修正）：
  1. `# 18 · 编译单元与模块：#include 的接班人`
  2. 翻译单元与 ODR（先补地基）：一个 .cpp = 一个翻译单元；ODR（名字只能定义一次）；
     头文件 = 文本粘贴的暴力本质（为什么 include guard/#pragma once 存在）
  3. 声明 vs 定义：`int add(int, int);` vs 实现；为什么库作者分开写
  4. inline 的真实含义（不是"内联优化"而是"允许多重定义"）
  5. **C++20 模块**（引用 math.ixx/main.cpp）：export module / export / import 三件套；
     模块接口单元 vs 实现单元一句话；import 的语义（不是文本粘贴——编译器真正理解边界）
  6. 手工编译全流程（main.cpp 头部注释的两步命令逐参数讲）：`/interface /c` 产
     .obj + .ifc；主程序链接；**为什么 build.ps1 要特判 .ixx**（引 build.ps1 实现一段）
  7. 模块 vs 头文件对比表：编译速度（不用反复解析同义头）、隔离性（未 export 的
     辅助函数真私有）、迁移成本；`import std;` 与生态现状一段（工具链支持不齐，
     建议新模块新项目尝鲜）
  8. 静态库/动态库一段：lib/dll 是链接层的事（模块是源码层的事，别混淆）
  9. `## 坑位清单`：.ixx 没用 /interface 编（找不到模块）、模块名与文件名不一致
      导致 /reference 对不上、混用 include 与 import 的过渡期写法、全局模块片段
      `module;` 一句话

- [ ] **Step 3: 写 19-threads.md**（约 240 行，吸收旧 6.1/6.2 压缩重讲）：
  1. `# 19 · 并发 I：线程与锁`
  2. 心智模型：并发 = 同时做多件事；并行 = 同时做多件事的多核版；数据竞争定义
     （两个线程同时读写同一位置、至少一个是写 = UB）
  3. jthread（引用 19.1，吸收旧 6.1 的 thread/jthread 对照并简化）：构造即启动、
     析构自动 join；stop_token 协作式取消（**为什么不能强杀线程**一段）
  4. mutex + lock_guard（引用 19.2，吸收旧 6.2 核心）：RAII 锁回扣第 08 章；
     unique_lock 与 lock_guard 选型；"锁保护数据而不是代码段"的设计观
  5. 条件变量（引用 19.3）：wait + 谓词（防虚假唤醒）；notify_one/notify_all；
     生产者-消费者走读；**队列空/满的两类等待**
  6. 死锁一节：双锁顺序颠倒的构造反例（注释形式）；std::scoped_lock 一次锁多把
  7. 什么时候需要多线程一段：IO 密集（等待重叠）vs CPU 密集（分核）；
     "先测量再并发"（第 24 章实战会真用上）
  8. `## 坑位清单`：忘 join（jthread 免了）、锁里调未知代码（回调再拿锁→死锁）、
      条件变量忘谓词、按引用捕获捕获局部变量给线程（悬垂）、detach 的滥用

- [ ] **Step 4: 写 20-atomic.md**（约 230 行，吸收旧 6.3/6.5 压缩重讲）：
  1. `# 20 · 并发 II：原子操作与同步原语`
  2. atomic（引用 20.1）：fetch_add；**relaxed 只保证原子性不保证顺序**——计数器够用；
     对比第 19 章 mutex 版（什么时候 mutex 什么时候 atomic 选型表）
  3. 内存序一段（点到为止）：sequentially_consistent 默认最稳；acquire/release 一句话；
     **"不懂就别写非默认序"**是本节的全部建议
  4. latch（引用 20.2）：一次性发令枪；分段求和走读（各写各的槽位=无竞争的分工模式）
  5. barrier（引用 20.3）：可复用的全员集合点；与 latch 对比表
  6. semaphore 一段（吸收旧 6.2）：限流 N 个并发——不进示例，给骨架代码块
  7. 并行算法（引用 20.4）：`std::execution::par`；for_each/sort/count_if 一表；
     **谓词必须线程安全**（示例里用 atomic 累加的原因）
  8. false sharing 一句话（数组槽位为什么分块而不是交错——性能彩蛋）
  9. `## 坑位清单`：atomic 上调复合操作仍要 CAS 循环（compare_exchange_weak 骨架）、
      parallel 算法里加锁（并行白干）、内存序乱用、忙等（该用条件变量/信号量）

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/17*.md docs/18*.md docs/19*.md docs/20*.md
```

预期：各 150–250 行；抽查 17.4/18.6（手工命令）/19.3/20.2 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 17–20 章 编译期、模块、线程、原子

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 15: docs/21–24 章

**Files:**
- Create: `docs/21-coroutines.md`（示例 `examples/21_coroutines/`）
- Create: `docs/22-textfiles.md`（示例 `examples/22_textfiles/`）
- Create: `docs/23-tooling.md`（示例 `examples/23_tooling/`）
- Create: `docs/24-minigrep.md`（示例 `examples/24_minigrep/`）

**Interfaces:**
- Consumes: Task 8/9 的四个示例；旧 README 1.3/2.2 深入/2.7/5.2/6.4/6.6/6.7/第 7 章素材。

- [ ] **Step 1: 写 21-coroutines.md**（约 230 行，吸收旧 1.3/6.4/6.7）：
  1. `# 21 · 协程：可暂停的函数`
  2. 心智模型：普通函数一进一出；协程能**暂停（yield）后恢复**——栈帧搬到了堆上
  3. 两个关键词先学：co_yield（交出一个值并暂停）、co_await（等待可等待物）——
     co_return 一句话（吸收旧 1.3 的"C++20 只有底层机制"认知并展开）
  4. 手写 Generator（引用 21.1 逐段走读）：promise_type（协程与外界的中介）；
     get_return_object/initial_suspend（为什么 suspend_always=惰性）/yield_value；
     coroutine_handle 的 resume/destroy；iterator 接口
  5. 用生成器（引用 21.2）：fibonacci 的 co_yield 版 vs 递归/循环版对比——
     "把序列当流消费"
  6. std::generator（引用 21.3，C++23）：标准库替你写完了 21.1；迁移建议
  7. 惰性证明（引用 main 末段）：只取 3 个不算到百万——与第 12 章 ranges 惰性呼应
  8. 协程生态一段（吸收旧 6.7）：task/when_all 要靠库（cppcoro、P2300 std::execution）；
     C++26 展望一句话；**教程边界：会写/会用 generator，理解 co_await 机制即可**
  9. `## 坑位清单`：Generator 忘 destroy（内存泄漏）、协程里捕获引用参数（帧还在引用没了）、
      手写 promise 忘 noexcept 的 final_suspend（编译错）、把协程当回调存起来重复 resume

- [ ] **Step 2: 写 22-textfiles.md**（约 240 行，吸收旧 2.2 深入/2.7/5.2 文本部分）：
  1. `# 22 · 文本与文件：格式化、正则与文件系统`
  2. format 深入（引用 22.1）：对齐/填充/精度/类型（x/b/百分比）速查表；
     format vs print；format_to（进字符串/缓冲）；**中文宽度按码点计，对齐不完美**
     （实测坑写进文档）
  3. regex（引用 22.2）：R"(...)" 原始字符串（为什么需要——反斜杠地狱）；
     regex_match/regex_search/regex_replace 三分工；捕获组 str(n)；
     sregex_iterator 遍历全部匹配；**std::regex 很慢**（编译也慢）——热路径换手写或
     第三方库一段
  4. filesystem（引用 22.3）：path 拼接的 `/` 运算符；create_directories；
     directory_iterator vs recursive_directory_iterator；is_regular_file 判型；
     remove_all；**遍历顺序不保证**（示例先收集再 sort 的原因）；错误处理
     （error_code 重载 vs 异常重载）
  5. 文件读写补充（示例 22.3 内的 ofstream 用法）：ofstream/ifstream；`<<`/rdbuf
     整读；fstream 与 print 的关系
  6. UTF-8 与编码一段：源码 /utf-8；运行时中文（chcp 65001 回扣第 02 章）；
     char8_t 一句话（C++20 的历史包袱）；"程序按 UTF-8 字节处理，显示交给终端"
  7. stacktrace 一瞥（吸收旧 2.7，详见第 23 章）：`std::stacktrace::current()` 一行
     值多少钱——定位"从哪来"
  8. mdspan 一瞥（引用 22.4，C++23）：二维视图零拷贝；`grid[r, c]` 下标语
     （本机实测无 `grid(r,c)`——工具链差异写明）
  9. `## 坑位清单`：regex 每次循环重构造（编译开销）、路径拼接手写 `/` 与反斜杠混用、
      遍历时修改目录、ofstream 析构前读文件（未 flush）、relative path 依赖 cwd

- [ ] **Step 3: 写 23-tooling.md**（约 230 行，吸收旧第 7 章调试指南压缩重讲）：
  1. `# 23 · 测试、调试与工具生态`
  2. 自造单测框架（引用 23.1–23.2）：TestCase + assert 的十行框架走读；
     slugify 被测函数的"纯函数可测性"设计观；**真实项目用 GoogleTest/Catch2/doctest**
     一段选型（本教程零依赖所以手造）
  3. assert 的正确用法：不变量而非业务校验；NDEBUG 编译期移除；副作用禁入
  4. 调试器基础（吸收旧 7.1/7.3）：VS 断点/单步/监视窗口工作流（配图文字版）；
     **cout 调试法**何时还值得用；条件断点/数据断点一句话
  5. 并发调试（吸收旧 7.1/7.4）：race 的复现困难；日志加序号；TSan 一句话
     （MSVC 无 TSan，Linux/Clang 有——诚实标注）；"把并发问题缩小成单线程测试"
  6. stacktrace（引用 23.3，C++23）：出错路径打印；与 assert 组合
  7. 构建生态一节：CMake 最小示例（15 行骨架：add_executable + C++23 标准）；
     vcpkg 装库三行；MSVC vs g++/clang 差异表（吸收旧编译器支持章：/std:c++latest
     vs -std=c++23、/utf-8 默认与否、模块标志差异）
  8. 静态分析一句：/analyze 与 clang-tidy
  9. `## 坑位清单`：测试依赖执行顺序、断言里调函数（副作用）、调试 Release 版对不上、
      只测 happy path、CMake 里忘设 C++ 标准（默认 C++14 编译不过 C++20 代码）

- [ ] **Step 4: 写 24-minigrep.md**（约 260 行，实战章）：
  1. `# 24 · 实战：迷你 grep`
  2. 成品演示：`minigrep <dir> <pattern> [-i] [-t N]`；手工运行示例
     （`./build/24_minigrep.exe examples/24_minigrep warning -i`）与预期输出
  3. 需求与分解：搜目录 → 多线程 → 高亮输出；**多文件工程的组织**（search/output/
     main 三层分离——接口先行，吸收第 18 章头文件组织）
  4. 搜索层走读（search.h/search.cpp）：Match 结构；find_in_line 的朴素匹配
     （为什么不用 regex——性能与教学双理由）；大小写折叠的 tolower 手法；
     按行切分逻辑；`#pragma once`
  5. 输出层走读（output.cpp）：ANSI 转义高亮；`file:line:text` 惯例（对齐真 grep）；
     分层让"换 GUI 输出"不动搜索层
  6. 参数解析（引用 24.1）：手写 argv 循环（够用）；为什么不用第三方 CLI 库一句话
  7. 自检模式（引用 24.2）：内置临时目录 + 断言——**可验证的示例才有资格进 build.ps1**
     （呼应第 23 章测试观）
  8. 多线程搜索（引用 24.3）：原子游标 fetch_add 瓜分任务（吸收旧 6.6 线程池思想并
     简化为 15 行——"线程池的本质：任务队列 + 一组常驻工人"一段对照）；
     打印互斥锁（输出不交错）；jthread 自动 join（第 19 章回扣）
  9. 组装与退出码（main）：0=有命中/1=无命中/2=用法错误的惯例讨论
     （本示例统一 0，真工具按惯例——教学取舍说明）
  10. 扩展方向：正则模式、彩色统计、--include 过滤、管道/流式大文件、async IO
  11. `## 坑位清单`：递归遍历把符号链接绕成环（follow_directory_symlink 默认关）、
       二进制文件当文本搜（乱码输出——真 grep 有 -I）、线程数超过文件数白开、
       输出未加锁交错、退出码与脚本集成不严肃

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20 && wc -l docs/21*.md docs/22*.md docs/23*.md docs/24*.md && ls docs | wc -l
```

预期：各 150–260 行；docs/ 共 24 个文件；抽查 21.1/22.2/23.2/24.3 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(cpp20): 第 21–24 章 协程、文本文件、工具链、实战 grep

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 16: 清理旧文件 + README 重写 + CHEATSheet + 根 README 微调

**Files:**
- Delete: `snippets/`（82 个文件）、`examples/*.cpp`（16 个旧平文件）
- Create: `README.md`（重写）、`CHEATSheet.md`
- Modify: 仓库根 `README.md`（cpp20 描述两处）

**Interfaces:**
- Consumes: docs/ 24 章与 examples/ 23 个目录（索引表引用它们）。
- Produces: 最终目录形态：README/docs/examples/build.ps1/CHEATSheet.md。

- [ ] **Step 1: 删除旧文件**

```bash
cd /g/code/guide/cpp20
git rm -q -r snippets
# 只删 examples 下的旧"平文件"（路径恰好两段：examples/xxx.cpp）。
# 注意：git 通配符会跨目录匹配，'examples/*.cpp' 会误删新示例目录里的 main.cpp，
# 所以用 awk 按路径段数过滤。
git ls-files examples | awk -F/ 'NF==2' | while read f; do git rm -q "$f"; done
git status --short | head -8
ls examples | head -5   # 只剩 NN_name 目录
```

- [ ] **Step 2: 重写 README.md**（约 60 行，对齐 dotnet README 格式）：
  1. `# C++ 编程指南（C++20/23）`；定位段：面向**会编程、初学 C++** 的读者；主线
     C++23（兼容讲 20），MSVC /std:c++latest 验证；每章"读讲解 → 跑示例 → 改代码再跑"
  2. 目录结构代码块（README/docs/examples/build.ps1/CHEATSheet.md 各一行注释）
  3. **24 章索引表**（三列：章主题链接 | 主题 | 示例目录；01 无示例）
  4. 构建工具链：vcvars 路径、编译参数一行、pwsh 7 要求、直接跑 exe 的 chcp 65001
  5. 编译验证命令块（-All/-Example/-Clean + 三层验证一句话）
  6. 单跑某个示例：`cd examples/12_ranges && cl ... main.cpp`（标准学法：改了再跑）
  7. 相关教程链接：win32/mfc/wpf（GUI 方向）、boost（库方向）、dotnet C# 对照

- [ ] **Step 3: 写 CHEATSheet.md**（约 220 行）：
  1. `# C++20/23 速查表`（开头注明配教程使用、按章号引用）
  2. 编译命令：build.ps1 三式 + 手工 cl 全参数 + 模块两步 + chcp
  3. 程序骨架：main + print 三行模板
  4. 按主题速查（每节骨架代码 + 指回章节号）：类型与初始化（03）/控制流（04）/
     函数传参三式（05）/struct·enum·string·view·span（06）/错误三件套
     expected·optional·assert（07）/类·RAII·spaceship（08）/智能指针选型（09）/
     容器选型表（10）/常用算法一表（11）/ranges 管道常用组合（12）/模板与概念
     约束写法（13–14）/move 与 forward（15）/虚函数骨架（16）/constexpr·if
     constexpr·fold（17）/模块三行（18）/jthread·mutex·条件变量骨架（19）/
     atomic·latch·barrier（20）/generator 骨架（21）/format 规格·regex·filesystem
     常用（22）/单测骨架（23）
  5. 坑位索引：每章坑位清单的标题级汇总（一行一坑，标章号）

- [ ] **Step 4: 微调根 README.md**

`G:\code\guide\README.md` 中（先 grep 定位再改）：
- 第 24 行 `- [cpp20](./cpp20) — C++20 教程与示例，适配 MSVC/Windows 构建` 改为
  `- [cpp20](./cpp20) — C++ 从零到 C++20/23 教程（24 章 + 迷你 grep 实战，MSVC 主线）`
- 第 87 行附近的 `4. [cpp20](./cpp20)` 保持链接不变，若行文含"教程与示例"字样同步微调。

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/cpp20
ls && ls docs | wc -l && ls examples | wc -l   # 预期 5 项 / 24 / 23
git status --short | wc -l
```

```bash
git add -A && git commit -m "docs(cpp20): 重写 README、新增 CHEATSheet、清理旧指南与 snippets

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

（根 README 的修改也在本任务一并提交；若 git status 显示根 README 变更，确认在
`git add -A` 范围内——工作目录是仓库根的子目录，`git add -A` 从仓库根生效。）

---

### Task 17: 终验（全量 -All + 一致性检查 + 收尾）

**Files:**
- 无新文件（发现问题回修后重跑）

- [ ] **Step 1: 全量验证**

```bash
cd /g/code/guide/cpp20 && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All 2>&1 | tail -25
```

预期（逐项核对）：23 个示例各 `[Module]`（仅 18）/`[Compile]`/`[Run]` 依次通过，
零 warning，运行输出含各自"自检通过"；末行 `[Done] 全部 23 个示例编译+运行通过。`。
全程约 1–3 分钟。

- [ ] **Step 2: 一致性与卫生检查**

```bash
cd /g/code/guide/cpp20
ls docs | wc -l && ls examples | wc -l && wc -l docs/*.md | tail -1
git ls-files | grep -c "^snippets/" || echo "snippets 已清"
git ls-files examples | awk -F/ 'NF==2' | wc -l   # 预期 0：旧平文件已清（目录内 cpp 是三段路径）
grep -c "docs/" README.md               # 预期 24（索引表链接）
```

预期：docs 24 个、examples 23 个、docs 总行数 4500–6000；README 含 24 个链接；
抽查三章代码片段与 examples 逐字一致（3.4/15.4/24.3）。

- [ ] **Step 3: 清理与收尾**

```bash
cd /g/code/guide/cpp20 && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && git status --short
```

预期：`git status` 干净（build/ 已清且不入库）。若有未提交变更，补提交。

- [ ] **Step 4: Commit（如有收尾变更）**

```bash
git add -A && git commit -m "chore(cpp20): 教程终验收尾

Co-Authored-By: Claude Code <noreply@anthropic.com>" || echo "无收尾变更，跳过"
```

- [ ] **Step 5: 勾选计划与勘误归档**

把本文件中所有 `- [ ]` 勾选为 `- [x]`；实施期间如有偏差（API 不符、编译失败后调整），
在文末追加 `## 执行勘误（YYYY-MM-DD 实施时对计划的修正）` 表格记录（参照 flutter 计划
的勘误表格式：位置 | 偏差 | 原因），并单独提交：

```bash
cd /g/code/guide && git add docs/superpowers/plans/2026-09-17-cpp20-tutorial-rewrite.md
git commit -m "docs: 勾选 cpp20 教程实施计划全部任务并记录执行勘误

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```
