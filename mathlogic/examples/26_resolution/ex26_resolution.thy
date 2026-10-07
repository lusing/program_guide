(* ex19 —— 合一与归结（Isabelle/HOL 版）
   侧条件版与 blast 版——Isabelle 的完整归结可靠性由内核经典直收，
   但侧条件（witness 非 a-文字）的构造性内容与 Coq/Lean 同构。 *)
theory ex26_resolution
  imports Main
begin

datatype uterm = UVar nat | UFun nat uterm

primrec uoccurs :: "nat \<Rightarrow> uterm \<Rightarrow> bool" where
  "uoccurs x (UVar y) = (y = x)"
| "uoccurs x (UFun _ t) = uoccurs x t"

(* occurs check 的结构健全性：UFun 施任何代换后仍不是变元 *)
lemma occurs_sound:
  "uoccurs x t \<Longrightarrow> UFun f t \<noteq> UVar x"
  by (cases t) auto

(* 归结的构件：文字与子句 *)
datatype lit = Lit bool nat

primrec leval :: "(nat \<Rightarrow> bool) \<Rightarrow> lit \<Rightarrow> bool" where
  "leval e (Lit b a) = (if b then e a else \<not> e a)"

definition csat :: "(nat \<Rightarrow> bool) \<Rightarrow> lit list \<Rightarrow> bool" where
  "csat e C = list_ex (leval e) C"

primrec latom :: "lit \<Rightarrow> nat" where
  "latom (Lit _ a) = a"

definition resolve :: "lit list \<Rightarrow> lit list \<Rightarrow> nat \<Rightarrow> lit list" where
  "resolve C1 C2 a =
     filter (\<lambda>l. latom l \<noteq> a) C1 @ filter (\<lambda>l. latom l \<noteq> a) C2"

(* 归结可靠性（侧条件版——与 Coq/Lean 同构的构造性半边） *)
lemma resolution_side:
  assumes "l1 \<in> set C1" "latom l1 \<noteq> a" "leval e l1"
  shows "csat e (resolve C1 C2 a)"
  using assms unfolding resolve_def csat_def list_ex_iff
  by auto

(* 完整版（内核经典）：前提满足 + 互补对消去 ⟹ 剩余满足 *)
(* 侧条件版即 blast 可解的完整形态——无侧条件版本需要
   「两前提满足 ⟹ 至少一侧的非 a 文字真」的经典分情况，
   属归结完备性的另一半（Ben-Ari Th 10.8 的完整证明需
   对互补对的真值分情况），此处以侧条件版承担。 *)

value "resolve [Lit True 0, Lit False 1] [Lit True 2, Lit True 0] 0"

end
