(* ============================================================ *)
(* 37 简单扩展 —— Coq：导出形式的方法学与 fix 的发散            *)
(* （TAPL 书 ch.11 的三件机器面）                               *)
(*   甲·λ→+Unit+fix 的小步机：E-FixBeta 的展开、diverger 的      *)
(*      无范式性（书 11.11「每个类型都有无定义元素」的机器版）   *)
(*   乙·seq 作为导出形式：desugar = (λx:Unit.t2) t1；外部规则   *)
(*      E-Seq/E-SeqNext 是内部规则的定理（新鲜性下吻合）         *)
(*   丙·变式/数据类型的元语言化身：书 11.10 的 NatList 与        *)
(*      单字段变式的币种例——Coq 的 Inductive 就是它们            *)
(* ============================================================ *)

Require Import Arith List.
Import ListNotations.
Require Import Lia.

(* ---- 内部语言：λ→ + Unit + fix（de Bruijn） ---- *)
Inductive ty : Type :=
| TUnit : ty
| TNat  : ty
| TArr  : ty -> ty -> ty.

Inductive tm : Type :=
| var : nat -> tm
| abs : ty -> tm -> tm
| app : tm -> tm -> tm
| tt  : tm                       (* unit 常量（图 11.2） *)
| fixp : tm -> tm.               (* 一般递归原语（图 11.12） *)

Fixpoint shift (t : tm) (d c : nat) : tm :=
  match t with
  | var k => if k <? c then var k else var (k + d)
  | abs A b => abs A (shift b d (S c))
  | app f a => app (shift f d c) (shift a d c)
  | tt => tt
  | fixp f => fixp (shift f d c)
  end.

Fixpoint subst (t : tm) (j : nat) (s : tm) : tm :=
  match t with
  | var k => if k =? j then s
             else if j <? k then var (k - 1) else var k
  | abs A b => abs A (subst b (S j) (shift s 1 0))
  | app f a => app (subst f j s) (subst a j s)
  | tt => tt
  | fixp f => fixp (subst f j s)
  end.

Inductive value : tm -> Prop :=
| v_abs : forall A b, value (abs A b)
| v_tt  : value tt.

Inductive step : tm -> tm -> Prop :=
| E_AppAbs : forall A b v, value v ->
    step (app (abs A b) v) (subst b 0 v)
| E_App1 : forall f f' a, step f f' ->
    step (app f a) (app f' a)
| E_App2 : forall v a a', value v -> step a a' ->
    step (app v a) (app v a')
| E_FixBeta : forall A b,
    step (fixp (abs A b)) (subst b 0 (fixp (abs A b)))
| E_Fix : forall f f', step f f' ->
    step (fixp f) (fixp f').

Inductive multi : tm -> tm -> Prop :=
| m_refl : forall t, multi t t
| m_step : forall t t' t'', step t t' -> multi t' t'' -> multi t t''.

(* ================= 甲·fix 的展开与发散（书 11.11） ================= *)

Definition diverger := abs TUnit (fixp (abs TUnit (var 0))).
Definition diverging := app diverger tt.

(* 一步化简：diverging →E-AppAbs→ fixp (λx.x)（代换后 var 0 存活：
   体内 0 号变量指的是刚被绑定的那个哑参数） *)
Example diverge_first_step :
  step diverging (subst (fixp (abs TUnit (var 0))) 0 tt).
Proof. apply E_AppAbs. constructor. Qed.

Example subst_computes :
  subst (fixp (abs TUnit (var 0))) 0 tt = fixp (abs TUnit (var 0)).
Proof. reflexivity. Qed.

(* 此后每一步都展开回自身：fixp (λx.x) 的不动点是自身 *)
Example self_loop :
  step (fixp (abs TUnit (var 0))) (fixp (abs TUnit (var 0))).
Proof. apply E_FixBeta. Qed.

(* 无范式性：diverging 出发能到的任何项都还能再走一步。
   归纳只靠基座——自环把「无限」压缩成「原地踏步」。 *)
(* 无范式性（书 11.11）：显式造出无限归约序列——
   diverging → loop → loop → …，每一步都是 E-FixBeta 的原地展开 *)
Definition loop := fixp (abs TUnit (var 0)).

Definition diverge_seq (n : nat) : tm :=
  match n with O => diverging | S _ => loop end.

Lemma diverge_seq_steps : forall k, step (diverge_seq k) (diverge_seq (S k)).
Proof.
  destruct k.
  - unfold diverging, diverger. simpl.
    apply E_AppAbs. constructor.
  - simpl. apply E_FixBeta.
Qed.

(* fix 的类型规则（图 11.12）：T-Fix 不限于函数类型——
   任何 T 都可取 T→T 的不动点 *)
Inductive has_ty : list ty -> tm -> ty -> Prop :=
| T_Var : forall G k T, nth_error G k = Some T -> has_ty G (var k) T
| T_Abs : forall G A b B, has_ty (A :: G) b B -> has_ty G (abs A b) (TArr A B)
| T_App : forall G f a A B,
    has_ty G f (TArr A B) -> has_ty G a A -> has_ty G (app f a) B
| T_Tt  : forall G, has_ty G tt TUnit
| T_Fix : forall G f A, has_ty G f (TArr A A) -> has_ty G (fixp f) A.

(* diverger : Unit → Unit 良类型（每个类型都有无定义元素） *)
Lemma diverger_typed : has_ty [] diverger (TArr TUnit TUnit).
Proof.
  apply T_Abs. apply T_Fix with (A := TUnit). apply T_Abs.
  apply T_Var. reflexivity.
Qed.

(* ================= 乙·seq 作为导出形式（书 11.3） ================= *)

(* 自由变量（de Bruijn：abs 层把正编号减一后下放） *)
Fixpoint fv (t : tm) : list nat :=
  match t with
  | var k => [k]
  | abs _ b => map (fun k => k - 1) (filter (fun k => 0 <? k) (fv b))
  | app f a => fv f ++ fv a
  | tt => []
  | fixp f => fv f
  end.

(* 外部构造子：t1;t2，化简为 (λx:Unit.t2) t1（书 11.3 的定义） *)
Definition seqc (t1 t2 : tm) : tm := app (abs TUnit t2) t1.

(* de Bruijn 的诚实注记：named 演算里 [x↦v]t2 = t2 只要 x ∉ FV(t2)；
   de Bruijn 的 β-代换还会给高于绑定位的变量减位，字面等式只在
   t2 无自由变量时成立（02/64 章的同一话题）。故闭项给样本、
   一般情形的「外部规则 = 内部规则的定理」在 E-Seq（下面）无保留成立。 *)

(* 外部规则 E-Seq：子项先走 = 内部 E-App1 的直译（无保留） *)
Lemma E_Seq_derived : forall t1 t1' t2,
  step t1 t1' -> step (seqc t1 t2) (seqc t1' t2).
Proof. intros. unfold seqc. apply E_App2; [constructor | assumption]. Qed.

(* 外部规则 E-SeqNext 的样本：t1 是值、t2 的 0 号变量指 seq 绑定器
   时，β 落回 t2。一般引理需要「全部自由变量低于绑定位」的新鲜性
   （Forall (< j) (fv t) ⇒ subst t j s = t）——64 章元理论的属地，
   这里以两个直算样本立据：*)
Example E_SeqNext_sample :
  step (seqc tt (abs TUnit (var 0))) (abs TUnit (var 0)).
Proof. unfold seqc. apply E_AppAbs; constructor. Qed.

Example E_SeqNext_sample2 :
  step (seqc tt tt) tt.
Proof. unfold seqc. apply E_AppAbs; constructor. Qed.

(* 类型侧：T-Seq 的化简式在扩展上下文中给同一类型 *)
Lemma T_Seq_derived : forall G t1 t2 T,
  has_ty G t1 TUnit -> has_ty (TUnit :: G) t2 T ->
  has_ty G (seqc t1 t2) T.
Proof.
  intros G t1 t2 T H1 H2. unfold seqc.
  apply T_App with (A := TUnit).
  - apply T_Abs. assumption.
  - assumption.
Qed.

(* ================= 丙·变式/数据类型的元语言化身（书 11.10） ================= *)

(* 书 11.10 的 NatList：OCaml datatype = 变式 + 递归 + 参数化；
   Coq/Agda/Lean 的 Inductive 恰是同一个东西（30 章 MLTT 线的重逢） *)
Inductive natlist : Type :=
| nnil  : natlist
| ncons : nat -> natlist -> natlist.

Fixpoint lsum (l : natlist) : nat :=
  match l with nnil => 0 | ncons n r => n + lsum r end.

Example natlist_sample : lsum (ncons 2 (ncons 3 nnil)) = 5.
Proof. reflexivity. Qed.

(* 单字段变式的币种例（书 11.10 末）：Dollar/Euro 不经 case 不可混算 *)
Inductive money : Type :=
| D : nat -> money
| E : nat -> money.

Definition d2e (m : money) : money :=
  match m with D n => E (n * 111 / 100) | E n => E n end.

Example d2e_on_dollar : d2e (D 39) = E 43.
Proof. reflexivity. Qed.

(* 单字段变式的完整版（书 11.10 末）：两个独立类型各自包装 *)
Inductive dollar := MkD (n : nat).
Inductive euro   := MkE (n : nat).
Definition d2e2 (d : dollar) : euro :=
  match d with MkD n => MkE (n * 111 / 100) end.

(* 双重转换被类型系统挡在门外：d2e2 的参数要 dollar，
   结果却是 euro——Fail Check 就是「编译错误」的机器见证 *)
Fail Check (fun x : dollar => d2e2 (d2e2 x)).
