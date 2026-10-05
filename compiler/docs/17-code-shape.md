# 第 17 章　代码形状：数组、字符串与跳转表

## 17.1 问题：同一句话，多种译法

`a[i][j] = x` 是
源程序里
一句话，
落到机器
上是
**五六条
指令**：
算地址、
做范围
检查、
访存。
这五六条
指令
**长什么样**，
编译器
说了算——
这就是
**代码形状**
（code
shape）。

形状不是
小事。
第 16 章
的三地址码
决定了
"语句→
四元组"的
骨架；
本章决定
**表达式
与数据
引用**
的肉：
数组元素
的地址
怎么算、
字符串
操作
怎么发
指令、
多路
分支
怎么
找到
目标。
同一个
语义，
好的
形状
省乘法、
省访存、
省比较；
坏的
形状
让后面
的优化
（第 41 章
值编号、
第 43 章
强度削减）
无从
下手。

取材
鲸书
第 7 章
（Code
Shape）的
三块
核心：
§7.5 数组
存储与
寻址、
§7.6 字符串、
§7.8.3 case
语句，
自包含
展开。
对象与
记录的
布局
已在
第 52 章
讲过，
本章
补齐
**数组、
字符串、
多路
分支**
三件。

## 17.2 值的住处：形状决策的总纲

编译器
为每个
值选
住处：
寄存器、
栈槽、
堆、
静态区。
住处
决定了
引用
它的
指令
形状：

- 局部
  标量
  进
  寄存器
  （第 58 章
  分配）；
- 记录/
  对象
  按编译期
  偏移
  访问
  （第 52 章
  前缀法
  布局）；
- 数组
  元素
  的
  位置
  **运行期
  才知**
  ——
  需要
  地址
  多项式；
- 形状
  本身
  运行期
  才知
  （变界
  数组、
  数组
  参数）
  ——
  需要
  **dope
  vector**。

本章
聚焦
后两者，
再加
两个
"操作
形状"
问题：
字符串
操作
（表示
决定
代价）
与
case
分派
（结构
决定
比较
次数）。

## 17.3 数组地址多项式：从一维到行主序二维

**一维**
向量
A[low..high]，
元素宽
w：

> addr(A[i])
> = @A +
> (i − low) × w

**二维**
行主序
（row-major：
一行
摆完
再摆
下一行，
C/Pascal
口径；
Fortran
是列主序
——
公式
同型、
维序
互换）。
A[low1..high1,
low2..high2]，
记
len2 =
high2 −
low2 + 1：

> addr(A[i,j])
> = @A +
> (i − low1) × len2 × w +
> (j − low2) × w

推导
只要
两步：
先找
**第 i 行
的起点**
（前面有
i−low1 整行，
每行
len2 个
元素），
再在
行内
按向量
公式
走
(j−low2)。
期望输出
用
A[1..2,
1..4]、
w=4
（鲸书
原例）
逐格
打印：
朴素
多项式、
假零版、
**枚举
直查**
三方
相等——
枚举
直查
是
把数组
整个
摆开
数格子的
"地面
真值"，
它不
套任何
公式，
公式
对不对
它说了算。

## 17.4 假零：把下界折进基址

朴素
多项式
每次
访问
要算
两次
减法
（i−low1、
j−low2）。
观察：
**下界
项与
i、j
无关**——

> @A +
> (i × len2 + j) × w −
> (low1 × len2 + low2) × w

把减项
折进
基址：

> @A0 =
> @A −
> (low1 × len2 + low2) × w
>
> addr(A[i,j])
> = @A0 +
> (i × len2 + j) × w

这就是
**假零**
（false
zero）：
基址
挪到
"下标
全为零"
的位置，
让运行期
计算
只剩
`i×len2 + j`
一次乘法
加一次
加法
（乘 w
还是
常量乘，
可再
换移位）。
我们的
例子里
@A0 =
@A − 20，
A[2,3]
落在
@A0 +
(2×4+3)×4
= @A0+44
= @A+24
——
与朴素
多项式、
枚举
直查
三方
一致
（断言一）。

代价与
收益的
边界：
假零
折算
发生在
**过程
入口**
（或
首次
访问前）
一次；
数组
只在
循环里
访问
一两次时，
未必
回本。
鲸书
的
建议：
访问
密集
就
入口
折算，
访问
稀疏
就
保留
朴素
形状。

## 17.5 dope vector：运行期的形状

数组
作参数
传递、
或界
运行期
才定时，
被调方
**编译期
不知道
len2**。
解法：
调用方
构造
一个
描述子
——
**dope
vector**
（"dope"
= 数据
的
配料表）：

```
struct DopeVector {
    int falseZero;   // @A0：假零基址（构造时算好）
    int stride;      // len2：一行多少个元素
    int w;           // 元素宽度
};
```

被调方
拿到的
只是
指向
描述子的
指针，
每次
引用
A[i][j]
都从
描述子里
**现读**
stride，
套假零
公式。
代价
账
（期望
输出）：
编译期
已知
形状
4 条
操作
（multI/
add/
multI/
loadAO），
dope
形状
5 条
——
**多的
正是
那次
stride
访存**。
更隐蔽
的
代价：
优化器
失去
完整
形状
知识，
依赖
len2
的
交换
判定
（第 63 章
GCD
检验）
等
推理
全部
失效。
鲸书
的
口径：
dope
vector
让
"跨
编译
单元
传
数组"
成为
可能，
但
每个
这样的
数组
都是
优化器
眼里的
**半个
陌生人**。

## 17.6 字符串：三种表示的代价表

字符串
的
表示
决定
每个
操作的
指令
形状。
三种
经典
表示：

- **定长**：
  长度是
  声明，
  编译期
  常量；
- **长度
  前缀**：
  头部
  一个
  长度字
  （PL/I、
  Pascal）；
- **零
  终止**：
  '\0' 哨兵
  收尾
  （C）。

两个
操作的
访存
账
（a 长
12、
b 长
34）：

| | length(a) | length(a+b) |
|---|---|---|
| 定长 | 0（常量） | 0（常量相加） |
| 长度前缀 | 1（读长度字） | 2（读两个字） |
| 零终止 | 13（走到 '\0'） | 48（走完两段） |

鲸书
点的
经典
优化题：
`strlen(strcat(a,b))`
——
朴素
译法
先
拼接
（抄
46 个
字符）
再
数
长度；
看穿
表示
的
编译器
译成
`strlen(a)+strlen(b)`：
长度
前缀
下
就是
**两次
读字
一次
加法**。
表示
知识
值
一次
遍历。

零终止
省了
一个
长度字
的空间，
代价
是
**长度
与拼接
线性
访存**、
且
"内嵌
'\0'
的
串"
无法
表达。
定长
最快
但
浪费
尾部
空间、
拼接
要
检查
溢出。
工程
上
没有
免费
的
表示——
C++
的
`std::string`
选了
长度
前缀
（+
短串
优化），
把
账
摊回
了
正确
的一边。

## 17.7 case 语句：三策略与选择

`switch(e)`
的
核心
问题：
**e 的值
运行期
才知，
怎么
找到
对应
的
case？**
鲸书
§7.8.3
给
三策略：

**线性
比较链**：
把 switch
译成
嵌套
if-then-else。
命中
第 k 个
case
比较
k 次；
default
比
全部。
case
数
≤3 时
它就
是
正解
（比较
次数
少、
代码
小）。
顺带
一提：
线性链
应按
**估计
频度**
排序
case
——
形状
优化
的
第一课。

**跳转表**
（jump
table）：
标签
密集时，
建一张
向量
@Table，
槽 k
放
case
(k+lo)
的
目标
标签；
运行期
一次
范围
检查
（越界
走
default）
加一次
按表
跳转：

```
t1 ← e
if (t1 < lo or t1 > hi) goto Default
goto Table[t1 - lo]      ← 一次范围检查 + 一次间接跳转
```

洞（无
对应
case
的值）
填
default
标签。
代价
恒定：
**2 步**
（我们的
口径：
范围
检查
1 +
跳转
1）。

**二分
搜索**：
标签
稀疏、
跨度
大时，
建
有序
表，
运行期
折半
查找
匹配
标签，
⌈log₂ n⌉
次比较。

**选择
规则**
（chooseStrategy
的
实现）：
case
数 ≤3
→
线性；
密度
（标签数/
跨度）
≥0.5
且跨度
≤64
→
跳转表；
否则
→
二分。
期望
输出
的三组
样例
恰好
各归
其位：
{0..9}
密度 1.0
选跳转表、
{0,15,
23,…,99}
密度 0.1
选二分、
{1,3,5}
选线性。

密集集
上的
均摊
账
（对
取值域
均匀
发牌，
含
default）：
线性
5.5、
二分
4.4、
跳转表
2——
**跳转表
赢在
代价
与
case
数
无关**。
而
稀疏集
若
强建
表要
100 槽：
空间
不划算，
二分
4.43
次已
够好。

还有一个
工程
细节：
跳转表/
二分
把
"多个
可能
目标"
藏进了
数据
或
搜索，
CFG
构造器
（第 14 章）
看不见
它们。
鲸书
建议
在 IR
里用
tbl 伪操作
把
目标集
**显式
晒给
分析器**——
否则
可达性
分析
会把
后半个
程序
判成
死代码。

## 17.8 期望输出解读与对账

五段
输出、
四条
断言：

1. **二维
  多项式**：
  8 个
  (i,j)
  上
  朴素=假零=枚举
  三方
  全等；
  鲸书
  原例
  A[2,3]
  = @A+24
  复现；
2. **dope
  vector**：
  dope
  访问
  与
  假零
  公式
  一致、
  操作数
  4 vs 5
  （多的
  是
  stride
  访存）；
3. **case
  选择**：
  密集→
  跳转表、
  稀疏→
  二分、
  三个→
  线性；
  均摊
  2 < 4.4 < 5.5；
4. **字符串**：
  长度
  前缀
  1/2 次
  vs 零终止
  13/48 次
  访存。

断言：
三方
地址
相等
（一）、
dope
一致
且更贵
（二）、
策略
按密度
落位
且
代价
序
成立
（三）、
前缀
表示
两种
长度
操作
都省
（四）。

## 17.9 工程注意点

- **下标
  从 0
  还是
  从 1**：
  C 选 0
  使
  low=0、
  假零
  折算
  消失——
  **地址
  多项式
  反过来
  影响了
  语言
  设计**。
  Fortran/Ada
  的任意
  下界
  则把
  折算
  留给
  编译器。
- **乘 w
  换移位**：
  w 是
  2 的幂
  时
  multI
  换
  lshift；
  但
  第 43 章
  会提醒：
  过早
  把
  乘法
  改写
  成移位
  会
  **锁死
  交换律**，
  剥夺
  后续
  重结合
  的
  机会——
  形状
  决策
  要
  看
  整条
  优化
  流水线。
- **范围
  检查**：
  跳转表
  的
  范围
  检查
  顺带
  完成了
  数组
  式的
  界检查；
  分立的
  界检查
  如何
  被证明
  冗余，
  见
  虎书
  轮的
  第 44 章
  （guard
  消除）。
- **case
  落空
  语义**：
  C 的
  fall-through
  要求
  各 case
  块
  **按
  源序
  摆放**
  （二分/
  跳转表
  只分派、
  块序
  不动）；
  没有
  fall-through
  的语言
  （Ada、
  Swift）
  连
  这个
  约束
  都省了。
- **间接
  向量
  数组**：
  鲸书
  还讲了
  第四种
  布局——
  每维
  一张
  指针表
  （BCPL/Java
  的
  锯齿
  数组），
  寻址
  每维
  恰两步、
  天然
  支持
  变长行，
  但
  缓存
  局部性
  更难
  预测。
  我们
  不实现，
  留作
  练习
  的
  对照
  组。

## 17.10 本章配套文件

本示例
无 ANTLR——
形状
推演
自包含，
走"简单
程序"
对账
协议。

### 17.10.1 shape.hpp 与 shape.cpp

地址
多项式、
假零、
dope
vector、
case
策略
选择
与
代价、
字符串
访存
账。

```cpp
// file: src/shape.hpp
// file: src/shape.hpp
// 第 17 章配套：代码形状——数组地址多项式、字符串表示、case 三策略（鲸书 §7.5–7.8）。
#ifndef TIP_SHAPE_HPP
#define TIP_SHAPE_HPP

#include <vector>

namespace tip {

// ---------- 数组地址多项式（行主序）----------

// 一维：@A + (i - low) * w
int vectorAddr(int i, int low, int w);

// 二维朴素多项式：@A + (i-low1)*len2*w + (j-low2)*w
int rowMajor2Naive(int i, int j, int low1, int high1, int low2, int high2, int w);

// 假零（false zero）：把下界项折进基址 @A0 = @A - (low1*len2 + low2)*w
// 访问只剩 @A0 + (i*len2 + j) * w —— 一次乘法（×w 可再换成移位）
int falseZeroBase(int low1, int high1, int low2, int high2, int w);
int rowMajor2FalseZero(int i, int j, int low1, int high1, int low2, int high2, int w);

// 枚举直查：按行主序把数组摆开，数 (i,j) 前面有几个元素——公式的"地面真值"
int rowMajor2Enumerate(int i, int j, int low1, int high1, int low2, int high2, int w);

// ---------- dope vector：运行期才知道的形状 ----------

struct DopeVector {
    int falseZero = 0;   // @A0：假零基址（调用方构造时算好）
    int stride = 0;      // len2：一行多少个元素
    int w = 4;           // 元素宽度
};

// 经 dope vector 取 A[i][j] 的地址（每次访问从描述子里现读 stride）
int dopeAddr(const DopeVector &d, int i, int j);

// 每种访问策略 emitted 的操作数（教学口径：数乘加与访存次数）
// 已知编译期形状：multI i,len2; add ; multI ,w; loadAO   → 2 乘 1 加 1 访存
int opsKnownShape();
// dope vector：loadAI stride; mult; add; mult; loadAO → 多一次 stride 的访存
int opsDopeShape();

// ---------- case 三策略（鲸书 §7.8.3）----------

enum class CaseStrategy { Linear, Binary, JumpTable };

// 按 (case 数, 标签密度) 选策略：≤3 线性；密集（密度≥0.5 且跨度≤64）跳转表；否则二分
CaseStrategy chooseStrategy(const std::vector<int> &labels);

// 命中 value 需要的比较次数：线性=位次；二分=折半步数；跳转表=1（一次范围检查）
int costLinear(const std::vector<int> &labels, int value);
int costBinary(const std::vector<int> &labels, int value);
int costJumpTable(const std::vector<int> &labels, int lo, int hi, int value);

// 均摊比较次数（对标签集合均匀取值；default 记 n 次/⌈log2⌉ 次）
double avgCost(const std::vector<int> &labels, int lo, int hi,
               int (*cost)(const std::vector<int> &, int));

// ---------- 字符串三表示 ----------

enum class StrRepr { Fixed, LengthPrefix, NulTerminated };

// length(a) 的访存次数：前缀=1（读长度字）；零终止=len+1（走到 '\0'）；定长=0（编译期常量）
int strlenTouches(StrRepr r, int len);

// length(a+b) 的访存次数：前缀=2；零终止=len(a)+len(b)+2
int concatLenTouches(StrRepr r, int lenA, int lenB);

}  // namespace tip

#endif  // TIP_SHAPE_HPP
```

```cpp
// file: src/shape.cpp
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
```

### 17.10.2 驱动 main.cpp

一个
数组、
一张
dope
vector、
三组
case、
三张
表示
账、
四断言。

```cpp
// file: src/main.cpp
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
```

### 17.10.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 二维地址多项式（A[1..2,1..4]，w=4）==
  假零基址 @A0 = @A + (-20)  ← 下界项折进基址
  A[1,1] 朴素=0 假零=0 枚举=0
  A[1,2] 朴素=4 假零=4 枚举=4
  A[1,3] 朴素=8 假零=8 枚举=8
  A[1,4] 朴素=12 假零=12 枚举=12
  A[2,1] 朴素=16 假零=16 枚举=16
  A[2,2] 朴素=20 假零=20 枚举=20
  A[2,3] 朴素=24 假零=24 枚举=24
  A[2,4] 朴素=28 假零=28 枚举=28
  鲸书例：A[2,3] 落在 @A+24（书中间距 24）
== dope vector（形状运行期才知）==
  dope 访问与多项式一致: yes
  操作数（编译期已知形状）=4（dope）=5 ← 每次访问多读一次 stride
== case 三策略 ==
  密集 0..9（10 个）→ 跳转表
  稀疏 {0,15,23,...,99}（10 个，跨 100）→ 二分
  三个标签 {1,3,5} → 线性链
  密集集均摊比较：线性=5.5 二分=4.4 跳转表=2
  稀疏集：二分均摊=4.43；若建表需 100 槽（密度 0.1）——不划算
== 字符串三表示（a 长 12、b 长 34）==
  定长: length(a) 访存=0  length(a+b) 访存=0
  长度前缀: length(a) 访存=1  length(a+b) 访存=2
  零终止: length(a) 访存=13  length(a+b) 访存=48
== 对账 ==
  多项式=假零=枚举 且 A[2,3]=@A+24: yes
  dope 地址一致且操作数更多: yes
  策略按密度选择且代价 跳转表<二分<线性: yes
  长度前缀长度/拼接访存都少于零终止: yes
```

## 17.11 小结与练习

本章把
"源语言
结构→
指令
形状"
的三块
硬骨头
啃完：

- 数组
  寻址：
  多项式
  是
  定义、
  假零
  是
  化简、
  枚举
  直查
  是
  证人；
- dope
  vector
  用
  一次
  stride
  访存
  换
  "形状
  运行期
  才知"
  的
  表达力，
  代价
  是
  优化器
  的
  半个
  失明；
- 字符串
  表示
  是
  一张
  代价
  表：
  空间、
  长度、
  拼接
  各有
  赢家；
- case
  三策略
  按
  密度
  落位，
  跳转表
  把
  分派
  代价
  与
  case
  数
  解耦。

下一章
（16）
离开
数据
形状、
回到
控制流：
把
基本块
串成
顺直的
跟踪。

练习：

1. 把
   rowMajor2
   推广到
   三维
   A[1..2,1..3,1..4]，
   写
   朴素
   多项式
   与
   假零
   版，
   枚举
   直查
   对账；
   数一数
   假零
   省了
   几次
   运行期
   减法。
2. 实现
   列主序
   （Fortran）
   版本，
   对同一
   (i,j)
   集合
   比较
   两种
   布局的
   地址：
   什么样的
   循环嵌套
   在哪种
   布局下
   顺序
   访存？
   （与
   第 63 章
   的
   交换
   判定
   呼应。）
3. 给
   chooseStrategy
   加
   第四
   参数
   "各
   case
   的
   profile
   频度"：
   频度
   高度
   不均时，
   线性链
   按频度
   排序
   能不能
   打败
   跳转表？
   给出
   频度
   分布的
   临界
   条件。
4. 实现
   间接
   向量
   版
   数组
   寻址
   （每维
   一次
   指针
   装载），
   对比
   其
   操作数
   与
   行主序
   多项式：
   几维
   之后
   间接
   向量
   反而
   更省？
5. 字符串
   拼接
   `a+b`
   的
   **复制**
   代价
   在三种
   表示下
   各是
   多少
   访存？
   定长
   表示
   的
   溢出
   检查
   加在
   哪里、
   几次
   比较？
