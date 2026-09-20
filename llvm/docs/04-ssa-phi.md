# 04 · SSA、phi 与 mem2reg

> 对应示例：`examples/04_ssa_phi/`（phi.ll / allocastyle.ll）

SSA（Static Single Assignment，静态单赋值）是 LLVM IR 的灵魂，也是读懂一切 IR 的钥匙。好消息是：概念本身只有两句话；坏消息是：它派生出 `phi` 这个"最像外星语法"的指令。本章用同一个循环的两种写法（手写 SSA vs alloca 风格）对撞，再让 `mem2reg` 当场把后者变成前者——这是全书最有"啊哈感"的一章。

## 4.1 SSA 是什么

两条规则：

1. **每个值只被赋值一次**：`%x = add i32 %a, %b` 之后，`%x` 永远是这个结果，不可改写。
2. **赋值先于使用**：一个值只能被"定义之后"的代码用。

好处是全给优化器的：数据流一目了然，没有"这个变量现在是什么值"的追踪难题——**值即定义，定义即身份**。第 5 章你看到的每个优化奇迹（常量折叠、死代码删除、循环不变量外提），底层都在吃 SSA 的红利。

## 4.2 基本块与控制流

SSA 规则 2 引出**基本块**（basic block）：一段**只能从第一条进入、从最后一条离开**的直线代码。块的最后一条必须是**终结指令**（terminator）：

| 终结指令 | 语义 |
|---|---|
| `ret` | 函数返回 |
| `br label %dest` | 无条件跳转（IR 的 goto） |
| `br i1 %cond, label %a, label %b` | 条件跳转 |
| `switch` / `unreachable` | 多路 / 不可达 |

```llvm
define i32 @clamp(i32 %x) {
entry:
  %c = icmp sgt i32 %x, 100           ; x > 100 ?（sgt=有符号大于）
  br i1 %c, label %hi, label %lo      ; 条件跳转
hi:
  ret i32 100
lo:
  ret i32 %x
}
```

注意：`hi`/`lo` 是**标签**（`%` 前缀的块名），控制流图（CFG）的节点；`br` 是**唯一**改变执行位置的指令——没有 fallthrough，块尾不写终结指令直接报错（`verify` 会抓）。

## 4.3 phi：跨控制流合流的"带来源的值"

矛盾来了：SSA 说"一次赋值"，可循环变量每圈都要变、`if/else` 两支要给同一个变量不同值。**phi 指令**就是解法——它声明"我是谁，取决于我从哪来"：

```llvm
%m = phi i32 [ 值A, %块A ], [ 值B, %块B ]
;     到达本块的前驱若是 %块A，%m 取 值A；若是 %块B，取 值B
```

硬规则（`verify` 挨个查）：

1. **phi 必须是块的第一条指令**（前面只能有其他 phi）；
2. **来源块列表 = 该块的全部前驱**，一个不能多、一个不能少；
3. 来源块必须是**真的**有边到本块（CFG 里的，不是你想象的）。

### 手写一个 SSA 循环

`examples/04_ssa_phi/phi.ll` 的 `sum_to`，逐行标注：

```llvm
define i32 @sum_to(i32 %n) {
entry:
  br label %loop.head

loop.head:                                    ; preds = %entry, %loop.body
  %i   = phi i32 [ 1, %entry ], [ %i.next, %loop.body ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop.body ]
  %cond = icmp sle i32 %i, %n                 ; i <= n ?
  br i1 %cond, label %loop.body, label %exit

loop.body:
  %acc.next = add i32 %acc, %i                ; acc += i
  %i.next = add i32 %i, 1                     ; i++
  br label %loop.head

exit:
  ret i32 %acc
}
```

读 phi 的心智模型：`%i` 在 `loop.head` **入口处**定值——第一圈从 `entry` 来，初值 1；之后每圈从 `loop.body` 来，取上一圈的 `%i.next`。注意 `%i.next` 定义在 `loop.body`、使用在 `loop.head` 的 phi 里——**phi 的使用规则特殊**：引用的是"到达时"的值，不算违反"先定义后使用"（这就是 phi 存在的意义）。

实测：

```text
5050         ; sum_to(100)
0            ; sum_to(0)：cond 第一圈为假，phi 直接带着 [0, %entry] 走 exit
==== 04 ok ====
```

## 4.4 alloca 风格：clang 的策略

手写 phi 累不累？累。所以**真实前端（clang）根本不手写 SSA**——策略是：可变变量先放栈槽，后面交给优化器：

```llvm
; examples/04_ssa_phi/allocastyle.ll 的 sum_to（节选）
entry:
  %i.addr = alloca i32                    ; int i 的栈槽
  %acc.addr = alloca i32                  ; int acc 的栈槽
  store i32 1, ptr %i.addr                ; i = 1
  store i32 0, ptr %acc.addr              ; acc = 0
  br label %loop.cond

loop.cond:
  %i = load i32, ptr %i.addr              ; 用一次 load 一次
  %cond = icmp sle i32 %i, %n
  br i1 %cond, label %loop.body, label %loop.end

loop.body:
  %acc = load i32, ptr %acc.addr
  %acc.next = add i32 %acc, %i
  store i32 %acc.next, ptr %acc.addr      ; acc += i（store 回写）
  %i.next = add i32 %i, 1
  store i32 %i.next, ptr %i.addr          ; i++
  br label %loop.cond
```

"可变变量 = 内存，内存天然可重复写"——SSA 约束被绕开，前端实现简单到爆：**每个变量一个 alloca，读就是 load，写就是 store**。第 13 章我们的 MiniLang 就这么干，第 15 章再升级。

## 4.5 mem2reg：两种风格的自动翻译

`mem2reg` pass 专门做"alloca 风格 → phi 风格"的翻译（术语叫 **promote，提升**）：

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
& "$uc\opt.exe" -passes=mem2reg examples\04_ssa_phi\allocastyle.ll -S
```

（实测输出，`build/04_ssa_phi/allocastyle.mem2reg.ll`）：

```llvm
define i32 @sum_to(i32 %n) {
entry:
  br label %loop.cond

loop.cond:                                        ; preds = %loop.body, %entry
  %acc.addr.0 = phi i32 [ 0, %entry ], [ %acc.next, %loop.body ]
  %i.addr.0 = phi i32 [ 1, %entry ], [ %i.next, %loop.body ]
  %cond = icmp sle i32 %i.addr.0, %n
  br i1 %cond, label %loop.body, label %loop.end

loop.body:
  %acc.next = add i32 %acc.addr.0, %i.addr.0
  %i.next = add i32 %i.addr.0, 1
  br label %loop.cond

loop.end:
  ret i32 %acc.addr.0
}
```

和我们手写的 `phi.ll` **语义完全一致**（连变量顺序都类似，mem2reg 把提升后的值起名为 `槽名.0`）。 `-O1` 及以上级别的管线都自动含 mem2reg——这就是为什么 `clang -O1` 的输出里几乎见不到朴素 alloca，而 `-O0` 满屏都是。

### mem2reg 不是万能的

它只提升"合格的"alloca。这些不提升：

- **地址逃逸**：alloca 的地址被传给别的函数、存进别的内存（clang 对被取地址的局部变量会主动加 `llvm.lifetime` 标记，逃逸则直接不提升）；
- **非一次性的入口块 alloca**：静态分配给可变大小数组（`alloca i32, i64 %n`）；
- volatile 语义的 load/store。

此时优化退到 `sroa`（聚合拆分）+ 局部拷贝传播等组合拳。你在 `-O2` 输出里仍然看到的 alloca，基本都是"真需要内存在场"的（比如按值传参的超大结构体、逃逸缓冲区）。

> **实测坑**：给 `allocastyle.ll` 的某个 alloca 加一行 `%escape = call ptr @escape(ptr %i.addr)`，mem2reg 就跳过它——留下 load/store 和一个 phi 没了。调试 pass 时"为什么这个变量没提升"的答案，九成是地址逃逸。

## 4.6 为什么 IR 选 SSA（而不是像机器码）

| | 机器码（寄存器可重写） | SSA IR |
|---|---|---|
| `x` 现在是什么值 | 要顺着代码追踪 | 值 = 定义，天然明确 |
| 死代码删除 | 需保守分析 | use 链为空即死（第 9 章 Use 详解） |
| 常量折叠 | 每处单独发现 | 定义是常量则处处是常量 |
| 公共子表达式 | 需证明等价 | 同一个 `%v` 就是同一个值 |

phi 到了机器码层会变成什么？寄存器分配器把它落成"前驱块末尾的 mov"（或直接由寄存器合并消掉）——所以你手写 phi 不必担心运行时代价，phi 是**编译期**的账本。

## 4.7 本章小结

- SSA：一值一定义；收益全在优化器；phi 负责跨控制流合流。
- phi 三硬规则：块首、前驱全列、来源真实；读法是"从哪来取哪值"。
- 前端实践：可变变量 = alloca+load+store，mem2reg 自动提升成 phi。
- `-O1+` 自带 mem2reg；提升失败的头号原因是地址逃逸。

| 坑 | 解法 |
|---|---|
| phi 不在块首 | 移到第一条（前面只能有 phi） |
| verify 报 "PHI nodes not grouped at top" | 同上 |
| verify 报前驱数不匹配 | `; preds =` 注释（opt -S 会打印）逐个核对来源 |
| mem2reg 没提升 | 检查地址是否逃逸/非入口块/变长 alloca |
| 手写循环初值错 | sum_to(0) 这种边界用例专门跑一遍（build 脚本里有） |

下一章把优化器整体请出来：`opt` 的 `-O0`…`-O3` 到底做了什么。
