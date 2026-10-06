(* ex16_eq —— 等式的自然演绎规则 =i / =e（深嵌入版，H&R §2.3.1 式 (2.5)(2.8)）

   对书：Huth&Ryan §2.3.1（=i 公理 / =e 等量代换）/ §2.4.3（等式语义锚点）

   设计：
   - form 增加 FEq t1 t2 构造子；eform 的等式条款解释为论域（nat）
     上的真实相等——「等式是唯一锁定语义的谓词」（§2.4.3）。
   - nd 演算装载本章需要的规则族：hyp / →i / →e / ∀i / ∀e / =i / =e。
   - =e 的侧条件「t free for x」（H&R 约定 2.10）在本教学版强化为
     「t1 t2 均为闭项」——15 章 subst_all_eval 的侧条件形态，
     使代入交换无条件成立（充分方案；一般化留文档）。
   - 派生件三枚：对称 (2.6)、传递 (2.7)、谓词等量代换（H&R 例题）。

   边界（诚实清单）：等式规则相对 eform 的可靠性大定理
   （nd G f → 全满足 G 则满足 f）需要一致性+代入交换全套组装，
   本章不展开——语义侧只立 FEq 条款与 sanity 现场。 *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法（沿 14 章一元片段 + FEq） ---------- *)

Inductive term : Type :=
| tvar : nat -> term
| fapp : nat -> term -> term.

Inductive form : Type :=
| atom : nat -> term -> form
| fimp : form -> form -> form
| fneg : form -> form
| fall : nat -> form -> form
| feq   : term -> term -> form.        (* 新增：等式原子 *)

Fixpoint fv_term (t : term) : list nat :=
  match t with
  | tvar n => [n]
  | fapp f t' => fv_term t'
  end.

Fixpoint fv (f : form) : list nat :=
  match f with
  | atom p t => fv_term t
  | fimp a b => fv a ++ fv b
  | fneg a => fv a
  | fall y a => remove (Nat.eq_dec) y (fv a)
  | feq t1 t2 => fv_term t1 ++ fv_term t2
  end.

Definition closedT (t : term) : Prop := fv_term t = [].

Fixpoint subst_term (t : term) (x : nat) (s : term) : term :=
  match t with
  | tvar y => if Nat.eqb y x then s else tvar y
  | fapp f t' => fapp f (subst_term t' x s)
  end.

Fixpoint subst (f : form) (x : nat) (s : term) : form :=
  match f with
  | atom p t => atom p (subst_term t x s)
  | fimp a b => fimp (subst a x s) (subst b x s)
  | fneg a => fneg (subst a x s)
  | fall y a => if Nat.eqb y x then fall y a
                else fall y (subst a x s)
  | feq t1 t2 => feq (subst_term t1 x s) (subst_term t2 x s)
  end.

(* ---------- 语义（沿 15 章，FEq 条款=真相等） ---------- *)

Definition fenv := nat -> nat -> nat.
Definition penv := nat -> nat -> bool.
Definition env := nat -> nat.

Fixpoint eterm (fe : fenv) (e : env) (t : term) : nat :=
  match t with
  | tvar n => e n
  | fapp f t' => fe f (eterm fe e t')
  end.

Fixpoint eform (fe : fenv) (pe : penv) (e : env) (f : form) : Prop :=
  match f with
  | atom p t => pe p (eterm fe e t) = true
  | fimp a b => (~ eform fe pe e a) \/ eform fe pe e b
  | fneg a => ~ eform fe pe e a
  | fall y a => forall v, eform fe pe (fun m => if Nat.eqb m y then v else e m) a
  | feq t1 t2 => eterm fe e t1 = eterm fe e t2   (* 锁定语义 *)
  end.

(* ---------- nd 演算：本章所需规则族 ---------- *)

Definition fvCtx (G : list form) : list nat :=
  flat_map fv G.

Inductive nd : list form -> form -> Prop :=
| ndHyp : forall G f, In f G -> nd G f
| ndImpI : forall G f g, nd (f :: G) g -> nd G (fimp f g)
| ndImpE : forall G f g, nd G (fimp f g) -> nd G f -> nd G g
| ndAllI : forall G x a,
    ~ In x (fvCtx G) ->
    (forall v, nd G (subst a x (tvar v))) ->
    nd G (fall x a)
| ndAllE : forall G x a t,
    nd G (fall x a) -> nd G (subst a x t)
| ndEqI : forall G t, nd G (feq t t)
| ndEqE : forall G t1 t2 x f,
    closedT t1 -> closedT t2 ->
    nd G (feq t1 t2) ->
    nd G (subst f x t1) ->
    nd G (subst f x t2).

(* 闭项不怕代入：subst 对闭项是恒等（=e 侧条件的引擎） *)
Lemma subst_closed_id : forall t x s, closedT t -> subst_term t x s = t.
Proof.
  induction t as [n|f t' IH]; intros x s Hc; simpl in *.
  - discriminate.
  - rewrite IH by exact Hc. reflexivity.
Qed.

(* ---------- 派生件一：对称（H&R 式 2.6） ---------- *)

Theorem eq_sym_nd : forall G t1 t2,
  nd G (feq t1 t2) -> closedT t1 -> closedT t2 ->
  nd G (feq t2 t1).
Proof.
  intros G t1 t2 H Hc1 Hc2.
  assert (Hs : subst (feq (tvar 0) t1) 0 t2 = feq t2 t1).
  { simpl. rewrite (subst_closed_id t1 0 t2 Hc1). reflexivity. }
  rewrite <- Hs.
  apply (ndEqE G t1 t2 0 (feq (tvar 0) t1) Hc1 Hc2 H).
  simpl. rewrite (subst_closed_id t1 0 t1 Hc1). apply ndEqI.
Qed.

(* ---------- 派生件二：传递（H&R 式 2.7） ---------- *)

Theorem eq_trans_nd : forall G t1 t2 t3,
  nd G (feq t1 t2) -> nd G (feq t2 t3) ->
  closedT t1 -> closedT t2 -> closedT t3 ->
  nd G (feq t1 t3).
Proof.
  intros G t1 t2 t3 H12 H23 Hc1 Hc2 Hc3.
  assert (Hs : subst (feq t1 (tvar 0)) 0 t3 = feq t1 t3).
  { simpl. rewrite (subst_closed_id t1 0 t3 Hc1). reflexivity. }
  rewrite <- Hs.
  apply (ndEqE G t2 t3 0 (feq t1 (tvar 0)) Hc2 Hc3 H23).
  simpl. rewrite (subst_closed_id t1 0 t2 Hc1). exact H12.
Qed.

(* ---------- 派生件三：谓词等量代换（H&R =e 例题形态） ---------- *)

Theorem eq_cong_atom : forall G p t1 t2,
  nd G (atom p t1) -> nd G (feq t1 t2) ->
  closedT t1 -> closedT t2 ->
  nd G (atom p t2).
Proof.
  intros G p t1 t2 HP Heq Hc1 Hc2.
  apply (ndEqE G t1 t2 0 (atom p (tvar 0)) Hc1 Hc2 Heq).
  simpl. exact HP.
Qed.

(* ---------- 全称实例化与等式的组合现场 ---------- *)

Example all_eq_use : forall G f x t,
  nd G (fall x (feq (tvar x) (fapp f (tvar x)))) ->
  closedT t ->
  nd G (feq t (fapp f t)).
Proof.
  intros G f x t Hall Hct.
  pose proof (ndAllE G x (feq (tvar x) (fapp f (tvar x))) t Hall) as Hinst.
  simpl in Hinst.
  rewrite !Nat.eqb_refl in Hinst.
  exact Hinst.
Qed.

(* ---------- 语义 sanity：FEq 条款即真相等 ---------- *)

Example feq_sem_sanity : forall fe pe e t,
  eform fe pe e (feq t t).
Proof. intros. simpl. reflexivity. Qed.

Example feq_sem_concrete : forall fe pe e,
  eform fe pe e (feq (tvar 0) (tvar 0)).
Proof. intros. simpl. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - ndEqE 的参数序（G t1 t2 x f）在 apply 时要用命名实参定位，
     否则 subst 的三个参数（f x t1/t2）统一方向会选错；
   - fvCtx 用 flat_map fv——ndAllI 的侧条件「x ∉ FV(G)」在
     归纳证明里每次 ndImpI 都要重新核（本章派生件不经过
     ndImpI，暂不触发）；
   - eq_sym_nd 的 φ 选 feq (tvar 0) t1——0 号变元是「新鲜名」
     的教学约定（闭项侧条件下 subst 不会撞车）。 *)
