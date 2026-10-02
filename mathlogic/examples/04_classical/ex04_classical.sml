(* ex04 —— 经典加成（HOL4 版）：经典内核白送原理本体 *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse

val _ = new_theory "Ex04classical"
val _ = print "[start] ex04_classical\n"

val c_dne = store_thm("c_dne", ``!p. ~~p ==> p``, PROVE_TAC [])
val c_lem = store_thm("c_lem", ``!p. p \/ ~p``, PROVE_TAC [])
val c_peirce = store_thm("c_peirce",
  ``!p q. ((p ==> q) ==> p) ==> p``, PROVE_TAC [])
val c_clavius = store_thm("c_clavius", ``!p. (~p ==> p) ==> p``, PROVE_TAC [])
val c_de_morgan = store_thm("c_de_morgan",
  ``!p q. ~(p /\ q) ==> ~p \/ ~q``, PROVE_TAC [])

val _ = print "[OK] ex04_classical\n"
val _ = export_theory ()

(* 坑位速记（HOL4 侧）：
   - ~~p 的双否定写法直接解析（NEG 嵌套）；
   - 这些正是 Coq 侧「证不出」的那批——LCF 经典内核无账单可言，
     定理存在性由内核规则担保；
   - PROVE_TAC 全部秒过，无 metis 不终止之虞（纯命题无方向性）。 *)
