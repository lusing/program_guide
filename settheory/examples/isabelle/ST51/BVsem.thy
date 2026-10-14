theory BVsem
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 51 章 B-值等词三律的谓词式骨架（B = Pow(A0) 实例上）。\<close>

definition
  beq :: "[i, i, i] \<Rightarrow> i" where
  "beq(A0, x, y) \<equiv> (if x = y then A0 else 0)"

text \<open>反身：beq(x,x) = A0 = Pow(A0) 的顶。\<close>

lemma beq_refl: "beq(A0, x, x) = A0"
  unfolding beq_def by simp

text \<open>对称。\<close>

lemma beq_sym: "beq(A0, x, y) = beq(A0, y, x)"
  unfolding beq_def by simp

text \<open>传递（弱形式 x ⊆ y 的化身：beq(x,y) ∩ beq(y,z) \<subseteq> beq(x,z)）。\<close>

lemma beq_trans:
  "beq(A0, x, y) \<inter> beq(A0, y, z) \<subseteq> beq(A0, x, z)"
proof (rule subsetI)
  fix w
  assume "w \<in> beq(A0, x, y) \<inter> beq(A0, y, z)"
  then have h1: "w \<in> beq(A0, x, y)" and h2: "w \<in> beq(A0, y, z)"
    by simp+
  show "w \<in> beq(A0, x, z)"
  proof (cases "x = y")
    case True
    from h2 show ?thesis
    proof (cases "y = z")
      case True
      then have hxz: "x = z" using \<open>x = y\<close> by simp
      from h2 \<open>y = z\<close> have hw: "w \<in> A0" unfolding beq_def by simp
      from hxz hw show ?thesis unfolding beq_def by simp
    next
      case False
      then have "w \<in> 0" using h2 unfolding beq_def by simp
      then show ?thesis by simp
    qed
  next
    case False
    then have "w \<in> 0" using h1 unfolding beq_def by simp
    then show ?thesis by simp
  qed
qed

end
