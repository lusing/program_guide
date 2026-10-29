(* 98 推理规则：语言构件与原语操作的规格、手工验证示例 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Rules 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax.

Implicit Types n : int.
Implicit Types t : trm.
Implicit Types r v : val.
Implicit Types p : loc.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

(* ---------- 98.1 序列规则 ---------- *)

(* {H} t1 {fun _ => H1}   {H1} t2 {Q}
   ----------------------------------
         {H} (t1; t2) {Q}                    *)

(* 练习（2 星，标准，必做）：序列规则。 *)

Lemma triple_seq : forall t1 t2 H Q H1,
  triple t1 H (fun _ => H1) ->
  triple t2 H1 Q ->
  triple (trm_seq t1 t2) H Q.
Proof using. introv M1 M2 Hs. applys* eval_seq. Qed.

(* ---------- 98.2 let 规则 ---------- *)

(* 注意区分程序变量 x 与 Rocq 值变量 v1：续体对一切结果值 v1 陈述，
   项 t2 里的程序变量 x 已被代换成 v1。 *)

Lemma triple_let : forall x t1 t2 Q1 H Q,
  triple t1 H Q1 ->
  (forall v1, triple (subst x v1 t2) (Q1 v1) Q) ->
  triple (trm_let x t1 t2) H Q.
Proof using. introv M1 M2 Hs. applys* eval_let. Qed.

(* ---------- 98.3 条件规则 ---------- *)

(* 练习（2 星，标准，必做）：两分支形式的条件规则。 *)

Lemma triple_if_case : forall b t1 t2 H Q,
  (b = true -> triple t1 H Q) ->
  (b = false -> triple t2 H Q) ->
  triple (trm_if (val_bool b) t1 t2) H Q.
Proof using.
  introv M1 M2 Hs. applys eval_if. case_if.
  { applys* M1. }
  { applys* M2. }
Qed.

(* 用 Rocq 自己的 if 把两个前提合并成一条。 *)

Lemma triple_if : forall (b:bool) t1 t2 H Q,
  triple (if b then t1 else t2) H Q ->
  triple (trm_if b t1 t2) H Q.
Proof using. introv M Hs. applys* eval_if. Qed.

(* ---------- 98.4 值规则 ---------- *)

(* 实用形式：前条件蕴含"结果为 v"即可。
     H ==> Q v
   --------------
     {H} v {Q}                          *)

Lemma triple_val : forall v H Q,
  H ==> Q v ->
  triple (trm_val v) H Q.
Proof using. introv M Hs. applys* eval_val. Qed.

(* 练习（1 星，标准，必做）：极简形式 {\[]} v {fun r => \[r = v]}。 *)

Lemma triple_val_minimal : forall v,
  triple (trm_val v) \[] (fun r => \[r = v]).
Proof using. intros v. applys triple_val. xsimpl. auto. Qed.

(* 练习（2 星，标准，必做）：反向——不展开 triple 定义，
   用 triple_conseq_frame + triple_val_minimal 推出实用形式。 *)

Lemma triple_val' : forall v H Q,
  H ==> Q v ->
  triple (trm_val v) H Q.
Proof using.
  introv M. applys triple_conseq_frame.
  { applys triple_val_minimal. }
  { xsimpl. }
  { intros r. xpull. intros ->. applys M. }
Qed.

(* 练习（4 星，标准，必做）：let 的参数已是值时的特设规则。 *)

Lemma triple_let_val : forall x v1 t2 H Q,
  triple (subst x v1 t2) H Q ->
  triple (trm_let x (trm_val v1) t2) H Q.
Proof using.
  introv M. applys triple_let (fun v => \[v = v1] \* H).
  { applys triple_val. xsimpl*. }
  { intros v. applys triple_hpure. intros ->. applys M. }
Qed.

(* ---------- 98.5 函数定义规则 ---------- *)

Lemma triple_fun : forall x t1 H Q,
  H ==> Q (val_fun x t1) ->
  triple (trm_fun x t1) H Q.
Proof using. introv M Hs. applys* eval_fun. Qed.

Lemma triple_fix : forall f x t1 H Q,
  H ==> Q (val_fix f x t1) ->
  triple (trm_fix f x t1) H Q.
Proof using. introv M Hs. applys* eval_fix. Qed.

(* ---------- 98.6 函数调用规则 ---------- *)

(* beta 规约的规格版：被调函数必须是已知的具体值。 *)

Lemma triple_app_fun : forall x v1 v2 t1 H Q,
  v1 = val_fun x t1 ->
  triple (subst x v2 t1) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M Hs. applys* eval_app_fun. Qed.

(* 递归函数的双重代入：先代入自身 f，再代入实参 x。 *)

Lemma triple_app_fix : forall v1 v2 f x t1 H Q,
  v1 = val_fix f x t1 ->
  triple (subst x v2 (subst f v1 t1)) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M Hs. applys* eval_app_fix. Qed.

(* ---------- 98.7 加法的规格：最小足迹约定 ---------- *)

Lemma triple_add : forall n1 n2,
  triple (val_add n1 n2)
    \[]
    (fun r => \[r = val_int (n1 + n2)]).
Proof using.
  introv Hs. applys* eval_add. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

(* 也可写成 triple_val 风格，但最小足迹版（前条件 \[]）才能配合框架规则
   灵活使用；函数规格一律按"前条件只覆盖必须访问的内存"来写。 *)

Lemma triple_add' : forall H Q n1 n2,
  H ==> Q (val_int (n1 + n2)) ->
  triple (val_add n1 n2) H Q.
Proof using.
  introv M. applys triple_conseq_frame.
  { applys triple_add. }
  { xsimpl. }
  { xpull. intros ? ->. auto. }
Qed.

(* ---------- 98.8 除法的规格 ---------- *)

Lemma triple_div : forall n1 n2,
  n2 <> 0 ->
  triple (val_div n1 n2)
    \[]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  introv Hn2 Hs. applys* eval_div. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

(* ---------- 98.9 rand 的规格 ---------- *)

(* 练习（2 星，标准，必做）：非确定性原语的规格——
   后条件断言结果落在 [0,n) 内。 *)

Lemma triple_rand : forall n,
  n > 0 ->
  triple (val_rand n)
    \[]
    (fun r => \[exists n1, r = val_int n1 /\ 0 <= n1 < n]).
Proof using.
  introv Hn Hs. applys eval_rand.
  { math. }
  { intros n1 Hn1. lets ->: hempty_inv Hs.
    applys hpure_intro. exists n1. split. { reflexivity. } { math. } }
Qed.

(* ---------- 98.10 分配的规格 ---------- *)

Lemma triple_ref : forall v,
  triple (val_ref v)
    \[]
    (fun r => \exists p, \[r = val_loc p] \* p ~~> v).
Proof using.
  intros. intros s1 K. applys eval_ref. intros p D.
  lets ->: hempty_inv K. rewrite Fmap.update_empty.
  applys hexists_intro p. rewrite hstar_hpure_l. split*.
  applys hsingle_intro.
Qed.

(* funloc 记法：funloc p => H 即 fun r => \exists p, \[r = val_loc p] \* H。 *)

Lemma triple_ref' : forall v,
  triple (val_ref v)
    \[]
    (funloc p => p ~~> v).
Proof using. apply triple_ref. Qed.

(* ---------- 98.11 释放的规格 ---------- *)

(* 练习（2 星，标准，必做）：释放一个单格。 *)

Lemma triple_free' : forall p v,
  triple (val_free (val_loc p))
    (p ~~> v)
    (fun r => \[r = val_unit]).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_free.
  { applys* Fmap.indom_single. }
  { rewrite* Fmap.remove_single. applys hpure_intro. auto. }
Qed.

(* 实用版：返回值信息无用，后条件取空。 *)

Lemma triple_free : forall p v,
  triple (val_free (val_loc p))
    (p ~~> v)
    (fun _ => \[]).
Proof using. intros. applys triple_conseq triple_free'; xsimpl*. Qed.

(* ---------- 98.12 读的规格 ---------- *)

Lemma triple_get : forall v p,
  triple (val_get p)
    (p ~~> v)
    (fun r => \[r = v] \* (p ~~> v)).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_get.
  { applys* Fmap.indom_single. }
  { rewrite hstar_hpure_l. split*. rewrite* Fmap.read_single. }
Qed.

(* ---------- 98.13 写的规格 ---------- *)

(* 练习（2 星，标准，必做）：写一个单格。 *)

Lemma triple_set : forall w p v,
  triple (val_set (val_loc p) v)
    (p ~~> w)
    (fun r => \[r = val_unit] \* (p ~~> v)).
Proof using.
  intros. intros s K. lets ->: hsingle_inv K. applys eval_set.
  { applys* Fmap.indom_single. }
  { rewrite hstar_hpure_l. split*.
    rewrite Fmap.update_single. applys hsingle_intro. }
Qed.

(* ---------- 98.14 示例程序：incr 的手工验证 ---------- *)

Module ExamplePrograms.
Export ProgramSyntax.

(* incr p = let n = !p in let m = n+1 in p := m，裸构造子写法： *)

Definition incr : val :=
  val_fun "p" (
    trm_let "n" (trm_app val_get (trm_var "p")) (
    trm_let "m" (trm_app (trm_app val_add
                             (trm_var "n")) (val_int 1)) (
    trm_app (trm_app val_set (trm_var "p")) (trm_var "m")))).

(* 同一程序的记法写法： *)

Definition incr' : val :=
  <{ fun 'p =>
       let 'n = ! 'p in
       let 'm = 'n + 1 in
       'p := 'm }>.

Lemma incr_eq_incr' :
  incr = incr'.
Proof using. reflexivity. Qed.

(* 93 章的三行战术 xwp/xapp 在幕后做的事，用基础规则手工展开如下。
   每一步都注明对应规则；evar ?Q1 由第一步的规格自动定值。 *)

Lemma triple_incr : forall (p:loc) (n:int),
  triple (trm_app incr p)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  intros. applys triple_app_fun.
  { reflexivity. }
  simpl.
  applys triple_let.
  { apply triple_get. }
  intros n'. simpl.
  apply triple_hpure. intros ->.
  applys triple_let.
  { applys triple_conseq_frame.
    { applys triple_add. }
    { xsimpl. }
    { xsimpl. } }
  intros m'. simpl.
  apply triple_hpure. intros ->.
  applys triple_conseq_frame.
    { applys triple_set. }
    { xsimpl. }
    { xsimpl. }
Qed.

(* ---------- 98.15 练习：succ_using_incr 的手工验证 ---------- *)

Definition succ_using_incr : val :=
  <{ fun 'n =>
       let 'r = val_ref 'n in
       incr 'r;
       let 'x = ! 'r in
       val_free 'r;
       'x }>.

(* 练习（4 星，标准，必做）：按 triple_incr 的模式手工验证。 *)

Lemma triple_succ_using_incr : forall (n:int),
  triple (trm_app succ_using_incr n)
    \[]
    (fun v => \[v = val_int (n+1)]).
Proof using.
  intros. applys triple_app_fun.
  { reflexivity. }
  simpl.
  applys triple_let.
  { applys triple_ref'. }
  intros r. simpl.
  applys triple_hexists. intros p. apply triple_hpure. intros ->.
  applys triple_seq.
  { applys triple_incr. }
  applys triple_let.
  { applys triple_get. }
  intros x. simpl.
  apply triple_hpure. intros ->.
  applys triple_seq.
  { applys triple_free. }
  { applys triple_val. xsimpl. auto. }
Qed.

End ExamplePrograms.

(* ---------- 98.16 同语义的项满足相同的三元组 ---------- *)

Module ProofsSameSemantics.

(* eval_like t1 t2：t2 的行为不多于 t1（t1 能到哪，t2 就能到哪）。 *)

Definition eval_like (t1 t2:trm) : Prop :=
  forall s Q, eval s t1 Q -> eval s t2 Q.

(* 练习（1 星，标准，必做）：eval_like 传递三元组。 *)

Lemma triple_eval_like : forall t1 t2 H Q,
  eval_like t1 t2 ->
  triple t1 H Q ->
  triple t2 H Q.
Proof using.
  introv L M. unfolds triple. introv Hs.
  applys L. applys M Hs.
Qed.

(* 应用一：let x = t in x 与 t 有相同语义（eta 收缩方向）。 *)

Lemma eval_like_eta_reduction : forall (t:trm) (x:var),
  eval_like t (trm_let x t x).
Proof using.
  introv R. applys eval_let R.
  simpl. rewrite var_eq_spec. case_if.
  introv Hv. applys eval_val Hv.
Qed.

(* 练习（4 星，标准，选做）：eta 扩张方向——对 eval 推导归纳，
   借 eval_conseq 换后条件，代换后的 trm_var x 用 case_if 化简。 *)

Lemma eval_like_eta_expansion : forall (t:trm) (x:var),
  eval_like (trm_let x t x) t.
Proof using.
  introv R. inverts R as M1 K.
  applys eval_conseq M1. introv HK.
  lets E: (K v h HK).
  simpl in E. rewrite var_eq_spec in E. case_if in E.
  inverts E. auto.
Qed.

(* 练习（2 星，标准，必做）：两个方向合起来——eta 前后满足相同三元组。 *)

Lemma eta_same_triples : forall (t:trm) (x:var) H Q,
   triple t H Q <-> triple (trm_let x t x) H Q.
Proof using.
  iff M.
  { applys triple_eval_like M. applys eval_like_eta_reduction. }
  { applys triple_eval_like M. applys eval_like_eta_expansion. }
Qed.

(* 应用二：用 eval_like 重看 triple_app_fun——
   beta 规约前后语义相同。 *)

Lemma triple_app_fun' : forall x v1 v2 t1 H Q,
  v1 = val_fun x t1 ->
  triple (subst x v2 t1) H Q ->
  triple (trm_app v1 v2) H Q.
Proof using.
  introv E M1. applys triple_eval_like M1.
  introv R. applys eval_app_fun E R.
Qed.

(* 应用三（练习，3 星，标准，选做）：改写序列的括号结构——
   t1;(t2;t3) 满足 (t1;t2);t3 满足的一切三元组。
   辅引理把左嵌套的序列拆开。 *)

Lemma eval_seq_swap : forall s t1 t2 Q1',
  eval s (trm_seq t1 t2) Q1' ->
  forall t3 Q, (forall v s', Q1' v s' -> eval s' t3 Q) ->
  eval s (trm_seq t1 (trm_seq t2 t3)) Q.
Proof using.
  introv M. inverts M as M1 M2. intros t3 Q C.
  applys eval_seq M1. intros v1 s2 Hv.
  applys eval_seq (M2 v1 s2 Hv). exact C.
Qed.

Lemma triple_trm_seq_assoc : forall t1 t2 t3 H Q,
  triple (trm_seq (trm_seq t1 t2) t3) H Q ->
  triple (trm_seq t1 (trm_seq t2 t3)) H Q.
Proof using.
  introv M. applys triple_eval_like M.
  introv R. inverts R as R1 K.
  applys eval_seq_swap R1 K.
Qed.

End ProofsSameSemantics.

(* ---------- 98.17 组合的 let-框架规则 ---------- *)

Module LetFrame.

(* 练习（3 星，标准，必做）：把 let 规则与框架规则合起来——
   第一步只需前条件中属于自己的那块 H1，框架 H2 原样留给续体。 *)

Lemma triple_let_frame : forall x t1 t2 Q1 H H1 H2 Q,
  triple t1 H1 Q1 ->
  H ==> H1 \* H2 ->
  (forall v1, triple (subst x v1 t2) (Q1 v1 \* H2) Q) ->
  triple (trm_let x t1 t2) H Q.
Proof using.
  introv M WH M2. applys triple_let (Q1 \*+ H2).
  { applys triple_conseq_frame M WH. xsimpl. }
  { intros v1. applys (M2 v1). }
Qed.

End LetFrame.

(* ---------- 98.18 纯前条件的另一种规格风格 ---------- *)

Module DivSpec.

(* 除零前提也可以放进前条件 \[n2 <> 0]：两种风格等价。 *)

Lemma triple_div' : forall n1 n2,
  triple (val_div n1 n2)
    \[n2 <> 0]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  intros. applys triple_hpure'. applys triple_div.
Qed.

(* 练习（2 星，标准，必做）：反方向。 *)

Lemma triple_div_from_triple_div' : forall n1 n2,
  n2 <> 0 ->
  triple (val_div n1 n2)
    \[]
    (fun r => \[r = val_int (Z.quot n1 n2)]).
Proof using.
  introv Hn. applys triple_conseq_frame triple_div'.
  { xsimpl. auto. }
  { intros r. xsimpl. auto. }
Qed.

End DivSpec.

(* ---------- 98.19 结果值的另一种规格风格（对照） ---------- *)

Module MatchStyle.

(* ref 的后条件也可用 match 而非存在量词来写，但可读性差、不便使用： *)

Parameter triple_ref'' : forall v,
  triple (val_ref v)
    \[]
    (fun r => match r with
              | val_loc p => (p ~~> v)
              | _ => \[False]
              end).

End MatchStyle.

(* ---------- 98.20 递归示例：factorec 的手工验证 ---------- *)

Module ExamplePrograms2.
Export ProgramSyntax.

(* triple_hpure' 在 97 章证过，这里复刻（用库的 triple_conseq/triple_hpure）。 *)

Lemma triple_hpure' : forall t (P:Prop) Q,
  (P -> triple t \[] Q) ->
  triple t \[P] Q.
Proof using.
  introv M. applys triple_conseq (triple_hpure M).
  { xsimpl. auto. }
  { applys qimpl_refl. }
Qed.

(* 库把二元原语统一编码成 eval_binop + evalbinop_*；
   这里按 eval_add 的模式导出三个专用规则。 *)

Lemma eval_le : forall s n1 n2 Q,
  Q (val_bool (isTrue (n1 <= n2))) s ->
  eval s (val_le (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_le. }
  { intros ? ->. auto. }
Qed.

Lemma eval_sub : forall s n1 n2 Q,
  Q (val_int (n1 - n2)) s ->
  eval s (val_sub (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_sub. }
  { intros ? ->. auto. }
Qed.

Lemma eval_mul : forall s n1 n2 Q,
  Q (val_int (n1 * n2)) s ->
  eval s (val_mul (val_int n1) (val_int n2)) Q.
Proof using.
  intros. applys* eval_binop.
  { applys* evalbinop_mul. }
  { intros ? ->. auto. }
Qed.

Lemma triple_le : forall n1 n2,
  triple (val_le n1 n2)
    \[]
    (fun r => \[r = val_bool (isTrue (n1 <= n2))]).
Proof using.
  introv Hs. applys* eval_le. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

Lemma triple_sub : forall n1 n2,
  triple (val_sub n1 n2)
    \[]
    (fun r => \[r = val_int (n1 - n2)]).
Proof using.
  introv Hs. applys* eval_sub. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

Lemma triple_mul : forall n1 n2,
  triple (val_mul n1 n2)
    \[]
    (fun r => \[r = val_int (n1 * n2)]).
Proof using.
  introv Hs. applys* eval_mul. lets ->: hempty_inv Hs.
  applys hpure_intro. auto.
Qed.

(* facto 的公理化（与 93 章一致）： *)

Module Facto.

Parameter facto : int -> int.

Parameter facto_init : forall n,
  0 <= n <= 1 ->
  facto n = 1.

Parameter facto_step : forall n,
  n >= 1 ->
  facto n = n * (facto (n-1)).

End Facto.

Import Facto.

Definition factorec : val :=
  <{ fix 'f 'n =>
       let 'b = ('n <= 1) in
       if 'b
         then 1
         else let 'x = 'n - 1 in
              let 'y = 'f 'x in
              'n * 'y }>.

(* 练习（4 星，标准，必做）：手工验证递归函数——
   良基归纳提供递归调用规格，分支与代入按 triple_incr 的模式处理。 *)

Lemma triple_factorec : forall n,
  n >= 0 ->
  triple (factorec n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  intros n. induction_wf IH: (downto 0) n. unfold downto in IH.
  intros Hn.
  applys triple_app_fix.
  { reflexivity. }
  simpl.
  applys triple_let.
  { applys triple_le. }
  intros b. simpl.
  applys triple_hpure'. intros ->.
  applys triple_if. case_if as C. rew_bool_eq in *.
  { applys triple_val. xsimpl.
    asserts E: (facto n = 1). { applys facto_init. math. }
    rewrite E. auto. }
  { applys triple_let.
    { applys triple_sub. }
    intros x. simpl. applys triple_hpure'. intros ->.
    applys triple_let.
    { applys IH. math. math. }
    intros y. simpl. applys triple_hpure'. intros ->.
    applys triple_conseq_frame.
    { applys triple_mul. }
    { xsimpl. }
    { intros r. xsimpl. intros ->.
      asserts H1: (n >= 1). { math. }
      rewrite (@facto_step n H1). auto. } }
Qed.

End ExamplePrograms2.

(* ---------- 98.21 小结 ----------
   1) 语言构件规则（seq/let/if/val/fun/fix/app）全部由 97 章的 eval 规则
      一行导出；app 类规则要求被调函数是已知的具体值；
   2) 原语规格遵循"最小足迹"约定：前条件只覆盖必须访问的内存；
   3) triple_incr 的手工证明揭示了 x 战术的四大件：结构规则、构件规则、
      原语规格与 xsimpl；evar ?Q1 由所用规格自动定值；
   4) eval_like 原理：语义等价的项满足相同三元组（eta、括号重排等）；
   5) 后续章节将自动化框架规则的应用、消除程序变量与代换的手工操作。 *)
