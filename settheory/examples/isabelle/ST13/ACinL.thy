theory ACinL
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 13 章 AC 与 GCH 在 L 中。

AC_in_L.thy 是 Isabelle/ZF Constructible 会话的招牌：
L 的典范良序 L_r（定理 33 的机器形态）与 AC 在 L 中的
完整证明。GCH 的机器化（定理 34）未在库中——由讲义与
计算通道承载。
\<close>

section \<open>L 的典范良序（定理 33 的机器形态）\<close>

text \<open>well_ord_L_r：L_r 良序化（(13.8) 的官方版本）：\<close>
thm well_ord_L_r

section \<open>AC 在 L 中（定理 33 的主体）\<close>

text \<open>L(x) ⟹ x 可良序化（对每个 L(x) 实例化即全局形态）：\<close>
thm L_implies_AC

section \<open>GCH 的语义（定理 34 讲义）\<close>

text \<open>引理 13.1（X ⊆ ω_α ⟹ X ∈ L_γ，某 γ < ω_{α+1}）的
证明用 Condensation：取可数充分集 M ⊇ {X, ω_α}，坍缩 M 为
传递 N，绝对性给 N = L_γ（γ 可数 < ω_{α+1}），X ∈ N = L_γ。
配合 |L_γ| = |γ| 的归纳——P(ω_α) ⊆ L_{ω_{α+1}} 给出
2^{ℵ_α} ≤ ℵ_{α+1}；Cantor 给反向。∎\<close>

end
