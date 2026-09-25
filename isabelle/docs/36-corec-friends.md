# 36 · corec 进阶：友元与混合递归

对应示例：`../examples/T36_corec_friends.thy`（IsaTutLib 会话，父堆 HOL-Library）

## 36.1 一句话概括

`corec` 比 `primcorec` 多三档火力：`if` 守卫下的递归、
**友元**（friend）函数参数里的递归、以及 `corecursive` 的裸递归
（代价是手证终止性）。本章在自定义 `llist` 与库 `stream` 上三档全开，
含官方 `LFilter` 的终止性证明全文与斐波那契流的友元定义。

## 36.2 会话与导入

`corec` / `friend_of_corec` 注册在 `HOL-Library.BNF_Corec`，
**不在 Main**（实测裸 HOL 里报 outer syntax error）。本理论因此
属于 `IsaTutLib` 会话（`examples/ROOT` 第二个会话，父堆
`HOL-Library`）——这是教程里第一个不在主会话的理论。

## 36.3 primcorec 不吃构造子模式

实测：`primcorec lmap where "lmap f LNil = LNil" | ...` 报

```text
*** Non-variable function argument on left-hand side "LNil"
```

现代 primcorec 只认选择子/判别式方程。双构造子共数据类型
（有 LNil 的）用 `corec` + `case` 折：

```isabelle
corec lmap :: "('a ⇒ 'b) ⇒ 'a llist ⇒ 'b llist" where
  "lmap f xs = (case xs of LNil ⇒ LNil | LCons y ys ⇒ LCons (f y) (lmap f ys))"
```

守卫递归（第一档）：`upto i = (if i = 0 then LNil else LCons i (upto (i - 1)))`。

## 36.4 友元：官方 stream 上免证明，自定义类型上要补

官方 `Corec_Examples/Paper_Examples.thy` 的友元全在 `nat stream` 上：

```isabelle
corec (friend) add1s :: "nat stream ⇒ nat stream" where
  "add1s ns = (shd ns + 1) ## add1s (stl ns)"

corec (friend) plus_s :: "nat stream ⇒ nat stream ⇒ nat stream" where
  "plus_s xs ys = (shd xs + shd ys) ## plus_s (stl xs) (stl ys)"
```

注册后递归可以藏在友元参数里——斐波那契流一个方程：

```isabelle
corec fibS :: "nat stream" where
  "fibS = plus_s (0 ## 1 ## fibS) (0 ## fibS)"
```

**实测边界**：同款"加一"在自定义 `llist` 上，友元的尊重性义务
默认策略打不动（`Tactic failed`）——stream 的 transfer 设施齐全、
自定义类型要自己补规则。教学示例的友元全放 stream。

## 36.5 证引理：subst 单步

`corec` 的 `.code` 方程是**无穷展开**的：`simp add: fibS.code`
让化简器追着流展开，实测构建挂死到被超时打断。安全姿势：

```isabelle
lemma fib_head: "shd fibS = 0"
  by (subst fibS.code, subst plus_s.code) simp
```

## 36.6 corecursive：lfilter 的终止性

`else` 分支的 `lfilter P (ltl xs)` 是裸递归，`corec` 拒收，
要 `corecursive` + 手证。官方证明的度量是"到下一个满足谓词的
元素的距离"（`LEAST n. P (lhd ((ltl ^^ n) xs))`），核心引理
`Least_Suc` 说明跳过头一步后距离恰减一。全文见示例
（抄官方 `Corec_Examples/LFilter.thy`，逐行注释在文档侧）。

**抄官方片段要抄全**：官方在化简引理之间还有一条 `[simp]` 的
`lnull_lfilter`（lfilter P xs = LNil ⟷ ∀x∈lset xs. ¬ P x）——少了它，
下一条 `lfilter_LCons` 的 `auto` 当场卡住（实测目标剩
`LNil = lfilter P xs`）。教学版用充分方向的条件化简规则一行替代。

## 36.7 坑位清单（实测）

1. `corec` 不在 Main：裸 HOL 报 outer syntax error，要 HOL-Library 会话。
2. primcorec 拒绝构造子模式方程（Non-variable function argument）。
3. 自定义共数据类型上友元默认策略打不动（Tactic failed）。
4. `simp add: foo.code` 对 corec 方程发散；用 `subst` 单步。
5. 流 cons 是 `##`；`\<lhd>` 是个别文件的自定义记号。
6. 抄官方证明抄全——隐藏的 [simp] 依赖不在"读法"注释里。
7. `value` 对无穷流不可用（急切求值跑不完），用 shd/stl 的 subst 链。

## 36.8 与其他章的接口

- 第 26 章 primcorec/codatatype 基础；本章是其火力升级。
- 第 35 章 partial_function：共递归在部分函数侧的表亲。
- 第 51 章 Knaster–Tarski：corecursive 的不动点语义。
