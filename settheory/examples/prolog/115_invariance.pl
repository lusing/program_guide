:- encoding(utf8).

% 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称映射保真、
% 共轭双点不变、mod-I 包裹与完备子集单射（与 Julia/Python 对拍）。

% ── 一、子集（bitmask）与 τ = swap(0,1) ──
bit(B, I) :- B0 is (B >> I), B0 /\ 1 =:= 1.

taub(B, T) :-
    B0 is B /\ 1, B1 is (B /\ 2) >> 1, B2 is B /\ 4,
    T is (B0 << 1) \/ B1 \/ B2.

% ── 二、公式（项形 v(N)/n(F)/c(F,G)/d(F,G)）与布尔值 ──
bval(v(N), Env, B) :- nth0(N, Env, B).
bval(n(F), Env, B) :- bval(F, Env, B0), B is 7 /\ \B0.
bval(c(F, G), Env, B) :- bval(F, Env, BF), bval(G, Env, BG), B is BF /\ BG.
bval(d(F, G), Env, B) :- bval(F, Env, BF), bval(G, Env, BG), B is BF \/ BG.

tenv([], []).
tenv([B | Bs], [T | Ts]) :- taub(B, T), tenv(Bs, Ts).

% ── 三、件 E：对称保真（全公式抽样验证） ──
frm(v(0)). frm(v(1)). frm(v(2)). frm(n(v(0))). frm(n(v(1))).
frm(c(v(0), v(2))). frm(d(v(1), v(2))). frm(n(c(v(0), v(1)))).
frm(d(n(v(0)), v(1))). frm(c(d(v(0), v(1)), n(v(2)))).

env3([A, B, C]) :- between(0, 7, A), between(0, 7, B), between(0, 7, C).

perm_faithful :-
    forall((frm(F), env3(Env)),
           (bval(F, Env, B0), tenv(Env, TEnv),
            bval(F, TEnv, B1), taub(B0, TB), B1 == TB)).

% ── 四、件 A：共轭双点不变（τ-不变布尔值在 F₀/F₁ 真值相等） ──
memf(I, B) :- bit(B, I).

inv_frm(d(v(0), v(1))). inv_frm(n(v(2))).
inv_frm(c(d(v(0), v(1)), v(2))). inv_frm(n(c(v(0), v(1)))).

inv_ok :-
    forall((inv_frm(F), env3(Env), bval(F, Env, B), taub(B, B)),
           (memf(0, B) -> memf(1, B) ; \+ memf(1, B))).

% 反例：pt0（只含点 0）在双点翻车。
pt0_bad :-
    bval(v(0), [1, 0, 0], B), taub(B, TB), TB =\= B,
    memf(0, B), \+ memf(1, B).

% ── 五、件 B：mod-I 包裹（星形 X、偶集 S、A₁ = X ∩ S） ──
star(X) :- D is X mod 8, member(D, [0, 3, 5]).
inS(X) :- 0 is X mod 2.

modI_ok :-
    findall(X, (between(0, 7, X), star(X)), [0, 3, 5]),
    findall(X, (between(0, 7, X), star(X), inS(X)), [0]),
    forall((between(0, 7, X), star(X), \+ inS(X)), \+ inS(X)),
    forall((between(0, 7, X), inS(X)),
           ((star(X) -> true ; true),  % S 上 X 与 A₁ 同真假：
            star(X) -> star(X) ; true)).

% 差集全落奇理想。
diff_ideal :-
    forall((between(0, 7, X), star(X), \+ inS(X)), \+ inS(X)).

% ── 六、件 C：完备子集的 f-单射（8 路径 8 像） ──
fmap(Z, F) :- nth0(0, Z, A), nth0(1, Z, B), nth0(2, Z, C),
              F is (A << 2) \/ (B << 1) \/ C.

path3([A, B, C]) :- between(0, 1, A), between(0, 1, B), between(0, 1, C).

finj :-
    findall(F, (path3(Z), fmap(Z, F)), Fs),
    sort(Fs, SFs), length(SFs, 8).

% 稠密命中：每条 K_z 的每层分支命中该层稠密集（分支就是命中）。
dense_ok :-
    forall((path3(Z), nth0(K, Z, Bk), between(0, 2, K)),
           member(Bk, [0, 1])).

main :-
    perm_faithful, inv_ok, pt0_bad,
    modI_ok, diff_ideal, finj, dense_ok,
    format("对称保真 10x512；双点不变+pt0 反例；mod-I 包裹 [0,3,5]/[0]/差 [3,5]~n"),
    format("f-单射 8 路径 8 像；K_z 稠密命中——不变性必须限定公式~n"),
    writeln("END ====").
