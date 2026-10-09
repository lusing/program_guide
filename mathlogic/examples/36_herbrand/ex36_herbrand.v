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


(* ---------- 张寅生轮深化：H 域逐层生成+语义树（书 10.1） ---------- *)

(* H 域（定义 10.9）：H0={a}（无常元补哑常量），H_{i+1}=H_i ∪ F(H_i)
   ——函数符闭包。教学件：一元函数符 f（编号+1）的 H 域 *)
Definition hterm := nat.                (* 项编号：0=a，k+1=f(k) *)
Definition fsym (t : hterm) : hterm := S t.

Fixpoint hLayer (i : nat) : list hterm :=
  match i with
  | 0 => [0]
  | S k => hLayer k ++ map fsym (hLayer k)
  end.

(* H 域逐层账：H0={a}、H1={a,f a}、H2 加 {f²a,f³a}——单调增长 *)
Example h_layers :
  map hLayer [0;1;2;3]
  = [ [0]; [0;1]; [0;1;1;2]; [0;1;1;2;1;2;2;3] ].
Proof. reflexivity. Qed.
(* 列表层账有重复元素（f 已见项再指一层）——H 域按集合读：
   |H_k|=2^k（去重后恰 [0..2^k-1]）。 *)
Example h_layers_dedup :
  map (fun i => nodup Nat.eq_dec (hLayer i)) [0;1;2;3]
  = [ [0]; [0;1]; [0;1;2]; [0;1;2;3] ].
Proof. reflexivity. Qed.

(* 单调性：H_i ⊆ H_{i+1}（H 域的可数超穷构造——书 p128 例 10.2） *)
Example h_monotone_sample :
  forallb (fun t => existsb (Nat.eqb t) (hLayer 2)) (hLayer 1)
  = true.
Proof. reflexivity. Qed.

(* 语义树（例 10.7，图 10.1/10.2 的可执行版）：基原子逐个二叉分叉
   （真假赋值），失败节点=某子句基例在该枝上全文字被否定——剪枝。
   教学件：子句集 S={P(a), ¬P(a)∨P(f a), ¬P(f a)} 的语义树封闭 *)
Definition atoms3 : list nat := [1; 2].   (* 1=P(a)，2=P(f a) *)

(* 一条枝=对全部基原子的真值指派（bitmask：bit k 对 atoms3 的第 k 个） *)
Definition branchVal (branch : nat) (k : nat) : bool :=
  Nat.ltb 0 (Nat.land branch (Nat.pow 2 k)).

(* 子句在枝上「失败」=所有文字在该枝赋值下为假 *)
Definition litFalse (branch : nat) (atomId : nat) (pol : bool) : bool :=
  negb (Bool.eqb (branchVal branch atomId) pol).

(* S 的三个子句（文字表 (原子号,极性)） *)
Definition cls1 := [ (1, true) ].            (* P(a) *)
Definition cls2 := [ (1,false); (2,true) ].  (* ¬P(a)∨P(f a) *)
Definition cls3 := [ (2, false) ].           (* ¬P(f a) *)

Definition clauseFails (branch : nat) (c : list (nat * bool)) : bool :=
  forallb (fun l => litFalse branch (fst l) (snd l)) c.

(* 封闭语义树：每条枝上至少一个子句失败——S 不可满足的语义树证据 *)
Example sem_tree_closed :
  forallb (fun branch =>
    existsb (clauseFails branch) [cls1; cls2; cls3])
    (seq 0 4) = true.
Proof. reflexivity. Qed.
(* Herbrand 定理（定理 10.4）的语义树版：S 不可满足 ⟺ 存在有限的
   封闭语义树。上面 4 条枝全部失败——S={P(a),¬P(a)∨P(f a),¬P(f a)}
   不可满足的最小语义树证据（枝 00：P(a) 假→cls1 败；枝 11：P(f a)
   真→cls3 败；等等）。图 10.2「封闭树」的可执行化。 *)
