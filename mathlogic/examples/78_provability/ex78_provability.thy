(* ex78 —— 可证性条件 D1-D3、对角化与 Loeb 定理（Isabelle/HOL 版）
   locale prov 打包 der（T ⊢ α）/重言封闭/分离规则/D1/D2/D3/对角化引理，
   与 Coq/Lean 通道同账：(D0) 引理 10.1.1；□g→□⊥ 账；¬□ 不动点 ⟺ con；
   (10.2)；Godel 第二不完备；Loeb 步引理/公理 D4/规则形；Henkin 问题的
   答案；Godel II 的 Loeb 一行版。 *)
theory ex78_provability
  imports Main
begin

datatype form =
  Atom nat
| FBot
| FImp "form" "form"
| FBox "form"

primrec mval :: "(nat \<Rightarrow> bool) \<Rightarrow> (form \<Rightarrow> bool) \<Rightarrow> form \<Rightarrow> bool" where
  "mval v bx (Atom n) = v n"
| "mval v bx FBot = False"
| "mval v bx (FImp a b) = (mval v bx a \<longrightarrow> mval v bx b)"
| "mval v bx (FBox x) = bx x"

definition Taut :: "form \<Rightarrow> bool" where
  "Taut a \<equiv> \<forall>v bx. mval v bx a"

text \<open>可证性条件的 locale：六条假设（重言封闭、分离、D1、D2、D3、对角化）。\<close>

locale prov =
  fixes der :: "form \<Rightarrow> bool"                (* T \<turnstile> \<alpha> *)
  assumes htaut: "\<And>a. Taut a \<Longrightarrow> der a"
  assumes hmp: "\<And>a b. der (FImp a b) \<Longrightarrow> der a \<Longrightarrow> der b"
  assumes hd1: "\<And>a. der a \<Longrightarrow> der (FBox a)"                                  (* (D1) *)
  assumes hd2: "\<And>a b. der (FImp (FBox (FImp a b)) (FImp (FBox a) (FBox b)))"        (* (D2) *)
  assumes hd3: "\<And>a. der (FImp (FBox a) (FBox (FBox a)))"                            (* (D3) *)
  assumes hdiag: "\<And>b. \<exists>g. der (FImp g (FImp (FBox g) b)) \<and>
                          der (FImp (FImp (FBox g) b) g)"
begin

text \<open>两个组合子：重言提升与链式传递。\<close>

lemma tauti: "(\<forall>v bx. mval v bx a \<longrightarrow> mval v bx b) \<Longrightarrow> der (FImp a b)"
  using htaut[of "FImp a b"] unfolding Taut_def by simp

lemma imp_trans: "der (FImp a b) \<Longrightarrow> der (FImp b c) \<Longrightarrow> der (FImp a c)"
proof -
  assume hab: "der (FImp a b)" and hbc: "der (FImp b c)"
  have T: "Taut (FImp (FImp a b) (FImp (FImp b c) (FImp a c)))"
    unfolding Taut_def by auto
  show ?thesis using hmp[OF hmp[OF htaut[OF T] hab] hbc] .
qed

lemma imp_distr: "der (FImp a (FImp b c)) \<Longrightarrow> der (FImp a b) \<Longrightarrow> der (FImp a c)"
proof -
  assume h1: "der (FImp a (FImp b c))" and h2: "der (FImp a b)"
  have T: "Taut (FImp (FImp a (FImp b c)) (FImp (FImp a b) (FImp a c)))"
    unfolding Taut_def by auto
  show ?thesis using hmp[OF hmp[OF htaut[OF T] h1] h2] .
qed

text \<open>(D0)：引理 10.1.1——D1 与 D2 的联合。\<close>

lemma D0: "der (FImp a c) \<Longrightarrow> der (FImp (FBox a) (FBox c))"
  using hmp[OF hd2 hd1] .

text \<open>一致性句子 con := \<not>\<box>\<bottom>。\<close>

definition conf :: form where "conf = FImp (FBox FBot) FBot"

text \<open>关键账：g \<leftrightarrow> \<not>\<box>g 的不动点满足 \<turnstile> \<box>g \<rightarrow> \<box>\<bottom>。\<close>

lemma boxg_boxbot:
  assumes hfwd: "der (FImp g (FImp (FBox g) FBot))"
  shows "der (FImp (FBox g) (FBox FBot))"
proof -
  have h1: "der (FImp (FBox g) (FBox (FImp (FBox g) FBot)))" by (rule D0[OF hfwd])
  have h2: "der (FImp (FBox (FImp (FBox g) FBot))
                    (FImp (FBox (FBox g)) (FBox FBot)))" by (rule hd2)
  have h3: "der (FImp (FBox g) (FBox (FBox g)))" by (rule hd3)
  show ?thesis using imp_distr[OF imp_trans[OF h1 h2] h3] .
qed

text \<open>定理 10.4.1 断言：\<not>\<box> 的不动点在 T 等价意义下唯一——都等价于 con。\<close>

lemma godel_sentence_iff_con:
  assumes hfwd: "der (FImp g (FImp (FBox g) FBot))"
    and hrev: "der (FImp (FImp (FBox g) FBot) g)"
  shows "der (FImp g conf) \<and> der (FImp conf g)"
proof -
  have hbb: "der (FImp (FBox g) (FBox FBot))" by (rule boxg_boxbot[OF hfwd])
  txt \<open>g \<rightarrow> con：\<bottom>\<rightarrow>g 是重言式，D0 得 \<box>\<bottom>\<rightarrow>\<box>g；与 hfwd 拼\<close>
  have hf: "der (FImp FBot g)" by (rule tauti) simp
  have hbg: "der (FImp (FBox FBot) (FBox g))" by (rule D0[OF hf])
  have hc2: "der (FImp (FImp (FBox FBot) (FBox g))
                    (FImp (FImp g (FImp (FBox g) FBot)) (FImp g conf)))"
    by (rule tauti) (auto simp: conf_def)
  have leg1: "der (FImp g conf)" by (rule hmp[OF hmp[OF hc2 hbg] hfwd])
  txt \<open>con \<rightarrow> g\<close>
  have hc1: "der (FImp (FImp (FBox g) (FBox FBot))
                    (FImp conf (FImp (FBox g) FBot)))"
    by (rule tauti) (auto simp: conf_def)
  have leg2: "der (FImp conf g)" by (rule imp_trans[OF hmp[OF hc1 hbb] hrev])
  show ?thesis using leg1 leg2 ..
qed

text \<open>(10.2)：T \<turnstile> con \<rightarrow> \<not>\<box>con。\<close>

lemma con_unprovable_formal: "der (FImp conf (FImp (FBox conf) FBot))"
proof -
  obtain g where hfwd: "der (FImp g (FImp (FBox g) FBot))"
    and hrev: "der (FImp (FImp (FBox g) FBot) g)"
    using hdiag[of FBot] by auto
  note cc = godel_sentence_iff_con[OF hfwd hrev]
  have hcon_g: "der (FImp conf g)" using cc[THEN conjunct2] .
  have hbb: "der (FImp (FBox g) (FBox FBot))" by (rule boxg_boxbot[OF hfwd])
  have h1: "der (FImp (FBox conf) (FBox g))" by (rule D0[OF hcon_g])
  have h2: "der (FImp (FBox conf) (FBox FBot))" by (rule imp_trans[OF h1 hbb])
  have ht: "der (FImp (FImp (FBox conf) (FBox FBot))
                    (FImp conf (FImp (FBox conf) FBot)))"
    by (rule tauti) (auto simp: conf_def)
  show ?thesis using hmp[OF ht h2] .
qed

text \<open>Godel II（机器面）：若 T \<turnstile> con 则 T \<turnstile> \<bottom>。\<close>

lemma goedel_second: "der conf \<Longrightarrow> der FBot"
  using hmp[OF hmp[OF con_unprovable_formal] hd1] .

text \<open>Loeb 步引理（书中 (10.4) 前半）。\<close>

lemma lob_step:
  assumes hfwd: "der (FImp h (FImp (FBox h) a))"
  shows "der (FImp (FBox h) (FBox a))"
proof -
  have h1: "der (FImp (FBox h) (FBox (FImp (FBox h) a)))" by (rule D0[OF hfwd])
  have h2: "der (FImp (FBox (FImp (FBox h) a))
                    (FImp (FBox (FBox h)) (FBox a)))" by (rule hd2)
  have h3: "der (FImp (FBox h) (FBox (FBox h)))" by (rule hd3)
  show ?thesis using imp_distr[OF imp_trans[OF h1 h2] h3] .
qed

text \<open>Loeb 公理形（(D4)）：\<turnstile> \<box>(\<box>a\<rightarrow>a) \<rightarrow> \<box>a。\<close>

lemma lob_axiom: "der (FImp (FBox (FImp (FBox a) a)) (FBox a))"
proof -
  obtain h where hfwd: "der (FImp h (FImp (FBox h) a))"
    and hrev: "der (FImp (FImp (FBox h) a) h)"
    using hdiag[of a] by auto
  have h4: "der (FImp (FBox h) (FBox a))" by (rule lob_step[OF hfwd])
  have ht: "der (FImp (FImp (FBox h) (FBox a))
                    (FImp (FImp (FBox a) a) (FImp (FBox h) a)))"
    by (rule tauti) auto
  have h5: "der (FImp (FImp (FBox a) a) (FImp (FBox h) a))"
    using hmp[OF ht h4] .
  have h6: "der (FImp (FImp (FBox a) a) h)" by (rule imp_trans[OF h5 hrev])
  show ?thesis using imp_trans[OF D0[OF h6] h4] .
qed

text \<open>Loeb 规则形（定理 10.4.2(2)）：若 \<turnstile> \<box>a\<rightarrow>a 则 \<turnstile> a。\<close>

lemma lob_rule:
  assumes hla: "der (FImp (FBox a) a)"
  shows "der a"
proof -
  obtain h where hfwd: "der (FImp h (FImp (FBox h) a))"
    and hrev: "der (FImp (FImp (FBox h) a) h)"
    using hdiag[of a] by auto
  have h4: "der (FImp (FBox h) (FBox a))" by (rule lob_step[OF hfwd])
  have hha: "der (FImp (FBox h) a)" by (rule imp_trans[OF h4 hla])
  have hh: "der h" using hmp[OF hrev hha] .
  show ?thesis using hmp[OF hla hmp[OF h4 hd1[OF hh]]] .
qed

text \<open>推论 10.4.1：\<box> 的不动点恰为内定理。\<close>

lemma henkin_answer:
  assumes hfwd: "der (FImp x (FBox x))" and hrev: "der (FImp (FBox x) x)"
  shows "der x"
  using lob_rule[OF hrev] .

text \<open>Godel II 的 Loeb 一行版。\<close>

lemma goedel_second_via_lob: "der conf \<Longrightarrow> der FBot"
  using lob_rule[of FBot] unfolding conf_def .

end

end
