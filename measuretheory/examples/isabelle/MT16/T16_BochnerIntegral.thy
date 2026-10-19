theory T16_BochnerIntegral
  imports "HOL-Analysis.Analysis"
begin

section \<open>第 16 章：Bochner 积分（有限空间上的向量实弹）\<close>

text \<open>对应严书 3.7。Isabelle 的 Bochner 积分在
Bochner_Integration：核心谓词 has_bochner_integral M f x 与
函数 bochner_integral。有限计数空间上向量值积分退化为有限和
（lebesgue_integral_count_space_finite）。\<close>

subsection \<open>向量值积分 = 逐分量和\<close>

lemma bochner_count_vec:
  fixes a b :: real
  shows "(LINT x|count_space {0,1::nat}. (if x = 1 then a else 0, if x = 1 then b else 0))
       = (a, b)"
  by (simp add: lebesgue_integral_count_space_finite)

subsection \<open>has_bochner_integral 的存在性引用\<close>

lemma has_bochner_count_vec:
  fixes a b :: real
  shows "has_bochner_integral (count_space {0,1::nat})
           (\<lambda>x::nat. (if x = 1 then a else 0, if x = 1 then b else 0)) (a, b)"
proof -
  have hf: "integrable (count_space {0,1::nat})
          (\<lambda>x::nat. (if x = 1 then a else 0, if x = 1 then b else 0))"
    by (simp add: integrable_iff_bounded nn_integral_count_space_finite)
  from has_bochner_integral_integrable[OF hf]
  have h1: "has_bochner_integral (count_space {0,1::nat})
          (\<lambda>x::nat. (if x = 1 then a else 0, if x = 1 then b else 0))
          (integral\<^sup>L (count_space {0,1::nat})
             (\<lambda>x::nat. (if x = 1 then a else 0, if x = 1 then b else 0)))" .
  from h1[simplified bochner_count_vec]
  show ?thesis .
qed

end
