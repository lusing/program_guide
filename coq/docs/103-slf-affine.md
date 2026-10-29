# 103. 仿射分离逻辑：可丢弃资源与 `\GC`

对应示例：`../examples/103_slf_affine.v`（rocq 9.1.1 + SLF 库实测编译退出码 0）

取材 Software Foundations 卷六 *Separation Logic Foundations*（v1.0）的 *Affine* 章。原书 14 个练习均在本章示例中完整证明，无 `Admitted`。

---

## 103.0 从线性资源到可丢弃资源

此前各章的分离逻辑是**线性**的：前条件中的每份资源都必须在后条件中得到交代。这很适合显式释放内存的语言，却不适合带垃圾回收的语言。例如，函数内部分配一个引用，返回时引用已经不可达；若逻辑不允许丢弃它，规格就被迫把这块无用内存写进后条件，并逐层泄漏给所有调用者。

仿射逻辑增加**丢弃规则**。但“任何资源都能丢”并不总是合理：文件句柄应当关闭，锁应当释放，这些资源即使位于带 GC 的语言中也应保持线性。因此，本章不直接加入一条无限制规则，而是构造一套可配置的**部分仿射分离逻辑**：

1. 用 `heap_affine h` 说明堆片段 `h` 可以丢弃；
2. 用 `haffine H` 说明堆谓词 `H` 只描述可丢弃的堆；
3. 用 affine-top 谓词 `\GC` 统一表示“某些可以丢弃的资源”；
4. 把三元组精化为“求值结果除了满足后条件，还可以留下 `\GC`”；
5. 重新证明结构规则、WP 规则和 `mkstruct` 规则，并实现 `xgc`、`xgc_keep`、`xgc_post`。

示例放在 `Affine` 模块中，以免本章的可配置定义与 `LibSepReference` 中为日常验证准备的全仿射实例混淆。

```coq
(* 103 仿射分离逻辑：可丢弃资源、affine-top、精化三元组与 GC 战术 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Affine 章。 *)

Set Implicit Arguments.
From SLF Require Export LibSepReference.

Implicit Types f : var.
Implicit Types b : bool.
Implicit Types v : val.
Implicit Types h : heap.
Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.

Module Affine.
```

---

## 103.1 动机：后条件不该泄漏临时单元

函数 `succ_using_incr` 分配初值为 `n` 的引用，执行一次 `incr`，再读出结果。在线性逻辑中，证明可以顺利完成，但后条件必须包含 `\exists p, p ~~> (n+1)`。调用者只关心结果等于 `n+1`，却仍要携带这个已经无法访问的单元。

```coq
(* ---------- 103.1 动机：不能泄漏的内存单元 ---------- *)

Module MotivatingExample.
Export DemoPrograms.

Definition succ_using_incr :=
  <{ fun 'n =>
       let 'p = ref 'n in
       incr 'p;
       ! 'p }>.

(* 在线性逻辑中，后条件必须交代函数留下的引用单元。 *)

Lemma triple_succ_using_incr : forall (n:int),
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1] \* \exists p, (p ~~> (n+1))).
Proof using.
  xwp. xapp. intros p. xapp. xapp. xsimpl. auto.
Qed.

End MotivatingExample.
```

若把后条件直接写成 `fun r => \[r = n+1]`，最后会剩下 `p ~~> (n+1) ==> \[]`，在线性逻辑中无法证明。本章后续不是针对这一个例子打补丁，而是修改三元组的语义，使“留下可回收资源”成为逻辑正式支持的行为。

---

## 103.2 资源策略：`heap_affine` 与 `haffine`

### 103.2.1 两条最小假设

`heap_affine` 是由逻辑设计者选择的资源策略。本章不对它作额外假设，只要求：

- 空堆可丢弃；
- 两个不相交的可丢弃堆，其并集仍可丢弃。

这里的 `Parameter` 是抽象接口，不是未完成的练习。后面会分别实例化为“所有堆均可丢弃”和“只有空堆可丢弃”，验证接口确实涵盖两种极端逻辑。

```coq
(* ---------- 103.2 哪些堆和堆谓词可以丢弃 ---------- *)

(* heap_affine 是程序逻辑设计者提供的资源策略；这里只假设空堆可丢弃，
   且两个不相交可丢弃堆的并仍可丢弃。 *)

Parameter heap_affine : heap -> Prop.

Parameter heap_affine_empty :
  heap_affine Fmap.empty.

Parameter heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).
```

堆谓词 `H` 仿射，当且仅当每个满足 `H` 的堆都仿射。注意这不是要求 `H` 在所有堆上成立，而是对 `H` 实际描述的那些堆作限制。

```coq
(* 一个堆谓词仿射，当且仅当它只在仿射堆上成立。 *)

Definition haffine (H:hprop) : Prop :=
  forall h, H h -> heap_affine h.
```

### 103.2.2 常见构造保持仿射性

`\[]` 与 `\[P]` 都只描述空堆，因此仿射。分离合取则把满足 `H1` 和 `H2` 的两个不相交堆拼起来，正好使用 `heap_affine_union`。

```coq
Lemma haffine_hempty :
  haffine \[].
Proof using.
  introv K. lets E: hempty_inv K. subst. applys heap_affine_empty.
Qed.

Lemma haffine_hpure : forall P,
  haffine \[P].
Proof using.
  intros. intros h K. lets (HP&M): hpure_inv K.
  subst. applys heap_affine_empty.
Qed.

Lemma haffine_hstar : forall H1 H2,
  haffine H1 ->
  haffine H2 ->
  haffine (H1 \* H2).
Proof using.
  introv M1 M2 K. lets (h1&h2&K1&K2&D&U): hstar_inv K.
  subst. applys* heap_affine_union.
Qed.
```

量词规则看似不对称，其实来自消除方向：

- 若 `h` 满足 `\exists x, J x`，只能得到某个未知的 `x`，所以必须知道**每个** `J x` 都仿射；
- 若 `h` 满足 `\forall x, J x`，可以任选一个 `x` 实例化，所以只要有**一个**仿射分支就足够。

```coq
Lemma haffine_hexists : forall A (J:A->hprop),
  (forall x, haffine (J x)) ->
  haffine (\exists x, (J x)).
Proof using. introv F1 (x&Hx). applys* F1. Qed.

(* 对全称量词，只要有一个分支仿射即可；对存在量词则必须全部分支仿射。 *)

Lemma haffine_hforall' : forall A (J:A->hprop),
  (exists x, haffine (J x)) ->
  haffine (\forall x, (J x)).
Proof using.
  introv (x&Hx) M. lets N: hforall_inv M. applys* Hx.
Qed.
```

实际使用全称量词时，通常所有分支都仿射。此时需要类型可居住，以便选出一个 witnesses；SLF 用 `Inhab A` 和 `arbitrary` 表达这一点。纯事实与堆谓词合取时，则允许在 `P` 成立的前提下证明 `H` 仿射。

```coq
Lemma haffine_hforall : forall A `{Inhab A} (J:A->hprop),
  (forall x, haffine (J x)) ->
  haffine (\forall x, (J x)).
Proof using.
  introv IA M. applys haffine_hforall'. exists (arbitrary (A:=A)). applys M.
Qed.

Lemma haffine_hstar_hpure_l : forall P H,
  (P -> haffine H) ->
  haffine (\[P] \* H).
Proof using. introv M. intros h K. rewrite hstar_hpure_l in K. applys* M. Qed.
```

---

## 103.3 affine-top 谓词 `\GC`

### 103.3.1 定义与两个方向的刻画

`\GC` 的定义是“存在某个仿射谓词 `H`，并且当前堆满足 `H`”。相比直接写 `fun h => heap_affine h`，这个定义更适合 `xpull`、`xsimpl` 等分离逻辑战术处理。

```coq
(* ---------- 103.3 affine-top 谓词 \GC ---------- *)

(* \GC 表示“某个可丢弃谓词所描述的资源”。 *)

Definition hgc : hprop :=
  \exists H, \[haffine H] \* H.

Declare Scope hgc_scope.
Open Scope hgc_scope.

Notation "\GC" := (hgc) : hgc_scope.
```

**练习 `hgc_intro`**：已知 `heap_affine h`，选择谓词 `(= h)`，即“恰好是堆 `h`”。它当然仿射，而当前堆也满足它。`hstar_hpure_l` 把纯事实与 `(= h)` 的分离合取化成普通合取。

```coq
(* 原书练习（2 星）：从底层堆的仿射性构造 \GC。 *)

Lemma hgc_intro : forall h,
  heap_affine h ->
  \GC h.
Proof using.
  intros h M. unfold hgc. exists (= h).
  rewrite hstar_hpure_l. split.
  { intros h' ->. exact M. }
  { reflexivity. }
Qed.
```

**练习 `hgc_inv`**：反向展开 `\GC`，得到某个 `H`、`haffine H` 和 `H h`，直接应用仿射谓词的定义即可。两个方向合起来说明 `\GC` 与底层的 `heap_affine` 是同一个谓词。

```coq
(* 原书练习（2 星）：从 \GC 消去得到底层堆的仿射性。 *)

Lemma hgc_inv : forall h,
  \GC h ->
  heap_affine h.
Proof using.
  intros h M. unfold hgc in M. destruct M as (H&M).
  rewrite hstar_hpure_l in M. destruct M as (A&K). applys A K.
Qed.

Lemma hgc_eq_heap_affine :
  hgc = heap_affine.
Proof using.
  intros. applys himpl_antisym.
  { intros h M. applys* hgc_inv. }
  { intros h M. applys* hgc_intro. }
Qed.
```

### 103.3.2 合并、吸收与自身仿射性

两份 `\GC` 描述的两块不相交垃圾仍可合并为一份垃圾；反过来，一份垃圾也能看成“它自己加空垃圾”。证明使用 `haffine_hstar` 和 `haffine_hempty`。

```coq
(* 两份垃圾可以合并成一份；\GC 自身也是仿射谓词。 *)

Lemma hstar_hgc_hgc :
  (\GC \* \GC) = \GC.
Proof using.
  unfold hgc. applys himpl_antisym.
  { xpull. intros H1 K1 H2 K2. xsimpl (H1 \* H2). applys* haffine_hstar. }
  { xpull. intros H K. xsimpl H \[]. auto. applys haffine_hempty. }
Qed.
```

`\GC` 自身仿射，因为它定义的每个分支都是 `\[haffine H] \* H`，而纯事实规则恰好允许在 `haffine H` 的前提下证明这个合取仿射。于是任意仿射谓词都蕴含 `\GC`，空堆谓词是其特例。

```coq
Lemma haffine_hgc :
  haffine \GC.
Proof using.
  applys haffine_hexists. intros H. applys haffine_hstar_hpure_l. auto.
Qed.

Lemma himpl_hgc_r : forall H,
  haffine H ->
  H ==> \GC.
Proof using. introv M. intros h K. applys hgc_intro. applys M K. Qed.

Lemma hempty_himpl_hgc :
  \[] ==> \GC.
Proof using. applys himpl_hgc_r. applys haffine_hempty. Qed.
```

**练习 `himpl_hgc_absorb_r`**：先用 `himpl_hgc_r` 把右侧的 `H` 改成 `\GC`，再利用 `hstar_hgc_hgc` 合并。这条规则是后续所有“把垃圾并入已有垃圾”证明的基础。

```coq
(* 原书练习（3 星）：\GC 可以吸收任意仿射谓词。 *)

Lemma himpl_hgc_absorb_r : forall H,
  haffine H ->
  \GC \* H ==> \GC.
Proof using.
  introv M. xchange (himpl_hgc_r M). rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.
```

---

## 103.4 两种极端实例

### 103.4.1 全仿射：任何资源都能丢弃

取 `heap_affine h = True`，两条接口假设立即成立。此时每个堆谓词都仿射，而 `\GC` 等于 `htop`，即“任意堆”。这适合只把内存视为 GC 资源、没有文件句柄或锁等线性资源的设置。

```coq
(* ---------- 103.4 全仿射与全线性两种极端实例 ---------- *)

Module FullyAffineLogic.

Parameter heap_affine_def : forall h,
  heap_affine h = True.

Lemma heap_affine_empty :
  heap_affine Fmap.empty.
Proof using. rewrite* heap_affine_def. Qed.

Lemma heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).
Proof using. intros. rewrite* heap_affine_def. Qed.

Lemma haffine_equiv : forall H,
  (haffine H) <-> True.
Proof using.
  intros. iff M.
  { auto. }
  { unfold haffine. intros. rewrite* heap_affine_def. }
Qed.

Definition htop : hprop :=
  \exists H, H.

Lemma hgc_eq_htop : hgc = htop.
Proof using.
  unfold hgc, htop. applys himpl_antisym.
  { xsimpl. }
  { xsimpl. intros. rewrite* haffine_equiv. }
Qed.

End FullyAffineLogic.
```

### 103.4.2 全线性：只有空资源能丢弃

取 `heap_affine h = (h = Fmap.empty)`。两个可丢弃堆都必须是空堆，其并也是空堆。此时 `haffine H` 等价于 `H ==> \[]`，`\GC` 退化为 `\[]`；把 `\GC` 加入后条件不会产生任何新能力，因此恢复此前的线性逻辑。

```coq
Module FullyLinearLogic.

Parameter heap_affine_def : forall h,
  heap_affine h = (h = Fmap.empty).

Lemma heap_affine_empty :
  heap_affine Fmap.empty.
Proof using. rewrite* heap_affine_def. Qed.

Lemma heap_affine_union : forall h1 h2,
  heap_affine h1 ->
  heap_affine h2 ->
  Fmap.disjoint h1 h2 ->
  heap_affine (Fmap.union h1 h2).
Proof using.
  introv K1 K2 D. rewrite heap_affine_def in *.
  subst. rewrite* Fmap.union_empty_r.
Qed.

Lemma haffine_equiv : forall H,
  haffine H <-> (H ==> \[]).
Proof using.
  intros. unfold haffine. iff M.
  { intros h K. specializes M K. rewrite heap_affine_def in M.
    subst. applys hempty_intro. }
  { intros h K. specializes M K. rewrite heap_affine_def.
    applys hempty_inv M. }
Qed.

Lemma hgc_eq_hempty : hgc = hempty.
Proof using.
  unfold hgc. applys himpl_antisym.
  { xpull. introv N. rewrite* haffine_equiv in N. }
  { xsimpl \[]. applys haffine_hempty. }
Qed.

End FullyLinearLogic.
```

这两个实例说明：部分仿射逻辑不是另一套互斥系统，而是由同一个 `heap_affine` 参数控制的一组系统。

---

## 103.5 精化三元组与六条丢弃规则

### 103.5.1 在语义中预留垃圾空间

原三元组要求 `eval s t Q`。新定义改成 `eval s t (Q \*+ \GC)`：正常结果仍满足 `Q`，但最终堆可以额外包含一份可丢弃资源。这里 `Q \*+ \GC` 是后条件上的分离合取，逐值把 `Q v` 与 `\GC` 组合。

```coq
(* ---------- 103.5 精化三元组并证明结构规则 ---------- *)

Module NewTriples.

(* 新定义把“求值后允许留下垃圾”直接编码进语义三元组。 *)

Definition triple (t:trm) (H:hprop) (Q:val->hprop) : Prop :=
  forall s, H s -> eval s t (Q \*+ \GC).
```

后果规则只需同时变形附加的 `\GC`。框架规则的关键是把框架堆 `H'` 保留到最终后条件，而不能把它误当成垃圾。纯事实和存在量词规则仍按原来的前提分解证明。

```coq
Lemma triple_conseq : forall t H' Q' H Q,
  triple t H' Q' ->
  H ==> H' ->
  Q' ===> Q ->
  triple t H Q.
Proof using.
  unfolds triple. introv M MH MQ HF. applys* eval_conseq. xsimpl*.
Qed.

Lemma triple_frame : forall t H Q H',
  triple t H Q ->
  triple t (H \* H') (Q \*+ H').
Proof using.
  introv M HF. lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. specializes M M1. applys eval_conseq.
  { applys eval_frame M MD. } { xsimpl. intros h' ->. applys M2. }
Qed.

Lemma triple_hpure : forall t (P:Prop) H Q,
  (P -> triple t H Q) ->
  triple t (\[P] \* H) Q.
Proof using.
  introv M. intros h (h1&h2&M1&M2&D&U). destruct M1 as (M1&HP).
  lets E: hempty_inv HP. subst. rewrite Fmap.union_empty_l. applys~ M.
Qed.

Lemma triple_hexists : forall t (A:Type) (J:A->hprop) Q,
  (forall (x:A), triple t (J x) Q) ->
  triple t (hexists J) Q.
Proof using. introv M (x&K). applys M K. Qed.
```

序列规则最能说明新定义为什么可行。第一段产生 `H1 \* \GC`；对第二段使用框架后，最终结果同时带有第一段和第二段的垃圾。用 `hstar_hgc_hgc` 合并，恰好回到精化三元组要求的单一 `\GC`。

```coq
(* 序列规则必须把两段求值各自留下的 \GC 合并。 *)

Lemma triple_seq : forall t1 t2 H Q H1,
  triple t1 H (fun v => H1) ->
  triple t2 H1 Q ->
  triple (trm_seq t1 t2) H Q.
Proof using.
  unfold triple. introv M1 M2. intros s Hs. applys eval_seq.
  { applys M1 Hs. }
  { simpl. intros v1 s2 Hs2. lets (h1&h2&N1&N2&D&->): hstar_inv (rm Hs2).
    applys eval_conseq. { applys eval_frame D. applys* M2. }
    asserts R: ((= h2) ==> \GC). { intros ? ->. auto. } xchange (rm R).
    xchange hstar_hgc_hgc. xsimpl. }
Qed.
```

### 103.5.2 后条件与前条件丢弃

**练习 `triple_hgc_post`**：前提中的三元组已经在后条件带一个 `\GC`，而新定义又隐式添加一个，因此实际求值后条件有两份垃圾。展开定义后，用 `hstar_assoc` 把两份 `\GC` 相邻，再合并。

```coq
(* 原书练习（3 星）：从后条件删去一个 \GC。 *)

Lemma triple_hgc_post : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. intros s Hs. applys eval_conseq M. { applys Hs. }
  intros v. simpl. rewrite hstar_assoc. rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.
```

**练习 `triple_haffine_post`**：若额外后条件是任意仿射 `H'`，先通过后果规则把 `H'` 改成 `\GC`，再调用上一规则。这样使用规则时不必一开始就知道具体垃圾是什么；最后只要能证明 `H' ==> \GC` 即可。

```coq
(* 原书练习（1 星）：任意仿射后条件都可先改写成 \GC 再丢弃。 *)

Lemma triple_haffine_post : forall t H H' Q,
  haffine H' ->
  triple t H (Q \*+ H') ->
  triple t H Q.
Proof using.
  introv A M. applys triple_hgc_post. applys triple_conseq M.
  { applys himpl_refl. }
  { intros v. simpl. applys himpl_frame_r. applys himpl_hgc_r A. }
Qed.
```

**练习 `triple_hgc_post_from_triple_haffine_post`**：反过来，`\GC` 自身仿射，所以一般的仿射后条件规则也立即可推出 `\GC` 版本。

```coq
(* 原书练习（1 星）：反向实例化 triple_haffine_post。 *)

Lemma triple_hgc_post_from_triple_haffine_post : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. applys triple_haffine_post M. applys haffine_hgc.
Qed.
```

**练习 `triple_haffine_pre`**：前条件中的 `H'` 不必另找一套语义论证。框架规则把它移到后条件，随后用 `triple_haffine_post` 丢弃。前、后两种丢弃规则因此可以互相衔接。

```coq
(* 原书练习（1 星）：框架规则把 H' 移到后条件，再将其丢弃。 *)

Lemma triple_haffine_pre : forall t H H' Q,
  haffine H' ->
  triple t H Q ->
  triple t (H \* H') Q.
Proof using.
  introv A M. applys triple_haffine_post A. applys triple_frame M.
Qed.
```

### 103.5.3 组合结构规则

**练习 `triple_conseq_frame_hgc`** 把后果、框架和丢弃合并：先框架，再用给定的前、后条件蕴含做后果变形，最后删掉新后条件中的 `\GC`。

```coq
(* 原书练习（2 星）：后果、框架与丢弃的组合规则。 *)

Lemma triple_conseq_frame_hgc : forall H2 H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* H2 ->
  Q1 \*+ H2 ===> Q \*+ \GC ->
  triple t H Q.
Proof using.
  introv M WH WQ. applys triple_hgc_post.
  applys triple_conseq WH WQ. applys triple_frame M.
Qed.
```

**练习 `triple_ramified_frame_hgc`** 用魔法杖后条件 `Q1 \--* (Q \*+ \GC)` 取代显式框架 `H2`。实例化上一条组合规则后，`qwand_equiv` 正好给出剩余的后条件蕴含。

```coq
(* 原书练习（1 星）：带丢弃能力的汇聚框架规则。 *)

Lemma triple_ramified_frame_hgc : forall H1 Q1 t H Q,
  triple t H1 Q1 ->
  H ==> H1 \* (Q1 \--* (Q \*+ \GC)) ->
  triple t H Q.
Proof using.
  introv M W. applys triple_conseq_frame_hgc (Q1 \--* (Q \*+ \GC)) M W.
  rewrite* <- qwand_equiv.
Qed.
```

---

## 103.6 WP 形式的三条规则

WP 的定义同步改成 `eval s t (Q \*+ \GC)`，所以 `wp_equiv` 仍是定义展开即可得到的等价。后果和框架证明与此前一致，只是每次都要携带附加垃圾。

```coq
(* ---------- 103.6 WP 形式的丢弃规则 ---------- *)

Definition wp (t:trm) (Q:val->hprop) : hprop :=
  fun s => eval s t (Q \*+ \GC).

Lemma wp_equiv : forall t H Q,
  (H ==> wp t Q) <-> (triple t H Q).
Proof using. iff M; introv Hs; applys M Hs. Qed.

Lemma wp_conseq : forall t Q1 Q2,
  Q1 ===> Q2 ->
  wp t Q1 ==> wp t Q2.
Proof using.
  unfold wp. introv M. intros s Hs. applys* eval_conseq. xsimpl*.
Qed.

Lemma wp_frame : forall t H Q,
  (wp t Q) \* H ==> wp t (Q \*+ H).
Proof using.
  intros. unfold wp. intros h HF.
  lets (h1&h2&M1&M2&MD&MU): hstar_inv (rm HF).
  subst. applys eval_conseq.
  { applys eval_frame M1 MD. }
  { xsimpl. intros h' ->. applys M2. }
Qed.
```

**练习 `wp_hgc_post`** 是 `triple_hgc_post` 的 WP 翻译，直接展开后仍然只需合并两份 `\GC`。

```coq
(* 原书练习（1 星）：WP 形式的后条件丢弃。 *)

Lemma wp_hgc_post : forall t Q,
  wp t (Q \*+ \GC) ==> wp t Q.
Proof using.
  intros. unfold wp. intros s Hs. applys eval_conseq Hs.
  intros v. simpl. rewrite hstar_assoc. rewrite hstar_hgc_hgc. applys himpl_refl.
Qed.
```

**练习 `wp_haffine_pre`** 分三步：用 `wp_frame` 把 `H` 放入后条件；用 `wp_conseq` 和 `himpl_hgc_r` 把 `H` 改成 `\GC`；最后应用 `wp_hgc_post`。显式写出中间公式，可以清楚看到每次传递的中点。

```coq
(* 原书练习（3 星）：先框架，再把 H 改成 \GC，最后使用后条件丢弃。 *)

Lemma wp_haffine_pre : forall t H Q,
  haffine H ->
  (wp t Q) \* H ==> wp t Q.
Proof using.
  introv A. applys himpl_trans (wp t (Q \*+ H)).
  { applys wp_frame. }
  applys himpl_trans (wp t (Q \*+ \GC)).
  { applys wp_conseq. intros v. simpl.
    applys himpl_frame_r. applys himpl_hgc_r A. }
  { applys wp_hgc_post. }
Qed.
```

**练习 `wp_ramified`** 是同一个思路的汇聚形式：先框架，魔法杖消去得到 `Q2 \*+ \GC`，再丢弃。`qwand_cancel` 正好完成中间的魔法杖消去。

```coq
(* 原书练习（3 星）：WP 的汇聚框架规则同时包含丢弃规则。 *)

Lemma wp_ramified : forall Q1 Q2 t,
  (wp t Q1) \* (Q1 \--* (Q2 \*+ \GC)) ==> (wp t Q2).
Proof using.
  intros. applys himpl_trans (wp t (Q2 \*+ \GC)).
  2:{ applys wp_hgc_post. }
  applys himpl_trans (wp t (Q1 \*+ (Q1 \--* (Q2 \*+ \GC)))).
  { applys wp_frame. }
  { applys wp_conseq. applys qwand_cancel. }
Qed.
```

---

## 103.7 让 `xwp` 自动预留 `\GC`

验证函数时，若直到证明末尾才想到要丢弃资源，就得回头修改整条证明。更实用的策略是：每次 `xwp` 开始时就把目标后条件扩成 `Q \*+ \GC`，让后续证明一直携带垃圾槽。

`xwp_lemma` 是生成器进入函数体所依赖的抽象接口；`xwp_lemma'` 先按旧接口证明带 `\GC` 的规格，再用 `triple_hgc_post` 去掉外层垃圾。新的 `xwp` 只改为调用这个加强版引理。

```coq
(* ---------- 103.7 把后条件丢弃集成进 xwp ---------- *)

Parameter xwp_lemma : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 Q ->
  triple (trm_app v1 v2) H Q.

Lemma xwp_lemma' : forall v1 v2 x t1 H Q,
  v1 = val_fun x t1 ->
  H ==> wpgen ((x,v2)::nil) t1 (Q \*+ \GC) ->
  triple (trm_app v1 v2) H Q.
Proof using. introv E M. applys triple_hgc_post. applys* xwp_lemma. Qed.

Tactic Notation "xwp" :=
  intros; applys xwp_lemma';
  [ reflexivity | simpl; unfold wpgen_var; simpl ].
```

回到开头例子，并假设当前实例中所有谓词均仿射。新版 `xwp` 已预留垃圾槽，所以最后的引用单元可直接用 `himpl_hgc_r` 吸收；后条件不再泄漏 `p`。

```coq
Module MotivatingExampleWithUpdatedXwp.
Export MotivatingExample.

Parameter haffine_hany : forall (H:hprop),
  haffine H.

Lemma triple_succ_using_incr' : forall (n:int),
  triple (succ_using_incr n)
    \[]
    (fun r => \[r = n+1]).
Proof using.
  xwp. xapp. intros r. xapp. xapp. xsimpl. { auto. }
  applys himpl_hgc_r. applys haffine_hany.
Qed.

End MotivatingExampleWithUpdatedXwp.
```

---

## 103.8 `mkstruct` 如何同时支持三种结构变形

第 101、102 章的 `mkstruct F Q` 通过存在量词和后条件魔法杖支持后果与框架。本章把魔法杖目标从 `Q` 改成 `Q \*+ \GC`，于是同一层结构还获得丢弃能力。

```coq
(* ---------- 103.8 支持丢弃的 mkstruct ---------- *)

Definition mkstruct (F:formula) : formula :=
  fun Q => \exists Q', F Q' \* (Q' \--* (Q \*+ \GC)).
```

`mkstruct_hgc` 的证明把目标中新增的 `\GC` 与定义固有的 `\GC` 合并。`set (X := hgc) at 3` 精确定位第三处出现，避免误改其他垃圾槽。其余四条原有性质仍然成立：擦除时向 `\GC` 提供空堆；后果、框架与单调性仍由同一个魔法杖传递。

```coq
Lemma mkstruct_hgc : forall Q F,
  mkstruct F (Q \*+ \GC) ==> mkstruct F Q.
Proof using.
  intros. unfold mkstruct. set (X := hgc) at 3. replace X with (\GC \* \GC).
  { xsimpl. } { subst X. apply hstar_hgc_hgc. }
Qed.

Lemma mkstruct_erase : forall F Q,
  F Q ==> mkstruct F Q.
Proof using.
  intros. unfold mkstruct. xsimpl Q. apply himpl_hgc_r. apply haffine_hempty.
Qed.

Lemma mkstruct_conseq : forall F Q1 Q2,
  Q1 ===> Q2 ->
  mkstruct F Q1 ==> mkstruct F Q2.
Proof using.
  introv WQ. unfold mkstruct. xpull. intros Q'. xsimpl Q'. xchange WQ.
Qed.

Lemma mkstruct_frame : forall F H Q,
  (mkstruct F Q) \* H ==> mkstruct F (Q \*+ H).
Proof using.
  intros. unfold mkstruct. xpull. intros Q'. xsimpl Q'.
Qed.

Lemma mkstruct_monotone : forall F1 F2 Q,
  (forall Q, F1 Q ==> F2 Q) ->
  mkstruct F1 Q ==> mkstruct F2 Q.
Proof using.
  introv WF. unfolds mkstruct. xpull. intros Q'. xchange WF. xsimpl Q'.
Qed.
```

**练习 `mkstruct_haffine_post`**：先用 `mkstruct_conseq` 把仿射的 `H` 改成 `\GC`，再调用 `mkstruct_hgc`。

```coq
(* 原书练习（2 星）：mkstruct 的后条件仿射丢弃。 *)

Lemma mkstruct_haffine_post : forall H Q F,
  haffine H ->
  mkstruct F (Q \*+ H) ==> mkstruct F Q.
Proof using.
  introv A. applys himpl_trans_r mkstruct_hgc.
  applys mkstruct_conseq. intros v. simpl.
  applys himpl_frame_r. applys himpl_hgc_r A.
Qed.
```

**练习 `mkstruct_haffine_pre`**：先用 `mkstruct_frame` 把前条件的 `H` 移到后条件，再应用上一练习。这与三元组、WP 中的前条件丢弃证明完全同构。

```coq
(* 原书练习（2 星）：mkstruct 的前条件仿射丢弃。 *)

Lemma mkstruct_haffine_pre : forall H Q F,
  haffine H ->
  (mkstruct F Q) \* H ==> mkstruct F Q.
Proof using.
  introv A. applys himpl_trans.
  { applys mkstruct_frame. }
  { applys mkstruct_haffine_post A. }
Qed.

End NewTriples.
```

---

## 103.9 自动化：`xaffine` 与三个 GC 战术

### 103.9.1 分解仿射性目标

`xaffine` 根据堆谓词的顶层构造反复应用 103.2 节的分配规则；遇到原子谓词时，使用 `haffine` 提示库和当前假设。演示中的三个合取分量分别由假设解决。

```coq
(* ---------- 103.9 xaffine、xsimpl 与三个 GC 战术 ---------- *)

Module Xaffine.

Create HintDb haffine.

Tactic Notation "xaffine" :=
  repeat match goal with |- haffine ?H =>
    match H with
    | (hempty) => apply haffine_hempty
    | (hpure _) => apply haffine_hpure
    | (hstar _ _) => apply haffine_hstar
    | (hexists _) => apply haffine_hexists
    | (hforall _) => apply haffine_hforall
    | (hgc) => apply haffine_hgc
    | _ => eauto with haffine
    end
  end.

Lemma xaffine_demo : forall H1 H2 H3,
  haffine H1 ->
  haffine H2 ->
  haffine H3 ->
  haffine (H1 \* H2 \* H3).
Proof using. introv K1 K2 K3. xaffine. Qed.

End Xaffine.
```

`xsimpl` 能消去两边共有的 `H2`，留下 `H1 ==> \GC`；本章再显式应用 `himpl_hgc_r`，用 `K1` 完成证明。这样没有借用参考库“任何谓词均仿射”的简化假设。

```coq
Module XsimplExtended.

Lemma xsimpl_xaffine_demo : forall H1 H2,
  haffine H1 ->
  H1 \* H2 ==> H2 \* \GC.
Proof using. introv K1. xsimpl. applys himpl_hgc_r K1. Qed.

End XsimplExtended.
```

### 103.9.2 `xgc`：丢弃指定前条件

`xgc_lemma` 把当前资源分解成“要丢弃的 `H1`”和“要保留的 `H2`”。保留部分继续证明原目标；丢弃部分先随 `mkstruct_frame` 进入后条件，再由 `mkstruct_hgc` 吸收。最后的 `Affine.himpl_hgc_r` 使用本章的定义，而不是参考库的同名引理。

```coq
Module XGC.
Import Xaffine NewTriples.

Lemma xgc_lemma: forall H1 H2 H F Q,
  H ==> H1 \* H2 ->
  haffine H1 ->
  H2 ==> mkstruct F Q ->
  H ==> mkstruct F Q.
Proof using.
  introv WH K M. xchange WH. xchange M.
  applys himpl_trans mkstruct_frame.
  applys himpl_trans_r mkstruct_hgc.
  applys mkstruct_conseq. xsimpl. applys Affine.himpl_hgc_r K.
Qed.
```

`xgc H` 把三个子目标分别交给 `xsimpl`、`xaffine` 和用户。`xsimpl` 推断剩余资源时可能交换合取顺序，所以演示最后用 `hstar_comm` 对齐假设 `M`。

```coq
Tactic Notation "xgc" constr(H) :=
  eapply (@xgc_lemma H); [ xsimpl | xaffine | ].

Lemma xgc_demo : forall H1 H2 H3 F Q,
  haffine H2 ->
  H1 \* H3 ==> mkstruct F Q ->
  (H1 \* H2 \* H3) ==> mkstruct F Q.
Proof using.
  introv K2 M. xgc H2. rewrite (hstar_comm H3 H1). applys M.
Qed.
```

### 103.9.3 `xgc_keep`：只保留指定资源

`xgc_keep H` 使用同一引理，但把参数 `H` 放到“保留部分”的位置，让 `xsimpl` 推断应丢弃的其余资源。演示中保留 `H2`，`xaffine` 自动证明 `H1 \* H3` 仿射。

```coq
Tactic Notation "xgc_keep" constr(H) :=
  eapply (@xgc_lemma _ H); [ xsimpl | xaffine | ].

Lemma xgc_keep_demo : forall H1 H2 H3 F Q,
  haffine H1 ->
  haffine H3 ->
  H2 ==> mkstruct F Q ->
  (H1 \* H2 \* H3) ==> mkstruct F Q.
Proof using. introv K1 K3 M. xgc_keep H2. applys M. Qed.
```

### 103.9.4 `xgc_post`：延迟到最终后条件再丢弃

`xgc_post` 不立即选择垃圾，只把目标从 `mkstruct F Q` 改成 `mkstruct F (Q \*+ \GC)`。之后可继续程序证明，最后让所有剩余仿射资源进入垃圾槽。

演示真正需要丢弃的是 `H2 \* H3`，所以前提分别给出它们的仿射性。这里明确写出 `himpl_hgc_r` 和 `xaffine`，使证明在一般的部分仿射实例中也成立。

```coq
Lemma xgc_post_lemma : forall H Q F,
  H ==> mkstruct F (Q \*+ \GC) ->
  H ==> mkstruct F Q.
Proof using. introv M. xchange M. applys mkstruct_hgc. Qed.

Tactic Notation "xgc_post" :=
  apply xgc_post_lemma.

Lemma xgc_post_demo : forall H1 H2 H3 F Q,
  haffine H2 ->
  haffine H3 ->
  H1 ==> mkstruct F (Q \*+ H2 \*+ H3) ->
  H1 ==> mkstruct F Q.
Proof using.
  introv K2 K3 M.
  xgc_post.
  xchange M. applys mkstruct_conseq.
  xsimpl. applys himpl_hgc_r. xaffine.
Qed.

End XGC.
```

三种战术对应三种使用时机：`xgc` 主动删一项，`xgc_keep` 主动删到只剩一项，`xgc_post` 则把丢弃推迟到末尾。它们都只是前面已证规则的用户界面，没有引入新的语义假设。

---

## 103.10 量词规则的谓词族形式

把“谓词族中每个成员都仿射”命名为 `haffine_post`，存在量词和可居住类型上的全称量词规则就能写得更整齐。证明与 103.2 节相同，只是前提的包装方式不同。

```coq
(* ---------- 103.10 量词规则的谓词族形式 ---------- *)

Module HaffineQuantifiers.

Definition haffine_post (A:Type) (J:A->hprop) : Prop :=
  forall x, haffine (J x).

Lemma haffine_hexists : forall A (J:A->hprop),
  haffine_post J ->
  haffine (hexists J).
Proof using. introv F1 (x&Hx). applys* F1. Qed.

Lemma haffine_hforall : forall A `{Inhab A} (J:A->hprop),
  haffine_post J ->
  haffine (hforall J).
Proof using.
  introv IA F1 Hx. lets N: hforall_inv Hx. applys* F1 (arbitrary (A:=A)).
Qed.

End HaffineQuantifiers.
```

---

## 103.11 反向推导：只有前条件丢弃规则也够吗

此前由后条件丢弃规则加框架规则推出了前条件丢弃。反过来也成立，但需要一个语义观察：`t` 与 `let x = t in x` 具有相同的三元组行为。

证明先作这种 eta 展开。执行完 `t` 后，结果暂存在 `x` 中；此时 `t` 留下的 `\GC` 位于下一段“返回变量 `x`”的前条件中，于是恰好可以使用 `triple_hgc_pre`。最后返回值本身不再产生额外资源。

这里把前条件丢弃和 eta 等价作为模块接口假设，是为了单独展示这一推导方向；它不替代 103.5 节已经在精化三元组下完成的证明。

```coq
(* ---------- 103.11 由前条件丢弃推导后条件丢弃 ---------- *)

Module FromPreToPostGC.

Parameter triple_hgc_pre : forall t H Q,
  triple t H Q ->
  triple t (H \* \GC) Q.

Parameter eta_same_triples : forall (t:trm) (x:var) H Q,
   triple t H Q <-> triple (trm_let x t x) H Q.

(* 把 t 改写成 let x = t in x，就能在两段求值之间使用前条件丢弃。 *)

Lemma triple_hgc_post_from_hgc_pre : forall t H Q,
  triple t H (Q \*+ \GC) ->
  triple t H Q.
Proof using.
  introv M. rewrite (eta_same_triples t "x"). applys triple_let.
  { applys M. }
  { intros v. simpl. applys triple_hgc_pre. applys triple_val. auto. }
Qed.

End FromPreToPostGC.

End Affine.
```

---

## 103.12 本章小结

本章的核心不是一条孤立的“删除内存”规则，而是一套相互一致的设计：

- `haffine H` 精确限定哪些资源可以丢弃；
- `\GC` 把所有可丢弃资源统一成一个便于推理的谓词；
- `triple` 与 `wp` 在求值后条件中内置 `\GC`，从源头支持垃圾；
- `hstar_hgc_hgc` 保证顺序执行、框架和后果变形不会累积无法处理的垃圾；
- `mkstruct` 把丢弃能力与后果、框架能力放在同一个结构层；
- `xgc`、`xgc_keep`、`xgc_post` 分别支持立即丢弃、保留式丢弃和延迟丢弃。

全仿射实例中 `\GC = htop`，全线性实例中 `\GC = \[]`。因此，同一套证明既能模拟垃圾回收语言，也能退化为严格的线性资源逻辑，还能在二者之间逐类选择资源策略。
