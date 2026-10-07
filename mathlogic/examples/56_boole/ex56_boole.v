(* ex50 —— Boole 代数与逻辑电路（Jongsma ch7 §7.3-7.6）
   bax —— B={0,1} 是 Boole 代数：十公理逐条机器验证（书 §7.3.3 的
          例 7.3.3；orb=+、andb=·、negb=补、false=0、true=1）；
   bprops —— 公理的推论精选（书 Prop 7.3.1-7.3.9）：幂等/湮灭/吸收/
          De Morgan/对合与 0̅=1/运算联动（iff！书 Prop 7.3.6 的
          「普遍双条件」形态）/冗余/共识/消去律；
   gates —— 门动物园（书 Table 7.1）：nand/nor 的 De Morgan 形、
          xnor=等值门（可接受串 00 与 11）；
   adders —— 加法器（书例 7.4.9/7.4.10）：半加器/全加器（两个半加器
          拼装）/两位行波进位加法器，布尔电路做 nat 算术（Shannon
          1938 的核心贡献）；
   minterm —— minterm 表示定理（书 Thm 7.5.1 的 n=2 一般机器版
          dnf2：任意 f:B*B->B 等于其接受行的 minterm 展开）+ 三元
          多数函数实例（书例 7.5.5/7.5.6）；
   QMC（书 §7.6.5）在 Prolog 通道 ex56_boole.pl。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 1. B={0,1}：十公理验证（书 §7.3.3 例 7.3.3） ---------- *)

Lemma b_comm_or : forall x y, orb x y = orb y x.
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma b_comm_and : forall x y, andb x y = andb y x.
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma b_assoc_or : forall x y z, orb (orb x y) z = orb x (orb y z).
Proof. intros; destruct x, y, z; reflexivity. Qed.

Lemma b_assoc_and : forall x y z, andb (andb x y) z = andb x (andb y z).
Proof. intros; destruct x, y, z; reflexivity. Qed.

(* 第二分配律：+ 对 · 也分配——普通算术没有（1+2*3=7 ≠ 12） *)
Lemma b_dist_and : forall x y z,
    andb x (orb y z) = orb (andb x y) (andb x z).
Proof. intros; destruct x, y, z; reflexivity. Qed.

Lemma b_dist_or : forall x y z,
    orb x (andb y z) = andb (orb x y) (orb x z).
Proof. intros; destruct x, y, z; reflexivity. Qed.

Lemma b_ident_or : forall x, orb x false = x.
Proof. intros; destruct x; reflexivity. Qed.

Lemma b_ident_and : forall x, andb x true = x.
Proof. intros; destruct x; reflexivity. Qed.

Lemma b_compl_or : forall x, orb x (negb x) = true.
Proof. intros; destruct x; reflexivity. Qed.

Lemma b_compl_and : forall x, andb x (negb x) = false.
Proof. intros; destruct x; reflexivity. Qed.

(* ---------- 2. 公理的推论（书 Prop 7.3.1-7.3.9 精选） ---------- *)

Lemma b_idem_or : forall x, orb x x = x.
Proof. intros; destruct x; reflexivity. Qed.

Lemma b_idem_and : forall x, andb x x = x.
Proof. intros; destruct x; reflexivity. Qed.

(* 湮灭律（书 Prop 7.3.4ab） *)
Lemma b_annih_and : forall x, andb x false = false.
Proof. intros; destruct x; reflexivity. Qed.

Lemma b_annih_or : forall x, orb x true = true.
Proof. intros; destruct x; reflexivity. Qed.

(* 吸收律（书 Prop 7.3.4cd） *)
Lemma b_absorb_and : forall x y, andb x (orb x y) = x.
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma b_absorb_or : forall x y, orb x (andb x y) = x.
Proof. intros; destruct x, y; reflexivity. Qed.

(* 补元律（书 Prop 7.3.2）：0̅=1、1̅=0、x̿=x *)
Lemma b_not_false : negb false = true.  Proof. reflexivity. Qed.
Lemma b_not_true : negb true = false.   Proof. reflexivity. Qed.
Lemma b_not_not : forall x, negb (negb x) = x.
Proof. intros; destruct x; reflexivity. Qed.

(* De Morgan（书 Prop 7.3.5） *)
Lemma b_demorgan_and : forall x y, negb (andb x y) = orb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma b_demorgan_or : forall x y, negb (orb x y) = andb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.

(* 运算联动律（书 Prop 7.3.6）：普遍双条件，不是等式族 *)
Lemma b_linkage : forall x y, andb x y = x <-> orb x y = y.
Proof.
  intros x y; destruct x, y; simpl; split; intro H;
    (reflexivity || discriminate H).
Qed.

(* 冗余律（书 Prop 7.3.7） *)
Lemma b_redund_and : forall x y, andb x (orb (negb x) y) = andb x y.
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma b_redund_or : forall x y, orb x (andb (negb x) y) = orb x y.
Proof. intros; destruct x, y; reflexivity. Qed.

(* 共识律（书 Prop 7.3.8a：xy + x̄z + yz = xy + x̄z。
   注意：中间项必须带补 x̄——PDF 文本层丢上杠，须按数学实体校读 *)
Lemma b_consensus : forall x y z,
    orb (orb (andb x y) (andb (negb x) z)) (andb y z)
    = orb (andb x y) (andb (negb x) z).
Proof. intros; destruct x, y, z; reflexivity. Qed.

(* 消去律（书 Prop 7.3.9）：两个前提缺一不可——
   x=0 时靠 + 等式，x=1 时靠 · 等式 *)
Lemma b_cancel : forall x y z,
    andb x y = andb x z -> orb x y = orb x z -> y = z.
Proof.
  intros x y z H1 H2; destruct x.
  - simpl in H1. exact H1.
  - simpl in H2. exact H2.
Qed.

(* ---------- 3. 门动物园（书 Table 7.1） ---------- *)

Definition nand (x y : bool) : bool := negb (andb x y).
Definition nor (x y : bool) : bool := negb (orb x y).
Definition xnor (x y : bool) : bool := negb (xorb x y).

(* 门表达式与 De Morgan 形一致（表末列） *)
Lemma nand_form : forall x y, nand x y = orb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.

Lemma nor_form : forall x y, nor x y = andb (negb x) (negb y).
Proof. intros; destruct x, y; reflexivity. Qed.

(* xor 的积之和形：可接受串恰为 01 与 10 *)
Lemma xor_form : forall x y,
    xorb x y = orb (andb x (negb y)) (andb (negb x) y).
Proof. intros; destruct x, y; reflexivity. Qed.

(* xnor 可接受 00 与 11——等值门 *)
Lemma xnor_accept : forall x y, xnor x y = true <-> x = y.
Proof.
  intros x y; destruct x, y; simpl; split; intro H;
    (reflexivity || discriminate H).
Qed.

(* ---------- 4. 加法器：布尔电路做算术（书例 7.4.9/7.4.10） ---------- *)

Definition bval (b : bool) : nat := if b then 1 else 0.

(* 半加器：和位=xor、进位=and（书例 7.4.9b） *)
Definition ha (x y : bool) : bool * bool := (xorb x y, andb x y).

Lemma ha_correct : forall x y,
    bval (fst (ha x y)) + 2 * bval (snd (ha x y)) = bval x + bval y.
Proof. intros; destruct x, y; reflexivity. Qed.

(* 全加器：两个半加器拼装（书例 7.4.10 / Ex 7.4.43） *)
Definition fa (w x y : bool) : bool * bool :=
  let (s1, c1) := ha x y in
  let (s2, c2) := ha w s1 in
  (s2, orb c1 c2).

Lemma fa_correct : forall w x y,
    bval (fst (fa w x y)) + 2 * bval (snd (fa w x y))
    = bval w + bval x + bval y.
Proof. intros; destruct w, x, y; reflexivity. Qed.

(* 两位行波进位：低位半加器出进位，高位全加器吃进位 *)
Definition add2 (a1 a0 b1 b0 : bool) : bool * bool * bool :=
  let (s0, c0) := ha a0 b0 in
  let (s1, c1) := fa a1 b1 c0 in
  (c1, s1, s0).

(* (c1, s1, s0) 是嵌套对 ((c1,s1),s0)——fst/snd 逐层取 *)
Lemma add2_correct : forall a1 a0 b1 b0,
    bval (snd (add2 a1 a0 b1 b0))
    + 2 * bval (snd (fst (add2 a1 a0 b1 b0)))
    + 4 * bval (fst (fst (add2 a1 a0 b1 b0)))
    = (2 * bval a1 + bval a0) + (2 * bval b1 + bval b0).
Proof. intros; destruct a1, a0, b1, b0; reflexivity. Qed.

(* ---------- 5. minterm 表示定理（书 Thm 7.5.1 的机器版） ---------- *)

(* 文字：s=1 取正文字 x，s=0 取反文字 x̅ *)
Definition lit (s x : bool) : bool := if s then x else negb x.

(* 单个 minterm 恰接受一个输入串（书 Prop 7.5.2 的核心） *)
Lemma minterm_accept : forall s1 s2 x1 x2,
    andb (lit s1 x1) (lit s2 x2) = true <-> (x1 = s1 /\ x2 = s2).
Proof.
  intros s1 s2 x1 x2; destruct s1, s2, x1, x2; simpl;
    split; intro H;
    first [ reflexivity
          | discriminate H
          | split; reflexivity
          | destruct H as [H1 H2]; first [discriminate H1 | discriminate H2] ].
Qed.

(* n=2 一般定理：任意 f 都等于其接受行 minterm 之和。
   系数写在 minterm 右侧（andb 先匹配左字面量，保证化简可行） *)
Theorem dnf2 : forall (f : bool -> bool -> bool) (x y : bool),
    f x y =
    orb (andb (andb (lit true x) (lit true y)) (f true true))
        (orb (andb (andb (lit true x) (lit false y)) (f true false))
            (orb (andb (andb (lit false x) (lit true y)) (f false true))
                (andb (andb (lit false x) (lit false y)) (f false false)))).
Proof.
  intros f x y; destruct x, y; simpl;
    try rewrite orb_false_r; reflexivity.
Qed.

(* 三元多数函数（书例 7.5.5/7.5.6）：简化形 = minterm 展开 *)
Definition maj (x y z : bool) : bool :=
  orb (andb x y) (orb (andb x z) (andb y z)).

Lemma maj_dnf : forall x y z, maj x y z =
    orb (andb (andb x y) z)
        (orb (andb (andb x y) (negb z))
            (orb (andb (andb x (negb y)) z)
                (andb (andb (negb x) y) z))).
Proof. intros; destruct x, y, z; reflexivity. Qed.

(* ---------- 6. 冒烟与账本 ---------- *)

Compute (maj true false true).   (* true：两票即可 *)
Compute (fst (ha true true)).    (* false：1+1=10，和位 0 *)
Compute (snd (fa true true true)).  (* true：1+1+1=11，进位 1 *)
Compute (add2 true false false true).  (* (false,true,true)：10+01=11 *)

Print Assumptions b_dist_or.
Print Assumptions b_consensus.
Print Assumptions b_cancel.
Print Assumptions ha_correct.
Print Assumptions fa_correct.
Print Assumptions add2_correct.
Print Assumptions dnf2.
Print Assumptions maj_dnf.
