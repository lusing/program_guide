// file: src/main.cpp
// 第 59 章驱动（无参运行，走"简单程序"对账协议）：
//   直线块上两个局部分配器（频率计数 vs farthest-use）→
//   手造 SSA CFG 的干涉图 → MCS 找 PEO → 弦图最优着色 vs Briggs →
//   支配树先序是否为 PEO 的理论核验 → 五断言。
#include "alloc.hpp"

#include <iostream>

namespace {

// ---------- 直线块：局部分配的战场 ----------
// a 前四条高频、之后死透——频率计数给 a 整块独占（后半块白占一格），
// farthest-use 在压力出现时立刻把 a 请出去，让位给后半块的热值。
std::vector<tip::LocalInst> demoBlock() {
    return {
        {"a", {}}, {"b", {}},
        {"t1", {"a", "a"}},
        {"t2", {"a", "b"}},
        {"t3", {"a", "a"}},
        {"u1", {"t1", "t2"}},
        {"u2", {"t2", "t3"}},
        {"u3", {"u1", "u2"}},
        {"u4", {"u3", "t2"}},
        {"", {"u4"}},
    };
}

// ---------- SSA CFG：弦图的战场 ----------
// 嵌套分支 + 汇合 φ：d/e 两臂各算一次、汇合处 φ 合并。
std::vector<tip::SsaBlockLite> demoSsa() {
    tip::SsaBlockLite b0;                       // 入口：三个常量
    b0.body = {{"a0", {}}, {"b0", {}}, {"c0", {}}};
    b0.succs = {1};

    tip::SsaBlockLite b1;                       // 分支头
    b1.body = {{"", {"a0", "b0"}}};             // if a0 > b0 goto B2
    b1.succs = {2, 3};

    tip::SsaBlockLite b2;                       // then 臂
    b2.body = {{"d0", {"a0", "b0"}}, {"e0", {"d0", "c0"}}, {"f0", {"e0", "b0"}}};
    b2.succs = {4};

    tip::SsaBlockLite b3;                       // else 臂
    b3.body = {{"d1", {"a0", "b0"}}, {"e1", {"d1", "c0"}}, {"g0", {"e1", "a0"}}};
    b3.succs = {4};

    tip::SsaBlockLite b4;                       // 汇合：φ + 收尾
    tip::SsaInstLite dphi, ephi, fphi;
    dphi.dst = "d2";  dphi.uses = {"d0", "d1"};  dphi.isPhi = true;
    ephi.dst = "e2";  ephi.uses = {"e0", "e1"};  ephi.isPhi = true;
    fphi.dst = "h0";  fphi.uses = {"f0", "g0"};  fphi.isPhi = true;
    b4.body = {dphi, ephi, fphi,
               {"h1", {"d2", "e2"}},
               {"h2", {"h0", "h1"}},
               {"", {"h1"}},
               {"", {"h2"}}};
    b4.succs = {};

    std::vector<tip::SsaBlockLite> blocks = {b0, b1, b2, b3, b4};
    // preds 按 B2（then，跳转边）在前、B3（else，落空边）在后——与 φ 实参次序一致
    blocks[1].preds = {0};
    blocks[2].preds = {1};
    blocks[3].preds = {1};
    blocks[4].preds = {2, 3};
    return blocks;
}

}  // namespace

int main() {
    // ---------- 局部分配 ----------
    std::cout << "== 局部分配（k=3）==\n";
    auto blk = demoBlock();
    tip::LocalReport td = tip::topDownLocal(blk, 3);
    tip::LocalReport bu = tip::bottomUpLocal(blk, 3);
    std::cout << "  自顶向下（频率计数）: 驻留 {";
    for (size_t i = 0; i < td.resident.size(); ++i)
        std::cout << (i ? "," : "") << td.resident[i];
    std::cout << "} 访存=" << td.memoryTraffic << "\n";
    std::cout << "  自底向上（farthest-use）: 访存=" << bu.memoryTraffic << "\n";

    // ---------- 干涉图 ----------
    std::cout << "== SSA 干涉图 ==\n";
    auto blocks = demoSsa();
    tip::Graph g = tip::buildInterference(blocks);
    std::cout << "  节点 " << g.nodes.size() << " 个，边 " << g.edges.size() << " 条:\n";
    for (const auto &e : g.edges)
        std::cout << "    " << e.first << " — " << e.second << "\n";

    // ---------- MCS 与 PEO ----------
    std::cout << "== MCS 与完美消除序 ==\n";
    std::vector<std::string> order = tip::mcsOrder(g);
    std::vector<std::string> peo(order.rbegin(), order.rend());
    std::cout << "  MCS 序（编号序）:";
    for (const auto &v : order) std::cout << " " << v;
    std::cout << "\n  PEO（MCS 逆序）:";
    for (const auto &v : peo) std::cout << " " << v;
    std::cout << "\n";

    // ---------- 弦图最优着色 vs Briggs ----------
    std::cout << "== 着色对照 ==\n";
    std::map<std::string, int> cc = tip::chordalColor(g, peo);
    int chordalK = 0;
    for (const auto &kv : cc) chordalK = std::max(chordalK, kv.second + 1);
    int omega = tip::peoCliqueNumber(g, peo);
    std::map<std::string, int> bc = tip::briggsColor(g, chordalK + 1);
    int briggsK = 0;
    for (const auto &kv : bc) briggsK = std::max(briggsK, kv.second + 1);
    std::cout << "  弦图（PEO 贪心）: 色数=" << chordalK << "，团数=" << omega << "\n";
    std::cout << "  Chaitin–Briggs（k=" << chordalK + 1 << "）: 用色=" << briggsK << "\n";

    // ---------- 支配树先序的理论核验 ----------
    // 定理（Hack 等）：SSA 干涉图是弦图，且"定义点的支配树先序的某个方向"
    // 是 PEO。我们的 CFG：B0→B1→{B2,B3}→B4，支配树先序上块内按定义序。
    // 手工给出两个方向的序，让机器裁决哪个是 PEO。
    std::cout << "== 支配树先序核验 ==\n";
    std::vector<std::string> domPre = {"a0", "b0", "c0", "d0", "e0", "f0",
                                       "d1", "e1", "g0", "d2", "e2", "h0", "h1", "h2"};
    bool fwd = tip::isPerfectElimination(g, domPre);
    std::vector<std::string> domRev(domPre.rbegin(), domPre.rend());
    bool rev = tip::isPerfectElimination(g, domRev);
    std::cout << "  支配树先序是 PEO: " << (fwd ? "yes" : "no") << "\n";
    std::cout << "  支配树先序的逆是 PEO: " << (rev ? "yes" : "no") << "\n";
    (void)fwd;
    (void)rev;

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = tip::isPerfectElimination(g, peo);
    bool ok2 = chordalK == omega;
    bool ok3 = tip::coloringValid(g, cc, chordalK) && tip::coloringValid(g, bc, chordalK + 1);
    bool ok4 = chordalK <= briggsK;
    bool ok5 = bu.memoryTraffic <= td.memoryTraffic;
    std::cout << "  MCS 逆序通过 PEO 校验（图是弦图）: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  弦图色数 == 团数（最优性）: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  两份着色相邻异色且域合法: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  弦图色数 ≤ Briggs 用色: " << (ok4 ? "yes" : "NO") << "\n";
    std::cout << "  farthest-use 访存 ≤ 频率计数: " << (ok5 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4 && ok5) ? 0 : 1;
}
