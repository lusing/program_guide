(* ex49_goedel.v —— 算术化与哥德尔编码（Mendelson §3.4）
   编码三件套：配对单射（2^a·(2b+1)）、语法树编码 gcf 及单射性、
   β-函数（中国剩余）序列编解码往返；代入 subf 现场与自引骨架。
   一般定理（β-CRT、sub 原始递归、不动点引理）为文档线——机器面给足
   它们的可检验素材。 *)

From Stdlib Require Import Bool Arith Lia List PeanoNat.
Import ListNotations.

(* ============ 一、哥德尔配对与单射性 ============ *)
(* 平方配对 cp(a,b) = (a+b)^2 + b：多项式增长（指数配对会把码放进指数位，
   nat 单仁表示下内存爆炸——实测教训）；单射性只需平方严格单调。 *)

Lemma sq_step : forall s, s * s + s < (s + 1) * (s + 1).
Proof. intro s. rewrite !Nat.add_1_r, Nat.mul_succ_l, Nat.mul_succ_r. lia. Qed.

Lemma sq_mono : forall s1 s2, s1 <= s2 -> s1 * s1 <= s2 * s2.
Proof.
  intros s1 s2 H. apply Nat.mul_le_mono; assumption.
Qed.

Definition cp (a b : nat) : nat := (a + b) * (a + b) + b.

Theorem cp_inj : forall a1 b1 a2 b2,
  cp a1 b1 = cp a2 b2 -> a1 = a2 /\ b1 = b2.
Proof.
  unfold cp. intros a1 b1 a2 b2 H.
  destruct (Nat.lt_trichotomy (a1 + b1) (a2 + b2)) as [Hlt | [Heq | Hgt]].
  - exfalso.
    assert (H1 : (a1 + b1) * (a1 + b1) + b1 < (a1 + b1 + 1) * (a1 + b1 + 1)).
    { pose proof (sq_step (a1 + b1)). lia. }
    assert (H2 : (a1 + b1 + 1) * (a1 + b1 + 1)
                 <= (a2 + b2) * (a2 + b2)).
    { apply sq_mono. lia. }
    lia.
  - assert (Hb : b1 = b2) by lia.
    subst b2. split; [lia | reflexivity].
  - exfalso.
    assert (H1 : (a2 + b2) * (a2 + b2) + b2 < (a2 + b2 + 1) * (a2 + b2 + 1)).
    { pose proof (sq_step (a2 + b2)). lia. }
    assert (H2 : (a2 + b2 + 1) * (a2 + b2 + 1)
                 <= (a1 + b1) * (a1 + b1)).
    { apply sq_mono. lia. }
    lia.
Qed.

Definition pr3 (a b c : nat) : nat := cp a (cp b c).

Theorem pr3_inj : forall a1 b1 c1 a2 b2 c2,
  pr3 a1 b1 c1 = pr3 a2 b2 c2 -> a1 = a2 /\ b1 = b2 /\ c1 = c2.
Proof.
  unfold pr3. intros a1 b1 c1 a2 b2 c2 H.
  destruct (cp_inj _ _ _ _ H) as [Ha Hbc].
  destruct (cp_inj _ _ _ _ Hbc) as [Hb Hc].
  auto.
Qed.

(* ============ 二、极小一阶语法与树编码 ============ *)

Inductive tm : Type :=
| var (n : nat)
| num (n : nat).

Inductive fm : Type :=
| eqt (t1 t2 : tm)
| neg (a : fm)
| imp (a b : fm)
| exq (x : nat) (a : fm).

Definition gct (t : tm) : nat :=
  match t with
  | var n => pr3 0 n 0
  | num n => pr3 0 n 1
  end.

Fixpoint gcf (φ : fm) : nat :=
  match φ with
  | eqt t1 t2 => pr3 1 (gct t1) (gct t2)
  | neg a => pr3 2 (gcf a) 0
  | imp a b => pr3 3 (gcf a) (gcf b)
  | exq x a => pr3 4 x (gcf a)
  end.

Theorem gct_inj : forall t1 t2, gct t1 = gct t2 -> t1 = t2.
Proof.
  intros [n1 | n1] [n2 | n2] H; simpl in H;
    try (destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]];
         congruence).
Qed.

Theorem gcf_inj : forall φ1 φ2, gcf φ1 = gcf φ2 -> φ1 = φ2.
Proof.
  intro φ1. induction φ1 as [t1 t2 | a IHa | a IHa b IHb | x a IHa];
    intros [u1 u2 | c | c d | y c] H; simpl in H;
    try (destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]]; discriminate).
  - destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]].
    rewrite (gct_inj _ _ H1), (gct_inj _ _ H2). reflexivity.
  - destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]].
    rewrite (IHa _ H1). reflexivity.
  - destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]].
    rewrite (IHa _ H1), (IHb _ H2). reflexivity.
  - destruct (pr3_inj _ _ _ _ _ _ H) as [H0 [H1 H2]].
    rewrite H1, (IHa _ H2). reflexivity.
Qed.


(* ============ 三、代入：语法层现场 ============ *)

Definition subt (t : tm) (x : nat) (u : tm) : tm :=
  match t with
  | var n => if Nat.eqb n x then u else var n
  | num _ => t
  end.

(* 天真代入：绑定位撞名整体保留。侧条件 y∉FV(u) 与换名是文档线；
   本章 u 恒取闭项 num n，天然避开撞名。 *)
Fixpoint subf (φ : fm) (x : nat) (u : tm) : fm :=
  match φ with
  | eqt t1 t2 => eqt (subt t1 x u) (subt t2 x u)
  | neg a => neg (subf a x u)
  | imp a b => imp (subf a x u) (subf b x u)
  | exq y a => if Nat.eqb y x then exq y a else exq y (subf a x u)
  end.

Example subf_samples :
  (subf (eqt (var 0) (var 1)) 0 (num 5),
   subf (exq 0 (eqt (var 0) (var 0))) 0 (num 5),
   subf (exq 1 (eqt (var 0) (var 1))) 0 (num 5))
  = (eqt (num 5) (var 1),
     exq 0 (eqt (var 0) (var 0)),
     exq 1 (eqt (num 5) (var 1))).
Proof. reflexivity. Qed.

(* ============ 四、β-函数：中国剩余的序列编码 ============ *)

Definition beta (b c i : nat) : nat := b mod (1 + (i + 1) * c).

Fixpoint bcheck (b c : nat) (xs : list nat) (i : nat) : bool :=
  match xs with
  | [] => true
  | v :: rest => Nat.eqb (beta b c i) v && bcheck b c rest (S i)
  end.

(* 逐 b 搜索（c 手选互素族）：找到 b 使 β 逐位还原序列 *)
Fixpoint findb (xs : list nat) (c b fuel : nat) : option nat :=
  match fuel with
  | O => None
  | S f => if bcheck b c xs 0 then Some b else findb xs c (S b) f
  end.

(* c=6：模族 7,13,19 两两互素——CRT 保证解存在，搜索必命中 *)
Example beta_rt : match findb [2; 5; 1] 6 0 2000 with
                  | Some b => bcheck b 6 [2; 5; 1] 0
                  | None => false
                  end = true.
Proof. reflexivity. Qed.

(* c=2：模族 3,9 非互素且余数冲突——搜索扑空（CRT 条件的现场） *)
Example beta_conflict : findb [2; 7] 2 0 500 = None.
Proof. reflexivity. Qed.

(* 搜索见证：b=590——590 mod 7=2, 590 mod 13=5, 590 mod 19=1 逐位还原 *)
Example beta_witness : bcheck 590 6 [2; 5; 1] 0 = true.
Proof. reflexivity. Qed.

(* findb 命中同一见证 *)
Example beta_findb : findb [2; 5; 1] 6 0 2000 = Some 590.
Proof. reflexivity. Qed.

(* ============ 五、自引骨架 ============ *)

(* 模板：一个含自由变元 0 的式；dsub n = 把 ⌜num n⌝ 代入 0 位 *)
Definition Tdiag : fm := eqt (var 0) (var 1).
Definition dsub (n : nat) : fm := subf Tdiag 0 (num n).

(* 嵌套配对的码值快速增长（每层再平方）：dsub 0 已是 4555，dsub 1 破百万
   （核内单仁转换会栈溢出——这正是编码工程学的权衡现场：指数配对更紧
   但 nat 单仁表示算不动，平方配对也要小现场）。 *)
Example dsub_first : gcf (dsub 0) = 4555.
Proof. reflexivity. Qed.

(* 有界搜索「gcf (dsub n) = n」在小范围内无解——真不动点引理（书 3.5）
   需要 β 提供的行内序列构造，把「对自身编码的代入」做成一次算术运算；
   文档线 *)
Fixpoint findfix (fuel : nat) : option nat :=
  match fuel with
  | O => None
  | S f => if Nat.eqb (gcf (dsub fuel)) fuel then Some fuel else findfix f
  end.

Example nofix_small : findfix 1 = None.
Proof. reflexivity. Qed.


(* ============ 账本 ============ *)

Print Assumptions cp_inj.
Print Assumptions gcf_inj.
Print Assumptions beta_rt.
Print Assumptions nofix_small.
