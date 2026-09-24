# 20 · 化简器与 simpset

> 对应示例：[`examples/20_simpset/20_simpset.sml`](../examples/20_simpset/20_simpset.sml)

第 8 章把 `simp` 家族当作"几个不同力度的按钮"来用。这一章打开盖子：
simpset 里装的是**重写规则**、**合同性（cong）规则**和**定向策略**三样东西，
而 `simp` 之所以不会死循环，靠的是第三样。

## 20.1 四个现成的 simpset

```text
同一个项 `LENGTH ([] : num list)` 在四个 simpset 下：
  bool_ss  : <UNCHANGED>
  std_ss   : <UNCHANGED>
  arith_ss : <UNCHANGED>
  srw_ss() : ⊢ LENGTH [] = 0
bool_ss 只认命题演算，连 LENGTH 都不认识；
srw_ss() 在 std_ss 之上再挂上所有已注册数据类型的展开规则。
同一个项 `(1 : num) < 2` 在四个 simpset 下：
  bool_ss  : <UNCHANGED>
  std_ss   : ⊢ 1 < 2 ⇔ T
  arith_ss : ⊢ 1 < 2 ⇔ T
  srw_ss() : ⊢ 1 < 2 ⇔ T
```

```sml
fun sc nm ss ths t =
  out ("  " ^ nm ^ " : " ^
       (thm_to_string (SIMP_CONV ss ths t) handle UNCHANGED => "<UNCHANGED>"))
val _ = sc "bool_ss " bool_ss      [] ``LENGTH ([] : num list)``
val _ = sc "srw_ss()" (srw_ss ())  [] ``LENGTH ([] : num list)``
```

四个 simpset 的力度递进：

| 名字 | 装了什么 |
|---|---|
| `bool_ss` | 只有命题演算（`∧` `∨` `⇒` `¬` `=` 的基本规则） |
| `std_ss` | `bool_ss` + `bool` 库的其余规则 + 已注册数据类型的通用化简 |
| `arith_ss` | `std_ss` + 算术化简 |
| `srw_ss ()` | `std_ss` + 所有已注册类型的**方程展开**规则 |

第一组对比最能说明差别：`LENGTH []` 只有 `srw_ss ()` 认识 ——
因为 `LENGTH` 是具体函数，它的方程只挂在 `srw_ss` 上。

`bool_ss` 连 `1 < 2` 都判不出（第二组第一行），因为它没有算术。

> 注意 `SIMP_CONV` 在"什么都没改"时**抛 `UNCHANGED` 异常** ——
> 所以演示函数 `sc` 里必须 handle 掉，否则脚本会在这里 abort（20.7 节详述）。

## 20.2 装配：`++`

```text
bool_ss 加上 ETA_ss 才认 η 化简：
  bool_ss           : <UNCHANGED>
  bool_ss++ETA_ss   : ⊢ (λx. f x) = f ⇔ T
`++` 的类型是 simpset -> ssfrag -> simpset，右边是一「片段」，
可以带自己的重写规则、conv、cong、甚至一个 filter。
临时加规则用 SIMP_CONV 的第二个参数更省事：
  srw_ss + ADD_ASSOC : <UNCHANGED>
```

```sml
val _ = sc "bool_ss++ETA_ss  " (bool_ss ++ boolSimps.ETA_ss) [] ``(\x. f x) = f``
val _ = sc "srw_ss + ADD_ASSOC" (srw_ss ()) [ADD_ASSOC] ``(a : num) + b + c``
```

两种加装东西的方式：

1. **`ss ++ frag`** —— 造一个**新 simpset**。右边是个"片段"（`ssfrag`），
   可以带自己的重写规则、cong 规则、conv，甚至一个 filter。
   适合"这一整套配置我要反复用"的场合。
2. **`SIMP_CONV ss [thm1, thm2] t`** —— 只在**这一次调用**里加定理。
   适合临时试一下。

第二行 `<UNCHANGED>` 是个有意思的结果：`a + b + c` 用 `ADD_ASSOC`
按定向规则本来就是"已归约"的形状（左结合），所以它没动。
**加了规则不等于一定会有变化** —— 得看定向之后它是不是"变小"了。

## 20.3 定向：`simp` 为什么不循环

```text
ADD_COMM 说的是 m + n = n + m，两个方向都能匹配。
但 simp 按自己的项序把规则定向后，只往「变小」的一侧走：
  a + b : <UNCHANGED>
  b + a : ⊢ b + a = a + b
a + b 本来就「更小」，所以 UNCHANGED；b + a 被翻成 a + b 后停下。
REWRITE_CONV 没有这一层保护：
  REWRITE_CONV [ADD_COMM] `a + b` 会 a+b → b+a → a+b → …… 一直转下去。
  想只翻一次，用 Once：
  ⊢ a + b = b + a
（这条不能用脚本验证 —— 它会真的跑不完；run-all.sh 的看门狗就是为这种情况准备的。）
```

```sml
val _ = sc "a + b" bool_ss [ADD_COMM] ``(a : num) + b``
val _ = sc "b + a" bool_ss [ADD_COMM] ``(b : num) + a``
val _ = out ("  " ^ thm_to_string (REWRITE_CONV [Once ADD_COMM] ``(a : num) + b``))
```

这是全章最关键的一节。`ADD_COMM : ∀m n. m + n = n + m`
两个方向都能匹配 `a + b`，那 `simp` 为什么不会 `a+b → b+a → a+b → …` 死循环？

因为 **simpset 会给每条重写规则定向**：它按自己的项序（term ordering）
判断等式哪一侧"更小"，只允许往小的方向走。

- `a + b` 按项序本来就是较小的一侧 → 不动，抛 `UNCHANGED`；
- `b + a` 被翻成 `a + b`，然后停下（再翻就要变大，被定向策略挡住）。

`REWRITE_CONV` **没有**这一层保护：它老老实实按你给的方向重写，
`REWRITE_CONV [ADD_COMM] \`a + b\`` 会一直转下去。想只翻一次，加 `Once`：

```sml
REWRITE_CONV [Once ADD_COMM] ``a + b``   (* ⊢ a + b = b + a，只翻一次 *)
```

> 最后那行括号里的提醒是认真的：本教程的验证脚本 `run-all.sh` 里有个
> **看门狗**（默认 120 秒后 `KILL`），就是为了让"跑不完"变成可诊断的失败
> 而不是无限挂起。写 `simp`/`rw` 脚本时遇到"卡住"，第一反应应当是
> "我是不是把交换律/结合律当重写规则喂进去了"（另见 12.4 和 24.6）。

## 20.4 假设传播

```text
SIMP_CONV 的第二个参数是「额外的假设」，它会当重写规则用：
  带假设 x = 3  :  [.] ⊢ x + 1 = 4
但它不会替你把前提拆开：
  不拆前提      : ⊢ x = 3 ⇒ x + 1 = 4 ⇔ T
`simp`/`rw`/`fs` 会先拆再化，所以它们能过：
  ⊢ x = 3 ⇒ x + 1 = 4
注意 SIMP_CONV 打出来的 ` [.] ⊢ x + 1 = 4`：方括号里的点
代表「用掉了一条假设」，是化简器留下的痕迹，不是输出噪声。
```

```sml
val _ = sc "带假设 x = 3 " (srw_ss ()) [ASSUME ``(x : num) = 3``] ``x + 1``
val _ = sc "不拆前提     " (srw_ss ()) []
          ``(x : num) = 3 ==> x + 1 = 4``
val _ = out ("  " ^ p ``(x : num) = 3 ==> x + 1 = 4`` (rw []))
```

`SIMP_CONV` 的第二个参数是"额外的假设/定理"，它们会被当重写规则用。
第一行把 `x = 3` 喂进去，`x + 1` 就被化成了 `4`。

输出里那个 `[.] ⊢ x + 1 = 4` 值得解释一下：
**方括号里的 `.` 代表"用掉了一条假设"**，是化简器在定理左边留下的标记，
不是打印噪声。看到 `[.]` 就知道这个化简依赖了某条假设。

第二行和第三行的对比是关键：

- `SIMP_CONV` **不会**替你把 `⇒` 的前提拆开 —— 它把整个
  `x = 3 ⇒ x + 1 = 4` 当命题看待，判成 `⇔ T`（这个例子碰巧能判）；
- `simp` / `rw` / `fs` 是**战术**，它们会先 `strip_tac` 把前提拆进上下文，
  再化简。所以 `rw []` 能证 `x = 3 ⇒ x + 1 = 4`。

> 需要"让化简器用上某个前提"时，用**战术**（`rw`/`fs`），不要用 `SIMP_CONV`。

## 20.5 cong：化简儿子之前先看父亲

```text
AND_CONG  : ⊢ ∀P P' Q Q'. (Q ⇒ (P ⇔ P')) ∧ (P' ⇒ (Q ⇔ Q')) ⇒ (P ∧ Q ⇔ P' ∧ Q')
IMP_CONG  : ⊢ ∀x x' y y'. (x ⇔ x') ∧ (x' ⇒ (y ⇔ y')) ⇒ (x ⇒ y ⇔ x' ⇒ y')
COND_CONG : ⊢ ∀P Q x x' y y'.
    (P ⇔ Q) ∧ (Q ⇒ x = x') ∧ (¬Q ⇒ y = y') ⇒
    (if P then x else y) = if Q then x' else y'
OR_CONG   : ⊢ ∀P P' Q Q'. (¬Q ⇒ (P ⇔ P')) ∧ (¬P' ⇒ (Q ⇔ Q')) ⇒ (P ∨ Q ⇔ P' ∨ Q')
LET_CONG  : ⊢ ∀f g M N. M = N ∧ (∀x. x = N ⇒ f x = g x) ⇒ LET f M = LET g N
「合同性」说的是：要化简 P ∧ Q，可以先化简 P 和 Q。
带条件的那些更妙 —— IMP_CONG 允许在化简结论时用上前提：
  if p then 1 else 2 : ⊢ p ⇒ (if p then 1 else 2) = 1 ⇔ T
simp 能把 if 的两个分支分别化简，靠的就是 COND_CONG 里
那两条带前提的等式（Q ⇒ x = x'）和（¬Q ⇒ y = y'）。
```

```sml
val _ = out ("AND_CONG  : " ^ thm_to_string (DB.fetch "bool" "AND_CONG"))
val _ = out ("COND_CONG : " ^ thm_to_string (DB.fetch "bool" "COND_CONG"))
val _ = sc "if p then 1 else 2" (srw_ss ()) []
          ``(p : bool) ==> (if p then 1 else 2 : num) = 1``
```

**合同性（congruence）**规则告诉化简器"可以钻到哪里去化简"：

```
AND_CONG :  (Q ⇒ (P ⇔ P')) ∧ (P' ⇒ (Q ⇔ Q'))  ⟹  P ∧ Q ⇔ P' ∧ Q'
```

读法：要化简 `P ∧ Q`，先化简 `P`（可以假设 `Q` 成立），再化简 `Q`
（可以假设化简后的 `P'` 成立）。这就是 `rw` 能"边化左边、边用左边化右边"的机制。

带条件的那些更妙。`COND_CONG` 里：

```
(Q ⇒ x = x') ∧ (¬Q ⇒ y = y')
```

意思是：化简 `if P then x else y` 的 **then 分支时可以假设条件成立**，
化简 **else 分支时可以假设条件不成立**。

最后一行就是这个能力的直接结果：目标 `p ⇒ (if p then 1 else 2) = 1`
被判成 `⇔ T` —— 化简器知道在 `p` 成立的前提下 `if p then 1 else 2` 就是 `1`。

`IMP_CONG` 同理：化简蕴含的**结论**时可以用上**前提**。
这也是"`rw` 会自动用前提"这件事的底层机制。

## 20.6 AC

```text
交换律交给定向去解有个副作用：它只认一种「规范序」。
想把 a + b + c 归一成某个固定形状，用 AC：
  AC ADD_ASSOC ADD_COMM : ⊢ a + b + c = a + (b + c)
AC 把两条定理交给化简器里的 AC 机制，不再走逐条重写。
```

```sml
val _ = sc "AC ADD_ASSOC ADD_COMM" bool_ss
          [AC ADD_ASSOC ADD_COMM] ``(a : num) + b + c``
```

定向机制保证了终止，但副作用是**它只认一种规范序**。
想把 `a + b + c` 归一成"右结合"这种固定形状，定向逐条重写做不到
（`ADD_ASSOC` 定向后只会往左结合走）。

`AC` 把结合律和交换律一起交给化简器里的 **AC 机制**，
不再走"逐条重写 + 定向"，而是做真正的结合-交换归一化。
上面那行输出 `⊢ a + b + c = a + (b + c)` 就是归一化的结果。

> 需要"把一堆加法/乘法按某种规范形排好"时（比如 24 章的表达式优化），
> 用 `AC` 比硬塞 `ADD_ASSOC` / `ADD_COMM` 稳。

## 20.7 边界

```text
1) 不做归纳。LENGTH (REVERSE l) = LENGTH l 它一点办法都没有；
2) 不做非线性算术。`n * n >= n` 这种要自己给引理；
3) 不会为了用某条规则去「造」一个中间步骤；
4) 用 UNCHANGED 表示「没改动」——这是异常，不是返回值。
边界 4 的实际后果：
  改得动： ⊢ a ∧ T ⇔ a
  改不动： <抛 UNCHANGED —— 没改动时它抛异常>
```

```sml
val _ = out ("  改得动： " ^ thm_to_string (SIMP_CONV bool_ss [] ``(a : bool) /\ T``))
val _ = out ("  改不动： " ^ ((thm_to_string (SIMP_CONV bool_ss [] ``(a : bool) /\ b``))
                     handle UNCHANGED => "<抛 UNCHANGED —— 没改动时它抛异常>"))
```

四条边界：

1. **不做归纳。** `LENGTH (REVERSE l) = LENGTH l` 需要结构归纳（14.5 节）；
2. **不做非线性算术。** `n * n ≥ n` 要自己给单调性引理；
3. **不会"造"中间步骤。** 它只会按已有规则重写，不会为了用某条规则
   去发明一个引理或插入一步推理；
4. **用 `UNCHANGED` 表示"没改动"** —— 这是**异常**不是返回值。

最后两行是边界 4 的实证：同一个 `SIMP_CONV` 调用，
`a ∧ T` 改得动就返回定理，`a ∧ b` 改不动就抛异常。
**不 `handle` 的话脚本会在这里 abort** —— 这也是 11 章说
"写脚本时外层包 `TRY_CONV` / `QCONV`"的原因。

## 20.8 坑位清单

1. **`SIMP_CONV` 没改动时抛 `UNCHANGED`** → 演示和工具里必须 handle。
2. **`++` 的右边是 `ssfrag` 不是定理列表** → 临时加定理用 `SIMP_CONV` 的第二个参数。
3. **加了规则不代表会有变化** → 定向之后得真的"变小"才会重写。
4. **`REWRITE_CONV [ADD_COMM]` 会死循环** → 它没定向；要 `Once` 或改用 `simp`。
5. **别把交换律/结合律当重写规则喂给 `rw`** → 容易绕圈跑不完（12.4、24.6）。
6. **`SIMP_CONV` 不拆前提** → 要让化简器用上前提，用 `rw` / `fs`（它们是战术）。
7. **输出里的 `[.]` 是"用掉了假设"的标记** → 不是打印噪声。
8. **`srw_ss ()` 是个函数调用，括号不能省** → `arith_ss` / `std_ss` 才是常量。
9. **`bool_ss` 连 `LENGTH` 和 `1 < 2` 都不认识** → 试化简时先换 `srw_ss ()`。
10. **需要结合-交换归一化时用 `AC`** → 定向逐条重写只认一种规范序。

---

上一章：[19 · 类型与类型缩写](19-types.md) ·
下一章：[21 · 自动化工具箱](21-automation.md)
