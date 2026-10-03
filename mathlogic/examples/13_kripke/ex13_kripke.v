(* ex13 —— Kripke 语义：直觉主义不可证性的机器证据
   对书：Mints ch7 / Huth&Ryan §5.2（模态对应）

   两世界框架 W = {0, 1}（0 ≤ 1）：世界 0 无原子知识，
   世界 1 知道 p。强制关系按单调性定义。
   LEM（p ∨ ¬p）在世界 0 不被强制——「证不出」升级为「有反例」。

   旗舰两条（零公理）：
     monotone      w ≤ w' ⟹ (w ⊩ f → w' ⊩ f)
     lem_counter   世界 0 不强制 p ∨ ¬p —— LEM 在直觉逻辑无效 *)

Require Import List Bool Arith Lia.
Import ListNotations.

Inductive form : Type :=
| FVar : nat -> form
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FImp : form -> form -> form
| FBot : form.

(* ---------- Kripke 模型：两世界 + 原子知识 ---------- *)

(* 世界 0：无原子；世界 1：知道 p(0)。0 ≤ 1 *)
Definition val (w : nat) (n : nat) : bool :=
  match w with
  | 0 => false            (* 世界 0 什么都不知道 *)
  | S _ => match n with 0 => true | _ => true end
  end.

(* 世界序：0 ≤ 0, 0 ≤ 1, 1 ≤ 1 *)
Definition le' (w w' : nat) : Prop := w <= w' /\ w' <= 1.

(* ---------- 强制关系 ---------- *)

Fixpoint forces (w : nat) (f : form) : Prop :=
  match f with
  | FVar n => val w n = true
  | FAnd a b => forces w a /\ forces w b
  | FOr a b => forces w a \/ forces w b
  | FImp a b => forall w', (w <= w' /\ w' <= 1) ->
                  forces w' a -> forces w' b
  | FBot => False
  end.

(* ---------- 单调性引理 ---------- *)

Lemma val_mono : forall w w' n,
  w <= w' -> w' <= 1 -> val w n = true -> val w' n = true.
Proof.
  intros w w' n Hle H1 Hv.
  destruct n as [|n'];
  destruct w as [|[|w2]]; destruct w' as [|[|w2']]; simpl in *;
    try discriminate; try lia; try reflexivity; try (exfalso; lia).
Qed.

Theorem monotone : forall f w w',
  w <= w' -> w' <= 1 -> forces w f -> forces w' f.
Proof.
  induction f as [n|a IHa b IHb|a IHa b IHb|a IHa b IHb|];
    intros w w' Hle H1 Hf; simpl in *.
  - apply (val_mono w w' n); assumption.
  - destruct Hf as [Ha Hb]. split.
    + apply (IHa w w'); assumption.
    + apply (IHb w w'); assumption.
  - destruct Hf as [Ha | Hb].
    + left. apply (IHa w w'); assumption.
    + right. apply (IHb w w'); assumption.
  - intros w'' [Hle'1 Hle'2] Hfa.
    apply Hf with (w' := w'').
    + split; [lia | exact Hle'2].
    + exact Hfa.
  - exact Hf.
Qed.

(* ---------- 旗舰：LEM 的两世界反例 ---------- *)

Lemma lem_var0 : ~ forces 0 (FOr (FVar 0) (FImp (FVar 0) FBot)).
Proof.
  simpl. intros [Hv | Himp].
  - simpl in Hv. discriminate.
  - specialize (Himp 1 (conj (le_S 0 0 (le_n 0)) (Nat.le_refl 1))
                     eq_refl).
    exact Himp.
Qed.

(* 展示反例的读法：
   - 左支：世界 0 不知道 p——∨ 左不成立；
   - 右支：p → ⊥ 要求所有可达世界（含 1），而世界 1 知道 p——
     若 p→⊥ 在 0 被强制，喂它世界 1 的 p 证据得 ⊥。
   两支皆倒——世界 0 不强制 LEM。 *)

Print Assumptions monotone.  (* Closed *)
Print Assumptions lem_var0.  (* Closed *)

(* ---------- 框架条件与中间逻辑（文档钩子） ---------- *)

(* 排中律在框架 F 中有效 ⟺ R 是全序（Mints §7.3）；
   ¬¬p → p 有效 ⟺ R 对称（对应经典 S5 一侧）。
   两世界偏序框架恰是 LEM 的最小反例。 *)

(* 坑位速记（Coq 侧）：
   - forces 的 → 分支量词所有可达世界（含自身与未来）——
     Kripke 语义的「知识只增」要点；
   - Himp 1 ... 的世界 1 证据：le_S 0 0 (le_n 0) 构造 0≤1；
     le_n/lia 组合即可；
   - val 的世界 1 对一切 n 都 true（简化：只关心 p(0)）。 *)
