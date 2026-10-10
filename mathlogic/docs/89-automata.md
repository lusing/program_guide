# 第 89 章 自动机与形式语言：Chomsky 层级

> 对书：张寅生《证明方法与理论》11.2-11.8 节（p139-156）：五原型
> （图灵机/线性有界自动机/下推自动机/DFA/NFA）+乔姆斯基四型文法+
> 文法-机器对应+自动机与数学证明的关系。本章通道：C（`examples/
> 89_automata/ex89_automata.v`）/ L（`examples/89_automata/
> ex89_automata.lean`）/ P（`examples/89_automata/ex89_automata.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `pandaDfa`/`propDfa` | DFA 运行器：例 11.6「熊猫」词识别（¬A 补类拒绝）+例 11.7「1+1=2」命题接受 | C/L/P |
| `nfaRun`/`subsetDfa` | **NFA 状态集语义+子集构造**：定理 11.1 的构造化证明（全词枚举对账） | C/L |
| `gogDfa`/`gogRg` | 例 11.9 go*gle 家族（DFA 与文法双化身） | C/L/P |
| `anbn`/`depthTrace` | PDA 栈语义：例 11.5 aⁿbⁿ接受+aⁿbᵐ拒绝对账+栈深轨迹（表 11.9） | C/L |
| `lbaShadow2` | LBA 等额检查影子：例 11.4② ⟨aᵐbcᵐ⟩ 识别 | C/L |
| `rgDerives`/`rgToDfa` | **3 型文法↔DFA 互译**（定理 11.2(4)）：生成语言=接受语言 | C/L/P |
| `chomskyTable` | 四型文法约束表+包含链 0⊇1⊇2⊇3 | C/L |

61 章造过图灵机（0 型文法的机器）、86 章用过 Büchi 自动机做 LTL 模型
检查——但它们脚下的**自动机层级**（Chomsky 天梯的四层）从未正面登
场。张寅生书 12 章把五台原型机作为「自动证明机器」一次铺开（11.8 节
的论题：图灵机对一个函数的计算结果构成对该命题的证明——定理 11.3）。
本章补上这一层：从 DFA 到 LBA，每台机器配书中的原例。

## 一、五原型与 Chomsky 天梯

书 11.2-11.6 节给出五台机器的形式定义（各有 Accept/Reject 双停机的
变体风味）：

| 机器 | 元组 | 转移 | 语言层 |
|---|---|---|---|
| 图灵机（11.2） | 6 元组 | δ:Q×Γ→Q×Γ×{L,R,S} | 0 型：递归可枚举 |
| LBA（11.3） | 8 元组（边界 ⟨,⟩） | 同上（带头困在输入内） | 1 型：上下文有关 |
| PDA（11.4） | 7 元组（栈） | δ:Q×Σ→Q×Γ×Γ | 2 型：上下文无关 |
| DFA（11.5） | 5 元组 | δ:Q×Σ→Q（全函数） | 3 型：正则 |
| NFA（11.6） | 5 元组 | δ:Q×Σ→P(Q) | 3 型：正则 |

定理 11.2（乔姆斯基-机器对应）：四型文法生成的语言恰被四类机器接
受；语法限制递增（0 型无限制→1 型 |α|≤|β|→2 型左部单变元→3 型右线
性）、生成能力递减，包含链 0⊇1⊇2⊇3。图灵机在 61 章已造；本章造下
面三层。

## 二、DFA 与 NFA：确定性可模拟非确定性

DFA 的机器面——转移表驱动：

```coq
Fixpoint dfaStep (d : dfa) (q s : nat) : nat :=
  match d with
  | [] => 99                                 (* 缺省：sink 态（99 拒收） *)
  | (q', s', q2) :: t =>
      if andb (Nat.eqb q q') (Nat.eqb s s') then q2
      else dfaStep t q s
  end.
```

（实现注记：缺省转移的语义要选对——「自环」会让越轨的词**免费跳过
一个符号**继续读（[g,l,g,l,e] 被误收的现场）；「sink 态」才是诚实
的拒绝。这个坑在本章开发时被 Prolog 对账件当场抓获——三通道统一改
sink。）书例 11.6 的熊猫识别器：

```coq
Definition pandaDfa : dfa :=
  [ (0,0,1); (0,1,3); (1,0,3); (1,1,2); (2,0,3); (2,1,3); (3,0,3); (3,1,3) ].

Example panda_accept : dfaAccept pandaDfa 0 [2] [0;1] = true.
Example panda_reject_extra : dfaAccept pandaDfa 0 [2] [0;1;0] = false.
```

状态链 0→1→2=Acc，一切越轨入 3=Rej 自环——书里 ¬A「非识别符号」的
补类转移。例 11.7 的「1+1=2」命题识别器同构（命题=固定符号串——
定理 11.3「机器计算即证明」的最小标本）。

**NFA 的非确定性**用状态集语义驯服：`nfaRun` 一步把当前状态集扩
展成全部可达目标。定理 11.1（每台 NFA 有等价 DFA）书里只有文字论
证——机器件把它做成**构造化证明**：

```coq
Definition maskOf (qs : list nat) : nat :=        (* 状态集→bitmask *)
  fold_left (fun acc q => acc + Nat.pow 2 q) (dedupNat qs) 0.

Definition subsetDfa (n : nfa) : dfa :=           (* 16 状态集×2 符号 *)
  flat_map (fun m => map (fun s => (m, s, subsetRow n m s)) [0;1]) (seq 0 16).

Example subset_ok :
  forallb (fun w =>
    Bool.eqb (nfaAccept miniNfa 0 [3] w)
             (dfaAccept miniDfa (maskOf [0]) [8] w))
    (wordsUpto 2 4) = true.
```

「随机选择」编译成「全部并行」——非确定性不增加计算能力，只增加
描述的简洁性。例 11.9 的 go*gle 识别器（q1 的 o-循环不定次数）是
NFA 天然的应用场景。

## 三、PDA 与 LBA：栈与边界

**PDA**（例 11.5）：识别 aⁿbⁿ——读 a 压栈、读 b 弹栈、栈空接受：

```coq
Fixpoint anbn (w : list nat) (depth : nat) : bool :=
  match w with
  | [] => Nat.eqb depth 0
  | 0 :: rest => anbn rest (S depth)        (* a：压栈 *)
  | 1 :: rest => match depth with           (* b：弹栈 *)
                 | 0 => false                (* 栈空遇 b：拒绝 *)
                 | S d => anbn rest d
                 end
  | _ => false
  end.

Example pda_anbn_accept :
  [ anbn [0;0;0;1;1;1] 0; anbn [] 0; anbn [0;1] 0 ] = [true; true; true].
Example pda_anbn_reject :
  [ anbn [0;0;1] 0; anbn [1;0] 0; anbn [0;1;1] 0; anbn [0;0;0] 0 ]
  = [false; false; false; false].
```

栈深轨迹 `depthTrace [0;0;1;1] 0 = [0;1;2;1;0]` 是书表 11.9 的机器
面——**栈=一个计数器**，aⁿbⁿ 的「数相等」靠压弹平衡。这正是 2 型
文法（上下文无关）的力量边界：能数一层括号，不能数两组交叉相等。

**LBA**（例 11.4②）：识别 ⟨aᵐbcᵐ⟩——带头被边界符困在输入内来回
配对。函数式影子保存「线性空间=只看输入内部」的计算本质：

```coq
Definition lbaShadow2 (w : list nat) : bool :=
  match w with
  | 1 :: rest =>
      andb (forallb (fun s => orb (Nat.eqb s 0) (Nat.eqb s 2)) rest)
           (Nat.eqb (length (filter (Nat.eqb 0) rest))
                    (length (filter (Nat.eqb 2) rest)))
  | _ => false
  end.
```

aᵐ 与 cᵐ 等额——**两组交叉计数**，PDA 做不到（2 型的硬边界）、
LBA 可以（1 型）。带边界限制的真实带头语义记文档线：LBA 的本质
=空间被输入长度线性封顶的图灵机。

## 四、文法与机器互译

定理 11.2(4)：3 型文法（右线性）与有穷自动机互译。机器面把两边都
造出来对账：

```coq
Definition gogRg : rg :=                    (* 产生式 A→aB / A→a *)
  [ (0,(0,Some 1)); (1,(1,Some 1)); (1,(0,Some 2)); (2,(2,Some 3))
  ; (3,(3,None)) ].

Fixpoint rgDerives (g : rg) (A : nat) (w : list nat) : bool := ...

Definition rgToDfa (g : rg) : dfa :=        (* 产生式=转移、终止=接受 *)
  map (fun r => match snd (snd r) with
                | Some B => (fst r, fst (snd r), B)
                | None => (fst r, fst (snd r), 4) end) g.

Example rg_dfa_agree :
  forallb (fun w =>
    Bool.eqb (rgDerives gogRg 0 w) (dfaAccept (rgToDfa gogRg) 0 [4] w))
    (wordsUpto 4 5) = true.
```

**生成与识别在正则层完全对偶**：派生一步=转移一步、变元序列=状态
轨迹、终止式=接受态。词长 ≤5 的全枚举（1365 词，4 符号字母表）双
向对账——Prolog 件同款（`agree_gog` 逐词比对，`rg_dfa_agree=true`）。
这个对偶性向上断裂：2 型文法（PDA）的派生树已经不再对应简单的状态
轨迹——**层级每升一层，生成侧的树就深一截、识别侧的存储就贵一截**
（无存储→栈→线性带→无限带）。

## 五、自动机与证明的关系（11.8 节）

书 11.8 节的论题值得单独一提：定义 11.9 把「自动化证明方法」写成
图灵机对命题语言的计算 `M: L(G_α)→L_g(G_α)`，定理 11.3 论证「图灵
机对一个函数的计算结果构成对该命题的一个证明」（书 11.9 的推论：
作者自己的三段论系统 ND(SOA)/QESS 就是 0 型文法自动机——22 章 5 节
已见）。这在「计算=证明」的大叙事（107 章收官的 Curry–Howard 与
Leibniz 之梦）里，是机器视角的 midway 站：**证明的机器模型从「推理
规则系统」（04 章）走到了「语言识别器」**——下一个合流点是 86 章
Büchi 自动机与 LTL 的相遇（时态逻辑的模型检查=自动机接受问题）。

泵引理与 Myhill-Nerode 定理（正则性的经典刻画）书里没有展开，记
文档线：aⁿbⁿ∉REG 的对角论证与 62 章停机问题同族——「数不完的状态
数不完的等价类」。

## 小结

Chomsky 天梯的四层在机器上各就各位：DFA（转移表+sink 语义）、NFA
（状态集+子集构造的构造化证明）、PDA（栈=计数器：aⁿbⁿ 账）、LBA
（线性带=交叉计数：aᵐbcᵐ 账）、TM（61 章）。文法-机器在正则层的
互译做成了全枚举对账件——生成与识别的对偶性及断裂处。下一章（90 章）回到时态逻辑线，Büchi 自动机将把本章的有限词语言升级为无穷字
（ω-语言）——LTL 模型检查的地基。

---

上一章：[88 时态演绎系统 L](docs/88-ltlded.md) · 下一章：[90 自动机与 LTL 模型检查](docs/90-buechi.md)
