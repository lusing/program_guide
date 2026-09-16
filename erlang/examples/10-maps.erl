%% ============================================================
%% 10 - Map
%%
%%    Map 是 OTP 17 引入的键值结构，现在已经是 Erlang 里
%%    最常用的「小记录 / 配置 / 计数表」载体。
%%
%%    ⚠ 最重要的一条：**map 的迭代顺序是未定义的**。
%%    实测同一份代码，maps:keys(#{c=>3,a=>1,b=>2,z=>26,y=>25}) 在
%%    20 次运行里出现了 [y,c,a,b,z]（6 次）和 [y,c,b,a,z]（14 次）
%%    两种结果 —— 因为原子哈希带每次启动随机的种子。
%%    所以本示例里凡是要打印 map，一律先 lists:sort(maps:to_list(M))。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/10-maps.erl
%% 运行：
%%   erl -noshell -pa build -run '10-maps' main -s init stop
%% ============================================================
-module('10-maps').

-export([main/0, new_user/2, birthday/1, merge_config/2, count_words/1]).

main() ->
    construct_and_access(),
    update(),
    iterate(),
    nested(),
    order_warning(),
    idioms(),
    io:format("~n==== 10 结束 ====~n").

%% 1) 构造与访问
%% ------------------------------------------------------------
construct_and_access() ->
    io:format("== 1) 构造与访问 ==~n"),
    M = #{name => "alice", age => 30},
    d("字面量 #{name => \"alice\", age => 30}", sorted(M)),
    d("maps:get(name, M)", maps:get(name, M)),
    %% 用点号取字段：键必须是**原子**，且键不存在会抛 badkey
    d("M 的 name 字段（M 语法）", maps:get(name, M)),
    d("maps:get/3 带默认值", maps:get(city, M, "unknown")),
    d("maps:find 返回 {ok,V} 或 error", {maps:find(age, M), maps:find(x, M)}),
    d("maps:is_key / maps:size", {maps:is_key(age, M), maps:size(M)}),
    d("map 也能用模式取字段", begin #{age := A} = M, A end),
    d("maps:from_list", sorted(maps:from_list([{a, 1}, {b, 2}]))),
    d("maps:from_list 重复键后者胜", sorted(maps:from_list([{a, 1}, {a, 2}]))),
    d("maps:to_list 再排序才是稳定输出", sorted(M)),
    d("maps:keys 用之前先排序", lists:sort(maps:keys(M))),
    d("maps:values 同理", lists:sort(maps:values(M))),
    ok.

%% 2) 更新
%% ------------------------------------------------------------
%% 三个容易混淆的操作：
%%   M#{K => V}        新增或覆盖（=> 表示「总是更新」）
%%   M#{K := V}        只更新**已存在**的键，不存在就抛 badkey
%%   maps:put/3        等价于 =>
update() ->
    io:format("~n== 2) 更新 ==~n"),
    M = #{a => 1},
    d("M#{b => 2}（新增）", sorted(M#{b => 2})),
    d("M#{a => 9}（覆盖）", sorted(M#{a => 9})),
    d("M#{zz => 1} 里用 := 会抛 badkey",
      raises(fun(MM) -> MM#{zz := 1} end, M)),
    d("maps:put 与 => 等价", sorted(maps:put(c, 3, M))),
    d("maps:remove 删键（删不存在的键不报错）", sorted(maps:remove(nope, M))),
    d("maps:take 返回 {值, 剩余} 或 error",
      {maps:take(a, M), maps:take(nope, M)}),
    %% update_with：有则用函数更新，无则用初值 —— 计数/累加的标准写法
    d("maps:update_with(a, +1, 0, M)", sorted(maps:update_with(a, fun(V) -> V + 1 end, 0, M))),
    d("maps:update_with(zz, +1, 0, M)（缺失键用初值 0）",
      sorted(maps:update_with(zz, fun(V) -> V + 1 end, 0, M))),
    %% 原 map 不会被修改：Erlang 的数据都是不可变的
    d("原 M 仍然是 #{a => 1}", sorted(M)),
    ok.

%% 3) 遍历与转换
%% ------------------------------------------------------------
iterate() ->
    io:format("~n== 3) 遍历与转换 ==~n"),
    M = #{a => 1, b => 2, c => 3},
    d("maps:map 变换值", sorted(maps:map(fun(_K, V) -> V * 10 end, M))),
    d("maps:filter 过滤", sorted(maps:filter(fun(_K, V) -> V > 1 end, M))),
    d("maps:fold 累积（先排序保证稳定）",
      lists:sort(maps:fold(fun(K, V, Acc) -> [{K, V} | Acc] end, [], M))),
    d("maps:merge 右侧优先", sorted(maps:merge(#{a => 1, b => 2}, #{b => 9}))),
    d("maps:merge_with 冲突时用函数决定", sorted(maps:merge_with(fun(_K, L, R) -> L + R end, #{a => 1}, #{a => 2}))),
    d("maps:with 只保留指定键", sorted(maps:with([a, c], M))),
    d("maps:without 排除指定键", sorted(maps:without([a], M))),
    %% 用推导式处理：先生成 {K,V} 对再汇成 map
    d("推导式 + from_list 也是常用组合",
      sorted(maps:from_list([{K, V * V} || {K, V} <- maps:to_list(M)]))),
    ok.

%% 4) 嵌套 map 与「记录式」用法
%% ------------------------------------------------------------
%% 拿 map 当记录用很常见，但要自己做「字段默认值」和「合法字段」的约束。
new_user(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #{name => Name,
      age => Age,
      tags => [],
      created_at => 0}.

birthday(User) ->
    User#{age := maps:get(age, User) + 1}.

%% 深合并：以 base 的字段集为骨架，用 override 覆盖
merge_config(Base, Override) ->
    maps:fold(fun(K, V, Acc) ->
                      case {maps:is_key(K, Acc), is_map(V), is_map(maps:get(K, Acc, #{}))} of
                          {true, true, true} ->
                              Acc#{K := merge_config(maps:get(K, Acc), V)};
                          _ ->
                              Acc#{K => V}
                      end
              end, Base, Override).

nested() ->
    io:format("~n== 4) 嵌套 map ==~n"),
    U = new_user("alice", 30),
    d("new_user/2 的默认字段", sorted(U)),
    d("birthday/1 只改 age", sorted(birthday(U))),
    %% 更新嵌套字段要一层层拿出来再放回去
    Config = #{server => #{host => "localhost", port => 8080},
               log => #{level => info}},
    d("深合并只改 port",
      sorted(maps:get(server, merge_config(Config, #{server => #{port => 9090}})))),
    d("深合并没有污染其它分支",
      sorted(maps:get(log, merge_config(Config, #{server => #{port => 9090}})))),
    %% 用 maps:get 的默认值语法可以安全地往下钻
    d("安全下钻 maps:get(a, maps:get(server, Config, #{}), none)",
      maps:get(a, maps:get(server, Config, #{}), none)),
    ok.

%% 5) 顺序的坑（这一节是本示例存在的核心理由）
%% ------------------------------------------------------------
order_warning() ->
    io:format("~n== 5) 顺序不保证 ==~n"),
    M = #{c => 3, a => 1, b => 2, z => 26, y => 25},
    %% 下面这行如果直接打印 maps:keys(M)，两次运行可能得到不同结果，
    %% 所以本示例只打印排序后的结果。
    d("排序后的键（稳定）", lists:sort(maps:keys(M))),
    d("to_list 排序后（稳定）", sorted(M)),
    %% 整数键的 map 打印看起来是排序的，但这是实现细节，不要依赖
    d("整数键 map 的 to_list", maps:to_list(maps:from_list([{3, c}, {1, a}, {2, b}]))),
    d("所以「相等」要用排序后的列表判断",
      sorted(#{a => 1, b => 2}) =:= sorted(#{b => 2, a => 1})),
    ok.

%% 6) 常用惯用法：计数、分组、转 proplist
%% ------------------------------------------------------------
count_words(Words) ->
    lists:foldl(fun(W, Acc) -> maps:update_with(W, fun(N) -> N + 1 end, 1, Acc) end,
                #{}, Words).

idioms() ->
    io:format("~n== 6) 惯用法 ==~n"),
    Words = ["apple", "banana", "apple", "cherry", "banana", "apple"],
    d("词频统计", sorted(count_words(Words))),
    %% 按值分组：先算出 {值, 键} 再规整
    ByLen = lists:foldl(fun(W, Acc) ->
                                L = length(W),
                                Acc#{L => [W | maps:get(L, Acc, [])]}
                        end, #{}, Words),
    d("按词长分组（每组内排序）",
      lists:sort([{K, lists:sort(V)} || {K, V} <- maps:to_list(ByLen)])),
    d("map 与 proplist 互转", lists:sort(maps:to_list(maps:from_list([{a, 1}, {b, 2}])))),
    ok.

%% 把 map 转成「按 key 排序的列表」，输出才可逐字节比对
sorted(M) when is_map(M) -> lists:sort(maps:to_list(M)).

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
