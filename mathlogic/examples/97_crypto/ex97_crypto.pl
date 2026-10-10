:- encoding(utf8).
% ex97_crypto.pl —— 密码与信任机器（Müller-Stach ch4）Prolog 搜索面
%
% 与 Coq/Lean 通道（powmod+RSA 回环+费马账+Shamir 三趟+哈希链+
% 纠缠锥+感知器）互补，这里跑离散对数的回溯搜索本体：
%   dlp/4        —— 小群上 g^m ≡ y (mod p) 的全部解枚举；
%   dlp_table/1  —— Z_17^* 的 DLP 全表（生成元 vs 非生成元）；
%   gen_check/1  —— 生成元判定（阶 = p-1）——Shamir/RSA 的困难
%                   假设（离散对数难）在小群上的可解现场：小群
%                   全表秒出，大群（2^2048）指数爆炸——单向函数
%                   的「易正向、难反向」在表的两半现形。

% 快速模幂（平方-乘，Prolog is 上的递归）
powmod(_, 0, _, 1) :- !.
powmod(B, E, N, R) :-
    E mod 2 =:= 1, !,
    E1 is E // 2,
    powmod(B, E1, N, H),
    R is (H * H * B) mod N.
powmod(B, E, N, R) :-
    E1 is E // 2,
    powmod(B, E1, N, H),
    R is (H * H) mod N.

% 离散对数：g^m ≡ y (mod p)，m ∈ [0, p-2] 全解枚举
dlp(G, Y, P, M) :-
    P2 is P - 1,
    between(0, P2, M0),
    powmod(G, M0, P, Y),
    !,
    M = M0.           % 唯一解（g 为生成元时）；截断取首个

% Z_p^* 全表：对每个 y ∈ [1, p-1] 求 m（给定基 g）
dlp_rows(G, P, T) :-
    P1 is P - 1,
    findall((Y, M),
            ( between(1, P1, Y),
              dlp(G, Y, P, M) ),
            T).

% 双基对照：生成元（2 mod 11）覆盖全部 10 行；非生成元
% （3 mod 11，阶 5）只覆盖其循环子群的一半——DLP 的可解性
% 系于基的阶
dlp_table(P) :-
    dlp_rows(2, P, T2), length(T2, N2),
    format("DLP base 2 mod ~d : ~d rows (generator: full)~n", [P, N2]),
    dlp_rows(3, P, T3), length(T3, N3),
    format("DLP base 3 mod ~d : ~d rows (ord 5: subgroup only)~n", [P, N3]).

% 生成元判定：g 的阶 = p-1（g^k ≠ 1 对 0<k<p-1）
ord(G, P, K) :-
    P1 is P - 1,
    between(1, P1, K),
    powmod(G, K, P, 1), !.

is_gen(G, P) :-
    ord(G, P, K),        % 最小阶（截断找首个）
    K =:= P - 1.         % 费马说 g^(p-1)≡1 恒真——生成元要阶恰为 p-1

gen_check(P) :-
    P2 is P - 1,
    findall(G, (between(2, P2, G), is_gen(G, P)), Gs),
    format("generators of Z_~d* : ~w~n", [P, Gs]).

% 3 在 Z_17 里是生成元（阶 16）——Shamir 协议的 g=3 选对了
main :-
    format("== DLP tables (backtracking) ==~n"),
    dlp_table(11),
    gen_check(17),
    powmod(3, 5, 17, S1),
    format("shamir step1 : 3^5 mod 17 = ~d~n", [S1]),
    dlp(3, S1, 17, M),
    format("Eve inverting DLP: finds m = ~d (small p! real p: 2^2048)~n",
           [M]),
    format("==== ex71 crypto END ====~n").
