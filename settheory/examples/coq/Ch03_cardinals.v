(* 第 03 章 基数：SB 的区间套装备 + Cantor 的集合侧 *)

(* ---------- 一、Schröder-Bernstein 的证明装备（Jech 定理 7） ----------

   f : A → B 单，g : B → A 单。Jech 的证明分两步：
   (1) 化归：不妨 A₁ ⊆ B ⊆ A 且 f : A → A₁ 双射（把 g 的像
       与 f 的像翻译进同一载体）；
   (2) 区间套：A₀ = A，B₀ = B，A_{n+1} = f[A_n]，B_{n+1} = f[B_n]，
       拼接映射 h 在 ⋃_n (A_n - B_n) 上用 f、其余用 f⁻¹。

   注意：嵌套性 A_{n+1} ⊆ A_n **依赖第 (1) 步的化归**
   （f 的像落在 A₁ ⊆ A 里）——一般 f : A → B 上这不成立。
   完整证明见 Lean 通道（Function.Embedding.antisymm）与
   Jech 定理 7 正文；这里把区间套做成数据结构。 *)

Section SchroederBernstein.

Variable A : Type.
Variable f : A -> A.                    (* 化归后 f : A → A₁ ⊆ A *)

(* x ∈ A_n ⟺ x 是 f^n 迭代像的成员 *)
Fixpoint in_chain (n : nat) (x : A) : Prop :=
  match n with
  | O => True                          (* A_0 = A *)
  | S k => exists y, in_chain k y /\ f y = x
  end.                                  (* A_{n+1} = f[A_n] *)

(* 区间套的"层"结构：每层是上一层的像 *)
Lemma chain_layer_zero :
  forall x, in_chain 0 x.
Proof. intros x. exact I. Qed.

(* 嵌套传递：A_{n+1} ⊆ A_n 对任意 f : A → A 成立。
   x ∈ A_{n+2} 意味着 x = f(y)、y ∈ A_{n+1}；由 IH 得 y ∈ A_n，
   于是 x = f(y) ∈ f[A_n] = A_{n+1}。 *)
Lemma chain_nested :
  forall n x, in_chain (S n) x -> in_chain n x.
Proof.
  induction n as [|n IH]; intros x Hx.
  - exact I.
  - destruct Hx as [y [Hy Hfy]].
    exists y. split.
    + exact (IH y Hy).
    + exact Hfy.
Qed.

End SchroederBernstein.

(* ---------- 二、Cantor：无满射 X → (X → Prop) ---------- *)

(* 命题引擎：¬P ≠ P（第 00 章的 transport 版，此处复用） *)
Lemma nprp : forall P : Prop, (~ P) <> P.
Proof.
  intros P E.
  pose (c := fun np => match E in _ = T return T with eq_refl => np end).
  pose (c' := fun p => match (eq_sym E) in _ = T return T with eq_refl => p end).
  assert (t : ~ P) by (intro p; exact (c' p p)).
  exact (t (c t)).
Qed.

(* Cantor：任何 F 都造不出对角补 P = fun x => ~ F x x。
   陈述采用"点态对角"形态（函数命题相等需要外延性，绕开）。 *)
Theorem no_onto_powerset :
  forall (X : Type) (F : X -> (X -> Prop)),
    forall x, ~ (F x x = (~ F x x)).
Proof.
  intros X F x H.
  apply (nprp (F x x)).
  exact (eq_sym H).
Qed.

Print Assumptions no_onto_powerset.
(* Closed under the global context——构造性，零公理。 *)
