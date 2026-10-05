# 第 65 章　分支预测与预取：替机器赌未来

## 65.1 问题：等待是并行性的天敌

流水线
（第 64 章）
把指令
错开叠放，
一个周期
启动多条；
但两类
"停下来等"
的事件
能把它
打回原形：

- **分支**：
  条件没算完
  之前，
  不知道下一条
  取谁——
  流水线
  要么排空
  （冒泡）、
  要么**猜**；
- **访存 miss**：
  数据在
  内存里，
  几百个
  周期——
  要么干等、
  要么**提前要**。

现代机器的
答案：
**猜**（分支
预测器）
与**提前要**
（预取）。
两者都靠
编译器与
硬件的
配合：
编译器
把循环
摆得
可猜
（14 章
跟踪、
37 章
循环形状）、
把访问
排得
可预取
（52 章
局部性）；
本讲把
这两台
"未来机器"
拆开。
材料取自
虎书
§20.3 与
§21.2–21.3，
自包含展开。

## 65.2 二位饱和预测器：连错两次才翻脸

**分支预测器**
的基本件是
**二位饱和
计数器**
（2-bit
saturating
counter）：

```
状态 0 ──taken──> 1 ──taken──> 2 ──taken──> 3
  ↑                                        │
  └─────not taken──── 2 ←──not taken──────┘
  （0 和 3 饱和：不再上/下）

预测：状态 ≥ 2 ⇒ taken；否则 not taken
```

四个状态
两档预测：
0、1 猜不跳，
2、3 猜跳。
**关键性质**：
预测方向
翻转需要
**连续两次**
反向证据
（从 2 到 0
或 3 到 1）
——单次
意外不翻脸。

对**循环**
（回边
taken×N +
出口
not-taken×1）：

- 第一次
  迭代后
  计数器
  升到
  taken 区，
  之后
  每圈回边
  全中；
- 出口
  错一次、
  计数器
  只降一档，
  下个循环
  （若在
    同一现场）
  继续
  正确猜跳。

期望输出的
状态序列
（5 次×3 轮）：

```
1 2 3 3 2 | 3 3 3 3 2 | 3 3 3 3 2
```

第一次
事件后
爬坡
（0→1→2→3），
出口
降一档
（3→2），
下轮
立即恢复——
**稳态
命中率
= 回边
全中 +
出口全错**。
对 N 次
迭代：
(N−2)/N
——N 越大
越接近
100%。

对**不可预测
分支**
（数据驱动的
if），
二位机
退化为
50%
（0101
交替让
计数器
在 0/1
或 1/0
间震荡，
永远猜
not）：

```
状态序列: 1 0 1 0 1 0 1 0 1 0     命中率 50%
```

期望输出的
两组对照
（66% vs
50%）
就是
"循环好猜、
分支难猜"
的机器
证词。

**预测器的
进化树**
（正文导览、
不实现）：
二位机
按分支
**地址**
索引——
多条分支
共享一个
计数器会
互相污染；
gshare
（地址 ⊕
历史）
把"最近
几次方向"
编进索引；
锦标赛
预测器
（多算法
竞赛、
动态择优）
与 TAGE
是当代
主力，
命中率
97%+。
方向
不变：
**过去
预测
未来**，
循环是
最大的
红利。

## 65.3 静态启发式：编译期的赌注

硬件预测器
要运行时
历史；
**编译期**
也能下注——
**静态预测
启发式**
（虎书
20.3）：

> **后向
> 跳转预测
> taken，
> 前向
> 预测
> not-taken。**

理由：
后向边
≈ 循环
回边
（14 章
的 DFS
边分类
正是
这么认
回边的）
——循环
执行
多次，
回边
大概率
跳；
前向边
≈ if 的
then 臂
或
错误处理
——
统计上
not-taken
（顺序流）
略优。

期望输出：

```
循环: hits=12 misses=3（回边全对，出口全错）
分支: hits=5 misses=5（五五开）
```

对循环
回边，
静态
启发式
与二位机
**打平**
（都是
回边全中、
出口全错）
——编译期
一条
"后向
taken"
就能拿到
硬件预测器
的循环
红利；
对不可
预测分支
两者
一样
无能。
静态
启发式
的真正
用户是
**编译器
自己**：
- 循环
  优化
  让热路径
  顺直
  （14 章
    消跳转）
  本质是
  在给
  "预测
    not-taken"
  铺路；
- 代码
  布局
  （基本块
    排序）
  把
  "预测对
    的路径"
  放在
  顺直
  位置。

**profile
引导**
（PGO）
是中间态：
跑一遍
采分支
频度、
按频度
布局——
静态
启发式
+ 一次
实测，
命中率
逼近
二位机
且无需
硬件。

## 65.4 预取：把延迟藏进未来

**预取**
（prefetch）：
在数据
**用到
之前**
发起
取数，
让 miss
延迟与
计算
**重叠**。

对循环
（虎书
21.3 的
软件
预取）：

```
for (i = 0; i < n; i++)
    prefetch(A[i + d]);      ← 提前 d 个迭代要 A[i+d]
    use(A[i]);               ← 用 A[i]
```

**距离 d
的公式**：

> d =
> ⌈T_latency
>  / T_cycle⌉

- T_cycle：
  每迭代
  用时
  （周期）——
  预取
  发起后
  有 d 次
  迭代的
  计算
  时间
  可供
  等待；
- T_latency：
  一次
  取数
  延迟
  ——预取
  要在
  **用时
  之前**
  这么多
  周期
  发出。

d 太小：
数据
未到、
照样停
（late）；
d 太大：
占缓存
（把
  还没轮到
  的行
  提前踢
  进来，
  挤掉
  在用的）。
恰好的
d 让
"到货
时刻
≤ 用数
时刻"
**逐迭代
成立**。

期望输出的
推演表
（T_cycle=2、
T_latency=10
⇒ d=5）：

```
用数@迭代0（t=0）  预取@迭代-5（t=-10） 到货 t=0  ok
用数@迭代5（t=10） 预取@迭代0 （t=0）   到货 t=10 ok
```

负迭代号
= **开场
预取**
（prologue）：
前 d 个
迭代等
不及
"上个
迭代"
发起——
循环前
一次性
预取
A[0..d-1]，
循环体
内预取
A[i+d]。

第二组
（T_cycle=5）
给出
d=2：
**慢循环**
每迭代
算得久，
预取
从容——
同一个
延迟
摊得开。
这个
观察的
推论：
**展开
循环
（38 章）
会增大
T_cycle
（每迭代
  干更多
  事），
从而
减小
d、
减少
在途
预取
的缓存
占用**——
展开与
预取的
又一层
配合。

硬件
**预取器**
（streaming/
stride）
自动识别
等差
访问
（52 章
的仿射
访问！）
并预取——
软件
预取的
显式
指令
（x86
prefetcht0）
用于
硬件
猜不出的
模式
（间接
访问、
跨步
不规则）。

## 65.5 对齐：缓存行的几何学

**缓存行
对齐**
（cache
alignment，
虎书
21.2）：
数据
布局与
缓存
几何的
配合。

**冲突
场景**
（直接
映射
缓存）：
两个热
数组
A、B
的行
映射到
**相同的槽**
——基址
差恰为
缓存
容量
的整数倍：

```
A 基址 0：  行 0..3  → 槽 0..3
B 基址 32（= 8 行 × 4 单元，恰一个容量）：行 8..11 → 槽 0..3   ← 同槽！
```

交替访问
`A[i], B[i]`
（模板计算
风格）：
每对
访问
互相
踢出——
**每次
都 miss**
（32 次
miss /
16 对）。

**解法**：
把 B
错开
**一个
缓存行**
（pad=4
单元，
基址 36）：
B 的行
映射
移位，
与 A
不再
同槽——
冲突
消失，
只剩
冷启动
miss
（8 次）。

期望输出：

```
B 基址 32（同相位）: misses=32
B 基址 36（pad=4 错开）: misses=8
```

**四倍
差距，
一行
之差**。
工程上：

- 数组
  基址
  按缓存行
  对齐
  （分配器
    常默认）；
- 结构体
  填充
  （padding）
  把
  热字段
  隔开
  消除
  **伪共享**
  （两个核
    写同一线程
    的不同
    变量、
    缓存
    一致性
    协议
    互相
    失效）；
- 52 章
  的分块
  是同一
  几何学
  的
  循环级
  应用。

## 65.6 期望输出解读与对账

五段输出、
四条断言：

1. **trace**：
  循环
  15 事件
  （5 次×3 轮、
  回边 12 +
  出口 3）、
  前向分支
  10 事件
  （0101）；
2. **二位机**：
  状态序列
  全打印
  （爬坡/
  稳态/
  出口降档
  肉眼可见）、
  命中率
  66% vs
  50%
  （断言一：
  循环 >
  乱序）；
3. **静态
  启发式**：
  循环
  12 中
  = 回边
  全中
  （断言二）；
4. **预取
  推演**：
  ⌈10/2⌉=5、
  ⌈10/5⌉=2
  （断言三：
  公式的
  机器
  验证）；
  时间线
  逐迭代
  "ok"——
  到货
  恰不晚于
  用数；
5. **对齐**：
  32 → 8
  miss
  （断言四：
  pad 消
  冲突）。

## 65.7 工程注意点

- **猜错
  的代价**
  不对称：
  预测错
  = 冲刷
  流水线
  （十几
    周期）；
  预取
  错 =
  白占
  带宽与
  缓存。
  两者
  都要
  "宁缺
  勿滥"——
  这就是
  二位机
  要"连错
  两次"
  的哲学。
- **编译器
  的分支
  提示**：
  C++20
  [[likely]]/
  [[unlikely]]
  把静态
  启发式
  的裁决权
  交给
  程序员；
  __builtin_expect
  是 GCC
  老接口。
  37 章
  的循环
  形状
  让编译器
  自动
  获得
  这些
  知识。
- **预取
  与
  一致性**：
  多核下
  预取
  会提前
  拉取
  别的核
  正要写
  的行——
  预取
  让一致性
  流量
  提前/
  增多，
  需要节制。
- **预测
  与安全**：
  Spectre
  （2018）
  把"猜错
  也执行"
  的投机
  变成了
  侧信道——
  现代机器
  的预测器
  加了
  隔离与
  训练
  防护。
  预测
  是性能
  的支柱、
  也是
  安全的
  攻击面。
- **模拟器
  的口径**：
  我们的
  二位机
  单计数器、
  全局共享；
  真实
  预测器
  按地址
  索引、
  千计数器
  并联。
  "单灯
  版"
  足以讲
  清状态机
  与循环
  红利；
  索引污染、
  别名
  这些
  工程病
  留给
  延伸
  阅读。

## 65.8 本章配套文件

本示例无
ANTLR——
预测器与
缓存
模拟
自包含，
走"简单
程序"
对账
协议。

### 65.8.1 predict.hpp 与 predict.cpp

二位
饱和机、
静态
启发式、
预取
距离
推演、
对齐
冲突
模拟。

```cpp
// file: src/predict.hpp
// file: src/predict.hpp
// 第 65 章配套：分支预测与存储预取的模拟（虎书 §20.3 + §21.2–21.3）。
#ifndef TIP_PREDICT_HPP
#define TIP_PREDICT_HPP

#include <string>
#include <vector>

namespace tip {

// 分支事件：taken = 实际跳不跳；backward = 目标在本指令之前（回边）
struct BranchEvent {
    bool taken;
    bool backward;
};

struct PredictReport {
    int total = 0;
    int hits = 0;
    int misses = 0;
    std::vector<int> stateLog;   // 二位机逐事件后的状态（0..3）
};

// 二位饱和预测器
PredictReport twoBitPredict(const std::vector<BranchEvent> &trace);

// 静态启发式（后向 taken / 前向 not-taken）
PredictReport staticHeuristic(const std::vector<BranchEvent> &trace);

struct PrefetchStep {
    int iter;         // 用数的迭代号
    int issueIter;    // 发预取的迭代号（iter − distance；< 0 = 开场即发）
    int issueAt;      // 发出时刻（周期）
    int arriveAt;     // 到货时刻
    std::string verdict;   // "ok" / "late"
};

struct PrefetchPlan {
    int tCycle = 1;
    int tLatency = 10;
    int distance = 0;
    int iterations = 0;
    std::vector<PrefetchStep> timeline;
};

// 预取距离推演：d = ⌈T_latency / T_cycle⌉
PrefetchPlan prefetchDistance(int tCycle, int tLatency, int iterations);

struct AlignReport {
    int baseMisses = 0;   // 未错开（同相位冲突）
    int padMisses = 0;    // 错开 pad 后
};

// 交替访问 A[i]/B[i] 的直接映射冲突演示：pad 错开相位消 miss
AlignReport alignSim(int n, int lineSize, int cacheLines, int pad);

}  // namespace tip

#endif  // TIP_PREDICT_HPP
```

```cpp
// file: src/predict.cpp
// file: src/predict.cpp
// 第 65 章配套：二位饱和分支预测器、静态启发式、预取距离推演、
// 缓存对齐消冲突（虎书 §20.3 + §21.2–21.3）。
#include "predict.hpp"

#include <map>

namespace tip {

// ---------- 二位饱和计数器（2-bit saturating counter）----------
// 状态 0..3：0,1 = 预测不跳（not taken），2,3 = 预测跳（taken）。
// taken：+1 封顶 3；not taken：-1 触底 0。预测 = 状态 ≥ 2。
// 语义：连错两次才翻转预测（单次噪声不敏感）。

PredictReport twoBitPredict(const std::vector<BranchEvent> &trace) {
    PredictReport r;
    int state = 0;   // 初始：强不跳
    for (const auto &e : trace) {
        bool predicted = state >= 2;
        if (predicted == e.taken) ++r.hits;
        else ++r.misses;
        // 状态机推进
        if (e.taken) state = state < 3 ? state + 1 : 3;
        else state = state > 0 ? state - 1 : 0;
        r.stateLog.push_back(state);
    }
    r.total = static_cast<int>(trace.size());
    return r;
}

// ---------- 静态启发式：后向跳转预测 taken（循环启发式）----------
// 编译器不需要运行时历史：目标地址在本指令之前 ⇒ 大概率是循环回边 ⇒ 跳。
// 前向（if 的 then）≈ 五五开 ⇒ 预测不跳（顺序流）。
PredictReport staticHeuristic(const std::vector<BranchEvent> &trace) {
    PredictReport r;
    for (const auto &e : trace) {
        bool predicted = e.backward;   // 后向 → taken
        if (predicted == e.taken) ++r.hits;
        else ++r.misses;
    }
    r.total = static_cast<int>(trace.size());
    return r;
}

// ---------- 预取距离推演（虎书 21.3）----------
// 循环每迭代用时 T_cycle 周期、一次 miss 的延迟 T_latency 周期 ⇒
// 提前 d = ⌈T_latency / T_cycle⌉ 个迭代发起预取，数据恰在用时前到达。
// 返回每个 (T_cycle, T_latency) 组合的距离。

PrefetchPlan prefetchDistance(int tCycle, int tLatency, int iterations) {
    PrefetchPlan p;
    p.tCycle = tCycle;
    p.tLatency = tLatency;
    p.distance = (tLatency + tCycle - 1) / tCycle;   // ⌈⌉
    p.iterations = iterations;
    // 时间线：迭代 i 在时刻 i·T_cycle 用数；预取在 (i-d)·T_cycle 发出，
    // 到货 (i-d)·T_cycle + T_latency ≤ i·T_cycle ⟺ d ≥ T_latency/T_cycle ✓。
    for (int i = 0; i < iterations; ++i) {
        int useAt = i * tCycle;
        int issueIter = i - p.distance;
        int issueAt = issueIter * tCycle;
        int arriveAt = issueAt + tLatency;
        p.timeline.push_back({i, issueIter, issueAt, arriveAt,
                              arriveAt <= useAt ? "ok" : "late"});
    }
    return p;
}

// ---------- 缓存对齐消冲突（虎书 21.2）----------
// 直接映射缓存里，两个热数组列若相隔恰为缓存容量的整数倍，
// 互相踢出（冲突 miss）。把数组 B 的基址错开一个缓存行 ⇒ 冲突消失。
AlignReport alignSim(int n, int lineSize, int cacheLines, int pad) {
    AlignReport r;
    r.baseMisses = 0;
    r.padMisses = 0;
    // 访问模式：A[i] 与 B[i] 交替（模板计算风格），行主序逐 i。
    auto sim = [&](int bBase, int &misses) {
        std::map<int, int> tag;
        auto touch = [&](int addr) {
            int line = addr / lineSize;
            int slot = line % cacheLines;
            auto it = tag.find(slot);
            if (it == tag.end() || it->second != line) {
                tag[slot] = line;
                ++misses;
            }
        };
        for (int i = 0; i < n; ++i) {
            touch(i);                    // A[i]（A 基址 0）
            touch(bBase + i);            // B[i]（B 基址 = bBase）
        }
    };
    // 冲突布置：B 放在“恰一个缓存容量”之外（基址 = cacheLines*lineSize）
    // ⇒ B 的行映射到与 A 相同的槽——同相位互相踢出。
    int unalignedBase = cacheLines * lineSize;
    sim(unalignedBase, r.baseMisses);
    // 对齐：B 错开 pad 个单元（pad 取一个缓存行），相位错开、冲突消失
    sim(unalignedBase + pad, r.padMisses);
    return r;
}

}  // namespace tip
```

### 65.8.2 驱动 main.cpp

两种
trace、
两台
预测器、
两组
延迟、
一次
对齐、
四断言。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 65 章驱动（无参运行，走“简单程序”对账协议）：
//   循环 trace + 分支 trace → 二位预测器逐事件 → 静态启发式 →
//   预取距离推演（两组延迟）→ 对齐消冲突 miss 对比。
#include "predict.hpp"

#include <iostream>

namespace {

// 循环 trace：5 次迭代 = 回边 taken×4 + 出口 not-taken×1，再跑 3 轮循环
std::vector<tip::BranchEvent> loopTrace(int iters, int rounds) {
    std::vector<tip::BranchEvent> t;
    for (int r = 0; r < rounds; ++r)
        for (int i = 0; i < iters; ++i)
            t.push_back({i + 1 < iters, true});
    return t;
}

// 分支 trace：不可预测的 if（数据驱动，taken 交替随机但无规律——用 0101 模拟）
std::vector<tip::BranchEvent> branchTrace(int n) {
    std::vector<tip::BranchEvent> t;
    for (int i = 0; i < n; ++i)
        t.push_back({i % 2 == 0, false});   // 前向：if 的 then
    return t;
}

}  // namespace

int main() {
    auto loop = loopTrace(5, 3);
    auto branch = branchTrace(10);

    std::cout << "== trace ==\n";
    std::cout << "  循环回边（taken×4 + not×1）×3 轮 = " << loop.size() << " 事件\n";
    std::cout << "  前向分支 0101…×10 = " << branch.size() << " 事件\n";

    std::cout << "== 二位饱和预测器（循环）==\n";
    tip::PredictReport p1 = tip::twoBitPredict(loop);
    std::cout << "  状态序列:";
    for (int s : p1.stateLog) std::cout << ' ' << s;
    std::cout << "\n  hits=" << p1.hits << " misses=" << p1.misses
              << " 命中率=" << (p1.total ? 100 * p1.hits / p1.total : 0) << "%\n";

    std::cout << "== 二位饱和预测器（乱序分支）==\n";
    tip::PredictReport p2 = tip::twoBitPredict(branch);
    std::cout << "  状态序列:";
    for (int s : p2.stateLog) std::cout << ' ' << s;
    std::cout << "\n  hits=" << p2.hits << " misses=" << p2.misses
              << " 命中率=" << (p2.total ? 100 * p2.hits / p2.total : 0) << "%\n";

    std::cout << "== 静态启发式（后向 taken / 前向 not）==\n";
    tip::PredictReport s1 = tip::staticHeuristic(loop);
    tip::PredictReport s2 = tip::staticHeuristic(branch);
    std::cout << "  循环: hits=" << s1.hits << " misses=" << s1.misses
              << "（回边全对，出口全错）\n";
    std::cout << "  分支: hits=" << s2.hits << " misses=" << s2.misses
              << "（五五开）\n";

    std::cout << "== 预取距离推演 ==\n";
    tip::PrefetchPlan f1 = tip::prefetchDistance(2, 10, 6);
    std::cout << "  T_cycle=2 T_latency=10 ⇒ d=" << f1.distance << '\n';
    for (const auto &st : f1.timeline)
        std::cout << "    用数@迭代" << st.iter << "（t=" << st.issueIter + f1.distance << "*2="
                  << (st.iter) * f1.tCycle << "） 预取@迭代" << st.issueIter
                  << "（t=" << st.issueAt << "） 到货 t=" << st.arriveAt
                  << " " << st.verdict << '\n';
    tip::PrefetchPlan f2 = tip::prefetchDistance(5, 10, 4);
    std::cout << "  T_cycle=5 T_latency=10 ⇒ d=" << f2.distance
              << "（慢循环：预取更从容）\n";

    std::cout << "== 对齐消冲突（直接映射）==\n";
    // 16 单元数组、行 4、槽 8：B 放在容量 32 之外（基址 32 = 8 行 × 4）
    // ⇒ B 的行与 A 的行映射同槽，同相位互相踢出；pad=4（一行）错开。
    tip::AlignReport ar = tip::alignSim(16, 4, 8, 4);
    std::cout << "  交替访问 A[i]/B[i]，B 基址 32（同相位）: misses=" << ar.baseMisses << '\n';
    std::cout << "  B 基址 36（pad=4 错开）: misses=" << ar.padMisses << '\n';

    std::cout << "== 对账 ==\n";
    bool ok1 = p1.hits > p2.hits;                       // 循环比乱序好预测
    bool ok2 = s1.hits >= 4 * 3;                        // 启发式抓循环回边
    bool ok3 = f1.distance == 5 && f2.distance == 2;    // ⌈⌉ 公式
    bool ok4 = ar.padMisses < ar.baseMisses;            // 错开消冲突
    std::cout << "  循环命中率 > 乱序: " << (ok1 ? "yes" : "NO") << '\n';
    std::cout << "  启发式抓回边: " << (ok2 ? "yes" : "NO") << '\n';
    std::cout << "  距离公式 ⌈10/2⌉=5 ⌈10/5⌉=2: " << (ok3 ? "yes" : "NO") << '\n';
    std::cout << "  对齐 miss 下降: " << (ok4 ? "yes" : "NO") << '\n';
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
```

### 65.8.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== trace ==
  循环回边（taken×4 + not×1）×3 轮 = 15 事件
  前向分支 0101…×10 = 10 事件
== 二位饱和预测器（循环）==
  状态序列: 1 2 3 3 2 3 3 3 3 2 3 3 3 3 2
  hits=10 misses=5 命中率=66%
== 二位饱和预测器（乱序分支）==
  状态序列: 1 0 1 0 1 0 1 0 1 0
  hits=5 misses=5 命中率=50%
== 静态启发式（后向 taken / 前向 not）==
  循环: hits=12 misses=3（回边全对，出口全错）
  分支: hits=5 misses=5（五五开）
== 预取距离推演 ==
  T_cycle=2 T_latency=10 ⇒ d=5
    用数@迭代0（t=0*2=0） 预取@迭代-5（t=-10） 到货 t=0 ok
    用数@迭代1（t=1*2=2） 预取@迭代-4（t=-8） 到货 t=2 ok
    用数@迭代2（t=2*2=4） 预取@迭代-3（t=-6） 到货 t=4 ok
    用数@迭代3（t=3*2=6） 预取@迭代-2（t=-4） 到货 t=6 ok
    用数@迭代4（t=4*2=8） 预取@迭代-1（t=-2） 到货 t=8 ok
    用数@迭代5（t=5*2=10） 预取@迭代0（t=0） 到货 t=10 ok
  T_cycle=5 T_latency=10 ⇒ d=2（慢循环：预取更从容）
== 对齐消冲突（直接映射）==
  交替访问 A[i]/B[i]，B 基址 32（同相位）: misses=32
  B 基址 36（pad=4 错开）: misses=8
== 对账 ==
  循环命中率 > 乱序: yes
  启发式抓回边: yes
  距离公式 ⌈10/2⌉=5 ⌈10/5⌉=2: yes
  对齐 miss 下降: yes
```

## 65.9 小结与练习

本章替
机器
赌了两把
未来：

- 二位
  饱和机：
  连错
  两次
  才翻脸，
  循环
  是最大
  红利、
  乱序
  分支
  是天敌；
- 静态
  启发式
  （后向
  taken）
  让编译期
  免费拿到
  循环
  预测的
  大头，
  代码
  布局
  是它的
  姊妹
  武器；
- 预取
  距离 =
  ⌈延迟/迭代⌉，
  开场
  预取
  补前 d 个
  迭代，
  慢循环
  摊得开
  延迟；
- 对齐
  消冲突：
  同槽
  互踢、
  错行
  相安——
  一行
  之差
  四倍
  miss。

下一章
（52）
把访问
模式
与缓存
几何
正式
合流：
迭代空间、
交换、
分块。

练习：

1. 手工推
   0101
   分支下
   二位机
   的状态
   序列，
   与输出
   对照；
   换 0011
   重复，
   命中率
   变多少？
   （提示：
    0011
    的周期
    与饱和
    边界
    相互
    作用。）
2. 实现
   gshare：
   4 位
   全局
   历史 ⊕
   分支
   地址
   索引
   16 个
   二位机，
   在
   0101
   trace
   上
   命中率
   能到
   多少？
3. 给
   预取
   推演加
   "d 太小"
   对照组：
   d=3 时
   列出
   late
   的迭代，
   验证
   延迟
   漏出。
4. 把
   对齐
   模拟
   改成
   2 路
   组相联：
   同槽
   冲突
   还在吗？
   pad
   还需要吗？
   （提示：
    相联度
    是冲突
    的第二
    道防线。）
5. 连回
   50 章：
   展开系数
   k=2 时
   T_cycle
   翻倍、
   d 减半——
   写出
   展开 +
   预取的
   联合
   参数表，
   讨论
   在途
   预取数
   （= d）
   与展开
   因子的
   权衡。
