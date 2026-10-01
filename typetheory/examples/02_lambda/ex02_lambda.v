(* ============================================================ *)
(* 02 无类型 λ 演算 —— Coq 镜像实现（与 ex02_lambda.lean 同构）  *)
(* de Bruijn 项 + 代换/平移 + 左外 β-归约 + Church 算术实测     *)
(* ============================================================ *)

Require Import List Arith ZArith.
Import ListNotations.

(* ---- 项：变量是 de Bruijn 指标 ---- *)
Inductive term : Type :=
| var : nat -> term
| lam : term -> term
| app : term -> term -> term.

(* ---- 平移：指标 >= c 的自由变量平移 d（β 里要移进/移出绑定器） ---- *)
Fixpoint shift (d : Z) (c : nat) (t : term) : term :=
  match t with
  | var k => if Nat.leb c k then var (Z.to_nat (Z.of_nat k + d)) else var k
  | lam b => lam (shift d (S c) b)
  | app f a => app (shift d c f) (shift d c a)
  end.

(* ---- 代换 [j := s]t：无捕获，de Bruijn 的回报 ---- *)
Fixpoint subst (j : nat) (s t : term) : term :=
  match t with
  | var k => if Nat.eqb k j then s else var k
  | lam b => lam (subst (S j) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)
  end.

(* ---- β 单步：最左最外优先（normal order） ---- *)
Fixpoint step (t : term) : option term :=
  match t with
  | app (lam b) a => Some (shift (-1) 0 (subst 0 (shift 1 0 a) b))
  | app f a =>
      match step f with
      | Some f' => Some (app f' a)
      | None => option_map (fun a' => app f a') (step a)
      end
  | lam b => option_map lam (step b)
  | _ => None
  end.

Fixpoint normalizeFuel (fuel : nat) (t : term) : term :=
  match fuel with
  | 0 => t
  | S n => match step t with
           | None => t
           | Some t' => normalizeFuel n t'
           end
  end.

(* ---- Church 数 ---- *)
Fixpoint iter (n : nat) (s z : term) : term :=
  match n with
  | 0 => z
  | S n => app s (iter n s z)
  end.

Definition cnum (n : nat) : term := lam (lam (iter n (var 1) (var 0))).

(* λm n f x. ((m f) ((n f) x)) —— 加法 *)
Definition cplus : term :=
  lam (lam (lam (lam (
    app (app (var 3) (var 1)) (app (app (var 2) (var 1)) (var 0)))))).

(* λm n f. (m (n f)) —— 乘法 *)
Definition cmul : term :=
  lam (lam (lam (app (var 2) (app (var 1) (var 0))))).

(* λm n. (n m) —— 乘幂 *)
Definition cexp : term := lam (lam (app (var 0) (var 1))).

(* ---- 解码：λλ. fⁿ x --> n ---- *)
Fixpoint countApps (t : term) : option nat :=
  match t with
  | app (var 1) (var 0) => Some 1
  | app (var 1) rest => option_map S (countApps rest)
  | _ => None
  end.

Definition decodeCnum (t : term) : option nat :=
  match t with lam (lam b) => countApps b | _ => None end.

(* ---- 实测：Church 算术（vm_compute 快速走完归约） ---- *)
Example add23 : decodeCnum (normalizeFuel 200 (app (app cplus (cnum 2)) (cnum 3)))
              = Some 5.
Proof. vm_compute. reflexivity. Qed.

Example mul23 : decodeCnum (normalizeFuel 200 (app (app cmul (cnum 2)) (cnum 3)))
              = Some 6.
Proof. vm_compute. reflexivity. Qed.

Example exp23 : decodeCnum (normalizeFuel 500 (app (app cexp (cnum 2)) (cnum 3)))
              = Some 8.
Proof. vm_compute. reflexivity. Qed.

(* ---- S K K = I ---- *)
Definition K : term := lam (lam (var 1)).
Definition S : term :=
  lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0))))).

Example skk : normalizeFuel 100 (app (app S K) K) = lam (var 0).
Proof. vm_compute. reflexivity. Qed.

(* ---- Ω：一步归约回到自身 ---- *)
Definition omega : term := lam (app (var 0) (var 0)).
Definition Omega : term := app omega omega.

Example omega_step : step Omega = Some Omega.
Proof. vm_compute. reflexivity. Qed.

(* ---- 无捕获代换的经典现场：(λx. λy. x) z → λw. z ----
   z 是自由变量（指标 0），移进 λy 时 shift 到 1；
   若不做 shift，x 会被 λy 捕获，错得 λy. y *)
Example subst_demo : step (app (lam (lam (var 1))) (var 0)) = Some (lam (var 1)).
Proof. vm_compute. reflexivity. Qed.
