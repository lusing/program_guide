(* ex03 —— 自然演绎 NJp（Isabelle/HOL 版）
   Isabelle 的特色：ND 规则全是内核定理，有专名——
   conjI/conjE、disjI1/disjI2/disjE、impI/mp、notI/notE、FalseE。
   Isar 证明可以一行一行地贴着规则写。 *)
theory ex03_njp
  imports Main
begin

lemma nd_and_comm: "P \<and> Q \<Longrightarrow> Q \<and> P"
proof (erule conjE)
  assume P: P and Q: Q
  show "Q \<and> P" using Q P by (rule conjI)
qed

lemma nd_or_comm: "P \<or> Q \<Longrightarrow> Q \<or> P"
proof (erule disjE)
  assume P: P
  show "Q \<or> P" using P by (rule disjI2)
next
  assume Q: Q
  show "Q \<or> P" using Q by (rule disjI1)
qed

lemma nd_de_morgan: "\<not>(P \<or> Q) \<Longrightarrow> \<not>P \<and> \<not>Q"
proof -
  assume H: "\<not>(P \<or> Q)"
  have np: "\<not>P"
  proof (rule notI)
    assume P
    then have "P \<or> Q" by (rule disjI1)
    with H show False by (rule notE)
  qed
  have nq: "\<not>Q"
  proof (rule notI)
    assume Q
    then have "P \<or> Q" by (rule disjI2)
    with H show False by (rule notE)
  qed
  show "\<not>P \<and> \<not>Q" using np nq by (rule conjI)
qed

lemma nd_mt: "\<lbrakk> P \<longrightarrow> Q; \<not> Q \<rbrakk> \<Longrightarrow> \<not>P"
proof (rule notI)
  assume imp: "P \<longrightarrow> Q" and nq: "\<not>Q" and P: P
  from imp P have Q by (rule mp)
  with nq show False by (rule notE)
qed

lemma nd_ex_falso: "False \<Longrightarrow> P"
  by (rule FalseE)

lemma nd_k: "P \<Longrightarrow> Q \<longrightarrow> P"
proof -
  assume P: P
  show "Q \<longrightarrow> P"
  proof (rule impI)
    assume Q: Q
    show P by (rule P)
  qed
qed

(* 坑位速记（Isabelle 侧）：
   - proof (erule conjE) 把前提的 ∧ 拆成两个 assume——ND 的 E 规则即目标变换；
   - using A B by (rule conjI) 的 fact 顺序就是参数顺序；
   - rule notI/notE/mp/disjI1 都是内核定理名，Isar 里直接当方法用。 *)

end
