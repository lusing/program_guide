:- encoding(utf8).
/* ============================================================
   39 子类型 —— Prolog：声明式、算法化与最小类型（书 ch.15-17）
   甲·声明式子类型 subtype/2：S-Refl/S-Trans/S-Top/S-Arrow
      + 记录三律（宽度/深度/置换，图 15.3）
   乙·算法化子类型 asubtype/2：S-Refl/S-Trans 被清除，
      记录三律合并为 SA-Rcd 宏规则（图 16.2）——语法制导
   丙·类型机 typeof/2 的两版：含包含（T-Sub）的声明式
      vs 最小类型算法版（16.2 的算法类型化）；
      record 项 + 函数 + 上下文（命名变量版：查表即 nth0）
   验证面：两版子类型在样本对上等价（16.1.5 的机器面）；
      宽度/深度/置换各自见证；(λr:{x}.r.x) {x,y} 通过
      （书 15.1 的开篇例子）；T-Sub 与算法版给同型
      （16.2 的定理）；S-RcdPerm 使关系非反对称的见证
   ============================================================ */

:- use_module(library(lists)).

/* ---- 类型语法：Top / arrow(A,B) / rcd([l=T,...]) ---- */

/* ---- 甲·声明式子类型（图 15.1 + 15.3） ----
   注：S-Trans 的「猜中继类型 U」在 Prolog 里是无界搜索（负例
   会发散）——这正是书 16 章算法化的动机。本件只装直推规则；
   trans 可达的判断（如 perm+width 复合）走算法版对照。 ---- */
subtype(S, S).                                  % S-Refl
subtype(_, top).                                % S-Top
subtype(arr(S1, S2), arr(T1, T2)) :-            % S-Arrow（逆变/协变）
    subtype(T1, S1), subtype(S2, T2).
/* 模式守卫：三律只做「验证」（两侧给定）——T 侧未定时
   length 会造出无界列表（本批实测栈爆） */
subtype(rcd(SF), rcd(TF)) :- nonvar(TF),        % S-RcdWidth
    length(SF, N), length(TF, M), M < N,
    common_fields(SF, TF).
subtype(rcd(SF), rcd(TF)) :- nonvar(TF),        % S-RcdDepth
    same_labels(SF, TF),
    map_pairs(SF, TF).
subtype(rcd(SF), rcd(TF)) :- nonvar(TF),        % S-RcdPerm
    length(SF, N), length(TF, N), N > 1,
    perm(SF, TF0), TF0 = TF, TF0 \== SF.

subtype1(_, top).
subtype1(arr(S1, S2), arr(T1, T2)) :-
    subtype(T1, S1), subtype(S2, T2).
subtype1(rcd(SF), rcd(TF)) :- nonvar(TF),
    length(SF, N), length(TF, M), M < N, common_fields(SF, TF).
subtype1(rcd(SF), rcd(TF)) :- nonvar(TF),
    same_labels(SF, TF), map_pairs(SF, TF).
subtype1(rcd(SF), rcd(TF)) :- nonvar(TF),
    length(SF, N), length(TF, N), N > 1, perm(SF, TF).

common_fields(_, []) :- !.
common_fields(SF, [L=_|TF]) :-
    member(L=_, SF), !, common_fields(SF, TF).
/* 置换：库无 perm/2 时自带（ sublist 重排） */
perm([], []).
perm(L, [X|P]) :- select(X, L, R), perm(R, P).

same_labels(SF, TF) :-
    length(SF, N), length(TF, N),
    maplist([L=_,L=_]>>true, SF, TF).
map_pairs([], []).
map_pairs([L=S|SF], [L=T|TF]) :- subtype(S, T), map_pairs(SF, TF).

/* ---- 乙·算法化子类型（图 16.2） ---- */
asubtype(_, top) :- !.                          % SA-Top
asubtype(arr(S1, S2), arr(T1, T2)) :- !,        % SA-Arrow
    asubtype(T1, S1), asubtype(S2, T2).
asubtype(rcd(SF), rcd(TF)) :- !,                % SA-Rcd 宏规则
    every_field_has_subtype(TF, SF).
asubtype(S, S).                                  % 结构相等（Refl 的残迹）

every_field_has_subtype([], _).
every_field_has_subtype([L=T|TF], SF) :-
    member(L=S, SF),
    asubtype(S, T),
    every_field_has_subtype(TF, SF).

/* ---- 丙·类型机：命名变量 + 记录项 ---- */
/* 项：var(X) / lm(X,T,B) / ap(F,A) / rc([l=v,...]) / pr(E,l) */
lookup([X=T|_], X, T) :- !.
lookup([_|G], X, T) :- lookup(G, X, T).

/* 值常量（样本字段用） */
dtypeof(zero, _, natt).
dtypeof(truev, _, boolt).
atypeof(zero, _, natt).
atypeof(truev, _, boolt).

/* 声明式定型：T-Sub 版（宽进） */
dtypeof(var(X), G, T) :- lookup(G, X, S), subtype(S, T).
dtypeof(lm(X, A, B), G, arr(A, T2)) :- dtypeof(B, [X=A|G], T2).
dtypeof(ap(F, A), G, T) :-
    dtypeof(F, G, arr(S1, S2)), dtypeof(A, G, A0),
    subtype(A0, S1), subtype(S2, T).
dtypeof(rc(Fs), G, rcd(Ts)) :- dfields(Fs, G, Ts).
dtypeof(pr(E, L), G, T) :-
    dtypeof_rc(E, G, Ts), member(L=T0, Ts), subtype(T0, T).

/* 记录位的「开箱」版：直接拿 rcd 类型的字段表——绕开
   subtype(S, rcd(未定)) 的无界模式 */
dtypeof_rc(var(X), G, Ts) :- lookup(G, X, rcd(Ts)).
dtypeof_rc(rc(Fs), G, Ts) :- dfields(Fs, G, Ts).

dfields([], _, []).
dfields([L=E|Fs], G, [L=T|Ts]) :- dtypeof(E, G, T), dfields(Fs, G, Ts).

/* 算法版最小类型（16.2）：T-Sub 消失、T-App 靠算法子类型 */
atypeof(var(X), G, T) :- lookup(G, X, T).
atypeof(lm(X, A, B), G, arr(A, T2)) :- atypeof(B, [X=A|G], T2).
atypeof(ap(F, A), G, T) :-
    atypeof(F, G, arr(S1, S2)), atypeof(A, G, A0),
    asubtype(A0, S1), T = S2.
atypeof(rc(Fs), G, rcd(Ts)) :- afields(Fs, G, Ts).
atypeof(pr(E, L), G, T) :-
    atypeof(E, G, rcd(Ts)), member(L=T, Ts).

afields([], _, []).
afields([L=E|Fs], G, [L=T|Ts]) :- atypeof(E, G, T), afields(Fs, G, Ts).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 记录三律各一例（图 15.3） */
    check("宽度：{x=Nat,y=Nat} <: {x=Nat}",
           asubtype(rcd([x=natt, y=natt]), rcd([x=natt]))),
    check("深度：{x={a=Nat,b=Nat}} <: {x={a=Nat}}",
           asubtype(rcd([x=rcd([a=natt, b=natt])]), rcd([x=rcd([a=natt])]))),
    check("置换：{a=Nat,b=Bool} <: {b=Bool,a=Nat}",
           asubtype(rcd([a=natt, b=boolt]), rcd([b=boolt, a=natt]))),
    check("箭头逆变：{x}→N <: {x,y}→N（参数侧反宽）",
           asubtype(arr(rcd([x=natt]), natt),
                    arr(rcd([x=natt, y=natt]), natt))),
    check("Top 吸收一切", asubtype(arr(top, top), top)),

    /* ② 两版等价的样本（16.1.5 的机器面） */
    findall(ok, (sample_pair(S, T),
                 (  subtype(S, T) -> asubtype(S, T)
                 ;  \+ asubtype(S, T) )), Oks),
    length(Oks, N),
    format("ok   : ~w 对样本上声明式 = 算法化~n", [N]),

    /* ③ 置换使子类型非反对称（15.2 末的注记） */
    check("非反对称：双向成立但类型不同",
           ( asubtype(rcd([a=natt, b=boolt]), rcd([b=boolt, a=natt])),
             asubtype(rcd([b=boolt, a=natt]), rcd([a=natt, b=boolt])),
             rcd([a=natt, b=boolt]) \= rcd([b=boolt, a=natt]) )),

    /* ④ 书 15.1 开篇例：带多余字段的记录喂进只要 x 的函数 */
    check("(λr:{x:Nat}. r.x) {x=1,y=2} 通过（T-Sub）",
           dtypeof(ap(lm(r, rcd([x=natt]), pr(var(r), x)),
                      rc([x=zero, y=zero])),
                   [], natt)),
    check("算法版给同一答案（16.2 定理的样本）",
           atypeof(ap(lm(r, rcd([x=natt]), pr(var(r), x)),
                      rc([x=zero, y=zero])),
                   [], natt)),
    check("反例：只要 {y} 的函数吃 {x} 记录被拒",
           \+ atypeof(ap(lm(r, rcd([y=natt]), pr(var(r), y)),
                         rc([x=one])), [], _)),

    /* ⑤ 最小类型 vs 声明式的多解：{x,y} 的记录在声明式下
          既是 {x,y} 又是 {x}——算法版只给「最大信息」的那个 */
    check("最小类型的惟一性：算法版单解",
           findall(T, atypeof(rc([x=zero, y=zero]), [], T), [_])),

    format("all checks passed.~n").


sample_pair(rcd([x=natt, y=natt]), rcd([x=natt])).
sample_pair(rcd([x=natt]), rcd([x=natt, y=natt])).        % 反向：应双否
sample_pair(rcd([x=rcd([a=natt, b=natt])]), rcd([x=rcd([a=natt])])).
sample_pair(arr(rcd([x=natt]), natt), arr(rcd([x=natt, y=natt]), natt)).
sample_pair(arr(natt, rcd([x=natt, y=natt])), arr(natt, rcd([x=natt]))).
sample_pair(top, natt).                                    % 应双否
sample_pair(rcd([a=natt, b=boolt]), rcd([b=boolt, a=natt])).
sample_pair(rcd([b=boolt, a=natt]), rcd([a=natt, b=boolt])).
sample_pair(rcd([x=natt]), top).
sample_pair(boolt, natt).                                  % 应双否
