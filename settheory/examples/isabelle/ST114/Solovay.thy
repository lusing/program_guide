theory Solovay
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 114 章：Solovay 内模型与 HOD(Ω)——群作用下的不变对象与
可定义性交换、轨道封闭、配对整合与 DC 链（引理 3.22 的机制核，沿
103-113 章确定性规则链纪律）。Z/8 数值窗口在 ZF 有数字解析坑
（数字 \<ge>3 在 ZF 序位置不解析），故群作用改取**表旋转**：宇宙是
0/1 数字表（list(nat)），生成元 rotl 是循环左移——置换的阶恰给出
非平凡稳定子。本体（Col(ω,<κ)、OD(Ω)、HOD(Ω)、定理 3.24）留在正文。\<close>

subsection\<open>生成元：循环左移（C4 作用的表形态）\<close>

consts
  rotl :: "i\<Rightarrow>i"

primrec
  "rotl(Nil) = Nil"
  "rotl(Cons(a, l)) = l @ [a]"

text \<open>旋转长度不减、成员不变（确定性链）。\<close>

lemma rotl_type [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> rotl(u) \<in> list(nat)"
  apply (erule_tac x = u in list.induct)
  apply simp_all
  done

lemma rotl_mem [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> \<forall>b \<in> nat. (b \<in> set_of_list(u) \<longleftrightarrow> b \<in> set_of_list(rotl(u)))"
  apply (erule_tac x = u in list.induct)
  apply (simp_all add: set_of_list_append)
  apply blast
  done

subsection\<open>不变对象：位和与交替表（生成元下的不变量）\<close>

text \<open>位和（0/1 表的元素和）在旋转下不变——不变对象定理。\<close>

consts
  bsum :: "i\<Rightarrow>i"

primrec
  "bsum(Nil) = 0"
  "bsum(Cons(a, l)) = a #+ bsum(l)"

lemma bsum_snoc [rule_format]:
  "l \<in> list(nat) \<Longrightarrow> a \<in> nat \<Longrightarrow> bsum(l @ [a]) = bsum(l) #+ a"
  apply (erule_tac x = l in list.induct)
  apply simp_all
  done

lemma bsum_rotl [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> bsum(rotl(u)) = bsum(u)"
  apply (erule_tac x = u in list.induct)
  apply (simp_all add: bsum_snoc add_commute)
  done

text \<open>实例：四位置上的周期二表 [0,1,0,1]（稳定子非平凡的见证）。\<close>

lemma rotl_0101: "rotl([0, 1, 0, 1]) = [1, 0, 1, 0]"
  apply simp
  done

lemma rotl2_0101: "rotl(rotl([0, 1, 0, 1])) = [0, 1, 0, 1]"
  apply simp
  done

text \<open>实例：全零表是不动点（平凡稳定子=全群的另一端）。\<close>

lemma rotl_0000: "rotl([0, 0, 0, 0]) = [0, 0, 0, 0]"
  apply simp
  done

subsection\<open>稳定子样本：周期二与不动点（群作用的轨道分层）\<close>

text \<open>ZF 上归纳关系（pair-域的 inductive）在 erule 下有高阶统一飘移
风险（113 章实测），故「定义与群作用交换」（件 A）由 Lean/Coq/Agda
数值窗口承担；本节给出稳定子的两个确定性样本：周期二表（非平凡
稳定子含 rotl\<circ>rotl）与全零表（全群不动点）。\<close>

subsection\<open>DC 链（引理 3.22(2) 机制核）\<close>

consts
  rots :: "[i, i] \<Rightarrow> i"

text \<open>生成元迭代：rots(n, a) = rotl^n(a)（非递归参原样传递——
ZF primrec 的合法性要求；DC 链的一般形式由 Lean/Coq/Agda 承担）。\<close>

primrec
  "rots(0, a) = a"
  "rots(succ(n), a) = rotl(rots(n, a))"

text \<open>迭代方程（unfold 一步）。\<close>

lemma rots_step [rule_format]:
  "rots(succ(n), a) = rotl(rots(n, a))"
  apply simp
  done

text \<open>周期二实例：五步链在两条表之间往返（选择函数的轨道链）。\<close>

lemma rots_1_0101: "rots(1, [0, 1, 0, 1]) = [1, 0, 1, 0]"
  apply simp
  done

lemma rots_2_0101: "rots(2, [0, 1, 0, 1]) = [0, 1, 0, 1]"
  apply simp
  done

lemma rots_4_0101: "rots(succ(succ(2)), [0, 1, 0, 1]) = [0, 1, 0, 1]"
  apply simp
  done

end
