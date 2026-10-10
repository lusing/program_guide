:- encoding(utf8).
% ex40_roughset.pl —— 粗糙集与双直觉主义（Prolog 通道）
% 三段：粗糙集三区代数（等价关系 {0}|{1,2} 上全子集枚举账）；
% 双模态 S4 的 Ax.a 帧条件抽查（3 世界小帧族）；余直觉减法在
% 2 链上的后承电池。协议：utf8 源、ASCII 出、END ==== 收尾。


% ---------- 1. 粗糙集三区代数 ----------
% 等价关系 eq(X,Y)：{0}|{1,2} 分块
eq(0,0).
eq(1,1). eq(1,2).
eq(2,1). eq(2,2).

in_set([X|_], X) :- !.
in_set([_|T], X) :- in_set(T, X).

all_sets(S) :- member(S, [[],[0],[1],[2],[0,1],[0,2],[1,2],[0,1,2]]).

compl([], [0,1,2]).
compl([0], [1,2]).
compl([1], [0,2]).
compl([2], [0,1]).
compl([0,1], [2]).
compl([0,2], [1]).
compl([1,2], [0]).
compl([0,1,2], []).

cls(X, C) :- findall(Y, eq(X,Y), C).

subset([], _).
subset([X|T], Y) :- in_set(Y, X), subset(T, Y).

intersects(A, B) :- member(X, A), in_set(B, X).

flatten_cls([], []).
flatten_cls([X|T], U) :- cls(X,C), append(C,R,U), flatten_cls(T,R).

% I(G)：全部含于 G 的类之并；C(G)：与 G 相交的类之并
int_(G, I) :-
    findall(X, (between(0,2,X), cls(X,C), subset(C,G)), Xs),
    flatten_cls(Xs, I0), sort(I0, I).

clo_(G, C) :-
    findall(X, (between(0,2,X), cls(X,Cl), intersects(Cl,G)), Xs),
    flatten_cls(Xs, C0), sort(C0, C).

intersection_([], _, []).
intersection_([X|T], Y, [X|R]) :- in_set(Y, X), !, intersection_(T, Y, R).
intersection_([_|T], Y, R) :- intersection_(T, Y, R).

subtract_([], _, []).
subtract_([X|T], Y, R) :- in_set(Y, X), !, subtract_(T, Y, R).
subtract_([X|T], Y, [X|R]) :- subtract_(T, Y, R).

bnd_(G, B) :- clo_(G, C), int_(G, I), subtract_(C, I, B).

posneg_bnd(G, POS, BND, NEG) :-
    int_(G, POS), bnd_(G, BND), clo_(G, C), compl(C, NEG).

% 账：I(-G) = -C(G) 全部 8 个子集
duality_count(Count) :-
    aggregate_all(count,
      (all_sets(S), compl(S,NS), int_(NS,I), clo_(S,C), compl(C,NC), I=NC),
      Count).

% 反例账：BND 的交包含不成立（G={1},H={2}）
bnd_counter :-
    G1=[1], H1=[2],
    bnd_(G1,BG), bnd_(H1,BH), intersection_(BG,BH,Both),
    intersection_(G1,H1,Empty), Empty==[],
    bnd_(Empty,BE), \+ subset(Both, BE).

% ---------- 2. 双模态 S4：Ax.a 帧条件抽查 ----------
rel(id3, 0,0). rel(id3, 1,1). rel(id3, 2,2).
rel(un3, W, W2) :- between(0,2,W), between(0,2,W2).
rel(ch, 0,0). rel(ch, 1,1). rel(ch, 2,2). rel(ch, 0,1). rel(ch, 0,2).

sr_subset(S, R) :- \+ (rel(S,W,W2), \+ rel(R,W,W2)).

bit0(Val, W) :- I is Val >> W, I /\ 1 =:= 1.

box_p(R, Val, W) :- \+ (rel(R,W,W2), \+ bit0(Val, W2)).
box_p_s(S, R, Val, W) :-
    \+ (rel(S,W,W2), \+ box_p(R, Val, W2)).

% Ax.a：□_R p ⊃ □_S □_R p 在帧上有效
axa_valid(R, S) :-
    \+ (between(0,2,W), between(0,7,Val),
        box_p(R, Val, W), \+ box_p_s(S, R, Val, W)).

% ---------- 3. 余直觉减法（2 链） ----------
le(0,0). le(0,1). le(1,1).

catom(V, N, W) :- I is V >> (2*N + W), I /\ 1 =:= 1.

ev(val(_), cbot, _, false).
ev(val(V), ca(N), W, B) :- (catom(V,N,W) -> B=true ; B=false).
ev(val(V), cor(A,B_), W, T) :- ev(val(V),A,W,T1), ev(val(V),B_,W,T2),
    (T1=true -> T=true ; T=T2).
ev(val(V), cdiff(A,B_), W, T) :-
    (   le(W,W2), ev(val(V),A,W2,true), \+ ev(val(V),B_,W2,true)
    ->  T=true ; T=false), !.

cseq(A, B) :-
    \+ (between(0,1,W), between(0,15,V),
        ev(val(V),A,W,true), \+ ev(val(V),B,W,true)).

% ---------- 主程序 ----------
main :-
    duality_count(D),
    S1=[0,2], posneg_bnd(S1, P1, B1, N1),
    format("duality holds on ~d/8 subsets~n", [D]),
    format("G=~w POS=~w BND=~w NEG=~w~n", [S1,P1,B1,N1]),
    (bnd_counter -> BC=ok ; BC=fail),
    (axa_valid(id3, id3), sr_subset(id3, id3) -> A1=ok ; A1=fail),
    (axa_valid(ch, un3) -> A2=fail ; A2=ok),   % S=un3⊄R=ch：应无效
    (axa_valid(un3, un3) -> A3=ok ; A3=fail),
    format("bnd-counter=~w  Ax.a id3/id3=~w  un3/ch invalid-as-expected=~w  un3/un3=~w~n",
           [BC,A1,A2,A3]),
    (cseq(ca(0), cdiff(ca(0), cbot)) -> E1=ok ; E1=fail),
    (cseq(cdiff(ca(0), ca(1)), ca(0)) -> E2=fail ; E2=ok),
    (cseq(cdiff(ca(0), cor(ca(1), ca(2))),
          cor(cdiff(ca(0), ca(1)), cdiff(ca(0), ca(2)))) -> E3=ok ; E3=fail),
    format("C|-C-bot=~w  C-D|-C refuted=~w  distrib=~w~n", [E1,E2,E3]),
    writeln("END ===="),
    halt.
