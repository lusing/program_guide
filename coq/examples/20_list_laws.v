(* 20 列表定律证明实战 —— 六条经典定律，一套通用方法 *)

From Coq Require Import List Arith.
Import ListNotations.

Module Ex20ListLaws.

(* ---------- 1. 右单位元 ---------- *)

Theorem app_nil_r : forall (A : Type) (xs : list A), xs ++ [] = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* 看「定义形状决定证明难度」的活例子：
   [] ++ ys = xs?? —— app_nil_l 是 reflexivity 一行的事
   （++ 在左参数上递归，左边是 [] 直接化简），
   而 xs ++ [] = xs 必须归纳（左边是变量）。 *)

(* ---------- 2. 结合律 ---------- *)

Theorem app_assoc : forall (A : Type) (xs ys zs : list A),
  xs ++ ys ++ zs = (xs ++ ys) ++ zs.
Proof.
  intros A xs ys zs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* ---------- 3. length 与 ++ ---------- *)

Theorem length_app : forall (A : Type) (xs ys : list A),
  length (xs ++ ys) = length xs + length ys.
Proof.
  intros A xs ys. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* ---------- 4. map 融合 ---------- *)

Theorem map_map : forall (A B C : Type)
                          (f : A -> B) (g : B -> C) (xs : list A),
  map g (map f xs) = map (fun x => g (f x)) xs.
Proof.
  intros A B C f g xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

(* 两次遍历可融合成一次——著名的 map fusion，
   编译器自动做不了，但你可以证明了再换。 *)

(* ---------- 5. rev 分配（方向会翻转！） ---------- *)

Theorem rev_app_distr : forall (A : Type) (xs ys : list A),
  rev (xs ++ ys) = rev ys ++ rev xs.
Proof.
  intros A xs ys. induction xs as [| x tl IH].
  - simpl. rewrite app_nil_r. reflexivity.
    (* 基例也要借 app_nil_r：rev ys ++ [] = rev ys *)
  - simpl. rewrite IH. rewrite <- app_assoc. reflexivity.
    (* 步例把括号挪个位置，靠结合律 *)
Qed.

(* ---------- 6. rev 的对合性 ---------- *)

Theorem rev_involutive : forall (A : Type) (xs : list A),
  rev (rev xs) = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite rev_app_distr. rewrite IH. simpl. reflexivity.
Qed.

(* 翻两次等于不翻——「显然」，但它的证明需要：
   rev_app_distr（定律 5）+ 归纳假设 + 化简。
   定理之间互相引用组装成网，这就是「证明工程」。 *)

(* ---------- 7. 累加器反转的正确性（强化命题实战） ---------- *)

Fixpoint rev_acc {A : Type} (acc xs : list A) : list A :=
  match xs with
  | [] => acc
  | h :: tl => rev_acc (h :: acc) tl
  end.

(* 直接证「rev_acc [] xs = rev xs」会卡死：步例的累加器变成了
   x :: acc，而归纳假设只谈固定的 []——够不着。
   解法：把命题一般化成「对任意 acc」，归纳时 acc 留在目标里
   （注意 intros acc 放在 induction 之后），IH 就对所有 acc 成立。 *)

Lemma rev_acc_correct : forall (A : Type) (xs acc : list A),
  rev_acc acc xs = rev xs ++ acc.
Proof.
  intros A xs. induction xs as [| x tl IH]; intros acc.
  - reflexivity.
  - simpl. rewrite IH. rewrite <- app_assoc. simpl. reflexivity.
Qed.

Theorem fast_rev_correct : forall (A : Type) (xs : list A),
  rev_acc [] xs = rev xs.
Proof.
  intros A xs.
  rewrite rev_acc_correct.   (* 先上一般化版本 *)
  rewrite app_nil_r.         (* 消掉 ++ [] *)
  reflexivity.
Qed.

(* ---------- 方法总结 ---------- *)
(* 六条定律一个剧本：
   intros（保留要归纳的变量最后收）→ induction xs as [| x tl IH]
   → 基例 reflexivity（或借前几条定律）→ 步例 simpl、rewrite IH
   → 必要时 rewrite 其他定律、调方向（<-）。
   写不出时：先证一条「更强或更基础」的定律再来。 *)

End Ex20ListLaws.
