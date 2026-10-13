theory Models
  imports "ZF-Constructible.Formula"
begin

text \<open>
第 10 章 模型：公式的一阶语法与满足语义。

Isabelle/ZF 的 Constructible/Formmla.thy 给出集合论语言的
**官方算术化**：formula 是归纳数据类型（Member/Eq/Nand/Forall
四个构造子），sats 是满足关系。这是第 12-15 章（L 的构造
与绝对性）的语法底座。
\<close>

section \<open>公式的归纳类型\<close>

text \<open>四个构造子：x∈y、x=y、非与（否定由 Nand p p 派生）、全称。
逻辑联结词 And/Or/Implies/Iff/Exists 全部由此派生：\<close>
thm And_type

thm Or_type

thm Implies_type

thm Exists_type

section \<open>满足语义\<close>

text \<open>sats(A, p, env)：结构 A（带 ∈ 的类）在赋值 env 下满足 p。
四个构造子的语义条款：\<close>
thm sats_Member_iff

thm sats_Equal_iff

thm sats_Nand_iff

thm sats_Forall_iff

section \<open>受限量词与绝对性的预告\<close>

text \<open>引理 10.1：受限公式（受限（Delta0））在传递类之间绝对。
ZF 库为此准备了 \<exists> 的受限形态与 absoluteness 框架
（Relative.thy/DPow_absolute.thy）——第 12 章的正题。\<close>

text \<open>x ∈ y 的满足语义（sats 的 Member 条款）：
     sats(A, Member(x,y), env) \<longleftrightarrow> nth(x,env) ∈ nth(y,env)
     ——满足关系忠实翻译成员关系，语义正确性的基线。\<close>

end
