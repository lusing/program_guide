:- encoding(utf8).
% ex40_sldprolog.pl —— SLD 与逻辑编程语义的工程面（Ben-Ari 2e §8.3/8.5 精选）
%
% 三个现场（与 Coq/Lean 的独立性机器件互补）：
%   1. cut：green cut 只剪重复解（答案集不变）/ red cut 剪掉真解
%      （纯逻辑语义被过程性偏离——SLD 树被砍分支）；
%   2. NAF：\+ 是「有限失败即否定」，不是经典否定——封闭世界
%      假设（CWA）的活标本；
%   3. CLP：约束传播先于标签生成（2e §8.5 的 clpfd 版）。
%
% 编码纪律：首行 encoding、输出纯 ASCII、公共谓词面。
% 注：clpfd 为 SWI 专有（GNU Prolog 用 fd 系内建）——跨引擎抽查
% 只跑前两个现场（见文件尾的 cross/0）。
:- use_module(library(clpfd)).
:- dynamic not_likes/2.

% ---------- 现场一：cut 的两面 ----------

% 无 cut：member 全解
member_nc(X, [X|_]).
member_nc(X, [_|T]) :- member_nc(X, T).

% green cut：首解即回（答案集=「是否在表里」这一查询语义不变
% ——对存在性查询而言；打印对照用 first/2）
first_gc(X, L) :- member_nc(X, L), !.

% red cut：过程性偏离——下面两条的语义不再是表的逻辑属性
red_broken(X, L) :- member_nc(X, L), X < 3, !.
red_broken(X, L) :- member_nc(X, L).

% ---------- 现场二：NAF ≠ 经典否定 ----------

likes(mary, food).
likes(mary, wine).
likes(john, wine).

% 「谁不喜欢食物」：NAF 版（有限失败）
dislikes_naf(P, F) :- \+ likes(P, F).

% 经典否定版需要显式的否定事实——没有就是「不知道」
dislikes_classical(P, F) :- not_likes(P, F).
% not_likes/2 无任何子句：经典版一无所知

% ---------- 现场三：CLP（约束传播先于标签） ----------

% 平方和拼图：X,Y ∈ 1..9，X*X + Y*Y #= 25，X < Y
% 传播：X*X ≤ 25 ⇒ X ≤ 5……标签只剩极少数组合
sq25(X, Y) :-
    X in 1..9, Y in 1..9,
    X*X + Y*Y #= 25,
    X #< Y,
    label([X, Y]).

% ---------- main ----------

main :-
    format('==== ex40 sld prolog semantics START ====~n', []),
    % 现场一
    findall(X, member_nc(X, [4,1,4,2]), All),
    format('member all solutions : ~w~n', [All]),
    findall(X, first_gc(X, [4,1,4,2]), FirstGC),
    format('green cut first-only : ~w  (same existence answer)~n', [FirstGC]),
    findall(X, red_broken(X, [4,1,2]), RedCut),
    format('red cut solutions    : ~w  (2,4 lost: semantics changed)~n', [RedCut]),
    % 现场二
    ( dislikes_naf(john, food) -> J = yes ; J = no ),
    ( dislikes_naf(mary, food) -> M = yes ; M = no ),
    format('NAF john dislikes food: ~w  (unknown => finite failure => neg)~n', [J]),
    format('NAF mary dislikes food: ~w  (known true => neg fails)~n', [M]),
    findall(P, dislikes_classical(P, food), ClPs),
    format('classical dislikes   : ~w  (no facts: nothing known)~n', [ClPs]),
    % 现场三
    catch(findall([X,Y], sq25(X,Y), Pairs), E,
          ( E = error(existence_error(procedure, _), _) ->
              Pairs = [[clpfd, unavailable]] ; throw(E))),
    format('CLP x^2+y^2=25, x<y  : ~w  (3,4 only)~n', [Pairs]),
    format('==== ex40 sld prolog semantics END ====~n', []).

% 跨引擎抽查入口（gprolog 无 clpfd，只跑前两现场）
cross :-
    findall(X, member_nc(X, [4,1,4,2]), All),
    format('member all: ~w~n', [All]),
    findall(P, dislikes_naf(P, food), NafPs),
    format('NAF dislikes food: ~w~n', [NafPs]).
