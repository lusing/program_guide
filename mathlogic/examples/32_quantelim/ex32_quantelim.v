(* ex32_quantelim.v —— 量词消去（Marker ch7）
   机器件：DLO 单变量存在式的区间推理消去（完备方向定理零公理+
   相邻性反例——密度公理在说话）；F_p 上 Horner 求值与暴根表；
   F_9=F_3[t]/(t^2+1) 上「无根变有根」的扩域见证（代数闭包一瞥）；
   一维可定义集「有限或余有限」的强极小性计数表（ACF tame 影子）。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. DLO 量词消去：区间推理 ---------- *)

Inductive zlit : Type :=
| zGt (p : nat)
| zLt (p : nat)
| zEq (p : nat).

Definition pv2 (a b : nat) : nat -> nat :=
  fun k => if Nat.eqb k 0 then a else b.

Definition evZ (l : zlit) (z : nat) (P : nat -> nat) : bool :=
  match l with
  | zGt p => P p <? z
  | zLt p => z <? P p
  | zEq p => Nat.eqb z (P p)
  end.

Definition evEx (fs : list zlit) (P : nat -> nat) : bool :=
  existsb (fun z => forallb (fun l => evZ l z P) fs) (seq 0 21).

Fixpoint allGts (fs : list zlit) : list nat :=
  match fs with
  | [] => []
  | zGt p :: t => p :: allGts t
  | _ :: t => allGts t
  end.

Fixpoint allLts (fs : list zlit) : list nat :=
  match fs with
  | [] => []
  | zLt p :: t => p :: allLts t
  | _ :: t => allLts t
  end.

Fixpoint lmax (d : nat) (l : list nat) : nat :=
  match l with [] => d | x :: t => Nat.max x (lmax d t) end.

Fixpoint lmin (d : nat) (l : list nat) : nat :=
  match l with [] => d | x :: t => Nat.min x (lmin d t) end.

(* 非空表的首元作默认——保证结果落在表内 *)
Fixpoint lmin1 (x0 : nat) (l : list nat) : nat :=
  match l with [] => x0 | x :: t => Nat.min x (lmin1 x0 t) end.

Lemma lmax0_in : forall (l : list nat), l <> [] -> In (lmax 0 l) l.
Proof.
  induction l as [|x t IH]; intros Hne; [congruence|].
  simpl. destruct t as [|y t'].
  - rewrite Nat.max_0_r. left. reflexivity.
  - assert (Hne' : y :: t' <> []) by discriminate.
    specialize (IH Hne').
    destruct (le_lt_dec x (lmax 0 (y :: t'))) as [Hl|Hl].
    + rewrite Nat.max_r by lia. right. exact IH.
    + rewrite Nat.max_l by lia. left. reflexivity.
Qed.

Lemma lmin1_in : forall (x0 : nat) (l : list nat), In (lmin1 x0 l) (x0 :: l).
Proof.
  intros x0 l. induction l as [|x t IH].
  - simpl. left. reflexivity.
  - simpl in *. destruct (le_lt_dec x (lmin1 x0 t)) as [Hl|Hl].
    + rewrite Nat.min_l by lia. right. left. reflexivity.
    + rewrite Nat.min_r by lia.
      destruct IH as [Heq | Hin].
      * left. exact Heq.
      * right. right. exact Hin.
Qed.

Lemma lmax_ub : forall (l : list nat) (b : nat),
  (forall x, In x l -> x < b) -> l <> [] -> lmax 0 l < b.
Proof.
  intros l b Hlt Hne.
  apply Hlt. apply lmax0_in. exact Hne.
Qed.

Lemma lmin1_lb : forall (x0 : nat) (l : list nat) (b : nat),
  (forall x, In x (x0 :: l) -> b < x) -> b < lmin1 x0 l.
Proof.
  intros x0 l b Hgt.
  apply Hgt. apply lmin1_in.
Qed.

(* 完备方向：有见证 ⟹ 无量词条件成立（零公理） *)
Definition qfcond (fs : list zlit) (P : nat -> nat) : bool :=
  match allGts fs, allLts fs with
  | [], _ => true
  | _, [] => true
  | _, u :: rest =>
      lmax 0 (map P (allGts fs)) <? lmin1 (P u) (map P rest)
  end.

Lemma in_allGts : forall fs p,
  In p (allGts fs) -> In (zGt p) fs.
Proof.
  induction fs as [|a t IH]; intros p H; simpl in H.
  - contradiction.
  - destruct a as [q|q|q].
    + destruct H as [->|H]; [left; reflexivity|].
      right. apply IH. exact H.
    + right. apply IH. exact H.
    + right. apply IH. exact H.
Qed.

Lemma in_allLts : forall fs p,
  In p (allLts fs) -> In (zLt p) fs.
Proof.
  induction fs as [|a t IH]; intros p H; simpl in H.
  - contradiction.
  - destruct a as [q|q|q].
    + right. apply IH. exact H.
    + destruct H as [->|H]; [left; reflexivity|].
      right. apply IH. exact H.
    + right. apply IH. exact H.
Qed.

Theorem qe_complete_dir : forall fs P,
  evEx fs P = true -> qfcond fs P = true.
Proof.
  intros fs P H. unfold evEx in H.
  apply existsb_exists in H. destruct H as [z [Hz Hall]].
  apply in_seq in Hz. destruct Hz as [_ Hz]. simpl in Hz.
  pose proof (proj1 (forallb_forall (fun l => evZ l z P) fs) Hall) as HAll.
  unfold qfcond.
  destruct (allGts fs) as [|g gs] eqn:Eg.
  - reflexivity.
  - destruct (allLts fs) as [|u us] eqn:Eu.
    + reflexivity.
    + apply Nat.ltb_lt.
      assert (Hg : lmax 0 (map P (g :: gs)) < z).
      { apply lmax_ub; [|discriminate].
        intros x Hx. apply in_map_iff in Hx.
        destruct Hx as [p [<- Hp]].
        assert (HinG : In (zGt p) fs).
        { apply in_allGts. rewrite Eg. exact Hp. }
        specialize (HAll (zGt p) HinG).
        unfold evZ in HAll. apply Nat.ltb_lt. exact HAll. }
      assert (Hu : z < lmin1 (P u) (map P us)).
      { apply lmin1_lb.
        intros x Hx.
        assert (Hex : exists p, P p = x /\ In (zLt p) fs).
        { destruct Hx as [Heq | HinMap].
          - exists u. split; [congruence|].
            apply in_allLts. rewrite Eu. simpl. left. reflexivity.
          - apply in_map_iff in HinMap.
            destruct HinMap as [p [<- Hp]].
            exists p. split; [reflexivity|].
            apply in_allLts. rewrite Eu. simpl. right. exact Hp. }
        destruct Hex as [p [Hpx Hp]].
        rewrite <- Hpx.
        specialize (HAll (zLt p) Hp).
        unfold evZ in HAll. apply Nat.ltb_lt. exact HAll. }
      lia.
Qed.

(* 经典恒等式 ∃z(x<z ∧ z<y) ↔ x<y：非相邻赋值上的双向对账 *)
Example between_agree :
  forallb (fun ab =>
    let a := fst ab in let b := snd ab in
    if andb (Nat.ltb a b) (Nat.leb 2 (b - a)) then
      Bool.eqb (evEx [zGt 0; zLt 1] (pv2 a b))
               (qfcond [zGt 0; zLt 1] (pv2 a b))
    else true)
    (list_prod (seq 0 8) (seq 0 8)) = true.
Proof. reflexivity. Qed.

(* 相邻性反例：x=2,y=3——序条件真、样本链无中介。
   在真 DLO(ℚ,<) 中 2<3 即有中介；有限采样只在步长 ≥2 处
   模拟密度——密度公理在说话 *)
Example adjacency_counter :
  andb (qfcond [zGt 0; zLt 1] (pv2 2 3))
       (negb (evEx [zGt 0; zLt 1] (pv2 2 3))) = true.
Proof. reflexivity. Qed.

(* 等词文字：∃z(z=x ∧ z>y) ↔ x>y（等式锁定 z） *)
Definition qfcond_eq (a b : nat) : bool := b <? a.

Example eq_lit_case :
  forallb (fun ab =>
    Bool.eqb (evEx [zEq 0; zGt 1] (pv2 (fst ab) (snd ab)))
             (qfcond_eq (fst ab) (snd ab)))
    (list_prod (seq 0 8) (seq 0 8)) = true.
Proof. reflexivity. Qed.

(* ---------- 2. F_p 求值与暴根表 ---------- *)

(* 系数表低次在前；Horner 求值 *)
Fixpoint pevalc (p : nat) (cs : list nat) (x : nat) : nat :=
  match cs with
  | [] => 0
  | c :: rest => (c + x * pevalc p rest x) mod p
  end.

Definition hasRootFp (p : nat) (f : list nat) : bool :=
  existsb (fun x => Nat.eqb (pevalc p f x) 0) (seq 0 p).

Definition rootsFp (p : nat) (f : list nat) : list nat :=
  filter (fun x => Nat.eqb (pevalc p f x) 0) (seq 0 p).

(* x^2+1 / x^2-1 / x^2 over F_3：无根 / 两根 ±1 / 一根 *)
Example f3_roots_table :
  map (fun f => length (rootsFp 3 f)) [[1;0;1]; [2;0;1]; [0;0;1]] = [0;2;1].
Proof. reflexivity. Qed.

(* ---------- 3. F_9 = F_3[t]/(t^2+1)：扩域见证 ---------- *)

Definition f9add (a b : nat * nat) : nat * nat :=
  ((fst a + fst b) mod 3, (snd a + snd b) mod 3).
Definition f9mul (a b : nat * nat) : nat * nat :=
  ((fst a * fst b + 2 * snd a * snd b) mod 3,
   (fst a * snd b + snd a * fst b) mod 3).

Fixpoint pevalF9 (cs : list nat) (x : nat * nat) : nat * nat :=
  match cs with
  | [] => (0, 0)
  | c :: rest => f9add (c mod 3, 0) (f9mul x (pevalF9 rest x))
  end.

Definition F9 : list (nat * nat) := list_prod (seq 0 3) (seq 0 3).

Definition rootsF9 (f : list nat) : list (nat * nat) :=
  filter (fun e => andb (Nat.eqb (fst (pevalF9 f e)) 0)
                        (Nat.eqb (snd (pevalF9 f e)) 0)) F9.

(* x^2+1：F_3 无根、F_9 有根 (0,1)——「F_p 无根变 F_{p^2} 有根」 *)
Example f3_x2p1_noroot : negb (hasRootFp 3 [1;0;1]) = true.
Proof. reflexivity. Qed.

Example f9_x2p1_root : pevalF9 [1;0;1] (0,1) = (0,0).
Proof. reflexivity. Qed.

(* ---------- 4. 强极小性影子：一维可定义集有限或余有限 ---------- *)

(* F_3 上全部 9 个首一二次多项式（b + a·x + x²）的根数表 *)
Definition monicQuads : list (list nat) :=
  map (fun ab => [snd ab; fst ab; 1]) (list_prod (seq 0 3) (seq 0 3)).

Example strong_min_table :
  map (fun f => length (rootsFp 3 f)) monicQuads
  = [1;0;2;2;1;0;2;1;0].
Proof. reflexivity. Qed.
(* 每行 ≤ 2 = deg，域大小 3 —— 零点集必有限（≤deg），其余可定义集
   由布尔组合生成，余有限侧对称成立：强极小性（书 Def 7.18 区）的
   数值影子。ACF QE 的完整引擎（Euclid 除法+「非常数即有根」）记
   文档线。 *)

(* 冒烟 *)
Compute (map (fun f => (f, rootsFp 3 f)) [[1;0;1];[2;0;1]]).
Compute (length monicQuads, length (rootsF9 [1;0;1])).
Print Assumptions qe_complete_dir.   (* Closed under global context *)
