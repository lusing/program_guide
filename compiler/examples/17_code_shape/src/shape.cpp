// file: src/shape.cpp
// 第 17 章配套：行主序多项式与假零、dope vector、case 三策略、字符串表示代价
// （鲸书 §7.5.3 + §7.6 + §7.8.3）。
#include "shape.hpp"

#include <algorithm>

namespace tip {

// ---------- 数组地址多项式 ----------

int vectorAddr(int i, int low, int w) {
    return (i - low) * w;
}

int rowMajor2Naive(int i, int j, int low1, int high1, int low2, int high2, int w) {
    (void)high1;   // 行数不进入单个元素的地址；签名保持"完整形状"自文档
    int len2 = high2 - low2 + 1;
    return (i - low1) * len2 * w + (j - low2) * w;
}

int falseZeroBase(int low1, int high1, int low2, int high2, int w) {
    (void)high1;
    int len2 = high2 - low2 + 1;
    return -(low1 * len2 + low2) * w;
}

int rowMajor2FalseZero(int i, int j, int low1, int high1, int low2, int high2, int w) {
    int len2 = high2 - low2 + 1;
    return falseZeroBase(low1, high1, low2, high2, w) + (i * len2 + j) * w;
}

int rowMajor2Enumerate(int i, int j, int low1, int high1, int low2, int high2, int w) {
    // 地面真值：按行主序把整个数组"摆开"，数 (i,j) 之前落了多少个元素
    int offset = 0;
    for (int r = low1; r <= high1; ++r)
        for (int c = low2; c <= high2; ++c) {
            if (r == i && c == j) return offset * w;
            ++offset;
        }
    return -1;   // 越界（不该发生）
}

// ---------- dope vector ----------

int dopeAddr(const DopeVector &d, int i, int j) {
    return d.falseZero + (i * d.stride + j) * d.w;
}

int opsKnownShape() {
    // multI i,len2 / add i,j / multI ,w / loadAO —— 2 乘 1 加 1 访存
    return 4;
}

int opsDopeShape() {
    // loadAI stride / mult / add / multI ,w / loadAO —— 多一次 stride 的访存
    return 5;
}

// ---------- case 三策略 ----------

CaseStrategy chooseStrategy(const std::vector<int> &labels) {
    int n = static_cast<int>(labels.size());
    if (n <= 3) return CaseStrategy::Linear;
    int lo = *std::min_element(labels.begin(), labels.end());
    int hi = *std::max_element(labels.begin(), labels.end());
    double density = static_cast<double>(n) / (hi - lo + 1);
    if (density >= 0.5 && (hi - lo + 1) <= 64) return CaseStrategy::JumpTable;
    return CaseStrategy::Binary;
}

int costLinear(const std::vector<int> &labels, int value) {
    for (size_t k = 0; k < labels.size(); ++k)
        if (labels[k] == value) return static_cast<int>(k) + 1;
    return static_cast<int>(labels.size());   // default：比完全部
}

int costBinary(const std::vector<int> &labels, int value) {
    // 标签有序；数折半步（含最后的相等判断）
    std::vector<int> s = labels;
    std::sort(s.begin(), s.end());
    int lo = 0, hi = static_cast<int>(s.size()) - 1, steps = 0;
    while (lo < hi) {
        int mid = (lo + hi) / 2;
        ++steps;
        if (s[mid] < value) lo = mid + 1;
        else hi = mid;
    }
    return steps + 1;
}

int costJumpTable(const std::vector<int> &labels, int lo, int hi, int value) {
    // 一次范围检查 + 一次按表跳转；命中与 default 同价
    (void)labels;
    if (value < lo || value > hi) return 1;
    return 2;
}

double avgCost(const std::vector<int> &labels, int lo, int hi,
               int (*cost)(const std::vector<int> &, int)) {
    // 对 [lo,hi] 均匀取值（含洞与 default），折算每次命中的平均比较数
    long total = 0, n = 0;
    for (int v = lo; v <= hi; ++v) {
        total += cost(labels, v);
        ++n;
    }
    return static_cast<double>(total) / n;
}

// ---------- 字符串 ----------

int strlenTouches(StrRepr r, int len) {
    switch (r) {
    case StrRepr::Fixed:         return 0;        // 长度是声明，编译期常量
    case StrRepr::LengthPrefix:  return 1;        // 读一次长度字
    case StrRepr::NulTerminated: return len + 1;  // 逐字符走到 '\0'
    }
    return -1;
}

int concatLenTouches(StrRepr r, int lenA, int lenB) {
    switch (r) {
    case StrRepr::Fixed:         return 0;                  // 两个常量相加
    case StrRepr::LengthPrefix:  return 2;                  // 两次读长度字
    case StrRepr::NulTerminated: return lenA + lenB + 2;    // 走完两段
    }
    return -1;
}

}  // namespace tip
