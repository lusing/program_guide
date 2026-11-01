theory Tower1
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 116 章：荟萃塔 I——无界闭集与荟萃性的有限刻画、支撑单调
与复合（定义 3.10/3.15 的机制核，沿确定性规则链纪律）。载体取
{0,1,2}；子集 = 谓词；一元函数 27 个上枚举。本体（序列函数
(\<Union>X)^<\<omega>、P_\<delta>、Los 3.30、良基性 3.33）留在正文。\<close>

subsection\<open>轮换与像集\<close>

definition
  gcyc :: "i\<Rightarrow>i" where
    "gcyc(x) \<equiv> (if x = 0 then 1 else if x = 1 then 2 else 0)"

definition
  inU :: "i\<Rightarrow>o" where
    "inU(b) \<equiv> b = 0 \<or> b = 1 \<or> b = 2"

definition
  img :: "[i\<Rightarrow>i, i\<Rightarrow>o] \<Rightarrow> i\<Rightarrow>o" where
    "img(f, A, b) \<equiv> inU(b) \<and> (\<exists>a. inU(a) \<and> A(a) \<and> f(a) = b)"

definition
  clubf :: "[i\<Rightarrow>i, i\<Rightarrow>o] \<Rightarrow> o" where
    "clubf(f, A) \<equiv> \<forall>b. img(f, A, b) \<longrightarrow> A(b)"

lemma gcyc_vals:
  "gcyc(0) = 1 \<and> gcyc(1) = 2 \<and> gcyc(2) = 0"
  unfolding gcyc_def by auto

subsection\<open>club 的基本事实\<close>

lemma clubf_empty: "clubf(f, \<lambda>x. False)"
  unfolding clubf_def img_def by auto

lemma clubf_univ: "clubf(f, inU)"
  unfolding clubf_def img_def inU_def by auto

subsection\<open>轮换的 club 最小\<close>

lemma gcyc_inU: "inU(x) \<Longrightarrow> inU(gcyc(x))"
  unfolding gcyc_def inU_def by auto

lemma gcyc_gcyc_gcyc: "inU(x) \<Longrightarrow> gcyc(gcyc(gcyc(x))) = x"
  unfolding gcyc_def inU_def by auto

lemma clubf_gcyc_min:
  assumes hA: "\<forall>b. A(b) \<longrightarrow> inU(b)" and hc: "clubf(gcyc, A)"
    and hw: "\<exists>a. inU(a) \<and> A(a)"
  shows "\<forall>b. inU(b) \<longrightarrow> A(b)"
proof -
  from hw obtain a where ha: "inU(a)" and hAa: "A(a)" by blast
  have h1: "A(gcyc(a))"
  proof -
    have "img(gcyc, A, gcyc(a))"
      unfolding img_def using ha hAa gcyc_inU[OF ha] by blast
    with hc show ?thesis unfolding clubf_def by blast
  qed
  have h2: "A(gcyc(gcyc(a)))"
  proof -
    have "img(gcyc, A, gcyc(gcyc(a)))"
      unfolding img_def using gcyc_inU[OF ha] h1 gcyc_inU[OF gcyc_inU[OF ha]] by blast
    with hc show ?thesis unfolding clubf_def by blast
  qed
  show ?thesis
  proof (intro allI impI)
    fix b assume hb: "inU(b)"
    from hb consider "b = 0" | "b = 1" | "b = 2" unfolding inU_def by blast
    then show "A(b)"
    proof cases
      case 1
      then have "b = gcyc(gcyc(a)) \<or> b = a \<or> b = gcyc(a)" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    next
      case 2
      then have "b = gcyc(a) \<or> b = gcyc(gcyc(a)) \<or> b = a" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    next
      case 3
      then have "b = a \<or> b = gcyc(a) \<or> b = gcyc(gcyc(a))" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    qed
  qed
qed

end
