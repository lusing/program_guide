(* 26 依赖类型与强规范 —— 让「类型」说出值的性质 *)

From Stdlib Require Import Arith Lia.

Module Ex26Dependent.

(* ---------- 26.1 依赖数据类型：长度入类型 ---------- *)

(* list nat 只说「都是 nat」；vect A n 连长度一起说。
   构造子的类型由参数 n 决定——vnil 只能是长度 0，
   vcons 造出的长度必然是 S n *)
Inductive vect (A : Type) : nat -> Type :=
| vnil : vect A 0
| vcons : forall {n}, A -> vect A n -> vect A (S n).

Arguments vnil {A}.
Arguments vcons {A n} x v.

(* 连接：结果长度 n + m 写进类型里。
   vnil 分支：0 + m 化简就是 m，类型自动对上；
   vcons 分支：S n' + m 化简就是 S (n' + m)，同样对上 *)
Fixpoint vappend {A} {n m} (v : vect A n) (w : vect A m) : vect A (n + m) :=
  match v with
  | vnil => w
  | vcons x v' => vcons x (vappend v' w)
  end.

Example vappend_ex : vect nat 2 :=
  vappend (vcons 1 vnil) (vcons 2 vnil).
(* 1 + 1 与 2 的相等由类型系统里的「可转换性」自动确认 *)

(* 长度说错，编译期直接拒绝——不用等运行期越界 *)
Fail Check (vcons 1 vnil : vect nat 5).

(* 依赖匹配的红利：v : vect A (S n) 时 vnil 分支「不可能」，
   可以整个省略——穷尽性检查在依赖类型下变聪明了 *)
Definition vhead {A} {n} (v : vect A (S n)) : A :=
  match v with
  | vcons x _ => x
  end.
(* 对照：普通 list 的 head 只能返回 option（第 17 章）——
   依赖类型把「非空」的运行期检查变成了编译期事实 *)

(* ---------- 26.2 弱规范 vs 强规范 ---------- *)

(* 弱规范：f : A -> B + 伴随引理 forall a, R a (f a)
   （前 25 章的做法：函数一个类型、性质一条定理，分开住）
   强规范：输出直接是「值 + 值满足性质的证据」，
   类型即合同——本章的主角 *)

(* ---------- 26.3 子集类型 {x : A | P x} ---------- *)

(* sig：带认证的值。计算部分是 S n，认证部分是 n < S n 的证明 *)
Definition pos (n : nat) : {p : nat | n < p}.
Proof. exists (S n). lia. Defined.

Compute (proj1_sig (pos 41)).   (* = 42 —— 取计算部分，证明不可见 *)

(* 认证部分不是摆设：想构造 {p | n < p} 的值，
   必须真的给出一个 n < p 的证明，编不出来 *)

(* ---------- 26.4 有认证的不相交和 {A} + {B} ---------- *)

(* sumbool：bool 的强规范版——true/false 各自带「为什么」 *)
Definition zero_dec : forall n : nat, {n = 0} + {n <> 0}.
Proof.
  intros n. destruct n as [| p].
  - left. reflexivity.
  - right. discriminate.
Defined.

(* sumbool 可以直接用 if——这正是 if 的真身（第 5 章） *)
Compute (if zero_dec 3 then 0 else 1).   (* = 1 *)

(* 标准库同款：Nat.eq_dec / Z_le_gt_dec 等，命名以 _dec 结尾 *)
Check Nat.eq_dec.
(* forall n m : nat, {n = m} + {n <> m} *)

(* ---------- 26.5 强规范函数：pred 三连 ---------- *)

(* 版本一（强规范 + 定义域限定）：
   要么给出前驱并证明 n = S p，要么证明 n = 0 *)
Definition pred_strong : forall n : nat, {p : nat | n = S p} + {n = 0}.
Proof.
  intros n. destruct n as [| p].
  - right. reflexivity.
  - left. exists p. reflexivity.
Defined.

Compute (pred_strong 5).
(* = inleft (exist (fun p : nat => 5 = S p) 4 eq_refl)
   ——值 4 和证据 eq_refl 都看得见 *)

(* 版本二（偏函数 + 前置条件）：调用方负责证明 n <> 0 *)
Definition pred_partial : forall n : nat, n <> 0 -> nat.
Proof.
  refine (fun n => match n as x return x <> 0 -> nat with
                   | 0 => fun h => False_rect _ (h eq_refl)
                   | S p => fun _ => p
                   end).
Defined.
(* refine 给出计算骨架（match 的形状自己写），
   留 _ 交给策略补证明——计算内容不被自动策略污染 *)

Compute (pred_partial 7 (Nat.neq_succ_0 6)).   (* = 6：前置条件是库里的现成定理 *)

(* 版本三（子集类型收尾）：返回值连性质一起带走 *)
Definition pred_witness : forall n : nat, n <> 0 -> {p : nat | n = S p}.
Proof.
  intros n H. destruct n as [| p].
  - exfalso. apply H. reflexivity.
  - exists p. reflexivity.
Defined.

(* ---------- 26.6 Defined 与 Qed：能算的证明，收尾方式不同 ---------- *)

(* 定义「函数」用 Defined.：证明保持透明（transparent），
   Compute 才能展开它做计算 *)
Definition pred_opaque : forall n : nat, {p : nat | n = S p} + {n = 0}.
Proof.
  intros n. destruct n as [| p].
  - right. reflexivity.
  - left. exists p. reflexivity.
Qed.

Compute (pred_opaque 5).
(* = pred_opaque 5  ——卡住了！Qed 把证明封成黑盒（opaque），
   计算进不去。证定理用 Qed、造函数用 Defined，是铁律 *)

End Ex26Dependent.
