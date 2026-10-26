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
