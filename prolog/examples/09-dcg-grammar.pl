% ============================================================
%  09-dcg-grammar.pl —— 定子句文法（DCG）
%
%  运行（SWI）: swipl -q -f examples/09-dcg-grammar.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/09-dcg-grammar.pl --entry-goal main
%
%  DCG 就是「自动加两个参数」的语法糖：
%      a --> b, c.      等价于    a(S0, S) :- b(S0, S1), c(S1, S).
%  这两个参数通常叫「输入串 - 剩余串」，所以 DCG 天生适合解析。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、最小 DCG
% ------------------------------------------------------------
det --> [the].
det --> [a].
noun --> [cat].
noun --> [dog].
verb --> [eats].
verb --> [sees].

% 终结符写成 [xxx]，非终结符直接写名字，{} 里可以放任意 Prolog 目标
sentence --> det, noun, verb, det, noun.

demo_basic :-
    format("---- 最小 DCG ----~n", []),
    ( phrase(sentence, [the,cat,eats,a,dog]) -> R1 = '接受' ; R1 = '拒绝' ),
    format("  「the cat eats a dog」 -> ~w~n", [R1]),
    ( phrase(sentence, [the,cat,eats]) -> R2 = '接受' ; R2 = '拒绝' ),
    format("  「the cat eats」       -> ~w（不完整）~n", [R2]),
    % phrase/3 能拿到剩余部分
    ( phrase(sentence, [the,cat,eats,a,dog,then,sleeps], Rest)
    -> format("  句法成立后剩余：~w~n", [Rest])
    ;  true ),
    % 反向运行：DCG 也能「生成」
    findall(S, (length(S, 5), phrase(sentence, S)), Gen),
    length(Gen, NG),
    format("  反向生成 5 词句子，共 ~w 种~n", [NG]),
    ( length(First, 4), append(First, _, Gen) -> true ; First = Gen ),
    forall(member(G, First), format("    ~w~n", [G])),
    format("  （共 ~w 条，这里只列前 4 条）~n", [NG]).

% ------------------------------------------------------------
%  二、在 DCG 里带出结构（加参数）
% ------------------------------------------------------------
% np(N) 解析出一个名词短语，并把结果放在 N 里
np(np(D, N)) --> det(D), noun(N).
det(the) --> [the].
det(a)   --> [a].
noun(cat) --> [cat].
noun(dog) --> [dog].

demo_args :-
    format("---- 带参数的 DCG（直接造出语法树）----~n", []),
    phrase(np(Tree), [the, cat], Left),
    format("  「the cat」 -> ~q，剩余 ~w~n", [Tree, Left]).

% ------------------------------------------------------------
%  三、{} 里放任意 Prolog 代码（语义动作）
% ------------------------------------------------------------
% 数一数里面有多少个 x
count_x(0) --> [].
count_x(N) --> [x], count_x(N0), { N is N0 + 1 }.

% 用 {} 做条件判断
even_len --> [].
even_len --> [_,_], even_len.
odd_len  --> [_], even_len.

demo_semantic :-
    format("---- 语义动作 {} ----~n", []),
    phrase(count_x(N), [x,x,x]),
    format("  数 x 的个数：~w~n", [N]),
    ( phrase(even_len, [a,b]) -> format("  [a,b] 长度是偶数~n", []) ; true ),
    ( phrase(even_len, [a,b,c]) -> true ; format("  [a,b,c] 长度不是偶数~n", []) ),
    % {} 里也能做副作用
    phrase(debug_walk, [a,b,c]).

debug_walk --> [].
debug_walk --> [X], { format("    吃掉 ~w~n", [X]) }, debug_walk.

% ------------------------------------------------------------
%  四、递归与左递归（DCG 里左递归会死循环！）
% ------------------------------------------------------------
% 右递归：OK
digits([D | Ds]) --> digit(D), digits(Ds).
digits([])       --> [].
digit(D) --> [D], { between(0'0, 0'9, D) }.

demo_recursion :-
    format("---- 递归 ----~n", []),
    phrase(digits(Ds), [0'1, 0'2, 0'3]),
    format("  解析数字串（字符码）：~w~n", [Ds]),
    atom_codes(Atom, Ds),
    format("  转成原子：~w~n", [Atom]),
    format("  注意：DCG 里写左递归（expr --> expr, ...）会无限循环，~n", []),
    format("  必须用右递归或中间递归 + 层级拆分（见 10-dcg-parser）。~n", []).

% ------------------------------------------------------------
%  五、DCG 的展开式：看懂它就不神秘了
% ------------------------------------------------------------
% 手写的等价形式（不用 --> 语法）
det_hand(S0, S) :- S0 = [the | S].
det_hand(S0, S) :- S0 = [a | S].

demo_expand :-
    format("---- DCG 展开后长什么样 ----~n", []),
    det_hand([the, cat, sleeps], After),
    format("  det_hand([the,cat,sleeps], X) -> X = ~w~n", [After]),
    ( phrase(det(the), [the,cat,sleeps], After2) -> true ; After2 = none ),
    format("  phrase(det(the), 同上, X)     -> X = ~w~n", [After2]),
    format("  两者完全一样：DCG 只是把 S0/S 这两个参数藏起来了。~n", []).

% ------------------------------------------------------------
%  六、双引擎差异
% ------------------------------------------------------------
demo_portability :-
    format("---- 双引擎差异 ----~n", []),
    format("  · --> 语法、phrase/2、phrase/3 两个引擎都支持~n", []),
    format("  · phrase/4（带剩余+S0）只有 SWI 有，GNU 没有~n", []),
    format("  · SWI 有 library(dcg/basics) 提供 integer//1、number//1 等，~n", []),
    format("    GNU 没有，可移植代码里要自己写（见 10）~n", []),
    ( current_prolog_flag(dialect, D) -> format("  当前引擎：~w~n", [D]) ; true ).

run :-
    format("==== 09  定子句文法 DCG ====~n", []), nl,
    demo_basic,       nl,
    demo_args,        nl,
    demo_semantic,    nl,
    demo_recursion,   nl,
    demo_expand,      nl,
    demo_portability.

main :-
    (   catch((run, nl, format("==== 09 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 09 运行失败~n", []), halt(1)
    ).
