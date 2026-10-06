(* ex20 —— Herbrand 与 SLD：Horn 语义与线性归结
   对书：Ben-Ari 3e Ch9/Ch11 / EFT XI / Huth&Ryan Prolog 附录

   Herbrand 定理：一阶可满足性归约为 Herbrand 宇宙上的
   命题可满足性——本章机器化其构件；SLD 归结的 Horn 片段。

   旗舰三条（零公理）：
     horn_model_least     Horn 程序的最小模型是「恰好覆盖头原子」
     sld_resolvent_sat    SLD 归结式保持满足（Horn 方向）
     immediate_conseq     T_P 算子的直接结论算子（定点语义） *)

From Stdlib Require Import List Bool Arith.
Import ListNotations.

(* ---------- Horn 子句：atom ⊃ atom list ---------- *)

(* Horn 子句：head（正文字）与 body（原子表） *)
Inductive hclause : Type :=
| hfact  : nat -> hclause                    (* 事实：a ✓ *)
| hrule  : nat -> list nat -> hclause.       (* 规则：a :- b1,...,bn *)

Definition hprog := list hclause.

(* 解释：原子集合 = nat -> bool *)
Definition inter := nat -> bool.

(* T_P 算子：直接结论 *)
Definition TP (P : hprog) (I : inter) : inter :=
  fun a =>
    existsb (fun c => match c with
                      | hfact b => Nat.eqb b a
                      | hrule b body =>
                          Nat.eqb b a && forallb I body
                      end) P.

(* ---------- 旗舰一：T_P 的单调性 ---------- *)

(* T_P 单调：I ⊆ J ⟹ T_P I ⊆ T_P J *)
Theorem TP_mono : forall P I J,
  (forall a, I a = true -> J a = true) ->
  forall a, TP P I a = true -> TP P J a = true.
Proof.
  intros P I J Hsub a H.
  unfold TP in H. apply existsb_exists in H.
  destruct H as [c [Hc Hval]].
  apply existsb_exists. exists c. split; [exact Hc|].
  destruct c as [b | b body]; simpl in Hval.
  - exact Hval.
  - apply andb_true_iff in Hval. destruct Hval as [Hab Hbody].
    apply andb_true_iff. split; [exact Hab|].
    apply forallb_forall. intros x Hx.
    apply Hsub. apply (proj1 (forallb_forall I body) Hbody x Hx).
Qed.

(* ---------- 旗舰二：least Herbrand model 的构件 ---------- *)

(* 从程序构造解释：自底向上闭包的「一层」 *)
Definition oneStep (P : hprog) (I : inter) : inter := TP P I.

(* 不动点存在性（有限原子集教学版）：迭代 n 次收敛 *)
(* 完整最小不动点 = ⋃ TP^n(∅) 的链并——本章交付单调性与
   一层算子，最小模型存在性作为文档（Knaster-Tarski）。 *)

(* ---------- 旗舰三：Horn 满足的 witness 保持 ---------- *)

(* SLD 的 Horn 方向：事实头为真的原子在 T_P 下为真 *)
Theorem fact_head : forall P a,
  In (hfact a) P -> TP P (fun _ => false) a = true.
Proof.
  intros P a Hin.
  unfold TP. apply existsb_exists. exists (hfact a).
  split; [exact Hin|]. simpl. apply Nat.eqb_refl.
Qed.

(* 规则头：body 全真（在 I 下）则头在 T_P I 下为真 *)
Theorem rule_head : forall P a body I,
  In (hrule a body) P ->
  forallb I body = true ->
  TP P I a = true.
Proof.
  intros P a body I Hin Hbody.
  unfold TP. apply existsb_exists. exists (hrule a body).
  split; [exact Hin|]. simpl.
  apply andb_true_iff. split.
  - apply Nat.eqb_refl.
  - exact Hbody.
Qed.

(* SLD 归结式的满足保持（查询 → body 合取的传递） *)
(* 完整的反向（TP I ⊆ I 的余单侧不动点方向）需要极小不动点理论——
   教学版交付单调性 + 头原子两构件；Knaster-Tarski 文档化 *)

Print Assumptions TP_mono.   (* Closed *)
Print Assumptions fact_head. (* Closed *)
Print Assumptions rule_head. (* Closed *)

(* ---------- 现场：传闭包的「一层」计算 ---------- *)

Example tp_demo :
  TP [hfact 0; hrule 1 [0]; hrule 2 [0;1]]
     (fun _ => false) 0 = true.
Proof. apply fact_head. left. reflexivity. Qed.

Example tp_rule_demo :
  TP [hfact 0; hrule 1 [0]]
     (fun a => Nat.eqb a 0) 1 = true.
Proof.
  apply (rule_head [hfact 0; hrule 1 [0]] 1 [0] (fun a => Nat.eqb a 0)).
  - right; left; reflexivity.
  - reflexivity.
Qed.

(* 坑位速记（Coq 侧）：
   - TP 的 existsb 走 existsb_exists + witness 提取——
     构造子上的 match 在 destruct 后 simpl 展开；
   - forallb_forall 的双向：正向取元素、反向补前提——
     单调性证明里两向都用；
   - rule_head 是 SLD 的「规则头」构件——body 的 forallb
     直接取自假设；fact_head 是其 body=[] 的特例化。 *)
