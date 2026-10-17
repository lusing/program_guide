:- encoding(utf8).
/* ============================================================
   50 MTT 语义学 —— Prolog 双轨对照机（罗朝晖书 3.1–3.3）
   蒙太古轨道（简单类型论 C：e/t，表 3.1）vs MTT 轨道
   （现代类型论，表 3.2）——同一句话在两条轨道上的判决：
   ① 「桌子会讲话」：蒙太古**合法**（谓词 e→t 作用于任何实体，
      只是通常为假，式 3.21）；MTT **非法**（Table 与 Human
      互不相交、无强制可插，式 3.22）——选择限制 = 类型检测
   ② read 例（式 3.33–3.41）：Man≤Human、Σheavy≤Book 两条
      强制让 read(zhang, W&P) 合法
   ③ 语义生成对照：some 的两个定义（式 3.7 vs 3.12）产出
      不同的公式——量化带不带类型标注
   ============================================================ */

/* ---- 蒙太古轨道（表 3.1）：万物皆 e，谓词皆 e→t ---- */
mtype(catM,    arr(e, t)).
mtype(tableM,  arr(e, t)).
mtype(studentM, arr(e, t)).
mtype(talkM,   arr(e, t)).
mtype(zhangM,  e).
mtype(table1M, e).

/* 蒙太古组合：谓词可作用于任何实体——无选择限制 */
mont_ok(P, X) :- mtype(P, arr(e, t)), mtype(X, e).

/* ---- MTT 轨道（表 3.2）：通名即类型 ---- */
ttype(human,  cn).   ttype(cat, cn).   ttype(table, cn).
ttype(man,    cn).   ttype(student, cn).  ttype(book, cn).
ttype(object, cn).   ttype(event, cn).
ttype(zhang, human).  ttype(oliver, cat).  ttype(table1, table).
ttype(bc1, sig(cat, black)).                  /* 一只黑猫 */
ttype(wp_dummy_book, book).                   /* 一本普通书 */
ttype(zhang_man, man).                       /* 张三作为男人 */
ttype(wp, sig(book, heavy)).                 /* 很重的 W&P */
ttype(talk,   arr(human, prop)).             /* 讲话 */
ttype(read,   arr(human, arr(book, prop))).  /* 读 */
ttype(black,  arr(object, prop)).            /* 黑的 */
ttype(enjoy,  arr(human, arr(event, prop))). /* 很喜欢（事件论域） */

/* ---- 强制转换表（coercion，48 章）----
   man ≤π1 human（Man=Σmale）；student ≤ human；
   cat ≤ animal ≤ object 链；Σheavy ≤π1 book；book ≤reading event */
coerce(man, human, pi1).
coerce(student, human, sh).
coerce(cat, animal, ca).
coerce(animal, object, ao).
coerce(sig(book, heavy), book, pi1).
coerce(sig(cat, black), cat, pi1).
coerce(book, event, reading_ev).    /* 事件强迫（3.53） */

sub(A, B) :- coerce(A, B, _).
sub(A, B) :- coerce(A, C, _), sub(C, B).   /* 链式（黑猫→猫→动物→物体） */

/* MTT 组合：论域 D 收 D 的对象，也收 D 的子类型对象（强制插入） */
mtt_ok1(P, X) :- ttype(P, arr(D, prop)), ttype(X, D).
mtt_ok1(P, X) :- ttype(P, arr(D, prop)), ttype(X, DX), sub(DX, D).

/* 二元谓词逐参检查 */
mtt_ok2(P, X, Y) :- ttype(P, arr(D1, arr(D2, prop))),
    ttype(X, DX), (DX = D1 ; sub(DX, D1)),
    ttype(Y, DY), (DY = D2 ; sub(DY, D2)).

/* ---- 语义生成对照：some 两版 ---- */
/* 蒙太古（式 3.7）：someM(P,Q) = ∃x:e. P(x) ∧ Q(x) */
gen(montague, somem(P, Q), exists(x, e, and(app(P, x), app(Q, x)))).
/* MTT（式 3.12）：some(A,P) = ∃x:A. P(x)——量化带类型标注 */
gen(mtt, some(A, P), exists(x, A, app(P, x))).

/* ---- 见证 ---- */
check(Name, Goal) :-
    (   call(Goal) -> format("ok   : ~w~n", [Name])
    ;   format("FAIL : ~w~n", [Name]), fail ).

main :-
    /* ① 「桌子会讲话」双轨判决（本章主角） */
    check("蒙太古：talkM(table1M) 合法（只是通常为假）",
           mont_ok(talkM, table1M)),
    check("MTT：talk(table1) 非法——论域 Human 与 Table 互不相交",
           \+ mtt_ok1(talk, table1)),
    check("MTT：talk(zhang) 合法（zhang:Human）",
           mtt_ok1(talk, zhang)),

    /* ② 子类型的必要性：read 三句（3.36–3.38） */
    check("read(zhang_man, b) 合法：Man ≤π1 Human",
           mtt_ok2(read, zhang_man, wp_dummy_book)),
    check("read(h, W&P) 合法：Σheavy ≤π1 Book",
           ( ttype(wp, sig(book, heavy)),
             mtt_ok2(read, zhang, wp) )),
    check("read(zhang_man, W&P) 合法：一句双强制（式 3.38）",
           mtt_ok2(read, zhang_man, wp)),

    /* ③ 黑猫的链式子类型：Σblack ≤ cat ≤ animal ≤ object */
    check("black(黑猫) 合法：Σ≤cat≤animal≤object 链式强制",
           mtt_ok1(black, bc1)),
    check("black(table) 非法：Table 无强制链到 Object",
           \+ mtt_ok1(black, table1)),

    /* ④ 事件强迫：enjoy(julie, x) x:Book 合法（3.52–3.55） */
    check("enjoy(j, 书) 合法：Book ≤reading Event（事件强迫）",
           mtt_ok2(enjoy, zhang, wp_dummy_book)),
    check("enjoy(j, W&P) 合法：Σheavy≤Book≤Event 三级链",
           mtt_ok2(enjoy, zhang, wp)),

    /* ⑤ 语义生成：some 两版产出不同公式 */
    check("蒙太古 some：∃x:e. studentM(x)∧talkM(x)（式 3.8）",
           gen(montague, somem(studentM, talkM),
               exists(x, e, and(app(studentM, x), app(talkM, x))))),
    check("MTT some：∃x:student. talk(x)（式 3.14，量化带类型）",
           gen(mtt, some(student, talk),
               exists(x, student, app(talk, x)))),

    format("ok   : 通名即类型 vs 通名即谓词——双轨判决完毕~n"),
    format("all checks passed.~n").
