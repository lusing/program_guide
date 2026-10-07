# 第 62 章　局部寄存器分配与 SSA 弦图：两个现代视角

## 62.1 问题：k 个寄存器，一屋子的值

第 61 章
把
Chaitin–Briggs
着色
分配器
走完了
一遍：
活跃、
干涉图、
simplify/
select、
溢出。
它
很
通用，
也
很
**悲观**——
一般图
着色
是
NP
完全，
所以
只能
启发式。
本章
从
鲸书
§13.3
与
§13.5.2
取
两个
补充
视角，
把
寄存器
分配
的
地图
补全：

1. **局部
  视角**
  （§13.3）：
  单个
  基本块
  内，
  分配
  是
  **多项式**
  的
  （区间
  图
  着色），
  两个
  经典
  启发式
  ——
  自顶向下
  按频率、
  自底向上
  按最远
  下次使用
  ——
  各有
  胜场；
2. **SSA
  视角**
  （§13.5.2）：
  若
  干涉图
  建在
  **SSA
  名字**
  （而非
  合并
  后的
  活跃
  区间）
  上，
  图
  必是
  **弦图**
  （chordal
  graph），
  着色
  线性
  时间
  **最优**——
  多项式
  的
  桃子
  原来
  挂在
  SSA
  这棵
  树上。

第二个
发现
（2000
年代
由
Hack、
Bouchez
等
人
独立
指出）
是
寄存器
分配
近
二十
年
最重要的
理论
进展
之一，
鲸书
第二版
专门
为它
加了
小节。
本章
自包含
讲清：
为什么
是
弦图、
怎么
找到
完美
消除序、
最优
着色
怎么
直接
读
出来，
以及
它
与
52 章
的
分配器
各自的
领地。

## 62.2 分配与指派：先分地盘再点名

鲸书
先
掰开
两个
词：

- **分配**
  （allocation）：
  决定
  **哪些
  值
  在
  每个
  程序点
  住
  寄存器**——
  全局
  视角
  的
  容量
  规划；
- **指派**
  （assignment）：
  给
  已
  获得资格
  的值
  **指定
  具体
  寄存器
  名字**——
  块内
  的
  排座。

单块、
单一
数据
尺寸、
统一
存储
代价
下，
**最优
分配
多项式
可解**
（把
每个
值的
生存
区间
当
线段，
区间
图
着色）；
几乎
任何
现实
复杂化
——
第二种
寄存器
尺寸、
非统一
访存、
多块
控制流
——
都
让它
跳回
NP
完全。
局部
视角
的
价值
正在于：
**搞清楚
问题
哪一半
是
难的**，
优化
火力
才
对得准。

## 62.3 自顶向下：频率计数，整块独占

第一个
局部分配器
简单
得
像
常识：

1. 线性
  扫一遍，
  数每个
  虚拟
  寄存器
  出现
  的
  次数
  （定义
  与
  使用
  各记
  一票）——
  频率
  计数
  就是
  优先级；
2. 按
  频率
  **降序**
  给
  前 k−F
  个
  名字
  各
  发
  一个
  **整块
  独占**
  的
  寄存器
  （F 是
  "可行
  寄存器
  数"，
  留给
  住内存
  值的
  load/
  store
  代码用）；
3. 住
  内存
  的值：
  每次
  使用
  一次
  load、
  每次
  定义
  一次
  store。

它
的
软肋
也
一眼
可见：
**寄存器
  与
  值
  绑定
  整块**。
一个
值
前半块
高频、
后半块
死透，
它的
寄存器
后半块
就
在
晒太阳——
而
后半块
的热值
只好
住
内存。
鲸书
的
评语：
适合
"使用
分布
均匀"
的块；
分布
偏斜
的块
需要
下一个
分配器。

## 62.4 自底向上：farthest-use 驱逐

第二个
分配器
不预付
任何
东西，
逐指令
现场
决策：

- 使用
  内存值：
  找
  空寄存器
  装入
  （1 次
  load）；
- 寄存器
  满：
  驱逐
  **下次
  使用
  最远**
  的
  驻留者
  （没有
  下次
  使用的
  最先
  走），
  脏值
  驱逐
  先
  store；
- 定义：
  直接
  写进
  寄存器
  （标记
  脏，
  不产生
  读）。

"驱逐
最远
者"
正是
Belady
离线
页面
替换
算法
的
寄存器
版——
而
它的
血缘
比
页式
存储
更老：
鲸书
章注
考证
这个
算法
由
Best
在
1950
年代
FORTRAN
编译器
里
发明，
后来
被
反复
重新
发现。

期望
输出的
对照
精心
布置：
a 在
前四条
高频、
之后
死透。
频率
计数
把
a 排
进
前三
（访存
12 次）；
farthest-use
在
压力
出现
时
立刻
把
无
下次
使用的
a 请
出去
（访存
9 次）
——
**分布
偏斜
的块，
现场
决策
赢
整块
独占**。
两者
复杂度
都是
O(块长)，
实际
编译器
常把
自底向上
版
当
快速
路径
（如
线性扫描
的
块内
内核）。

## 62.5 SSA 干涉图是弦图：桃子挂在哪

现在
进入
本章
主菜。
52 章
的
干涉图
建在
**活跃
区间**
上——
同一
变量
的
多次
定义
合并
成
长命
节点，
图
一般
不是
弦图。
但
若
直接
建在
**SSA
名字**
上：

> **定理**
> （Hack
> 等）：
> SSA
> 干涉图
> 中，
> 每个
> 长度
> ≥4 的
> 环
> 都有
> 弦
> ——
> 图
> 是
> 弦图。

直觉
（一页
纸版）：
SSA
里
两个
名字
a、b
干涉，
必有一点
两者
同时
活跃；
SSA
的
use
必被
def
支配
（第 41 章），
于是
**干涉
的
一方
定义
支配
另一方
定义**。
把
节点
按
"定义
支配
关系"
的
**逆
先序**
排（叶
先、
根后），
每个
节点
的
靠后
邻居
恰是
它
定义点
的
同批
活跃者
——
两两
也在
那里
活跃，
故
两两
相邻
——
成团。
这个
序
就是
**完美
消除序**
（PEO）。

期望
输出
把
这个
理论
做成了
实验：
手工
写出
支配
树
先序，
机器
裁决
——
**正序
不是
PEO，
逆序
是**。
理论
方向
由
实验
钉死，
不靠
背书。

弦图
的
桃子：

- **PEO
  存在
  ⇒ 贪心
  着色
  最优**：
  依
  PEO
  给
  每个
  节点
  挑
  邻居
  未占
  的
  最小
  色，
  用色数
  恰等于
  团数
  ω——
  不需要
  simplify/
  select
  的
  压栈
  回放，
  更
  没有
  溢出
  试探；
- **识别
  也是
  线性**：
  最大势
  搜索
  （MCS，
  Tarjan）——
  反复
  取
  "与
  已编号
  集
  相邻
  最多"
  的
  节点
  编号，
  编号
  的
  **逆序**
  即
  PEO；
  再
  花一遍
  校验
  （每个
  节点
  的
  靠后
  邻居
  成团），
  通过
  ⇔ 图
  是
  弦图。

我们的
示例
CFG
（入口
三常量、
分支
两臂
各算
d/e、
汇合
三 φ
收尾）
产出
14 节点
47 边；
MCS
给出
PEO，
校验
通过，
弦图
着色
**色数
9
== 团数
9**；
Briggs
在
同一图
上
（k=10）
也
用
9 色——
**弦图
≤
Briggs**
永远
成立
（最优
对
启发式），
小图
上
常打平，
差距
在
大图
与
坏
运气
上
显现。

## 62.6 SSA 分配器的账：便宜与代价

便宜
拿到了，
代价
也要
记在
明面上
（鲸书
§13.5.2
的
冷静
账）：

- **拆
  SSA
  的
  代价**：
  分配
  完
  要
  退出
  SSA，
  φ 变
  并行
  copy——
  可能
  插入
  额外
  寄存器
  需求
  （断
  copy
  环
  要
  一个
  临时；
  第 42 章
  讲过
  怎么断）。
  最优
  色数
  不等于
  最终
  物理寄存器
  数；
- **合并
  的
  边界**：
  φ 与
  实参
  的
  copy
  想
  消掉
  就得
  合并
  ——
  但
  基于干涉图
  的
  合并
  （52 章
  Briggs
  准则）
  会
  **破坏
  弦性**。
  SSA
  分配器
  得用
  图外
  的
  合并
  算法
  （依
  支配
  关系
  判定）；
- **溢出
  仍然
  NP**：
  弦图
  只
  救
  着色，
  溢出
  **选择**
  （挑谁、
  放哪、
  何处
  重载）
  依旧
  难。
  好消息：
  SSA
  名字
  被
  φ 切短，
  溢出
  可以
  只
  波及
  小
  区间
  （循环
  头、
  循环
  出口
  天然
  是
  切点）。

工程
综述
（鲸书
原话
的
转述）：
SSA
分配器
与
传统
分配器
的
高下
难有
定论——
着色
更优
不
代表
最终
代码
更优，
溢出
策略
与
copy
  处理
  的
  权重
  往往
  更大。
但
"SSA
干涉图
是
弦图"
这个
事实
本身，
已经
把
52 章
那套
启发式
的
**悲观
下界**
撕开
了一个
多项式
的
口子。

## 62.7 期望输出解读与对账

四段
输出、
五条
断言：

1. **局部
  分配**
  （k=3）：
  频率
  计数
  驻留
  {a,t2,b}
  访存
  12；
  farthest-use
  访存
  9——
  前热
  后死
  的 a
  在
  现场决策
  里
  被
  及早
  驱逐；
2. **干涉
  图**：
  14 节点
  47 边
  全打印
  ——
  肉眼
  可查
  a0/b0/c0
  三角、
  φ 目的
  d2/e2/h0
  与
  两臂
  值的
  交叉
  边；
3. **MCS/PEO**：
  MCS
  编号序
  与
  其
  逆序
  （PEO）
  全
  打印；
  **支配
  树
  先序
  正序
  非
  PEO、
  逆序
  是**
  ——
  定理
  方向
  的
  机器
  裁决；
4. **着色**：
  弦图
  色数
  9 ==
  团数
  9
  （最优性）；
  Briggs
  （k=10）
  用
  9；
  两份
  着色
  均过
  相邻
  异色
  校验。

五断言：
MCS
逆序
过
PEO
校验（一）、
色数
==
团数（二）、
两份
着色
合法（三）、
弦图
≤
Briggs（四）、
farthest-use
≤
频率
计数（五）。

## 62.8 工程注意点

- **φ 与
  实参
  不连边**：
  我们
  的
  buildInterference
  显式
  跳过
  φ 目的
  与
  自身
  实参
  的边
  ——它们
  沿
  各自
  前驱
  边
  传递
  同一
  值，
  天然
  可共
  寄存器。
  这
  一处
  宽松
  是
  SSA
  图
  比区间
  图
  优雅
  的
  直接
  来源。
- **活跃
  分析
  的
  φ 口径**：
  φ 实参
  算
  **对应
  前驱块
  末尾**
  的
  use——
  端点
  挂
  边
  上
  而非
  块内，
  这是
  SSA
  活跃
  与
  普通
  活跃
  （第 32 章）
  唯一的
  形状
  差别。
- **MCS
  的
  平局**：
  我们的
  实现
  以
  名字
  字典序
  破
  平局
  （确定性）；
  不同
  破法
  得到
  不同
  但
  同样
  合法
  的
  PEO。
- **溢出
  后的
  图
  不再
  弦**：
  一旦
  溢出
  改写
  （插
  load/store
  造新
  名字），
  需要
  重建
  图——
  此时
  弦性
  无
  保证，
  得
  回到
  52 章
  的
  启发式
  或
  再跑
  一轮
  SSA
  化。
- **从
  局部
  到
  全局**：
  鲸书
  §13.3.3
  讲
  局部
  分配器
  如何
  当
  全局
  的
  基线
  （每块
  独立
  分配、
  跨块
  值
  在
  块界
  存取）——
  线性扫描
  分配器
  （JIT
  的
  主力）
  本质
  就是
  这条
  路线
  的
  区间
  推广。

## 62.9 本章配套文件

本示例
无 ANTLR——
手造
CFG
与
直线块
自包含，
走"简单
程序"
对账
协议。

### 62.9.1 alloc.hpp 与 alloc.cpp

两个
局部分配器、
SSA
活跃
与
干涉、
MCS/PEO、
弦图
与
Briggs
着色。

```cpp
// file: src/alloc.hpp
// file: src/alloc.hpp
// 第 62 章配套：局部寄存器分配与 SSA 弦图着色（鲸书 §13.3 + §13.5.2）。
#ifndef TIP_ALLOC_HPP
#define TIP_ALLOC_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 局部分配的输入：一个直线块 ----------
struct LocalInst {
    std::string dst;                 // 空 = 纯使用（如 output）
    std::vector<std::string> uses;
};

// 自顶向下（频率计数）：整块独占寄存器，排不上的住内存。
// 返回访存次数（内存值的每次使用 = 1 load，每次定义 = 1 store）。
struct LocalReport {
    int memoryTraffic = 0;
    std::vector<std::string> resident;   // 住上寄存器的名字（按优先序）
};
LocalReport topDownLocal(const std::vector<LocalInst> &block, int k);

// 自底向上（farthest-use 驱逐）：逐指令现场装/卸，驱逐"下次使用最远"者。
// 脏值驱逐先 store；内存值使用先 load。
LocalReport bottomUpLocal(const std::vector<LocalInst> &block, int k);

// ---------- SSA 干涉图与着色 ----------

using EdgeSet = std::set<std::pair<std::string, std::string>>;

struct Graph {
    std::set<std::string> nodes;
    EdgeSet edges;                                   // 无向，端点按字典序
    std::map<std::string, std::set<std::string>> adj;
    void addEdge(const std::string &x, const std::string &y);
};

// SSA 程序（块 + φ）→ 干涉图：def 与"定义点之后活跃"者连边；
// φ 目的不与自己的实参连边（它们天然可以共享寄存器）。
// 输入用"指令即结构"的极简形状：phiArgs 非空为 φ。
struct SsaInstLite {
    std::string dst;
    std::vector<std::string> uses;      // 非定义用途（φ 则为实参表）
    bool isPhi = false;
};
struct SsaBlockLite {
    std::vector<SsaInstLite> body;      // φ 在最前
    std::vector<int> succs;
    std::vector<int> preds;             // 与 φ 实参次序一致
};
// 活跃分析（后向到不动点；φ 实参算作对应前驱块末尾的 use）
std::vector<std::set<std::string>> ssaLiveness(const std::vector<SsaBlockLite> &blocks);

Graph buildInterference(const std::vector<SsaBlockLite> &blocks);

// 最大势搜索（MCS）：弦图线性识别 + 给出完美消除序（PEO）。
// 返回节点序列（按编号升序；逆序即 PEO）。
std::vector<std::string> mcsOrder(const Graph &g);

// PEO 合法性校验：序中每个点的"靠后邻居"成团。
bool isPerfectElimination(const Graph &g, const std::vector<std::string> &order);

// 依 PEO 贪心着色 = 弦图最优着色（色数 = 团数）。
std::map<std::string, int> chordalColor(const Graph &g, const std::vector<std::string> &peo);

// PEO 口径的最大团数：max_v (1 + |靠后邻居|)
int peoCliqueNumber(const Graph &g, const std::vector<std::string> &peo);

// Chaitin–Briggs：simplify（度<k 压栈）+ select（后进先出挑色）。
// 返回空 map 表示 k 太小发生溢出。
std::map<std::string, int> briggsColor(const Graph &g, int k);

// 着色合法性：相邻异色且颜色在 [0,k)
bool coloringValid(const Graph &g, const std::map<std::string, int> &color, int k);

}  // namespace tip

#endif  // TIP_ALLOC_HPP
```

```cpp
// file: src/alloc.cpp
// file: src/alloc.cpp
// 第 62 章配套：两个局部分配器、SSA 干涉图、MCS/PEO、弦图与 Briggs 着色
// （鲸书 §13.3 + §13.5.2）。
#include "alloc.hpp"

#include <algorithm>
#include <cstdlib>

namespace tip {

// ---------- 局部分配 ----------

namespace {

// 块内 next-use：position i 处名字 v 的下一次使用下标（无则 -1）
std::map<std::pair<int, std::string>, int> nextUseOf(const std::vector<LocalInst> &block) {
    std::map<std::pair<int, std::string>, int> nu;
    std::map<std::string, int> pending;
    for (int i = static_cast<int>(block.size()) - 1; i >= 0; --i) {
        for (const auto &v : block[i].uses)
            nu[{i, v}] = pending.count(v) ? pending[v] : -1;
        if (!block[i].dst.empty()) pending[block[i].dst] = i;
        for (const auto &v : block[i].uses) pending[v] = i;   // 使用点也是"最近定义起点"
    }
    return nu;
}

}  // namespace

LocalReport topDownLocal(const std::vector<LocalInst> &block, int k) {
    LocalReport r;
    // 频率计数：一次定义 + 每次使用各记一票
    std::map<std::string, int> freq;
    for (const auto &inst : block) {
        if (!inst.dst.empty()) ++freq[inst.dst];
        for (const auto &v : inst.uses) ++freq[v];
    }
    std::vector<std::pair<int, std::string>> order;
    for (const auto &[v, c] : freq) order.push_back({c, v});
    std::sort(order.begin(), order.end(),
              [](auto &x, auto &y) { return x.first > y.first || (x.first == y.first && x.second < y.second); });
    std::set<std::string> resident;
    for (size_t i = 0; i < order.size() && static_cast<int>(i) < k; ++i) {
        resident.insert(order[i].second);
        r.resident.push_back(order[i].second);
    }
    // 访存账：内存值的每次使用 1 load、每次定义 1 store
    for (const auto &inst : block) {
        if (!inst.dst.empty() && !resident.count(inst.dst)) ++r.memoryTraffic;
        for (const auto &v : inst.uses)
            if (!resident.count(v)) ++r.memoryTraffic;
    }
    return r;
}

LocalReport bottomUpLocal(const std::vector<LocalInst> &block, int k) {
    LocalReport r;
    auto nu = nextUseOf(block);
    std::map<std::string, int> home;        // 名字 → 寄存器（-1 = 在内存）
    std::map<int, std::string> owner;       // 寄存器 → 名字
    std::map<int, bool> dirty;
    auto evict = [&](int reg) {             // 驱逐：脏则 store
        auto it = owner.find(reg);
        if (it == owner.end()) return;
        if (dirty[reg]) ++r.memoryTraffic;
        home[it->second] = -1;
        owner.erase(it);
        dirty[reg] = false;
    };
    auto ensure = [&](const std::string &v, int at, bool fromMemory) {
        if (home.count(v) && home[v] >= 0) return;
        int reg = -1;
        for (int i = 0; i < k; ++i)
            if (!owner.count(i)) { reg = i; break; }
        if (reg < 0) {
            // 驱逐下次使用最远的驻留者（Belady 同型；无下次使用者最先走）
            int bestReg = 0, bestDist = -2;
            for (const auto &[rg, name] : owner) {
                auto f = nu.find({at, name});
                int dist = (f == nu.end() || f->second < 0) ? 1 << 30 : f->second;
                if (dist > bestDist) { bestDist = dist; bestReg = rg; }
            }
            evict(bestReg);
            reg = bestReg;
        }
        if (fromMemory) ++r.memoryTraffic;  // 内存值装进寄存器才算 1 load；
        home[v] = reg;                      // 定义直接写寄存器，不产生访存
        owner[reg] = v;
        dirty[reg] = false;
    };
    for (int i = 0; i < static_cast<int>(block.size()); ++i) {
        const auto &inst = block[i];
        for (const auto &v : inst.uses) ensure(v, i, true);
        if (!inst.dst.empty()) {
            ensure(inst.dst, i, false);     // 定义占寄存器但不读内存
            dirty[home[inst.dst]] = true;
        }
    }
    for (const auto &[rg, name] : owner) r.resident.push_back(name);
    std::sort(r.resident.begin(), r.resident.end());
    return r;
}

// ---------- SSA 活跃与干涉 ----------

std::vector<std::set<std::string>> ssaLiveness(const std::vector<SsaBlockLite> &blocks) {
    size_t n = blocks.size();
    std::vector<std::set<std::string>> in(n), out(n);
    auto phiArgsFor = [&](int s, int pred) -> std::vector<std::string> {
        std::vector<std::string> args;
        for (const auto &inst : blocks[s].body) {
            if (!inst.isPhi) continue;
            size_t pos = 0;
            for (int p : blocks[s].preds) {
                if (p == pred) break;
                ++pos;
            }
            if (pos < inst.uses.size()) args.push_back(inst.uses[pos]);
        }
        return args;
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            std::set<std::string> o;
            for (int s : blocks[b].succs) {
                o.insert(in[s].begin(), in[s].end());
                for (const auto &a : phiArgsFor(s, static_cast<int>(b))) o.insert(a);
            }
            std::set<std::string> i = o;
            for (auto it = blocks[b].body.rbegin(); it != blocks[b].body.rend(); ++it) {
                if (!it->dst.empty()) i.erase(it->dst);
                for (const auto &v : it->uses) i.insert(v);
            }
            if (i != in[b] || o != out[b]) { in[b] = i; out[b] = o; ch = true; }
        }
    }
    return out;
}

void Graph::addEdge(const std::string &x, const std::string &y) {
    if (x == y || x.empty() || y.empty()) return;
    nodes.insert(x);
    nodes.insert(y);
    edges.insert({std::min(x, y), std::max(x, y)});
    adj[x].insert(y);
    adj[y].insert(x);
}

Graph buildInterference(const std::vector<SsaBlockLite> &blocks) {
    Graph g;
    auto out = ssaLiveness(blocks);
    for (size_t b = 0; b < blocks.size(); ++b) {
        // 块内逐点活跃：从 liveOut 倒推
        std::set<std::string> live = out[b];
        for (auto it = blocks[b].body.rbegin(); it != blocks[b].body.rend(); ++it) {
            // def 与"定义点之后仍活跃"者连边；φ 目的不与自己的实参连边
            if (!it->dst.empty()) {
                for (const auto &v : live) {
                    if (it->isPhi) {
                        bool isArg = false;
                        for (const auto &a : it->uses) if (a == v) isArg = true;
                        if (isArg) continue;   // φ 与实参可共寄存器
                    }
                    g.addEdge(it->dst, v);
                }
                live.erase(it->dst);
            }
            for (const auto &v : it->uses) live.insert(v);
        }
    }
    for (const auto &b : blocks)
        for (const auto &inst : b.body) {
            if (!inst.dst.empty()) g.nodes.insert(inst.dst);
            for (const auto &v : inst.uses) g.nodes.insert(v);
        }
    return g;
}

// ---------- MCS / PEO / 着色 ----------

std::vector<std::string> mcsOrder(const Graph &g) {
    // 最大势搜索：反复取"与已编号集相邻最多"的节点编号；逆序为 PEO。
    std::map<std::string, int> weight;
    std::set<std::string> numbered;
    std::vector<std::string> order;
    for (size_t n = 0; n < g.nodes.size(); ++n) {
        std::string best;
        int bestW = -1;
        for (const auto &v : g.nodes) {
            if (numbered.count(v)) continue;
            if (weight[v] > bestW || (weight[v] == bestW && (best.empty() || v < best))) {
                bestW = weight[v];
                best = v;
            }
        }
        numbered.insert(best);
        order.push_back(best);
        for (const auto &u : g.adj.at(best)) ++weight[u];
    }
    return order;   // order 的逆序是 PEO
}

bool isPerfectElimination(const Graph &g, const std::vector<std::string> &order) {
    // order 即消除序：每个点的"靠后邻居"必须成团
    std::map<std::string, int> pos;
    for (size_t i = 0; i < order.size(); ++i) pos[order[i]] = static_cast<int>(i);
    for (size_t i = 0; i < order.size(); ++i) {
        std::vector<std::string> later;
        for (const auto &u : g.adj.at(order[i]))
            if (pos[u] > static_cast<int>(i)) later.push_back(u);
        for (size_t x = 0; x < later.size(); ++x)
            for (size_t y = x + 1; y < later.size(); ++y)
                if (!g.adj.at(later[x]).count(later[y])) return false;
    }
    return true;
}

std::map<std::string, int> chordalColor(const Graph &g, const std::vector<std::string> &peo) {
    std::map<std::string, int> color;
    for (const auto &v : peo) {
        std::set<int> used;
        for (const auto &u : g.adj.at(v)) {
            auto it = color.find(u);
            if (it != color.end()) used.insert(it->second);
        }
        int c = 0;
        while (used.count(c)) ++c;
        color[v] = c;
    }
    return color;
}

int peoCliqueNumber(const Graph &g, const std::vector<std::string> &peo) {
    std::map<std::string, int> pos;
    for (size_t i = 0; i < peo.size(); ++i) pos[peo[i]] = static_cast<int>(i);
    int omega = 1;
    for (size_t i = 0; i < peo.size(); ++i) {
        int later = 0;
        for (const auto &u : g.adj.at(peo[i]))
            if (pos[u] > static_cast<int>(i)) ++later;
        omega = std::max(omega, later + 1);
    }
    return omega;
}

std::map<std::string, int> briggsColor(const Graph &g, int k) {
    std::map<std::string, std::set<std::string>> adj;
    for (const auto &v : g.nodes) adj[v] = g.adj.count(v) ? g.adj.at(v) : std::set<std::string>{};
    std::vector<std::string> stack;
    std::set<std::string> remaining = g.nodes;
    while (!remaining.empty()) {
        std::string pick;
        for (const auto &v : remaining)
            if (static_cast<int>(adj[v].size()) < k) { pick = v; break; }
        if (pick.empty()) return {};   // 需要溢出：本示例不接受
        for (const auto &u : adj[pick]) adj[u].erase(pick);
        adj.erase(pick);
        stack.push_back(pick);
        remaining.erase(pick);
    }
    std::map<std::string, int> color;
    for (auto it = stack.rbegin(); it != stack.rend(); ++it) {
        std::set<int> used;
        for (const auto &u : g.adj.at(*it)) {
            auto cit = color.find(u);
            if (cit != color.end()) used.insert(cit->second);
        }
        int c = 0;
        while (c < k && used.count(c)) ++c;
        if (c >= k) return {};
        color[*it] = c;
    }
    return color;
}

bool coloringValid(const Graph &g, const std::map<std::string, int> &color, int k) {
    for (const auto &v : g.nodes) {
        auto it = color.find(v);
        if (it == color.end() || it->second < 0 || it->second >= k) return false;
    }
    for (const auto &e : g.edges) {
        auto a = color.find(e.first), b = color.find(e.second);
        if (a == color.end() || b == color.end() || a->second == b->second) return false;
    }
    return true;
}

}  // namespace tip
```

### 62.9.2 驱动 main.cpp

直线块
双分配器、
手造
SSA
CFG、
理论
方向
裁决、
五断言。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 62 章驱动（无参运行，走"简单程序"对账协议）：
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
```

### 62.9.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 局部分配（k=3）==
  自顶向下（频率计数）: 驻留 {a,t2,b} 访存=12
  自底向上（farthest-use）: 访存=9
== SSA 干涉图 ==
  节点 14 个，边 47 条:
    a0 — b0
    a0 — c0
    a0 — d0
    a0 — d1
    a0 — e0
    a0 — e1
    a0 — f0
    a0 — g0
    b0 — c0
    b0 — d0
    b0 — d1
    b0 — e0
    b0 — e1
    b0 — f0
    b0 — g0
    c0 — d0
    c0 — d1
    c0 — e0
    c0 — e1
    c0 — f0
    c0 — g0
    d0 — d1
    d0 — e0
    d0 — e1
    d0 — f0
    d0 — g0
    d1 — e0
    d1 — e1
    d1 — f0
    d1 — g0
    d2 — e0
    d2 — e1
    d2 — e2
    d2 — f0
    d2 — g0
    d2 — h0
    e0 — e1
    e0 — f0
    e0 — g0
    e1 — f0
    e1 — g0
    e2 — f0
    e2 — g0
    e2 — h0
    f0 — g0
    h0 — h1
    h1 — h2
== MCS 与完美消除序 ==
  MCS 序（编号序）: a0 b0 c0 d0 d1 e0 e1 f0 g0 d2 e2 h0 h1 h2
  PEO（MCS 逆序）: h2 h1 h0 e2 d2 g0 f0 e1 e0 d1 d0 c0 b0 a0
== 着色对照 ==
  弦图（PEO 贪心）: 色数=9，团数=9
  Chaitin–Briggs（k=10）: 用色=9
== 支配树先序核验 ==
  支配树先序是 PEO: no
  支配树先序的逆是 PEO: yes
== 对账 ==
  MCS 逆序通过 PEO 校验（图是弦图）: yes
  弦图色数 == 团数（最优性）: yes
  两份着色相邻异色且域合法: yes
  弦图色数 ≤ Briggs 用色: yes
  farthest-use 访存 ≤ 频率计数: yes
```

## 62.10 小结与练习

本章给
寄存器
分配
补了
两个
视角：

- 局部
  分配
  多项式
  可解：
  频率
  计数
  整块
  独占
  简单
  但
  木讷，
  farthest-use
  现场
  驱逐
  是
  Belady
  在
  寄存器
  里的
  还魂；
- SSA
  干涉图
  是
  弦图：
  PEO
  =
  支配
  树
  先序
  的
  **逆**
  （实验
  裁决），
  MCS
  线性
  找
  PEO、
  贪心
  即
  最优
  （色数
  =
  团数）；
- 桃子
  有
  价：
  拆
  SSA
  造
  copy、
  合并
  破坏
  弦性、
  溢出
  依旧
  NP——
  最优
  着色
  不
  直接
  等于
  最优
  代码。

下一章
（54）
离开
寄存器，
看指令
怎么
从
表达式
树上
切
下来。

练习：

1. 给
   topDownLocal
   实现
   鲸书
   的
   **F 寄存器**
   预留
   （k−F 个
   驻留 +
   F 个
   内存
   代码
   专用），
   F 从
   0 扫
   到
   k：
   最优
   F 与
   块的
   内存
   值
   使用
   密度
   有
   什么
   关系？
2. 把
   bottomUpLocal
   的
   驱逐
   策略
   换成
   LRU
   （驱逐
   最久
   未用），
   在
   demoBlock
   与
   随机
   块上
   与
   farthest-use
   对比——
   Belady
   的
   优势
   何时
   显现？
3. 构造
   一个
   **非
   SSA**
   干涉图
   含
   无弦
   四边形的
   程序
   （同一
   变量
   两个
   不相交
   活跃
   段），
   验证
   MCS
   校验
   失败——
   再
   对
   其
   SSA
   版
   验证
   通过。
   弦性
   从
   哪个
   构造
   细节
   来？
4. Briggs
   在
   什么
   图上
   会
   比
   弦图
   着色
   多
   用
   色？
   构造
   或
   随机
   搜索
   一个
   14 节点
   的
   弦图
   使
   Briggs
   用
   ω+1 色
   （提示：
   select
   的
   出栈
   序
   是
   度
   序
   而非
   PEO）。
5. 把
   φ 与
   实参
   的
   免干涉
   边
   改成
   "合并
   候选"
   标记，
   在
   弦图
   着色
   后
   做图外
   合并
   （同色
   才
   合并）：
   对照
   52 章
   的
   Briggs
   合并
   准则，
   数一数
   各自
   消掉
   的
   copy 数。

---

上一章：[61 寄存器分配](61-regalloc.md) · 下一章：[63 指令选择与窥孔](63-isel-peephole.md)
