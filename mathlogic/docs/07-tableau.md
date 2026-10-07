# 07 语义表列：反向搜索的判定程序

> 对书：Ben-Ari 3e §2.6-2.7 / H&R §1.5（间接）/ Smullyan 的 α/β 分类传统
> 通道：C/L（三定理链，全部零公理）

02 章的判定器枚举赋值（自底向上），06 章的矢列演算给证明搜索
搭了骨架（自下而上拆连接词）。本章的**语义表列**（semantic
tableau）把这条路走成完整算法：不问「怎么证出 f」，而问
「怎么把 ¬f 的全部可能性都堵死」——**反证式的判定程序**。
它教会我们一件贯穿后续章节的事：**一个搜索程序可以配上完整的
正确性证明**（可靠+完备+判定，三条定理零公理）。

## 带符号公式：把「证」翻译成「堵」

表列在**带符号公式**上工作：T f 表示「假设 f 真」，F f 表示
「假设 f 假」。要判定 f 是否有效，从单个假设 `F f`（f 假）出发，
不断展开，看每条分支会不会撞墙。撞墙=**闭分支**：同一原子同时
带 T 号和 F 号。全部分支撞墙，说明「f 假」这个假设无路可走——
f 有效。

展开规则按 Smullyan 的分类分两组（这个分类比逐连接词记规则
省力一个量级）：

- **α 规则**（合取型，不分枝——前提与结论「同时为真」）：
  `T(a∧b)` 落成 `Ta, Tb`；`F(a∨b)` 落成 `Fa, Fb`；
  `F(a→b)` 落成 `Ta, Fb`（蕴含为假恰是前真后假）；
  `T(¬a)`/`F(¬a)` 翻号继续。
- **β 规则**（析取型，分两枝——「至少其一为真」）：
  `F(a∧b)` 分成 `Fa | Fb`；`T(a∨b)` 分成 `Ta | Tb`；
  `T(a→b)` 分成 `Fa | Tb`。

记忆法：**T 号看连接词的「真值条件」，F 号看它的反面**；
合取型条件唯一（α 不分枝），析取型条件分叉（β 分枝）。
九种符号-连接词组合全部落入这两类——这就是为什么 α/β 分类
是表列教学的标准姿势。

## 一个手算例子

判定 `p → (q → p)`（05 章的 A1！）：从 `F(p → (q → p))` 出发。

```text
F(p → (q → p))          α：蕴含为假
  T p, F(q → p)         继续 α
  T p, T q, F p         闭：p 同时带 T 与 F ✗
```

唯一分支闭——公式有效。注意全程没有「证明」，只有**可能性的
穷举与封堵**：这正是「反向搜索」的含义。

## 实现：燃料化的结构递归

表列的数学版本可以无穷展开（懒惰实现），要机器化必须先解决
终止性。本章方案：**fuel 化**——给搜索配一箱燃料，每步烧一格；
同时证一个引理保证「燃料够多就够用」（完备性定理里的
`bsize B < fuel` 前提）。核心数据结构（`examples/07_tableau/
ex07_tableau.v`）：

```coq
Inductive sign : Type := T | F.
Definition entry : Type := (sign * form)%type.
Definition branch : Type := list entry.
```

分支是带符号公式的表。三个辅助件各司其职：

- `extract B`：抽出**第一个复合式**（原子跳过），返回
  `Some (sign, formula, 剩余分支)`；全是原子则 `None`；
- `closedB B`：扫有没有「T x 与 F x 同枝」；
- `readOff B`：从饱和分支**读出模型**——T 号原子为真、
  其余为假的那个赋值。

主循环 `tsearch` 是九条规则的直接转写：

```coq
Fixpoint tsearch (fuel : nat) (B : branch) {struct fuel}
  : option (nat -> bool) :=
  match fuel with
  | 0 => None
  | S k =>
    if closedB B then None else
    match extract B with
    | None => Some (readOff B)
    | Some (T, FAnd a b, B') => tsearch k ((T, a) :: (T, b) :: B')
    | Some (F, FAnd a b, B') =>
        orelse (tsearch k ((F, a) :: B')) (tsearch k ((F, b) :: B'))
    | ... (* 其余七条同构 *)
    end
  end.
```

读法：闭分支返回 `None`（此路不通）；无复合式返回
`Some (readOff B)`（饱和开放分支——反模型找到了）；α 规则
延长分支继续搜；β 规则 `orelse` 分两枝（左枝出模型就用，
否则搜右枝）。返回值 `option (nat -> bool)` 是**反模型见证**：
不只回答「否」，还交出一个让公式成假的具体赋值。

终止度量是分支尺寸 `bsize B = Σ fsize f`（每个公式的节点数
之和）：α 步把尺寸 ≥2 的复合式换成尺寸和恰小 1 的两个碎片，
β 步每枝更小。**燃料取 `S (bsize B)` 必够**——这就是完备性
定理里那个不等式前提的来历。

## 旗舰三定理

一个判定程序的完整正确性有三条腿，本章全部零公理拿下：

```coq
Theorem tsearch_sound : forall fuel B e,
  tsearch fuel B = Some e -> satisfies e B.
Theorem tsearch_complete : forall fuel B e,
  bsize B < fuel -> satisfies e B -> tsearch fuel B <> None.
Corollary tsearch_decides : forall f,
  tsearch (S (bsize [(F, f)])) [(F, f)] = None <-> valid f.
```

**sound**（搜到的模型真满足分支）：对 fuel 归纳，戏眼在饱和
分支——`readOff` 读出的赋值天然满足 T 号原子；F 号原子 x
若被误读成 true，说明分支里另有 `(T, FVar x)`，与
`closedB = false` 矛盾（`closed_contradicts` 引理现场拼装）。
T 号复合式则用归纳假设：它们被 α/β 步拆成了更小的碎片，
碎片满足则整体满足（`eval` 的布尔等式一族）。

**complete**（有模型则搜得到）：对 fuel 归纳，前提
`bsize B < fuel` 保燃料。α 步直接 IH；β 步是戏眼——模型满足
`T(a∨b)` 意味着满足 a 或 b，**模型替我们选枝**：满足哪枝，
哪枝就不可能返回 None（IH 反向），于是 `orelse` 总有一枝出货。
这条定理的读法值得停留：**完备性证明本质上在证「搜索的剪枝
从不剪掉真模型所在的枝」**。

**decides**（判定）：两条定理合流。从 `F f` 单点出发：
返回 None ⟺ 无反模型 ⟺ f 有效。`valid` 的 Prop 形态
（`forall e, eval e f = true`）与搜索的布尔行为之间，靠
sound/complete 双向缝合。推论证明本身也是教学点：→ 方向对
`eval e f` 布尔三分，← 方向对 `tsearch` 的结果做 `destruct`
——两个方向的「不可能情形」都由对方定理封死。

## Lean 版：可执行现场

Lean 通道同款实现附赠 REPL 乐趣：

```lean
#eval (tsearch 20 [(T, x₀ ∨ x₁)]).get! 0   -- true：读出的模型让 x₀ 真
```

一个工程细节：`tsearch` 返回 `Option (Nat → Bool)`，**函数的
Option 不能判等**（要等函数得 funext——与范畴论教程的自然
变换三文化同源地雷），所以演示谓词写成 `found : Option … → Bool`
折一层。

## 现场纠错：判定器不会错

Coq 文件尾的两个 Example 自带教学事故：

```coq
Example demo_sat :
  match tsearch 20 [(T, FOr (FVar 0) (FVar 1))] with
  | Some _ => true | None => false end = true.
Proof. reflexivity. Qed.

Example demo_unsat :
  tsearch 20 [(T, FAnd (FVar 0) (FNeg (FVar 0)))] = None.
Proof. reflexivity. Qed.
```

Lean 侧曾拟的三目 UNSAT 例句 `F(x₀→x₁) + T x₀ + F x₁` 其实是
**自洽的**（蕴含为假要求前真后假——T x₀ 与 F x₁ 恰好成全它），
`native_decide` 直接证伪了第一版例句。元教训：**示例先在纸上
走一遍再上机；判定器不会错，错的是对「矛盾」的直觉**。

## 与矢列演算的精确对应

表列规则不是天上掉下来的——**把 06 章 G 的规则倒过来读就是它**。
对应关系一行说清：T 号公式住左表，F 号公式住右表；「分支封闭」
就是「到达 gAx」；α/β 规则就是左/右引入规则的自下而上应用。
举例对拍：`T(a∧b)` 拆成 `Ta, Tb` 正是 gLAnd（左表头的 ∧ 拆开）；
`F(a∧b)` 分成 `Fa | Fb` 正是 gRAnd 的两个前提（右表头的 ∧ 要
两条路都走通）。闭分支判「同一原子双号」而不是「任意公式双号」，
靠的是**子公式性质**：无 cut 系统里复合式总会被拆到原子，原子
层的公理命中与复合层的公理命中等价。这也解释了为什么表列天生
经典：它继承 G 的双表结构（右表多项=F 号共存=「给自己留后路」），
06 章「G 天生经典」的分析原样搬过来即可。

## 本章小结

- 表列=反证式搜索：从 `F f` 出发堵死所有可能性；
  α 不分枝、β 分两枝，九种组合两类收编。
- 闭分支=同原子双号；开放饱和分支=反模型（`readOff` 读出）。
- fuel 化+bsize 度量：终止性变成可证引理。
- 三定理链：sound/complete/decides——判定程序正确性的完整
  形态，全部构造性零公理。
- 与前后章的接缝：G 的规则倒过来就是表列规则（06 章）；
  CNF 特化+归结规则就是 26 章的自动推理引擎。

## 坑位速记（本章实测，20+ 轮迭代）

- **Coq/Rocq**：`destruct (extract B) as [[[s f] B']|] eqn:Eex`
  ——option((a*b)*c) 是**三层括号**；`eqn:` 会把 scrutinee 在
  IH 里抽象掉（IH 的前提变成 `Some … = Some …`，用 `eq_refl`
  消）；分支序 = 模式序（Some 在前！）——完备性证明曾把
  None 分支写反；`tauto` 把 iff 假设当原子（先 `rewrite IH`）；
  等式方向 `(s,f) = en` vs `en = (s,f)` 也不是重言式——
  `firstorder` 兜底；`↔` 的 `←` 方向 `valid → (= None)` 是
  **证明等式**不是否定——intros 只吃一个；destruct eqn 后目标
  被抽象成 `None = None`，收尾用 reflexivity 不是 exact E。
- **Lean**：`for_` 避让关键字；`/-…-/` 文档注释不能挂在
  `#eval` 前；三目 UNSAT 例句见正文纠错实录。
- **通用**：α/β 规则表的「T 号看真值条件、F 号看反面」记忆法
  能防九条规则写串；β 分枝证明里「模型选枝」的读法是完备性
  论证的万能钥匙（26 章归结的可靠性也用同一招）。

---

上一章：[06 矢列演算 G：双向上下文与经典性](docs/06-sequent.md) · 下一章：[08 范式：NNF 与 CNF](docs/08-cnf.md)
