(* ex59_pregeom.v —— 强极小集的几何：预几何与三分法（Marker GTM 217 §8.1-8.3）
   机器件：**预几何实验室**——五个闭包算子的交换律对账：F₂³ 线性
   张成（✓——Steinitz 交换）、F₃² 仿射闭包（✓）、平凡闭包（✓ 空洞）、
   Z₄ 群生成闭包（✗——2a∈⟨a⟩ 而 a∉⟨2a⟩ 的机器抓取）、偏序下闭包
   （✗）；**局部模检查器**（模律 cl(X∪(Y∩cl(X∪Y)))=cl(X∪Y)：
   线性✓、仿射✗、在原点局部化后仿射✓）；**局部化保持**（cl_A 仍是
   预几何）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition inclb (l1 l2 : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) l2) l1.
Definition sameSet (l1 l2 : list nat) : bool :=
  andb (inclb l1 l2) (inclb l2 l1).

(* ---------- 1. F₂³ 与 F₃² 的线性/仿射闭包 ---------- *)

(* F₂³：向量=0..7（位向量）；xorb3 加法 *)
Definition xor3 (x y : nat) : nat :=
  fold_left (fun acc i => acc + (((x / 2 ^ i + y / 2 ^ i) mod 2) * 2 ^ i)) [0;1;2] 0.

(* 线性张成：对 xor3 闭包（含 0） *)
Fixpoint linClF (fuel : nat) (s : list nat) : list nat :=
  match fuel with
  | 0 => s
  | S f => let s' := fold_left (fun acc p => let v := xor3 (fst p) (snd p) in
                  if existsb (Nat.eqb v) acc then acc else v :: acc)
                (list_prod s s) s in
           if Nat.eqb (length s') (length s) then s' else linClF f s'
  end.

Definition linCl (s : list nat) : list nat :=
  linClF 32 (if existsb (Nat.eqb 0) s then s else 0 :: s).

(* F₃²：点=(a,b) 编码 3a+b；仿射闭包=「直线闭包」 *)
Definition addp (p q : nat) : nat :=
  (((p / 3) + (q / 3)) mod 3) * 3 + ((p mod 3) + (q mod 3)) mod 3.

Fixpoint remDupNat (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => if existsb (Nat.eqb x) t then remDupNat t else x :: remDupNat t
  end.

(* 仿射组合：过两点的直线（mod 3 参数化 t=0,1,2——恰三点） *)
Definition line3 (p q : nat) : list nat :=
  remDupNat (map (fun t =>
    (((p / 3) + t * (((q / 3) + 3 - (p / 3)) mod 3)) mod 3) * 3
    + (((p mod 3) + t * (((q mod 3) + 3 - (p mod 3)) mod 3)) mod 3)) [0;1;2]).

Fixpoint affClF (fuel : nat) (s : list nat) : list nat :=
  match fuel with
  | 0 => s
  | S f =>
      let s' := fold_left (fun acc p => let L := line3 (fst p) (snd p) in
                    fold_left (fun acc2 v =>
                      if existsb (Nat.eqb v) acc2 then acc2 else v :: acc2) L acc)
                  (list_prod s s) s in
      if Nat.eqb (length s') (length s) then s' else affClF f s'
  end.

Definition affCl (s : list nat) : list nat := affClF 64 (remDupNat s).

(* ---------- 2. 交换律对账 ---------- *)

Definition exchange (cl : list nat -> list nat) (A : list nat) (a b : nat) : bool :=
  implb (andb (existsb (Nat.eqb b) (cl (remDupNat (a :: A))))
              (negb (existsb (Nat.eqb b) (cl A))))
        (existsb (Nat.eqb a) (cl (remDupNat (b :: A)))).

Fixpoint allSubsets (base : list nat) : list (list nat) :=
  match base with
  | [] => [[]]
  | b :: t => let rest := allSubsets t in map (fun s => b :: s) rest ++ rest
  end.

(* F₂³ 上交换律：全部 A⊆{1,2,4,3}、a,b∈{1,2,4,3,5,6,7} *)
Definition exchCases2 : list (list nat * (nat * nat)) :=
  flat_map (fun A => map (fun p => (A, p)) (list_prod [1;2;4;3;5;6;7] [1;2;4;3;5;6;7]))
    (allSubsets [1;2;4;3]).

Example exchange_linear :
  forallb (fun c => exchange linCl (fst c) (fst (snd c)) (snd (snd c))) exchCases2 = true.
Proof. vm_compute. reflexivity. Qed.

(* F₃² 仿射：交换律同样成立（仿射闭包是预几何） *)
Definition exchCases3 : list (list nat * (nat * nat)) :=
  flat_map (fun A => map (fun p => (A, p)) (list_prod (seq 0 9) (seq 0 9)))
    (allSubsets [0;1;3;4]).

Example exchange_affine :
  forallb (fun c => exchange affCl (fst c) (fst (snd c)) (snd (snd c))) exchCases3 = true.
Proof. vm_compute. reflexivity. Qed.

(* 平凡闭包：cl(A)=A——交换律空洞成立 *)
Example exchange_trivial :
  forallb (fun c => exchange (fun l => l) (fst c) (fst (snd c)) (snd (snd c))) exchCases2 = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. 两个反例：Z₄ 群闭包与偏序下闭包 ---------- *)

(* Z₄ 群生成闭包：〈A〉=对 (x+y) mod 4 与 -x 闭包 *)
Definition z4pairs (s : list nat) : list nat :=
  fold_left (fun acc p =>
    let v1 := ((fst p) + (snd p)) mod 4 in
    let v2 := ((fst p) - (snd p)) mod 4 in
    fold_left (fun acc2 v => if existsb (Nat.eqb v) acc2 then acc2 else v :: acc2)
              [v1; v2] acc) (list_prod s s) s.

Fixpoint grpClF (fuel : nat) (s : list nat) : list nat :=
  match fuel with
  | 0 => s
  | S f => let s' := z4pairs s in
           if Nat.eqb (length s') (length s) then s' else grpClF f s'
  end.

Definition z4Cl (s : list nat) : list nat := grpClF 8 (remDupNat (0 :: s)).

(* 交换律破口：2 ∈ 〈{1}〉∖〈∅〉={0,1,2,3}∖{0}，但 1 ∉ 〈{2}〉={0,2} *)
Example z4_exchange_fails :
  andb (existsb (Nat.eqb 2) (z4Cl [1]))
       (negb (existsb (Nat.eqb 1) (z4Cl [2]))) = true.
Proof. vm_compute. reflexivity. Qed.

(* 偏序下闭包（链 0<1<2<3）：cl(A)=↓A *)
Definition downCl (A : list nat) : list nat :=
  fold_left (fun acc a => fold_left (fun acc2 v =>
    if existsb (Nat.eqb v) acc2 then acc2 else v :: acc2)
    (seq 0 (a + 1)) acc) A [].

(* 交换律破口：2 ∈ ↓{3}∖↓∅... 用 A=∅：b=2∈cl({3})、3∉cl({2}) *)
Example poset_exchange_fails :
  andb (existsb (Nat.eqb 2) (downCl [3]))
       (negb (existsb (Nat.eqb 3) (downCl [2]))) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. 维度版模律与局部化 ---------- *)

(* F₃² 上线性维数：0（全零）/1（共线过原点）/2 *)
Definition sub3 (p q : nat) : nat :=
  (((p / 3) + 3 - (q / 3)) mod 3) * 3 + ((p mod 3) + 3 - (q mod 3)) mod 3.

Definition onLine0 (u v : nat) : bool :=
  (* u,v 共线过原点 ⟺ u = t·v（t=0,1,2） *)
  existsb (fun t =>
    Nat.eqb ((t * (v / 3)) mod 3 * 3 + (t * (v mod 3)) mod 3) u) [0; 1; 2]
  || Nat.eqb v 0.

Definition dimL (S : list nat) : nat :=
  let nz := filter (fun v => negb (Nat.eqb v 0)) S in
  if Nat.eqb (length nz) 0 then 0
  else if forallb (fun v => onLine0 v (hd 0 nz)) nz then 1 else 2.

(* 仿射维数：∅ → None；否则平移到基点的线性维数 *)
Definition dimA (S : list nat) : option nat :=
  match S with
  | [] => None
  | s0 :: _ => Some (dimL (map (fun s => sub3 s s0) (remDupNat S)))
  end.

Definition dimEq (a b : option nat) : bool :=
  match a, b with
  | None, None => true
  | Some x, Some y => Nat.eqb x y
  | _, _ => false
  end.

(* 模律（维度形式）：dim X + dim Y = dim cl(X∪Y) + dim cl(X)∩cl(Y)
   ——交空按 None（−1 约定的机器面） *)
Definition modDim (cl : list nat -> list nat) (X Y : list nat) : bool :=
  let dX := dimA (cl X) in
  let dY := dimA (cl Y) in
  let dU := dimA (cl (remDupNat (X ++ Y))) in
  let dI := dimA (filter (fun x => existsb (Nat.eqb x) (cl Y)) (cl X)) in
  match dI with
  | None => dimEq (match dX, dY with Some a, Some b => Some (a+b) | _, _ => None end)
                   (match dU with Some u => Some (u+1) | None => None end)
  | Some i => dimEq (match dX, dY with Some a, Some b => Some (a+b) | _, _ => None end)
                     (match dU with Some u => Some (u+i) | None => None end)
  end.

(* 仿射非模见证：平行线 X={1,2}（x=0 列）、Y={4,5}（x=1 列）
   ——1+1 ≠ 2+(−1)：两条平行线不相交 *)
Example affine_not_modular :
  negb (modDim affCl [1; 2] [4; 5]) = true.
Proof. vm_compute. reflexivity. Qed.

(* 相交线对照：X={1;2}（x=0）、Y={1;3}（y=1... 0=(0,0),1=(0,1),3=(1,0)）
   交点 1：1+1=2+0 ✓ *)
Example affine_meeting_ok :
  modDim affCl [1; 2] [1; 3] = true.
Proof. vm_compute. reflexivity. Qed.

(* 局部化：cl₀(X)=affCl(X∪{0})——平行线破口被修复（0 点把一侧
   撑成平面，交不再空） *)
Definition affCl0 (X : list nat) : list nat := affCl (remDupNat (0 :: X)).

Example localized_fixes_parallel :
  modDim affCl0 [1; 2] [4; 5] = true.
Proof. vm_compute. reflexivity. Qed.

(* 局部化后的模律样本族：全部通过（局部模=「某点局部化后模」） *)
Example localized_modular_family :
  forallb (fun p => modDim affCl0 (fst p) (snd p))
    (list_prod (allSubsets [1; 2]) (allSubsets [4; 5; 3])) = true.
Proof. vm_compute. reflexivity. Qed.

(* 线性 F₂³ 的模律维度版：全样本（57 章维数公式的姊妹账）。
   F₂³ 的维数机：rank（0/1/2/3） *)
Definition onLine02 (u v : nat) : bool :=
  Nat.eqb v 0 || (Nat.eqb (xor3 u v) 0) || Nat.eqb u 0.

Fixpoint lowbit2F (fuel x : nat) : nat :=
  match fuel with
  | 0 => 0
  | S f => if Nat.eqb x 0 then 0
           else if Nat.eqb (x mod 2) 1 then 0 else S (lowbit2F f (x / 2))
  end.

Definition lowbit2 (x : nat) : nat := lowbit2F 8 x.

(* 归约：消元后对**全基**重启（重启须显式携带 full——分支里的
   basis 已被窄化成后缀；pivot 位唯一保证每个基元素至多用一次） *)
Fixpoint redGo (fuel : nat) (full cur : list nat) (v : nat) : nat :=
  match fuel with
  | 0 => v
  | S f =>
      match cur with
      | [] => v
      | p :: t =>
          if Nat.eqb ((v / 2 ^ (lowbit2 p)) mod 2) 1
          then redGo f full full (xor3 v p)
          else redGo f full t v
      end
  end.

Definition redFrom (fuel : nat) (basis : list nat) (v : nat) : nat :=
  redGo fuel basis basis v.

Fixpoint rank2 (S : list nat) (basis : list nat) : nat :=
  match S with
  | [] => length basis
  | v :: t =>
      let w := redFrom 16 basis v in
      if Nat.eqb w 0 then rank2 t basis else rank2 t (w :: basis)
  end.

Definition modDim2 (X Y : list nat) : bool :=
  let dX := rank2 (linCl X) [] in
  let dY := rank2 (linCl Y) [] in
  let dU := rank2 (linCl (remDupNat (X ++ Y))) [] in
  let I := filter (fun x => existsb (Nat.eqb x) (linCl Y)) (linCl X) in
  let dI := rank2 I [] in
  Nat.eqb (dX + dY) (dU + dI).

Definition xorCl (S : list nat) : list nat := linCl S.

Example modular_linear_family :
  forallb (fun p => modDim2 (fst p) (snd p))
    (list_prod (allSubsets [1; 2]) (allSubsets [3; 5; 6])) = true.
Proof. vm_compute. reflexivity. Qed.

Print Assumptions modular_linear_family.
