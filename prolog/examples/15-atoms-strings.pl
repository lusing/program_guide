% ============================================================
%  15-atoms-strings.pl —— 原子、字符码与「字符串」
%
%  运行（SWI）: swipl -q -f examples/15-atoms-strings.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/15-atoms-strings.pl --entry-goal main
%
%  Prolog 里真正的文本类型只有两种：原子（atom）和字符码列表（codes）。
%  这是两个引擎差异最大的一块，本例全部用可移植写法。
% ============================================================

% 关键一行：让 "abc" 在两个引擎里都表示字符码列表
:- set_prolog_flag(double_quotes, codes).

run :-
    format("==== 15  原子、字符码与文本 ====~n", []), nl,
    demo_types,    nl,
    demo_convert,  nl,
    demo_split,    nl,
    demo_search,   nl,
    demo_format_atom, nl,
    demo_portability.

% ------------------------------------------------------------
%  一、三种表示法
% ------------------------------------------------------------
demo_types :-
    format("---- 三种文本表示 ----~n", []),
    format("  原子 atom      ：'hello' 或 hello，不可变、被内部化、比较是 O(1)~n", []),
    format("  字符码 codes   ：[104,101,108,108,111]，就是普通整数列表~n", []),
    format("  字符串 string  ：只有 SWI 有独立类型，GNU 里 \"x\" 就是 codes~n", []),
    atom_codes(hello, Cs),
    format("  atom_codes(hello, X) -> ~w~n", [Cs]),
    ( atom(hello) -> format("  atom(hello) -> 真~n", []) ; true ),
    ( is_list(Cs) -> format("  字符码列表就是普通列表，所有列表谓词都能用~n", []) ; true ).

% ------------------------------------------------------------
%  二、互转
% ------------------------------------------------------------
demo_convert :-
    format("---- 互转 ----~n", []),
    atom_codes(abc, C1),
    format("  atom_codes(abc, X)      -> ~w~n", [C1]),
    atom_chars(abc, C2),
    format("  atom_chars(abc, X)      -> ~w（单字符原子）~n", [C2]),
    number_codes(123, C3),
    format("  number_codes(123, X)    -> ~w~n", [C3]),
    number_chars(4.5, C4),
    format("  number_chars(4.5, X)    -> ~w~n", [C4]),
    (   catch(atom_number('42', N1), _, fail)
    ->  format("  atom_number('42', X)    -> ~w~n", [N1])
    ;   format("  atom_number/2 本引擎没有；可移植做法是 number_codes/2：~n", []),
        number_codes(N2, [0'4, 0'2]),
        format("    number_codes(X, [0'4,0'2]) -> ~w~n", [N2])
    ),
    atom_concat(pro, log, A1),
    format("  atom_concat(pro,log,X)  -> ~w~n", [A1]),
    atom_concat(Pre, log, prolog),
    format("  atom_concat(X,log,prolog) -> ~w（反向拆解）~n", [Pre]),
    atom_length(prolog, L1),
    format("  atom_length(prolog, X)  -> ~w~n", [L1]),
    char_code(a, CC),
    format("  char_code(a, X)         -> ~w~n", [CC]),
    format("  0'a 这种写法就是 a 的字符码：~w~n", [0'a]).

% ------------------------------------------------------------
%  三、切分与拼接（SWI 有现成的，GNU 没有 —— 这里给可移植版）
% ------------------------------------------------------------
% 按分隔符切分原子，结果是原子列表
split_atom(Atom, Sep, Parts) :-
    atom_codes(Atom, Cs),
    atom_codes(Sep, [SepCode]),
    split_codes(Cs, SepCode, Groups),
    maplist(atom_codes, Parts, Groups).

split_codes([], _, [[]]).
split_codes([C | Cs], Sep, [G | Gs]) :-
    (   C =:= Sep
    ->  G = [], split_codes(Cs, Sep, Gs)
    ;   G = [C | G1], split_codes(Cs, Sep, [G1 | Gs])
    ).

join_atoms([], _, '').
join_atoms([A], _Sep, A).
join_atoms([A | As], Sep, Out) :-
    join_atoms(As, Sep, Rest),
    atom_concat(Sep, Rest, Tmp),
    atom_concat(A, Tmp, Out).

demo_split :-
    format("---- 切分与拼接（自写，跨引擎）----~n", []),
    split_atom('a,b,c', ',', Ps),
    format("  split_atom('a,b,c', ',', X) -> ~w~n", [Ps]),
    split_atom('2026-09-15', '-', Ds),
    format("  split_atom('2026-09-15', '-', X) -> ~w~n", [Ds]),
    join_atoms([a, b, c], '-', J),
    format("  join_atoms([a,b,c], '-', X) -> ~w~n", [J]),
    format("  SWI 上等价写法：atomic_list_concat/3 与 split_string/4~n", []),
    format("  GNU 上没有，所以本教程统一用自写版本。~n", []).

% ------------------------------------------------------------
%  四、查找与子串
% ------------------------------------------------------------
demo_search :-
    format("---- sub_atom/5 ----~n", []),
    sub_atom(prolog, 0, 3, _, Sub1),
    format("  sub_atom(prolog, 0, 3, _, X) -> ~w~n", [Sub1]),
    sub_atom(prolog, _, 3, _, Sub2),
    format("  sub_atom(prolog, _, 3, _, X) -> ~w（第一个长度 3 的子串）~n", [Sub2]),
    findall(S, sub_atom(aba, _, 2, _, S), All),
    format("  'aba' 里所有长度 2 的子串：~w（有重复，需要时先去重）~n", [All]),
    sub_atom('hello world', Before, Len, After, world),
    format("  反向定位 world：前 ~w 字符，长 ~w，后 ~w 字符~n", [Before, Len, After]).

% ------------------------------------------------------------
%  五、把格式化结果装进原子
% ------------------------------------------------------------
% SWI 有 format(atom(A), ...)，GNU 没有。
% GNU 上的可移植替代：先写临时文件，再读回来（笨但通用）。
atom_format(Atom, Fmt, Args) :-
    (   current_prolog_flag(dialect, swi)
    ->  format(atom(Atom), Fmt, Args)
    ;   Tmp = '/tmp/prolog-15-fmt.tmp',
        open(Tmp, write, S), format(S, Fmt, Args), close(S),
        open(Tmp, read, S2), read_all_codes(S2, Cs), close(S2),
        atom_codes(Atom, Cs)
    ).

read_all_codes(S, Cs) :-
    get_code(S, C),
    (   C =:= -1
    ->  Cs = []
    ;   Cs = [C | Rest], read_all_codes(S, Rest)
    ).

demo_format_atom :-
    format("---- 格式化到原子 ----~n", []),
    (   catch(atom_format(A, "n=~w, s=~w", [42, abc]), E,
              (format("  失败：~q~n", [E]), fail))
    ->  format("  atom_format -> ~w~n", [A])
    ;   format("  两个引擎都不支持这种输出目标~n", [])
    ).

% ------------------------------------------------------------
%  六、差异清单
% ------------------------------------------------------------
demo_portability :-
    format("---- 双引擎差异清单 ----~n", []),
    format("  1) 双引号：SWI 默认 string，GNU 默认 codes。~n", []),
    format("     统一加 :- set_prolog_flag(double_quotes, codes). 最省事~n", []),
    format("  2) format/1：GNU 没有，只能写 format(「x~~n」, []) 这种两参数形式~n", []),
    format("  3) format(atom(X), ...)：GNU 没有~n", []),
    format("  4) atomic_list_concat/3、split_string/4、string_chars/2：只有 SWI~n", []),
    format("  5) upcase_atom/2、downcase_atom/2：只有 SWI（GNU 要自己按码转换）~n", []),
    format("  6) sub_atom/5、atom_concat/3、atom_length/2、char_code/2：两边都有~n", []),
    format("     atom_number/2 只有 SWI 有，GNU 上用 number_codes/2 代替~n", []),
    format("  7) GNU 的原子默认不能无限长，超长文本用字符码列表更稳~n", []).

main :-
    (   catch((run, nl, format("==== 15 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 15 运行失败~n", []), halt(1)
    ).
