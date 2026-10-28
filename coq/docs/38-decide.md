# 38 · 可判定规格

对应示例：`../examples/38_decide.v`（`Module Ex38Decide`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

到第 37 章为止，我们换了两次排序规格：第 23 章是 `sorted + Permutation`，第 37 章是 `sorted + 多重集`。两次换的都是「规格**说什么**」。本章换一个正交的问题：规格**住在哪个世界**——`Prop` 还是 `bool`/`Set`。Prop 世界的规格能证、不能跑：`Compute` 它得不到答案。给规格配一台判定机，让「检查是否满足规格」本身变成一段可执行程序，就是**可判定规格**。

三个问题串起全章：哪些规格配得上判定机（38.1–38.3）？同一件事的两种写法怎么互相印证（38.4）？判定机要怎样才能真的算（38.5）？预备知识都在前面：第 15 章定义过 `reflect`，第 20 章见过决策过程，第 31 章用 reflect 搭过自反证明的桥。本章示例完全自包含，只用标准库。

### 38.1 规格的第三个维度：能不能算

文件头与本章的第一座桥：

```coq
(* 38 可判定规格 —— 规格能不能跑：bool 判定机、sumbool 与 reflect 桥 *)

From Stdlib Require Import List Arith Bool Lia.
Import ListNotations.

Module Ex38Decide.

(* ---------- 38.1 规格的第三个维度：能不能算 ---------- *)

(* 第 23 章把「排序正确」拆成 sorted + Permutation，第 37 章换成
   多重集——它们都是 Prop 世界的规格：能证，不能跑。
   Compute 一个 Prop 得不到 true/false，只能得到一堆没算完的联结词。
   可判定规格（第 20 章「决策过程」的谓词版）：
     谓词 P : T -> Prop 可判定，当且仅当存在可计算函数
     f : T -> bool，使得 forall x, f x = true <-> P x。
   配齐「三件套」，规格就从能证升级到能算：
     1) 谓词（Prop，给人证）
     2) 判定机（bool，给机器跑）
     3) 桥定理（reflect，保证两个世界说的是同一件事） *)

Check Nat.leb.    (* : nat -> nat -> bool ——<= 的判定机早就在用 *)

(* 第 15 章给 evenb 造过桥，这里给 Nat.leb 再造一座（模式完全一样） *)
Lemma leb_reflect : forall a b : nat, reflect (a <= b) (Nat.leb a b).
Proof.
  intros a b. destruct (Nat.leb a b) eqn:E.
  - apply ReflectT. apply Nat.leb_le. exact E.
  - apply ReflectF. intros Hle. apply Nat.leb_gt in E. lia.
Qed.
```

导入行各司其职：`List` 给 list、`In`、`nth_error`、`in_dec`、`list_eq_dec`；`Arith` 给 `Nat.leb` 一族与 `le_dec`；`Bool` 给 `reflect`、`andb`、`negb`；`Lia` 给 `lia`。`ListNotations` 打开 `[1; 2]` 记法，`Module Ex38Decide` 把全章包住（第 18 章的习惯）。

注释里是全章的纲领：**可判定谓词**的定义（存在可计算 `f : T -> bool` 使 `f x = true <-> P x`——这正是第 20 章「决策过程」从策略层面降到谓词层面），以及**三件套**——谓词、判定机、桥定理。`Check Nat.leb` 提醒你判定机早就在写：第 16、23 章的 `if Nat.leb x y` 一直是 `<=` 的判定机，只是当时没把它当「规格」看。

`leb_reflect` 是三件套的桥，与第 15 章的 `evenb_reflect` 逐行同构：`destruct (Nat.leb a b) eqn:E` 是第 16 章的老朋友——按 bool 的值分情况并记住等式；`ReflectT` 分支用 `Nat.leb_le` 把 `E : Nat.leb a b = true` 升格成 `a <= b`；`ReflectF` 分支 `intros Hle` 之后先 `apply Nat.leb_gt in E`（把 `= false` 翻成 `b < a`），`Hle : a <= b` 与 `b < a` 交给 `lia` 收尾。第 31 章说过：桥定理只证一次，之后所有实例都是计算。

### 38.2 sortedb：给「有序」配一台判定机

第一个完整的「构造式规格 + 判定机 + 桥」三件套，对象是第 23 章的老相识「有序」：

```coq
(* ---------- 38.2 sortedb：给「有序」配一台判定机 ---------- *)

(* 有序的构造式规格：归纳谓词，证据是一棵构造子搭起来的推导树。
   第 23 章用的是 le_all 的 Fixpoint 版，这里换成相邻版——
   构造子把「怎么证明」摆在明面上 *)
Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall x, sorted [x]
| sorted_cons : forall x y l,
    x <= y -> sorted (y :: l) -> sorted (x :: y :: l).

(* 构造式规格的标准配件：反演引理——把长列表的证据拆回
   「头 <= 次头」+「尾部有序」，之后 induction/inversion 都走它 *)
Lemma sorted_cons_inv : forall x y l,
  sorted (x :: y :: l) -> x <= y /\ sorted (y :: l).
Proof.
  intros x y l H. inversion H; subst. split.
  - assumption.
  - assumption.
Qed.

(* 头砍掉，尾部照样有序（单元素时尾部是 []，也成立） *)
Lemma sorted_tail : forall x l, sorted (x :: l) -> sorted l.
Proof.
  intros x l H. destruct l as [| y l'].
  - constructor.
  - destruct (sorted_cons_inv _ _ _ H) as [_ Hs]. exact Hs.
Qed.
```

`sorted` 是**构造式规格**：三个构造子就是三种「怎么证明有序」——空列表、单元素、`头 <= 次头` 且尾部有序。它与第 23 章 `le_all` 的 Fixpoint 版等价（38.4 的方法论直接套用），但证据形态不同：归纳版的证据是一棵推导树，构造子把证明步骤摆在明面上。`sorted_cons_inv` 是构造式规格的标准配件**反演引理**：`inversion H; subst` 把 `sorted (x :: y :: l)` 的证据拆开（单元素构造子因形状不合自动消失），`split` 后两个 `assumption` 各自认领 `x <= y` 与 `sorted (y :: l)`。`sorted_tail` 把「头砍掉尾部仍有序」补齐：`l = []` 时 `constructor` 用 `sorted_nil`；`l = y :: l'` 时直接调 `sorted_cons_inv` 取第二个分量（`[_ Hs]` 模式跳过用不到的 `x <= y`）。

判定机与它的桥：

```coq
(* 判定机：相邻两两比较，一趟扫描。
   注意递归写在 l' 上（l' 是 l 的结构性子项）；
   直接写 sortedb (y :: l') 会被终止检查器拒绝——
   y :: l' 不是子项变量，是一棵现拼的新树 *)
Fixpoint sortedb (l : list nat) : bool :=
  match l with
  | [] => true
  | x :: l' =>
      match l' with
      | [] => true
      | y :: _ => Nat.leb x y && sortedb l'
      end
  end.

Compute (sortedb [1; 2; 3; 4]).    (* = true : bool *)
Compute (sortedb [1; 3; 2; 4]).    (* = false : bool *)

(* 展开引理：把 sortedb 的第一步计算写成等式，证明里 rewrite 用——
   避免 simpl 把递归调用也一并展开（一展开 match 就卡住） *)
Lemma sortedb_cons_cons : forall x y l',
  sortedb (x :: y :: l') = Nat.leb x y && sortedb (y :: l').
Proof. reflexivity. Qed.

(* 桥定理：判定机说真 <=> 列表真的有序。
   两个 bool（比较结果、递归结果）都要分情况，
   四种组合恰好各归约到 true/false，reflect 的两个构造子各吃一半 *)
Lemma sortedb_reflect : forall l, reflect (sorted l) (sortedb l).
Proof.
  induction l as [| x l IH].
  - apply ReflectT. constructor.
  - destruct l as [| y l'].
    + simpl. apply ReflectT. constructor.
    + rewrite sortedb_cons_cons.
      destruct IH as [Hs | Hns].
      * destruct (Nat.leb x y) eqn:E.
        -- apply ReflectT. apply Nat.leb_le in E.
           constructor.
           ++ exact E.
           ++ exact Hs.
        -- apply ReflectF. intros Hs'.
           destruct (sorted_cons_inv _ _ _ Hs') as [Hxy _].
           apply Nat.leb_gt in E. lia.
      * destruct (Nat.leb x y) eqn:E.
        -- apply ReflectF. intros Hs'.
           destruct (sorted_cons_inv _ _ _ Hs') as [_ Hrest].
           apply Hns. exact Hrest.
        -- apply ReflectF. intros Hs'.
           destruct (sorted_cons_inv _ _ _ Hs') as [_ Hrest].
           apply Hns. exact Hrest.
Qed.

(* reflect 一翻手就是 iff（标准库的 reflect_iff） *)
Lemma sorted_iff : forall l, sorted l <-> sortedb l = true.
Proof.
  intros l. apply reflect_iff. apply sortedb_reflect.
Qed.

(* 桥的用法：跑判定机，把 true 升格成证明 *)
Example sorted_pi : sorted [1; 1; 2; 3; 3; 4].
Proof. apply sorted_iff. reflexivity. Qed.
```

`sortedb` 一趟扫描：空列表与单元素直接 `true`，两个以上就比较头两个（`Nat.leb x y`，38.1 的判定机在此复用）并 `&&` 上尾部的递归结果。**递归必须写在 `l'` 上**——`l'` 是外层 match 的结构性子项；写成 `sortedb (y :: l')` 会被终止检查器拒收（`y :: l'` 是现拼的新树，不是子项变量，实测报 `Recursive definition of sortedb is ill-formed`）。两个 `Compute` 让规格自己跑了：`[1; 2; 3; 4]` 答 `true`，`[1; 3; 2; 4]` 答 `false`——这就是「能算」。

`sortedb_cons_cons` 是个一行引理（`reflexivity`，因为等式两边做一步 iota 归约就相同），存在理由纯粹是战术：证明里 `rewrite` 它可以把 `sortedb (x :: y :: l')` 换成 `Nat.leb x y && sortedb (y :: l')` 而不动递归调用——直接 `simpl` 会把 `sortedb (y :: l')` 也展开成卡住的 `match`，后面的 `apply ReflectT` 就对不上了。

`sortedb_reflect` 的骨架值得盯着看：外层 `induction l`；`[x]` 分支 `simpl` 后 `constructor` 用 `sorted_1`。双元素以上分支先 `rewrite sortedb_cons_cons`，然后**两次 destruct**——`destruct IH as [Hs | Hns]` 把归纳假设（自己就是一座 reflect）按构造子拆开，依赖消去会顺手把目标里的 `sortedb (y :: l')` 替换成 `true`/`false`；再 `destruct (Nat.leb x y) eqn:E` 分比较结果。四种组合里：两个都真 → `ReflectT`，`constructor` 落到 `sorted_cons`，`exact E`（经 `Nat.leb_le` 升格）交出 `x <= y`、`exact Hs` 交出尾部；其余三种都答 `false` → `ReflectF`，`intros Hs'` 拿到假设的有序证据后走 `sorted_cons_inv` 拆它——比较失败的分支用 `x <= y` 与 `Nat.leb_gt` 给的 `y < x` 喂 `lia`，尾部无序的分支用 `[ _ Hrest]` 拿出 `Hrest` 直接撞 `Hns`。注意**两个 bool 都要 destruct**：只分一个，目标里就残留 `Nat.leb x y && false` 这种归约不到构造子的表达式。

`sorted_iff` 用标准库的 `reflect_iff` 把 reflect 翻成 `P <-> b = true` 的常用形态；`sorted_pi` 展示桥的用法——`apply sorted_iff` 把命题换成 `sortedb [1; 1; 2; 3; 3; 4] = true`，`reflexivity` 触发计算放行。第 31 章的「桥定理证一次、实例全是计算」在这里原样重演，只不过这次算的是**规格本身**。

### 38.3 no_dup：写得出 ≠ 算得出

「无重复」是下一个对象——它演示 Prop 规格的另一种困境：

```coq
(* ---------- 38.3 no_dup：写得出 ≠ 算得出 ---------- *)

(* 无重复谓词：量词式写法，一行搞定——但它住在 Prop 里 *)
Fixpoint no_dup (l : list nat) : Prop :=
  match l with
  | [] => True
  | x :: l' => ~ In x l' /\ no_dup l'
  end.

(* Compute 一个 Prop 得不到答案：能归约的都归约了，剩下的还是命题 *)
Compute (no_dup [1; 2]).
(* = (2 = 1 \/ False -> False) /\ (False -> False) /\ True : Prop
   ——没有 true/false，只有没算完的联结词。
   第 39 章验证二叉搜索树时，elements 的无重复性正是这一类规格 *)
```

`no_dup` 一行写完：头部元素不出现在尾部（`~ In x l'`），尾部递归无重复。`Compute` 的实测输出值得逐个符号读：`2 = 1` 来自 `In` 的定义（`In a (b :: m)` 展开成 `b = a \/ In a m`，所以 `In 1 [2]` 是 `2 = 1 \/ False`）；`-> False` 是 `~` 的展开；最外层还压着 `/\`。**能归约的都归约了，但答案不是 `true`/`false`，是一堆没算完的命题**——`~ (2 = 1 \/ False)` 该化简成 `True` 吗？经典逻辑下「显然」，构造式世界里 `2 = 1 \/ False -> False` 是一个**需要证明的命题**，不是一次比较。这就是「写得出 ≠ 算得出」。第 39 章验证二叉搜索树时，`elements` 的无重复性正是这类规格——本章先把它的判定机备好。

判定机与桥：

```coq
(* 判定机：成员测试交给 existsb + Nat.eqb *)
Fixpoint nodupb (l : list nat) : bool :=
  match l with
  | [] => true
  | x :: l' => negb (existsb (Nat.eqb x) l') && nodupb l'
  end.

Compute (nodupb [1; 2; 3]).    (* = true : bool *)
Compute (nodupb [1; 2; 1]).    (* = false : bool *)

Lemma nodupb_reflect : forall l, reflect (no_dup l) (nodupb l).
Proof.
  induction l as [| x l IH].
  - apply ReflectT. exact I.
  - simpl. destruct (existsb (Nat.eqb x) l) eqn:E1.
    + (* 头部元素已在尾部出现：判定机必答 false *)
      assert (Hin : In x l).
      { apply existsb_exists in E1. destruct E1 as [z [Hz Hxz]].
        apply Nat.eqb_eq in Hxz. subst z. exact Hz. }
      simpl. apply ReflectF. intros [Hnin _]. apply Hnin. exact Hin.
    + destruct IH as [Hnd | Hnnd].
      * simpl. apply ReflectT. split.
        -- (* ~ In x l：反证——In 则 existsb 该答 true *)
           intros Hin.
           assert (Hex : existsb (Nat.eqb x) l = true).
           { apply existsb_exists. exists x. split.
             exact Hin. apply Nat.eqb_refl. }
           rewrite Hex in E1. discriminate E1.
        -- exact Hnd.
      * simpl. apply ReflectF. intros [_ Hrest]. apply Hnnd. exact Hrest.
Qed.

Lemma no_dup_iff : forall l, no_dup l <-> nodupb l = true.
Proof.
  intros l. apply reflect_iff. apply nodupb_reflect.
Qed.

Example no_dup_312 : no_dup [3; 1; 2].
Proof. apply no_dup_iff. reflexivity. Qed.
```

`nodupb` 把成员测试整个搬进 bool 世界：`existsb (Nat.eqb x) l'`（「尾部有元素与 x 相等」的可计算版）取反后 `&&` 尾部递归。两个 `Compute` 立刻有答案。

`nodupb_reflect` 的证明在 38.2 的骨架上多了「过两座桥」：`existsb_exists` 把 `existsb ... = true` 翻成 `exists z, In z l /\ Nat.eqb x z = true`，`Nat.eqb_eq` 再把布尔相等翻成 `x = z`，`subst z` 后 `exact Hz` 拿到 `In x l`——于是 `ReflectF` 分支 `intros [Hnin _]`（模式拆合取、丢弃用不到的第二个分量）后 `Hnin` 与 `Hin` 对撞。反方向同理：要证 `~ In x l`，`intros Hin` 反证，用 `existsb_exists` + `Nat.eqb_refl` 现场构造出 `existsb (Nat.eqb x) l = true`，`rewrite Hex in E1` 后 `discriminate E1`（与已知的 `= false` 冲突）。尾部无序分支 `intros [_ Hrest]` 跳过 `~ In x l`、拿 `Hrest` 撞 `Hnnd`。`no_dup_iff` 与 `no_dup_312` 与 38.2 完全同型——三件套到手，`no_dup [3; 1; 2]` 从此是 `reflexivity` 一步。

可判定性是「继承」的，这是本节真正要交的货：

```coq
(* 可判定性是「继承」的：列表谓词的判定机要从元素类型借零件。
   标准库的形状都是「给你元素的可判定相等，还你列表的判定机」，
   而且结果类型 sumbool 住在 Set 里——能当程序跑 *)

Check Nat.eq_dec.    (* : forall n m : nat, {n = m} + {n <> m} *)
Check in_dec.        (* 元素相等可判定 => In 可判定 *)
Check list_eq_dec.   (* 元素相等可判定 => 列表相等可判定 *)

Definition list_nat_eq_dec : forall al bl : list nat,
  {al = bl} + {al <> bl} :=
  list_eq_dec Nat.eq_dec.

Definition list_nat_in : forall (i : nat) (l : list nat),
  {In i l} + {~ In i l} :=
  fun i l => in_dec Nat.eq_dec i l.

Compute (if list_nat_eq_dec [1; 3; 4] [1; 4; 3] then true else false).
(* = false : bool *)
Compute (if list_nat_eq_dec [1; 3; 4] [1; 3; 4] then true else false).
(* = true : bool *)
Compute (if list_nat_in 4 [3; 1; 4; 1; 5; 9; 2; 6] then true else false).
(* = true : bool *)

(* 不可判定的边界（如实记录，不在 Coq 里证）：
   - 元素类型没有可判定相等，no_dup 就无从判定：函数类型
     nat -> nat 上构造式地拿不到 {f = g} + {f <> g}，
     它上面的「无重复」跟着不可判定——不可判定沿类型构造子传播；
   - 停机问题（Turing 1936）这类规格则根本不可判定：
     那个 bool 函数不存在，经典逻辑也救不了 *)
```

三个 `Check` 读出标准库的统一形状：`{A} + {B}` 是 **sumbool**（38.5 细讲），`Nat.eq_dec` 说 nat 相等可判定；`in_dec` 与 `list_eq_dec` 都是「喂我元素的可判定相等，还你列表谓词的判定机」。`list_nat_eq_dec` 是 `list_eq_dec` 吃 `Nat.eq_dec` 的实例；`list_nat_in` 同理（`fun i l => in_dec Nat.eq_dec i l` 就是函数套用）。三个 `Compute` 全部算出 `bool`——注意 `if` 的被检查项是 sumbool 值，这合法且**真的在算**。最后一段注释如实划出边界：no_dup 的可判定性是从元素类型**继承**的——函数类型 `nat -> nat` 上构造式地拿不到可判定相等，它上面的无重复判定跟着泡汤（不可判定沿类型构造子传播）；停机问题这类规格则根本不可判定，那个 bool 函数不存在，经典逻辑也救不了。

### 38.4 构造式 vs 存在式：sorted_spec 与规格自检

同一个「有序」，换一种规格风格，再把两种风格证等价：

```coq
(* ---------- 38.4 构造式 vs 存在式：sorted_spec 与规格自检 ---------- *)

(* 同一件事的两种规格风格：
   构造式（sorted）：证据 = 构造子搭的推导树，「怎么证」写在定义里；
   存在式（sorted_spec）：只说证据要满足什么——「第 i 个元素」不从
   结构里拆出来，而是以假设的形式（nth_error = Some iv）给出来，
   元素与大小关系全部靠量词间接描述。
   把两个规格证等价，是对规格本身的「测试」：规格没法被证明是对的，
   但可以多写一个互相印证（VFA 的格言） *)

Definition sorted_spec (al : list nat) : Prop :=
  forall i j iv jv,
    i < j ->
    nth_error al i = Some iv ->
    nth_error al j = Some jv ->
    iv <= jv.
```

两种风格的分野：**构造式**（`sorted`）用构造子说「怎么证」；**存在式**（`sorted_spec`，量词式）只说证据必须满足什么——「第 i 个元素」不从列表结构里拆出来，而是以假设的形式给出：`nth_error al i = Some iv` 读作「**如果**第 i 个位置存在元素、记作 iv」。四个量词 `i j iv jv`、前提 `i < j`、两条 nth_error 假设、结论 `iv <= jv`——「任意两个位置的元素按先后不减」。写两遍规格再证等价，是对规格本身的测试：规格没法被证明「是对的」（Perlis 的格言：无法从非形式走到形式），但可以多写一个互相印证（VFA 的原话）。

方向一（构造式 → 存在式）要先备「头压得住全场」：

```coq
(* 方向一要先证「头压得住全场」——归纳把 x 也一起 generalize *)
Lemma sorted_hd_le : forall x l,
  sorted (x :: l) -> forall y, In y l -> x <= y.
Proof.
  intros x l. revert x.
  induction l as [| z l' IH]; intros x H y Hy.
  - destruct Hy.
  - destruct (sorted_cons_inv _ _ _ H) as [Hxz Hs].
    simpl in Hy. destruct Hy as [Hz_eq | Hy_in].
    + subst z. exact Hxz.
    + apply (Nat.le_trans x z y).
      * exact Hxz.
      * exact (IH z Hs y Hy_in).
Qed.
```

为什么 `revert x`：归纳步里尾部的新头 `z` 要请出「`z` 压得住 `l'`」这条假设——它正是同一引理换了个头，所以归纳假设必须对**任意头**可用（第 15 章加强归纳假设的老招）。基例 `destruct Hy` 一击必杀：`In y []` 就是 `False`。归纳步 `sorted_cons_inv` 拆出 `x <= z` 与 `sorted (z :: l')`；`simpl in Hy` 把 `In y (z :: l')` 展成 `z = y \/ In y l'`，`destruct Hy as [Hz_eq | Hy_in]` 分两路：`y` 就是 `z`，`subst z` 后 `exact Hxz`；`y` 在更深处，`Nat.le_trans` 串起 `x <= z` 与 IH 给的 `z <= y`（`IH z Hs y Hy_in` 把三个参数一次喂齐）。

主战场：

```coq
Lemma sorted_nth_error_le : forall al,
  sorted al ->
  forall i j iv jv,
    i < j -> nth_error al i = Some iv -> nth_error al j = Some jv ->
    iv <= jv.
Proof.
  intros al H i. revert al H.
  induction i as [| i IH]; intros al H j iv jv Hlt Hi Hj.
  - (* i = 0：iv 必是表头，jv 是尾部某个元素 *)
    destruct al as [| x l].
    + discriminate Hi.
    + simpl in Hi. injection Hi as Hiv. subst iv.
      destruct j as [| j'].
      * lia.
      * simpl in Hj. apply nth_error_In in Hj.
        exact (sorted_hd_le x l H jv Hj).
  - (* i = S i：两边下标都往尾部退一格，用归纳假设 *)
    destruct al as [| x l].
    + discriminate Hi.
    + destruct j as [| j'].
      * lia.
      * simpl in Hi. simpl in Hj.
        assert (Hlt' : i < j') by lia.
        exact (IH l (sorted_tail x l H) j' iv jv Hlt' Hi Hj).
Qed.

Theorem sorted_sorted_spec : forall al, sorted al -> sorted_spec al.
Proof.
  intros al H. exact (sorted_nth_error_le al H).
Qed.
```

`sorted_nth_error_le` 把引理写成对下标 `i` 归纳（`revert al H` 让列表随归纳走）。`i = 0` 分支：列表为空则 `discriminate Hi`（`None = Some iv` 冲突）；非空则 `simpl in Hi` 得 `Some x = Some iv`，`injection Hi as Hiv` + `subst iv` 认定 iv 就是表头。`j` 为 0 与 `0 < 0` 冲突，`lia` 收掉；`j = S j'` 则 `simpl in Hj` 把 cons 消掉，`nth_error_In` 把「第 j' 位是 jv」翻成 `In jv l`，交给 `sorted_hd_le`。`i = S i` 分支**两边的下标都要退格**：`j = 0` 照例 `lia` 消失；`j = S j'` 时 `simpl in Hi. simpl in Hj.` 一起消掉表头，`assert (Hlt' : i < j') by lia` 把 `S i < S j'` 整理成 IH 要的 `i < j'`，最后 `exact (IH l (sorted_tail x l H) ...)` 一次喂六个参数。`sorted_sorted_spec` 一行 `exact` 收编——`sorted_spec` 展开后就是 `sorted_nth_error_le` 的形状。

方向二（存在式 → 构造式）反而短：

```coq
(* 方向二：存在式规格只要「点到两个下标」，归纳一步还一步 *)
Lemma sorted_spec_cons : forall x l,
  sorted_spec (x :: l) -> sorted_spec l.
Proof.
  intros x l H i j iv jv Hlt Hi Hj.
  apply (H (S i) (S j) iv jv).
  - lia.
  - simpl. exact Hi.
  - simpl. exact Hj.
Qed.

Lemma sorted_spec_sorted : forall al, sorted_spec al -> sorted al.
Proof.
  induction al as [| x l IH]; intros H.
  - constructor.
  - destruct l as [| y l'].
    + constructor.
    + assert (Hxy : x <= y).
      { apply (H 0 1 x y).
        - lia.
        - reflexivity.
        - reflexivity. }
      constructor.
      * exact Hxy.
      * apply IH. apply (sorted_spec_cons x (y :: l')). exact H.
Qed.
```

`sorted_spec_cons` 展示存在式证据的唯一用法——**specialize 到具体下标再挖**：把 `S i`、`S j` 喂回假设 `H`，两个 `simpl. exact Hi/Hj` 证明 cons 版的 nth_error 就是去掉头部的版本，`lia` 管 `S i < S j`。`sorted_spec_sorted` 对列表归纳：空表与单元素 `constructor` 直接落 `sorted_nil`/`sorted_1`；两个以上时 `apply (H 0 1 x y)` **点名下标 0 和 1**，两条 `nth_error (x :: y :: l') 0/1 = Some x/Some y` 都是 `reflexivity`（定义一步归约），拿到 `x <= y` 后 `constructor` 落 `sorted_cons`，尾部靠 `IH` 与 `sorted_spec_cons`（显式给 `x (y :: l')` 两个参数，`exact H` 收尾）。

```coq
Theorem sorted_iff_sorted_spec : forall al, sorted al <-> sorted_spec al.
Proof.
  intros al. split.
  - apply sorted_sorted_spec.
  - apply sorted_spec_sorted.
Qed.

(* 使用上的差别（实测）：
   - 构造式规格的证据能拆：sorted_cons_inv 就是一次 inversion；
     存在式规格的证据只能 specialize 到具体下标再「挖」；
   - 等价 != 同难度：证 insert 保序时归纳版顺手得多，
     存在式版要绕 nth_error 的中转引理（VFA 把它列为 5 星习题） *)
```

`sorted_iff_sorted_spec` 合上环。但等价 ≠ 同难度——这是 VFA 反复强调的教训：方向一要自备 `sorted_hd_le`、要处理双下标退格；证明 `insert` 保序时，归纳版顺手得多，存在式版要绕 `nth_error` 的中转引理（VFA 把它列为 5 星习题）。**规格怎么写，直接决定证明有多难**；而构造式规格的证据能 `inversion` 拆（`sorted_cons_inv` 就是演示）、存在式只能 specialize——两种风格等价，手感不同。

### 38.5 让判定机真跑起来：透明度与公理

最后一公里：判定机在 `Compute`/`if` 里真的算，需要什么？

```coq
(* ---------- 38.5 让判定机真跑起来：透明度与公理 ---------- *)

(* sumbool 住在 Set 里（参数是 Prop，类型本身不是），
   所以它能当 if 的被检查项——这是 {P}+{~P} 比 P\/~P 强的地方：
   Axiom lt_or_axiom : forall i j : nat, i < j \/ ~ (i < j).
   Definition max_or (i j : nat) : nat :=
     if lt_or_axiom i j then j else i.
   上面两行编不过（实测）：or 住在 Prop 里，不许 match 出一个 nat——
   「Incorrect elimination ... in the inductive type or」 *)

Axiom lt_dec_axiom : forall i j : nat, {i < j} + {~ (i < j)}.

Definition max_with_axiom (i j : nat) : nat :=
  if lt_dec_axiom i j then j else i.

(* 公理版能编过、能证明，但算不动 *)
Eval compute in (max_with_axiom 3 7).
(* = if lt_dec_axiom 3 7 is left _ then 7 else 3 : nat ——卡在公理上 *)

Lemma prove_with_axiom : max_with_axiom 3 7 = 7.
Proof.
  unfold max_with_axiom.
  destruct (lt_dec_axiom 3 7) as [Hlt | Hn].
  - reflexivity.
  - exfalso. apply Hn. lia.
Qed.
```

关键差别在**类型住在哪个世界**：`sumbool` 的定义是 `Inductive sumbool (A B : Prop) : Set`——参数是 Prop，类型本身住在 Set，所以能当 `if` 的被检查项、能算。注释里那两行 `P \/ ~P` 版的 `max_or` 实测编不过：`or` 住在 Prop 里，Prop 的归纳值不许消去出 Set 的结果（错误原话 `Incorrect elimination ... in the inductive type or`，还附赠一条「非 bool 的 if」弃用警告）。`lt_dec_axiom` 把排中律**对 nat 的小于**声明成 sumbool 版公理（这是一致的公理，加它不会证出 False）：`max_with_axiom` 能编过、能证明，但 `Eval compute` 的实测输出卡在公理上——`if lt_dec_axiom 3 7 is left _ then 7 else 3`，一步没走。`prove_with_axiom` 展示它能**证**不能**算**：`destruct (lt_dec_axiom 3 7)` 做案例分析（公理值也能 destruct），左分支 `reflexivity`，右分支 `exfalso. apply Hn. lia.`——`Hn : ~ (3 < 7)` 要一个 `3 < 7`，`lia` 供应。

不用公理会怎样？拿 38.1 自己的桥试试：

```coq
(* 公理不是必需的。但拿 38.1 的桥造 sumbool 也会卡：
   leb_reflect 是 Qed 收尾的——不透明定理算不动 *)
Definition leb_dec_opaque (a b : nat) : {a <= b} + {~ a <= b} :=
  match leb_reflect a b with
  | ReflectT _ P => left P
  | ReflectF _ Q => right Q
  end.

Eval compute in (leb_dec_opaque 3 7).
(* = match leb_reflect 3 7 with
     | ReflectT _ P => left P
     | ReflectF _ Q => right Q
     end : {3 <= 7} + {~ 3 <= 7} ——卡在不透明的 Qed 上 *)

(* 最小对照：换一座 Defined 收尾的小桥，就能算到底 *)
Lemma zerop_reflect : forall n : nat, reflect (n = 0) (Nat.eqb n 0).
Proof.
  destruct n as [| m].
  - apply ReflectT. reflexivity.
  - apply ReflectF. intros H. discriminate H.
Defined.

Definition zerop_dec (n : nat) : {n = 0} + {n <> 0} :=
  match zerop_reflect n with
  | ReflectT _ P => left P
  | ReflectF _ Q => right Q
  end.

Compute (if zerop_dec 5 then 1 else 2).    (* = 2 : nat ——算出来了 *)
Compute (if zerop_dec 0 then 1 else 2).    (* = 1 : nat *)

(* 给 <= 造一台从头透明的判定机，要连依赖的每个引理都 Defined——
   工程上直接用标准库造好的（它们就是为此全程透明） *)
Check le_dec.
Compute (if le_dec 3 7 then true else false).    (* = true : bool *)

Example le_dec_computes : (if le_dec 3 7 then true else false) = true.
Proof. reflexivity. Qed.

Print Assumptions le_dec_computes.
(* Closed under the global context——全程没用公理 *)

End Ex38Decide.
```

`leb_dec_opaque` 用 reflect 造 sumbool 的标准姿势：`match leb_reflect a b with ReflectT _ P => left P | ReflectF _ Q => right Q end`（reflect 的两个构造子各带一个证明，直接转给 `left`/`right`）。但 `Eval compute` 卡住了——输出里 `match leb_reflect 3 7 with ...` 原样躺着。原因：**`Qed` 收尾的引理是不透明的**，`compute` 展不开它。第 31 章说过「桥定理 Qed 没关系，判定函数透明就行」——那是因为当时只在**证明**里用桥；现在要把桥当**程序**跑，桥自己也必须透明。

`zerop_reflect` 是最小对照：同一套证明脚本（`destruct n`，`ReflectT reflexivity` / `ReflectF + discriminate`），收尾从 `Qed` 换成 `Defined`。`zerop_dec` 同样的 match 造法，两个 `Compute` 真的算出 `2` 和 `1`。一词之差，能不能算。想给 `<=` 造一台从头透明的判定机，就得把 `leb_reflect` 及其依赖的每个引理全部 `Defined` 到底（`le_S_n` 一类引理都得自己透明重造）；工程上的答案是直接用标准库——`Check le_dec` 显示它就是 `{n <= m} + {~ n <= m}`，`Compute (if le_dec 3 7 ...)` 实测答 `true`，因为标准库造它时就是为此全程透明。`le_dec_computes` 用 `reflexivity` 一步证明；`Print Assumptions` 的实测输出 `Closed under the global context` 盖章：全程没用公理。

收个尾。可判定规格三件套——**谓词给人证、判定机给机器跑、reflect 桥保证两个世界说同一件事**；可判定性从元素类型继承（38.3），构造式与存在式两种风格等价但手感不同（38.4），透明度决定判定机能不能算（38.5）。第 39 章马上用得上：二叉搜索树的 `insert`/`lookup` 处处是 `Nat.leb` 的决策，`elements` 的无重复性正是本章的 no_dup——到时你会发现那一章的证明就是本章三件套的连播。

### 38.6 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`sortedb` 递归写成 `sortedb (y :: l')` 编不过**（38.2）：终止检查器报 `Recursive call to sortedb has principal argument equal to "y :: l'"`——`y :: l'` 是现拼的新树，不是子项变量。改成嵌套 match、递归直接落在 `l'` 上。
2. **reflect 桥的证明里乱用 `simpl` 会自锁**（38.2）：`simpl` 把 `sortedb (y :: l')` 连带展开成卡住的 `match`，之后 `apply ReflectT` 报 `Unable to unify "reflect ?P true"`（目标里是 `true && <卡住的 match>`，归约不到 `true`）。对策：写一行展开引理（`sortedb_cons_cons`，`reflexivity` 即证）再 `rewrite`。
3. **reflect 证明只 destruct 一个 bool 不够**（38.2）：目标残留 `Nat.leb x y && false` 这种表达式，`true`/`false` 构造子都对不上。比较结果与递归结果**两个 bool 都要 destruct**，四种组合才各归约到字面 `true`/`false`；`destruct IH`（对 reflect 用依赖消去）会顺手把目标里的递归调用替换掉。
4. **sorted_spec 方向一要「双下标退格」**（38.4）：归纳在 `i` 上时，`j` 也得 `destruct` 成 `S j'` 并 `simpl in Hj`——只退 `i` 不退 `j`，IH 要 `i < j'` 而手里只有 `S i < S j'`（实测报 `The term "Hlt" has type "S i < j"`）。`assert (Hlt' : i < j') by lia` 先整理再喂。另：`sorted (x :: l)` 退 `sorted l` 需要 `sorted_tail`（单元素情形尾部是 `[]`）。
5. **`if` 拿 `\/` 值当被检查项编不过**（38.5）：`or` 住在 Prop 里，实测报 `Incorrect elimination of ... in the inductive type "or": the return type has sort "Set"`（另附 non-boolean-if 弃用警告）。sumbool 的定义是 `Inductive sumbool (A B : Prop) : Set`——参数是 Prop、类型本身在 Set，这才配当 `if` 的被检查项。
6. **Qed 的桥造不出能算的判定机**（38.5）：`match leb_reflect a b with ... end` 配 `Eval compute`，输出原样卡在 `leb_reflect 3 7` 上——`Qed` = 不透明。要算就 `Defined`（`zerop_reflect` 实测能算到底），且依赖的每个引理都得透明；省事的路线是用标准库的 `le_dec`（实测 `Compute` 答 `true`）。
7. **`Compute` Prop 规格得到的是没算完的命题**（38.3）：`Compute (no_dup [1; 2])` 实测输出 `(2 = 1 \/ False -> False) /\ (False -> False) /\ True : Prop`——`2 = 1` 来自 `In` 的定义方向（`In a (b :: m)` 是 `b = a \/ ...`），`-> False` 是 `~` 的展开。这不是 bug 是本质：Prop 里的否定与析取是**待证命题**不是可执行比较，想要答案就得另配 bool 判定机。

---
上一章：[37 · 多重集：另一种规格风格](37-multiset.md) ｜ 下一章：[39 · 二叉搜索树的验证](39-searchtree.md) ｜ 返回：[README](../README.md)
