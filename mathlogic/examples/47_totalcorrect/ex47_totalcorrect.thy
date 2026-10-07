(* ex47_totalcorrect —— 完全正确性（Isabelle/HOL 版，H&R §4.4 / §4.3.3）

   与 Coq/Lean 版同构：hoareT（终止内建）+ hoareT_while_layered
   （total-while 分层形态）+ countdown_total + amin 吸收律构件。

   工程注记：exec 的 inductive 规则默认进 intro 集——blast/auto/
   force 在含 exec 的目标上会沿 eWhileT 无限展开（实测 600s+ 不止，
   内存 1GB+）。本文件的纪律：exec 相关目标一律 metis（只吃给定
   事实）或定向 rule 应用；算术走 linarith，不走搜索。 *)
theory ex47_totalcorrect
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
   体前提参数化 n（本轮变体初值），后件 V < n：每轮严格降。
   对变体上界 n 做普通归纳（严格降保证 Suc 情形回落到 n）。 *)
theorem hoareT_while_layered:
  assumes hpos: "\<And>s. P s \<Longrightarrow> b s \<Longrightarrow> (0::nat) < V s"
    and hbody: "\<And>n. hoareT (\<lambda>s. P s \<and> b s \<and> V s = n) c
                         (\<lambda>s. P s \<and> V s < n)"
  shows "hoareT P (cwhile b c) (\<lambda>s. P s \<and> \<not> b s)"
proof -
  have hmain: "\<And>(n::nat) (s1::state). P s1 \<Longrightarrow> V s1 \<le> n \<Longrightarrow>
      \<exists>s2. exec (cwhile b c) s1 s2 \<and> P s2 \<and> \<not> b s2"
  proof -
    fix n :: nat and s1 :: state
    show "P s1 \<Longrightarrow> V s1 \<le> n \<Longrightarrow>
        \<exists>s2. exec (cwhile b c) s1 s2 \<and> P s2 \<and> \<not> b s2"
    proof (induct n arbitrary: s1)
      case 0
      then have HP: "P s1" and HV: "V s1 = 0" by auto
      show ?case
      proof (cases "b s1")
        case True
        then have "0 < V s1" using hpos HP by metis
        with HV show ?thesis by simp
      next
        case False
        then show ?thesis using eWhileF HP by metis
      qed
    next
      case (Suc n)
      then have HP: "P s1" and HV: "V s1 \<le> Suc n" by auto
      show ?case
      proof (cases "b s1")
        case True
        then have "0 < V s1" using hpos HP by metis
        note hI = hbody[of "V s1", unfolded hoareT_def, rule_format,
                        OF conjI[OF HP conjI[OF True refl]]]
        then obtain s2 where hex: "exec c s1 s2"
          and HP2: "P s2" and HV2: "V s2 < V s1" by metis
        then have HV2n: "V s2 \<le> n" using HV by linarith
        note IH = Suc.hyps[of s2, OF HP2 HV2n]
        then obtain s3 where hex23: "exec (cwhile b c) s2 s3"
          and HP3: "P s3" and Hb3: "\<not> b s3" by metis
        show ?thesis
          using eWhileT[of b s1 c s2 s3] True hex hex23 HP3 Hb3 by metis
      next
        case False
        then show ?thesis using eWhileF HP by metis
      qed
    qed
  qed
  show ?thesis unfolding hoareT_def
  proof (intro allI impI)
    fix s1 assume HP1: "P s1"
    from hmain[of s1 "V s1", OF HP1 Nat.le_refl]
    show "\<exists>s2. exec (cwhile b c) s1 s2 \<and> P s2 \<and> \<not> b s2" .
  qed
qed

(* ---------- countdown 的完全正确性 ---------- *)

definition countdown :: "nat \<Rightarrow> nat \<Rightarrow> cmd" where
  "countdown x y = cwhile (\<lambda>s. s x \<noteq> 0)
    (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1)))"

(* 变体 = s x；不变式 = s x + s y = C；别名前提 x \<noteq> y *)
theorem countdown_total:
  assumes hxy: "x \<noteq> y" and hinv: "s1 x + s1 y = C"
  shows "\<exists>s2. exec (countdown x y) s1 s2 \<and> s2 x + s2 y = C \<and> s2 x = 0"
proof -
  have hpos: "\<And>s. s x + s y = C \<Longrightarrow> s x \<noteq> 0 \<Longrightarrow> (0::nat) < s x" by auto
  have hbody: "\<And>n. hoareT (\<lambda>s. s x + s y = C \<and> s x \<noteq> 0 \<and> s x = n)
      (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1)))
      (\<lambda>s. s x + s y = C \<and> s x < n)"
    unfolding hoareT_def
  proof (intro allI impI)
    fix n :: nat and s :: state
    assume HP: "s x + s y = C \<and> s x \<noteq> 0 \<and> s x = n"
    then have Hne: "s x \<noteq> 0" and Hn: "s x = n" and HC: "s x + s y = C"
      by auto
    then have H0: "(0::nat) < s x" by simp
    define s2 where "s2 = upd (upd s x (s x - 1)) y (upd s x (s x - 1) y + 1)"
    have ex1: "exec (cass x (\<lambda>s. s x - 1)) s (upd s x (s x - 1))"
      by (rule eAss)
    have ex2: "exec (cass y (\<lambda>s. s y + 1)) (upd s x (s x - 1)) s2"
      unfolding s2_def by (rule eAss)
    have exS: "exec (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1))) s s2"
      by (rule eSeq[OF ex1 ex2])
    have rx: "s2 x = s x - 1"
      unfolding s2_def upd_def using hxy by simp
    have ry: "s2 y = s y + 1"
      unfolding s2_def upd_def using hxy by simp
    show "\<exists>s2a. exec (cseq (cass x (\<lambda>s. s x - 1))
               (cass y (\<lambda>s. s y + 1))) s s2a \<and>
              s2a x + s2a y = C \<and> s2a x < n"
    proof (rule exI[of _ s2], rule conjI[OF exS], rule conjI)
      show "s2 x + s2 y = C" using rx ry HC H0 by linarith
    next
      show "s2 x < n" using rx Hn H0 by linarith
    qed
  qed
  have U: "hoareT (\<lambda>s. s x + s y = C)
      (cwhile (\<lambda>s. s x \<noteq> 0)
        (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1))))
      (\<lambda>s. s x + s y = C \<and> \<not> (s x \<noteq> 0))"
    apply (rule hoareT_while_layered[of "\<lambda>s. s x + s y = C" "\<lambda>s. s x \<noteq> 0"
        "\<lambda>s. s x" "cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1))"])
    subgoal by (rule hpos)
    subgoal by (rule hbody)
    done
  have hp: "(\<lambda>s. s x + s y = C) s1" using hinv by simp
  note mainI = U[unfolded hoareT_def, rule_format, OF hp]
  then obtain s2 where hex: "exec (cwhile (\<lambda>s. s x \<noteq> 0)
      (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1)))) s1 s2"
    and hq: "s2 x + s2 y = C" and hq0: "s2 x = 0"
    by metis
  show ?thesis unfolding countdown_def using hex hq hq0 by metis
qed

(* ---------- minsum 构件（H&R §4.3.3 教学版） ---------- *)

definition amin :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "amin u v = (if u \<le> v then u else v)"

lemma amin_le_left: "amin u v \<le> u"
  unfolding amin_def by auto

lemma amin_le_right: "amin u v \<le> v"
  unfolding amin_def by auto

lemma amin_min: "w \<le> u \<Longrightarrow> w \<le> v \<Longrightarrow> w \<le> amin u v"
  unfolding amin_def by auto

end
