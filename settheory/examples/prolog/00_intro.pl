:- encoding(utf8).
% 第 00 章 导引：一阶语言的公式与 ZFC 公理的形状
%
% Prolog 通道的立场：把一阶集合论语言的**语法**做成数据，
% 用项/公式深嵌入逐条打印公理的形状，并推演 Russell 悖论。

% ---------- 一、一阶语言：项与公式 ----------
% 语言 L = { ∈ }。变元用 v(N) 表示；没有函数符号与常量。

term(v(N)) :- integer(N), N >= 0.

form(mem(T1, T2)) :- term(T1), term(T2).
form(eq(T1, T2))  :- term(T1), term(T2).
form(not(F))      :- form(F).
form(and(F1, F2)) :- form(F1), form(F2).
form(or(F1, F2))  :- form(F1), form(F2).
form(imp(F1, F2)) :- form(F1), form(F2).
form(iff(F1, F2)) :- form(F1), form(F2).
form(all(N, F))   :- integer(N), N >= 0, form(F).
form(ex(N, F))    :- integer(N), N >= 0, form(F).

% ---------- 二、ZFC 前两条公理的形状（示意两例） ----------
% 外延：∀x ∀y ( ∀u (u∈x ↔ u∈y) → x = y )
axiom(extensionality,
       all(0, all(1, imp(all(2, iff(mem(v(2), v(0)), mem(v(2), v(1)))),
                        eq(v(0), v(1)))))).

% 配对：∀a ∀b ∃c ∀x ( x∈c ↔ (x=a ∨ x=b) )
axiom(pairing,
       all(0, all(1, ex(2, all(3,
          iff(mem(v(3), v(2)),
              or(eq(v(3), v(0)), eq(v(3), v(1))))))))).

% ---------- 三、Russell 悖论的命题核心 ----------
% 全称概括（假公理）给出 R = {x : x ∉ x}，于是 R∈R ↔ ¬(R∈R)。
% 命题逻辑炸弹的形状：P ↔ ¬P 蕴含 ⊥。用纯粹的命题表推演：

% 双向规则：p <-> not_p
:- dynamic p/0, not_p/0.
russell_bomb :-
    retractall(p), retractall(not_p),
    asserta((not_p :- p)),          % P → ¬P
    asserta((p :- not_p)),          % ¬P → P
    (   true ),
    format("  规则 P -> ~~P 与 ~~P -> P 互指：~n"),
    format("  若 P 则 ~~P（矛盾）；若 ~~P 则 P（矛盾）。~n"),
    format("  故 P <-> ~~P 不可能被任何一致理论满足。~n"),
    format("  （注意：不要真的去 call(p)——互指子句造成无限~n"),
    format("   递归，这正是『不一致』的程序形态。）~n"),
    retractall(p), retractall(not_p).

% ---------- 四、main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 00 导引：一阶语言与公理的形状~n"),
    forall(axiom(Name, F),
           (   form_chk(F),
               format("  公理 ~w : 良型 OK~n", [Name]))),
    format("Russell 悖论推演：~n"),
    russell_bomb,
    format("结论：全称概括不可采纳；分离模式是安全的弱化。~n"),
    format("END ====~n").

% 公式的良型检查（独立于 form/1，作为双保险验证器）
form_chk(mem(A, B)) :- !, term(A), term(B).
form_chk(eq(A, B))  :- !, term(A), term(B).
form_chk(not(F))    :- !, form_chk(F).
form_chk(and(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(or(A, B))  :- !, form_chk(A), form_chk(B).
form_chk(imp(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(iff(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(all(_, F)) :- !, form_chk(F).
form_chk(ex(_, F))  :- !, form_chk(F).
form_chk(_) :- !, fail.

term_chk(v(N)) :- integer(N), N >= 0, !.

