theory Transmodel
  imports ZF
begin

text \<open>第 85 章 · 传递模型与内在模型论（冯琦第二卷 §1.2）。
例 1.7：传递载体上，相对化的同一律就是外延公理。
定理 1.22：子载体若对每个存在公式都含见证，则与原结构初等。\<close>

section \<open>例 1.7\<close>

lemma transitive_relativized_extensionality:
  assumes tr: "Transset(M)" and aM: "a \<in> M" and bM: "b \<in> M"
  shows "(\<forall>x\<in>M. x \<in> a \<longleftrightarrow> x \<in> b) \<longleftrightarrow> a = b"
proof
  assume h: "\<forall>x\<in>M. x \<in> a \<longleftrightarrow> x \<in> b"
  have aSub: "a \<subseteq> M" and bSub: "b \<subseteq> M"
    using tr aM bM unfolding Transset_def by auto
  have "a \<subseteq> b"
  proof (rule subsetI)
    fix x assume xa: "x \<in> a"
    have xM: "x \<in> M" by (rule subsetD [OF aSub xa])
    from h xM xa show "x \<in> b" by blast
  qed
  moreover have "b \<subseteq> a"
  proof (rule subsetI)
    fix x assume xb: "x \<in> b"
    have xM: "x \<in> M" by (rule subsetD [OF bSub xb])
    from h xM xb show "x \<in> a" by blast
  qed
  ultimately show "a = b" by (rule equalityI)
next
  assume "a = b"
  then show "\<forall>x\<in>M. x \<in> a \<longleftrightarrow> x \<in> b" by simp
qed

section \<open>定理 1.22\<close>

consts fm :: i
datatype
  "fm" = feq ("i \<in> nat", "j \<in> nat")
       | fneg ("p \<in> fm")
       | fand ("p \<in> fm", "q \<in> fm")
       | fex ("p \<in> fm")

declare fm.intros [TC]

consts sat :: "[i,i] => i"
primrec
  "sat(U,feq(i,j)) =
     (\<lambda>env \<in> list(U). bool_of_o (nth(i,env) = nth(j,env)))"
  "sat(U,fneg(p)) =
     (\<lambda>env \<in> list(U). bool_of_o (\<not> sat(U,p)`env = 1))"
  "sat(U,fand(p,q)) =
     (\<lambda>env \<in> list(U). bool_of_o (sat(U,p)`env = 1 \<and> sat(U,q)`env = 1))"
  "sat(U,fex(p)) =
     (\<lambda>env \<in> list(U). bool_of_o (\<exists>x\<in>U. sat(U,p)`Cons(x,env) = 1))"

lemma sat_type: "p \<in> fm \<Longrightarrow> sat(U,p) \<in> list(U) -> bool"
  by (induct set: fm) simp_all

abbreviation strue :: "[i,i,i] => o" where
  "strue(U,p,env) \<equiv> sat(U,p)`env = 1"

lemma strue_eq_iff [simp]:
  "env \<in> list(U) \<Longrightarrow> strue(U,feq(i,j),env) \<longleftrightarrow> nth(i,env) = nth(j,env)"
  by simp
lemma strue_neg_iff [simp]:
  "env \<in> list(U) \<Longrightarrow> strue(U,fneg(p),env) \<longleftrightarrow> \<not> strue(U,p,env)"
  by simp
lemma strue_and_iff [simp]:
  "env \<in> list(U) \<Longrightarrow> strue(U,fand(p,q),env) \<longleftrightarrow> strue(U,p,env) \<and> strue(U,q,env)"
  by simp
lemma strue_ex_iff [simp]:
  "env \<in> list(U) \<Longrightarrow> strue(U,fex(p),env) \<longleftrightarrow> (\<exists>x\<in>U. strue(U,p,Cons(x,env)))"
  by simp

declare sat.simps [simp del]

theorem tarski_agreement:
  assumes sub: "B \<subseteq> A"
    and closed: "\<And>p env. \<lbrakk>p \<in> fm; env \<in> list(B); strue(A,fex(p),env)\<rbrakk>
                   \<Longrightarrow> \<exists>x\<in>B. strue(A,p,Cons(x,env))"
    and pt: "p \<in> fm"
  shows "\<forall>env\<in>list(B). strue(B,p,env) \<longleftrightarrow> strue(A,p,env)"
  using pt
proof (induct p)
  case (feq i j)
  show ?case
  proof (rule ballI)
    fix env assume envB: "env \<in> list(B)"
    have envA: "env \<in> list(A)"
      by (rule subsetD [OF list_mono [OF sub] envB])
    show "strue(B,feq(i,j),env) \<longleftrightarrow> strue(A,feq(i,j),env)"
      by (simp add: strue_eq_iff [OF envB] strue_eq_iff [OF envA])
  qed
next
  case (fneg p)
  show ?case
  proof (rule ballI)
    fix env assume envB: "env \<in> list(B)"
    have envA: "env \<in> list(A)"
      by (rule subsetD [OF list_mono [OF sub] envB])
    have IH: "strue(B,p,env) \<longleftrightarrow> strue(A,p,env)"
      by (rule bspec [OF fneg(2) envB])
    then show "strue(B,fneg(p),env) \<longleftrightarrow> strue(A,fneg(p),env)"
      by (simp add: strue_neg_iff [OF envB] strue_neg_iff [OF envA])
  qed
next
  case (fand p q)
  show ?case
  proof (rule ballI)
    fix env assume envB: "env \<in> list(B)"
    have envA: "env \<in> list(A)"
      by (rule subsetD [OF list_mono [OF sub] envB])
    have IHp: "strue(B,p,env) \<longleftrightarrow> strue(A,p,env)"
      by (rule bspec [OF fand(2) envB])
    have IHq: "strue(B,q,env) \<longleftrightarrow> strue(A,q,env)"
      by (rule bspec [OF fand(4) envB])
    show "strue(B,fand(p,q),env) \<longleftrightarrow> strue(A,fand(p,q),env)"
      by (simp add: strue_and_iff [OF envB] strue_and_iff [OF envA] IHp IHq)
  qed
next
  case (fex p)
  show ?case
  proof (rule ballI)
    fix env assume envB: "env \<in> list(B)"
    have envA: "env \<in> list(A)"
      by (rule subsetD [OF list_mono [OF sub] envB])
    show "strue(B,fex(p),env) \<longleftrightarrow> strue(A,fex(p),env)"
    proof
      assume h: "strue(B,fex(p),env)"
      then have "\<exists>x\<in>B. strue(B,p,Cons(x,env))"
        by (rule strue_ex_iff [OF envB, THEN iffD1])
      then obtain x where xB: "x \<in> B" and hx: "strue(B,p,Cons(x,env))"
        by (rule bexE)
      have cB: "Cons(x,env) \<in> list(B)" using xB envB by simp
      have hxA: "strue(A,p,Cons(x,env))"
        by (rule bspec [OF fex(2) cB, THEN iffD1, OF hx])
      have xA: "x \<in> A" by (rule subsetD [OF sub xB])
      have "\<exists>x\<in>A. strue(A,p,Cons(x,env))"
        using hxA xA by (rule bexI)
      then show "strue(A,fex(p),env)"
        by (rule strue_ex_iff [OF envA, THEN iffD2])
    next
      assume h: "strue(A,fex(p),env)"
      from closed [OF fex(1) envB h]
      obtain x where xB: "x \<in> B" and hx: "strue(A,p,Cons(x,env))"
        by (rule bexE)
      have cB: "Cons(x,env) \<in> list(B)" using xB envB by simp
      have "strue(B,p,Cons(x,env))"
        by (rule bspec [OF fex(2) cB, THEN iffD2, OF hx])
      then have "\<exists>x\<in>B. strue(B,p,Cons(x,env))" using xB by (rule bexI)
      then show "strue(B,fex(p),env)"
        by (rule strue_ex_iff [OF envB, THEN iffD2])
    qed
  qed
qed

end
