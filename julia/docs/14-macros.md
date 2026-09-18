# 14 · 元编程 ⭐

> 对应示例：`examples/14_macros/`
>
> Julia 继承 Lisp 的核心洞察：**代码即数据**。宏是编译期改写代码的正规手段。

## 14.1 Expr：程序是普通值

```julia
ex = :(1 + 2 * 3)          # :() 捕获单个表达式（不求值）
ex isa Expr                # true
ex.head                    # :call——表达式种类
ex.args                    # Any[:+, 1, :(2 * 3)]——参数是 Symbol/值/子 Expr
```

表达式 = `head`（形状）+ `args`（成分）。多行用 `quote ... end`（head 是 `:block`，行号节点混在 args 里）。`:name` 是 Symbol——标识符的"名字值"。

quote 里可以**插值**注入已求值的成分：

```julia
xval = 40
built = :($xval + 2)       # args[2] 是 40（值已代入）
```

## 14.2 eval：把数据变回执行

```julia
eval(:(1 + 2)) == 3
eval(:($xval * 2)) == 80
```

eval 在**当前模块的全局作用域**求值——函数体内慎用（慢且绕过类型推断）。它的主业是构建 DSL 与 REPL/工具链。

## 14.3 宏：Expr 进、Expr 出

```julia
macro twice(ex)
    :($ex + $ex)
end
@twice(21)         # 42
@twice(2 + 3)      # 10——拼接的是表达式：(2+3) + (2+3)
```

宏在**编译前**展开：拿到的是语法树，返回替换后的语法树。对比 C 宏的文本替换——这里操作的是结构化数据（无注入风险、编辑器可导航）。

一个结构完整的宏长这样（注意 `esc`——14.4）：

```julia
macro unless(cond, body)
    quote
        if !($(esc(cond)))
            $(esc(body))
        end
    end
end
ran = false
@unless 1 == 2 begin
    ran = true            # 条件为假才执行
end
```

## 14.4 卫生（hygiene）：宏变量默认隔离

宏展开时，宏内部引入的变量被自动重命名（防与调用处冲突）——这叫卫生。代价：**给调用处变量赋值必须 `esc`**：

```julia
macro setvar(dest, value)
    quote
        $(esc(dest)) = $(esc(value))     # dest/value 都属于调用者的世界
        $(esc(dest))
    end
end
@setvar y 7          # y == 7——真的写进了调用处作用域
```

实测反面教材：`@unless` 不给 `$(esc(body))` 加 esc 时，body 里的 `ran = true` 被卫生改名——赋值丢失、外层 `ran` 纹丝不动。**经验法则：凡"调用者的表达式/变量"一律 esc**；宏自用的临时变量不 esc（让它被隔离）。

## 14.5 变参宏与展开检查

```julia
macro showex(exs...)                        # 收集任意多个参数
    quote
        println("宏收到 $(length($exs)) 个参数")
        $(foldl((acc, e) -> :($acc; $e), exs; init = :nothing))
    end
end
@showex 1 2 3       # 打印计数，返回 3（块表达式拼接）

macroexpand(Main, :(@twice 5))     # 看宏展开成什么（调试宏第一工具）
eval(macroexpand(Main, :(@twice 5))) == 10
```

展开结果含卫生标记（`escape`/`esc` 节点），**直接 `==` 比较通常不成立**——用 `eval` 验语义、用 `occursin` 看形状（实测坑）。

宏调用传参的形式：`@m a b`（空格分隔多参）；`@m a, b` 的逗号版会把 **`(a, b)` 元组当一个参数**传进去（实测 MethodError）——这是与函数调用最大的语法差异。

## 14.6 世界年龄（world age）：正在运行的代码看不见新方法

```julia
function try_call_new()
    @eval new_fn() = 99      # 运行中定义新方法（产生新"世界"）
    new_fn()                 # ❌ MethodError——本函数编译于旧世界
end

function call_via_invokelatest()
    @eval new_fn2() = 99
    Base.invokelatest(new_fn2)   # ✅ 跳到最新世界调用 → 99
end
```

机制：方法表带版本号（world age），运行中的函数锁定在编译时的世界——这是 JIT 一致性的基石，代价是 `eval` 的新定义要 `invokelatest` 才能立刻用。1.12 起全局绑定访问还会打 depwarn（"Detected access to binding ... in a world prior to its definition world"）——看到这警告就想到世界年龄。

实测细节：**重复 `@eval` 同一个定义不产生新世界**——首次定义后的旧世界调用会 MethodError，之后同样的调用反而能成功（方法已存在）。演示时注意这一条。

## 14.7 @generated：按类型生成方法体

```julia
@generated function myzero(::Type{T}) where {T}
    if T <: Number
        :(zero(T))            # 数值类型 → 编译期决定用 zero(T)
    else
        :("无零值")
    end
end
myzero(Int) == 0 && myzero(String) == "无零值"
```

`@generated` 函数的"体"在**首次对该类型调用时**运行（拿到 T），返回的表达式成为该特化的方法体。它是 `@pure`、StaticArrays 式零开销抽象的底层机制——够用即可，别滥用（难调试、限制多）。

## 14.8 坑位清单

1. **卫生吞赋值**：宏展开的 body 里 `x = ...` 不 esc 就被改名丢失——"调用者的东西"一律 `esc`（14.4 实测）。
2. **宏多参用空格不用逗号**：`@setvar y, 7` 传的是元组 `(y,7)` → 方法数不匹配（14.5 实测）。
3. **`macroexpand` 结果别 `==` 比较**：含卫生标记——用 eval 验语义、occursin 验形状（14.5 实测）。
4. **世界年龄**：`@eval` 定义的新方法在"旧世界"调用 MethodError——`Base.invokelatest` 桥接；重复同定义不建新世界（14.6 实测）。
   **1.12+ 还会额外往 stderr 打一条 world-age 警告**（`Detected access to binding ... in a world prior to its definition world`）。
   示例里这两次调用用 `redirect_stderr(devnull)` 圈住——因为"警告"正是本节要演示的现象，
   而验证脚本要求 stderr 为空；真实项目要改代码（用 invokelatest / 别在运行中定义方法），不是靠重定向遮盖。
   另外这条警告**不受 `--depwarn=no` 控制**（实测：加了照样打），别指望用编译开关关掉它。
5. **宏在编译期展开，拿不到运行期值**：`@twice(n)` 拼的是表达式不是 n 的值——需要运行期信息用函数/闭包，不是宏。
