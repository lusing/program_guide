(* ex03 —— 自然演绎 NJp：每条规则都是一个程序
   八书对位：Huth&Ryan §1.2 / Mints §2.2 / Ben-Ari 3e Ch3（对照用）
            / Mendelson §1.4（Hilbert 对照）

   Curry-Howard 直读：∧I=配对、∧E=投影、∨I=注入、∨E=分情况、
   →I=λ、→E=应用、⊥E=空消解。「规则即程序」在类型论系是字面事实。 *)

(* ---------- 规则的函数化身 ---------- *)

Definition impI {P Q : Prop} (f : P -> Q) : P -> Q := f.
Definition impE {P Q : Prop} (hpq : P -> Q) (hp : P) : Q := hpq hp.

Definition andI {P Q : Prop} (p : P) (q : Q) : P /\ Q := conj p q.
Definition andE1 {P Q : Prop} (h : P /\ Q) : P := proj1 h.
Definition andE2 {P Q : Prop} (h : P /\ Q) : Q := proj2 h.

Definition orI1 {P Q : Prop} (p : P) : P \/ Q := or_introl p.
Definition orI2 {P Q : Prop} (q : Q) : P \/ Q := or_intror q.

Definition negI {P : Prop} (f : P -> False) : ~ P := f.
Definition negE {P : Prop} (hnp : ~ P) (hp : P) : False := hnp hp.

(* ---------- 定理即程序组合 ---------- *)

Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof. intros P Q [HP HQ]. split. exact HQ. exact HP. Qed.

Theorem or_comm : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof. intros P Q [HP | HQ].
  - right. exact HP.
  - left. exact HQ. Qed.

(* de Morgan：两个方向构造性都成立（对偶方向 ¬p∨¬q→¬(p∧q) 才是 11 章的坎） *)
Theorem de_morgan_1 : forall P Q : Prop, ~ (P \/ Q) -> ~ P /\ ~ Q.
Proof. intros P Q H. split.
  - intros HP. apply H. left. exact HP.
  - intros HQ. apply H. right. exact HQ. Qed.

Theorem de_morgan_2 : forall P Q : Prop, ~ P /\ ~ Q -> ~ (P \/ Q).
Proof. intros P Q [HNP HNQ] [HP | HQ].
  - exact (HNP HP).
  - exact (HNQ HQ). Qed.

(* 派生规则：拒取式 MT *)
Theorem mt : forall P Q : Prop, (P -> Q) -> ~ Q -> ~ P.
Proof. intros P Q HPQ HNQ HP. apply HNQ. apply HPQ. exact HP. Qed.

(* ex falso 与 K 公理 *)
Theorem ex_falso : forall P : Prop, False -> P.
Proof. intros P H. destruct H. Qed.

Theorem k_axiom : forall P Q : Prop, P -> Q -> P.
Proof. intros P Q HP HQ. exact HP. Qed.

Print Assumptions and_comm.  (* Closed *)
Print Assumptions de_morgan_2. (* Closed *)

(* 坑位速记（Coq 侧）：
   - intros [HP | HQ] 直接做 ∨E；split 即 ∧I；
   - 全部定理 Print Assumptions 均 Closed——NJp 片段零公理；
   - 注意 de_morgan_2 依赖 pattern matching 位置双分支的缩进深度。 *)
