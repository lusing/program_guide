// file: src/dag.cpp
// 第 34 章配套：DAG 构造与重发射实现。
#include "dag.hpp"

#include <cctype>
#include <set>

namespace tip {

namespace {
bool isNumD(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool commutative(TOp op) {
    return op == TOp::Add || op == TOp::Mul || op == TOp::Eq;
}
}  // namespace

DagResult dagBuild(const std::vector<Quad> &code, const Block &b) {
    DagResult d;
    auto newLeaf = [&](const std::string &s) {
        DagNode n;
        n.isLeaf = true;
        n.leaf = s;
        d.nodes.push_back(n);
        return static_cast<int>(d.nodes.size()) - 1;
    };
    auto leafFor = [&](const std::string &s) {
        for (int k = 0; k < static_cast<int>(d.nodes.size()); ++k)
            if (d.nodes[k].isLeaf && d.nodes[k].leaf == s) return k;
        return newLeaf(s);
    };
    // 取数走“当前绑定”：名字 → 它绑定的结点（Copy 由此穿透到值）；
    // 未绑定的名字（块外进来的值）才落成新叶。
    auto nodeFor = [&](const std::string &s) {
        if (isNumD(s)) return leafFor(s);
        auto it = d.labelOf.find(s);
        if (it != d.labelOf.end()) return it->second;
        return leafFor(s);
    };
    auto findOrCreate = [&](TOp op, int a, int bb) {
        for (int k = 0; k < static_cast<int>(d.nodes.size()); ++k) {
            const auto &n = d.nodes[k];
            if (!n.isLeaf && n.op == op && n.kid0 == a && n.kid1 == bb) {
                ++d.cseHits;
                return k;
            }
        }
        DagNode n;
        n.isLeaf = false;
        n.op = op;
        n.kid0 = a;
        n.kid1 = bb;
        d.nodes.push_back(n);
        return static_cast<int>(d.nodes.size()) - 1;
    };
    auto bind = [&](const std::string &name, int node) {
        auto it = d.labelOf.find(name);
        if (it != d.labelOf.end()) {
            // 旧绑定解除：把名字从旧结点的标签里摘掉（重定义）
            auto &old = d.nodes[it->second].labels;
            for (auto x = old.begin(); x != old.end();)
                if (*x == name) x = old.erase(x);
                else ++x;
        }
        d.labelOf[name] = node;
        d.nodes[node].labels.push_back(name);
    };
    // 结点取值表达式（代数恒等式的判定基础）：
    // 叶且是常量 → 值；否则无。
    auto constOf = [&](int k, int *val) {
        if (!d.nodes[k].isLeaf) return false;
        if (!isNumD(d.nodes[k].leaf)) return false;
        *val = std::atoi(d.nodes[k].leaf.c_str());
        return true;
    };
    for (int i = b.begin; i < b.end; ++i) {
        const Quad &q = code[i];
        switch (q.op) {
        case TOp::Copy: {
            bind(q.dst, nodeFor(q.a));
            break;
        }
        case TOp::Input: {
            // input 有副作用：不折叠成纯值叶；名字绑到“自身名叶”，
            // 让 a = t1 这类复制把 input 结果引下去（发射时 input 前置）。
            bind(q.dst, leafFor(q.dst));
            break;
        }
        case TOp::Add: case TOp::Sub: case TOp::Mul:
        case TOp::Div: case TOp::Gt: case TOp::Eq: {
            int lhs = nodeFor(q.a), rhs = nodeFor(q.b);
            // 交换律规范键：小的孩子下标在左，a+b 与 b+a 同结点
            if (commutative(q.op) && lhs > rhs) std::swap(lhs, rhs);
            // 代数恒等式（绿龙 12.4 的一小张表）：
            int lv = 0, rv = 0;
            bool lc = constOf(lhs, &lv), rc = constOf(rhs, &rv);
            int result = -1;
            if (q.op == TOp::Add && lc && lv == 0) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Add && rc && rv == 0) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && lc && lv == 1) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && rc && rv == 1) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && (lc && lv == 0)) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && (rc && rv == 0)) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Sub && rc && rv == 0) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Div && rc && rv == 1) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Add && lc && rc) {
                DagNode n;
                n.isLeaf = true;
                n.leaf = std::to_string(lv + rv);
                d.nodes.push_back(n);
                result = static_cast<int>(d.nodes.size()) - 1;
                ++d.algebraHits;
            }
            else if (q.op == TOp::Mul && lc && rc) {
                DagNode n;
                n.isLeaf = true;
                n.leaf = std::to_string(lv * rv);
                d.nodes.push_back(n);
                result = static_cast<int>(d.nodes.size()) - 1;
                ++d.algebraHits;
            }
            if (result < 0) result = findOrCreate(q.op, lhs, rhs);
            bind(q.dst, result);
            break;
        }
        default:
            break;   // 跳转/输出/返回：根引用在 emit 时登记
        }
    }
    return d;
}

std::vector<Quad> dagEmit(const DagResult &dag, const std::vector<Quad> &code,
                          const Block &b) {
    // 根：块尾跳转/输出/返回引用的操作数（保活），加上全部仍有标签的名字。
    std::set<int> live;
    for (const auto &kv : dag.labelOf) live.insert(kv.second);
    // 从根向下标记可达结点
    std::set<int> keep = live;
    std::vector<int> stack(live.begin(), live.end());
    while (!stack.empty()) {
        int k = stack.back();
        stack.pop_back();
        if (dag.nodes[k].isLeaf) continue;
        for (int kid : {dag.nodes[k].kid0, dag.nodes[k].kid1})
            if (kid >= 0 && !keep.count(kid)) {
                keep.insert(kid);
                stack.push_back(kid);
            }
    }
    // 拓扑序：结点数组天然按创建序，孩子先于父亲（构造保证），正向扫即可。
    std::vector<Quad> out;
    for (int k = 0; k < static_cast<int>(dag.nodes.size()); ++k) {
        if (!keep.count(k) || dag.nodes[k].isLeaf) continue;
        const auto &n = dag.nodes[k];
        Quad q;
        q.op = n.op;
        q.dst = n.labels.empty() ? "d" + std::to_string(k) : n.labels.front();
        q.a = dag.nodes[n.kid0].isLeaf ? dag.nodes[n.kid0].leaf
                                       : (!dag.nodes[n.kid0].labels.empty()
                                              ? dag.nodes[n.kid0].labels.front()
                                              : "d" + std::to_string(n.kid0));
        q.b = dag.nodes[n.kid1].isLeaf ? dag.nodes[n.kid1].leaf
                                       : (!dag.nodes[n.kid1].labels.empty()
                                              ? dag.nodes[n.kid1].labels.front()
                                              : "d" + std::to_string(n.kid1));
        out.push_back(q);
        // 额外标签：复制绑定
        for (size_t li = 1; li < n.labels.size(); ++li)
            out.push_back(Quad{TOp::Copy, n.labels[li], n.labels.front(), "", -1});
    }
    // 名字绑定到叶（常量/变量）的：以复制形式补发射（保持名字语义）。
    // t 系临时是块内草稿（tacgen 的表达式暂存），块外无读者，死绑定不补——
    // 这是“局部优化无全局活跃信息”下的保守规则里唯一安全的一刀。
    for (const auto &kv : dag.labelOf) {
        const auto &n = dag.nodes[kv.second];
        if (n.isLeaf && n.leaf != kv.first && kv.first[0] != 't')
            out.push_back(Quad{TOp::Copy, kv.first, n.leaf, "", -1});
    }
    // input 前置（副作用先行，定义先于使用），控制流/IO 收尾（它们不是值结点）。
    // 收尾指令引用死临时（如 return t7）时，把操作数改写为其绑定的叶。
    auto rewriteOperand = [&](std::string &x) {
        auto it = dag.labelOf.find(x);
        if (it != dag.labelOf.end() && dag.nodes[it->second].isLeaf)
            x = dag.nodes[it->second].leaf;
    };
    std::vector<Quad> inputs, tail;
    for (int i = b.begin; i < b.end; ++i) {
        Quad q = code[i];
        if (q.op == TOp::Input) {
            inputs.push_back(q);
        } else if (q.op == TOp::Output || q.op == TOp::Ret) {
            rewriteOperand(q.a);
            tail.push_back(q);
        } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
            rewriteOperand(q.a);
            rewriteOperand(q.b);
            tail.push_back(q);
        } else if (q.op == TOp::Goto) {
            tail.push_back(q);
        }
    }
    out.insert(out.begin(), inputs.begin(), inputs.end());
    out.insert(out.end(), tail.begin(), tail.end());
    return out;
}

}  // namespace tip
