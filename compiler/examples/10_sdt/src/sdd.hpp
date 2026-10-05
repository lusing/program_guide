// file: src/sdd.hpp
// 第 10 章配套：语法制导翻译的通用引擎。
// 一个 SDD = 文法 + 语义规则表；求值 = 在分析树上建依赖图 + 拓扑排序逐条算。
// 这是紫龙 5.1–5.2 的忠实程序化：属性是树节点上的字符串值，
// 规则是“从哪些属性读、往哪个属性写”的声明式数据。
#ifndef TIP_SDD_HPP
#define TIP_SDD_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace tip {

// 分析树节点：文法符号 + 词素 + 孩子 + 属性表
struct TreeNode {
    std::string symbol;                 // 文法符号（终结符或非终结符）
    std::string lexeme;                 // 终结符的词素（非终结符为空）
    int prod = -1;                      // 本节点按哪条产生式展开（-1 = 叶子）
    std::vector<std::unique_ptr<TreeNode>> children;
    std::map<std::string, std::string> attrs;   // 属性名 → 值（求值期填充）
    int seqId = 0;                              // 遍历序号：让输出顺序与地址无关
};

// 语义规则：把若干源属性的值，算成目标属性的一个值。
// targetChild = 0 表示写本节点（产生式左部），k>0 表示写右部第 k 个孩子。
struct SemRule {
    int targetChild;
    std::string targetAttr;
    std::vector<std::pair<int, std::string>> sources;   // (孩子下标, 属性名)
    std::function<std::string(const std::vector<std::string> &)> compute;
};

struct SddGrammar {
    // 每条产生式挂一组规则；产生式右部用于构造分析树（本引擎自带递归下降建树）
    struct ProdDef {
        std::string lhs;
        std::vector<std::string> rhs;
        std::vector<SemRule> rules;
    };
    std::vector<ProdDef> prods;
};

// 依赖图节点：(树节点指针, 属性名)
struct AttrRef {
    TreeNode *node;
    std::string attr;
    bool operator<(const AttrRef &o) const {
        if (node->seqId != o.node->seqId) return node->seqId < o.node->seqId;
        return attr < o.attr;
    }
};

class SddEngine {
public:
    explicit SddEngine(const SddGrammar &g) : g_(g) {}

    // 求值：返回 false 表示依赖图有环（SDD 非良定义）。
    // statsOut 收集 (属性实例数, 依赖边数, 拓扑序长度)。
    bool evaluate(TreeNode *root, std::map<std::string, size_t> &stats,
                  std::vector<AttrRef> *cycle = nullptr);

    // 注释树打印（含属性）
    static void dump(const TreeNode *n, int depth = 0);

private:
    const SddGrammar &g_;
};

// ---------- 两个内置 SDD ----------
// 表达式 → 值 + 后缀（紫龙 Fig 5.4 的 inh/syn 线程化，扩展到 + 与 *）
// 文法（右递归，与第 6 章改造后的文法同形）：
//   expr → term expr' ; expr' → PLUS term expr' | ε
//   term → factor term' ; term' → STAR factor term' | ε ; factor → INT
// 从 token 名序列建树；失败返回 nullptr。
std::unique_ptr<TreeNode> buildExprTree(const std::vector<std::pair<std::string, std::string>> &toks);
const SddGrammar &exprSdd();

// 声明块 → 偏移布局（继承属性的经典用武之地，紫龙 6.3 存储布局的雏形）
//   decls → VAR idlist SEMI ; idlist → IDENT idlist' ;
//   idlist' → COMMA IDENT idlist' | ε
std::unique_ptr<TreeNode> buildDeclTree(const std::vector<std::pair<std::string, std::string>> &toks);
const SddGrammar &declSdd();

// 后缀表达式求值（小栈机）：供 main 做 post 求值 == val 的对账。
int evalPostfix(const std::string &post);

}  // namespace tip

#endif  // TIP_SDD_HPP
