(* ============================================================ *)
(* 15 W 类型与良序 —— Coq 侧（与 Lean 版同构）                    *)
(* ============================================================ *)

Inductive Wt (A : Type) (B : A -> Type) : Type :=
| sup : forall a : A, (B a -> Wt A B) -> Wt A B.

Arguments sup {A B} a f.

(* ---- 编码一：三标签树 ---- *)

Inductive Tag : Set :=
| leaf | unary | binary.

Definition arity (t : Tag) : Type :=
  match t with
  | leaf => Empty_set
  | unary => unit
  | binary => bool
  end.

Definition Tree : Type := Wt Tag arity.

Definition lf : Tree := @sup Tag arity leaf (fun e => match e with end).
Definition nd1 (t : Tree) : Tree := sup unary (fun _ => t).
Definition nd2 (l r : Tree) : Tree :=
  @sup Tag arity binary (fun b => if b then l else r).

(* W 递归：Fixpoint 对「经 f 的递归调用」守卫检查过不去时，
   直接用生成的 Wt_rect（Type 版消去子）——良序归纳 *)
Arguments Wt_rect {A B}.

Definition size (t : Tree) : nat :=
  Wt_rect (fun _ => nat)
    (fun a f ih =>
      match a as a0 return (forall x : arity a0, nat) -> nat with
      | leaf => fun _ => 1
      | unary => fun ih1 => 1 + ih1 tt
      | binary => fun ih2 => 1 + ih2 true + ih2 false
      end ih)
    t.

Example size_lf : size lf = 1 := eq_refl.
Example size_nd2 : size (nd2 lf lf) = 3 := eq_refl.
Compute size (nd1 (nd2 lf (nd1 lf))).          (* 5 *)

(* ---- 编码二：ℕ = W Bool ---- *)

Definition arityN (b : bool) : Type :=
  match b with true => unit | false => Empty_set end.

Definition NatW : Type := Wt bool arityN.

Definition zw : NatW := @sup bool arityN false (fun e => match e with end).
Definition sw (n : NatW) : NatW := sup true (fun _ => n).

Definition toNatW (t : NatW) : nat :=
  Wt_rect (fun _ => nat)
    (fun b f ih =>
      match b as b0 return (forall x : arityN b0, nat) -> nat with
      | true => fun ih1 => 1 + ih1 tt
      | false => fun _ => 0
      end ih)
    t.

Example toNatW_3 : toNatW (sw (sw (sw zw))) = 3 := eq_refl.

(* W-ℕ 加法：后继链改接 *)
Fixpoint addW (m n : NatW) : NatW :=
  match m with
  | sup false _ => n
  | sup true f => sw (addW (f tt) n)
  end.

Example addW_23 : toNatW (addW (sw (sw zw)) (sw (sw (sw zw)))) = 5.
Proof. reflexivity. Qed.

(* ---- 良序注记：Wt_rect 打印出来就是 Noetherian 归纳 ---- *)
Print Wt_rect.




