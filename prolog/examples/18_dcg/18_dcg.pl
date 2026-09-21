%% ============================================================================
%%  18_dcg.pl —— DCG（定子句文法）
%%
%%  --> 是 Prolog 里最优雅的语法糖。写
%%      sentence --> noun_phrase, verb_phrase.
%%  编译器会把它变成
%%      sentence(S0, S) :- noun_phrase(S0, S1), verb_phrase(S1, S).
%%  也就是「每个非终结符都是一个『吃一段输入』的谓词」，参数 S0/S 是
%%  「还没吃的输入」与「吃完剩下的输入」这个差值表（difference list）。
%%
%%  这就是为什么 DCG 既高效又不需要额外机制：它复用列表统一而已。
%%
%%  语法要点：
%%    [a,b]       终结符（吃掉列表 [a,b]）
%%    []          空，什么都不吃
%%    nonterm     非终结符（递归下去）
%%    {Goal}      插入一个普通 Prolog 目标，不消耗输入
%%    ,  ;        并且 / 或者
%%    phrase/2,3  从外部调用：phrase(NonTerm, Input) / phrase(NonTerm, Input, Rest)
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、最简单的识别器
%% ---------------------------------------------------------------------------
ab --> [a], [b].

%% 递归：a^n b^n（n >= 0）
anbn --> [].
anbn --> [a], anbn, [b].

%% 收集所有 token
tokens([]) --> [].
tokens([T | Ts]) --> [T], tokens(Ts).

demo_basic :-
    say("---- 1. 识别与拆分 ----"),
    phrase(ab, [a, b]),
    say("  phrase(ab, [a,b])        成功"),

    (   phrase(ab, [a, b, c], Rest)
    ->  format("  phrase(ab, [a,b,c], Rest)  成功，剩下 ~w~n", [Rest])
    ;   say("  phrase(ab, [a,b,c], Rest)  失败")
    ),
    (   phrase(ab, [b, a])
    ->  say("  phrase(ab, [b,a])        成功")
    ;   say("  phrase(ab, [b,a])        失败（顺序不对）")
    ),
    (   phrase(ab, [a])
    ->  say("  phrase(ab, [a])          成功")
    ;   say("  phrase(ab, [a])          失败（少一个终结符）")
    ),

    (   phrase(anbn, [a, a, b, b])
    ->  say("  phrase(anbn, [a,a,b,b])  成功（两个 a 配两个 b）")
    ;   say("  phrase(anbn, [a,a,b,b])  失败")
    ),
    (   phrase(anbn, [a, a, b])
    ->  say("  phrase(anbn, [a,a,b])    成功")
    ;   say("  phrase(anbn, [a,a,b])    失败（数量不配）")
    ),
    say("  anbn 只有两条规则就表达了「a 和 b 数量必须相等」——"),
    say("  这是上下文无关文法，用正则表达式写不出来。"),

    phrase(tokens(Ts), [p, q, r]),
    format("  phrase(tokens(Ts), [p,q,r])  Ts = ~w~n", [Ts]),

    say("  关键认识：DCG 规则 --> 会被展开成带两个额外参数的普通谓词。"),
    (   current_predicate(ab/2)
    ->  say("  查一下：ab//0 展开后确实对应 ab/2 —— 可以直接当普通谓词调")
    ;   say("  查一下：没找到 ab/2")
    ).

%% ---------------------------------------------------------------------------
%%  二、用 {} 插入普通目标
%% ---------------------------------------------------------------------------
%% 三个 x，同时把个数算出来
three_x(N) -->
    [x], [x], [x],
    {   N is 3
    }.

%% 校验型非终结符：吃掉一个数，并断言它在某区间内
small(N) -->
    [N],
    {   number(N),
        N >= 1,
        N =< 9
    }.

demo_braces :-
    say("---- 2. {Goal}：在 DCG 里插普通目标 ----"),
    phrase(three_x(N), [x, x, x]),
    format("  phrase(three_x(N), [x,x,x])   N = ~w~n", [N]),
    phrase(small(N2), [7]),
    format("  phrase(small(N), [7])         N = ~w~n", [N2]),
    (   phrase(small(_N3), [70])
    ->  say("  phrase(small(N), [70])        成功？")
    ;   say("  phrase(small(N), [70])        失败（70 不在 1..9）")
    ),
    say("  {} 里的目标不消耗输入，纯粹做计算与校验 —— 这是 DCG 与普通"),
    say("  谓词之间的桥。副作用（打印、assert）也都放在 {} 里。"),
    say("  注意：{} 里可以访问 DCG 外面的变量，但绑定会留在里面。"),
    say("  反面教材：在 DCG 里做重计算会让「生成」方向变得不可用，慎用。"),

    % 典型用途：语义动作（把结果算出来）
    phrase(double(8, D), [8]),
    format("  phrase(double(8,D), [8])      D = ~w（语义动作在 {} 里算）~n", [D]).

double(X, Y) -->
    [X],
    {   Y is X * 2
    }.

%% ---------------------------------------------------------------------------
%%  三、或与非终结符的参数
%% ---------------------------------------------------------------------------
%% 匹配一个「数字或字母」
atom_or_num(X) --> [X], {number(X)}.
atom_or_num(X) --> [X], {atom(X)}.

%% 匹配逗号分隔的一串数
numlist([N | Rest]) --> [N], {number(N)}, numlist_rest(Rest).
numlist_rest([N | Rest]) --> [','], [N], {number(N)}, numlist_rest(Rest).
numlist_rest([]) --> [].

demo_args :-
    say("---- 3. 或 / 参数 / 递归 ----"),
    phrase(atom_or_num(X), [42]),
    format("  atom_or_num(42)   X = ~w~n", [X]),
    phrase(atom_or_num(X2), [foo]),
    format("  atom_or_num(foo)  X = ~w~n", [X2]),

    phrase(numlist(Ns), [1, ',', 2, ',', 3]),
    format("  numlist([1,',',2,',',3]) = ~w~n", [Ns]),
    phrase(numlist(Ns2), [9]),
    format("  numlist([9])             = ~w~n", [Ns2]),

    say("  与普通谓词一样：一个非终结符可以有多条规则（这就是「或」），"),
    say("  也可以用分号写在一条里。DCG 里没有「if-then-else」的概念，"),
    say("  要条件分支就写在 {} 里，或者靠规则顺序 + !。"),

    % 用 tokens//1 取出全部终结符，再自己处理 —— 这在实战里很常用
    phrase(tokens(Ts3), [a, b, c, d]),
    length(Ts3, NT),
    format("  phrase(tokens(Ts), [a,b,c,d]) 取出 ~w 个 token~n", [NT]).

%% ---------------------------------------------------------------------------
%%  四、一个实用的例子：按空格切词
%% ---------------------------------------------------------------------------
%% 输入是字符码列表（第 15 章），输出是单词列表。
%% 思路：交替吃「空白」与「非空白」。
words([]) --> blanks.
words([W | Ws]) --> blanks, word(W), words(Ws).

blanks --> [].
blanks --> [C], {C =:= 32}, blanks.

%% 关键：word//1 必须【吃掉至少一个字符】，否则递归可能不消耗输入，
%% 于是「跳过空白 + 空单词 + 继续」这一条路径会无限循环下去。
%% 这是写 DCG 时最常见的死循环来源：忘了保证「每次递归都在前进」。
word([C | Cs]) --> [C], {C =\= 32}, word_rest(Cs).

word_rest([C | Cs]) --> [C], {C =\= 32}, word_rest(Cs).
word_rest([]) --> [].

demo_words :-
    say("---- 4. 实用例：把一行文本切成单词 ----"),
    phrase(words(Ws), "the quick brown fox"),
    format("  输入 \"the quick brown fox\"~n", []),
    format("  切出 ~w~n", [Ws]),
    say("  每个词都是「字符码列表」（也就是第 15 章的双引号串）。"),
    say("  要变成原子就 maplist(atom_codes, Ws, Atoms) 一下。"),

    % 注意 atom_codes/2 的参数顺序是 (原子, 码列表)，所以这里码在前要反着写
    maplist(atom_codes, Atoms, Ws),
    format("  转成原子：~w~n", [Atoms]),

    phrase(words(Ws2), "hello"),
    format("  输入 \"hello\" 切出 ~w~n", [Ws2]),
    phrase(words(Ws3), "  a   b  "),
    format("  连续空格与首尾空格也照切：~w~n", [Ws3]).

%% ---------------------------------------------------------------------------
%%  五、DCG 展开成了什么
%% ---------------------------------------------------------------------------
%% 这是 ab//0 的手写版本，与 ab --> [a], [b] 完全等价
ab_expanded(S0, S) :-
    S0 = [a | S1],
    S1 = [b | S].

demo_expansion :-
    say("---- 5. 自己写一遍 DCG 展开 ----"),
    % 手写版
    ab_expanded([a, b], Rest),
    format("  手写版 ab_expanded([a,b], Rest)      Rest = ~w~n", [Rest]),
    % DCG 版
    ab([a, b], Rest2),
    format("  DCG 版  ab([a,b], Rest)              Rest = ~w~n", [Rest2]),
    say("  ----------"),
    say("  ab --> [a],[b].  展开后等价于："),
    say("      ab(S0, S) :- S0 = [a|S1], S1 = [b|S].   % 也就是 S0 = [a,b|S]"),
    say("  也就是说：DCG 不过是把你从没写过的「差值表」参数替你补上了。"),
    say("  理解了这一点，phrase/3 的第三个参数（剩下的尾巴）就顺理成章了。"),
    say("  实战价值：不用 DCG 也能解析，但只要涉及「嵌套 + 回溯」，"),
    say("  手写差值表会迅速变成一团乱麻 —— 这是 DCG 存在的全部理由。").

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 18 开始 ====~n", []),
    say("DCG 把「吃输入」这件事变成谓词参数，于是文法和代码合二为一。"),
    say(""),

    demo_basic,     say(""),
    demo_braces,    say(""),
    demo_args,      say(""),
    demo_words,     say(""),
    demo_expansion, say(""),

    format("==== 18 结束 ====~n", []).
