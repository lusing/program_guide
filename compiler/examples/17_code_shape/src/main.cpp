// file: src/main.cpp
// 第 17 章驱动（无参运行，走"简单程序"对账协议）：
//   二维地址多项式（朴素/假零/枚举）三方对账 → dope vector 对照与操作数 →
//   case 三策略选择与代价对比 → 字符串三表示的访存账 → 四断言。
#include "shape.hpp"

#include <iostream>

namespace {

const char *reprName(tip::StrRepr r) {
    switch (r) {
    case tip::StrRepr::Fixed: return "定长";
    case tip::StrRepr::LengthPrefix: return "长度前缀";
    case tip::StrRepr::NulTerminated: return "零终止";
    }
    return "?";
}

}  // namespace

int main() {
    // ---------- 数组：A[1..2, 1..4]，w=4（鲸书 §7.5.3 的例）----------
    const int low1 = 1, high1 = 2, low2 = 1, high2 = 4, w = 4;
    std::cout << "== 二维地址多项式（A[1..2,1..4]，w=4）==\n";
    std::cout << "  假零基址 @A0 = @A + (" << tip::falseZeroBase(low1, high1, low2, high2, w)
              << ")  ← 下界项折进基址\n";
    bool agree = true;
    for (int i = low1; i <= high1; ++i)
        for (int j = low2; j <= high2; ++j) {
            int naive = tip::rowMajor2Naive(i, j, low1, high1, low2, high2, w);
            int fz = tip::rowMajor2FalseZero(i, j, low1, high1, low2, high2, w);
            int enu = tip::rowMajor2Enumerate(i, j, low1, high1, low2, high2, w);
            bool ok = naive == fz && fz == enu;
            agree = agree && ok;
            std::cout << "  A[" << i << "," << j << "] 朴素=" << naive
                      << " 假零=" << fz << " 枚举=" << enu << (ok ? "" : "  ←不一致!") << "\n";
        }
    // 鲸书的数字例：A[2,3] 在 @A+24
    int a23 = tip::rowMajor2Naive(2, 3, low1, high1, low2, high2, w);
    std::cout << "  鲸书例：A[2,3] 落在 @A+" << a23 << "（书中间距 24）\n";

    // ---------- dope vector ----------
    std::cout << "== dope vector（形状运行期才知）==\n";
    tip::DopeVector d;
    d.falseZero = tip::falseZeroBase(low1, high1, low2, high2, w);
    d.stride = high2 - low2 + 1;
    d.w = w;
    bool dopeOk = true;
    for (int i = low1; i <= high1; ++i)
        for (int j = low2; j <= high2; ++j)
            dopeOk = dopeOk && tip::dopeAddr(d, i, j)
                     == tip::rowMajor2FalseZero(i, j, low1, high1, low2, high2, w);
    std::cout << "  dope 访问与多项式一致: " << (dopeOk ? "yes" : "NO") << "\n";
    std::cout << "  操作数（编译期已知形状）=" << tip::opsKnownShape()
              << "（dope）=" << tip::opsDopeShape() << " ← 每次访问多读一次 stride\n";

    // ---------- case 三策略 ----------
    std::cout << "== case 三策略 ==\n";
    std::vector<int> dense = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    std::vector<int> sparse = {0, 15, 23, 37, 41, 50, 68, 72, 83, 99};
    std::vector<int> tiny = {1, 3, 5};
    auto strat = [](tip::CaseStrategy s) {
        return s == tip::CaseStrategy::Linear ? "线性链"
             : s == tip::CaseStrategy::Binary ? "二分" : "跳转表";
    };
    std::cout << "  密集 0..9（10 个）→ " << strat(tip::chooseStrategy(dense)) << "\n";
    std::cout << "  稀疏 {0,15,23,...,99}（10 个，跨 100）→ "
              << strat(tip::chooseStrategy(sparse)) << "\n";
    std::cout << "  三个标签 {1,3,5} → " << strat(tip::chooseStrategy(tiny)) << "\n";

    // 密集集合上的均摊比较（取值域均匀，含 default）
    double lin = tip::avgCost(dense, 0, 9, tip::costLinear);
    double bin = tip::avgCost(dense, 0, 9, tip::costBinary);
    long jtTotal = 0;
    for (int v = 0; v <= 9; ++v) jtTotal += tip::costJumpTable(dense, 0, 9, v);
    double jt = static_cast<double>(jtTotal) / 10;
    std::cout << "  密集集均摊比较：线性=" << lin << " 二分=" << bin
              << " 跳转表=" << jt << "\n";
    // 稀疏集合上：二分 vs（若强行）跳转表的表规模
    std::cout << "  稀疏集：二分均摊=" << tip::avgCost(sparse, 0, 99, tip::costBinary)
              << "；若建表需 100 槽（密度 0.1）——不划算\n";

    // ---------- 字符串三表示 ----------
    std::cout << "== 字符串三表示（a 长 12、b 长 34）==\n";
    const int la = 12, lb = 34;
    for (tip::StrRepr r : {tip::StrRepr::Fixed, tip::StrRepr::LengthPrefix,
                           tip::StrRepr::NulTerminated}) {
        std::cout << "  " << reprName(r)
                  << ": length(a) 访存=" << tip::strlenTouches(r, la)
                  << "  length(a+b) 访存=" << tip::concatLenTouches(r, la, lb) << "\n";
    }

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = agree && a23 == 24;
    bool ok2 = dopeOk && tip::opsKnownShape() < tip::opsDopeShape();
    bool ok3 = tip::chooseStrategy(dense) == tip::CaseStrategy::JumpTable
            && tip::chooseStrategy(sparse) == tip::CaseStrategy::Binary
            && tip::chooseStrategy(tiny) == tip::CaseStrategy::Linear
            && jt < bin && bin < lin;
    bool ok4 = tip::strlenTouches(tip::StrRepr::LengthPrefix, la)
                   < tip::strlenTouches(tip::StrRepr::NulTerminated, la)
            && tip::concatLenTouches(tip::StrRepr::LengthPrefix, la, lb)
                   < tip::concatLenTouches(tip::StrRepr::NulTerminated, la, lb);
    std::cout << "  多项式=假零=枚举 且 A[2,3]=@A+24: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  dope 地址一致且操作数更多: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  策略按密度选择且代价 跳转表<二分<线性: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  长度前缀长度/拼接访存都少于零终止: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
