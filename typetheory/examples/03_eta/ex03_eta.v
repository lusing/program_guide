(* ============================================================ *)
(* 03 η、βη 与 λI —— Coq 镜像实现（与 ex03_eta.lean 同构）      *)
(* η-步进 + βη 两阶段 + λI 谓词 + 消元/复制对照                 *)
(* 依 Hindley BSTT 1C-1D                                        *)
(* ============================================================ *)

Require Import List Arith ZArith.
Import ListNotations.

(* ---- 项与 β 机器：与 02 章同一套（自包含复制） ---- *)
Inductive term : Type :=
| var : nat -> term
| lam : term -> term
| app : term -> term -> term.

Fixpoint shift (d : Z) (c : nat) (t : term) : term :=
  match t with
  | var k => if Nat.leb c k then var (Z.to_nat (Z.of_nat k + d)) else var k
  | lam b => lam (shift d (S c) b)
  | app f a => app (shift d c f) (shift d c a)
  end.

Fixpoint subst (j : nat) (s t : term) : term :=
  match t with
  | var k => if Nat.eqb k j then s else var k
  | lam b => lam (subst (S j) (shift 1 0 s) b)
  | app f a => app (subst j s f) (subst j s a)
  end.

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

Fixpoint nfBeta (fuel : nat) (t : term) : term :=
  match fuel with
  | 0 => t
  | S n => match step t with
           | None => t
           | Some t' => nfBeta n t'
           end
  end.

(* ---- η 层：occurs 检查 + 最左外 η 单步 ----
   contractum 是 shift (-1) 0 t：t 的自由指标全体 >= 1（0 被 λ 用掉），
   出绑定器后必须降 1——与 β 的出口平移同款，只是入口无须代换。 *)
Fixpoint occurs (k : nat) (t : term) : bool :=
  match t with
  | var j => Nat.eqb j k
  | lam b => occurs (S k) b
  | app f a => orb (occurs k f) (occurs k a)
  end.

Fixpoint eta_step (t : term) : option term :=
  match t with
  | lam b =>
      (* 先看整体是否 η-redex；不是（或 occurs 拦下）再递归进体内。
         递归参数是直接子项 b——Coq 守卫检查器不认嵌套模式的
         「重建子项」app u (var 0)，只认结构子项。 *)
      match b with
      | app u (var 0) =>
          if occurs 0 u then option_map lam (eta_step b)
          else Some (shift (-1) 0 u)
      | _ => option_map lam (eta_step b)
      end
  | app f a =>
      match eta_step f with
      | Some f' => Some (app f' a)
      | None => option_map (fun a' => app f a') (eta_step a)
      end
  | _ => None
  end.

Fixpoint nfEta (fuel : nat) (t : term) : term :=
  match fuel with
  | 0 => t
  | S n => match eta_step t with
           | None => t
           | Some t' => nfEta n t'
           end
  end.

(* βη 两阶段（Hindley 1C9.5）：先 β 后 η *)
Definition nfBetaEta (fuel : nat) (t : term) : term := nfEta fuel (nfBeta fuel t).

Fixpoint eta_steps_aux (fuel : nat) (t : term) (k : nat) : nat :=
  match fuel with
  | 0 => k
  | S n => match eta_step t with
           | None => k
           | Some t' => eta_steps_aux n t' (S k)
           end
  end.

Definition eta_steps (fuel : nat) (t : term) : nat := eta_steps_aux fuel t 0.

Fixpoint size (t : term) : nat :=
  match t with
  | var _ => 1
  | lam b => S (size b)
  | app f a => S (size f + size a)
  end.

(* ---- λI 谓词：每个绑定器都被使用（Church 1941 原版） ---- *)
Fixpoint isLI (t : term) : bool :=
  match t with
  | var _ => true
  | lam b => andb (occurs 0 b) (isLI b)
  | app f a => andb (isLI f) (isLI a)
  end.

(* ---- Church 数（iter 须在组合子 S 之前定义：S 会遮蔽 nat 后继） ---- *)
Fixpoint iter (n : nat) (s z : term) : term :=
  match n with
  | 0 => z
  | S n => app s (iter n s z)
  end.

Definition cnum (n : nat) : term := lam (lam (iter n (var 1) (var 0))).

(* ---- 名角 ---- *)
Definition I := lam (var 0).
Definition K := lam (lam (var 1)).
Definition S := lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0))))).
Definition omega := lam (app (var 0) (var 0)).

(* ---- 实测一：η 基本功 ---- *)
Example eta_basic : eta_step (lam (app (var 1) (var 0))) = Some (var 0).
Proof. vm_compute. reflexivity. Qed.

Example omega_is_eta_nf : eta_step omega = None.
Proof. vm_compute. reflexivity. Qed.

Example K_not_LI : isLI K = false.
Proof. vm_compute. reflexivity. Qed.

Example S_is_LI : isLI S = true.
Proof. vm_compute. reflexivity. Qed.

Example omega_is_LI : isLI omega = true.
Proof. vm_compute. reflexivity. Qed.

Example cnum3_is_LI : isLI (cnum 3) = true.
Proof. vm_compute. reflexivity. Qed.

Example cnum0_not_LI : isLI (cnum 0) = false.
Proof. vm_compute. reflexivity. Qed.

(* ---- 实测二：β/η 两条路在 F 汇合 ---- *)
Definition F := lam (app (var 1) (var 0)).            (* λy. f y *)
Definition N2 := lam (app (shift 1 0 F) (var 0)).     (* λx. (λy. f y) x *)

Example eta_first : eta_step N2 = Some F.
Proof. vm_compute. reflexivity. Qed.

Example beta_first : step N2 = Some F.
Proof. vm_compute. reflexivity. Qed.

Example eta_F : eta_step F = Some (var 0).
Proof. vm_compute. reflexivity. Qed.

Example nf_N2 : nfBetaEta 50 N2 = var 0.
Proof. vm_compute. reflexivity. Qed.

Example nf_Ix : nfBetaEta 50 (lam (app I (var 0))) = I.
Proof. vm_compute. reflexivity. Qed.

Example eta_chain_len : eta_steps 50 N2 = 2.
Proof. vm_compute. reflexivity. Qed.

Example size_N2 : size N2 = 7.
Proof. vm_compute. reflexivity. Qed.

(* ---- 实测三：λI 不消元 / λK 消元 ---- *)
Definition selfApp := app (lam (app (var 0) (var 0))) (var 1).

Example selfApp_step : step selfApp = Some (app (var 1) (var 1)).
Proof. vm_compute. reflexivity. Qed.

Example selfApp_keep : occurs 1 (app (var 1) (var 1)) = true.
Proof. vm_compute. reflexivity. Qed.

Definition swallow := app (lam (lam (var 0))) (var 3).

Example swallow_step : step swallow = Some (lam (var 0)).
Proof. vm_compute. reflexivity. Qed.

Example swallow_loses : occurs 3 (lam (var 0)) = false.
Proof. vm_compute. reflexivity. Qed.

Example swallow_not_LI : isLI (lam (lam (var 0))) = false.
Proof. vm_compute. reflexivity. Qed.

(* ---- 实测四：λI 对 βη 封闭（实例账） ---- *)
Example SII_reduces : nfBetaEta 100 (app (app S I) I) = omega.
Proof. vm_compute. reflexivity. Qed.

Example SII_stays_LI : isLI (nfBetaEta 100 (app (app S I) I)) = true.
Proof. vm_compute. reflexivity. Qed.
