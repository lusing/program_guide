# 07 语义表列：反向搜索的判定程序

> 对书：Ben-Ari 3e §2.6-2.7 / Huth&Ryan §1.5（间接）

表列是「倒着推」的自然演绎：不问「怎么证出 f」，而问「怎么把 ¬f
的全部可能性都堵死」。带符号公式 T f / F f 落在分支上：

- **α 规则**（不分枝）：T(a∧b)、F(a∨b)、F(a→b)、T/F(¬a)
- **β 规则**（分两枝）：F(a∧b)、T(a∨b)、T(a→b)
- **闭分支**：同一原子同时带 T/F 号

## 实现：fuel 化的结构递归

```
tsearch (fuel) (B : branch) : option (nat → bool)
  闭检查 closedB → None
  extract 首个复合式 → α 延长 / β 分枝（orelse 短路）
  全原子 → Some (readOff B)   ← 从 T 号原子读出模型
```

终止度量 `bsize B = Σ fsize f`：每次分解把复合式（尺寸 ≥2）换成
尺寸和恰小 1 的碎片——β 分枝每枝更是小 1+。

## 旗舰三定理（Coq 通道，全部零公理）

```
tsearch_sound    : tsearch fuel B = Some e → satisfies e B
tsearch_complete : bsize B < fuel → satisfies e B → tsearch fuel B ≠ None
tsearch_decides  : tsearch (S (bsize [(F,f)])) [(F,f)] = None ↔ valid f
```

sound 的饱和分支最有戏：readOff 读出的赋值对 T 号原子真——而 F 号
原子 x 若被读成 true，说明 B 里另有 (T, FVar x)，与 closedB = false
矛盾（closed 见证现场拼装）。complete 的 β 分支：模型满足哪枝就
反证哪枝不可能是 None。两者合起来：**None ⟺ 有效**——一个判定程序
的完整正确性，构造性成立。

## Lean 版：可执行现场

`#eval (tsearch 20 [(T, x₀ ∨ x₁)]).get! 0` 直接把模型读出来验证；
`found` 把 `Option (Nat → Bool)` 折成 Bool——函数 Option 不能判等
（funext 地雷，与范畴论教程的 NT 三文化同源）。

## 坑位速记（本章实测，20+ 轮迭代）

- **Coq**：`destruct (extract B) as [[[s f] B']|] eqn:Eex`——
  option((a*b)*c) 是**三层括号**；`eqn:` 会把 scrutinee 在 IH 里
  抽象掉（IH 的前提变成 `Some … = Some …`，用 `eq_refl` 消）；
  分支序 = 模式序（Some 在前！）——完备性证明曾把 None 分支写反；
  `tauto` 把 iff 假设当原子（先 `rewrite IH`）；等式方向
  `(s,f) = en` vs `en = (s,f)` 也不是重言式——`firstorder` 兜底；
  `↔` 的 `←` 方向 `valid → (= None)` 是**证明等式**不是否定——
  intros 只吃一个；destruct eqn 后目标被抽象成 `None = None`，
  收尾用 reflexivity 不是 exact E。
- **Lean**：`for_` 避让关键字；`/-…-/` 文档注释不能挂在 `#eval`
  前；三目 UNSAT 例句要想清楚（F(x₀→x₁)+T x₀+F x₁ 其实自洽——
  native_decide 直接证伪了我的第一版例句）。
- **元教训**：示例先在纸上走一遍再上机——判定器不会错，错的是
  对「矛盾」的直觉。
