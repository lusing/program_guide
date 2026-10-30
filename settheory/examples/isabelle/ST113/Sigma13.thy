theory Sigma13
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 113 章：布劳威尔-克林序、双树互补与外延稳定性（定理 3.19
的机制核，沿 103-112 章确定性规则链纪律）。树取 list(nat) 的前缀闭
子集；「实数」取数字串；「力迫扩张」的影子是细化一层（snoc）。
本体（Martin-Solovay 树、Magidor、Oxtoby 赛事、FMW 三等价）留在正文。\<close>

subsection\<open>布劳威尔-克林序（引理 3.20 机制核）\<close>

consts
  bkre :: i

text \<open>布劳威尔-克林序的归纳定义（关系版）：真前段（u 非空）与
首异位比较（a < b）两条规则。\<close>

inductive
  domains   "bkre" \<subseteq> "Sigma(list(nat), \<lambda>_. list(nat))"
  intros
    prefixI: "\<lbrakk>t \<in> list(nat); u \<in> list(nat); u \<noteq> Nil\<rbrakk> \<Longrightarrow>
              \<langle>t @ u, t\<rangle> \<in> bkre"
    diffI: "\<lbrakk>p \<in> list(nat); r \<in> list(nat); q \<in> list(nat);
             a \<in> nat; b \<in> nat; a < b\<rbrakk> \<Longrightarrow>
            \<langle>p @ Cons(a, r), p @ Cons(b, q)\<rangle> \<in> bkre"
  type_intros app_type SigmaI list.intros

text \<open>延伸者更小：s @@ [b] 小于 s（树枝的每一步都是递降）。\<close>

lemma bk_snoc:
    "\<lbrakk>s \<in> list(nat); b \<in> nat\<rbrakk> \<Longrightarrow> \<langle>s @ [b], s\<rangle> \<in> bkre"
  apply (rule bkre.prefixI)
   apply assumption
  apply (blast intro: list.intros)
  apply simp
  done

text \<open>空序列是最大元（定理 3.15(3)(a)）。\<close>

lemma bk_Nil_max:
    "\<lbrakk>s \<in> list(nat); s \<noteq> Nil\<rbrakk> \<Longrightarrow> \<langle>s, Nil\<rangle> \<in> bkre"
  apply (subgoal_tac "\<langle>[] @ s, []\<rangle> \<in> bkre")
   apply simp
  apply (rule bkre.prefixI)
   apply (blast intro: list.intros)
  apply assumption
  apply assumption
  done

subsection\<open>双树互补（定理 3.19 机制核）\<close>

text \<open>caught T x：x 的每一段前缀都被树 T 接住（π[T] 的有限替身；
k 走遍不超过长度的自然数）。\<close>

definition
  caught :: "[i,i] \<Rightarrow> o" where
    "caught(T, x) \<equiv> \<forall>k \<in> nat. k \<le> length(x) \<longrightarrow> take(k, x) \<in> T"

text \<open>首位分裂对：T0 = {Nil} \<union> {Cons(0,l)}，T1 = {Nil} \<union> {Cons(1,l)}，
交恰为 {Nil}（根部独占交）。\<close>

definition
  T0 :: i  where
    "T0 \<equiv> {Nil} \<union> {Cons(zero, l) . l \<in> list(nat)}"

definition
  T1 :: i  where
    "T1 \<equiv> {Nil} \<union> {Cons(succ(zero), l) . l \<in> list(nat)}"

lemma T0I [intro!,simp]: "l \<in> list(nat) \<Longrightarrow> Cons(zero, l) \<in> T0"
  unfolding T0_def by blast

lemma T1I [intro!,simp]: "l \<in> list(nat) \<Longrightarrow> Cons(succ(zero), l) \<in> T1"
  unfolding T1_def by blast

lemma T0_T1_inter: "T0 \<inter> T1 = {Nil}"
  by (unfold T0_def T1_def, auto)

text \<open>「广泛」面：首位 0 的实数在一切深度都被 T0 接住（对深度无量化
限制——「广泛」的有限影子）。\<close>

lemma caught_zero [rule_format]:
  "l \<in> list(nat) \<Longrightarrow> caught(T0, Cons(zero, l))"
  unfolding caught_def
  apply (rule ballI)
  apply (rule impI)
  apply (erule_tac n = k in natE)
  apply (auto simp add: T0_def)
  done

text \<open>k = 0 处的取段方程走显式类型链（succ(zero) 的自然数性
不是简化器可解，nat_succI 属 intro/TC）。\<close>

lemma caught_one [rule_format]:
  "l \<in> list(nat) \<Longrightarrow> caught(T1, Cons(succ(zero), l))"
  unfolding caught_def
  apply (rule ballI)
  apply (rule impI)
  apply (erule_tac n = k in natE)
   apply (subgoal_tac "take(0, Cons(succ(zero), l)) = Nil")
    apply (simp add: T1_def)
   apply (rule take_0)
   apply (rule list.intros)
    apply (rule nat_succI)
    apply (rule nat_0I)
   apply assumption
  apply simp
  done

text \<open>全长取段引理：确定性链（规避 blast 类型检查）。\<close>

lemma length_cons_nat:
  assumes hb: "b \<in> nat" and hl: "l \<in> list(nat)"
  shows "length(Cons(b,l)) \<in> nat"
  apply (rule length_type)
  apply (rule list.intros(2))
   apply (rule hb)
  apply (rule hl)
  done

lemma le_length_self:
  assumes hb: "b \<in> nat" and hl: "l \<in> list(nat)"
  shows "length(Cons(b,l)) \<le> length(Cons(b,l))"
  apply (rule le_refl)
  apply (rule nat_into_Ord)
  apply (rule length_cons_nat [OF hb hl])
  done

text \<open>根部独占交（T0 \<inter> T1 = {Nil}）\<Longrightarrow> 投影不交：在全长处取段
即整条实数，首位不可能既是 0 又是 1。\<close>

lemma no_dual_caught:
  assumes hl: "l \<in> list(nat)" and hb: "b \<in> nat"
    and h0: "caught(T0, Cons(b,l))" and h1: "caught(T1, Cons(b,l))"
  shows "False"
proof -
  have kn: "length(Cons(b,l)) \<in> nat" by (rule length_cons_nat [OF hb hl])
  have kle: "length(Cons(b,l)) \<le> length(Cons(b,l))"
    by (rule le_length_self [OF hb hl])
  have tak: "take(length(Cons(b,l)), Cons(b,l)) = Cons(b,l)"
    by (rule take_all [rule_format, OF kn, OF list.intros(2) [OF hb hl], OF kle])
  have himp0: "length(Cons(b,l)) \<le> length(Cons(b,l)) \<longrightarrow>
               take(length(Cons(b,l)), Cons(b,l)) \<in> T0"
    by (rule h0 [unfolded caught_def, THEN bspec, OF kn])
  have himp1: "length(Cons(b,l)) \<le> length(Cons(b,l)) \<longrightarrow>
               take(length(Cons(b,l)), Cons(b,l)) \<in> T1"
    by (rule h1 [unfolded caught_def, THEN bspec, OF kn])
  from himp0 [THEN mp, OF kle] have e0: "take(length(Cons(b,l)), Cons(b,l)) \<in> T0" .
  from himp1 [THEN mp, OF kle] have e1: "take(length(Cons(b,l)), Cons(b,l)) \<in> T1" .
  have e0': "Cons(b,l) \<in> T0" by (rule e0 [simplified tak])
  have e1': "Cons(b,l) \<in> T1" by (rule e1 [simplified tak])
  have cint: "Cons(b,l) \<in> T0 \<inter> T1" by (rule IntI [OF e0' e1'])
  then show "False" by (simp add: T0_T1_inter)
qed

subsection\<open>外延稳定性（定理 3.19 (3) 的力迫面）\<close>

text \<open>基础件：j \<le> succ(j)（自建：succ_iff + ltI + leI）。\<close>

lemma le_succ_step: "Ord(j) \<Longrightarrow> j \<le> succ(j)"
  apply (rule leI [OF ltI [OF _ Ord_succ]])
  apply (rule succ_iff [THEN iffD2, of j j])
  apply (rule disjI1 [OF refl])
  apply assumption
  done

text \<open>snoc 后长度恰加一。\<close>

lemma length_snoc [rule_format]:
  "x \<in> list(nat) \<Longrightarrow> b \<in> nat \<Longrightarrow> length(x @ [b]) = succ(length(x))"
  apply (erule list.induct)
  apply simp_all
  done

text \<open>细化的前段仍是原前段：Cons 步引理（自带命名，规避分案变量）。\<close>

lemma take_zero_cons: "take(0, Cons(a, l)) = Nil"
  by (simp add: take_def)

text \<open>Cons 步引理（结论取规范形，等式前提吸掉 natE 的分案等式）。\<close>

lemma take_snoc_succ:
  assumes ih: "m \<le> length(l) \<longrightarrow> take(m, l @ [b]) = take(m, l)"
    and hK: "K = succ(m)" and hm: "m \<in> nat" and ha: "a \<in> nat"
    and hl: "l \<in> list(nat)"
    and hle: "succ(m) \<le> length(Cons(a, l))"
  shows "take(K, Cons(a, l @ [b])) = take(K, Cons(a, l))"
proof -
  have hlen: "length(Cons(a, l)) = succ(length(l))" by (simp add: length.simps)
  have mle: "m \<le> length(l)" by (rule succ_le_imp_le [OF hle [simplified hlen]])
  from ih [THEN mp, OF mle] have e: "take(m, l @ [b]) = take(m, l)" .
  show ?thesis unfolding hK by (simp only: take_succ_Cons [OF hm] e)
qed

text \<open>细化的前段仍是原前段：对 u 归纳、k 按 natE 分案
（drule-bspec 的实例改经 subgoal_tac 送入，规避链式前提失配）。\<close>

lemma take_snoc_le [rule_format]:
  "u \<in> list(nat) \<Longrightarrow>
   \<forall>k \<in> nat. k \<le> length(u) \<longrightarrow> take(k, u @ [b]) = take(k, u)"
  apply (erule list.induct)
   apply (rule ballI, rule impI, erule_tac n = k in natE, auto)
  apply (erule_tac n = k in natE)
   apply (simp add: take_zero_cons)
  apply (subgoal_tac "x \<le> length(l) \<longrightarrow> take(x, l @ [b]) = take(x, l)")
   prefer 2
   apply (drule_tac x = x in bspec)
    apply assumption
   apply assumption
  apply (subgoal_tac "succ(x) \<le> length(Cons(a, l))")
   prefer 2
   apply (simp add: length.simps)
  apply (rule take_snoc_succ, assumption+)
  done

text \<open>新实数 x @@ [b] 被接住 \<Longrightarrow> 旧实数 x 仍被接住（旧实数成员资格
在扩张下不变——「广泛」的第二面：并非只在当前宇宙验证）。\<close>

lemma caught_shrink:
  assumes hx: "x \<in> list(nat)" and hb: "b \<in> nat" and hc: "caught(T, x @ [b])"
  shows "caught(T, x)"
  unfolding caught_def
proof (rule ballI, rule impI)
  fix k
  assume kn: "k \<in> nat" and kle: "k \<le> length(x)"
  have ls: "length(x @ [b]) = succ(length(x))" by (rule length_snoc [OF hx hb])
  have knat2: "length(x) \<in> nat" by (rule length_type [OF hx])
  have kle2: "k \<le> length(x @ [b])"
  proof (rule le_trans [OF kle])
    show "length(x) \<le> length(x @ [b])"
      by (simp only: ls, rule le_succ_step [OF nat_into_Ord [OF knat2]])
  qed
  have tk: "take(k, x @ [b]) = take(k, x)"
    by (rule take_snoc_le [OF hx kn kle])
  have himp: "k \<le> length(x @ [b]) \<longrightarrow> take(k, x @ [b]) \<in> T"
    by (rule hc [unfolded caught_def, THEN bspec, OF kn])
  from himp [THEN mp, OF kle2] tk show "take(k, x) \<in> T" by simp
qed

end
