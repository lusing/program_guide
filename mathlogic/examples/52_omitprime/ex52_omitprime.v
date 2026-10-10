(* ex52_omitprime.v —— 省略型与素模型（Marker GTM 217 §4.2）
   机器件：三阶段 Henkin 纪律的有限重演（完备/见证/省略——T_c 常量
   理论上逐阶段可满足性验证+省略记账）；PA 端扩张论证的鸽洞账
   （Thm 4.2.5 的 (**)：∀x∃y>x∃v<a θ ⟹ ∃v<a∀x∃y>x θ——在 (N,<)
   有限片段上对公式族枚举验证=p_a 非孤立的机制面）；(Z_6,S,0) 的
   项模型=素模型（项闭包=全域+每元素有孤立见证）。零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb f t) end.

(* ---------- 1. 常量等式片段的可满足性（指派枚举） ---------- *)

Definition lit : Type := nat * nat * bool.   (* c_i = c_j（true）或 ≠ *)

Fixpoint allAssigns (k R : nat) : list (list nat) :=
  match k with
  | 0 => [[]]
  | S k' => flat_map (fun v => map (fun t => v :: t) (allAssigns k' R)) (seq 0 (R + 1))
  end.

Definition litOK (asg : list nat) (l : lit) : bool :=
  match l with
  | (i, j, true) => Nat.eqb (nth i asg 0) (nth j asg 0)
  | (i, j, false) => negb (Nat.eqb (nth i asg 0) (nth j asg 0))
  end.

Definition satLits (R : nat) (L : list lit) : bool :=
  existsb (fun asg => forallb (litOK asg) L) (allAssigns 4 R).

(* ---------- 2. 三阶段 Henkin 纪律的有限重演 ---------- *)

(* 理论 T_c = {c_i ≠ c_j : i<j≤3}；被省略的型
   p(v) = {v ≠ c_i : i}（「非标准点」型——非孤立：任何公式只提
   有限多个常量，总有常量逃出禁集） *)
Definition Tc : list lit :=
  [(0,1,false);(0,2,false);(0,3,false);(1,2,false);(1,3,false);(2,3,false)].

(* 阶段记录：(阶段号, 动作码, 追加的文字)——0=init、1=完备、
   2=见证、3=省略——三阶段轮转的有限重演 *)
Definition henkinTrace : list (nat * nat * list lit) :=
  [ (0, 0, Tc)
  ; (1, 1, [(0,0,true)])                  (* 完备：c_0=c_0 永真提交 *)
  ; (2, 2, [(1,0,false)])                 (* 见证：∃v v≠c_0 用 c_1（Tc 已知） *)
  ; (3, 3, [(0,0,true)])                  (* 省略：¬(v≠c_0) 落 c_0，φ=v≠c_0 ∈ p *)
  ; (4, 1, [(1,1,true)])
  ; (5, 2, [(2,1,false)])                 (* 见证：∃v v≠c_1 用 c_2 *)
  ; (6, 3, [(1,1,true)])
  ; (7, 3, [(2,2,true)])
  ; (8, 3, [(3,3,true)])
  ].

Definition recStage (r : nat * nat * list lit) : nat := fst (fst r).
Definition recLits (r : nat * nat * list lit) : list lit := snd r.

Definition stateAt (s : nat) : list lit :=
  fold_left (fun acc r => if Nat.leb (recStage r) s then acc ++ recLits r else acc)
    henkinTrace [].

(* 每阶段后状态可满足（c_i:=i 是见证） *)
Example henkin_stages_sat :
  forallb (fun s => satLits 3 (stateAt s)) (seq 0 9) = true.
Proof. vm_compute. reflexivity. Qed.

(* 省略记账：对每个 c_k（k<4），构造在某阶段把某 φ∈p 的否定放
   在 c_k 上（¬(v≠c_k) 即 c_k=c_k）——规范模型的每个元素都被
   「钉」在自己的常量上，p 无处实现 *)
Example omit_ledger :
  forallb (fun k => existsb (fun r => existsb (fun l =>
    match l with
    | (i, j, true) => andb (Nat.eqb i k) (Nat.eqb j k)
    | _ => false
    end) (recLits r)) henkinTrace) (seq 0 4) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 3. PA 端扩张的鸽洞账（Thm 4.2.5 的 (**)） ---------- *)

(* θ(v,y) 公式族；K=12 截断、a=4 个 v 槽 *)
Definition thetaList : list (nat -> nat -> bool) :=
  [ fun v y => Nat.eqb v y
  ; fun v y => Nat.ltb v y
  ; fun v y => Nat.ltb y v
  ; fun v y => negb (Nat.ltb v y)
  ; fun v y => negb (Nat.eqb v y)
  ; fun v y => orb (Nat.ltb v y) (Nat.eqb v y)
  ].

Definition aBound := 4.
Definition kBound := 12.

(* (**)：∀x∃y(x<y≤K ∧ ∃v<a θ(v,y)) ⟹ ∃v<a∀x∃y(x<y≤K ∧ θ(v,y))
   ——a 个 v 槽对无界 y 的鸽洞：某 v 接住任意大的 y。这正是
   p_a={v<a, v≠m} 非孤立的机制（PA 可证的推理 (**)） *)
Definition pqPremise (th : nat -> nat -> bool) : bool :=
  forallb (fun x =>
    existsb (fun y => andb (Nat.ltb x y)
      (existsb (fun v => andb (Nat.ltb v aBound) (th v y)) (seq 0 aBound)))
    (seq (x + 1) (kBound - x))) (seq 0 kBound).

Definition pqConcl (th : nat -> nat -> bool) : bool :=
  existsb (fun v => andb (Nat.ltb v aBound)
    (forallb (fun x => existsb (fun y => andb (Nat.ltb x y) (th v y))
      (seq (x + 1) (kBound - x))) (seq 0 kBound))) (seq 0 aBound).

Example pa_pigeonhole :
  forallb (fun th => implb (pqPremise th) (pqConcl th)) thetaList = true.
Proof. vm_compute. reflexivity. Qed.

Example unbounded_needed :
  andb (forallb (fun y => existsb (fun v => Nat.ltb v y) (seq 0 aBound)) (seq 1 kBound))
       (negb (existsb (fun v => forallb (fun y => Nat.ltb v y) (seq 0 kBound)) (seq 0 aBound)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 4. 素模型=项模型：(Z_6,S,0) ---------- *)

Definition step6 (x : nat) : nat := (x + 1) mod 6.

(* 项闭包：{S^k 0 : k<12} 去重 = 全域（恰 6 个） *)
Definition termClosure : list nat :=
  fold_left (fun acc v => if existsb (Nat.eqb v) acc then acc else acc ++ [v])
    (map (fun k => Nat.iter k step6 0) (seq 0 12)) [].

Example prime_term_model :
  (length termClosure, forallb (fun v => existsb (Nat.eqb v) termClosure) (seq 0 6))
  = (6, true).
Proof. vm_compute. reflexivity. Qed.

(* 每个元素被公式 x=S^k 0 孤立——素模型只实现孤立型
   （Thm 4.2.10「原子=素」的有限面） *)
Example prime_isolated :
  forallb (fun v => existsb (fun k => Nat.eqb (Nat.iter k step6 0) v) (seq 0 6)) (seq 0 6)
  = true.
Proof. vm_compute. reflexivity. Qed.

Print Assumptions prime_isolated.
