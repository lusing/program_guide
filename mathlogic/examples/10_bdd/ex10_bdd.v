(* ex10 —— BDD：布尔函数的决策树与 apply（Ben-Ari 3e Ch5 / Huth&Ryan Ch6）
   设计：深度即变量索引——DNode 顶是变量 0，子树配 eshift 赋值；
   mkvar 用「复制消歧」：顶变量与目标无关时两支复制，
   语义上 if e 0 then t else t = t 把无关测试吸收掉。

   旗舰三条（零公理）：
     apply_correct   teval e (applyd op b1 b2) = op (teval e b1) (teval e b2)
     mkvar_correct   teval e (mkvar v) = e v
     mk_correct      teval e (mk f) = eval e f  ——公式到 BDD 编译保语义
   化简的规模红利在 Lean 通道现场（mknode 坍缩两分支相同节点）。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Inductive form : Type :=
| FVar : nat -> form
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FNeg : form -> form.

Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n   => e n
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr a b  => orb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  end.

(* ---------- 决策树：深度即变量索引 ---------- *)

Inductive dtree : Type :=
| DLeaf : bool -> dtree
| DNode : dtree -> dtree -> dtree.

Definition eshift (e : nat -> bool) : nat -> bool := fun m => e (S m).

Fixpoint teval (e : nat -> bool) (b : dtree) : bool :=
  match b with
  | DLeaf c => c
  | DNode lo hi => if e 0 then teval (eshift e) hi else teval (eshift e) lo
  end.

Fixpoint bsize (b : dtree) : nat :=
  match b with
  | DLeaf _ => 1
  | DNode lo hi => 1 + bsize lo + bsize hi
  end.

(* ---------- mapleaf：叶上变换 ---------- *)

Fixpoint mapleaf (f : bool -> bool) (b : dtree) : dtree :=
  match b with
  | DLeaf c => DLeaf (f c)
  | DNode lo hi => DNode (mapleaf f lo) (mapleaf f hi)
  end.

Lemma teval_mapleaf : forall b e f,
  teval e (mapleaf f b) = f (teval e b).
Proof.
  induction b as [c|lo IHlo hi IHhi]; intros e f; simpl.
  - reflexivity.
  - destruct (e 0); [rewrite IHhi | rewrite IHlo]; reflexivity.
Qed.

(* ---------- apply ---------- *)

Fixpoint applyd (op : bool -> bool -> bool) (b1 b2 : dtree) {struct b1} : dtree :=
  match b1, b2 with
  | DLeaf c1, _ => mapleaf (fun c => op c1 c) b2
  | _, DLeaf c2 => mapleaf (fun c => op c c2) b1
  | DNode l1 h1, DNode l2 h2 =>
      DNode (applyd op l1 l2) (applyd op h1 h2)
  end.

Theorem apply_correct : forall op b1 b2 e,
  teval e (applyd op b1 b2) = op (teval e b1) (teval e b2).
Proof.
  intros op b1. induction b1 as [c1|l1 IHl h1 IHh]; intros b2 e.
  - destruct b2 as [c2|l2 h2].
    + simpl. reflexivity.
    + simpl. destruct (e 0); rewrite teval_mapleaf; reflexivity.
  - destruct b2 as [c2|l2 h2].
    + simpl. destruct (e 0); rewrite teval_mapleaf; reflexivity.
    + simpl. destruct (e 0).
      * rewrite (IHh h2 (eshift e)). reflexivity.
      * rewrite (IHl l2 (eshift e)). reflexivity.
Qed.

(* ---------- 单变量树与公式编译 ---------- *)

Fixpoint mkvar (v : nat) : dtree :=
  match v with
  | 0 => DNode (DLeaf false) (DLeaf true)
  | S v' => DNode (mkvar v') (mkvar v')
  end.

Theorem mkvar_correct : forall v e, teval e (mkvar v) = e v.
Proof.
  induction v as [|v' IH]; intros e.
  - simpl. destruct (e 0); reflexivity.
  - simpl. destruct (e 0).
    + rewrite IH. reflexivity.
    + rewrite IH. reflexivity.
Qed.

(* 教学版不化简：mkvar v 是深度 v+1 的满树 *)
Lemma two_pow_pos : forall n, 0 < 2 ^ n.
Proof. induction n as [|n IH]; simpl; lia. Qed.

Lemma bsize_mkvar : forall v, bsize (mkvar v) = 2 ^ (v + 2) - 1.
Proof.
  induction v as [|v' IH]; simpl.
  - reflexivity.
  - rewrite IH.
    pose proof (two_pow_pos (v' + 2)) as H. lia.
Qed.

Fixpoint mk (f : form) : dtree :=
  match f with
  | FVar n   => mkvar n
  | FAnd a b => applyd andb (mk a) (mk b)
  | FOr a b  => applyd orb (mk a) (mk b)
  | FNeg a   => mapleaf negb (mk a)
  end.

Theorem mk_correct : forall f e, teval e (mk f) = eval e f.
Proof.
  induction f as [n|a IHa b IHb|a IHa b IHb|a IHa]; intros e; simpl.
  - apply mkvar_correct.
  - rewrite apply_correct, IHa, IHb. reflexivity.
  - rewrite apply_correct, IHa, IHb. reflexivity.
  - rewrite teval_mapleaf, IHa. reflexivity.
Qed.

Print Assumptions mk_correct.  (* Closed：编译零公理 *)

(* ---------- 现场 ---------- *)

Example mkvar_two :
  mkvar 1 = DNode (DNode (DLeaf false) (DLeaf true))
                  (DNode (DLeaf false) (DLeaf true)).
Proof. reflexivity. Qed.

Example xor_bdd : bsize (applyd xorb (mkvar 0) (mkvar 1)) = 7.
Proof. reflexivity. Qed.


(* ---------- restrict / exists：H&R §6.2.3-6.2.4 ---------- *)

(* 赋值在变元 v 处的更新 *)
Definition upd (e : nat -> bool) (v : nat) (b : bool) : nat -> bool :=
  fun n => if Nat.eqb n v then b else e n.

(* teval 只逐点依赖赋值——一致性的 dtree 版（02 章 agree 的亲戚） *)
Lemma teval_ext : forall t e1 e2,
  (forall n, e1 n = e2 n) -> teval e1 t = teval e2 t.
Proof.
  induction t as [c|lo IHlo hi IHhi]; intros e1 e2 H; simpl.
  - reflexivity.
  - rewrite (H 0). destruct (e2 0).
    + apply IHhi. intros n. apply H.
    + apply IHlo. intros n. apply H.
Qed.

(* lift：把子树垫回一层——变量整体保持绝对编号。
   teval e (lift t) = teval (eshift e) t：垫回的顶节点测试 e 0，
   而两个分支同树，测试结果无关紧要。 *)
Definition lift (t : dtree) : dtree := DNode t t.

Lemma teval_lift : forall t e, teval e (lift t) = teval (eshift e) t.
Proof. intros t e. simpl. destruct (e 0); reflexivity. Qed.

(* restrict v b t：把变元 v 钉为 b——H&R §6.2.3 的「重定向入边到
   选定分支」。深度编码下 v=离根层数：递归 v 层后剪枝，剪完必须
   lift 垫回（否则子树变量错位——见本章坑位速记的坍缩事故）。
   树形表示无共享，垫回的 DNode 让 restrict 只保语义不缩尺寸——
   尺寸收益属于 DAG 共享（正文讨论）。 *)
Fixpoint restrict (v : nat) (b : bool) (t : dtree) : dtree :=
  match t with
  | DLeaf _ => t
  | DNode lo hi =>
      match v with
      | 0 => lift (if b then hi else lo)
      | S v' => DNode (restrict v' b lo) (restrict v' b hi)
      end
  end.

Lemma upd_tail_0 : forall e b n, upd e 0 b (S n) = e (S n).
Proof. intros e b n. unfold upd. simpl. reflexivity. Qed.

Lemma upd_head_S : forall e v b, upd e (S v) b 0 = e 0.
Proof. intros e v b. unfold upd. simpl. reflexivity. Qed.

Lemma eshift_upd_S : forall e v b n,
  eshift (upd e (S v) b) n = upd (eshift e) v b n.
Proof. intros e v b n. unfold eshift, upd. simpl. reflexivity. Qed.

Theorem restrict_correct : forall t v b e,
  teval e (restrict v b t) = teval (upd e v b) t.
Proof.
  induction t as [c|lo IHlo hi IHhi]; intros v b e.
  - destruct v; reflexivity.
  - destruct v as [|v'].
    + change (restrict 0 b (DNode lo hi)) with (lift (if b then hi else lo)).
      rewrite teval_lift. simpl. destruct b.
      * assert (Hs : forall n, eshift (upd e 0 true) n = eshift e n).
        { intros n. unfold eshift. rewrite upd_tail_0. reflexivity. }
        rewrite (teval_ext hi _ _ Hs). reflexivity.
      * assert (Hs : forall n, eshift (upd e 0 false) n = eshift e n).
        { intros n. unfold eshift. rewrite upd_tail_0. reflexivity. }
        rewrite (teval_ext lo _ _ Hs). reflexivity.
    + change (restrict (S v') b (DNode lo hi))
        with (DNode (restrict v' b lo) (restrict v' b hi)).
      simpl. rewrite upd_head_S. destruct (e 0).
      * rewrite (IHhi v' b (eshift e)).
        assert (Hs : forall n, eshift (upd e (S v') b) n = upd (eshift e) v' b n).
        { apply eshift_upd_S. }
        rewrite (teval_ext hi _ _ Hs). reflexivity.
      * rewrite (IHlo v' b (eshift e)).
        assert (Hs : forall n, eshift (upd e (S v') b) n = upd (eshift e) v' b n).
        { apply eshift_upd_S. }
        rewrite (teval_ext lo _ _ Hs). reflexivity.
Qed.

(* exists：H&R 式 (6.3)——∃x. f := f[0/x] + f[1/x]，用 apply 组装 *)
Definition exb (v : nat) (t : dtree) : dtree :=
  applyd orb (restrict v false t) (restrict v true t).

Theorem exb_correct : forall t v e,
  teval e (exb v t) =
  orb (teval (upd e v false) t) (teval (upd e v true) t).
Proof.
  intros t v e. unfold exb.
  rewrite apply_correct.
  rewrite (restrict_correct t v false), (restrict_correct t v true).
  reflexivity.
Qed.

(* 现场两枚：
   ∃x₀. x₀ 恒真（单变量树剪两刀后 or 装配出常真叶）；
   (x₀ ∧ x₁)[x₁:=true] 语义恰为 x₀（restriction 的最小现场） *)
Example exb_mkvar : forall e, teval e (exb 0 (mkvar 0)) = true.
Proof. intros e. simpl. destruct (e 0); reflexivity. Qed.

Example restrict_and_demo :
  forall e, teval e (restrict 1 true (mk (FAnd (FVar 0) (FVar 1)))) = e 0.
Proof.
  intros e. rewrite restrict_correct, mk_correct. unfold upd. simpl.
  destruct (e 0); reflexivity.
Qed.

Print Assumptions restrict_correct.  (* Closed *)
Print Assumptions exb_correct.       (* Closed *)

(* 坑位速记（Coq 侧）：
   - 深度编码变量时，「坍缩 hi=lo 返回子树」会让变量错位
     （子树在下一层，语义配 eshift e）——正确坍缩须配 lift 垫回，
     而 lift(DNode)=DNode 的语义又要求 e 0 无关——教学版干脆不化简，
     化简红利在 Lean 通道用结构判等现场演示；
   - mkvar (S v) = DNode (mkvar v) (mkvar v) 的「复制消歧」：
     顶变量与内容无关，if e 0 then t else t ≡ t；
   - applyd 叶/节点交叉四种情况逐一收——mapleaf 是叶情形的统一出口。 *)
