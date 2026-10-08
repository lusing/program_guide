# 第 29 章 自由模型与逻辑编程的代数

> 对书：EFT ch XI（§XI.1-11.3+11.7）。本章通道：C（`examples/29_freemodel/ex29_freemodel.v`）/
> L（`examples/29_freemodel/ex29_freemodel.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| 自由幺半群 | 词表 List Nat：乘=拼接、幺=空表；公理（结合+幺元）机器证 | C/L |
| 初始性存在 | `suml`/`andl`：到 nat-加与 bool-与两个具体幺半群的同态 | C/L |
| 初始性唯一 | 同态由生成元取值唯一决定（泛性质的机器面） | C/L |
| 必需性 | 长度函数穿过同态良定义；不同生成元的词不同（无额外等同） | C/L |

第 26/27/30 章从**算法侧**做了归结、Herbrand 定理与 SLD；这一章换
代数侧看同一件事：Horn 理论的**词项模型** IΦ 是初始对象（initial）
——到任何模型恰有一个同态。「初始」正是「最小 Herbrand 模型」的
范畴论名字，也是 Prolog 说明语义（最小不动点）的根基。EFT 第 XI 章
的独到之处：把逻辑编程放回**泛性质**的语言里讲。

## 一、自由模型：公理只逼出必需的元素

书 Thm XI.2.3 的主角是 universal Horn 理论的词项解释 IΦ——元素只
含公理**必需**的（信息序下最小）。机器面取最干净的现场：幺半群
公理（结合律+幺元律是 Horn 子句的化身）。自由模型=生成元的有限
表：

```coq
Definition wmul (u v : list nat) : list nat := u ++ v.

Lemma wmul_assoc : forall u v w, wmul (wmul u v) w = wmul u (wmul v w).
Proof. intros. unfold wmul. rewrite app_assoc. reflexivity. Qed.

Lemma wmul_ident : forall u, wmul [] u = u.
Proof. intros. unfold wmul. reflexivity. Qed.
```

两条公理的机器证明一行一条——拼接的结合律就是 `app_assoc`。与
22 章的对照是本章的核心张力：那边理论 Φ := {a≡b, f(a)≡b} 让商
结构**塌缩**成一个等价类（基方程吞并词）；这边公理只在「括号换
位、添删幺元」的意义下等同，**词的内容保留**——[1;2] 和 [2;1] 是
不同的元素。自由=无额外等同。

## 二、初始性：存在唯一同态

**存在侧**：从自由幺半群到任何幺半群都有同态。机器面做两个目标：

- (ℕ, +, 0)：同态是 `suml`（把表的元素全加起来）；
- (Bool, ∧, true)：同态是 `andl`（全与）。

```coq
Lemma suml_mul : forall u v, suml (wmul u v) = nat_mon (suml u) (suml v).
```

保乘=把「拼接」映成「加/与」——`fold_right` 对 `++` 的分配律，
表归纳直落。保幺=空表映到 0/true（`suml_one`）。

**唯一侧**：同态由生成元上的取值**唯一决定**：

```coq
Lemma mor_unique : forall h u,
    (forall a b, h (wmul a b) = nat_mon (h a) (h b)) ->
    h [] = 0 ->
    (forall a, h [a] = a) ->
    h u = suml u.
```

三条前提分别是保乘、保幺、生成元约定；结论：h 在一切词上等于
suml。归纳直落：h (a::u′) = h ([a]·u′) = h[a] + h[u′]（保乘）=
a + suml u′（归纳假设+生成元约定）。这正是泛性质（universal
property）：**Hom(自由模型, 任意模型) ≅ 生成元的像**——「自由」
的范畴论定义在机器上就是这一条引理。

**首版教训**（见坑位）：最初把唯一性写成「保乘+保幺 ⟹ h = suml」
——机器当场拒证（h [a] 可以是任意自然数！）。加上生成元约定后
才成立。泛性质从来都是「由生成元的映射**唯一扩张**」，不是「无
条件唯一」——数学内容和机器抓包完全对上。

## 三、必需性：最小模型的信息序

初始模型的元素都是「必需」的——没有多余元素可以被等同吞并。
机器面两个证词：**长度函数**穿过同态良定义（`suml_length`：映
1 再求和=长度——同态保长度说明词不被压缩）；**不同生成元的词不
同**（`suml [1] ≠ suml [2]`——自由模型里 [1] 和 [2] 是不同元素，
它们在具体模型里的像也不同）。

Prolog 的连接：对确定程序 P，最小 Herbrand 模型正是「只含必需
原子」的模型——支撑集语义（well-founded semantics）与稳定模型
语义都在这个「最小」上做文章。30 章做了 SLD 的回答集与最小模型
的一致性；本章把「最小」的代数本质（初始性=泛性质）补上。

## 四、与归结族各章的分工表

| 章 | 视角 | 本章关系 |
|---|---|---|
| 26 合一与归结 | 算法：归结反演 | 归结的完备性用 Herbrand 定理——本章的代数地基 |
| 27 Herbrand 与 SLD | 结构：基项论域 | Herbrand 结构=无函数方程情形的自由模型 |
| 28 归结完备性 | 证明论：反演 | 完备性的模型侧论证经自由模型 |
| 30 SLD 与 Prolog 语义 | 语义：最小不动点 | 最小不动点=初始性的不动点化 |
| **29（本章）** | **代数：泛性质** | 统一上四者的「最小模型」直觉 |

EFT XI 的其余部分——Herbrand 定理（XI.1，可满足性归约到命题实
例）、命题归结（XI.5）、FOL 归结（XI.6）、逻辑编程（XI.7）——与
26/27/30 章的机器面已有对应；本章补的是它们共有的**代数骨架**：
一切「最小模型」现象都是初始性。

## 坑位速记（本章实测）

- **首版唯一性少了生成元约定**：泛性质是「由生成元映射唯一扩张」
  而非「无条件唯一」——机器拒证 h [a] = h [a]（平凡环）暴露了
  缺假设；补 (forall a, h [a] = a) 后归纳直落。
- **Lean 的 = 与 && 优先级**：`a = b && c` 解析为 `(a = b) && c`
  （= 的绑定级 50 高于 && 的 35）——acc 引理的 RHS 忘括号让
  `Bool` 等式变成 `decide(...) && b`，rfl/native_decide 全乱；
  处方：布尔等式的 RHS 永远显式括号。
- **foldr 的累加器交换**：`foldr f (foldr f true v) u' =
  foldr f true u' && foldr f true v`（append 折叠的交换律）需要
  按表归纳+按 Bool 分案的自证引理——核心库不带；这是 andl_mul
  的唯一实质工作量。
- **Coq 的 andb_true_r/andb_assoc** 在 Stdlib.Bool（默认 Prelude
  不含）——Require Import Bool 后可用；或 lia 处理。
- **suml_length 的 omega**：fold_right 的 0/+ 形状对 omega 透明，
  但 Lean 侧要先把 map/foldr 的 cons 形规约出来再喂。

## 小结

自由模型把「最小 Herbrand 模型」从 Prolog 语境提升为泛性质：存在
唯一同态到任意模型。归结族四章的算法面在 26-30 章已实；本章给
它们共同的代数地基——初始对象。下一章进入本书最接地气的机器
模型：寄存器机——程序、停机、不可判定，一条链走完。

---

上一章：[28 归结完备性与 SAT 难例](docs/28-rescomp.md) · 下一章：[30 SLD 与 Prolog 语义](docs/30-sldprolog.md)
