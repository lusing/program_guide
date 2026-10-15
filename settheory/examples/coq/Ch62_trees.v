(* 第 62 章：树的机器化（Makinson Ch7）
   二叉树归纳类型 + BST 搜索/插入 + n−1 边 + 波兰记法求值。 *)
From Coq Require Import List Arith Lia Bool.
Import ListNotations.

(* ---------- 二叉树：新根法递归的原生形态 ---------- *)
Inductive BTree : Type :=
| leaf : BTree
| node : BTree -> nat -> BTree -> BTree.

Fixpoint search (t : BTree) (x : nat) : bool :=
  match t with
  | leaf => false
  | node l a r =>
      if Nat.eqb x a then true
      else if Nat.ltb x a then search l x
      else search r x
  end.

Fixpoint insert (t : BTree) (x : nat) : BTree :=
  match t with
  | leaf => node leaf x leaf
  | node l a r =>
      if Nat.ltb x a then node (insert l x) a r
      else if Nat.ltb a x then node l a (insert r x)
      else t
  end.

(* 书中 BST (d)：5,3,7,2,4,6,10,9 *)
Definition tD : BTree :=
  node (node (node leaf 2 leaf) 3 (node leaf 4 leaf)) 5
       (node (node leaf 6 leaf) 7
             (node (node leaf 9 leaf) 10 leaf)).

Example cert_search6 : search tD 6 = true.
Proof. vm_compute. reflexivity. Qed.

Example cert_search8 : search tD 8 = false.
Proof. vm_compute. reflexivity. Qed.

Example cert_insert8 : search (insert tD 8) 8 = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- n − 1 条边 ---------- *)
Fixpoint nodes (t : BTree) : nat :=
  match t with leaf => 0 | node l _ r => 1 + nodes l + nodes r end.

Fixpoint edges (t : BTree) : nat :=
  match t with
  | leaf => 0
  | node l _ r =>
      edges l + edges r
      + (if Nat.eqb (nodes l) 0 then 0 else 1)
      + (if Nat.eqb (nodes r) 0 then 0 else 1)
  end.

Theorem edges_eq : forall t,
    edges t = nodes t - (if Nat.eqb (nodes t) 0 then 0 else 1).
Proof.
  induction t as [| l IHl x r IHr]; simpl.
  - reflexivity.
  - destruct l as [|ll lx lr], r as [|rl rx rr]; simpl in *;
      repeat match goal with
      | |- context [Nat.eqb ?a ?b] => destruct (Nat.eqb a b) eqn:?
      end; simpl in *; lia.
Qed.

(* ---------- 逆波兰（后缀）记法的栈式求值器 ---------- *)
(* 编码：词牌 100+k 表示运算符 k（0=+, 1=−, 2=×），其余为操作数。
   栈求值器对词牌表结构递归。 *)
Fixpoint evalPostfix (tokens : list nat) (stk : list nat)
  : option nat :=
  match tokens with
  | [] => match stk with [v] => Some v | _ => None end
  | tok :: rest =>
      if Nat.ltb 99 tok then
        match stk with
        | b :: a :: stk' =>
            evalPostfix rest
              (match tok - 100 with
               | 0 => a + b | 1 => a - b | _ => a * b end :: stk')
        | _ => None
        end
      else evalPostfix rest (tok :: stk)
  end.

(* (5 + (2*4)) 与 ((7-3)+(2+4)) 的和：中缀 23；后缀 5 2 4 × + 7 3 − 2 4 + + *)
Example cert_polish :
  evalPostfix [5; 2; 4; 102; 100; 7; 3; 101; 2; 4; 100; 100; 100] [] = Some 23.
Proof. vm_compute. reflexivity. Qed.

(* x=4, y=7 代入书中表达式 (5+(2x))−((y−3)+(2+x)) = 13 − 16 = −3：
   nat 不够用，改乘法版验证栈机语义 *)
Example cert_polish2 :
  evalPostfix [5; 2; 4; 102; 100] [] = Some 13.
Proof. vm_compute. reflexivity. Qed.

