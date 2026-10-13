# 23 公理纪律与证明工程

> 本章代码：[`examples/23_metatheory.v`](../examples/23_metatheory.v)

前 22 章在"做数学"。这一章换一个视角——**做工程**：怎样审计一条定理用了哪些公理，
怎样在一个几百个文件的库里找到需要的引理，怎样读懂一条定理的真实形状，
以及类型类搜索失败时从哪里查起。这些技能决定了你能不能把前面学的东西用到自己的证明里。

## 23.1 公理审计：`Print Assumptions`

HoTT 库把两条公理做成显式假设（第 02 章），于是**每条定理的公理用量都可以被机器列出来**。
这是本库最重要的工程约定，也是 HoTT 相对许多其他基础的一个实际优势。

三个层次：

```coq
Print Assumptions concat_p1.          (* Closed under the global context *)
Print Assumptions isequiv_adjointify. (* Closed under the global context *)
```

路径代数、等价论、纤维可缩 ⟺ 等价——全部零公理。HoTT 的"无公理核心"很大。

```coq
Print Assumptions path_forall.
```

```text
Axioms:
isequiv_apD10 : Funext -> forall A P (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

函数外延的真名是 `isequiv_apD10`；`Funext` 是它的载体。

```coq
Print Assumptions equiv_loopCircle_int.
```

```text
Axioms:
isequiv_equiv_path : Univalence -> forall A B, IsEquiv (equiv_path A B)
isequiv_apD10 : Funext -> ...
Univalence_implies_Funext : Univalence -> Funext
gqglue : ...
GraphQuotient_ind_beta_gqglue : ...
Univalence : Type0
Funext : Type0
```

读这份清单要知道三件事：

1. **`Univalence_implies_Funext`**：库证明了泛等蕴含函数外延，所以用了泛等的定理
   会自动带上 `Funext`。这不表示多用了一条公理。
2. **`gqglue`、`GraphQuotient_ind_beta_gqglue`**：这是 HIT 的路径构造子和计算规则。
   它们在数学上是构造性的归纳规则，不是逻辑公理；但 Coq 没有原生 HIT，
   库用 `Axiom` 模拟它们，所以 `Print Assumptions` 分不出来。
   判断方法：名字里带 `glue`、`beta`、`ind` 的通常是 HIT 规则。
3. **清单会随库版本变动**。移植证明时重新核对。

本教程各章结论的公理依赖见 README 的总表。规律很清楚：
**只有在把等价提升为路径（泛等）或比较函数（外延）时才需要公理。**

## 23.2 读懂定义：`Print` 与 `About`

`Print` 摊开定义体。对理解路径理论最有帮助的两段：

```coq
Print concat_p1.
(* fun A x y (p : x = y) => match p as p0 in _ = a return p0 @ 1 = p0 with 1 => 1 end *)

Print transport.
(* fun A P x y (p : x = y) (u : P x) => match p in _ = a return P a with 1 => u end *)
```

两者都是只有一个分支的 `match`——因为 `paths` 只有一个构造子。
`return` 子句里出现目标类型，这就是路径归纳在 Coq 里的实现方式。
看懂这两段，就看懂了第 04、05 章的全部。

`About` 给出定理的完整信息：隐式参数、作用域、化简策略、定义位置。

```coq
About concat.
(* Arguments concat {A} {x y z} (p q)%path_scope : simpl nomatch
   Expands to: Constant HoTT.Basics.Overture.concat
   Declared in library HoTT.Basics.Overture, line 362 *)
```

两条最有用的信息：

- `simpl nomatch`：`concat`、`transport` 等被标记为"化简时不要暴露 `match`"。
  这解释了为什么 `simpl` 对它们"什么都不做"——那是刻意的，防止目标变成一团 `match`。
  要化简它们，用专门的引理（`concat_p1`、`transport_pp`……）。
- `Declared in library ... line ...`：直接定位源码。

## 23.3 找引理：三条经验

**一、给具体类型缩小范围。** 裸的形状模式会刷出几百条：

```coq
Search (IsEquiv) (@inverse Bool true false).
```

**二、按形状找，不按名字找。** 名字记不住，形状忘不了：

```coq
Search (transport _ _ _ = _ -> _ = _).
```

这条一次找回整个 `moveR_transport_*` / `moveL_transport_*` 家族。

**三、找到候选后 `Check` 确认方向。** 库里大量引理成对出现、方向相反
（`concat_p_pp` / `concat_pp_p`、`moveR_*` / `moveL_*`、`transport_paths_l` / `_r`）。
名字只能提示，`Check` 才能确认。

```coq
Check moveR_transport_p.   (* u = transport P p^ v -> transport P p u = v *)
Check moveL_transport_p.   (* 方向相反 *)
```

## 23.4 类型类搜索失败时

症状：`srapply`、`exact _`、`refine` 报 `Unable to satisfy the following constraints`。

HoTT 库重度依赖类型类：`IsHSet`、`IsHProp`、`Contr`、`IsEquiv`、`Funext`、`Univalence`、
`IsPointed` 都是类型类。失败的常见原因按频率排：

1. **公理没导入**。`Funext` / `Univalence` 的实例要从 `HoTT.Axioms.*` 导入，或用 `Context`。
2. **截断实例找不到**。先单独测试：

   ```coq
   Definition can_find : IsHSet Bool := _.   (* 能过就说明实例在库里 *)
   ```

   找不到时手动给，或用 `istrunc_leq` 从已知层级抬上去。
3. **目标形状不对**。比如 `Trunc_rec` 要求目标是 n-型，目标不是时它就卡在约束上。
   这时问题不在类型类，在证明策略。

## 23.5 记号排查：`Locate`

遇到不认识的符号，或者一个项的类型出乎意料，八成是作用域问题。`Locate` 反查：

```coq
Locate "@".    (* concat，path_scope *)
Locate "^".    (* inverse，path_scope；另有 mc_mult_scope 的群逆 *)
Locate "1".    (* 绑定了 9 次！idpath / equiv_idmap / mon_unit / ... *)
```

带 `(default interpretation)` 的那条是当前生效的。

Coq 会在打印里回显作用域键——看到 `0%nat`、`(-2)%trunc`，就知道解析走了哪条路。
这本身就是排查工具。

另一类现象：类型类**缺信息时的任意统一**。单独 `Check hset_path2` 会看到 `?x : ordinal_carrier ?o`，
单独 `Check zero` 看到 `?R : CRing`。那是 Coq 在缺少约束时随便挑了一个匹配的实例。
给具体类型参数就恢复正常。这不是 bug，但第一次见会吓一跳。

## 23.6 零公理核心的范围

把本教程的结论按公理分组：

| 零公理 | 需要 `Funext` | 需要 `Univalence` |
|---|---|---|
| 路径群胚律（06） | 函数相等（10） | `Type` 不是集合（11） |
| transport 全部性质（05） | Π 类型的截断层级（09） | 结构搬运（18） |
| 伴随等价、`equiv_adjointify`（07） | `IsEquiv`、`IsHProp` 是命题（07、09） | 圆的覆叠、`loop ≠ 1`（13、24） |
| 纤维可缩 ⟺ 等价（08） | HIT 的泛性质（19、21） | π₁(S¹) = ℤ（13、21） |
| 乘积、Σ、和的路径刻画（14） | | 范畴的单叶性（20） |
| 截断层级的基本推理（09） | | |
| HIT 的消去子与计算规则（12、13、16、19） | | |

一个值得记住的事实：**等价论的几乎全部内容是零公理的**。
公理只在两个地方进场：把等价提升为 `Type` 里的路径，以及比较两个函数。

## 23.7 几条工程习惯

- **写定理时先决定公理立场**。库代码用 `Context `{Funext}`，让使用者选择；
  应用代码直接导入。
- **路径证明先写类型再写 tactic**。把每一步的路径类型写在注释里，方向错误会立刻暴露。
- **HIT 的 `_beta_` 规则用 `rewrite`**，`simpl` 不会动它们。
- **`path_universe` 用 `_path_universe` 系列引理化开**，别指望计算。
- **遇到对称孪生引理，`Check` 而不是猜。**

## 小结

- `Print Assumptions` 列出公理依赖；`Closed under the global context` 是零公理。
  `Univalence_implies_Funext` 和 HIT 规则会出现在清单里，要会读。
- `Print` 看定义体，`About` 看隐式参数、化简策略、源码位置。
- 找引理：给具体类型、按形状搜、`Check` 确认方向。
- 类型类失败：先查公理导入，再查截断实例，再查目标形状。
- `Locate` 排查作用域；类型类缺信息时会任意统一，给具体参数即可。

## 常见误区

1. **把 HIT 规则当成逻辑公理**。`gqglue` 等是构造性规则，Coq 只是用 `Axiom` 模拟。
2. **以为 `simpl` 不动 `transport` 是失败**。那是 `simpl nomatch` 的设计，用引理化简。
3. **靠名字猜引理方向**。成对出现的引理一定要 `Check`。
4. **把 `?x : ordinal_carrier ?o` 当成类型错误**。那是缺约束时的任意统一。

## 练习

1. 对第 13 章的 `loop_nontrivial` 和第 24 章的 `loop_nontrivial_via_negb` 做 `Print Assumptions`，
   比较两份清单，解释差异。
2. 用 `Search` 找出所有形如 `transport (fun x => _ = _) _ _ = _` 的引理，
   和第 05 章的表对一遍。
3. 思考：如果库把 `Funext` 做成全局 `Axiom` 而不是类型类，`Print Assumptions` 还能区分
   "用了函数外延"和"没用"吗？这对库的设计意味着什么？

---

**上一章**：[22 自然数与整数](22-numbers.md)
**下一章**：[24 综合实战：圆上的螺旋覆叠](24-capstone.md)
