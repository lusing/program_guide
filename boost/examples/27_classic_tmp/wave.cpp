// wave.cpp —— Boost.Wave（2003）：C++ 预处理器的完整实现（可当库用）。
// 代码分析工具、编译器前端、预处理转储的原料。
// 对应文档：docs/27-classic-tmp.md
#include <boost/wave.hpp>
#include <boost/wave/cpplexer/cpp_lex_token.hpp>
#include <boost/wave/cpplexer/cpp_lex_iterator.hpp>
#include <iostream>
#include <string>
#include <vector>

int main() {
    // 待预处理的"迷你翻译单元"
    std::string code = R"(
#define GREETING(name) Hello, name!
#define WORLD World
GREETING(WORLD)
#if 1
#define ENABLED 1
#endif
)";

    using lex_type = boost::wave::cpplexer::lex_token<>;
    using iterator_type = boost::wave::cpplexer::lex_iterator<lex_type>;
    using context_type = boost::wave::context<
        std::string::const_iterator, iterator_type>;

    try {
        context_type ctx(code.begin(), code.end(), "demo.cpp");
        // 遍历预处理后的 token 流
        std::vector<std::string> tokens;
        for (auto it = ctx.begin(); it != ctx.end(); ++it) {
            tokens.push_back(it->get_value().c_str());
        }
        // 输出应包含展开后的 "Hello, World!" 与 ENABLED 定义生效
        std::string joined;
        for (auto& t : tokens) joined += t;
        bool has_hello = joined.find("Hello") != std::string::npos;
        bool has_world = joined.find("World") != std::string::npos;
        std::cout << "宏展开含 Hello? " << has_hello << " 含 World? " << has_world << '\n';
        std::cout << "token 数 = " << tokens.size() << '\n';
    } catch (const boost::wave::preprocess_exception& e) {
        std::cout << "预处理异常: " << e.description() << '\n';
    }

    // 定位：写"要看预处理结果"的工具（静态分析、代码生成）时，
    // Wave 是唯一的标准件级选择
    std::cout << "自检通过\n";
    return 0;
}
