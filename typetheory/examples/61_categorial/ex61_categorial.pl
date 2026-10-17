:- encoding(utf8).
/* ============================================================
   55 范畴语法 —— Prolog（罗朝晖书 4.5 + 附录 E）
   依赖性子结构类型论 λ⊙：三种 Π——线性 ⊸、有序右向 /、
   有序左向 \（依赖形为 Πlx: A.B 等，此处非依赖形教学版）。
   机器面：
   ① 词汇表双轨（表 4.4/4.5：有序型 / 线性型）
   ② 有序分析器：A (A\B)→B 与 (B/A) A→B 两规则，**词序不动**
   ③ 线性分析器：A ⊸ B 消除，**允许排列**（资源敏感不删不重）
   ④ 依赖 Π 实例化：most:ΠX:CN.S/(X\S)，students:CN 代入 +
      累积 students ⊑ NP 使 NP\S 逆变接受
   ⑤ 双轨并用论（书 4.5.1 引 [115][169]）：单纯线性**生成
      过剩**（today 前置线性轨也收），有序轨拒绝——
      「有序管词序、线性管资源」的分工机器化
   ============================================================ */

/* ---- 类型语法 ---- */
ty(s).  ty(np).  ty(cn).
ty(sl(_, _)).    % A \ B   左向（找左参）
ty(sr(_, _)).    % B / A   右向（找右参）
ty(lin(_, _)).   % A -o B  线性
ty(pi(_)).       % ΠX:CN.B 依赖（X 具体化时以 inst 换入）

/* ---- 词汇表（表 4.4 / 4.5）---- */
% lex(词, 有序型, 线性型)
lex(john,    np,                          np).
lex(caught,  sr(np, sl(np, s)),           lin(np, lin(np, s))).
lex(the,     sr(cn, np),                  lin(cn, np)).
lex(fish,    cn,                          cn).
lex(today,   sl(sl(np, s), sl(np, s)),    lin(lin(np, s), lin(np, s))).
lex(most,    pi(sr(sl(xv, s), s)),        pi(lin(lin(xv, s), s))).
lex(students, cn,                         cn).
lex(study,   sl(np, s),                   lin(np, s)).
lex(hard,    sl(sl(np, s), sl(np, s)),    lin(lin(np, s), lin(np, s))).

/* ---- 累积关系 ⊑（附录 E 定义 E.1 的教学版）----
   词汇条目 c:CN ⟹ c ⊑ NP；函数类型对 ⊑ 同余（论域**逆变**） */
cumul(A, np) :- atom(A), lex(A, cn, cn).   % 词汇条目 c:CN ⟹ c ⊑ NP
cumul(sl(A, B), sl(A2, B)) :- cumul(A2, A).   % 逆变：A'⊑A ⟹ A\B ⊑ A'\B
cumul(sr(A, B), sr(A2, B)) :- cumul(A2, A).
cumul(lin(A, B), lin(A2, B)) :- cumul(A2, A).
cumul(T, T).

/* ---- 依赖 Π 的实例化：ΠX:CN.B 以 CN 常量代入 ---- */
inst(pi(sr(sl(xv, s), s)), A, sr(sl(A, s), s)) :- !.
inst(pi(lin(lin(xv, s), s)), A, lin(lin(A, s), s)) :- !.
inst(T, _, T).

/* ---- ② 有序分析器：两规则消解类型序列，词序刚性 ---- */
ord_red([A, sl(A, B) | Rest], [B | Rest]).   % 左应用
ord_red([sr(A, B), A | Rest], [B | Rest]).   % 右应用
ord_parse(Ts, T) :- ord_step(Ts, T).
ord_step([T], T) :- !.
ord_step(Ts, T) :- append(L, R, Ts), R \= [],
                   ord_red(R, R2), append(L, R2, Ts2),
                   ord_step(Ts2, T).

/* ---- ③ 线性分析器：⊸ 消除 + 排列（生成过剩之源）---- */
lin_red([A, lin(A, B) | Rest], [B | Rest]).
lin_parse(Ts, T) :-
    permutation(Ts, TsP),
    lin_step(TsP, T).
lin_step([T], T) :- !.
lin_step(Ts, T) :- append(L, R, Ts), R \= [],
                   lin_red(R, R2), append(L, R2, Ts2),
                   lin_step(Ts2, T).

/* 词 → 双轨类型 */
word_tys([], [], []).
word_tys([W | Ws], [O | Os], [L | Ls]) :-
    lex(W, O, L), word_tys(Ws, Os, Ls).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    S1 = [john, caught, the, fish, today],

    /* ① 基准句：两轨同收（式 4.100/4.101–4.103） */
    check("「John caught the fish today」有序轨收为 S",
           ( word_tys(S1, Os, _), ord_parse(Os, s) )),
    check("同句线性轨收为 S（λ串 john∘caught∘the∘fish∘today）",
           ( word_tys(S1, _, Ls), lin_parse(Ls, s) )),

    /* ② 双轨分家：today 前置——线性轨收（排列自由=生成过剩）、
          有序轨拒（词序刚性）——「有序+线性并用」的动机现场 */
    check("「Today John caught the fish」线性轨仍收（过剩！）",
           ( word_tys([today, john, caught, the, fish], _, Ls2),
             lin_parse(Ls2, s) )),
    check("同句有序轨拒收（today 只能贴在动词短语上）",
           ( word_tys([today, john, caught, the, fish], Os2, _),
             \+ ord_parse(Os2, s) )),

    /* ③ 依赖 Π 实例化：most（表 4.5，式 4.105–4.108） */
    check("most:ΠX:CN.S/(X\\S) 代入 students 得 S/(students\\S)",
           ( lex(most, OM, _), lex(students, cn, cn),
             inst(OM, students, sr(sl(students, s), s)) )),
    check("「Most students study hard」有序轨收为 S（含逆变）",
           ( word_tys([most, students, study, hard], Os3, _),
             parse_dep(Os3, s) )),
    check("同句线性轨收为 S",
           ( word_tys([most, students, study, hard], _, Ls3),
             parse_dep_lin(Ls3, s) )),

    /* ④ 逆变的必要性：NP\\S ⊑ students\\S（students ⊑ NP） */
    check("累积：students ⊑ NP",
           cumul(students, np)),
    check("逆变：NP\\S ⊑ students\\S",
           cumul(sl(np, s), sl(students, s))),

    /* ⑤ 资源敏感：john 双现——线性轨也救不了（无函项可用） */
    check("「John John caught…」两轨皆拒（资源/词序双违）",
           ( word_tys([john, john, caught, the, fish], Os5, Ls5),
             \+ ord_parse(Os5, s), \+ lin_parse(Ls5, s) )),

    format("ok   : 有序管词序、线性管资源、Π 管依赖——三轨各司其职~n"),
    format("all checks passed.~n").

/* 依赖轨：先 inst 掉 Π，再走对应分析器（含累积匹配） */
parse_dep(Ts, T) :- ord_step_dep(Ts, T).
parse_dep_lin(Ts, T) :-
    permutation(Ts, TsP), lin_step_dep(TsP, T).

/* 带累积匹配的消解（书 4.5.2：NP\\S ⊑ students\\S 让 study 上岗） */
ord_step_dep([T], T) :- !.
ord_step_dep(Ts, T) :-
    append(L, R, Ts), R \= [],
    (   R = [pi(B), cn | Rest],                  % Π 消去：通名实参
        lex(Stu, cn, cn), inst(pi(B), Stu, I), R2 = [I | Rest]
    ;   R = [A, sl(A2, B) | Rest], cumul(A2, A), R2 = [B | Rest]
    ;   R = [sr(A, B), A2 | Rest], cumul(A2, A), R2 = [B | Rest]
    ),
    append(L, R2, Ts2), ord_step_dep(Ts2, T).

lin_step_dep([T], T) :- !.
lin_step_dep(Ts, T) :-
    append(L, R, Ts), R \= [],
    (   R = [pi(B), cn | Rest],
        lex(Stu, cn, cn), inst(pi(B), Stu, I), R2 = [I | Rest]
    ;   R = [A, lin(A2, B) | Rest], cumul(A, A2),
        R2 = [B | Rest]
    ),
    append(L, R2, Ts2), lin_step_dep(Ts2, T).



