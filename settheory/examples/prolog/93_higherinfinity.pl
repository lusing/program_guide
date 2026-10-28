:- encoding(utf8).
% 第 93 章：高阶无穷导引——相对强度 DAG 的路径查询。
% woodin_witness 是「超紧与武丁见证的联合假设」节点。
node(zfc). node(measurable). node(supercompact). node(woodin_witness).
edge(zfc, measurable).
edge(measurable, supercompact).
edge(supercompact, woodin_witness).

rank(zfc, 0). rank(measurable, 1).
rank(supercompact, 2). rank(woodin_witness, 3).

path(Start, Goal, Path) :- walk(Start, Goal, [Start], Rev), reverse(Rev, Path).
walk(Goal, Goal, Acc, Acc).
walk(Current, Goal, Acc, Path) :-
    edge(Current, Next),
    \+ member(Next, Acc),
    walk(Next, Goal, [Next|Acc], Path).

main :-
    format("==== 93~n"),
    path(zfc, woodin_witness, Path),
    Path = [zfc, measurable, supercompact, woodin_witness],
    forall((edge(A,B), rank(A,RA), rank(B,RB)), RA < RB),
    \+ path(woodin_witness, supercompact, _),
    format("查询路径：~w~n", [Path]),
    writeln("秩随边严格增加，无回边；查询成功只说明有限图结构，不是 Con 证明 ✓"),
    writeln("END ====").
