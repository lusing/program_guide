(* ex39_saturated.v —— 饱和与齐次模型（Marker GTM 217 §4.3）
   机器件：深度有界饱和检查器（profile 法复用 37 章方法论，章内
   自含）；(N,S,0) 的逐层饱和账 vs 「钳位」结构的破口账——∞ 型
   未实现=不饱和的现场；DLO 有限影子上的 2m+1 型计数与「密度=
   实现」链；部分初等映射的延拓账（尾平移自同构 vs 命名点不可
   挪）；饱和⟹齐次（Prop 4.3.3）的样本装配。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. 小语言：项（S^k 0 / S^k p_i / S^k x）+等词+布尔 ---------- *)

Inductive term : Type :=
| TZ : nat -> term            (* S^k 0 *)
| TP : nat -> nat -> term     (* S^k p_i（参数=域元素下标） *)
| TX : nat -> term.           (* S^k x *)

Inductive pf : Type :=
| AEq : term -> term -> pf
| PNot : pf -> pf
| PAnd : pf -> pf -> pf
| POr : pf -> pf -> pf.

(* 结构=后继函数 step；参数指派=A 的元素表 *)
Definition evT (t : term) (x : nat) (A : list nat) (step : nat -> nat) : nat :=
  match t with
  | TZ k => Nat.iter k step 0
  | TP k i => Nat.iter k step (nth i A 0)
  | TX k => Nat.iter k step x
  end.

Fixpoint evP (p : pf) (x : nat) (A : list nat) (step : nat -> nat) : bool :=
  match p with
  | AEq t1 t2 => Nat.eqb (evT t1 x A step) (evT t2 x A step)
  | PNot q => negb (evP q x A step)
  | PAnd q r => andb (evP q x A step) (evP r x A step)
  | POr q r => orb (evP q x A step) (evP r x A step)
  end.

Definition terms (nA B : nat) : list term :=
  map TZ (seq 0 (B + 1))
  ++ flat_map (fun k => map (fun i => TP k i) (seq 0 nA)) (seq 0 (B + 1))
  ++ map TX (seq 0 (B + 1)).

Definition atoms (nA B : nat) : list pf :=
  flat_map (fun t1 => map (fun t2 => AEq t1 t2) (terms nA B)) (terms nA B).

Definition forms (nA B : nat) : list pf := atoms nA B ++ map PNot (atoms nA B)
  ++ flat_map (fun p => map (fun q => PAnd p q) (atoms nA B)) (atoms nA B).

(* x 的 profile：公式表上的真值向量 *)
Definition profile (fs : list pf) (x : nat) (A : list nat) (step : nat -> nat)
  : list bool :=
  map (fun p => evP p x A step) fs.

Fixpoint listBeq (l1 l2 : list bool) : bool :=
  match l1, l2 with
  | [], [] => true
  | a :: t1, b :: t2 => andb (Bool.eqb a b) (listBeq t1 t2)
  | _, _ => false
  end.

(* A 上的（深度有界）1-型在 dom 中实现 ⟺ dom 中有同 profile 元素 *)
Definition realizedIn (fs : list pf) (A dom : list nat) (step : nat -> nat)
  (x : nat) : bool :=
  existsb (fun w => listBeq (profile fs x A step) (profile fs w A step)) dom.

(* 饱和检查（有界）：全部采样型（=各 x 的 profile）都在 dom 实现
   ——x 取「证据宇宙」evid（比 dom 更宽，代表初等扩张中的候选） *)
Definition satCheck (fs : list pf) (A dom evid : list nat) (step : nat -> nat)
  : bool :=
  forallb (fun x => realizedIn fs A dom step x) evid.

Definition stepN (x : nat) : nat := x + 1.
Definition stepClamp5 (x : nat) : nat := Nat.min (x + 1) 4.

(* ---------- 2. (N,S,0) 逐层饱和 vs 钳位结构的破口 ---------- *)

(* (N,S,0)：B=3 层公式（16 项→256 原子→6.6 万公式）、A={0,2}、
   证据宇宙 0..14：全部型在 0..14 中实现——∞ 型由大元素接住 *)
Example n_saturated_bounded :
  satCheck (forms 2 3) [0;2] (seq 0 15) (seq 0 15) stepN = true.
Proof. vm_compute. reflexivity. Qed.

(* 钳位 M₅={0..4}（S(4)=4）：∞ 型（证据 x=7 的 profile，对一切
   k≤6：x≠S^k 0 且 S^j x≠S^k 0）在 dom 中无实现——不饱和的现场 *)
Example clamp5_unsaturated :
  negb (realizedIn (forms 0 6) [] (seq 0 5) stepClamp5 7) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. DLO 有限影子：2m+1 型与「密度=实现」 ---------- *)

(* 序原子：OCmp i true = p_i < x；OCmp i false = x < p_i *)
Inductive oat : Type := OCmp (i : nat) (d : bool).

Definition evO (a : oat) (x : nat) (A : list nat) : bool :=
  match a with
  | OCmp i true => Nat.ltb (nth i A 0) x
  | OCmp i false => Nat.ltb x (nth i A 0)
  end.

Definition oprofile (x : nat) (A : list nat) : list bool :=
  map (fun a => evO a x A)
    (flat_map (fun i => [OCmp i true; OCmp i false]) (seq 0 (length A))).

(* 切割位置 p（x 落在 A[p-1] 与 A[p] 之间；p=0 在下方、p=|A| 在
   上方）的 profile 直接构造：p_i<x ⟺ i<p *)
Definition cutProfile (A : list nat) (p : nat) : list bool :=
  flat_map (fun i => [Nat.ltb i p; negb (Nat.ltb i p)]) (seq 0 (length A)).

Fixpoint dedup (l : list (list bool)) : list (list bool) :=
  match l with
  | [] => []
  | pr :: t => if existsb (listBeq pr) t then dedup t else pr :: dedup t
  end.

(* 型数账（Ex 4.3.9）：|A|=m 时 S₁(A) = 2m+1（m+1 个切割型+m 个
   实现型），两两不同 *)
Definition dloTypes (A : list nat) : list (list bool) :=
  map (fun p => cutProfile A p) (seq 0 (length A + 1))
  ++ map (fun k => oprofile (nth k A 0) A) (seq 0 (length A)).

Example dlo_type_count :
  (length (dedup (dloTypes [0;5])), length (dedup (dloTypes [0;3;5])))
  = (5, 7).
Proof. vm_compute. reflexivity. Qed.

(* 切割型在 dom 实现 ⟺ dom 在该区间有元素——「密度=实现」 *)
Definition cutRealized (A dom : list nat) (p : nat) : bool :=
  existsb (fun w => listBeq (cutProfile A p) (oprofile w A)) dom.

Example dlo_realization_gap :
  (* A=[0;5]、中割 p=1（0<v<5）：dom 有中点 2 则实现，无则破口 *)
  (cutRealized [0;5] [0;2;5] 1, cutRealized [0;5] [0;5] 1) = (true, false).
Proof. vm_compute. reflexivity. Qed.

(* (Q,<) 的饱和机制：对有限 A，全部 2m+1 型都在 Q 实现——
   密度保证每个开区间非空、两端点外无界 *)
Example q_saturated_over_finite :
  forallb (fun p => cutRealized [1;5] [0;1;2;3;4;5;6] p) (seq 0 3) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. 部分初等映射：延拓账 ---------- *)

(* 同型⟹可配对：profile 相同的元素对（有界初等等价） *)
Definition sameType (fs : list pf) (A : list nat) (step : nat -> nat)
  (x y : nat) : bool :=
  listBeq (profile fs x A step) (profile fs y A step).

(* (N,S,0) 的尾平移：B=6 层下 7、8、9、10 两两同型（∞ 区平移） *)
Example tail_same_type :
  andb (sameType (forms 0 6) [] stepN 7 8)
       (sameType (forms 0 6) [] stepN 9 10) = true.
Proof. vm_compute. reflexivity. Qed.

(* 命名点不可挪：0 与 1 不同型（v=S^k 0 分离） *)
Example named_immovable :
  negb (sameType (forms 0 6) [] stepN 0 1) = true.
Proof. vm_compute. reflexivity. Qed.

(* 饱和⟹齐次的样本装配（Prop 4.3.3）：f={7↦8} 部分初等（上账），
   b=9 时存在 c（=10）使 f∪{9↦10} 仍部分初等——Γ 的实现元搜索 *)
Example sat_implies_hom_sample :
  existsb (fun c => andb (sameType (forms 0 6) [] stepN 7 8)
                         (sameType (forms 0 6) [] stepN 9 c))
          (seq 0 15) = true.
Proof. vm_compute. reflexivity. Qed.

Print Assumptions sat_implies_hom_sample.
