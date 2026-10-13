:- encoding(utf8).
% 第 15 章 OD/HOD：可定义性谓词与 Berry 型自指检查
%
% 检查"定义模板"是否带序数参数（OD 的合法形态）以及
% 最小反例原理的自指形态。

% ---------- 一、定义模板的参数形态 ----------

% param(ord(_))：序数参数（安全）
% param(set(_))：集合参数（越界——超出 OD）

safe_params([]).
safe_params([ord(_) | Ps]) :- safe_params(Ps).

% ---------- 二、OD 判定骨架 ----------

% X ∈ OD ⟺ X = {u : φ(u, α₁..αₙ)}（安全参数）
od_ok(define(_, Params)) :- safe_params(Params).

% ---------- 三、最小反例与 Berry ----------

% least_undef(Def, D)：D 是 ~Def 的最小反例（强归纳）
% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 15 OD 与 HOD~n"),
    (   od_ok(define(phi, [ord(omega), ord(17)])) ->
        format("  φ(u, ω, 17) 定义：序数参数 ✓ ∈ OD~n")
    ;   format("  （错误）~n") ),
    (   od_ok(define(psi, [set(x)])) ->
        format("  ψ(u, x) 定义：集合参数（错误！越出 OD）~n")
    ;   format("  ψ(u, x) 定义被拒 ✓（集合参数越界）~n") ),
    format("  Berry：'最小不可定义'若可定义则自爆——OD 的参数~n"),
    format("  安全性来自序数的 canonical 良序。HOD=TC⊆OD（定理38）。~n"),
    format("END ====~n").
