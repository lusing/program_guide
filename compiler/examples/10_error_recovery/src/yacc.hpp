// yacc 心脏：LALR(1) 表（08 章副本）之上的值栈驱动器 + 优先级仲裁 + 嵌入动作改写。
// 对应 L 书 §5.4–5.5 的三个机制：%union（任意值类型）、$$/$n 伪变量、
// 优先级/结合性声明消冲突；§5.5.6 的嵌入动作 = 空产生式改写也在本文件实现。
#ifndef TIP_YACC_HPP
#define TIP_YACC_HPP

#include <functional>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "lr1.hpp"

namespace tip {

// ---------- %union：值栈元素的带标签联合 ----------
// yacc 的 %union 声明编译成一个 union/struct，词法动作填 yylval，
// 语法动作经 $$/$n 读写。教学版用 Tag + 双字段表达同一契约：
// 动作里取错标签 = 生成器报错的运行期对应物（断言炸）。
struct YaccValue {
    enum class Tag { Empty, Num, Str } tag = Tag::Empty;
    double num = 0;
    std::string str;

    static YaccValue empty() { return {}; }
    static YaccValue ofNum(double v) { YaccValue y; y.tag = Tag::Num; y.num = v; return y; }
    static YaccValue ofStr(std::string s) { YaccValue y; y.tag = Tag::Str; y.str = std::move(s); return y; }

    double asNum(const char *who) const {
        // %type 声明的运行期影子：声明了 <num> 的位置来了 Str，就是类型错误
        if (tag != Tag::Num) {
            std::ostringstream os;
            os << "type error: " << who << " expects Num, got "
               << (tag == Tag::Str ? "Str" : "Empty");
            throw std::runtime_error(os.str());
        }
        return num;
    }
    const std::string &asStr(const char *who) const {
        if (tag != Tag::Str) {
            std::ostringstream os;
            os << "type error: " << who << " expects Str, got "
               << (tag == Tag::Num ? "Num" : "Empty");
            throw std::runtime_error(os.str());
        }
        return str;
    }
};

// ---------- 规则与动作 ----------
// vals[k-1] 即 $k（$1..$n 按出现序）；返回值即 $$。
// 动作为空的规则按 yacc 缺省：$$ = $1（ε 规则给 Empty）。
using YaccAction = std::function<YaccValue(std::vector<YaccValue> &)>;

struct YaccRule {
    std::string lhs;
    std::vector<std::string> rhs;
    YaccAction action;        // 可空
    std::string actionName;   // 日志用（嵌入动作改写对账的关键）
    int rulePrec = 0;         // %prec 覆盖：0 = 未声明（取最右终结符）
};

// ---------- 结合性 ----------
enum class YaccAssoc { None, Left, Right };

// ---------- 驱动器 ----------
class MiniYacc {
public:
    // startSym 指定文法开始非终结符；内部自动增广 S'→startSym。
    MiniYacc(std::vector<YaccRule> rules, const std::string &startSym,
             std::vector<std::string> terminals);

    // 优先级/结合性声明（%left/%right/%prec 的教学对应物）。
    void setPrec(const std::string &term, int level, YaccAssoc assoc);

    struct RunResult {
        bool accept = false;
        int steps = 0;
        std::vector<std::string> reduceLog;   // "p: lhs → rhs" 逐次归约
        std::vector<std::string> actionLog;   // 动作名按执行序（嵌入改写对账用）
        YaccValue result;
    };

    // 值栈分析：stateStack 与 valueStack 平行推进；Err 即拒绝。
    // 非 const：首次调用会触发冲突仲裁（声明先于规则、表收尾生成的 yacc 次序）。
    RunResult parse(const std::vector<std::pair<std::string, std::string>> &toks,
                    bool runActions);

    // ---- 第 10 章扩展（本章正题）：错误处置四模式 ----
    //   None     报错即停（对照组）
    //   TokenDel 朴素删除：删当前 token 重试——级联假错误的制造机
    //   Panic    恐慌模式：丢输入至"栈上某状态能接受"为止（L 书 §5.7.2 应急方式）
    //   ErrorProd 文法里写好 error 记号：弹栈至可移进 error、移进、
    //             再丢输入至表恢复动作（yacc 的 error 记号协议，§5.7.3）
    enum class Recover { None, TokenDel, Panic, ErrorProd };
    struct RecoverOut {
        bool accept = false;
        int steps = 0;
        std::vector<std::pair<int, std::string>> diags;   // (token 下标, 人话)
        int detectPos = -1;                               // 首错位置（LL/LR 对照的 LR 侧）
        std::vector<std::string> reduceLog;
    };
    RecoverOut parseRecover(const std::vector<std::pair<std::string, std::string>> &toks,
                            Recover mode);

    // 冲突账本：resolve 前后可各打印一次。
    struct ConflictStats {
        int raw = 0;            // 表构造期记录的冲突格数
        int byPrec = 0;         // 优先级高者胜
        int byAssoc = 0;        // 同级看结合性
        int defaultShift = 0;   // 一方无优先级：缺省移进
        int ruleOrder = 0;      // reduce/reduce：先声明者胜
        int unresolved = 0;
    };
    const ConflictStats &conflictStats() const {
        const_cast<MiniYacc *>(this)->ensureResolved();
        return cstats_;
    }

    const Grammar &grammar() const { return g_; }
    const Table &table() const {
        const_cast<MiniYacc *>(this)->ensureResolved();
        return tab_;
    }

private:
    void buildTable();
    void resolveConflicts();
    // yacc 的 .y 文件里声明在规则前、表在收尾生成——对应到代码就是
    // 「setPrec 尽管晚到，首次用时（parse/取表）才仲裁」。
    void ensureResolved() {
        if (!resolved_) {
            resolveConflicts();
            resolved_ = true;
        }
    }
    int prodPrecOf(int rulesIdx) const;   // 产生式优先级：%prec 覆盖或最右终结符

    Grammar g_;
    std::vector<YaccRule> rules_;   // 含增广产生式在内的展开结果（与 g_.prods 对齐）
    Table tab_;
    std::map<std::string, std::pair<int, YaccAssoc>> prec_;  // 终结符 → (级, 结合性)
    ConflictStats cstats_;
    bool resolved_ = false;
};

// ---------- 嵌入动作 = 空产生式改写（§5.5.6）----------
// rhs 中以 '#' 起头的符号是嵌入动作占位（"#log"），其执行体经 embeds 旁表给出。
// rewriteEmbedded 把占位符变成新的 ε 非终结符并搬运动作——等价性的机制核心。
// 返回 (改写后的规则集, 新增的 ε 规则数)。
std::pair<std::vector<YaccRule>, int> rewriteEmbedded(
    std::vector<YaccRule> rules,
    std::map<std::string, std::pair<YaccAction, std::string>> embeds);

// 产生式打印："lhs → a b c"（ε 显示为 ε）。
std::string showProd(const Grammar &g, int p);

}  // namespace tip

#endif  // TIP_YACC_HPP
