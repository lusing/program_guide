(* 第 114 章：Solovay 内模型与 HOD(Ω)——参数化定义与群作用交换、
   不变对象、HOD 闭包遗传、哥德尔配对整合、DC 链（引理 3.22 的
   机制核；本体留在正文 docs/114-solovay.md）。 *)
Require Import List Arith Lia Bool.
Import ListNotations.

(* ── 一、Z/8 窗口与生成元 ── *)
(* rot = (x+2) mod 8 的分支形：lia 不解 mod，用 if 分支钉住。 *)
Definition rot (x : nat) : nat := if Nat.ltb x 6 then x + 2 else x - 6.

(* 窗口枚举：lia 证的八分案。 *)
Lemma nat8_cases : forall x, x < 8 ->
  x = 0 \/ x = 1 \/ x = 2 \/ x = 3 \/ x = 4 \/ x = 5 \/ x = 6 \/ x = 7.
Proof. intros x hx; lia. Qed.

(* 窗口内周期四（轨道大小整除 4）：八分案 + 字面量计算。 *)
Lemma rot4_id : forall x, x < 8 -> rot (rot (rot (rot x))) = x.
Proof.
  intros x hx.
  destruct (nat8_cases x hx) as [E|[E|[E|[E|[E|[E|[E|E]]]]]]]; subst x;
    reflexivity.
Qed.

(* ── 二、参数化谓词（OD 的影子）与群作用交换 ──
   三点星形 {k, k+3, k+5}（mod 8）在窗口 0..7 内恰为线性方程组
   k=x ∨ k+3=x ∨ k+3=x+8 ∨ k+5=x ∨ k+5=x+8（无 mod——lia 可达）。 *)
Definition odefP (k x : nat) : Prop :=
  k = x \/ k + 3 = x \/ k + 3 = x + 8 \/ k + 5 = x \/ k + 5 = x + 8.

(* 件 A：定义与生成元交换（一般 j 由生成元迭代归纳，机制同）。 *)
Lemma odefP_rot : forall k x, k < 8 -> x < 8 ->
  (odefP (rot k) (rot x) <-> odefP k x).
Proof.
  intros k x hk hx.
  destruct (nat8_cases x hx) as [Ex|[Ex|[Ex|[Ex|[Ex|[Ex|[Ex|Ex]]]]]]]; subst x;
  destruct (nat8_cases k hk) as [Ek|[Ek|[Ek|[Ek|[Ek|[Ek|[Ek|Ek]]]]]]]; subst k;
    unfold odefP, rot; simpl; lia.
Qed.

(* ── 三、不变对象与轨道封闭 ── *)
Lemma mod_add2 : forall a b, (a + b * 2) mod 2 = a mod 2.
Proof. intros a b. apply Nat.Div0.mod_add. Qed.

Lemma evens_rot : forall x, x mod 2 = 0 <-> rot x mod 2 = 0.
Proof.
  intros x. unfold rot.
  destruct (Nat.ltb x 6) eqn:E.
  - apply Nat.ltb_lt in E.
    replace (x + 2) with (x + 1 * 2) by lia.
    rewrite mod_add2. reflexivity.
  - apply Nat.ltb_ge in E.
    remember (x - 6) as y eqn:Ey.
    replace x with (y + 3 * 2) by lia.
    rewrite mod_add2. reflexivity.
Qed.

Definition orbit4 (x : nat) : list nat :=
  [x; rot x; rot (rot x); rot (rot (rot x))].

Lemma orbit_closed : forall x, x < 8 ->
  forall y, In y (orbit4 x) -> In (rot y) (orbit4 x).
Proof.
  intros x hx y Hy. unfold orbit4 in Hy. simpl in Hy.
  destruct Hy as [E1 | [E2 | [E3 | [E4 | []]]]]; subst y.
  - simpl; right; left; reflexivity.
  - simpl; right; right; left; reflexivity.
  - simpl; right; right; right; left; reflexivity.
  - rewrite rot4_id by lia. simpl; left; reflexivity.
Qed.

(* ── 四、HOD 闭包遗传（燃料递归） ── *)
Definition parts (x : nat) : list nat :=
  if Nat.eqb x 0 then [] else [x / 2].

Definition inOD (p x : nat) : bool :=
  (Nat.eqb (x mod 8) (p mod 8))
  || (Nat.eqb (x mod 8) ((p + 3) mod 8))
  || (Nat.eqb (x mod 8) ((p + 5) mod 8)).

Fixpoint inHOD (d p x : nat) : bool :=
  match d with
  | 0 => true
  | S d' => inOD p x && forallb (inHOD d' p) (parts x)
  end.

Lemma hod_od : forall d p x, inHOD (S d) p x = true -> inOD p x = true.
Proof.
  intros d p x H. simpl in H. apply andb_prop in H. tauto.
Qed.

Lemma hod_parts : forall d p x, inHOD (S d) p x = true ->
  forall y, In y (parts x) -> inHOD d p y = true.
Proof.
  intros d p x H y Hy. simpl in H.
  apply andb_prop in H as [_ Hall].
  rewrite forallb_forall in Hall. now apply Hall.
Qed.

(* ── 五、窗口配对：哥德尔对应的有限替身（引理 3.22(1)） ── *)
Definition gpair (m k : nat) : nat := m + 8 * k.

Lemma gpair_inj : forall m1 k1 m2 k2,
  m1 < 8 -> m2 < 8 -> gpair m1 k1 = gpair m2 k2 -> m1 = m2 /\ k1 = k2.
Proof.
  intros m1 k1 m2 k2 h1 h2 H. unfold gpair in H. lia.
Qed.

Lemma gpair_decode : forall m k, m < 8 ->
  gpair m k mod 8 = m /\ gpair m k / 8 = k.
Proof.
  intros m k hm. unfold gpair.
  replace (m + 8 * k) with (m + k * 8) by lia.
  rewrite Nat.Div0.mod_add, Nat.mod_small by lia.
  rewrite Nat.div_add by lia.
  rewrite Nat.div_small by lia.
  lia.
Qed.

(* ── 六、DC 链（引理 3.22(2) 机制核） ── *)
Fixpoint dchain (next : nat -> nat) (a : nat) (d : nat) : list nat :=
  match d with
  | 0 => []
  | S d' => a :: dchain next (next a) d'
  end.

Fixpoint chainAll (R : nat -> nat -> bool) (l : list nat) : bool :=
  match l with
  | [] => true
  | x :: t =>
    match t with
    | [] => true
    | y :: _ => R x y && chainAll R t
    end
  end.

Lemma dchain_all : forall (R : nat -> nat -> bool) (next : nat -> nat),
  (forall x, R x (next x) = true) ->
  forall d a, chainAll R (dchain next a d) = true.
Proof.
  intros R next Hnext d. induction d as [| d IH]; intros a.
  - reflexivity.
  - destruct d as [| d'].
    + reflexivity.
    + simpl. apply andb_true_intro; split; [apply Hnext | apply IH].
Qed.

(* ── 七、交接样本（与 Julia/Python 同账） ── *)
Example rot_samples : rot 0 = 2 /\ rot 6 = 0.
Proof. repeat split; reflexivity. Qed.

Example orbit_sample : orbit4 0 = [0; 2; 4; 6].
Proof. reflexivity. Qed.

Example gpair_sample : gpair 3 5 = 43.
Proof. reflexivity. Qed.

Example chain_sample : dchain rot 0 5 = [0; 2; 4; 6; 0].
Proof. reflexivity. Qed.
