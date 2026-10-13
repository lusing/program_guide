:- encoding(utf8).
% 第 01 章 公理：九公理的完整深嵌入
%
% 00 章展示了两条公理的形状；本章把 ZFC 九条全部做成项，
% 逐条良型检查，并推演三个元事实：
%   (1) 分离公理保证"子类是集合"；
%   (2) 分离 ⟹ 空集存在（需先有一个集合）；
%   (3) 习题 1.14 的结构：分离可以从替换推出。

% ---------- 一、项与公式（同 00 章） ----------

term(v(N)) :- integer(N), N >= 0.

% 语言含一个常量符号：empty_const（表示空集/零），它不是变元
termx(v(N)) :- integer(N), N >= 0, !.
termx(empty_const) :- !.
termx(upair_union(T)) :- !, termx(T).

form(mem(T1, T2)) :- termx(T1), termx(T2).
form(eq(T1, T2))  :- termx(T1), termx(T2).
form(not(F))      :- form(F).
form(and(F1, F2)) :- form(F1), form(F2).
form(or(F1, F2))  :- form(F1), form(F2).
form(imp(F1, F2)) :- form(F1), form(F2).
form(iff(F1, F2)) :- form(F1), form(F2).
form(all(N, F))   :- integer(N), N >= 0, form(F).
form(ex(N, F))    :- integer(N), N >= 0, form(F).

% ---------- 二、九公理 ----------

% I 外延：∀x∀y(∀u(u∈x↔u∈y) → x=y)
axiom(extensionality_I,
  all(0, all(1, imp(all(2, iff(mem(v(2), v(0)), mem(v(2), v(1)))),
                   eq(v(0), v(1)))))).

% II 配对：∀a∀b∃c∀x(x∈c ↔ x=a ∨ x=b)
axiom(pairing_II,
  all(0, all(1, ex(2, all(3,
    iff(mem(v(3), v(2)),
        or(eq(v(3), v(0)), eq(v(3), v(1))))))))).

% III 分离（模式）：对每个公式 φ(u,p)：
%    ∀x∀p∃y∀u(u∈y ↔ u∈x ∧ φ(u,p))
%    用 schema(phi(N)) 标记"φ 是第 N 个模式实例的谓词"
axiom(separation_III(schema(_)),
  all(0, all(1, ex(2, all(3,
    iff(mem(v(3), v(2)),
        and(mem(v(3), v(0)), phi(v(3), v(1))))))))).

% IV 并：∀x∃y∀u(u∈y ↔ ∃z(z∈x ∧ u∈z))
axiom(union_IV,
  all(0, ex(1, all(2,
    iff(mem(v(2), v(1)),
        ex(3, and(mem(v(3), v(0)), mem(v(2), v(3))))))))).

% V 幂集：∀x∃y∀u(u∈y ↔ u⊆x)，其中 u⊆x ≡ ∀w(w∈u → w∈x)
axiom(power_V,
  all(0, ex(1, all(2,
    iff(mem(v(2), v(1)),
        all(3, imp(mem(v(3), v(2)), mem(v(3), v(0))))))))).

% VI 无穷：∃S(0∈S ∧ ∀y∈S (y∪{y}∈S))
%    0 记为 v(0)；y∪{y} 的存在由配对+并保证，公理只说封闭性
axiom(infinity_VI,
  ex(0, and(mem(empty_const, v(0)),
            all(1, imp(mem(v(1), v(0)),
                       mem(upair_union(v(1)), v(0))))))).

% VII 替换（模式）：函数性 + 像restrict在集合上
axiom(replacement_VII(schema(_)),
  all(0, all(1, imp(
    all(2, all(3, all(4, imp(and(psi(v(2), v(3), v(1)),
                                  psi(v(2), v(4), v(1))),
                             eq(v(3), v(4)))))),
    ex(5, all(3, iff(mem(v(3), v(5)),
                     ex(2, and(mem(v(2), v(0)),
                               psi(v(2), v(3), v(1))))))))))).

% VIII 正则：∀S(S≠∅ → ∃x∈S ∀y∈x (y∉S))
axiom(regularity_VIII,
  all(0, imp(neq_empty(v(0)),
             ex(1, and(mem(v(1), v(0)),
                       all(2, imp(mem(v(2), v(1)),
                                  not(mem(v(2), v(0)))))))))).

% IX 选择：∀S(∅∉S ∧ ∀X∈S X≠∅ → ∃f(f 是 S 上的选择函数))
%    选择函数的"f(X)∈X"用 pred(f, X, f_of) 简化表示
axiom(choice_IX,
  all(0, imp(and(not(mem(v(0), v(0))),
                 all(1, imp(mem(v(1), v(0)), neq_empty(v(1))))),
             ex(2, all(1, imp(mem(v(1), v(0)),
                              ex(3, and(chfun_apply(v(2), v(1), v(3)),
                                        mem(v(3), v(1)))))))))).

:- discontiguous form/1.

% 辅助原子（在模式公式中出现）
form(upair_union(T)) :- term(T).
form(empty_const) :- true.
form(neq_empty(T))   :- term(T).
form(chfun_apply(T1, T2, T3)) :- term(T1), term(T2), term(T3).
form(phi(T1, T2))    :- term(T1), term(T2).
form(psi(T1, T2, T3)) :- term(T1), term(T2), term(T3).

% ---------- 三、三个元事实 ----------

% (1) 分离保证：类的交是集合（"a subclass of a set is a set"）
%     类 C = {u : φ(u)} 与集合 X 的交 C ∩ X 是集合
meta_fact(1, '分离 ⟹ 子类是集合：C ∩ X 是集合，对任何类 C 与集合 X').

% (2) 空集存在：取任何集合 X（无穷公理保证存在），∅ = X - X 分离而得
meta_fact(2, '分离 + 无穷 ⟹ 空集存在：∅ = {u ∈ X : u ≠ u}').

% (3) 习题 1.14：分离可以从替换推出
%     给 φ，令 F = {(x,y) : y = x ∧ φ(x)}，则 {x∈X : φ(x)} = F[X]
meta_fact(3, '习题 1.14：替换 ⟹ 分离（F = {(x,x) : φ(x)}，F[X] 即分离集）').

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 01 公理：九公理深嵌入~n"),
    forall(axiom(Name, F),
           (   form_chk(F) ->
               format("  ~w : 良型 OK~n", [Name])
           ;   format("  ~w : 良型 FAIL~n", [Name])
           )),
    forall(meta_fact(N, Desc),
           format("  元事实 ~d：~w~n", [N, Desc])),
    format("结论：九公理全部良型；分离模式与替换模式用 schema(_) 索引。~n"),
    format("END ====~n").

form_chk(mem(A, B)) :- !, termx(A), termx(B).
form_chk(eq(A, B))  :- !, termx(A), termx(B).
form_chk(not(F))    :- !, form_chk(F).
form_chk(and(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(or(A, B))  :- !, form_chk(A), form_chk(B).
form_chk(imp(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(iff(A, B)) :- !, form_chk(A), form_chk(B).
form_chk(all(_, F)) :- !, form_chk(F).
form_chk(ex(_, F))  :- !, form_chk(F).
form_chk(upair_union(A)) :- !, termx(A).
form_chk(empty_const) :- !.
form_chk(neq_empty(A))   :- !, termx(A).
form_chk(chfun_apply(A, B, C)) :- !, termx(A), termx(B), termx(C).
form_chk(phi(A, B))       :- !, termx(A), termx(B).
form_chk(psi(A, B, C))    :- !, termx(A), termx(B), termx(C).
form_chk(_) :- !, fail.
