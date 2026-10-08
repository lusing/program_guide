:- use_module(library(lists)).
coloring(_, [], _, []).
coloring(Edges, [V|Vs], K, [V-C|As]) :-
    between(1, K, C),
    \+ (member(U-C, As), adj_member(U-V, Edges)),
    coloring(Edges, Vs, K, As).
adj_member(U-V, E) :- member(U-V, E).
adj_member(U-V, E) :- member(V-U, E).
k4e([0-1,0-2,0-3,1-2,1-3,2-3]).
