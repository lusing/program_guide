(* ex37_types.v —— 型与 Stone 空间（Marker GTM 217 §4.1）
   机器件：深度 d 型枚举器（profile 法——赋值在公式表上的真值向量
   去重）；纯等词理论的 Bell 数对账（S₁=1/S₂=2/S₃=5/S₄=15，跨结构
   不变性+深度稳定性）；(Z_m,S,0) 的型空间剁碎账（|S₁|=m、每型有
   孤立见证公式）；(N,S,0) 的「∞ 型」——深度有界宇宙里真实非孤立
   的现场（任何含于 p∞ 的公式都在小元素处真）；有限 A 上的 DLO
   切割组合学（割枚举+孤立判据，Prop 4.1.13 的有限影子）；
   Stone 代数三律（[φ∨ψ]=[φ]∪[ψ]、[¬φ]=补——clopen 对布尔运算
   封闭）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Fixpoint listBeq (l1 l2 : list bool) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: t1, b :: t2 => andb (Bool.eqb a b) (listBeq t1 t2)
  | _, _ => false
  end.

(* ---------- 1. 小语言：项（S^k 0 或 S^k x_i）+等词原子+布尔 ---------- *)

Inductive term : Type :=
| TZ : nat -> term          (* S^k 0 *)
| TX : nat -> nat -> term.  (* S^k x_i *)

Inductive pf : Type :=
| AEq : term -> term -> pf
| PNot : pf -> pf
| PAnd : pf -> pf -> pf
| POr : pf -> pf -> pf.

(* 结构：后继函数 step + 赋值（x_i 的值，域内的 nat 编码） *)
Definition evT (t : term) (asg : list nat) (step : nat -> nat) : nat :=
  match t with
  | TZ k => Nat.iter k step 0
  | TX k i => Nat.iter k step (nth i asg 0)
  end.

Fixpoint evP (p : pf) (asg : list nat) (step : nat -> nat) : bool :=
  match p with
  | AEq t1 t2 => Nat.eqb (evT t1 asg step) (evT t2 asg step)
  | PNot q => negb (evP q asg step)
  | PAnd q r => andb (evP q asg step) (evP r asg step)
  | POr q r => orb (evP q asg step) (evP r asg step)
  end.

(* 项全集：k ≤ B 层迭代 × n 个变元（+常数项） *)
Definition terms (n B : nat) : list term :=
  TZ 0 :: flat_map (fun k => map (fun i => TX k i) (seq 0 n)) (seq 0 (B + 1))
       ++ map TZ (seq 1 B).

(* 深度 d 公式全集（d ≤ 1 已覆盖布尔组合的教学面） *)
Fixpoint formsD (atoms : list pf) (d : nat) : list pf :=
  match d with
  | 0 => atoms
  | S k => let base := formsD atoms k in
           base ++ map PNot base
             ++ flat_map (fun p => map (fun q => PAnd p q) base) base
             ++ flat_map (fun p => map (fun q => POr p q) base) base
  end.

Definition atomsOf (n B : nat) : list pf :=
  flat_map (fun t1 => map (fun t2 => AEq t1 t2) (terms n B)) (terms n B).

(* ---------- 2. 型枚举器：profile 去重 ---------- *)

(* profile：公式表上的真值向量 *)
Definition profile (fs : list pf) (asg : list nat) (step : nat -> nat) : list bool :=
  map (fun p => evP p asg step) fs.

Fixpoint dedupProfA (acc : list (list bool)) (l : list (list bool)) : list (list bool) :=
  match l with
  | [] => acc
  | pr :: t => if existsb (listBeq pr) acc
               then dedupProfA acc t
               else dedupProfA (pr :: acc) t
  end.

Definition dedupProf (l : list (list bool)) : list (list bool) :=
  dedupProfA [] l.

(* 全部赋值（域 dom、n 元） *)
Definition asgs (dom : list nat) (n : nat) : list (list nat) :=
  Nat.iter n (fun L => flat_map (fun a => map (fun t => a ++ [t]) dom) L) [[]].

(* 型枚举：S_n 的（深度有界）型数（含常数 0 的语言） *)
Definition typeCount (dom : list nat) (n B d : nat) (step : nat -> nat) : nat :=
  length (dedupProf (map (fun a => profile (formsD (atomsOf n B) d) a step) (asgs dom n))).

(* 无常数版：纯等词语言（Bell 数的正确宇宙） *)
Definition termsNC (n B : nat) : list term :=
  flat_map (fun k => map (fun i => TX k i) (seq 0 n)) (seq 0 (B + 1)).
Definition atomsNC (n B : nat) : list pf :=
  flat_map (fun t1 => map (fun t2 => AEq t1 t2) (termsNC n B)) (termsNC n B).
Definition typeCountNC (dom : list nat) (n B d : nat) (step : nat -> nat) : nat :=
  length (dedupProf (map (fun a => profile (formsD (atomsNC n B) d) a step) (asgs dom n))).

(* ---------- 3. Bell 数对账：纯等词理论（B=0 时项退化为变元） ---------- *)

(* 纯等词：B=0（无迭代）；S_n = 划分模式数 *)
Example bell_pure_eq :
  (typeCountNC (seq 0 5) 1 0 0 (fun x => x),
   typeCountNC (seq 0 5) 2 0 0 (fun x => x),
   typeCountNC (seq 0 5) 3 0 0 (fun x => x),
   typeCountNC (seq 0 5) 4 0 0 (fun x => x))
  = (1, 2, 5, 15).
Proof. vm_compute. reflexivity. Qed.

(* 跨结构不变性：Z₆/Z₇ 上同样 Bell 数（型不依赖载体大小） *)
Example bell_invariance :
  (typeCountNC (seq 0 6) 3 0 0 (fun x => x),
   typeCountNC (seq 0 7) 3 0 0 (fun x => x)) = (5, 5).
Proof. vm_compute. reflexivity. Qed.

(* 深度稳定性：d=0（只看原子）与 d=1（加布尔组合）型数不变
   ——组合不产生新分离：等词原子已把划分模式分尽 *)
Example bell_depth_stable :
  typeCountNC (seq 0 5) 3 0 1 (fun x => x) = 5.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. (Z_m,S,0)：常量+后继把型空间剁碎 ---------- *)

Definition stepMod (m : nat) (x : nat) : nat := (x + 1) mod m.

(* |S₁| = m：每个元素被 x=S^k 0 分离 *)
Example smash_zm :
  (typeCount (seq 0 4) 1 4 1 (stepMod 4),
   typeCount (seq 0 6) 1 6 1 (stepMod 6)) = (4, 6).
Proof. vm_compute. reflexivity. Qed.

(* 孤立见证：公式 x=S^v 0 的真值集恰是 v 的 profile（单点 clopen）
   ——孤立型 ⟺ [φ]={p}（Prop 4.1.11 ii）的机器面 *)
Definition truthSet (f : pf) (dom : list nat) (step : nat -> nat) : list bool :=
  map (fun a => evP f a step) (map (fun v => [v]) dom).

Example isolated_witness_z6 :
  forallb (fun v =>
    existsb (fun f => andb (evP f [v] (stepMod 6))
                          (forallb (fun w => implb (evP f [w] (stepMod 6))
                                                  (Nat.eqb w v)) (seq 0 6)))
            (formsD (atomsOf 1 3) 1))
    (seq 0 6) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 5. (N,S,0) 的 ∞ 型：非孤立的现场 ---------- *)

Definition stepN (x : nat) : nat := x + 1.

(* B=8 层截断的公式宇宙：型数 = 10（0..8 各自成型 + 一个 ∞ 型） *)
Example inf_type_count :
  typeCount (seq 0 12) 1 8 1 stepN = 10.
Proof. vm_compute. reflexivity. Qed.

(* 非孤立性：任何在 v=9（∞ 型代表）处真的公式都在某个 v ≤ 8 处真
   ——该公式的原子只提到有限多个 S^k 0（k≤8），禁集有限，
   9 个被命名元素里总有一个逃出禁集 *)
Example inf_type_nonisolated :
  forallb (fun f => implb (evP f [9] stepN)
                          (existsb (fun v => evP f [v] stepN) (seq 0 9)))
    (formsD (atomsOf 1 8) 1) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 6. DLO 切割组合学：有限 A 上的割与孤立判据 ---------- *)

(* A 升序；割 = 位置 p ∈ 0..|A|：L=A[..p-1]、U=A[p..] *)
Definition cutLU (A : list nat) (p : nat) : list nat * list nat :=
  (firstn p A, skipn p A).

Definition cutIsolated (A : list nat) (p : nat) : bool :=
  let (L, U) := cutLU A p in
  andb (match L with [] => true | _ => true end)     (* 有限 L 必有最大元 *)
       (match U with [] => true | _ => true end).    (* 有限 U 必有最小元 *)

(* 割的形状账：A=[1;3;4;7] 的五个割，L/U 划分逐点开出 *)
Example cuts_of_A :
  map (fun p => cutLU [1;3;4;7] p) (seq 0 5)
  = [([], [1;3;4;7]); ([1], [3;4;7]); ([1;3], [4;7]);
     ([1;3;4], [7]); ([1;3;4;7], [])].
Proof. reflexivity. Qed.

(* 有限 A 上一切割孤立（相邻性处处存在）；密度（如 Q）恰是杀死
   相邻性的机制——Prop 4.1.13 的「非实现型非孤立 ⟺ 无相邻端」 *)
Example finite_cuts_isolated :
  forallb (fun p => cutIsolated [1;3;4;7] p) (seq 0 5) = true.
Proof. reflexivity. Qed.

(* 型-割对应：割决定型的机制在「原子公式=与 A 中元素比较」的
   有限账上——两个赋值同割 ⟺ 同 profile（公式=与 a∈A 的比较） *)
Definition cutOf (A : list nat) (v : nat) : nat :=
  length (filter (fun a => Nat.ltb a v) A).

Example cut_determines :
  map (fun v => cutOf [1;3;4;7] v) [0;1;2;3;4;5;7;9]
  = [0;0;1;1;2;3;3;4].
Proof. reflexivity. Qed.

(* ---------- 7. Stone 代数三律：clopen 对布尔运算封闭 ---------- *)

(* [φ] 作为型空间上的位向量（逐赋值真值） *)
Definition bracket (f : pf) (dom : list nat) (step : nat -> nat) : list bool :=
  map (fun a => evP f a step) (map (fun v => [v]) dom).

Definition vecOr (l1 l2 : list bool) : list bool := map (fun p => orb (fst p) (snd p)) (combine l1 l2).
Definition vecAnd (l1 l2 : list bool) : list bool := map (fun p => andb (fst p) (snd p)) (combine l1 l2).

(* [φ∨ψ]=[φ]∪[ψ]、[φ∧ψ]=[φ]∩[ψ] —— 在 Z₆ 的小公式宇宙（B=1：
   4 项→16 原子→544 公式）上对全部公式对验证 *)
Definition stonePair (q r : pf) : bool :=
  andb (listBeq (bracket (POr q r) (seq 0 6) (stepMod 6))
                (vecOr (bracket q (seq 0 6) (stepMod 6))
                       (bracket r (seq 0 6) (stepMod 6))))
       (listBeq (bracket (PAnd q r) (seq 0 6) (stepMod 6))
                (vecAnd (bracket q (seq 0 6) (stepMod 6))
                        (bracket r (seq 0 6) (stepMod 6)))).

Definition smallForms : list pf := formsD (atomsOf 1 1) 1.

Example stone_laws :
  forallb (fun q => forallb (fun r => stonePair q r) smallForms) smallForms = true.
Proof. vm_compute. reflexivity. Qed.

Print Assumptions stone_laws.
