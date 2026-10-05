// file: src/main.cpp
// 第 52 章驱动（无参运行，走“简单程序”对账协议）：
//   依赖检验（GCD + 方向向量）→ 交换合法性 → 三种顺序的缓存 miss 对比。
#include "loc.hpp"

#include <iostream>

int main() {
    std::cout << "== 依赖检验 ==\n";
    // 访问对：写 a[i][j]，读 a[i-k][j]（k=1）
    // 下标方程：i*1 - i'*1 = k（同一数组、同 j）
    tip::GcdInfo g = tip::gcdDep(1, 1, 1);
    std::cout << "  写 a[i][j] / 读 a[i-1][j]: gcd(1,1)=" << g.gcd
              << " 整除 1: " << (g.dependent ? "yes" : "no")
              << " => 存在依赖\n";
    std::vector<int> dir = tip::directionOf(1);
    std::cout << "  方向向量: " << tip::showDir(dir)
              << " 交换合法: " << (tip::directionLegal(dir) ? "yes" : "no") << '\n';
    // 逆序反例：读 a[i+1][j]
    std::vector<int> bad = tip::directionOf(1);
    bad[0] = -bad[0];
    std::cout << "  反例（读 a[i+1][j]）: " << tip::showDir(bad)
              << " 交换合法: " << (tip::directionLegal(bad) ? "yes" : "no") << '\n';

    std::cout << "== 缓存模拟（直接映射，行=4 单元，槽=8）==\n";
    const int N = 16;
    tip::CacheReport row = tip::cacheSim(N, tip::Order::RowMajor, 4, 8);
    tip::CacheReport col = tip::cacheSim(N, tip::Order::ColMajor, 4, 8);
    tip::CacheReport til = tip::cacheSim(N, tip::Order::Tiled, 4, 8);
    std::cout << "  row-major : reads=" << row.reads << " writes=" << row.writes
              << " misses=" << row.misses << '\n';
    std::cout << "  col-major : reads=" << col.reads << " writes=" << col.writes
              << " misses=" << col.misses << '\n';
    std::cout << "  2x2 tiled : reads=" << til.reads << " writes=" << til.writes
              << " misses=" << til.misses << '\n';
    std::cout << "== 对账 ==\n";
    std::cout << "  col 交换后读 miss 高于 row（行主序缓存下行序即正义）\n";
    std::cout << "  tiled 摊 miss 最低（时间局部性入袋）\n";
    return 0;
}
