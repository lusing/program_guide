// file: src/re.hpp
// 第 5 章配套：正则表达式 → NFA → DFA → 最小 DFA 的完整流水线。
// 数据结构刻意贴着绿龙 Algorithm 3.1–3.3 的伪码走：
//   NFA 状态 = (符号, 下一状态1, 下一状态2) 三元组（ε 用 '\0' 表示）；
//   DFA 状态 = NFA 状态子集（子集构造的产物）；
//   最小化   = 按可区分性反复分割（Algorithm 3.3）。
#ifndef TIP_RE_HPP
#define TIP_RE_HPP

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 正则表达式的语法树 ----------
// 与绿龙 3.3 节的归纳定义一一对应：基础是 ε 与单符号 a，
// 归纳步是 R|S、RS、R* 三条。没有并集、差集之类的扩展运算——
// 教科书子集足够描述 TIP 的全部 token。
enum class REKind { Eps, Sym, Alt, Concat, Star };

struct RE {
    REKind kind;
    char ch = 0;                     // Kind::Sym 时有效
    std::unique_ptr<RE> lhs, rhs;    // Alt/Concat 用两个，Star 用 lhs

    static std::unique_ptr<RE> eps();
    static std::unique_ptr<RE> sym(char c);
    static std::unique_ptr<RE> alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b);
    static std::unique_ptr<RE> star(std::unique_ptr<RE> a);
};

// 把中缀正则串解析成语法树。文法（优先级：* 高于并置，并置高于 |）：
//   expr  → term ('|' term)*
//   term  → factor factor*
//   factor→ atom '*'?
//   atom  → '(' expr ')' | 字符
// 这本身就是一个 LL(1) 文法——第 6 章会正式认识它。
std::unique_ptr<RE> parseRE(const std::string &pat);

// ---------- NFA：绿龙式三元组表示 ----------
// Algorithm 3.2 保证每个状态至多两条出边，因此三元组就够。
// sym == '\0' 表示 ε 边；to2 == -1 表示没有第二条边。
struct NFA {
    struct State {
        char sym1 = 0; int to1 = -1;
        char sym2 = 0; int to2 = -1;
        bool accept = false;
    };
    std::vector<State> st;
    int start = 0, finish = 0;   // Thompson 构造保证单一入口/单一出口
};

// Thompson 构造（Algorithm 3.2）：按语法树归纳地拼装。
NFA thompson(const RE &re);

// ---------- DFA ----------
struct DFA {
    // 状态编号 0..n-1；trans[s][c] 缺席（-1）表示该输入下无转移。
    std::vector<std::map<char, int>> trans;
    int start = 0;
    std::vector<int> color;   // 0 = 非接受；k>0 = 第 k 优先级的接受类
    int states() const { return static_cast<int>(trans.size()); }
};

// 子集构造（Algorithm 3.1）。alphabet 显式给出，避免“隐式全集”歧义。
// stateClass 为空时按 accept 态统一给类 1；scanner 场景传入
// “NFA 态 → 规则号+1”的着色，子集的类取集合中最小者（最高优先级）。
DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass = {});

// 状态最小化（Algorithm 3.3）。初试分割按 color 分组——
// 不同优先级的接受态即使行为相同也不可合并（scanner 语义依赖优先级）。
DFA minimize(const DFA &d, const std::set<char> &alphabet);

// ---------- 多模式 scanner ----------
struct TokenRule { std::string name, pat; };

// 词法分析：把每条规则编译成一个 NFA，共用一个新起点并联；
// 子集构造时每个 DFA 态携带“所含 NFA 接受态的最高优先级规则号”；
// 主循环做最长匹配（maximal munch），平局按优先级。
class Scanner {
public:
    explicit Scanner(std::vector<TokenRule> rules, std::set<char> alphabet);
    // 对输入做一遍切词；无法成词的字符输出 ERR('c')。
    std::vector<std::string> lex(const std::string &src) const;
    // 诊断信息：供 --check 打印各阶段状态数。
    std::string stats() const;

private:
    std::vector<TokenRule> rules_;
    std::set<char> alpha_;
    DFA dfa_;
    std::vector<int> nfaStateRule_;   // NFA 态 → 规则号（-1 非接受）
};

}  // namespace tip

#endif  // TIP_RE_HPP
