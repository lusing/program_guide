:- encoding(utf8).
% 第 119 章：有限策略、坏目标搜索与有限良枝证书。
c_strategy(0,0).
c_strategy(K,P) :- K > 0, P is K-1.
bad_strategy(_,6).

legal_target(K,P) :- K < 6, P >= 0, P =< K, c_strategy(K,P).

% run(Strategy,Fuel,K,Parents,Status)：Parents 按时间正序累积。
run(_,0,K,[],done) :- K >= 6.
run(_,0,K,[],out_of_fuel) :- K < 6.
run(Strategy,Fuel,K,Parents,Status) :-
    Fuel > 0, K >= 6, Parents = [], Status = done.
run(Strategy,Fuel,K,[P|Rest],Status) :-
    Fuel > 0, K < 6,
    ( Strategy = c -> c_strategy(K,P) ; bad_strategy(K,P) ),
    legal_target(K,P),
    F1 is Fuel-1, K1 is K+1,
    run(Strategy,F1,K1,Rest,Status).
run(Strategy,Fuel,K,[],illegal) :-
    Fuel > 0, K < 6,
    ( Strategy = c -> c_strategy(K,P) ; bad_strategy(K,P) ),
    \+ legal_target(K,P).

% Even 的有限坏证书逐项下降；Odd 在此有限证书表中为良枝。
bad_step(even,(0,2,5,4)).
bad_step(even,(2,4,4,3)).
bad_step(even,(4,6,3,2)).
descending_step(S,T) :- J is S+1, J > T.
bad_branch(B) :-
    B = even,
    forall(bad_step(B,(_,_,S,T)),descending_step(S,T)).
good_branch(odd).
select_good_branch(B) :- good_branch(B).

must(G) :- (G -> true ; throw(verification_failed(G))).
main :-
    format('==== 119~n'),
    must(run(c,6,0,Parents,done)), must(Parents == [0,0,1,2,3,4]),
    must(run(c,5,0,_,out_of_fuel)),
    must(run(bad,6,0,_,illegal)),
    must(bad_branch(Bad)), must(Bad == even),
    must(select_good_branch(Good)), must(Good == odd),
    format('六步策略完成；短燃料与非法目标均被拒绝~n'),
    format('坏枝搜索=~w；有限选枝证书=~w~n',[Bad,Good]),
    format('END ====~n').
