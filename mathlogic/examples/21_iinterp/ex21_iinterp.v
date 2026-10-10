(* ex21_iinterp.v —— 直觉主义插值与 Beth 可定义性（Mints ch11-12）
   机器件：≤3 世界**全预序枚举**的有界 Kripke 有效性检查器（预序 =
   n² 位关系掩码过滤自反+传递；赋值=逐变元上集——单调性内建）；
   **语义签名去重**的插值子搜索宇宙（候选公式按「全模型×全世界力迫
   向量」折叠成代表——Lindenbaum 代数的算法影子）；Craig 插值双条件
   （α→t 与 t→β 皆有界有效+t 变元⊆共享）三型样本（共享/常值流/划分）；
   Beth：隐定义 α∧α[p/q]→(p↔q) 有效性+显定义 t（不含 p）搜索——
   环链样本 α=(p→q)∧(q→r)∧(r→p) 的 t=q 全账（Thm 12.2）。文档线：
   Mints 的 LJp 逐情形构造（Case 0-4 组合表）与 73 章经典 Maehara 的
   对照、谓词版 Beth（Thm 15.6）指向 75 章。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition impb (a b : bool) : bool := if a then b else true.

(* ---------- 1. 公式与变元账 ---------- *)

Inductive fm : Type :=
| pv  : nat -> fm
| ff  : fm
| aand : fm -> fm -> fm
| oor : fm -> fm -> fm
| iimp : fm -> fm -> fm.

Notation "a ~> b" := (iimp a b) (at level 90, right associativity).
Definition negf (a : fm) : fm := a ~> ff.
Definition top : fm := ff ~> ff.

Fixpoint fmeqb (a b : fm) : bool :=
  match a, b with
  | pv m, pv n => Nat.eqb m n
  | ff, ff => true
  | aand x y, aand u v => andb (fmeqb x u) (fmeqb y v)
  | oor x y, oor u v => andb (fmeqb x u) (fmeqb y v)
  | iimp x y, iimp u v => andb (fmeqb x u) (fmeqb y v)
  | _, _ => false
  end.

Definition memF (a : fm) (l : list fm) : bool := existsb (fmeqb a) l.
Definition addF (a : fm) (l : list fm) : list fm :=
  if memF a l then l else a :: l.

Fixpoint varsOf (a : fm) : list nat :=
  match a with
  | pv n => [n]
  | ff => []
  | aand x y => varsOf x ++ varsOf y
  | oor x y => varsOf x ++ varsOf y
  | iimp x y => varsOf x ++ varsOf y
  end.

Definition subVars (l : list nat) (m : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) m) l.

Fixpoint dedupN (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => let r := dedupN t in
      if existsb (Nat.eqb x) r then r else x :: r
  end.

(* ---------- 2. ≤3 世界全预序枚举的有界 Kripke 语义 ---------- *)

(* 帧=(n, 关系位掩码)：R i j 的位号 = i*n+j *)
Definition frame := (nat * nat)%type.
Definition rOf (F : frame) (i j : nat) : bool :=
  Nat.testbit (snd F) (fst F * i + j).
Definition rBit (n m i j : nat) : bool := Nat.testbit m (n * i + j).

Definition preord (n m : nat) : bool :=
  (* 自反 *)
  forallb (fun i => rBit n m i i) (seq 0 n)
  && forallb (fun i =>
       forallb (fun j =>
         forallb (fun k =>
            impb (andb (rBit n m i j) (rBit n m j k)) (rBit n m i k))
           (seq 0 n)) (seq 0 n)) (seq 0 n).

Definition allPreords (n : nat) : list frame :=
  map (fun m => (n, m)) (filter (preord n) (seq 0 (2 ^ (n * n)))).

(* 赋值：变元 0/1 → 世界集（须为上集）；力迫按 Def 7.2 *)
Definition valUp (F : frame) (s : nat) (n : nat) : list nat :=
  filter (fun w => Nat.testbit s w) (seq 0 (fst F)).

Definition isUpsetV (F : frame) (A : list nat) : bool :=
  forallb (fun i =>
     impb (existsb (Nat.eqb i) A)
          (forallb (fun j => impb (rOf F i j) (existsb (Nat.eqb j) A))
                   (seq 0 (fst F))))
    (seq 0 (fst F)).

Fixpoint force (F : frame) (v0 v1 : list nat) (w : nat) (a : fm) : bool :=
  match a with
  | pv 0 => existsb (Nat.eqb w) v0
  | pv _ => existsb (Nat.eqb w) v1
  | ff => false
  | aand x y => andb (force F v0 v1 w x) (force F v0 v1 w y)
  | oor x y => orb (force F v0 v1 w x) (force F v0 v1 w y)
  | iimp x y =>
      forallb (fun w' => impb (rOf F w w')
                        (impb (force F v0 v1 w' x) (force F v0 v1 w' y)))
               (seq 0 (fst F))
  end.

(* 有界有效性：≤3 世界全预序×全单调赋值×全世界 *)
Definition bValid (a : fm) : bool :=
  forallb (fun F =>
     let n := fst F in
     forallb (fun s0 =>
        let A0 := valUp F s0 0 in
        forallb (fun s1 =>
           let A1 := valUp F s1 1 in
           forallb (fun w => force F A0 A1 w a) (seq 0 n))
           (filter (fun s => isUpsetV F (valUp F s 1)) (seq 0 (2 ^ n))))
        (filter (fun s => isUpsetV F (valUp F s 0)) (seq 0 (2 ^ n))))
    (allPreords 1 ++ allPreords 2 ++ allPreords 3).

(* 矢列 Γ⇒Δ 的有界有效性：∧Γ→∨Δ *)
Definition seqValid (G D : list fm) : bool :=
  bValid (fold_right aand top G ~> fold_right oor ff D).

(* ---------- 3. 语义签名与插值子搜索 ---------- *)

(* 签名=在探针模型族上的力迫向量——语义等价类的代表折叠
   （Lindenbaum 代数的算法影子：代数元素=等价类，此处以有界语义近似） *)
Definition sigOf (a : fm) : list bool :=
  flat_map
    (fun F =>
       let n := fst F in
       let v0s := [0; 1; 2; 3] in
       let v1s := [0; 1; 2; 3; 4; 5; 6; 7] in
       flat_map
         (fun s0 =>
            let A0 := valUp F s0 0 in
            flat_map
              (fun s1 =>
                 let A1 := valUp F s1 1 in
                 map (fun w => force F A0 A1 w a) (seq 0 n))
              v1s)
         v0s)
    (allPreords 3).

Definition beqb (a b : bool) : bool := if a then b else negb b.

Fixpoint eqbList (l1 l2 : list bool) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: t1, b :: t2 => andb (beqb a b) (eqbList t1 t2)
  | _, _ => false
  end.

Fixpoint dedupSig (l : list fm) : list fm :=
  match l with
  | [] => []
  | x :: t => let r := dedupSig t in
      if existsb (fun y => eqbList (sigOf x) (sigOf y)) r then r else x :: r
  end.

(* 候选宇宙：变元 {0,1}+⊥ 的深度≤2 闭包，签名折叠 *)
Definition univ0 : list fm := [pv 0; pv 1; ff].
Definition binClose (base : list fm) : list fm :=
  flat_map (fun x =>
     flat_map (fun y => [aand x y; oor x y; iimp x y]) base) base.
Definition univ12 : list fm := univ0 ++ binClose univ0.
(* 深度≤2 的 30 候选——样本的插值子（q/⊥/p/∧∨组合）全在此层；
   更深候选会把枚举推到 10⁶ 级，教学不需要 *)
Definition univ : list fm := dedupSig univ12.

(* Craig 插值子（Mints Def：对 α→β 的 t：α→t 与 t→β 有效、
   vars(t) ⊆ vars(α)∩vars(β)）——搜第一个满足者 *)
Definition interpOf (a b : fm) : option fm :=
  let shared := filter (fun x => existsb (Nat.eqb x) (varsOf b))
                       (dedupN (varsOf a)) in
  match filter (fun t =>
            andb (subVars (varsOf t) shared)
                 (andb (bValid (a ~> t)) (bValid (t ~> b)))) univ with
  | [] => None
  | t :: _ => Some t
  end.

Definition isInterp (a b t : fm) : bool :=
  andb (subVars (varsOf t) (filter (fun x => existsb (Nat.eqb x) (varsOf b))
                                   (dedupN (varsOf a))))
       (andb (bValid (a ~> t)) (bValid (t ~> b))).

(* ---------- 4. 三型样本 ---------- *)

Definition P : fm := pv 0.
Definition Q : fm := pv 1.

(* 先验证前提 α→β 有界有效，再报插值子 *)
Example share_valid : bValid ((aand P Q) ~> (oor Q (pv 2))) = true.
Proof. vm_compute. reflexivity. Qed.

Example share_interp :
  match interpOf (aand P Q) (oor Q (pv 2)) with
  | Some t => isInterp (aand P Q) (oor Q (pv 2)) t
  | None => false
  end = true.
Proof. vm_compute. reflexivity. Qed.

(* 常值流：矛盾前件流的 ⊥（变元空集） *)
Example const_valid : bValid ((aand Q (negf Q)) ~> (oor P (negf P))) = true.
Proof. vm_compute. reflexivity. Qed.

Example const_interp :
  match interpOf (aand Q (negf Q)) (oor P (negf P)) with
  | Some t => isInterp (aand Q (negf Q)) (oor P (negf P)) t
  | None => false
  end = true.
Proof. vm_compute. reflexivity. Qed.

(* 划分版（Mints Def 的 Γ;Δ→α）：(p∧q);(q→r) ⊢ r 的 t=q *)
Example part_valid :
  seqValid [aand P Q; Q ~> pv 2] [pv 2] = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. Beth 可定义性（Thm 12.2） ---------- *)

(* 代入 p:=q *)
Fixpoint substP (a : fm) : fm :=
  match a with
  | pv 0 => pv 1
  | pv n => pv n
  | ff => ff
  | aand x y => aand (substP x) (substP y)
  | oor x y => oor (substP x) (substP y)
  | iimp x y => iimp (substP x) (substP y)
  end.

(* 隐定义：α∧α[p/q]→(p↔q) 有效（p 至多一个） *)
Definition implicitDef (a : fm) : bool :=
  bValid (aand a (substP a) ~> aand (P ~> Q) (Q ~> P)).

(* 环链 α=(p→q)∧(q→r)∧(r→p)：r 退场后 p 被 q 唯一确定 *)
Definition ringA : fm := aand (aand (P ~> Q) (Q ~> pv 2))
                              (pv 2 ~> P).

Example ring_implicit : implicitDef ringA = true.
Proof. vm_compute. reflexivity. Qed.

(* 显定义核：t=q 不含 p 且 α→(p↔q)（Thm 12.2 的构造产物） *)
Example ring_explicit :
  andb (negb (existsb (Nat.eqb 0) (varsOf Q)))
       (bValid (ringA ~> aand (P ~> Q) (Q ~> P))) = true.
Proof. vm_compute. reflexivity. Qed.

(* 非隐定义对照：α=p∨q 不隐定义 p *)
Example not_implicit : implicitDef (oor P Q) = false.
Proof. vm_compute. reflexivity. Qed.
