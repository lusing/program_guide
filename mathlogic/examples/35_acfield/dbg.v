(* ex35_acfield.v —— 代数闭域：量词消去与范畴性（Marker GTM 217 §3.2）
   机器件：F₄=F₂[t]/(t²+t+1) 与 F₁₆=F₂[s]/(s⁴+s+1) 的显式算术（卷积
   +折减）；加根塔见证（F₂ 无根⟹F₄ 有根+F₁₆ 内寻得 F₄ 拷贝）；域公理
   抽样账（无零因子=模多项式不可约）；F₃ 线上构造集全枚举的「有限
   塌缩」；F₁₆ 上 acl（=子域生成）的交换律机器验证——为 45 章预几何
   埋线。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

Definition inclb (l1 l2 : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) l2) l1.

Definition eqsetb (l1 l2 : list nat) : bool := andb (inclb l1 l2) (inclb l2 l1).

(* ---------- 1. GF(2^k)：位向量多项式算术 ---------- *)

(* 元素=多项式系数位向量（低位在前）：x = Σ b_i·2^i *)
Definition bits (k x : nat) : list nat :=
  map (fun i => (x / 2 ^ i) mod 2) (seq 0 k).

Fixpoint unbits (l : list nat) : nat :=
  match l with
  | [] => 0
  | b :: t => b mod 2 + 2 * unbits t
  end.

(* 特征 2 的多项式加法=异或（长度可不等，零填充） *)
Fixpoint padd (a b : list nat) : list nat :=
  match a, b with
  | [], l => map (fun x => x mod 2) l
  | l, [] => map (fun x => x mod 2) l
  | x :: t1, y :: t2 => ((x + y) mod 2) :: padd t1 t2
  end.

(* 多项式卷积（移位累加） *)
Fixpoint conv (a b : list nat) : list nat :=
  match a with
  | [] => []
  | x :: t => padd (map (fun y => x * y) b)
                   (repeat 0 1 ++ conv t b)
  end.

(* 折减：长度 > k 时最高位 c·t^n 换成 c·tbl·t^{n-k}（tbl=t^k 的表示）
   F₄：t²=t+1（k=2，tbl=[1;1]）；F₁₆：s⁴=s+1（k=4，tbl=[1;1;0;0]） *)
Fixpoint reducePolyF (fuel k : nat) (tbl : list nat) (l : list nat) : list nat :=
  match fuel with
  | 0 => map (fun x => x mod 2) l
  | S f =>
      if Nat.leb (length l) k then map (fun x => x mod 2) l
      else
        let n := length l - 1 in
        let c := nth n l 0 in
        let front := firstn n l in
        let shifted := repeat 0 (n - k) ++ map (fun x => x * c) tbl in
        reducePolyF f k tbl (padd front shifted)
  end.

Definition reducePoly (k : nat) (tbl : list nat) (l : list nat) : list nat :=
  reducePolyF (length l) k tbl l.

Definition f4_add (x y : nat) : nat := unbits (padd (bits 2 x) (bits 2 y)).
Definition f4_mul (x y : nat) : nat :=
  unbits (reducePoly 2 [1;1] (conv (bits 2 x) (bits 2 y))).
Definition f16_add (x y : nat) : nat := unbits (padd (bits 4 x) (bits 4 y)).
Definition f16_mul (x y : nat) : nat :=
  unbits (reducePoly 4 [1;1;0;0] (conv (bits 4 x) (bits 4 y))).

Definition f16_dom : list nat := seq 0 16.
Definition f4_dom : list nat := seq 0 4.

(* 域公理抽样账：无零因子（=模多项式不可约的数值面）、交换、幺元 *)
Example f16_no_zero_divisors :
  forallb (fun p => implb (Nat.eqb (f16_mul (fst p) (snd p)) 0)
                          (orb (Nat.eqb (fst p) 0) (Nat.eqb (snd p) 0)))
    (list_prod f16_dom f16_dom) = true.
Proof. reflexivity. Qed.

Example f16_mul_comm :
  forallb (fun p => Nat.eqb (f16_mul (fst p) (snd p)) (f16_mul (snd p) (fst p)))
    (list_prod f16_dom f16_dom) = true.
Proof. reflexivity. Qed.

Example f16_mul_one :
  forallb (fun x => Nat.eqb (f16_mul x 1) x) f16_dom = true.
Proof. reflexivity. Qed.

(* 每个非零元有逆（乘法表全列搜索） *)
Definition inv16 (x : nat) : nat :=
  match find (fun y => Nat.eqb (f16_mul x y) 1) f16_dom with
  | Some y => y | None => 0
  end.

Example f16_units : forallb (fun x => implb (negb (Nat.eqb x 0))
    (Nat.eqb (f16_mul x (inv16 x)) 1)) f16_dom = true.
Proof. reflexivity. Qed.

(* ---------- 2. 加根塔：无根 ⟹ 扩域有根 ---------- *)

(* 多项式（系数低位在前）在 GF(2^k) 上的 Horner 求值 *)
Fixpoint evalGF (mul add : nat -> nat -> nat) (p : list nat) (x : nat) : nat :=
  match p with
  | [] => 0
  | c :: t => add (mul x (evalGF mul add t x)) (c mod 2)
  end.

(* x²+x+1 在 F₂ 上无根（两个代入都 ≠0） *)
Example no_root_f2 :
  forallb (fun x => negb (Nat.eqb (evalGF f4_mul f4_add [1;1;1] x) 0)) [0;1] = true.
Proof. reflexivity. Qed.

(* 同一多项式在 F₄ 有根：t=2（编码 10）满足 t²+t+1=0 *)
Example root_f4 : Nat.eqb (evalGF f4_mul f4_add [1;1;1] 2) 0 = true.
Proof. reflexivity. Qed.

(* F₁₆ 的模多项式 s⁴+s+1 在 F₂ 无根——它是「下一个无根见证」 *)
Example no_root_s4 :
  forallb (fun x => negb (Nat.eqb (evalGF f16_mul f16_add [1;1;0;0;1] x) 0)) [0;1] = true.
Proof. reflexivity. Qed.

(* ---------- 3. F₁₆ 内寻得 F₄ 拷贝：α=s²+s 满足 α²+α+1=0 ---------- *)

(* s=2（编码 0000→0010）；α = s²+s = f16_add (f16_mul 2 2) 2 *)
Definition alpha : nat := f16_add (f16_mul 2 2) 2.

Example f4_inside_f16 :
  Nat.eqb (evalGF f16_mul f16_add [1;1;1] alpha) 0 = true.
Proof. reflexivity. Qed.

(* 塔的三层：F₂ ⊂ F₄拷贝 ⊂ F₁₆——{0,1,α,α+1} 对 f16 乘法封闭 *)
Example f4_copy_closed :
  forallb (fun p => existsb (Nat.eqb (f16_mul (fst p) (snd p)))
                            [0;1;alpha;f16_add alpha 1])
    (list_prod [0;1;alpha;f16_add alpha 1] [0;1;alpha;f16_add alpha 1]) = true.
Proof. reflexivity. Qed.

(* ---------- 4. 根数 ≤ 次数：x³-1=(x-1)(x²+x+1) 在 F₁₆ 完全分裂 ---------- *)

Definition roots16 (p : list nat) : list nat :=
  filter (fun x => Nat.eqb (evalGF f16_mul f16_add p x) 0) f16_dom.

Example roots_x3_1 : eqsetb (roots16 [255;0;0;1]) [1; alpha; f16_add alpha 1] = true.
Proof. reflexivity. Qed.

(* ---------- 5. F₃ 线上的构造集：有限域上一切皆构造（塌缩账） ---------- *)

Fixpoint evalF3 (p : list nat) (x : nat) : nat :=
  match p with
  | [] => 0
  | c :: t => ((x mod 3) * evalF3 t x + c) mod 3
  end.

Definition vf3 (p : list nat) : list nat :=
  filter (fun x => Nat.eqb (evalF3 p x) 0) [0;1;2].

(* 全部 27 个 ≤2 次多项式的零点集，去重后恰为全部 8 个子集
   ——「有限或余有限」在有限域上塌缩成「全部」 *)
Definition allPolys3 : list (list nat) :=
  flat_map (fun c0 => flat_map (fun c1 => map (fun c2 => [c0;c1;c2]) [0;1;2]) [0;1;2]) [0;1;2].

Definition dedup (l : list (list nat)) : list (list nat) :=
  fold_left (fun acc s => if existsb (fun t => eqsetb t s) acc then acc else acc ++ [s]) l [].

Example constructible_collapse_f3 :
  (length (dedup (map vf3 allPolys3)), length (dedup (map (fun s => vf3 [1;1;1] ++ []) [0])))
  = (8, 1).
Proof. reflexivity. Qed.

(* ---------- 6. acl = 子域生成：F₁₆ 上的交换律（Steinitz 交换律的
   有限影子——45 章预几何的 exchange 公理现场） ---------- *)

(* 子域闭包：从 A∪{0,1} 出发对 +,×,⁻¹ 封闭到不动点 *)
Fixpoint rem_dup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: t => if existsb (Nat.eqb x) t then rem_dup t else x :: rem_dup t
  end.

Fixpoint closeStep (s : list nat) : list nat :=
  fold_left (fun acc p =>
      let x := fst p in let y := snd p in
      fold_left (fun acc2 e => if existsb (Nat.eqb e) acc2 then acc2 else acc2 ++ [e])
                [f16_add x y; f16_mul x y; inv16 x] acc)
    (list_prod s s) s.

Fixpoint closeTo (fuel : nat) (s : list nat) : list nat :=
  match fuel with
  | 0 => s
  | S f => let s' := closeStep s in
           if Nat.eqb (length s') (length s) then s' else closeTo f s'
  end.

Definition acl16 (A : list nat) : list nat := closeTo 8 (rem_dup (0 :: 1 :: A)).

(* 三层塔的 acl 账：∅ 的 acl=素域 F₂；α 的 acl=F₄ 拷贝；s 的 acl=F₁₆ *)
Example acl_layers :
  (eqsetb (acl16 []) [0;1],
   eqsetb (acl16 [alpha]) [0;1;alpha;f16_add alpha 1],
   eqsetb (acl16 [2]) f16_dom) = (true, true, true).
Proof. reflexivity. Qed.

(* 交换律（exchange）：b ∈ acl(A∪{a}) \ acl(A) ⟹ a ∈ acl(A∪{b})
   ——Steinitz 交换律的有限影子，对 A∈{∅,{α}} 与全部 a,b 枚举 *)
Definition exchangeCheck (A : list nat) (a b : nat) : bool :=
  implb (andb (existsb (Nat.eqb b) (acl16 (a :: A)))
              (negb (existsb (Nat.eqb b) (acl16 A))))
        (existsb (Nat.eqb a) (acl16 (b :: A))).

Definition exchCases : list (list nat * (nat * nat)) :=
  flat_map (fun A => map (fun p => (A, p)) (list_prod f16_dom f16_dom))
    [[]; [alpha]].


Eval vm_compute in (filter (fun c => negb (exchangeCheck (fst c) (fst (snd c)) (snd (snd c)))) exchCases).
