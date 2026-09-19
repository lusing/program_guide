# 09 · 指针与内存

> 对应示例：`examples/09_pointers/`

## 9.1 取址与解引用

```freebasic
Dim x As Integer = 42
Dim p As Integer Ptr = @x     ' @ 取地址
Print *p                      ' 42：* 解引用
*p = 100                      ' 通过指针写回 x
```

指针类型写法 `T Ptr`（`Integer Ptr`、`Double Ptr`、`Point3D Ptr`…）；`Any Ptr` 是无类型指针。UDT 指针用 `->` 访问字段：

```freebasic
Dim pp As Point3D Ptr = @pt
pp->z = 99
```

## 9.2 指针下标：p[i] 是糖

```freebasic
Dim q As Integer Ptr = @arr(0)
q[2]                          ' = *(q + 2)
*(q + 2)                      ' 同一回事
```

**指针运算按元素大小走**：`q + 2` 前进 2 个 `Integer`（16 字节），不是 2 个字节——和 C 一致。

## 9.3 堆内存四件套

| 函数 | 行为 | 对应 C |
|---|---|---|
| `Allocate(n)` | 分配 n 字节，**不清零** | `malloc` |
| `Callocate(num, size)` | 分配并**清零** | `calloc` |
| `Reallocate(p, n)` | 扩容，内容保留，失败返回 0 | `realloc` |
| `Deallocate(p)` | 释放 | `free` |

```freebasic
Dim a As Integer Ptr = Allocate(5 * Sizeof(Integer))
For i As Integer = 0 To 4 : a[i] = i * i : Next
a = Reallocate(a, 8 * Sizeof(Integer))    ' 扩到 8 个，前 5 个还在
Deallocate(a)
```

FB 没有垃圾回收也没有 RAII（12 章的析构函数可以补救一半）——谁分配谁释放，`Reallocate` 返回值要接住（原地失败时旧指针仍有效，返回 0）。

## 9.4 Peek / Poke：按地址裸读写

```freebasic
Poke Integer, @x, 777        ' 把 777 写进 x 的地址
Print Peek(Integer, @x)      ' 777
```

类型显式给出，地址当 `Any Ptr` 用。现代代码里有类型化指针就够了，`Peek/Poke` 留给对接外部缓冲、文件镜像等场景。

## 9.5 Byref 局部变量

```freebasic
Dim ByRef r As Integer = x   ' r 是 x 的别名，必须立即初始化
r += 1                       ' x 变了
```

过程出参之外，FB 也允许局部引用（1.00+）。不能重绑定，就是个别名。

## 9.6 安全网：-exx

- `-exx` 下**空指针解引用**立即中止（退出码 = 错误号），数组越界同理。
- 没开 `-exx` 时解引用空指针 = 未定义行为（多半是段错误）。
- 好习惯：`If p = 0 Then` 判空再动手；`Assert(p <> 0)` 配 `-g`（23 章）。

## 9.7 坑位清单（1.10.1 实测）

1. 指针运算按 `sizeof(元素)` 步进；`p[i]` 与 `*(p+i)` 完全等价。
2. `Allocate` 不清零——要零值用 `Callocate(num, size)`（两参数，与 C 的 calloc 对齐）。
3. `Reallocate` 可能移动内存，返回值必须接回。
4. `->` 只用于 UDT 指针；普通变量用 `.`。
5. `Dim ByRef r As T = x` 必须带初始化式，且不能再指向别人。
