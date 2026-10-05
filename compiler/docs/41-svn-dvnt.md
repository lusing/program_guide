# 第 41 章　超局部与支配者值编号：SVN/DVNT

## 41.1 回望：块内的钱好捡，块缝里的钱难捡

第 40 章
的基本块
DAG 把
**块内**
的重复
计算
折掉了：
同一块里
两次
`a+b`，
第二次
直接
复用。
但冗余
不长眼，
它偏偏
爱待在
**块的
缝隙**里：

```
B0:  m = a + b
     if (a > b) goto B2 else B1
B2:  r = c + d        ← 与 B0 无关；但下面的 q 呢？
B3:  q = a + b        ← 明明 B0 刚算过！
```

块内
值编号
（LVN）
对 B3
的
`q = a+b`
无能为力：
它的表
在块界
清零了。
可这条
路径上
（B0→B3）
B0
**必然**
执行过
`a+b`，
q 的
计算是
纯粹的
重复劳动。

捡这笔钱
要回答
两个
问题：
**谁能
给谁
当上下文？**
（不是
所有
前驱
都行——
见下）
以及
**上下文
怎么
高效地
带上、
撤下？**
本章
按鲸书
§8.5.1
（超局部
值编号
SVN）
与
§10.5.2
（支配者
值编号
DVNT）
自包含
展开，
给出
从
LVN
到
DVNT
的
三档
阶梯，
每一档
都是
下一档
的
地基。

## 41.2 上下文的安全边界：EBB 与支配

**哪个
前驱的
计算
可以为
后继
背书？**
标准
只有
一条：
**沿每条
到达
路径
都执行过**
的
计算
才算数。

**扩展
基本块**
（EBB）
给了
一个
便宜的
充分
条件：
一条
单前驱
块链
`B0→B1→B2→…`
（链上
每块
除首块
外
恰有
一个
前驱）。
链上
任何
一块
的
上下文
=
它
前面的
整条
链——
因为
走到
这里
**只有
一条路**，
链前缀
必然
全部
执行。

SVN
就吃
这个
范围：
把
LVN
的表
沿
EBB
**携带**。
多前驱
块
（汇合点）
没这个
福分：
两条
路
来的
表
没法
合并
（一条
路上
算过
不等于
两条
路上
都算过），
只能
空表
重来。

**支配**
（第 37 章）
把这个
故事
讲到
极致：
汇合点
B4
虽然
不能
用
两臂
的
计算，
但
能用
**支配它**
的块
（B0、
分支块）
的计算
——
那些
块
在
每条
到达
B4 的
路径上。
DVNT
把
值编号
搬到
支配树
上，
表
沿树
下行、
出树
上卷，
就得到
**过程内**
的
值编号。

中间
有个
美丽的
巧合：
SSA
（第 38 章）
的
名字
**恰好**
编码了
"哪次
定义
存活"——
臂上
重定义
a 会
产生
新名字
a1 并
在
汇合点
插 φ，
于是
"上下文
里
a 变没变"
这个
LVN
最难
的
问题，
在
SSA
上
**根本
不会
被问到**。
所以
鲸书
建议
（我们也
照做）：
SVN/DVNT
都跑在
SSA 上。

## 41.3 SVN：作用域化散列表与撤销

SVN 的
表怎么
"带上、
撤下"？
鲸书
给了
三案：
快照
记录/恢复、
反向
解算、
**词法
作用域式
散列表**。
第三案
最优雅：
进块
push
一个
scope，
出块
pop——
pop 掉的
恰是
本块
写入的
条目，
表
自动
回到
块前
状态。

我们
的
引擎
（svn.cpp
的
`VnEngine`）
用
`scopes_`
栈
实现：
`lookupExpr`
从栈顶
向下
找，
`insertExpr`
只写
栈顶。
配合
SSA，
还有一个
简化：
名字→
规范名
的
映射
`vn_`
可以
**全局**
——
SSA 名字
只定义
一次，
映射
写一次
就
永远
有效，
撤销
只针对
expr 表。

SVN 的
遍历
（`runSVN`）
照抄
鲸书
Figure
8.12：

```
SVN(b, table):
    为 b 开 scope，LVN 处理 b
    for 后继 s:
        if s 只有 b 一个前驱: SVN(s, 当前表)     ← 携带上下文深入
        elif s 未处理: 工作表.append(s)          ← 汇合点：外层空表重来
    pop scope
```

效率
要点：
链前缀
只算
一次。
若对
每条
路径
独立
跑
LVN
（把
EBB
当
长块），
B0 在
三条
路径
上
会被
分析
三遍；
作用域
方案
里
每块
恰处理
一次。

SVN 的
边界
也
一眼
可见：
汇合点
开空表，
它们
的
冗余
（哪怕
肉眼看
穿）
全部
漏掉。
这就是
第三档
的
出场
理由。

## 41.4 DVNT：沿支配树先序与 φ 三判

DVNT 的
遍历
换成
**支配树
先序**
（`runDVNT`
的
`walk`）：

```
DVNT(B):
    开 scope
    处理 B 的 φ（三判）
    LVN 处理 B 的赋值
    对每个 CFG 后继 s：改写 s 的 φ 中来自边 (B,s) 的实参
    for 支配树孩子 c: DVNT(c)
    pop scope
```

三条
细节
撑起
整个
算法：

**其一，
访问序
反直觉**。
支配树
先序
可以
先访问
B4
再访问
B2、
B3
（三者
同是
分支块
的孩子，
次序
无关
紧要）——
能用于
B4 的
事实
只来自
支配者，
兄弟
之间
谁先
谁后
不相互
依赖。
我们的
实现
里
孩子
按
发现序
（块号
序）
访问，
无关
正确性。

**其二，
φ 三判**
（鲸书
Figure
10.6）。
对块首
每个
`n = φ(a1,…,ak)`：

1. **无义**：
  实参
  规范名
  全同
  ⇒ 删 φ，
  `vn[n] =
  该公共名`。
  典型
  成因：
  两臂
  算了
  同一个
  表达式，
  且
  各自
  被
  支配者
  的
  同一
  定义
  替换；
2. **重复**：
  实参
  元组
  与
  本块
  另一
  个 φ
  相同
  ⇒ 删，
  并入
  那个
  φ；
3. **新值**：
  入表
  （键
  带块号——
  同元组
  不同块
  是
  不同
  的 φ）。

**其三，
后继
φ 实参
随边
改写**。
块 B
处理完
后，
把每个
CFG
后继
s 的
φ 中
**对应
边
(B,s)
的那个
实参**
改写成
规范名。
这一步
与
SSA
构造的
改名
阶段
同型
（第 38 章
的
后继
处理），
它让
φ 的
实参
在
**定义者
被处理
时**
得到
最新
规范名——
弥补
"访问
序
反直觉"
造成的
时序
错位。

**不动点
扫描**。
第一轮
改写
完
φ 实参
后，
"两臂
同值"
的 φ
可能
要
下一轮
才
收敛为
无义。
我们
扫到
不增
即停
（上限
4 轮）；
示例
程序
第一轮
全中、
第二轮
空转
确认
（期望
输出
"2 轮
扫描"）。

## 41.5 值身份与名字身份：DVNT 与 PRE 的分工

第 44 章
的
PRE
（懒惰
代码
提升）
也消
冗余，
两者的
**身份
判据**
不同
（鲸书
§10.5.1）：

- **值身份**
  （值编号
  一族）：
  `a+b`
  与
  `2+b`
  当
  a=2 时
  是
  同一个
  值——
  判据
  是
  操作数
  的
  值号
  相等；
  还能
  顺带
  删
  赋值、
  删
  无义 φ。
- **名字身份**
  （LCM/PRE）：
  数据流
  方程
  在
  固定
  名字
  空间
  上
  传播，
  `a+b`
  与
  `a+c`
  天生
  不同；
  但能
  消
  **部分
  冗余**
  （一条
  路径
  上
  算过、
  另一条
  没有——
  补算
  后
  全局
  提升），
  且能
  沿
  **回边**
  传播
  （循环
  出口
  的
  冗余
  喂给
  下轮
  入口）。

DVNT
不做
部分
冗余、
不沿
回边
传播
（支配树
无环）；
PRE
认不出
值相等
的
换名
冗余。
工程
编译器
的
常见
配合
（鲸书
原话）：
先用
DVNT
把
值
身份
编码
进
名字
空间，
再让
LCM
吃
名字
身份
的红利。

## 41.6 示例与期望输出解读

示例
程序
vn.tip
的
形状
专为本章
定制：

```
B0:  常量赋值、m = a+b、n = a+b（块内冗余）、u = c+d
B2(then 臂):  r = c+d、t = a+b
B3(else 臂):  q = a+b、t = a+b
B4(汇合):     v = a+b、z = c+d、output×3
```

四块
冗余
各归
其档：

1. **LVN**：
  `n = a+b`
  块内
  复用
  m——
  消除
  **2** 条
  （另一条
  是
  TACGen
  临时
  变量
  的
  同式
  折叠）；
2. **SVN**：
  两臂
  的
  r/q/t
  都能
  复用
  B0 的
  m/u——
  消除
  **5** 条；
3. **DVNT**：
  再加
  汇合块
  的
  v/z——
  消除
  **7** 条
  +
  **1 个
  无义 φ**
  （两臂
  的 t
  都被
  规范化
  成
  m 的
  SSA 名，
  φ(t,t)
  实参
  相同，
  无义
  删除）。

期望
输出
的
"DVNT
优化后"
段
还有
两个
看头：

- **常量
  穿透**：
  `a0
  = t10`、
  `t10
  = 11`
  的
  copy 链
  被
  值编号
  整条
  折穿——
  `t50
  = 11
  + 4`、
  `if
  11 >
  4`。
  值编号
  天生
  包含
  复制
  传播
  与
  别名
  常量
  折叠；
- **保守
  φ**：
  我们的
  buildSsa
  对
  只在
  一臂
  定义
  的
  名字
  也
  插
  φ，
  未定义
  侧
  用
  `qu`/`ru`
  式
  占位
  实参。
  这些
  φ
  实参
  永不
  相同，
  DVNT
  不删
  （正确——
  它们
  可能
  真的
  未定义），
  但也
  不碍事：
  其
  结果
  从未
  被使用。

对账
四断言：
SVN
多于
LVN（跨块）、
DVNT
多于
SVN
（汇合+φ）、
优化
前后
outputs
相等
（SSA
解释器
证人）、
无义 φ
被删
且
经
不动点
确认。

## 41.7 工程注意点

- **为什么
  跑在
  SSA 上**：
  非
  SSA
  名字
  可
  多次
  定义，
  值号
  记录
  在
  哪个
  scope
  都
  不对
  （鲸书
  §8.5.1
  末段
  的
  反例：
  x 在
  B0/B3/B4
  各定义
  一次，
  删
  B3 的
  scope
  撤不干净）。
  SSA
  单定值
  从根上
  免疫。
- **φ
  实参
  改写
  的
  时序**：
  我们
  靠
  "后继
  改写 +
  多轮
  扫描"
  收敛；
  生产
  编译器
  （如
  Hack 的
  SSA
  图
  哈希
  一致化）
  把
  φ
  当
  图
  结点
  做
  自底
  向上
  哈希，
  一遍
  完成——
  思路
  不同，
  判据
  相同：
  实参
  值号
  相同
  即
  同值。
- **代数
  恒等式**：
  第 40 章
  DAG 的
  恒等式
  表
  （x+0、
  x×1、
  交换律
  归一）
  可以
  原样
  接进
  `exprKey`——
  本章
  从简
  未接，
  留作
  练习。
- **与
  SCCP
  的
  亲缘**：
  鲸书
  §10.7.1
  的
  SCCP
  在
  SSA 图上
  同时
  传播
  常量
  与
  可达性；
  DVNT
  的
  支配树
  遍历
  是
  它的
  "表
  驱动
  近亲"。
  两者
  都
  利用
  了
  同一个
  事实：
  SSA
  的
  use-def
  链
  就是
  一张
  可
  遍历
  的
  图。
- **撤销
  的
  工程学**：
  作用域
  化
  散列表
  与
  第 12 章
  的
  符号表
  同构——
  前端
  的
  设施
  在
  优化器
  里
  再用
  一次，
  这是
  鲸书
  明说
  的
  软件工程
  红利。

## 41.8 本章配套文件## 39.8 本章配套文件

示例复用第 38 章（SSA）的基座本地副本，新增 svn.hpp/svn.cpp 与驱动。

### 41.8.1 文法 TIP.g4

```text
// file: TIP.g4
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
AND        : '&' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

### 41.8.2 新件：svn.hpp 与 svn.cpp

三档接口与公共引擎（正文 39.3/39.4 逐段讲解的就是这两个文件）。

```cpp
// file: src/svn.hpp
// file: src/svn.hpp
// 第 41 章配套：超局部值编号（SVN）与支配者值编号（DVNT）（鲸书 §8.5.1 + §10.5.2）。
#ifndef TIP_SVN_HPP
#define TIP_SVN_HPP

#include <set>
#include <string>
#include <vector>

#include "ssa.hpp"

namespace tip {

// 三档值编号的成绩单
struct VnReport {
    int redundant = 0;        // 消掉的冗余赋值（复用已有值）
    int phiDeleted = 0;       // 删掉的 φ（无义或重复）
    int sweeps = 1;           // DVNT 扫描轮数（LVN/SVN 恒 1）
    std::vector<std::string> notes;   // 逐条流水（谁复用了谁）
};

struct VnResult {
    VnReport rep;
    SsaProgram prog;          // 删除 + 名字改写后的程序（解释器对账用）
};

// 第一档：块内值编号（LVN）——每块空表起步
VnResult runLVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds);

// 第二档：超局部值编号（SVN）——沿单前驱链携带作用域化散列表，多前驱块空表重来
VnResult runSVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds);

// 第三档：支配者值编号（DVNT）——沿支配树先序，φ 三判（无义/重复/新值），
// 后继 φ 实参随边改写；扫到不动点（上限 4 轮）
VnResult runDVNT(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds, const DomInfo &di);

}  // namespace tip

#endif  // TIP_SVN_HPP
```

```cpp
// file: src/svn.cpp
// file: src/svn.cpp
// 第 41 章配套：三档值编号的公共引擎与三种作用域纪律
// （LVN 块内 / SVN 扩展基本块 / DVNT 支配树，鲸书 §8.5.1 + §10.5.2）。
// φ 的表示沿用 ssa.cpp 口径：phiArgs 非空即是 φ；"删除"= 不进幸存序列。
#include "svn.hpp"

#include <functional>

namespace tip {

namespace {

// 值编号引擎：作用域化散列表（expr key → 既有定义名）+ 名字→规范名映射。
// 在 SSA 上运行：名字唯一，全局 vn 映射即可正确撤销（删 scope 只影响 expr 表）。
class VnEngine {
public:
    VnEngine(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
             const std::vector<std::set<int>> &preds)
        : prog_(ssa), adj_(adj), preds_(preds) {}

    VnResult finish() {
        VnResult r;
        r.rep = rep_;
        r.prog = prog_;
        return r;
    }

    int removed() const { return rep_.redundant + rep_.phiDeleted; }

    void pushScope() { scopes_.emplace_back(); }
    void popScope() { scopes_.pop_back(); }

    std::string canon(const std::string &x) const {
        auto it = vn_.find(x);
        return it == vn_.end() ? x : it->second;
    }

    // ---------- 处理一个块（重写 body，删除即不进幸存序列）----------
    // withPhi：DVNT 口径（块首先做 φ 三判）；LVN/SVN 跳过 φ 判定但保留实参改写。
    void processBlock(int b, bool withPhi) {
        std::vector<SsaInst> body = prog_.blocks[b].body;   // 取走原体
        std::vector<SsaInst> live;
        for (auto inst : body) {
            // ---- φ：phiArgs 非空即是（ssa.cpp 口径）----
            if (!inst.phiArgs.empty()) {
                if (withPhi) {
                    // 三判（鲸书 Figure 10.6）：实参先经 canon（可能已被前驱的
                    // 后继改写推进来）；
                    // 无义 → 并入实参公共值；重复 → 并入同键 φ；新值 → 入表
                    for (auto &arg : inst.phiArgs) arg = canon(arg);
                    bool same = true;
                    for (size_t k = 1; k < inst.phiArgs.size(); ++k)
                        if (inst.phiArgs[k] != inst.phiArgs[0]) { same = false; break; }
                    if (same) {
                        vn_[inst.dst] = inst.phiArgs[0];
                        ++rep_.phiDeleted;
                        rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                             " = φ(...) 无义，并入 " + inst.phiArgs[0]);
                        continue;   // 删除：不入 live
                    }
                    std::string key = "φB" + std::to_string(b) + "(";
                    for (size_t k = 0; k < inst.phiArgs.size(); ++k) {
                        if (k) key += ",";
                        key += inst.phiArgs[k];
                    }
                    key += ")";
                    std::string hit = lookupExpr(key);
                    if (!hit.empty()) {
                        vn_[inst.dst] = hit;
                        ++rep_.phiDeleted;
                        rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                             " = φ(...) 重复，并入 " + hit);
                        continue;
                    }
                    vn_[inst.dst] = inst.dst;
                    insertExpr(key, inst.dst);
                }
                live.push_back(inst);   // 幸存的 φ 原样保留
                continue;
            }
            // ---- 普通指令 ----
            switch (inst.op) {
            case TOp::Copy:
                inst.a = canon(inst.a);
                vn_[inst.dst] = inst.a;
                break;
            case TOp::Add: case TOp::Sub: case TOp::Mul:
            case TOp::Div: case TOp::Gt: case TOp::Eq: {
                inst.a = canon(inst.a);
                inst.b = canon(inst.b);
                std::string key = exprKey(inst);
                std::string hit = lookupExpr(key);
                if (!hit.empty()) {
                    vn_[inst.dst] = hit;
                    ++rep_.redundant;
                    rep_.notes.push_back("B" + std::to_string(b) + ": " + inst.dst +
                                         " 复用 " + hit);
                    continue;   // 删除
                }
                vn_[inst.dst] = inst.dst;
                insertExpr(key, inst.dst);
                break;
            }
            case TOp::Input:
                vn_[inst.dst] = inst.dst;   // 两次 input 不同值，不可比较
                break;
            case TOp::Output: case TOp::Ret:
                inst.a = canon(inst.a);
                break;
            case TOp::IfGt: case TOp::IfEq:
                inst.a = canon(inst.a);
                inst.b = canon(inst.b);
                break;
            default:
                break;
            }
            live.push_back(inst);
        }
        prog_.blocks[b].body = live;
        // 后继 φ 实参随边改写（与 SSA 改名阶段的后继处理同型）
        for (int s : adj_[b]) {
            size_t pos = 0;
            for (int p : preds_[s]) {
                if (p == b) break;
                ++pos;
            }
            if (pos >= preds_[s].size()) continue;
            for (auto &inst : prog_.blocks[s].body)
                if (!inst.phiArgs.empty() && pos < inst.phiArgs.size())
                    inst.phiArgs[pos] = canon(inst.phiArgs[pos]);
        }
    }

private:
    std::string lookupExpr(const std::string &key) const {
        for (auto it = scopes_.rbegin(); it != scopes_.rend(); ++it) {
            auto f = it->find(key);
            if (f != it->end()) return f->second;
        }
        return "";
    }
    void insertExpr(const std::string &key, const std::string &name) {
        scopes_.back()[key] = name;
    }
    static std::string exprKey(const SsaInst &inst) {
        auto opChar = [](TOp op) {
            switch (op) {
            case TOp::Add: return "+";
            case TOp::Sub: return "-";
            case TOp::Mul: return "*";
            case TOp::Div: return "/";
            case TOp::Gt: return ">";
            case TOp::Eq: return "=";
            default: return "?";
            }
        };
        return std::string(opChar(inst.op)) + "(" + inst.a + "," + inst.b + ")";
    }

    SsaProgram prog_;
    const std::vector<std::vector<int>> &adj_;
    const std::vector<std::set<int>> &preds_;
    std::vector<std::map<std::string, std::string>> scopes_;
    std::map<std::string, std::string> vn_;
    VnReport rep_;
};

}  // namespace

VnResult runLVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds) {
    VnEngine eng(ssa, adj, preds);
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        eng.pushScope();
        eng.processBlock(static_cast<int>(b), false);
        eng.popScope();
    }
    VnResult r = eng.finish();
    r.rep.sweeps = 1;
    return r;
}

VnResult runSVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds) {
    VnEngine eng(ssa, adj, preds);
    std::vector<bool> done(ssa.blocks.size(), false);
    // 沿单前驱链递归携带表；多前驱后继进工作表、空表重来（鲸书 Figure 8.12）
    std::vector<int> worklist;
    std::function<void(int)> svnRec = [&](int b) {
        done[b] = true;
        eng.pushScope();
        eng.processBlock(b, false);
        for (int s : adj[b]) {
            if (done[s]) continue;
            if (preds[s].size() == 1) svnRec(s);   // 携带上下文深入
            else worklist.push_back(s);            // 汇合点：外层空表重来
        }
        eng.popScope();
    };
    svnRec(0);
    for (int b : worklist)
        if (!done[b]) {
            done[b] = true;
            eng.pushScope();
            eng.processBlock(b, false);
            eng.popScope();
        }
    VnResult r = eng.finish();
    r.rep.sweeps = 1;
    return r;
}

VnResult runDVNT(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds, const DomInfo &di) {
    VnEngine eng(ssa, adj, preds);
    // 支配树先序：每块开一个 scope，处理完孩子再收（鲸书：先序保证用前先定义）
    std::function<void(int)> walk = [&](int b) {
        eng.pushScope();
        eng.processBlock(b, true);
        for (int c : di.children[b]) walk(c);
        eng.popScope();
    };
    // 扫到不动点：第一轮改写后继 φ 实参后，"两臂同值"的 φ 要第二轮才看得见
    int prev = -1, sweeps = 0;
    for (int s = 0; s < 4; ++s) {
        walk(0);
        ++sweeps;
        int now = eng.removed();
        if (now == prev) break;
        prev = now;
    }
    VnResult r = eng.finish();
    r.rep.sweeps = sweeps;
    return r;
}

}  // namespace tip
```

### 41.8.3 驱动 main.cpp

三档同台、流水打印、解释器对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 41 章驱动：
//   --check FILE：TIP → TAC → 块图 → SSA → 三档值编号（LVN/SVN/DVNT）→
//   各档成绩单与流水 → DVNT 优化后程序 → SSA 解释器前后对账。
#include "svn.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

struct CollectErrorListener : antlr4::BaseErrorListener {
    std::vector<std::string> messages;
    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);
    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);
    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty())
        throw std::runtime_error("词法/语法错误: " + errors.messages.front());
    Parsed p;
    p.ast = tip::buildAst(tree);
    p.bindings = tip::resolveNames(*p.ast);
    if (!p.bindings.errors.empty())
        throw std::runtime_error("名字解析错误: " + p.bindings.errors.front().text);
    return p;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*p.ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    tip::DomInfo di = tip::dominators(adj);
    auto preds = tip::predsOf(adj);

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA（输入）==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    // ---------- 三档值编号 ----------
    tip::VnResult lvn = tip::runLVN(ssa, adj, preds);
    tip::VnResult svn = tip::runSVN(ssa, adj, preds);
    tip::VnResult dvnt = tip::runDVNT(ssa, adj, preds, di);
    std::cout << "== 三档成绩 ==\n";
    std::cout << "  LVN（块内）  : 消除 " << lvn.rep.redundant << " 条冗余\n";
    std::cout << "  SVN（EBB）   : 消除 " << svn.rep.redundant << " 条冗余\n";
    std::cout << "  DVNT（支配树）: 消除 " << dvnt.rep.redundant << " 条冗余 + "
              << dvnt.rep.phiDeleted << " 个无义/重复 φ（" << dvnt.rep.sweeps << " 轮扫描）\n";
    std::cout << "== DVNT 流水 ==\n";
    for (const auto &s : dvnt.rep.notes) std::cout << "  " << s << "\n";

    std::cout << "== DVNT 优化后 ==\n";
    for (size_t b = 0; b < dvnt.prog.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : dvnt.prog.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    // ---------- 解释器对账 ----------
    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::ssaRun(ssa);
    std::vector<int> after = tip::ssaRun(dvnt.prog);
    std::cout << "  原始 outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  优化 outputs:";
    for (int v : after) std::cout << ' ' << v;
    std::cout << "\n  前后一致: " << (before == after ? "yes" : "NO") << "\n";

    bool ok1 = lvn.rep.redundant >= 1 && svn.rep.redundant > lvn.rep.redundant;
    bool ok2 = dvnt.rep.redundant + dvnt.rep.phiDeleted > svn.rep.redundant;
    bool ok3 = before == after;
    bool ok4 = dvnt.rep.phiDeleted >= 1 && dvnt.rep.sweeps >= 2;
    std::cout << "  SVN 比 LVN 多抓跨块冗余: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  DVNT 比 SVN 多抓连接块与 φ: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  优化前后 outputs 相等: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  无义 φ 被删（≥2 轮扫描）: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok && ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
```

### 41.8.4 基座：前端、TAC 家族、支配与 SSA（本地副本）

与第 38 章同源的基座原样拷贝：AST 构建（ast.hpp/ast_build）、符号表
（symtab）、TAC 生成与基本块（tacgen/tacblocks）、支配者（dom，
第 37 章配套）、SSA 构造（ssa，第 38 章配套——含 CHK 支配边界、
φ 插入、版本栈改名与 SSA 解释器 ssaRun）。

```cpp
// file: src/ast.hpp
// AST 定义：AST 是去掉了括号、分号等语法噪音的程序结构。
// 接口自本章起冻结，后续所有分析（名字、CFG、类型、格……）都在此之上工作。
#pragma once

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace tip {

enum class BOp { Add, Sub, Mul, Div, Gt, Eq };

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr {
    int v;
    explicit IntLit(int value) : v(value) {}
};
struct VarRef : Expr {
    std::string name;
    explicit VarRef(std::string n) : name(std::move(n)) {}
};
struct InputE : Expr {};
struct Binop : Expr {
    BOp op;
    std::unique_ptr<Expr> l, r;
    Binop(BOp o, std::unique_ptr<Expr> lhs, std::unique_ptr<Expr> rhs)
        : op(o), l(std::move(lhs)), r(std::move(rhs)) {}
};
struct CallE : Expr {
    std::unique_ptr<Expr> callee;
    std::vector<std::unique_ptr<Expr>> args;
    CallE(std::unique_ptr<Expr> fn, std::vector<std::unique_ptr<Expr>> as)
        : callee(std::move(fn)), args(std::move(as)) {}
};
struct Deref : Expr {
    std::unique_ptr<Expr> e;
    explicit Deref(std::unique_ptr<Expr> p) : e(std::move(p)) {}
};
struct AddrOf : Expr {                       // spa: & Id
    std::string name;
    explicit AddrOf(std::string n) : name(std::move(n)) {}
};
struct AllocE : Expr {
    std::unique_ptr<Expr> e;
    explicit AllocE(std::unique_ptr<Expr> init) : e(std::move(init)) {}
};
struct NullE : Expr {};
struct RecLit : Expr {
    std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
    explicit RecLit(std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fs)
        : fields(std::move(fs)) {}
};
struct FieldA : Expr {
    std::unique_ptr<Expr> e;
    std::string field;
    FieldA(std::unique_ptr<Expr> record, std::string f)
        : e(std::move(record)), field(std::move(f)) {}
};

struct Stmt {
    virtual ~Stmt() = default;
};
// target 只会是 VarRef / FieldA / Deref，文法 lvalue 已限定。
struct AssignS : Stmt {
    std::unique_ptr<Expr> target, value;
    AssignS(std::unique_ptr<Expr> t, std::unique_ptr<Expr> v)
        : target(std::move(t)), value(std::move(v)) {}
};
struct OutputS : Stmt {
    std::unique_ptr<Expr> e;
    explicit OutputS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};
struct IfS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> then, els;
    IfS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> t, std::unique_ptr<Stmt> e)
        : cond(std::move(c)), then(std::move(t)), els(std::move(e)) {}
};
struct WhileS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> body;
    WhileS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> b)
        : cond(std::move(c)), body(std::move(b)) {}
};
struct BlockS : Stmt {
    std::vector<std::unique_ptr<Stmt>> ss;
    explicit BlockS(std::vector<std::unique_ptr<Stmt>> v) : ss(std::move(v)) {}
};
struct ReturnS : Stmt {
    std::unique_ptr<Expr> e;
    explicit ReturnS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};

struct FunDecl {
    std::string name;
    std::vector<std::string> params;
    std::vector<std::string> vars;
    std::unique_ptr<Stmt> body;
    std::unique_ptr<ReturnS> ret;
};

struct ProgramA {
    std::vector<std::unique_ptr<FunDecl>> funs;
};

}  // namespace tip
```

```cpp
// file: src/ast_build.hpp
// AST 构建器：在 ANTLR 生成的 parse-tree 上下文节点上手工递归下降。
// （本工具链 C++ runtime 的 visitor 以 std::any 传值，而 std::any 不能持有
// unique_ptr，因此不使用 visitor 机制：parse-tree 的上下文类本身信息完整，
// 用 dynamic_cast 区分 #标签备选，自己做一次结构化遍历同样直接。）
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "TIPParser.h"
#include "antlr4-runtime.h"
#include "ast.hpp"

namespace tip {

struct AstBuilder {
    std::unique_ptr<ProgramA> build(TIPParser::ProgramContext *tree);

private:
    std::unique_ptr<FunDecl> buildFun(TIPParser::FunctionContext *ctx);
    std::unique_ptr<Expr> buildExpr(TIPParser::ExprContext *ctx);
    std::unique_ptr<Stmt> buildStmt(TIPParser::StmtContext *ctx);
    // lvalue 翻译成赋值目标表达式：VarRef / Deref，可再包一层 FieldA。
    std::unique_ptr<Expr> buildLvalue(TIPParser::LvalueContext *lv);
};

// 便捷入口：parse tree 的 program 节点 -> 完整 AST。
std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree);

}  // namespace tip
```

```cpp
// file: src/ast_build.cpp
#include "ast_build.hpp"

#include <utility>
#include <vector>

namespace tip {

std::unique_ptr<ProgramA> AstBuilder::build(TIPParser::ProgramContext *tree) {
    auto program = std::make_unique<ProgramA>();
    for (auto *fc : tree->function()) program->funs.push_back(buildFun(fc));
    return program;
}

std::unique_ptr<FunDecl> AstBuilder::buildFun(TIPParser::FunctionContext *ctx) {
    auto f = std::make_unique<FunDecl>();
    f->name = ctx->IDENT()->getText();
    if (ctx->params()) {
        for (auto *p : ctx->params()->IDENT()) f->params.push_back(p->getText());
    }
    if (ctx->varDecls()) {
        for (auto *v : ctx->varDecls()->IDENT()) f->vars.push_back(v->getText());
    }

    std::vector<std::unique_ptr<Stmt>> body;
    for (auto *sc : ctx->stmt()) body.push_back(buildStmt(sc));
    f->body = std::make_unique<BlockS>(std::move(body));

    f->ret = std::make_unique<ReturnS>(buildExpr(ctx->expr()));
    return f;
}

std::unique_ptr<Expr> AstBuilder::buildLvalue(TIPParser::LvalueContext *lv) {
    std::unique_ptr<Expr> base;
    std::string field;
    if (auto *d = dynamic_cast<TIPParser::DirectLvalueContext *>(lv)) {
        base = std::make_unique<VarRef>(d->IDENT(0)->getText());
        if (d->IDENT().size() == 2) field = d->IDENT(1)->getText();
    } else {
        auto *p = dynamic_cast<TIPParser::PointerLvalueContext *>(lv);
        base = std::make_unique<Deref>(buildExpr(p->expr()));
        if (p->IDENT()) field = p->IDENT()->getText();
    }
    if (!field.empty())
        return std::make_unique<FieldA>(std::move(base), std::move(field));
    return base;
}

std::unique_ptr<Expr> AstBuilder::buildExpr(TIPParser::ExprContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::IntExprContext *>(ctx))
        return std::make_unique<IntLit>(std::stoi(c->INT()->getText()));
    if (auto *c = dynamic_cast<TIPParser::VarExprContext *>(ctx))
        return std::make_unique<VarRef>(c->IDENT()->getText());
    if (dynamic_cast<TIPParser::InputExprContext *>(ctx))
        return std::make_unique<InputE>();
    if (dynamic_cast<TIPParser::NullExprContext *>(ctx))
        return std::make_unique<NullE>();
    if (auto *c = dynamic_cast<TIPParser::ParenExprContext *>(ctx))
        return buildExpr(c->expr());

    if (auto *c = dynamic_cast<TIPParser::AddExprContext *>(ctx)) {
        const BOp op = c->PLUS() ? BOp::Add : BOp::Sub;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::MulExprContext *>(ctx)) {
        const BOp op = c->STAR() ? BOp::Mul : BOp::Div;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::CmpExprContext *>(ctx)) {
        const BOp op = c->GT() ? BOp::Gt : BOp::Eq;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::NegExprContext *>(ctx)) {
        // TIP 没有负数字面量 token，-E 即 0-E。
        return std::make_unique<Binop>(BOp::Sub, std::make_unique<IntLit>(0),
                                       buildExpr(c->expr()));
    }
    if (auto *c = dynamic_cast<TIPParser::CallExprContext *>(ctx)) {
        std::vector<std::unique_ptr<Expr>> args;
        if (c->args())
            for (auto *a : c->args()->expr()) args.push_back(buildExpr(a));
        return std::make_unique<CallE>(buildExpr(c->expr()), std::move(args));
    }
    if (auto *c = dynamic_cast<TIPParser::FieldExprContext *>(ctx))
        return std::make_unique<FieldA>(buildExpr(c->expr()), c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::DerefExprContext *>(ctx))
        return std::make_unique<Deref>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::AddrExprContext *>(ctx))
        return std::make_unique<AddrOf>(c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::AllocExprContext *>(ctx))
        return std::make_unique<AllocE>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::RecExprContext *>(ctx)) {
        std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
        for (auto *fc : c->field())
            fields.emplace_back(fc->IDENT()->getText(), buildExpr(fc->expr()));
        return std::make_unique<RecLit>(std::move(fields));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<Stmt> AstBuilder::buildStmt(TIPParser::StmtContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::AssignStmtContext *>(ctx))
        return std::make_unique<AssignS>(buildLvalue(c->lvalue()), buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::OutputStmtContext *>(ctx))
        return std::make_unique<OutputS>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::IfStmtContext *>(ctx)) {
        std::unique_ptr<Stmt> els;
        if (c->stmt().size() == 2) els = buildStmt(c->stmt(1));
        return std::make_unique<IfS>(buildExpr(c->expr()), buildStmt(c->stmt(0)),
                                     std::move(els));
    }
    if (auto *c = dynamic_cast<TIPParser::WhileStmtContext *>(ctx))
        return std::make_unique<WhileS>(buildExpr(c->expr()), buildStmt(c->stmt()));
    if (auto *c = dynamic_cast<TIPParser::BlockStmtContext *>(ctx)) {
        std::vector<std::unique_ptr<Stmt>> ss;
        for (auto *sc : c->stmt()) ss.push_back(buildStmt(sc));
        return std::make_unique<BlockS>(std::move(ss));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree) {
    return AstBuilder{}.build(tree);
}

}  // namespace tip
```

```cpp
// file: src/symtab.hpp
// 符号表与名字解析：把 AST 上的每个 VarRef 绑定到它的声明
// （函数 / 参数 / 局部变量），同时产出未声明、重复声明诊断。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Symbol {
    enum Kind { Fun, Param, Local } kind;
    std::string name;
    const FunDecl *fun;          // Fun: 指向自身声明; Param/Local: 指向所属函数
};

struct Scope {
    Scope *parent;
    std::map<std::string, Symbol> table;

    explicit Scope(Scope *p = nullptr) : parent(p) {}
    const Symbol *lookup(const std::string &name) const;
};

struct Diag {
    std::string text;
};

struct Bindings {
    Scope global;                                  // 函数名所在的全局作用域
    // 各函数作用域由 Bindings 持有所有权：uses 中的 Symbol* 才不会悬垂。
    std::vector<std::unique_ptr<Scope>> scopes;
    std::vector<Diag> errors;
    std::map<const VarRef *, const Symbol *> uses;  // 解析成功的使用点
};

// 两遍解析：先注册全部函数名（支持前向调用），再逐函数解析函数体。
Bindings resolveNames(ProgramA &program);

}  // namespace tip
```

```cpp
// file: src/symtab.cpp
#include "symtab.hpp"

#include <utility>

namespace tip {

namespace {

// 解析器在遍历 AST 的同时完成绑定与诊断收集。
struct Resolver {
    Bindings bindings;
    Scope *current = nullptr;
    const FunDecl *owner = nullptr;

    void declare(const std::string &name, Symbol::Kind kind) {
        if (current->table.count(name)) {
            bindings.errors.push_back({"error: redeclared '" + name + "'"});
            return;  // 保留先声明者，后声明被忽略
        }
        current->table.emplace(name, Symbol{kind, name, owner});
    }

    void resolveExpr(const Expr *e) {
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            const Symbol *s = current->lookup(x->name);
            if (!s) {
                bindings.errors.push_back({"error: undeclared '" + x->name + "'"});
            } else {
                bindings.uses[x] = s;
            }
            return;
        }
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            resolveExpr(x->l.get());
            resolveExpr(x->r.get());
            return;
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            resolveExpr(x->callee.get());
            for (const auto &a : x->args) resolveExpr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const AllocE *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            resolveExpr(x->e.get());  // 字段名不是变量，无需解析
            return;
        }
        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &f : x->fields) resolveExpr(f.second.get());
            return;
        }
        // IntLit / InputE / AddrOf / NullE：无变量使用。
    }

    void resolveStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            resolveExpr(x->target.get());
            resolveExpr(x->value.get());
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->then.get());
            if (x->els) resolveStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) resolveStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) return resolveExpr(x->e.get());
    }
};

}  // namespace

const Symbol *Scope::lookup(const std::string &name) const {
    auto it = table.find(name);
    if (it != table.end()) return &it->second;
    return parent ? parent->lookup(name) : nullptr;
}

Bindings resolveNames(ProgramA &program) {
    Resolver resolver;
    resolver.bindings.global = Scope(nullptr);
    Scope *global = &resolver.bindings.global;

    // 第一遍：所有函数名进入全局作用域。
    for (const auto &f : program.funs) {
        if (global->table.count(f->name)) {
            resolver.bindings.errors.push_back({"error: redeclared '" + f->name + "'"});
            continue;
        }
        global->table.emplace(f->name, Symbol{Symbol::Fun, f->name, f.get()});
    }

    // 第二遍：每个函数开自己的作用域，父作用域是全局表；
    // 作用域所有权交给 Bindings，遍历结束后符号依然存活。
    for (const auto &f : program.funs) {
        auto functionScope = std::make_unique<Scope>(global);
        resolver.current = functionScope.get();
        resolver.owner = f.get();

        for (const std::string &p : f->params) resolver.declare(p, Symbol::Param);
        for (const std::string &v : f->vars) resolver.declare(v, Symbol::Local);

        resolver.resolveStmt(f->body.get());
        resolver.resolveStmt(f->ret.get());

        resolver.current = nullptr;
        resolver.bindings.scopes.push_back(std::move(functionScope));
    }
    return std::move(resolver.bindings);
}

}  // namespace tip
```

```cpp
// file: src/tacgen.hpp
// file: src/tacgen.hpp
// 第 16 章配套：AST → 三地址码（TAC）。
// 指令形态取绿龙 §7.6 的四元组风格：
//   x = y          （复制，y 可以是数字字面量）
//   x = y op z     （op ∈ + - * / > ==）
//   t? = input ; output x ; return x
//   if x > y goto L ; if x == y goto L ; goto L
// 布尔值不落地：比较直接嵌在条件跳转里（绿龙 §7.8/7.9 的口径）。
// 每条指令至多一次运算——“三地址”的名字就是这么来的。
#ifndef TIP_TACGEN_HPP
#define TIP_TACGEN_HPP

#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

enum class TOp { Copy, Add, Sub, Mul, Div, Gt, Eq, Input, Output, Ret,
                 Goto, IfGt, IfEq };

struct Quad {
    TOp op;
    std::string dst;    // Copy/Bin/Input 的目的
    std::string a, b;   // 操作数
    int target = -1;    // 跳转目标（TAC 下标；打印为 L<n>）
};

std::string show(const Quad &q);

// 单函数 TAC：把函数体降落到四元组序列。
// 不支持的构造（指针、记录、调用）抛异常并注明去向章节。
std::vector<Quad> tacGen(const FunDecl &fn);

}  // namespace tip

#endif  // TIP_TACGEN_HPP
```

```cpp
// file: src/tacgen.cpp
// file: src/tacgen.cpp
// 第 16 章配套：TAC 生成与打印。
#include "tacgen.hpp"

#include <map>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace tip {

std::string show(const Quad &q) {
    std::ostringstream os;
    switch (q.op) {
    case TOp::Copy:   os << q.dst << " = " << q.a; break;
    case TOp::Add:    os << q.dst << " = " << q.a << " + " << q.b; break;
    case TOp::Sub:    os << q.dst << " = " << q.a << " - " << q.b; break;
    case TOp::Mul:    os << q.dst << " = " << q.a << " * " << q.b; break;
    case TOp::Div:    os << q.dst << " = " << q.a << " / " << q.b; break;
    case TOp::Gt:     os << q.dst << " = " << q.a << " > " << q.b; break;
    case TOp::Eq:     os << q.dst << " = " << q.a << " == " << q.b; break;
    case TOp::Input:  os << q.dst << " = input"; break;
    case TOp::Output: os << "output " << q.a; break;
    case TOp::Ret:    os << "return " << q.a; break;
    case TOp::Goto:   os << "goto L" << q.target; break;
    case TOp::IfGt:   os << "if " << q.a << " > " << q.b << " goto L" << q.target; break;
    case TOp::IfEq:   os << "if " << q.a << " == " << q.b << " goto L" << q.target; break;
    }
    return os.str();
}

namespace {

struct Gen {
    std::vector<Quad> code;
    int tmp = 0, nlabels = 0;
    std::map<int, int> labelHere;               // 标签号 → TAC 下标
    std::vector<std::pair<int, int>> patches;   // (指令下标, 标签号)

    std::string newTmp() { return "t" + std::to_string(++tmp); }
    int newLabel() { return nlabels++; }
    void setLabel(int l) { labelHere[l] = static_cast<int>(code.size()); }
    void emit(Quad q) { code.push_back(std::move(q)); }
    void jump(TOp op, const std::string &a, const std::string &b, int l) {
        patches.emplace_back(static_cast<int>(code.size()), l);
        emit({op, "", a, b, -1});
    }
    void finish() {
        for (const auto &p : patches) code[p.first].target = labelHere.at(p.second);
    }

    [[noreturn]] void unsupported(const char *what, int ch) {
        std::ostringstream os;
        os << "TAC 生成不支持 " << what << "（留待第 " << ch << " 章家族）";
        throw std::runtime_error(os.str());
    }

    // 表达式求值到“地址”：变量名或临时名。常量也先落入临时——
    // 让“每条指令至多一次运算”成为不破的铁律（绿龙 §7.7 的约定）。
    std::string addr(const Expr &e) {
        if (auto *n = dynamic_cast<const IntLit *>(&e)) {
            std::string t = newTmp();
            emit({TOp::Copy, t, std::to_string(n->v), "", -1});
            return t;
        }
        if (auto *v = dynamic_cast<const VarRef *>(&e)) return v->name;
        if (dynamic_cast<const InputE *>(&e)) {
            std::string t = newTmp();
            emit({TOp::Input, t, "", "", -1});
            return t;
        }
        if (auto *b = dynamic_cast<const Binop *>(&e)) {
            std::string l = addr(*b->l), r = addr(*b->r), t = newTmp();
            TOp op = b->op == BOp::Add ? TOp::Add
                    : b->op == BOp::Sub ? TOp::Sub
                    : b->op == BOp::Mul ? TOp::Mul
                    : b->op == BOp::Div ? TOp::Div
                    : b->op == BOp::Gt ? TOp::Gt : TOp::Eq;
            emit({op, t, l, r, -1});
            return t;
        }
        unsupported("该表达式构造（指针/记录/调用）", 42);
    }

    // 条件跳转：比较不落地，直接嵌进跳转（绿龙 §7.9 的控制流翻译）。
    void condJump(const Expr &cond, int target) {
        auto *b = dynamic_cast<const Binop *>(&cond);
        if (!b || (b->op != BOp::Gt && b->op != BOp::Eq))
            unsupported("非常规条件（if/while 条件请用 > 或 ==）", 13);
        std::string l = addr(*b->l), r = addr(*b->r);
        jump(b->op == BOp::Gt ? TOp::IfGt : TOp::IfEq, l, r, target);
    }

    void stmt(const Stmt &s) {
        if (auto *a = dynamic_cast<const AssignS *>(&s)) {
            std::string v = addr(*a->value);
            if (auto *tv = dynamic_cast<const VarRef *>(a->target.get())) {
                emit({TOp::Copy, tv->name, v, "", -1});
            } else {
                unsupported("非变量赋值目标（指针/字段写）", 42);
            }
        } else if (auto *o = dynamic_cast<const OutputS *>(&s)) {
            std::string v = addr(*o->e);
            emit({TOp::Output, "", v, "", -1});
        } else if (auto *i = dynamic_cast<const IfS *>(&s)) {
            // if c then S else S'：
            //   if c goto L_then ; goto L_else ; L_then: S ; goto L_end ;
            //   L_else: S' ; L_end:
            int lThen = newLabel(), lElse = newLabel(), lEnd = newLabel();
            condJump(*i->cond, lThen);
            jump(TOp::Goto, "", "", lElse);
            setLabel(lThen);
            stmt(*i->then);
            jump(TOp::Goto, "", "", lEnd);
            setLabel(lElse);
            if (i->els) stmt(*i->els);
            setLabel(lEnd);
        } else if (auto *w = dynamic_cast<const WhileS *>(&s)) {
            // L_head: if c goto L_body ; goto L_end ; L_body: S ;
            // goto L_head ; L_end:
            int lHead = newLabel(), lBody = newLabel(), lEnd = newLabel();
            setLabel(lHead);
            condJump(*w->cond, lBody);
            jump(TOp::Goto, "", "", lEnd);
            setLabel(lBody);
            stmt(*w->body);
            jump(TOp::Goto, "", "", lHead);
            setLabel(lEnd);
        } else if (auto *blk = dynamic_cast<const BlockS *>(&s)) {
            for (const auto &st : blk->ss) stmt(*st);
        } else if (auto *r = dynamic_cast<const ReturnS *>(&s)) {
            std::string v = addr(*r->e);
            emit({TOp::Ret, "", v, "", -1});
        } else {
            unsupported("未知语句", 42);
        }
    }
};

}  // namespace

std::vector<Quad> tacGen(const FunDecl &fn) {
    Gen g;
    g.stmt(*fn.body);
    g.stmt(*fn.ret);
    g.finish();
    return g.code;
}

}  // namespace tip
```

```cpp
// file: src/tacblocks.hpp
// file: src/tacblocks.hpp
// 第 16 章配套：leader 划分基本块 + 块内 next-use 信息。
// 两条规则都出自绿龙 §7.9 / 紫 §8.4 的经典表述：
//   leader = 首指令 | 跳转目标 | 跳转的下一指令；
//   next-use = 块内反向一趟，写 kills、读 gens。
#ifndef TIP_TACBLOCKS_HPP
#define TIP_TACBLOCKS_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"

namespace tip {

struct Block {
    int id;
    int begin, end;   // [begin, end) 的 TAC 下标
    std::set<int> succs;
};

// 基本块划分 + 后继表（后继由块尾跳转/顺序落入决定）。
std::vector<Block> partitionBlocks(const std::vector<Quad> &code);

// next-use：tac[i] 处变量 v 的下一次使用下标（块内），无则 -1。
// 返回 map[(i, var)] -> 下标。
std::map<std::pair<int, std::string>, int> nextUse(const std::vector<Quad> &code,
                                                   const Block &b);

}  // namespace tip

#endif  // TIP_TACBLOCKS_HPP
```

```cpp
// file: src/tacblocks.cpp
// file: src/tacblocks.cpp
// 第 16 章配套：leader 划分与 next-use。
#include "tacblocks.hpp"

#include <algorithm>

namespace tip {

namespace {
bool isJump(const Quad &q) {
    return q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq;
}
}  // namespace

std::vector<Block> partitionBlocks(const std::vector<Quad> &code) {
    // leader 三规则（绿龙 §7.9）：
    //   1) 首指令；2) 跳转目标；3) 紧跟跳转的指令。
    std::vector<bool> leader(code.size(), false);
    if (!code.empty()) leader[0] = true;
    for (size_t i = 0; i < code.size(); ++i) {
        if (isJump(code[i])) {
            leader[code[i].target] = true;
            if (i + 1 < code.size()) leader[i + 1] = true;
        }
    }
    std::vector<int> heads;
    for (size_t i = 0; i < code.size(); ++i)
        if (leader[i]) heads.push_back(static_cast<int>(i));
    std::vector<Block> blocks;
    for (size_t k = 0; k < heads.size(); ++k) {
        int b = heads[k];
        int e = (k + 1 < heads.size()) ? heads[k + 1] : static_cast<int>(code.size());
        Block blk{static_cast<int>(k), b, e, {}};
        const Quad &last = code[e - 1];
        if (last.op == TOp::Goto) {
            blk.succs.insert(last.target);
        } else if (last.op == TOp::IfGt || last.op == TOp::IfEq) {
            blk.succs.insert(last.target);
            if (e < static_cast<int>(code.size())) blk.succs.insert(e);
        } else if (e < static_cast<int>(code.size())) {
            blk.succs.insert(e);
        }
        blocks.push_back(blk);
    }
    return blocks;
}

// 块内反向一趟（紫龙 §8.4.2 的 next-use 算法）：
// 读操作数：把“它下一次被用的行”记在当前行，然后登记自己；
// 写目的：先记当前信息，再清空（重定义使旧信息失效）。
std::map<std::pair<int, std::string>, int> nextUse(const std::vector<Quad> &code,
                                                   const Block &b) {
    std::map<std::string, int> nu;   // 变量 → 下一次使用的行号
    std::map<std::pair<int, std::string>, int> out;
    auto reads = [](const Quad &q) {
        std::vector<std::string> r;
        switch (q.op) {
        case TOp::Copy:
        case TOp::Output:
        case TOp::Ret:
            if (!q.a.empty() && !isdigit(q.a[0])) r.push_back(q.a);
            break;
        case TOp::Add: case TOp::Sub: case TOp::Mul:
        case TOp::Div: case TOp::Gt: case TOp::Eq:
        case TOp::IfGt: case TOp::IfEq:
            for (const std::string &s : {q.a, q.b})
                if (!s.empty() && !isdigit(s[0])) r.push_back(s);
            break;
        default: break;
        }
        return r;
    };
    auto isDigitStr = [](const std::string &s) {
        return !s.empty() && isdigit(s[0]);
    };
    for (int i = b.end - 1; i >= b.begin; --i) {
        const Quad &q = code[i];
        for (const auto &v : reads(q))
            out[{i, v}] = nu.count(v) ? nu[v] : -1;
        // 定义处也登记：被定义变量“在此之后”的下一使用——
        // 它是“结果占着寄存器值不值”的判据（紫龙 §8.4.2 的完整口径）。
        if (!q.dst.empty() && !isDigitStr(q.dst))
            out[{i, q.dst}] = nu.count(q.dst) ? nu[q.dst] : -1;
        if (!q.dst.empty() && !isDigitStr(q.dst))
            nu[q.dst] = -1;   // 定义即清空
        for (const auto &v : reads(q))
            nu[v] = i;        // 本次使用登记
    }
    return out;
}

}  // namespace tip
```

```cpp
// file: src/dom.hpp
// file: src/dom.hpp
// 第 37 章配套之一：支配者（dominators）与支配树。
// dom[b] = { d | 每条 entry→b 的路径都经过 d }——
// 迭代方程：dom[entry]={entry}；dom[b]={b} ∪ ∩ dom[pred]。
// 这是“从全集出发、单调收缩”的不动点（与 may 分析方向相反的镜像）。
#ifndef TIP_DOM_HPP
#define TIP_DOM_HPP

#include <map>
#include <set>
#include <vector>


namespace tip {

struct DomInfo {
    std::vector<std::set<int>> dom;      // 每块（块号）的支配集
    std::vector<int> idom;               // 直接支配者（-1 = 无/入口）
    std::vector<std::vector<int>> children;   // 支配树孩子表
};

// 前驱表（邻接表反推）。
std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj);

DomInfo dominators(const std::vector<std::vector<int>> &adj);

// 自检：由支配树推导的支配集 == 迭代解（idom 唯一性的机器验证）。
bool domTreeCheck(const DomInfo &di);

}  // namespace tip

#endif  // TIP_DOM_HPP
```

```cpp
// file: src/dom.cpp
// file: src/dom.cpp
// 第 37 章配套：支配者实现。
#include "dom.hpp"

namespace tip {

std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    std::vector<std::set<int>> preds(n);
    for (size_t q = 0; q < n; ++q)
        for (int s : adj[q]) preds[s].insert(static_cast<int>(q));
    return preds;
}

DomInfo dominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    DomInfo di;
    // 初值：入口只含自己，其余从全集出发（“人人可能支配”，逐步证伪）。
    std::set<int> all;
    for (size_t k = 0; k < n; ++k) all.insert(static_cast<int>(k));
    di.dom.assign(n, all);
    if (n > 0) di.dom[0] = {0};
    auto preds = predsOf(adj);
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 1; b < n; ++b) {
            std::set<int> acc = all;
            bool hasPred = false;
            for (int p : preds[b]) {
                std::set<int> keep;
                for (int x : acc)
                    if (di.dom[p].count(x)) keep.insert(x);
                acc = keep;
                hasPred = true;
            }
            acc.insert(static_cast<int>(b));
            if (!hasPred) acc = {static_cast<int>(b)};   // 不可达块：只支配自己
            if (acc != di.dom[b]) {
                di.dom[b] = acc;
                changed = true;
            }
        }
    }
    // idom：b 的严格支配者中，支配集最大（最靠近 b）的那个。
    di.idom.assign(n, -1);
    for (size_t b = 1; b < n; ++b) {
        int best = -1;
        size_t bestSize = 0;
        for (int d : di.dom[b]) {
            if (d == static_cast<int>(b)) continue;
            if (di.dom[d].size() >= bestSize) {
                bestSize = di.dom[d].size();
                best = d;
            }
        }
        di.idom[b] = best;
    }
    // 支配树
    di.children.assign(n, {});
    for (size_t b = 1; b < n; ++b)
        if (di.idom[b] >= 0) di.children[di.idom[b]].push_back(static_cast<int>(b));
    return di;
}

bool domTreeCheck(const DomInfo &di) {
    size_t n = di.dom.size();
    // 由树推导支配集：dom'(b) = 路径上祖先 ∪ {b}
    std::vector<std::set<int>> fromTree(n);
    for (size_t b = 0; b < n; ++b) {
        std::set<int> s = {static_cast<int>(b)};
        int cur = di.idom[b];
        while (cur >= 0) {
            s.insert(cur);
            cur = di.idom[cur];
        }
        fromTree[b] = s;
    }
    for (size_t b = 0; b < n; ++b)
        if (fromTree[b] != di.dom[b]) return false;
    return true;
}

}  // namespace tip
```

```cpp
// file: src/ssa.hpp
// file: src/ssa.hpp
// 第 38 章配套：支配边界（CHK）、φ 插入、支配树改名——SSA 构造全套。
#ifndef TIP_SSA_HPP
#define TIP_SSA_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"

namespace tip {

// ---------- 支配边界（Cooper–Harvey–Kennedy） ----------
// DF[b] = { c | b 支配 c 的某个前驱，但 b 不严格支配 c }。
// 直觉：“b 的影响沿支配树下行，DF 是它‘管不到’却‘够得着’的汇合点”。
std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds);

// ---------- SSA ----------
struct SsaInst {
    TOp op = TOp::Copy;
    std::string dst, a, b;
    int target = -1;                    // 跳转目标 = 块号
    std::vector<std::string> phiArgs;   // φ 专用：按前驱次序的实参
};

struct SsaBlock {
    std::vector<SsaInst> body;          // φ 在最前
};

struct SsaProgram {
    std::vector<SsaBlock> blocks;
    std::vector<std::vector<int>> preds;   // 每块前驱（块号，定序）
};

// 构造：φ 插入（iterated DF 的不动点）+ 支配树先序改名（版本栈）。
// 单定值自检：每个 SSA 名字恰好定义一次（返回 false 即违例）。
SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk);

std::string show(const SsaInst &q);

// ---------- SSA 解释器（对账证人） ----------
std::vector<int> ssaRun(const SsaProgram &p);

}  // namespace tip

#endif  // TIP_SSA_HPP
```

```cpp
// file: src/ssa.cpp
// file: src/ssa.cpp
// 第 38 章配套：SSA 构造与解释实现。
#include "ssa.hpp"

#include <cctype>
#include <deque>
#include <functional>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNumS(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarS(const std::string &s) { return !s.empty() && !isNumS(s); }
bool defInstrS(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds) {
    size_t n = adj.size();
    std::vector<std::set<int>> df(n);
    // CHK：只看汇合点（前驱 ≥ 2）。runner 从每个前驱沿 idom 上行，
    // 直到碰到 idom[c]——沿途每站都把 c 记入 DF。
    for (size_t c = 0; c < n; ++c) {
        if (preds[c].size() < 2) continue;
        for (int p : preds[c]) {
            int runner = p;
            while (runner >= 0 && runner != di.idom[c]) {
                df[runner].insert(static_cast<int>(c));
                runner = di.idom[runner];
            }
        }
    }
    return df;
}

std::string show(const SsaInst &q) {
    std::ostringstream os;
    if (!q.phiArgs.empty()) {
        os << q.dst << " = phi(";
        for (size_t k = 0; k < q.phiArgs.size(); ++k)
            os << (k ? ", " : "") << q.phiArgs[k];
        os << ")";
        return os.str();
    }
    switch (q.op) {
    case TOp::Copy:   os << q.dst << " = " << q.a; break;
    case TOp::Add:    os << q.dst << " = " << q.a << " + " << q.b; break;
    case TOp::Sub:    os << q.dst << " = " << q.a << " - " << q.b; break;
    case TOp::Mul:    os << q.dst << " = " << q.a << " * " << q.b; break;
    case TOp::Div:    os << q.dst << " = " << q.a << " / " << q.b; break;
    case TOp::Gt:     os << q.dst << " = " << q.a << " > " << q.b; break;
    case TOp::Eq:     os << q.dst << " = " << q.a << " == " << q.b; break;
    case TOp::Output: os << "output " << q.a; break;
    case TOp::Ret:    os << "return " << q.a; break;
    case TOp::Goto:   os << "goto B" << q.target; break;
    case TOp::IfGt:   os << "if " << q.a << " > " << q.b << " goto B" << q.target; break;
    case TOp::IfEq:   os << "if " << q.a << " == " << q.b << " goto B" << q.target; break;
    case TOp::Input:  os << q.dst << " = input"; break;
    }
    return os.str();
}

SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk) {
    size_t n = blocks.size();
    // 块邻接与前驱（定序）
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    std::vector<std::vector<int>> preds(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : adj[b]) preds[s].push_back(static_cast<int>(b));

    DomInfo di = dominators(adj);
    auto predsSet = predsOf(adj);
    std::vector<std::set<int>> df = dominanceFrontiers(adj, di, predsSet);

    // ---------- φ 插入 ----------
    // 变量 → 定值块集合；iterated DF 的不动点；φ 挂块头。
    std::map<std::string, std::set<int>> defBlocks;
    std::set<std::string> vars;
    for (const auto &q : code) {
        if (isVarS(q.dst)) vars.insert(q.dst);
        if (isVarS(q.a)) vars.insert(q.a);
        if (isVarS(q.b)) vars.insert(q.b);
    }
    for (int i = 0; i < static_cast<int>(code.size()); ++i)
        if (defInstrS(code[i]) && isVarS(code[i].dst))
            for (size_t b = 0; b < n; ++b)
                if (i >= blocks[b].begin && i < blocks[b].end)
                    defBlocks[code[i].dst].insert(static_cast<int>(b));
    std::map<std::pair<int, std::string>, bool> hasPhi;   // (块, 变量)
    for (const auto &v : vars) {
        std::deque<int> work(defBlocks[v].begin(), defBlocks[v].end());
        std::set<int> enqueued(work.begin(), work.end());
        while (!work.empty()) {
            int b = work.front();
            work.pop_front();
            for (int c : df[b]) {
                if (!hasPhi[{c, v}]) {
                    hasPhi[{c, v}] = true;
                    if (!enqueued.count(c)) {
                        enqueued.insert(c);
                        work.push_back(c);   // φ 本身是新定值，其 DF 也要传播
                    }
                }
            }
        }
    }

    // ---------- 改名（支配树先序 + 版本栈） ----------
    std::map<std::string, int> counter;          // 变量 → 下一版本号
    std::map<std::string, std::vector<std::string>> stack;   // 变量 → 版本名栈
    auto freshName = [&](const std::string &v) {
        int k = counter[v]++;
        std::string name = v + std::to_string(k);
        stack[v].push_back(name);
        return name;
    };
    auto curName = [&](const std::string &v) -> std::string {
        auto it = stack.find(v);
        if (it == stack.end() || it->second.empty()) return v + "u";   // u = 未定义（⊥）
        return it->second.back();
    };
    SsaProgram out;
    out.blocks.resize(n);
    out.preds = preds;

    // 先给每块的 φ 占位（目标名先定，实参改名时回填）
    std::map<std::pair<int, std::string>, size_t> phiSlot;
    for (size_t b = 0; b < n; ++b)
        for (const auto &v : vars)
            if (hasPhi[{static_cast<int>(b), v}]) {
                SsaInst phi;
                phi.dst = v + "#phi";   // 临时占位，改名时替换
                out.blocks[b].body.push_back(phi);
                phiSlot[{static_cast<int>(b), v}] = out.blocks[b].body.size() - 1;
            }

    std::function<void(int)> renameBlock = [&](int b) {
        std::vector<std::string> pushed;   // 本块压栈的名字（离开时弹出）
        // φ 目标先改名（φ 是本块第一条“定值”）
        for (const auto &v : vars)
            if (hasPhi[{b, v}]) {
                size_t slot = phiSlot.at({b, v});
                out.blocks[b].body[slot].dst = freshName(v);
                pushed.push_back(v);
            }
        auto renameUse = [&](std::string &x) {
            if (isVarS(x)) x = curName(x);
        };
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            SsaInst si;
            si.op = code[i].op;
            si.a = code[i].a;
            si.b = code[i].b;
            si.dst = code[i].dst;
            si.target = code[i].target;
            renameUse(si.a);
            renameUse(si.b);
            if (defInstrS(code[i]) && isVarS(si.dst)) {
                si.dst = freshName(si.dst);
                pushed.push_back(code[i].dst);
            }
            // 跳转目标换块号
            if (si.op == TOp::Goto || si.op == TOp::IfGt || si.op == TOp::IfEq)
                for (size_t k = 0; k < n; ++k)
                    if (si.target == blocks[k].begin) si.target = static_cast<int>(k);
            out.blocks[b].body.push_back(si);
        }
        // 给后继的 φ 填实参：沿本块在后继前驱表中的位置
        for (int s : adj[b])
            for (const auto &v : vars)
                if (hasPhi[{s, v}]) {
                    size_t slot = phiSlot.at({s, v});
                    size_t pos = 0;
                    for (size_t k = 0; k < preds[s].size(); ++k)
                        if (preds[s][k] == b) { pos = k; break; }
                    while (out.blocks[s].body[slot].phiArgs.size() < preds[s].size())
                        out.blocks[s].body[slot].phiArgs.push_back(v + "u");
                    out.blocks[s].body[slot].phiArgs[pos] = curName(v);
                }
        // 支配树孩子先序递归
        for (int c : di.children[b]) renameBlock(c);
        for (auto it = pushed.rbegin(); it != pushed.rend(); ++it)
            stack[*it].pop_back();
    };
    renameBlock(0);

    // ---------- 单定值自检 ----------
    singleDefOk = true;
    std::map<std::string, int> defs;
    for (const auto &blk : out.blocks)
        for (const auto &inst : blk.body) {
            if (!inst.dst.empty()) defs[inst.dst]++;
            for (const auto &arg : inst.phiArgs)
                if (arg.empty()) singleDefOk = false;
        }
    for (const auto &kv : defs)
        if (kv.second > 1) singleDefOk = false;
    return out;
}

std::vector<int> ssaRun(const SsaProgram &p) {
    std::vector<int> outputs;
    std::map<std::string, int> env;
    auto rd = [&](const std::string &s) -> int {
        if (isNumS(s)) return std::atoi(s.c_str());
        if (!s.empty() && s.back() == 'u')
            return 0;   // 未定值名（改名器的 ⊥ 记号）：按全 0 初值口径（第 65 章同款）
        auto it = env.find(s);
        if (it == env.end()) throw std::runtime_error("SSA 读未定义 " + s);
        return it->second;
    };
    int b = 0;
    int from = -1;
    int guard = 0;
    while (b >= 0 && b < static_cast<int>(p.blocks.size())) {
        if (++guard > 100000) throw std::runtime_error("SSA 解释超步数");
        const SsaBlock &blk = p.blocks[b];
        // φ：并行语义——先取全部实参再赋值（SSA 名字互不相同，顺序亦同，
        // 但按定义写成两段，正文 33.3 讲原因）
        std::vector<std::pair<std::string, int>> phiVals;
        for (const auto &inst : blk.body) {
            if (inst.phiArgs.empty()) continue;
            if (from < 0) continue;   // 入口块没有前驱，φ 不该有实参
            size_t pos = 0;
            for (size_t k = 0; k < p.preds[b].size(); ++k)
                if (p.preds[b][k] == from) { pos = k; break; }
            phiVals.push_back({inst.dst, rd(inst.phiArgs[pos])});
        }
        for (const auto &kv : phiVals) env[kv.first] = kv.second;
        int next = -1;
        int nextFrom = b;
        for (const auto &inst : blk.body) {
            if (!inst.phiArgs.empty()) continue;   // φ 已在入块时并行处理
            switch (inst.op) {
            case TOp::Copy:  env[inst.dst] = rd(inst.a); break;
            case TOp::Add:   env[inst.dst] = rd(inst.a) + rd(inst.b); break;
            case TOp::Sub:   env[inst.dst] = rd(inst.a) - rd(inst.b); break;
            case TOp::Mul:   env[inst.dst] = rd(inst.a) * rd(inst.b); break;
            case TOp::Div:   env[inst.dst] = rd(inst.a) / rd(inst.b); break;
            case TOp::Gt:    env[inst.dst] = rd(inst.a) > rd(inst.b) ? 1 : 0; break;
            case TOp::Eq:    env[inst.dst] = rd(inst.a) == rd(inst.b) ? 1 : 0; break;
            case TOp::Input: throw std::runtime_error("示例程序不含 input");
            case TOp::Output: outputs.push_back(rd(inst.a)); break;
            case TOp::Ret:    return outputs;
            case TOp::Goto:   next = inst.target; break;
            case TOp::IfGt:   next = rd(inst.a) > rd(inst.b) ? inst.target : -1; break;
            case TOp::IfEq:   next = rd(inst.a) == rd(inst.b) ? inst.target : -1; break;
            }
            if (next != -1) break;
        }
        if (next == -1) next = b + 1;
        b = next;
        from = nextFrom;
    }
    return outputs;
}

}  // namespace tip
```


### 41.8.5 程序与期望输出

```text
// file: programs/vn.tip
main() {
  var a, b, c, d, m, n, u, q, r, t, v, z;
  a = 11;
  b = 4;
  c = 9;
  d = 2;
  m = a + b;
  n = a + b;
  u = c + d;
  if (a > b) {
    r = c + d;
    t = a + b;
    output n;
  } else {
    q = a + b;
    t = a + b;
    output q;
  }
  v = a + b;
  z = c + d;
  output v;
  output z;
  output t;
  return 0;
}
```

```text
; expected: expected/output.txt
== vn.tip ==
== SSA（输入）==
  B0:
    t10 = 11
    a0 = t10
    t20 = 4
    b0 = t20
    t30 = 9
    c0 = t30
    t40 = 2
    d0 = t40
    t50 = a0 + b0
    m0 = t50
    t60 = a0 + b0
    n0 = t60
    t70 = c0 + d0
    u0 = t70
    if a0 > b0 goto B2
  B1:
    goto B3
  B2:
    t80 = c0 + d0
    r0 = t80
    t90 = a0 + b0
    t1 = t90
    output n0
    goto B4
  B3:
    t100 = a0 + b0
    q0 = t100
    t110 = a0 + b0
    t0 = t110
    output q0
  B4:
    q1 = phi(qu, q0)
    r1 = phi(r0, ru)
    t2 = phi(t1, t0)
    t101 = phi(t10u, t100)
    t111 = phi(t11u, t110)
    t81 = phi(t80, t8u)
    t91 = phi(t90, t9u)
    t120 = a0 + b0
    v0 = t120
    t130 = c0 + d0
    z0 = t130
    output v0
    output z0
    output t2
    t140 = 0
    return t140
== 三档成绩 ==
  LVN（块内）  : 消除 2 条冗余
  SVN（EBB）   : 消除 5 条冗余
  DVNT（支配树）: 消除 7 条冗余 + 1 个无义/重复 φ（2 轮扫描）
== DVNT 流水 ==
  B0: t60 复用 t50
  B3: t100 复用 t50
  B3: t110 复用 t50
  B2: t80 复用 t70
  B2: t90 复用 t50
  B4: t2 = φ(...) 无义，并入 t50
  B4: t120 复用 t50
  B4: t130 复用 t70
== DVNT 优化后 ==
  B0:
    t10 = 11
    a0 = 11
    t20 = 4
    b0 = 4
    t30 = 9
    c0 = 9
    t40 = 2
    d0 = 2
    t50 = 11 + 4
    m0 = t50
    n0 = t50
    t70 = 9 + 2
    u0 = t70
    if 11 > 4 goto B2
  B1:
    goto B3
  B2:
    r0 = t70
    t1 = t50
    output t50
    goto B4
  B3:
    q0 = t50
    t0 = t50
    output t50
  B4:
    q1 = phi(qu, t50)
    r1 = phi(t70, ru)
    t101 = phi(t10u, t50)
    t111 = phi(t11u, t50)
    t81 = phi(t70, t8u)
    t91 = phi(t50, t9u)
    v0 = t50
    z0 = t70
    output t50
    output t70
    output t50
    t140 = 0
    return 0
== 对账 ==
  原始 outputs: 15 15 11 15
  优化 outputs: 15 15 11 15
  前后一致: yes
  SVN 比 LVN 多抓跨块冗余: yes
  DVNT 比 SVN 多抓连接块与 φ: yes
  优化前后 outputs 相等: yes
  无义 φ 被删（≥2 轮扫描）: yes
```

## 41.9 小结与练习

本章把
值编号
从块内
推到
过程内：

- EBB
  给了
  "携带
  上下文"
  的
  安全
  边界，
  作用域化
  散列表
  给了
  高效的
  带上/撤下；
- 支配树
  把
  边界
  推到
  汇合块：
  能用
  的
  事实
  恰是
  支配者
  算过的
  事实；
- SSA
  的
  单定值
  让
  撤销
  天然
  正确、
  让
  φ 的
  三判
  （无义/
  重复/
  新值）
  成为
  新的
  优化面；
- DVNT
  与
  PRE
  是
  值身份
  与
  名字身份
  的
  双璧，
  工程
  上
  先
  值后名
  串联
  使用。

下一章
（40）
把
火力
对准
循环：
preheader
与
外提。

练习：

1. 给
   `exprKey`
   接上
   第 40 章
   的
   代数
   恒等式
   （x+0=x、
   x×1=x、
   交换律
   排序
   操作数），
   构造
   一个
   `a+b`
   与
   `b+a`
   同块
   出现的
   程序，
   验证
   三档
   计数
   变化。
2. 把
   SVN 的
   EBB
   换成
   **跟踪**
   （trace，
   第 18 章
   的
   顺直
   块链，
   允许
   经
   分支
   进入）：
   跟踪上
   的
   值编号
   还
   安全吗？
   给出
   反例
   或
   证明。
   （提示：
   跟踪
   不保证
   前缀
   全路径
   执行——
   需要
   补偿
   代码，
   这正是
   虎书
   跟踪调度
   的
   书挡。）
3. 实现
   鲸书
   复习题
   10.5.2-2：
   构造
   一个
   LCM
   能消
   而
   DVNT
   不能
   的
   部分冗余
   （一条
   路径
   上
   算过、
   另一条
   没有），
   用
   第 44 章
   的
   PRE
   与
   本章
   DVNT
   分别
   跑，
   对照
   计数。
4. 把
   DVNT 的
   φ 实参
   改写
   从
   "后继
   改写+
   多轮"
   改成
   SSA 图上
   的
   **自底
   向上
   哈希**
   （对
   每个
   结点
   计算
   递归
   哈希
   键，
   φ 键 =
   "φ"+
   实参
   哈希），
   一遍
   完成
   并
   对比
   两版
   的
   删除
   集合
   是否
   相同。
5. 我们的
   buildSsa
   对
   单臂
   定义
   的
   名字
   也
   插
   φ
   （占位
   实参
   qu/ru）。
   改造
   SSA
   构造：
   只对
   "汇合点
   处
   仍有
   活跃
   使用"
   的
   名字
   插
   φ
   （半
   剪枝
   SSA），
   观察
   期望
   输出
   里
   保守
   φ
   的
   减少。
