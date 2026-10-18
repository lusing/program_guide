(* ex24 —— 截面与三个超幂函子（Simmons 6.5）
   三书对位：Simmons 6.3-6.6 /《高级范畴论》1.7 / 06 章幂集三兄弟。

   三元素链 0 ≤ 1 ≤ 2、单调 phi : x ↦ min(x+1, 2)。
   ∃(phi) = 直接像下闭包；I(phi) = 逆像；∀(phi) = 对偶像。
   伴随串 ∃(phi) ⊣ I(phi) ⊣ ∀(phi)：两条包含等式各 64 格穷尽。 *)

Inductive Ch3 : Set := c0 | c1 | c2.

Definition phi (x : Ch3) : Ch3 :=
  match x with c0 => c1 | c1 => c2 | c2 => c2 end.

Definition leC : Ch3 -> Ch3 -> bool :=
  fun x y =>
    match x, y with
    | c0, _ => true
    | c1, c1 => true | c1, c2 => true
    | c2, c2 => true
    | _, _ => false
    end.

(* 谓词包含：三点逐一 implb *)
Definition inclP (X Y : Ch3 -> bool) : bool :=
  andb (implb (X c0) (Y c0))
    (andb (implb (X c1) (Y c1)) (implb (X c2) (Y c2))).

(* ∃(phi)(X) := ⋃{ ↓phi(x) | x ∈ X } ——直接像 + 下闭包 *)
Definition existsF (X : Ch3 -> bool) : Ch3 -> bool :=
  fun s =>
    orb (andb (X c0) (leC s (phi c0)))
      (orb (andb (X c1) (leC s (phi c1)))
           (andb (X c2) (leC s (phi c2)))).

(* I(phi)(Y) := 逆像 *)
Definition invF (Y : Ch3 -> bool) : Ch3 -> bool :=
  fun t => Y (phi t).

(* ∀(phi)(X) := (⋃{ ↑phi(t) | t ∉ X })′ ——对偶像 *)
Definition allF (X : Ch3 -> bool) : Ch3 -> bool :=
  fun s =>
    negb (orb (andb (negb (X c0)) (leC (phi c0) s))
           (orb (andb (negb (X c1)) (leC (phi c1) s))
                (andb (negb (X c2)) (leC (phi c2) s)))).

(* 下闭截面判定：0 ≤ 1 ≤ 2 的闭包 = 三条蕴含 *)
Definition closedP (P : Ch3 -> bool) : bool :=
  andb (implb (P c1) (P c0))
    (andb (implb (P c2) (P c0)) (implb (P c2) (P c1))).

(* 伴随串左半：∃(phi)(X) ⊆ Y ⟺ X ⊆ I(phi)(Y)
   —— X、Y 须为下闭截面（否则有反例：Y 不闭则 ⟸ 不成立）；
   非闭组合被 closedP 假设的 discriminate 消灭。 *)
Lemma exists_left_adjoint : forall (X Y : Ch3 -> bool),
  closedP X = true -> closedP Y = true ->
  inclP (existsF X) Y = inclP X (invF Y).
Proof.
  intros X Y HX HY. unfold closedP in HX, HY.
  unfold inclP, existsF, invF. cbv.
  destruct (X c0), (X c1), (X c2), (Y c0), (Y c1), (Y c2);
    cbv in HX, HY; try discriminate; reflexivity.
Qed.

(* 伴随串右半：Y ⊆ ∀(phi)(X) ⟺ I(phi)(Y) ⊆ X —— 同款 *)
Lemma all_right_adjoint : forall (Y X : Ch3 -> bool),
  closedP Y = true -> closedP X = true ->
  inclP Y (allF X) = inclP (invF Y) X.
Proof.
  intros Y X HY HX. unfold closedP in HY, HX.
  unfold inclP, allF, invF. cbv.
  destruct (Y c0), (Y c1), (Y c2), (X c0), (X c1), (X c2);
    cbv in HY, HX; try discriminate; reflexivity.
Qed.

Print Assumptions exists_left_adjoint.
Print Assumptions all_right_adjoint.

(* 坑位速记：
   1. 谓词包含 implb 的三点合取顺序不影响结果——但与 existsF/
      allF 的析取顺序要对齐（c0/c1/c2 三段一致），否则穷尽格
      里出现「部分展开」的怪形状。
   2. 64 格 = 6 个布尔变量（X 三点 + Y 三点）；destruct 顺序
      无关紧要（都是独立变量），但漏一个就剩 meta 卡住。
   3. 伴随等式的「X 在左在右」写反会全红——幸运的可判定错误。 *)
