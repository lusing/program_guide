#ifndef DS_CALCULATOR_HPP
#define DS_CALCULATOR_HPP

#include <cctype>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace ds {

inline bool is_operator(char c) {
    return c == '+' || c == '-' || c == '*' || c == '/';
}

inline int precedence(char c) {
    return (c == '+' || c == '-') ? 1 : 2;
}

// 按空格切 token；运算符与括号各占一个 token，数字（含小数点）整体一个 token。
inline std::vector<std::string> tokenize(std::string_view expr) {
    std::vector<std::string> tokens;
    for (size_t i = 0; i < expr.size();) {
        char c = expr[i];
        if (c == ' ' || c == '\t') {
            ++i;
            continue;
        }
        if (is_operator(c) || c == '(' || c == ')') {
            tokens.emplace_back(1, c);
            ++i;
            continue;
        }
        size_t j = i;
        while (j < expr.size() &&
               (std::isdigit(static_cast<unsigned char>(expr[j])) || expr[j] == '.')) {
            ++j;
        }
        tokens.emplace_back(expr.substr(i, j - i));
        i = j;
    }
    return tokens;
}

inline bool is_number_token(const std::string& tk) {
    return std::isdigit(static_cast<unsigned char>(tk[0])) != 0;
}

// 中缀 → 后缀：调度场算法。数字直接输出；左括号入栈；右括号弹到左括号；
// 运算符入栈前，先把栈顶优先级不低于它的运算符全部弹出。
inline std::string to_postfix(std::string_view infix) {
    const std::vector<std::string> tokens = tokenize(infix);
    std::vector<char> ops;
    std::vector<std::string> out;

    for (const std::string& tk : tokens) {
        if (is_number_token(tk)) {
            out.push_back(tk);
        } else if (tk[0] == '(') {
            ops.push_back('(');
        } else if (tk[0] == ')') {
            while (!ops.empty() && ops.back() != '(') {
                out.emplace_back(1, ops.back());
                ops.pop_back();
            }
            if (!ops.empty()) {
                ops.pop_back();  // 弹出 '('，它本身不进输出
            }
        } else {
            while (!ops.empty() && ops.back() != '(' &&
                   precedence(ops.back()) >= precedence(tk[0])) {
                out.emplace_back(1, ops.back());
                ops.pop_back();
            }
            ops.push_back(tk[0]);
        }
    }
    while (!ops.empty()) {
        out.emplace_back(1, ops.back());
        ops.pop_back();
    }

    std::string result;
    for (size_t i = 0; i < out.size(); ++i) {
        if (i != 0) {
            result += ' ';
        }
        result += out[i];
    }
    return result;
}

// 后缀表达式求值：遇数压栈，遇运算符弹出两个操作数（先弹的是右操作数），
// 结果再压回。除零、操作数不足、表达式不完整都抛异常。
inline double eval_postfix(std::string_view expr) {
    const std::vector<std::string> tokens = tokenize(expr);
    std::vector<double> st;

    for (const std::string& tk : tokens) {
        if (is_number_token(tk)) {
            st.push_back(std::stod(tk));
            continue;
        }
        if (st.size() < 2) {
            throw std::runtime_error("eval_postfix：操作数不足");
        }
        const double rhs = st.back();
        st.pop_back();
        const double lhs = st.back();
        st.pop_back();
        switch (tk[0]) {
            case '+': st.push_back(lhs + rhs); break;
            case '-': st.push_back(lhs - rhs); break;
            case '*': st.push_back(lhs * rhs); break;
            case '/':
                if (rhs == 0.0) {
                    throw std::runtime_error("eval_postfix：除数为零");
                }
                st.push_back(lhs / rhs);
                break;
            default:
                throw std::runtime_error("eval_postfix：未知运算符");
        }
    }

    if (st.size() != 1) {
        throw std::runtime_error("eval_postfix：表达式不完整");
    }
    return st.back();
}

// 括号匹配：左括号压栈，右括号必须与栈顶同类，遍历完栈必须为空。
inline bool balanced(std::string_view expr) {
    std::vector<char> st;
    for (char c : expr) {
        if (c == '(' || c == '[' || c == '{') {
            st.push_back(c);
        } else if (c == ')' || c == ']' || c == '}') {
            if (st.empty()) {
                return false;
            }
            const char top = st.back();
            st.pop_back();
            const bool match = (c == ')' && top == '(') ||
                               (c == ']' && top == '[') ||
                               (c == '}' && top == '{');
            if (!match) {
                return false;
            }
        }
    }
    return st.empty();
}

}  // namespace ds

#endif  // DS_CALCULATOR_HPP
