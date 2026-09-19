# 14 · 运算符重载

> 对应示例：`examples/14_operators/`

## 14.1 成员 vs 全局：谁是左手边

| 运算符 | 放哪 | 原因 |
|---|---|---|
| `+`、`-`、`*`、`=`、`<>` 等双目 | **全局 Operator**（至少一个形参是你的 UDT） | 左右手都可以是任意类型 |
| `+=`、`-=`、`*=` 等复合赋值 | **必须成员**（error 152 实测） | 会改左手边 |
| `Cast`、`Let`（赋值）、`For/Step/Next` | **必须成员** | 绑定在本类型上 |

```freebasic
Type Vec
    Dim As Double x, y
    Declare Operator Cast() As String       ' 成员：转字符串
    Declare Operator += (ByRef rhs As Vec)  ' 成员：复合赋值
End Type

Operator + (ByRef a As Vec, ByRef b As Vec) As Vec   ' 全局：双目加
    Return Vec(a.x + b.x, a.y + b.y)
End Operator
```

## 14.2 Cast：让 UDT 直接可打印

```freebasic
Operator Vec.Cast() As String
    Return "(" & Format(x, "0.0#") & ", " & Format(y, "0.0#") & ")"
End Operator

Print "v1 + v2 = "; sum      ' Print/字符串拼接自动走 Cast
```

`Cast` 可以声明多个目标类型（重载）。有它就不必为打印写 `toString()` 方法。

## 14.3 标量乘法要两个方向

```freebasic
Operator * (ByRef a As Vec, k As Double) As Vec     ' Vec * 3
Operator * (k As Double, ByRef a As Vec) As Vec     ' 3 * Vec
```

运算符重载不做交换律——左手边是标量时那个方向要单独定义。

## 14.4 For / Step / Next：让自定义类型吃 For 语法 ⭐

FB 独门：实现三个运算符，你的类型就能进 `For ... To ... Next`：

```freebasic
Type Range
    Dim As Integer i, limit_
    Declare Operator For ()                            ' 循环开始：初始化
    Declare Operator Step ()                           ' 每轮步进（Step 子句另有一版带参）
    Declare Operator Next(ByRef endCond As Range) As Integer   ' 返回"继续否"
End Type

For r As Range = Range(1, 0) To Range(0, 4)
    Print r.i                          ' 1..4
Next
```

带 `Step 2` 的循环用 `Declare Operator Step (ByRef stepVal As Range)` 的带参重载。这是把"迭代器协议"焊进语言的老派做法——现代语言用迭代器接口，FB 用运算符，效果等价。

## 14.5 亲踩现场：字段与形参同名

```freebasic
Constructor Range(i_ As Integer, limit_ As Integer)
    i = i_
    limit_ = limit_        ' BUG：形参 limit_ 遮蔽字段 limit_，这是参数自赋值！
End Constructor
```

上面这个构造器编译零警告，但字段 `limit_` 永远是 0——我的 `For` 迭代因此一轮都没跑，被断言层当场抓获。正确写法：

```freebasic
This.i = i_
This.limit_ = limit_
```

**教训**：构造器/运算符里给字段赋值，永远 `This.` 前缀；`-w all` 也抓不住这类逻辑错，断言层（`-g -exx` + Assert）才是防线。

## 14.6 坑位清单（1.10.1 实测）

1. `+=` 等复合赋值必须是**成员** Operator（全局版 error 152）。
2. 标量在左的乘法（`3 * v`）要单独定义一个反向全局 Operator。
3. `Cast()` 成员才合法；可多目标重载。
4. `For/Step/Next` 三件套都在成员侧；无 Step 子句时调无参 `Step()`。
5. **字段与形参同名 → 自赋值静默通过**——`This.` 前缀保平安（亲踩，断言抓获）。
6. 重载 `=` 要的是 `Operator = (a, b) As Boolean`（比较），不是赋值——赋值是 `Let`（成员）。
