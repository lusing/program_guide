(* ex05 —— Hilbert 系统 L 与演绎定理（HOL4 版）
   浅嵌入：三条公理模式在经典内核直接成立；
   identity 用 A1/A2 的 MATCH_MP 链现场组合（I = S K K 的命题版）。 *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse

val _ = new_theory "Ex05hilbert"
val _ = print "[start] ex05_hilbert\n"

(* Mendelson 三公理模式 *)
val ax1 = store_thm("ax1", ``!p q. p ==> q ==> p``, PROVE_TAC [])
val ax2 = store_thm("ax2",
  ``!p q r. (p ==> q ==> r) ==> (p ==> q) ==> p ==> r``, PROVE_TAC [])
val ax3 = store_thm("ax3", ``!p q. (~q ==> ~p) ==> p ==> q``, PROVE_TAC [])

(* I = S K K：五步 MP 链的现场组合 *)
val ident_hilbert =
  let
    val P  = ``p:bool``
    val s1 = ISPECL [P, ``p:bool ==> p:bool``] ax1        (* p -> ((p->p) -> p) *)
    val s2 = ISPECL [P, ``p:bool ==> p:bool``, P] ax2     (* A2 实例 *)
    val s3 = MATCH_MP s2 s1                                (* (p -> (p->p)) -> (p->p) *)
    val s4 = ISPECL [P, P] ax1                             (* p -> (p->p) *)
  in
    MATCH_MP s3 s4                                         (* p -> p *)
  end
val _ = save_thm("ident_hilbert", GEN ``p:bool`` ident_hilbert)

(* 演绎定理的内核对应物：DISCH 就是 →I
   （LCF 系里「元定理」长在内核规则上，不需要对推导归纳） *)
val disch_demo = save_thm("disch_demo",
  DISCH ``p:bool`` (ASSUME ``q:bool``))                    (* p,q |- p ==> q 的倒影 *)

val _ = print "[OK] ex05_hilbert\n"
val _ = export_theory ()

(* 坑位速记（HOL4 侧）：
   - ISPECL 的实例顺序 = 定理全称量的声明顺序；
   - MATCH_MP th1 th2 = MP 的定理层组合子（th1 的前件吃 th2 的结论）；
   - DISCH 是内核的 →I 元规则——浅嵌入下演绎定理「免费」，
     这正是 LCF 与深度嵌入（Coq/Lean 的 derives 归纳）的对照点。 *)
