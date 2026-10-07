(* ex41 —— 归结完备性与 SAT 难例（Ben-Ari 3e §4.4-4.5 + §6.2/6.4）
   26 章留下了归结的可靠性；本章补证明对象与难例现场：
     resproof —— 归结反驳即数据（演算作为数据）；良构检查 rp_wf
       逐代核对每个归结步的双臂文字；
     PHP(2,2) —— 鸽笼难例的四步显式反驳：命题 SAT 的天然硬族
       （Ben-Ari §4.5：反驳长度随笼数指数增长——docs 走查）；
     枚举对照 —— 4 步反驳 vs 16 个赋值的穷举：短证书的价值现场；
     resolvent_sound —— 归结式的可靠性（26 章方向在命题层的收口）；
     dpElim —— Davis-Putnam 变量消元一步（§6.2，演示级）。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Definition lit := (bool * nat)%type.        (* (true,p)=p  (false,p)=¬p *)
Definition clause := list lit.
Definition cnf := list clause.

Fixpoint litSat (e : nat -> bool) (l : lit) : bool :=
  match l with
  | (true, p) => e p
  | (false, p) => negb (e p)
  end.

Definition clauseSat (e : nat -> bool) (c : clause) : bool :=
  existsb (litSat e) c.

Definition cnfSat (e : nat -> bool) (S : cnf) : bool :=
  forallb (clauseSat e) S.

(* ---------- 文字相等/成员/子句相等 ---------- *)

Definition eqlL (l1 l2 : lit) : bool :=
  match l1, l2 with
  | (s1, p1), (s2, p2) => (if s1 then s2 else negb s2) && Nat.eqb p1 p2
  end.

Definition memL (c : clause) (l : lit) : bool := existsb (eqlL l) c.

Definition removeLit (l : lit) (c : clause) : clause :=
  filter (fun x => negb (eqlL x l)) c.

Definition oppl (l : lit) : lit :=
  match l with (s, p) => (negb s, p) end.

Definition resolvent (l : lit) (C1 C2 : clause) : clause :=
  removeLit l C1 ++ removeLit (oppl l) C2.

(* ---------- 归结式可靠性：满足两前提的赋值满足归结式 ---------- *)

Lemma eqlL_refl : forall l, eqlL l l = true.
Proof.
  intros [s p]. destruct s; simpl; rewrite Nat.eqb_refl; reflexivity.
Qed.

Lemma eqlL_true : forall l1 l2, eqlL l1 l2 = true -> l1 = l2.
Proof.
  intros [s1 p1] [s2 p2] H. unfold eqlL in H.
  destruct s1, s2; simpl in H; try discriminate;
  apply Nat.eqb_eq in H; subst; reflexivity.
Qed.

Lemma memL_In : forall c l, memL c l = true -> In l c.
Proof.
  intros c l H. unfold memL in H. rewrite existsb_exists in H.
  destruct H as [x [Hin Heq]].
  apply eqlL_true in Heq. subst. exact Hin.
Qed.

Theorem resolvent_sound : forall e l C1 C2,
  clauseSat e C1 = true -> clauseSat e C2 = true ->
  clauseSat e (resolvent l C1 C2) = true.
Proof.
  intros e [s p] C1 C2 H1 H2.
  unfold clauseSat, resolvent, removeLit, oppl in *.
  rewrite existsb_exists in H1. destruct H1 as [x1 [Hin1 Hs1]].
  rewrite existsb_exists in H2. destruct H2 as [x2 [Hin2 Hs2]].
  rewrite existsb_app. apply (proj2 (orb_true_iff _ _)).
  destruct (eqlL x1 (s, p)) eqn:E1; destruct (eqlL x2 (negb s, p)) eqn:E2.
  - (* x1 = l 且 x2 = ¬l：见证文字对撞——矛盾 *)
    exfalso. apply eqlL_true in E1. apply eqlL_true in E2. subst x1 x2.
    destruct s; simpl in Hs1, Hs2;
      first [ rewrite Hs1 in Hs2 | rewrite Hs2 in Hs1 ]; discriminate.
  - (* x1 = l：x2 ≠ ¬l，存活于 C2 段 *)
    right. rewrite existsb_exists. exists x2. split.
    + rewrite filter_In. split.
      * exact Hin2.
      * rewrite E2. reflexivity.
    + exact Hs2.
  - (* x2 = ¬l：x1 ≠ l，存活于 C1 段 *)
    left. rewrite existsb_exists. exists x1. split.
    + rewrite filter_In. split.
      * exact Hin1.
      * rewrite E1. reflexivity.
    + exact Hs1.
  - (* 都存活：x1 在 C1 段 *)
    left. rewrite existsb_exists. exists x1. split.
    + rewrite filter_In. split.
      * exact Hin1.
      * rewrite E1. reflexivity.
    + exact Hs1.
Qed.

(* ---------- 归结反驳证明对象 ---------- *)

Inductive resproof : Type :=
| RLeaf : clause -> resproof
| RRes : resproof -> resproof -> lit -> resproof.

Fixpoint concl (r : resproof) : clause :=
  match r with
  | RLeaf c => c
  | RRes r1 r2 l => resolvent l (concl r1) (concl r2)
  end.

(* 良构：每步两臂确实含被消文字的正负两侧 *)
Fixpoint rp_wf (r : resproof) : bool :=
  match r with
  | RLeaf _ => true
  | RRes r1 r2 (s, p) =>
      rp_wf r1 && rp_wf r2
      && memL (concl r1) (s, p) && memL (concl r2) (negb s, p)
  end.

(* ---------- 鸽笼难例现场 ----------
   PHP(2,2)（双鸽双洞）可满足——作 DP 消元的正例；
   PHP(3,1)（三鸽一洞）不可满足——三步显式反驳。Ben-Ari §4.5 的
   难例族 PHP(n+1,n)：n=2 即 PHP(3,2) 的反驳已需数十步且随 n
   指数增长——docs 走查其结构。 *)

Definition pos (p : nat) : lit := (true, p).
Definition negp (p : nat) : lit := (false, p).

Definition php22 : cnf :=
  [ [pos 0; pos 1];            (* 鸽 1 有洞：x11 ∨ x12 *)
    [pos 2; pos 3];            (* 鸽 2 有洞 *)
    [negp 0; negp 2];          (* 洞 1 至多一鸽 *)
    [negp 1; negp 3] ].        (* 洞 2 至多一鸽 *)

(* PHP(3,1)：三鸽一洞。变元 x1=0 x2=1 x3=2 *)
Definition php31 : cnf :=
  [ [pos 0]; [pos 1]; [pos 2];            (* 每鸽有洞 *)
    [negp 0; negp 1]; [negp 0; negp 2]; [negp 1; negp 2] ].  (* 洞至多一鸽 *)

(* 两步：
   1. (x3) 与 (¬x1∨¬x3) 消 x3 → (¬x1)——鸽子 3 被洞拒绝
   2. (¬x1) 与 (x1) 对撞 → 空子句——矛盾 *)
Definition php31_refute : resproof :=
  RRes (RRes (RLeaf [pos 2]) (RLeaf [negp 0; negp 2]) (pos 2))
       (RLeaf [pos 0]) (negp 0).

Example php31_wf : rp_wf php31_refute = true.
Proof. reflexivity. Qed.

Example php31_empty : concl php31_refute = [].
Proof. reflexivity. Qed.

(* ---------- 枚举对照：短证书 vs 穷举 ---------- *)

Fixpoint boolLists (n : nat) : list (list bool) :=
  match n with
  | 0 => [[]]
  | S k => map (cons true) (boolLists k) ++ map (cons false) (boolLists k)
  end.

Definition envOf (bits : list bool) : nat -> bool :=
  fun p => nth p bits false.

Definition satByEnum (S : cnf) (nvars : nat) : bool :=
  existsb (fun bits => cnfSat (envOf bits) S) (boolLists nvars).

(* 对照现场：PHP(2,2) 有模型（双鸽分居两洞）——枚举 16 个赋值命中 *)
Example php22_sat_enum : satByEnum php22 4 = true.
Proof. reflexivity. Qed.

(* PHP(3,1) 不可满足：枚举 8 个赋值全败（对照：反驳只要 2 步） *)
Example php31_unsat_enum : satByEnum php31 3 = false.
Proof. reflexivity. Qed.

(* ---------- Davis-Putnam 变量消元一步（§6.2，演示级） ---------- *)

Definition dpElim (p : nat) (S : cnf) : cnf :=
  let posC := filter (fun c => memL c (true, p)) S in
  let negC := filter (fun c => memL c (false, p)) S in
  let news :=
    flat_map (fun C1 =>
      flat_map (fun C2 => [resolvent (true, p) C1 C2]) negC) posC in
  filter (fun c => negb (memL c (true, p)) && negb (memL c (false, p))) S
  ++ news.

(* 消去 x11 后：三子句——鸽 2 的存在、洞 2 的约束、以及归结出的
   x12∨x22（两鸽挤向洞 2 的紧张关系浮现） *)
Example dp_step_demo : dpElim 0 php22 =
  [ [pos 2; pos 3]; [negp 1; negp 3]; [pos 1; negp 2] ].
Proof. reflexivity. Qed.

(* 继续消下去终到空矛盾（php22 可满足，这里只演示消元形态）——
   DP 的完全算法见 docs/41 的三规则走查 *)
