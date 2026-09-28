#include <algorithm>
#include <cmath>
#include <functional>
#include <print>
#include <string>
#include <vector>

// 17 一等函数：函数指针、仿函数与 std::function

// ═══ 17.1 函数指针：能“换弹”的最原始形态 ═══
long add(long a, long b) { return a + b; }
long multiply(long a, long b) { return a * b; }

bool by_length(const std::string& a, const std::string& b) {
    return a.size() > b.size();   // 谁的回调说了算：长的排前
}

// ═══ 17.2 类型别名让函数指针签名可读 ═══
using BinOp = long (*)(long, long);            // “函数指针类型”的别名
template <typename T>
using Compare = bool (*)(const T&, const T&);  // 别名模板：参数化后的回调类型

// ═══ 17.3 高阶函数：回调参数是泛型的，函数指针/仿函数/lambda 通吃 ═══
template <typename T, typename Comparison>
const T* find_optimum(const std::vector<T>& values, Comparison compare) {
    if (values.empty()) return nullptr;
    const T* best = &values[0];
    for (std::size_t i = 1; i < values.size(); ++i) {
        if (compare(values[i], *best)) best = &values[i];
    }
    return best;
}

// ═══ 17.4 仿函数：带状态的“函数对象”——lambda 的前身 ═══
class Nearer {
public:
    explicit Nearer(int target) : target_{target} {}
    bool operator()(int a, int b) const {        // 函数调用运算符
        return std::abs(a - target_) < std::abs(b - target_);
    }
private:
    int target_;                                  // 状态：记住比较基准
};

struct Counter {
    int hits = 0;
    void record() {
        auto bump = [this] { ++hits; };           // 捕 this：拿到整个成员访问权
        bump();
        bump();
    }
};

int main() {
    // 函数指针：定义 → 换弹 → 经指针调用
    BinOp op = add;                       // 别名让声明可读；auto* op{add}; 也行
    std::println("op(3, 5) = {}", op(3, 5));
    op = multiply;                        // 同签名可以换函数
    std::println("换弹后 op(3, 5) = {}", op(3, 5));

    // 高阶函数吃函数指针
    std::vector<int> nums{91, 18, 92, 22, 13, 43};
    Compare<int> cmp = [](const int& a, const int& b) { return a < b; };   // 无捕获 lambda 可转函数指针（签名要吻合）
    std::println("最小元素 = {}", *find_optimum(nums, cmp));
    std::vector<std::string> names{"Moe", "Larry", "Shemp", "Curly Joe"};
    std::println("最长的名字 = {}", *find_optimum(names, by_length));

    // 仿函数：构造时带上状态（比较基准 50）
    std::println("离 50 最近的数 = {}", *find_optimum(nums, Nearer{50}));
    // 标准函数对象：<functional> 里现成的比较器（第 15 章的 std::greater{} 就是它）
    std::println("最大元素 = {}", *find_optimum(nums, std::greater<>{}));

    // ═══ 17.5 lambda 捕获全家福 ═══
    int threshold = 20;
    auto by_value = [threshold](int v) { return v > threshold; };   // 值捕获：快照
    auto by_ref = [&threshold](int v) { return v > threshold; };    // 引用捕获：实时
    threshold = 60;
    std::println("值捕获仍比 20：{} 个；引用捕获实时比 60：{} 个",
                 std::count_if(nums.begin(), nums.end(), by_value),
                 std::count_if(nums.begin(), nums.end(), by_ref));
    auto counter = [n = 0](int) mutable { return ++n; };            // 初始化捕获 + mutable
    (void)counter(0);
    std::println("有状态 lambda（初始化捕获 n=0，mutable 可改）：第 2 次调用返回 {}", counter(0));
    Counter c;
    c.record();
    std::println("lambda 捕 this 改成员：hits = {}", c.hits);

    // 泛型 lambda 的两种写法（auto 参数 / 显式模板形参）
    auto show = [](const auto& x) { std::println("值 = {}", x); };
    show(42);
    show(3.5);
    auto same_type = []<typename T>(const T& a, const T& b) { return a == b; };
    std::println("显式模板形参：same_type(1, 1) = {}", same_type(1, 1));

    // ═══ 17.6 std::function：能装一切可调用对象的容器 ═══
    std::function<bool(int, int)> chooser;
    chooser = [](int a, int b) { return a < b; };                  // 装 lambda
    std::println("function 装 lambda：{} ", chooser(1, 2));
    chooser = Nearer{50};                                          // 换成仿函数——继续换弹
    std::println("function 换成仿函数：{}（43 比 91 更靠近 50）", chooser(43, 91));
    std::function<void()> empty;
    std::println("function 判空 = {}", empty == nullptr);          // 空的调用会抛 bad_function_call

    // 回调注册表：把一堆“稍后要做的事”存进容器（函数指针做不到——类型各不相同）
    std::vector<std::function<void()>> on_shutdown;
    int cleaned = 0;
    on_shutdown.push_back([&cleaned] { ++cleaned; });              // 引用捕获外部状态
    on_shutdown.push_back([] { std::println("再见！"); });
    for (const auto& task : on_shutdown) task();                   // 逐个触发
    std::println("清理了 {} 项", cleaned);

    std::println("自检通过");
}
