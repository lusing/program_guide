(* ex23 —— 完备预序与剩余映射（Simmons 6.1/6.2）
   三书对位：Simmons 6.1.1 /《高级范畴论》1.6 / 贺伟 1.3。

   菱形（4 元布尔格）上：f(x) := x ∧ a 保全部 sup（分配律），
   按 6.1.1 的公式造出右伴随 g(y) := ⋁{x | f x ≤ y}，
   伴随定律 f(x) ≤ y ⟺ x ≤ g(y) 十六格穷尽。
   注：教科书直觉的 x ↦ x∨a 反而不保空 sup（f(⊥)=a≠⊥），
   没有 Right adjoint——「保 sup」必须含空 sup。 *)

Inductive Diam : Set := dBot | dL | dR | dTop.   (* ⊥ < a=dL, b=dR < ⊤ *)

Definition leD : Diam -> Diam -> bool :=
  fun x y =>
    match x, y with
    | dBot, _ => true
    | dL, dL => true | dL, dTop => true
    | dR, dR => true | dR, dTop => true
    | dTop, dTop => true
    | _, _ => false
    end.

(* sup 表：⋁ 任意两元 *)
Definition supD : Diam -> Diam -> Diam :=
  fun x y =>
    match x, y with
    | dBot, z => z
    | z, dBot => z
    | dL, dL => dL
    | dR, dR => dR
    | dTop, _ => dTop
    | _, dTop => dTop
    | _, _ => dTop        (* a 与 b 的 sup 是 ⊤ *)
    end.

(* inf 表：⋀ 任意两元 *)
Definition infD : Diam -> Diam -> Diam :=
  fun x y =>
    match x, y with
    | dTop, z => z
    | z, dTop => z
    | dBot, _ => dBot
    | _, dBot => dBot
    | dL, dL => dL
    | dR, dR => dR
    | _, _ => dBot        (* a 与 b 的 inf 是 ⊥ *)
    end.

(* f(x) := x ∧ a ——保全部 sup（含空 sup：f(⊥)=⊥） *)
Definition fMeet (x : Diam) : Diam := infD x dL.

(* g(y) := ⋁{x | f x ≤ y}，按公式查表算出的右伴随 *)
Definition gAdj (y : Diam) : Diam :=
  match y with
  | dBot => dR      (* {⊥, b} 的 sup *)
  | dL  => dTop     (* 全集的 sup *)
  | dR  => dR       (* {⊥, b} 的 sup *)
  | dTop => dTop
  end.

(* 伴随定律：f(x) ≤ y ⟺ x ≤ g(y) —— 十六格穷尽，零公理 *)
Lemma adjunction_law : forall x y,
  leD (fMeet x) y = leD x (gAdj y).
Proof. intros x y. destruct x, y; reflexivity. Qed.

(* f 单调 *)
Lemma fMeet_mono : forall x y, leD x y = true -> leD (fMeet x) (fMeet y) = true.
Proof. intros x y H. destruct x, y; simpl in *; try reflexivity; discriminate. Qed.

(* 保空 sup：f(⊥) = ⊥ = ⋁∅ *)
Example fMeet_bottom : fMeet dBot = dBot := eq_refl.

(* 保二元 sup：f(x ∨ y) = f(x) ∨ f(y) —— 六对组合 *)
Lemma fMeet_join : forall x y,
  fMeet (supD x y) = supD (fMeet x) (fMeet y).
Proof. intros x y. destruct x, y; reflexivity. Qed.

Print Assumptions adjunction_law.

(* 坑位速记：
   1. 「保 sup」的清单里藏着空 sup——x∨a 连右伴随都没有，
      样本要选 x∧a（分配格上 meet-with 保 join）。
   2. g 的表值由公式算出再「查表写出」——16 格伴随定律的
      穷尽验证就是 (2)⟹(1) 构造的可计算复述。
   3. leD 用 bool 而非 Prop/Le-族：瘦范畴的「同序」比较
      要 bool 相等（rfl 判定），Prop 值会拖进证明无关性。 *)

(* ---------- 闭包算子与闭元互同构（高级范畴论 5.1 定理 5.1.1/5.1.2） ----------
   最小非平凡现场：链 {0 ≤ 1}（Ch2，c0 < c1）。
   F := 常底（c0）、G := 常顶（c1）——F ⊣ G：两侧皆为恒真
   （F(a)=c0 ≤ b 恒真；a ≤ c1=G(b) 恒真）。四格查表。
   GF ≡ 1（闭包算子）：闭元集 A0 = {c1}；
   FG ≡ 0（开核算子）：开元集 B0 = {c0}；
   F 把闭元 c1 送到开元 c0 —— 定理 5.1.2 的最小化身。零公理。 *)

Inductive Ch2 : Set := c0 | c1.

Definition le2 : Ch2 -> Ch2 -> bool :=
  fun x y => match x, y with
             | c0, _ => true
             | c1, c1 => true
             | _, _ => false end.

Definition Fbot (a : Ch2) : Ch2 := c0.     (* 常底 *)
Definition Gtop (b : Ch2) : Ch2 := c1.     (* 常顶 *)

(* F ⊣ G：F(a) ≤ b ⟺ a ≤ G(b)——四格穷尽 *)
Lemma galois_pair : forall a b, le2 (Fbot a) b = le2 a (Gtop b).
Proof. intros a b; destruct a, b; reflexivity. Qed.

(* 闭包算子 GF ≡ 1：膨胀 + 幂等由常值白送 *)
Lemma gf_one : forall a, Gtop (Fbot a) = c1.
Proof. intros a; destruct a; reflexivity. Qed.

(* 开核算子 FG ≡ 0 *)
Lemma fg_zero : forall b, Fbot (Gtop b) = c0.
Proof. intros b; destruct b; reflexivity. Qed.

(* 闭元集 A0 = {c1}（GF(a) = a 的解）、开元集 B0 = {c0} *)
Definition closedA (a : Ch2) : bool :=
  match a with c1 => true | c0 => false end.

Lemma closedA_ok : forall a, closedA a = true -> Gtop (Fbot a) = a.
Proof. intros a H; destruct a; [discriminate|reflexivity]. Qed.

(* 定理 5.1.2：F 映闭元到开元、G 映开元到闭元、限制后互逆 *)
Lemma F_maps_closed : forall a, closedA a = true -> Fbot a = c0.
Proof. intros a H; destruct a; [discriminate|reflexivity]. Qed.

Lemma G_maps_open : Fbot c0 = c0 -> Gtop c0 = c1.
Proof. intros _; reflexivity. Qed.

(* F0 与 G0 的互逆：单点集之间的同构，refl 级 *)
Lemma F0_G0_inverse : Gtop (Fbot c1) = c1 /\ Fbot (Gtop c0) = c0.
Proof. split; reflexivity. Qed.
