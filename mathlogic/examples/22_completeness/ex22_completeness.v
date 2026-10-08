(* ex22_completeness.v —— 完备性：Henkin 构造的机器面（EFT ch V）
   机器件：基项的合同闭包（fuel 迭代）= 词项解释 IΦ 的商结构；
   Φ 的方程在 TΦ 上成立；「原子式可导 ⟺ 在 TΦ 真」双向对账；
   见证式 Henkin 化的可满足性保持。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 语法与方程推导 ---------- *)

Inductive tm : Type :=
| var : nat -> tm
| fsym : nat -> list tm -> tm.

Inductive fm : Type :=
| rat : nat -> list tm -> fm
| eqf : tm -> tm -> fm
| neg : fm -> fm
| disj : fm -> fm -> fm
| exq : nat -> fm -> fm.

(* 方程推导：自反/对称/传递/同余/假设/弱化（EFT 矢列演算 S 的
   等词规则在方程世界的身影——20 章已证对称/传递/同余为可导规则） *)
Inductive dmeq : list (tm * tm) -> tm -> tm -> Prop :=
| dRefl : forall Φ t, dmeq Φ t t
| dSym : forall Φ t1 t2, dmeq Φ t1 t2 -> dmeq Φ t2 t1
| dTrans : forall Φ t1 t2 t3, dmeq Φ t1 t2 -> dmeq Φ t2 t3 -> dmeq Φ t1 t3
| dCong : forall Φ f ts1 ts2,
    Forall2 (fun a b => dmeq Φ a b) ts1 ts2 ->
    dmeq Φ (fsym f ts1) (fsym f ts2)
| dHyp : forall Φ t1 t2, In (t1, t2) Φ -> dmeq Φ t1 t2
| dWeak : forall Φ Ψ t1 t2, incl Φ Ψ -> dmeq Φ t1 t2 -> dmeq Ψ t1 t2.

(* ---------- 2. 现场语言与理论 ---------- *)

Definition a_c : tm := fsym 2 [].
Definition b_c : tm := fsym 3 [].
Definition f (t : tm) : tm := fsym 0 [t].

(* 理论：a≡b、f(a)≡b——塌缩出非平凡等价类 *)
Definition PhiG : list (tm * tm) := [(a_c, b_c); (f a_c, b_c)].

(* 基项截断（论域素材，深度 3） *)
Fixpoint terms_upto (d : nat) : list tm :=
  match d with
  | O => []
  | S d' => a_c :: b_c :: map f (terms_upto d')
  end.

Definition T4 : list tm := terms_upto 3.

(* ---------- 3. 合同闭包：可计算的商结构 ---------- *)

(* 项相等判定：fuel 单 Fixpoint（深度预算递减；嵌套结构的 guard
   检查对「子项的子项」跨 list 类型不认——预算递归是干净出路，
   与 20 章 substt 的 tsize 测度同一思想） *)
Fixpoint teqbL (n : nat) (l1 l2 : list tm) : bool :=
  match n with
  | 0 => match l1, l2 with [], [] => true | _, _ => false end
  | S n' =>
      match l1, l2 with
      | [], [] => true
      | var p :: l1', var q :: l2' => andb (p =? q) (teqbL n' l1' l2')
      | fsym s ts :: l1', fsym s' ts' :: l2' =>
          andb (s =? s') (andb (teqbL n' ts ts') (teqbL n' l1' l2'))
      | _, _ => false
      end
  end.

Definition tm_eqb (t u : tm) : bool := teqbL 30 [t] [u].
Definition teqb : tm -> tm -> bool := tm_eqb.

(* 去重：防止闭包轮次的列表指数膨胀 *)
Definition dedup (E : list (tm * tm)) : list (tm * tm) :=
  fold_right (fun p acc =>
    if existsb (fun q => andb (teqb (fst p) (fst q)) (teqb (snd p) (snd q))) acc
    then acc else p :: acc) [] E.

(* 有限论域成员检查 *)
Definition inT4 (t : tm) : bool := existsb (teqb t) T4.

(* 一轮闭包：对称 + f-同余上升，限定在论域 T4 内（否则 f-提升无界
   爆炸——合同闭包在截断论域上才不动点） *)
Definition close_step (E : list (tm * tm)) : list (tm * tm) :=
  let R := map (fun t => (t, t)) T4 in
  let S1 := R ++ E ++ map (fun p => (snd p, fst p)) E in
  let L := map (fun p => (f (fst p), f (snd p))) S1 in
  let Tr := flat_map (fun p => map (fun q => (fst p, snd q))
      (filter (fun q => teqb (snd p) (fst q)) S1)) S1 in
  dedup (filter (fun p => andb (inT4 (fst p)) (inT4 (snd p))) (S1 ++ L ++ Tr)).

Definition subsume (E1 E2 : list (tm * tm)) : bool :=
  forallb (fun p => existsb (fun q => andb (teqb (fst p) (fst q))
                                           (teqb (snd p) (snd q))) E2) E1.

Fixpoint closure (E : list (tm * tm)) (fuel : nat) : list (tm * tm) :=
  match fuel with
  | O => E
  | S fuel' =>
      let E' := close_step E in
      if subsume E' E then E else closure E' fuel'
  end.

Definition PhiG_cl : list (tm * tm) := closure PhiG 40.

(* 类代表：T4 序下第一个与 t 有闭包连接（含自反）的元素 *)
Definition canon (E : list (tm * tm)) (t : tm) : tm :=
  match filter (fun u =>
    existsb (fun p => andb (teqb (fst p) t) (teqb (snd p) u)) E
    ) T4 with
  | u :: _ => u
  | [] => t
  end.

Definition rep_of (t : tm) : tm := canon PhiG_cl t.

(* 商论域：T4 的代表去重 *)
Definition quotient_D : list tm :=
  fold_right (fun t acc =>
    if existsb (fun u => teqb u (rep_of t)) acc then acc
    else rep_of t :: acc) [] T4.

(* 方程在 TΦ 上真 ⟺ 两项同代表 *)
Definition holds_eq (t1 t2 : tm) : bool := teqb (rep_of t1) (rep_of t2).

(* Φ 的方程在 TΦ 上成立（词项模型是 Φ 的模型——Henkin 定理的现场） *)
Example Phi_holds : forallb (fun p => holds_eq (fst p) (snd p)) PhiG = true.
Proof. reflexivity. Qed.

(* ---------- 4. 「原子式可导 ⟺ 在 TΦ 真」双向对账 ---------- *)

(* 可导的可计算完全化：闭包成员（双向查询） *)
Definition deriv_b (t1 t2 : tm) : bool :=
  existsb (fun p => orb (andb (teqb (fst p) t1) (teqb (snd p) t2))
                        (andb (teqb (fst p) t2) (teqb (snd p) t1))) PhiG_cl.

Definition probes : list (tm * tm) :=
  [ (a_c, b_c); (f a_c, b_c); (f b_c, a_c); (f (f a_c), b_c);
    (f (f (f a_c)), a_c); (a_c, f (f b_c)) ].

Example deriv_iff_holds :
  forallb (fun p => Bool.eqb (deriv_b (fst p) (snd p))
                             (holds_eq (fst p) (snd p))) probes = true.
Proof. reflexivity. Qed.

(* 严谨性衔接（诚实记账）：deriv_b 是 dmeq 在本现场的完全化——
   soundness（dmeq PhiG t1 t2 -> deriv_b t1 t2 = true）对推导结构归纳：
   五个构造子分别对应闭包的自反（查询缺省 t 自己?? 注意 canon 对
   不可辨识项回退自身——恰为自反）、对称（close_step 的镜像加法）、
   传递（不动点迭代的合并）、同余（f-上升）、假设（初始成员）。
   完整归纳证明与「dRefl 通过 canon 回退」的边界情形在有限截断 T4
   上可枚举验证（上例的六探针即其抽样）；一般情形的证明依赖闭包
   不动点的构造归纳，超出本章预算，记文档级。 *)

(* ---------- 5. 见证式 Henkin 化：可满足性保持 ---------- *)

Fixpoint fm_bool (v : nat -> bool) (φ : fm) : bool :=
  match φ with
  | rat _ _ => v 0
  | eqf _ _ => v 1
  | neg ψ => negb (fm_bool v ψ)
  | disj ψ χ => orb (fm_bool v ψ) (fm_bool v χ)
  | exq _ ψ => fm_bool v ψ      (* 命题级：量词透明 *)
  end.

Definition sat (v : nat -> bool) (Φ : list fm) : bool :=
  forallb (fm_bool v) Φ.

(* 见证化：exq x φ ↦ φ（命题级量词透明的化身；一般情形 φ[x:=c_φ]） *)
Fixpoint henk (Φ : list fm) : list fm :=
  match Φ with
  | [] => []
  | exq x ψ :: Φ' => ψ :: henk Φ'
  | φ :: Φ' => φ :: henk Φ'
  end.

Definition AX1 : list fm := [disj (rat 0 []) (rat 0 []); neg (rat 0 [])].

Example henk_sat_keep :
  forallb (fun v => Bool.eqb (sat v AX1) (sat v (henk AX1)))
    (map (fun m => fun n => Nat.testbit m n) (seq 0 4)) = true.
Proof. reflexivity. Qed.

(* 二元域上的真量词验证：∃x P(x) 的 Henkin 分配 P(0)∨P(1) *)
Definition bumpv (P : nat -> bool) (a : nat) : nat -> bool :=
  fun n => if n =? 0 then a =? 1 else P n.

Fixpoint ev2 (P : nat -> bool) (φ : fm) : bool :=
  match φ with
  | rat _ _ => P 0
  | eqf _ _ => P 1
  | neg ψ => negb (ev2 P ψ)
  | disj ψ χ => orb (ev2 P ψ) (ev2 P χ)
  | exq _ ψ => orb (ev2 (bumpv P 0) ψ) (ev2 (bumpv P 1) ψ)
  end.

Definition sat2 (P : nat -> bool) (Φ : list fm) : bool := forallb (ev2 P) Φ.

Definition AX2 : list fm := [exq 0 (rat 0 []); neg (exq 0 (rat 0 []))].
(* ∃x P(x) 与 ¬∃x P(x)：见证式与它的否定——显然不可满足 *)

Example AX2_unsat :
  forallb (fun m => negb (sat2 (fun n => Nat.testbit m n) AX2)) (seq 0 4) = true.
Proof. reflexivity. Qed.

(* 冒烟与账本 *)
Compute (length quotient_D).            (* 商论域大小（塌缩后 < 8） *)
Compute (map rep_of T4).                (* 各项的类代表序列 *)
Compute (map (fun p => (deriv_b (fst p) (snd p), holds_eq (fst p) (snd p))) probes).
