(* ex25 —— 霍尔逻辑（Isabelle/HOL 版）：while 规则与倒数程序
   对书：Huth&Ryan ch4 / Ben-Ari 3e ch15

   Isabelle 的 induct 对构造子头索引自动小反转——只出
   eWhileT/eWhileF 两个 case，零额外手工（与 Coq 的 remember +
   inversion Hcw、Lean 的命令泛化 + noConfusion 成三通道对照）。 *)
theory ex46_hoare
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

definition hoare :: "(state \<Rightarrow> bool) \<Rightarrow> cmd \<Rightarrow> (state \<Rightarrow> bool) \<Rightarrow> bool" where
  "hoare P c Q \<longleftrightarrow> (\<forall>s1 s2. P s1 \<longrightarrow> exec c s1 s2 \<longrightarrow> Q s2)"

(* 旗舰一：skip 规则 *)
theorem hoare_skip: "hoare P cskip P"
  unfolding hoare_def by (auto elim: exec.cases)

(* 旗舰二：赋值公理 *)
theorem hoare_ass: "hoare (\<lambda>s. Q (upd s x (f s))) (cass x f) Q"
  unfolding hoare_def by (auto elim: exec.cases)

(* 旗舰三：顺序规则 *)
theorem hoare_seq: "hoare P c1 Q \<Longrightarrow> hoare Q c2 R \<Longrightarrow> hoare P (cseq c1 c2) R"
  unfolding hoare_def by (blast elim: exec.cases)

(* 旗舰四：while 规则——不变式 *)
theorem hoare_while:
  assumes body: "hoare (\<lambda>s. P s \<and> b s) c P"
  shows "hoare P (cwhile b c) (\<lambda>s. P s \<and> \<not> b s)"
proof -
  have aux: "\<And>s1 s2. exec (cwhile b c) s1 s2 \<Longrightarrow> P s1 \<Longrightarrow> P s2 \<and> \<not> b s2"
  proof -
    fix s1 s2
    assume He: "exec (cwhile b c) s1 s2" and HP: "P s1"
    from He HP show "P s2 \<and> \<not> b s2" using body[unfolded hoare_def]
    proof (induct "cwhile b c" s1 s2 arbitrary: HP rule: exec.induct)
      case eWhileT
      then show ?case by auto
    next
      case eWhileF
      then show ?case by auto
    qed
  qed
  then show ?thesis unfolding hoare_def by auto
qed

(* ---------- 现场演示：倒数程序 ---------- *)

definition countdown :: "nat \<Rightarrow> nat \<Rightarrow> cmd" where
  "countdown x y = cwhile (\<lambda>s. s x \<noteq> 0)
    (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1)))"

(* 完全组装：别名前提 x \<noteq> y 同 Coq/Lean 版 *)
theorem countdown_correct:
  assumes hne: "x \<noteq> y" and hinv: "s1 x + s1 y = C"
    and he: "exec (countdown x y) s1 s2"
  shows "s2 x + s2 y = C \<and> s2 x = 0"
proof -
  have body: "hoare (\<lambda>s. s x + s y = C \<and> s x \<noteq> 0)
                (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1)))
                (\<lambda>s. s x + s y = C)"
    unfolding hoare_def
  proof (intro allI impI)
    fix s t
    assume HP: "s x + s y = C \<and> s x \<noteq> 0"
      and Hx: "exec (cseq (cass x (\<lambda>s. s x - 1)) (cass y (\<lambda>s. s y + 1))) s t"
    from Hx obtain u where u1: "exec (cass x (\<lambda>s. s x - 1)) s u"
      and u2: "exec (cass y (\<lambda>s. s y + 1)) u t"
      by (auto elim: exec.cases)
    from u1 have u: "u = upd s x (s x - 1)" by (auto elim: exec.cases)
    from u2 have t: "t = upd u y (u y + 1)" by (auto elim: exec.cases)
    have ux: "u x = s x - 1" using u by (simp add: upd_def)
    have uy: "u y = s y" using u hne by (simp add: upd_def)
    obtain k where sx: "s x = Suc k" using HP by (cases "s x") auto
    from t hne have tx: "t x = u x" and ty: "t y = u y + 1"
      by (auto simp: upd_def)
    from tx ty ux uy HP sx show "t x + t y = C" by simp
  qed
  from hoare_while[OF body, unfolded hoare_def] he hinv countdown_def
  show ?thesis by auto
qed

end

(* 坑位速记（Isabelle 侧）：
   - 裸 proof (induct rule: exec.induct) 装不上（"Failed to apply
     initial proof method"）——构造子头索引要显式实例化：
     induct "cwhile b c" s1 s2 arbitrary: HP rule: exec.induct，
     不可能 case 自动小反转（只出 eWhileT/eWhileF）；HP : P s1
     依赖索引 s1，必须 arbitrary: HP 携带进动机（Coq revert 的
     Isabelle 形态）；
   - hoare_seq 用 auto elim: exec.cases 留尾巴（中间状态的选择
     auto 深度不够）——blast 一发过；
   - nat 截断减法绕行：从 s x \<noteq> 0 取 Suc k 分解，减法 simp 直收，
     无需 Coq/Lean 侧的 lia/omega 算术机器。 *)
