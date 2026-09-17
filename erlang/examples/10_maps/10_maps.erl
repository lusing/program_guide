%% ============================================================
%% 10_maps —— 映射与记录
%%
%%    Map 是「小记录 / 配置 / 计数表」的首选载体；
%%    record 是「带字段名的元组」的编译期语法糖。
%%
%%    ⚠ 最重要的一条：**map 的迭代顺序是未定义的**。
%%    实测同一份代码，maps:keys(#{c=>3,a=>1,b=>2,z=>26,y=>25}) 在
%%    20 次运行里出现了两种不同结果 —— 原子哈希带每次启动随机的种子。
%%    所以本示例里凡是要打印 map，一律先 lists:sort(maps:to_list(M))。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/10_maps examples/10_maps/10_maps.erl
%% 运行：
%%   erl -noshell -pa build/10_maps -run '10_maps' main -s init stop
%% ============================================================
-module('10_maps').

%% record 定义：字段可带默认值与类型标注（:: 后面是给 dialyzer 看的，23 章）
-record(person, {name = "" :: string(),
                 age = 0 :: non_neg_integer(),
                 tags = [] :: [atom()]}).

-export([main/0, new_user/2, count_words/1, new_person/2, birthday/1,
         label/1, to_map/1, from_map/1, raises/2]).

main() ->
    construct_and_access(),
    update(),
    iterate(),
    order_warning(),
    idioms(),
    record_basics(),
    record_matching(),
    record_is_tuple(),
    record_vs_map(),
    io:format("~n==== 10 结束 ====~n").

%% 1) 构造与访问
%% ------------------------------------------------------------
construct_and_access() ->
    io:format("== 1) 构造与访问 ==~n"),
    M = #{name => "alice", age => 30},
    d("字面量（排序后输出）", sorted(M)),
    d("maps:get(name, M)", maps:get(name, M)),
    d("maps:get/3 带默认值", maps:get(city, M, "unknown")),
    d("maps:find 返回 {ok,V} 或 error", {maps:find(age, M), maps:find(x, M)}),
    d("maps:is_key / maps:size", {maps:is_key(age, M), maps:size(M)}),
    d("map 模式取字段", begin #{age := A} = M, A end),
    d("maps:from_list 重复键后者胜", sorted(maps:from_list([{a, 1}, {a, 2}]))),
    ok.

%% 2) 更新：=> 与 := 是两套语义
%% ------------------------------------------------------------
%%   M#{K => V}   新增或覆盖（总是更新）
%%   M#{K := V}   只更新**已存在**的键，不存在就抛 badkey
%%   maps:put/3   等价于 =>
update() ->
    io:format("~n== 2) 更新 ==~n"),
    M = #{a => 1},
    d("M#{b => 2}（新增）", sorted(M#{b => 2})),
    d("M#{a => 9}（覆盖）", sorted(M#{a => 9})),
    d("M#{zz := 1} 里用 := 会抛 badkey",
      raises(fun(MM) -> MM#{zz := 1} end, M)),
    d("maps:remove 删键（删不存在的键不报错）", sorted(maps:remove(nope, M))),
    d("maps:take 返回 {值, 剩余} 或 error",
      {maps:take(a, M), maps:take(nope, M)}),
    %% update_with：有则用函数更新，无则用初值 —— 计数/累加的标准写法
    d("maps:update_with(zz, +1, 0, M)（缺失键用初值）",
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
    d("maps:merge 右侧优先", sorted(maps:merge(#{a => 1, b => 2}, #{b => 9}))),
    d("maps:merge_with 冲突时用函数决定",
      sorted(maps:merge_with(fun(_K, L, R) -> L + R end, #{a => 1}, #{a => 2}))),
    d("maps:with / without",
      {sorted(maps:with([a, c], M)), sorted(maps:without([a], M))}),
    d("推导式 + from_list 组合",
      sorted(maps:from_list([{K, V * V} || {K, V} <- maps:to_list(M)]))),
    ok.

%% 4) 顺序的坑（这一节是本示例存在的核心理由）
%% ------------------------------------------------------------
order_warning() ->
    io:format("~n== 4) 顺序不保证 ==~n"),
    M = #{c => 3, a => 1, b => 2, z => 26, y => 25},
    d("排序后的键（稳定）", lists:sort(maps:keys(M))),
    d("整数键 map 的 to_list 看似有序，但这是实现细节",
      maps:to_list(maps:from_list([{3, c}, {1, a}, {2, b}]))),
    d("「相等」要用排序后的列表判断",
      sorted(#{a => 1, b => 2}) =:= sorted(#{b => 2, a => 1})),
    ok.

%% 5) 惯用法：计数、分组
%% ------------------------------------------------------------
new_user(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #{name => Name, age => Age, tags => []}.

count_words(Words) ->
    lists:foldl(fun(W, Acc) -> maps:update_with(W, fun(N) -> N + 1 end, 1, Acc) end,
                #{}, Words).

idioms() ->
    io:format("~n== 5) 惯用法 ==~n"),
    Words = ["apple", "banana", "apple", "cherry", "banana", "apple"],
    d("词频统计", sorted(count_words(Words))),
    ByLen = lists:foldl(fun(W, Acc) ->
                                L = length(W),
                                Acc#{L => [W | maps:get(L, Acc, [])]}
                        end, #{}, Words),
    d("按词长分组（组内排序）",
      lists:sort([{K, lists:sort(V)} || {K, V} <- maps:to_list(ByLen)])),
    d("maps:groups_from_list（OTP 25+）",
      lists:sort(maps:to_list(maps:groups_from_list(fun length/1, Words)))),
    ok.

%% 6) record：创建、访问、更新
%% ------------------------------------------------------------
record_basics() ->
    io:format("~n== 6) record 基础 ==~n"),
    P = new_person("alice", 30),
    d("#person.name", P#person.name),
    d("#person.tags 的默认值", P#person.tags),
    d("birthday(P) 的 age", (birthday(P))#person.age),
    d("原 P 不受影响（不可变）", P#person.age),
    d("一次更新多字段后与原值不等",
      P#person{name = "bob", age = 1} =/= P),
    d("模式里解构字段 #person{name = N}", begin #person{name = N} = P, N end),
    ok.

new_person(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #person{name = Name, age = Age}.

birthday(P = #person{age = A}) ->
    P#person{age = A + 1}.

%% 7) record 在模式与 guard 里
%% ------------------------------------------------------------
%% 子句顺序：匿名判定必须放在年龄判定**前面**，否则 age=0 的匿名人先命中 minor
label(#person{name = ""}) -> anonymous;
label(#person{age = A}) when A < 18 -> minor;
label(#person{age = A}) when A < 65 -> adult;
label(#person{}) -> senior.

record_matching() ->
    io:format("~n== 7) record 与模式/guard ==~n"),
    d("label(未成年人)", label(new_person("kid", 10))),
    d("label(成年人)", label(new_person("adult", 30))),
    d("label(老人)", label(new_person("old", 70))),
    d("label(匿名人，默认字段)", label(#person{})),
    d("is_record(P, person)", is_record(new_person("a", 1), person)),
    d("is_record 做 guard 分流",
      (fun(X) when is_record(X, person) -> is_person;
           (_) -> not_person
        end)(new_person("a", 1))),
    ok.

%% 8) record 的运行期形态就是元组
%% ------------------------------------------------------------
record_is_tuple() ->
    io:format("~n== 8) 运行期是元组 ==~n"),
    P = new_person("alice", 30),
    d("tuple_size(P)（标签 + 3 字段）", tuple_size(P)),
    d("element(1, P) 是标签原子", element(1, P)),
    d("element(3, P) 是 age", element(3, P)),
    d("直接用元组也能构造出等价 record", {person, "alice", 30, []} =:= P),
    d("record_info(fields, person)（编译期展开）",
      record_info(fields, person)),
    ok.

%% 9) record 与 map 的取舍
%% ------------------------------------------------------------
%% record：字段名编译期检查、访问是 element/2、内存省；
%%         但字段名运行期不可见、定义不跨模块共享。
%% map：字段名运行期可见、结构可动态生长；但拼错字段名运行期才发现。
%% 经验：**程序内部的结构用 record，跨模块/跨进程传递或结构会变用 map**。
to_map(#person{name = N, age = A, tags = T}) ->
    #{name => N, age => A, tags => T}.

from_map(#{name := N, age := A} = M) ->
    #person{name = N, age = A, tags = maps:get(tags, M, [])}.

record_vs_map() ->
    io:format("~n== 9) record 与 map 互转 ==~n"),
    P = new_person("alice", 30),
    d("to_map(P)（排序后）", sorted(to_map(P))),
    d("from_map(to_map(P)) 等价于 P", from_map(to_map(P)) =:= P),
    d("map 可以缺字段，用默认值补",
      sorted(to_map(from_map(#{name => "bob", age => 1})))),
    ok.

%% 把 map 转成「按 key 排序的列表」，输出才可逐字节比对
sorted(M) when is_map(M) -> lists:sort(maps:to_list(M)).

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
