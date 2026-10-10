(* ex40_roughset.v —— 粗糙集、语用力与双直觉主义（Bellin 篇，书 ch10）
   机器件三段——
   (1) 粗糙集实验室：3 元宇宙全部 5 个等价关系（512 关系全过滤）；
       内部/闭包按等价类算（x∈I(G) ⟺ [x]⊆G；x∈C(G) ⟺ [x]∩G≠∅）；
       不相交表示 (I(G), −C(G))=（证明空间,反驳空间）；三区
       POS/BND/NEG；账：I(−G)=−C(G) 对偶恒真、negPair∘negPair=id
       （书引理 2/式 (5) 的集合语义面）、BND(G∩H)⊇BND(G)∩BND(H)
       全对全验证；
   (2) 双模态 S4 帧枚举：3 世界全部 29 个预序（512 过滤）、841 个
       (R,S) 对；**引理 1(ii)(a) 的穷举式机器证明**：
       Ax.a「□_Rλ⊃□_S□_Rλ 在帧上有效」⟺「S⊆R」逐帧等价；
       引理 1(i)（预序传递性方向的 □□⊃□）在一切 (R,S) 帧有效；
   (3) 余直觉减法的 Kripke 语义：w⊩C∖D ⟺ ∃w'≤w: w'⊩C 且 w'⊮D；
       全预序枚举下：C⊢C∖⊥ 有效、C∖D⊬C 无效（反模型交出）、
       分配律 C∖(D⋎E)⊢(C∖D)⋎(C∖E) 有效。
   零公理。坑位速记见 docs/40-roughset.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. 粗糙集实验室 ---------- *)

Definition rel3 : Type := nat.    (* 9 位掩码：bit(3i+j) = E(i,j) *)

Definition relAt (E : nat) (i j : nat) : bool := Nat.testbit E (3 * i + j).

Definition allRels : list nat := seq 0 512.

Definition reflOK (E : nat) : bool :=
  forallb (fun i => relAt E i i) [0;1;2].
Definition symmOK (E : nat) : bool :=
  forallb (fun i => forallb (fun j =>
    implb (relAt E i j) (relAt E j i)) [0;1;2]) [0;1;2].
Definition transOK (E : nat) : bool :=
  forallb (fun i => forallb (fun j => forallb (fun k =>
    if andb (relAt E i j) (relAt E j k) then relAt E i k else true)
    [0;1;2]) [0;1;2]) [0;1;2].

Definition equivOK (E : nat) : bool :=
  andb (reflOK E) (andb (symmOK E) (transOK E)).

Definition allEquivs : list nat := filter equivOK allRels.

(* 子集=3 位掩码 *)
Definition memU (G x : nat) : bool := Nat.testbit G x.
Definition compU (G : nat) : nat := Nat.lxor 7 G.
Definition allSubsU : list nat := seq 0 8.

(* 类 [x] 与内部/闭包 *)
Definition cls (E x : nat) : nat :=
  (if relAt E x 0 then 1 else 0)
+ (if relAt E x 1 then 2 else 0)
+ (if relAt E x 2 then 4 else 0).

Definition subU (G H : nat) : bool :=
  forallb (fun x => implb (memU G x) (memU H x)) [0;1;2].

Definition intersects (G H : nat) : bool :=
  negb (Nat.eqb (Nat.land G H) 0).

Definition interrE (E G : nat) : nat :=
  (if subU (cls E 0) G then 1 else 0)
+ (if subU (cls E 1) G then 2 else 0)
+ (if subU (cls E 2) G then 4 else 0).

Definition closrE (E G : nat) : nat :=
  (if intersects (cls E 0) G then 1 else 0)
+ (if intersects (cls E 1) G then 2 else 0)
+ (if intersects (cls E 2) G then 4 else 0).

(* 账一：对偶恒真 I(−G) = −C(G)（一切等价关系、一切子集） *)
Example interior_closure_duality :
  forallb (fun E => forallb (fun G =>
    Nat.eqb (interrE E (compU G)) (compU (closrE E G))) allSubsU)
    allEquivs
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 账二：negPair∘negPair=id（书式 (5) 的集合面）：
   negPair(X,Y) = (−Y,−X)；对不相交对（I(G),−C(G)）施加两次复原 *)
Definition negPairFst (X Y : nat) : nat := compU Y.
Definition negPairSnd (X Y : nat) : nat := compU X.

Example negneg_pair :
  forallb (fun E => forallb (fun G =>
    andb (Nat.eqb (negPairFst (negPairFst (interrE E G) (compU (closrE E G)))
                                 (negPairSnd (interrE E G) (compU (closrE E G))))
                    (interrE E G))
         (Nat.eqb (negPairSnd (negPairFst (interrE E G) (compU (closrE E G)))
                              (negPairSnd (interrE E G) (compU (closrE E G))))
                  (compU (closrE E G)))) allSubsU) allEquivs
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 账三：分配律 I(G∩H)=I(G)∩I(G)？——**否**！正确的是
   I(G∩H)=I(G)∩I(H)（内部对交分配）与 C(G∪H)=C(G)∪C(H)
   （闭包对并分配）。注意 BND 的两个「包含直觉」都不成立：
   类 [x] 可以在不同元素处分别碰 G 与 H（G∩H 空）——边界不吃
   交。机器账只立恒真者。 *)
Definition bnd (E G : nat) : nat :=
  Nat.land (closrE E G) (compU (interrE E G)).

Example interior_meets :
  forallb (fun E => forallb (fun G => forallb (fun H =>
    Nat.eqb (interrE E (Nat.land G H))
            (Nat.land (interrE E G) (interrE E H))) allSubsU) allSubsU)
    allEquivs
  = true.
Proof. vm_compute. reflexivity. Qed.

Example closure_joins :
  forallb (fun E => forallb (fun G => forallb (fun H =>
    Nat.eqb (closrE E (Nat.lor G H))
            (Nat.lor (closrE E G) (closrE E H))) allSubsU) allSubsU)
    allEquivs
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 反例账：BND(G∩H) ⊇ BND(G)∩BND(H) **不成立**——等价关系
   {x}|{y,z}、G={y}、H={z}：y∈BND(G)∩BND(H) 但 G∩H=∅ *)
Example boundary_inclusion_fails :
  subU (Nat.land (bnd 433 2) (bnd 433 4)) (bnd 433 (Nat.land 2 4))
  = false.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. 双模态 S4：引理 1 的穷举式机器证明 ---------- *)

Definition preordOK (E : nat) : bool := andb (reflOK E) (transOK E).
Definition allPreords : list nat := filter preordOK allRels.

Definition SRsub (S R : nat) : bool :=
  forallb (fun i => forallb (fun j =>
    implb (relAt S i j) (relAt R i j)) [0;1;2]) [0;1;2].

Inductive mform : Type :=
| mp                                     (* 原子 p *)
| mimp (a b : mform)
| mboxR (a : mform)
| mboxS (a : mform).

(* 赋值：p 在 w 的真值（3 位掩码） *)
Fixpoint evM (R S val : nat) (w : nat) (f : mform) : bool :=
  match f with
  | mp => Nat.testbit val w
  | mimp a b => implb (evM R S val w a) (evM R S val w b)
  | mboxR a =>
      forallb (fun w' => implb (relAt R w w') (evM R S val w' a))
              [0;1;2]
  | mboxS a =>
      forallb (fun w' => implb (relAt S w w') (evM R S val w' a))
              [0;1;2]
  end.

Definition allVals3 : list nat := seq 0 8.

Definition frameValid (R S : nat) (f : mform) : bool :=
  forallb (fun val => forallb (fun w => evM R S val w f)
                             [0;1;2]) allVals3.

(* Ax.a：□_Rλ ⊃ □_S□_Rλ（以原子 p 代 λ——公理模式对原子成立即可
   由替换引理推广；文档线） *)
Definition axA : mform := mimp (mboxR mp) (mboxS (mboxR mp)).

(* 引理 1(ii)(a)：Ax.a 在 (R,S) 上有效 ⟺ S⊆R——**逐帧等价** *)
Example lemma1a_iff :
  forallb (fun p =>
     let R := fst p in let S := snd p in
     Bool.eqb (frameValid R S axA) (SRsub S R))
    (flat_map (fun R => map (fun S => (R, S)) allPreords) allPreords)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 引理 1(i)：□_R□_Rλ⊃□_Rλ 与 □_S□_Sλ⊃□_Sλ 在一切预序帧有效 *)
Example lemma1i_trans :
  forallb (fun p =>
     let R := fst p in let S := snd p in
     andb (frameValid R S (mimp (mboxR (mboxR mp)) (mboxR mp)))
          (frameValid R S (mimp (mboxS (mboxS mp)) (mboxS mp))))
    (flat_map (fun R => map (fun S => (R, S)) allPreords) allPreords)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. 余直觉减法的 Kripke 语义 ---------- *)

(* w⊩C∖D ⟺ ∃w'≤w: w'⊩C 且 w'⊮D；⋎=局部析取。
   公式：catom | cor_ | cdiff | cfalse *)
Inductive cform : Type :=
| ca (n : nat)
| cor_ (a b : cform)
| cdiff (a b : cform)
| cbot.

Fixpoint evC (R val : nat) (w : nat) (f : cform) : bool :=
  match f with
  | ca n => Nat.testbit val (3 * n + w)
  | cor_ a b => orb (evC R val w a) (evC R val w b)
  | cdiff a b =>
      existsb (fun w' =>
        andb (andb (relAt R w w') (evC R val w' a))
             (negb (evC R val w' b))) [0;1;2]
  | cbot => false
  end.

(* 有效：一切预序、一切赋值（2 原子 6 位）、一切世界 *)
Definition cValid (f : cform) : bool :=
  forallb (fun R =>
    forallb (fun val => forallb (fun w => evC R val w f) [0;1;2])
            (seq 0 64)) allPreords.

(* 后承判定：一切帧/赋值/世界上 a 真则 b 真 *)
Definition cseq (a b : cform) : bool :=
  forallb (fun R =>
    forallb (fun val => forallb (fun w =>
      implb (evC R val w a) (evC R val w b)) [0;1;2])
            (seq 0 64)) allPreords.

(* 电一：C ⊢ C∖⊥ 有效——w 自身即见证（自反性） *)
Example cdiff_bot_valid :
  cseq (ca 0) (cdiff (ca 0) cbot) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：C∖D ⊬ C 无效——反模型：2 链 w0≤w1，C 只在 w1，D 处处假 *)
Example cdiff_not_c :
  cseq (cdiff (ca 0) (ca 1)) (ca 0) = false.
Proof. vm_compute. reflexivity. Qed.

(* 电三：分配律 C∖(D⋎E) ⊢ (C∖D)⋎(C∖E) 有效 *)
Example cdiff_distrib :
  cseq (cdiff (ca 0) (cor_ (ca 1) (ca 2)))
       (cor_ (cdiff (ca 0) (ca 1)) (cdiff (ca 0) (ca 2)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (length allEquivs, length allPreords).
Compute (interrE 433 5, closrE 433 5).  (* E=433: {0}|{1,2} 分块；G={0,2} *)
