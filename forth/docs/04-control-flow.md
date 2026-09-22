# 04 · 分支与循环

对应示例：`../examples/04-control-flow.fs`

布尔值是**整数**：0 为假，非 0 为真（系统给的真值通常是 `-1`，即全 1）。

```forth
IF ... ELSE ... THEN                       \ 注意是 THEN 结尾
CASE x OF ... ENDOF  y OF ... ENDOF  ENDCASE
DO ... LOOP      DO ... n +LOOP     ?DO ... LOOP
BEGIN ... UNTIL  BEGIN ... WHILE ... REPEAT  BEGIN ... AGAIN
```

> ⚠ **头号坑**：`DO` 的参数顺序是 `( 上限 起点 -- )`，`10 0 DO I . LOOP` 打印 0..9。

```forth
: gcd  ( a b -- gcd )          \ 欧几里得，经典写法
  begin  dup  while  tuck mod  repeat  drop ;

: sum-array  ( addr n -- sum ) \ bounds 是遍历内存的标准姿势
  0 -rot cells bounds  do  i @ +  cell +loop ;
```

`?DO` 只在「起点 = 上限」时跳过；**起点 > 上限不是「不循环」，而是无符号比较一路加到回绕 ≈ 2⁶⁴ 次 = 死循环**。想要「可能 0 次」的循环，用 `begin ... while ... repeat`。

提前跳出用 `LEAVE`（或 `UNLOOP EXIT`）。

综合练习：九九乘法表、FizzBuzz、试除法素数判断。

运行：`gforth examples/04-control-flow.fs`

---
上一章：[03 · 词、常量与变量](03-words-variables.md) ｜ 下一章：[05 · 字符串](05-strings.md) ｜ 返回：[README](../README.md)
