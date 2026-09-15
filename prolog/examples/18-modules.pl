% ============================================================
%  18-modules.pl —— 代码组织、命名空间与条件编译
%
%  运行（SWI-Prolog）：
%    swipl -q -f examples/18-modules.pl -g main -t halt
%  运行（GNU Prolog）：
%    gprolog --consult-file examples/18-modules.pl --entry-goal main
%
%  核心事实：GNU Prolog 没有模块系统，只有 :- if 条件编译。
%            想让一份代码同时跑在两套上，得用「前缀命名 + 条件编译」。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、单文件内部的分区约定
%
%   Prolog 不关心你写的顺序，但人关心。惯例是自顶向下：
%     1) 指令区（:- set_prolog_flag / :- dynamic / :- if ...）
%     2) 数据区（事实）
%     3) 入口（main/0）
%     4) 逻辑谓词（按被调用顺序，或按主题分组）
%
%   下面这个 :- discontiguous 就是「我要把一个谓词的子句
%   拆到好几处写」的声明，不写它 GNU 和 SWI 都会警告。
% ------------------------------------------------------------

:- discontiguous(geo_area/2).
:- dynamic(counter/2).
:- dynamic(handler/2).

counter(calls, 0).

% ------------------------------------------------------------
%  二、GNU 没有模块 —— 用命名前缀模拟命名空间
%
%   约定：模块名做前缀，用下划线隔开。
%   这是唯一两套系统都支持、且零成本的做法。
% ------------------------------------------------------------

geo_area(circle(R), A)  :- A is 3.141592653589793 * R * R.
geo_area(rect(W, H), A) :- A is W * H.
geo_area(square(S), A)  :- A is S * S.

% 另一个「模块」
geo_perimeter(circle(R), P) :- P is 2 * 3.141592653589793 * R.
geo_perimeter(rect(W, H), P) :- P is 2 * (W + H).
geo_perimeter(square(S), P) :- P is 4 * S.

demo_prefix :-
    format("---- 用命名前缀模拟模块 ----~n", []),
    findall(S-A, (member(S, [circle(1), rect(2,3), square(2)]), geo_area(S, A)), Ps),
    forall(member(Sh-Val, Ps),
           ( geo_perimeter(Sh, Per),
             format("  ~w  面积 ~2f  周长 ~2f~n", [Sh, Val, Per]) )),
    format("  做法：把模块名 geo_ 当前缀，靠命名而不是靠系统来隔离~n", []).

% ------------------------------------------------------------
%  三、动态派发表 —— 比硬编码 if-then-else 更容易扩展
%
%   把「形状 -> 处理闭包」放进数据库，新增形状不用改已有代码。
% ------------------------------------------------------------

handler(circle, geo_area).
handler(rect,   geo_area).
handler(square, geo_area).

demo_dispatch :-
    format("---- 动态派发表 ----~n", []),
    forall(member(Name, [circle, rect, square]),
           ( handler(Name, Impl),
             format("  ~w 由 ~w 处理~n", [Name, Impl]) )),
    % call/3 把「模块名 + 参数」拼起来调用
    ( catch(call(geo_area, circle(2), V), E,
            (format("  调用失败：~q~n", [E]), fail))
    -> format("  call(geo_area, circle(2), X) -> ~2f~n", [V])
    ;  format("  调用失败~n", []) ),
    format("  好处：加一个新形状 = assertz 一条 handler，不碰已有谓词~n", []).

% ------------------------------------------------------------
%  四、条件编译：:- if / :- elif / :- else / :- endif
%
%   两套系统的 :- if 都认 current_prolog_flag(dialect, X)。
%   但有个坑：GNU 只是「跳过执行」，读文件时照样要能解析语法。
%   所以 SWI 专有语法（比如 clpfd 的 ins 运算符）必须先 :- op 声明，
%   否则 GNU 在读文件阶段就报语法错误，:- if 也救不了。
% ------------------------------------------------------------

:- if(current_prolog_flag(dialect, swi)).
:- elif(current_prolog_flag(dialect, gprolog)).
:- else.
:- endif.

% 当前引擎的名字（可移植写法：查不到就当 unknown）
dialect_name(D) :-
    (   catch(current_prolog_flag(dialect, X), _, fail)
    ->  D = X
    ;   D = unknown
    ).

demo_dialect :-
    format("---- 条件编译与方言检测 ----~n", []),
    dialect_name(D),
    format("  current_prolog_flag(dialect, X) -> ~w~n", [D]),
    (   D == swi
    ->  format("  这一支是 SWI-Prolog：有 module/2、clpfd、string 类型、dict~n", [])
    ;   D == gprolog
    ->  format("  这一支是 GNU Prolog：有内置 FD 约束、能编译成本地可执行文件~n", [])
    ;   format("  未知方言~n", [])
    ),
    format("  写法要点：~n", []),
    format("    :- if(current_prolog_flag(dialect, swi)).~n", []),
    format("    ...只有 SWI 才编译的代码...~n", []),
    format("    :- endif.~n", []),
    format("  坑：被跳过的代码 GNU 仍然要「读得懂」，专有运算符先 :- op 声明~n", []).

% ------------------------------------------------------------
%  五、:- public —— GNU 上 clause/2 的通行证
%
%   GNU Prolog 不允许 clause/2 去读静态谓词的子句，
%   必须先 :- public(p/n) 声明。SWI 没这个限制。
% ------------------------------------------------------------

:- if(current_prolog_flag(dialect, gprolog)).
:- public(grade/2).
:- endif.

grade(S, a) :- S >= 90.
grade(S, b) :- S >= 80.
grade(S, c) :- S >= 70.
grade(_, d).

demo_public :-
    format("---- clause/2 与 :- public ----~n", []),
    (   catch(findall(H-B, clause(grade(H, B), _), Cs), E,
              (format("  失败：~q~n", [E]), fail))
    ->  length(Cs, N),
        format("  clause/2 读到 ~w 条 grade/2 子句~n", [N]),
        findall(S-G, (member(S, [95, 85, 75, 50]), call(grade, S, G)), R),
        format("  打分：~w~n", [R])
    ;   format("  本引擎不允许 clause/2 访问静态谓词（GNU 需 :- public）~n", [])
    ).

% ------------------------------------------------------------
%  六、:- initialization —— 加载即执行
%
%   这是把脚本跑起来的关键指令，两套系统都支持。
%   build.ps1 / run-all.sh 里的 gplc 通道就是靠拼一行
%   ":- initialization(main)." 把示例变成可执行文件的。
% ------------------------------------------------------------

demo_init :-
    format("---- :- initialization ----~n", []),
    format("  :- initialization(main).      加载完后跑 main/0~n", []),
    format("  :- initialization(main, main). SWI 还支持这个，等价于 -g main~n", []),
    format("  注意：GNU 的 :- initialization(Goal) 里 Goal 在加载时立刻执行，~n", []),
    format("        别在里面做需要终端交互的事~n", []).

% ------------------------------------------------------------
%  七、计数器：动态数据库当「模块状态」用
% ------------------------------------------------------------

bump(Name) :-
    retract(counter(Name, N0)),
    N1 is N0 + 1,
    assertz(counter(Name, N1)),
    !.
bump(Name) :-
    assertz(counter(Name, 1)).

demo_state :-
    format("---- 用动态数据库保存状态 ----~n", []),
    bump(calls), bump(calls), bump(calls),
    counter(calls, N),
    format("  bump 三次后 counter(calls) = ~w~n", [N]),
    format("  注意 bump/1 第一条子句末尾的 ! ：匹配到就别再试第二条~n", []),
    format("  没有那个 cut 的话，第一次调用会留下两条 counter 事实~n", []).

% ------------------------------------------------------------
%  入口
% ------------------------------------------------------------

main :-
    (   catch(run, E, (nl, format("*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format("*** run/0 失败~n", []), halt(1)
    ).

run :-
    demo_prefix, nl,
    demo_dispatch, nl,
    demo_dialect, nl,
    demo_public, nl,
    demo_init, nl,
    demo_state, nl,
    format("==== 18 结束 ====~n", []).

% 分散书写的子句（测试 :- discontiguous）
geo_area(triangle(B, H), A) :- A is B * H / 2.
