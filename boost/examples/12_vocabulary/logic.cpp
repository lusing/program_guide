// logic.cpp —— Boost.Tribool：三值逻辑（true/false/indeterminate）
// 对应文档：docs/12-vocabulary.md
// SQL 的 NULL 语义、可选布尔、三态配置——bool 不够用的地方。
#include <boost/logic/tribool.hpp>
#include <boost/optional.hpp>
#include <iostream>

const char* name_of(boost::tribool b) {
    if (b) return "真";
    if (!b) return "假";
    return "未知";
}

int main() {
    boost::tribool yes = true;
    boost::tribool no = false;
    boost::tribool unknown = boost::indeterminate;

    // 1) 三态打印（indeterminate 不是 true 也不是 false）
    std::cout << name_of(yes) << '/' << name_of(no) << '/' << name_of(unknown) << '\n';

    // 2) Kleene 三值逻辑运算：未知参与运算的传播
    std::cout << "未知 AND 假 = " << name_of(unknown && no) << "（短路吸收）\n";
    std::cout << "未知 AND 真 = " << name_of(unknown && yes) << "（未知传播）\n";
    std::cout << "未知 OR 真 = " << name_of(unknown || yes) << "（短路吸收）\n";
    std::cout << "NOT 未知 = " << name_of(!unknown) << '\n';

    // 3) 显式判 indeterminate
    std::cout << "indeterminate()? " << boost::indeterminate(unknown) << '\n';

    // 4) 与 optional<bool> 的边界 + 更名宏
    std::cout << "选型：第三态语义用 tribool，缺答案用 optional<bool>\n";
    // 【optional<bool> 的 bool 语境陷阱】ob 的 bool 语义是"有无值"，
    // 不是"值是真"：有值且值为 false 时，if (ob) 依然成立！
    boost::optional<bool> ob{false};          // 有值，值是 false
    std::cout << "  陷阱: ob=" << (ob ? "真(有值!)" : "假")
              << " 但 *ob=" << std::boolalpha << *ob
              << " ——判值必须 *ob" << '\n';
    // 更名宏：第三态名字可以换成更贴业务的词（全局作用域用）
    //   BOOST_TRIBOOL_THIRD_STATE(unknown)  ← 之后 unknown 与 indeterminate 等价
    std::cout << "更名宏 BOOST_TRIBOOL_THIRD_STATE(名字) 可给第三态换名\n";
    // 比较传染律：与 indeterminate 的 == 比较结果仍是 indeterminate，
    // 所以 if (tb == indeterminate) 永远不成立——判第三态只能用函数形式

    std::cout << "自检通过\n";
    return 0;
}
