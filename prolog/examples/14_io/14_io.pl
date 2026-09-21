%% ============================================================================
%%  14_io.pl —— 输入输出
%%
%%  Prolog 的 I/O 是「流（stream）」模型：标准输入 user_input、标准输出
%%  user_output、标准错误 user_error 都是流，open/3 打开的也是流。
%%  所有写谓词都有两个版本：write/1（写标准输出）与 write/2（写指定流）。
%%  format 也一样：format/2 与 format/3。
%%
%%  本章用一个临时文件走完「写进去 → 读回来 → 再解析」的完整闭环。
%%  临时文件放在 /tmp 下：这是唯一在两套引擎、三种运行方式下都稳的做法。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

text_file('/tmp/prolog_tutorial_14.txt').
term_file('/tmp/prolog_tutorial_14_terms.txt').

%% ---------------------------------------------------------------------------
%%  一、写到标准输出
%% ---------------------------------------------------------------------------
demo_stdout :-
    say("---- 1. 写到标准输出 ----"),

    % write/1：原样打，不加引号
    format("  write(hello)        -> ", []), write(hello), nl,
    format("  write('a b')        -> ", []), write('a b'), nl,

    % writeq/1：必要时加引号（q = quoted），便于人读
    format("  writeq('a b')       -> ", []), writeq('a b'), nl,
    format("  writeq([a,'b c'])   -> ", []), writeq([a, 'b c']), nl,

    % format/2：唯一能稳定控制排版的
    % 格式串里的字面 ~ 要写成 ~~，否则会被当说明符，去实参列表里找参数
    format("  format(~~w)         -> ~w~n", [f(1, a)]),
    format("  format(~~q)         -> ~q~n", ['a b']),

    % nl/0 换行，tab/1 打 N 个空格，put_char/1 打一个字符
    format("  put_char + tab      -> ", []),
    put_char(x), tab(3), put_char(y), nl,

    % 有对应「流版本」的：nl/1、tab/1 没有流版、put_char/2
    format("  put_char(Stream,C)  -> ", []),
    put_char(user_output, z), nl(user_output),
    say("  注意：tab/1 只有标准输出版；nl/0 与 nl/1、put_char/1 与 put_char/2 成对。").

%% ---------------------------------------------------------------------------
%%  二、写文件
%% ---------------------------------------------------------------------------
demo_write_file :-
    say("---- 2. 写文件：open / format / close ----"),
    text_file(F),
    open(F, write, S),
    format(S, "line one~n", []),
    format(S, "line two~n", []),
    put_char(S, 'X'),
    nl(S),
    close(S),
    format("  已写入 ~w~n", [F]),
    say("  write 模式会清空原文件；要追加用 open(F, append, S)。"),

    % 追加模式
    open(F, append, S2),
    format(S2, "line three~n", []),
    close(S2),
    say("  再用 append 模式追加了一行。"),

    % 读回来
    open(F, read, S3),
    read_line(S3, L1),
    read_line(S3, L2),
    read_line(S3, L3),
    read_line(S3, L4),
    close(S3),
    format("  读回第 1 行: ~s~n", [L1]),
    format("  读回第 2 行: ~s~n", [L2]),
    format("  读回第 3 行: ~s~n", [L3]),
    format("  读回第 4 行: ~s~n", [L4]).

%% 读「一整行」：一字符一字符读到换行为止。
%% 这里用 get_code（拿到整数码）而不是 get_char（拿到单字符原子），
%% 因为 format 的 ~s 说明符要吃「整数码列表」。
%% 文件尾 get_code 给 -1，换行是 10。
read_line(S, Codes) :-
    get_code(S, C),
    (   C =:= -1
    ->  Codes = []
    ;   C =:= 10
    ->  Codes = []
    ;   Codes = [C | Rest],
        read_line(S, Rest)
    ).

%% ---------------------------------------------------------------------------
%%  三、读写「项」而不是字符
%% ---------------------------------------------------------------------------
demo_terms :-
    say("---- 3. 读写项：write_term + read/1 ----"),
    term_file(F),

    % 写出去时必须自己补上空隙与句号，否则读不回来
    open(F, write, S),
    forall(member(T, [point(1, 2), edge(a, b), size(3.5)]),
           (   write_term(S, T, [quoted(true)]),
               write(S, '.'),
               nl(S)
           )),
    close(S),
    format("  已写入 3 个项到 ~w~n", [F]),
    say("  write_term 一定要配 quoted(true)：原子带空格时才会加引号，"),
    say("  否则写出去的文件读不回来（这是最常见的自造格式 bug）。"),

    % 读到文件尾：read/1 会返回 end_of_file
    read_all_terms(F, Terms),
    format("  读回全部项: ~w~n", [Terms]),

    % read_term/3 可以顺便拿到变量信息
    open(F, read, S2),
    read_term(S2, First, [variables(Vs)]),
    length(Vs, NV),
    close(S2),
    format("  第一个项 = ~w，其中未绑定变量有 ~w 个~n", [First, NV]),
    say("  variables/1 这类选项对「读模板、填模板」很有用（第 12 章）。").

read_all_terms(F, Terms) :-
    open(F, read, S),
    read_loop(S, Terms),
    close(S).

read_loop(S, Terms) :-
    read(S, T),
    (   T == end_of_file
    ->  Terms = []
    ;   Terms = [T | Rest],
        read_loop(S, Rest)
    ).

%% ---------------------------------------------------------------------------
%%  四、see / tell：老式的「当前输入流 / 当前输出流」
%% ---------------------------------------------------------------------------
demo_see_tell :-
    say("---- 4. see/1 与 tell/1（ISO 老接口）----"),
    tell('/tmp/prolog_tutorial_14_see.txt'),
    write(legacy_style),
    write('.'),
    nl,
    told,
    see('/tmp/prolog_tutorial_14_see.txt'),
    read(X),
    seen,
    format("  tell 写 / see 读回来: ~w~n", [X]),
    say("  这一套是 ISO 之前的接口，全局切换当前流；新代码一律用 open/3 + 流参数，"),
    say("  因为 see/tell 是全局状态，一旦忘记 seen/told 就会污染后面所有 I/O。"),
    say("  两套引擎都还支持它们，读老代码时会遇到。").

%% ---------------------------------------------------------------------------
%%  五、标准错误与「诊断信息」
%% ---------------------------------------------------------------------------
demo_stderr :-
    say("---- 5. 写到标准错误 ----"),
    say("  format(user_error, ...) 可以把诊断信息写到 stderr，"),
    say("  这样它就不会混进正常输出里（本教程的 main/0 出错时就是这么做的）。"),
    say("  本示例故意不往 stderr 写东西 —— 验证脚本会检查 stderr 必须为空。"),
    say("  注意：本教程所有示例都遵守这条约定，所以出现异常时也不会污染输出。").

%% ---------------------------------------------------------------------------
%%  六、这一步不可移植：SWI 专有的 I/O 工具
%% ---------------------------------------------------------------------------
demo_portability :-
    say("---- 6. 不可移植的 I/O 工具（本教程不用）----"),
    say("  with_output_to/2   把输出收集成原子/串（SWI 专有）"),
    say("  open/4 的 encoding(utf8) 选项（GNU 报 domain_error）"),
    say("  atom_to_term/3  term_string/2  read_term_from_atom/3（SWI 专有）"),
    say("  exists_file/1（SWI）  vs  file_exists/1（GNU）——连文件是否存在都不能统一"),
    say("  替代方案：要「序列化到内存」就自己写 DCG 生成器（第 18、19 章，且完全可控）。").

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
    format("==== 14 开始 ====~n", []),
    say("I/O 是流模型：一切写谓词都有「标准输出版」与「指定流版」两个成对的形态。"),
    say(""),

    demo_stdout,       say(""),
    demo_write_file,   say(""),
    demo_terms,        say(""),
    demo_see_tell,     say(""),
    demo_stderr,       say(""),
    demo_portability,  say(""),

    format("==== 14 结束 ====~n", []).
