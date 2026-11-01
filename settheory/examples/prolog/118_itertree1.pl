:- encoding(utf8).
% 第 118 章：有限交错树路径、共尾枝前段与非法序数下降证书。
parent(0,0). parent(1,0). parent(2,0). parent(3,1).
parent(4,2). parent(5,3). parent(6,4).
extender(0,0,0,1). extender(1,1,0,2). extender(2,2,1,3).
extender(3,3,2,4). extender(4,4,3,5). extender(5,5,4,6).
% extender(E,Source,Target,Child)：E 属于 Source，却作用于 Target。
legal_application(E) :-
    extender(E,_,Target,Child), parent(Child,Target), Child \== Target.

path(0,[0]).
path(X,[X|Rest]) :- X > 0, parent(X,P), path(P,Rest).

branch_node(even,K,X) :- X is 2*K.
branch_node(odd,0,0).
branch_node(odd,K,X) :- K > 0, X is 2*K-1.
branch_prefix(Name,N,[X|Rest]) :-
    branch_node(Name,0,X),
    branch_prefix_from(Name,1,N,X,Rest).
branch_prefix_from(_,N,N,_,[]).
branch_prefix_from(Name,K,N,Prev,[X|Rest]) :-
    K < N, branch_node(Name,K,X), parent(X,Prev),
    K1 is K+1, branch_prefix_from(Name,K1,N,X,Rest).

cofinal_window(Name,Bound) :-
    forall(between(0,Bound,N),
           (between(0,8,K), branch_node(Name,K,X), X >= N)).

% j 在各段均取 x↦x+1；每一段都满足引理 3.81 的 j(s)>t。
bad_step(0,2,5,4). bad_step(2,4,4,3). bad_step(4,6,3,2).
bad_certificate([(0,2,5,4),(2,4,4,3),(4,6,3,2)]).
bad_step_ok(M,N,S,T) :- bad_step(M,N,S,T), J is S+1, J > T.

must(G) :- (G -> true ; throw(verification_failed(G))).
main :-
    format('==== 118~n'),
    must(forall(between(0,5,E),legal_application(E))),
    must(path(6,P6)), must(P6 == [6,4,2,0]),
    must(path(5,P5)), must(P5 == [5,3,1,0]),
    must(branch_prefix(even,4,Even)), must(Even == [0,2,4,6]),
    must(branch_prefix(odd,4,Odd)), must(Odd == [0,1,3,5]),
    must(cofinal_window(even,7)), must(cofinal_window(odd,7)),
    must(forall(bad_step(M,N,S,T),bad_step_ok(M,N,S,T))),
    format('合法边 6/6；Even=~w；Odd=~w~n',[Even,Odd]),
    format('两枝窗口共尾；非法下降证书三段全通过~n'),
    format('END ====~n').
