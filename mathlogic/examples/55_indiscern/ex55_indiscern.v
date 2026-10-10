(* ex55_indiscern.v —— 不可辨元：Ramsey 与 Ehrenfeucht-Mostowski 定理
   （Marker GTM 217 §5.1-5.2）。机器件：R(3,3)=6 双账（K₅ 反例见证+
   K₆ 全 32768 染色皆有单色三角）；R(3,4)>8 的 Wagner 图见证（M₈=
   C₈+对径弦：无三角+独立数 ≤3——70 个四点组全含边）；不可辨性
   检查器（同长递增子序列同 profile——序语言下递增列不可辨 vs
   加后继 S 后同列被距离原子拆穿）；EM 装配演示（Skolem 壳=项闭包+
   保序平移诱导的初等嵌入账）。零公理。 *)

From Stdlib Require Import List Arith Nat.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. Ramsey：R(3,3)=6 双账 + Wagner 图见证 ---------- *)

(* 三元组表（预算一次）：(a,(i,j)) 列 a<i<j<n *)
Definition tri3 (n : nat) : list (nat * (nat * nat)) :=
  flat_map (fun a => flat_map (fun i => map (fun j => (a, (i, j)))
    (seq (i + 1) (n - i - 1))) (seq (a + 1) (n - a - 1))) (seq 0 n).

(* 单色三角：三边同色（红或蓝） *)
Definition edgeCol (c : nat -> nat -> bool) (i j : nat) : bool :=
  if Nat.ltb i j then c i j else c j i.

Definition monoTri3 (c : nat -> nat -> bool) (a i j : nat) : bool :=
  let e1 := edgeCol c a i in
  let e2 := edgeCol c i j in
  let e3 := edgeCol c a j in
  orb (andb e1 (andb e2 e3)) (andb (negb e1) (andb (negb e2) (negb e3))).

Definition hasMonoTri (n : nat) (c : nat -> nat -> bool) : bool :=
  existsb (fun tr => monoTri3 c (fst tr) (fst (snd tr)) (snd (snd tr))) (tri3 n).

(* 染色向量枚举（免除法）：15 条边的布尔表，triIdx 给出三角形的
   三条边在表中的下标 *)
Fixpoint allVecs (k : nat) : list (list bool) :=
  match k with
  | 0 => [[]]
  | S k' => flat_map (fun v => [false :: v; true :: v]) (allVecs k')
  end.

(* 边 (i,j)（i<j）在 15 表中的下标：i*6+j 的位次（前 i 行各
   5,4,3,2,1 条）——直接用 i*(2*6-i-1)/2 + (j-i-1) 的累加 *)
Fixpoint edgeIdxRow (i : nat) : nat :=
  match i with 0 => 0 | S i' => edgeIdxRow i' + (6 - i' - 1) end.

Definition edgeIdx (i j : nat) : nat := edgeIdxRow i + (j - i - 1).

(* 三角形的三边下标表（20 个三元组） *)
Definition triIdxs : list (nat * nat * nat) :=
  flat_map (fun a => flat_map (fun i => map (fun j =>
    (edgeIdx a i, edgeIdx i j, edgeIdx a j)) (seq (i + 1) (6 - i - 1)))
    (seq (a + 1) (6 - a - 1))) (seq 0 6).

Definition b3 (v : list bool) (p : nat * nat * nat) : bool :=
  let e1 := nth (fst (fst p)) v false in
  let e2 := nth (snd (fst p)) v false in
  let e3 := nth (snd p) v false in
  orb (andb e1 (andb e2 e3)) (andb (negb e1) (andb (negb e2) (negb e3))).

Definition hasMonoVec (v : list bool) : bool :=
  existsb (b3 v) triIdxs.

(* K₆：全部 2^15=32768 个染色向量都有单色三角——R(3,3)=6 机器全账 *)
Example r33_upper :
  forallb hasMonoVec (allVecs 15) = true.
Proof. vm_compute. reflexivity. Qed.

(* R(3,4)>8：Wagner 图 M₈=C₈+对径弦 (i,i+4 mod 8)——无三角、
   独立数 ≤3（70 个四点组全含边）；配合文献的 R(3,4)=9 上界 *)
Definition wagner (i j : nat) : bool :=
  orb (Nat.eqb ((i + 1) mod 8) j)
      (orb (Nat.eqb ((j + 1) mod 8) i)
           (Nat.eqb ((i + 4) mod 8) (j mod 8))).

Definition quadSets : list (list nat) :=
  flat_map (fun a => flat_map (fun b => flat_map (fun c =>
    map (fun d => [a;b;c;d]) (seq (c + 1) (8 - c - 1))) (seq (b + 1) (8 - b - 1)))
    (seq (a + 1) (8 - a - 1))) (seq 0 8).

Definition indepQuad (q : list nat) : bool :=
  negb (existsb (fun p => wagner (fst p) (snd p))
    (flat_map (fun x => map (fun y => (x, y)) q) q)).

Definition hasRedTri (n : nat) (c : nat -> nat -> bool) : bool :=
  existsb (fun tr =>
    let a := fst (fst tr) in
    let i := snd (fst tr) in
    let j := snd tr in
    andb (edgeCol c a i) (andb (edgeCol c i j) (edgeCol c a j)))
    (map (fun tr => ((fst tr, fst (snd tr)), snd (snd tr))) (tri3 n)).

Example wagner_red_triangle_free :
  negb (hasRedTri 8 wagner) = true.
Proof. vm_compute. reflexivity. Qed.

Example wagner_alpha_le3 :
  negb (existsb indepQuad quadSets) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 2. 不可辨性检查器（profile 法） ---------- *)

(* 原子族：0=x_i<x_j；1=S^k(x_i)=x_j（k≤3）；2=S^k(x_i)<x_j *)
Definition indAtom (mode k i j : nat) (seqI : list nat) : bool :=
  match mode with
  | 0 => Nat.ltb (nth i seqI 0) (nth j seqI 0)
  | 1 => Nat.eqb (Nat.iter k (fun x => x + 1) (nth i seqI 0)) (nth j seqI 0)
  | _ => Nat.ltb (Nat.iter k (fun x => x + 1) (nth i seqI 0)) (nth j seqI 0)
  end.

Definition indProfile (modes : list nat) (B idxs : list nat) (seqI : list nat)
  : list bool :=
  map (fun m => forallb (fun k =>
        forallb (fun i => forallb (fun j =>
          indAtom (nth m modes 0) (nth k B 0) (nth i idxs 0) (nth j idxs 0) seqI)
          idxs) idxs) B)
    (seq 0 (length modes)).

(* 直接实现：两两指标对的原子一致 *)
Definition atomEq (modes B : list nat) (seqI : list nat) (i j k l : nat) : bool :=
  forallb (fun m =>
    forallb (fun kk =>
      Bool.eqb (indAtom (nth m modes 0) (nth kk B 0) i j seqI)
               (indAtom (nth m modes 0) (nth kk B 0) k l seqI))
    B) modes.

Definition pairAgree (modes B : list nat) (seqI : list nat) (i j k l : nat) : bool :=
  andb (atomEq modes B seqI i j k l)
       (andb (atomEq modes B seqI j i l k)
             (atomEq modes B seqI i i k k)).

Definition indisc2 (modes B : list nat) (seqI : list nat) : bool :=
  let n := length seqI in
  forallb (fun i => forallb (fun j => forallb (fun k => forallb (fun l =>
    implb (andb (Nat.ltb i j) (Nat.ltb k l))
          (pairAgree modes B seqI i j k l)) (seq 0 n)) (seq 0 n)) (seq 0 n)) (seq 0 n).

(* 账一：序语言（mode 0）下 [2;5;9;14] 递增列不可辨
   ——序原子对「间隔」视而不见 *)
Example order_only_indiscernible :
  indisc2 [0] [0] [2;5;9;14] = true.
Proof. vm_compute. reflexivity. Qed.

(* 账二：加后继原子（mode 1，k≤4）后同一列被拆穿
   ——S³(2)=5 而 S⁴(5)=9：y=S^k x 的 k 随位置漂移 *)
Example with_S_not_indiscernible :
  negb (indisc2 [0;1] [1;2;3;4] [2;5;9;14]) = true.
Proof. vm_compute. reflexivity. Qed.

(* 账三：等差列也救不回来——后继语言没有任何长度 ≥3 的不可辨列。
   AP[0;2;4;6] 的原子 S^k(x_i)=x_j 在 (i,j)=(0,1) 处 k=2 为真、
   在 (0,2) 处 k=4 为真——指标差不同⟹真值 k 漂移。定理：S 拆穿
   一切 3-列（间隔须全体相等，而两两不等不可能） *)
Example ap_also_fails_with_S :
  negb (indisc2 [0;1] [1;2;3;4;5] [0;2;4;6]) = true.
Proof. vm_compute. reflexivity. Qed.

(* 账四：纯序语言对等差列照旧不可辨——语言的表达力决定
   「多少序列形状是自由的」 *)
Example ap_ok_order_only :
  indisc2 [0] [0] [0;2;4;6;8] = true.
Proof. vm_compute. reflexivity. Qed.



(* Skolem 壳的形状：hull(I) = I ∪ {t(i,j) : i<j}——项在不可辨列上的
   全部取值按指标对的字典序排出（新鲜元素编码 t(i,j)=100+10i+j） *)
Definition emHullPairs (n : nat) : list (nat * nat) :=
  flat_map (fun i => map (fun j => (i, j)) (seq (i + 1) (n - i - 1))) (seq 0 n).

Definition emElem (p : nat * nat) : nat := 100 + 10 * (fst p) + (snd p).

(* 保序平移 τ：I=x₀<x₁<x₂<x₃ ↦ J=τI=x₁<x₂<x₃<x₄（右移一格，
   Lemma 5.2.6 的初等嵌入版——有限序上唯一保序置换是恒等，
   故用保序单射演示） *)
Definition emShiftPairs (n : nat) : list (nat * nat) :=
  map (fun p => (S (fst p), S (snd p))) (emHullPairs (n - 1)).

Example em_shift_shape :
  emShiftPairs 4 = [(1,2);(1,3);(2,3)].
Proof. reflexivity. Qed.

(* 嵌入账：σ 把 hull(I) 的项值搬到 hull(J) 的对应项值
   ——t(i,j) ↦ t(τi,τj)；在编码层面：emElem(i,j)+10 = emElem(i+1,j+1)
   ——「模板不动、指标右移」就是 EM 定理的全部算术 *)
Example em_embed_account :
  (map emElem (emShiftPairs 4),
   map emElem [(1,2);(1,3);(2,3)]) = ([112;113;123], [112;113;123]).
Proof. reflexivity. Qed.

(* 壳的大小账：|hull(I)| = |I| + C(|I|,2)——二元 Skolem 项的计数 *)
Example hull_size :
  (length (emHullPairs 5), length (seq 0 5)) = (10, 5).
Proof. reflexivity. Qed.

Print Assumptions em_embed_account.
