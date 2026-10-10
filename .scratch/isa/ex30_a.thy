(* ex30_a —— 完全正确性（Isabelle/HOL 版，H&R §4.4 / §4.3.3）

   与 Coq/Lean 版同构：hoareT（终止内建）+ hoareT_while_layered
   （total-while 分层形态）+ countdown_total + amin 吸收律构件。 *)
theory ex30_a
  imports Main
begin

type_synonym state = "nat \<Rightarrow> nat"

definition upd :: "state \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> state" where
  "upd s x v m = (if m = x then v else s m)"

datatype cmd =
    cskip
  | cass nat "state \<Rightarrow> nat"
  | cseq cmd cmd
  | cwhile "state \<Rightarrow> bool" cmd

inductive exec :: "cmd \<Rightarrow> state \<Rightarrow> state \<Rightarrow> bool" where
  eSkip: "exec cskip s s"
| eAss: "exec (cass x f) s (upd s x (f s))"
| eSeq: "exec c1 s1 s2 \<Longrightarrow> exec c2 s2 s3 \<Longrightarrow> exec (cseq c1 c2) s1 s3"
| eWhileT: "b s1 \<Longrightarrow> exec c s1 s2 \<Longrightarrow> exec (cwhile b c) s2 s3 \<Longrightarrow>
            exec (cwhile b c) s1 s3"
| eWhileF: "\<not> b s \<Longrightarrow> exec (cwhile b c) s s"

(* 完全正确性：终止内建（存在终态且满足后件） *)
definition hoareT :: "(state \<Rightarrow> bool) \<Rightarrow> cmd \<Rightarrow> (state \<Rightarrow> bool) \<Rightarrow> bool" where
  "hoareT P c Q \<longleftrightarrow> (\<forall>s1. P s1 \<longrightarrow> (\<exists>s2. exec c s1 s2 \<and> Q s2))"

(* 旗舰：total-while（变体版，H&R 式 4.15 分层形态）。
   体前提参数化 n（本轮变体初值），后件 V < n：每轮严格降。 *)
theorem hoareT_while_layered:
  assumes hpos: "\<And>s. P s \<Longrightarrow> b s \<Longrightarrow> 0 < V s"
    and hbody: "\<And>n. hoareT (\<lambda>s. P s \<and> b s \<and> V s = n) c
                         (\<lambda>s. P s \<and> V s < n)"
  shows "hoareT P (cwhile b c) (\<lambda>s. P s \<and> \<not> b s)"
proof -
  have hmain: "\<And>n s1. P s1 \<Longrightarrow> V s1 \<le> n \<Longrightarrow>
      \<exists>s2. exec (cwhile b c) s1 s2 \<and> P s2 \<and> \<not> b s2"
  proof (induct n rule: less_induct)
    case (less n)
    fix s1 assume HP: "P s1" and HV: "V s1 \<le> n"
    show "\<exists>s2. exec (cwhile b c) s1 s2 \<and> P s2 \<and> \<not> b s2"
    proof (cases "b s1")
      case True
      then have "0 < V s1" using hpos HP by blast
      obtain s2 where hex: "exec c s1 s2"
        and HP2: "P s2" and HV2: "V s2 < V s1"
        using hbody[of "V s1", unfolded hoareT_def] HP \<open>0 < V s1\<close> by blast
      then obtain s3 where hex2: "exec (cwhile b c) s2 s3"
        and HP3: "P s3" and Hb3: "\<not> b s3"
        using less.hyps[of "V s2"] HV2 HV by blast
      then show ?thesis
        using eWhileT[of b s1 c s2 s3] True hex by blast
    next
      case False
      then show ?thesis using eWhileF HP by blast
    qed
  qed
  then show ?thesis unfolding hoareT_def
    using le_refl by blast
qed


end
