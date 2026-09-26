(* 19 Ltac：自定义策略 —— 把重复的证明步骤做成可复用的程序 *)

From Stdlib Require Import Arith ZArith List Lia.
Import ListNotations.

Module Ex19Ltac.

(* ---------- 19.1 策略带参数：一次定义，处处调用 ---------- *)

(* 经典习语「试探-回滚」：先移走假设 h 再 auto；
   ; fail 的妙处——auto 若收掉全部目标，fail 无目标可作用＝空成功；
   auto 没吃下目标则 fail 触发，try 把 clear 一并回滚，h 原样回来 *)
Ltac auto_clear h := try (clear h; auto; fail).

Example auto_clear_demo : forall n m : nat, m = 3 -> n <= m -> n <= m.
Proof. intros n m Hm Hnm. auto_clear Hm. Qed.
(* auto 用假设 Hnm 直接收——顺手验证了「清掉 Hm 不碍事」 *)

(* 反向验证回滚：auto 吃不下这个目标，clear 被整体撤销——
   注意后面 lia 仍能用 H（它没有被真删掉） *)
Example auto_clear_rollback : forall n m : nat, n <= m -> n + 0 <= m + 1.
Proof. intros n m H. auto_clear H. lia. Qed.

(* 参数也可以是「另一个策略」——调用时用 ltac:(...) 括起来，
   把策略与 Gallina 项区分开 *)
Ltac auto_after tac := try (tac; auto; fail).

Example auto_after_demo : forall n m : nat, m = 7 -> n <= m -> n <= m.
Proof. intros n m Hm Hnm. auto_after ltac:(clear Hm). Qed.

(* ---------- 19.2 递归策略 ---------- *)

Print le.
(* Inductive le (n : nat) : nat -> Prop :=
     le_n : n <= n | le_S : forall m, n <= m -> n <= S m *)

Ltac le_S_star := apply le_n || (apply le_S; le_S_star).
(* 读法：要么用 le_n 收尾，要么剥一层 le_S 再递归。
   || 是「第一个失败才试第二个」的顺序组合 *)

Example le_5_25 : 5 <= 25.
Proof. le_S_star. Qed.

(* ---------- 19.3 match goal：按目标形状分派 ---------- *)

Ltac dispatch :=
  match goal with
  | [ |- _ = _ ] => reflexivity
  | [ |- _ <= _ ] => lia
  | [ |- _ < _ ] => lia
  end.

Example dispatch_ex1 : forall n : nat, 0 + n = n.
Proof. intros n. dispatch. Qed.
(* 注意目标若写成 n + 0 = n，reflexivity 吃不下（0 在右边不化简，
   需要归纳或 Nat.add_0_r）——matched 子句失败后 Ltac 会回溯尝试
   后续子句，全都对不上才报 No matching clauses *)

Example dispatch_ex2 : forall n m : nat, n <= m -> n <= S m.
Proof. intros n m H. dispatch. Qed.

(* 对「假设」做模式匹配：contrapose——把 ~A 目标与 ~B 假设
   换成新假设 B 与目标 A（逆否变换），新名字由调用方指定 *)
Ltac contrapose H :=
  match goal with
  | [ H0 : ~ _ |- ~ _ ] => intro H; apply H0
  end.

Theorem contrapose_ex : forall x y : nat, x <> y -> x <= y -> ~ (y < x).
Proof.
  intros x y Hxy Hle.
  contrapose H'.      (* H' : y < x，目标 x = y *)
  lia.                (* y < x 与 x <= y 联手逼出 x = y *)
Qed.

(* ---------- 19.4 深度匹配与回溯：context 与 fail n ---------- *)

Theorem S_plus_one : forall n : nat, S n = n + 1.
Proof. intros n. rewrite Nat.add_1_r. reflexivity. Qed.

(* 想对目标里所有 S x（x 非 0）做 S x → x + 1 的重写再交给 ring。
   直接 repeat rewrite (S_plus_one) 会死循环：
   1 本身就是 S 0，重写产物 0 + 1 里又长出新的 S 0……
   解法：模式里挖出 x，x 是 0 时用 fail 1 跳出整个 match 分支 *)
Ltac S_to_plus_simpl :=
  match goal with
  | [ |- context [S ?x] ] =>
      match x with
      | O => fail 1                     (* 跳过 S 0，别往 0+1 的路上走 *)
      | ?y => rewrite (S_plus_one y); S_to_plus_simpl
      end
  | [ |- _ ] => idtac
  end.

(* ring 不认识 S：这个等式 ring 直接吃不下（残留 m * S n 之类），
   先用自定义策略把 S n 规整成 n + 1，ring 才能收 *)
Example ring_after_ltac : forall n m : nat,
  n * 0 + (S n) * m = n * n * 0 + m * n + m.
Proof. intros n m. S_to_plus_simpl. ring. Qed.

(* ---------- 19.5 在策略里做计算：eval ... in ---------- *)

(* eval simpl in e：在策略层面把 e 化简出一个值 v，
   再把目标里所有 e 替换成 v——「只化简指定子项」的定向 simpl *)
Ltac simpl_on e :=
  let v := eval simpl in e in
  match goal with
  | [ |- context [e] ] => replace e with v; [ idtac | auto ]
  end.

Example simpl_on_ex : forall n : nat, (1 + n) * (1 + n) = (1 + n) * S n.
Proof. intros n. simpl_on (1 + n). reflexivity. Qed.

(* ---------- 19.6 工程打包：inversion + subst + clear ---------- *)

(* 等式假设里构造子打架时，inversion 拆出全部小等式，
   subst 一律代入，clear 清掉用完的假设——三连打包成 inv *)
Ltac inv H := inversion H; subst; clear H.

Example inv_ex : forall ys : list nat, 1 :: ys = [1; 2] -> ys = [2].
Proof. intros ys H. inv H. reflexivity. Qed.

(* ---------- 19.7 Hint 数据库与 eauto ---------- *)

(* Hint Resolve 把定理注册进指定数据库，eauto 搜索时当积木用 *)
Hint Resolve Nat.le_trans : le_db.

Theorem eauto_ex : forall a b c d : nat,
  a <= b -> b <= c -> c <= d -> a <= d.
Proof. intros a b c d H1 H2 H3. eauto with le_db. Qed.
(* auto 不行：它不会主动猜 le_trans 的中间值；
   eauto 的 e = existential 变量替它猜 *)

(* Hint Rewrite + autorewrite：注册一组「永远从左往右」的重写规则。
   经典例子（组合逻辑）：S 与 K 的重写规则足以把 S K K 化简成恒等组合子 *)
Section CombinatoryLogic.
Variables (CL : Type) (App : CL -> CL -> CL) (S K : CL).
Hypothesis S_rule : forall A B C : CL,
  App (App (App S A) B) C = App (App A C) (App B C).
Hypothesis K_rule : forall A B : CL, App (App K A) B = A.

Hint Rewrite S_rule K_rule : CL_rules.

Theorem obtain_I : forall A : CL, App (App (App S K) K) A = A.
Proof. intros. autorewrite with CL_rules. reflexivity. Qed.
End CombinatoryLogic.

(* ---------- 19.8 组合技：first 与一击必杀 ---------- *)

Ltac number_goal := first [ reflexivity | lia | ring | congruence ].

Example number_goal_ex1 : forall n : nat, 0 + n = n.
Proof. intros n. number_goal. Qed.

Example number_goal_ex2 :
  forall x y : Z, ((x + y) * (x + y) = x * x + 2 * x * y + y * y)%Z.
Proof. intros x y. number_goal. Qed.

End Ex19Ltac.
