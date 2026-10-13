:- encoding(utf8).
% 第 02 章 序数：有限 von Neumann 序数的推理机
%
% 有限序数 n = {0,1,...,n-1} 用嵌套项表示：
%   o(0) 表示 ∅；o(s(N)) 表示 N ∪ {N}
% ∈ 关系：X ∈ o(s(N)) ⟺ X = o(N) ∨ X ∈ o(N)
% 在此基础上验证：< 的三歧性、∈ 的传递性（Transset）。

% ---------- 一、表示与隶属 ----------

% mem(X, o(s(N))) :- X = o(N).
mem(o(N), o(s(N))).
mem(X, o(s(N))) :- mem(X, o(N)).
% mem(X, o(0)) 恒假（无子句）

% ---------- 二、< 即 ∈ ----------

lt(X, Y) :- mem(X, Y).

% ---------- 三、传递性：X ∈ Y ∈ Z ⟹ X ∈ Z ----------

trans_example(o(0), o(s(0)), o(s(s(0)))).
% 0 ∈ 1 ∈ 2 ⟹ 0 ∈ 2
check_trans :-
    trans_example(X, Y, Z),
    mem(X, Y), mem(Y, Z), mem(X, Z),
    format("  传递性：~w ∈ ~w ∈ ~w 且 ~w ∈ ~w~n", [X, Y, Z, X, Z]).

% 一般性传递（对有限深度归纳）：
trans_mem(X, Y, Z) :- mem(X, Y), mem(Y, Z), mem(X, Z).

% ---------- 四、三歧性（有限部分） ----------

% 对任何两个具体有限序数，恰好一者成立：lt / eq / gt
trich(X, Y) :-
    (   lt(X, Y) -> format("  ~w < ~w~n", [X, Y])
    ;   X = Y    -> format("  ~w = ~w~n", [X, Y])
    ;   lt(Y, X) -> format("  ~w > ~w~n", [X, Y])
    ).

% ---------- 五、非自反 ----------

% mem(X, X) 对任何有限序数不可满足：
% 测试：查询 mem(o(s(0)), o(s(0)))？—— 第一条子句要求 o(s(0))=o(0)（否），
% 第二条递归 mem(o(s(0)), o(0)) 无子句。失败即非自反。
check_irrefl :-
    (   mem(o(s(0)), o(s(0))) -> format("  自反（错误！）~n")
    ;   format("  1 ∉ 1：非自反成立~n")
    ).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 02 序数：有限 von Neumann 序数推理~n"),
    format("成员检查：~n"),
    (   mem(o(0), o(s(0))) -> format("  0 ∈ 1 ✓~n") ; format("  0 ∈ 1 失败（错误！）~n") ),
    (   mem(o(0), o(s(s(0)))) -> format("  0 ∈ 2 ✓~n") ; format("  0 ∈ 2 失败（错误！）~n") ),
    (   mem(o(s(0)), o(s(s(0)))) -> format("  1 ∈ 2 ✓~n") ; format("  1 ∈ 2 失败（错误！）~n") ),
    (   mem(o(s(s(0))), o(s(0))) -> format("  2 ∈ 1（错误！）~n") ; format("  2 ∉ 1 ✓~n") ),
    check_trans,
    check_irrefl,
    format("三歧性（= 即 ∈ 或被 ∈）：~n"),
    trich(o(0), o(s(0))),
    trich(o(s(0)), o(s(0))),
    trich(o(s(s(0))), o(s(0))),
    format("要点：有限序数上 ∈ 即 <，传递/非自反/三歧逐条成立。~n"),
    format("END ====~n").
