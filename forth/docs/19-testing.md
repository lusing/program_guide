# 19 · 测试与基准

对应示例：`../examples/19-testing.fs`

Forth 里「能跑」和「跑对了」是两回事：一个词悄悄在栈上多留一个值，程序照样跑，只是三分钟后莫名其妙。所以测试是刚需。

自制断言库（零依赖，最实用）：

```forth
: assert=  { 实际 期望 -- }
  实际 期望 =
  if   记通过
  else 记失败  cr ."   期望 " 期望 . ."  实际 " 实际 .  then ;

: assert-栈空  ( -- )  depth 0=  if  记通过  else  记失败 ...  then ;

: assert-抛出  ( xt 期望码 -- )  { 期望码 }  catch ... ;
```

三类必测项：

1. **返回值断言** —— `assert=` / `assert-深` / `assert≈`（浮点用 `f- fabs 容差 f<`，**不要**用 `f~`）。
2. **栈平衡断言** —— `assert-栈空`，专治「悄悄多留一个值」。
3. **异常断言** —— `assert-抛出`，验证边界条件真的抛了。

基准用 `utime`（双精度微秒）：

```forth
utime 2>r  <被测词>  utime 2r> d- d>s
```

自带的测试库：

- `test/tester.fs` —— ⚠ 可用但有副作用：里面有 `: { T{ ;`，**会把 `{` 抢走**，locals 语法报废；还会把 `BASE` 切成 16 进制并在 stderr 打 `redefined {`。要混用就放最后 require，并配 `warnings off` + `decimal`。
- `test/ttester.fs` —— 浮点部分在本机不可用（`rx}t` / `r}t` 报 NUMBER OF FLOAT RESULTS）。

结论：**自制断言比自带测试库更可靠**。

运行：`gforth examples/19-testing.fs`

---
上一章：[18 · 生成器与惰性序列](18-generators.md) ｜ 下一章：[20 · 速查表](20-cheatsheet.md) ｜ 返回：[README](../README.md)
