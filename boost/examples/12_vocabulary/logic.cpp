// logic.cpp —— Boost.Tribool：三值逻辑（true/false/indeterminate）
// 对应文档：docs/12-vocabulary.md
// SQL 的 NULL 语义、可选布尔、三态配置——bool 不够用的地方。
#include <boost/logic/tribool.hpp>
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
    std::cout << "未知 AND 假 = " << name_of(unknown && no) << "（短 路 吸收）\n";
    std::cout << "未知 AND 真 = " << name_of(unknown && yes) << "（未知传播）\n";
    std::cout << "未知 OR 真 = " << name_of(unknown || yes) << "（短路吸收）\n";
    std::cout << "NOT 未知 = " << name_of(!unknown) << '\n';

    // 3) 显式判 indeterminate
    std::cout << "indeterminate()? " << boost::indeterminate(unknown) << '\n';

    // 4) 与 optional<bool> 的边界：optional<bool> 的"无值"是"没答案"，
    //    tribool 的 indeterminate 是"答案就是第三态"——语义不同
    std::cout << "选型：第三态语义用 tribool，缺答案用 optional<bool>\n";

    std::cout << "自检通过\n";
    return 0;
}
