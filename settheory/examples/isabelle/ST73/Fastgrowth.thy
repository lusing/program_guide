theory Fastgrowth
  imports "ZF.OrderType" "ZF.Nat" "ZF.Epsilon" "ZF.OrdQuant"
begin

text \<open>
第 73 章：快速增长数论函数层次（冯琦 §1.8.4）。

ZF 库有 oadd/omult 却无 oexp（OrdinalArith 在 ZF 侧缺席——本轮实测
的库缺口），本章先用 transrec2（Epsilon.thy 的三情形超限递归器，
定理 1.56 的官方化身）自建序数幂 oexp 并证三款递归式与幂保持
序数性，再点火塔式序列 otow（δ₀=ω、δ_{n+1}=ω^{δ_n}）给出 ε₀ 的
正式定义，最后落基本序列（定义 1.83）的两条样板条款与 ε₀ 自身的
基本序列。F_α 层次与古德斯坦剧场由其余六通道承载。
\<close>

subsection \<open>自建序数幂：transrec2 的三款递归式\<close>

text \<open>冯琦定义 1.81 的幂：a^0 = 1、a^{β+1} = a^β·a、极限处取并。
transrec2(b, 1, λj r. r**a) 逐字对应——零款给 1、后继款给
"前一值乘 a"、极限款由 transrec2 自动取并。\<close>

definition oexp :: "[i,i] \<Rightarrow> i"  (infixr "^^" 75) where
  "a ^^ b \<equiv> transrec2(b, 1, \<lambda>j r. r ** a)"

lemma oexp_0 [simp]: "a ^^ 0 = 1"
  by (simp add: oexp_def)

lemma oexp_succ [simp]: "a ^^ succ(i) = (a ^^ i) ** a"
  by (simp add: oexp_def)

lemma oexp_Limit: "Limit(i) \<Longrightarrow> a ^^ i = (\<Union>j<i. a ^^ j)"
  apply (simp add: oexp_def)
  apply (rule transrec2_Limit)
  apply assumption
  done

text \<open>幂的一号样例：a^1 = a（后继款 + 乘法幺元 omult_1_left）。\<close>

lemma oexp_1: "Ord(a) \<Longrightarrow> a ^^ 1 = a"
  by simp

subsection \<open>塔式序列与 ε₀ 的正式定义（定义 1.82）\<close>

text \<open>otow：δ₀ = ω（ZF 的 ω 即 nat）、δ_{n+1} = ω^{δ_n}；
ε₀ = sup{δ_n | n ∈ ω} = ⋃n∈nat. otow(n)。\<close>

definition otow :: "i \<Rightarrow> i" where
  "otow(n) \<equiv> rec(n, nat, \<lambda>x r. nat ^^ r)"

definition eps0 :: "i" where
  "eps0 \<equiv> \<Union>n\<in>nat. otow(n)"

lemma otow_0: "otow(0) = nat"
  by (simp add: otow_def)

lemma otow_succ: "n \<in> nat \<Longrightarrow> otow(succ(n)) = nat ^^ otow(n)"
  by (simp add: otow_def)

text \<open>塔的前两级现形：δ₁ = ω^ω、δ₂ = ω^{ω^ω}
（1、2 在 Bool.thy 里是 succ 缩写，rec_succ 直接命中）。\<close>

lemma otow_1: "otow(1) = nat ^^ nat"
  by (simp add: otow_succ [OF nat_0I] otow_0)

lemma otow_2: "otow(2) = nat ^^ (nat ^^ nat)"
  by (simp add: otow_succ [OF nat_1I] otow_1)

text \<open>幂保持序数性：trans_induct 超限归纳 + Ord_cases 三情形
（0 用 oexp_0、后继用 Ord_omult、极限用 Ord_OUN 收并）。\<close>

lemma Ord_oexp: "\<lbrakk>Ord(a); Ord(b)\<rbrakk> \<Longrightarrow> Ord(a ^^ b)"
  apply (erule_tac i = b in trans_induct3)
    apply simp                        \<comment> \<open>a ^^ 0 = 1\<close>
   apply simp                         \<comment> \<open>Ord_omult 是 TC 规则，自动吃 IH\<close>
  apply (subst oexp_Limit)            \<comment> \<open>极限款：先展开成 OUnion\<close>
    apply assumption                  \<comment> \<open>Limit(x) 就在假设里\<close>
  apply (rule Ord_OUN)                \<comment> \<open>⋃j<x. 形要配 Ord_OUN 而非 Ord_UN\<close>
  apply (simp add: lt_def)            \<comment> \<open>y<x 展成 y∈x，IH 即收\<close>
  done

lemma otow_Ord: "n \<in> nat \<Longrightarrow> Ord(otow(n))"
  apply (erule nat_induct)
   apply (simp add: otow_0 Ord_nat)
  apply (simp add: otow_succ Ord_oexp Ord_nat)
  done

lemma Ord_eps0: "Ord(eps0)"
  apply (simp add: eps0_def)
  apply (rule Ord_UN)
  apply (simp add: otow_Ord)
  done

text \<open>ω 卧在塔底：nat = δ₀ ⊆ ε₀（引理 1.21(2) 的方向之一）。\<close>

lemma nat_subset_eps0: "nat \<subseteq> eps0"
proof -
  have "otow(0) \<subseteq> (\<Union>n\<in>nat. otow(n))" by (rule UN_upper [OF nat_0I])
  thus ?thesis by (simp add: eps0_def otow_0)
qed

subsection \<open>基本序列（定义 1.83）的样板条款\<close>

text \<open>条款 (1)：ω(n) = n——nat 上的恒等 lambda 就是 ω 的基本序列。\<close>

definition fs_omega :: "i" where
  "fs_omega \<equiv> \<lambda>n\<in>nat. n"

lemma fs_omega_apply: "n \<in> nat \<Longrightarrow> fs_omega`n = n"
  by (simp add: fs_omega_def beta)

lemma fs_omega_mono: "\<lbrakk>m \<in> nat; n \<in> nat; m < n\<rbrakk> \<Longrightarrow> fs_omega`m < fs_omega`n"
  by (simp add: fs_omega_apply)

text \<open>条款 (a) 的样板：ω²(n) = ω·n——omult_Limit 逐字给出收敛：
ω·ω = ⋃k∈ω. ω·k（基本序列的上确界回到序数本身，引理 1.22）。\<close>

definition fs_omega2 :: "i" where
  "fs_omega2 \<equiv> \<lambda>n\<in>nat. nat ** n"

lemma fs_omega2_apply: "n \<in> nat \<Longrightarrow> fs_omega2`n = nat ** n"
  by (simp add: fs_omega2_def beta)

lemma fs_omega2_sup: "nat ** nat = (\<Union>k\<in>nat. nat ** k)"
  by (rule omult_Limit [OF Ord_nat Limit_nat])

text \<open>ε₀ 自己的基本序列（定义 1.83(3)）：ε₀(0)=0、ε₀(n+1)=ω^{ε₀(n)}
——链条现形：ε₀(1)=1、ε₀(2)=ω、ε₀(3)=ω^ω，三步追上塔的第一级。
（3 在 ZF 里不是缩写，须写 succ(2)。）\<close>

definition fs_eps0 :: "i \<Rightarrow> i" where
  "fs_eps0(n) \<equiv> rec(n, 0, \<lambda>x r. nat ^^ r)"

lemma fs_eps0_0: "fs_eps0(0) = 0"
  by (simp add: fs_eps0_def)

lemma fs_eps0_succ: "n \<in> nat \<Longrightarrow> fs_eps0(succ(n)) = nat ^^ fs_eps0(n)"
  by (simp add: fs_eps0_def)

lemma fs_eps0_1: "fs_eps0(1) = 1"
  by (simp add: fs_eps0_succ [OF nat_0I] fs_eps0_0)

lemma fs_eps0_2: "fs_eps0(2) = nat"
  by (simp add: fs_eps0_succ [OF nat_1I] fs_eps0_1 oexp_1 [OF Ord_nat])

lemma fs_eps0_3: "fs_eps0(succ(2)) = nat ^^ nat"
  by (simp add: fs_eps0_succ [OF nat_2I] fs_eps0_2)

end
