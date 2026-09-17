# 12 · 异常与错误处理哲学

> 对应示例：`examples/12_errors/`

## 12.1 三类异常

```erlang
erlang:error({bad_input, X}).   %% error：代码 bug / 参数违反契约——让它崩
exit(shutdown).                 %% exit：这个进程该结束了（进程级信号）
throw(early_return).            %% throw：非本地返回，只在本进程内
try F() catch Class:Reason:Stack -> ... end.   %% 三类都能这样接
```

选择原则：**调用方能处理的失败不抛**，返回 `{ok,_} | {error,_}`；调用方用不了的违反契约才 `error`；跨进程是 `exit` 的活。

## 12.2 catch 的两个陷阱

- **省略 Class 默认接 throw**：`catch R -> ...` 只接 throw 类，error/exit 直接穿透崩进程——永远写 `Class:Reason` 或 `_:Reason`；
- **`catch Expr` 已废弃**（OTP 29 编译即警告，`-Werror` 失败）：它把三类压成三种不同形状的值，一律改 `try`。

## 12.3 after 与 stacktrace

`after` 无论正常/异常都执行（清理资源的唯一位置）。`catch Class:Reason:Stack` 的第三段是栈，**冒号后直接跟变量**（写 `[...]` 是语法错误）；第一帧就是出错函数。重抛时把 Stack 交给 `erlang:raise/3`，否则调用方丢栈。

## 12.4 maybe 表达式

```erlang
classify(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true ?= (N >= 0),        %% 必须 ?=，普通 = 失败会穿透 else
        {non_negative, N}
    else
        {error, R} -> {error, R};
        false -> {error, negative};
        Other -> {error, {unexpected, Other}}   %% else 也要兜底
    end.
```

三条实测语义：① 只有 `?=` 失败才走 else，else 匹配**失败值本身**；② body 里普通 `=` 的 badmatch **穿透** else（实测 `{error,{badmatch,false}}`）；③ else 全不匹配抛 `else_clause`。

## 12.5 Reason 全表（实测）

| Reason | 场景 | 形状 |
|---|---|---|
| `badarg` | `list_to_integer("abc")` | 裸原子 |
| `badarith` | `1/0`（无 inf！） | 裸原子 |
| `badmatch` | `{ok,X} = {error,1}` | **带触发值** |
| `function_clause` | 参数没有匹配子句 | 带实参 |
| `undef` | 调不存在的函数 | `{M,F,A}` |
| `case_clause` / `if_clause` / `try_clause` | 分支没兜底 | 带触发值 |
| `badmap` / `badkey` | 非 map / 缺键 | `{badmap,X}` `{badkey,K}` |
| `system_limit` / `timeout_value` | 资源上限 / 超时为负 | 裸原子 |

> `-Wall` 会在**编译期**点死常量版的这些错误（`-Werror` 直接编不过）——想演示运行期错误，输入必须来自参数或 opaque 函数。

## 12.6 let it crash：崩了能被看见

```erlang
{_Pid, Ref} = spawn_monitor(fun() -> crash(Kind) end),
receive {'DOWN', Ref, process, _, Reason} -> ... end.
```

DOWN 的 Reason：error 类 → `{Reason0, Stacktrace}`（**带栈**）；未捕获 throw → `{{nocatch, V}, Stack}`；exit 类 → Reason 原样（无栈）。默认 logger 自动上报 error 类崩溃（exit 类一律不报）——监督树重启的就是这些被看见的崩溃（16 章）。

## 12.7 坑位清单

1. **`catch _:_ -> ok` 吞一切**：把 bug 变成静默返回值——只在最外层边界（HTTP handler 出口）规整成 `{error,_}`。
2. **catch 省略 Class 默认 throw**：error 类根本接不住，进程照崩。
3. **maybe 里普通 `=` 不走 else**：想拦断言必须写 `?=`。
4. **else 没兜底子句**：抛 `else_clause`——和 case/if 一样的纪律。
5. **重抛丢栈**：`raise(Class, Reason, Stack)` 三参都要带，否则排障只能看到包装层。
6. **可预期失败别抛异常**：文件不存在、解析失败——返回 `{error,_}` 让调用方分支处理。

---
