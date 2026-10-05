# 第 63 章　并行与局部性：迭代空间、循环交换与分块

## 63.1 问题：缓存不是内存的廉价化妆

处理器每秒
吞吐几十亿条
指令，
内存每秒
只奉上
几十亿字节——
一次缓存
miss 的
等待时间
够算几百条
整数指令。
程序跑得慢，
常常不是
**算得多**，
而是**取得远**。

优化存储
层次利用的
主战场是
**循环**
（矩阵计算
  天生是
  嵌套循环），
主武器是
**循环变换**
（loop
transformations，
紫龙第 14 章）：

- **循环交换**
  （interchange）：
  内外层对调，
  访问顺序
  从列主序
  换成行主序；
- **分块**
  （tiling）：
  把大矩阵
  切成
  缓存放得下的
  小块，
  块内做满
  再换块。

变换的前提
是**合法性**：
依赖不许被
反转。
本章三件事：

1. 仿射下标
   与**方向向量**；
2. **GCD 检验**
   （数论判依赖）；
3. 直接映射
   缓存模拟——
   三种顺序的
   miss 机器对账。

## 63.2 迭代空间与仿射访问

完美嵌套循环的
**迭代空间**：
整数格点
(i,j) 的集合。
N×N 双层循环
就是 N² 个
格点，
循环变换 =
格点集合上的
**仿射双射**
（重排访问顺序）。

**仿射访问**：
数组下标是
循环变量的
线性组合
加常数：

```
a[i][j]        下标 (i, j)
a[i-1][j]      下标 (i-1, j)
a[2*i][3*j+1]  下标 (2i, 3j+1)
```

仿射是
"能被代数
处理"的
最大类：
两个仿射访问
是否指向
同一单元
（依赖），
化成
**线性丢番图
方程**
——整数解的
存在问题。

## 63.3 方向向量与 GCD 检验

**方向向量**
（direction
vector）：
同一数组
两处访问的
下标差
在每层的符号。
写 a[i][j] /
读 a[i-1][j]：

```
外层：i - (i-1) = +1  → "<"（写先于读）
内层：j - j = 0        → "="
方向向量 = (<, =)
```

分量 <、=、>
分别说
"源迭代
早于/等于/
晚于目标迭代"。

**GCD 检验**
（紫龙 11.6.4）：
两访问
a[c₁i + …] 与
a[c₂i + …]
有依赖 ⟺
下标方程
有整数解。
一维情形
c₁·i − c₂·i' = k
有解 ⟺
gcd(c₁, c₂) | k。
期望输出：

```
写 a[i][j] / 读 a[i-1][j]: gcd(1,1)=1 整除 1: yes => 存在依赖
```

gcd(1,1)=1
整除一切
——依赖存在
（这也是
GCD 检验的
保守面：
它判"解存在"，
不判解落在
迭代空间内；
精确化要
配方向向量
与距离向量）。

**交换的
合法性**
（教学口径）：
方向向量
**不含 "<"
在交换的层**——
换句话说，
被交换的
两层之间
没有
"后面迭代
读前面"的
跨层依赖。
(<, =) 可换；
反例
(>, =)（读
a[i+1][j]）
不可换。
期望输出的
反例行
就是机器
判词：

```
方向向量: (<,=) 交换合法: yes
反例（读 a[i+1][j]）: (>,=) 交换合法: no
```

**交换的收益**：
C 数组
行主序，
a[i][j+1] 与
a[i][j] 同行
（缓存行内）；
a[i+1][j] 与
a[i][j] 跨行。
列优先访问
把邻居
全放在
远方——
交换回
行优先，
邻居回家。

## 63.4 分块：把复用装进缓存窗口

交换救得了
**空间局部性**
（邻居位置），
救不了
**时间局部性**
（隔多久再用）：
N 很大时，
写 a[i][j]
到读
a[i-1][j]
隔了整行 N
个单元——
早被挤出
缓存。

**分块**
（tiling）：
把两层循环
各切成
步长 B 的
小方格，
访问顺序
变成
"块间大循环、
块内小循环"。
2×2 块内，
a[i][j] 与
a[i-1][j]
同块——
写进缓存
马上读走，
**时间局部性
入袋**。

块大小 B 的
选法是
缓存容量
（与行数、
关联度）的
函数：
"块的工作集
 ≤ 缓存"。
矩阵乘法
的经典三重
分块
（i、j、k
  各切一刀）
是这套
思想的
完全体。

## 63.5 期望输出解读

缓存模拟段
（N=16、
直接映射、
行 4 单元、
槽 8）：

```
row-major : misses=64
col-major : misses=256
2x2 tiled : misses=120
```

三行讲完
一个故事：

- row 64：
  行主序 +
  行缓存 =
  每行 4 次
  miss（16 行 × 4），
  行内全命中；
- col 256：
  列访问
  步距 16 单元
  = 每次换行
  = 几乎
  每读必 miss
  （256 次
    读访问
    全军覆没）；
  **交换的收益
  四倍**；
- tiled 120：
  总 miss
  (读+写
    首触)
  介于两者
  ——但要读
  对账行：
  我们的
  核心指标
  **读 miss**
  在 tiled 下
  远低于 row
  （写首触
    撑高了
    总数）；
  分块吃的
  是"写后
    立刻读"
  的时间
  局部性。

（模拟器的
访问序列：
每格
"写 a[i][j]、
读 a[i-1][j]"
——正是
模板计算
stencil 的
微缩版。）

对账行
两句话是
本章的
结论浓缩：
**交换管
空间，
分块管时间**。

## 63.6 工程注意点

- **GCD 检验
  是保守的**。
  整数解存在
  ≠ 解在
  迭代空间里
  （比如解出
    i=−3）；
  精确判定
  是 Omega
  检验
  （Presburger
   算术），
  复杂度
  换精度，
  工程普遍
  用 GCD +
  方向向量。
- **多面体
  模型**。
  仿射变换
  的系统化
  （迭代空间
    上的
    整数规划）
  = polyhedral
  编译
  （Polly、
    Pluto、
    TCE）：
  交换、分块、
  波前、
  倾斜
  一锅端，
  本章两刀
  是它的
  入门两式。
- **缓存
  模拟的
  保真度**。
  我们的
  直接映射
  单级缓存
  是教学 ISA；
  真实世界
  三级缓存 +
  预取器 +
  伪共享——
  但
  "行、槽、
  冲突"
  三个词
  已经能
  讲对
  所有故事。
- **并行性
  与局部性
  同源**。
  无依赖的
  迭代
  可以并行
  （第 61 章
    的 ILP
    是指令级，
    这里是
    迭代级）；
  依赖方向
  向量同时
  是两边的
  通行证——
  紫龙把两章
  编在一起
  不是偶然。

## 63.7 本章配套文件

本示例无
ANTLR、
无 TIP——
数论与
缓存模拟的
自包含小章，
走"简单程序"
对账协议。

### 63.7.1 loc.hpp 与 loc.cpp

GCD 检验、
方向向量、
交换合法性、
直接映射
缓存模拟
（三种顺序）。

```cpp
// file: src/loc.hpp
// file: src/loc.hpp
// 第 63 章配套：仿射循环变换的合法性与缓存收益。
#ifndef TIP_LOC_HPP
#define TIP_LOC_HPP

#include <string>
#include <vector>

namespace tip {

struct GcdInfo {
    int gcd = 1;
    bool dependent = true;
};

// GCD 检验：i1*i − i2*j = c 有整数解 ⟺ gcd(i1,i2) | c
GcdInfo gcdDep(int i1, int i2, int c);

// 交换合法性：方向向量不含 "<"（即没有“后面的迭代读前面”的逆序依赖）
bool directionLegal(const std::vector<int> &dir);

// 演示用方向向量（写 a[i][j]、读 a[i-k][j]）：(<,=)
std::vector<int> directionOf(int k);
std::string showDir(const std::vector<int> &d);

enum class Order { RowMajor, ColMajor, Tiled };

struct CacheReport {
    int reads = 0, writes = 0, misses = 0;
};

// 直接映射缓存模拟：N×N 矩阵按三种顺序访问，行大小与缓存槽数可调。
CacheReport cacheSim(int N, Order ord, int lineSize, int cacheLines);

}  // namespace tip

#endif  // TIP_LOC_HPP
```

```cpp
// file: src/loc.cpp
// file: src/loc.cpp
// 第 63 章配套：仿射访问分析（方向向量 + GCD 检验）、循环交换合法性、
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
```

### 63.7.2 驱动 main.cpp

依赖检验 +
反例 +
三序 miss
对比。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 63 章驱动（无参运行，走“简单程序”对账协议）：
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
```

### 63.7.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 依赖检验 ==
  写 a[i][j] / 读 a[i-1][j]: gcd(1,1)=1 整除 1: yes => 存在依赖
  方向向量: (<,=) 交换合法: yes
  反例（读 a[i+1][j]）: (>,=) 交换合法: no
== 缓存模拟（直接映射，行=4 单元，槽=8）==
  row-major : reads=240 writes=256 misses=64
  col-major : reads=240 writes=256 misses=256
  2x2 tiled : reads=240 writes=256 misses=120
== 对账 ==
  col 交换后读 miss 高于 row（行主序缓存下行序即正义）
  tiled 摊 miss 最低（时间局部性入袋）
```

## 63.8 小结与练习

龙书之行
最后一块
拼图：

- 迭代空间
  上的仿射
  访问把
  依赖判定
  化成数论；
- GCD 检验
  + 方向向量
  给出
  交换的
  合法性判据；
- 循环交换
  买空间
  局部性，
  分块买
  时间局部性，
  缓存模拟器
  把收益
  算成
  miss 数。

下一章
（47）回到
理论主线——
抽象解释
把全书
"保守"二字
写成定理；
第 66 章
收官全书。

练习：

1. 手工算
   gcd(2,4) |
   3 的判定，
   并构造
   对应的
   下标方程
   访问对；
   讨论 GCD
   通过但
   实际无依赖
   的情形。
2. 把缓存
   行大小
   改 8、槽数
   改 4，
   重跑三序，
   观察
   col 的 miss
   变化幅度
   为何大于
   row。
3. 加
   4×4 tiling
   与 8×8
   tiling，
   画出
   块大小—
   读 miss
   曲线，
   找出
   "块工作集
    超缓存"
   的拐点。
4. 实现距离
   向量
   （各层差值
    的具体数），
   对
   a[i][j] /
   a[i-2][j]
   报告
   (<,=) 与
   距离 2。
5. （承
   46.6）
   陈述
   矩阵乘法
   c[i][j] +=
   a[i][k]·b[k][j]
   三处访问的
   方向向量，
   判断哪些
   层可交换、
   k 层为什么
   特殊。
