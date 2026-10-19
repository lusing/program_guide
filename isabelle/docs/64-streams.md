# 64 · 流、流上的 LTL、ω 词与周期函数

对应示例：`../examples/lib/T64_streams.thy`（IsaTutLib 会话，依赖
`HOL-Library.Stream`、`Linear_Temporal_Logic_on_Streams`、
`Omega_Words_Fun`、`Periodic_Fun`、`Code_Lazy`）

「无穷序列」在 HOL-Library 里有两个平行世界：共归纳数据类型
`stream`（第 26 章的 codatatype 装备齐全）与类型同义词
`'a word = nat ⇒ 'a`（函数装备直接用）。本章讲清两者及其上的
时序逻辑与周期设施。

## 64.1 Stream：共归纳列表及其求值前提

`Stream` 是库存的共归纳列表：构造子 `x ## s`（`SCons`），选择子
`shd`/`stl`，映射 `smap`，索引 `s !! n`，前段 `stake`/`sdrop`，
列表前缀拼接 `xs @- s`。

先讲一个硬前提：**流不能直接 `value`**。生成代码里 `SCons` 是
严格构造子，严格求值构造无限尾部会撑爆栈（实测
`Interrupt_Breakdown`）。`Code_Lazy` 的 `code_lazy_type stream`
把流包成惰性表示，之后 `stake` 一类有限观察才能安全求值：

```isabelle
code_lazy_type stream

value "stake 5 (nats :: nat stream)"        (* [0, 1, 2, 3, 4] *)
value "(nats :: nat stream) !! 4"           (* 4 *)
value "stake 5 (cycle [1::nat, 2, 3])"      (* [1, 2, 3, 1, 2] *)
value "stake 4 (smap (%n. n * 2) (nats :: nat stream))"  (* [0, 2, 4, 6] *)
value "stake 3 ([9::nat, 8] @- nats)"       (* [9, 8, 0] *)
```

`nats` 是库里现成的缩写（`fromN 0`，即 `siterate Suc 0`）——
别自己再定义同名常量（不报错，但 simp 展开路径不同，残目标会
突然冒出 `fromN`）。`sset s` 是元素集合，`sset_range` 把它与
`snth` 的值域互译——集合视角与序列视角的桥。

## 64.2 生成器与共归纳证明

两个基本生成器：`siterate`（反复应用函数）与 `cycle`（循环非空
列表）。它们满足同一形态的不动点方程 `s = x ## s`，于是「逐个
构造子相等」的共归纳能证它们相等：

```isabelle
lemma cycle_singleton_is_siterate: "cycle [x] = siterate id x"
  by coinduction auto
```

`coinduction` 方法自动生成关系
`R a b ⟷ (a = cycle [x] ∧ b = siterate id x)`，剩下的「头相等、
尾仍在关系内」都是 auto 的常规动作。这是流上证明的标准起手式，
比手动构造双模拟省力得多。（顺带一提：打印时
`siterate id x` 会显示成 `sconst x`——库里还有这个常流缩写。）

## 64.3 流上的线性时序逻辑

`Linear_Temporal_Logic_on_Streams` 把 LTL 建在流上：公式是
`'a stream ⇒ bool` 的谓词。算子一览：`holds P`（首元素满足 P）、
`nxt φ`（下一时刻）、`HLD s`（首元素属于集合 s——原子命题的
标准入口）、`ev φ`（**终将**，归纳定义）、`alw φ`（**恒常**，
共归纳定义）、`φ until ψ`（弱直到，共归纳）。记号 `s · P` 是
「当前在 s、下一刻起 P」。

两个证明演示，恰好展示两种定义的对偶风格。`ev` 是归纳定义，
用引入规则直接构造（第 2 位恰好是 2）：

```isabelle
lemma ev_demo: "ev (HLD {2::nat}) (sdrop 2 nats)"
  by (rule ev.base) (simp add: HLD_iff)
```

`alw` 是共归纳定义，用共归纳证。注意 `arbitrary: k`——把关系
泛化到任意起点，否则尾巴换相（`siterate Suc k` 的 k 每步加一）
关系就断了：

```isabelle
lemma alw_demo: "alw (%s. even (shd s)) (smap (%n. 2 * n) (siterate Suc k))"
  by (coinduction arbitrary: k) auto
```

`until` 一族配了完整代数（`ev_nxt`、`alw_mono` 等单调性与展开
式），模型检查所需的 LTL 语义基础都在。

## 64.4 Omega_Words_Fun：作为函数的 ω 词

`Omega_Words_Fun` 与 Stream 平行但走了另一条路：
`'a word` 就是 `nat ⇒ 'a` 的**类型同义词**——没有包装。好处是
函数装备（复合、逐点运算）直接用；坏处是没有共归纳工具。
配套操作：拼接 `w ⌢ x`（有限词接 ω 词）、ω 迭代 `w⇧ω`（非空
有限词的无限循环）、`suffix k x`（丢前 k 个）、`w [i → j]`
（右开区间子串）、`limit x`（无穷多次出现的字母集——定义在
62 章的 `∃⇩∞`（`Inf_many`）上，是 ω 自动机接受条件的基石）。

```isabelle
value "([0::nat, 1]⇧ω) 5"     (* 1 — 5 mod 2 = 1 *)

lemma "([1::nat, 2, 3] ⌢ w) 1 = 2"
  by simp
```

`iter` 的定义 `w⇧ω n = w ! (n mod length w)` 把「周期性」直接
写成取模，周期引理由 mod 算术完成：

```isabelle
lemma aux: "Suc (Suc n) mod Suc (Suc 0) = n mod Suc (Suc 0)"
  by arith

lemma iter_periodic: "([0::nat, 1]⇧ω) (2 + n) = ([0, 1]⇧ω) n"
  by (simp add: iter_nth aux)
```

（`aux` 写成 Suc 形态是因为 `length [0,1]` 化简后就是
`Suc (Suc 0)`，`simp` 按形态匹配——写辅助引理时先让残目标
现身说法。）

## 64.5 Periodic_Fun：周期函数的 locale

`Periodic_Fun` 把「`f (x + p) = f x`」封装成 locale
`periodic_fun`：证一次周期，白拿一族导出（`f (x - p) = f x`、
`f (x + n*p) = f x` 等，`periodic_simps` 引理集）。两个便利子
locale：`periodic_fun_simple`（任意周期 p）与
`periodic_fun_simple'`（周期 1）。演示：mod 2 是周期 2 的：

```isabelle
interpretation mod2: periodic_fun_simple "λn::int. n mod 2" 2
  by standard auto

lemma "(λn::int. n mod 2) (5 + 3 * 2) = (λn::int. n mod 2) 5"
  using mod2.plus_of_nat[of 5 3] by simp
```

`plus_of_nat` 是 locale 导出的「加 n 个周期不变」。三角函数是
头牌用户：`sin_plus_pi`、`cos_plus_pi` 一族就是这么来的——
证的只是 `sin (x + π) = - sin x` 这类半周期关系，再由 locale
组合出整周期。

## 64.6 坑位清单（实测）

1. **流的 `value` 必须先 `code_lazy_type stream`**（导入
   `Code_Lazy`），否则严格求值撑爆栈（Interrupt_Breakdown）。
2. **库里已有缩写 `nats = fromN 0`**，别重名定义；打印时
   `siterate id` 显示为 `sconst`、`siterate Suc` 显示为
   `fromN`——读输出时认识这些别名。
3. 共归纳证流相等用 `by coinduction auto`；关系里有递变参数
   时（如 `siterate` 起点）必须 `arbitrary: k` 泛化，否则尾巴
   掉出关系。
4. `ev` 是归纳定义（intro 构造），`alw`/`until` 是共归纳
   （coinduction）——证明风格相反，别拿 intro 证 alw。
5. **`##` 记号有两个主人**：Stream 的 `SCons` 与
   Omega_Words_Fun 的 `build`，同导入时 `x ## s` 歧义——
   正文引用退到 `SCons`/构造子全名。
6. `'a word` 是类型同义词不是新类型：流的 `shd`/`stake` 不适用
   于 word，但函数装备直接用。
7. `w⇧ω` 对空列表是 `undefined`——所有周期引理都带
   `w ≠ []`/`0 < length w` 前提。
8. `w [i → j]` 是右开区间子串（基于 `[i..<j]`），长度 j - i。
9. `periodic_fun` 总 locale 参数多（g/gm/g1/gn1 四个加速器），
   自用先实例化 simple 变体。
10. LTL 的 `holds`/`nxt`/`ev`/`alw` 名字很短，与其他理论同堂
    时留意冲突；`HLD` 是原子命题入口（`HLD_iff` 即
    `shd ω ∈ s`）。

## 64.7 与其他章的接口

- 第 26 章 codatatype/corec：Stream 是那条流水线的库存实例，
  本章的 `coinduction` 演示是它的直接应用。
- 第 36 章 corec 友元：流的递归定义（`sfilter` 等）走那里讲的
  友元机制。
- 第 62 章 Infinite_Set：`limit` 集与 LTL 的 `ev`/`alw` 与
  `∃⇩∞`/`∀⇩∞` 同宗。
- 第 63 章单子：stream 的 `smap`/`sbind` 结构与列表单子同源；
  word 则直接吃 Function_Algebras 的逐点装备。
- 第 65 章 Code_Lazy：本章 `code_lazy_type` 是预告。
