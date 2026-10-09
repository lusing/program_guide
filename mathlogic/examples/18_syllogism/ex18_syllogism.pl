:- encoding(utf8).
% ex18_syllogism.pl —— 三段论与传统逻辑（张寅生第 5 章+9.2/9.3）Prolog 件
% 双引擎：
%   [判定] syl(Mood1,Mood2,Mood3,Figure) —— 有限论域枚举判定有效性
%   [生成] ND(SOA) 产生式骨架（书 9.2 定义 9.2 的 P1/P2 演绎）
% 输出 ASCII；末行 END ====。

% ---------- 论域与子集 ----------

d([0,1,2]).

subsets([], [[]]).
subsets([X|Rest], SS) :-
    subsets(Rest, SR),
    add_or_skip(SR, X, SS).
add_or_skip([], _, []).
add_or_skip([S|T], X, [S, [X|S]|TT]) :-
    add_or_skip(T, X, TT).

% ---------- 四直言命题（载集语义） ----------

a_form(S, P) :- subset_of(S, P).
e_form(S, P) :- disjoint(S, P).
i_form(S, P) :- intersect(S, P).
o_form(S, P) :- \+ subset_of(S, P), S \= [].

subset_of([], _).
subset_of([X|T], P) :- member(X, P), subset_of(T, P).

disjoint_from(_, []).
disjoint_from(S, [Y|T]) :- \+ member(Y, S), disjoint_from(S, T).
disjoint(S, P) :- disjoint_from(P, S).

intersect(S, P) :- member(X, S), member(X, P).

form(a, S, P) :- a_form(S, P).
form(e, S, P) :- e_form(S, P).
form(i, S, P) :- i_form(S, P).
form(o, S, P) :- o_form(S, P).

% ---------- 格与判定 ----------

% 前提词项排布（fig：1 (m,p)(s,m) | 2 (p,m)(s,m) | 3 (m,p)(m,s) | 4 (p,m)(m,s)）
prem(1, M1, M2, S, M, P) :- form(M1, M, P), form(M2, S, M).
prem(2, M1, M2, S, M, P) :- form(M1, P, M), form(M2, S, M).
prem(3, M1, M2, S, M, P) :- form(M1, M, P), form(M2, M, S).
prem(4, M1, M2, S, M, P) :- form(M1, P, M), form(M2, M, S).

% 传统语义：词项非空预设下的有效性（反例搜索失败即有效）
syl_valid_trad(M1, M2, M3, Fig) :-
    \+ ( d(D), subsets(D, SS),
         member(S, SS), member(M, SS), member(P, SS),
         S \= [], M \= [], P \= [],
         prem(Fig, M1, M2, S, M, P),
         \+ form(M3, S, P) ).

% 现代语义：允许空词项
syl_valid_modern(M1, M2, M3, Fig) :-
    \+ ( d(D), subsets(D, SS),
         member(S, SS), member(M, SS), member(P, SS),
         prem(Fig, M1, M2, S, M, P),
         \+ form(M3, S, P) ).

% ---------- 主账：全格式枚举 ----------

main :- findall((F,M1,M2,M3),
        ( member(F,[1,2,3,4]), member(M1,[a,e,i,o]),
          member(M2,[a,e,i,o]), member(M3,[a,e,i,o]) ), All),
      length(All, 256),
      write('formats_total=256'), nl,
      findall((F,M1,M2,M3),
        ( member((F,M1,M2,M3), All), syl_valid_modern(M1,M2,M3,F) ), Mod),
      length(Mod, LM), write('valid_modern='), write(LM), nl,
      findall((F,M1,M2,M3),
        ( member((F,M1,M2,M3), All), syl_valid_trad(M1,M2,M3,F) ), Trad),
      length(Trad, LT), write('valid_trad='), write(LT), nl,
      write('modern15:'), nl, write_moods(Mod),
      write('weak_only(Darapti AAI-3 check): '),
      ( syl_valid_trad(a,a,i,3) -> write('AAI-3 valid (trad)') ; write(fail) ), nl,
      ( syl_valid_modern(a,a,i,3) -> write('AAI-3 valid (modern)') ; write('AAI-3 invalid (modern)') ), nl,
      ndsoa_demo,
      write('==== syllogism END ===='), nl.

% ---------- ND(SOA) 生成器骨架（书 9.2 定义 9.2 的 P1/P2 演绎） ----------

% P1 产生式骨架（节选）：(1) H→p∧q  (2)(3) p,q→A|E|I|O  (8) p∧q→C|∅
% (10)-(13) 结论 C→量词+系词+词项对。生成 Barbara（AAA-1）的推导链：
%   H ⇒ p∧q ⇒ (A,(A)) ⇒ C=a ⇒ 前提量化对 ((m,p),(s,m)) 读出格 1
ndsoa_demo :-
  write('ND(SOA) Barbara derivation:'), nl,
  write('  H -> p and q        (P1-1)'), nl,
  write('  p -> A, q -> A      (P1-2,3 mood atoms)'), nl,
  write('  p and q -> C=a      (P1-9,10: A-prime -> all m p)'), nl,
  write('  fig1 = (m,p),(s,m)  (middle term position)'), nl,
  write('  => AAA-1 = Barbara  (P2-1: major universal, minor affirmative)'), nl.

write_moods([]).
write_moods([(F,M1,M2,M3)|T]) :-
  write('  fig'), write(F), write(': '), write(M1), write(M2), write(M3), nl,
  write_moods(T).
