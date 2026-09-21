%% ============================================================================
%%  15_text.pl —— 文本处理
%%
%%  Prolog 没有「字符串类型」这一个概念，有四种表示法，而且默认值因引擎而异：
%%    原子        'abc'            整体是一个不可分割的原子
%%    字符码列表  "abc" == [97,98,99]      本教程统一用这个
%%    字符列表    ['a','b','c']    元素是单字符原子
%%    串对象      "abc"（SWI 独有）两个引擎行为不同，所以本教程不用
%%
%%  第一行 :- set_prolog_flag(double_quotes, codes). 就是在统一这件事：
%%  SWI 默认把 "abc" 当串对象，GNU 默认当字符码列表，不写这行两边就分道扬镳。
%%
%%  【重要】本教程所有「按字符数」的操作（长度、截取、拆分）都只在 ASCII 上做。
%%  原因：SWI 的 atom_length('逻辑') 是 2，GNU 是 6（算 UTF-8 字节），
%%  atom_codes 也一样一个给码点、一个给字节 —— 这是无法调和的差异。
%%  中文只用来「显示」（~s / ~w 输出字面量），绝不用来做长度与截取运算。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、四种表示法
%% ---------------------------------------------------------------------------
demo_representations :-
    say("---- 1. 四种表示法 ----"),

    % 原子
    A = abc,
    format("  'abc'         是原子      -> ~w~n", [A]),
    format("  atom('abc')               -> ~w~n", [true]),

    % 字符码列表（双引号 + codes 标志）
    S = "abc",
    format("  \"abc\"         字符码列表 -> ~w~n", [S]),

    % 字符列表
    Cs = ['a', 'b', 'c'],
    format("  ['a','b','c'] 字符列表   -> ~w~n", [Cs]),

    say("  三种之间可以互转，转换谓词是最常用的一批："),
    atom_codes(abc, Codes),
    format("    atom_codes(abc, L)      L = ~w~n", [Codes]),
    atom_chars(abc, Chars),
    format("    atom_chars(abc, L)      L = ~w~n", [Chars]),
    atom_codes(RoundTrip, Codes),
    format("    atom_codes(A, L) 反向    A = ~w~n", [RoundTrip]),
    say("  记住这条：双引号串是「整数列表」，所以要打印它必须用 ~s 而不是 ~w："),
    format("    用 ~~s 打双引号串 -> ~s~n", ["abc"]).

%% ---------------------------------------------------------------------------
%%  二、长度与截取（仅 ASCII）
%% ---------------------------------------------------------------------------
demo_length :-
    say("---- 2. 长度与截取 ----"),
    atom_length(hello, N),
    format("  atom_length(hello)        = ~w~n", [N]),

    % sub_atom(Atom, Start, Length, After, Sub)
    sub_atom(hello, 1, 3, _, Sub),
    format("  sub_atom(hello,1,3,_,S)   S = ~w~n", [Sub]),
    % 四个参数里任意三个给了，剩下的就能推出来
    sub_atom(hello, 0, _, 2, Head),
    format("  sub_atom(hello,0,_,2,S)   S = ~w（前缀）~n", [Head]),
    sub_atom(hello, _, _, 0, Tail),
    format("  sub_atom(hello,_,_,0,S)   S = ~w（后缀）~n", [Tail]),
    % 全枚举
    findall(Sub2, sub_atom(abc, _, 1, _, Sub2), Singles),
    format("  sub_atom(abc,_,1,_,S) 枚举 ~w~n", [Singles]),

    say("  注意 sub_atom 的下标从 0 开始，长度单位是「字符」。"),
    say("  判定前缀的最省事写法：sub_atom(Atom, 0, N, _, Prefix)，N 用前缀长度。"),
    sub_atom(hello, 0, 3, _, Prefix),
    (   Prefix == hel
    ->  say("    sub_atom(hello,0,3,_,P)  P = hel，确实是前缀")
    ;   say("    sub_atom(hello,0,3,_,P)  不是前缀")
    ).

%% ---------------------------------------------------------------------------
%%  三、拼接
%% ---------------------------------------------------------------------------
%% 没有 atomics_to_string/atomic_list_concat（SWI 专有），自己写一个：
%% 用 foldl 的递归骨架把列表拼成原子
join_atoms([], '').
join_atoms([A], A) :- !.
join_atoms([A | T], R) :-
    join_atoms(T, Rest),
    atom_concat(A, Rest, R).

%% 带分隔符的版本
join_with(_, [], '').
join_with(_, [A], A) :- !.
join_with(Sep, [A | T], R) :-
    join_with(Sep, T, Rest),
    atom_concat(Sep, Rest, R1),
    atom_concat(A, R1, R).

%% 按「分隔字符」把原子切成若干段。
%% 思路：转成字符码列表，在码列表上手工切 —— 完全不依赖引擎专有谓词。
split_on(Atom, Sep, Parts) :-
    char_code(Sep, SepCode),
    atom_codes(Atom, Codes),
    split_codes(Codes, SepCode, Parts).

split_codes([], _, []).
split_codes(Codes, Sep, [Part | Rest]) :-
    take_until(Codes, Sep, PartCodes, Remainder),
    atom_codes(Part, PartCodes),
    (   Remainder = [Sep | Tail]
    ->  split_codes(Tail, Sep, Rest)
    ;   Rest = []
    ).

take_until([], _, [], []).
take_until([C | T], Sep, [], [C | T]) :-
    C =:= Sep,
    !.
take_until([C | T], Sep, [C | PT], R) :-
    take_until(T, Sep, PT, R).

demo_concat :-
    say("---- 3. 拼接与切分 ----"),
    atom_concat(ab, cd, X),
    format("  atom_concat(ab,cd,X)     X = ~w~n", [X]),
    % 反向用：给定整体，枚举拆法
    % 用 pair/2 包起来、用 ~q 打印，空原子 '' 才会显式显示出来
    findall(pair(P, S), atom_concat(P, S, abc), Splits),
    format("  atom_concat 反向枚举      ~q~n", [Splits]),

    join_atoms([a, b, c], J1),
    format("  join_atoms([a,b,c])      ~w~n", [J1]),
    join_with('-', ['2024', '09', '21'], J2),
    format("  join_with('-', 日期)     ~w~n", [J2]),

    split_on('2024-09-21', '-', Parts),
    format("  split_on('2024-09-21','-')  ~w~n", [Parts]),
    split_on(base_case_naming, '_', Parts2),
    format("  split_on(base_case_naming,'_')  ~w~n", [Parts2]),
    say("  这个 split_on/3 完全用字符码 + 递归自己写的，两套引擎上逐字节一致。"),
    say("  内建的 split_string/4 与 atomic_list_concat/3 都是 SWI 专有，所以不用。").

%% ---------------------------------------------------------------------------
%%  四、字符与数字的互转
%% ---------------------------------------------------------------------------
demo_convert :-
    say("---- 4. 字符码与数字的互转 ----"),
    char_code(a, C),
    format("  char_code(a, C)           C = ~w~n", [C]),
    char_code(Ch, 98),
    format("  char_code(C, 98)          C = ~w~n", [Ch]),

    number_codes(123, NC),
    format("  number_codes(123, L)      L = ~w~n", [NC]),
    number_codes(N, NC),
    format("  number_codes(N, L) 反向   N = ~w~n", [N]),

    % 手写「数字 → 原子」：不用 number_codes 也能做
    digits_of(2026, Ds),
    format("  digits_of(2026)（手写）   ~w~n", [Ds]),

    say("  char_code(C, N) 的 C 是「单字符原子」，不是字符码列表，别混。"),
    say("  atom_codes 处理的是「整体字符串」，char_code 处理的是「单个字符」。").

%% 手写「整数 → 数字列表」：用 / 与 mod 逐位取出来再反转
digits_of(N, Ds) :-
    digits_rev(N, Rev),
    reverse(Rev, Ds).

digits_rev(N, [N]) :-
    N < 10,
    !.
digits_rev(N, [D | T]) :-
    D is N mod 10,
    N1 is N // 10,
    digits_rev(N1, T).

%% ---------------------------------------------------------------------------
%%  五、手写 to_upper（upcase_atom/2 是 SWI 专有）
%% ---------------------------------------------------------------------------
upper_code(C, U) :-
    C >= 97,
    C =< 122,
    !,
    U is C - 32.
upper_code(C, C).

to_upper(Atom, Upper) :-
    atom_codes(Atom, Codes),
    maplist(upper_code, Codes, Upped),
    atom_codes(Upper, Upped).

demo_upper :-
    say("---- 5. 手写大小写转换（不用 SWI 专有谓词）----"),
    to_upper(hello, U1),
    format("  to_upper(hello)  = ~w~n", [U1]),
    to_upper('Hello', U2),
    format("  to_upper('Hello') = ~w（非字母原样保留）~n", [U2]),
    say("  upcase_atom/2 与 downcase_atom/2 都是 SWI 专有，"),
    say("  GNU Prolog 没有，所以自己用 char_code + maplist 实现最稳。"),
    say("  代价：只对 ASCII 有效 —— 这也正好避开了下面的中文坑。").

%% ---------------------------------------------------------------------------
%%  六、中文为什么不能做「字符运算」
%% ---------------------------------------------------------------------------
demo_cjk :-
    say("---- 6. 中文：能显示，不能数 ----"),
    say("  显示中文完全没问题，用 ~s 或 ~w 打原子/码列表都可以："),
    format("    ~s~n", ["逻辑编程（用 ~s 打双引号码列表）"]),
    format("    ~w~n", ['逻辑编程（用 ~w 打原子）']),
    say("  但是下面这些操作两套引擎结论不同，绝对不能写进可移植代码："),
    say("    atom_length('逻辑编程')  SWI 给 4（Unicode 码点），GNU 给 12（UTF-8 字节）"),
    say("    atom_codes('逻辑', L)    SWI 给 [36923,36753]，GNU 给 [233,128,187,232,190,145]"),
    say("    sub_atom('逻辑编程',1,2,_,S)  SWI 给「辑编」，GNU 给半个字符"),
    say("  结论：中文只用于「常量、消息、显示」，涉及计数与截取一律用 ASCII。"),
    say("  真要处理中文，就在宿主语言里做，或把文本当字节数组、自己规定编码。"),
    say("  本教程的做法是：中文全部走常量字面量，逻辑全在 ASCII 上跑。"),
    % 只做一个「安全」的示范：按码点相等判断
    (   '逻辑' == '逻辑'
    ->  say("  原子相等判断是安全的：'逻辑' == '逻辑' 成立")
    ;   say("  原子相等判断不成立")
    ).

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
    format("==== 15 开始 ====~n", []),
    say("Prolog 的「字符串」是原子或字符列表，没有专门的字符串类型。"),
    say(""),

    demo_representations, say(""),
    demo_length,          say(""),
    demo_concat,          say(""),
    demo_convert,         say(""),
    demo_upper,           say(""),
    demo_cjk,             say(""),

    format("==== 15 结束 ====~n", []).
