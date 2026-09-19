# 10 · 预处理器与宏

> 对应示例：`examples/10_preprocessor/`

## 10.1 FB 的预处理器

fbc 自带预处理器，指令以 `#` 开头：`#define`、`#macro`、`#if/#ifdef/#ifndef/#else/#endif`、`#include`、`#inclib`。**没有 C 的宏函数高级玩法之外的限制**——FB 宏甚至更猛（`#macro` 多语句）。

## 10.2 #define：对象式与函数式

```freebasic
#define MAX_ITEMS 5                        ' 对象式：编译期常量
#define SQ(x) ((x) * (x))                  ' 函数式：括号！括号！括号！
SQ(1 + 2)                                  ' ((1+2)*(1+2)) = 9
```

函数式宏的参数**无类型、纯文本替换**——两边加括号是保命符。带副作用的参数会被求值多次：`SQ(i++)` 里 `i` 加两次。

## 10.3 #macro：多行宏 ⭐

FB 特色：宏体可以跨语句、跨行，直到 `#endmacro`：

```freebasic
#macro MAX3(a, b, c, result)
    If (a) >= (b) AndAlso (a) >= (c) Then
        result = (a)
    ElseIf (b) >= (c) Then
        result = (b)
    Else
        result = (c)
    End If
#endmacro

Dim m As Integer
MAX3(3, 9, 5, m)                ' m = 9
```

注意 `#macro` 展开处会引入宏体内的 `Dim`——**不能在宏里声明再在宏外用**，变量要从参数传进去（上面的 `result` 模式）。

## 10.4 # 字符串化：调试打印神器

```freebasic
#macro SHOW(e)
    Print "  " & #e & " = "; e
#endmacro

SHOW(2 ^ 10)                   '   2 ^ 10 =  1024
```

`#e` 把实参变成字符串。**与 C 不同：FB 会先展开参数里的宏再字符串化**（`SHOW(SQ(5))` 打出 `((5) * (5)) = 25`，C 的 `#` 会打出 `SQ(5)` 字面）。

## 10.5 条件编译与内置宏

```freebasic
#If VERBOSE
    ...
#else
    ...
#endif

#ifdef __FB_WIN32__     ' Windows 平台
#ifdef __FB_64BIT__     ' 64 位目标
#if __FB_VER_MAJOR__ = 1
Print __FILE__          ' 当前文件名
```

常用内置宏：`__FB_WIN32__/__FB_LINUX__`、`__FB_64BIT__/__FB_32BIT__`、`__FB_VER_MAJOR__/__FB_VER_MINOR__`、`__FILE__`、`__FUNCTION__`、`__LINE__`（配合 `-g` 断言输出用）。调试开关、平台分支、版本守卫都靠它们。

## 10.6 #include 与 #inclib

```freebasic
#Include Once "mod_counter.bi"    ' 头文件（11 章主菜）
#inclib "mylib"                  ' 链接 mylib.dll/a（20 章）
```

`Once` = include guard；没有 `Once` 的重复包含会重复声明直接报错。

## 10.7 坑位清单（1.10.1 实测）

1. 函数宏参数是文本替换：括号不全 = 表达式惨案；参数带副作用会多次求值。
2. `#macro` 体内的 `Dim` 只活在展开块里——结果变量走参数传出。
3. `#e` 字符串化**先展开宏参数**（与 C 相反）。
4. `#if` 的条件是**整数常量表达式**，不能放运行期变量。
5. `__FILE__` 给的是文件名字符串（相对编译时路径），`__LINE__` 要 `-g` 才准确。
