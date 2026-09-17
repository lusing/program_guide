%% ============================================================
%% 10_maps 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/10_maps examples/10_maps/*_tests.erl
%%   erl -noshell -pa build/10_maps -eval "eunit:test('10_maps_tests'), halt()."
%% ============================================================
-module('10_maps_tests').

-include_lib("eunit/include/eunit.hrl").

%% record 定义要在使用它的每个模块里重复（或从 .hrl 引入）
-record(person, {name = "" :: string(),
                 age = 0 :: non_neg_integer(),
                 tags = [] :: [atom()]}).

access_test() ->
    M = #{name => "alice", age => 30},
    ?assertEqual("alice", maps:get(name, M)),
    ?assertEqual("unknown", maps:get(city, M, "unknown")),
    ?assertEqual({ok, 30}, maps:find(age, M)),
    ?assertEqual(error, maps:find(x, M)),
    ?assertEqual(2, maps:size(M)),
    ?assertEqual(#{a => 2}, maps:from_list([{a, 1}, {a, 2}])).  %% 重复键后者胜

update_test() ->
    M = #{a => 1},
    ?assertEqual(#{a => 1, b => 2}, M#{b => 2}),
    ?assertEqual(#{a => 9}, M#{a => 9}),
    ?assertEqual(M, M),                       %% 原值不变
    %% := 更新不存在的键 → badkey
    ?assertMatch({error, {badkey, zz}},
                 '10_maps':raises(fun(MM) -> MM#{zz := 1} end, M)),
    ?assertEqual({1, #{}}, maps:take(a, M)),
    ?assertEqual(error, maps:take(nope, M)).

take_shape_test() ->
    %% take 成功返回 {值, 新map}——值在前，容易记反
    ?assertEqual({2, #{a => 1}}, maps:take(b, #{a => 1, b => 2})).

count_words_test() ->
    ?assertEqual(#{"apple" => 2, "banana" => 1},
                 '10_maps':count_words(["apple", "banana", "apple"])).

order_test() ->
    %% 迭代顺序不保证：相等判断用排序后的 to_list
    ?assertEqual(lists:sort(maps:to_list(#{a => 1, b => 2})),
                 lists:sort(maps:to_list(#{b => 2, a => 1}))).

record_test() ->
    P = '10_maps':new_person("alice", 30),
    %% record 只在本模块的 -record 定义下可见；这里用标签元组验证形态
    ?assertEqual({person, "alice", 30, []}, P),
    ?assertEqual({person, "alice", 31, []}, '10_maps':birthday(P)),
    %% is_record 判定
    ?assert(is_record(P, person)),
    ?assertNot(is_record({person, "x"}, person)).   %% 字段数不对就不是该 record

label_test() ->
    ?assertEqual(minor, '10_maps':label('10_maps':new_person("kid", 10))),
    ?assertEqual(adult, '10_maps':label('10_maps':new_person("adult", 30))),
    ?assertEqual(senior, '10_maps':label('10_maps':new_person("old", 70))),
    ?assertEqual(anonymous, '10_maps':label(#person{})).

record_map_convert_test() ->
    P = '10_maps':new_person("alice", 30),
    ?assertEqual(P, '10_maps':from_map('10_maps':to_map(P))),
    %% map 缺字段时 from_map 用默认值补
    ?assertEqual({person, "bob", 1, []},
                 '10_maps':from_map(#{name => "bob", age => 1})).
