# C++20/23 速查表

配 [C++ 教程](README.md) 使用：按主题给骨架代码与坑位，括号内为章节号。

## 编译命令（01）

```bash
# Windows：build.ps1（pwsh 7）
pwsh -ExecutionPolicy Bypass -File build.ps1 -All / -Example 08_compound / -Clean

# 手工（先 vcvars64.bat）
cl /nologo /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4 main.cpp
chcp 65001   # 直接跑 exe 时防中文乱码

# 模块两步（26）
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

# 模块三步（26）：clang 用 --precompile 出 .pcm；gcc 用 -fmodules-ts（产物落 ./gcm.cache）
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

## 指针与引用（05）

```cpp
int* p{nullptr};              // 声明即初始化；& 取地址，* 解引用
const int* ptr_to_const;      // 数据只读（右到左读：const int 的指针）
int* const const_ptr{&v};     // 指针只读（≈ 引用的本质）
p[i] ≡ *(p + i);  p1 - p2     // 指针算术按元素宽度跳
delete p; p = nullptr;        // new 配一次 delete；new[] 配 delete[]；删完置空
int& ref{n};                  // 必然绑定、永不换绑的别名
// 黄金法则：不写裸 new/delete → vector + 智能指针（13）
```

## 函数传参三式（06）

```cpp
void f(small_t x);                 // 小类型按值
void modify(T& x);                 // 要改：引用
void read(const big_t& x);         // 大对象只读：const 引用
void greet(const std::string& n, const std::string& g = "你好");  // 默认实参靠右
auto add = [factor](int v) { return v * factor; };  // lambda 值捕获
```

## 字符串（07）

```cpp
std::string s3(6, 'z');       // () 重复字符；{6, 'z'} 是坑（6 变字符码）
s.find("an") == std::string::npos;   // 找不到的判法（npos 当布尔是 true！）
s.contains / starts_with / ends_with;  // C++23/20/20 的布尔查询
s.substr(pos, len);           // C++ 标记法：起点+长度（len 不是终点下标）
s.erase(i, 1);                // 删一个；erase(i) 是删到尾！
std::string_view sv{s};       // 零拷贝视图；→ string 必须显式
auto path = R"(C:\dir\file)"; // 原始字面量：反斜杠不转义
```

## 复合类型（08）

```cpp
struct Book { std::string title; double price; int pages; };
Book b{.title = "C++", .price = 89.5, .pages = 420};   // 指定初始化器：按声明顺序
auto [t, p, n] = b;                                     // 结构化绑定
enum class Format { paperback, hardcover };             // 强类型枚举
int sum(std::span<const int> v);                        // 数组/vector 通吃的只读视图
// 悬垂警钟：string_view/span 不拥有数据，别指向临时对象
```

## 词汇类型（09）

```cpp
auto [k, v] = *m.begin();     // pair 拆解（map 元素就是 pair）
auto [a, b, c] = std::tuple{1, 2.5, "x"};   // tuple：结构化绑定按位拆
std::variant<int, std::string> val{"text"};
std::holds_alternative<std::string>(val); std::get_if<T>(&val);
std::visit(overloaded{ [](int){}, [](const std::string&){} }, val);  // 穷举分派
std::any box{3.14};  std::any_cast<double>(box);  // 开放集合才用 any
```

## 错误处理三件套（10）

```cpp
std::optional<int> find(void);                    // 可能有
std::expected<int, std::string> parse(std::string_view s);  // 值或错误（C++23）
auto r = parse("42").transform([](int v) { return v * 2; });  // 链式
assert(idx >= 0 && "不变量");                     // 开发期断言
```

## 类与 RAII（11）

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

## 运算符重载（12）

```cpp
T& operator+=(const T& rhs);            // 地基：复合赋值返回 *this
T operator+(const T& rhs) const { T c{*this}; c += rhs; return c; }  // + 借 +=
auto operator<=>(const T&) const = default;      // 能 default 就 default
operator double() const;                 // 转换运算符一律 explicit
int& operator[](std::size_t i);          // 非 const 返回引用才能写穿
double& operator[](size_t r, size_t c);  // C++23 多参下标：m[r, c]
template <> struct std::formatter<T> { /* … */ };  // print 时代的输出重载
```

## 智能指针（13）

```cpp
auto u = std::make_unique<Task>(args);   // 独占（默认选择，零开销）
auto s = std::make_shared<Task>(args);   // 共享（引用计数，确需才用）
std::weak_ptr<Task> w = s;               // 观察（lock() 升级，破循环）
auto moved = std::move(u);               // 转移所有权；u 变空
// 禁：裸 new/delete、get() 裸指针存起来
```

## 容器（14）

```cpp
std::vector<T> v;                 // 默认选择
std::map<K, V> m;                 // 有序键值（[] 会误插入！只读用 find/contains）
std::unordered_map<K, V> um;      // 哈希 O(1) 平均
std::erase_if(v, pred);           // C++20 一行过滤（替代 erase-remove）
for (const auto& [k, val] : m) {} // 结构化绑定遍历
v.emplace_back(args...);          // 原地构造，省一次搬移
```

## 算法与 lambda（15）

```cpp
std::sort(v.begin(), v.end(), std::greater{});      // 降序
auto it = std::find_if(v.begin(), v.end(), pred);   // 用前判 it != end()
int n  = std::count_if(v.begin(), v.end(), pred);
double s = std::accumulate(v.begin(), v.end(), 0.0);  // 初始值定累加类型！
int thr = 4;
auto by_val = [thr](int x) { return x > thr; };    // 值捕获：快照
auto by_ref = [&thr](int x) { return x > thr; };   // 引用捕获：实时（防悬垂）
```

## 迭代器（16）

```cpp
static_assert(std::random_access_iterator<std::vector<int>::iterator>);  // 类目验票
std::copy(src.begin(), src.end(), std::back_inserter(dst));   // 写入=push_back（免预分配）
std::copy(src.begin(), src.end(), std::inserter(s, s.end())); // + set = 有序去重
std::vector<int> nums{std::istream_iterator<int>{in}, {}};    // 迭代器对当区间
std::vector<std::string> taken{std::make_move_iterator(v.begin()),
                                std::make_move_iterator(v.end())};   // 搬空源
auto it2 = std::next(it);  std::advance(it, 2);  std::distance(a, b); // 副本/原地/计数
// std::sort 只收随机访问迭代器：list/map 用成员 sort()；distance 在 list 上是 O(n)
```

## 一等函数（17）

```cpp
using BinOp = long (*)(long, long);      // 函数指针类型别名；auto* op{fn};
struct Nearer {                          // 仿函数：operator() + 成员状态
    explicit Nearer(int t) : t_{t} {}
    bool operator()(int a, int b) const;
};
// [x] [&x] [x = expr] [this] mutable —— 值/引用/初始化/this 捕获
[]<typename T>(const T& a, const T& b);  // 泛型 lambda 显式模板形参
std::function<void()> cb = []{};         // 类型擦除容器（空调用抛 bad_function_call）
std::vector<std::function<void()>> on_event;   // 回调注册表（lambda 类型只有编译器知道）
```

## 数值与随机（18）

```cpp
double s = std::accumulate(v.begin(), v.end(), 0.0); // 初值 0.0！初始值定累加类型
auto n = std::transform_reduce(v.begin(), v.end(), 0, std::plus{},
                               [](auto& s) { return s.size(); });    // MapReduce
std::partial_sum(v.begin(), v.end(), std::back_inserter(out));       // 前缀和
std::iota(v.begin(), v.end(), 1);                    // 填 1..N
std::gcd(36, 60);  std::midpoint(a, b);  std::lerp(a, b, t);   // C++17/20
double pi = std::numbers::pi;                        // C++20 <numbers>（pi_v<float> 换精度）
std::mt19937 gen{seed};                              // 引擎构造一次反复用（循环里重造=同序列）
std::uniform_int_distribution<int> dice{1, 6};  dice(gen);      // 用法=分布(引擎)
// rand()%n 退役：质量差+偏差；分布算法实现定义——跨平台只断言统计量不断言序列
```

## Ranges（19）

```cpp
auto out = data | std::views::filter(pred)
                 | std::views::transform(f)
                 | std::ranges::to<std::vector>();   // C++23 收集
std::ranges::sort(v, std::greater{}, &Item::score); // 投影消灭比较器
for (auto [i, x] : v | std::views::enumerate) {}    // C++23 带索引
// 惰性：提前停用手动 for+break（MSVC 的 to 会抽干 filter——实测坑）
// 无限序列 iota(1) 必须 take
```

## 模板与概念（20/21）

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

## 移动语义（22）

```cpp
Widget b = std::move(a);              // 转移：a 变"有效但未定"，别再用
Widget make() { return Widget{...}; } // RVO：按值返回，别写 return std::move(local)
template <typename T>
void relay(T&& arg) { target(std::forward<T>(arg)); }  // 完美转发
// 移动构造/赋值记得 noexcept（容器扩容才敢用）
```

## 多态骨架（24/23）

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
// 派生构造链：Carton(l,w,h,m) : Box{l,w,h}, m_{m}——拷贝构造记得 Box{other}！
// 默认实参静态绑、函数体动态绑：虚函数的默认实参全层次写同一个值
```

## 编译期（25）

```cpp
constexpr unsigned long long factorial(unsigned n) { /* for 循环即可 */ }
consteval int square(int v) { return v * v; }     // 只许编译期
if constexpr (std::is_arithmetic_v<T>) { ... }    // 编译期剪枝（模板里）
template <typename... Ts>
auto sum_all(Ts... vs) { return (0 + ... + vs); } // fold（空包安全）
```

## 预处理器（27）

```cpp
#define STR(x) #x     // 字符串化        #define CAT(a,b) a##b   // 拼接
#ifndef GUIDE_UTIL_H  // include guard：防重复包含（ODR）
#define GUIDE_UTIL_H
// … 头文件内容
#endif
inline int f();        // 头文件里的定义必须 inline
extern int visits;     // 跨单元变量：extern 声明 + 一个 .cpp 定义
static int helper();   // 内部链接；或匿名命名空间 namespace { }
#if __has_include(<generator>) /* … */ #endif   // 头文件探测
#ifdef __cpp_lib_ranges  /* … */ #endif          // 特性宏（值=年月）
// 宏三宗罪：无类型/无作用域/盲替换 → constexpr + 模板替代
```

## 并发（28/29）

```cpp
std::jthread worker{[](std::stop_token st) { while (!st.stop_requested()) { /* ... */ } }};
worker.request_stop();                                // 协作式取消；析构自动 join

std::mutex mtx;
{ std::lock_guard lock{mtx}; /* 临界区：越小越好 */ }  // RAII 锁
std::scoped_lock both{m1, m2};                 // 多锁一把抓（内部死锁避免算法）
std::unique_lock dfl{m, std::defer_lock};      // 先造后锁；try_lock_for 要 timed_mutex
std::shared_mutex sm;
{ std::shared_lock r{sm}; /* 读：多读者并行 */ } { std::unique_lock w{sm}; /* 写：独占 */ }
std::once_flag flag;  std::call_once(flag, init);      // 一次性初始化（magic static 同效）
thread_local int visits = 0;                  // 每线程一份，天然无竞争
cv_any.wait(lock, stop_token, pred);          // 可中断等待：stop 一请求就醒（28.5）

std::atomic<int> hits{0};
hits.fetch_add(1, std::memory_order_relaxed);        // 计数专用（其余场景用默认序）
int exp = v.load();                           // CAS 循环："检查再设置"的原子化
while (!v.compare_exchange_weak(exp, exp + 1)) {}
while (sp_flag.test_and_set(acquire)) {}      // atomic_flag 自旋锁（临界区极短才配）

std::latch go{1};      go.count_down();  go.wait();  // 一次性发令枪
std::barrier sync{4};  sync.arrive_and_wait();        // 可复用集合点
std::counting_semaphore<2> empty{2};          // 名额/容量：acquire 占，release 还
auto fut = std::async(std::launch::async, task);      // 任务：future.get() 直取结果
// 必须接住 fut！丢弃 future 的析构会阻塞等任务完（伪同步）；异常经通道在 get() 重抛
auto sf = fut.share();  sf.get();  sf.get();          // shared_future 可多次取
fut.wait_for(50ms) == std::future_status::timeout;    // 限时等（promise 活着才会超时）
std::for_each(std::execution::par, v.begin(), v.end(), f);  // 并行算法（谓词须线程安全）
// 注意：par 只保证"允许并行"，不保证真并行。macOS 实测：libc++ 的后端是桩实现，
// 五条 par 算法在 400 万元素上都只跑 1 个线程；Apple 自带 libc++ 连 par 都没有。
// 要真并行就自己开 std::thread 或用线程池（见 docs/29-atomic.md 29.7/29.9）。
```

## 协程（30）

```cpp
std::generator<int> squares(int n) {          // C++23 <generator>
    for (int i = 1; i <= n; ++i) co_yield i * i;
}
for (int v : squares(5)) { /* 1 4 9 16 25 */ }
int v = co_await task();    // awaiter 三钩子：await_ready / await_suspend / await_resume
// 最小 Task<T>：惰性（要 start() 点火）+ 对称转移交棒 + 异常存档 result() 重抛
```

## 时间（31）

```cpp
using namespace std::chrono;  using namespace std::chrono_literals;
auto wait = 500ms;                       // 单位在类型里：1h/30min/45s/100ms/150us/60ns
minutes m = duration_cast<minutes>(90s); // 细化自动、粗化显式（余数截断）
auto t0 = steady_clock::now();           // 测耗时只准 steady（system 会被 NTP 回拨）
duration<double> elapsed = steady_clock::now() - t0;
year_month_day d{2026y / September / 28d};
d + months{3};                           // 月份运算在日历类型上！sys_days+months=平均月漂移
year{2026} / February / last;            // 月末
zoned_time tokyo{"Asia/Tokyo", tp};      // 同一时刻的不同说法
std::println("{:%Y-%m-%d %H:%M}", tp);   // %S/%M/%Y… chrono 格式说明符（:.2f 会编译错）
```

## 流 I/O（32）

```cpp
while (in >> x) { }                // 流到 bool：fail/bad 即停；失败的算术抽取把 x 写成 0
in.clear();  in.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
std::getline(in, line);            // 整行；>> 后直接 getline 拿空行（残留 '\n'）
out << std::hex << 255 << ' ' << std::setw(6) << 42;   // 粘性；setw 只管下一次
std::ofstream f{"a.txt"};          // 析构自动关（RAII）；if (!f) 必查；二进制加 binary
friend std::ostream& operator<<(std::ostream&, const T&);   // 自定义类型：返回流引用
// 输出首选 print/format（33）；流的不可替代处：>> 解析、文件读写
```

## 文本与文件（33）

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

## 测试（34）

```cpp
std::vector<TestCase> tests{
    {"用例名", [] { assert(f(x) == expected); }},
};
for (auto& t : tests) { t.run(); std::println("[PASS] {}", t.name); }
// 真实项目：GoogleTest / Catch2 / doctest
```

## Effective STL 精要（36）

```cpp
std::erase_if(c, pred);                    // C++20 统一删除（vector/map 通吃，真删）
auto [it, ok] = m.try_emplace(k, args...); // 只添加：撞键不动手（实参保证不被搬空）
m.insert_or_assign(k, v);                  // 添加或覆盖（operator[] 是"默认构造+赋值"两步）
auto node = m.extract(k);  node.key() = k2;  m.insert(std::move(node));   // C++17 改键正道
v.reserve(n);   v.shrink_to_fit();         // 防扩容搬移 / 收缩多余容量（swap 技巧的转正）
v.data();       s.c_str();                 // 送 C API（空容器 data() 可调不可解引用）
std::vector<int> v{read, eof};             // 迭代器对构造用 {}——() 会撞"最烦人的解析"
auto [lo, hi] = std::equal_range(v.begin(), v.end(), x);   // 排序区间：位置 + 个数
std::partial_sort / nth_element / partition;   // 要多少排多少（前 n 名别用全排 sort）
std::istreambuf_iterator<char> it{in}, end{};  std::string s{it, end};    // 原样读流（含空白）
// 50 条裁决速记：约七成原样成立；unordered_*/flat_map/try_emplace/erase_if 是原书
// 预言的兑现；auto_ptr/配接器/COW string/vector<bool> 的老对策已成历史（详见 docs/36）
```

## 坑位索引（高频）

1. 全角标点混入源码（02）
2. `int bad{3.14}` 反过来：`= 3.14` 静默截断——用 `{}`（03）
3. 无符号倒序死循环（03/04）
4. range-for 遍历中 push_back/erase → 迭代器失效（04/14）
5. map 的 `[]` 只读访问也插入（14）
6. move 后继续用源对象（13/20）
7. 忘虚析构，基类指针删除子类（24）
8. lambda 引用捕获悬垂（15）
9. 锁里调未知代码 / 条件变量裸 wait（28）
10. 循环里反复构造 regex（33）
11. delete 后不置空 / new[] 配 delete（05）
12. 拷贝构造漏 Base{other}——基类部分被默认构造（23）
13. 虚函数配默认实参——实参取静态类型版（24）

**跨编译器校验补录**（2026-09-17 双工具链实测，前两条是"标准没规定"、后两条是"各家进度不一"）：

14. **实参求值顺序未指定**：`println("{} {} {}", next(), next(), next())` 在 GCC/MSVC 上打 `3 2 1`、clang 上打 `1 2 3`（11 示例故意演示）；`println("{}", v.size(), v.pop())` 同理（20）。带副作用的实参一律拆成多条语句。
15. **容器元素的析构顺序未规定**：`vector<unique_ptr<T>>` 析构时，libc++ 逆序销毁、libstdc++ 正序（13）。顺序重要就自己 `pop_back` 弹空。
16. **C++23 头文件各家进度不一**：`<generator>`/`<stacktrace>` libc++ 23 还没有，`<mdspan>` libstdc++ 15 还没有（30/33/34）。跨平台代码用 `__has_include` + 特性宏探测，别硬 `#include`。
17. **`-Wall -Wextra` 不是"更严的 MSVC `/W4`"**：clang 的 `-Wunused-but-set-parameter`（06）、GCC 的 `-Wrange-loop-construct`（14）在 MSVC 上都不报——只在一个编译器上"零告警"不等于零告警。
18. **`std::execution::par` 可能只是"允许并行"而没有真并行**：macOS 上 libc++ 的后端是桩实现（`par` 五条算法 400 万元素实测各只 1 个线程，`hardware_concurrency = 4`），Apple 自带 libc++ 干脆没有 `par`（29）。要真并行自己开 `std::thread`；别用运行时长/加速比来断言并行度，要数线程 id。

**标准库扩充补录**（2026-09-28 按《The C++ Standard Library, 4th》补 16/18/31/32 四章实测）：

19. **system_clock 测耗时**：NTP 回拨让耗时报负数——测量一律 steady_clock（31）。
20. **`sys_days + months` 按平均月（30.44 天）漂移**：加出 07:27:18 这种时分秒——月份运算要在 `year_month_day` 上做（31）。
21. **`>>` 后直接 `getline` 拿空行**：残留 `'\n'` 被当整行；且失败的算术抽取会把变量**清成 0**（C++11 规则）——clear + ignore 清场（32）。
22. **丢弃 `std::async` 的 future**：临时 future 析构阻塞等任务完——`std::async(f);` 是伪同步；get() 只能调一次（29）。

**并发深化补录**（2026-09-28 按《C++ Concurrency in Action》《Mastering Asynchronous C++》实测补 28/29/30 三章）：

23. **promise 析构 = 投递 broken_promise**：孤儿 future 立刻就绪、get() 抛 future_error——wait_for 想真超时，promise 得活着（29）。
24. **普通 mutex 没有 try_lock_for**：限时等锁得用 timed_mutex；unique_lock 的 defer_lock 才支持"先造后锁"（28）。
25. **shared_mutex 读锁不可递归**：同线程两次 shared_lock 自找死锁；读多写少才值得读写锁，写者还可能被读者饿死（28）。
26. **信号量不绑身份**：任何线程都能 release——它管名额/容量，不护数据；护数据用 mutex（29）。
27. **线程池成员逆序析构**：靠 jthread 自动收尾时 workers_ 必须最后声明，否则工人摸已死的锁；显式 join 最稳（29）。
28. **惰性 Task 忘 start 就 result**：读到空 box；co_await 临时 Task 后再复用 = 悬垂（30）。

**Effective STL 补录**（2026-09-29 按《Effective STL 中文版》50 条实测补 36 章）：

29. **remove/unique 不删元素**：size 不变、返回"新逻辑尾"、尾段值未指定——erase 收尾或 `std::erase_if`；打印 remove 后的尾段靠不住（36）。
30. **同一容器两种"找到"**：忽略大小写 set 里成员 find（按等价）命中、`std::find`（按相等）落空——查关联容器只用成员函数/`contains`（36）。
31. **`try_emplace` 撞已有键保证实参不被搬空**；`operator[]` 添加则走"默认构造+赋值"且要求值可默认构造——添加/更新用 `try_emplace`/`insert_or_assign` 各归其位（36）。
32. **reverse_iterator 删除偏一格**：删 ri 所指用 `std::next(ri).base()`，直接 base() 删到隔壁；插入才用 base 本尊（36）。
33. **vector\<bool\> 的 `operator[]` 是代理不是 `bool&`**：不连续、`&v[0]` 编不过——真 bool 用 `deque<bool>`/`vector<char>`，定长用 `bitset`（36）。
34. **`tolower/toupper` 前先转 `unsigned char`**（负值 char 直接喂是 UB）；它们依赖全局 locale，非 ASCII 场景走 `std::locale`（36）。
35. **改 set/map 的键**：C++11 起 set 迭代器解引用是 const 的（直接改编译不过）；正道是 `extract` 拔节点改 `key()` 再插回（36）。
36. **排序区间算法喂未排序区间 = 运行期算错**：`binary_search`/`equal_range`/`set_*`/`merge`/`includes` 不报错直接给错答案；比较函数还要与排序时同一个（36）。
37. **`accumulate` 的折叠函数不许有副作用**（标准原文级禁令）；带状态统计用 for_each 的返回 functor；初始值类型劫持累加类型（15/36）。
38. **const 整型局部量在 lambda 里可免捕获**：带常量初值的 const int 不捕获也能用，再显式捕获 clang 报 `-Wunused-lambda-capture`——要演示捕获语义就用非 const（36）。
