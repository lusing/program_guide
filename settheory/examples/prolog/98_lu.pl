:- encoding(utf8).
% 第 98 章：有限截断不变量——谓词在段内一致 ⟹ 定义内容一致。

% 谓词 P 的样本：主测度（焦点 2）与截断版本。
inP(0, false).
inP(1, false).
inP(2, true).
inP(3, true).   % 截断之外：两个谓词在 3 处不同
inP(4, false).

inQ(0, false).
inQ(1, false).
inQ(2, true).
inQ(3, false).  % Q 与 P 在 3、4 处不同
inQ(4, true).

% 段 S 内 P 与 Q 一致（段 = {0,1,2}）。
seg(2).
agree_on_seg :- forall((between(0, 2, X), inP(X, A), inQ(X, B)), A == B).

% 项求值：self/mem/eq/and/not（与四通道同构）。
beval(P, self, X, V) :- call(P, X, V).
beval(P, mem(A), X, V) :- call(P, A, V).
beval(P, eq(A), X, V) :- (X =:= A -> V = true ; V = false).
beval(P, and(L, R), X, V) :- beval(P, L, X, VL), beval(P, R, X, VR),
                              (VL = true, VR = true -> V = true ; V = false).
beval(P, not(L), X, V) :- beval(P, L, X, VL),
                           (VL = true -> V = false ; V = true).

% 局部性：段内 x、段内参数 ⟹ P 与 Q 的求值一致。
locality :- forall(( between(0, 2, X), member(T, [self, mem(0), mem(2),
                                                   eq(1), eq(2),
                                                   and(self, mem(2)),
                                                   not(self),
                                                   and(eq(0), not(mem(1)))]),
                     beval(inP, T, X, A), beval(inQ, T, X, B) ),
                    A == B).

% 段外可感知：x = 3 处 self 项两谓词分歧。
disagree_outside :- inP(3, A), inQ(3, B), A \== B.

main :-
    format("==== 98~n"),
    agree_on_seg,
    locality,
    disagree_outside,
    format("段 {0,1,2} 内两谓词一致 ⟹ 全部样本项求值一致（局部性）；~n", []),
    format("段外（x=3）self 项立即分歧：L[U] 只在截断内无歧义~n", []),
    writeln("END ====").
