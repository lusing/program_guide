% ============================================================
%  20-portability.pl —— 双引擎差异、可移植封装与综合实战
%
%  运行（SWI-Prolog）：
%    swipl -q -f examples/20-portability.pl -g main -t halt
%  运行（GNU Prolog）：
%    gprolog --consult-file examples/20-portability.pl --entry-goal main
%
%  这一例是整套教程的「收口」：
%    1) 运行时探测当前引擎缺什么
%    2) 用薄封装把差异抹平
%    3) 用一个完整小项目（词频统计）验证封装真的能跑
% ============================================================

% 让 "abc" 在两套系统里都表示字符码列表（SWI 默认是 string 类型）
:- set_prolog_flag(double_quotes, codes).

:- dynamic(freq/2).

% ------------------------------------------------------------
%  一、方言检测
% ------------------------------------------------------------

dialect(D) :-
    (   catch(current_prolog_flag(dialect, X), _, fail)
    ->  D = X
    ;   D = unknown
    ).

demo_dialect :-
    format("---- 一、当前引擎 ----~n", []),
    dialect(D),
    format("  dialect = ~w~n", [D]),
    (   D == swi     -> format("  SWI-Prolog：库最多，开发首选~n", [])
    ;   D == gprolog -> format("  GNU Prolog：体量小，能编译成独立可执行文件~n", [])
    ;   format("  未知~n", [])
    ),
    format("  版本信息用命令行看：swipl --version / gprolog --version~n", []).

% ------------------------------------------------------------
%  二、特性探测：catch 是最可靠的「有没有这个谓词」检测法
%
%   注意 GNU 报的是 error(existence_error(procedure, Name/Arity), _)，
%   SWI 在 -q 下也是同类错误，所以一个 catch 就能统一判断。
% ------------------------------------------------------------

probe(Name, Goal) :-
    (   catch(once(Goal), _, fail)
    ->  format("  ~w  ->  有~n", [Name])
    ;   format("  ~w  ->  没有~n", [Name])
    ).

demo_probe :-
    format("---- 二、特性探测（同一份代码，两套系统结果不同才正常）----~n", []),
    probe("get_time/1",          get_time(_)),
    probe("numlist/3",           numlist(1, 3, _)),
    probe("writeln/1",           writeln(x)),
    probe("atom_number/2",       atom_number('42', 42)),
    probe("term_to_atom/2",      term_to_atom(f(a), _)),
    probe("atomics_to_string/3", atomics_to_string([a,b], '-', _)),
    probe("exists_file/1",       exists_file('20-portability.pl')),
    probe("union/3",             union([1],[2],_)),
    probe("gensym/2",            gensym(a, _)),
    probe("statistics/2",        statistics(runtime, [_, _])),
    probe("number_codes/2",      number_codes(42, _)),
    probe("read_term_from_atom/3", read_term_from_atom('f(a).', _, [])),
    probe("min_list/2",          min_list([1,2], _)),
    probe("max_list/2",          max_list([1,2], _)),
    format("  凡是「没有」的，都不要用 —— 或者用下一节的封装替代~n", []).

% ------------------------------------------------------------
%  三、可移植封装层（shim）
%
%   原则：封装只做「有就用、没有就退」，不追求功能完整。
% ------------------------------------------------------------

% writeln/1：SWI 有，GNU 没有
my_writeln(T) :- format("~q~n", [T]).

% 计时：SWI 有 get_time/1，GNU 没有；但两边都有 statistics(runtime, ...)
% 返回毫秒（整数），精度够做基准了
runtime_ms(Ms) :- statistics(runtime, [Ms, _]).

% 原子 -> 整数。SWI 有 atom_number/2，GNU 没有，退回 number_codes/2
atom_to_int(A, N) :-
    (   catch(atom_number(A, N), _, fail)
    ->  true
    ;   atom_codes(A, Cs),
        all_digits(Cs),
        Cs \= [],
        number_codes(N, Cs)
    ).

all_digits([]).
all_digits([C | Cs]) :- C >= 0'0, C =< 0'9, all_digits(Cs).

% 文件是否存在：SWI 有 exists_file/1，GNU 没有，退回「试着打开」
my_file_exists(F) :-
    (   catch(exists_file(F), _, fail)
    ->  true
    ;   catch((open(F, read, S), close(S)), _, fail)
    ).

% numlist/3：SWI 有，GNU 没有
my_numlist(Lo, Hi, L) :- my_numlist(Lo, Hi, [], L).
my_numlist(Lo, Hi, Acc, L) :-
    (   Lo > Hi
    ->  reverse(Acc, L)
    ;   Lo1 is Lo + 1,
        my_numlist(Lo1, Hi, [Lo | Acc], L)
    ).

% 把结果格式化成原子：SWI 有 format(atom(A),...)，GNU 没有
% GNU 上没有 with_output_to，最笨也最通用的办法是「写临时文件再读回」
atom_fmt(Atom, Fmt, Args) :-
    (   catch(format(atom(Atom), Fmt, Args), _, fail)
    ->  true
    ;   Tmp = '/tmp/prolog-20-fmt.tmp',
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

demo_shim :-
    format("---- 三、封装层演示 ----~n", []),
    format("  my_writeln(hello) -> ", []), my_writeln(hello),
    runtime_ms(Ms),
    format("  runtime_ms        -> ~w ms（自进程启动）~n", [Ms]),
    (   atom_to_int('1024', N)
    ->  format("  atom_to_int('1024') -> ~w~n", [N])
    ;   format("  atom_to_int 失败~n", [])
    ),
    (   atom_to_int('abc', _)
    ->  format("  atom_to_int('abc') 居然成功了，不该~n", [])
    ;   format("  atom_to_int('abc') 正确地失败了~n", [])
    ),
    (   my_file_exists('20-portability.pl')
    ->  format("  my_file_exists(本文件) -> 是~n", [])
    ;   format("  my_file_exists(本文件) -> 否（可能换了工作目录）~n", [])
    ),
    my_numlist(1, 5, NL),
    format("  my_numlist(1,5)   -> ~w~n", [NL]),
    (   atom_fmt(A, "n=~w", [42])
    ->  format("  atom_fmt          -> ~w~n", [A])
    ;   format("  atom_fmt 失败~n", [])
    ).

% ------------------------------------------------------------
%  四、综合实战：词频统计
%
%   流程：原始文本 -> 分词 -> 转小写 -> 排序 -> 游程压缩 -> 按频次排序 -> top N
%   全程只用两套系统都有的谓词，不碰任何专有库。
% ------------------------------------------------------------

% 注意：别用反斜杠续行写长字符串，GNU Prolog 不支持，会报
%       "quote character expected here"。就写成一行长的。
sample_text("Prolog is a logic programming language. Prolog is declarative. In Prolog, you state facts and rules, then ask questions. Prolog searches for answers by itself. Logic programming is not imperative. You describe what is true, not how to compute it. Prolog Prolog Prolog - yes, this word appears many times.").

% 按「非字母」切词，返回原子列表
tokenize(Codes, Words) :-
    split_words(Codes, [], RevGroups),
    reverse(RevGroups, Groups),
    % split_words 是「头插」攒缓冲的，所以每个分组自己是倒着的，要再翻一次
    findall(W,
            ( member(Cs, Groups), Cs \= [],
              reverse(Cs, CsR),
              downcase_codes(CsR, Lc), atom_codes(W, Lc) ),
            Words).

split_words([], Cur, [Cur]).
split_words([C | Cs], Cur, Out) :-
    (   is_alpha_code(C)
    ->  split_words(Cs, [C | Cur], Out)
    ;   Out = [Cur | Rest],
        split_words(Cs, [], Rest)
    ).

is_alpha_code(C) :-
    ( C >= 0'a, C =< 0'z -> true
    ; C >= 0'A, C =< 0'Z -> true
    ; C =:= 39                        % 39 是撇号，处理 don't 这类词
    ).

downcase_codes([], []).
downcase_codes([C | Cs], [D | Ds]) :-
    ( C >= 0'A, C =< 0'Z -> D is C + 32 ; D = C ),
    downcase_codes(Cs, Ds).

% 游程压缩：排序后的列表 -> [元素-次数]
rle([], []).
rle([X | Xs], [X-N | Rest]) :-
    take_same(X, Xs, 1, N, Tail),
    rle(Tail, Rest).

take_same(_, [], Acc, Acc, []).
take_same(X, [Y | Ys], Acc, N, Tail) :-
    (   X == Y
    ->  Acc1 is Acc + 1,
        take_same(X, Ys, Acc1, N, Tail)
    ;   N = Acc,
        Tail = [Y | Ys]
    ).

% 按频次降序：把计数取负当 key，keysort 之后自然就是降序
% （keysort 按键升序排，取负数等价于按原计数降序）
freq_sorted(Freqs, Sorted) :-
    findall(K-W, (member(W-C, Freqs), K is 0 - C), Pairs),
    keysort(Pairs, Sorted).

demo_wordfreq :-
    format("---- 四、综合实战：词频统计 ----~n", []),
    sample_text(T),
    tokenize(T, Words),
    length(Words, Total),
    format("  总词数：~w~n", [Total]),
    msort(Words, SortedWords),
    rle(SortedWords, Freqs),
    length(Freqs, Uniq),
    format("  不同词数：~w~n", [Uniq]),
    freq_sorted(Freqs, Ranked),
    format("  Top 8：~n", []),
    (   append(First8, _, Ranked),
        length(First8, 8)
    ->  true
    ;   First8 = Ranked
    ),
    forall(member(K-W, First8),
           ( C is 0 - K, format("    ~w  x~w~n", [W, C]) )),
    (   member(_-prolog, Ranked)
    ->  member(Kp-prolog, Ranked), Cp is 0 - Kp,
        format("  “prolog” 出现 ~w 次（停用词没过滤，所以它排第一很正常）~n", [Cp])
    ;   format("  没找到 prolog~n", [])
    ),
    format("  用到的全是公共子集：msort / keysort / findall / forall / append~n", []).

% ------------------------------------------------------------
%  五、部署：三条运行通道
% ------------------------------------------------------------

demo_deploy :-
    format("---- 五、部署方式 ----~n", []),
    format("  1) 解释执行（开发时用）~n", []),
    format("     swipl -q -f prog.pl -g main -t halt~n", []),
    format("     gprolog --consult-file prog.pl --entry-goal main~n", []),
    format("  2) SWI 编译成字节码可执行文件~n", []),
    format("     swipl -q -o prog -c prog.pl      （prog.pl 需有 :- initialization(main, main).）~n", []),
    format("  3) GNU 编译成真正的本地可执行文件（无依赖）~n", []),
    format("     echo ':- initialization(main).' > entry.pl~n", []),
    format("     cat prog.pl >> entry.pl~n", []),
    format("     gplc entry.pl -o prog~n", []),
    format("     注意 gplc 只能在当前目录工作，源文件放子目录会链接失败；~n", []),
    format("     本仓库 run-all.sh 的做法就是把源码拼一份到 build/ 再编。~n", []),
    format("  4) 退出码：main 里 halt(0) 表示成功，halt(1) 表示失败，CI 直接读~n", []).

% ------------------------------------------------------------
%  六、可移植清单（踩过的坑汇总）
% ------------------------------------------------------------

demo_checklist :-
    format("---- 六、可移植清单 ----~n", []),
    format("  1) 文件头写 :- set_prolog_flag(double_quotes, codes).~n", []),
    format("     否则 \"abc\" 在 SWI 里是 string、在 GNU 里是 codes，行为分叉~n", []),
    format("  2) 只用 format(Fmt, Args) 两参数以上形式，别用 format/1~n", []),
    format("  3) 别用 numlist / writeln / atom_number / exists_file / union /~n", []),
    format("     gensym / term_to_atom / atomic_list_concat —— 这些 GNU 没有~n", []),
    format("  4) GNU 上要 clause/2 读静态谓词，先 :- public(p/n). 声明~n", []),
    format("  5) 条件编译用 :- if(current_prolog_flag(dialect, X))，~n", []),
    format("     但被跳过的代码 GNU 仍要能解析，专有运算符先 :- op 声明~n", []),
    format("  6) 约束求解：GNU 用 fd_domain/fd_labeling，SWI 用 clpfd 的 in/ins~n", []),
    format("     两套 API 完全不同，只能条件编译各写一份~n", []),
    format("  7) main/0 结尾一定 halt，否则会掉进交互式 toplevel 卡住~n", []),
    format("  8) read 文件到 EOF 的判断用 get_code 返回 -1，别只靠 at_end_of_stream~n", []).

% ------------------------------------------------------------
%  入口
% ------------------------------------------------------------

main :-
    (   catch(run, E, (nl, format("*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format("*** run/0 失败~n", []), halt(1)
    ).

run :-
    demo_dialect, nl,
    demo_probe, nl,
    demo_shim, nl,
    demo_wordfreq, nl,
    demo_deploy, nl,
    demo_checklist, nl,
    format("==== 20 结束 ====~n", []).
