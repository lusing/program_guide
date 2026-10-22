(* 第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）
   典型代表元的整数构造（定义 1.36）+ 布劳威尔-克林序（例 1.18）。 *)
From Coq Require Import List Bool Arith Lia ZArith.
Import ListNotations.

(* ---------- 定义 1.36：整数 = 自然数 ∪ 负数对 (1,(m,1)) ---------- *)

Inductive bookZ : Type :=
| ZP (n : nat)            (* 非负整数：直接用自然数 *)
| ZN (m : nat).           (* 负整数：(1,(m,1))，绝对值 = m+1 *)

(* 序：负 < 非负；负按绝对值反序（书页 61 定义 1.36(3)） *)
Definition zle (x y : bookZ) : bool :=
  match x, y with
  | ZP a, ZP b => a <=? b
  | ZN a, ZN b => b <=? a
  | ZN _, ZP _ => true
  | ZP _, ZN _ => false
  end.

(* 加法（书页 61 定义 1.36(4) 四情形） *)
Definition zadd (x y : bookZ) : bookZ :=
  match x, y with
  | ZP a, ZP b => ZP (a + b)
  | ZN a, ZN b => ZN (S a + S b - 1)
  | ZP a, ZN b => if S b <? a then ZP (a - S b)
                  else if a =? S b then ZP 0
                  else ZN (S b - a - 1)
  | ZN a, ZP b => if S a <? b then ZP (b - S a)
                  else if b =? S a then ZP 0
                  else ZN (S a - b - 1)
  end.

(* 乘法（书页 62 定义 1.36(5) 四情形） *)
Definition zmul (x y : bookZ) : bookZ :=
  match x, y with
  | ZP a, ZP b => ZP (a * b)
  | ZN a, ZN b => ZP (S a * S b)
  | ZP a, ZN b => if a =? 0 then ZP 0 else ZN (a * S b - 1)
  | ZN a, ZP b => if b =? 0 then ZP 0 else ZN (S a * b - 1)
  end.

(* 与标准 ℤ 对拍：φ : bookZ → Z 保持加、乘与序 *)
Definition toZ (z : bookZ) : Z :=
  match z with ZP n => Z.of_nat n | ZN m => -Z.of_nat (S m) end.

Lemma zadd_sound : forall x y, toZ (zadd x y) = Z.add (toZ x) (toZ y).
Proof.
  intros [a|a] [b|b]; unfold zadd, toZ.
  - lia.
  - destruct (Nat.ltb_spec0 (S b) a) as [Hlt|Hge];
    destruct (Nat.eqb_spec a (S b)) as [Heq|Hne]; cbv iota; zify; lia.
  - destruct (Nat.ltb_spec0 (S a) b) as [Hlt|Hge];
    destruct (Nat.eqb_spec b (S a)) as [Heq|Hne]; cbv iota; zify; lia.
  - lia.
Qed.

Lemma zmul_sound : forall x y, toZ (zmul x y) = Z.mul (toZ x) (toZ y).
Proof.
  (* 不能用 repeat destruct：reflect 的 destruct 只给等式假设不替换变元，
     repeat 会无限分裂（实测卡死 1 小时+）。一次性分情形 + 手工改写。 *)
  intros [a|a] [b|b]; unfold zmul.
  - cbn [toZ]; now rewrite Nat2Z.inj_mul.
  - destruct (Nat.eqb_spec a 0) as [Ha|Ha].
    + subst; cbn [toZ Nat.eqb]; lia.
    + cbn [toZ].
      assert (H1 : S (a * S b - 1) = a * S b) by nia.
      rewrite H1, Nat2Z.inj_mul; lia.
  - destruct (Nat.eqb_spec b 0) as [Hb|Hb].
    + subst; cbn [toZ Nat.eqb]; lia.
    + cbn [toZ].
      assert (H1 : S (S a * b - 1) = S a * b) by nia.
      rewrite H1, Nat2Z.inj_mul; lia.
  - cbn [toZ]; rewrite Nat2Z.inj_mul; nia.
Qed.

Example zadd_comm_book : forall x y, toZ (zadd x y) = toZ (zadd y x).
Proof.
  intros x y. rewrite !zadd_sound. lia.
Qed.

(* 序与嵌入一致 *)
Example zle_sound : forall x y,
  zle x y = true <-> Z.le (toZ x) (toZ y).
Proof.
  (* 布尔反射先经 leb_le/ltb_lt 转命题，再 zify；true/false 分支分开 *)
  intros [a|a] [b|b]; cbn [zle toZ].
  - rewrite Nat.leb_le; zify; lia.
  - split; [discriminate | zify; lia].
  - split; zify; lia.
  - rewrite Nat.leb_le; zify; lia.
Qed.

(* ---------- 例 1.18：布劳威尔-克林序 ----------
   s < t ⟺ (t 是 s 的真前段) ∨ (最早分歧位处 s(k) < t(k))。
   延伸让序列变小；空序列是最大元。 *)

Fixpoint isPrefix (t s : list nat) : bool :=
  match t, s with
  | [], _ => true
  | _ :: _, [] => false
  | t1 :: ts, s1 :: ss => andb (Nat.eqb t1 s1) (isPrefix ts ss)
  end.

Definition properPrefix (t s : list nat) : bool :=
  andb (isPrefix t s) (negb (Nat.eqb (length t) (length s))).

Fixpoint firstDiffLT (s t : list nat) : bool :=
  match s, t with
  | s1 :: ss, t1 :: ts =>
      if Nat.eqb s1 t1 then firstDiffLT ss ts else Nat.ltb s1 t1
  | _, _ => false
  end.

Definition BKlt (s t : list nat) : bool :=
  orb (properPrefix t s) (firstDiffLT s t).

Lemma isPrefix_app : forall (u s : list nat), isPrefix u (u ++ s) = true.
Proof.
  induction u as [|a u IH]; intros s; simpl.
  - reflexivity.
  - rewrite IH, Nat.eqb_refl. reflexivity.
Qed.

Lemma length_append1 : forall (s : list nat) (x : nat),
  length (s ++ [x]) = S (length s).
Proof.
  induction s as [|a s' IH]; intros x; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma properPrefix_app : forall (s : list nat) (x : nat),
  properPrefix s (s ++ [x]) = true.
Proof.
  intros s x. unfold properPrefix.
  rewrite isPrefix_app, andb_true_l.
  destruct (Nat.eqb_spec (length s) (length (s ++ [x]))) as [He|Hne].
  - rewrite length_append1 in He. exfalso; lia.
  - reflexivity.
Qed.

(* 延伸即变小：s ++ [x] < s（例 1.18 的第一性质） *)
Lemma bk_extend_smaller : forall (s : list nat) (x : nat),
  BKlt (s ++ [x]) s = true.
Proof.
  intros s x. unfold BKlt.
  rewrite properPrefix_app, orb_true_l. reflexivity.
Qed.

(* 空序列是最大元（例 1.18 的第二性质） *)
Lemma bk_nil_max : forall s : list nat, s <> [] -> BKlt s [] = true.
Proof.
  intros [|a s'] Hne; [contradiction|].
  unfold BKlt, properPrefix. reflexivity.
Qed.

(* 稠密性抽查：有限宇宙不可能"自稠密"（BK 序有相邻对，如 [0]/[1]——
   nat 数字 0,1 之间无中间位）。见证公式（书页稠密性证明的构造内核）：
   s<t 若在首位分歧处 s_k < t_k，则 u = t++[0] 居间；若 t 是 s 的真前段
   （s = t++w），则 u = t++[w0+1] 居间。抽查四组配对与机器见证： *)
Definition dense_checks : list (list nat * list nat * list nat) :=
  [ ([0;0], [0;1], [0;1;0]);      (* 分歧位 pos1: 0<1；u = t++[0] 延伸 t 侧 *)
    ([0],   [1;1], [1;0]);        (* 分歧位 pos0: 0<1；u 走 [1;0] *)
    ([1],   [2],   [2;0]);        (* 分歧位 pos0: 1<2；u = t++[0] *)
    ([0;0;0], [0;1], [0;1;0]) ].  (* 分歧位 pos1: 0<1；u 延伸 [0;1] *)

(* Coq stdlib 的 forallb 参数序：谓词在前、列表在后 *)
Definition bk_dense_ok : bool :=
  forallb (fun p => match p with
                    | (s, t, u) => andb (BKlt s t) (andb (BKlt s u) (BKlt u t))
                    end) dense_checks.

Example bk_dense_finite : bk_dense_ok = true.
Proof. vm_compute. reflexivity. Qed.
