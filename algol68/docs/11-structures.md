# 11 · 结构（STRUCT）与联合（UNION）

> 示例：[`examples/11_structures/11_structures.a68`](../examples/11_structures/11_structures.a68)
> 运行：`./run-all.sh 11`（或 `cd examples/11_structures && a68g 11_structures.a68`）

Algol 68 用 `MODE` 定义**新模（类型）**。把几个字段打包成一个整体，就是 `STRUCT`；
让一个值可以是若干模中的任意一种，就是 `UNION`。本章讲清：怎么用 `MODE STRUCT` 命名
结构类型、用选择符 `OF` 取/改字段、嵌套结构、结构数组、给结构重载运算符，以及 `UNION`
的合规分派。所有代码都来自示例，输出逐字节取自本机 `a68g 3.13.3`。

`run-all.sh 11` 做严格双通道验证：check 通道用 `a68g --warnings --notices`（解释器，
全运行时检查 + 告警），release 通道用 `a68g -O2`（编译到 C 后端的出货形态），两条通道
的 stdout 必须**逐字节一致**，且退出码 0、stderr 空、含结束标记 `==== 11 结束 ====`。

## 1. MODE STRUCT：把几个字段打包成一个新模

```algol68
MODE POINT = STRUCT(INT x, y);          # 同模字段可合并写 INT x, y #
POINT p := (3, 4);
print(("p = (", whole(x OF p, 0), ",", whole(y OF p, 0), ")", new line));
```

- `MODE POINT = STRUCT(INT x, y)` 定义了一个新模 `POINT`，它有两个字段 `x`、`y`，都是
  `INT`。**同模的连续字段可以合并写** `INT x, y`，等价于 `INT x, INT y`。
- `POINT p := (3, 4)` 声明一个 `POINT` 变量 `p`，并用一个**结构初值**（enclosed clause）
  `(3, 4)` 按字段顺序赋值：`x` 得 3，`y` 得 4。
- 输出时 `whole(x OF p, 0)` 把 `INT` 转成字符串：`whole(值, 宽度)`，宽度给 `0` 表示
  **不补空格、按最短位数**输出（第 4 章细讲格式化）。所以 `p = (3,4)`。

## 2. 选择符 OF：取字段，也能就地改字段

`OF` 是 Algol 68 的**选择符**（selector），`字段名 OF 结构值` 取出该字段。取出的字段是
一个可赋值的名字，因此能就地修改：

```algol68
x OF p := 10;
print(("改 x OF p := 10 后，x = ", whole(x OF p, 0), new line));
```

`x OF p := 10` 直接把 `p` 里的 `x` 字段改成 10，输出 `改 x OF p := 10 后，x = 10`。
注意 `OF` 读作"……的"：`x OF p` 就是"p 的 x"。

## 3. 混合字段类型

字段可以是任意模，不必同类型：

```algol68
MODE PERSON = STRUCT(STRING name, INT age, REAL height);
PERSON me := ("Ada", 36, 1.70);
print(("name=", name OF me, "  age=", whole(age OF me, 0),
       "  height=", fixed(height OF me, 0, 2), new line));
```

`PERSON` 有三个不同类型的字段。输出时：

- `name OF me` 是 `STRING`，`print` 直接输出，得 `Ada`；
- `age OF me` 是 `INT`，用 `whole(..., 0)` 得 `36`；
- `height OF me` 是 `REAL`，用 `fixed(值, 整数位宽, 小数位数)`；`fixed(1.70, 0, 2)` 表示
  保留 2 位小数、整数位不补宽，得 `1.70`。

整行实测输出：`name=Ada  age=36  height=1.70`。

## 4. 嵌套结构：OF 可以连写

一个结构的字段本身可以又是结构：

```algol68
MODE RECT = STRUCT(POINT tl, br);
RECT r := ((0, 0), (5, 8));
print(("rect 右下角 = (", whole(x OF br OF r, 0), ",", whole(y OF br OF r, 0), ")", new line));
INT area := (x OF br OF r - x OF tl OF r) * (y OF br OF r - y OF tl OF r);
print(("面积 = ", whole(area, 0), new line));
```

- `RECT` 有两个 `POINT` 字段：`tl`（左上）和 `br`（右下）。初值 `((0,0),(5,8))` 是嵌套的
  结构初值：`tl = (0,0)`，`br = (5,8)`。
- `OF` 可以**连写**：`x OF br OF r` 读作"r 的 br 的 x"，先取 `r` 的 `br`（一个 `POINT`），
  再取它的 `x`。连写从右往左结合。实测 `rect 右下角 = (5,8)`。
- 面积 = 宽 × 高 = `(5-0)*(8-0) = 40`，输出 `面积 = 40`。

## 5. 结构数组

数组的元素可以是结构模。声明时把模写在数组声明里：

```algol68
[1:3] POINT poly := ((0, 0), (4, 0), (0, 3));
print(("第三个顶点 y = ", whole(y OF poly[3], 0), new line));
```

- `[1:3] POINT poly` 是一个下标 1 到 3、元素为 `POINT` 的行（数组）；初值是三个结构。
- `poly[3]` 取出第 3 个 `POINT`，再 `y OF poly[3]` 取它的 `y` 字段，得 `3`。
- 也可以 `x OF poly[2] = 4`（自检断言）。取字段与取下标可自由组合。

## 6. 给结构定义运算符：让它像值类型一样用

可以为自定义模**重载运算符**，让结构支持 `+` 之类的写法：

```algol68
OP + = (POINT a, b) POINT: (x OF a + x OF b, y OF a + y OF b);
POINT p1 := (1, 2), p2 := (3, 4);
POINT sum := p1 + p2;
print(("(1,2)+(3,4) = (", whole(x OF sum, 0), ",", whole(y OF sum, 0), ")", new line));
```

- `OP + = (POINT a, b) POINT: ...` 声明一个作用于两个 `POINT`、返回 `POINT` 的 `+` 运算符；
  运算符体是一个返回结构初值的 routine-text。
- `p1 + p2` 逐字段相加，得 `(1+3, 2+4) = (4, 6)`。

> **坑（实测）：裸写 `(1,2)` 会被当成 COMPLEX，不是 POINT。** a68g 内置了复数模，一个
> 光秃秃的 `(1,2)` 在需要数值时会被解释成 `COMPLEX`。所以要让运算符知道给哪个模重载，
> 必须**先把值声明成 `POINT` 变量**（`POINT p1 := (1,2)`），再参与 `p1 + p2`。直接写
> `(1,2) + (3,4)` 会走复数加法而不是你的 `POINT` 加法。

## 7. 结构赋值与拷贝语义（值类型）

`POINT sum := p1 + p2` 与 `POINT p := (3, 4)` 都是**把结构值绑定到一个新变量**：`sum` 得到
一份独立的 `(4,6)`，与 `p1`、`p2` 互不影响。STRUCT 是**值类型**——赋值是逐字段拷贝，改
`sum` 不会动 `p1`。这与第 12 章的 `REF`（引用/别名，共享同一存储）形成鲜明对照：想让两个
名字共享同一份数据、改一个另一个也变，必须用 `REF`（见 `12-refs.md`）；普通的结构赋值只是
拷贝一份值。就地修改单个字段用选择符 `OF`（`x OF p := 10`），它作用于 `p` 自己的存储。

## 8. MODE UNION：一个值可以是若干模之一

`UNION` 让一个值在若干模中取其一（受约束的动态类型）：

```algol68
MODE NUM = UNION(INT, REAL, STRING);
PROC describe = (NUM u) VOID:
  CASE u IN                            # 合规分派：按当前实际模选分支 #
    (INT    i):  print(("  这是整数 ", whole(i, 0), new line)),
    (REAL   rr): print(("  这是实数 ", fixed(rr, 0, 2), new line)),
    (STRING ss): print(("  这是字符串 [", ss, "]", new line))
  ESAC;
describe(42);
describe(3.5);
describe("hi");
```

- `NUM` 可以装 `INT`、`REAL` 或 `STRING`。调用 `describe(42)` 时，`42` 被自动合规成 `NUM`
  的 `INT` 分支。
- **`CASE ... IN ... ESAC` 是合规分派**：按 `u` 当前的实际模选择分支，并把该分支的值绑定到
  模式变量（`i`/`rr`/`ss`）供分支体使用。每个分支之间用逗号分隔。

实测输出：

```text
UNION 分派：
  这是整数 42
  这是实数 3.50
  这是字符串 [hi]
```

`UNION` 也能被断言——用 `CASE` 取出当前分支的值：

```algol68
PROC as_int = (NUM u) INT:
  CASE u IN
    (INT i): i,
    (REAL rr): ENTIER rr,        # ENTIER 取实数的整数部分（截断） #
    (STRING ss): 0
  ESAC;
assert(as_int(42) = 42, "INT 分支取值");
assert(as_int(3.9) = 3, "REAL 分支截断");
```

`as_int(3.9)` 走 `REAL` 分支，`ENTIER 3.9 = 3`（向零截断）。

> **坑（实测）：a68g 没有独立的 `IS` 布尔合规测试。** 写 `u IS (INT)` 是语法错。要判断联合
> 当前是哪个模，**只能用 `CASE ... IN ... ESAC` 分派**——在每个分支里你已经知道它是哪个模。
> 别指望有一个返回 `BOOL` 的"是不是 INT"测试。

## 9. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 11` 中 check 通道的真实 stdout（release 通道逐字节一致）：

```text
p = (3,4)
改 x OF p := 10 后，x = 10
name=Ada  age=36  height=1.70
rect 右下角 = (5,8)
面积 = 40
第三个顶点 y = 3
(1,2)+(3,4) = (4,6)
UNION 分派：
  这是整数 42
  这是实数 3.50
  这是字符串 [hi]
提示：判断 UNION 实际模用 CASE 分派，无独立 IS 布尔测试
==== 11 结束 ====
自检全部通过
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| `p = (3,4)` | `whole(x OF p, 0)` 宽度 0 → 不补空格，`3` 和 `4` 直接拼进字符串 |
| `name=Ada  age=36  height=1.70` | `fixed(1.70, 0, 2)` 保留 2 位小数 → `1.70`；`STRING` 字段直接输出 |
| `rect 右下角 = (5,8)` | `x OF br OF r` / `y OF br OF r` 连写选择符取出嵌套字段 |
| `面积 = 40` | `(5-0)*(8-0) = 40` |
| `(1,2)+(3,4) = (4,6)` | 重载的 `OP +` 逐字段相加（先声明成 `POINT` 变量才走这个重载） |
| `这是实数 3.50` | `fixed(rr, 0, 2)` 把 `3.5` 格式化成 2 位小数 |
| `自检全部通过` | `fails = 0`，所有 `assert` 未触发；否则打印 `自检失败 N 项` 并非 0 退出 |

## 10. 坑位清单（实测）

1. **裸写 `(1,2)` 会被当成 COMPLEX**：a68g 内置复数模，光秃秃的 `(1,2)` 在数值上下文按
   `COMPLEX` 解释。要用自定义结构的运算符，先把值声明成该模变量（`POINT p1 := (1,2)`）。
2. **没有独立的 `IS` 布尔合规测试**：`u IS (INT)` 语法错；判断 `UNION` 实际模只能用
   `CASE ... IN ... ESAC` 分派。
3. **同模字段合并写**：`STRUCT(INT x, y)` 等价于 `STRUCT(INT x, INT y)`；别漏掉合并写法
   导致以为 `y` 没类型。
4. **`OF` 从右往左连写**：`x OF br OF r` 是"r 的 br 的 x"，不是"x OF br 再 OF r"的左结合。
5. **格式化宽度**：`whole(v, 0)` 不补宽；`fixed(v, 0, 2)` 保留 2 位小数（`3.5` → `3.50`）。
   宽度非 0 时会补空格，拼接时留意。
6. **STRUCT 是值类型**：赋值逐字段拷贝、互相独立；想共享同一份数据要用第 12 章的 `REF`。

---
上一章：[10 数组与行](10-arrays.md) ｜ 下一章：[12 引用与堆](12-refs.md) ｜ 返回：[README](../README.md)
