%% ============================================================================
%%  20_exceptions.pl —— 异常处理
%%
%%  Prolog 的异常是 ISO 标准的 throw/1 与 catch/3：
%%      throw(Ball)                 抛出任意项（Ball 会被复制一份再抛）
%%      catch(Goal, Catcher, Recovery)
%%                                  Catcher 与抛出的项合一成功就执行 Recovery
%%
%%  三条核心规则：
%%    1. 没被 catch 的异常会一路穿透到顶层，程序终止
%%    2. catch/3 只捕获【合一成功】的异常，其它异常继续往外穿
%%    3. ISO 的运行时错误统一是 error(Formal, Context) 的形状
%%
%%  【本教程的约定】error/2 里的 Formal 与 Context 两套引擎填的内容不同
%%  （Context 里 SWI 会塞 context(system:goal/arity, 内部变量)），
%%  所以示例只打印 functor 名字或自己抛的项，绝不打印引擎给的错误项。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% 自己的异常项：给出「名字 + 字段」，用起来像结构化错误
%%   bad_input(Where, What)
%%   div_by_zero(Left, Right)
%%   out_of_range(Value, Low, High)

%% ---------------------------------------------------------------------------
%%  一、最基本的一对：throw / catch
%% ---------------------------------------------------------------------------
risky(0) :- throw(zero).
risky(N) :- N > 0, R is 100 / N, format("  risky(~w) = ~w~n", [N, R]).

demo_basic :-
    say("---- 1. throw 与 catch ----"),
    (   catch(risky(8), zero, say("  捕到 zero"))
    ->  say("  catch(risky(8), zero, ...) 整体成功")
    ;   say("  catch(risky(8), zero, ...) 整体失败")
    ),
    say("  risky(8) 没抛异常，所以 Recovery 没执行 —— 上面这行只是说明它成功了。"),
    catch(risky(0), zero, say("  捕到 zero：risky(0) 抛了 zero")),
    say("  catch 本身永远是「成功」的（只要 Recovery 成功），"),
    say("  所以判断有没有出错不能看 catch 的成败，要看它做了什么。"),

    % 不匹配的异常【不会】变成失败，而是原样再抛出去。
    % 所以「穿透」要用嵌套 catch 才看得见：
    (   catch(catch(risky(0), other_error, say("  内层捕到 other_error")),
              zero,
              say("  内层用 other_error 没捕到 → 原样重抛 → 外层用 zero 捕到了"))
    ->  true
    ;   say("  连外层都没捕到（不该出现）")
    ),
    say("  关键区别：catch 捕不中时是【重抛】，不是【失败】——"),
    say("  所以别把 catch 放进 if-then-else 的失败分支去判「有没有异常」。").


%% ---------------------------------------------------------------------------
%%  二、异常会被「复制」——这是特性不是 bug
%% ---------------------------------------------------------------------------
demo_copy :-
    say("---- 2. throw 会把异常项复制一份 ----"),
    Ball = tagged(1),
    (   catch(throw(Ball), tagged(X), true)
    ->  format("  捕到 tagged(~w)~n", [X])
    ;   say("  没捕到（不该出现）")
    ),
    say("  抛出的项与接收到的变量之间【没有共享】：catch 内外的变量不会互相绑定。"),
    say("  原因：throw 在抛出前 copy_term 了一次，避免「异常把调用者的变量绑了」。"),
    say("  实践含义：别指望用异常回传变量绑定，要回传数据就在异常项里带上。"),

    % 演示：外面的变量不会被异常的合一绑上
    Payload = payload(Inside),
    (   catch(throw(Payload), payload(_), true)
    ->  true
    ;   true
    ),
    (   var(Inside)
    ->  say("  验证：抛出项里的变量在外面仍然是空的（复制生效了）")
    ;   say("  验证：外面被绑上了（不该出现）")
    ).

%% ---------------------------------------------------------------------------
%%  三、只捕你要捕的：分类与穿透
%% ---------------------------------------------------------------------------
%% 自定义异常：用「名字 + 字段」表达错误的种类
validate_age(A, ok) :-
    integer(A),
    A >= 0,
    A =< 150,
    !.
validate_age(A, _) :-
    \+ integer(A),
    !,
    throw(bad_input(age, not_an_integer(A))).
validate_age(A, _) :-
    throw(out_of_range(A, 0, 150)).

demo_classify :-
    say("---- 3. 分类捕获：只处理自己懂的 ----"),
    forall(member(A, [30, -5, 200, foo]),
           (   % 外层兜住「没人接」的异常，才能把它打印出来
               catch(catch(validate_age(A, R),
                           out_of_range(V, Lo, Hi),
                           R = rejected(range(V, Lo, Hi))),
                     Escaped,
                     R = escaped(Escaped))
           ->  format("  validate_age(~w) -> ~w~n", [A, R])
           ;   format("  validate_age(~w) -> 无解~n", [A])
           )),
    say("  注意 foo 那条：它抛的是 bad_input(...)，与 out_of_range 不匹配，"),
    say("  于是原样重抛，被最外层兜住 —— 这就是「不吞异常」的写法。"),
    say("  工程准则：catch 只捕你明确知道怎么处理的异常，其它一律放行。"),
    say("  想全部兜住再用 error/2 的形状判断（下一节）。").

demo_iso_error :-
    say("---- 4. ISO 运行时错误的形状 ----"),
    % 只取 functor 名，不打印整个项 —— 两个引擎的 Context 部分不一样
    (   catch(_X is 1 + a, E1, (functor(E1, N1, _), format("  1 + a      -> 错误名 ~w~n", [N1])))
    ->  true
    ;   say("  1 + a      -> 没有异常？")
    ),
    (   catch(_Y is _Z + 1, E2, (functor(E2, N2, _), format("  空变量参与 -> 错误名 ~w~n", [N2])))
    ->  true
    ;   say("  空变量参与 -> 没有异常？")
    ),
    (   catch(call(_), E3, (functor(E3, N3, _), format("  call(空变量) -> 错误名 ~w~n", [N3])))
    ->  true
    ;   say("  call(空变量) -> 没有异常？")
    ),
    say("  这些错误项都是 error(Formal, Context) 的形状，functor 一律是 error。"),
    say("  但 Formal 与 Context 的具体内容是引擎自由的，所以可移植代码"),
    say("  只能靠「自己 throw 的项」来区分，不要解析引擎给的结构。"),
    say("  唯一稳妥的例外：捕 error(_, _)，然后一律转成自己的错误处理。").

%% ---------------------------------------------------------------------------
%%  四、不用异常也能表达「可能没有」：some / none
%% ---------------------------------------------------------------------------
%% 很多语言用 null / Optional；Prolog 里最地道的做法是「失败」，
%% 但当你确实需要一个「值」时，可以显式包一层。
find_user(Db, Id, Result) :-
    (   member(user(Id, Name, Age), Db)
    ->  Result = some(user(Name, Age))
    ;   Result = none
    ).

demo_option :-
    say("---- 5. some / none：把「可能没有」变成值 ----"),
    Db = [user(1, alice, 30), user(2, bob, 25)],
    find_user(Db, 1, R1),
    format("  find_user(1) -> ~w~n", [R1]),
    find_user(Db, 9, R2),
    format("  find_user(9) -> ~w~n", [R2]),
    say("  好处：调用方拿到的一定是一个值，可以继续用 ~w 打印、塞进列表、"),
    say("  用 if-then-else 分支，不会因为「空而失败」把控制流打散。"),
    say("  坏处：多一次显式拆包。所以两种风格要按场景选："),
    say("    靠失败 → 用于「搜索 / 遍历」这类天然可回溯的场景"),
    say("    some/none → 用于「查表 / 解析」这类调用者需要明确知道结果有无的场景"),
    say("  本教程第 24 章的解释器对「变量未定义」就用 none 表达。"),

    % 拆包
    (   R1 = some(user(N, A))
    ->  format("  拆包 some：~w 岁 ~w~n", [N, A])
    ;   say("  拆包 some：不是 some（不该出现）")
    ),
    (   R2 = some(user(N2, A2))
    ->  format("  拆包 none：~w 岁 ~w~n", [N2, A2])
    ;   say("  拆包 none：没有这个用户（这就是 none 的意义）")
    ).

%% ---------------------------------------------------------------------------
%%  五、异常不是控制流
%% ---------------------------------------------------------------------------
demo_not_control :-
    say("---- 6. 别用异常做正常控制流 ----"),
    say("  Prolog 里「找不到」的标准表达是【失败】，不是抛异常："),
    (   member(c, [a, b])
    ->  say("    member(c,[a,b]) 成功")
    ;   say("    member(c,[a,b]) 失败 —— 这就是它的正常语义，不需要异常")
    ),
    say("  什么时候该 throw："),
    say("    · 输入违反了接口约定（类型错、范围错）—— 这是「编程错误」"),
    say("    · 环境不允许继续（文件打不开、资源耗尽）"),
    say("  什么时候不该 throw："),
    say("    · 搜索没找到解（用失败）"),
    say("    · 用来跳出循环（用 ! 或递归）"),
    say("  用异常做控制流的代价：catch 会把中间的选择点砍掉，"),
    say("  回溯行为变得难以推理，而且两套引擎对错误项的填充还不一致。"),
    say("  最后一条：没有 catch 的异常会打到顶层并把程序终止，"),
    say("  所以示例的 main/0 一定把 run/0 包在 catch 里（第 02 章）。").

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
    format("==== 20 开始 ====~n", []),
    say("异常用于「编程错误与环境问题」，不用来表达「没找到」。"),
    say(""),

    demo_basic,      say(""),
    demo_copy,       say(""),
    demo_classify,   say(""),
    demo_iso_error,  say(""),
    demo_option,     say(""),
    demo_not_control, say(""),

    format("==== 20 结束 ====~n", []).
