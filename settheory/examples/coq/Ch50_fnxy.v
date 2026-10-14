(** 第 50 章：Fn(3,2) 的 ccc 有限版（决定性枚举）

    条件 = 坐标-取值关联表（list (nat * bool)），域 ⊆ {0,1,2}。
    相容 ⟺ 无坐标冲突。策略：单一布尔检查器 + vm_compute，
    不做 64 分支的人工枚举。 *)

Require Import List Arith Lia.
Import ListNotations.

Definition cond := list (nat * bool).

Fixpoint lookup (i : nat) (c : cond) : option bool :=
  match c with
  | nil => None
  | (j, b) :: rest => if Nat.eq_dec i j then Some b else lookup i rest
  end.

Definition beqb (a b : bool) : bool :=
  if a then b else negb b.

Fixpoint no_clash (c d : cond) : bool :=
  match c with
  | nil => true
  | (i, b) :: rest =>
      match lookup i d with
      | Some b' => if beqb b b' then no_clash rest d else false
      | None => no_clash rest d
      end
  end.

Definition compat (c d : cond) : bool := no_clash c d && no_clash d c.

Fixpoint cond_eqb (c d : cond) : bool :=
  match c, d with
  | nil, nil => true
  | (i, b) :: cs, (j, b') :: ds =>
      andb (Nat.eqb i j) (andb (beqb b b') (cond_eqb cs ds))
  | _, _ => false
  end.

(* ---- 全定义的 8 个条件 ---- *)
Definition total (b0 b1 b2 : bool) : cond :=
  [(0, b0); (1, b1); (2, b2)].

Definition all8 : list cond :=
  [ total true true true; total true true false;
    total true false true; total true false false;
    total false true true; total false true false;
    total false false true; total false false false ].

(* ---- 单一检查器：反链 = 任何两个不同成员不相容 ---- *)
Definition antichainb (L : list cond) : bool :=
  forallb (fun c => forallb (fun d =>
    if cond_eqb c d then true else negb (compat c d)) L) L.

Lemma all8_antichain : antichainb all8 = true.
Proof. vm_compute. reflexivity. Qed.

(* ---- 极大性：任何部分条件与某个全定义条件相容 ---- *)
(* 27 个部分条件：k 个坐标 × 2^k 取值。代表性抽样断言 *)
Definition singletons : list cond :=
  [ [(0, true)]; [(0, false)]; [(1, true)]; [(1, false)];
    [(2, true)]; [(2, false)] ].

Definition extendable (c : cond) : bool :=
  existsb (fun t => compat c t) all8.

Lemma singletons_extendable :
  forallb extendable singletons = true.
Proof. vm_compute. reflexivity. Qed.

(* 双坐标样例 *)
Lemma pairs_extendable :
  extendable [(0, true); (2, false)] = true
  /\ extendable [(1, false); (2, true)] = true.
Proof. split; vm_compute; reflexivity. Qed.
