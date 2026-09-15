% ============================================================
%  16-exceptions.pl —— 异常、清理与防御式编程
%
%  运行（SWI）: swipl -q -f examples/16-exceptions.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/16-exceptions.pl --entry-goal main
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、throw / catch 基础
% ------------------------------------------------------------
demo_basic :-
    format("---- throw / catch ----~n", []),
    ( catch(throw(my_error), my_error, (format("  捕获到 my_error~n", [])))
    -> true ; format("  没捕获到~n", []) ),
    ( catch(catch(throw(my_error), other_error, (format("  不会执行~n", []))),
            Outer, (format("  匹配不上的异常会继续外抛，外层收到：~q~n", [Outer])))
    -> true ; true ),
    ( catch(throw(error(type_error(int, abc), _)), error(type_error(_, _), _),
            (format("  用变量做模式匹配，捕获一类错误~n", [])))
    -> true ; format("  没捕获到~n", []) ),
    format("  注意：catch 会丢掉 Goal 里的所有选择点，只保留第一个解。~n", []).

% ------------------------------------------------------------
%  二、ISO 标准错误项
%     error(Formal, Context)
%     Formal 常见形式：
%       instantiation_error       变量还没绑定
%       type_error(Type, Culprit) 类型不对
%       domain_error(Domain, _)   取值超出范围
%       existence_error(Type, _)  谓词/文件不存在
%       permission_error(...)     没权限（比如改静态谓词）
%       syntax_error(...)         读进来的项不合语法
% ------------------------------------------------------------
demo_iso_errors :-
    format("---- ISO 标准错误项 ----~n", []),
    show_error('X is _ + 1',        ( _A is _ + 1 )),
    show_error('atom_length(f(a), N)', ( atom_length(f(a), _N) )),
    show_error('open 不存在的文件', ( open('no-such-file-xyz', read, _S) )),
    show_error('调用不存在的谓词',  ( call(no_such_predicate_here) )).

show_error(Label, Goal) :-
    (   catch(Goal, E, (format("  ~w -> ~q~n", [Label, E]), fail))
    ->  format("  ~w -> 成功~n", [Label])
    ;   true
    ).

% ------------------------------------------------------------
%  三、主动抛错：参数校验
% ------------------------------------------------------------
safe_div(A, B, R) :-
    (   var(B)
    ->  throw(error(instantiation_error, safe_div/3))
    ;   B =:= 0
    ->  throw(error(evaluation_error(zero_divisor), safe_div/3))
    ;   R is A / B
    ).

demo_validate :-
    format("---- 主动抛错做参数校验 ----~n", []),
    ( catch(safe_div(10, 2, R1), E1, (format("  10/2 异常：~q~n", [E1]), fail))
    -> format("  10/2 = ~w~n", [R1]) ; true ),
    ( catch(safe_div(10, 0, R2), E2, (format("  10/0 -> ~q~n", [E2]), fail))
    -> format("  10/0 = ~w（不该发生）~n", [R2]) ; true ),
    ( catch(safe_div(10, _, R3), E3, (format("  10/_ -> ~q~n", [E3]), fail))
    -> format("  10/_ = ~w（不该发生）~n", [R3]) ; true ).

% ------------------------------------------------------------
%  四、资源清理
%     SWI 有 setup_call_cleanup/3，GNU 没有 —— 手写等价物
% ------------------------------------------------------------
% 可移植版：用 catch 包住主体，无论如何都执行清理
with_open(File, Mode, Goal) :-
    open(File, Mode, Stream),
    (   catch(call(Goal, Stream), Err,
              ( close(Stream), throw(Err) ))
    ->  close(Stream)
    ;   close(Stream), fail
    ).

count_lines(File, N) :-
    with_open(File, read, count_lines_to(N)).

count_lines_to(N, S) :- count_lines_to(S, 0, N).
count_lines_to(S, Acc, N) :-
    get_code(S, C),
    (   C =:= -1
    ->  N = Acc
    ;   ( C =:= 10 -> Acc1 is Acc + 1 ; Acc1 = Acc ),
        count_lines_to(S, Acc1, N)
    ).

% 跨平台临时文件路径：POSIX 用 /tmp；Windows 没有通用的 /tmp，用 %TEMP%
:- if((current_prolog_flag(dialect, swi), current_prolog_flag(windows, true))).
demo_tmp_file(F) :-
    (   getenv('TEMP', T), T \== ''
    ->  atom_concat(T, '/prolog-16-demo.txt', F)
    ;   F = 'prolog-16-demo.txt'
    ).
:- else.
demo_tmp_file('/tmp/prolog-16-demo.txt').
:- endif.

demo_cleanup :-
    format("---- 资源清理 ----~n", []),
    demo_tmp_file(Tmp),
    open(Tmp, write, S),
    write(S, 'a'), nl(S), write(S, 'b'), nl(S),
    close(S),
    (   catch(count_lines(Tmp, N), E,
              (format("  异常：~q~n", [E]), fail))
    ->  format("  文件行数：~w~n", [N])
    ;   format("  统计失败~n", [])
    ),
    % 演示：主体里抛异常，流仍然会被关掉
    (   catch(with_open(Tmp, read, throws_inside), Err2,
              (format("  主体抛错：~q，但流已经关掉了~n", [Err2])))
    ->  true
    ;   true
    ),
    format("  SWI 上直接写 setup_call_cleanup(open(...), Goal, close(...)) 即可；~n", []),
    format("  GNU 没有这个谓词，所以上面手写了 with_open/3。~n", []).

throws_inside(_S) :- throw(deliberate_error).

% ------------------------------------------------------------
%  五、catch 与回溯的相互作用（最容易踩的坑）
% ------------------------------------------------------------
picky(1).
picky(2) :- throw(bad_two).
picky(3).

demo_backtrack :-
    format("---- catch 与回溯 ----~n", []),
    findall(X, (member(X, [1,2,3]), catch(picky(X), _, fail)), Safe),
    format("  catch 包在 picky 外面：~w（2 被拦截，1/3 正常）~n", [Safe]),
    findall(Y, catch((member(Y, [1,2,3]), picky(Y)), _, fail), Outer),
    format("  catch 包在整段外面：~w（异常一抛，整段作废）~n", [Outer]),
    format("  结论：catch 的位置决定「失败范围」，包得越紧粒度越细。~n", []).

% ------------------------------------------------------------
%  六、让程序在出错时优雅退出
% ------------------------------------------------------------
demo_exit_code :-
    format("---- 退出码 ----~n", []),
    format("  halt(0) 表示成功，halt(1) 表示失败。~n", []),
    format("  本教程每个示例的 main/0 都是这个模式：~n", []),
    format("    main :- ( catch(run, E, (报 stderr, halt(1)))~n", []),
    format("             -> halt(0) ; 报 stderr, halt(1) ).~n", []),
    format("  这样脚本才能靠退出码判断成败。~n", []).

run :-
    format("==== 16  异常与清理 ====~n", []), nl,
    demo_basic,      nl,
    demo_iso_errors, nl,
    demo_validate,   nl,
    demo_cleanup,    nl,
    demo_backtrack,  nl,
    demo_exit_code.

main :-
    (   catch((run, nl, format("==== 16 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 16 运行失败~n", []), halt(1)
    ).
