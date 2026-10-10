# 第 57 章 递归函数与部分递归

> 对书：Mendelson §3.3（原始递归与递归函数）+ §5.3/§5.4（部分递归、层级，
> 文档线）。本章通道：C（`examples/57_recfn/ex57_recfn.v`）/
> L（`examples/57_recfn/ex57_recfn.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| PR 求值器 | prf 构造子（Z/N/U/复合/递归）+ peval 结构求值+prec_unfold 展开方程 | C/L |
| 书例函数族 | 命题 3.16：add/mul/pred/monus/sg/exp/fact 全部构造子组装 | C/L |
| 全正确定理 | add/mul/pred/monus/exp/fact 六条归纳真证（步进方程=rfl） | C/L |
| Ackermann | 双层递归可定义；ack1/ack2 公式+ack3 增长表——**非 PR** 文档线 | C/L |
| 限制 μ-算子 | muleast 有界最小化（Option 部分性）+正反例 | C/L |

55 章寄存器机、56 章图灵机给了「程序」的两个**机器**模型；本章给出第三个
——**语法**模型：函数写成可检查的树（构造子），「计算」就是求值器。三个
模型计算同一类函数（Church-Turing 论题的三张面孔），而语法模型的优点是
**归纳法直接可用**——这正是 63/64 章算术化的跳板。

## 一、初始函数、两条规则与求值器

§3.3 的定义链：**初始函数**是零函数 Z、后继 N、投影 U_i^n；**复合**(IV)与
**原始递归**(V)是两条构造规则；PR=初始+IV+V；再加上**限制 μ-算子**(VI)
（对保证有零点的 g 取最小零点）得到**递归**函数。机器版把这条链原样做成
归纳类型：

```coq
Inductive prf : Type :=
| pz : prf                        (* 零函数 Z *)
| ps : prf                        (* 后继 N *)
| prj (n i : nat) : prf           (* 投影 U_i^n *)
| comp1 (g h : prf)               (* 一元复合 g(h(x))——(IV) 的代表 *)
| comp2 (g h1 h2 : prf)           (* 二元复合 g(h1(x),h2(x))——(IV) 的代表 *)
| prec (g h : prf).               (* 原始递归 (V) *)
```

复合取一元/二元两个代表：一般 k 元复合（书 (IV) 的 h₁,…,h_k）由命题 3.14
（加哑变元/换位/认同）与这两个代表迭代派生——文档线，机器面不再多做。求值
器对 prec 的嵌套递归是本章第一个技术点：`f(S m)=h(m, f(m), xs)` 的迭代被
交给一个**闭包参数化**的顶层迭代器（EFT 五撞同款预案）：

```coq
Fixpoint itup (step : nat -> nat -> nat) (k r : nat) : nat :=
  match k with
  | O => r
  | S m => step m (itup step m r)
  end.

Fixpoint peval (f : prf) (args : list nat) {struct f} : nat :=
  match f with
  ...
  | prec g h =>
      match args with
      | [] => 0
      | a :: xs => itup (fun m r => peval h (m :: r :: xs)) a (peval g xs)
      end
  end.
```

`itup` 只递归于计数、把步函数当**参数**——peval 对 prec 分支的调用都落在
真子项 g/h 上，结构归纳成立（Lean 侧见坑位：元素递归的 list-comp 会把
定义挤到良基 recursion，rfl 失效——comp1/comp2 双构造子是正解）。展开
方程是**一切正确性证明的钥匙**：

```coq
Lemma prec_unfold : forall g h x xs,
  peval (prec g h) (S x :: xs) = peval h (x :: peval (prec g h) (x :: xs) :: xs).
Proof. reflexivity. Qed.
```

它说：递归在 S x 处的值 = h 作用于 (x, 递归在 x 处的值, 其余参数)——整个
itup 链条被转换检查一步压平。

## 二、书例函数族（命题 3.16）与步进方程法

命题 3.16 列出的函数全部 PR——书给出构造，机器照抄构造子：

```coq
Definition pr_add : prf := prec (prj 1 0) (comp1 ps (prj 3 1)).
Definition pr_mul : prf := prec pz (comp2 pr_add (prj 3 1) (prj 3 2)).
Definition pr_pred : prf := prec pz (prj 2 0).
(* 约定：求值器对首变元递归，故 pr_monus [x;y] = y ∸ x *)
Definition pr_monus : prf := prec (prj 1 0) (comp1 pr_pred (prj 3 1)).
Definition pr_sg : prf := comp2 pr_monus pr_pred (prj 1 0).
Definition pr_exp : prf := prec (comp1 ps pz) (comp2 pr_mul (prj 3 1) (prj 3 2)).
Definition pr_fact : prf :=
  prec (comp1 ps pz) (comp2 pr_mul (prj 3 1) (comp1 ps (prj 3 0))).
```

读法示例：加法的基是「U_1^0」（递归位取 0 时返回第二参数 y——注意本章
求值器对**首**变元递归），步是「ps∘U_3^1」（对 (x, r, y) 取 r 加一）。
monus 的步是 pred∘U——每递归一步做一次前驱，正是书的 x∸(y+1)=δ(x∸y)。

正确性证明用**步进方程法**：每个函数先给一条 rfl 级的步进引理（定义方程
的转换检查），再普通归纳：

```coq
Lemma pr_add_S : forall x y, peval pr_add [S x; y] = S (peval pr_add [x; y]).
Proof. reflexivity. Qed.

Theorem pr_add_is_add : forall x y, peval pr_add [x; y] = x + y.
Proof.
  intro x. induction x as [|x IH]; intro y.
  - reflexivity.
  - rewrite pr_add_S, IH. reflexivity.
Qed.
```

六条全正确定理同构：乘法接加法（步进引理右边就是 pr_add，复合地用已证的
定理）、前驱/monus 接 lia、指数接 `Nat.pow_succ_r'`、阶乘对递归定义的
fact 证。对账表再兜一层数值：

```coq
Example table_pred_monus_sg :
  map (fun x => (peval pr_pred [x], peval pr_monus [3; x], peval pr_sg [x]))
      (seq 0 8)
  = [(0, 0, 0); (0, 0, 1); (1, 0, 1); (2, 0, 1); (3, 1, 1);
     (4, 2, 1); (5, 3, 1); (6, 4, 1)].
Proof. reflexivity. Qed.
```

（注意 monus 列的截断行为：x=1,2,3 处都是 0——**期望表首版算错被机器
对账抓出**，行对齐后再过。）命题 3.16 其余成员（min/max/rm/qt）是同法
练习，文档线留给读者按书构造。

## 三、Ackermann：可定义但非 PR

Ackermann 函数是「PR 之外还有函数」的经典证据：

```coq
Fixpoint ack (m : nat) : nat -> nat :=
  match m with
  | O => fun n => S n
  | S m' => fun n =>
      (fix inner (k : nat) : nat :=
         match k with
         | O => ack m' 1
         | S k' => ack m' (inner k')
         end) n
  end.
```

它在 Coq/Lean 里**可定义**（外层对 m 结构归纳、内层局部 fix 对 k——56 章
tm 求值器同款手法），但**不属于 PR**：每个 PR 函数最终被某个固定的 Ackermann
层支配（Ackermann 本人/original 论证的骨架），对角化 d(n)=φₙ(n)+1 再给出
「PR ≠ 全部递归」——非 PR 的完整论证是文档线（书的 §3.3 末与习题线索），
机器面给增长对账：

```coq
Theorem ack_1n : forall n, ack 1 n = n + 2.
Theorem ack_2n : forall n, ack 2 n = 2 * n + 3.
Example table_ack3 : map (ack 3) (seq 0 6) = [5; 13; 29; 61; 125; 253].
```

ack 3 n = 2^(n+3)−3 的指数增长肉眼可见——每上一层塔就换一次运算
（+2 → ×2+3 → 2^n）。这两条公式定理本身就是「嵌套递归也能归纳」的现场：
ack_2n 的归纳步要经过 ack_1n 复合。

## 四、限制 μ-算子与部分递归

§3.3 规则 (VI)：对**保证有零点**的 g，μy(g(y)=0) 取最小零点——「限制」
保证全函数。机器面把「限制」松成**有界搜索**（燃料版），None 就是部分
函数的「未定义」：

```coq
Fixpoint muleast (g : nat -> nat) (b : nat) : option nat :=
  match b with
  | O => if Nat.eqb (g O) 0 then Some O else None
  | S b' => match muleast g b' with
            | Some y => Some y
            | None => if Nat.eqb (g (S b')) 0 then Some (S b') else None
            end
  end.

Example mu_abs2 :
  muleast (fun y => Nat.sub (2 * y) 4 + Nat.sub 4 (2 * y)) 10 = Some 2.
Example mu_none : muleast (fun y => S y) 10 = None.
```

第一个例子的 g 是 |2y−4|（两向截断减相加）——只在 y=2 取零，最小化命中；
第二个例子无零点，燃料尽返回 None——这正是「部分递归函数在无定义处
发散」的类型化身（TM 的永不停机、RM 的燃料尽、这里的 None 是同一件事的
三种说法）。**递归=PR+μ**（部分函数类）与 **TM 可计算=递归**（§5.3
定理）的等价链是文档线，把 55/56 章的机器模型与本章语法模型缝起来。
§5.4 的 Kleene–Mostowski 层级（Σₙ/Πₙ、r.e.=Σ₁）与 Kleene 正规形
（T 谓词）也是文档线——64 章的不完备性证明会把「递归」当作表示性的
入场券。

## 五、与前后的接驳

| 章 | 关系 |
|---|---|
| 33 RM / 34 TM | 三模型同一函数类：RM 燃料尽/TM 无匹配/μ 的 None 是「未定义」三化身 |
| 36 算术化 | 本章 prf 的**编码**（构造子→素数幂）就是哥德尔编码的第一层素材 |
| 37 不完备性 | 「每个递归函数在 S 中可表示」的定理以本章函数族为实例来源 |
| 54 PA | S1-S9 的递归方程（S5-S8 正是 pr_add/pr_mul 的公理版）互为镜像 |

## 坑位速记（本章实测）

- **Lean 的 list-comp 求值挤到良基递归**：`gs.map (fun gi => peval gi args)`
  的元素递归让方程编译器放弃结构归纳，peval 的 rfl/defeq 全废——改
  **comp1/comp2 双构造子**（k 元复合文档线派生）后结构归纳回归、
  prec_unfold 重回 rfl。Coq 的 guard 反而收 list-comp——两通道行为
  分歧的现场。
- **itup 只 match 计数**：成对 match（k, r）会让第二个 scrutinee（stuck
  的 peval g xs）阻塞 iota 展开——r 作普通参数传入。
- **期望表两连错**：monus 列首版按 x−3 直觉写出、又行错位——以 Compute
  实值为准回填（截断减法在 x<3 处全 0，直觉易漏）。
- **Lean succ 形态**：`x + 1` 不是构造子形态，步进引理陈述须写
  `[Nat.succ x, y]`；`(x+1).pred` 卡在 HAdd——`Nat.pred_succ`/`Nat.pred_eq_sub_one`
  两把钥匙；`0 + y` 转换可过、`y - 0` 卡（减法递归于首参）——基例用
  `simp [peval, …, itup]`。
- **Coq 注释混进 Lean**：`(* *)` 在 Lean 里是语法错（`--` 才是行注释）——
  镜像文件先过一遍注释形态。
- **ack 的 WF 方程**：Lean 把嵌套 ack 编译成良基递归，方程不能 rfl——
  `have h : ack 1 (n+1) = ack 0 (ack 1 n) := by simp [ack]` 提取后 rw。
- 账本：Coq 全章零公理；Lean 主定理带 [propext, Quot.sound]（simp/WF
  引入）。

## 小结

递归函数把「可计算」从机器搬进语法：构造子树+求值器+归纳法。步进方程法
（rfl 级引理+普通归纳）让六条全正确定理轻落；Ackermann 演示嵌套递归的
可定义性与 PR 的天花板；μ 的 Option 语义把部分性做成类型。下一章把这棵
语法树本身编码成自然数——算术化的全部素材到此备齐。

---

上一章：[56 图灵机：四元组与纸带](docs/56-turing.md) · 下一章：[58 通用性与不可判定性：停机、Rice 与递归定理](docs/58-undecidable.md)
