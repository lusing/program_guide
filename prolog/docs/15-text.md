# 15 · 文本处理

> 对应示例：[`examples/15_text/15_text.pl`](../examples/15_text/15_text.pl)

## 15.1 先接受这件事：Prolog 没有「字符串类型」

其他语言的 `"abc"` 是一个独立的数据类型，有 `length()`、`substr()`、`split()`。
Prolog **没有字符串类型** —— 所谓的「字符串」是**原子**或**字符列表**：

| 写法 | 是什么 | 例子 |
|---|---|---|
| `'abc'` | **原子**（atom） | `atom('abc')` 为真 |
| `"abc"` | **字符码列表**（整数列表） | `[97,98,99]` |
| `['a','b','c']` | **字符列表**（单字符原子列表） | `[a,b,c]` |

```text
'abc'         是原子      -> abc
atom('abc')               -> true
"abc"         字符码列表 -> [97,98,99]
['a','b','c'] 字符列表   -> [a,b,c]
```

**关键：双引号串是「整数列表」，不是原子。** 所以它和原子之间要显式转换：

```prolog
atom_codes(abc, L).      % L = [97,98,99]     原子 -> 码列表
atom_chars(abc, L).      % L = [a,b,c]        原子 -> 单字符列表
atom_codes(A, [97,98,99]).   % A = abc        码列表 -> 原子
```

> **打印双引号串必须用 `~s` 而不是 `~w`。** `~w` 会忠实地把整数列表打出来（`[97,98,99]`），
> `~s` 才会把它当字符串渲染（`abc`）。**这是初学者最常见的输出困惑。**
>
> 本教程所有文件都写 `:- set_prolog_flag(double_quotes, codes).` 就是为了把这件事钉死 ——
> SWI 默认把 `"abc"` 读成**字符串对象**（第三种东西！），GNU 读成**码列表**。不钉死就没法
> 跨引擎对齐。

## 15.2 长度与截取

```text
atom_length(hello)        = 5
sub_atom(hello,1,3,_,S)   S = ell
sub_atom(hello,0,_,2,S)   S = hel（前缀）
sub_atom(hello,_,_,0,S)   S = hello（后缀）
sub_atom(abc,_,1,_,S) 枚举 [a,b,c]
```

`sub_atom/5` 的参数顺序是 **`sub_atom(Atom, Before, Length, After, Sub)`** ——
第 2 个是**起点下标**，第 3 个是**子串长度**，第 4 个是**子串后面还剩多少**。
开始记不清没关系，记两个特例就够：

| 想干什么 | 怎么写 |
|---|---|
| 取**前缀** | `sub_atom(A, 0, N, _, P)`（N = 前缀长度） |
| 取**后缀** | `sub_atom(A, _, _, 0, S)`（后剩 0） |
| 取**中段** | `sub_atom(A, 1, 3, _, S)` |

```prolog
sub_atom(hello, 0, 3, _, P).      % P = hel —— 确实是前缀
```

**`sub_atom/5` 是「关系式」的**：除了最后一参，别的都可以留空让它枚举 ——
`sub_atom(abc, _, 1, _, S)` 会依次给出 `a`、`b`、`c`（所有长度为 1 的子串）。
这是 Prolog 相对其他语言的一个真实优势：**一个谓词同时充当「取子串」和「找子串」。**

**下标从 0 开始，长度单位是「字符」**（在 ASCII 上就是字节）。

## 15.3 拼接与切分：全手写

内置的 `atomic_list_concat/3` 和 `split_string/4` **都是 SWI 专有**，所以本教程全部手写：

```prolog
%% 无分隔符拼接：递归骨架 + atom_concat
join_atoms([], '').
join_atoms([A], A) :- !.
join_atoms([A | T], R) :-
    join_atoms(T, Rest),
    atom_concat(A, Rest, R).

%% 带分隔符的版本
join_with(_, [], '').
join_with(_, [A], A) :- !.
join_with(Sep, [A | T], R) :-
    join_with(Sep, T, Rest),
    atom_concat(Sep, Rest, R1),
    atom_concat(A, R1, R).
```

```text
atom_concat(ab,cd,X)     X = abcd
atom_concat 反向枚举      [pair('',abc),pair(a,bc),pair(ab,c),pair(abc,'')]
join_atoms([a,b,c])      abc
join_with('-', 日期)     2024-09-21
split_on('2024-09-21','-')  [2024,09,21]
split_on(base_case_naming,'_')  [base,case,naming]
```

**`atom_concat/3` 也是关系式的** —— 给它整体，它会枚举所有拆法：

```prolog
findall(pair(P,S), atom_concat(P,S,abc), Splits).
% [pair('',abc), pair(a,bc), pair(ab,c), pair(abc,'')]
```

注意用 `pair/2` 包起来、用 `~q` 打印 —— **空原子 `''` 用 `~w` 打出来是空白，看不见**，
必须用 `~q` 才显示成 `''`。

**按分隔字符切分**（`split_on/3`）：转成字符码列表，在码列表上手工切 —— 完全不依赖引擎
专有谓词，两套引擎上结果**逐字节一致**：

```prolog
split_on(Atom, Sep, Parts) :-
    char_code(Sep, SepCode),
    atom_codes(Atom, Codes),
    split_codes(Codes, SepCode, Parts).

split_codes([], _, []).
split_codes(Codes, Sep, [Part | Rest]) :-
    take_until(Codes, Sep, PartCodes, Remainder),
    atom_codes(Part, PartCodes),
    (   Remainder = [Sep | Tail]      % 找到分隔符 → 继续切剩余部分
    ->  split_codes(Tail, Sep, Rest)
    ;   Rest = []                     % 没找到 → 这是最后一段
    ).
```

## 15.4 字符码与数字互转

```text
char_code(a, C)           C = 97
char_code(C, 98)          C = b
number_codes(123, L)      L = [49,50,51]
number_codes(N, L) 反向   N = 123
digits_of(2026)（手写）   [2,0,2,6]
```

**`char_code/2` 的「字符」参数是单字符原子，不是码列表** —— 别和 `atom_codes/2` 混：

| 谓词 | 处理对象 | 例子 |
|---|---|---|
| `char_code/2` | **单个字符** | `char_code(a, C)` → `C = 97` |
| `atom_codes/2` | **整体字符串** | `atom_codes(abc, L)` → `L = [97,98,99]` |

**手写「整数 → 数字列表」也不用 `number_codes/2`**（虽然它有，但演示一下更好理解）：

```prolog
digits_of(N, Ds) :- digits_rev(N, Rev), reverse(Rev, Ds).

digits_rev(N, [N]) :- N < 10, !.
digits_rev(N, [D | T]) :-
    D is N mod 10,       % 取末位
    N1 is N // 10,       % 去掉末位
    digits_rev(N1, T).
```

这个「取 `mod 10` → 除 `10` → 递归」的模式，就是所有进制转换的核心（第 07 章）。

## 15.5 手写大小写转换

`upcase_atom/2` / `downcase_atom/2` **都是 SWI 专有**。用 `char_code` + `maplist` 自己写：

```prolog
upper_code(C, U) :- C >= 97, C =< 122, !, U is C - 32.
upper_code(C, C).

to_upper(Atom, Upper) :-
    atom_codes(Atom, Codes),
    maplist(upper_code, Codes, Upped),
    atom_codes(Upper, Upped).
```

```text
to_upper(hello)  = HELLO
to_upper('Hello') = HELLO（非字母原样保留）
```

ASCII 里小写 `a`–`z` 是 97–122，大写 `A`–`Z` 是 65–90，**差正好 32**。
所以 `C - 32` 就是转大写。第二个子句兜住所有非小写字母的字符，**原样保留**。

> **「只对 ASCII 有效」不是缺陷，反而是本章的救命稻草** —— 见下一节。

## 15.6 中文：能显示，不能数

这是本教程最实用的一节。**显示中文完全没问题**，两种打法都行：

```text
逻辑编程（用 ~s 打双引号码列表）
逻辑编程（用 ~w 打原子）
```

**但下面这些操作两套引擎结论不同，绝对不能写进可移植代码：**

| 操作 | SWI | GNU |
|---|---|---|
| `atom_length('逻辑编程')` | **4**（Unicode 码点） | **12**（UTF-8 字节） |
| `atom_codes('逻辑', L)` | `[36923,36753]` | `[233,128,187,232,190,145]` |
| `sub_atom('逻辑编程', 1, 2, _, S)` | `辑编` | **半个字符** |

```text
atom_length('逻辑编程')  SWI 给 4（Unicode 码点），GNU 给 12（UTF-8 字节）
atom_codes('逻辑', L)    SWI 给 [36923,36753]，GNU 给 [233,128,187,232,190,145]
sub_atom('逻辑编程',1,2,_,S)  SWI 给「辑编」，GNU 给半个字符
```

**根因**：SWI 的 `atom_length`/`atom_codes`/`sub_atom` 按**码点**计数，GNU 按 **UTF-8 字节**
计数。一个中文字符在 SWI 里是 1 个单位，在 GNU 里是 3 个单位。**不是 bug，是两套设计。**

**唯一安全的操作是「相等判断」**：`'逻辑' == '逻辑'` 成立 —— 因为字节序列一样。

> **工程结论**：
>
> - **中文只用于常量、消息、显示** —— 也就是「原样进出」，不做任何加工。
> - **涉及计数与截取一律用 ASCII。**
> - 真要处理中文，就在宿主语言里做，或**把文本当字节数组、自己规定编码**。
>
> **本教程的做法**：中文全部走常量字面量（注释、`say("...")` 的消息），
> **逻辑全在 ASCII 上跑**。所以你能看到文档和输出里到处是中文，但所有 `sub_atom`、
> `atom_length`、`atom_codes` 的调用都只碰 ASCII。

## 15.7 坑位清单

1. **双引号串用 `~w` 打** → 打出 `[97,98,99]`。要 `~s`。
2. **忘了 `set_prolog_flag(double_quotes, codes)`** → SWI 给字符串对象，GNU 给码列表。
3. **`char_code/2` 当 `atom_codes/2` 用** → 前者只吃**单个**字符。
4. **`sub_atom/5` 参数记成 `(Atom, Start, End, ...)`** → 第 3 个是**长度**不是终点。
5. **空原子用 `~w` 打印** → 看不见。用 `~q`（显示成 `''`）。
6. **对中文调 `atom_length` / `sub_atom`** → 两套引擎结论不同，代码不可移植。
7. **用 `split_string/4`、`atomic_list_concat/3`、`upcase_atom/2`** → SWI 专有。
8. **`join_atoms` 忘了 `[A]` 那个剪枝子句** → 空表元素会多拼出问题。
9. **`atom_concat/3` 当纯函数用** → 它是关系的，参数全空时能枚举出无穷多解。
10. **手写 `to_upper` 期望处理 Unicode** → 只改 ASCII，中文原样返回（这正是安全的做法）。

---

上一章：[14 · 输入输出](14-io.md) · 下一章：[16 · 运算符](16-operators.md)
