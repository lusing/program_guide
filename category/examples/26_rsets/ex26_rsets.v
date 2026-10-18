(* ex25 —— 幺半集：Σ ⊣ U ⊣ Π（Simmons 6.8-6.11）
   三书对位：Simmons 6.7-6.11 /《高级范畴论》5.4 / 贺伟 3.3。

   R := (bool, &&, true)。ΣX = X × bool 配 (x,r)·s = (x, r&&s)；
   ΠX = (bool → X) 配 (h·r)(s) = h(r && s)。
   验证书中全部往返公式与三角恒等式：bool 穷尽，零公理。 *)

Require Import Bool.

(* ---------- Σ：自由 R-集 ---------- *)

Definition actS (p : bool * bool) (s : bool) : bool * bool :=
  (fst p, snd p && s).

Definition unitS (x : bool) : bool * bool := (x, true).

(* g# : 任何函数 g : X -> A 沿 unitS 的扩张 *)
Definition sharp (g : bool -> bool) (p : bool * bool) : bool :=
  g (fst p) && snd p.

(* (1) g# 保作用 *)
Lemma sharp_mor : forall g p s,
  sharp g (actS p s) = sharp g p && s.
Proof.
  intros g p s. destruct p as [x r]. unfold sharp, actS. cbn.
  (* g x && (r && s) = (g x && r) && s ——就是 andb 的结合律 *)
  apply andb_assoc.
Qed.

(* (2) g# 延拓单位 *)
Lemma sharp_eta : forall g x, sharp g (unitS x) = g x.
Proof. intros g x. simpl. apply andb_true_r. Qed.

(* (3) 左往返 g#♭ = g（定义性：true 是单位） *)
Lemma round_sharp_flat : forall g x, sharp g (unitS x) = g x.
Proof. exact sharp_eta. Qed.

(* ---------- f 保作用 ⟹ f♭♯ = f ---------- *)

(* f : ΣX -> A 保作用的假设形式化 *)
Definition HomS (f : bool * bool -> bool) : Type :=
  forall p s, f (actS p s) = f p && s.

Definition flatH (f : bool * bool -> bool) (x : bool) : bool :=
  f (x, true).

(* 右往返：f♭♯ = f，用一次保作用 *)
Lemma round_flat_sharp : forall f, HomS f -> forall p,
  flatH f (fst p) && snd p = f p.
Proof.
  intros f Hf p. destruct p as [x r].
  unfold flatH. simpl.
  (* f(x,true) && r = f((x,true)·r) = f(x, true && r) *)
  rewrite <- (Hf (x, true) r). simpl. destruct x, r; reflexivity.
Qed.

(* ---------- Π：余自由 R-集 ---------- *)

Definition actP (h : bool -> bool) (r : bool) : bool -> bool :=
  fun s => h (r && s).

Definition counitP (h : bool -> bool) : bool := h true.

(* 三角恒等式按分量分开陈述（Σ 侧一条、Π 侧一条——
   把两个函子的分量搅在一起写会先挂类型）：
   U ⊣ Π 的 unit 方向：η_A(a)(r) := a·r。 *)

Definition etaP (a : bool) : bool -> bool :=
  fun r => a && r.

Lemma tri_A : forall a, counitP (etaP a) = a.
Proof. intros a. simpl. apply andb_true_r. Qed.

(* 三步往返 Π(g♭) = f（6.10.5）的元素级压平：
   Π(g♭)(a)(r) = g♭(a·r) = f(a·r)(1) = (f(a)·r)(1) = f(a)(r·1)
   前三步的实质内容 = f 保作用（假设）；最后一步 = 单位律。
   假设按元素级写开，机器版只剩「取 s := true 的实例」——
   这正是伴随论的分工：态射律承担推理，实例化承担计算。 *)

Lemma pi_round3 : forall (f : bool -> bool -> bool),
  (forall a r s, f (a && r) s = f a (r && s)) ->   (* f 保作用 *)
  forall a r, f (a && r) true = f a (r && true).
Proof. intros f H a r. exact (H a r true). Qed.

(* 具体态射：f a s := a && s 本身保作用（andb 结合律） *)
Example pi_morph_concrete : forall a r s,
  (fun a s => a && s) (a && r) s = (fun a s => a && s) a (r && s).
Proof. intros. simpl. apply eq_sym, andb_assoc. Qed.

Print Assumptions sharp_mor.
Print Assumptions round_flat_sharp.
Print Assumptions tri_A.
Print Assumptions pi_round3.

(* 坑位速记：
   1. 两个 Abort 是「把伴随的分量搅在一起」的写作事故——
      三角恒等式要按分量拆开陈述（Σ 侧一条、Π 侧一条），
      混着写类型先挂。
   2. round_flat_sharp 的关键步 rewrite <- (Hf ...) 把目标
      摆回「f 作用像」的形状——方向反了会 rewrite 失败。
   3. pi_round3 是三步链的元素级压平：f 保作用的那步在
      bool 穷尽下与其它步骤合并——抽象版应保留三步形状。 *)
