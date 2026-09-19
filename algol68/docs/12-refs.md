# 12 · 引用与堆：REF、HEAP、别名与就地修改

> 示例：[`examples/12_refs/12_refs.a68`](../examples/12_refs/12_refs.a68)
> 运行：`./run-all.sh 12`（或 `cd examples/12_refs && a68g 12_refs.a68`）

上一章的 STRUCT 是**值类型**：赋值即拷贝，两个名字各存一份。本章讲 Algol 68 里让两个名字
**共享同一份数据**的机制——引用 `REF`。围绕它讲清：`LOC`/`HEAP` 在哪开存储、`REF` 别名如何
指向同一个"盒子"、`:=` 在 `REF` 变量上是"重绑"而非"改值"、怎么判断"是不是同一个对象"、用
`REF` 串链表，以及自动垃圾回收。所有代码来自示例，输出逐字节取自本机 `a68g 3.13.3`。

`run-all.sh 12` 双通道验证：check 通道 `a68g --warnings --notices`（解释器，全运行时检查），
release 通道 `a68g -O2`（编译到 C 后端），两条通道 stdout 必须**逐字节一致**，且退出码 0、
stderr 空、含结束标记 `==== 12 结束 ====`。

## 1. LOC 与 HEAP：存储开在哪

```algol68
LOC INT li; li := 5;
print(("LOC INT li = ", whole(li, 0), new line));
HEAP INT h := 7;                          # h 是堆上的 INT 盒，h:=v 改盒里的值 #
h := 8;
print(("HEAP INT h（改成 8）= ", whole(h, 0), new line));
```

- `LOC INT li` 在**当前栈帧**上开一个可变 `INT`。它随所在块（`BEGIN ... END`）结束而失效，
  不能被引用带出块外。
- `HEAP INT h := 7` 在**堆**上开一个 `INT` 盒子，初值 7。堆对象的生命周期由"是否还有引用
  指向它"决定，因此**可以被 `REF` 带出当前块**——这是做链表、导出闭包（第 13 章）的基础。
- 关键：`HEAP INT h` 声明的 `h`，其模是 `INT`（一个绑定到堆盒的名字），所以 `h := 8` 是
  **改盒里的值**。实测输出 `HEAP INT h（改成 8）= 8`。这一点与下面 §3 的 `REF INT` 变量
  的 `:=` 语义截然不同，务必分清。

## 2. REF 是别名：指向同一个盒子

`REF`（reference）是"引用/别名"。多个 `REF` 名字可以指向同一个盒子，改一个另一个也变：

```algol68
REF INT alias := h;                       # alias 和 h 指向同一处 #
print(("alias（指向 h）= ", whole(alias, 0), new line));
alias +:= 2;                              # 通过别名就地 +2，改的是同一个盒子 #
print(("alias +:= 2 后，h = ", whole(h, 0), "  (共享)", new line));
```

- `REF INT alias := h` 让 `alias` 的模是 `REF INT`，它指向 `h` 那个堆盒。
- `alias +:= 2` 是**解引用赋值**：`+:=` 会取出盒里的值、加 2、再写回同一个盒子。因为 `alias`
  和 `h` 共享同一盒，`h` 也随之从 8 变成 10。实测 `alias +:= 2 后，h = 10  (共享)`。
- 这就是引用 vs 值的核心区别：STRUCT 赋值拷贝一份（第 11 章），`REF` 别名共享同一份。

## 3. 坑：对 REF 型变量用 := 是"重新绑定"，不是改盒里的值 ★

```algol68
REF INT r := h;
r := HEAP INT := 99;                      # 重新绑定：r 现在指向一个新盒子 #
print(("r 重绑到新盒 = ", whole(r, 0), "，而原 h 仍 = ", whole(h, 0), new line));
```

- 因为 `r` 的模是 `REF INT`，`r := <右值>` 期望右边**也是一个 `REF INT`**（把 `r` 指向别处），
  而不是改盒里的值。实测直接写 `r := 99` 会报：

  ```text
  error: INT cannot be coerced to REF INT
  ```

- 要"改盒里的值"，用 `+:=` 之类的**解引用赋值**（`r +:= 1`），或干脆把变量声明成
  `HEAP INT` / `LOC INT`（那样 `:=` 就是改值，见 §1）。
- 要"让 `r` 指向别处"，用**重绑**：`r := HEAP INT := 99` 先在堆上开一个新盒、装 99，再把
  `r` 指过去。实测 `r 重绑到新盒 = 99，而原 h 仍 = 10`——重绑**不影响**原盒，`h` 依旧是 10。

一句话记牢：**`REF` 变量上的 `:=` 换指向，`+:=`（及 `val OF ...:=` 等）才换盒里的值。**

## 4. 怎么判断"是不是同一个对象"：靠共享改动，别指望 IS ★

```algol68
REF INT x1 := HEAP INT := 1;
REF INT x2 := x1;                         # x2 与 x1 指向同一个盒子 #
x2 +:= 10;                                # 通过 x2 改 #
print(("x2 +:= 10 后 x1 = ", whole(x1, 0), "  (变 11 说明二者共享同一对象)", new line));
print(("注意：x1 IS x2 实测 = ", (x1 IS x2), "（不可靠，勿依赖）", new line));
```

- `x2 := x1` 让二者指向同一盒；`x2 +:= 10` 把盒里的值从 1 改成 11，`x1` 也读到 11——**共享
  改动**证明它们是同一个对象。实测 `x2 +:= 10 后 x1 = 11`。
- 但 `x1 IS x2` 在 a68g 3.13.3 里对两个用 `:=` 绑定的普通 `REF` 变量**返回 `F`（FALSE）**，
  与实际共享情况矛盾。实测输出：`注意：x1 IS x2 实测 = F（不可靠，勿依赖）`。
- 结论：**`IS`/`ISNT` 在普通 `REF` 变量之间不可靠**，判断"是否同一对象"要靠"改一个看另一个
  是否变"。`IS`/`ISNT` 唯一可靠的用法是**与带模的 NIL 常量比较**（见 §5 链表遍历）。

## 5. 链表：用 HEAP 造节点，用 typed NIL 判尾

```algol68
MODE NODE = STRUCT(INT val, REF NODE next);
REF NODE nil_node = NIL;                  # 带模的 NIL 常量，用来可靠判尾 #
REF NODE n1 := HEAP NODE := (1, nil_node);
REF NODE n2 := HEAP NODE := (2, n1);
REF NODE n3 := HEAP NODE := (3, n2);
val OF n1 := 100;                         # 通过引用改结构字段 #

INT total := 0, cnt := 0;
REF NODE cur := n3;
WHILE cur ISNT nil_node DO                # 用 typed NIL 遍历 #
  total +:= val OF cur;
  cnt +:= 1;
  cur := next OF cur
OD;
print(("链表节点数 = ", whole(cnt, 0), "  值之和 = ", whole(total, 0), new line));
```

- `NODE` 是一个**自引用结构**：字段 `next` 的模是 `REF NODE`，指向下一个节点。
- 每个节点用 `HEAP NODE := (...)` 在堆上造，`next` 字段串起前一个节点：`n3 → n2 → n1 → NIL`。
- `val OF n1 := 100` 是**通过引用改结构字段**：`n1` 是 `REF NODE`，`val OF n1` 解引用后取
  `val` 字段并就地改成 100（原来是 1）。这正是 §3 说的"解引用赋值改盒里的值"。
- **坑（实测）：裸写 `IS NIL` / `ISNT NIL` 在 a68g 3.13.3 里判断不可靠**（实测恒非 NIL）。
  对策是**声明一个带模的 NIL 常量** `REF NODE nil_node = NIL;`，遍历时用
  `WHILE cur ISNT nil_node DO ... OD`，走到尾部时 `cur IS nil_node` 为真。
- 节点值被改成 100 后，链上三节点是 `3 → 2 → 100`（遍历从 n3 起：3、2、100），
  和 = 105。实测 `链表节点数 = 3  值之和 = 105`，自检 `100+2+3=105，遍历 3 个节点` 通过。

## 6. 垃圾回收是自动的

```algol68
BEGIN
  REF NODE tmp := HEAP NODE := (999, nil_node);
  print(("临时节点 val = ", whole(val OF tmp, 0), "（出块后即可被 GC）", new line))
END;
print(("提示：a68g 自动 GC，无需手动释放堆对象", new line));
```

- Algol 68 **没有 `free`/`delete`**：`HEAP` 上不再被任何 `REF` 引用的对象由 a68g 自动回收。
- 让堆对象可被回收的方式：让所有指向它的 `REF` 走出作用域（如上面内层 `BEGIN ... END` 里的
  `tmp`），或把它们重绑到别处（如 §3 的 `r := HEAP INT := 99`）。
- 实测 `临时节点 val = 999（出块后即可被 GC）`，随后打印自动 GC 提示。

## 7. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 12` 中 check 通道的真实 stdout（release 通道逐字节一致）：

```text
LOC INT li = 5
HEAP INT h（改成 8）= 8
alias（指向 h）= 8
alias +:= 2 后，h = 10  (共享)
r 重绑到新盒 = 99，而原 h 仍 = 10
x2 +:= 10 后 x1 = 11  (变 11 说明二者共享同一对象)
注意：x1 IS x2 实测 = F（不可靠，勿依赖）
链表节点数 = 3  值之和 = 105
临时节点 val = 999（出块后即可被 GC）
提示：a68g 自动 GC，无需手动释放堆对象
==== 12 结束 ====
自检全部通过
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| `alias +:= 2 后，h = 10  (共享)` | `alias` 与 `h` 指向同一堆盒，`+:=` 解引用改盒里的值，`h` 同步变 10 |
| `r 重绑到新盒 = 99，而原 h 仍 = 10` | `r := HEAP INT := 99` 是重绑，指向新盒；原盒 `h` 不受影响 |
| `x2 +:= 10 后 x1 = 11` | `x1`、`x2` 共享同一盒（1 → 11），证明是同一对象 |
| `x1 IS x2 实测 = F` | a68g 3.13.3 里 `IS` 对两个 `:=` 绑定的 `REF` 变量不可靠，返回 FALSE |
| `链表节点数 = 3  值之和 = 105` | `val OF n1 := 100` 改字段后，3+2+100=105；`ISNT nil_node` 遍历 3 个节点 |
| `F` | a68g 打印 `BOOL` 用 `T`/`F`（true/false） |

## 8. 坑位清单（实测）

1. **`REF` 变量上的 `:=` 是重绑不是改值**：`REF INT r := h; r := 99` →
   `error: INT cannot be coerced to REF INT`。改盒里的值用 `+:=` 等解引用赋值，或把变量声明成
   `HEAP INT` / `LOC INT`（那样 `:=` 就是改值）。
2. **`IS`/`ISNT` 在普通 `REF` 变量间不可靠**：`x1`、`x2` 明明共享同一盒（改 x2 动 x1），
   `x1 IS x2` 实测返回 `F`。判断同一对象靠"共享改动"，别靠 `IS`。
3. **裸写 `IS NIL`/`ISNT NIL` 不可靠**（实测恒非 NIL）：判尾要声明带模的 NIL 常量
   `REF NODE nil_node = NIL;`，再用 `cur ISNT nil_node`。`IS`/`ISNT` 只有对 typed NIL 才可靠。
4. **`HEAP INT h` 与 `REF INT r` 的 `:=` 语义相反**：前者 `h := v` 改盒里的值（模是 INT），
   后者 `r := v` 重绑（模是 REF INT）。声明方式决定了 `:=` 的含义。
5. **`LOC` 不能被带出块**：栈帧随块结束失效；要让引用带出作用域，用 `HEAP`。
6. **没有手动释放**：无 `free`/`delete`；让 `REF` 走出作用域或重绑，堆对象由 a68g 自动 GC。

---
上一章：[11 结构](11-structures.md) ｜ 下一章：[13 闭包与一等过程](13-closures.md) ｜ 返回：[README](../README.md)
