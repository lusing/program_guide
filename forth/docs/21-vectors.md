# 21 · 执行令牌与向量执行

对应示例：`../examples/21-vectors.fs`

素材：《Programming Forth》(Pelc) 第 10 章 Execution Tokens and Vectors、
《Thinking Forth》第 7 章 Vectored Execution / DOER/MAKE。

## xt：函数指针三件套

```forth
' greet          \ 顶层取 xt（冒号里必须 [']——老坑）
['] greet        \ 编译进词里（顶层用不了——也是老坑）
xt execute       \ 调用；可以 xt catch 包住防连坐
```

高阶词顺手就来：`: twice ( xt -- ) dup execute execute ;`。

## 执行数组：跳转表

同签名的一组词用 `,` 铺进数据区，**「加一个算符」= 加一个词 + 表里加一格，
分发逻辑零改动**——比 CASE 好扩，这是 Pelc 的招牌手法，也是第 28 章
计算器的骨架。

```forth
create ops  ' op-add ,  ' op-sub ,  ' op-mul ,  ' op-div ,
: apply-op  ( a b idx -- r )  cells ops + @ execute ;
```

两个实测坑：

- `c"` 和 `,"` 都是 **compile-only**，顶层造字符串表用 `create + s,`；
- gforth 的 `s,` 存的是 **counted string**（首字节是长度），取回用
  `count type`，别按裸字节 `type`；
- 表里要存 **body 地址**时直接执行 create 词（`n0 ,`），写 `' n0 ,`
  存进去的是 xt，`type` 出来是机器码。

## DEFER 全家：可换装的口子

| 词 | 用法 |
|---|---|
| `defer logger` | 声明 |
| `' log-echo is logger` | 解释态换装（名字来自输入流） |
| `['] x defer!` / `defer@` | 直接写/读（`defer!` 无返回值，别接 `.`） |
| `action-of logger` | 读当前指向 |

⚠ **未初始化 defer 一执行就往 stderr 打** `deferred word xxx is
uninitialized`，而且 `catch` 拦下来返回 **0（假成功）**——stderr 照脏。
空占位请显式 `' noop is logger`。

## DOER：运行时批量造 defer

`: doer ( "name" ) defer ['] noop latestxt defer! ;`——CREATE...DOES> 与
DEFER 的组合拳。示例里实现了 `with-behave`：换装 → 执行 → 还原，
这是 polyFORTH `MAKE/UNMAKE` 在 gforth 下的手工版（gforth 没有 ; 钩子，
不能自动还原）。

## 向量状态机

动作表 + 转移表两张表，**改行为只换表不换逻辑**。示例是经典旋转门
（2 状态 × 2 事件）——这正是 Thinking Forth「消除控制结构」一章的
招牌手法。

运行：`gforth examples/21-vectors.fs`

---
上一章：[20 · 栈戏法与返回栈](20-stack-fu.md) ｜ 下一章：[22 · 输入流与解析](22-parsing.md) ｜ 返回：[README](../README.md)
