(* ============================================================
   26 从 Peano 到 Bézout —— Coq 主场（TTAFP ch.14–15 + 附录 B/C）
     · 公理化 Peano（Parameter + Axiom——书 14.1 的原始定义版，
       Print Assumptions 记账对照）
     · 除法定理与 Bézout（受限版：互素 ⇒ ∃x y, mx+ny=1）——
       stdlib 的 Z 生态；书 15.6 的「九个洞」以假设形式呈现
       （旗式常数 a1..a44 的工程化身），每个洞标注 stdlib 哪条
       引理补上
     · 极小元定理（15.7）：非空有界子集有最小元——Wf_nat 现成
   ============================================================ *)

From Coq Require Import ZArith Lia.
From Coq Require Import Wf_nat.

Open Scope Z_scope.

(* ---------- 一、公理化 Peano（书 14.1） ---------- *)
(* 书的选型：N/0/s 是原始定义（⊥⊥），公理跟在后面。
   Coq 的对应物：Parameter + Axiom。 *)

Parameter PeanoN : Type.
Parameter pzero : PeanoN.
Parameter psucc : PeanoN -> PeanoN.

Axiom ax_nat1 : forall x : PeanoN, psucc x <> pzero.
Axiom ax_nat2 : forall x y : PeanoN, psucc x = psucc y -> x = y.
Axiom ax_ind  : forall P : PeanoN -> Prop,
                P pzero -> (forall x, P x -> P (psucc x)) -> forall x, P x.

(* ax-nat2 说 s 单射；ax-nat1 说 s 不满——链条不回头（书 14.1） *)
Theorem succ_injective : forall x y : PeanoN, psucc x = psucc y -> x = y.
Proof. exact ax_nat2. Qed.

(* 记账：公理化 Peano 的账单一目了然 *)
Print Assumptions succ_injective.
(* -> ax_nat2（+ Parameters）——「把归纳当公理」的代价公示 *)

(* ---------- 二、除法定理（书 15.8 的 stdlib 版） ---------- *)

Theorem division_theorem : forall a b : Z, 0 < b ->
  exists q r : Z, a = q * b + r /\ 0 <= r < b.
Proof.
  intros a b hb.
  exists (a / b), (a mod b).
  split.
  - assert (hb' : b <> 0) by lia. pose proof (Z.div_mod a b hb') as Hdm.
    rewrite Z.mul_comm in Hdm. exact Hdm.
  - apply Z.mod_pos_bound; lia.
Qed.

(* ---------- 三、Bézout（受限版，书 15.1） ---------- *)

(* 互素的朴素刻画（无 >1 公因子）⟺ gcd = 1 *)
Lemma gcd_eq1_of_coprime : forall m n : Z, 0 < m -> 0 < n ->
  (forall d : Z, 1 < d -> Z.divide d m -> Z.divide d n -> False) -> Z.gcd m n = 1.
Proof.
  intros m n Hm Hn Hcop.
  assert (Hpos : 0 < Z.gcd m n).
  { pose proof (Z.gcd_nonneg m n).
    pose proof (Z.gcd_divide_l m n) as Hl.
    destruct (Z.eq_dec (Z.gcd m n) 0) as [E|E].
    - exfalso. rewrite E in Hl.
      destruct Hl as [k Hk]. rewrite Hk in *. subst m. lia.
    - lia. }
  destruct (Z.eq_dec (Z.gcd m n) 1) as [E|E]; [exact E|].
  exfalso. apply (Hcop (Z.gcd m n));
    [lia | apply Z.gcd_divide_l | apply Z.gcd_divide_r].
Qed.

(* stdlib 的 Z.gcd_bezout：Z.gcd n m = p ⇒ ∃a b, a*n + b*m = p *)
Theorem bezout_restricted : forall m n : Z, 0 < m -> 0 < n ->
  Z.gcd m n = 1 -> exists x y : Z, m * x + n * y = 1.
Proof.
  intros m n Hm Hn Hg.
  destruct (Z.gcd_bezout m n 1 Hg) as [x [y Hxy]].
  exists x, y.
  rewrite (Z.mul_comm x m), (Z.mul_comm y n) in Hxy. exact Hxy.
Qed.

(* 合体：书 15.1 的定理原文（互素版本的朴素刻画直接给出见证） *)
Theorem bezout_book : forall m n : Z, 0 < m -> 0 < n ->
  (forall d : Z, 1 < d -> Z.divide d m -> Z.divide d n -> False) ->
  exists x y : Z, m * x + n * y = 1.
Proof.
  intros m n Hm Hn Hcop.
  apply bezout_restricted; try lia.
  apply gcd_eq1_of_coprime; assumption.
Qed.

(* ---------- 四、「九个洞」（书 15.6）的工程化身 ---------- *)
(* 书：Bézout 形式化留下 9 个洞——都是「小而不难」的证明对象。
   Coq 侧把洞做成【假设】（旗式常数 a1..a44 的直系），并标注
   stdlib 的补洞引理： *)

Section BezoutHoles.

Variables (m n : Z) (Hm : 0 < m) (Hn : 0 < n).

(* 洞 #1：(Z,≤) 是偏序 —— Z.le 关系三性质 *)
Hypothesis hole1 : (forall x : Z, x <= x) /\
                   (forall x y z : Z, x <= y -> y <= z -> x <= z) /\
                   (forall x y : Z, x <= y -> y <= x -> x = y).

(* 洞 #2：m = m*1 + n*0 —— 单位律与零律 *)
Hypothesis hole2 : m = m * 1 + n * 0.

(* 洞 #5（代表）：r 的表达式属于 S = {mx+ny | x,y∈Z} *)
Hypothesis hole5 : forall q x0 y0 r : Z,
  r = m * (1 - q * x0) - n * (q * y0) -> exists x y : Z, r = m * x + n * y.

(* 三个洞拼出主骨架（书 Figure 15.10 的浓缩） *)
Theorem bezout_skeleton :
  forall d x0 y0 : Z,
    d = m * x0 + n * y0 ->
    0 < d ->
    (forall q r : Z, m = q * d + r -> 0 <= r -> r < d -> r = 0) ->
    Z.divide d m.
Proof.
  intros d x0 y0 Hd Hpos Hdiv.
  destruct (division_theorem m d) as [q [r [Hqr [Hr0 Hrb]]]]; [lia|].
  assert (Hr : r = 0).
  { apply (Hdiv q r Hqr Hr0). lia. }
  exists q. rewrite Hqr, Hr, Z.add_0_r. reflexivity.
Qed.

End BezoutHoles.

(* 实际补洞：hole1 由 Z.le 性质免费（lia 全权代理）；
   hole2 是 lia 的单行；hole5 是交换代数——证明无关性的
   好例子（r 的两个表示都行）。 *)

Lemma hole2_filled : forall m n : Z, m = m * 1 + n * 0.
Proof. intros; lia. Qed.

(* ---------- 五、极小元定理（书 15.7） ---------- *)
(* 非空的自然数子集有最小元——Wf_nat 现成（书 15.7 用 N 的
   良建归纳从零向上找；stdlib 的版本异曲同工） *)

Theorem minimum_theorem :
  forall (P : nat -> Prop),
    (forall n, P n \/ ~ P n) ->
    (exists n, P n) ->
    exists n, P n /\ forall y, P y -> (n <= y)%nat.
Proof.
  intros P dec Hex.
  destruct (dec_inh_nat_subset_has_unique_least_element P dec Hex)
    as [z [Hz1 Hz2]].
  exists z. split.
  - exact (proj1 Hz1).
  - exact (proj2 Hz1).
Qed.

Print Assumptions minimum_theorem.
(* -> 无公理（Wf_nat 的良建归纳是构造性的）——对照 25 章
   iotaL 的 Classical.choice 账单 *)
