%% ============================================================
%% 16 - 属性列表（proplists）：Erlang 里最常见的「配置」数据结构
%%
%%    属性列表就是一个列表，元素是 {Key, Value}，或者**裸原子**（等于 {K, true}）。
%%    OTP 自己的选项、sys.config、gen_server 的启动参数到处都是它。
%%    为什么不用 map？因为它允许**重复键**、有**顺序**、值可以是任意项，
%%    而且取第一个匹配项就够了 —— 「先给的赢」，正好是「命令行 > 配置文件 > 默认值」
%%    这种覆盖语义。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/16-proplists.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '16-proplists' main -s init stop
%% ============================================================
-module('16-proplists').

-export([main/0, open/1, describe_open/1]).

main() ->
    shape_and_read(),
    duplicates(),
    convert(),
    boolean_flags(),
    with_lists(),
    plain_lists_api(),
    real_world_options(),
    io:format("~n==== 16 结束 ====~n").

%% 1) 形状与读取
%% ------------------------------------------------------------
%% 属性列表（proplist）里的项有三种合法形状：
%%   {Key, Value}   —— 最常见
%%   Key            —— 裸原子，被当成 {Key, true}
%%   其它           —— 会被 proplists 的取值函数忽略（但不报错！）
shape_and_read() ->
    io:format("== 1) 形状与读取 ==~n"),
    Opts = [{verbose, true}, debug, {retries, 3}, 42],
    d("属性列表", Opts),
    d("proplists:get_value(verbose, Opts)", proplists:get_value(verbose, Opts)),
    d("proplists:get_value(debug, Opts)（裸原子等价于 {debug,true}）",
      proplists:get_value(debug, Opts)),
    d("proplists:get_value(retries, Opts)", proplists:get_value(retries, Opts)),
    d("proplists:get_value(missing, Opts) → undefined",
      proplists:get_value(missing, Opts)),
    d("proplists:get_value(missing, Opts, 默认值) → 用第三个参数兜底",
      proplists:get_value(missing, Opts, 60)),
    d("proplists:lookup(debug, Opts)（拿到整个项，而不是值）",
      proplists:lookup(debug, Opts)),
    d("proplists:lookup(missing, Opts)",
      proplists:lookup(missing, Opts)),
    d("proplists:is_defined(debug, Opts)", proplists:is_defined(debug, Opts)),
    d("proplists:is_defined(nope, Opts)", proplists:is_defined(nope, Opts)),
    d("proplists:get_keys(Opts)（裸项也算键）", lists:sort(proplists:get_keys(Opts))),
    d("proplists:delete(debug, Opts)（删掉所有 debug 项）",
      lists:sort(proplists:delete(debug, Opts))),
    %% 注意第 4 项是整数 42：取值函数会忽略它，**不会报错**
    io:format("  ~ts~n", ["（列表里的 42 不是合法项，取值时被静默忽略 —— 不校验形状是常见坑）"]),
    %% proplists:property/1,2 不是「合法性判断」，是**构造器 + 归一化**。
    %% 源码（stdlib-8.0.2/proplists.erl）：
    %%   property({Key,true}) when is_atom(Key) -> Key;
    %%   property(Property) -> Property.
    %%   property(Key, true) when is_atom(Key) -> Key;
    %%   property(Key, Value) -> {Key, Value}.
    %% property/2 是「构造一个属性项」，值恰好是 true 时缩成裸原子。
    d("property(a, 1) → 构造 {a,1}", proplists:property(a, 1)),
    d("property(a, true) → 缩成裸原子 a", proplists:property(a, true)),
    d("property({a, true}) → 归一化成裸原子", proplists:property({a, true})),
    d("property({a, 1}) → 原样", proplists:property({a, 1})),
    d("property(42) → 原样返回（它不做合法性判断！）", proplists:property(42)),
    ok.

%% 2) 重复键：先给的赢
%% ------------------------------------------------------------
%% 这与 map 相反（map 是后写的覆盖先写的）。所以典型的「合并配置」写法是
%%   lists:foldl(fun({K,V}, Acc) -> proplists:delete(K, Acc) ++ [{K,V}] end, ...)
%% 或者干脆把「高优先级的那份」放在前面、**不要合并**。
duplicates() ->
    io:format("~n== 2) 重复键（proplist 的看家本领） ==~n"),
    P = [{level, warn}, {level, info}, {level, debug}],
    d("同一个键出现三次", P),
    d("get_value 取**第一个**", proplists:get_value(level, P)),
    d("get_all_values 取全部（返回的是值列表）",
      proplists:get_all_values(level, P)),
    d("lookup_all 取全部（返回的是完整项列表）",
      proplists:lookup_all(level, P)),
    %% 对照 map：后写的赢
    M = maps:from_list([{level, warn}, {level, info}, {level, debug}]),
    d("对照 map：from_list 之后只剩最后一个", maps:to_list(M)),
    %% 「高优先级放前面」的合并写法
    Defaults = [{retries, 3}, {timeout, 60}],
    User = [{timeout, 5}],
    d("默认值 + 用户值，用户值放前面 → 用户赢",
      [{K, proplists:get_value(K, User, proplists:get_value(K, Defaults, undefined))}
       || {K, _} <- Defaults]),
    ok.

%% 3) 规范化与互转
%% ------------------------------------------------------------
%% 以下语义全部对着 stdlib-8.0.2 的 proplists.erl 源码核过（不是靠记忆）：
%%   unfold/1     裸原子 → {K, true}；**已是指针形式的项原样保留**，它不拆列表！
%%   compact/1    {K, true} → K（unfold 的反向）；其它项原样
%%   normalize/2  先按 stages 做别名/否定/展开，最后 compact 一遍
%%   to_map/1     proplist → map（重复键时后者赢，因为 map 只能有一个值）
%%   from_map/1   map → proplist（顺序随机！一定要 sort）
%%   get_keys/1   键**去重**，而且实现里用了 sets，顺序也随机 → 必须 sort
convert() ->
    io:format("~n== 3) 规范化与互转 ==~n"),
    d("unfold([a, {b,2}, {c,[1,2]}])（只动裸原子）",
      proplists:unfold([a, {b, 2}, {c, [1, 2]}])),
    d("compact([a, {b,true}, {c,1}])（{K,true} 缩成 K）",
      proplists:compact([a, {b, true}, {c, 1}])),
    d("normalize/2 的 stages 可以改键名（{aliases, ...}）",
      proplists:normalize([{old, 1}, {old, 2}], [{aliases, [{old, new}]}])),
    d("normalize/2 的 stages 是空列表时等价于 compact",
      proplists:normalize([{a, true}, {b, 1}], [])),
    d("to_map（重复键时后者赢）",
      lists:sort(maps:to_list(proplists:to_map([{a, 1}, {a, 2}, b])))),
    d("from_map 之后必须 sort（map 的迭代顺序每次启动都随机）",
      lists:sort(proplists:from_map(#{x => 1, y => 2}))),
    d("get_keys 会去重 → 再 sort 才是确定输出",
      lists:sort(proplists:get_keys([{a, 1}, {a, 2}, b]))),
    d("split 按键分组", proplists:split([{a, 1}, {b, 2}, {a, 3}], [a])),
    d("append_values 只取值（收集同名键的所有值）",
      proplists:append_values(a, [{a, 1}, {b, 2}, {a, 3}])),
    d("substitute_aliases 改键名", proplists:substitute_aliases([{old, new}], [{old, 1}])),
    d("substitute_negations 把「否定开关」变成显式布尔",
      proplists:substitute_negations([{no_x, x}], [{no_x, true}, {x, true}])),
    ok.

%% 4) 布尔开关：get_bool/2 与 property/1
%% ------------------------------------------------------------
%% 命令行开关（--debug）的经典形态就是「裸原子」。
%% get_bool/2 是专门给这种开关用的：**项不存在**或**值为 false 时都返回 false**。
%% 所以它无法区分「没写」和「写了 false」—— 想区分就用 is_defined/2。
boolean_flags() ->
    io:format("~n== 4) 布尔开关 ==~n"),
    d("get_bool(debug, [debug])", proplists:get_bool(debug, [debug])),
    d("get_bool(debug, [{debug, true}])", proplists:get_bool(debug, [{debug, true}])),
    d("get_bool(debug, [{debug, false}])（显式 false 也是 false）",
      proplists:get_bool(debug, [{debug, false}])),
    d("get_bool(debug, [])（不存在也是 false，无法区分）",
      proplists:get_bool(debug, [])),
    d("想区分就用 is_defined/2",
      {proplists:is_defined(debug, []), proplists:is_defined(debug, [{debug, false}])}),
    ok.

%% 5) 把一条选项展开成多条：expand/2
%% ------------------------------------------------------------
%% 典型场景：`{debug, [log, trace]}` 想变成两条独立选项。
%% 注意 unfold/1 做不到这件事（它只把裸原子变成 {K,true}），要拆得用 expand/2。
%%
%% expand/2 的匹配规则是**实测**出来的（不是靠猜）：
%%   展开表里写 {K, Expansion}      → 匹配「值为 true 的属性」和裸原子 K
%%   展开表里写 {{K, false}, Exp}   → 只匹配 {K, false}
%%   值为其它东西的属性（如 {debug, x}）**不会被展开**
%% 也就是说：展开表的第一元不是「键」，而是「一个属性」。
with_lists() ->
    io:format("~n== 5) 一条选项展开成多条 ==~n"),
    E = [{debug, [{debug, log}, {debug, trace}]}],
    d("expand(表, [debug])（裸原子会被展开）", proplists:expand(E, [debug])),
    d("expand(表, [{debug,true}])（值为 true 也会）", proplists:expand(E, [{debug, true}])),
    d("expand(表, [{debug,x}])（值是 x，不展开）", proplists:expand(E, [{debug, x}])),
    d("夹在其它项中间", proplists:expand(E, [a, debug, b])),
    F = [{{debug, false}, [{debug, off}]}],
    d("表里写 {{K,false}, ...} 时只匹配 {K,false}", proplists:expand(F, [{debug, false}])),
    d("同一个表匹配不上裸原子 debug", proplists:expand(F, [debug])),
    d("展开 real 用法的路径列表",
      proplists:expand([{path, [{path, "/a"}, {path, "/b"}]}], [path])),
    d("unfold 只能处理裸原子，别指望它拆列表",
      proplists:unfold([{path, ["/a", "/b"]}])),
    ok.

%% 6) 直接用普通列表函数操作 proplist
%% ------------------------------------------------------------
%% proplist 就是列表，所以 lists 的 key* 系列全都适用，而且更快更可控。
%% 记不住 proplists 那 20 多个函数时，用这些往往更划算。
plain_lists_api() ->
    io:format("~n== 6) 直接用 lists 的 key* 系列 ==~n"),
    P = [{b, 2}, {a, 1}, {c, 3}],
    d("原样", P),
    d("lists:keyfind(a, 1, P)（找不到返回 false，不抛）", lists:keyfind(a, 1, P)),
    d("lists:keyfind(z, 1, P)", lists:keyfind(z, 1, P)),
    d("lists:keymember(a, 1, P)", lists:keymember(a, 1, P)),
    d("lists:keytake(a, 1, P)（返回 {值, 剩下的}）", lists:keytake(a, 1, P)),
    d("lists:keysort(1, P)（按第 1 元排序；重复键保持原有相对顺序）",
      lists:keysort(1, P)),
    d("用 lists:keyfind 把 proplist 变成函数参数",
      {lists:keyfind(b, 1, P), lists:keyfind(c, 1, P)}),
    ok.

%% 7) 实战：一个带选项的 API
%% ------------------------------------------------------------
%% 这是 proplists 最正经的用途：函数的「命名参数」。
%% 要点：先合并默认值，再校验取值范围，最后别保留用户给错的键。
open(Opts) ->
    Mode = proplists:get_value(mode, Opts, read),
    Retries = proplists:get_value(retries, Opts, 3),
    Verbose = proplists:get_bool(verbose, Opts),
    Known = [mode, retries, verbose],
    Unknown = [K || {K, _} <- Opts, not lists:member(K, Known)]
        ++ [K || K <- Opts, is_atom(K), not lists:member(K, Known)],
    case lists:member(Mode, [read, write, append]) of
        false -> {error, {bad_mode, Mode}};
        true when not is_integer(Retries); Retries < 0 ->
            {error, {bad_retries, Retries}};
        true when Unknown =/= [] ->
            {error, {unknown_options, lists:sort(Unknown)}};
        true ->
            {ok, #{mode => Mode, retries => Retries, verbose => Verbose}}
    end.

describe_open(Opts) ->
    case open(Opts) of
        {ok, M} -> {ok, lists:sort(maps:to_list(M))};
        {error, R} -> {error, R}
    end.

real_world_options() ->
    io:format("~n== 7) 实战：带选项的 API ==~n"),
    d("全用默认值", describe_open([])),
    d("改两个", describe_open([{mode, write}, {retries, 0}])),
    d("布尔开关写成裸原子", describe_open([{mode, append}, verbose])),
    d("mode 非法", describe_open([{mode, destroy}])),
    d("retries 非法", describe_open([{retries, -1}])),
    d("多写了不认识的键（应该报错，而不是静默忽略）",
      describe_open([{mode, read}, {retry, 5}])),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
