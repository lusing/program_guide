% ============================================================
%  14-io-files.pl —— 输入输出与文件
%
%  运行（SWI）: swipl -q -f examples/14-io-files.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/14-io-files.pl --entry-goal main
%
%  本例建一个临时文件跑读写（POSIX 在 /tmp，Windows 在 %TEMP%），SWI 下跑完会被删掉。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% 跨平台临时文件路径：POSIX 用 /tmp；Windows 没有通用的 /tmp
% （'/tmp/x' 会被解析成 <当前盘>:\tmp\x，该目录通常不存在），
% 所以 Windows 下用 %TEMP%，取不到 TEMP 就退回当前工作目录。
:- if((current_prolog_flag(dialect, swi), current_prolog_flag(windows, true))).
tmp_file(F) :-
    (   getenv('TEMP', T), T \== ''
    ->  atom_concat(T, '/prolog-14-io-demo.tmp', F)
    ;   F = 'prolog-14-io-demo.tmp'
    ).
:- else.
tmp_file('/tmp/prolog-14-io-demo.tmp').
:- endif.

% ------------------------------------------------------------
%  一、写文件：open / write / close 三件套
% ------------------------------------------------------------
demo_write :-
    format("---- 写文件 ----~n", []),
    tmp_file(F),
    open(F, write, S),
    write(S, '第一行'), nl(S),
    write(S, '第二行'), nl(S),
    format(S, "格式化输出：~w / ~w~n", [42, abc]),
    close(S),
    format("  已写入 ~w~n", [F]).

% ------------------------------------------------------------
%  二、读文件：逐字符
% ------------------------------------------------------------
demo_read_chars :-
    format("---- 逐字符读 ----~n", []),
    tmp_file(F),
    open(F, read, S),
    read_n_chars(S, 12, Cs),
    close(S),
    format("  前 12 个字符码：~w~n", [Cs]),
    atom_codes(A, Cs),
    format("  转成原子：~w~n", [A]).

read_n_chars(_, 0, []) :- !.
read_n_chars(S, N, Cs) :-
    N > 0,
    (   at_end_of_stream(S)
    ->  Cs = []
    ;   get_code(S, C),
        (   C =:= -1
        ->  Cs = []
        ;   N1 is N - 1, Cs = [C | Rest], read_n_chars(S, N1, Rest)
        )
    ).

% ------------------------------------------------------------
%  三、逐行读（自己写，两个引擎都没有内置的 read_line_to_string）
% ------------------------------------------------------------
demo_read_lines :-
    format("---- 逐行读 ----~n", []),
    tmp_file(F),
    open(F, read, S),
    read_lines2(S, Lines),
    close(S),
    forall(member(L, Lines),
           ( atom_codes(LA, L), format("  行：~w~n", [LA]) )).

% 注意 EOF 的判断：get_code 返回 -1，不能只靠 at_end_of_stream
read_lines2(S, Lines) :-
    read_one_line(S, Cs, Last),
    (   Last == yes
    ->  ( Cs == [] -> Lines = [] ; Lines = [Cs] )
    ;   ( Cs == [] -> Lines = Rest ; Lines = [Cs | Rest] ),
        read_lines2(S, Rest)
    ).

read_one_line(S, Cs, Last) :-
    get_code(S, C),
    (   C =:= -1
    ->  Cs = [], Last = yes
    ;   C =:= 10
    ->  Cs = [], Last = no
    ;   Cs = [C | Rest], read_one_line(S, Rest, Last)
    ).

% ------------------------------------------------------------
%  四、把整个 Prolog 知识库存盘再读回（write_term / read_term）
% ------------------------------------------------------------
:- dynamic(kv/2).

demo_terms :-
    format("---- 用项做序列化 ----~n", []),
    tmp_file(F),
    retractall(kv(_, _)),
    assertz(kv(name, tom)), assertz(kv(age, 42)), assertz(kv(tags, [a, b])),
    open(F, write, S1),
    forall(kv(K, V),
           ( write_term(S1, kv(K, V), [quoted(true)]),
             write(S1, '.'), nl(S1) )),
    close(S1),
    % 读回来
    retractall(kv(_, _)),
    open(F, read, S2),
    read_terms(S2, Ts),
    close(S2),
    forall(member(T, Ts), assertz(T)),
    findall(K2-V2, kv(K2, V2), Back),
    format("  存盘再读回：~w~n", [Back]),
    format("  用 quoted(true) 很关键：否则原子可能读回来变成别的类型。~n", []).

read_terms(S, Ts) :-
    read_term(S, T, []),
    (   T == end_of_file
    ->  Ts = []
    ;   Ts = [T | Rest], read_terms(S, Rest)
    ).

% ------------------------------------------------------------
%  五、标准流与别名
% ------------------------------------------------------------
demo_streams :-
    format("---- 流与别名 ----~n", []),
    current_output(CO),
    current_input(CI),
    format("  当前输出流：~w，输入流：~w（具体形式各引擎不同）~n", [CO, CI]),
    format(user_output, "  往 user_output 写~n", []),
    format("  user_output / user_error / current_output 是三个常用别名~n", []).

% ------------------------------------------------------------
%  六、双引擎差异
% ------------------------------------------------------------
demo_portability :-
    format("---- 双引擎差异 ----~n", []),
    format("  · open/3 close/1 get_code/2 put_code/2 nl/1 两个引擎都有~n", []),
    format("  · read_term/3、write_term/3 都有，但可选项列表不完全一样~n", []),
    format("  · exists_file/1、absolute_file_name/2、directory_files/2 是 SWI 的~n", []),
    format("  · read_line_to_string/2、read_string/3 也是 SWI 的，GNU 要自己写~n", []),
    format("  · SWI 有 with_output_to/2 可以把输出抓到原子里，GNU 没有~n", []),
    format("    可移植的替代：open 一个临时文件，或者先写再读~n", []).

cleanup :-
    tmp_file(F),
    (   catch(open(F, read, S), _, fail)
    ->  close(S),
        ( catch(delete_demo(F), _, true) -> true ; true )
    ;   true
    ).

% 两个引擎都没有标准的可移植删除文件谓词（SWI 有 delete_file/1，
% GNU 没有）。这里用条件编译。
:- if(current_prolog_flag(dialect, swi)).
delete_demo(F) :- delete_file(F).
:- else.
delete_demo(_) :- true.
:- endif.

run :-
    format("==== 14  输入输出与文件 ====~n", []), nl,
    demo_write,       nl,
    demo_read_chars,  nl,
    demo_read_lines,  nl,
    demo_terms,       nl,
    demo_streams,     nl,
    demo_portability, nl,
    cleanup.

main :-
    (   catch((run, nl, format("==== 14 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 14 运行失败~n", []), halt(1)
    ).
