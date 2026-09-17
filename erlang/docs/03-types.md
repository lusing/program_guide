# 03 · 数值与基本类型

> 对应示例：`examples/03_types/`

## 3.1 整数没有上限

```erlang
1 bsl 64.                       %% 18446744073709551616 —— 没有 int64 溢出这回事
length(integer_to_list(1 bsl 128)).  %% 39：2^128 有 39 位十进制
```

整数是**任意精度**的，不存在溢出，只有"变慢"。阶乘、大数幂、位图掩码都直接算。

## 3.2 字面量：进制、下划线与 $ 字符

```erlang
16#FF.        %% 255   Base#Value，最大 36 进制
2#1010.       %% 10
1_000_000.    %% 1000000（下划线只是分隔符）
$A.           %% 65    $X 取字符的**码点**（$中 = 20013）
1.5e3.        %% 1500.0
```

## 3.3 div / rem 一律向零截断

```erlang
-7 div 2.     %% -3   不是 -4！
-7 rem 2.     %% -1   余数符号跟随**被除数**（同 C，反 Python）
7 / 2.        %% 3.5  / 永远返回浮点，整除用 div
1 div 0.      %% 抛 badarith（不是返回 0，也不是 inf）
```

恒等式自检：`N =:= (N div D)*D + (N rem D)` 永远成立。想给周期性序列取模（结果同除数符号）得自己写 `(N rem D + D) rem D`。

## 3.4 浮点：溢出是 badarith，不是 inf

```erlang
0.1 + 0.2.            %% 0.30000000000000004（IEEE 754 通病）
1.0e308 * 10.         %% 抛 badarith —— Erlang 没有 inf/nan！
float_to_binary(0.1, [short]).   %% <<"0.1">> 最短往返表示
```

**Erlang 没有 `inf` / `nan`**，浮点溢出与非法运算一律抛 `badarith`。涉及金额用整数（分）。

## 3.5 取整家族

| 函数 | 语义 | `round(±2.5)` |
|---|---|---|
| `round/1` | 四舍五入，**.5 远离零** | `3` / `-3` |
| `trunc/1` | 向零截断 | `2` / `-2` |
| `floor/1` | 向下 | `2` / `-3` |
| `ceil/1` | 向上 | `3` / `-2` |

另有一条隐蔽 badarg：`io_lib:format("~.0f", [2.5])` 不合法——**浮点精度不能写 0**，要整数结果用 `~.0B` 或先取整。

## 3.6 两套比较与全序

```erlang
1 == 1.0.    %% true  算术比较（整数提升为浮点再比）
1 =:= 1.0.   %% false 精确比较（类型也要相同）——默认用这套
```

Erlang 还有**全序**（任何两个 term 都能比）：`number < atom < reference < fun < port < pid < tuple < map < nil < list < bit string`。所以 `1 < a` 是 true，`lists:sort([b,1,a,"x",3.0])` 得 `[1,3.0,a,b,"x"]`。

## 3.7 原子：字面量、原子表与安全转换

```erlang
hello.             %% 小写开头不用引号
'Hello'.           %% 大写开头、含空格/连字符/中文 → 必须引号
'03_types':safe_atom("hello").
%% {ok,hello}：list_to_existing_atom 只命中已存在的原子
'03_types':safe_atom("no_such_thing").
%% {error,not_existing}：不创建新原子
```

原子比较是常数时间；但**原子表不被 GC**（上限 `erlang:system_info(atom_limit)`，默认 1048576），打满即节点被杀。铁律：**永远不要拿外部输入 `list_to_atom`**——用 `list_to_existing_atom`（不存在就 badarg，不会创建）。

## 3.8 坑位清单

1. **`/` 返回浮点**：`5 / 2` 是 `2.5`；要整数商必须 `div`。
2. **`rem` 符号跟被除数**：`-7 rem 2 = -1`，从 Python 过来的最容易写错周期取模。
3. **浮点溢出抛 badarith**：写科学计算先想好边界；没有 inf 可比较。
4. **`~.0f` 是 badarg**：精度 0 的浮点格式串不合法（02 章格式串的延伸坑）。
5. **`list_to_atom` 打爆原子表**：外部输入一律 `list_to_existing_atom` + 白名单。
6. **`==` 抹平类型**：`1 == 1.0` 为 true 会让 pattern 分支漏接；默认 `=:=`。

---
