(* ex16 —— FOL 自然演绎（HOL4 版）：量词与 Drinker *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse

val _ = new_theory "Ex16folnd"
val _ = print "[start] ex16_folnd\n"

(* (1) 量词 de Morgan 构造方向 *)
val all_not_ex = store_thm("all_not_ex",
  ``!P. (!x. P x) ==> ~ (?x. ~ P x)``,
  PROVE_TAC []);

val ex_not_all = store_thm("ex_not_all",
  ``!P. (?x. ~ P x) ==> ~ (!x. P x)``,
  PROVE_TAC []);

(* (2) Drinker 悖论：经典内核 PROVE_TAC 直收 *)
val drinker = store_thm("drinker",
  ``!P. ?x. P x ==> !y. P y``,
  PROVE_TAC []);

(* (3) 量词 de Morgan 完整版 *)
val de_morgan_exists = store_thm("de_morgan_exists",
  ``!P. (?x. ~ P x) = ~ (!x. P x)``,
  PROVE_TAC []);

val _ = print "[OK] ex16_folnd\n"
val _ = export_theory ()

(* 坑位速记（HOL4 侧）：
   - ?x. P x 是 Exists 的 ASCII 写法（! 是 Forall）；
   - PROVE_TAC 处理量词+经典零障碍（内核 SELECT 原则）；
   - Drinker 无需手写分派——与 15 章理论定理同款待遇。 *)
