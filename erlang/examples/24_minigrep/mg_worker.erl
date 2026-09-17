%% ============================================================
%% mg_worker —— 扫描单个文件：找含模式的行（无状态纯函数）
%%
%% 思路（08/19 章的组合）：
%%   ① file:read_file 整个文件读成二进制；
%%   ② binary:split 按 \n 切成行（保留行号）；
%%   ③ binary:match 逐行找模式（子串匹配，不是正则——与 go/zig 版一致）。
%% 行尾的 \r（Windows CRLF）剥掉再输出。
%% ============================================================
-module(mg_worker).

-export([scan_file/2, scan_binary/1]).

%% 扫一个文件：返回 {ok, [{行号, 行文本}]}（只含命中行，按行号升序）
scan_file(File, Pattern) when is_binary(Pattern) ->
    case file:read_file(File) of
        {ok, Bin} -> {ok, scan_binary(match_lines(Bin, Pattern))};
        {error, Reason} -> {error, {unreadable, Reason}}
    end.

%% 可测试的纯函数：输入「命中行号集合 + 全部行」→ [{行号, 文本}]
scan_binary({HitNos, Lines}) ->
    [{No, strip_cr(lists:nth(No, Lines))} || No <- HitNos].

%% 找出所有含 Pattern 的行号（升序）
match_lines(Bin, Pattern) ->
    Lines = binary:split(Bin, <<"\n">>, [global, trim_all]),
    HitNos = [No || {No, Line} <- enumerate(Lines),
                    binary:match(Line, Pattern) =/= nomatch],
    {HitNos, Lines}.

enumerate(L) ->
    lists:zip(lists:seq(1, length(L)), L).

%% 剥掉 Windows 行尾的 \r（19 章：CRLF 的坑）
strip_cr(Line) ->
    case binary:split(Line, <<"\r">>) of
        [Body, <<>>] -> Body;
        _ -> Line
    end.
