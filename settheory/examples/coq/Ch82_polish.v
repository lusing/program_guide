(* 第 82 章：有限 Gale–Stewart 逆向归纳——对偶性与具体赛局。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch82.

(* 深度 n 的交替博弈：zs=true 轮张三（存在制胜步即胜），
   zs=false 轮李四（所有步张三都胜张三才胜）。
   前缀以逆序积累：p 的首元素是最近一步。 *)
Fixpoint zwins (A : list bool -> bool) (n : nat) (zs : bool)
    (p : list bool) : bool :=
  match n with
  | 0 => A p
  | S k =>
      if zs
      then orb (zwins A k false (true :: p)) (zwins A k false (false :: p))
      else andb (zwins A k true (true :: p)) (zwins A k true (false :: p))
  end.

(* 对偶：补赛事 + 互换行棋方 = 原赛局的否定（德摩根律逐层生效）。
   有限确定性（命题 3.9/3.10 的内核）：任一赛局恰有一方处于胜势。 *)
Theorem zwins_dual : forall (A : list bool -> bool) (n : nat) (zs : bool),
  forall (p : list bool),
  zwins (fun q => negb (A q)) n (negb zs) p = negb (zwins A n zs p).
Proof.
  intros A n. induction n as [|n IH]; intros zs p.
  - simpl. destruct (A p); reflexivity.
  - destruct zs; simpl.
    + assert (E1 := IH false (true :: p)); simpl in E1.
      assert (E2 := IH false (false :: p)); simpl in E2.
      rewrite E1, E2.
      destruct (zwins A n false (true :: p));
        destruct (zwins A n false (false :: p)); reflexivity.
    + assert (E1 := IH true (true :: p)); simpl in E1.
      assert (E2 := IH true (false :: p)); simpl in E2.
      rewrite E1, E2.
      destruct (zwins A n true (true :: p));
        destruct (zwins A n true (false :: p)); reflexivity.
Qed.

(* 深度 2 的具体赛局：张三出 x、李四出 y（叶上序列为 [y;x]）。 *)
Definition A_and : list bool -> bool :=
  fun q => match q with
           | y :: x :: _ => andb x y
           | _ => false
           end.

Definition A_or : list bool -> bool :=
  fun q => match q with
           | y :: x :: _ => orb x y
           | _ => false
           end.

(* x∧y：张三无胜算——李四总可以出 false。 *)
Example and_game : zwins A_and 2 true [] = false.
Proof. reflexivity. Qed.

(* x∨y：张三先手出 true 即稳赢。 *)
Example or_game : zwins A_or 2 true [] = true.
Proof. reflexivity. Qed.

(* 由对偶定理（换先手 + 取补）：原李四在补赛局中稳赢。 *)
Example and_dual_game : zwins (fun q => negb (A_and q)) 2 false [] = true.
Proof. reflexivity. Qed.

End Ch82.
