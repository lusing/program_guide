# 31 · 归纳定义：`inductive`

对应示例：`../examples/T31_inductive.thy`

## 31.1 一句话概括

`datatype` 把"最小不动点"放进**类型**，`inductive` 把它放进**谓词**：
声明一组引入规则，Isabelle 造出满足它们的最小关系，并附送
`intros`（怎么造）、`cases`（怎么拆）、`induct`（怎么归纳）三件套。
闭包、求值关系、类型规则——所有"规则系统"都从这扇门进来。

## 31.2 为什么 fun 写不了

第 5 章 `fun` 的每个输入都要有输出且必须终止；而"从 x 沿 r 可达"
这种关系不是计算，是**满足规则的最小集合**：

```isabelle
inductive star :: "('a ⇒ 'a ⇒ bool) ⇒ 'a ⇒ 'a ⇒ bool" for r where
  refl [intro!]: "star r x x"
| step [intro!]: "star r x y ⟹ r y z ⟹ star r x z"
```

注意 `for r`——把参数 `r` 固定为定义的参数，规则里出现的是同一个 `r`。
不带 `for` 的话 `r` 是每条规则自己的全称变量，意思就全错了。

## 31.3 偶数：最小谓词

```isabelle
inductive ev :: "nat ⇒ bool" where
  ev0  [intro!]: "ev 0"
| evSS [intro!]: "ev n ⟹ ev (Suc (Suc n))"
```

定义立刻可用的事实：

```text
thm ev.intros
(* ev 0 ⟹ ev n ⟹ ev (Suc (Suc n))  （两条引入规则）*)
thm ev.cases
(* ev ?n ⟹ (n = 0 ⟹ P) ⟹ (⋀m. n = Suc (Suc m) ⟹ ev m ⟹ P) ⟹ P *)
thm ev.induct
(* ev ?n ⟹ P 0 ⟹ (⋀m. ev m ⟹ P m ⟹ P (Suc (Suc m))) ⟹ P ?n *)
```

`[intro!]` 的叹号：规则进 `auto` 的**无条件引入**集。挂普通 `[intro]`
则只在需要时用。实测 `lemma "ev 4" by auto` 一步过——`auto` 自己
把四层 `Suc (Suc _)` 拼出来了。

## 31.4 规则归纳

对"凡 ev 皆……"型命题，归纳原理是 `ev.induct`：

```isabelle
lemma ev_imp_dvd: "ev n ⟹ 2 dvd n"
  by (induct rule: ev.induct) auto
```

结构：`evSS` 那步送进来的归纳假设是 `ev m ⟹ 2 dvd m` 整条，
不是裸的 `2 dvd m`——归纳假设**带着谓词前提**，`auto` 用 `ev_simps`
类的事实拆掉。忘了这一点手写 `erule` 时会发现假设"不够用"。

泛化（`arbitrary:`）什么时候要：结论里出现**链上才有的中间变量**。
比如证 `star r x y ⟹ star r y z ⟹ star r x z` 时归纳沿 x→y 走，
z 是旁观者——它固定不动，不需要泛化；若命题是
"Ɐz. star r y z ⟶ star r x z"就要 `arbitrary: z`。

## 31.5 cases vs induct

- `cases`：拆分，无归纳假设。"拿到一个 ev 事实，它必然是这两条规则
  之一造的"——对 `ev (Suc 0)` 直接给出矛盾分支；
- `induct`：拆分 + 每条规则送归纳假设。

```isabelle
lemma "ev (Suc 0) ⟹ False"
  by (auto elim: ev.cases)
```

节奏：先 `cases` 探路；发现"要再走一步"的冲动时，换 `induct`。

## 31.6 组合已有谓词

定义体里**调用**别的谓词（如 `ev`）是合法的——`inductive` 定义出的
谓词自动单调，组合无需声明。普通函数出现在负位置（`¬ P x`）才会
触发 `Monotonicity check failed`；解法是证一条单调性引理再
`mono` 命令注册（进阶场景，教程用不上，记住门牌）。

```isabelle
inductive ev_pos :: "nat ⇒ bool" where
  [intro!]: "ev n ⟹ n ≠ 0 ⟹ ev_pos n"
```

## 31.7 坑位清单（实测）

1. **`o` 不能当变量名**——它是函数复合的 ASCII 语法。`ES o` 报
   `Inner syntax error` 且光标位置误导（第 34 章互斥定义同款坑）。
2. **忘写 `for r`**：参数变全称变量，定义通过但意思错，
   `star r x x` 证 `refl` 性质时突然要处理任意 r。
3. **`[intro!]` 滥用**：非安全规则挂 `!` 会让 `auto` 疯狂分裂目标；
   只有"无前提或前提可判定"的规则才配叹号。
4. **`.inducts` 不存在**：datatype/inductive 都只有 `.induct`，
   `.inducts` 是旧包遗物（实测 Undefined fact）。
5. **归纳假设带谓词前提**：手写 `erule` 版本时假设形状是
   `ev m ⟹ P m`，忘了带谓词会"证明卡在最后一步"。
6. **`inductive_set` vs 谓词版**：前者操作集合（`x ∈ S` 语法），
   后者操作 bool。证明里谓词版顺手，集合版在和 `image` 等集合
   工具打交道时省转换（`inductive_set` 自动两者都给）。
7. **命名**：不给规则命名时，`ev.intros` 里是匿名的
   `ev.n(0)` 风格编号，引用起来痛苦——规则都显式命名。
8. **mono 命令的参数是引理不是常量**：`mono foo` 要求 `foo` 是
   已证明的单调性定理；传常量名直接报错。
9. **负位置谓词直接被拒**：`"¬ P x ⟹ R x"` 这种定义体过不了
   单调性检查，报错信息里带 `monotonicity`。
10. **规则归纳不是结构归纳**：`induct rule: ev.induct` 沿**规则**
    走，不是沿 `Suc` 走。两者结论形状不同，混用时 `induct` 方法
    报 `Cannot match` 类错误。

## 31.8 与其他章的接口

- 第 6 章结构归纳：规则归纳是它的推广（归纳对象从数据变成规则）。
- 第 15 章良基：`star` 的归纳原理本质上就是沿关系走的良基归纳。
- 第 18 章 IMP 大步语义：`inductive` 的第一个工程级应用。
- 第 26 章 `codatatype`/`coinductive`：最大不动点那一半；
  共归纳谓词用 `coinductive` 命令，语法同款。
- 第 51 章不动点理论：`inductive` 的数学原型是 `lfp`，
  Knaster–Tarski 在 `complete_lattice` 上从零证给你看。
