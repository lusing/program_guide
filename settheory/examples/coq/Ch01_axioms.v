(* 第 01 章 公理：浅嵌入 ZF——公理显式记账，第一件实事 *)

Require Import ZArith Lia.

(* ---------- 一、浅嵌入：一个"ZF 结构"的记录 ---------- *)

Record ZFStructure {A : Type} {mem : A -> A -> Prop} : Prop := BuildZF
  {
    (* 外延公理 *)
    zf_extensional :
      forall x y : A, (forall u, mem u x <-> mem u y) -> x = y ;
    (* 配对公理 *)
    zf_pairing :
      forall a b : A, exists c, forall u, mem u c <-> (u = a \/ u = b) ;
    (* 并公理 *)
    zf_union :
      forall X : A, exists c, forall u,
        mem u c <-> exists z, mem z X /\ mem u z ;
    (* 幂集公理 *)
    zf_power :
      forall X : A, exists c, forall u,
        mem u c <-> (forall w, mem w u -> mem w X)
  }.

(* 公理是"字段"：模型 = 载体 + 关系 + 四个证据。
   这正是"公理化集合论"的形式骨架。 *)

(* ---------- 二、用公理干活：单点集与singleton ---------- *)

Section UsingAxioms.

Variable A : Type.
Variable mem : A -> A -> Prop.
Variable ZF : ZFStructure (A := A) (mem := mem).

(* 单点集 {a}：取配对 {a,a}，其成员条件退化为 u = a *)
Lemma singleton_exists :
  forall a : A, exists c, forall u, mem u c <-> u = a.
Proof.
  intros a.
  destruct (zf_pairing ZF a a) as [c Hc].
  exists c.
  intros u. rewrite Hc. split.
  - intros [H | H]; assumption.
  - intro H. left; assumption.
Qed.

(* 幂集公理的元素侧阅读：mem u c = "u 是 X 的子集"，
   因此"子集"关系可以从公理读出，而不必先有全域的子集概念 *)
Definition subset_of (u X : A) : Prop :=
  forall w, mem w u -> mem w X.

Lemma power_char :
  forall X : A, exists c, forall u, mem u c <-> subset_of u X.
Proof.
  intros X. destruct (zf_power ZF X) as [c Hc].
  exists c. exact Hc.
Qed.

End UsingAxioms.

(* ---------- 三、HF 的第一次预告：公理可以被"满足" ---------- *)

(* HF（遗传有限集合）满足配对公理：构造证据本身是函数。
   完整的 HF 模型在 Agda 通道（Ch01_hf.agda）展开；
   Coq 侧 02 章将给出归纳定义版并验证外延性。 *)

Print Assumptions singleton_exists.
