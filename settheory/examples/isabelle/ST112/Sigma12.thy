theory Sigma12
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 112 章：有限绝对性的两翼与补集之空（确定性规则链，
沿 103-111 章纪律）。M \<subseteq> V 是「力迫扩张」的影子：存在语句沿
扩张上行、全程语句沿扩张下行（Shoenfield 绝对性的量词面）；
补集之交为空是博雷尔代码补运算（引理 3.15/3.16）的核。
本体（定理 3.7-3.14、引理 3.8-3.19）留在正文。\<close>

text \<open>上行：M 中的见证在 V 中仍是见证（Sigma 面的绝对性）。\<close>

lemma ex_upward:
  assumes hsub: "M \<subseteq> V"
    and hwit: "\<exists>m \<in> M. \<phi>(m)"
  shows "\<exists>v \<in> V. \<phi>(v)"
proof -
  from hwit obtain m where hm: "m \<in> M" and hphi: "\<phi>(m)" ..
  from hsub hm have hv: "m \<in> V" by (rule subsetD)
  show ?thesis
  proof (rule bexI [where x = m])
    from hphi show "\<phi>(m)" .
  next
    from hv show "m \<in> V" .
  qed
qed

text \<open>下行：V 中处处成立的语句限制到 M 仍处处成立（Pi 面的绝对性）。\<close>

lemma all_downward:
  assumes hsub: "M \<subseteq> V"
    and hall: "\<forall>v \<in> V. \<phi>(v)"
  shows "\<forall>m \<in> M. \<phi>(m)"
proof (rule ballI)
  fix m
  assume hm: "m \<in> M"
  from hsub hm have hv: "m \<in> V" by (rule subsetD)
  from hall hv show "\<phi>(m)" by (rule bspec)
qed

text \<open>补集之交为空（引理 3.15 的补运算核）：A 与 V-A 无公共元素。\<close>

lemma compl_inter_empty:
  shows "A \<inter> (V - A) = 0"
proof (rule equalityI)
  show "A \<inter> (V - A) \<subseteq> 0"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> A \<inter> (V - A)"
    then have hA: "x \<in> A" by (rule IntD1)
    from hx have hD: "x \<in> V - A" by (rule IntD2)
    from hD have hnA: "x \<notin> A" by (rule DiffD2)
    from hnA hA show "x \<in> 0" by (rule notE)
  qed
next
  show "0 \<subseteq> A \<inter> (V - A)" by (rule empty_subsetI)
qed

text \<open>补集之并覆盖全域（绝对性的另一半账）。\<close>

lemma compl_union_cover:
  shows "V \<subseteq> A \<union> (V - A)"
proof (rule subsetI)
  fix x
  assume hx: "x \<in> V"
  show "x \<in> A \<union> (V - A)"
  proof (rule disjE [OF excluded_middle [of "x \<in> A"]])
    assume hA: "x \<in> A"
    from hA show ?thesis by (rule UnI1)
  next
    assume hnA: "x \<notin> A"
    have hD: "x \<in> V - A"
    proof (rule DiffI)
      from hx show "x \<in> V" .
    next
      from hnA show "x \<notin> A" .
    qed
    from hD show ?thesis by (rule UnI2)
  qed
qed

end
