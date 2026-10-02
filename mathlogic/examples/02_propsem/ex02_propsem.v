(* ex02 —— 命题逻辑：语法、语义与蛮力判定器
   八书对位：Huth&Ryan §1.3-1.4 / Ben-Ari 3e §2.2-2.5 / EFT II-III / Mendelson §1.1-1.2

   公式是一棵树（归纳类型），语义是一个布尔函数（eval），
   判定器 = 枚举公式全部变元的所有赋值。
   旗舰两条：check f = true → f 语义有效；check f = false → 反赋值存在。
   桥梁是「满足一致性引理」：eval 只看 f 中出现的变元。 *)

Require Import List Bool Arith.
Import ListNotations.

(* ---------- 语法 ---------- *)

Inductive form : Type :=
| FVar  : nat -> form
| FImp  : form -> form -> form
| FAnd  : form -> form -> form
| FOr   : form -> form -> form
| FNeg  : form -> form
| FFals : form.

(* ---------- 语义 ---------- *)

Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n  => e n
  | FImp a b => implb (eval e a) (eval e b)
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr  a b => orb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  | FFals    => false
  end.

Fixpoint vars (f : form) : list nat :=
  match f with
  | FVar n   => [n]
  | FImp a b => vars a ++ vars b
  | FAnd a b => vars a ++ vars b
  | FOr  a b => vars a ++ vars b
  | FNeg a   => vars a
  | FFals    => []
  end.

(* ---------- 满足一致性引理（EFT III.5 / Huth&Ryan §1.4） ---------- *)

Lemma agree_eval : forall f e1 e2,
  (forall x, In x (vars f) -> e1 x = e2 x) -> eval e1 f = eval e2 f.
Proof.
  induction f as [n|f1 IH1 f2 IH2|f1 IH1 f2 IH2|f1 IH1 f2 IH2|f1 IH1|];
    intros e1 e2 H; simpl.
  - apply H. left. reflexivity.
  - rewrite (IH1 e1 e2); [|intros x Hx; apply H; apply in_or_app; left; exact Hx].
    rewrite (IH2 e1 e2); [|intros x Hx; apply H; apply in_or_app; right; exact Hx].
    reflexivity.
  - rewrite (IH1 e1 e2); [|intros x Hx; apply H; apply in_or_app; left; exact Hx].
    rewrite (IH2 e1 e2); [|intros x Hx; apply H; apply in_or_app; right; exact Hx].
    reflexivity.
  - rewrite (IH1 e1 e2); [|intros x Hx; apply H; apply in_or_app; left; exact Hx].
    rewrite (IH2 e1 e2); [|intros x Hx; apply H; apply in_or_app; right; exact Hx].
    reflexivity.
  - rewrite (IH1 e1 e2); [|intros x Hx; apply H; exact Hx]. reflexivity.
  - reflexivity.
Qed.

(* ---------- 蛮力判定器 ---------- *)

Fixpoint lookup (n : nat) (l : list (nat * bool)) : bool :=
  match l with
  | [] => false
  | (x, b) :: r => if Nat.eqb n x then b else lookup n r
  end.

Definition assignOf (vs : list nat) (v : list bool) : nat -> bool :=
  fun n => lookup n (combine vs v).

Fixpoint allVectors (vs : list nat) : list (list bool) :=
  match vs with
  | [] => [[]]
  | x :: xs => map (cons false) (allVectors xs) ++ map (cons true) (allVectors xs)
  end.

Definition check (f : form) : bool :=
  forallb (fun v => eval (assignOf (vars f) v) f) (allVectors (vars f)).

(* ---------- 三条辅助引理 ---------- *)

Lemma lookup_zip_map : forall vs e x,
  In x vs -> lookup x (combine vs (map e vs)) = e x.
Proof.
  induction vs as [|y ys IH]; intros e x Hx; simpl in *.
  - contradiction.
  - destruct (Nat.eqb x y) eqn:E.
    + apply Nat.eqb_eq in E. subst y. reflexivity.
    + destruct Hx as [Heq | Hin].
      * exfalso. apply Nat.eqb_neq in E. apply E. symmetry. exact Heq.
      * rewrite IH by exact Hin. reflexivity.
Qed.

Lemma map_in_allVectors : forall vs e, In (map e vs) (allVectors vs).
Proof.
  induction vs as [|x xs IH]; intros e; simpl.
  - left. reflexivity.
  - destruct (e x) eqn:E.
    + apply in_or_app. right. apply in_map. exact (IH e).
    + apply in_or_app. left. apply in_map. exact (IH e).
Qed.

Lemma forallb_false_witness : forall (p : list bool -> bool) l,
  forallb p l = false -> exists v, In v l /\ p v = false.
Proof.
  induction l as [|a l IH]; intros H; simpl in H.
  - discriminate.
  - apply andb_false_iff in H. destruct H as [H | H].
    + exists a. split; [left; reflexivity | exact H].
    + destruct (IH H) as [v [Hin Hp]]. exists v.
      split; [right; exact Hin | exact Hp].
Qed.

(* ---------- 旗舰：判定器双向可靠 ---------- *)

Theorem check_true_valid : forall f,
  check f = true -> forall e, eval e f = true.
Proof.
  intros f H e.
  assert (Heq : eval e f = eval (assignOf (vars f) (map e (vars f))) f).
  { apply agree_eval. intros x Hx. unfold assignOf.
    rewrite lookup_zip_map by exact Hx. reflexivity. }
  rewrite Heq. unfold check in H.
  apply (proj1 (forallb_forall _ _) H). apply map_in_allVectors.
Qed.

Theorem check_false_counter : forall f,
  check f = false -> exists e, eval e f = false.
Proof.
  intros f H. unfold check in H.
  destruct (forallb_false_witness _ _ H) as [v [Hin Hv]].
  exists (assignOf (vars f) v). exact Hv.
Qed.

(* ---------- 现场：真值表语义是经典的 ---------- *)

(* Peirce 律在语义层恒真——但第 04 章会看到它在构造证明里不可达。 *)
Example peirce_sem_valid :
  check (FImp (FImp (FImp (FVar 0) (FVar 1)) (FVar 0)) (FVar 0)) = true.
Proof. reflexivity. Qed.

Example contradiction_sem :
  check (FAnd (FVar 0) (FNeg (FVar 0))) = false.
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - In x (a :: l) 展开为 a = x \/ In x l——方向是「表头 = x」；
   - rewrite (IH e1 e2) 会把前提甩成后续子目标（| 分隔），顺序别搞反；
   - Example 里 reflexivity 直接算 check——全遍历 2^n 个向量，n 大了换 vm_compute。 *)
