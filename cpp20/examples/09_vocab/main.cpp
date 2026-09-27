#include <any>
#include <print>
#include <string>
#include <tuple>
#include <utility>
#include <variant>
#include <vector>

// 09 词汇类型：pair、tuple、variant 与 any —— 把“组合/选择”写进类型

// ═══ 9.4 variant 的 visit 配手写重载集（经典 overload 惯用法）═══
template <class... Ts>
struct overloaded : Ts... {
    using Ts::operator()...;   // C++20 起：继承全部 lambda 的调用运算符
};

int main() {
    // ═══ 9.1 pair：两个值打一个包 ═══
    std::pair<std::string, int> lang{"cpp", 23};
    std::println("pair: {}-{}", lang.first, lang.second);
    auto [name, year] = lang;                  // 结构化绑定拆 pair
    std::println("拆开: {} / {}", name, year);
    // map 的元素就是 pair<const Key, Value>——遍历时的 [k, v] 绑定的就是它（第 14 章）

    // ═══ 9.2 tuple：任意个数的值打一个包 ═══
    std::tuple<std::string, int, double> point{"原点", 3, 4.5};
    std::println("tuple: {} / {} / {}", std::get<0>(point), std::get<1>(point), std::get<2>(point));
    auto [label, x, y] = point;                // 结构化绑定按位置拆
    std::println("拆开: {} 位于 ({}, {})", label, x, y);
    std::string a_label;
    int a_x = 0;
    std::tie(a_label, a_x, std::ignore) = point;   // tie：拆到已有变量（跳过的用 ignore）
    std::println("tie 拆到已有变量: {} / {}", a_label, a_x);
    auto merged = std::tuple_cat(point, std::make_tuple("附注"));  // 元组拼接
    std::println("tuple_cat 后第 4 个元素 = {}", std::get<3>(merged));

    // ═══ 9.3 variant：类型安全的 union——同一时刻只装备选类型之一 ═══
    using Value = std::variant<int, std::string, bool>;
    Value v{42};                                     // 当前是 int
    std::println("装的是 int？{}", v.index() == 0);   // index() 报告当前备选下标
    std::println("值 = {}", std::get<int>(v));
    v = std::string{"hello"};                        // 换成 string——旧值先析构
    std::println("现在装的是 string？{}", std::holds_alternative<std::string>(v));
    if (auto* p = std::get_if<int>(&v); p != nullptr) {   // get_if：指针式取值，不抛
        std::println("int 值 = {}", *p);
    } else {
        std::println("get_if：当前不是 int，拿到 nullptr（不抛异常）");
    }
    // std::get<int>(v);   // 此时取 int 会抛 bad_variant_access——variant 把“拿错类型”变成异常而非 UB

    // visit + 重载集：对“当前到底是哪种值”做穷举分派
    for (Value w : {Value{7}, Value{std::string{"text"}}, Value{true}}) {
        std::string desc = std::visit(overloaded{
            [](int i)         { return "整数 " + std::to_string(i); },
            [](const std::string& s) { return "字符串 \"" + s + "\""; },
            [](bool b)        { return std::string{"布尔 "} + (b ? "true" : "false"); },
        }, w);
        std::println("visit 分派到：{}", desc);
    }

    // ═══ 9.4 any：装得下任何可拷贝类型的类型擦除盒子 ═══
    std::any box{std::string{"可装任何东西"}};
    std::println("any 里有 string？{}", box.has_value() && box.type() == typeid(std::string));
    std::println("any_cast 取出 = {}", std::any_cast<std::string>(box));
    box = 3.14;                                      // 随时换成别的类型
    std::println("换成 double 后取出 = {}", std::any_cast<double>(box));
    try {
        (void)std::any_cast<std::string>(box);       // 类型不符 → 抛 bad_any_cast
    } catch (const std::bad_any_cast&) {
        std::println("any_cast 类型不符：抛 bad_any_cast（可捕获，不是 UB）");
    }

    // ═══ 9.5 选型总表（一页决策）═══
    // optional<T>   —— 可能有 T（第 10 章）
    // expected<T,E> —— T 或错误 E（第 10 章）
    // pair<A,B>     —— 恰好两个值（map 元素、minmax 结果）
    // tuple<Ts...>  —— 固定个数的异质值（结构化绑定消费）
    // variant<Ts..> —— 闭合集合里选一个（visit 可穷举，编译器查漏）
    // any           —— 开放集合装一个（灵活但要 any_cast，慎用）
    std::println("自检通过");
}
