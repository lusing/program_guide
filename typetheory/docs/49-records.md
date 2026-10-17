# 49 依赖记录与模块：从标签元组到栈的实现

> 对应读本：罗朝晖书 2.5.3 节 3（依赖性记录类型）+ 5.2.3
> （程序的模块化开发及验证）。代码：
> `examples/49_records/ex49_records.v`（记录的选择/限制运算、
> **栈/数组双规范 + 细化映射 ρ（书图 5.4）+ 定理
> array_impl_stack 完整机器证明——书中 Admitted 的真证明版**、
> funArray 实现上栈操作的运行面 0→7→9→7→0）。

Σ 类型（19、30 章）是「无标签的多元组」——访问靠 π₁/π₂
层叠。本章给多元组**装上标签**：依赖性记录类型（dependent
record type），然后看它最漂亮的应用——**程序模块的规范与
细化**（specification & refinement）：栈的规范如何被数组的
规范「实现」，而这整个推理在类型论里是一个可证明的命题。

## 49.1 依赖记录类型：带标签的 Σ（书 2.5.3 节 3）

记录类型的文法极小：

> R ::= ⟨⟩ | (R, l : A)　　r ::= ⟨⟩ | (r, l = a : A)

带两个运算：**选择** r.l（取标签 l 的分量）与**限制**
[r⁻]（去掉最后一个字段）。判断形式新增两种：`⊢ R rtype`
（R 是记录类型）与 `⊢ R rtype [L]`（且顶级标签都属于有穷集
L）。形成/引入/消去/计算四组规则（书图 2.3）与 Σ 的四组
规则逐条平行——唯一的差别是标签。但这个「唯一的差别」有
实质后果：

**后果一：标签是类型的一部分**。书里明确：l ≠ l′ 时
`⟨l:Nat⟩ ≠ ⟨l′:Nat⟩`——不同标签即不同类型。机器件：

```coq
Record TagA := mkTagA { ta : nat }.
Record TagB := mkTagB { tb : nat }.
Definition demoA (x : TagA) : nat := ta x.
Fail Definition demoB (x : TagA) : nat := tb x.   (* 标签不互通 *)
```

**后果二：结构性子类型可以全组合谐**。书表 2.1 对比 Σ 与
记录的三种结构子类型：

| | Σ 类型 | 记录类型 |
|---|---|---|
| 左投射 | Σx:A.B ≤π1 A | ⟨R, l:A⟩ ≤[⁻] R（限制运算） |
| 右投射 | Σ ≤π2 B(a) | ⟨R,l:A⟩ ≤Snd ⟨l:A([r⁻])⟩ |
| 组成部分 | dΣ 逐分量 | d_R 逐字段 |

48 章说过 Σ 的 π1/π2/dΣ **不能同时**作强制（π1、π2 同
注册即不合谐）。记录的 [⁻]、Snd、d_R **却可以同时用**——
它们在一起合谐。这是记录类型「用起来更恰当」的技术根据，
也是 Coq 把 Record 做成语言原语的类型论理由（Coq 的记录
字段 `:>` 直接注册投影强制——48 章 Man 例的机制）。

## 49.2 模块规范 = 结构类型 + 性质谓词（书 5.2.3）

类型论不仅是逻辑语言，还是**函数式程序语言**（书 5.2.2）。
程序验证的两个世界（34–35 章见过）在这里合成一体的方法：
一个模块的**规范**（specification）是序对

> Spec = (Str[·], φ[·])　——Str 是**结构类型**（依赖记录/
> Σ：模块有哪些操作、各是什么类型），φ 是**性质谓词**
> （操作该满足的公理）

**栈的规范**（书例 5.1）——结构类型是六字段记录：

```coq
Record StrStack := mkStrStack
  { Stack : Type;
    SEq    : Stack -> Stack -> Prop;   (* 栈的等同标准 *)
    empty  : Stack;
    push   : nat -> Stack -> Stack;
    pop    : Stack -> Stack;
    top    : Stack -> nat }.
```

注意 SEq 字段——栈自己声明**怎么算两个栈相等**。φ[Stack]
（性质谓词）包括：top(push n s) = n、pop(push n s) ≈ s、
top(empty) = 0、pop(empty) ≈ empty。

**数组的规范**同理：Array/newarray/assign/access 四字段，
φ[Array]：新数组全零、赋值律（写的位置读新值、不写的位置
不变）。

## 49.3 细化映射 ρ：数组实现栈（书图 5.4）

**细化（refinement）**：规范 B 细化规范 A，当存在映射
ρ : Str[B] → Str[A] 保持性质（φ_B(y) ⟹ φ_A(ρ(y))）。栈的
数组实现——每个栈 = 数组 arr + 指针 ptr 的序对：

> SEq s s′ := ptr 相等 ∧ ∀i < ptr. 两数组 access 相等
> （**弱等同**：只看指针以下的存储）
> empty = (newarray, 0)　push n s = (assign n arr ptr, ptr+1)
> pop s = (arr s, ptr − 1)　top s = match ptr with
> 0 → 0 | S k → access arr k

机器件直译（`rho`），然后是本章旗舰——书里 `Admitted` 的
定理，这里给完整证明：

```coq
Theorem array_impl_stack :
  forall A : StrArray, phiArray A -> phiStack (rho A).
Proof.
  intros A [Hnew Hassign].
  unfold phiStack; simpl; split; [| split; [| split]].
  - (* top (push n s) = n：指针走 S 分支，读到写进的新值 *)
    intros n [arr ptr]. simpl.
    assert (Hw : access A (assign A n arr ptr) ptr = n)
      by (apply (proj1 (Hassign ptr ptr n arr)); reflexivity).
    destruct ptr as [| k]; simpl; exact Hw.
  - (* pop (push n s) ≈ s：指针 pred(S ptr) = ptr；
       指针以下 i < ptr ≠ ptr，assign 不动这些位置 *)
    intros n [arr ptr]. simpl. split.
    + f_equal. lia.
    + intros i Hi. destruct (Hassign ptr i n arr) as [_ Hne].
      apply Hne. lia.
  - reflexivity.
  - split. + reflexivity.
    + intros i Hi. simpl in Hi. lia.
Qed.
```

四条性质的证明结构值得读：**top∘push** 用赋值律的 i=j 方向
（写在 ptr 读在 ptr）；**pop∘push ≈ id** 用 i≠j 方向（指针
以下的位置 assign 不碰）——φ[Array] 的两条赋值律恰好被
φ[Stack] 的两条性质分别吃掉；**empty** 两条是平凡情形
（nat 截断减 pred 0 = 0 由转换规则自动处理）。

**为什么 SEq 必须是弱等同**（本章最深的坑）：若把 SEq 取
成 Leibniz 相等，pop(push n s) ≈ s 就是**假**的——assign
恰在指针处改写了数组，`(assign …, ptr)` 与 `(arr, ptr)`
不是同一个序对。弱等同只看「指针以下」，assign 写的位置
恰在指针**上**——这就是数据结构教科书里「抽象相等」的
类型论化身。34 章 rev·rev 一题三文化里 setoid 派的
「相等自己定义」在此有了工程用武之地。

## 49.4 运行面：规范不是纸面文章

细化映射是**可执行的**。给一个具体数组实现（函数式数组
`nat -> nat`）：

```coq
Definition funArray : StrArray :=
  mkStrArray (nat -> nat)
    (fun _ => 0)                                    (* newarray *)
    (fun n a i => fun j => if Nat.eqb j i then n else a j)
    (fun a i => a i).                               (* access  *)
```

`rho funArray` 就是一台能跑的栈：

```coq
Compute (top theStack s0).    (* = 0 *)
Compute (top theStack s1).    (* = 7  (push 7) *)
Compute (top theStack s2).    (* = 9  (push 9) *)
Compute (top theStack (pop theStack s2)).   (* = 7：弹出恢复 *)
```

**同一件东西既是证明义务又是程序**——φ[Stack] 被
array_impl_stack 证明，同时 ρ(funArray) 的操作被 Compute
执行。「类型论 = 逻辑 + 程序设计」在模块层面兑现。

## 49.5 一页总结（本章的三个公式）

> 依赖记录 = 带标签的 Σ：选择/限制两运算，标签属于类型；
> [⁻]/Snd/d_R 三强制**合谐**——记录优于 Σ 的类型论根据。
> 模块规范 = (结构类型, 性质谓词)；细化 ρ 保性质——
> array_impl_stack 完整机器证明（书 Admitted 处）。
> 栈的等同标准是弱等同（指针以下存储相等）——assign 恰写
> 在指针上，Leibniz 版定理为假。

> **坑位速记**
> ① SEq 千万别取 Leibniz——pop∘push = id 立刻变假（assign
>   在指针处改数组）；「抽象相等」要按模块的抽象边界定义；
> ② `Hassign : … /\ (i <> j -> …)` 里是**蕴涵**——destruct
>   出来的是函数不是等式，要 `proj1 (Hassign ptr ptr n arr)
>   (eq_refl ptr)` 连证据一起喂；
> ③ Coq 裸环境没有 `string`/`%pair` 记号——记法糖要么
>   Require（String/Arith/Lia 按需），要么绕开；
> ④ `contradiction` 不认「对称后矛盾」（E : j = i 对
>   Hij : i <> j）——`congruence` 或 `lia` 才行；
> ⑤ sed 批量删 `%pair` 会把配对的右括号一起吃掉——
>   逐处核对括号平衡（本批三行连环缺括号实测）；
> ⑥ 函数式数组的 assign 返回的是**函数**（写一点的新数组），
>   `if` 在**读取时**才判位置——类型 `nat -> (nat->nat) ->
>   nat -> (nat->nat)` 别写岔。

## 49.6 与本书其他线的接口

- 19/30 章 Σ 类型——记录是带标签版；30 章自造 Σ 的四组
  规则与图 2.3 逐条平行；
- 34 章 rev·rev 一题三文化——setoid 派「相等自己定义」的
  工程版（本章 SEq）；
- 36 章 NB 操作语义（归纳关系）vs 本章（记录 + 谓词）——
  命令式验证的「间接形式化」与模块验证的「直接形式化」
  （书 5.4 后记的对照）；
- 48 章投影强制（记录字段 `:>`）——本章 ρ 的 SEq/push/pop
  都是普通字段，强制的身影在 50–54 章语义学里加重；
- 43 章存在包（∃）——模块规范是「存在版」的亲戚：规范的
  实现细节（数组+指针）被封装在 ρ 之后，客户端只见
  Str[Stack]。

## 49.7 章末地图（书 2.5.3 + 5.2 要点选）

- **书图 2.3**（记录四组规则）——与附录 B.2 的 Σ 规则
  并排对读；
- **书表 2.1**（三结构子类型）——Σ 不合谐 vs 记录合谐的
  完整对照；
- **书例 5.1**（栈/数组/细化）——UTT 原文 [125] 第 8 章
  在 Lego 里的原实现；Coq 版此处为完整证明；
- **5.2.1/5.2.2**（命令式 while 验证、函数式 isort 验证）
  ——36 章（NB）与 34 章（rev）已各自覆盖同款技术，此处
  不重开；
- **5.4 后记**（直接 vs 间接形式化）——与 53 章（HoTT 的
  HIT 直接形式化 vs setoid 间接形式化）对读。

---

上一章：[48 强制性子类型](48-coercive.md) · 下一章：[50 MTT 语义学](50-mttsem.md)
