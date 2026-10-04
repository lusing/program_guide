# 25 霍尔逻辑程序验证：while 规则与不变式

> 对书：Huth&Ryan ch4 / Ben-Ari 3e ch15

前三条是演算的「程序侧」收官：命题/谓词/时序之后，把「推理」
对象换成「程序」。霍尔三元组 `{P} c {Q}`（部分正确性：P 成立时
执行 c 终止则 Q 成立）的证明系统只有四条骨干规则——skip、赋值、
顺序、while——加上后承规则即可完备（相对 while 语言的部分正确
性，Cook 定理）。

## while 语言与语义

```
cmd := skip | x := f(state) | c1; c2 | while b do c
exec : cmd -> state -> state -> Prop   （大步语义）
hoare P c Q := ∀s1 s2. P s1 → exec c s1 s2 → Q s2
```

状态 = 变元赋值（`nat → nat`），程序变量是状态的**自变量**——
这带来了五通道共有的别名坑：`x = y` 时两个「变量」是同一格，
`x := x-1; y := y+1` 的修补项不再抵消，正确性必须以 `x ≠ y`
为前提（Coq/Lean/Isabelle/Agda 四版同款条件）。

## 旗舰四条（五通道对照）

```
hoare_skip    {P} skip {P}
hoare_ass     {Q[x↦e]} x := e {Q}        （赋值公理：后推前件）
hoare_seq     {P} c1 {Q} / {Q} c2 {R} ⇒ {P} c1;c2 {R}
hoare_while   {P∧b} c {P} ⇒ {P} while b c {P∧¬b}
```

### while 规则的三系统反应（本章最大看点）

归纳 `exec (cwhile b c) s1 s2` 时构造子头索引的处理：

| 系统 | 配方 |
|------|------|
| Coq | `remember (cwhile b c) as w` + revert → 方程进动机，`inversion Hw` 灭不可能支 |
| Lean | induction 直接拒绝构造子头索引（"consider cases"）；命令泛化为 w + 方程 `w = cwhile b c` 进 `key` 引理（remember 的直译），`Cmd.noConfusion` 灭支 |
| Isabelle | `induct "cwhile b c" s1 s2 arbitrary: HP rule: exec.induct` 显式实例化 + HP 依赖索引必须 arbitrary；不可能支自动小反转 |
| Agda | 结构递归两行——构造子头索引是常态，匹配即小反转，三套仪式全免 |
| HOL4 | 命令泛化 + 方程携带（Coq 同款）且必须 `exec_strongind`（弱 ind 的案例只有 exec' 没有 exec 副推导） |

## 现场演示：倒数程序

```
countdown(x,y) := while (x ≠ 0) do (x := x-1; y := y+1)
不变式 inv := s x + s y = C
```

组装：`hoare_seq`（中间不变式选 `t x + t y + 1 = C`——先减后加
的一轮修补）+ 两次 `hoare_ass` + `hoare_while`，得到
`inv s2 ∧ s2 x = 0`（部分正确性 + 出口守卫）。

截断减法坑（五通道同病）：`s x - 1 + 1 = s x` 需要 `s x > 0`，
由循环守卫 `s x ≠ 0` 提供——Coq 用 `lia`、Lean 用 `omega`、
Isabelle 取 `Suc k` 分解、Agda `suc k` 分解后 `∸ 1` 定义式归约、
HOL4 `Cases_on` + `fs`。

## 通道边界（如实登记）

- Coq / Lean / Isabelle / Agda：完整 `countdown_correct` 组装。
- HOL4：四条规则全量 + 单步不变式引理 `countdown_step`——
  exec 双重反演（seq→cass→upd 方程链）被 `IMP_RES_THEN` 的
  实例级联污染上下文，完整组装的代价与教学价值不成比例，
  单步引理承载同一核心算术（截断减法 + 别名前提）。

## 坑位速记（本章实测）

- **Coq**：`remember` + `revert HP` 后方程 Hw 自动进动机（五个
  构造子分支前三支 `inversion Hw` 灭）；不 remember 直接归纳
  会把 cmd 索引完全泛化（skip 分支变得不可证）；`inv` 等
  Definition 在假设里对 `lia` 不透明——先 `unfold inv in Hinv'`。
- **Lean**：`while` 是 do 记法保留字（构造子必须叫 `cwhile`）；
  `lemma` 在本工具链（4.25 裸 core）不是命令关键字——解析器
  当标识符吃进应用参数；守卫别写 `!(s x == 0)`——BEq+decide
  强制让同一式样在守卫位与前件位 elaboration 分叉（非 defeq），
  正解 `decide (s x ≠ 0)` + `of_decide_eq_true` 桥。
- **Isabelle**：裸 `proof (induct rule: exec.induct)` 装不上
  （构造子头索引要显式实例化 + `arbitrary: HP`）；`hoare_seq`
  的 auto 深度不够——blast 一发过。
- **Agda**：upd 用 with 定义会让 upd-self/upd-other 卡
  with-under-with——换 Bool-if + cong；等价判定用 `_≡ᵇ_` 而非
  `⌊ m ≟ x ⌋`（stdlib 的 `_≟_` 走 because/Reflects 构造，
  Dec 不做定义性归约，with 抽象留悬空约束）；组装构件（first/
  second）要提为顶层显式参数——where 块的隐式 State 元变量在
  hoare-seq 应用位悬空。
- **HOL4**：战术位引文是静态上下文 elaboration（目标绑定的
  P/s1 看不见——全类型注解救命，`!s1 s2.` 加注解反而解析失败，
  DECIDE 引理绑定名 b 与上下文冲突）；metis 三雷（大定理集/
  hoare 黑盒/函数等式上下文）全部参数调制爆炸且 hol run 模式
  静默中止——RES_TAC 确定性消解是正解；Hol_reln 的 strongind/
  cmd_distinct/cmd_11 要 fetch；exec 反演只能一层（级联污染）。
