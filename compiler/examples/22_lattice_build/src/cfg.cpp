#include "cfg.hpp"

#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"

namespace tip {
namespace {

// 两遍构造：第一遍按 AST 先序给所有程序点分配固定编号；第二遍连边。
// 先编号再连边，是为了让编号严格按源码顺序（连边时若先构造后继节点，
// 后继会抢在前面编号），从而输出与程序点编号都是确定的。
class CfgBuilder {
public:
    explicit CfgBuilder(const ProgramA &program) : program_(program) {}

    Cfg run() {
        Cfg cfg;
        for (const auto &fun : program_.funs) {
            FunCfg fc;
            cur_ = &fc;
            cur_->name = fun->name;
            nextId_ = 1;
            stmtId_.clear();

            const int entry = addNode(CfgNode::Kind::Entry);
            cur_->entry = entry;
            numberStmt(fun->body.get());
            const int retId = addNode(CfgNode::Kind::Return, fun->ret.get());
            const int exitId = addNode(CfgNode::Kind::Exit);
            cur_->exitNode = exitId;

            // 连边：语句构造返回它自己的入口点集合；空块没有节点，直接透传后继。
            std::vector<int> bodyEntries = wireStmt(fun->body.get(), {retId});
            if (bodyEntries.empty()) bodyEntries = {retId};
            link(entry, bodyEntries);
            link(retId, {exitId});

            // set 去重并排序：CFG 边不允许重复，输出顺序固定。
            std::set<std::pair<int, int>> uniq(cur_->edges.begin(), cur_->edges.end());
            cur_->edges.assign(uniq.begin(), uniq.end());
            cfg.funs.push_back(std::move(*cur_));
        }
        return cfg;
    }

private:
    const ProgramA &program_;
    FunCfg *cur_ = nullptr;
    int nextId_ = 1;
    std::map<const Stmt *, int> stmtId_;

    int addNode(CfgNode::Kind kind, const Stmt *stmt = nullptr) {
        const int id = nextId_++;
        cur_->nodes.emplace(id, CfgNode{id, kind, stmt});
        return id;
    }

    // ---- 第一遍：编号 ----
    void numberStmt(const Stmt *s) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            for (const auto &x : b->ss) numberStmt(x.get());
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->then.get());
            numberStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            stmtId_[x] = addNode(CfgNode::Kind::Branch, x);
            numberStmt(x->body.get());
            return;
        }
        if (dynamic_cast<const AssignS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Assign, s);
            return;
        }
        if (dynamic_cast<const OutputS *>(s)) {
            stmtId_[s] = addNode(CfgNode::Kind::Output, s);
        }
    }

    // ---- 第二遍：连边。返回进入该语句时首先到达的程序点集合 ----
    std::vector<int> wireStmt(const Stmt *s, const std::vector<int> &succ) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            std::vector<int> cur = succ;
            for (auto it = b->ss.rbegin(); it != b->ss.rend(); ++it)
                cur = wireStmt(it->get(), cur);
            return cur;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            const int n = stmtId_[x];
            std::vector<int> targets = wireStmt(x->then.get(), succ);
            if (targets.empty()) targets = succ;
            if (x->els) {
                std::vector<int> e = wireStmt(x->els.get(), succ);
                if (e.empty()) e = succ;
                targets.insert(targets.end(), e.begin(), e.end());
            } else {
                targets.insert(targets.end(), succ.begin(), succ.end());
            }
            link(n, targets);
            return {n};
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            const int n = stmtId_[x];
            // 循环体执行完回到条件点；空体时条件点连一条自边（等于死循环）。
            std::vector<int> bodyEntries = wireStmt(x->body.get(), {n});
            if (bodyEntries.empty()) bodyEntries = {n};
            link(n, bodyEntries);
            link(n, succ);
            return {n};
        }
        const int n = stmtId_[s];
        link(n, succ);
        return {n};
    }

    void link(int from, const std::vector<int> &to) {
        for (int t : to) cur_->edges.emplace_back(from, t);
    }
};

const char *kindName(CfgNode::Kind kind) {
    switch (kind) {
        case CfgNode::Kind::Entry: return "entry";
        case CfgNode::Kind::Exit: return "exit";
        case CfgNode::Kind::Assign: return "assign";
        case CfgNode::Kind::Output: return "output";
        case CfgNode::Kind::Branch: return "branch";
        case CfgNode::Kind::Return: return "return";
    }
    return "?";
}

}  // namespace

Cfg buildCfg(const ProgramA &program) { return CfgBuilder(program).run(); }

std::string printCfg(const Cfg &cfg) {
    std::ostringstream out;
    for (const FunCfg &f : cfg.funs) {
        out << "== " << f.name << " ==\n";
        out << "nodes:\n";
        for (const auto &[id, node] : f.nodes) {
            out << "  " << id << ": " << kindName(node.kind);
            if (node.stmt) out << "  " << printStmtLine(*node.stmt);
            out << "\n";
        }
        out << "edges:\n";
        for (const auto &[a, b] : f.edges) out << "  " << a << " -> " << b << "\n";
    }
    return out.str();
}

}  // namespace tip
