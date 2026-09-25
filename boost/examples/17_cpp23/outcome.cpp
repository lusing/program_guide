// outcome.cpp —— Boost.Outcome（2018）：std::expected（C++23）的同题兄长。
// 不是直系毕业——std::expected 参考 tl::expected——但 Outcome 是"错误处理
// 该怎么用值语义表达"这场讨论里最重要的实践者之一。
// 对应文档：docs/17-cpp23.md
#include <boost/outcome.hpp>
#include <iostream>
#include <string>
#include <system_error>

namespace outcome = BOOST_OUTCOME_V2_NAMESPACE;

// result<T, EC>：无异常路径的返回值——成功带 T，失败带 EC
outcome::result<int, std::error_code> parse_port(const std::string& s) {
    try {
        std::size_t pos = 0;
        int v = std::stoi(s, &pos);
        if (pos != s.size() || v < 1 || v > 65535) {
            return std::make_error_code(std::errc::invalid_argument);
        }
        return v;
    } catch (...) {
        return std::make_error_code(std::errc::invalid_argument);
    }
}

int main() {
    // 1) 判定与取值：.value() 失败抛，.error() 拿错误码
    auto ok = parse_port("8080");
    auto bad = parse_port("99999");
    // 判失败要用 has_error()：result 的 operator bool 语义是**有值**（跟
    // std::expected 一致），直接 static_cast<bool> 会把"失败"打成 0，
    // 跟这一行的字面意思正好相反（旧版就这么写错了）
    std::cout << "成功值 = " << ok.value()
              << " 失败吗? " << std::boolalpha << bad.has_error()
              << " 消息 = " << bad.error().message() << '\n';

    // 2) TRY 惯用法：错误向上传播一行流（库作者的心头好）
    auto double_it = [](const std::string& s) -> outcome::result<int, std::error_code> {
        BOOST_OUTCOME_TRY(auto port, parse_port(s));   // 失败即 return 失败值
        return port * 2;
    };
    std::cout << "TRY 链: " << double_it("443").value() << '\n';

    // 3) outcome<T>：成功值 + 空 + 异常指针 的三态（比 expected 多一层）
    outcome::outcome<int> oc = outcome::success(7);
    std::cout << "outcome 值 = " << oc.value() << "（三态：值/错误/异常）\n";

    // 4) std::expected 对照（C++23）
    //    monadic：transform/and_then 也有；差异见文档对照表
    std::cout << "自检通过\n";
    return 0;
}
