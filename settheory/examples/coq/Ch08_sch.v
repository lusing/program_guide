(* 第 08 章 奇异基数：几乎不交族的构造与计数 *)

Require Import Arith Lia Lists.List.

(* ---------- 一、几乎不交函数族（Jech §8 的核心组合对象） ----------
   f, g : I → Ord 几乎不交 ⟺ 除有界多处外 f(α) ≠ g(α)。
   Silver 证明链的最底层（引理 8.5/8.4/8.7）全部围绕"几乎不交
   族的计数上界"展开。有限版：除有限多处外不同。 *)

Definition almost_disjoint (f g : nat -> nat) : Prop :=
  exists B, forall i, B <= i -> f i <> g i.

(* 常值函数族是几乎不交的 *)
Lemma const_family_ad :
  forall (u v : nat -> nat),
    (forall i, u i <> v i) -> almost_disjoint u v.
Proof.
  intros u v H. exists 0. intros i _. apply H.
Qed.

(* 两个不同的常值函数几乎不交 *)
Example const_ad_example :
  almost_disjoint (fun _ => 3) (fun _ => 7).
Proof.
  apply const_family_ad. intros _. discriminate.
Qed.

(* 切片分离构造（f_X 与 f_Y 在 max(X△Y) 后分离）的语义：
   不同的 X、Y 给出几乎不交的切片族——这是引理 8.4 从
   "几乎不交族有界"推出 "2^{ω₁} 有界"的桥。完整形式化由
   Agda（ad-slices）与 Prolog（almost_disjoint）通道承载。 *)

(* ---------- 二、SCH 的陈述（语义框架） ---------- *)

(* SCH：对每个奇异基数 κ，若 2^{cf κ} < κ，则 κ^{cf κ} = κ⁺。
   其独立性（Magidor：大基数下 SCH 可失败）是第 33 章的故事。 *)

