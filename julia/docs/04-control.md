# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 if 是表达式：一切皆表达式

```julia
function classify(n::Int)
    if n < 0
        "负数"
    elseif n == 0
        "零"
    else
        "其他"
    end                 # ← if 的值 = 命中分支的值，直接作为函数返回值
end
parity = if iseven(4) "偶" else "奇" end   # 赋值给变量
```

Julia 没有"语句"与"表达式"的鸿沟：if、begin、for 都产出值（for 的值是 `nothing`）。这让你少写临时变量与提前 return。

## 4.2 三元与短路当控制流

```julia
(5 > 3 ? "大" : "小")              # 三元：条件 ? 甲 : 乙
n > 0 && return "正"              # && 当"则"：为真才执行右边
n < 0 || return "零"              # || 当"否则"：为假才执行右边
```

惯用法：`cond && action` 是无 else 的 if；`cond || action` 是"不满足就兜底"。注意 `&&`/`||` 要求两侧是 Bool——`1 && 2` 直接 TypeError（不像 C 返回 2）。按位 `&`/`|` 不短路，逻辑组合数组要用 `.&`/`.|`（10 章）。

## 4.3 while 与 for：遍历一切可迭代物

```julia
i = n
while i > 0
    acc += i
    i -= 1
end

for i in 1:2:9          # start:step:stop（1,3,5,7,9）
    total += i
end
for ch in "abc中文"     # 字符串按 Unicode 码点迭代
for (i, row) in enumerate(eachrow(m))   # 带下标 / 行视图（09 章）
for i in 5:-1:1        # 递减要显式负步长
```

`for x in itr` 对任何可迭代物成立（数组、字典、生成器、通道……）。1:2:9 这类 `AbstractRange` 是惰性的——`collect(1:2:9)` 才落实成数组（11 章）。

## 4.4 break 与 continue——以及"没有 labeled break"

```julia
function firstnegrow(m)         # 找第一个含负数的行号
    for (i, row) in enumerate(eachrow(m))
        hasneg = false
        for v in row
            if v < 0
                hasneg = true
                break           # 只跳出内层
            end
        end
        hasneg && return i      # 外层靠 flag 协调
    end
    return 0
end
```

**Julia 没有 `break outer` 式标签循环**（对比 C++/Zig/Rust）。替代：函数 + 提前 return（首选，如上）、flag 协调、或 `@goto`（4.5）。想清楚"跳出两层"通常说明该抽函数了。

## 4.5 @goto/@label：函数体内的显式跳转

```julia
function collatz_len(n::Int)
    len = 0
    @label loop
    n == 1 && return len
    n = iseven(n) ? n ÷ 2 : 3n + 1
    len += 1
    @goto loop
end
collatz_len(27)     # 111
```

规则：只能**在函数体内**、向前向后都可以、跨函数跳非法。顶层作用域（脚本直接写）用 `@goto` 是语法错误。它是底层代码（生成器、状态机）的工具，业务代码优先结构化写法。

## 4.6 嵌套循环与作用域

```julia
for (i, c) in Iterators.product(1:2, 'x':'y')   # 笛卡尔积
    push!(pairs, (i, c))
end
x = 99
for x in 1:3; end
x == 99          # true——循环变量每次迭代都是新作用域，不污染外层
```

## 4.7 soft scope：顶层赋值的脚本/REPL 双面孔（实测头号坑）

这段代码 REPL 里能跑，脚本里报错：

```julia
total = 0
for i in 1:10
    global total += i     # 脚本（非交互）模式：不加 global 直接 UndefVarError！
end
```

机制：非交互模式下，顶层 `for` 体内对同名全局的**赋值**被视为"新局部变量"（soft scope 规则），`+=` 读未定义局部 → `UndefVarError: total not defined ... Suggestion: check for an assignment to a local variable that shadows a global`。REPL 为了交互方便采用宽松规则，所以同一段代码行为不同。

**正解不是写 `global`**，而是**把逻辑放进函数**（Julia 性能也要求如此，16 章）：

```julia
sumstep(range) = (t = 0; for i in range; t += i; end; t)   # 函数内一切自然
```

本教程示例全部遵守"顶层只做定义与调用"的纪律。

## 4.8 坑位清单

1. **soft scope**：脚本顶层循环里给全局 `+=` → UndefVarError；REPL 却能跑——写函数，别写 `global`（4.7）。
2. **没有 labeled break**：双重循环跳出用"抽函数 + return"（4.4）。
3. **`@goto` 只能在函数内**：顶层写 `@label` 是语法错误（4.5）。
4. **`&&`/`||` 只吃 Bool**：`1 && 2` 是 TypeError；按位 `&`/`|` 不短路（4.2）。
5. **函数要先定义再使用**：顶层代码逐句执行，"先用后定义"在脚本里是 UndefVarError（与 C++ 的前置声明习惯不同）——本教程示例函数一律定义在使用之前。
