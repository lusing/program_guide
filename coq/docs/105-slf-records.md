# 105. 记录分离逻辑：字段、关联列表与分配合约

对应示例：`../examples/105_slf_records.v`（rocq 9.1.1 + 项目内 SLF 库实测编译退出码 0）

取材 Software Foundations 卷六 *Separation Logic Foundations*（v1.0）的 *Records* 章。本章原书没有编号练习；原书中一处只展示证明开头的记录消去演示，在本章示例中已补成完整的 `Qed` 证明。全部证明均无 `Admitted`。

---

## 105.0 从连续内存块到记录

第 104 章已经说明，ML 风格对象通常存放在连续内存块中：地址 `p` 的头单元保存对象长度，真正的内容从 `p+1` 开始。记录与数组共用这一布局，区别在于记录字段由固定的自然数偏移命名，而不是由程序运行时计算的下标访问。

本章先独立给出实现记录所需的少量数组运行时机制。`hheader n p` 是保存整数 `n` 的头单元；`hrange L p` 则从 `p` 开始连续存放列表 `L`。与数组的 `hseg` 不同，`hrange` 直接以绝对地址递归，不再额外保存数组基址和相对下标。

```coq
(* 105 记录分离逻辑：字段表示、三层访问规格与记录分配 *)
(* 取材 Software Foundations 卷六 Separation Logic Foundations 的 Records 章。 *)

Set Implicit Arguments.
From SLF Require Import LibSepReference LibSepTLCbuffer.

Implicit Types P : Prop.
Implicit Types H : hprop.
Implicit Types Q : val->hprop.
Implicit Type p q : loc.
Implicit Type k : nat.
Implicit Type i : int.
Implicit Type n z : nat.
Implicit Type v : val.
Implicit Type L : list val.

(* ---------- 105.0 记录实现所需的连续内存块接口 ---------- *)

(* 本章只依赖第 104 章的少量运行时机制，在此独立给出，避免依赖原书章节文件。 *)

Definition hheader (n:int) (p:loc) : hprop :=
  p ~~> (val_int n).

Fixpoint hrange (L:list val) (p:loc) : hprop :=
  match L with
  | nil => \[]
  | x::L' => (p ~~> x) \* (hrange L' (p+1)%nat)
  end.
```

指针加法规格需要把整数偏移转换成自然数地址。`triple_ptr_add_nonneg` 是 `triple_ptr_add` 的常用特例：若偏移 `n` 非负，就可以直接返回地址 `p+abs n`。让 `math` 把 `loc` 当成算术透明类型后，非负性和地址等式都可自动处理。

```coq
Ltac is_additional_arith_type T ::=
  match T with
  | loc => constr:(true)
  end.

Lemma triple_ptr_add_nonneg : forall (p:loc) (n:int),
  n >= 0 ->
  triple (val_ptr_add p n)
    \[]
    (fun r => \[r = val_loc (p + abs n)%nat]).
Proof using.
  introv Hn. applys triple_conseq triple_ptr_add.
  { math. } { xsimpl. } { xsimpl. intros ? ->. fequal. math. }
Qed.
```

底层 `val_alloc` 的语义采用关系式接口。分配 `n` 个单元时，新堆片段 `sb` 是从某个非空地址 `p` 开始的连续映射，所有单元先填入 `val_uninit`，并且 `sb` 与旧堆 `sa` 不相交。`hrange_intro` 把这个有限的连续映射与分离逻辑谓词联系起来：空列表对应空堆；非空列表对应首单元与其余区间的分离合取。归纳步骤只需把 `S p` 与 `p+1` 两种地址写法统一。

```coq
Parameter val_alloc : val.

Parameter eval_alloc : forall (n:int) sa Q,
  n >= 0 ->
  (forall p sb,
    sb = Fmap.conseq (LibList.make (abs n) val_uninit) p ->
    p <> null ->
    Fmap.disjoint sa sb ->
    Q (val_loc p) (sb \u sa)) ->
  eval sa (val_alloc (val_int n)) Q.

Lemma hrange_intro : forall L p,
  (hrange L p) (Fmap.conseq L p).
Proof using.
  intros L. induction L as [|L']; intros; rew_listx.
  { applys hempty_intro. }
  { simpl. applys hstar_intro.
    { applys* hsingle_intro. }
    { replace (S p) with (p+1)%nat by math. applys IHL. }
    { applys Fmap.disjoint_single_conseq. left. math. } }
Qed.
```

由语义规则可推出三元组：空前条件分配一段全为 `val_uninit` 的连续区间，并保证返回地址非空。证明先应用 `eval_alloc`，再用 `hrange_intro` 解释新堆。提示数据库注册后，后面的 `xapp` 可以自动选择这条分配规格。

```coq
Lemma triple_alloc : forall (n:int),
  n >= 0 ->
  triple (val_alloc n)
    \[]
    (funloc p => hrange (LibList.make (abs n) val_uninit) p \* \[p <> null]).
Proof using.
  introv Hn Hsa. applys* eval_alloc. intros p sb Esb Hp D.
  lets ->: hempty_inv Hsa. applys hexists_intro p.
  rewrite hstar_hpure_l. split*. rewrite Fmap.union_empty_r.
  rewrite hstar_hpure_r. split*. subst sb. applys* hrange_intro.
Qed.

#[local] Hint Resolve triple_alloc : triple.
```

---

## 105.1 单个字段：隐藏布局算术

字段名 `k` 是从零开始的自然数偏移。记录基址为 `p` 时，第 `k` 个字段实际位于 `(p+1+k)%nat`。`hfield p k v` 把这一布局封装成 `p`.k ~~> v`，让程序证明只谈字段，不反复暴露指针运算。

谓词默认设为不透明：抽象规格的使用者不能绕过字段接口修改任意地址；后面的 `Realization` 模块在验证实现时再临时透明化它。

```coq
(* ---------- 105.1 单个记录字段的表示 ---------- *)

(* 字段名是从零开始的自然数偏移；字段谓词隐藏头单元之后的指针运算。 *)

Definition field : Type := nat.

Definition hfield (p:loc) (k:field) (v:val) : hprop :=
  (p+1+k)%nat ~~> v.

Global Opaque hfield.

Notation "p `. k '~~>' v" := (hfield p k v)
  (at level 32, k at level 0, no associativity,
   format "p `. k  '~~>'  v").
```

---

## 105.2 从字段列表到完整记录

### 105.2.1 关联列表与分离合取

一个字段条目是 `(field * val)`，一组字段就是该条目的列表。`hfields` 递归地把每个条目翻译成一个 `hfield`，再用分离合取连接。不同字段拥有不同单元，所以这里必须用 `\*`，不能用普通逻辑合取。

解析记号支持一至三个字段，并显式把初始化值转换为 `val`；打印记号省去强制转换，使目标更易读。这两组记号描述的是同一种关联列表。

```coq
(* ---------- 105.2 字段集合与记录表示 ---------- *)

Definition hrecord_field : Type := (field * val).
Definition hrecord_fields : Type := list hrecord_field.

Implicit Types kvs : hrecord_fields.

Fixpoint hfields (kvs:hrecord_fields) (p:loc) : hprop :=
  match kvs with
  | nil => \[]
  | (k,v)::kvs' => (p`.k ~~> v) \* (hfields kvs' p)
  end.

Notation "`{ k1 := v1 }" :=
  ((k1,(v1:val))::nil)
  (at level 0, k1 at level 0, only parsing).

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  ((k1,(v1:val))::(k2,(v2:val))::nil)
  (at level 0, k1, k2 at level 0, only parsing).

Notation "`{ k1 := v1 ; k2 := v2 ; k3 := v3 }" :=
  ((k1,(v1:val))::(k2,(v2:val))::(k3,(v3:val))::nil)
  (at level 0, k1, k2, k3 at level 0, only parsing).

Notation "`{ k1 := v1 }" :=
  ((k1,v1)::nil)
  (at level 0, k1 at level 0, only printing).

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  ((k1,v1)::(k2,v2)::nil)
  (at level 0, k1, k2 at level 0, only printing).

Notation "`{ k1 := v1 ; k2 := v2 ; k3 := v3 }" :=
  ((k1,v1)::(k2,v2)::(k3,v3)::nil)
  (at level 0, k1, k2, k3 at level 0, only printing).

Open Scope val_scope.
```

### 105.2.2 字段名不变量与 `hrecord`

仅有 `hfields` 还不足以描述合法记录：关联列表可能漏字段、重复字段或乱序。`maps_all_fields n kvs` 要求所有键的列表恰好是 `nat_seq 0 n`，即 `[0;1;...;n-1]`。完整记录 `hrecord kvs p` 同时存在地拥有：

1. 保存字段数 `n` 的头单元；
2. 关联列表描述的所有字段；
3. 字段名与 `n` 相符的纯事实。

这样，字段顺序、头单元长度和实际堆布局被同一个谓词约束。

```coq
(* maps_all_fields 要求键恰好依次为 0、1、……、n-1。 *)

Definition maps_all_fields (n:nat) (kvs:hrecord_fields) : Prop :=
  LibList.map fst kvs = nat_seq 0 n.

Definition hrecord (kvs:hrecord_fields) (p:loc) : hprop :=
  \exists n, hheader n p \* hfields kvs p \* \[maps_all_fields n kvs].

Notation "p '~~~>' kvs" := (hrecord kvs p)
  (at level 32).
```

### 105.2.3 消去存在的长度

`hrecord_elim` 把抽象记录展开为“可计算长度的头单元 + 字段列表”。证明核心是：若 `map fst kvs = nat_seq 0 n`，则 `n = length kvs`。对 `kvs` 和 `n` 同时归纳：空列表迫使 `n=0`；非空列表迫使 `n=S n'`，并把键序列的尾部交给归纳假设。

`LibListExec.length` 是适合在 Rocq 中计算的版本，通过 `LibListExec.length_eq` 与通常的逻辑长度互相转换。

```coq
Lemma hrecord_elim : forall p kvs,
  hrecord kvs p ==> hheader (LibListExec.length kvs) p \* hfields kvs p.
Proof using.
  intros. unfold hrecord. xpull. intros z Hz. xsimpl. xsimpl.
  rewrite LibListExec.length_eq. applys himpl_of_eq. fequal. gen Hz.
  unfold maps_all_fields. generalize 0%nat. gen z.
  induction kvs; intros; destruct z as [|z']; rew_listx in *; tryfalse.
  { math. } { inverts Hz. forwards*: IHkvs H1. math. }
Qed.
```

以可变链表节点为例，`head=0` 保存当前值，`tail=1` 保存后继指针。两字段记录的消去结果就是头单元加两个字段单元。原书在这里只展示化简后的形状；本章把该方向完整证明，便于直接检查抽象谓词与具体布局的对应关系。

```coq
Definition head : field := 0%nat.
Definition tail : field := 1%nat.

(* 原书此处仅给出演示框架；这里把完整的消去方向证明到底。 *)

Lemma demo_hrecord_elim : forall p x q,
    p ~~~> `{ head := x ; tail := q }
  ==> hheader 2 p \* (p`.head ~~> x) \* (p`.tail ~~> q).
Proof using. intros. xchange hrecord_elim. simpl. xsimpl*. Qed.
```

---

## 105.3 读取字段的三层规格

读取操作 `val_get_field k p` 写作 `p`.k`。字段名 `k` 是 Rocq 层的自然数，不是程序里的 `val`；因此 `val_get_field k` 本身是一个可应用于记录地址的程序值。

最内层是小足迹规格：只拥有一个字段，返回该字段的值，并保留字段所有权。它不要求知道记录的其他部分。

```coq
(* ---------- 105.3 读取字段的三层规格 ---------- *)

Declare Scope trm_scope_ext.

Parameter val_get_field : field -> val.

Notation "t1 '`.' k" :=
  (val_get_field k t1)
  (in custom trm at level 56, k at level 0, format "t1 '`.' k" )
  : trm_scope_ext.

Parameter triple_get_field : forall p k v,
  triple (val_get_field k p)
    (p`.k ~~> v)
    (fun r => \[r = v] \* (p`.k ~~> v)).
```

若拥有整个字段列表，则用 `hfields_lookup` 查找逻辑值。返回 `option val` 很关键：空列表或未命中都返回 `None`，只有 `Some v` 才允许读取。这样“字段存在”不是隐藏假设，而是规格前提。

```coq
Fixpoint hfields_lookup (k:field) (kvs:hrecord_fields) : option val :=
  match kvs with
  | nil => None
  | (ki,vi)::kvs' => if Nat.eq_dec k ki
                       then Some vi
                       else hfields_lookup k kvs'
  end.

Parameter triple_get_field_hfields : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hfields kvs p)
    (fun r => \[r = v] \* hfields kvs p).
```

最外层规格直接面向完整记录。头单元被读取操作保留，字段列表也不变；查找等式仍然决定返回值。后面会从单字段规格逐层推导出这两条大足迹规格，而不是把三条都当成彼此无关的公理。

```coq
Parameter triple_get_field_hrecord : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hrecord kvs p)
    (fun r => \[r = v] \* hrecord kvs p).
```

---

## 105.4 写入字段的三层规格

写入 `val_set_field k p v` 写作 `p`.k := v`。单字段规格允许旧值任意，写入后同一地址拥有新值。与读取不同，后条件不返回值约束，因为该操作返回单位值。

```coq
(* ---------- 105.4 写入字段的三层规格 ---------- *)

Parameter val_set_field : field -> val.

Notation "t1 '`.' k ':=' t2" :=
  (val_set_field k t1 t2)
  (in custom trm at level 56, k at level 0, format "t1 '`.' k  ':=' t2")
  : trm_scope_ext.

Parameter triple_set_field : forall v p k v',
  triple (val_set_field k p v)
    (p`.k ~~> v')
    (fun _ => p`.k ~~> v).
```

`hfields_update` 是逻辑列表上的写入。命中字段时，仅把当前条目的值替换为 `v`；未命中时递归处理尾部。若最终找不到字段，结果为 `None`，规格不可用。若成功，则结果 `Some kvs'` 同时充当新的后条件资源描述。

```coq
Fixpoint hfields_update (k:field) (v:val) (kvs:hrecord_fields)
                        : option hrecord_fields :=
  match kvs with
  | nil => None
  | (ki,vi)::kvs' => if Nat.eq_dec k ki
                       then Some ((k,v)::kvs')
                       else match hfields_update k v kvs' with
                            | None => None
                            | Some LR => Some ((ki,vi)::LR)
                            end
  end.

Parameter triple_set_field_hfields : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hfields kvs p)
    (fun _ => hfields kvs' p).

Parameter triple_set_field_hrecord : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hrecord kvs p)
    (fun _ => hrecord kvs' p).
```

---

## 105.5 带初始化器的分配规格

ML 记录通常在分配时就初始化所有字段。本章只处理二字段构造器，避免引入任意元数的元编程。`val_new_hrecord_2 k1 k2` 是接受两个初始值的程序值；`k1=0`、`k2=1` 保证字段名与 `maps_all_fields` 的布局不变量一致。

分配前不需要堆资源，返回地址 `p` 后拥有完整记录。`mcons` 将字段名固定为 `head` 和 `tail`，其规格只是通用构造器的直接实例。

```coq
(* ---------- 105.5 带初始化器的记录分配 ---------- *)

Parameter val_new_hrecord_2 : field -> field -> val.

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  (val_new_hrecord_2 k1 k2 v1 v2)
  (in custom trm at level 65,
   k1, k2 at level 0,
   v1, v2 at level 65).

Parameter triple_new_hrecord_2 : forall (k1 k2:field) (v1 v2:val),
  k1 = 0%nat ->
  k2 = 1%nat ->
  triple <{ `{ k1 := v1; k2 := v2 } }>
    \[]
    (funloc p => p ~~~> `{ k1 := v1 ; k2 := v2 }).

Definition mcons : val :=
  val_new_hrecord_2 head tail.

Lemma triple_mcons : forall (x q:val),
  triple (mcons x q)
    \[]
    (funloc p => p ~~~> `{ head := x ; tail := q }).
Proof using. intros. applys* triple_new_hrecord_2. Qed.
```

---

## 105.6 用指针运算实现字段访问

抽象接口已经足够验证记录使用者，但还需要证明它确实能由底层语言实现。`Realization` 模块把 `hfield` 透明化，并给 `math` 增加 `field` 类型支持。

读取字段先计算 `p+1`，再加字段偏移 `k`，最后调用普通的 `val_get`。大括号中的 `nat_to_Z k` 是 Rocq 层到程序语法的常量嵌入。证明执行两次指针加法后，把 `abs 1` 化简，并统一 `(p+1+k)%nat` 的不同写法，即可应用普通引用读取规格。

```coq
(* ---------- 105.6 用指针运算实现记录操作 ---------- *)

Module Realization.
Import ProgramSyntax.
Open Scope trm_scope_ext.

Global Transparent hfield.

#[local] Hint Extern 1 (_ >= _) => math : triple.

Ltac is_additional_arith_type T ::=
  match T with
  | loc => constr:(true)
  | field => constr:(true)
  end.

Definition val_get_field (k:field) : val :=
  <{ fun 'p =>
       let 'p1 = val_ptr_add 'p 1 in
       let 'q = val_ptr_add 'p1 {nat_to_Z k} in
       val_get 'q }>.

Notation "t1 '`.' f" :=
  (val_get_field f t1)
  (in custom trm at level 56, f at level 0, format "t1 '`.' f" ).

#[export] Hint Resolve triple_ptr_add_nonneg : triple.

Lemma triple_get_field : forall p k v,
  triple ((val_get_field k) p)
    (p`.k ~~> v)
    (fun r => \[r = v] \* (p`.k ~~> v)).
Proof using.
  unfold hfield. xwp. xapp. xapp. unfolds field.
  math_rewrite (p + abs 1 + k = p+1+k)%nat. xapp. xsimpl*.
Qed.
```

写入实现使用完全相同的地址计算，只是最后调用 `val_set`。因此单字段读写规格的正确性最终都归结为同一个布局等式和普通单元规格。

```coq
Definition val_set_field (k:field) : val :=
  <{ fun 'p 'v =>
       let 'p1 = val_ptr_add 'p 1 in
       let 'q = val_ptr_add 'p1 {nat_to_Z k} in
       val_set 'q 'v }>.

Lemma triple_set_field : forall v1 p k v2,
  triple ((val_set_field k) p v2)
    (p`.k ~~> v1)
    (fun _ => p`.k ~~> v2).
Proof using.
  unfold hfield. intros. xwp. xapp. xapp.
  unfolds field. math_rewrite (p + abs 1 + k = p+1+k)%nat. xapp. xsimpl.
Qed.

Notation "t1 '`.' f ':=' t2" :=
  (val_set_field f t1 t2)
  (in custom trm at level 56, f at level 0, format "t1 '`.' f  ':='  t2").
```

---

## 105.7 用框架规则提升为字段列表规格

### 105.7.1 读取

对字段列表归纳。若首字段就是要读取的 `k`，查找等式迫使返回值等于首字段值，直接应用单字段规格，并把尾部 `hfields L' p` 作为框架保留。若未命中，则对尾部应用归纳假设，把首字段作为框架保留。

两种分支都使用 `triple_conseq_frame`：它同时完成后果变形与框架添加。这里不需要重新展开堆布局，逻辑查找的递归结构与 `hfields` 的递归结构正好一致。

```coq
(* ---------- 105.7 从单字段规格推导字段列表规格 ---------- *)

Lemma triple_get_field_hfields : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hfields kvs p)
    (fun r => \[r = v] \* hfields kvs p).
Proof using.
  intros L. induction L as [| [ki vi] L']; simpl; introv E.
  { inverts E. }
  { case_if.
    { inverts E. subst ki. applys triple_conseq_frame.
      { applys triple_get_field. } { xsimpl. } { xsimpl*. } }
    { applys triple_conseq_frame.
      { applys IHL' E. }
      { xsimpl. }
      { xsimpl*. } } }
Qed.
```

### 105.7.2 写入

写入证明多一个尾部分支的 `match` 分析：只有递归更新返回 `Some`，原更新等式才可能成立。命中首字段时，新列表的首条目直接变成 `(k,v)`；递归成功时，新列表保留首条目，并替换尾部。框架规则分别保留未访问的尾部或首字段。

```coq
Lemma triple_set_field_hfields : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hfields kvs p)
    (fun _ => hfields kvs' p).
Proof using.
  intros kvs. induction kvs as [| [ki vi] kvs']; simpl; introv E.
  { inverts E. }
  { case_if.
    { inverts E. subst ki. applys triple_conseq_frame.
      { applys triple_set_field. } { xsimpl. } { xsimpl*. } }
    { cases (hfields_update k v kvs') as C2; tryfalse. inverts E.
      applys triple_conseq_frame. { applys IHkvs' C2. }
      { xsimpl. } { simpl. xsimpl*. } } }
Qed.
```

---

## 105.8 提升为完整记录规格

读取不改变字段列表，所以完整记录规格很直接：展开 `hrecord`，把头单元和纯事实留在框架中，对字段部分应用上一节的读取引理，最后重新折起记录。

```coq
(* ---------- 105.8 从字段列表规格推导完整记录规格 ---------- *)

Lemma triple_get_field_hrecord : forall kvs p k v,
  hfields_lookup k kvs = Some v ->
  triple (val_get_field k p)
    (hrecord kvs p)
    (fun r => \[r = v] \* hrecord kvs p).
Proof using.
  introv M. unfold hrecord. xtriple. xpull. intros z Hz.
  xapp (>> triple_get_field_hfields M). xsimpl*.
Qed.
```

写入则必须证明逻辑更新不会破坏字段名不变量。`hfields_update_preserves_fields` 对关联列表归纳，证明更新前后的 `map fst` 完全相等：命中时只改值，递归时保留首键并使用归纳假设。

由此，`maps_all_fields z kvs` 与 `maps_all_fields z kvs'` 作为命题相等。这里的 `extens` 使用命题外延性；真正提供等式内容的是上一条键列表保持引理。

```coq
Lemma hfields_update_preserves_fields : forall kvs kvs' k v,
  hfields_update k v kvs = Some kvs' ->
  LibList.map fst kvs' = LibList.map fst kvs.
Proof using.
  intros kvs. induction kvs as [|[ki vi] kvs1]; simpl; introv E.
  { introv _ H. inverts H. }
  { case_if.
    { inverts E. rew_listx*. subst. fequals. }
    { cases (hfields_update k v kvs1).
      { inverts E. rew_listx. fequals*. }
      { inverts E. } } }
Qed.

Lemma hfields_update_preserves_maps_all_fields : forall kvs kvs' z k v,
  hfields_update k v kvs = Some kvs' ->
  maps_all_fields z kvs = maps_all_fields z kvs'.
Proof using.
  introv M. unfold maps_all_fields. extens.
  rewrites* (>> hfields_update_preserves_fields M).
Qed.
```

最后展开记录、对字段部分执行写入，再用保持引理把更新后的键不变量改写回更新前的形式。头单元中的字段数无需改变，因为更新只修改值，不增删字段。

```coq
Lemma triple_set_field_hrecord : forall kvs kvs' k p v,
  hfields_update k v kvs = Some kvs' ->
  triple (val_set_field k p v)
    (hrecord kvs p)
    (fun _ => hrecord kvs' p).
Proof using.
  introv M. unfold hrecord. xtriple. xpull. intros z Hz.
  xapp (>> triple_set_field_hfields M). xsimpl.
  rewrites* <- (>> hfields_update_preserves_maps_all_fields z M).
Qed.
```

---

## 105.9 分配尚未初始化的记录

### 105.9.1 字段列表与连续区间相等

`val_alloc_hrecord ks` 分配 `length ks + 1` 个单元，把头单元设为字段数，再返回基址。此时所有字段仍是 `val_uninit`，稍后的初始化器会逐字段写入。

要把底层分配得到的 `hrange` 折成 `hfields`，需要一条布局等式：若 `kvs` 的键是从零开始的完整序列，且 `L` 恰好是所有值组成的列表，那么 `hfields kvs p = hrange L (p+1)`。

证明中的辅助命题把起点推广为任意 `o`。否则归纳假设只能处理从零开始的字段，无法用于尾部从 `o+1` 开始的列表。展开一个字段后，左址是 `p+1+o`，右址相应移动到 `p+1+(o+1)`；地址算术和 `nat_seq` 的递推共同完成归纳。

```coq
(* ---------- 105.9 分配尚未初始化的记录 ---------- *)

Definition val_alloc_hrecord (ks:list field) : val :=
  <{ fun 'v =>
       let 'm = {LibListExec.length ks} + 1 in
       let 'p = val_alloc 'm in
       val_set 'p {LibListExec.length ks};
       'p }>.

Lemma hfields_eq_hrange : forall z L p kvs,
  maps_all_fields z kvs ->
  z = length L ->
  L = LibList.map snd kvs ->
  hfields kvs p = hrange L (p+1)%nat.
Proof using.
  asserts Ind: (forall L p kvs o,
    LibList.map fst kvs = nat_seq o (length L) ->
    L = LibList.map snd kvs ->
    hfields kvs p = hrange L (p+1+o)%nat).
  { intros L. induction L as [|v L']; introv M E; rew_listx in *;
    destruct kvs as [|[k v'] kvs']; tryfalse; rew_listx in *.
    { auto. }
    { simpls. inverts M as M'. inverts E as E'. rew_listx in *.
      unfold hfield. fequals. math_rewrite (p+1+o+1=p+1+(o+1))%nat.
      applys* IHL'. math_rewrite* (o+1=S o)%nat. } }
  introv M HL E. subst z. rewrites (>> Ind M E). fequals. unfold loc. math.
Qed.
```

### 105.9.2 验证分配实现

`triple_alloc_hrecord` 的前提要求 `ks` 恰好是从零开始的字段名序列。证明先分配连续块，再写头单元。后条件中的头单元来自这次写入，其余连续单元通过 `hfields_eq_hrange` 转成字段列表。

还需构造两个纯事实：

- `maps_all_fields`：对字段数归纳，并使用 `ks = nat_seq 0 (length ks)`；
- 值列表等式：对 `ks` 归纳，证明 `map snd (map (fun k => (k,val_uninit)) ks)` 是长度相同的未初始化值列表。

这里交替使用 `LibListExec` 与 `LibList`：前者便于在程序语法中计算具体长度和列表，后者便于逻辑重写，两者由相应等式连接。

```coq
Lemma triple_alloc_hrecord : forall ks,
  ks = nat_seq 0 (LibListExec.length ks) ->
  triple ((val_alloc_hrecord ks) ())
    \[]
    (funloc p => hrecord (LibListExec.map (fun k => (k,val_uninit)) ks) p).
Proof using.
  introv Hks. xwp. xapp. xapp. intros p Hp. unfolds field.
  rewrite LibListExec.length_eq in *. set (n := length ks) in *.
  math_rewrite (abs (n + 1) = S n). rew_listx. simpl.
  xapp. xval. xsimpl*. unfold hrecord. autorewrite with rew_list_exec.
  asserts R: (maps_all_fields n (LibList.map (fun k => (k, val_uninit)) ks)).
  { unfolds. rewrite Hks. clears ks p. generalize 0%nat as o.
    induction n as [|n']; intros; simpl; rew_listx; fequals*. }
  xsimpl* n. xchange* <- (@hfields_eq_hrange n). { rew_listx*. }
  { unfold n. clears n p. induction ks as [|ks']; rew_listx; fequals*. }
Qed.

#[global] Hint Resolve triple_alloc_hrecord : triple.
```

对具体的 `head::tail::nil`，可计算长度与映射都会由 `simpl` 化到预期形状，因此列表节点分配规格只需调用通用引理。

```coq
Lemma triple_alloc_mcons :
  triple (val_alloc_hrecord (head::tail::nil) ())
    \[]
    (funloc p => p ~~~> `{ head := val_uninit ; tail := val_uninit }).
Proof using. applys* triple_alloc_hrecord. Qed.
```

---

## 105.10 分配并初始化二字段记录

二字段构造器先调用 `val_alloc_hrecord (k1::k2::nil)`，再依次写入两个字段，最后返回地址。其验证组合了本章两条完整记录写入规格和一条分配规格：

1. 分配得到两个值均为 `val_uninit` 的合法记录；
2. 第一次写入把字段 `k1` 的值改为 `x1`；
3. 第二次写入把字段 `k2` 的值改为 `x2`；
4. 键列表始终不变，所以头单元与布局不变量始终成立。

代入 `k1=0`、`k2=1` 后，两个 `hfields_update` 前提均可由 `reflexivity` 计算验证。

```coq
(* ---------- 105.10 分配并初始化二字段记录 ---------- *)

Definition val_new_hrecord_2 (k1:field) (k2:field) : val :=
  <{ fun 'x1 'x2 =>
       let 'p = {val_alloc_hrecord (k1::k2::nil)} () in
       'p`.k1 := 'x1;
       'p`.k2 := 'x2;
       'p }>.

Notation "`{ k1 := v1 ; k2 := v2 }" :=
  (val_new_hrecord_2 k1 k2 v1 v2)
  (in custom trm at level 65,
   k1, k2 at level 0,
   v1, v2 at level 65) : trm_scope_ext.

Lemma triple_new_hrecord_2 : forall k1 k2 v1 v2,
  k1 = 0%nat ->
  k2 = 1%nat ->
  triple <{ `{ k1 := v1; k2 := v2 } }>
    \[]
    (funloc p => p ~~~> `{ k1 := v1 ; k2 := v2 }).
Proof using.
  introv -> ->. xwp. xapp triple_alloc_hrecord. { reflexivity. }
  intros p. simpl.
  xapp triple_set_field_hrecord. { reflexivity. }
  xapp triple_set_field_hrecord. { reflexivity. }
  xval. xsimpl*.
Qed.

End Realization.
```

至此，抽象记录接口已经在具体堆模型上实现并验证：字段访问落实为指针加法和单元访问，记录分配落实为连续块分配、头单元写入和字段初始化。

---

## 105.11 扩展 `xapp` 自动处理记录访问

手工调用三层规格仍然繁琐。`xapp` 的记录扩展把完整记录读写规格转成 weakest-precondition 形状，使后续程序证明可以直接使用 `xsimpl` 搜索记录资源。

读取辅助引理的前提是：当前堆能分离出某个 `hrecord kvs p`，并且根据 `hfields_lookup k kvs` 的结果继续构造证明。若返回 `None`，得到 `False`，说明字段不存在；若返回 `Some v`，则得到“读取后的后条件魔杖到目标 `Q`”。`protect Q` 防止战术过早改写目标后条件。

证明在成功分支应用 `triple_get_field_hrecord` 和框架规则，再特化后条件魔杖；失败分支直接从假前提出发。

```coq
(* ---------- 105.11 扩展 xapp 自动处理记录访问 ---------- *)

Lemma xapp_get_field_lemma : forall H k p Q,
  H ==> \exists kvs, (hrecord kvs p) \*
     match hfields_lookup k kvs with
     | None => \[False]
     | Some v => ((fun r => \[r = v] \* hrecord kvs p) \--* protect Q) end ->
  H ==> wpgen_app (val_get_field k p) Q.
Proof using.
  introv N. xchange N. intros kvs. cases (hfields_lookup k kvs).
  { unfold wpgen_app. xsimpl.
    applys* triple_conseq_frame triple_get_field_hrecord.
    { xsimpl. }
    { xpull. intros r ->. xchange (qwand_specialize v).
      rewrite* hwand_hpure_l. } }
  { xpull. }
Qed.
```

写入辅助引理的结构相同，只是用 `hfields_update k v kvs` 决定字段是否存在，以及更新后的记录列表 `kvs'`。成功分支应用完整记录写入规格并特化魔杖；失败分支仍然由 `False` 排除。

```coq
Lemma xapp_set_field_lemma : forall H k p v Q,
  H ==> \exists kvs, (hrecord kvs p) \*
     match hfields_update k v kvs with
     | None => \[False]
     | Some kvs' => ((fun _ => hrecord kvs' p) \--* protect Q) end ->
  H ==> wpgen_app (val_set_field k p v) Q.
Proof using.
  introv N. xchange N. intros kvs. cases (hfields_update k v kvs).
  { unfold wpgen_app. xsimpl.
    applys* triple_conseq_frame triple_set_field_hrecord.
    { xsimpl. }
    { xpull. intros r. xchange (qwand_specialize r). } }
  { xpull. }
Qed.
```

最后的 Ltac 钩子依次尝试写入和读取辅助引理。`xsimpl` 负责找出记录资源，`simpl` 计算具体关联列表上的查找或更新，`xapp_simpl` 完成后条件化简。前面的章节之所以能用简短的 `xapp` 处理记录，正是依靠这一层规格变换与自动化。

```coq
Ltac xapp_nosubst_for_records tt ::=
  first [ applys xapp_set_field_lemma; xsimpl; simpl; xapp_simpl
        | applys xapp_get_field_lemma; xsimpl; simpl; xapp_simpl ].
```

---

## 105.12 本章证明与验收

本章覆盖原书的全部机制：

- 单字段谓词、字段关联列表与完整记录谓词；
- 字段读写的单字段、字段列表、完整记录三层规格；
- 二字段记录分配及 `mcons` 特例；
- 基于指针运算的字段访问实现；
- 基于连续块分配的未初始化记录与初始化记录实现；
- `hrecord_elim` 的完整消去证明，以及 `xapp` 的记录扩展。

原书 *Records* 章没有编号练习。示例中的每个 `Lemma` 均以 `Qed` 结束，没有 `Admitted`，也没有遗留调试命令。

```bash
./build.sh -File 105_slf_records.v
python3 tools/check_docs_coverage.py 105 --mutate
```
