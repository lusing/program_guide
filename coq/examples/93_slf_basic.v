(* 93 分离逻辑入门 —— triple/H/Q 三元组、x-tactics、分离合取与框架性质、递归函数 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Basic 章， *)

Set Implicit Arguments.
From SLF Require Import LibSepReference.
Import ProgramSyntax DemoPrograms.

Implicit Types n m : int.
Implicit Types p q : loc.

(* ---------- 93.1 第一个函数：incr 与它的规格 ---------- *)

Definition incr : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       'p := 'm }>.

Lemma triple_incr : forall (p:loc) (n:int),
  triple <{ incr p }>
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr : triple.

(* 借助强制转换（coercion），程序调用可以直接写成 incr p 而不必写 <{ incr p }>。 *)

Lemma triple_incr' : forall (p:loc) (n:int),
  triple (incr p)
    (p ~~> n)
    (fun _ => (p ~~> (n+1))).
Proof.
  xwp. xapp. xapp. xapp. xsimpl.
Qed.

(* ---------- 93.2 纯计算：空堆谓词 \[] 与纯事实 \[P] ---------- *)

Definition example_let : val :=
  <{ fun 'n =>
      let 'a = 'n + 1 in
      let 'b = 'n - 1 in
      'a + 'b }>.

Lemma triple_example_let : forall (n:int),
  triple (example_let n)
    \[]
    (fun r => \[r = 2*n]).
Proof.
  xwp. xapp. xapp. xapp. xsimpl. math.
Qed.

(* 练习：quadruple n 返回 4*n。 *)

Definition quadruple : val :=
  <{ fun 'n =>
       let 'm = 'n + 'n in
       'm + 'm }>.

Lemma triple_quadruple : forall (n:int),
  triple (quadruple n)
    \[]
    (fun r => \[r = 4*n]).
Proof.
  xwp. xapp. xapp. xsimpl. math.
Qed.

(* 练习：inplace_double 就地把引用内容翻倍。 *)

Definition inplace_double : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 'n in
       'p := 'm }>.

Lemma triple_inplace_double : forall (p:loc) (n:int),
  triple (inplace_double p)
    (p ~~> n)
    (fun _ => p ~~> (2*n)).
Proof.
  xwp. xapp. xapp. xapp. xsimpl. math.
Qed.

(* ---------- 93.3 分离合取 \* 与 incr_two ---------- *)

Definition incr_two : val :=
  <{ fun 'p 'q =>
       incr 'p;
       incr 'q }>.

Lemma triple_incr_two : forall (p q:loc) (n m:int),
  triple (incr_two p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> (m+1)).
Proof using.
  xwp. xapp. xapp. xsimpl.
Qed.

#[global] Hint Resolve triple_incr_two : triple.

(* ---------- 93.4 别名参数：incr_two p p ---------- *)

Definition aliased_call : val :=
  <{ fun 'p =>
       incr_two 'p 'p }>.

(* 用 triple_incr_two 去推 aliased_call 会卡住： Preconditions 要求 p ~~> ?n \* p ~~> ?m，
   而手里只有一份 p ~~> n。这个不可证的义务 (\[] ==> p ~~> ?m \* _) 正是分离合取
   「两块不相交」约束的直接体现。 *)

Lemma triple_aliased_call_attempt : forall (p:loc) (n:int),
  triple (aliased_call p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp.
Abort.

(* 解决办法之一：为别名情形单独证一条规格。 *)

Lemma triple_incr_two_aliased : forall (p:loc) (n:int),
  triple (incr_two p p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp. xapp. xsimpl. math.
Qed.

Lemma triple_aliased_call : forall (p:loc) (n:int),
  triple (aliased_call p)
    (p ~~> n)
    (fun _ => p ~~> (n+2)).
Proof using.
  xwp. xapp triple_incr_two_aliased. xsimpl.
Qed.

(* ---------- 93.5 框架性质初见：未被触碰的资源 ---------- *)

Definition incr_first : val :=
  <{ fun 'p 'q =>
       incr 'p }>.

Lemma triple_incr_first : forall (p q:loc) (n m:int),
  triple (incr_first p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> m).
Proof using.
  xwp. xapp. xsimpl.
Qed.

Lemma triple_incr_first' : forall (p q:loc) (n:int),
  triple (incr_first p q)
    (p ~~> n)
    (fun _ => p ~~> (n+1)).
Proof using.
  xwp. xapp. xsimpl.
Qed.

(* 提到两个引用的规格可以从只提一个的规格推出来：这就是框架规则的力量。 *)

Lemma triple_incr_first_derived : forall (p q:loc) (n m:int),
  triple (incr_first p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+1) \* q ~~> m).
Proof using.
  intros. xapp triple_incr_first'. xsimpl.
Qed.

(* ---------- 93.6 练习：transfer ---------- *)

Definition transfer : val :=
  <{ fun 'p 'q =>
       let 'n = !'p in
       let 'm = !'q in
       let 's = 'n + 'm in
       'p := 's;
       'q := 0 }>.

Lemma triple_transfer : forall (p q:loc) (n m:int),
  triple (transfer p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n+m) \* q ~~> 0).
Proof using.
  xwp. xapp. xapp. xapp. xapp. xapp. xsimpl.
Qed.

Lemma triple_transfer_aliased : forall (p:loc) (n:int),
  triple (transfer p p)
    (p ~~> n)
    (fun _ => p ~~> 0).
Proof using.
  xwp. xapp. xapp. xapp. xapp. xapp. xsimpl.
Qed.

(* ---------- 93.7 分配：ref 与 funloc 记号 ---------- *)

Parameter triple_ref : forall (v:val),
  triple <{ ref v }>
    \[]
    (fun r => \exists p, \[r = val_loc p] \* p ~~> v).

Notation "'funloc' p '=>' H" :=
  (fun (r:val) => \exists p, \[r = val_loc p] \* H)
  (at level 200, p name, format "'funloc'  p  '=>'  H").

Parameter triple_ref' : forall (v:val),
  triple <{ ref v }>
    \[]
    (funloc p => p ~~> v).

Definition ref_greater : val :=
  <{ fun 'p =>
       let 'n = !'p in
       let 'm = 'n + 1 in
       ref 'm }>.

Lemma triple_ref_greater : forall (p:loc) (n:int),
  triple (ref_greater p)
    (p ~~> n)
    (funloc q => p ~~> n \* q ~~> (n+1)).
Proof using.
  xwp. xapp. xapp. xapp. intros q. xsimpl. auto.
Qed.

(* 练习：抽象规格——不透露新单元的内容，只说它比 n 大。 *)

Lemma triple_ref_greater_abstract : forall (p:loc) (n:int),
  triple (ref_greater p)
    (p ~~> n)
    (funloc q => p ~~> n \* \exists (m:int), \[m > n] \* q ~~> m).
Proof using.
  intros. xapp triple_ref_greater. intros q. xsimpl. auto. math.
Qed.

(* 框架规则给 ref 规格加一块既有状态后仍然成立——这间接说明了
   「新分配的单元与既有单元互不相同」这一关键事实。 *)

Parameter triple_ref_with_frame : forall (p':loc) (v':val) (v:val),
  triple <{ ref v }>
    (p' ~~> v')
    (funloc p => p ~~> v \* p' ~~> v').

(* ---------- 93.8 释放：free 与 xval ---------- *)

Definition succ_using_incr_attempt :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       ! 'p }>.

(* 后条件不提内部引用 p 就证不下去：卡在 p ~~> (n+1) ==> \[]。 *)

Lemma triple_succ_using_incr_attempt : forall (n:int),
  triple (succ_using_incr_attempt n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. { auto. }
Abort.

Lemma triple_succ_using_incr_attempt' : forall (n:int),
  triple (succ_using_incr_attempt n)
    \[]
    (fun r => \[r = n+1] \* \exists p, (p ~~> (n+1))).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. { auto. }
Qed.

Definition succ_using_incr :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       let 'x = !'p in
       free 'p;
       'x }>.

Lemma triple_succ_using_incr : forall n,
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros p. xapp. xapp.
  xapp. (* 推理 free p：消费掉堆谓词 p ~~> _ *)
  xval. (* 推理返回值 'x *)
  xsimpl. auto.
Qed.

(* 练习：get_and_free 读出内容并释放单元。 *)

Definition get_and_free : val :=
  <{ fun 'p =>
      let 'v = ! 'p in
      free 'p;
      'v }>.

Lemma triple_get_and_free : forall p v,
  triple (get_and_free p)
    (p ~~> v)
    (fun r => \[r = v]).
Proof using.
  xwp. xapp. xapp. xval. xsimpl. auto.
Qed.

#[global] Hint Resolve triple_get_and_free : triple.

(* ---------- 93.9 非确定性：rand ---------- *)

Parameter triple_rand : forall n,
  n > 0 ->
  triple (val_rand n)
    \[]
    (fun r => \exists m, \[r = val_int m] \* \[0 <= m < n]).

Definition two_dice : val :=
  <{ fun 'u =>
      let 'n1 = val_rand 6 in
      let 'n2 = val_rand 6 in
      let 's = 'n1 + 'n2 in
      's + 2 }>.

Lemma triple_two_dice :
  triple <{ two_dice () }>
    \[]
    (fun r => \exists n, \[r = val_int n] \* \[2 <= n <= 12]).
Proof using.
  xwp.
  xapp triple_rand. { math. } intros n1 Hn1.
  xapp triple_rand. { math. } intros n2 Hn2.
  xapp. xapp.
  xsimpl. math. math.
Qed.

(* ---------- 93.10 递归函数与良基归纳 ---------- *)

Module Facto.

Parameter facto : int -> int.

Parameter facto_init : forall n,
  0 <= n <= 1 ->
  facto n = 1.

Parameter facto_step : forall n,
  n >= 1 ->
  facto n = n * (facto (n-1)).

Lemma facto_succ : forall i,
  i >= 0 ->
  facto (i + 1) = (i + 1) * facto i.
Proof using.
  introv Hi. rewrite (@facto_step (i+1)). f_equal. f_equal. math. math.
Qed.

End Facto.

Import Facto.

(* 乘法写在左边时的配套版本：facto i * (i+1) = facto (i+1)。 *)

Lemma facto_succ_mul : forall i,
  i >= 0 ->
  facto i * (i+1) = facto (i+1).
Proof using.
  intros i Hi. rewrite facto_succ; [|math]. math.
Qed.

Definition factorec : val :=
  <{ fix 'f 'n =>
       let 'b = 'n <= 1 in
       if 'b
         then 1
         else let 'x = 'n - 1 in
              let 'y = 'f 'x in
              'n * 'y }>.

Lemma triple_factorec : forall n,
  n >= 0 ->
  triple (factorec n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  intros n. induction_wf IH: (downto 0) n.
  unfold downto in IH.
  intros Hn. xwp.
  xapp.
  xif.
  { intros C.
    xval. xsimpl.
    rewrite facto_init. math. math. }
  { intros C.
    xapp.
    xapp.
    { math. }
    { math. }
    xapp.
    xsimpl. rewrite (@facto_step n). math. math. }
Qed.

Definition repeat_incr : val :=
  <{ fix 'f 'p 'm =>
       let 'b = 'm > 0 in
       if 'b then
         incr 'p;
         let 'x = 'm - 1 in
         'f 'p 'x
       end }>.

(* 练习：注意归纳要放在 m 上，且 n、p 留在目标里随归纳假设通用。 *)

Lemma triple_repeat_incr : forall (m n:int) (p:loc),
  m >= 0 ->
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + m)).
Proof using.
  intros m. induction_wf IH: (downto 0) m. unfold downto in IH.
  intros Hm n p. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    { math. }
    xsimpl. math. }
  { xval. xsimpl. math. }
Qed.

(* 若删掉前提 m >= 0 会怎样？else 分支要求证 n = n + m，m 可为负时不可证。 *)

Lemma triple_repeat_incr_incorrect : forall (p:loc) (n m:int),
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + m)).
Proof using.
  intros. gen n. induction_wf IH: (downto 0) m. unfold downto in IH.
  intros. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp. { math. } xsimpl. math. }
  { xval.
    xsimpl.
Abort.

Lemma max_l : forall n m,
  n >= m ->
  max n m = n.
Proof using. intros. unfold max. case_if; math. Qed.

Lemma max_r : forall n m,
  n <= m ->
  max n m = m.
Proof using. intros. unfold max. case_if; math. Qed.

(* 练习（选做）：不约束 m 的最一般规格，用 max 0 m 兜住负数情形。 *)

Lemma triple_repeat_incr_max : forall (p:loc) (n m:int),
  triple (repeat_incr p m)
    (p ~~> n)
    (fun _ => p ~~> (n + max 0 m)).
Proof using.
  intros p n m. gen n.
  induction_wf IH: (downto 0) m. unfold downto in IH.
  intros n. xwp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    xsimpl.
    rewrite max_r; [|math]. rewrite max_r; [|math]. math. }
  { xval. xsimpl. rewrite max_l; [|math]. math. }
Qed.

Definition step_transfer :=
  <{ fix 'f 'p 'q =>
       let 'm = !'q in
       let 'b = 'm > 0 in
       if 'b then
         incr 'p;
         decr 'q;
         'f 'p 'q
       end }>.

Lemma triple_step_transfer : forall p q n m,
  m >= 0 ->
  triple (step_transfer p q)
    (p ~~> n \* q ~~> m)
    (fun _ => p ~~> (n + m) \* q ~~> 0).
Proof using.
  intros p q n m Hm. gen n Hm.
  induction_wf IH: (downto 0) m. unfold downto in IH.
  intros. xwp. xapp. xapp. xif; intros C.
  { xapp. xapp. xapp.
    { math. }
    { math. }
    xsimpl. math. }
  { xval. xsimpl. math. math. }
Qed.

(* ---------- 93.11 用状态算阶乘 ---------- *)

Definition factoimp_aux : val :=
  <{ fix 'f 'r 'i 'n =>
       let 'b = 'i < 'n in
       if 'b then
         let 'j = 'i + 1 in
         let 's = !'r in
         let 'p = 's * 'j in
         'r := 'p;
         'f 'r 'j 'n
       end }>.

Definition factoimp : val :=
  <{ fun 'n =>
       let 'r = ref 1 in
       factoimp_aux 'r 1 'n;
       let 'm = !'r in
       free 'r;
       'm }>.

(* 练习：循环不变量是 r ~~> facto i。 *)

Lemma triple_factoimp_aux : forall (r:loc) (i n:int),
  0 <= i <= n ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. induction_wf IH: (upto n) i. introv Hn.
  xwp. xapp. xif; intros C.
  { xapp.
    xapp.
    xapp.
    xapp.
    rewrite facto_succ_mul; [|math].
    xapp.
    { math. }
    { math. }
    xsimpl. }
  { xval. xsimpl.
    assert (E: i = n). { math. }
    rewrite E. auto. }
Qed.

(* 练习：主函数 factoimp。 *)

Lemma triple_factoimp : forall n,
  n >= 1 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux.
  { math. }
  { rewrite facto_init; [|math]. auto. }
  xapp. xapp. xval. xsimpl. auto.
Qed.

(* ---------- 93.12 选读：把 n = 0 也一并覆盖 ---------- *)

Lemma triple_factoimp_aux_zero : forall (r:loc) (i n:int),
  i = 1 ->
  n = 0 ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. introv Hi Hn.
  xwp. xapp. xif; intros C.
  { false. math. }
  { xval. xsimpl. subst.
    rewrite facto_init; [|math].
    rewrite facto_init; [|math]. auto. }
Qed.

Lemma triple_factoimp_zero : forall n,
  n = 0 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux_zero. { math. } { math. }
  { rewrite* facto_init. { math. } }
  xapp. xapp. xval. xsimpl. auto.
Qed.

(* 练习（选做）：把两种情形合并成一条析取前置条件，一遍过整个循环。 *)

Lemma triple_factoimp_aux' : forall (r:loc) (i n:int),
  (i = 1 /\ n = 0) \/ (0 <= i <= n) ->
  triple (factoimp_aux r i n)
    (r ~~> facto i)
    (fun _ => r ~~> facto n).
Proof using.
  introv. induction_wf IH: (upto n) i. introv Hn.
  xwp. xapp. xif; intros C.
  { destruct Hn as [(?&?)|?]; [ false; math | ].
    xapp.
    xapp.
    xapp.
    xapp.
    rewrite facto_succ_mul; [|math].
    xapp.
    { math. }
    { right. math. }
    xsimpl. }
  { destruct Hn as [(?&?)|?].
    { subst. xval. xsimpl.
      rewrite facto_init; [|math].
      rewrite facto_init; [|math]. auto. }
    { xval. xsimpl.
      assert (E: i = n). { math. }
      rewrite E. auto. } }
Qed.

Lemma triple_factoimp' : forall n,
  n >= 0 ->
  triple (factoimp n)
    \[]
    (fun r => \[r = facto n]).
Proof using.
  introv Hn. xwp. xapp. intros r.
  xapp triple_factoimp_aux'.
  { destruct (classic (n = 0)) as [E|E].
    { left. auto. }
    { right. math. } }
  { rewrite facto_init; [|math]. auto. }
  xapp. xapp. xval. xsimpl. auto.
Qed.
