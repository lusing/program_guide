(* 18 策略武器库与模块 —— 自动化、assert、模块签名与封装 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Module Ex18TacticsModules.

(* ---------- auto：把 obvious 的活外包 ---------- *)

Theorem auto_ex1 : forall n m : nat, n + m = n + m.
Proof. auto. Qed.

Theorem auto_ex2 : forall P Q : Prop, P -> (P -> Q) -> Q.
Proof. auto. Qed.

(* auto = 带提示数据库的深度优先搜索。
   它能拼出「上下文里的假设 + reflexivity + 简单构造子应用」。
   卡在显然的目标上时先试 auto，省时间；auto 不万能，
   但「显然」这档的活它包了。 *)

(* ---------- assert：中间结论 ---------- *)

Theorem plus_rearrange : forall n m p q : nat,
  (n + m) + (p + q) = (m + n) + (p + q).
Proof.
  intros n m p q.
  assert (H : n + m = m + n).
  { apply Nat.add_comm. }
  (* 注意：老教材里的 plus_comm 在 8.20 已不存在，现名
     Nat.add_comm——抄旧书代码时先 Check 名字（实测坑） *)
  rewrite H. reflexivity.
Qed.

(* assert 造一个「局部引理」：花括号里现场证明它，
   之后 H 就像普通定理一样可用——证明长时的分段利器。 *)

(* ---------- transitivity：搭桥 ---------- *)

Theorem trans_le : forall a b c : nat, a <= b -> b <= c -> a <= c.
Proof.
  intros a b c Hab Hbc.
  transitivity b.
  - exact Hab.
  - exact Hbc.
Qed.

(* ---------- contradiction 与 try/; 组合 ---------- *)

Theorem contra_ex : forall P : Prop, 0 = 1 -> P.
Proof.
  intros P H. discriminate H.
  (* 实测坑：contradiction 在这里报 No such contradiction——
     它只认「上下文里有 False 或构造子直接冲突的假设」，
     0 = 1 这种「数字不同」的矛盾要靠 discriminate 看穿 *)
Qed.

(* 分号 ; 让一条策略作用于「当前全部目标」：
   destruct b; reflexivity. = 两种情况各自 reflexivity *)
Example semi_ex : forall b : bool, orb b true = true.
Proof.
  intros b. destruct b; reflexivity.
Qed.

(* try 让失败变成无害：try reflexivity 在证不了的目标上跳过 *)
Example try_ex : forall n : nat, 0 + n = n.
Proof.
  intros n. simpl. try reflexivity.
Qed.

(* ---------- 模块：命名空间 ---------- *)

Module Stack.
  Definition t := list nat.
  Definition empty : t := [].
  Definition push (x : nat) (s : t) : t := x :: s.
  Definition pop (s : t) : option (nat * t) :=
    match s with
    | [] => None
    | h :: tl => Some (h, tl)
    end.
  Theorem pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).
  Proof. intros x s. reflexivity. Qed.
End Stack.

Compute (Stack.pop (Stack.push 5 Stack.empty)).   (* Some (5, []) *)

(* ---------- 模块签名：接口 ---------- *)

Module Type STACK_SIG.
  Parameter t : Type.                       (* 接口只说「有个类型 t」 *)
  Parameter empty : t.
  Parameter push : nat -> t -> t.
  Parameter pop : t -> option (nat * t).
  Axiom pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).           (* 接口承诺的行为 *)
End STACK_SIG.

(* 用签名封印实现：外面只能通过接口看它 *)
Module SealedStack : STACK_SIG := Stack.

Print SealedStack.t.
(* SealedStack.t : Type —— 看不到 list nat 了！表示细节被隐藏 *)

Compute (SealedStack.pop (SealedStack.push 5 SealedStack.empty)).
(* = Some (5, []) : option (nat * SealedStack.t)
   —— 行为照常（承诺过的定理保证了这一点），
      但类型只暴露抽象名 SealedStack.t *)

Fail Check (SealedStack.push 5 [1; 2]).
(* 签名外看不到 t = list nat，想拿裸列表偷渡进来——类型错误 *)

End Ex18TacticsModules.
