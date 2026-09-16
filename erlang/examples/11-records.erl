%% ============================================================
%% 11 - Record
%%
%%    Record 是「带名字的元组」的语法糖：编译期展开成元组，
%%    所以访问字段是 O(1) 的 element/2，但字段名**只在编译期存在**，
%%    运行期拿不到字段名（这也是 record 与 map 最大的差别）。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/11-records.erl
%% 运行：
%%   erl -noshell -pa build -run '11-records' main -s init stop
%% ============================================================
-module('11-records').

%% record 定义必须以大写字母开头（它是一个「标签原子」）
-record(person, {name = "" :: string(),
                 age = 0 :: non_neg_integer(),
                 tags = [] :: [atom()]}).

%% 嵌套 record：地址里包含一个 person
-record(address, {city = "" :: string(),
                  zip = "" :: string()}).

%% 1) 创建、访问、更新
-export([main/0, new/2, birthday/1, label/1, to_map/1, from_map/1]).

main() ->
    create_access_update(),
    matching_and_guards(),
    tuple_representation(),
    nested_records(),
    record_vs_map(),
    io:format("~n==== 11 结束 ====~n").

create_access_update() ->
    io:format("== 1) 创建、访问、更新 ==~n"),
    P = new("alice", 30),
    %% 字段访问用 #record.field
    d("#person.name", P#person.name),
    d("#person.age", P#person.age),
    d("#person.tags 的默认值", P#person.tags),
    %% 更新用 #record{field = Value}
    d("birthday(P) 的 age", (birthday(P))#person.age),
    d("原 P 不受影响（不可变）", P#person.age),
    %% 一次更新多个字段
    d("P#person{name = \"bob\", age = 1}", sorted_record(P#person{name = "bob", age = 1})),
    %% 只写字段名是「取该字段作为值」的简写
    d("#person{name = N} = P 之后 N", begin #person{name = N} = P, N end),
    ok.

new(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #person{name = Name, age = Age}.

birthday(P = #person{age = A}) ->
    P#person{age = A + 1}.

%% 2) 在模式与 guard 里用 record
%% ------------------------------------------------------------
%% 模式里可以直接解构字段；guard 里可以用 is_record/2 判断类型。
label(#person{age = A}) when A < 18 -> minor;
label(#person{age = A}) when A < 65 -> adult;
label(#person{name = ""}) -> anonymous;
label(#person{}) -> senior.

matching_and_guards() ->
    io:format("~n== 2) 模式与 guard ==~n"),
    d("label(未成年人)", label(new("kid", 10))),
    d("label(成年人)", label(new("adult", 30))),
    d("label(老人)", label(new("old", 70))),
    d("label(匿名人)", label(#person{})),
    d("is_record(P, person)", is_record(new("a", 1), person)),
    d("is_record(P, address)（另一个 record 类型）", is_record(new("a", 1), address)),
    d("用 is_record 做 guard 分流",
      (fun(X) when is_record(X, person) -> is_person;
           (_) -> not_person
        end)(new("a", 1))),
    %% 匹配具体字段值
    d("按姓名匹配", name_of(#person{name = "alice"})),
    ok.

name_of(#person{name = N}) -> N.

%% 3) record 的运行期形态就是元组
%% ------------------------------------------------------------
tuple_representation() ->
    io:format("~n== 3) 运行期是元组 ==~n"),
    P = new("alice", 30),
    %% record 的第一个元素是标签原子，之后是各字段，顺序与定义一致
    d("tuple_size(P)", tuple_size(P)),
    d("element(1, P) 是标签", element(1, P)),
    d("element(3, P) 是 age", element(3, P)),
    %% 所以可以用普通元组语法操作 record（但完全是坏味道，仅作演示）
    d("可以直接用元组构造出等价的 record", {person, "alice", 30, []} =:= P),
    %% record_info 是编译期展开的，能拿到字段信息
    d("record_info(fields, person)（编译期展开）",
      record_info(fields, person)),
    d("record_info(size, person)", record_info(size, person)),
    ok.

%% 4) 嵌套 record
%% ------------------------------------------------------------
nested_records() ->
    io:format("~n== 4) 嵌套 record ==~n"),
    A = #address{city = "beijing", zip = "100000"},
    %% 更新嵌套字段要用「取出 → 改 → 放回」
    A2 = A#address{zip = "200000"},
    d("A2#address.zip", A2#address.zip),
    d("原 A 不变", A#address.zip),
    ok.

%% 5) record 与 map 的取舍
%% ------------------------------------------------------------
%% record：
%%   优点 —— 字段名编译期检查、访问是 element/2（常数时间）、内存更省
%%   缺点 —— 字段名运行期不可见（没法动态按名字取）、不能跨模块共享定义
%% map：
%%   优点 —— 字段名运行期可见（maps:keys / maps:get）、结构可以动态生长
%%   缺点 —— 字段拼错只能到运行期才发现、访问是哈希查找
%%
%% 经验：**程序内部的结构用 record，跨模块/跨进程传递、或结构会变用 map**。
to_map(#person{name = N, age = A, tags = T}) ->
    #{name => N, age => A, tags => T}.

from_map(#{name := N, age := A} = M) ->
    #person{name = N, age = A, tags = maps:get(tags, M, [])}.

record_vs_map() ->
    io:format("~n== 5) record 与 map 互转 ==~n"),
    P = new("alice", 30),
    d("to_map(P)（排序后）", sorted(to_map(P))),
    d("from_map(to_map(P)) 等价于 P", from_map(to_map(P)) =:= P),
    d("map 可以缺字段，用默认值补", sorted(to_map(from_map(#{name => "bob", age => 1})))),
    ok.

%% 把 record 转成排序后的 proplist，输出才稳定
sorted_record(R) when is_tuple(R) ->
    {Label, FieldNames} = {element(1, R), record_info(fields, person)},
    Values = lists:map(fun(I) -> element(I + 1, R) end, lists:seq(1, tuple_size(R) - 1)),
    {Label, lists:sort(lists:zip(FieldNames, Values))}.

sorted(M) when is_map(M) -> lists:sort(maps:to_list(M)).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
