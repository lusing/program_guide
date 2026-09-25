%% ============================================================
%% 32_sherlock —— 收官：文本侦探（福尔摩斯的最后一案）
%%
%%    Armstrong 书的压轴项目：给几段已知作者的文章 + 一段匿名文本，
%%    用统计手法判断匿名作者「文风最像谁」。全链路纯函数：
%%      · tokens     —— 分词与规范化（小写、去标点）
%%      · counts     —— 词频表
%%      · similarity —— 词集合的重合度（Jaccard：交集/并集）
%%      · predict_next —— bigram 模型：给定前一个词，预测下一个词
%%    没有进程、没有 IO（除打印）、没有时间——第 25–31 章学的分布式、
%%    套接字、端口、持久化、行为、剖析、并行一个都不用：**收官先回纯函数**。
%%
%%    语料是自写的固定英文段落（两位「作家」用不同的口头禅），
%%    匿名段的用词倾向作者甲——这就是要侦破的案子。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/32_sherlock examples/32_sherlock/32_sherlock.erl
%% 运行：
%%   erl -noshell -pa build/32_sherlock -run '32_sherlock' main
%% ============================================================
-module('32_sherlock').

-export([main/0, tokens/1, counts/1, top_n/2, similarity/2,
         predict_next/2, ratio/1,
         author_a1/0, author_a2/0, author_b1/0, author_b2/0, anonymous/0]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% ------------------------------------------------------------ %%
%% 语料（自写固定段落；A 与 B 各两段，口头禅不同）
%% ------------------------------------------------------------ %%
author_a1() ->
    "Indeed the morning was quiet, and therefore the detective walked slowly. "
    "Moreover he observed the garden, and indeed the footprints were fresh. "
    "Therefore he concluded that the visitor had arrived early, and moreover "
    "the visitor knew the garden well. Indeed the case was promising.".

author_a2() ->
    "The detective indeed wrote every detail, and therefore his notes grew long. "
    "Moreover the witness spoke quietly, and indeed the facts were clear. "
    "Therefore the deduction followed, and moreover the answer surprised nobody. "
    "Indeed the method mattered more than the result.".

author_b1() ->
    "Basically the night was loud, because the train passed often, and you know "
    "the streets never slept. Really the city talked all night, basically a "
    "machine of noise, because everyone wanted something, you know, really "
    "anything at all.".

author_b2() ->
    "Basically the cafe was warm, because the coffee never stopped, and you know "
    "the regulars told stories. Really the hours vanished there, basically a room "
    "of voices, because everyone had a story, you know, really long ones.".

anonymous() ->
    "Indeed the evening was cold, and therefore the lane was empty. Moreover the "
    "lamp flickered, and indeed the shadow moved quickly. Therefore the detective "
    "followed, and moreover the silence felt deliberate. Indeed the clue was small.".

%% ------------------------------------------------------------ %%
%% 纯函数工具链
%% ------------------------------------------------------------ %%
%% 分词：小写 + 只留字母（标点/数字当分隔符）
tokens(Text) ->
    Normalized = string:lowercase(Text),
    Words = split_words(Normalized, [], []),
    lists:reverse(Words).

split_words([], [], Words) -> Words;
split_words([], Cur, Words) -> [lists:reverse(Cur) | Words];
split_words([C | Rest], Cur, Words) when C >= $a, C =< $z ->
    split_words(Rest, [C | Cur], Words);
split_words([_Other | Rest], [], Words) ->
    split_words(Rest, [], Words);
split_words([_Other | Rest], Cur, Words) ->
    split_words(Rest, [], [lists:reverse(Cur) | Words]).

%% 词频表
counts(Tokens) ->
    lists:foldl(fun (W, Acc) -> maps:update_with(W, fun (N) -> N + 1 end, 1, Acc) end,
                #{}, Tokens).

%% Top-N：{-次数, 词} 排序——同频按字典序，输出确定
top_n(Counts, N) ->
    Sorted = lists:sort([{-C, W} || {W, C} <- maps:to_list(Counts)]),
    [{W, -NC} || {NC, W} <- lists:sublist(Sorted, N)].

%% Jaccard 重合度：词集合交集/并集（自相似=1、对称）
similarity(TokensA, TokensB) ->
    A = sets:from_list(TokensA, [{version, 2}]),
    B = sets:from_list(TokensB, [{version, 2}]),
    Inter = sets:size(sets:intersection(A, B)),
    Union = sets:size(sets:union(A, B)),
    {Inter, Union}.

ratio({Inter, Union}) when Union > 0 -> Inter / Union.

%% bigram 预测：给定前词，取后继里最常出现的（并列按字典序取最小）
predict_next(Tokens, Prev) ->
    Bigrams = pairwise(Tokens),
    Candidates = [Next || {P, Next} <- Bigrams, P =:= Prev],
    case Candidates of
        [] -> none;
        _ ->
            Counts = counts(Candidates),
            [{Word, _} | _] = top_n(Counts, 1),
            Word
    end.

pairwise([_]) -> [];
pairwise([A, B | Rest]) -> [{A, B} | pairwise([B | Rest])].

%% ------------------------------------------------------------ %%
main() ->
    logger:remove_handler(default),
    corpus(),
    tokenize(),
    frequencies(),
    the_case(),
    bigram_model(),
    io:format("~n==== 32 结束 ====~n").

corpus() ->
    io:format("~n== 1) 语料即数据 ==~n"),
    %% 整数列表会被 ~p 当可打印字符串——装元组防误读
    d("作者甲两段的词数", {length(tokens(author_a1())), length(tokens(author_a2()))}),
    d("作者乙两段的词数", {length(tokens(author_b1())), length(tokens(author_b2()))}),
    d("匿名段词数", length(tokens(anonymous()))),
    io:format("  （语料是模块里的函数——换语料不改一行算法）~n").

tokenize() ->
    io:format("~n== 2) 分词与规范化 ==~n"),
    d("样例：带标点大写", "Indeed, the Morning!"),
    d("tokens 后", lists:sublist(tokens("Indeed, the Morning!"), 3)),
    d("标点与数字是分隔符", lists:sublist(tokens("coffee, 42 stories;"), 2)).

frequencies() ->
    io:format("~n== 3) 词频：作家的口头禅 ==~n"),
    TokensA = tokens(author_a1()) ++ tokens(author_a2()),
    TokensB = tokens(author_b1()) ++ tokens(author_b2()),
    d("作者甲 top5（indeed/therefore/moreover）", top_n(counts(TokensA), 5)),
    d("作者乙 top5（basically/because/you-know）", top_n(counts(TokensB), 5)).

the_case() ->
    io:format("~n== 4) 侦破：匿名段像谁 ==~n"),
    Anon = tokens(anonymous()),
    A = tokens(author_a1()) ++ tokens(author_a2()),
    B = tokens(author_b1()) ++ tokens(author_b2()),
    SA = similarity(Anon, A),
    SB = similarity(Anon, B),
    d("与甲的重合 {交集, 并集}", SA),
    d("与乙的重合 {交集, 并集}", SB),
    d("与甲的重合度（比值）", ratio(SA)),
    d("与乙的重合度（比值）", ratio(SB)),
    d("自相似 = 1（方法的 sanity check）", ratio(similarity(Anon, Anon))),
    d("对称性", ratio(similarity(A, Anon)) =:= ratio(SA)),
    d("【结论】匿名段判给", case ratio(SA) > ratio(SB) of true -> author_a; false -> author_b end).

bigram_model() ->
    io:format("~n== 5) bigram：预测下一个词 ==~n"),
    TokensA = tokens(author_a1()) ++ tokens(author_a2()),
    d("indeed 后面最常出现", predict_next(TokensA, "indeed")),
    d("therefore 后面最常出现", predict_next(TokensA, "therefore")),
    d("查无此词", predict_next(TokensA, "elephant")),
    io:format("  （书上的下一词预测模型：把语料统计变成生成器的心脏）~n").
