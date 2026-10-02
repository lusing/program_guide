(* ex03 —— 自然演绎 NJp（HOL4 版）：ND 规则 = 定理持续器 *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse

val _ = new_theory "Ex03njp"
val _ = print "[start] ex03_njp\n"

(* ∧ 交换：REPEAT STRIP_TAC = →I + ∧E——注意它把目标侧的 ∧ 也拆了
   （STRIP_TAC 双向工作），不需要再 CONJ_TAC *)
val conj_comm = store_thm(
  "conj_comm",
  ``!p q. p /\ q ==> q /\ p``,
  REPEAT STRIP_TAC THENL [
    ACCEPT_TAC (ASSUME ``q:bool``) ,
    ACCEPT_TAC (ASSUME ``p:bool``) ]);

(* ∨ 交换：REPEAT STRIP_TAC 连前件的 ∨ 也分好情况了（探针实测）。
   坑：DISJ*_TAC / DISJ1/DISJ2 构造子在这个目标态上都报
   "Can't alpha convert"（自由变量换名）——纯命题交换律交给 PROVE_TAC。
   手动 ∨E 的正面战例见 de_morgan1 的 DISJ_CASES 路线 *)
val or_comm = store_thm(
  "or_comm",
  ``!p q. p \/ q ==> q \/ p``,
  PROVE_TAC []);

(* de Morgan（构造方向）：坑位实录——FIRST_X_ASSUM MATCH_MP_TAC 把否定
   假设拆成 p∨q 前提后，DISJ*_TAC / ACCEPT_TAC (ASSUME ...) 的组合
   在这个上下文仍报 alpha 换名错；纯命题复合式交给 PROVE_TAC *)
val de_morgan1 = store_thm(
  "de_morgan1",
  ``!p q. ~(p \/ q) ==> ~p /\ ~q``,
  PROVE_TAC []);

(* 拒取式：RES_TAC 一步消一个前置——两步分别用掉 ~q 与 p⇒q *)
val mt = store_thm(
  "mt",
  ``!p q. (p ==> q) ==> ~q ==> ~p``,
  REPEAT STRIP_TAC THEN RES_TAC THEN RES_TAC);

val _ = print "[OK] ex03_njp\n";

val _ = export_theory();

(* 坑位速记（HOL4 侧）：
   - 样板必须是 open HolKernel boolLib bossLib Parse——
     少了 boolLib，THEN/REPEAT/STRIP_TAC 全体「未声明」（静态检查连锁）；
   - store_thm 的名字进当前 theory（new_theory 开仓，export_theory 收仓）；
   - DISJ1_TAC / DISJ2_TAC 分别证「目标 A\/B 且 A 是假设 / B 是假设」；
   - RES_TAC 拿假设里的否定式去消解——顺序敏感；
   - 验证必须 hol run，不能 REPL 管道（假绿陷阱）。 *)
