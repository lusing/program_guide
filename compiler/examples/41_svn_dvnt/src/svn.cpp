// file: src/svn.cpp
// 第 41 章配套：三档值编号的公共引擎与三种作用域纪律
// （LVN 块内 / SVN 扩展基本块 / DVNT 支配树，鲸书 §8.5.1 + §10.5.2）。
// φ 的表示沿用 ssa.cpp 口径：phiArgs 非空即是 φ；"删除"= 不进幸存序列。
#include "svn.hpp"

#include <functional>

namespace tip {

namespace {

// 值编号引擎：作用域化散列表（expr key → 既有定义名）+ 名字→规范名映射。
// 在 SSA 上运行：名字唯一，全局 vn 映射即可正确撤销（删 scope 只影响 expr 表）。
class VnEngine {
public:
    VnEngine(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
             const std::vector<std::set<int>> &preds)
        : prog_(ssa), adj_(adj), preds_(preds) {}

    VnResult finish() {
        VnResult r;
        r.rep = rep_;
        r.prog = prog_;
        return r;
    }

    int removed() const { return rep_.redundant + rep_.phiDeleted; }

    void pushScope() { scopes_.emplace_back(); }
    void popScope() { scopes_.pop_back(); }

    std::string canon(const std::string &x) const {
        auto it = vn_.find(x);
        return it == vn_.end() ? x : it->second;
    }

    // ---------- 处理一个块（重写 body，删除即不进幸存序列）----------
    // withPhi：DVNT 口径（块首先做 φ 三判）；LVN/SVN 跳过 φ 判定但保留实参改写。
    void processBlock(int b, bool withPhi) {
        std::vector<SsaInst> body = prog_.blocks[b].body;   // 取走原体
        std::vector<SsaInst> live;
        for (auto inst : body) {
            // ---- φ：phiArgs 非空即是（ssa.cpp 口径）----
            if (!inst.phiArgs.empty()) {
                if (withPhi) {
                    // 三判（鲸书 Figure 10.6）：实参先经 canon（可能已被前驱的
                    // 后继改写推进来）；
                    // 无义 → 并入实参公共值；重复 → 并入同键 φ；新值 → 入表
                    for (auto &arg : inst.phiArgs) arg = canon(arg);
                    bool same = true;
                    for (size_t k = 1; k < inst.phiArgs.size(); ++k)
                        if (inst.phiArgs[k] != inst.phiArgs[0]) { same = false; break; }
                    if (same) {
                        vn_[inst.dst] = inst.phiArgs[0];
                        ++rep_.phiDeleted;
                        rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                             " = φ(...) 无义，并入 " + inst.phiArgs[0]);
                        continue;   // 删除：不入 live
                    }
                    std::string key = "φB" + std::to_string(b) + "(";
                    for (size_t k = 0; k < inst.phiArgs.size(); ++k) {
                        if (k) key += ",";
                        key += inst.phiArgs[k];
                    }
                    key += ")";
                    std::string hit = lookupExpr(key);
                    if (!hit.empty()) {
                        vn_[inst.dst] = hit;
                        ++rep_.phiDeleted;
                        rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                             " = φ(...) 重复，并入 " + hit);
                        continue;
                    }
                    vn_[inst.dst] = inst.dst;
                    insertExpr(key, inst.dst);
                }
                live.push_back(inst);   // 幸存的 φ 原样保留
                continue;
            }
            // ---- 普通指令 ----
            switch (inst.op) {
            case TOp::Copy:
                inst.a = canon(inst.a);
                vn_[inst.dst] = inst.a;
                break;
            case TOp::Add: case TOp::Sub: case TOp::Mul:
            case TOp::Div: case TOp::Gt: case TOp::Eq: {
                inst.a = canon(inst.a);
                inst.b = canon(inst.b);
                std::string key = exprKey(inst);
                std::string hit = lookupExpr(key);
                if (!hit.empty()) {
                    vn_[inst.dst] = hit;
                    ++rep_.redundant;
                    rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                         " 复用 " + hit);
                    continue;   // 删除
                }
                vn_[inst.dst] = inst.dst;
                insertExpr(key, inst.dst);
                break;
            }
            case TOp::Input:
                vn_[inst.dst] = inst.dst;   // 两次 input 不同值，不可比较
                break;
            case TOp::Output: case TOp::Ret:
                inst.a = canon(inst.a);
                break;
            case TOp::IfGt: case TOp::IfEq:
                inst.a = canon(inst.a);
                inst.b = canon(inst.b);
                break;
            default:
                break;
            }
            live.push_back(inst);
        }
        prog_.blocks[b].body = live;
        // 后继 φ 实参随边改写（与 SSA 改名阶段的后继处理同型）
        for (int s : adj_[b]) {
            size_t pos = 0;
            for (int p : preds_[s]) {
                if (p == b) break;
                ++pos;
            }
            if (pos >= preds_[s].size()) continue;
            for (auto &inst : prog_.blocks[s].body)
                if (!inst.phiArgs.empty() && pos < inst.phiArgs.size())
                    inst.phiArgs[pos] = canon(inst.phiArgs[pos]);
        }
    }

private:
    std::string lookupExpr(const std::string &key) const {
        for (auto it = scopes_.rbegin(); it != scopes_.rend(); ++it) {
            auto f = it->find(key);
            if (f != it->end()) return f->second;
        }
        return "";
    }
    void insertExpr(const std::string &key, const std::string &name) {
        scopes_.back()[key] = name;
    }
    static std::string exprKey(const SsaInst &inst) {
        auto opChar = [](TOp op) {
            switch (op) {
            case TOp::Add: return "+";
            case TOp::Sub: return "-";
            case TOp::Mul: return "*";
            case TOp::Div: return "/";
            case TOp::Gt: return ">";
            case TOp::Eq: return "=";
            default: return "?";
            }
        };
        return std::string(opChar(inst.op)) + "(" + inst.a + "," + inst.b + ")";
    }

    SsaProgram prog_;
    const std::vector<std::vector<int>> &adj_;
    const std::vector<std::set<int>> &preds_;
    std::vector<std::map<std::string, std::string>> scopes_;
    std::map<std::string, std::string> vn_;
    VnReport rep_;
};

}  // namespace

VnResult runLVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds) {
    VnEngine eng(ssa, adj, preds);
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        eng.pushScope();
        eng.processBlock(static_cast<int>(b), false);
        eng.popScope();
    }
    VnResult r = eng.finish();
    r.rep.sweeps = 1;
    return r;
}

VnResult runSVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds) {
    VnEngine eng(ssa, adj, preds);
    std::vector<bool> done(ssa.blocks.size(), false);
    // 沿单前驱链递归携带表；多前驱后继进工作表、空表重来（鲸书 Figure 8.12）
    std::vector<int> worklist;
    std::function<void(int)> svnRec = [&](int b) {
        done[b] = true;
        eng.pushScope();
        eng.processBlock(b, false);
        for (int s : adj[b]) {
            if (done[s]) continue;
            if (preds[s].size() == 1) svnRec(s);   // 携带上下文深入
            else worklist.push_back(s);            // 汇合点：外层空表重来
        }
        eng.popScope();
    };
    svnRec(0);
    for (int b : worklist)
        if (!done[b]) {
            done[b] = true;
            eng.pushScope();
            eng.processBlock(b, false);
            eng.popScope();
        }
    VnResult r = eng.finish();
    r.rep.sweeps = 1;
    return r;
}

VnResult runDVNT(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds, const DomInfo &di) {
    VnEngine eng(ssa, adj, preds);
    // 支配树先序：每块开一个 scope，处理完孩子再收（鲸书：先序保证用前先定义）
    std::function<void(int)> walk = [&](int b) {
        eng.pushScope();
        eng.processBlock(b, true);
        for (int c : di.children[b]) walk(c);
        eng.popScope();
    };
    // 扫到不动点：第一轮改写后继 φ 实参后，"两臂同值"的 φ 要第二轮才看得见
    int prev = -1, sweeps = 0;
    for (int s = 0; s < 4; ++s) {
        walk(0);
        ++sweeps;
        int now = eng.removed();
        if (now == prev) break;
        prev = now;
    }
    VnResult r = eng.finish();
    r.rep.sweeps = sweeps;
    return r;
}

}  // namespace tip
