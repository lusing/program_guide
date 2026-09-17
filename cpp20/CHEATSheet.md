# C++20/23 速查表

配 [C++ 教程](README.md) 使用：按主题给骨架代码与坑位，括号内为章节号。

## 编译命令（01）

```bash
# Windows：build.ps1（pwsh 7）
pwsh -ExecutionPolicy Bypass -File build.ps1 -All / -Example 06_compound / -Clean

# 手工（先 vcvars64.bat）
cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 main.cpp
chcp 65001   # 直接跑 exe 时防中文乱码

# 模块两步（18）
cl /std:c++latest /interface /c /ifcOutput build\m.ifc math.ixx
cl /std:c++latest /reference math=build\m.ifc main.cpp build\m.obj
```

```bash
# macOS / Linux：两条通道（clang++ 23 主 + g++ 15 对照），与上面等价
./run-all.sh              # / -v 看完整输出 / ./run-all.sh 18 22 按编号

# 手工编译单文件：那三个开关是 macOS 上能不能编过的分水岭（见 README 兼容性一节）
#   -L/-Wl,-rpath/-lc++ 属于"链接期"参数，放在命令行末尾即可
#   下面用短名 clang++-mp-23（MacPorts 装在 /opt/local/bin）；不在 PATH 里就写 /opt/local/bin/clang++-mp-23
clang++-mp-23 -std=c++23 -Wall -Wextra -O2 \
  -D_LIBCPP_DISABLE_AVAILABILITY -fexperimental-library \
  main.cpp -o demo \
  -L/opt/local/libexec/llvm-23/lib/libc++ -Wl,-rpath,/opt/local/libexec/llvm-23/lib/libc++ -lc++ \
  -L/opt/local/libexec/llvm-23/lib/libunwind -Wl,-rpath,/opt/local/libexec/llvm-23/lib/libunwind

# 模块三步（18）：clang 用 --precompile 出 .pcm；gcc 用 -fmodules-ts（产物落 ./gcm.cache）
CF="-std=c++23 -Wall -Wextra -O2 -D_LIBCPP_DISABLE_AVAILABILITY -fexperimental-library"
LD="-L/opt/local/libexec/llvm-23/lib/libc++ -Wl,-rpath,/opt/local/libexec/llvm-23/lib/libc++ -lc++"
LD="$LD -L/opt/local/libexec/llvm-23/lib/libunwind -Wl,-rpath,/opt/local/libexec/llvm-23/lib/libunwind"
clang++-mp-23 $CF -x c++-module math.ixx --precompile -o math.pcm
clang++-mp-23 $CF -fmodule-file=math=math.pcm -c main.cpp -o main.o
clang++-mp-23 $CF $LD math.pcm main.o -o demo    # 只有这一步才需要 $LD
```

> 编译期步骤**不要**带 `-L/-lc++/-rpath`：clang 会报 5 条
> `unused-command-line-argument` 告警（本教程要求零告警，两个入口也是这么分的参数）。
> 另外 `$CF` / `$LD` 这种「靠空格分词」的写法**只在 bash 下成立**；macOS 默认 shell 是 zsh，
> 那里要写成 `${=CF}`，或者干脆写成脚本并以 `#!/bin/bash` 开头。

## 程序骨架（02）

```cpp
#include <print>

int main() {
    std::println("你好，{}！", "C++23");   // println 自动换行
    std::print("{:>8.2f}\n", 3.14159);    // 宽 8、两位小数、右对齐
    return 0;
}
```

## 类型与初始化（03）

```cpp
auto x = 42;        // int
auto d = 0.5;       // double（要 float 写 0.5f）
int a{10};          // {} 初始化：拦 narrowing（int bad{3.14} 编译错）
constexpr double tau = 2.0 * std::numbers::pi;   // <numbers>
static_assert(tau > 6.28);                        // 编译期断言
```

## 控制流（04）

```cpp
if (auto pos = s.find("x"); pos != std::string::npos) { /* ... */ }  // if 带初始化
switch (level) { case 3: [[fallthrough]]; case 1: break; default: break; }  // 穿透必显式
for (const auto& item : container) { /* ... */ }   // 默认 const 引用
```

## 函数传参三式（05）

```cpp
void f(small_t x);                 // 小类型按值
void modify(T& x);                 // 要改：引用
void read(const big_t& x);         // 大对象只读：const 引用
void greet(const std::string& n, const std::string& g = "你好");  // 默认实参靠右
auto add = [factor](int v) { return v * factor; };  // lambda 值捕获
```

## 复合类型（06）

```cpp
struct Book { std::string title; double price; int pages; };
Book b{.title = "C++", .price = 89.5, .pages = 420};   // 指定初始化器：按声明顺序
auto [t, p, n] = b;                                     // 结构化绑定
enum class Format { paperback, hardcover };             // 强类型枚举
int sum(std::span<const int> v);                        // 数组/vector 通吃的只读视图
// 悬垂警钟：string_view/span 不拥有数据，别指向临时对象
```

## 错误处理三件套（07）

```cpp
std::optional<int> find(void);                    // 可能有
std::expected<int, std::string> parse(std::string_view s);  // 值或错误（C++23）
auto r = parse("42").transform([](int v) { return v * 2; });  // 链式
assert(idx >= 0 && "不变量");                     // 开发期断言
```

## 类与 RAII（08）

```cpp
class Session {
public:
    explicit Session(std::string name);
    ~Session();                       // 析构 = 自动还资源（异常也拦不住）
    Session(const Session&) = delete; // rule of zero 优先：成员自己管自己
private:
    std::string name_;
};
bool operator==(const Vec2&) const = default;        // C++20 默认相等
auto operator<=>(const Vec2& o) const = default;     // 三路比较：六个运算符一把抓
```

## 智能指针（09）

```cpp
auto u = std::make_unique<Task>(args);   // 独占（默认选择，零开销）
auto s = std::make_shared<Task>(args);   // 共享（引用计数，确需才用）
std::weak_ptr<Task> w = s;               // 观察（lock() 升级，破循环）
auto moved = std::move(u);               // 转移所有权；u 变空
// 禁：裸 new/delete、get() 裸指针存起来
```

## 容器（10）

```cpp
std::vector<T> v;                 // 默认选择
std::map<K, V> m;                 // 有序键值（[] 会误插入！只读用 find/contains）
std::unordered_map<K, V> um;      // 哈希 O(1) 平均
std::erase_if(v, pred);           // C++20 一行过滤（替代 erase-remove）
for (const auto& [k, val] : m) {} // 结构化绑定遍历
v.emplace_back(args...);          // 原地构造，省一次搬移
```

## 算法与 lambda（11）

```cpp
std::sort(v.begin(), v.end(), std::greater{});      // 降序
auto it = std::find_if(v.begin(), v.end(), pred);   // 用前判 it != end()
int n  = std::count_if(v.begin(), v.end(), pred);
double s = std::accumulate(v.begin(), v.end(), 0.0);  // 初始值定累加类型！
int thr = 4;
auto by_val = [thr](int x) { return x > thr; };    // 值捕获：快照
auto by_ref = [&thr](int x) { return x > thr; };   // 引用捕获：实时（防悬垂）
```

## Ranges（12）

```cpp
auto out = data | std::views::filter(pred)
                 | std::views::transform(f)
                 | std::ranges::to<std::vector>();   // C++23 收集
std::ranges::sort(v, std::greater{}, &Item::score); // 投影消灭比较器
for (auto [i, x] : v | std::views::enumerate) {}    // C++23 带索引
// 惰性：提前停用手动 for+break（MSVC 的 to 会抽干 filter——实测坑）
// 无限序列 iota(1) 必须 take
```

## 模板与概念（13/14）

```cpp
template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;
};
template <Addable T>               // 约束写上签名
T sum_all(const std::vector<T>& xs) { /* ... */ }
static_assert(Addable<int>);       // 概念是编译期布尔
// 约束重载：同族形参形式必须一致（都 const T&）
```

## 移动语义（15）

```cpp
Widget b = std::move(a);              // 转移：a 变"有效但未定"，别再用
Widget make() { return Widget{...}; } // RVO：按值返回，别写 return std::move(local)
template <typename T>
void relay(T&& arg) { target(std::forward<T>(arg)); }  // 完美转发
// 移动构造/赋值记得 noexcept（容器扩容才敢用）
```

## 虚函数骨架（16）

```cpp
class Shape {
public:
    virtual ~Shape() = default;        // 铁律：多态必虚析构
    virtual double area() const = 0;   // 纯虚 → 抽象类
};
class Circle : public Shape {
public:
    double area() const override { /* ... */ }  // override 必写
};
std::vector<std::unique_ptr<Shape>> shapes;      // 多态容器（值传递会切片！）
```

## 编译期（17）

```cpp
constexpr unsigned long long factorial(unsigned n) { /* for 循环即可 */ }
consteval int square(int v) { return v * v; }     // 只许编译期
if constexpr (std::is_arithmetic_v<T>) { ... }    // 编译期剪枝（模板里）
template <typename... Ts>
auto sum_all(Ts... vs) { return (0 + ... + vs); } // fold（空包安全）
```

## 并发（19/20）

```cpp
std::jthread worker{[](std::stop_token st) { while (!st.stop_requested()) { /* ... */ } }};
worker.request_stop();                                // 协作式取消；析构自动 join

std::mutex mtx;
{ std::lock_guard lock{mtx}; /* 临界区：越小越好 */ }  // RAII 锁

std::atomic<int> hits{0};
hits.fetch_add(1, std::memory_order_relaxed);        // 计数专用（其余场景用默认序）

std::latch go{1};      go.count_down();  go.wait();  // 一次性发令枪
std::barrier sync{4};  sync.arrive_and_wait();        // 可复用集合点
std::for_each(std::execution::par, v.begin(), v.end(), f);  // 并行算法（谓词须线程安全）
// 注意：par 只保证"允许并行"，不保证真并行。macOS 实测：libc++ 的后端是桩实现，
// 五条 par 算法在 400 万元素上都只跑 1 个线程；Apple 自带 libc++ 连 par 都没有。
// 要真并行就自己开 std::thread（见 docs/20-atomic.md 20.5）。
```

## 协程（21）

```cpp
std::generator<int> squares(int n) {          // C++23 <generator>
    for (int i = 1; i <= n; ++i) co_yield i * i;
}
for (int v : squares(5)) { /* 1 4 9 16 25 */ }
```

## 文本与文件（22）

```cpp
std::println("{:.2f} / {:#x} / {:*^12}", 3.14159, 255, "标题");
std::regex re{R"((\d{4})-(\d{2}))"};          // R"(...)" 原始字符串
for (std::sregex_iterator it{s.begin(), s.end(), re}, end; it != end; ++it)
    std::println("{}", it->str(1));           // str(n) 取捕获组
namespace fs = std::filesystem;
for (auto& e : fs::recursive_directory_iterator{dir})) { /* 遍历序不保证：先收集再 sort */ }
std::ofstream{path} << "content";             // 临时对象即写即 flush
// 实测坑：浮点 {:.1%} 编译期报错（MSVC）→ ×100 手写 %；mdspan 用 m[r, c] 不是 m(r, c)
```

## 测试（23）

```cpp
std::vector<TestCase> tests{
    {"用例名", [] { assert(f(x) == expected); }},
};
for (auto& t : tests) { t.run(); std::println("[PASS] {}", t.name); }
// 真实项目：GoogleTest / Catch2 / doctest
```

## 坑位索引（高频）

1. 全角标点混入源码（02）
2. `int bad{3.14}` 反过来：`= 3.14` 静默截断——用 `{}`（03）
3. 无符号倒序死循环（03/04）
4. range-for 遍历中 push_back/erase → 迭代器失效（04/10）
5. map 的 `[]` 只读访问也插入（10）
6. move 后继续用源对象（09/15）
7. 忘虚析构，基类指针删除子类（16）
8. lambda 引用捕获悬垂（11）
9. 锁里调未知代码 / 条件变量裸 wait（19）
10. 循环里反复构造 regex（22）

**跨编译器校验补录**（2026-09-17 双工具链实测，前两条是"标准没规定"、后两条是"各家进度不一"）：

11. **实参求值顺序未指定**：`println("{} {} {}", next(), next(), next())` 在 GCC/MSVC 上打 `3 2 1`、clang 上打 `1 2 3`（08 示例故意演示）；`println("{}", v.size(), v.pop())` 同理（13）。带副作用的实参一律拆成多条语句。
12. **容器元素的析构顺序未规定**：`vector<unique_ptr<T>>` 析构时，libc++ 逆序销毁、libstdc++ 正序（09）。顺序重要就自己 `pop_back` 弹空。
13. **C++23 头文件各家进度不一**：`<generator>`/`<stacktrace>` libc++ 23 还没有，`<mdspan>` libstdc++ 15 还没有（21/22/23）。跨平台代码用 `__has_include` + 特性宏探测，别硬 `#include`。
14. **`-Wall -Wextra` 不是"更严的 MSVC `/W4`"**：clang 的 `-Wunused-but-set-parameter`（05）、GCC 的 `-Wrange-loop-construct`（10）在 MSVC 上都不报——只在一个编译器上"零告警"不等于零告警。
15. **`std::execution::par` 可能只是"允许并行"而没有真并行**：macOS 上 libc++ 的后端是桩实现（`par` 五条算法 400 万元素实测各只 1 个线程，`hardware_concurrency = 4`），Apple 自带 libc++ 干脆没有 `par`（20）。要真并行自己开 `std::thread`；别用运行时长/加速比来断言并行度，要数线程 id。
