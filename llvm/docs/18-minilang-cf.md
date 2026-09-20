# 18 · 控制流进阶：while 与短路逻辑

> 对应示例：`examples/18_minilang_cf/`（minilang.cpp v0.7 + test.mini）

控制流收官章。两个特性都"必须用控制流实现、不能偷懒"：`while` 是开放条件循环，`&&`/`||` 的**短路语义**要求右操作数"可能根本不被求值"——这正是第 16 章用户自定义二元运算符做不到的事（普通函数调用两个参数都会求值），所以它们必须是**语言级**运算符。

## 18.1 词法：双字符 token

`&&`/`||` 是 MiniLang 第一批**多字符运算符**。词法器用 `putback` 回退处理：

```cpp
if (Last == '&' || Last == '|') {
  int Pair = In.get();               // 偷看下一个
  if (Pair == Last) {                // && 或 ||
    int Kind = Last; Last = ' ';
    return Kind == '&' ? (int)Tok::And : (int)Tok::Or;   // 200 / 201
  }
  In.putback(Pair);                  // 不是双字符：退回去走单字符老路
}
```

token 编码 200/201 刻意**避开 ASCII 区**——与关键字共用"负数/特殊值"的思路相反，运算符 token 需要能进 `BinopPrecedence`（int 键）。

> **实测坑（符号扩展）**：优先级表改成 `map<int,int>` 后，查找处若残留 `(char)CurTok` 强转，200 会变成 **-56**（char 符号扩展），表里永远查不到——`print(1 < 2 && 3 < 4)` 直接报 `expected ',' or ')'`。多字符 token 全链路统一用 int。

## 18.2 while：结果 phi 的正确位置

`while cond do body` 的值 = 最后一圈 body 值（0 圈为 0.0）——和 for 的结果语义对齐。**phi 放哪**是本章的考点：

```llvm
while.cond:
  %whileres = phi double [ 0.0, %entry ], [ %bodyV, %while.body ]  ; ①结果 phi 在循环头
  %c = fcmp one %cond, 0.0
  br i1 %c, label %while.body, label %while.exit
while.body:
  ... %bodyV ...
  br label %while.cond
while.exit:
  ... 用 %whileres ...
```

> **实测坑**：最初把结果 phi 放在 **exit 块**，incoming 写 `[bodyV, while.body]`——但 `while.body` 根本不是 exit 的前驱（它跳回 cond）！verify 报 `PHINode should have one entry for each predecessor of its parent basic block!`。**phi 的来源必须是真实 CFG 边**；放循环头，"回边带新值、入边带初值"，出口时自然持有最终值——这正是第 4 章 for 循环 `%res` phi 的同款位置。

## 18.3 短路：用控制流实现逻辑

`L && R` 的语义 = "L 假则 0（R 不求值），否则 R 的真值"：

```cpp
Value *LBool = fcmp(one) L, 0.0;
//          ┌─ L 真 → 评 R ─┐
// LBool ────┤              ├─→ phi i1 [短路值, shortBB], [RBool, rhsBB]
//          └─ L 假 → 短路 ─┘
// &&：condbr LBool, rhs, short（假短路）；短路值 = 0
// ||：condbr LBool, short, rhs（真短路）；短路值 = 1
```

四个块：当前块、`rhs`（评右值）、`and.short`/`or.short`（短路）、`logic.end`（i1 phi 合流后 uitofp 成 double）。**为什么不能是普通函数**（`def binary&& ...` 也不行）：函数调用先求值两个实参——短路性在参数求值这一步就丢了。C 的 `&&`、Python 的 `and`、Rust 的 `&&` 全是语言级，道理相同。

## 18.4 实测

```text
print(power(2, 10))            → 1024.000000     # while 迭代求幂
print(safe_div(90, 10))        → 1.000000        # d≠0：n/d=9 < 100
print(safe_div(90, 0))         → 0.000000        # d=0：n/d 根本没算
print(1 < 2 && 3 < 4)          → 1.000000
print(1 < 2 || 3 < 2)          → 1.000000
print(2 < 1 || 3 < 2)          → 0.000000
print(2 < 1 && 1 / 0 < 9)      → 0.000000        # 1/0 没被求值——否则是 inf
==== 18 ok ====
```

最后一行是短路的直接证据：`1 / 0` 若被求值，double 会得 `inf`，比较结果为假输出 0——看起来一样？不：中间测试 `2 < 1 && 1 / 0 < 9` 若**不**短路，`inf < 9` 为假 → 0，输出碰巧相同。真正区分性的用例是 `print(2 < 1 || 1 / 0 > 9)`（若不短路 `inf > 9` 为真 → 1；短路则 0）——留给读者做实验。

> **实测坑（用 double 写整数算法）**：第一版 power 用折半幂（`exp - 2*(exp/2)` 判奇偶）——MiniLang 万物皆 double，`1/2 = 0.5` 永远除不尽，exp 走向 0.5→0.25→… 输出 nan。**双精度语言写整数算法要显式取整**（MiniLang 没提供，测试改用线性版）。语言设计者一言难尽的时刻。

## 18.5 潜伏 bug 的考古收获

本章测试还挖出一个从 v0.1 潜伏至今的前端 bug：**原型参数表不支持逗号**（`def f(a, b)` 报错，`def f(a b)` 反而行）。此前九章测试恰好全是单参函数——**测试覆盖决定 bug 寿命**。修复：参数循环里接受可选逗号。写进坑位清单，提醒自己：新语法特性落地时先审旧语法的邻接区域。

## 18.6 本章小结

- 多字符 token：偷看+putback；编码避开 ASCII；全链路 int 传递防符号扩展。
- while 结果 phi 放**循环头**（真实 CFG 边）；短路逻辑必须语言级（4 块 + i1 phi）。
- 教训两条：double 写整数算法的坑；测试覆盖不足让 bug 潜伏九章。

| 坑 | 解法 |
|---|---|
| `(char)200` 变 -56 查不到表 | token 全 int；表 map<int,int> |
| phi 前驱数不匹配 | phi 进/出块核对真实 CFG 边 |
| def f(a, b) 报错 | v0.7 起参数表支持逗号 |
| 奇偶判断输出 nan | double 语言写整数算法要先取整 |

下一章把第 6/7 章的 pass 技能搬回进程内，给 MiniLang 装观察哨。
