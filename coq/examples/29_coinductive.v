(* 29 余归纳与无限数据 —— CoFixpoint、guard 约束与互模拟 *)

From Stdlib Require Import Arith.

Module Ex29Coinductive.

(* ---------- 29.1 惰性列表：CoInductive ---------- *)

(* 归纳类型：有限次应用构造子得到的「最小」集合；
   余归纳类型：允许无限构造的「最大」集合。
   LList 兼容有限（LNil 收尾）与无限（永远 LCons） *)
CoInductive LList (A : Type) : Type :=
| LNil : LList A
| LCons : A -> LList A -> LList A.

Arguments LNil {A}.
Arguments LCons {A} a l.

(* 观察函数照旧用 Fixpoint——递归在 nat 上，只消耗有限前缀 *)
Fixpoint LNth {A} (n : nat) (l : LList A) : option A :=
  match l with
  | LNil => None
  | LCons a l' => match n with 0 => Some a | S p => LNth p l' end
  end.

Definition LHead {A} (l : LList A) : option A :=
  match l with LNil => None | LCons a _ => Some a end.

Definition LTail {A} (l : LList A) : LList A :=
  match l with LNil => LNil | LCons _ l' => l' end.

Compute (LHead (LTail (LCons 1 (LCons 2 LNil)))).   (* = Some 2 *)

(* ---------- 29.2 CoFixpoint：用有限表达式造无限对象 ---------- *)

(* 从 n 开始的全体自然数。Fixpoint 版会被拒（S n 不是 n 的子项），
   CoFixpoint 版合法：递归调用出现在构造子 LCons 的参数位 *)
CoFixpoint from (n : nat) : LList nat := LCons n (from (S n)).

CoFixpoint repeat {A} (a : A) : LList A := LCons a (repeat a).

(* 无限拼接：guard 约束体现在「输出」上——match 消耗 u 的一个构造子，
   每层递归产出恰好一个 LCons *)
CoFixpoint LAppend {A} (u v : LList A) : LList A :=
  match u with
  | LNil => v
  | LCons a u' => LCons a (LAppend u' v)
  end.

Compute (LNth 19 (from 17)).   (* = Some 36 *)
Compute (LNth 123 (LAppend (repeat 33) (from 0))).   (* = Some 33 *)
Compute (LNth 123 (LAppend (LCons 0 (LCons 1 (LCons 2 LNil))) (from 0))).
(* = Some 120：前 3 步吃掉有限段，之后接上 from 0 的第 120 个元素 *)

(* ---------- 29.3 guard 约束：不是什么余递归都能定义 ---------- *)

(* else 分支直接返回递归调用（不在构造子里）——拒绝。
   若接受，过滤全 false 的流时 LHead 会发散 *)
Fail CoFixpoint bad_filter {A} (p : A -> bool) (l : LList A) : LList A :=
  match l with
  | LNil => LNil
  | LCons a l' => if p a then LCons a (bad_filter p l') else bad_filter p l'
  end.

(* 递归调用出现在 match 的 scrutinee 位——同样拒绝 *)
Fail CoFixpoint buggy_repeat {A} (a : A) : LList A :=
  match buggy_repeat a with
  | LNil => LNil
  | LCons _ l' => LCons a (buggy_repeat a)
  end.

(* ---------- 29.4 展开技术：分解引理 ---------- *)

(* simpl 不展开余递归（Eval simpl in (repeat 33) 原样返回）。
   经典技巧（Paulin-Mohring）：包一层恒等函数，逼 cofix 展开一步 *)
Definition LList_decompose {A} (l : LList A) : LList A :=
  match l with
  | LNil => LNil
  | LCons a l' => LCons a l'
  end.

Lemma LList_decomposition : forall {A} (l : LList A), l = LList_decompose l.
Proof. intros A l. destruct l; reflexivity. Qed.

(* 展开=(unfolding)引理一族：证明余递归函数「定义等式」的正规手段 *)
Lemma from_unfold : forall n, from n = LCons n (from (S n)).
Proof. intros n. rewrite (LList_decomposition (from n)). reflexivity. Qed.

Lemma repeat_unfold : forall {A} (a : A), repeat a = LCons a (repeat a).
Proof. intros A a. rewrite (LList_decomposition (repeat a)) at 1. reflexivity. Qed.
(* at 1：等式两侧都有 repeat a，不限定出现次数会两边一起换、越换越多 *)

Lemma LAppend_LCons : forall (A : Type) (a : A) (u v : LList A),
  LAppend (LCons a u) v = LCons a (LAppend u v).
Proof. intros A a u v. rewrite (LList_decomposition (LAppend (LCons a u) v)). reflexivity. Qed.

Lemma LAppend_LNil : forall (A : Type) (v : LList A), LAppend LNil v = v.
Proof. intros A v. rewrite (LList_decomposition (LAppend LNil v)). destruct v; reflexivity. Qed.

Hint Rewrite LAppend_LNil LAppend_LCons from_unfold : llists_db.

(* ---------- 29.5 余归纳谓词与 cofix 策略 ---------- *)

(* Infinite：余归纳谓词——证明本身可以是无限项
   （注意用 Coinductive；写成 Inductive 会得到永不可满足的谓词） *)
CoInductive Infinite (A : Type) : LList A -> Prop :=
| Infinite_cons : forall (a : A) (l : LList A),
    Infinite A l -> Infinite A (LCons a l).

Arguments Infinite {A}.

Theorem from_infinite : forall n, Infinite (from n).
Proof.
  cofix H.        (* 引入余递归假设 H : forall n, Infinite (from n) *)
  intros n.
  rewrite from_unfold.
  apply Infinite_cons.      (* H 只能喂给构造子——这是 guard *)
  apply H.
Qed.
(* 实测经验：用了 assumption/auto 等自动策略后敲一下 Guarded 命令
   检查 guard 是否仍成立——unguarded 的证明要到 Qed 才炸 *)

Theorem LNil_not_infinite : forall {A}, ~ Infinite (LNil (A := A)).
Proof. intros A H. inversion H. Qed.

(* ---------- 29.6 互模拟：无限对象的「相等」 ---------- *)

(* eq 太强：from 0 和 LAppend (LCons 0 LNil) (from 1) 构造不同无法证相等。
   bisimilar 是为无限对象准备的等价：每个位置都相同 *)
CoInductive bisimilar (A : Type) : LList A -> LList A -> Prop :=
| bisim_nil : bisimilar A LNil LNil
| bisim_cons : forall (a : A) (l l' : LList A),
    bisimilar A l l' -> bisimilar A (LCons a l) (LCons a l').

Arguments bisimilar {A}.

CoFixpoint bisimilar_refl {A} (l : LList A) : bisimilar l l.
Proof. destruct l as [| a l']. apply bisim_nil. apply bisim_cons. apply bisimilar_refl. Defined.

(* 结合律：等号版证不动（无限对象），互模拟版 cofix 一气呵成 *)
Theorem LAppend_assoc : forall (A : Type) (u v w : LList A),
  bisimilar (LAppend u (LAppend v w)) (LAppend (LAppend u v) w).
Proof.
  intros A. cofix H. intros u v w. destruct u as [| a u'].
  - rewrite !LAppend_LNil. apply bisimilar_refl.
  - rewrite !LAppend_LCons. apply bisim_cons. apply H.
Qed.

(* 无限流吃掉任何后缀仍是「自己」（互模拟意义下） *)
Theorem infinite_absorb : forall {A} (u v : LList A),
  Infinite u -> bisimilar u (LAppend u v).
Proof.
  cofix H. intros A u v Hinf.
  inversion Hinf as [a u' Hinf' Heq]. subst.
  rewrite LAppend_LCons.
  apply bisim_cons.
  apply H. exact Hinf'.
Qed.

Compute (LNth 5 (LAppend (from 0) (repeat 99))).   (* = Some 5：infinite_absorb 的可计算影子 *)

End Ex29Coinductive.
