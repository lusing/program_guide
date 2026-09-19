# 13 · 闭包与一等过程：PROC 值、捕获、作用域规则 ★

> 示例：[`examples/13_closures/13_closures.a68`](../examples/13_closures/13_closures.a68)
> 运行：`./run-all.sh 13`（或 `cd examples/13_closures && a68g 13_closures.a68`）

Algol 68 的 `PROC`（过程）是**一等值**：可以存进变量、当参数传、当结果返回、放进数组。
但"闭包捕获局部量再导出"受严格的**作用域规则**限制——本章用实测把这条规则钉死，并给出
在 a68g 里真正可用的惯用法。所有代码来自示例，输出逐字节取自本机 `a68g 3.13.3`。

`run-all.sh 13` 双通道验证：check 通道 `a68g --warnings --notices`（解释器，全运行时检查），
release 通道 `a68g -O2`（编译到 C 后端），两条通道 stdout 必须**逐字节一致**，且退出码 0、
stderr 空、含结束标记 `==== 13 结束 ====`。

## 1. PROC 是一等值：可存进变量、当参数传递

```algol68
PROC (INT) INT sq = (INT x) INT: x * x;
PROC (INT) INT cb = (INT x) INT: x * x * x;
PROC twice = (PROC(INT)INT f, INT x) INT: f(f(x));   # 高阶：接受 PROC 当参数 #
print(("sq(5)=", whole(sq(5), 0), "  cb(3)=", whole(cb(3), 0), new line));
print(("twice(sq,3)=sq(sq(3))=sq(9)=", whole(twice(sq, 3), 0), new line));
```

- `PROC (INT) INT sq = ...` 声明一个**过程值**：`sq` 的模是"接受 `INT`、返回 `INT` 的过程"，
  即 `PROC(INT)INT`。它绑定的是一段 routine-text `(INT x) INT: x * x`。
- `PROC twice = (PROC(INT)INT f, INT x) INT: f(f(x))` 是一个**高阶过程**：它的第一个形参
  `f` 本身就是一个 `PROC(INT)INT`。调用 `twice(sq, 3)` 就是 `sq(sq(3)) = sq(9) = 81`。
- 因为 `PROC` 是值，它可以像 `INT` 一样被赋给变量、当实参传递。实测：
  `sq(5)=25  cb(3)=27`、`twice(sq,3)=sq(sq(3))=sq(9)=81`。

## 2. PROC 数组：一等的直接体现

```algol68
[1:2] PROC(INT)INT ops := (sq, cb);
print(("ops(1)(4)=", whole(ops(1)(4), 0), "  ops(2)(2)=", whole(ops(2)(2), 0), new line));
```

- `[1:2] PROC(INT)INT ops := (sq, cb)` 是一个元素为过程值的行：`ops(1)` 是 `sq`，`ops(2)`
  是 `cb`。
- `ops(1)(4)` 是**两次调用**：先 `ops(1)` 取出过程 `sq`，再 `(4)` 调用它，得 `sq(4) = 16`。
  同理 `ops(2)(2) = cb(2) = 8`。实测 `ops(1)(4)=16  ops(2)(2)=8`。

## 3. 捕获"全局量"的闭包：可自由导出

闭包（closure）= 过程值 + 它捕获的外部名字。关键是：**被捕获的名字必须活得比这个过程值久**。
全局量、外层 `HEAP` 盒满足这一点，因此可以安全导出：

```algol68
HEAP INT bias := 7;
PROC mk biased = PROC(INT)INT: (INT x) INT: x + bias;   # 捕获全局 HEAP 盒 bias #
PROC (INT) INT plus7 := mk biased;
print(("plus7(10)=10+bias=", whole(plus7(10), 0), new line));
bias := 20;                               # 改全局盒，闭包随之看到新值（真·捕获） #
print(("bias 改成 20 后 plus7(10)=", whole(plus7(10), 0), "（闭包看见新值）", new line));
```

- `mk biased` 是一个返回 `PROC(INT)INT` 的过程；它返回的 routine-text `(INT x) INT: x + bias`
  **捕获了外层名字 `bias`**（一个 `HEAP INT` 盒）。把结果赋给 `plus7`，就得到一个可导出的闭包。
- `plus7(10)` = `10 + bias` = `10 + 7` = `17`。实测 `plus7(10)=10+bias=17`。
- **捕获的是引用，不是快照**：`bias := 20` 改的是同一个堆盒，之后 `plus7(10)` = `10 + 20` =
  `30`。实测 `bias 改成 20 后 plus7(10)=30（闭包看见新值）`。这正是第 12 章 `REF`/`HEAP`
  的语义：闭包通过引用看到盒的当前值。

## 4. 作用域规则 ★：捕获"局部量/形参"再导出 = 运行期错误

这是本章的核心坑。考虑"经典柯里化"写法——内层闭包捕获外层过程的**形参**：

```algol68
PROC adder = (INT k) PROC(INT)INT: (INT x) INT: x + k;   # 内层捕获形参 k #
PROC (INT) INT add5 := adder(5);                          # 把返回的闭包带出 adder #
```

实测这段代码在 a68g 3.13.3 里会：

```text
warning: potential scope violation from PROC(INT)INT routine-text
runtime error: PROC(INT)INT value is exported out of its scope
```

- **原因**：形参 `k` 绑定在 `adder` 这次调用的**栈帧**上。`adder(5)` 返回后，那个栈帧就销毁了，
  闭包里的 `k` 变成**悬空引用**（dangling）。Algol 68 的**作用域规则**要求："routine-text 只能
  带出寿命不短于它自身的对象"——即被捕获的名字必须活得比过程值久。形参/局部量的寿命止于
  所在块，比返回的过程值短，所以违规。
- **这不是 bug，而是语言在替你把"悬垂闭包"挡在运行期**。a68g 先给编译期 `warning: potential
  scope violation`，运行到导出那一步再抛 `runtime error: ... exported out of its scope`。
- 因此本示例**故意不触发**该错误（否则程序中断），只打印说明：

  ```text
  作用域规则：捕获局部/形参并导出 → 运行期 'exported out of its scope'
  （本示例故意不触发该错误，以免中断；错误形态见 docs/13）
  ```

对照 §3：捕获**全局 `HEAP` 盒** `bias` 之所以合法，是因为那个盒的寿命足够长（活得比返回的
过程值久），不违反作用域规则。**能否导出闭包，取决于被捕获名字的寿命，而非语法形式。**

## 5. 惯用法：有状态生成器用"显式 REF 传状态"

既然不能靠"捕获局部量"做可导出的有状态过程，正确姿势是：**状态由调用方持有（一个 `HEAP`
盒），过程接收 `REF` 就地改**（把第 12 章的引用语义用起来）：

```algol68
PROC next = (REF INT c) INT: (c +:= 1; c);
REF INT ctr = HEAP INT := 0;              # 调用方拥有状态，两个计数器互不干扰 #
REF INT ctr2 = HEAP INT := 0;
INT a1 := next(ctr), a2 := next(ctr), a3 := next(ctr);
INT b1 := next(ctr2);
print(("ctr: ", whole(a1, 0), " ", whole(a2, 0), " ", whole(a3, 0),
      "   ctr2: ", whole(b1, 0), "（各自独立）", new line));
```

- `next` 接收一个 `REF INT c`，用 `(c +:= 1; c)` 先就地加 1、再返回新值（分号串接，最后一项
  是结果）。`c +:= 1` 是解引用赋值，改的是调用方那个堆盒。
- `ctr`、`ctr2` 是**两个独立的堆盒**，各存各的状态。连续调 `next(ctr)` 得 1、2、3；调
  `next(ctr2)` 得 1。实测 `ctr: 1 2 3   ctr2: 1（各自独立）`。
- 状态**不在闭包里，而在调用方手里的 `REF` 盒里**——因此没有作用域违规，可以随意传递、导出。

同理可做**累加器**：状态是 `REF INT`，过程往里加（返回 `VOID`，调用即语句）：

```algol68
PROC acc = (REF INT s, INT v) VOID: s +:= v;
REF INT sum = HEAP INT := 0;
acc(sum, 5); acc(sum, 3); acc(sum, 2);
print(("累加 5+3+2 → sum=", whole(sum, 0), new line));
```

`acc` 返回 `VOID`，所以 `acc(sum, 5)` 本身就是一条语句。三次累加后 `sum` = 10，实测
`累加 5+3+2 → sum=10`。

## 6. 柯里化在 a68g 里的可行形态：靠 HEAP 盒，不靠捕获形参

经典柯里化 `add(3)(4)` 需要内层闭包捕获外层形参——受 §4 的作用域规则限制，无法导出。
可行写法是：**把外层的 `k` 存进一个 `HEAP` 盒，内层闭包捕获那个"够宽"的盒**：

```algol68
HEAP INT k box := 0;
PROC set k = (INT k) VOID: k box := k;
PROC (INT) INT add curried = (INT x) INT: x + k box;
set k(3); INT r1 := add curried(4);        # 相当于 add(3)(4)=7 #
set k(10); INT r2 := add curried(4);       # add(10)(4)=14 #
print(("curried add(3)(4)=", whole(r1, 0), "  add(10)(4)=", whole(r2, 0), new line));
```

- `k box` 是一个全局 `HEAP INT` 盒；`set k(k)` 把值写进盒；`add curried(x)` 返回 `x + k box`。
- 因为 `add curried` 捕获的是**全局堆盒**（寿命够长），不违反作用域规则，可自由使用。
- `set k(3)` 后 `add curried(4)` = `4 + 3` = 7；`set k(10)` 后 = `4 + 10` = 14。实测
  `curried add(3)(4)=7  add(10)(4)=14`。
- 代价：`k` 是全局共享的单一状态，"当前偏值"由 `set k` 显式切换——这不是真正每次调用独立的
  柯里化，而是"用全局盒模拟"。真正的独立捕获受作用域规则所限，无法直接导出。

## 7. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 13` 中 check 通道的真实 stdout（release 通道逐字节一致）：

```text
sq(5)=25  cb(3)=27
twice(sq,3)=sq(sq(3))=sq(9)=81
ops(1)(4)=16  ops(2)(2)=8
plus7(10)=10+bias=17
bias 改成 20 后 plus7(10)=30（闭包看见新值）
作用域规则：捕获局部/形参并导出 → 运行期 'exported out of its scope'
（本示例故意不触发该错误，以免中断；错误形态见 docs/13）
ctr: 1 2 3   ctr2: 1（各自独立）
累加 5+3+2 → sum=10
curried add(3)(4)=7  add(10)(4)=14
==== 13 结束 ====
自检全部通过
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| `twice(sq,3)=...=81` | 高阶过程 `twice(f,x)=f(f(x))`，`sq(sq(3))=sq(9)=81` |
| `ops(1)(4)=16` | PROC 数组，`ops(1)` 取出 `sq` 再 `(4)` 调用，`sq(4)=16` |
| `plus7(10)=10+bias=17` | 闭包捕获全局 `HEAP` 盒 `bias=7`，`10+7=17` |
| `bias 改成 20 后 plus7(10)=30` | 捕获的是引用不是快照，改盒后闭包看见新值 `10+20=30` |
| `作用域规则：...'exported out of its scope'` | 说明捕获局部/形参并导出会触发的运行期错误（本示例故意不触发） |
| `ctr: 1 2 3   ctr2: 1` | 显式 `REF` 传状态：两个独立 `HEAP` 盒各自计数，互不干扰 |
| `curried add(3)(4)=7  add(10)(4)=14` | 用全局 `HEAP` 盒 `k box` 模拟柯里化，`set k` 切换偏值 |

## 8. 坑位清单（实测）

1. **捕获局部量/形参再导出 = 运行期错误 ★**：`PROC adder=(INT k)PROC(INT)INT: (INT x)INT:x+k;`
   把 `adder(5)` 赋给变量，a68g 3.13.3 报
   `warning: potential scope violation from PROC(INT)INT routine-text` +
   `runtime error: PROC(INT)INT value is exported out of its scope`。原因：形参绑定在调用栈帧，
   帧销毁后闭包里的名字悬空；作用域规则要求"routine-text 只能带出寿命不短于它自身的对象"。
2. **要导出闭包，就捕获寿命够长的名字**：全局量、外层 `HEAP` 盒（如 §3 的 `bias`）。捕获它们
   合法，且闭包看到的是**引用**——改盒后闭包随之看到新值（不是快照）。
3. **有状态过程别靠闭包捕获局部**：用"调用方持有 `HEAP` 盒 + 过程接收 `REF` 就地改"的显式传
   状态法（§5 的 `next`/`acc`），既无作用域违规，又能让多个状态实例互不干扰。
4. **柯里化用全局/HEAP 盒模拟**：真正的"内层捕获外层形参"受作用域规则限制无法导出；
   §6 用全局 `k box` + `set k` 切换偏值是可行形态，但 `k` 是全局共享的单一状态。
5. **`PROC` 变量要写全模**：`PROC (INT) INT sq = ...`；数组元素类型 `[1:2] PROC(INT)INT`。
   调用数组里的过程要连写两次括号 `ops(1)(4)`（先取过程、再调用）。
6. **`VOID` 过程调用即语句**：`acc(sum, 5);` 本身是一条语句，无需赋值给谁。

---
上一章：[12 引用与堆](12-refs.md) ｜ 下一章：[14 文件与 transput](14-transput.md) ｜ 返回：[README](../README.md)
