(* ex54_countmodels.v —— 可数模型数：Ryll-Nardzewski 定理（Marker GTM 217 §4.4）
   机器件：型空间计数器（RN 条件 iii 的三例对账——纯等词 Bell 数
   有限、DLO 弱序数有限、(N,S,0) 逐层增长=无限）；Ehrenfeucht 三
   模型实验室（DLO+常量链的三个有限影子被两句话子分离+同构搜索
   失败）；「无限型空间⟹非 ℵ₀-范畴」的逐层证据。零公理。 *)

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

(* ---------- 1. 型空间计数器（profile 法，章内自含） ---------- *)

(* 语言 A：纯等词（eqb）/带后继（step）/带序（ltb）——统一成
   原子求值器 *)
Definition atomEv (mode : nat) (i j : nat) (asg : list nat) (step : nat -> nat) : bool :=
  match mode with
  | 0 => Nat.eqb (nth i asg 0) (nth j asg 0)          (* x_i = x_j *)
  | 1 => Nat.eqb (nth i asg 0) j                                (* x_i = c_j *)
  | _ => Nat.ltb (nth i asg 0) (nth j asg 0)           (* x_i < x_j *)
  end.

Definition atomsOf (mode n : nat) : list (nat * nat) :=
  match mode with
  | 1 => flat_map (fun i => map (fun j => (i, j)) (seq 0 9)) (seq 0 n)
  | _ => flat_map (fun i => map (fun j => (i, j)) (seq 0 n)) (seq 0 n)
  end.

Definition profileOf (mode n : nat) (asg : list nat) (step : nat -> nat) : list bool :=
  map (fun a => atomEv mode (fst a) (snd a) asg step) (atomsOf mode n).

Fixpoint dedupA (acc : list (list bool)) (l : list (list bool)) : list (list bool) :=
  match l with
  | [] => acc
  | pr :: t => if existsb (listBeq pr) acc then dedupA acc t else dedupA (pr :: acc) t
  end.

Definition typeCount (mode n : nat) (dom : list nat) (step : nat -> nat) : nat :=
  length (dedupA []
    (map (fun a => profileOf mode n a step)
         (Nat.iter n (fun L => flat_map (fun b => map (fun v => b ++ [v]) dom) L) [[]]))).

Definition id1 (x : nat) : nat := x.
Definition stepN (x : nat) : nat := x + 1.

(* RN 条件（iii）三例：每个 n 的 S_n(T) 有限
   例一：纯等词——|S_n| = Bell(n)：1/2/5/15（51 章复账） *)
Example rn_pure_eq :
  (typeCount 0 1 (seq 0 5) id1, typeCount 0 2 (seq 0 5) id1,
   typeCount 0 3 (seq 0 5) id1, typeCount 0 4 (seq 0 5) id1) = (1, 2, 5, 15).
Proof. vm_compute. reflexivity. Qed.

(* 例二：DLO 无参数——|S_n| = 弱序数（有序分拆）：1/3/13 *)
Example rn_dlo :
  (typeCount 2 1 (seq 0 5) id1, typeCount 2 2 (seq 0 5) id1,
   typeCount 2 3 (seq 0 5) id1) = (1, 3, 13).
Proof. vm_compute. reflexivity. Qed.

(* 例三：(N,S,0)——|S_1| 随证据宇宙增长：8 元宇宙已 ≥ 6
   （原子 x=c_j（j≤8）把 0..5 各自成型）——型空间无限，非 ℵ₀-范畴 *)
Example rn_N_infinite :
  Nat.leb 6 (typeCount 1 1 (seq 0 8) stepN) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. Ehrenfeucht 三模型实验室 ---------- *)

(* 语言 L={<, c₀,c₁,c₂}；结构=（域表，常量表） *)
Definition L1 : list nat * list nat := ([0;1;2;3], [0;1;2]).  (* 有上确界、其上无点 *)
Definition L2 : list nat * list nat := ([0;1;2;3;4], [0;1;2]). (* 有上确界、其上有点 *)
Definition L3 : list nat * list nat := ([0;1;2;3], [1;2;3]).  (* 链上无界（链在顶部） *)

(* 句子求值：σ_sup=∃x(c₂<x ∧ 无 y>x)；σ_above=∃x∃y(c₂<x ∧ x<y) *)
Definition lt (M : list nat * list nat) (a b : nat) : bool :=
  existsb (fun p => andb (Nat.eqb (fst p) a) (Nat.eqb (snd p) b))
    (flat_map (fun u => map (fun v => (u, v)) (fst M)) (fst M)).

(* 直接用域上 nat 序（有限影子即线性序） *)
Definition ltM (M : list nat * list nat) (a b : nat) : bool :=
  andb (existsb (Nat.eqb a) (fst M)) (Nat.ltb a b).

Definition sigmaSup (M : list nat * list nat) : bool :=
  existsb (fun x => andb (ltM M (nth 2 (snd M) 0) x)
                         (negb (existsb (fun y => ltM M x y) (fst M))))
    (fst M).

Definition sigmaAbove (M : list nat * list nat) : bool :=
  existsb (fun x => existsb (fun y => andb (ltM M (nth 2 (snd M) 0) x) (ltM M x y))
                            (fst M)) (fst M).

(* 分离账：L1=(T,F)、L2=(T,T)、L3=(F,F)——两句话子分出三个模型 *)
Example ehrenfeucht_separation :
  (sigmaSup L1, sigmaAbove L1, sigmaSup L2, sigmaAbove L2,
   sigmaSup L3, sigmaAbove L3) = (true, false, true, true, false, false).
Proof. vm_compute. reflexivity. Qed.

(* 同构搜索失败：L1 与 L3 同为 4 元，但「保常量+保序」的双射不存在
   ——同构必须逐点固定命名常量并保 < *)
Definition isoPres (M N : list nat * list nat) (f : list nat) : bool :=
  andb (forallb (fun i => Nat.eqb (nth i (snd M) 0) (nth (nth i f 0) (snd N) 0))
                (seq 0 3))
       (forallb (fun u => forallb (fun v =>
          Bool.eqb (ltM M u v) (ltM N (nth u f 0) (nth v f 0))) (fst M)) (fst M)).

Definition perms4 : list (list nat) :=
  flat_map (fun a => flat_map (fun b => flat_map (fun c =>
    map (fun d => [a;b;c;d]) [0;1;2;3]) [0;1;2;3]) [0;1;2;3]) [0;1;2;3].

Example no_iso_L1_L3 :
  negb (existsb (fun f => isoPres L1 L3 f) perms4) = true.
Proof. vm_compute. reflexivity. Qed.

(* 叙事账：真正的 Ehrenfeucht 例用无穷常量链 c₀<c₁<…——可数模型
   按链的上确界切割类型三分（无上界/上确界实现且其上有物/上确界
   实现且其上无物）。有限影子承载的是「切割类型」不变量；
   Thm 4.4.6（I(T,ℵ₀)≠2）与 Vaught 猜想见 docs。 *)

Print Assumptions no_iso_L1_L3.
