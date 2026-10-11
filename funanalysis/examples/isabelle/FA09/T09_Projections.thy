theory T09_Projections
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 09 章（Isabelle 通道）：幂等与投影（Conway II.3）在 real^2 的化身。
  1. I - E 幂等（Conway 3.2 (a)）；
  2. ran E = ker (I - E)（Conway 3.2 (b)）；
  3. 斜投影实例 obl(x,y) = (x+y, 0)：幂等但放大范数（axis 分解式，
     避开坐标枚举）。
\<close>

section \<open>幂等的一般事实（Conway 3.2）\<close>

lemma idem_I_minus_idem:
  assumes lin: "linear E" and hE: "\<And>x. E (E x) = E x"
  shows "(id - E) ((id - E) x) = (id - E) x"
proof -
  interpret El: linear E by (rule lin)
  have hsub: "E (x - E x) = E x - E (E x)"
    by (simp add: El.diff)
  have "(id - E) ((id - E) x) = (x - E x) - E (x - E x)" by simp
  also have "\<dots> = (x - E x) - (E x - E (E x))" using hsub by simp
  also have "\<dots> = (id - E) x" using hE by simp
  finally show ?thesis .
qed


end
