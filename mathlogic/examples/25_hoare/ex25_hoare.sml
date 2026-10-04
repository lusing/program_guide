(* ex25 —— 霍尔逻辑（HOL4 版）：while 规则与不变式
   对书：Huth&Ryan ch4 / Ben-Ari 3e ch15

   HOL4 的 exec 是 Hol_reln 关系；while 规则的归纳用「命令泛化为
   变量 + 方程 w = cwhile b c 进辅助引理」——与 Coq remember、Lean
   key 泛化同一配方；不可能分支交给 datatype distinctness。 *)
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0

open HolKernel boolLib bossLib Parse

val _ = new_theory "Ex25hoare"
val _ = print "[start] ex25_hoare\n"

val _ = type_abbrev("state", ``:num -> num``)

val upd_def = Define`
  upd (s:state) (x:num) (v:num) = (\m. if m = x then v else s m)`;

Datatype:
  cmd = cskip
      | cass num (state -> num)
      | cseq cmd cmd
      | cwhile (state -> bool) cmd
End

val (exec_rules, exec_ind, exec_cases) = Hol_reln`
  (!s. exec cskip s s) /\
  (!x f s. exec (cass x f) s (upd s x (f s))) /\
  (!c1 c2 s1 s2 s3. exec c1 s1 s2 /\ exec c2 s2 s3 ==> exec (cseq c1 c2) s1 s3) /\
  (!b c s1 s2 s3. b s1 /\ exec c s1 s2 /\ exec (cwhile b c) s2 s3 ==>
                  exec (cwhile b c) s1 s3) /\
  (!b c s. ~b s ==> exec (cwhile b c) s s)`;

val hoare_def = Define`
  hoare P c Q <=> !s1 s2. P s1 ==> exec c s1 s2 ==> Q s2`;

(* 旗舰一：skip 规则 *)
val hoare_skip = store_thm(
  "hoare_skip",
  ``!P. hoare P cskip P``,
  simp [hoare_def] THEN REPEAT STRIP_TAC THEN
  IMP_RES_THEN STRIP_ASSUME_TAC exec_cases THEN
  SRW_TAC [][]);

(* 旗舰二：赋值公理 *)
val hoare_ass = store_thm(
  "hoare_ass",
  ``!Q x f. hoare (\s. Q (upd s x (f s))) (cass x f) Q``,
  simp [hoare_def] THEN REPEAT STRIP_TAC THEN
  IMP_RES_THEN STRIP_ASSUME_TAC exec_cases THEN
  FULL_SIMP_TAC (srw_ss()) []);

(* 旗舰三：顺序规则 *)
val hoare_seq = store_thm(
  "hoare_seq",
  ``!P c1 Q c2 R. hoare P c1 Q /\ hoare Q c2 R ==> hoare P (cseq c1 c2) R``,
  simp [hoare_def] THEN REPEAT STRIP_TAC THEN
  IMP_RES_THEN STRIP_ASSUME_TAC exec_cases THEN
  FULL_SIMP_TAC (srw_ss()) [hoare_def] THEN METIS_TAC []);

(* 旗舰四：while 规则——命令泛化 + 方程携带进归纳（Coq remember 配方）。
   strongind 被 Hol_reln 存进理论但不在 3 元返回值里——fetch 取回 *)
val exec_strongind = fetch "Ex25hoare" "exec_strongind"
val cmd_distinct = fetch "Ex25hoare" "cmd_distinct"
val cmd_11 = fetch "Ex25hoare" "cmd_11"
val hoare_while_aux = store_thm(
  "hoare_while_aux",
  ``!P b c. hoare (\s. P s /\ b s) c P ==> !w s1 s2. exec w s1 s2 ==>
     (w = cwhile b c) ==> P s1 ==> (P s2 /\ ~b s2)``,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  HO_MATCH_MP_TAC exec_strongind THEN
  REPEAT CONJ_TAC THEN
  (* 只 intro ∀/⇒，不拆目标侧合取（否则 P s2 ∧ ¬b s2 裂两支） *)
  REPEAT (GEN_TAC ORELSE DISCH_TAC) THEN
  TRY (FULL_SIMP_TAC (srw_ss()) [cmd_distinct]) THEN
  TRY (FULL_SIMP_TAC (srw_ss()) [hoare_def, cmd_11]) THEN
  TRY (ASM_REWRITE_TAC []) THEN
  (* whileT 剩余唯一目标：RES_TAC 用 Hbody 出 P s1'，再用 IH2 直收
     ——不用 metis：上下文里的函数等式（w=c、b'=b）会让参数调制爆炸 *)
  `P s1'` by (RES_TAC THEN ASM_REWRITE_TAC []) THEN
  RES_TAC THEN ASM_REWRITE_TAC []);

val hoare_while = store_thm(
  "hoare_while",
  ``!P b c. hoare (\s. P s /\ b s) c P ==>
    hoare P (cwhile b c) (\s. P s /\ ~b s)``,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  `!s1 s2. P s1 ==> exec (cwhile b c) s1 s2 ==> (P s2 /\ ~b s2)`
    by (MP_TAC (Q.SPECL [`P:state->bool`, `b:state->bool`, `c:cmd`]
                      hoare_while_aux) THEN
        FULL_SIMP_TAC (srw_ss()) [hoare_def] THEN
        REPEAT STRIP_TAC THEN
        RES_TAC THEN REPEAT STRIP_TAC THEN ASM_REWRITE_TAC []) THEN
  rw [hoare_def] THEN RES_TAC THEN ASM_REWRITE_TAC []);

(* ---------- 现场演示：倒数程序 ---------- *)

val countdown_def = Define`
  countdown (x:num) (y:num) =
    cwhile (\s. s x <> 0)
      (cseq (cass x (\s. s x - 1)) (cass y (\s. s y + 1)))`;

(* upd 读出引理 *)
val upd_self = store_thm(
  "upd_self",
  ``!s x v. upd s x v x = v``,
  simp [upd_def]);

val upd_other = store_thm(
  "upd_other",
  ``!s x v m. m <> x ==> upd s x v m = s m``,
  simp [upd_def]);

(* 现场演示（单步版）：一轮迭代的核心算术——截断减法 + 别名前提。
   完整的 hoare_seq+hoare_while 组装见 Coq/Lean/Isabelle/Agda 版：
   HOL4 侧 exec 双重反演（seq→cass→upd 方程链）经实测会被
   IMP_RES_THEN 的实例级联污染上下文，单步引理是诚实的等价物。 *)
val countdown_step = store_thm(
  "countdown_step",
  ``!x y C s. x <> y /\ (s x + s y = C) /\ s x <> 0 ==>
    (upd (upd s x (s x - 1)) y (upd s x (s x - 1) y + 1) x +
     upd (upd s x (s x - 1)) y (upd s x (s x - 1) y + 1) y = C)``,
  rw [upd_def] THEN
  Cases_on `(s:state) (x:num)` THEN
  fs []);

val _ = print "[OK] ex25_hoare\n"
val _ = export_theory()

(* 坑位速记（HOL4 侧）：
   - 战术位引文是「静态上下文」elaboration：目标里绑定的 P/s1
     看不见——裸 `P s1` 把 P 推成多态非命题（ASSUME "not a
     proposition"）、Cases_on `s1 x` 报 dest_thy_type；全类型注解
     `(P:state->bool) (s1:state)` 直收，而 `!s1 s2.` 加注解反而
     No consistent parse；DECIDE 引理的绑定名 b 还会与上下文的
     state->bool 变量 b 相撞——绑定名要避开；
   - metis 三雷：大 aux/带 hoare 黑盒子进子句集 → 参数调制爆炸
     （hol run 模式下 timeout 静默中止，exit 0 无错误输出）；
     上下文里有函数等式（w=c、b'=b）也爆炸——正解 RES_TAC
     确定性消解；hoare_def 的 λ 前件先 FULL_SIMP β-归约再谈；
   - Hol_reln 返回 3 元组（rules/ind/cases）——strongind 会被
     定义并保存但不在返回值里，fetch "theory名" 取回（同理
     cmd_distinct/cmd_11 也要 fetch）；
   - hoare_while 的归纳必须 exec_strongind——弱 exec_ind 的案例
     里只有 exec'（动机实例）没有 exec（副推导事实），whileT 支
     拿不到 exec c s1 s2 喂 Hbody；应用 = HO_MATCH_MP_TAC（谓词
     变量要 HO 匹配）→ REPEAT (GEN_TAC ORELSE DISCH_TAC)（不拆
     目标侧合取）→ TRY 梯队 [cmd_distinct] / [hoare_def, cmd_11]
     / ASM_REWRITE → RES_TAC ×2 收 whileT；外层包 hoare 形式用
     SPECl aux + FULL_SIMP [hoare_def] + rw + RES_TAC；
   - exec 反演 = IMP_RES_THEN STRIP_ASSUME_TAC exec_cases——
     只能一层：连用两次会被实例级联污染（∀a2. a2 = s ⇒ ... 的
     悬空量化假设），这是 HOL4 版只做单步演示的原因；
   - 截断减法绕行同四通道：Cases_on 全注解引文 + fs [] 双支直收。 *)

