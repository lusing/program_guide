# 第 58 章　代码放置：热路径链与过程聚簇

## 58.1 问题：取指也要讲地理

第 16 章
把基本块
串成了
顺直的
跟踪，
第 56 章
讲了
分支
预测
吃
"顺直
红利"。
但
还有
一层
地理
没讲：
**代码
在
内存里
的
排列
顺序**。

CPU
取指
按
缓存行
搬运：
顺序
执行
B0→B1
时，
若 B1
紧挨
B0
之后，
取指
白拿
顺直
红利；
若 B1
在
另一个
角落，
每次
跳转
都是
一次
潜在的
i-cache
miss。
函数
也一样：
**热调用
对**
（caller、callee
总在
一起
执行）
分居
两页，
每次
调用
都
掀翻
缓存。

代码
放置
（code
placement）
就是
给
块
和
过程
**排座次**：
让
经常
一起
执行的
代码
住
在一起。
材料
取自
鲸书
§8.6.2
（全局
代码
放置）
与
§8.7.2
（过程
放置），
自包含
展开。
频度
哪来？
静态
估计
（回边
热、
循环
深度
加权）
或
profile
边
计数
——
鲸书
的
定性：
数据流
分析
保守
（覆盖
所有
路径），
profile
激进
（押注
历史
重演），
两者
都能
喂
本章
的
算法，
只是
频度
表的
成色
不同。

## 58.2 热路径链：频度降序的贪心拼接

块级
放置
的
核心
是
鲸书
Figure
8.16
的
**链
构造**：

1. 每块
  初始
  一条
  **退化
  链**，
  优先级
  = 边数
  E
  （最大
  值，
  "最冷"）；
2. 边
  按
  频度
  **降序**
  扫描：
  仅当
  x 是
  所在
  链的
  **尾**、
  y 是
  所在
  链的
  **头**，
  才
  把
  y 链
  接到
  x 链
  后；
3. 合并
  后的
  新链
  优先级
  =
  min(两链
  旧优先级,
  P++)
  ——P 是
  合并
  计数：
  第一条
  合并
  链
  (最热)
  拿
  0，
  之后
  递增；
  退化
  链
  保持
  E。

"尾
接头"
的
限制
保证
链
是
**可能
连续
执行**
的
路径
前缀；
优先级
编码
了
"热
到
什么
程度
轮到
你
上
场"。

**布局**
（Figure
8.17）：
入口
链
起步，
放完
一条
链，
把
它的
出边
指向的
**未放
链**
按
优先级
（小
=
热）
入
工作表；
循环
到
空。
链
内
的
边
全部
落
在
相邻
位置
——
**顺直
fall-through**，
跳转
只在
链间
发生。

期望
输出的
六块
例子：
入口
频度
10，
分支
7/3，
B1
再
分支
5/2。
链构造
的
流水
一目
了然：
(0,1,7)
先拼，
(1,3,5)、
(3,5,5)
顺着
接长，
得到
主链
(B0,B1,B3,B5)
优先级
0；
(2,4,3)
自成
一链
优先级
3；
(1,2,2)
与
(0,2,3)
因
端点
不是
链尾/
链头
被
跳过。
布局
B0
B1
B3
B5
B2
B4：
顺直
频度
12→20，
taken
16→8——
**一半
的
跳转
频度
被
布局
消灭**。

## 58.3 过程聚簇：调用图上的贪心缩点

过程
放置
（§8.7.2）
把
同一套
贪心
搬到
**调用图**：

1. 边
  （调用）
  按
  权重
  降序
  入
  优先
  队列；
  每个过程
  挂
  一张
  **有序
  表**
  list(p)
  =
  {p}；
2. 取
  最热
  边
  (x,y)：
  list(y)
  整段
  接到
  list(x)
  尾；
3. **ReSource**：
  y 的
  出边
  (y,z)
  改源
  为
  (x,z)
  （同
  目标
  并权）；
  **ReTarget**：
  指向
  y 的
  边
  (z,y)
  改靶
  为
  (z,x)
  （同源
  并权）；
4. 删
  y；
  循环
  到
  队列
  空。

终态：
每个
**连通
分量**
缩成
一个
节点，
它的
list
就是
该
分量
内
过程的
**相对
放置
序**。
自环
（递归）
只
改
权重
不
参与
合并
——
源汇
相同
挪不挪
都
一样。

期望
输出
复现
鲸书
Figure
8.22
的
全程：
(P5,P6,104)
先并、
(P5,P4,52)
跟上
（ReTarget
把
(P1,P4)
改到
P5、
与新边
并权
成
20）、
(P1,P2,20)
与
(P1,P5,20)
把
P1
系
并
成
(P1,P2,P5,P6,P4)、
最后
(P0,P1,12)
收拢
入口——
终序
**P0
P1
P2
P5
P6
P4
P3**，
与
书
中
手工
推演
一致。

## 58.4 度量：贪心优化的是什么

本章
实验
设计
里
藏了
一课。
初始
序
故意
打乱
（≈
源码
声明
序——
真实
二进制
的
常态，
与
调用
热度
无关）：

- **加权
  距离**
  Σ 权重
  ×
  位置差：
  662
  →
  354
  （近乎
  减半）；
- **相邻
  边权**
  （距离
  恰为
  1）：
  10
  →
  134；
- **窗口
  邻近度**
  （距离
  ≤3
  记权，
  近似
  "同
  一组
  缓存行
  共驻"）：
  112
  →
  198。

值得
诚实
记一笔：
若
初始
序
恰好
把
热簇
排
在
一起
（我们
第一版
实验
就是这样），
线性
距离
度量
可能
**惩罚**
聚簇
——它
会把
冷
被调者
（如
只被
10 次
调用
的
P3）
理性
流放
到
队尾，
距离
度量
只看见
"P1-P3
拉远了"，
看不见
"104×2
的
热簇
抱团
了"。
贪心
真正
优化
的是
**热簇
同居**，
不是
全图
距离
最优
——
这也
是
为什么
断言
选在
距离
与
窗口
双降
的
打乱
基线
上：
那个
基线
才是
放置
算法
的
真实
战场。

## 58.5 期望输出解读与对账

三段
输出、
四条
断言：

1. **链
  构造**：
  四次
  合并
  的
  流水
  （边、
  频度、
  新
  优先级）
  +
  终态
  链
  表
  (B0,B1,B3,B5)p0
  (B2,B4)p3；
2. **块
  布局**：
  基线
  （块号
  序）
  顺直
  12/
  taken
  16 →
  链
  布局
  顺直
  20/
  taken
  8；
3. **过程
  聚簇**：
  六步
  合并
  流水
  （含
  ReTarget
  并权
  后的
  20
  与
  12）+
  终序
  +
  三组
  度量
  对照。

断言：
块
布局
taken
降/
顺直
升
（一）、
过程
距离
与
窗口
双
改善
（二）、
最热
调用
对
(P5,P6)
相邻
（三）、
布局
完备
且
入口
打头
（四）。

## 58.6 工程注意点

- **链构造
  的
  数据
  结构**：
  我们
  的
  第一版
  用
  "块→链
  引用"
  直接
  重定向，
  踩了
  自食
  其尾
  的坑
  （重定向
  先
  覆盖
  了
  待拼接
  的
  尾链，
  append
  出
  重复
  块，
  布局
  死
  循环）；
  正解
  是
  **链
  索引**
  （块→
  链
  下标，
  链
  内容
  独立
  存放）。
  教科书
  伪码
  三行，
  实现
  的
  血泪
  一页。
- **频度
  从
  哪来**：
  无
  profile
  时
  的
  静态
  估计
  ——回边
  记
  循环
  次数
  上界、
  嵌套
  深度
  乘
  权、
  其余
  记
  1；
  鲸书
  §8.6
  的
  提醒：
  错误
  的
  频度
  会
  把
  冷
  路径
  摆
  到
  热位，
  比不
  摆
  更糟——
  **放置
  是
  押注，
  押错
  双倍
  伤害**。
- **与
  跟踪
  调度
  的
  分工**：
  第 16 章
  的
  跟踪
  线性化
  是
  **结构
  贪心**
  （不
  看频度，
  只
  顾
  顺直）；
  本章
  是
  **频度
  贪心**。
  生产
  编译器
  （如
  LLVM
  的
  MachineBlockPlacement）
  两者
  兼用：
  频度
  驱动
  主
  布局，
  结构
  规则
  处理
  平局
  与
  特殊
  形状。
- **巨型
  函数
  与
  巨型
  簇**：
  聚簇
  无
  上限
  时，
  一个
  入口
  可达
  的
  大
  连通
  分量
  会
  把
  整个
  程序
  拉成
  一条
  链——
  失去
  局部性
  的
  "全
  局
  最优"
  等于
  没有
  最优。
  实践
  里
  给
  合并
  设
  停止
  条件
  （簇
  体积
  上限、
  权重
  阈值）。
- **链接
  器
  的
  端**：
  过程
  放置
  的
  输出
  是
  "相对
  序"，
  落地
  要
  靠
  链接
  器
  尊重
  它
  （--symbol-ordering-file
  一类
  机制）；
  跨
  编译
  单元
  的
  聚簇
  还
  需要
  LTO
  把
  调用
  图
  拼全。

## 58.7 本章配套文件

本示例
无 ANTLR——
手造
CFG
频度
与
调用图
自包含，
走"简单
程序"
对账
协议。

### 58.7.1 place.hpp 与 place.cpp

链
构造、
链
布局、
过程
聚簇、
三组
度量。

```cpp
// file: src/place.hpp
// file: src/place.hpp
// 第 58 章配套：代码放置——热路径链构造与过程贪心聚簇（鲸书 §8.6.2 + §8.7.2）。
#ifndef TIP_PLACE_HPP
#define TIP_PLACE_HPP

#include <string>
#include <vector>

namespace tip {

// ---------- 块放置：热路径链 ----------

struct CfgEdge {
    int from, to;
    int freq;   // 执行频度（profile 或静态估计）
};

struct ChainPlan {
    std::vector<std::vector<int>> chains;   // 每条链的块序
    std::vector<int> priority;              // 链的优先级（小 = 热）
    std::vector<int> layout;                // 最终线性布局
    std::vector<std::string> steps;         // 链构造流水（边→合并）
};

// 鲸书 Figure 8.16：按边频降序扫描，x 是某链尾且 y 是某链头才合并；
// 新链优先级 = min(两链优先级, P++)；退化链初始优先级 = |edges|。
ChainPlan buildHotChains(int nBlocks, const std::vector<CfgEdge> &edges);

// 布局度量：顺直（fall-through）边频度合计 / 非顺直（taken）边频度合计。
// 布局里 y 紧跟 x 之后即顺直。
struct LayoutMetric {
    int fallFreq = 0;
    int takenFreq = 0;
};
LayoutMetric measure(const std::vector<int> &layout, const std::vector<CfgEdge> &edges);

// ---------- 过程放置：调用图贪心聚簇 ----------

struct CallEdge {
    std::string from, to;
    int weight;   // 调用频度
};

struct ProcPlan {
    std::vector<std::string> order;          // 最终过程布局
    std::vector<std::string> steps;          // 每步合并流水
};

// 鲸书 §8.7.2：边权降序贪心；合并 (x,y) 时 list(y) 接到 list(x)，
// ReSource (y,z)→(x,z)、ReTarget (z,y)→(z,x)，同边并权。
ProcPlan placeProcedures(const std::vector<std::string> &procs,
                         std::vector<CallEdge> edges);

// 调用图度量：边权 × 布局距离 的加权和；相邻（距离 1）边权合计。
struct ProcMetric {
    long weightedDist = 0;
    int adjacentWeight = 0;
};
ProcMetric measureProcs(const std::vector<std::string> &order,
                        const std::vector<CallEdge> &edges);

}  // namespace tip

#endif  // TIP_PLACE_HPP
```

```cpp
// file: src/place.cpp
// file: src/place.cpp
// 第 58 章配套：热路径链构造、链布局、过程贪心聚簇的实现
// （鲸书 §8.6.2 Figure 8.16/8.17 + §8.7.2）。
#include "place.hpp"

#include <algorithm>
#include <map>

namespace tip {

ChainPlan buildHotChains(int nBlocks, const std::vector<CfgEdge> &edges) {
    ChainPlan plan;
    // 链用独立记录（块 → 链下标），绝不让"链内容"与"重定向"互相踩——
    // 教训：引用式 chainOfBlock 在重定向时会覆盖待拼接的尾链，自食其尾。
    struct Chain {
        std::vector<int> blocks;
        int prio;
        bool alive = true;
    };
    std::vector<Chain> chains;
    std::vector<int> idxOf(nBlocks, -1);
    for (int b = 0; b < nBlocks; ++b) {
        chains.push_back({{b}, static_cast<int>(edges.size())});
        idxOf[b] = static_cast<int>(chains.size()) - 1;
    }
    // 边按频度降序（平局按 (from,to) 字典序）扫描
    std::vector<CfgEdge> sorted = edges;
    std::sort(sorted.begin(), sorted.end(), [](const CfgEdge &a, const CfgEdge &b) {
        if (a.freq != b.freq) return a.freq > b.freq;
        if (a.from != b.from) return a.from < b.from;
        return a.to < b.to;
    });
    int P = 0;
    for (const auto &e : sorted) {
        int ia = idxOf[e.from], ib = idxOf[e.to];
        if (ia == ib) continue;
        // x 必是所在链的尾、y 必是所在链的头，才可拼接（鲸书 Figure 8.16）
        if (chains[ia].blocks.back() != e.from || chains[ib].blocks.front() != e.to) continue;
        // 合并：b 链整段接到 a 链尾；成员重指向 a
        chains[ia].blocks.insert(chains[ia].blocks.end(),
                                 chains[ib].blocks.begin(), chains[ib].blocks.end());
        for (int blk : chains[ib].blocks) idxOf[blk] = ia;
        chains[ib].blocks.clear();
        chains[ib].alive = false;
        int newPrio = std::min({chains[ia].prio, chains[ib].prio, P++});
        chains[ia].prio = newPrio;
        plan.steps.push_back("边 B" + std::to_string(e.from) + "→B" + std::to_string(e.to) +
                             "（频度 " + std::to_string(e.freq) + "）：合并成链，优先级 " +
                             std::to_string(newPrio));
    }
    // 收链（活链，代表 = 首块）
    for (const auto &c : chains) {
        if (!c.alive || c.blocks.empty()) continue;
        plan.chains.push_back(c.blocks);
        plan.priority.push_back(c.prio);
    }
    // 布局（鲸书 Figure 8.17）：入口链起步，放完一条链把其出边目标所在链
    // 按优先级（小 = 热）入工作表；循环到空。
    std::vector<bool> placed(nBlocks, false);
    std::vector<std::pair<int, int>> work;   // (优先级, 链下标)
    std::vector<bool> queued(chains.size(), false);
    auto pushChain = [&](int ci) {
        if (queued[ci]) return;
        queued[ci] = true;
        work.push_back({chains[ci].prio, ci});
    };
    pushChain(idxOf[0]);
    while (!work.empty()) {
        std::sort(work.begin(), work.end());
        int ci = work.front().second;
        work.erase(work.begin());
        for (int blk : chains[ci].blocks) {
            if (placed[blk]) continue;
            placed[blk] = true;
            plan.layout.push_back(blk);
        }
        for (int blk : chains[ci].blocks)
            for (const auto &e : edges)
                if (e.from == blk && !placed[e.to]) pushChain(idxOf[e.to]);
    }
    for (int b = 0; b < nBlocks; ++b)
        if (!placed[b]) plan.layout.push_back(b);   // 保险：孤立块收尾
    return plan;
}

LayoutMetric measure(const std::vector<int> &layout, const std::vector<CfgEdge> &edges) {
    std::map<int, int> pos;
    for (size_t i = 0; i < layout.size(); ++i) pos[layout[i]] = static_cast<int>(i);
    LayoutMetric m;
    for (const auto &e : edges) {
        if (pos[e.to] == pos[e.from] + 1) m.fallFreq += e.freq;
        else m.takenFreq += e.freq;
    }
    return m;
}

ProcPlan placeProcedures(const std::vector<std::string> &procs,
                         std::vector<CallEdge> edges) {
    ProcPlan plan;
    // 每个连通分量的代表与有序表
    std::map<std::string, std::string> repOf;
    std::map<std::string, std::vector<std::string>> list;
    for (const auto &p : procs) {
        repOf[p] = p;
        list[p] = {p};
    }
    auto key = [](const CallEdge &e) { return e.from + "\x01" + e.to; };
    for (bool progress = true; progress;) {
        progress = false;
        // 取最大权边（平局字典序）
        auto best = edges.end();
        for (auto it = edges.begin(); it != edges.end(); ++it) {
            if (it->from == it->to) continue;   // 自环不影响放置
            if (best == edges.end() || it->weight > best->weight ||
                (it->weight == best->weight && key(*it) < key(*best)))
                best = it;
        }
        if (best == edges.end()) break;
        std::string x = best->from, y = best->to;
        int w = best->weight;
        edges.erase(best);
        // list(y) 接到 list(x)
        std::string rx = repOf[x], ry = repOf[y];
        if (rx == ry) continue;
        for (const auto &p : list[ry]) repOf[p] = rx;
        list[rx].insert(list[rx].end(), list[ry].begin(), list[ry].end());
        list.erase(ry);
        plan.steps.push_back("边 " + x + "→" + y + "（权 " + std::to_string(w) +
                             "）：list(" + ry + ") 并入 list(" + rx + ")");
        progress = true;
        // ReSource：y 的出边改从 x 出发（同目标并权）
        for (auto it = edges.begin(); it != edges.end();) {
            if (it->from == ry) {
                CallEdge ne{rx, it->to, it->weight};
                auto f = std::find_if(edges.begin(), edges.end(),
                                      [&](const CallEdge &c) { return c.from == ne.from && c.to == ne.to; });
                if (f != edges.end()) {
                    f->weight += ne.weight;
                    it = edges.erase(it);
                } else {
                    *it = ne;
                    ++it;
                }
            } else {
                ++it;
            }
        }
        // ReTarget：指向 y 的边改指 x（同源并权）
        for (auto it = edges.begin(); it != edges.end();) {
            if (it->to == ry) {
                CallEdge ne{it->from, rx, it->weight};
                auto f = std::find_if(edges.begin(), edges.end(),
                                      [&](const CallEdge &c) { return c.from == ne.from && c.to == ne.to; });
                if (f != edges.end()) {
                    f->weight += ne.weight;
                    it = edges.erase(it);
                } else {
                    *it = ne;
                    ++it;
                }
            } else {
                ++it;
            }
        }
    }
    // 汇总：按代表出现序展平各链
    for (const auto &p : procs)
        if (list.count(repOf[p])) {
            for (const auto &q : list[repOf[p]]) plan.order.push_back(q);
            list.erase(repOf[p]);
        }
    return plan;
}

ProcMetric measureProcs(const std::vector<std::string> &order,
                        const std::vector<CallEdge> &edges) {
    std::map<std::string, int> pos;
    for (size_t i = 0; i < order.size(); ++i) pos[order[i]] = static_cast<int>(i);
    ProcMetric m;
    for (const auto &e : edges) {
        int d = std::abs(pos[e.from] - pos[e.to]);
        m.weightedDist += static_cast<long>(d) * e.weight;
        if (d == 1) m.adjacentWeight += e.weight;
    }
    return m;
}

}  // namespace tip
```

### 58.7.2 驱动 main.cpp

链
流水、
双
度量
对照、
聚簇
流水、
四断言。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 58 章驱动（无参运行，走"简单程序"对账协议）：
//   CFG 频度 → 热路径链构造（流水+链表+优先级）→ 链布局 → 顺直/taken 度量
//   → 调用图贪心聚簇（流水+最终序）→ 加权距离度量 → 四断言。
#include "place.hpp"

#include <iostream>
#include <map>

int main() {
    // ---------- 块放置 ----------
    // 六块 CFG：入口频度 10；分支 7/3；B1 再分支 5/2。
    const int nBlocks = 6;
    std::vector<tip::CfgEdge> cfg = {
        {0, 1, 7}, {0, 2, 3}, {1, 3, 5}, {1, 2, 2}, {2, 4, 3}, {3, 5, 5}, {4, 5, 3},
    };
    std::cout << "== 热路径链构造 ==\n";
    tip::ChainPlan plan = tip::buildHotChains(nBlocks, cfg);
    for (const auto &s : plan.steps) std::cout << "  " << s << "\n";
    std::cout << "  链集合:";
    for (size_t i = 0; i < plan.chains.size(); ++i) {
        std::cout << " (";
        for (size_t k = 0; k < plan.chains[i].size(); ++k)
            std::cout << (k ? "," : "") << "B" << plan.chains[i][k];
        std::cout << ")p" << plan.priority[i];
    }
    std::cout << "\n";

    std::cout << "== 布局 ==\n";
    std::cout << "  基线（块号序）:";
    std::vector<int> baseline;
    for (int b = 0; b < nBlocks; ++b) baseline.push_back(b);
    for (int b : baseline) std::cout << " B" << b;
    tip::LayoutMetric mb = tip::measure(baseline, cfg);
    std::cout << "  顺直频度=" << mb.fallFreq << " taken频度=" << mb.takenFreq << "\n";
    std::cout << "  链布局:";
    for (int b : plan.layout) std::cout << " B" << b;
    tip::LayoutMetric ml = tip::measure(plan.layout, cfg);
    std::cout << "  顺直频度=" << ml.fallFreq << " taken频度=" << ml.takenFreq << "\n";

    // ---------- 过程放置 ----------
    // 鲸书 Figure 8.22 的调用图：七个过程、八条加权边。
    // 初始序故意打乱（≈源码声明序，与调用热度无关——真实二进制的常态）。
    std::vector<std::string> procs = {"P0", "P3", "P6", "P1", "P4", "P2", "P5"};
    std::vector<tip::CallEdge> calls = {
        {"P0", "P1", 10}, {"P0", "P5", 2}, {"P1", "P2", 20}, {"P1", "P3", 10},
        {"P1", "P4", 10}, {"P1", "P5", 10}, {"P5", "P4", 52}, {"P5", "P6", 104},
    };
    std::cout << "== 过程贪心聚簇 ==\n";
    tip::ProcPlan pp = tip::placeProcedures(procs, calls);
    for (const auto &s : pp.steps) std::cout << "  " << s << "\n";
    std::cout << "  基线（原序）:";
    for (const auto &p : procs) std::cout << " " << p;
    tip::ProcMetric pb = tip::measureProcs(procs, calls);
    std::cout << "  加权距离=" << pb.weightedDist
              << " 相邻边权=" << pb.adjacentWeight << "\n";
    std::cout << "  聚簇序:";
    for (const auto &p : pp.order) std::cout << " " << p;
    tip::ProcMetric pm = tip::measureProcs(pp.order, calls);
    std::cout << "  加权距离=" << pm.weightedDist
              << " 相邻边权=" << pm.adjacentWeight << "\n";

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = ml.takenFreq < mb.takenFreq && ml.fallFreq > mb.fallFreq;
    // 窗口邻近度（|距离|≤3 记权，近似"同一组缓存行"）：贪心优化的是热簇同居，
    // 不是全图线性距离——线性距离会惩罚冷被调者的合理流放（见正文）。
    auto windowWeight = [&](const std::vector<std::string> &order) {
        std::map<std::string, int> q;
        for (size_t i = 0; i < order.size(); ++i) q[order[i]] = static_cast<int>(i);
        int w = 0;
        for (const auto &e : calls)
            if (std::abs(q[e.from] - q[e.to]) <= 3) w += e.weight;
        return w;
    };
    int winBefore = windowWeight(procs);
    int winAfter = windowWeight(pp.order);
    std::cout << "  窗口邻近度（|距离|≤3 记权）: " << winBefore << " → " << winAfter << "\n";
    bool ok2 = pm.weightedDist < pb.weightedDist && winAfter > winBefore;
    // 最热的调用边 (P5,P6,104) 在聚簇序里相邻
    std::map<std::string, int> pos;
    for (size_t i = 0; i < pp.order.size(); ++i) pos[pp.order[i]] = static_cast<int>(i);
    bool ok3 = pos.count("P5") && pos.count("P6") && std::abs(pos["P5"] - pos["P6"]) == 1;
    bool ok4 = static_cast<int>(plan.layout.size()) == nBlocks &&
               pp.order.size() == procs.size() && pp.order.front() == "P0";
    std::cout << "  链布局 taken 下降且顺直上升: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  窗口邻近度不降: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  最热调用对 (P5,P6) 相邻: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  布局完备且入口打头: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
```

### 58.7.3 期望输出 expected/output.txt

```text
// file: expected/output.txt
== 热路径链构造 ==
  边 B0→B1（频度 7）：合并成链，优先级 0
  边 B1→B3（频度 5）：合并成链，优先级 0
  边 B3→B5（频度 5）：合并成链，优先级 0
  边 B2→B4（频度 3）：合并成链，优先级 3
  链集合: (B0,B1,B3,B5)p0 (B2,B4)p3
== 布局 ==
  基线（块号序）: B0 B1 B2 B3 B4 B5  顺直频度=12 taken频度=16
  链布局: B0 B1 B3 B5 B2 B4  顺直频度=20 taken频度=8
== 过程贪心聚簇 ==
  边 P5→P6（权 104）：list(P6) 并入 list(P5)
  边 P5→P4（权 52）：list(P4) 并入 list(P5)
  边 P1→P2（权 20）：list(P2) 并入 list(P1)
  边 P1→P5（权 20）：list(P5) 并入 list(P1)
  边 P0→P1（权 12）：list(P1) 并入 list(P0)
  边 P0→P3（权 10）：list(P3) 并入 list(P0)
  基线（原序）: P0 P3 P6 P1 P4 P2 P5  加权距离=662 相邻边权=10
  聚簇序: P0 P1 P2 P5 P6 P4 P3  加权距离=354 相邻边权=134
== 对账 ==
  窗口邻近度（|距离|≤3 记权）: 112 → 198
  链布局 taken 下降且顺直上升: yes
  窗口邻近度不降: yes
  最热调用对 (P5,P6) 相邻: yes
  布局完备且入口打头: yes
```

## 58.8 小结与练习

本章把
"代码
的
地理"
讲完：

- 块
  放置：
  频度
  降序
  拼
  热路径
  链，
  尾-
  头
  限制
  保
  顺直，
  优先级
  编码
  上场
  次序；
- 过程
  放置：
  调用
  图
  贪心
  缩点，
  ReSource/
  ReTarget
  维护
  边权，
  终态
  list
  即
  相对
  布局；
- 度量
  要
  对准
  贪心
  的
  目标：
  热簇
  同居
  ≠
  全图
  距离
  最小；
- 频度
  是
  押注：
  静态
  估计
  保守
  覆盖，
  profile
  激进
  命中，
  押错
  双倍
  伤害。

下一章
（59）
把
"保守"
本身
写成
定理：
收集
语义
与
Galois
连接。

练习：

1. 把
   链构造
   的
   平局
   破法
   从
   字典序
   换成
   "深
   优先"（同
   频度
   先
   合
   块号
   小
   的
   尾），
   构造
   一个
   两种
   破法
   产出
   不同
   布局
   的
   CFG，
   比较
   两者
   的
   taken
   频度。
2. 给
   placeProcedures
   加
   **簇
   体积
   上限**
   （合并
   后
   list
   长度
   超
   过
   L 即
   拒绝
   合并）：
   L 取
   多少
   时，
   终序
   从
   一条
   长链
   裂成
   多簇？
   窗口
   邻近度
   如何
   随
   L 变化？
3. 实现
   静态
   频度
   估计：
   回边
   乘
   循环
   上界
   （嵌套
   相乘）、
   其余
   边
   记
   父块
   频度
   的
   均
   分。
   对
   一个
   双层
   循环
   CFG
   与
   真实
   profile
   对比
   排序
   的
   一致率。
4. 块
   布局
   与
   第 16 章
   跟踪
   线性化
   在
   同一
   CFG
   上
   各跑
   一遍：
   什么
   形状
   的
   CFG
   两者
   结果
   相同？
   什么
   形状
   分道
   （提示：
   频度
   均匀
   时
   结构
   贪心
   =
   频度
   贪心）？
5. 把
   加权
   距离
   换成
   **页面
   模型**
   （每
   页
   4 个
   过程，
   跨页
   边
   记
   全
   权、
   同页
   记
   0）：
   聚簇
   序
   的
   页
   miss
   权
   比
   打乱
   基线
   降
   多少？
   簇
   体积
   上限
   与
   页
   大小
   对齐
   时
   有
   什么
   现象？
