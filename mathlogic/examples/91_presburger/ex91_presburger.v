(* ex91_presburger.v —— 简化版本的自然数模型（郝 ch8）Coq 侧账本
   与 Prolog 通道（消去器本体+对拍）互补，这里证「断言」的语义核心：
   8.3.1 的 S-消去账（注入性/无圈/bump 等价）、8.4.1 的 min-见证等价、
   D1 奇偶账、习题 8.5.7 加法在 (N,S,×) 中可定义的恒等式、以及
   「(S1)+(S2) 无有限模型」的鸽笼账（ℤ-链必须无穷——引理 8.3.1
   的另一条腿）。 *)

From Stdlib Require Import List Arith Lia Psatz.
Import ListNotations.

(* ---------- 1. 定理 8.3.1 的断言账：L_s = {0,S} ---------- *)

(* S-消去第一步：注入性可以约去公共的 S 层（公理 (S2) 的账） *)
Lemma Scancel : forall k x y, x + k = y + k -> x = y.
Proof. intros; lia. Qed.

(* 无圈：S^k x ≠ x（公理模式 (S4.n) 的语义账——标准 ℕ 上成立，
   非标准模型上由模式逐条封死「有限圈」的可能） *)
Lemma no_cycle : forall k x, x + S k <> x.
Proof. intros; lia. Qed.

(* 断言 3 的语义核（bump 引理）：∃x 的解出条件 *)
Lemma bump_sem : forall k m t u,
  (exists x, x + k = t /\ x + m = u) <-> (t + m = u + k /\ k <= t).
Proof.
  intros; split.
  - intros [x [H1 H2]]; split; lia.
  - intros [H1 H2]; exists (t - k); lia.
  Qed.

(* ---------- 2. 定理 8.4.1 断言 4/5 的语义核：min-见证 ---------- *)

(* 双侧夹界：δ₃ = S w < u 的形状（书的断言 5） *)
Lemma min_witness : forall w u,
  (exists x, w < x /\ x < u) <-> (S w < u).
Proof.
  intros; split.
  - intros [H1 H2]; lia.
  - intro H; exists (S w); lia.
  Qed.

(* 断言 4（无下界子情形）：ℕ 中 x:=0 见证 *)
Lemma zero_witness : forall u,
  (exists x, x < u) <-> (S 0 <= u).
Proof.
  intros; split.
  - intros [H]; lia.
  - intro H; exists 0; lia.
  Qed.

(* ---------- 3. D1 奇偶账（Prolog 通道 D1 的 Coq 镜像） ---------- *)

Lemma even_or_odd : forall x,
  (exists y, y + y = x) \/ (exists y, S (y + y) = x).
Proof.
  induction x as [| x IH].
  - left; exists 0; reflexivity.
  - destruct IH as [[y H] | [y H]].
    + right; exists y; lia.
    + left; exists (S y); simpl; lia.
  Qed.

(* ---------- 4. 习题 8.5.7：加法在 (N,S,×) 中可定义 ---------- *)

(* 展开账：S(ac)·S(bc) = S(c²·S(ab)) ⟺ c·(a+b) = c·c *)
Lemma id857_core : forall a b c,
  (a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 <-> c * (a + b) = c * c.
Proof.
  intros a b c; split; intro H; nia.
Qed.

(* 主定理：方程 ⟺ c = 0 ∨ a + b = c（c≠0 侧即加法图；c=0 行是
   「对任意 a,b 都满足」的噪声——定义公式需配 c≠0 边条件，见
   docs/91-presburger.md 的账） *)
Lemma id857 : forall a b c,
  (a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 <-> (c = 0 \/ a + b = c).
Proof.
  intros a b c; split.
  - intro Heq.
    assert (Hc : c * (a + b) = c * c) by (apply (proj1 (id857_core a b c)); exact Heq).
    destruct (Nat.eq_dec c 0) as [Hz | Hnz]; [now left | right; nia].
  - intros [Hz | Hab].
    + rewrite Hz; ring.
    + apply (proj2 (id857_core a b c)); rewrite <- Hab; nia.
Qed.

(* 样本行：a=1,b=1,c=2（书例网格的一格：9 = 9） *)
Example id857_sample : (1 * 2 + 1) * (1 * 2 + 1) = 2 * 2 * (1 * 1 + 1) + 1.
Proof. reflexivity. Qed.

(* ---------- 5. 鸽笼账：(S1)+(S2) 杀死全部有限模型 ---------- *)

(* 单射函数保序表列的无重复性（自证小件，替代 Stdlib 名字漂移） *)
Lemma NoDup_map_seq : forall n s (f : nat -> nat),
  (forall i j, s <= i -> i < s + n -> s <= j -> j < s + n -> f i = f j -> i = j) ->
  NoDup (map f (seq s n)).
Proof.
  intros n; induction n as [| n IH]; intros s f Hinj; simpl.
  - constructor.
  - constructor.
    + intro Hin. apply in_map_iff in Hin. destruct Hin as [x [Hfx Hx]].
      apply in_seq in Hx.
      assert (x = s) by (apply Hinj; [lia | lia | lia | lia | exact Hfx]). lia.
    + apply IH. intros i j Hi1 Hi2 Hj1 Hj2 Hf. apply Hinj; [lia | lia | lia | lia | exact Hf].
  Qed.

(* ℤ-链必须无穷：有限域上「全函数+单射+0 不是后继」不可能——
   Prolog 通道 zchain_shadow 的 (b) 账的定理化 *)
Theorem no_finite_successor : forall n (f : nat -> nat),
  0 < n ->
  (forall i, i < n -> f i < n) ->
  (forall i, i < n -> f i <> 0) ->
  ~ (forall i j, i < n -> j < n -> f i = f j -> i = j).
Proof.
  intros n f Hn Hbnd Hzero Hinj.
  assert (Hnd : NoDup (map f (seq 0 n))).
  { apply (NoDup_map_seq n 0 f). intros i j Hi Hj Hf; apply Hinj; lia. }
  assert (Hincl : incl (map f (seq 0 n)) (seq 1 (n - 1))).
  { intros y Hy. apply in_map_iff in Hy. destruct Hy as [x [Heq Hx]].
    apply in_seq in Hx. destruct Hx as [_ Hxb].
    apply in_seq. destruct n as [| n']; [lia | ].
    assert (Hfx : f x < S n') by (apply Hbnd; lia).
    assert (Hne : f x <> 0) by (apply Hzero; lia).
    lia. }
  assert (Hlen := NoDup_incl_length Hnd Hincl).
  rewrite !length_map, !length_seq in Hlen. lia.
Qed.
