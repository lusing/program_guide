// file: src/loc.cpp
// 第 52 章配套：仿射访问分析（方向向量 + GCD 检验）、循环交换合法性、
// 直接映射缓存模拟（原序/交换/分块三种顺序的 miss 对比）。
#include "loc.hpp"

#include <algorithm>
#include <map>
#include <set>
#include <sstream>

namespace tip {

GcdInfo gcdDep(int i1, int i2, int c) {
    // 依赖存在性：i1 - i2 = c 有整数解 ⟺ gcd(i1,i2) | c
    int a = std::abs(i1), b = std::abs(i2);
    while (b) {
        int t = a % b;
        a = b;
        b = t;
    }
    GcdInfo g;
    g.gcd = a;
    g.dependent = (c % a == 0);
    return g;
}

bool directionLegal(const std::vector<int> &dir) {
    // 交换合法性（教学口径）：方向向量不含 "<" 分量（紫龙 11.3 的交换条件）
    for (int d : dir)
        if (d < 0) return false;
    return true;
}

// 方向向量：两层嵌套、两处仿射访问 a[i][j] 写 / a[i-k][j] 读（k>0 常数）
std::vector<int> directionOf(int k) {
    (void)k;   // 方向与 k 的具体值无关（均为外层正向）
    // 外层 i：写 i、读 i-k ⇒ 外层方向 = +1（写后读，跨圈）
    // 内层 j：读写同 j ⇒ 0
    return {1, 0};
}

std::string showDir(const std::vector<int> &d) {
    std::ostringstream os;
    os << "(";
    for (size_t i = 0; i < d.size(); ++i)
        os << (i ? "," : "") << (d[i] > 0 ? "<" : d[i] < 0 ? ">" : "=");
    os << ")";
    return os.str();
}

CacheReport cacheSim(int N, Order ord, int lineSize, int cacheLines) {
    // 直接映射缓存：addr/lineSize 映到 addr/lineSize % cacheLines；
    // 访问序列按顺序生成：row-major 写 a[i][j]，配对读按 k 步距。
    CacheReport r;
    r.reads = r.writes = r.misses = 0;
    std::map<int, int> tag;   // 槽位 → 行号（冲突即 miss 换主）
    auto touch = [&](int addr, bool isWrite) {
        int line = addr / lineSize;
        int slot = line % cacheLines;
        if (isWrite) ++r.writes;
        else ++r.reads;
        auto it = tag.find(slot);
        if (it == tag.end() || it->second != line) {
            tag[slot] = line;
            ++r.misses;
        }
    };
    const int K = 1;
    auto cell = [&](int i, int j) { return i * N + j; };
    if (ord == Order::RowMajor) {
        for (int i = 0; i < N; ++i)
            for (int j = 0; j < N; ++j) {
                touch(cell(i, j), true);
                if (i - K >= 0) touch(cell(i - K, j), false);
            }
    } else if (ord == Order::ColMajor) {
        for (int j = 0; j < N; ++j)
            for (int i = 0; i < N; ++i) {
                touch(cell(i, j), true);
                if (i - K >= 0) touch(cell(i - K, j), false);
            }
    } else {
        // 2x2 tiling：块内行优先
        for (int ii = 0; ii < N; ii += 2)
            for (int jj = 0; jj < N; jj += 2)
                for (int i = ii; i < std::min(ii + 2, N); ++i)
                    for (int j = jj; j < std::min(jj + 2, N); ++j) {
                        touch(cell(i, j), true);
                        if (i - K >= 0) touch(cell(i - K, j), false);
                    }
    }
    return r;
}

}  // namespace tip
