:- encoding(utf8).
% 第 61 章 无穷逻辑与决定逻辑：有限开博弈胜策略搜索（Prolog 通道）
% Gale-Stewart 定理与例 24.14（开博弈决定性）的有限影子：Zermelo 定理。
% 胜集 winset/2（I 的胜前缀表）；gseval/4 后向归纳（谁有必胜策略）。
:- set_prolog_flag(stdout, encoding(utf8)).

% winset(+Prefix, -Winner)  Prefix 最新步在表头
% 博弈一：I 的奇数步全 true 即胜（首步+第三步双 t）
winset(Prefix, W) :- prefix_match(p1, Prefix, W).
prefix_match(p1, [true, _, true | _], true)  :- !.
prefix_match(p1, [false, false | _], false) :- !.
% 未定
prefix_match(_, _, undef).
prefix_match(p2, [true, true | _], false) :- !.
prefix_match(p2, [false, false | _], true) :- !.

% 博弈二：I 的双 true 判负（II 擒双 t）
winset2(Prefix, W) :- prefix_match(p2, Prefix, W).

% gseval(+WS, +Depth, +Player, +Pos, -Winner)
%   WS: winset 或 winset2；开博弈语义：depth 耗尽未命中 = II 胜（false）
gseval(WS, 0, _, Pos, W) :- call(WS, Pos, W0), (W0 = undef -> W = false ; W = W0), !.
gseval(WS, D, Player, Pos, W) :-
    D > 0,
    call(WS, Pos, W0),
    ( W0 \= undef -> W = W0
    ; D1 is D - 1, P1 is (Player + 1) mod 2,
      ( Player =:= 0
      -> ( gseval(WS, D1, P1, [true | Pos], W1),
           ( W1 == true -> W = true
           ; gseval(WS, D1, P1, [false | Pos], W0b),
             ( W0b == true -> W = true ; W = false ) ) )
      ; ( gseval(WS, D1, P1, [true | Pos], W1),
          ( W1 == false -> W = false
          ; gseval(WS, D1, P1, [false | Pos], W0b),
            ( W0b == false -> W = false ; W = true ) ) )
      )
    ), !.

main :-
    gseval(winset, 4, 0, [], W1),
    gseval(winset2, 4, 0, [], W2),
    ( W1 == true -> write('game1: first player (I) has winning strategy'), nl ; true ),
    ( W2 == false -> write('game2: second player (II) has winning strategy'), nl ; true ),
    write('zermelo: both games decided (finite open games)'), nl,
    write('END ===='), nl.
