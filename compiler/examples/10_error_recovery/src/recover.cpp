// LL(1) 三模式驱动实现。表与 FIRST/FOLLOW 全部来自第 6 章副本（零改动）。
#include "recover.hpp"

namespace tip {

namespace {

std::string topShow(const std::vector<std::string> &st) {
    return st.empty() ? "<empty>" : st.back();
}

}  // namespace

LLResult llParse(const LL1 &ll, const std::vector<std::string> &input, LLRecover mode) {
    LLResult r;
    // 栈底 $，其上是开始符号；输入尾部补 $。
    std::vector<std::string> st{"$", ll.g.start};
    std::vector<std::string> in = input;
    in.push_back("$");
    size_t i = 0;
    int noConsume = 0;   // Phrase 守卫：连续"不消耗输入的修复"计数
    auto diag = [&](const std::string &msg) {
        Diag d{static_cast<int>(i), msg + " [top=" + topShow(st) + " la=" + in[i] + "]"};
        r.diags.push_back(d);
        if (r.detectPos < 0) r.detectPos = static_cast<int>(i);
    };
    while (!st.empty()) {
        if (++r.steps > 4000) return r;   // 保险丝：模式错误时防止失控
        std::string top = st.back();
        if (top == "$" && in[i] == "$") {
            st.pop_back();
            r.accept = st.empty();
            return r;
        }
        if (ll.g.isTerm(top) || top == "$") {
            if (top == in[i]) {           // 匹配：弹栈前进
                st.pop_back();
                ++i;
                noConsume = 0;
                continue;
            }
            // 终结符不匹配——错误检测点
            switch (mode) {
            case LLRecover::None:
                diag("terminal mismatch");
                return r;
            case LLRecover::TokenDel:      // 朴素：删输入 token 重试（级联之源）
                diag("terminal mismatch");
                if (in[i] == "$") return r;
                ++i;
                break;
            case LLRecover::Panic:         // 恐慌：假定该终结符在输入中缺失——弹栈
                diag("terminal mismatch");
                st.pop_back();
                break;
            case LLRecover::Phrase:        // 短语级"插入"：假定输入缺了 top——弹掉它
                diag("terminal mismatch");
                if (++noConsume > 2) {     // 守卫：连续两次不消耗输入，强制吃一个
                    noConsume = 0;
                    if (in[i] != "$") ++i;
                } else {
                    st.pop_back();
                }
                break;
            }
            continue;
        }
        // 非终结符：查表
        auto key = std::make_pair(top, in[i]);
        auto cell = ll.table.find(key);
        if (cell != ll.table.end()) {
            const Production &p = ll.g.prods[cell->second];
            st.pop_back();
            for (auto it = p.rhs.rbegin(); it != p.rhs.rend(); ++it) st.push_back(*it);
            continue;
        }
        switch (mode) {
        case LLRecover::None:
            diag("empty table cell");
            return r;
        case LLRecover::TokenDel:
            diag("empty table cell");
            if (in[i] == "$") return r;
            ++i;
            break;
        case LLRecover::Panic: {
            // 丢输入至同步集 FOLLOW(A)，再弹掉 A——"这一段没有 A"的官方解释
            diag("empty table cell");
            const auto &fol = ll.follow.at(top);
            while (i + 1 < in.size() && !fol.count(in[i]) && in[i] != "$") ++i;
            st.pop_back();
            break;
        }
        case LLRecover::Phrase:
            // 短语级"删除"：la 已在 FOLLOW(A) 里，假定 A 推导了 ε——弹掉 A
            diag("empty table cell");
            if (ll.follow.at(top).count(in[i])) {
                if (++noConsume > 2) {
                    noConsume = 0;
                    if (in[i] != "$") ++i;
                } else {
                    st.pop_back();
                }
            } else if (in[i] != "$") {
                noConsume = 0;
                ++i;                      // A 的 FIRST 里谁都不是：删输入 token
            } else {
                st.pop_back();
            }
            break;
        }
    }
    return r;
}

}  // namespace tip
