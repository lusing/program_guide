# 32 · 收官：文本侦探（福尔摩斯的最后一案）

> 对应示例：`examples/32_sherlock/`

Armstrong 书的压轴项目：给几段已知作者的文章和一段匿名文本，用统计
手法判断「匿名段文风最像谁」。全链路纯函数——分布式、套接字、端口、
持久化、行为、剖析、并行一章都不用：**收官先回纯函数**，这是老书的
安排，也是函数式的世界观。

## 32.1 语料与分词

语料是模块里的函数（自写的固定英文段落，两位「作家」口头禅不同；
匿名段的用词倾向作者甲）。分词 = 小写化 + 非字母当分隔符：

```erlang
tokens("Indeed, the Morning!") = ["indeed","the","morning"]
```

```erlang
split_words([C | Rest], Cur, Words) when C >= $a, C =< $z ->
    split_words(Rest, [C | Cur], Words);      %% 字母攒进当前词
split_words([_Other | Rest], [], Words) ->
    split_words(Rest, [], Words);              %% 分隔符且无当前词：跳过
split_words([_Other | Rest], Cur, Words) ->
    split_words(Rest, [], [lists:reverse(Cur) | Words]).   %% 断词
```

手写递归分词是第 5 章基本功的回归——用 `string:lexemes/2` 也能做，
但这里的规则「只留字母」自己写更直白。

## 32.2 词频：作家的口头禅

```erlang
counts(Tokens) ->
    lists:foldl(fun (W, Acc) ->
                        maps:update_with(W, fun (N) -> N + 1 end, 1, Acc)
                end, #{}, Tokens).
top_n(Counts, N) ->
    Sorted = lists:sort([{-C, W} || {W, C} <- maps:to_list(Counts)]),
    [{W, -NC} || {NC, W} <- lists:sublist(Sorted, N)].
```

`{-次数, 词}` 排序让**同频按字典序**——输出确定。实测结果：

```text
作者甲 top5 = [{"the",15},{"and",6},{"indeed",6},{"moreover",4},{"therefore",4}]
作者乙 top5 = [{"the",8},{"basically",4},{"because",4},{"know",4},{"really",4}]
```

口头禅直接浮出水面——统计比直觉诚实。

## 32.3 侦破：重合度

词集合的 Jaccard 重合度（交集/并集）：

```erlang
similarity(TokensA, TokensB) ->
    A = sets:from_list(TokensA, [{version, 2}]),
    B = sets:from_list(TokensB, [{version, 2}]),
    {sets:size(sets:intersection(A, B)), sets:size(sets:union(A, B))}.
```

```text
与甲的重合 {交集, 并集} = {8,63}
与乙的重合 {交集, 并集} = {3,63}
与甲的重合度（比值） = 0.12698412698412698
与乙的重合度（比值） = 0.047619047619047616
自相似 = 1（方法的 sanity check） = 1.0
对称性 = true
【结论】匿名段判给 = author_a
```

方法自检先行：自相似必为 1、对称必成立——**先证明尺子直，再量东西**
（和第 21 章测试纪律同一血脉）。比值打印 `{Inter, Union}` 两个整数
再算商——浮点直接算也行，但整数对让验证输出更可读。

## 32.4 bigram：预测下一个词

书上的下一词预测模型——语料统计变成生成器的心脏：

```erlang
predict_next(Tokens, Prev) ->
    Bigrams = pairwise(Tokens),                    %% 相邻词对
    Candidates = [Next || {P, Next} <- Bigrams, P =:= Prev],
    [{Word, _} | _] = top_n(counts(Candidates), 1),
    Word.
```

```text
indeed 后面最常出现 = "the"
therefore 后面最常出现 = "the"
查无此词 = none
```

并列时取字典序最小（top_n 的排序保证）——确定性无死角。

## 32.5 命令式程序员的总复习

《Erlang and Elixir for Imperative Programmers》Part V 的三张概念
表，用本教程的章号对齐收拢：

| 命令式习惯 | 函数式/Erlang 对应 | 章 |
|---|---|---|
| 变量 = 内存格子（可改） | 变量 = 名字绑定一次（`=` 是匹配） | 03/04 |
| 循环改状态 | 递归 + 累加器；尾调用不涨栈 | 05 |
| 对象封装状态 | 进程封装状态（消息是唯一通道） | 13/15 |
| 继承/接口 | behaviour（模块契约）/协议思想（数据契约） | 29 |
| 异常驱动控制流 | tagged tuple + let it crash | 12 |
| 共享内存 + 锁 | 不共享；要共享用 ETS（18）或消息 | 18 |
| try/catch 兜一切 | 监督树兜一切（重启即恢复） | 16 |
| 单体应用 | application + 发布（release） | 17/23 |

一句话：**把「状态藏在哪」从语言机制（可变变量/对象）搬到显式边界
（绑定/进程/数据库）**——这就是 BEAM 世界观的全部。

## 32.6 要点小结

```text
  收官回纯函数：无进程、无 IO（除打印）、无时间
  分词手写递归；词频 foldl + maps:update_with
  top_n 用 {-次数, 词} 排序——同频字典序，输出确定
  重合度先自检（自相似=1、对称）再下结论
  bigram：语料统计 → 下一词预测（生成器的心脏）
  整数列表装元组再打印——~p 会把 [44,41] 当字符串 ",)"
  侦探结论是算出来的：anon 与甲 0.127 > 与乙 0.048
```

## 32.7 坑位清单

1. **整数列表被 `~p` 当字符串**：`[44,41]` 打成 `",)"`（可打印
   码点区间）——统计数字装元组 `{44,41}`。
2. **`{-C, W}` 不能写进模式**——comprehension 模式里取负是非法
   模式；排序用二元组、还原时再取负。
3. **同频 top-N 必须全序**：只按次数排，同频之间的顺序随 map 迭代
   漂移——`{-次数, 词}` 双键排序。
4. **语料函数也是 API**：测试要用就进 `-export`——忘了导出，测试里
   undef（但 main 里用得好好的，编译器不出声）。
5. **函数体的串接字符串要句号**：多行 `"..." "..."` 拼接是一个表达式，
   最后一行 `"..."` 之后**必须有 `.`**——漏了语法错误报在下一个函数
   头上，别被行号骗了。

---

教程正文到此结束。第 25–32 章的扩充回顾：

- **25 章**：分布式——节点、peer、rpc、global；位置透明性；
- **26 章**：套接字——顺序/并行服务器、active 三态、UDP 扁平形状；
- **27 章**：端口——外部程序、驱动帧、binary+latin1 透传；
- **28 章**：DETS 与 Mnesia——磁盘表、事务、索引、脏读；
- **29 章**：gen_event 与 gen_statem——事件解耦与状态机；
- **30 章**：剖析与跟踪——计数可打印、时间只断言；
- **31 章**：多核并行——pmap 三变体与 future；
- **32 章**：文本侦探——纯函数收官。

两个导航性文件：

- 速查与坑位索引：[CHEATSheet](../CHEATSheet.md)
- 分章总览与运行方法：[README](../README.md)

Elixir 视角的双语言对照见[附录：Erlang ↔ Elixir](appendix-erlang-elixir.md)。
