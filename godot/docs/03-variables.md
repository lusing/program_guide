# 03 · 变量与基本类型

> 对应示例：`examples/03_variables/`

## 3.1 示例全文

`examples/03_variables/main.gd`：

```gdscript
extends SceneTree

const MAX_HP := 100

func _initialize():
    var score := 100
    var player_name := "Alice"
    var is_ready := true
    var hp_ratio := 0.75

    var level: int = 3
    level += 1

    print("player_name = ", player_name)
    print("score = ", score)
    print("is_ready = ", is_ready)
    print("hp_ratio = ", hp_ratio)
    print("level = ", level)
    print("MAX_HP = ", MAX_HP)

    # 两种字符串填充方式：% 格式化 与 String.format()（GDScript 4.7 无 {expr} 插值）
    print("玩家 {who} 的分数是 {pts}".format({"who": player_name, "pts": score}))
    print("%s 升到 %d 级" % [player_name, level])
    quit()
```

实测输出：

```text
player_name = Alice
score = 100
is_ready = true
hp_ratio = 0.75
level = 4
MAX_HP = 100
玩家 Alice 的分数是 100
Alice 升到 4 级
```

## 3.2 三种声明姿势

GDScript 声明变量有三种写法，各司其职：

| 写法 | 含义 | 使用场景 |
|---|---|---|
| `var level: int = 3` | 显式类型注解 | 想锁定类型、获得编辑器检查（推荐默认姿势） |
| `var score := 100` | `:=` 类型推断，从初始值推断出 `int` | 初始值类型一目了然时 |
| `var x = some_call()` | 动态类型，无注解 | 返回值类型不定、或懒得标注的局部变量 |

关键区别：带注解（含 `:=`）的变量此后**只能装同类型值**，`score = "abc"` 编译报错；
不带注解的动态变量随便换——`var x = 1` 后 `x = "abc"` 合法，但会失去静态检查。
团队工程里"能注解就注解"，重构时才安全。

`const MAX_HP := 100` 是编译期常量，全脚本可见、不可改。注意 `const` 值必须是编译期
可求值的常量表达式（数字、字符串、内置类型的字面量），不能是函数调用结果。

## 3.3 基本类型一览

示例里出现了四个最常用的：`int`（100）、`String`（"Alice"）、`bool`（true）、
`float`(0.75)。完整的核心类型表：

| 类型 | 字面量示例 | 备注 |
|---|---|---|
| `int` | `42` | 64 位整数；`0x`/`0b` 前缀可用 |
| `float` | `0.75`、`1e6` | 双精度；`1.0` 与 `1` 是不同类型 |
| `String` | `"Alice"`、`'x'`、`r"C:\raw"` | `r"…"` 原始字符串（4.2+） |
| `bool` | `true` / `false` | 条件表达式应写它 |
| `Array` / `Dictionary` | 见第 06 章 | 引用语义 |
| `Vector2` / `Vector2i` | `Vector2(1, -0.5)` | 2D 数学主力（09 章大量使用） |
| `Vector3`、`Color`、`Rect2` 等 | `Color(1, 0.2, 0)` | 引擎几何/颜色类型，均为值语义 |

一个容易惊讶的点：**整数除法**。`7 / 2` 得 `3`（截断），想要 `3.5` 必须让一边是
浮点：`7.0 / 2`。实测：

```gdscript
print("7 / 2 = ", 7 / 2)      # 输出 3
print("7.0 / 2 = ", 7.0 / 2)  # 输出 3.5
```

计算百分比、坐标平均时踩这个坑的人非常多，先记住"斜杠两边的类型决定结果的类型"。

## 3.4 字符串填充：这里没有 f-string

Python 读者会本能地想写 `f"{name} 的分数"` 或 `"{name}"`——**GDScript 不做
字符串插值**。4.2 曾短暂加入 `"…{expr}"` 插值后又从主线移除；4.7.1 实测，这种写法
会**原样输出花括号**：

```gdscript
var player_name := "Alice"
print("玩家 {player_name}")   # 4.7.1 实测输出：玩家 {player_name}
```

静默失败、不报错，只把花括号当普通字符——这是本章最重要的坑。正确的两种姿势
（示例中各演示了一种）：

1. **`%` 格式化**：借鉴 C/Python，占位符 `%s`（任意值）、`%d`（整数）、`%.2f`
   （浮点），右值单值直接给、多值用数组：

   ```gdscript
   print("%s 升到 %d 级" % [player_name, level])
   ```

2. **`String.format()`**：模板里用 `{键名}` 占位，配字典或数组：

   ```gdscript
   print("玩家 {who} 的分数是 {pts}".format({"who": player_name, "pts": score}))
   ```

   `format` 还能直接吃对象：`"HP {hp}".format(player_node)` 会读节点属性——动态
   模板场景（本地化文本、UI 提示）很好用。

`String` 是不可变值类型；拼接用 `+`（两侧都得是 `String`，`"3" + 4` 报错），
数字转字符串用 `str(4)`，字符串转数字用 `int("42")`（解析失败运行时报错）。

## 3.5 类型化变量的转换与检查

```gdscript
var n = "42"
var m := n as int         # 动态上下文的 as int 实测得到 42
print(typeof(m) == TYPE_INT)  # true

var s := str(4)           # "4"
var k := int("42")        # 42
```

`typeof(x)` 返回 `TYPE_*` 枚举值，适合写通用逻辑（比如处理信号里的 `Variant`
参数）；`as` 对内置类型在动态上下文是"转换"（实测 String→int 成功），对对象类型
则是"安全转型，失败得 null"。

## 3.6 坑位清单

1. **`{expr}` 插值不生效且不报错**（4.7.1 实测原样输出）——见到网上教程里的
   `print("HP {hp}")` 直接换成 `format()` 或 `%`。
2. **整数除法截断**：`7 / 2 == 3`；血量百分比 `hp / max_hp` 若两边都是 `int`
   会得 0——写成 `float(hp) / max_hp`。
3. **`:=` 需要初始值**：`var x :=` 非法；想先声明后赋值就必须显式注解
   （`var x: int` 默认 0，`var s: String` 默认空串——类型有默认值，动态 `var x`
   则是 `null`）。
4. **动态变量是检查黑洞**：不注解的变量错传类型只在运行时炸，且 `if 1:` 这类
   非布尔条件在动态上下文里居然能跑——别依赖，条件永远写布尔表达式。
5. **`const` 不等于"引擎编译期求值一切"**：`const START := Vector2(0, 0)` 合法，
   `const START := some_func()` 编译报错。

上一章：[02 · 第一个程序与项目结构](02-hello.md) ｜ 下一章：[04 · 控制流](04-control.md) ｜ 返回：[README](../README.md)
