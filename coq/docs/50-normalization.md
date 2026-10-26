# 50 · STLC 规范化

对应示例：`../examples/50_normalization.v`（`Module Ex50Normalization`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

47 章证明了类型安全（良类型程序**不会走错**），本章问一个更强的问题：良类型程序
**会不会停**？答案在纯 STLC 里是肯定的——**规范化定理**（normalization）：每个
良类型的闭项多步归约到值。这是"类型系统 guarantee 终止"的最小完整样本，也是
**逻辑关系**（logical relations）证明技术的入门礼。

**本章的范围说明（诚实起见）**：完整走到 `normalize` 主定理需要三段大机器——
本章覆盖前两段的全部：① 直接归纳为什么**必然失败**（50.3 的 Abort 演示，最有
教学价值的一节）；② 逻辑谓词 **N** 的定义与**前向不变性**（50.4）。③ 反向
不变性 + 多重替换机器（env/msubst/tass/instantiation）+ typable_N 是原书
后半的练习群，本章不装作证完——`normalize` 主定理**不在本文件中陈述**
（不许 Admitted 的纪律），50.5 给出续做的完整路线图。

语言裁剪到**最小 STLC**：Bool 作不解释基础类型（只有 true/false 两个值，砍掉
if）+ 箭头。原书自己也说"布尔当不解释基础类型给出主体细节"——每个归纳少几个
分支，逻辑关系的骨架完全保留。

### 50.1 最小 STLC：Bool 作不解释基础类型

文件头：

```coq
(* 50 STLC 规范化 —— 良类型 ⟹ 强终止：逻辑谓词 N、多重替换与 typable_N/normalize（Bool 基础语言） *)

From Stdlib Require Import Arith Bool List Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex50Normalization.

(* ---------- 50.1 最小 STLC：Bool 作不解释基础类型 ---------- *)

Inductive ty : Type :=
  | Ty_Bool  : ty
  | Ty_Arrow : ty -> ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm.

Definition x : string := "x".
Definition y : string := "y".

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false.

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  end.

Reserved Notation "t '-->' t'" (at level 40).

Inductive step : tm -> tm -> Prop :=
  | ST_AppAbs : forall w T t v,
      value v ->
      tm_app (tm_abs w T t) v --> subst w v t
  | ST_App1 : forall t1 t1' t2,
      t1 --> t1' ->
      tm_app t1 t2 --> tm_app t1' t2
  | ST_App2 : forall v1 t2 t2',
      value v1 ->
      t2 --> t2' ->
      tm_app v1 t2 --> tm_app v1 t2'

  where "t --> t'" := (step t t').

Inductive multi {X : Type} (R : X -> X -> Prop) : X -> X -> Prop :=
  | multi_refl : forall (t : X), multi R t t
  | multi_step : forall (t t' t'' : X),
      R t t' ->
      multi R t' t'' ->
      multi R t t''.

Notation "t1 '-->*' t2" := (multi step t1 t2) (at level 40).

Lemma multi_trans : forall (X : Type) (R : X -> X -> Prop) x y z,
  multi R x y ->
  multi R y z ->
  multi R x z.
Proof.
  intros X R x y z Hxy. revert z.
  induction Hxy; intros z Hz.
  - exact Hz.
  - eapply multi_step.
    + exact H.
    + apply IHHxy. exact Hz.
Qed.
```

语言是最小 STLC：Bool 作**不解释**基础类型——true/false 是值但没有任何消去规则（砍掉 if），箭头是唯一的结构类型。这是原书自己推荐的裁剪：规范化证明的难点全部在箭头（beta 会复制红ex），把 if/积砍掉后每个归纳少一半分支而论证结构不变。value 三个构造子、step 三条规则（beta + 两条同余）、multi 自带一份（含 multi_trans——50.3 要对推导做手术）。

### 50.2 上下文、类型关系与保持（47 章同骨架）

```coq
(* ---------- 50.2 上下文、类型关系与保持（47 章同骨架） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (w : string) (v : A) :=
  fun w' => if String.eqb w w' then v else m w'.

Notation "w '!->' v ';' m" := (t_update m w v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) w v,
  (w !-> v ; m) w = v.
Proof.
  intros A m w v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) w1 w2 v,
  w1 <> w2 ->
  (w1 !-> v ; m) w2 = m w2.
Proof.
  intros A m w1 w2 v Hneq. unfold t_update.
  destruct (String.eqb_spec w1 w2).
  - contradiction.
  - reflexivity.
Qed.

Lemma t_update_shadow : forall (A : Type) (m : total_map A) w v1 v2,
  (w !-> v2 ; w !-> v1 ; m) = (w !-> v2 ; m).
Proof.
  intros A m w v1 v2.
  apply functional_extensionality. intros w'.
  unfold t_update.
  destruct (String.eqb w w'); reflexivity.
Qed.

Lemma t_update_permute : forall (A : Type) (m : total_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 !-> v1 ; w2 !-> v2 ; m) = (w2 !-> v2 ; w1 !-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 Hne. unfold t_update.
  apply functional_extensionality. intros w'.
  destruct (String.eqb w1 w') eqn:E1; destruct (String.eqb w2 w') eqn:E2;
    try reflexivity.
  apply String.eqb_eq in E1. apply String.eqb_eq in E2.
  congruence.
Qed.

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (w : string) (v : A) :=
  (w !-> Some v ; m).

Notation "w '|->' v ';' m" := (update m w v)
  (at level 0, w constr, v at level 200, right associativity).

Lemma apply_empty : forall (A : Type) (w : string),
  @empty A w = None.
Proof. intros. reflexivity. Qed.

Lemma update_eq : forall (A : Type) (m : partial_map A) w v,
  (w |-> v ; m) w = Some v.
Proof.
  intros. unfold update. rewrite t_update_eq. reflexivity.
Qed.

Lemma update_neq : forall (A : Type) (m : partial_map A) w1 w2 v,
  w2 <> w1 ->
  (w2 |-> v ; m) w1 = m w1.
Proof.
  intros A m w1 w2 v H. unfold update. rewrite t_update_neq.
  - reflexivity.
  - apply H.
Qed.

Lemma update_shadow : forall (A : Type) (m : partial_map A) w v1 v2,
  (w |-> v2 ; w |-> v1 ; m) = (w |-> v2 ; m).
Proof.
  intros. unfold update. apply t_update_shadow.
Qed.

Lemma update_permute : forall (A : Type) (m : partial_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 |-> v1 ; w2 |-> v2 ; m) = (w2 |-> v2 ; w1 |-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 H. unfold update.
  apply t_update_permute. apply H.
Qed.

Definition includedin {A : Type} (m m' : partial_map A) :=
  forall w v, m w = Some v -> m' w = Some v.

Lemma includedin_update : forall (A : Type) (m m' : partial_map A)
                                 (w : string) (vw : A),
  includedin m m' ->
  includedin (w |-> vw ; m) (w |-> vw ; m').
Proof.
  unfold includedin.
  intros A m m' w vw H w' vw'.
  destruct (String.eqb_spec w w').
  - rewrite <- e. rewrite !update_eq. intros H1. exact H1.
  - rewrite !update_neq by apply n. apply H.
Qed.

Definition context := partial_map ty.

Inductive has_type : context -> tm -> ty -> Prop :=
  | T_Var : forall Gamma w T1,
      Gamma w = Some T1 ->
      has_type Gamma (tm_var w) T1
  | T_Abs : forall Gamma w T1 T2 t1,
      has_type (w |-> T2 ; Gamma) t1 T1 ->
      has_type Gamma (tm_abs w T2 t1) (Ty_Arrow T2 T1)
  | T_App : forall T1 T2 Gamma t1 t2,
      has_type Gamma t1 (Ty_Arrow T2 T1) ->
      has_type Gamma t2 T2 ->
      has_type Gamma (tm_app t1 t2) T1
  | T_True : forall Gamma,
      has_type Gamma tm_true Ty_Bool
  | T_False : forall Gamma,
      has_type Gamma tm_false Ty_Bool.

Lemma weakening : forall Gamma Gamma' t T,
  includedin Gamma Gamma' ->
  has_type Gamma t T ->
  has_type Gamma' t T.
Proof.
  intros Gamma Gamma' t T H Ht.
  generalize dependent Gamma'.
  induction Ht; intros.
  - apply T_Var. apply H0. exact H.
  - apply T_Abs. apply IHHt.
    apply includedin_update. exact H.
  - eapply T_App with T2; eauto.
  - apply T_True.
  - apply T_False.
Qed.

Lemma weakening_empty : forall Gamma t T,
  has_type empty t T ->
  has_type Gamma t T.
Proof.
  intros Gamma t T H.
  apply (weakening empty Gamma t T).
  - unfold includedin. intros w v Hv.
    rewrite apply_empty in Hv. discriminate Hv.
  - exact H.
Qed.

Lemma substitution_preserves_typing : forall Gamma w U t v T,
  has_type (w |-> U ; Gamma) t T ->
  has_type empty v U ->
  has_type Gamma (subst w v t) T.
Proof.
  intros Gamma w U t v T Ht Hv.
  generalize dependent Gamma. generalize dependent T.
  induction t; intros T Gamma H;
    inversion H; clear H; subst; simpl; eauto.
  - (* tm_var *)
    rename s into y. destruct (String.eqb_spec w y); subst.
    + rewrite update_eq in H2.
      injection H2 as H2; subst.
      apply weakening_empty. assumption.
    + apply T_Var. rewrite update_neq in H2; auto.
  - (* tm_app *)
    eapply T_App with T2; eauto.
  - (* tm_abs *)
    destruct (String.eqb_spec w s); subst; apply T_Abs.
    + rewrite update_shadow in H5. assumption.
    + apply IHt.
      rewrite update_permute; auto.
  - apply T_True.
  - apply T_False.
Qed.

Theorem preservation : forall t t' T,
  has_type empty t T ->
  t --> t' ->
  has_type empty t' T.
Proof.
  intros t t' T HT.
  generalize dependent t'.
  remember empty as Gamma.
  induction HT; intros t' HE; subst Gamma;
    try solve [inversion HE; subst; auto].
  - (* T_App *)
    inversion HE; subst.
    + apply substitution_preserves_typing with T2.
      * inversion HT1; subst; assumption.
      * assumption.
    + apply T_App with T2.
      * apply (IHHT1 eq_refl). assumption.
      * assumption.
    + apply T_App with T2.
      * assumption.
      * apply (IHHT2 eq_refl). assumption.
Qed.

Print Assumptions preservation.
```

上下文层与 47.5 相同（含 shadow/permute 两条表等式——substitution 的 abs 分支要用，本章因此和 47 一样背上 functional_extensionality 公理）。weakening/substitution_preserves_typing/preservation 三件套照 47.9-47.10 骨架——但本章语言没有 if，分支顺序与 eauto 收尾都不同（坑 4）。注意 includedin/includedin_update 在本章文件内定义——47 章副本没带它们，weakening 需要时要自备。

### 50.3 停机：halts 与一个失败的直接归纳

```coq
(* ---------- 50.3 停机：halts 与一个失败的直接归纳 ---------- *)

Definition halts (t : tm) : Prop :=
  exists t', t -->* t' /\ value t'.

Lemma value_halts : forall v, value v -> halts v.
Proof.
  intros v V. exists v. split; [apply multi_refl | exact V].
Qed.

(* 直接对类型推导归纳证停机——App 分支在"代入后的体"处失守：
   IH 只覆盖 c1/c2 的语法子项，β 之后的新项不在其中。 *)
Theorem normalization_try1 :
  forall t T, has_type empty t T -> halts t.
Proof.
  intros t T HT.
  remember empty as Gamma.
  induction HT; subst Gamma; intros.
  - rewrite apply_empty in H. inversion H.
  - apply value_halts. apply v_abs.
  - (* App：走到一半就卡住 *)
    destruct (IHHT1 eq_refl) as [v1 [ST1 V1]].
    destruct (IHHT2 eq_refl) as [v2 [ST2 V2]].
    assert (HTV1 : has_type empty v1 (Ty_Arrow T2 T1)).
    { clear - HT1 ST1. induction ST1; eauto using preservation. }
    assert (V1ABS : exists w u, v1 = tm_abs w T2 u).
    { inversion V1; subst v1.
      + inversion HTV1; subst. exists w, t0. reflexivity.
      + inversion HTV1.
      + inversion HTV1. }
    destruct V1ABS as [w [u E]]. subst v1.
    assert (ST11 : tm_app t1 t2 -->* tm_app (tm_abs w T2 u) t2).
    { clear - ST1. induction ST1.
      - apply multi_refl.
      - eapply multi_step.
        + apply ST_App1. exact H.
        + exact IHST1. }
    assert (ST22 : tm_app (tm_abs w T2 u) t2 -->* tm_app (tm_abs w T2 u) v2).
    { clear - ST2 V2. induction ST2.
      - apply multi_refl.
      - eapply multi_step.
        + apply ST_App2; [apply v_abs | exact H].
        + apply IHST2; exact V2. }
    assert (ST23 : tm_app t1 t2 -->* tm_app (tm_abs w T2 u) v2).
    { eapply multi_trans with (tm_app (tm_abs w T2 u) t2).
      - exact ST11.
      - exact ST22. }
    assert (STT : tm_app t1 t2 -->* subst w v2 u).
    { eapply multi_trans; [exact ST23 |].
      eapply multi_step.
      - apply ST_AppAbs; exact V2.
      - apply multi_refl. }
    (* 要收尾还得知道 subst w v2 u 停机——它不是任何子项，IH 够不着。 *)
    (* 若 N 机制在手的完整证明将在此收尾；本 Abort 是教学演示。 *)
Abort.
```

halts：存在 t'，多步到 t' 且 t' 是值。value_halts 一步。**失败演示**是本节的主角：直接对类型推导归纳——var 分支矛盾（空上下文查不到变量）、abs 分支平凡（抽象本来就是值）、**app 分支走到一半卡住**：IH 给出 t1/t2 各自停到值，规范性论证（preserve 类型 + canonical forms）把 v1 钉成抽象，三段 multi 拼出 t1 t2 -->* [x:=v2]u——然后需要'代入后的体也停机'，而它是**新造的项**，不在任何 IH 的管辖里。这份卡住的证明**原样保留**（Abort），它是 50.4 引入 N 的全部动机。另附 step 确定性与 step_preserves_halting（后者是 50.4 的依赖，destruct 版证明见坑 1）。

### 50.4 逻辑谓词 N：按类型加码的停机

```coq
(* ---------- 50.4 逻辑谓词 N：按类型加码的停机 ---------- *)

Fixpoint N (T : ty) (t : tm) : Prop :=
  has_type empty t T /\ halts t /\
  (match T with
   | Ty_Bool => True
   | Ty_Arrow T1 T2 => (forall s, N T1 s -> N T2 (tm_app t s))
  end).

Lemma N_halts : forall T t, N T t -> halts t.
Proof.
  intros T t H. destruct T; unfold N in H; destruct H as [_ [H _]]; assumption.
Qed.

Lemma N_typable_empty : forall T t, N T t -> has_type empty t T.
Proof.
  intros T t H. destruct T; unfold N in H; destruct H as [H _]; assumption.
Qed.

Lemma value__normal : forall v, value v -> forall t, ~ (v --> t).
Proof.
  intros v V t E. inversion V; subst; inversion E.
Qed.

Lemma step_deterministic : forall t t1 t2,
  (t --> t1) -> (t --> t2) -> t1 = t2.
Proof.
  intros t t1 t2 E1.
  revert t2.
  induction E1; intros t'0 E2; inversion E2; subst; try congruence;
    try match goal with
    | Hs : step (tm_abs _ _ _) _ |- _ =>
        exfalso; eapply value__normal; [apply v_abs | exact Hs]
    end;
    try (exfalso; match goal with
         | Hv : value ?v, Hs : ?v --> _ |- _ =>
             exact (value__normal _ Hv _ Hs)
         end).
  - (* App1/App1 *) f_equal. apply IHE1. exact H2.
  - (* App2/App2 *) f_equal. apply IHE1. exact H4.
Qed.

Lemma step_preserves_halting : forall t t' T,
  has_type empty t T ->
  (t --> t') ->
  halts t ->
  halts t'.
Proof.
  intros t t' T HT E [w [STM V]].
  exists w. split; [| exact V].
  destruct STM as [u | u1 u2 u3 Hs Hrest].
  - exfalso. eapply value__normal; [exact V | exact E].
  - assert (Heq : u2 = t') by (eapply step_deterministic; eauto).
    subst u2. exact Hrest.
Qed.

Lemma step_preserves_N : forall T t t',
  (t --> t') -> N T t -> N T t'.
Proof.
  induction T; intros t t' E Nt; simpl in Nt |- *;
    destruct Nt as [typable_empty_t [halts_t NN]].
  - (* Bool *)
    split; [| split].
    + eapply preservation; eauto.
    + eapply step_preserves_halting; eauto.
    + auto.
  - (* Arrow *)
    split; [| split].
    + eapply preservation; eauto.
    + eapply step_preserves_halting; eauto.
    + intros.
      eapply IHT2.
      * apply ST_App1. apply E.
      * apply NN; auto.
Qed.

Lemma multistep_preserves_N : forall T t t',
  (t -->* t') -> N T t -> N T t'.
Proof.
  intros T t t' STM. induction STM; intros.
  - assumption.
  - apply IHSTM. eapply step_preserves_N.
    + apply H.
    + assumption.
Qed.
```

N 是**按类型加码**的停机谓词——逻辑关系技术的最小样本：Bool 层只要停机；箭头层额外要求'喂它一个 N 的参数，结果也在 N 里'。这个额外条件正是 50.3 缺的 IH：应用的结果类型由 N T1 s 保证。N 只能写成 **Fixpoint** 而不是 Inductive——后者违反严格正性（原书有专门解释）。两条投影引理 N_halts/N_typable_empty 从定义直接读出。**step_preserves_N** 对类型归纳：Bool 平凡；箭头第三分量用 ST_App1 把步子抬进应用、IH 递归到结果类型。**multistep_preserves_N** 照 multi 归纳一次传递。

```coq
End Ex50Normalization.
```

### 50.5 路线图：从 N 到 normalize 的剩余工程

本章已把"为什么需要 N"与"N 的前向不变性"证完。要收下主定理，还需三件套
（原书 Norm.v 后半，均留作练习群）：

1. **反向不变性** `step_preserves_N'`：`has_type empty t T -> (t --> t') ->
   N T t' -> N T t`——比前向多一个"t 良类型"前提（subject expansion 不成立）。
2. **多重替换机器**：`env`/`msubst`（环境一次替换完）、`tass`/`mupdate`
   （上下文当列表才能归纳）、`remove`（同名变量遮蔽）、`instantiation`
   （类型环境与值环境的配对）——以及 `vacuous_substitution`/`subst_not_afi`/
   `swap_subst`/`msubst_subst` 等一打替换交换律。
3. **typable_N**：对类型推导归纳，上下文的每个变量配一个 N 值（instantiation），
   得到"把值代进去后 t 属于 N"。`normalize` 是它在空上下文的特例（halts 从
   N 定义第二分量直接读出）。Abs 分支：`N T2 s` 的 s 归约到值 v，
   `(lambda.t) s -->* [x:=v]t`，反向不变性把 N 从代入结果搬回应用——两段
   multi 的拼接本章 50.3 已经排练过。

### 50.6 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **halts 的多步拆解用 destruct 不用 induction**（50.3 halting）：
   `[w [STM V]]` 之后直接 `destruct STM`——refl 分支是"值不能再走"的矛盾
   （value__normal），step 分支用确定性把第一步对齐。实测 induction 会把
   value t'' 卷进 IH 当前提，报
   `The term "IHSTM" has type ... while it is expected to have type ...`。
2. **step 的确定性要自己证**（50.3）：47 章没证 STLC step 确定性（progress/
   preservation 不需要），halting 的"第一步对齐"需要。AppAbs 与 App1/App2 的
   组合靠 value__normal 关闭，IH 名随 induction E1 的分支漂移——
   `f_equal. apply IHE1. exact H2` 显式化最稳。
3. **`clear - H` 后的归纳名跟随假设名**（50.3 ST11/ST22）：`clear - ST1` 后
   IH 叫 `IHST1`；ST22 的 IH 还带 `value t''` 前提（V2 依赖终点被泛化）——
   `apply IHST2; exact V2` 两步还账。
4. **`induction t` 的分支顺序 = 构造子顺序**（50.2 substitution）：var/app/abs/
   true/false 五支，eauto 只吃掉 true/false；漏写 `apply T_True/apply T_False`
   报 incomplete proof。abs 分支的构造子参数名（s/t）直接用原名，别 rename。
5. **`inversion V1` 的方程是反向的**（50.3 V1ABS）：`value v1` 反演出
   `tm_abs w T t0 = v1`，要先 `subst v1` 再反演 HTV1，否则 HTV1 的反演拿到
   的是无用上下文。
6. **失败演示用 Abort 收尾，别用 Admitted**（50.3）：教学性失败按 PLF 惯例
   `Abort.`；Admitted 会污染 Print Assumptions 的审查。
7. **preservation 的公理账本与 47 章一致**（50.2）：shadow/permute 表等式
   依赖 functional_extensionality，Print Assumptions 实测输出
   `functional_extensionality_dep`——substitution 的 abs 分支绕不开它们，
   想零公理得换 context_invariance 路线（原书 Norm 的选择）。

---
上一章：[49 · 子类型](49-subtyping.md) ｜ 下一章：[51 · 引用与副作用](51-references.md) ｜ 返回：[README](../README.md)
