# 22 · ⭐方言模式：-lang fb / fblite / qb

> 对应示例：`examples/22_langs/`——`22_langs.bas`（fb 方言）+ `legacy_qb.bas`（**`-lang qb` 第三验证通道**）

## 22.1 一个编译器，三种性格

| | `-lang fb`（默认） | `-lang fblite` | `-lang qb` |
|---|---|---|---|
| 定位 | 现代 FB | 过渡 | QBASIC 兼容 |
| 变量声明 | 必须 `As` / `Var` | 可省（默认类型） | 隐式变量 + `DEFINT` |
| 变量后缀 `x% s$` | **编译错误** | 允许 | 允许 |
| 行号 / `Goto` / `Gosub` | **编译错误** | Goto 允许，Gosub 允许 | 全家桶 + `On..Goto/Gosub` |
| `AndAlso/OrElse` | 有 | 无 | 无 |
| 字符串比较 | **区分大小写** | 不区分 | 不区分（沿袭 QB） |
| 作用域 | 块级 | 过渡规则 | 过程级 |

选型一句话：**新代码一律 `-lang fb`**；qb 方言只为两件事存在——编译 30 年前的 QB 代码、感受历史。

## 22.2 qb 方言现场（legacy_qb.bas 实测）

```freebasic
10 DEFINT A-Z                        ' A-Z 开头的变量默认 Integer
20 LET x = 5                          ' 隐式变量 + LET
30 PRINT "QB 方言模式：x ="; x
40 GOSUB 1000                         ' 跳子程序
1010 RETURN                           ' 回到 GOSUB 的下一行

50 ON x GOTO 200, 300, 400            ' x=5 超出目标数 → 不跳转，继续 60 行
80 ON y GOSUB 2000, 3000              ' y=1 → 调 2000 号子程序
```

实测语义：`ON var GOTO/GOSUB` 的 var **超出目标列表就当没看见**（不报错、不跳转）——QB 时代的防御性设计。`GOSUB/RETURN` 是"同函数内跳转子程序"：没有参数、没有局部变量隔离，全靠共享变量——这就是结构化编程出现前的世界。

## 22.3 迁移路线（老 QB 工程 → 现代 FB）

```text
-lang qb 编过 ──→ 去行号/改 Gosub 为 Sub ──→ -lang fblite ──→ 显式类型补全 ──→ -lang fb
```

每一步都可编译可运行——fbc 让你**增量现代化**而不是重写。实战要点：

1. 行号先换成标签（`gosub clear_screen:` 形式），`GOSUB` 换成真正的 `Sub`；
2. 隐式变量全数补 `Dim ... As`（`DEFINT A-Z` 的默认类型规则先人肉展开）；
3. 大小写不敏感的字符串比较（`IF s$ = "YES"`）要包 `UCase()`；
4. 后缀变量（`count%`）去掉后缀补类型；
5. `ON ERROR GOTO` + `RESUME` 体系换返回码（15 章）。

## 22.4 -forcelang：不改源文件的方言覆盖

```bash
fbc -forcelang qb legacy.bas      # 无视源文件里的 #lang 声明
```

源文件里也能自报方言：`#lang "qb"`（首行）——`.bas` 带着"母语"标记，fbc 混合编译多方言文件。

## 22.5 坑位清单（1.10.1 实测）

1. `Gosub` 在 `-lang fb` 直接编译错（"Only valid in -lang fblite or qb"）——别在 fb 工程里手滑。
2. `Resume Next` 只在 qb/fblite/deprecated 合法（15 章错误处理主坑）。
3. qb 方言的字符串比较**不区分大小写**，fb 区分——迁移时最容易静默出错的点。
4. `DEFINT A-Z` 的隐式类型规则只认变量首字母，与现代 `As` 声明混用时优先看显式声明。
5. `-lang qb` 下 `Print` 布尔/数字格式与 fb 相同（实测 zero-init 也一样清零）——方言差异集中在**声明与控制流**，不在运行库。
