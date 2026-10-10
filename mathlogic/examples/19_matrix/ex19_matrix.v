(* ex19_matrix.v —— 有限矩阵与拓扑完备性（Mints ch8.5.3 + ch9 + 8.4 桥）
   机器件：帧的上集位掩码矩阵——真值域=上集全集（「单调数」，例 8.1 的
   {0,2,3} 现场复刻：{0} 非单调被除名）；∧∨=交并、→=Kripke 蕴含的
   逐世界定义（8.5.3）；LEM/DNE 在链矩阵、WLEM/Dummett 在 V 帧矩阵
   （8 子集中恰 5 上集，练习 8.8）四连驳；IPC 定理库全取顶值的可靠性
   侧账（Thm 8.6 ⟸）；锥拓扑=上集开集：Interior((X−A)∪B) 与 Kripke
   蕴含逐上集对重合、力迫集↔开集赋值全公式对账（Thm 9.1 的构造核）；
   Thm 9.2 的 [0,1] 级数嵌入 β_s=Σ2·s(n)·q^{n+1}（q=1/(2N−1)）——
   「前缀+稳定尾」精确整数模型，分离引理 9.1(b)(c)(d) nat 缩放逐对账。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition impb (a b : bool) : bool := if a then b else true.

Definition memN (x : nat) (l : list nat) : bool := existsb (Nat.eqb x) l.
Definition inclb (l1 l2 : list nat) : bool := forallb (fun x => memN x l2) l1.
Definition eqSetL (l1 l2 : list nat) : bool :=
  andb (inclb l1 l2) (inclb l2 l1).
Fixpoint cross {A B} (l1 : list A) (l2 : list B) : list (A * B) :=
  match l1 with
  | [] => []
  | a :: t => map (fun b => (a, b)) l2 ++ cross t l2
  end.

(* ---------- 1. 帧、上集与矩阵运算 ---------- *)

Inductive fm : Type :=
| pv  : nat -> fm
| ff  : fm
| aand : fm -> fm -> fm
| oor : fm -> fm -> fm
| iimp : fm -> fm -> fm.

Notation "a ~> b" := (iimp a b) (at level 90, right associativity).
Definition negf (a : fm) : fm := a ~> ff.

Definition frame := (nat * (nat -> nat -> bool))%type.
Definition worlds (F : frame) : list nat := seq 0 (fst F).
Definition rOf (F : frame) : nat -> nat -> bool := snd F.

Definition chain2 : frame := (2, fun i j => Nat.leb i j).
Definition vframe : frame :=
  (3, fun i j => orb (Nat.eqb i j) (Nat.eqb i 0)).

Fixpoint subsOf (l : list nat) : list (list nat) :=
  match l with
  | [] => [[]]
  | x :: t => let r := subsOf t in r ++ map (cons x) r
  end.

Definition upsetP (F : frame) (S : list nat) : bool :=
  forallb (fun i =>
     impb (memN i S)
          (forallb (fun j => impb (rOf F i j) (memN j S)) (worlds F)))
    (worlds F).

Definition allUpsets (F : frame) : list (list nat) :=
  filter (upsetP F) (subsOf (worlds F)).

Definition mAnd (F : frame) (A B : list nat) : list nat :=
  filter (fun x => andb (memN x A) (memN x B)) (worlds F).
Definition mOr (F : frame) (A B : list nat) : list nat :=
  filter (fun x => orb (memN x A) (memN x B)) (worlds F).
Definition mImp (F : frame) (A B : list nat) : list nat :=
  filter (fun w =>
            forallb (fun w' =>
                       impb (rOf F w w')
                            (orb (negb (memN w' A)) (memN w' B)))
                       (worlds F))
         (worlds F).
Definition mNeg (F : frame) (A : list nat) : list nat := mImp F A [].

Definition val2 (F : frame) (a b : list nat) (n : nat) : list nat :=
  match n with 0 => a | 1 => b | _ => worlds F end.

Fixpoint mEval (F : frame) (V : nat -> list nat) (a : fm) : list nat :=
  match a with
  | pv n => V n
  | ff => []
  | aand x y => mAnd F (mEval F V x) (mEval F V y)
  | oor x y => mOr F (mEval F V x) (mEval F V y)
  | iimp x y => mImp F (mEval F V x) (mEval F V y)
  end.

Definition mValid2 (F : frame) (a : fm) : bool :=
  let U := allUpsets F in
  forallb (fun p => eqSetL (mEval F (val2 F (fst p) (snd p)) a) (worlds F))
          (cross U U).

Definition P : fm := pv 0.
Definition Q : fm := pv 1.

Definition bitmask (s : list nat) : nat :=
  fold_right (fun i m => m + 2 ^ i) 0 s.

(* 例 8.1 复刻：链 2 的真值域=位掩码 {0,2,3}；1={0} 非单调被除名 *)
Example chain2_upsets : map bitmask (allUpsets chain2) = [0; 2; 3].
Proof. vm_compute. reflexivity. Qed.

(* 练习 8.8：V 帧 8 子集中恰 5 个上集 *)
Example vframe_upsets5 : Nat.eqb (length (allUpsets vframe)) 5 = true.
Proof. vm_compute. reflexivity. Qed.

Example lem_fails  : mValid2 chain2 (oor P (negf P)) = false.
Proof. vm_compute. reflexivity. Qed.
Example dne_fails  : mValid2 chain2 (iimp (negf (negf P)) P) = false.
Proof. vm_compute. reflexivity. Qed.
Example wlem_fails : mValid2 vframe (oor (negf P) (negf (negf P))) = false.
Proof. vm_compute. reflexivity. Qed.
Example dummett_fails : mValid2 vframe (oor (iimp P Q) (iimp Q P)) = false.
Proof. vm_compute. reflexivity. Qed.

(* 可靠性侧账：IPC 定理库在两矩阵全取顶值（Thm 8.6 的 ⟸ 方向） *)
Definition ipcLib : list fm :=
  [ iimp P P
  ; negf (aand P (negf P))
  ; iimp (aand P Q) (aand Q P)
  ; iimp P (iimp Q P)
  ; iimp (aand P (iimp P Q)) Q
  ; iimp (iimp P Q) (iimp (negf Q) (negf P))
  ; negf (negf (iimp P P)) ].

Example ipc_holds :
  forallb (fun a => andb (mValid2 chain2 a) (mValid2 vframe a)) ipcLib = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. 锥拓扑：Thm 9.1 的构造核 ---------- *)

Definition interior (F : frame) (Y : list nat) : list nat :=
  filter (fun w => forallb (fun w' => impb (rOf F w w') (memN w' Y))
                          (worlds F))
         (worlds F).

Definition topImp (F : frame) (A B : list nat) : list nat :=
  interior F (mOr F (filter (fun w => negb (memN w A)) (worlds F)) B).

(* (9.2) Interior((X−A)∪B) 与 Kripke 蕴含在全部上集对上重合 *)
Example topImp_is_kripke :
  forallb (fun p => eqSetL (topImp vframe (fst p) (snd p))
                           (mImp vframe (fst p) (snd p)))
          (cross (allUpsets vframe) (allUpsets vframe)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 力迫集↔开集赋值：V(φ)={w|w⊩φ} 全公式对账（Lemma 8.8→Thm 9.1 桥） *)
Fixpoint force (F : frame) (V : nat -> list nat) (w : nat) (a : fm) : bool :=
  match a with
  | pv n => memN w (V n)
  | ff => false
  | aand x y => andb (force F V w x) (force F V w y)
  | oor x y => orb (force F V w x) (force F V w y)
  | iimp x y =>
      forallb (fun w' => impb (rOf F w w')
                        (impb (force F V w' x) (force F V w' y))) (worlds F)
  end.

Definition forcesSet (F : frame) (V : nat -> list nat) (a : fm) : list nat :=
  filter (fun w => force F V w a) (worlds F).

Definition coneFms : list fm :=
  [ P; Q; negf P; oor P Q; iimp P Q; negf (oor P (negf P));
    iimp (negf P) (negf (negf P)); oor (iimp P Q) (iimp Q P);
    iimp (iimp P Q) (oor P (iimp Q P)) ].

Example cone_bridge :
  forallb (fun p =>
     let V := val2 vframe (fst p) (snd p) in
     forallb (fun a => eqSetL (forcesSet vframe V a) (mEval vframe V a))
             coneFms)
    (cross (allUpsets vframe) (allUpsets vframe)) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. Thm 9.2：[0,1] 级数嵌入的精确整数模型 ---------- *)

(* β_s = Σ_{n≥0} 2·s(n)·q^{n+1}，q=1/(2N−1)，单调列至多 N−1 跳后稳定。
   全列=「前缀 l（长 m）+稳定值 w」。精确整数化（分母 D^m·(D−1)）：
   betaN = Σ_{n<m} 2·l(n)·D^{m−1−n}·(D−1) + 2w。分离引理 nat 缩放：
   (b) 尾项 2w ≤ D−1；(c) 前缀全同 ⟹ |Δ| ≤ D−1；
   (d) 首异位 j 且 t(j)>s(j) ⟹ Δ > D^{m−1−j}·(D−1)。 *)

Definition lastOf (l : list nat) : nat := fold_right Nat.max 0 l.

Fixpoint monoPre (N m : nat) : list (list nat) :=
  match m with
  | 0 => [[]]
  | S m' =>
      flat_map (fun l =>
          let lo := lastOf l in
          map (fun v => l ++ [v]) (seq lo (N - lo)))
        (monoPre N m')
  end.

Definition allSeqs (N m : nat) : list (list nat * nat) :=
  flat_map (fun l =>
      let lo := lastOf l in
      map (fun w => (l, w)) (seq lo (N - lo)))
    (monoPre N m).

Definition betaN (D : nat) (l : list nat) (w : nat) : nat :=
  let m := length l in
  fold_right (fun iv acc => acc + 2 * snd iv * D ^ (m - 1 - fst iv) * (D - 1))
             (2 * w) (combine (seq 0 m) l).

Fixpoint diffIx (s t : list nat) {struct s} : option nat :=
  match s, t with
  | [], [] => None
  | a :: s', b :: t' =>
      if Nat.eqb a b then
        match diffIx s' t' with Some j => Some (S j) | None => None end
      else Some 0
  | _, _ => None
  end.

(* (b) 尾项界：稳定值 w ≤ N−1 ⟺ 2w ≤ D−1 *)
Example tail_bound :
  forallb (fun p => Nat.leb (2 * snd p) (2 * 3 - 1 - 1)) (allSeqs 3 2) = true.
Proof. vm_compute. reflexivity. Qed.

(* (c) 前缀全同（可差稳定值）⟹ |ΔβN| ≤ D−1 *)
Definition closeCheck (D : nat)
  (pp : (list nat * nat) * (list nat * nat)) : bool :=
  let s1 := fst (fst pp) in let w1 := snd (fst pp) in
  let t1 := fst (snd pp) in let w2 := snd (snd pp) in
  match diffIx s1 t1 with
  | None =>
      andb (Nat.leb (Nat.sub (betaN D s1 w1) (betaN D t1 w2)) (D - 1))
           (Nat.leb (Nat.sub (betaN D t1 w2) (betaN D s1 w1)) (D - 1))
  | Some _ => true
  end.

(* (d) 首异位 j 且 t(j)>s(j) ⟹ βN_t − βN_s > D^{m−1−j}·(D−1) *)
Definition farCheck (D : nat)
  (pp : (list nat * nat) * (list nat * nat)) : bool :=
  let s1 := fst (fst pp) in let w1 := snd (fst pp) in
  let t1 := fst (snd pp) in let w2 := snd (snd pp) in
  match diffIx s1 t1 with
  | Some j =>
      impb (Nat.ltb (nth j s1 0) (nth j t1 0))
           (Nat.ltb (D ^ (length s1 - S j) * (D - 1))
                    (Nat.sub (betaN D t1 w2) (betaN D s1 w1)))
  | None => true
  end.

Example close_seqs_close_betas :
  forallb (closeCheck 5) (cross (allSeqs 3 2) (allSeqs 3 2)) = true.
Proof. vm_compute. reflexivity. Qed.

Example far_seqs_far_betas :
  forallb (farCheck 5) (cross (allSeqs 3 2) (allSeqs 3 2)) = true.
Proof. vm_compute. reflexivity. Qed.

Example far_seqs_far_betas2 :
  forallb (farCheck 3) (cross (allSeqs 2 2) (allSeqs 2 2)) = true.
Proof. vm_compute. reflexivity. Qed.
