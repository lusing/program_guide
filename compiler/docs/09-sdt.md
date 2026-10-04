# 第 9 章　语法制导翻译：属性文法与翻译方案

## 9.1 问题：语法结构上怎么“挂”计算

第 6、7 章结束时，
语法分析能回答
“这串 token 合不合法”，
并留下推导或分析树。
但编译器要的不是判决书，
是**翻译**：
识别出结构的瞬间，
顺手算出点东西——
表达式的值、
声明的偏移、
代码片段。
第 8 章的 ast_build
用访问者模式做这件事：
走到哪个节点，
就执行哪段建树代码。

本章给这个“顺手”
一个正式的名字和一套完整的理论：
**语法制导翻译**
（syntax-directed translation）。
核心思想只有一句：

> 计算附着在文法符号的**属性**上，
> 属性怎么算由附着在产生式上的
> **语义规则**说了算。

属性文法一写下来，
“翻译什么”与“何时翻译”
就分了家：
前者是规则表（声明式数据），
后者是求值顺序（可以机械推导）。
这个分离正是它能被分析、
被优化、被教学的原因。

材料取自绿龙第 7 章
与紫龙第 5 章，
定义、例子、反例全部自包含。
配套示例 `examples/09_sdt`
实现了一个通用的
SDD 求值引擎
（依赖图 + 拓扑排序），
并在两个属性文法上跑通：
表达式求值与后缀生成、
声明块偏移布局。

## 9.2 SDD：文法 + 语义规则

**语法制导定义**
（SDD，syntax-directed definition）
= 上下文无关文法 +
一张规则表：
每条产生式旁边挂着
若干条语义规则，
每条规则定义一个属性。

紫龙的开场例子是
桌面计算器
（Fig 5.1，规则表完整转写）：

```
产生式                语义规则
L → E n              L.val = E.val
E → E1 + T           E.val = E1.val + T.val
E → T                E.val = T.val
T → T1 * F           T.val = T1.val * F.val
T → F                T.val = F.val
F → ( E )            F.val = E.val
F → digit            F.val = digit.lexval
```

属性分两类：

- **综合属性**
  （synthesized）：
  在**产生式头部**的符号上定义，
  值来自产生式**体部**符号的属性——
  信息**从叶往根**流；
- **继承属性**
  （inherited）：
  在产生式**体部**的符号上定义，
  值可以来自头部符号、
  也可以来自体部里**更靠左**的符号——
  信息**从根往叶、从左往右**流。

上表全是综合属性。
终端符号的属性
（digit.lexval）
不由规则定义，
由词法器直接供给——
它是依赖图里的“种子”，
一切计算从这里起跑。

只含综合属性的 SDD
叫 **S-属性**（S-attributed）。
S-属性 SDD 天然配
自底向上分析：
每次归约时，
右部符号的属性
都已在栈上算好，
弹出时顺手算出
左部符号的属性。
yacc 把规则写成
归约动作，
就是这个形状。

把规则应用到具体分析树的
每个节点上，
算出全部属性值，
得到**注释分析树**
（annotated parse tree）。
紫龙对 `3 * 5 + 4 n`
的注释树给出
`L.val = 19`——
本章示例的输出
将一字不差地复现这个 19。

## 9.3 继承属性：当树形与语义错位

继承属性什么时候需要？
当分析树的形状
与源代码的抽象结构**对不上**时。

紫龙的经典场景
（Fig 5.4）：
为配合自顶向下分析，
文法被改写成右递归：

```
T → F T'
T' → * F T'1
T' → ε
F → digit
```

对输入 `3 * 5`：
左操作数 3 长在 F 子树里，
乘号却长在 T' 子树里——
“谁乘谁”被文法拆散了。
解法：
给 T' 一个**继承属性 inh**
（从左边接过已积累的左操作数）
和一个**综合属性 syn**
（把最终结果送回根上）：

```
产生式              语义规则
T → F T'           T'.inh = F.val ; T.val = T'.syn
T' → * F T'1       T'1.inh = T'.inh × F.val ; T'.syn = T'1.syn
T' → ε             T'.syn = T'.inh
F → digit          F.val = digit.lexval
```

对 `3 * 5` 的求值全程
（紫龙 Fig 5.5 的走读）：
F.val=3 沿"inh"传入
T'.inh=3；
遇到 \* 5，
T'1.inh = 3 × 5 = 15；
到 ε 时 syn 原样返回，
15 一路 syn 回 T.val。
**继承属性从左到右穿针，
综合属性从叶到根引线**——
一条链上两根线，
把错位的树重新缝起来。

本章示例的表达式 SDD
把这个模式扩展到
`+` 与 `*` 两层
（expr/expr' 与 term/term'），
并同时线程化两个属性：
数值 val 与后缀串 post。
对 `3 * 5 + 4` 的输出：

```
expr  post=3 5 * 4 +  val=19
```

树根的 19 与紫龙 Fig 5.3
同一数字；
post 是同一棵树上的
第二条引线。

## 9.4 依赖图与求值序

规则表写好了，
按什么顺序算？
**依赖图**
（dependency graph）
把答案画出来：

- 分析树上每个符号的
  每个属性，
  是依赖图的一个节点；
- 语义规则
  `A.b = f(X.c, …)`
  在**每个应用该产生式的节点处**
  产生一条边 X.c → A.b
  ——注意是"依赖"不是"相等"：
  `F.val = digit.lexval`
  也画一条边。

对含继承属性的规则，
边同样从源指向目标，
只是源可能在父节点
或左兄弟节点上。

属性实例的任何**拓扑序**
都是合法求值序。
拓扑序存在
⟺ 依赖图无环。
环长什么样？
紫龙的反例：

```
A → B     A.s = B.i ; B.i = A.s + 1
```

A.s 依赖 B.i，
B.i 又依赖 A.s——
谁也算不出来。
本章示例的
“circular demo”段
把这个反例跑给机器看：

```
acyclic = no (attrs=2 edges=2 topo=0)
stuck: A.s
stuck: B.i
```

topo=0：
拓扑排序一步没走，
两个属性原地互锁。
更狠的是紫龙脚注的断言：
**判断一个 SDD 是否
对某棵树产生循环依赖
是多项式可解的，
但判断它对所有树
都不产生循环，
是指数时间的**。
工程上的出路
不是判环，
而是把 SDD 限制在
天然无环的子类里——
这正是下一节的两位主角。

## 9.5 S-属性与 L-属性：两个够用的子类

**S-属性**：
只有综合属性。
任何自底向上的顺序
（如对分析树的后序遍历）
都是合法求值序。
配 LR 分析器：
归约即求值，
一遍完成。

**L-属性**
（L-attributed）：
每个继承属性只依赖
①产生式头部符号的继承属性，
②**左边的**兄弟符号的属性。
名字里的 L =
信息从**左**向右流。
配深度优先、从左到右的
分析树遍历：
访问节点前算好它的继承属性
（父节点带来、左兄弟递来），
离开节点前算好
它的综合属性——
同样一遍完成。

L-属性覆盖了实践中
几乎全部翻译需求，
而且它恰好是
**递归下降/访问者**的形状：
进入函数时
形参（继承属性）已就位，
return 之前
返回值（综合属性）已算好。
第 8 章 ast_build 的
每个 visit 函数
都是一台 L-属性求值机——
只是属性藏在
局部变量与返回值里，
没有显式命名。

把语义规则改成
嵌在产生式右部**特定位置**的
动作（花括号代码块），
就得到**翻译方案**
（translation scheme）：
方案把“何时执行”
写死在文法里。
动作的位置有语义：
放在符号 X 之前，
意味着"此时 X 的
继承属性必须就绪"；
放在产生式末尾，
意味着"全部右部可用"，
适合算综合属性。
位置放错（比如动作
要用还没算出的属性）
就是把依赖图
藏进了代码里，
错误的求值序
从此很难再看出来——
这也是声明式 SDD
作为设计工具的价值：
先画依赖图确认无环，
再机械地翻译成方案。

## 9.6 示例落地：引擎与两个 SDD

示例的结构
刻意贴着理论走：

- `TreeNode`：
  分析树节点 = 文法符号 +
  词素 + 产生式编号 +
  属性表（字符串值）；
- `SemRule`：
  一条语义规则 =
  目标（孩子下标 + 属性名）+
  源列表 +
  计算函数。
  **规则是数据**，
  这正是“SDD 是声明式规范”
  的直译；
- `SddEngine::evaluate`：
  收集树上全部规则实例 →
  建边（源属性 → 目标属性）→
  Kahn 拓扑排序，
  就绪一个算一个 →
  `done < 总数` 即有环。
  树叶的 lexval/lexeme
  在建叶时预播种——
  “词法器供给的属性”
  的程序化。

表达式 SDD 的规则表
在 `exprSdd()`：
每层非终结符两对
inh/syn（val 与 post），
对应 9.3 的穿针引线。
`3 * 5 + 4` 的依赖图
有 38 个属性实例、
36 条边、
拓扑序 38 位——
无环，全部求出。

声明 SDD 在 `declSdd()`：

```
decls → VAR idlist SEMI      idlist.inh = 0 ; decls.size = idlist.next
idlist → IDENT idlist'       IDENT.offset = idlist.inh
                              idlist'.inh = idlist.inh + 4
                              idlist.next = idlist'.next
idlist' → COMMA IDENT idlist'   同上右移四位
idlist' → ε                  idlist'.next = idlist'.inh
```

`var x, y, pz;` 的输出：

```
x @ offset 0
y @ offset 4
pz @ offset 8
size = 12 = 4 * 3 : yes
```

offset 是**写在终结符
IDENT 叶子上**的继承属性——
注释树上叶子也带属性，
这是继承属性
最直观的展示。
`size = 4 × 个数`
的对账行由驱动核对，
期望输出里恒为 yes。

## 9.7 期望输出解读

`--check` 按“文件首 token
是不是 VAR”分派两个 SDD。

**decl.tip 段**：
注释树全打印——
每个非终结符带着
inh/next/offset
（idlist 层层 +4 的轨迹
在树上是可见的）；
依赖统计
attrs/edges/topo 三数相等
（无环的机器证据）；
结果三行偏移 +
size 对账行。

**expr.tip 段**：
注释树的根行
`expr post=3 5 * 4 + val=19`
是全章的锚点——
19 来自紫龙 Fig 5.3，
post 串每层
追加一个运算符
（先 \* 后 +，
右递归文法下
运算符天然按
优先级顺序入栈）；
`evalPostfix(post) == val : yes`
是本章的机器对账：
用一台两行的小栈机
独立复算后缀串，
两个互不认识的属性
必须给出同一个答案。

**circular demo 段**：
固定跑 A/B 反例，
`acyclic = no`、
`stuck` 两行——
9.4 节的现场。

## 9.8 工程注意点

- **真实编译器不建分析树**。
  树占内存、遍历有代价；
  S-属性配 LR 归约动作、
  L-属性配递归下降/访问者，
  都能在**分析的同时**
  完成求值，
  树只是理论上的脚手架。
  本章建树、建依赖图，
  是为了把“求值序”
  变成一个可对账的
  对象而不是直觉——
  工程上的对应物
  是 yacc 的动作嵌入位置
  与 ANTLR 的嵌入动作。
- **ANTLR 的 `#{...}` 动作**
  （第 4 章没用、但支持）
  就是翻译方案的当代形态；
  visitor 里的
  访问顺序由 ANTLR 保证
  从左到右，
  恰是 L-属性的求值序。
- **属性的副作用**。
  理论模型里规则是纯函数；
  实践允许打印、
  符号表写入等副作用，
  但要保证副作用
  只依赖已就绪的属性，
  否则求值序的自由度
  会被悄悄消耗掉。
- **种子属性**。
  词法器给 lexval、
  符号表给类型、
  常量表给值——
  任何外部信息
  都以“无源属性”身份
  进入依赖图。
  本章的 lexeme/lexval
  预播种就是这一约定。
- **输出顺序要独立于地址**。
  引擎最初按
  属性实例的指针排序打印
  “卡住”清单，
  结果两次运行顺序不同、
  期望输出对不上账——
  修复是给节点编遍历序号。
  一切进入
  期望输出的顺序
  都必须是
  确定性的语义顺序，
  这是第 1 章定下的
  对账纪律在属性文法上的
  一次重演。

## 9.9 本章配套文件

### 9.9.1 文法 TIP.g4

与第 4 章相同，只用词法器。

```cpp
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

### 9.9.2 引擎 sdd.hpp 与 sdd.cpp

树、规则数据、
依赖图求值、
两个内置 SDD、
后缀栈机。

```cpp
// file: src/sdd.hpp
// file: src/sdd.hpp
// 第 9 章配套：语法制导翻译的通用引擎。
// 一个 SDD = 文法 + 语义规则表；求值 = 在分析树上建依赖图 + 拓扑排序逐条算。
// 这是紫龙 5.1–5.2 的忠实程序化：属性是树节点上的字符串值，
// 规则是“从哪些属性读、往哪个属性写”的声明式数据。
#ifndef TIP_SDD_HPP
#define TIP_SDD_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace tip {

// 分析树节点：文法符号 + 词素 + 孩子 + 属性表
struct TreeNode {
    std::string symbol;                 // 文法符号（终结符或非终结符）
    std::string lexeme;                 // 终结符的词素（非终结符为空）
    int prod = -1;                      // 本节点按哪条产生式展开（-1 = 叶子）
    std::vector<std::unique_ptr<TreeNode>> children;
    std::map<std::string, std::string> attrs;   // 属性名 → 值（求值期填充）
    int seqId = 0;                              // 遍历序号：让输出顺序与地址无关
};

// 语义规则：把若干源属性的值，算成目标属性的一个值。
// targetChild = 0 表示写本节点（产生式左部），k>0 表示写右部第 k 个孩子。
struct SemRule {
    int targetChild;
    std::string targetAttr;
    std::vector<std::pair<int, std::string>> sources;   // (孩子下标, 属性名)
    std::function<std::string(const std::vector<std::string> &)> compute;
};

struct SddGrammar {
    // 每条产生式挂一组规则；产生式右部用于构造分析树（本引擎自带递归下降建树）
    struct ProdDef {
        std::string lhs;
        std::vector<std::string> rhs;
        std::vector<SemRule> rules;
    };
    std::vector<ProdDef> prods;
};

// 依赖图节点：(树节点指针, 属性名)
struct AttrRef {
    TreeNode *node;
    std::string attr;
    bool operator<(const AttrRef &o) const {
        if (node->seqId != o.node->seqId) return node->seqId < o.node->seqId;
        return attr < o.attr;
    }
};

class SddEngine {
public:
    explicit SddEngine(const SddGrammar &g) : g_(g) {}

    // 求值：返回 false 表示依赖图有环（SDD 非良定义）。
    // statsOut 收集 (属性实例数, 依赖边数, 拓扑序长度)。
    bool evaluate(TreeNode *root, std::map<std::string, size_t> &stats,
                  std::vector<AttrRef> *cycle = nullptr);

    // 注释树打印（含属性）
    static void dump(const TreeNode *n, int depth = 0);

private:
    const SddGrammar &g_;
};

// ---------- 两个内置 SDD ----------
// 表达式 → 值 + 后缀（紫龙 Fig 5.4 的 inh/syn 线程化，扩展到 + 与 *）
// 文法（右递归，与第 6 章改造后的文法同形）：
//   expr → term expr' ; expr' → PLUS term expr' | ε
//   term → factor term' ; term' → STAR factor term' | ε ; factor → INT
// 从 token 名序列建树；失败返回 nullptr。
std::unique_ptr<TreeNode> buildExprTree(const std::vector<std::pair<std::string, std::string>> &toks);
const SddGrammar &exprSdd();

// 声明块 → 偏移布局（继承属性的经典用武之地，紫龙 6.3 存储布局的雏形）
//   decls → VAR idlist SEMI ; idlist → IDENT idlist' ;
//   idlist' → COMMA IDENT idlist' | ε
std::unique_ptr<TreeNode> buildDeclTree(const std::vector<std::pair<std::string, std::string>> &toks);
const SddGrammar &declSdd();

// 后缀表达式求值（小栈机）：供 main 做 post 求值 == val 的对账。
int evalPostfix(const std::string &post);

}  // namespace tip

#endif  // TIP_SDD_HPP
```

```cpp
// file: src/sdd.cpp
// file: src/sdd.cpp
// 第 9 章配套：SDD 引擎实现与两个内置属性文法。
#include "sdd.hpp"

#include <cassert>
#include <iostream>
#include <sstream>

namespace tip {

// ---------- 依赖图求值 ----------
bool SddEngine::evaluate(TreeNode *root, std::map<std::string, size_t> &stats,
                          std::vector<AttrRef> *cycle) {
    // 1) 收集所有 (节点, 产生式) 实例，为每条规则登记目标与源
    struct EdgeWaiter {
        TreeNode *host;             // 按该产生式展开的节点
        const SemRule *rule;
    };
    std::vector<EdgeWaiter> waiters;
    std::vector<TreeNode *> order;
    std::vector<TreeNode *> stack = {root};
    while (!stack.empty()) {
        TreeNode *n = stack.back();
        stack.pop_back();
        n->seqId = static_cast<int>(order.size());
        order.push_back(n);
        if (n->prod >= 0) {
            for (const auto &r : g_.prods[n->prod].rules)
                waiters.push_back({n, &r});
        }
        for (auto &c : n->children) stack.push_back(c.get());
    }
    // 2) 建边：源属性实例 → 目标属性实例
    std::map<AttrRef, std::vector<AttrRef>> edgesTo;   // 目标 ← 源
    std::map<AttrRef, int> indeg;
    auto ref = [](TreeNode *host, int childIdx, const std::string &attr,
                  const TreeNode *owner) -> AttrRef {
        TreeNode *t = host;
        if (childIdx > 0) {
            assert(childIdx <= static_cast<int>(host->children.size()));
            t = host->children[childIdx - 1].get();
        }
        (void)owner;
        return {t, attr};
    };
    for (auto &w : waiters) {
        AttrRef dst = ref(w.host, w.rule->targetChild, w.rule->targetAttr, w.host);
        if (!indeg.count(dst)) indeg[dst] = 0;
        for (const auto &src : w.rule->sources) {
            AttrRef s = ref(w.host, src.first, src.second, w.host);
            edgesTo[s].push_back(dst);
            indeg[dst] += 1;
            if (!indeg.count(s)) indeg[s] = 0;
        }
    }
    // 3) Kahn 拓扑排序 + 依序求值
    std::vector<AttrRef> ready;
    for (const auto &kv : indeg)
        if (kv.second == 0) ready.push_back(kv.first);
    size_t done = 0;
    while (!ready.empty()) {
        AttrRef cur = ready.back();
        ready.pop_back();
        ++done;
        // 该属性若被某条规则定为目标，且全部源就绪，则计算
        for (auto &w : waiters) {
            AttrRef dst = ref(w.host, w.rule->targetChild, w.rule->targetAttr, w.host);
            if (!(dst < cur) && !(cur < dst)) {
                std::vector<std::string> vals;
                bool allPresent = true;
                for (const auto &src : w.rule->sources) {
                    AttrRef s = ref(w.host, src.first, src.second, w.host);
                    auto it = s.node->attrs.find(s.attr);
                    if (it == s.node->attrs.end()) { allPresent = false; break; }
                    vals.push_back(it->second);
                }
                if (allPresent) dst.node->attrs[dst.attr] = w.rule->compute(vals);
            }
        }
        for (const auto &nxt : edgesTo[cur]) {
            if (--indeg[nxt] == 0) ready.push_back(nxt);
        }
    }
    stats["attrs"] = indeg.size();
    stats["edges"] = 0;
    for (const auto &kv : edgesTo) stats["edges"] += kv.second.size();
    stats["topo"] = done;
    if (done < indeg.size()) {
        if (cycle) {
            for (const auto &kv : indeg)
                if (kv.second > 0) cycle->push_back(kv.first);
        }
        return false;   // 有环
    }
    return true;
}

void SddEngine::dump(const TreeNode *n, int depth) {
    std::ostringstream os;
    for (int i = 0; i < depth; ++i) os << "  ";
    os << n->symbol;
    if (!n->lexeme.empty()) os << "('" << n->lexeme << "')";
    for (const auto &kv : n->attrs) os << "  " << kv.first << "=" << kv.second;
    std::cout << os.str() << '\n';
    for (const auto &c : n->children) dump(c.get(), depth + 1);
}

// ---------- 表达式 SDD ----------
namespace {

std::unique_ptr<TreeNode> leaf(const std::string &sym, const std::string &lex) {
    auto n = std::make_unique<TreeNode>();
    n->symbol = sym;
    n->lexeme = lex;
    // 词法器“免费”提供的两个属性：紫龙的 digit.lexval 正是这类种子。
    n->attrs["lexval"] = lex;
    n->attrs["lexeme"] = lex;
    return n;
}

// token 序列 = (名, 词素)
struct ExprBuilder {
    const std::vector<std::pair<std::string, std::string>> &t;
    size_t i = 0;
    std::string error;

    explicit ExprBuilder(const std::vector<std::pair<std::string, std::string>> &toks) : t(toks) {}

    std::unique_ptr<TreeNode> node(const std::string &sym, int prod) {
        auto n = std::make_unique<TreeNode>();
        n->symbol = sym;
        n->prod = prod;
        return n;
    }
    bool eat(const std::string &sym, std::unique_ptr<TreeNode> &into) {
        if (i < t.size() && t[i].first == sym) {
            into = leaf(sym, t[i].second);
            ++i;
            return true;
        }
        return false;
    }
    // expr → term expr'  [0]
    std::unique_ptr<TreeNode> expr() {
        auto n = node("expr", 0);
        auto a = term();
        if (!a) return nullptr;
        auto b = exprP();
        if (!b) return nullptr;
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
        return n;
    }
    // expr' → PLUS term expr' [1] | ε [2]
    std::unique_ptr<TreeNode> exprP() {
        if (i < t.size() && t[i].first == "PLUS") {
            auto n = node("expr'", 1);
            std::unique_ptr<TreeNode> op;
            if (!eat("PLUS", op)) return nullptr;
            auto a = term();
            if (!a) return nullptr;
            auto b = exprP();
            if (!b) return nullptr;
            n->children.push_back(std::move(op));
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
            return n;
        }
        auto n = node("expr'", 2);
        return n;
    }
    // term → factor term'  [3]
    std::unique_ptr<TreeNode> term() {
        auto n = node("term", 3);
        auto a = factor();
        if (!a) return nullptr;
        auto b = termP();
        if (!b) return nullptr;
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
        return n;
    }
    // term' → STAR factor term' [4] | ε [5]
    std::unique_ptr<TreeNode> termP() {
        if (i < t.size() && t[i].first == "STAR") {
            auto n = node("term'", 4);
            std::unique_ptr<TreeNode> op;
            if (!eat("STAR", op)) return nullptr;
            auto a = factor();
            if (!a) return nullptr;
            auto b = termP();
            if (!b) return nullptr;
            n->children.push_back(std::move(op));
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
            return n;
        }
        auto n = node("term'", 5);
        return n;
    }
    // factor → INT [6]
    std::unique_ptr<TreeNode> factor() {
        if (i < t.size() && t[i].first == "INT") {
            auto n = node("factor", 6);
            std::unique_ptr<TreeNode> k;
            eat("INT", k);
            n->children.push_back(std::move(k));
            return n;
        }
        error = "factor 期待 INT，遇到 " + (i < t.size() ? t[i].first : std::string("$"));
        return nullptr;
    }
};
}  // namespace

std::unique_ptr<TreeNode> buildExprTree(
    const std::vector<std::pair<std::string, std::string>> &toks) {
    ExprBuilder b(toks);
    auto tree = b.expr();
    if (tree && b.i != toks.size()) return nullptr;
    return tree;
}

const SddGrammar &exprSdd() {
    static SddGrammar g = {
        {
            // 0: expr → term expr'
            {"expr", {"term", "expr'"}, {
                {2, "valInh", {{1, "val"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "postInh", {{1, "post"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "val", {{2, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{2, "postSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 1: expr' → PLUS term expr'
            {"expr'", {"PLUS", "term", "expr'"}, {
                {3, "valInh",
                 {{0, "valInh"}, {2, "val"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + std::stoi(v[1])); }},
                {3, "postInh",
                 {{0, "postInh"}, {2, "post"}},
                 [](const std::vector<std::string> &v) { return v[0] + " " + v[1]; }},
                {0, "valSyn", {{3, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{3, "postSyn"}},
                 [](const std::vector<std::string> &v) { return v[0] + " +"; }},
            }},
            // 2: expr' → ε
            {"expr'", {}, {
                {0, "valSyn", {{0, "valInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{0, "postInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 3: term → factor term'
            {"term", {"factor", "term'"}, {
                {2, "valInh", {{1, "val"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "postInh", {{1, "post"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "val", {{2, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{2, "postSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 4: term' → STAR factor term'
            {"term'", {"STAR", "factor", "term'"}, {
                {3, "valInh",
                 {{0, "valInh"}, {2, "val"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) * std::stoi(v[1])); }},
                {3, "postInh",
                 {{0, "postInh"}, {2, "post"}},
                 [](const std::vector<std::string> &v) { return v[0] + " " + v[1]; }},
                {0, "valSyn", {{3, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{3, "postSyn"}},
                 [](const std::vector<std::string> &v) { return v[0] + " *"; }},
            }},
            // 5: term' → ε
            {"term'", {}, {
                {0, "valSyn", {{0, "valInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{0, "postInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 6: factor → INT
            {"factor", {"INT"}, {
                {0, "val", {{1, "lexval"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{1, "lexeme"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
        },
    };
    return g;
}

// ---------- 声明偏移 SDD ----------
namespace {
struct DeclBuilder {
    const std::vector<std::pair<std::string, std::string>> &t;
    size_t i = 0;
    explicit DeclBuilder(const std::vector<std::pair<std::string, std::string>> &toks) : t(toks) {}

    std::unique_ptr<TreeNode> node(const std::string &sym, int prod) {
        auto n = std::make_unique<TreeNode>();
        n->symbol = sym;
        n->prod = prod;
        return n;
    }
    bool eat(const std::string &sym, std::unique_ptr<TreeNode> &into) {
        if (i < t.size() && t[i].first == sym) {
            into = leaf(sym, t[i].second);
            ++i;
            return true;
        }
        return false;
    }
    // decls → VAR idlist SEMI [0]
    std::unique_ptr<TreeNode> decls() {
        auto n = node("decls", 0);
        std::unique_ptr<TreeNode> kw, semi;
        if (!eat("VAR", kw)) return nullptr;
        auto list = idlist();
        if (!list) return nullptr;
        if (!eat("SEMI", semi)) return nullptr;
            n->children.push_back(std::move(kw));
            n->children.push_back(std::move(list));
            n->children.push_back(std::move(semi));
        return n;
    }
    // idlist → IDENT idlist' [1]
    std::unique_ptr<TreeNode> idlist() {
        auto n = node("idlist", 1);
        std::unique_ptr<TreeNode> id;
        if (!eat("IDENT", id)) return nullptr;
        auto rest = idlistP();
        if (!rest) return nullptr;
            n->children.push_back(std::move(id));
            n->children.push_back(std::move(rest));
        return n;
    }
    // idlist' → COMMA IDENT idlist' [2] | ε [3]
    std::unique_ptr<TreeNode> idlistP() {
        if (i < t.size() && t[i].first == "COMMA") {
            auto n = node("idlist'", 2);
            std::unique_ptr<TreeNode> comma;
            if (!eat("COMMA", comma)) return nullptr;
            std::unique_ptr<TreeNode> id;
            if (!eat("IDENT", id)) return nullptr;
            auto rest = idlistP();
            if (!rest) return nullptr;
            n->children.push_back(std::move(comma));
            n->children.push_back(std::move(id));
            n->children.push_back(std::move(rest));
            return n;
        }
        return node("idlist'", 3);
    }
};
}  // namespace

std::unique_ptr<TreeNode> buildDeclTree(
    const std::vector<std::pair<std::string, std::string>> &toks) {
    DeclBuilder b(toks);
    auto tree = b.decls();
    if (tree && b.i != toks.size()) return nullptr;
    return tree;
}

const SddGrammar &declSdd() {
    static SddGrammar g = {
        {
            // 0: decls → VAR idlist SEMI
            {"decls", {"VAR", "idlist", "SEMI"}, {
                {2, "inh", {}, [](const std::vector<std::string> &) { return "0"; }},
                {0, "size", {{2, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 1: idlist → IDENT idlist'
            {"idlist", {"IDENT", "idlist'"}, {
                {1, "offset", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "inh",
                 {{0, "inh"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + 4); }},
                {0, "next", {{2, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 2: idlist' → COMMA IDENT idlist'
            {"idlist'", {"COMMA", "IDENT", "idlist'"}, {
                {2, "offset", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {3, "inh",
                 {{0, "inh"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + 4); }},
                {0, "next", {{3, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 3: idlist' → ε
            {"idlist'", {}, {
                {0, "next", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
        },
    };
    return g;
}

// ---------- 后缀求值（栈机） ----------
int evalPostfix(const std::string &post) {
    std::vector<int> st;
    std::istringstream in(post);
    std::string tok;
    while (in >> tok) {
        if (tok == "+" || tok == "*") {
            int b = st.back(); st.pop_back();
            int a = st.back(); st.pop_back();
            st.push_back(tok == "+" ? a + b : a * b);
        } else {
            st.push_back(std::stoi(tok));
        }
    }
    return st.back();
}

}  // namespace tip
```

### 9.9.3 驱动 main.cpp

词法 → 按 VAR 分派 →
注释树 + 依赖统计 + 结果 +
循环依赖演示。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 9 章驱动：--check FILE
//   FILE 以 var 开头 → 声明偏移 SDD；否则 → 表达式 SDD（值 + 后缀）。
//   末尾固定跑“循环依赖”小演示：紫龙 5.1.2 的 A/B 反例。
#include "sdd.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

std::vector<std::pair<std::string, std::string>> lexTip(const std::string &path) {
    std::ifstream stream(path);
    if (!stream) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(stream);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    tokens.fill();
    std::vector<std::pair<std::string, std::string>> out;
    for (antlr4::Token *t : tokens.getTokens()) {
        if (t->getType() == antlr4::Token::EOF) continue;
        std::string name(lexer.getVocabulary().getSymbolicName(t->getType()));
        out.emplace_back(name, t->getText());
    }
    return out;
}

void stats(const std::map<std::string, size_t> &s) {
    std::cout << "== dependency ==\n";
    for (const auto &kv : s) std::cout << "  " << kv.first << " = " << kv.second << '\n';
}

// 收集树上全部 IDENT 叶子的 (词素, offset)
void collectIdents(const tip::TreeNode *n, std::vector<std::pair<std::string, std::string>> &out) {
    if (n->symbol == "IDENT") {
        out.push_back({n->lexeme, n->attrs.count("offset") ? n->attrs.at("offset") : "?"});
    }
    for (const auto &c : n->children) collectIdents(c.get(), out);
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto toks = lexTip(argv[2]);
    std::cout << "== tokens ==\n ";
    for (const auto &t : toks) std::cout << ' ' << t.first << "('" << t.second << "')";
    std::cout << "\n";

    if (!toks.empty() && toks[0].first == "VAR") {
        // ---------- 声明偏移 ----------
        auto tree = tip::buildDeclTree(toks);
        if (!tree) {
            std::cerr << "syntax error: 无法按声明文法解析\n";
            return 1;
        }
        tip::SddEngine eng(tip::declSdd());
        std::map<std::string, size_t> st;
        if (!eng.evaluate(tree.get(), st)) {
            std::cerr << "SDD 有循环依赖\n";
            return 1;
        }
        std::cout << "== annotated tree ==\n";
        tip::SddEngine::dump(tree.get());
        stats(st);
        std::cout << "== results ==\n";
        std::vector<std::pair<std::string, std::string>> ids;
        collectIdents(tree.get(), ids);
        for (const auto &id : ids)
            std::cout << "  " << id.first << " @ offset " << id.second << '\n';
        std::string size = tree->attrs.at("size");
        std::cout << "  size = " << size << " = 4 * " << ids.size()
                  << " : " << (std::stoi(size) == 4 * static_cast<int>(ids.size()) ? "yes" : "NO")
                  << '\n';
    } else {
        // ---------- 表达式：值 + 后缀 ----------
        auto tree = tip::buildExprTree(toks);
        if (!tree) {
            std::cerr << "syntax error: 无法按表达式文法解析\n";
            return 1;
        }
        tip::SddEngine eng(tip::exprSdd());
        std::map<std::string, size_t> st;
        if (!eng.evaluate(tree.get(), st)) {
            std::cerr << "SDD 有循环依赖\n";
            return 1;
        }
        std::cout << "== annotated tree ==\n";
        tip::SddEngine::dump(tree.get());
        stats(st);
        std::cout << "== results ==\n";
        std::string val = tree->attrs.at("val");
        std::string post = tree->attrs.at("post");
        std::cout << "  val  = " << val << '\n';
        std::cout << "  post = " << post << '\n';
        int pv = tip::evalPostfix(post);
        std::cout << "  evalPostfix(post) == val : "
                  << (pv == std::stoi(val) ? "yes" : "NO") << '\n';
    }

    // ---------- 循环依赖演示（紫龙 5.1.2 的 A/B 反例） ----------
    std::cout << "== circular demo ==\n";
    std::cout << "  A -> B ; A.s = B.i ; B.i = A.s + 1\n";
    tip::SddGrammar bad = {{
        {"A", {"B"}, {
            {0, "s", {{1, "i"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            {1, "i", {{0, "s"}}, [](const std::vector<std::string> &v) { return v[0] + "+1"; }},
        }},
    }};
    auto a = std::make_unique<tip::TreeNode>();
    a->symbol = "A";
    a->prod = 0;
    auto b = std::make_unique<tip::TreeNode>();
    b->symbol = "B";
    a->children.push_back(std::move(b));
    tip::SddEngine eng2(bad);
    std::map<std::string, size_t> st2;
    std::vector<tip::AttrRef> cyc;
    bool ok = eng2.evaluate(a.get(), st2, &cyc);
    std::cout << "  acyclic = " << (ok ? "yes" : "no")
              << " (attrs=" << st2["attrs"] << " edges=" << st2["edges"]
              << " topo=" << st2["topo"] << ")\n";
    for (const auto &r : cyc)
        std::cout << "  stuck: " << r.node->symbol << "." << r.attr << '\n';
    return 0;
}
```

### 9.9.4 程序与期望输出

```text
// file: programs/decl.tip
var x, y, pz;
```

```text
// file: programs/expr.tip
3 * 5 + 4
```

```text
; expected: expected/output.txt
== decl.tip ==
== tokens ==
  VAR('var') IDENT('x') COMMA(',') IDENT('y') COMMA(',') IDENT('pz') SEMI(';')
== annotated tree ==
decls  size=12
  VAR('var')  lexeme=var  lexval=var
  idlist  inh=0  next=12
    IDENT('x')  lexeme=x  lexval=x  offset=0
    idlist'  inh=4  next=12
      COMMA(',')  lexeme=,  lexval=,
      IDENT('y')  lexeme=y  lexval=y  offset=4
      idlist'  inh=8  next=12
        COMMA(',')  lexeme=,  lexval=,
        IDENT('pz')  lexeme=pz  lexval=pz  offset=8
        idlist'  inh=12  next=12
  SEMI(';')  lexeme=;  lexval=;
== dependency ==
  attrs = 12
  edges = 11
  topo = 12
== results ==
  x @ offset 0
  y @ offset 4
  pz @ offset 8
  size = 12 = 4 * 3 : yes
== circular demo ==
  A -> B ; A.s = B.i ; B.i = A.s + 1
  acyclic = no (attrs=2 edges=2 topo=0)
  stuck: A.s
  stuck: B.i
== expr.tip ==
== tokens ==
  INT('3') STAR('*') INT('5') PLUS('+') INT('4')
== annotated tree ==
expr  post=3 5 * 4 +  val=19
  term  post=3 5 *  val=15
    factor  post=3  val=3
      INT('3')  lexeme=3  lexval=3
    term'  postInh=3  postSyn=3 5 *  valInh=3  valSyn=15
      STAR('*')  lexeme=*  lexval=*
      factor  post=5  val=5
        INT('5')  lexeme=5  lexval=5
      term'  postInh=3 5  postSyn=3 5  valInh=15  valSyn=15
  expr'  postInh=3 5 *  postSyn=3 5 * 4 +  valInh=15  valSyn=19
    PLUS('+')  lexeme=+  lexval=+
    term  post=4  val=4
      factor  post=4  val=4
        INT('4')  lexeme=4  lexval=4
      term'  postInh=4  postSyn=4  valInh=4  valSyn=4
    expr'  postInh=3 5 * 4  postSyn=3 5 * 4  valInh=19  valSyn=19
== dependency ==
  attrs = 38
  edges = 36
  topo = 38
== results ==
  val  = 19
  post = 3 5 * 4 +
  evalPostfix(post) == val : yes
== circular demo ==
  A -> B ; A.s = B.i ; B.i = A.s + 1
  acyclic = no (attrs=2 edges=2 topo=0)
  stuck: A.s
  stuck: B.i
```

## 9.10 小结与练习

本章给“语法结构上挂计算”
立了正式理论：

- SDD = 文法 + 规则表，
  综合属性向根汇总，
  继承属性向叶穿针；
- 依赖图决定求值序，
  拓扑序存在 ⟺ 无环，
  判全树无环是指数难——
  所以用 S-属性/L-属性
  两个良定义子类兜底；
- S-属性配 LR、
  L-属性配递归下降，
  一边分析一边求值，
  第 8 章的 visitor
  被认领为 L-属性的化身；
- 翻译方案把规则
  嵌进文法，
  动作位置即求值时机。

下一章离开前端理论，
进入中间表示：
三地址码、基本块、
以及一个将成为
后续所有变换之证人的
TAC 解释器。

练习：

1. 对 `expr.tip` 的注释树
   手工重建依赖图，
   数出 38 个属性实例
   与 36 条边，
   与输出对账。
2. 给表达式文法加
   一元减号
   （factor → MINUS factor），
   扩展 val 与 post 两条线，
   重新生成期望输出。
3. 把声明 SDD 的
   槽位从 4 字节改成
   “IDENT 为 8 字节”，
   观察哪些规则要改——
   体会“改声明不改引擎”。
4. 构造一个
   依赖成环的 SDD
   （不许照抄 A/B 反例），
   让 circular demo
   风格的输出出现在
   你自己的文法上。
5. 把 expr Sdd 的
   post 属性改造成
   中缀还原属性
   （加满括号），
   验证
   `paren(3*5+4) = ((3*5)+4)`。
