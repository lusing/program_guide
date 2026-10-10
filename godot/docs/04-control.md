# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 示例全文

`examples/04_control/main.gd`：

```gdscript
extends SceneTree

func _initialize():
    var value := 10
    if value > 5:
        print("value 大于 5")
    elif value == 5:
        print("value 等于 5")
    else:
        print("value 小于 5")

    for i in range(3):
        print("i = ", i)

    var inventory := ["剑", "盾", "药"]
    for item in inventory:
        print("携带：", item)

    var count := 0
    while count < 3:
        print("count = ", count)
        count += 1

    var state := "attack"
    match state:
        "idle":
            print("待机")
        "attack", "skill":
            print("进入攻击流程")
        _:
            print("未知状态")

    for e in range(10):
        if e == 3:
            continue
        if e == 6:
            break
        print("e = ", e)
    quit()
```

实测输出：

```text
value 大于 5
i = 0
i = 1
i = 2
携带：剑
携带：盾
携带：药
count = 0
count = 1
count = 2
进入攻击流程
e = 0
e = 1
e = 2
e = 4
e = 5
```

## 4.2 缩进即语法

GDScript 与 Python 同族：**缩进定义代码块**，没有大括号。行尾冒号开启块，块内统一
缩进（官方风格指南推荐 Tab；本教程示例统一 4 空格——同一文件里绝不能混用，混用是
编译错误，且报错信息指向"下一个 dedent"处，离真正写错的位置常常很远）。

`if` 体不能与条件同行：`if x: print(1)` 非法，必须换行缩进。`elif`（不是 `else if`）。

## 4.3 for-in：唯一的花名册

GDScript 4 没有 C 式 `for (i = 0; i < n; i++)`，只有 `for x in 可迭代物`：

- `for i in range(3)` → 0、1、2。`range` 家族：`range(3)` 从 0、`range(1, 4)` 含头
  不含尾、`range(3, 0, -1)` 倒序（第 10 章倒计时就用它）。
- `for item in array` / `for key in dictionary`（字典迭代**键**，见 06 章）。
- 需要下标时：`for i in inventory.size()`？不行——`int` 不是可迭代物，写
  `for i in range(inventory.size())`，或 `for i, item in enumerate(inventory)`？也
  没有 `enumerate`——GDScript 用 `for i in range(n)` 手动取 `inventory[i]`。习惯
  C/Python 的读者在这里会有小小的翻译开销。

## 4.4 match：结构化的开关 + 迷你模式匹配

`match` 类似其他语言的 switch，但**默认不贯穿**（没有 fall-through，不需要 break），
且 case 模式按**从上到下第一个命中**生效，顺序即优先级。4.1 示例演示了字符串模式、
一行多模式（`"attack", "skill":`）和通配 `_`。它的完整能力（4.7 实测均可用）：

```gdscript
match [hp, mp]:              # 元组式多值匹配：把多个量打包成一个"结构"
    [0, 0]:
        print("双空")
    [var h, var m] when h > m:   # 守卫：命中模式后再验布尔条件
        print("血多蓝少")
    [_, _]:
        print("其余组合")
```

- 数组/字典模式按**结构**匹配，`var h` 在模式内绑定值；
- `when` 守卫（4.2+）给模式追加布尔条件，守卫不通过会继续尝试下一条——比嵌套
  if 清晰得多；
- 没有 `default` 关键字，用 `_`。**4.7.1 实测：未命中任何模式时静默跳过整条
  match**（不报错）——想要"必须穷尽"的保障，自己写兜底分支：

  ```gdscript
  match state:
      "idle": …
      "run": …
      _:
          push_error("未处理的状态: %s" % state)
  ```

游戏状态机是 match 的主场：`match state: "idle": … "run": …` 替代长 if-elif 链。

## 4.5 continue / break

与 C 家族同义，示例输出里 `e` 跳过 3（continue）、在 6 前终止（break）。补充一点：
`while true:` + `break` 是 GDScript 里"未知次数循环"的惯用形——没有 do-while。

## 4.6 布尔语境：条件该写布尔

对注解过的变量，类型检查严格（`var ok: bool = 1` 编译错误）；但对动态变量
（`var ok = 1`），4.7.1 实测 `if ok:` **照样运行**——非 0、非空、非 null 即真。
结论：语言层面"能跑"，工程层面别依赖——条件永远显式写成比较表达式，静态检查
才能兜住你。空数组/空字典按 false 处理倒是可以放心的惯用法（`if inventory.is_empty():`
更显式，推荐）。

## 4.7 坑位清单

1. **Tab/空格混用**：编译错误指向远端行——开工先定死一种（官方 Tab）。
2. **match 未命中静默跳过**（4.7.1 实测）：忘写 `_` 兜底的 bug 不会有任何提示——
   关键逻辑的 match 一律显式写兜底分支并 `push_error`。
3. **`range(n)` 不含 n**：`for i in range(arr.size())` 安全；手写 `range(1, arr.size())`
   会漏掉最后一个元素，想包含写 `range(1, arr.size() + 1)` 或 `arr.size() - 1` 端点。
4. **match 按顺序命中**：`_` 或宽模式写前面，后面的窄模式永不可达，且没有警告。
5. **整数条件在动态上下文静默通过**（4.6）：代码评审时盯紧"非布尔条件"。

上一章：[03 · 变量与基本类型](03-variables.md) ｜ 下一章：[05 · 函数](05-functions.md) ｜ 返回：[README](../README.md)
