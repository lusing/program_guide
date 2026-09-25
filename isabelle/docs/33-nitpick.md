# 33 · Nitpick：证明之前，先问反例

对应示例：`../examples/T33_nitpick.thy`

## 33.1 一句话概括

Nitpick 把猜想翻译成一阶关系问题交给 Kodkod（内置 SAT 前端，
离线），在有限模型里穷尽搜索反例。找到 = 猜想必假（省掉你几小时
的无效证明）；找不到 ≠ 真，但小模型全过已是强证据。
与 quickcheck 的分野：quickcheck 只测可执行目标，Nitpick 能啃
量词、谓词、类型类约束的纯逻辑命题。

## 33.2 命令形态与 expect 断言

和 Sledgehammer 一样，`nitpick` 是**命令不是方法**，插在
`lemma` 与 `oops` 之间单占一行。`expect` 参数把结果变成可验证断言：

```isabelle
lemma wrong_rev: "rev (xs @ ys) = rev xs @ rev ys"
  nitpick [expect = genuine]
  oops
```

构建日志的真实输出：

```text
Nitpicking formula...
Nitpick found a counterexample for card 'a = 5:
  Free variables:
    xs = []
    ys = [a1, a2]
```

四档预期：`genuine`（真反例）、`none`（无反例）、`potential`
（潜在反例，模型实现未定）、`unknown`（超时/放弃）。
声明了 expect 而实际不符 → 报错。这让"找反例"本身成为被机器
认可的验证内容。

## 33.3 基数控制：card 与"漏反例"

Nitpick 对类型变量默认试到基数 5 左右。基数给小了会**漏反例**——
下面这条"所有元素相等"在基数 1 的模型里是真的，基数 2 才露馅：

```isabelle
lemma all_eq: "∀x y :: 'a. x = y"
  nitpick [card 'a = 1, expect = none]
  nitpick [card 'a = 2, expect = genuine]
  oops
```

两条连跑、两个 expect 都如约命中——这是"无反例 ≠ 真"的活标本。
反过来说，看到 `expect = none` 的目标卡在证明上，先把 card 调大
再跑一次，经常当场翻车。

常用旋钮：

- `[card 'a = 1-4, card nat = 2]`：按类型定基数（范围用 `-`）；
- `[show_all]`：打印模型里全部函数/关系（默认折叠成 `...`）；
- `[timeout = 10]`：秒数；
- `[box]`：把无限类型装盒近似（进阶，见手册）。

## 33.4 定义自动展开

实测：`definition` 的方程默认可用。`quad n = n * n` 不挂任何属性，
反例具体到 `n = 1`——说明它在数值层面展开了定义验算：

```text
Nitpick found a counterexample:
  Free variable:
    n = 1
```

需要手动标注的场合是"没有定义体"或"默认展开不准"：
`[nitpick_simp]`（fun 风格方程）、`[nitpick_psimp]`（模式匹配方程）、
`[nitpick_def]`（谓词特征化）——它们**覆盖**自动注册的行为。

## 33.5 potential 反例的味道

目标带公理（`assumes`/`axiomatization`）时，Nitpick 把公理当约束
找模型——公理本身可能不可满足或 Nearly vacuous，于是报
`potential counterexample`。看到它三步走：

1. 公理是否自洽（`axioms ⟹ False` 可导出吗）；
2. 未解释常量/函数是不是该挂 `nitpick_def`；
3. 都没问题再怀疑命题本身。

## 33.6 反例优先工作流

Nitpick 手册的节奏，落成三条军规：

1. 猜想写好后**先** `nitpick [expect = genuine]` 快扫
   （`[card 'a = 1-3, timeout = 10]`），有反例就改命题；
2. 反例干净（模型值具体）→ 改命题；`potential` → 查公理；
3. `expect = none` 通过后再证明；证明卡住时**回头看反例**——
   模型值常常就是缺的那个 `arbitrary:` 或 case-split。

与 Sledgehammer 分工：锤子负责"证出来"，Nitpick 负责"别证错方向"。

## 33.7 坑位清单（实测）

1. **`nitpick` 是命令不是方法**：`by nitpick` 语法错误，
   与 `sledgehammer` 同款坑。
2. **`expect` 写了就要对**：`expect = genuine` 而实际 none 会让
   构建失败——这正是我们要的（断言化），但改示例时容易忘同步。
3. **`card 'a = 5` 里的 5 是它自己定的**：输出里带基数信息，
   引用反例时连基数一起抄。
4. **基数小漏反例**：33.3 的活标本。证明卡住 + expect=none 时，
   先怀疑搜索空间不够。
5. **SAT 是指数的**：card 一大就爆炸，`timeout` 保护的是你
   的耐心，不是完备性。
6. **定义默认展开**——但只展开一层方程链可达的部分；
   `fun` 的条件方程挂 `[nitpick_simp]` 更稳。
7. **`n = 1` 这类模型值是从 0 编号的自由变量**：'a1, 'a2 是
   模型里的抽象元素（打印成下标形式），不是 nat 的 1。
8. **quickcheck 与 nitpick 语义差**：quickcheck 找到的"反例"是
   程序测试失败；nitpick 是逻辑模型。公理化目标 quickcheck
   直接说测不了。
9. **构建耗时**：每个 nitpick 调用秒级（SAT 转译），一章十几个
   调用就让验证翻倍——和 sledgehammer 一样省着用。
10. **`oops` 别忘写**：`expect = genuine` 的 lemma 是假命题，
    不 `oops` 收尾构建直接报 no proof。

## 33.8 与其他章的接口

- 第 17 章 quickcheck：可执行侧的姊妹工具，速度互补。
- 第 22 章诊断：本章是其 33.1 那句"真正的安全是 nitpick"的展开。
- 第 32 章锤子：正反两翼。
- 第 50 章证明论：为什么有限模型完备性不可指望——
  一阶逻辑的语义与语法差距。
