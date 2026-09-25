# 23 元理论与证明工程

> 对应示例：`examples/23_metatheory.v`（编译验证通过）

前 22 章都在"做数学"，本章换一个视角：**做工程**。
公理追踪、定义展开、找引理、排查 typeclass 失败、scope 混淆、
编译开关 —— 这些决定了你能不能在一个 582 个文件的库里高效干活。

## 23.1 公理盘点：`Print Assumptions`

本库把 `Funext` 与 `Univalence` 做成"空类型 + 类型类"，
于是每条定理用到哪些公理都能被机器列出来。
这是 HoTT 库最重要的工程约定之一：**公理用量可审计**。

```coq
Print Assumptions concat_p1.
Print Assumptions transport_pp.
Print Assumptions isequiv_adjointify.
```

实测输出（`build/out/23.sec1`，以下同）：

```text
Closed under the global context
Closed under the global context
Closed under the global context
```

**"Closed under the global context"** = 纯构造，一个公理都不用。
路径代数（第 06 章）、等价的构造（第 07 章）全部如此 ——
这就是第 07 章说"伴随等价是无公理事实"的机器验证版。

往上一层：

```coq
Print Assumptions path_forall.
```

```text
Axioms:
isequiv_apD10 :
  Funext ->
  forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

函数外延的真名出现了：`isequiv_apD10 : Funext -> ...`。
也就是说 `Funext` 是一个 `Type0` 类型的公理常量，
而"函数外延性"是由它构造出来的 `IsEquiv apD10`。

再往上是泛等：

```coq
Print Assumptions path_universe.
Print Assumptions equiv_path_universe.
```

```text
Axioms:
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
Univalence : Type0
Axioms:
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
Univalence : Type0
```

而第 21 章的圆基本群计算**同时**用到两者，还牵出了更多间接依赖：

```coq
Print Assumptions equiv_loopCircle_int.
```

```text
Axioms:
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
isequiv_apD10 :
  Funext ->
  forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
gqglue :
  forall (A : Type) (R : A -> A -> Type) (a b : A), R a b -> gq a = gq b
Univalence_implies_Funext : Univalence -> Funext
Univalence : Type0
GraphQuotient_ind_beta_gqglue :
  forall (A : Type) (R : A -> A -> Type) (P : GraphQuotient R -> Type)
  (gq' : forall a : A, P (gq a))
  (gqglue' : forall (a b : A) (s : R a b),
             transport P (gqglue s) (gq' a) = gq' b)
  (a b : A) (s : R a b),
  apD (GraphQuotient_ind P gq' gqglue') (gqglue s) = gqglue' a b s
Funext : Type0
```

值得注意的有三条：

1. **`Univalence_implies_Funext : Univalence -> Funext`**：
   库里证明过"泛等蕴含函数外延"，所以用了泛等的地方自动会带上 `Funext`
   作为*公理性的*过渡；
2. **`gqglue` 是 HIT 构造子**：它出现在公理表里是因为
   `GraphQuotient` 的路径构造子在归纳规则上与公理同级（它不是公理，
   但 `Print Assumptions` 会把"不可计算的解释规则"一并报出）；
3. 这份清单**会随库版本变动**，移植证明时要重新核对。

## 23.2 看定义：`Print` 与 `About`

```coq
Print concat_p1.
Print transport.
```

`Print` 把定义直接摊开，能看到 `match` 的实际形状：

```text
concat_p1@{u} =
fun (A : Type) (x y : A) (p : x = y) =>
match p as p0 in _ = a return p0 @ 1 = p0 with
| 1 => 1
end
     : forall {A : Type} {x y : A} (p : x = y), p @ 1 = p
transport@{u u0} =
fun (A : Type) (P : A -> Type) (x y : A) (p : x = y) (u : P x) =>
match p in _ = a return P a with
| 1 => u
end
     : forall {A : Type} (P : A -> Type) {x y : A}, x = y -> P x -> P y
```

这两段是理解整条路径理论的钥匙：

- `concat_p1` 的 `match` 带 `return p0 @ 1 = p0` —— **目标出现在返回类型里**；
- `transport` 的 `match` 带 `return P a` —— 纤维随路径终点变化；
- 两者都只有一个分支 `| 1 => ...`，因为 `paths` 只有一个构造子。

```coq
Print IsEquiv.
Print Equiv.
Print hfiber.
Print IsTrunc_internal.
```

```text
Record IsEquiv@{u u0} (A B : Type) (f : A -> B) : Type := Build_IsEquiv
  { equiv_inv : B -> A;
    eisretr : f o equiv_inv == idmap;
    eissect : equiv_inv o f == idmap;
    eisadj : forall x : A, eisretr (f x) = ap f (eissect x) }.
Record Equiv@{u u0} (A B : Type) : Type := Build_Equiv
  { equiv_fun : A -> B;  equiv_isequiv : IsEquiv equiv_fun }.
hfiber@{u u0} =
fun (A B : Type) (f : A -> B) (y : B) => {x : A & f x = y}
     : forall {A B : Type}, (A -> B) -> B -> Type
Inductive IsTrunc_internal@{u} (A : Type) : trunc_index -> Type :=
    Build_Contr : forall center : A, (forall y : A, center = y) -> Contr A
  | istrunc_S : forall n : trunc_index,
                (forall x y : A, IsTrunc n (x = y)) -> IsTrunc n.+1 A.
```

这四个就是第 07、08、09 章反复引用的"源文件级真身"：
`IsEquiv` 的**四份数据**（伴随等价）、`Equiv` 的两层包装、
`hfiber` 就是 Σ、`IsTrunc_internal` 的两个构造子对应 `-2` 与 `.+1`。

`About` 会连记号 scope 与 `Arguments` 一起给出，
排查"为什么这个项被解析成了别的东西"时最有用：

```coq
About concat.
About equiv_inv.
```

```text
concat@{u} : forall {A : Type} {x y z : A}, x = y -> y = z -> x = z

concat is universe polymorphic
Arguments concat {A}%_type_scope {x y z} (p q)%_path_scope : simpl nomatch
The reduction tactics unfold concat but avoid exposing match constructs
concat is transparent
Expands to: Constant HoTT.Basics.Overture.concat
Declared in library HoTT.Basics.Overture, line 362, characters 11-17
equiv_inv@{u u0} : forall {A B : Type} {f : A -> B}, IsEquiv f -> B -> A

equiv_inv is universe polymorphic
equiv_inv is a primitive projection of IsEquiv
Arguments equiv_inv {A B}%_type_scope {f}%_function_scope {IsEquiv} _
equiv_inv is transparent
Expands to: Constant HoTT.Basics.Overture.equiv_inv
Declared in library HoTT.Basics.Overture, line 514, characters 2-11
```

两条最有用的信息：

- **`: simpl nomatch`** —— `concat` 与 `transport` 的化简策略是
  "化开但不要暴露 match"。这解释了为什么 `simpl` 有时"看起来什么都没做"：
  它在按约定避免展开匹配；
- **`Expands to: Constant HoTT.Basics.Overture.concat`** ——
  给出全限定名与源码行号，直接可 grep。

## 23.3 找引理：`Search` 的三条经验

**1) 用具体的单态类型缩小范围**，否则会刷出上百条：

```coq
Search (IsEquiv) (@inverse Bool true false).
```

**2) 找"形状"而不是"名字"**：

```coq
Search (transport _ _ _ = _ -> _ = _).
```

这条模式（transport 等式推出路径等式）一次刷出了整个 `moveR` / `moveL`
家族（第 05 章的移项术全部由它找回）。

**3) 找到候选后用 `Check` 确认参数顺序**（这是最常出错的地方）：

```coq
Check moveR_transport_p.
```

```text
moveR_transport_p
     : forall (P : ?A -> Type) (x y : ?A) (p : x = y)
       (u : P x) (v : P y), u = transport P p^ v -> transport P p u = v
where
?A : [ |- Type]
```

注意它与 `moveL_transport_p` 的方向差异（一个前提里是 `p^`、结论是 `p`，
另一个正好相反）—— 这类"对称孪生引理"靠 `Check` 区分，靠名字记是记不住的。

## 23.4 类型类搜索失败时的排查顺序

症状：`srapply` / `exact _` 报
**"Unable to satisfy the following constraints"**。
常见原因是截断层级实例没找到（`IsHSet`、`IsHProp`），
或者是 `Funext` / `Univalence` 没导入。

先检查某个实例能否被自动找到：

```coq
Definition can_find_hset_bool : IsHSet Bool := _.
Definition can_find_hprop_unit : IsHProp Unit := _.
Check can_find_hset_bool.
Check can_find_hprop_unit.
```

```text
can_find_hset_bool
     : IsHSet Bool
can_find_hprop_unit
     : IsHProp Unit
```

能通过就说明实例在库里；找不到时手动指定：

```coq
Check istrunc_leq.
```

```text
istrunc_leq
     : (?m <= ?n)%trunc -> forall A : Type, IsTrunc ?m A -> IsTrunc ?n A
where
?m : [ |- trunc_index]
?n : [ |- trunc_index]
```

`istrunc_leq` 是"抬层级"的通用工具：从弱性质推出强性质
（例如从 `IsTrunc 0 A` 得到 `IsHProp A`）。

## 23.5 记号与 scope 的排查

`Locate` 反查记号定义在哪里、属于哪个 scope：

```coq
Locate "@".
Locate "^".
Locate "1".
Locate "<~>".
Locate "==".
```

```text
Notation "p @ q" := (concat p q)
  (* p in scope path_scope, q in scope path_scope *) : path_scope
  (default interpretation) (from HoTT.Basics.Overture)
Notation "x ^" := (inv x) : mc_mult_scope
  (from HoTT.Classes.interfaces.canonical_names.MultiplicativeNotations)
Notation "p ^" := (inverse p) (* p in scope path_scope *) : path_scope
  (default interpretation) (from HoTT.Basics.Overture)
```

`Locate "1"` 的输出**最长** —— `1` 一共被绑定了 9 次：

```text
Notation "1" := dp_id : dpath_scope (from HoTT.Cubical.DPath)
Notation "1" := ds_id : dsquare_scope (from HoTT.Cubical.DPathSquare)
Notation "1" := equiv_idmap : equiv_scope (from HoTT.Basics.Equivalences)
Notation "1" := mon_unit : mc_mult_scope
  (from HoTT.Classes.interfaces.canonical_names.MultiplicativeNotations)
Notation "1" := canonical_names.one : mc_scope
  (from HoTT.Classes.interfaces.canonical_names.BinOpNotations)
Notation "1" := idpath : path_scope (default interpretation)
  (from HoTT.Basics.Overture)
Notation "1" := 1%pos : positive_scope (from HoTT.Spaces.Pos.Core)
Notation "1" := sq_id : square_scope (from HoTT.Cubical.PathSquare)
```

（还有 `- 1` 在 `mc_scope` 里与 `1` 相关。）
带 `(default interpretation)` 的那条是当前实际生效的 —— 这里是 `idpath`。

当一个项的类型和你预期不符时，八成是 scope 抢了记号。
用三个 `Check` 现场演示同一个 `1` 的三种身份：

```coq
Check (1 : true = true).
Check (1%nat : nat).
Check ((-2)%trunc : trunc_index).
```

```text
1 : true = true
     : true = true
1 : nat
     : nat
-2 : trunc_index
     : trunc_index
```

Coq 把 scope 键**回显**在打印里（`1 : nat`、`-2 : trunc_index`），
这本身就是排查工具 —— 打印结果里带了 `%nat` 之类的标记，
说明解析走了对应的 scope。

## 23.6 编译与验证的工程化设置

本教程所有示例都用同一条命令行编译：

```bash
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
```

其中：

| 开关 | 作用 |
|---|---|
| `-noinit` | **不加载 Stdlib 的 Prelude**（否则 `paths`、`sig` 等名字被标准库抢走） |
| `-indices-matter` | 让归纳类型的索引参与等价判断（HoTT 要求） |
| `-R ... HoTT` | 把库根映射成 `HoTT` 命名空间 |
| `-q` | 安静模式（必要的输出仍然会打印） |

**缺 `-noinit` 的典型症状**：`Check idpath` 报类型不符 ——
因为标准库的 `id` 类型占据了 `=` 记号。这是新手把
"HoTT 库 + 普通工程模板"混装时的第一坑。

另外两点工程事实：

- **示例文件名不能以数字开头**（Coq 模块名规则），
  所以 `run-all.sh` 把 `01_xxx.v` 复制成 `ex_01_xxx.v` 再编译；
- **模块名数字开头时 `coqc -o` 会报
  `Invalid character '0' at beginning of identifier`**，
  看到这条错不要怀疑库，先检查文件名。

## 23.7 本教程用到的公理总览

到目前为止的示例里，只有涉及 `Funext` / `Univalence` 的章节
（10、11、13、18、21、24）真正需要公理；
类型论基础、路径代数、等价、截断这些是公理无关的。

```coq
Print Assumptions concat_p1.
Print Assumptions isequiv_contr_map.
```

```text
Closed under the global context
Closed under the global context
```

`isequiv_contr_map`（可缩纤维给出等价，第 08 章的核心引理）也是纯构造的。
换言之，**HoTT 库的"无公理核心"覆盖了等价论的绝大部分** ——
公理只在把"等价"提升为"路径"（泛等）和比较函数（外延）时才登场。

## 本章坑位清单

1. **`Print Assumptions` 的输出会随库版本变动**，移植前先重跑。
2. **`Closed under the global context` 是"零公理"的说法**，不是报错。
3. **`Univalence_implies_Funext` 会让公理清单变长**：
   用了泛等的定理自动带上 `Funext`，不表示你多用了公理。
4. **HIT 的路径构造子（如 `gqglue`）会出现在公理表里**：
   它不是公理，是"不可计算的解释规则"被一并报出。
5. **`concat` / `transport` 的 `: simpl nomatch`**：
   `simpl` 会刻意避免暴露 match，"什么都没化开"未必是失败。
6. **`About` 的 `Expands to` 给出全限定名与源码行号**，grep 时直接用。
7. **`Search` 要配具体类型**，裸形状会刷出上百条。
8. **`Check lt` / `Check zero` / `Check hset_path2` 的"任意统一"**：
   typeclass 缺实例时 Rocq 挑最好匹配的，看到奇怪类型先给具体参数。
9. **`1` 被绑定了 9 次**，`Locate "1"` 是分辨它们的唯一可靠方法。
10. **`-noinit` 必须加**：不加则标准库抢走 `paths` / `sig` / `=` 记号。
11. **`-indices-matter` 是 HoTT 的要求**，不加会得到非预期的归纳消除规则。
12. **示例文件名不能以数字开头**：`coqc -o` 会报
    `Invalid character '0' at beginning of identifier`。
13. **`coqc -o` 对错误文件名的报错不指向根因**：
    看到"Invalid character"先查文件名，别查代码。

---

**上一章**：[22 自然数与整数](docs/22-numbers.md)
**下一章**：[24 综合实战 —— 圆上的螺旋覆叠](docs/24-capstone.md)
