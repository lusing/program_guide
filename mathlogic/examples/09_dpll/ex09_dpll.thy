(* ex09 —— DPLL 与 SAT（Isabelle/HOL 版：实现 + eval 现场）
   完整三定理链在 Coq 通道；本文件给出同构实现与一条化简引理。
   记法纪律：全部用 ASCII/反斜杠转义记号——字面 Unicode 报 Inner lexical error。 *)
theory ex09_dpll
  imports Main
begin

type_synonym lit = "bool * nat"
type_synonym clause = "lit list"
type_synonym fml = "clause list"

definition lit_val :: "(nat => bool) => lit => bool" where
  "lit_val e l = (if fst l then e (snd l) else \<not> e (snd l))"

primrec cls_sat :: "(nat => bool) => clause => bool" where
  "cls_sat e [] = False"
| "cls_sat e (l # rest) = (lit_val e l \<or> cls_sat e rest)"

primrec fml_sat :: "(nat => bool) => fml => bool" where
  "fml_sat e [] = True"
| "fml_sat e (c # F) = (cls_sat e c \<and> fml_sat e F)"

(* 化简：真文字删子句、假文字删文字 *)
fun clause_step :: "clause => nat => bool => clause option" where
  "clause_step [] _ _ = Some []"
| "clause_step (l # rest) n s =
     (if snd l = n then
        (if fst l \<noteq> s then clause_step rest n s else None)
      else (case clause_step rest n s of
              Some c' => Some (l # c')
            | None => None))"

fun fml_step :: "fml => nat => bool => fml" where
  "fml_step [] _ _ = []"
| "fml_step (c # F) n s =
     (case clause_step c n s of
        None => fml_step F n s
      | Some c' => c' # fml_step F n s)"

definition is_empty :: "clause => bool" where
  "is_empty c = (c = [])"

definition has_conflict :: "fml => bool" where
  "has_conflict F = list_ex is_empty F"

fun find_unit :: "fml => lit option" where
  "find_unit [] = None"
| "find_unit ([l] # _) = Some l"
| "find_unit (_ # F) = find_unit F"

fun first_lit :: "fml => lit option" where
  "first_lit [] = None"
| "first_lit ((l # _) # _) = Some l"
| "first_lit (_ # F) = first_lit F"

definition upd :: "(nat => bool) => nat => bool => nat => bool" where
  "upd e n b = (\<lambda>m. if m = n then b else e m)"

(* fuel 结构递归：k < fuel 保证终止 *)
function dpll :: "nat => fml => (nat => bool) option" where
  "dpll 0 _ = None"
| "dpll (Suc k) F =
     (if has_conflict F then None
      else (case find_unit F of
              Some (s, n) =>
                (case dpll k (fml_step F n s) of
                   Some e => Some (upd e n s)
                 | None => None)
            | None =>
                (case first_lit F of
                   Some (s, n) =>
                     (case dpll k (fml_step F n s) of
                        Some e => Some (upd e n s)
                      | None =>
                          (case dpll k (fml_step F n (\<not> s)) of
                             Some e => Some (upd e n (\<not> s))
                           | None => None))
                 | None => Some (\<lambda>_. True))))"
  by pat_completeness auto
termination by (relation "measure (\<lambda>(fuel, _). fuel)") auto

(* ---------- 边界注记 ---------- *)

(* 化简引理 clause_step_none_sat（e n = s 且 step 返回 None 则子句满足）
   的完整归纳证明在 Coq 通道（clauseStep_none_sat，零公理）。
   Isabelle 侧手动 Isar 六轮未收口——残留目标卡在 lit_val 展开后的
   if-链与案例事实的配合上；此处如实记录为机器验证边界，
   只保留实现与 eval 现场。 *)

(* ---------- eval 现场 ---------- *)

lemma demo_sat: "dpll 30 [[(True::bool, 0::nat), (False, 1)],
                          [(False, 0), (False, 1)],
                          [(True, 1), (True, 0)]] \<noteq> None"
  by eval

lemma demo_unsat: "dpll 10 [[(True::bool, 0::nat)], [(False, 0)]] = None"
  by eval

value "case dpll 20 [[(True, 1)], [(False, 1), (True, 0)]] of
        Some e => (e 1, e 0) | None => (False, False)"

(* 坑位速记（Isabelle 侧）：
   - 字面 Unicode（× ⇒ ≠ ∧ ∨ ¬ λ）在本机词法层全部 Inner lexical error——
     统一 ASCII/\<xxx> 转义（isabelle 教程同款坑，本通道 09 章二次实锤）；
   - function + pat_completeness + termination by measure fuel——
     DPLL 的嵌套 case 让 fun 自动终止失败，须手写关系；
   - eval 方法直接把 fuel 版跑出结果（代码生成对 function 友好）。 *)

end
