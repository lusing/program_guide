#pragma once
// 外观：为一堆子系统零件给一个统一的高层入口，调用方只见门面不见零件。
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace dp {

// ---- 子系统三零件：各自能独立用，彼此知之甚少 ----
struct Lexer {
    // 按空格切词（教学简化）：tokens 个数决定了后续的 parse/emit 行为
    [[nodiscard]] std::vector<std::string> tokenize(std::string_view src) const {
        std::vector<std::string> out;
        for (size_t i = 0; i < src.size();) {
            while (i < src.size() && src[i] == ' ') ++i;
            size_t j = i;
            while (j < src.size() && src[j] != ' ') ++j;
            if (j > i) out.emplace_back(src.substr(i, j - i));
            i = j;
        }
        return out;
    }
};

struct Parser {
    // 教学版：节点数 = 语句数（以 ';' 计）
    [[nodiscard]] size_t parse(std::span<const std::string> tokens) const {
        size_t nodes = 0;
        for (const auto& t : tokens)
            if (t == ";") ++nodes;
        return nodes;
    }
};

struct CodeGen {
    [[nodiscard]] std::string emit(size_t nodes) const {
        return std::format("code for {} nodes", nodes);
    }
};

// ---- Facade：把"词法→语法→代码生成"的固定顺序与零件装配收进一个接口 ----
class Compiler {
public:
    [[nodiscard]] std::string compile(std::string_view src) const {
        auto tokens = lex_.tokenize(src);          // 第 1 步
        size_t nodes = par_.parse(tokens);         // 第 2 步
        return std::format("tokens:{} nodes:{} {}", tokens.size(), nodes,
                           gen_.emit(nodes));      // 第 3 步 + 汇总
    }

private:
    Lexer lex_;
    Parser par_;
    CodeGen gen_;
};

}  // namespace dp
