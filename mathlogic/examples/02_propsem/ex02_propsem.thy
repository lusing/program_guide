(* ex02 —— 命题逻辑：语法、语义与蛮力判定器（Isabelle/HOL 版）
   经典内核+自动化：同一组定理，这里的证明密度低一个数量级。 *)
theory ex02_propsem
  imports Main
begin

datatype form =
  FVar nat | FImp form form | FAnd form form | FOr form form | FNeg form | FFals

primrec eval :: "form \<Rightarrow> (nat \<Rightarrow> bool) \<Rightarrow> bool" where
  "eval (FVar n) e = e n"
| "eval (FImp a b) e = (eval a e \<longrightarrow> eval b e)"
| "eval (FAnd a b) e = (eval a e \<and> eval b e)"
| "eval (FOr a b) e = (eval a e \<or> eval b e)"
| "eval (FNeg a) e = (\<not> eval a e)"
| "eval FFals e = False"

primrec vars :: "form \<Rightarrow> nat list" where
  "vars (FVar n) = [n]"
| "vars (FImp a b) = vars a @ vars b"
| "vars (FAnd a b) = vars a @ vars b"
| "vars (FOr a b) = vars a @ vars b"
| "vars (FNeg a) = vars a"
| "vars FFals = []"

(* 一致性引理：一行归纳 *)
lemma agree_eval:
  "\<forall>x \<in> set (vars f). e1 x = e2 x \<Longrightarrow> eval f e1 = eval f e2"
  by (induction f) auto

primrec lookup :: "nat \<Rightarrow> (nat \<times> bool) list \<Rightarrow> bool" where
  "lookup n [] = False"
| "lookup n (xy # r) = (if n = fst xy then snd xy else lookup n r)"

definition assignOf :: "nat list \<Rightarrow> bool list \<Rightarrow> nat \<Rightarrow> bool" where
  "assignOf vs v n = lookup n (zip vs v)"

primrec allVectors :: "nat list \<Rightarrow> bool list list" where
  "allVectors [] = [[]]"
| "allVectors (x # xs) = map (Cons False) (allVectors xs) @ map (Cons True) (allVectors xs)"

definition check :: "form \<Rightarrow> bool" where
  "check f = list_all (\<lambda>v. eval f (assignOf (vars f) v)) (allVectors (vars f))"

lemma lookup_zip_map: "x \<in> set vs \<Longrightarrow> lookup x (zip vs (map e vs)) = e x"
  by (induction vs arbitrary: x) (auto simp: assignOf_def)

lemma map_mem_allVectors: "map e vs \<in> set (allVectors vs)"
  by (induction vs) (auto split: bool.splits)

(* 旗舰两条 *)
lemma check_true_valid: "check f \<Longrightarrow> eval f e"
proof -
  assume H: "check f"
  have agree: "eval f e = eval f (assignOf (vars f) (map e (vars f)))"
    using agree_eval[of f e "assignOf (vars f) (map e (vars f))"]
      lookup_zip_map[of _ "vars f"] by (auto simp: assignOf_def)
  from H show ?thesis
    unfolding check_def list_all_iff using agree map_mem_allVectors by auto
qed

lemma check_false_counter: "\<not> check f \<Longrightarrow> \<exists>e. \<not> eval f e"
  unfolding check_def list_all_iff by auto

(* 现场：by eval 直接把判定器算出来 *)
lemma peirce_sem_valid:
  "check (FImp (FImp (FImp (FVar 0) (FVar 1)) (FVar 0)) (FVar 0))"
  by eval

lemma contradiction_sem: "\<not> check (FAnd (FVar 0) (FNeg (FVar 0)))"
  by eval

(* 坑位速记（Isabelle 侧）：
   - primrec 定义在 datatype 上；eval 的联结词直接用 HOL 的 \<longrightarrow>/\<and>/\<or>/\<not>
     —— bool 就是命题层，无需「bool 值函数库」；
   - list_all_iff 把 list_all 拆成 \<forall>x\<in>set，剩下交给 auto；
   - lookup_zip_map 的 induction 要 arbitrary: x（x 固定也能走，但 auto 会自己分情况）。 *)

end
