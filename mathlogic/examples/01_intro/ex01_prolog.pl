:- encoding(utf8).
% ex01_prolog.pl —— 第七家：Prolog（SWI-Prolog 10，本机通道）。
%
% 编码铁律：SWI 在 Windows 默认按本地代码页（GBK）读源文件——UTF-8
% 中文注释的尾字节会连着换行一起被吃掉，把下一行子句吞进注释。
% 首行必须声明 encoding(utf8)（见下）。同理，运行期输出一律纯 ASCII
% （START/END 标记），不跟控制台代码页较劲。

% hello-logic：Horn 子句即程序，合一即计算。逻辑方程由 SLD 消解
% 求解——这正是 20 章 T_P 语义的操作化身，40 章的主角；这里只让
% 最小的几条子句跑起来，确认「事实表 + 规则 + 递归」三件套。
%
% 兼容性：只用 SWI 与 GNU Prolog 公共谓词（format/2、findall/3、
% between/3、length/2、is/2），可跨引擎抽查（gprolog 跳过首行
% encoding 指令亦无碍）。

% 与：真值表就是四条事实——命题语义的最小 Prolog 化身（02 章）
conj(t, t, t).
conj(t, f, f).
conj(f, t, f).
conj(f, f, f).

% 皮亚诺数：递归子句即归纳数据（22 章形式算术的远亲）
peano(z).
peano(s(X)) :- peano(X).

% 按深度精确构造——有界生成器；findall 枚举无穷谓词会发散，
% 枚举务必经 between/peano_n 这类有限出口（40 章坑位预告）
peano_n(0, z).
peano_n(N, s(P)) :- N > 0, N0 is N - 1, peano_n(N0, P).

main :-
    format('==== ex01 prolog hello-logic START ====~n', []),
    (  conj(t, t, t) -> format('and tt: ok~n', []) ; format('and tt: FAIL~n', []) ),
    (  conj(t, f, f) -> format('and tf: ok~n', []) ; format('and tf: FAIL~n', []) ),
    (  peano(s(s(z))) -> format('peano 2: ok~n', []) ; format('peano 2: FAIL~n', []) ),
    findall(P, (between(0, 4, D), peano_n(D, P)), Ls),
    length(Ls, N),
    format('peano<5 count: ~w~n', [N]),
    format('==== ex01 prolog hello-logic END ====~n', []).
