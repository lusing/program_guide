(* ex10_adequate.v —— 完备连接词集与公理独立性（Mendelson §1.3/1.5/1.6）
   机器件五组：
   1) shannon 表示定理：只依赖前 n 个字母的真值函数有 {¬,∧,∨} 公式表示
   2) 翻译器：tAND 消到 {¬,∧}；toDown 消到单连接词 ↓（A↓B := ¬(A∧B)）
   3) Prop 1.7 骨架：h(T,T)=T 传全真 ⇒ ¬ 不可定义；仅 ¬ 只得恒等/否定
   4) L 三公理独立：矩阵一 select/矩阵二 grotesque + super 擦负号（A3）
   5) L1（Hilbert–Ackermann ∨¬ 四公理）重言验证 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 0. 公式与二值语义（02 章配方，自包含复制） ============ *)

Inductive fm : Type :=
| v    (n : nat)
| neg  (a : fm)
| imp  (a b : fm)
| conj (a b : fm)
| disj (a b : fm).

Definition asn := nat -> bool.

Fixpoint beval (f : fm) (s : asn) : bool :=
  match f with
  | v n => s n
  | neg a => negb (beval a s)
  | imp a b => implb (beval a s) (beval b s)
  | conj a b => andb (beval a s) (beval b s)
  | disj a b => orb (beval a s) (beval b s)
  end.

Definition upd (s : asn) (n : nat) (b : bool) : asn :=
  fun i => if Nat.eqb i n then b else s i.

(* ============ 一、Shannon 表示定理（书 §1.3 Cor 1.6 的构造面） ============ *)

Definition fTrue  : fm := imp (v 0) (v 0).
Definition fFalse : fm := neg (imp (v 0) (v 0)).

Fixpoint shannon (n : nat) (f : asn -> bool) : fm :=
  match n with
  | O => if f (fun _ => false) then fTrue else fFalse
  | S n' => disj (conj (v n')    (shannon n' (fun s => f (upd s n' true))))
                 (conj (neg (v n')) (shannon n' (fun s => f (upd s n' false))))
  end.

Definition agree_upto (n : nat) (s1 s2 : asn) : Prop :=
  forall i, i < n -> s1 i = s2 i.

Lemma beval_fTrue  : forall s, beval fTrue s = true.
Proof. intros s; unfold fTrue; simpl; destruct (s 0); reflexivity. Qed.
Lemma beval_fFalse : forall s, beval fFalse s = false.
Proof. intros s; unfold fFalse, fTrue; simpl; destruct (s 0); reflexivity. Qed.

Theorem shannon_ok : forall n (f : asn -> bool) s,
  (forall s1 s2, agree_upto n s1 s2 -> f s1 = f s2) ->
  beval (shannon n f) s = f s.
Proof.
  induction n as [|n IH]; intros f s Hdep.
  - simpl. destruct (f (fun _ => false)) eqn:E.
    + rewrite beval_fTrue, <- E. apply (Hdep (fun _ => false) s).
      intros i; lia.
    + rewrite beval_fFalse, <- E. apply (Hdep (fun _ => false) s).
      intros i; lia.
  - simpl. destruct (s n) eqn:Hsn; simpl.
    + assert (HA : beval (shannon n (fun s0 => f (upd s0 n true))) s
                   = f (upd s n true)).
      { apply (IH (fun s0 => f (upd s0 n true))).
        intros s1 s2 Hag. cbv beta. apply Hdep. intros i Hi.
        unfold upd.
        destruct (Nat.eqb_spec i n) as [->|Hne].
        - reflexivity.
        - rewrite Hag by lia. reflexivity. }
      rewrite HA.
      assert (HT : f (upd s n true) = f s).
      { apply Hdep. intros i Hi. unfold upd.
        destruct (Nat.eqb_spec i n) as [->|Hne].
        - rewrite Hsn. reflexivity.
        - reflexivity. }
      rewrite HT. destruct (f s); reflexivity.
    + assert (HB : beval (shannon n (fun s0 => f (upd s0 n false))) s
                   = f (upd s n false)).
      { apply (IH (fun s0 => f (upd s0 n false))).
        intros s1 s2 Hag. cbv beta. apply Hdep. intros i Hi.
        unfold upd.
        destruct (Nat.eqb_spec i n) as [->|Hne].
        - reflexivity.
        - rewrite Hag by lia. reflexivity. }
      rewrite HB.
      assert (HF : f (upd s n false) = f s).
      { apply Hdep. intros i Hi. unfold upd.
        destruct (Nat.eqb_spec i n) as [->|Hne].
        - rewrite Hsn. reflexivity.
        - reflexivity. }
      rewrite HF. reflexivity.
Qed.

(* ============ 二、翻译器：{¬,∧} 与单连接词 ↓ ============ *)

Fixpoint tAND (f : fm) : fm :=
  match f with
  | v n => v n
  | neg a => neg (tAND a)
  | imp a b => neg (conj (tAND a) (neg (tAND b)))
  | conj a b => conj (tAND a) (tAND b)
  | disj a b => neg (conj (neg (tAND a)) (neg (tAND b)))
  end.

Theorem tAND_ok : forall f s, beval (tAND f) s = beval f s.
Proof.
  intros f. induction f as [n | a IHa | a IHa b IHb | a IHa b IHb
                          | a IHa b IHb]; intros s; simpl;
    try reflexivity.
  - rewrite IHa. destruct (beval a s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
Qed.

(* 单连接词 ↓（joint denial/NOR）：A↓B := ¬(A∨B)，恰在两者皆假时为真 *)
Inductive upfm : Type := uv (n : nat) | up (a b : upfm).

Fixpoint upeval (f : upfm) (s : asn) : bool :=
  match f with
  | uv n => s n
  | up a b => negb (orb (upeval a s) (upeval b s))
  end.

(* 书 §1.3 恒等式：¬A ⇔ A↓A；A∧B ⇔ (A↓A)↓(B↓B)；
   A∨B ⇔ (A↓B)↓(A↓B)；A⇒B = ¬A∨B 组合之 *)
Fixpoint toDown (f : fm) : upfm :=
  match f with
  | v n => uv n
  | neg a => up (toDown a) (toDown a)
  | imp a b => let na := up (toDown a) (toDown a) in
               up (up na (toDown b)) (up na (toDown b))
  | conj a b => up (up (toDown a) (toDown a)) (up (toDown b) (toDown b))
  | disj a b => up (up (toDown a) (toDown b)) (up (toDown a) (toDown b))
  end.

Theorem toDown_ok : forall f s, upeval (toDown f) s = beval f s.
Proof.
  intros f. induction f as [n | a IHa | a IHa b IHb | a IHa b IHb
                          | a IHa b IHb]; intros s; simpl;
    try reflexivity.
  - rewrite IHa. destruct (beval a s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
  - rewrite IHa, IHb. destruct (beval a s), (beval b s); reflexivity.
Qed.

(* ============ 三、Prop 1.7 骨架：唯 ↓ 与 | 可作单连接词 ============ *)

(* 任意二元连接词 h 上的公式 *)
Inductive hfm : Type := hv (n : nat) | hap (a b : hfm).

Section HConn.
Variable h : bool -> bool -> bool.

Fixpoint heval (f : hfm) (s : asn) : bool :=
  match f with
  | hv n => s n
  | hap a b => h (heval a s) (heval b s)
  end.

Definition allTrue (s : asn) : Prop := forall n, s n = true.

Theorem h_TT_propagates : h true true = true ->
  forall f s, allTrue s -> heval f s = true.
Proof.
  intros HT f s Hall. induction f; simpl; auto.
  rewrite IHf1 by auto. rewrite IHf2 by auto. exact HT.
Qed.

(* h(T,T)=T 时，否定不可由 h-式定义（全真赋值下值恒真） *)
Corollary undef_neg : h true true = true ->
  forall f, ~ (forall s, heval f s = negb (s 0)).
Proof.
  intros HT f Hexp.
  specialize (Hexp (fun _ => true)).
  assert (HT' : heval f (fun _ => true) = true).
  { apply (h_TT_propagates HT). intros n; reflexivity. }
  rewrite HT' in Hexp. discriminate.
Qed.

End HConn.

(* 仅 ¬（作用在单字母上）只得恒等与否定——常真不可定义 *)
Inductive nfm : Type := nv | nneg (a : nfm).

Fixpoint neval (f : nfm) (b : bool) : bool :=
  match f with nv => b | nneg a => negb (neval a b) end.

Theorem neg_only_two : forall f,
  (forall b, neval f b = b) \/ (forall b, neval f b = negb b).
Proof.
  intros f. induction f as [|a IHa].
  - left. intros b. reflexivity.
  - destruct IHa as [H|H].
    + right. intros b. simpl. rewrite H. destruct b; reflexivity.
    + left. intros b. simpl. rewrite H. destruct b; reflexivity.
Qed.

Corollary undef_constT : ~ exists f, forall b, neval f b = true.
Proof.
  intros [f Hf]. destruct (neg_only_two f) as [H|H].
  - specialize (Hf false). rewrite H in Hf. discriminate.
  - specialize (Hf true). rewrite H in Hf. simpl in Hf. discriminate.
Qed.

(* ============ 四、L 三公理独立性（书 §1.5 Prop 1.17） ============ *)

(* L 的语言就是 ¬,⇒；独立性定理只涉此片段 *)
Inductive pfm : Type := pv (n : nat) | pneg (a : pfm) | pimp (a b : pfm).

(* 三值求值器：矩阵由 neg/imp 两表参数化 *)
Fixpoint ev3 (ng : nat -> nat) (im : nat -> nat -> nat)
             (f : pfm) (s : nat -> nat) : nat :=
  match f with
  | pv n => s n
  | pneg a => ng (ev3 ng im a s)
  | pimp a b => im (ev3 ng im a s) (ev3 ng im b s)
  end.

(* 二值求值（给 super 用） *)
Fixpoint peval (f : pfm) (s : asn) : bool :=
  match f with
  | pv n => s n
  | pneg a => negb (peval a s)
  | pimp a b => implb (peval a s) (peval b s)
  end.

(* ---------- 矩阵一：select = 恒取 0 ---------- *)
(* ¬: 0→1, 1→1, 2→0；⇒ 九项表按书 §1.5 原数据 *)
Definition neg1 (a : nat) : nat :=
  match a with O => 1 | S O => 1 | _ => 0 end.

Definition imp1 (a b : nat) : nat :=
  match a with
  | O => match b with O => 0 | S O => 2 | _ => 2 end
  | S O => match b with O => 2 | S O => 2 | _ => 0 end
  | _ => 0
  end.

Definition ev1 (f : pfm) (s : nat -> nat) : nat := ev3 neg1 imp1 f s.
Definition sel (f : pfm) : Prop := forall s, ev1 f s = 0.

(* MP 保持 selectness *)
Theorem mp_sel : forall B C, sel B -> sel (pimp B C) -> sel C.
Proof.
  intros B C H1 H2. unfold sel in *.
  intros s. specialize (H1 s). specialize (H2 s).
  unfold ev1 in *; simpl in H1, H2.
  destruct (ev3 neg1 imp1 B s) as [|[|?]]; destruct (ev3 neg1 imp1 C s) as [|[|?]];
    simpl in H1, H2; try reflexivity; discriminate.
Qed.

(* A2 全实例 select：对 B C D 的取值 3^3 分案查表 *)
Theorem A2_sel : forall B C D, sel (pimp (pimp B (pimp C D))
                                      (pimp (pimp B C) (pimp B D))).
Proof.
  intros B C D s. unfold sel, ev1. simpl.
  destruct (ev3 neg1 imp1 B s) as [|[|?]]; destruct (ev3 neg1 imp1 C s) as [|[|?]];
    destruct (ev3 neg1 imp1 D s) as [|[|?]]; simpl; try reflexivity.
Qed.

Theorem A3_sel : forall B C, sel (pimp (pimp (pneg B) (pneg C))
                                     (pimp (pimp (pneg B) C) B)).
Proof.
  intros B C s. unfold sel, ev1. simpl.
  destruct (ev3 neg1 imp1 B s) as [|[|?]]; destruct (ev3 neg1 imp1 C s) as [|[|?]];
    simpl; try reflexivity.
Qed.

(* 反例：A1 实例不 select——A1=1、A2=2 时取值 2 *)
Example a1_not_sel : ev1 (pimp (pv 0) (pimp (pv 1) (pv 0)))
                        (fun n => match n with O => 1 | S O => 2 | _ => 0 end) = 2.
Proof. reflexivity. Qed.

(* ---------- 矩阵二：grotesque = 恒取 0 ---------- *)
Definition neg2 (a : nat) : nat :=
  match a with O => 1 | S O => 0 | _ => 1 end.

Definition imp2 (a b : nat) : nat :=
  match a with
  | O => match b with O => 0 | S O => 2 | _ => 1 end
  | S O => match b with O => 0 | S O => 2 | _ => 0 end
  | _ => 0
  end.

Definition ev2 (f : pfm) (s : nat -> nat) : nat := ev3 neg2 imp2 f s.
Definition grot (f : pfm) : Prop := forall s, ev2 f s = 0.

Theorem mp_grot : forall B C, grot B -> grot (pimp B C) -> grot C.
Proof.
  intros B C H1 H2 s. unfold grot in H1, H2.
  specialize (H1 s). specialize (H2 s).
  unfold ev2 in *; simpl in H1, H2.
  destruct (ev3 neg2 imp2 B s) as [|[|?]]; destruct (ev3 neg2 imp2 C s) as [|[|?]];
    simpl in H1, H2; congruence.
Qed.

Theorem A1_grot : forall B C, grot (pimp B (pimp C B)).
Proof.
  intros B C s. unfold grot, ev2. simpl.
  destruct (ev3 neg2 imp2 B s) as [|[|?]]; destruct (ev3 neg2 imp2 C s) as [|[|?]];
    simpl; try reflexivity.
Qed.

Theorem A3_grot : forall B C, grot (pimp (pimp (pneg B) (pneg C))
                                     (pimp (pimp (pneg B) C) B)).
Proof.
  intros B C s. unfold grot, ev2. simpl.
  destruct (ev3 neg2 imp2 B s) as [|[|?]]; destruct (ev3 neg2 imp2 C s) as [|[|?]];
    simpl; try reflexivity.
Qed.

(* 反例：A2 实例不 grotesque——(A1,A2,A3)=(0,0,1) 时取值 2 *)
Example a2_not_grot : ev2 (pimp (pimp (pv 0) (pimp (pv 1) (pv 2)))
                            (pimp (pimp (pv 0) (pv 1)) (pimp (pv 0) (pv 2))))
                       (fun n => match n with O => 0 | S O => 0
                                 | S (S O) => 1 | _ => 0 end) = 2.
Proof. reflexivity. Qed.

(* ---------- A3 独立：super 擦负号技巧 ---------- *)

Fixpoint erase (f : pfm) : pfm :=
  match f with
  | pneg a => erase a
  | pimp a b => pimp (erase a) (erase b)
  | pv n => pv n
  end.

Lemma erase_pimp : forall a b, erase (pimp a b) = pimp (erase a) (erase b).
Proof. induction a; intros b; simpl; try reflexivity. Qed.

(* A1/A2 是二值重言式（模式级） *)
Lemma taut_A1 : forall X Y s, peval (pimp X (pimp Y X)) s = true.
Proof. intros X Y s. simpl.
  destruct (peval X s); destruct (peval Y s); reflexivity. Qed.

Lemma taut_A2 : forall X Y Z s,
  peval (pimp (pimp X (pimp Y Z)) (pimp (pimp X Y) (pimp X Z))) s = true.
Proof.
  intros X Y Z s. simpl.
  destruct (peval X s); destruct (peval Y s); destruct (peval Z s);
    reflexivity.
Qed.

(* super 保持 MP *)
Theorem super_MP : forall B C,
  (forall s, peval (erase (pimp B C)) s = true) ->
  (forall s, peval (erase B) s = true) ->
  (forall s, peval (erase C) s = true).
Proof.
  intros B C H1 H2 s. rewrite erase_pimp in H1.
  specialize (H1 s). specialize (H2 s). simpl in H1.
  destruct (peval (erase B) s); destruct (peval (erase C) s);
    simpl in *; congruence.
Qed.

Theorem A1_super : forall B C s, peval (erase (pimp B (pimp C B))) s = true.
Proof. intros B C s. rewrite !erase_pimp. apply taut_A1. Qed.

Theorem A2_super : forall B C D s,
  peval (erase (pimp (pimp B (pimp C D)) (pimp (pimp B C) (pimp B D)))) s
  = true.
Proof. intros B C D s. rewrite !erase_pimp. apply taut_A2. Qed.

(* 反例：A3 实例不 super——擦负号后非重言（全假赋值下为假） *)
Example a3_not_super :
  peval (erase (pimp (pimp (pneg (pv 0)) (pneg (pv 0)))
                    (pimp (pimp (pneg (pv 0)) (pv 0)) (pv 0))))
        (fun _ => false) = false.
Proof. reflexivity. Qed.

(* ============ 五、L1（Hilbert–Ackermann ∨¬ 系统）四公理重言验证 ============ *)

Theorem L1_ax1 : forall B s, beval (imp (disj B B) B) s = true.
Proof. intros B s. simpl. destruct (beval B s); reflexivity. Qed.

Theorem L1_ax2 : forall B C s, beval (imp B (disj B C)) s = true.
Proof. intros B C s. simpl.
  destruct (beval B s); destruct (beval C s); reflexivity. Qed.

Theorem L1_ax3 : forall B C s, beval (imp (disj B C) (disj C B)) s = true.
Proof. intros B C s. simpl.
  destruct (beval B s); destruct (beval C s); reflexivity. Qed.

Theorem L1_ax4 : forall B C D s,
  beval (imp (imp C D) (imp (disj B C) (disj B D))) s = true.
Proof.
  intros B C D s. simpl.
  destruct (beval B s); destruct (beval C s); destruct (beval D s);
    reflexivity.
Qed.

(* ============ 账本 ============ *)

Print Assumptions shannon_ok.
Print Assumptions tAND_ok.
Print Assumptions toDown_ok.
Print Assumptions undef_neg.
Print Assumptions A2_sel.
Print Assumptions a1_not_sel.
Print Assumptions A1_super.
