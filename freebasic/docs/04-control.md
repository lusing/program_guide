# 04 · 运算符与控制流

> 对应示例：`examples/04_control/`

## 4.1 两套逻辑运算：短路 vs 位运算 ⭐

| 运算符 | 行为 | 用途 |
|---|---|---|
| `AndAlso` / `OrElse` | **短路**逻辑：左边已定结果则右边不求值 | 条件判断（现代写法） |
| `And` / `Or` / `Xor` / `Not` | **位运算**（顺带当非短路逻辑用） | 位操作；QB 风格条件 |

```freebasic
Function check(n As Integer, tag As String) As Boolean
    Print "    check("; tag; ") 被调用"
    Return (n > 0)
End Function

If check(-1, "左") And check(1, "右") Then ...        ' 两次调用：And 两边都算
If check(-1, "左") AndAlso check(1, "右") Then ...    ' 一次调用：左边假即短路
```

从 C 来的注意：`&&`/`||` 的对应物是 `AndAlso`/`OrElse`；直接写 `And`/`Or` 也能出对的结果（非零即真），但**不做短路**——`If p <> 0 AndAlso p->x > 0` 安全，换成 `And` 就空指针了。移位：`Shl`/`Shr`；取反 `Not 0 = -1`。

## 4.2 If 家族

```freebasic
If score >= 90 Then
    ...
ElseIf score >= 80 Then
    ...
Else
    ...
End If

If score > 0 Then Print "单行 If 也合法"
```

## 4.3 Select Case：比 C 的 switch 强

```freebasic
Select Case n
Case 1, 3, 5, 7, 9        ' 枚举多个值
Case 2 To 8               ' 范围
Case Is > 100             ' 关系（Is 代表 n）
Case Else
End Select
```

- 可以 `Select Case` **字符串**（C 的 switch 做不到）。
- 从上到下匹配，命中即出（无 fall-through，不需要 break）。
- `Case Is > 100` 里 `Is` 是占位符，不能写 `Case n > 100`。

## 4.4 循环全家桶

```freebasic
For i As Integer = 5 To 1 Step -2 : ... : Next    ' Step 可负；循环变量自带声明

Do While k < 3 : ... : Loop                       ' 先测后循环
Do : ... : Loop Until k = 0                       ' 先循环后测（至少一次）
While k < 2 : ... : Wend                          ' QB 遗风，等价 Do While
```

`Exit For` / `Exit Do` 跳出；`Continue For` / `Continue Do` 进入下一轮。循环内 `Dim` 的变量每轮重建（块作用域）。

## 4.5 Iif：三元表达式的现代形态

```freebasic
Print Iif(1 = 1, "yes", "no")
```

**1.10.1 实测：只求值选中的分支**——把带副作用的函数放进去，输出来自且仅来自被选中的一支。网上老教程（及 QB 时代记忆）说"Iif 两边都求值"，那是 fbc 1.08 之前的行为，已过时。当然，拿它当 `If` 语句的替代品堆复杂表达式仍然不推荐。

## 4.6 算术运算符速查

| 运算符 | 含义 | 例 |
|---|---|---|
| `\` | **整数除法**（向零截断） | `7 \ 2 = 3`、`-7 \ 2 = -3` |
| `Mod` | 取余 | `7 Mod 3 = 1` |
| `^` | 乘方（浮点语义） | `2 ^ 0.5 = 1.414...`、`2 ^ 10 = 1024` |
| `&` | 字符串拼接 | `"a" & "b"` |

`\` 两边先四舍五入成整数再除（QB 语义）；写整数表达式时没差别。

## 4.7 坑位清单（1.10.1 实测）

1. `And/Or` **不短路**——指针判空必须 `AndAlso`。
2. `Iif` 已是**惰性求值**（1.08+），老教程的"双求值"说法过时。
3. `Not 0 = -1`（位取反）；布尔真是 -1 不是 1。
4. `Select Case` 的关系分支写 `Case Is > 100`，不能 `Case n > 100`。
5. `Print` 分段求值、分段输出：`;` 后面的表达式求值时，前面的文本已经打出来了（副作用函数的输出会插在中间）。
6. `Gosub`/`On Goto`/行号在 `-lang fb` 全部编译错误——那是 22 章的 qb 方言领地。
