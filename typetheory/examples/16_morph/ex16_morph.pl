:- encoding(utf8).
:- discontiguous chk/2, cond/1.

% ============================================================
% 16 理论态射与小理论方法 —— Prolog 表级镜像（Farmer ch.13）
%   · 目标 = 运算表（模 2 加 xor 表 / 合取 and 表）
%   · 义务 = 源公理的像在目标表上的有效性：
%     ν⁺（xor）三条义务全过——态射；
%     GRP 的逆元像在 and 表上失败——机器揪出见证 0——非态射
%   · 运输：唯一幺元定理的像在两张表上各查一遍
% ============================================================

% ---- 目标表 ----
target(xor, [0,1, 1,0], 0).
target(and, [0,0, 0,1], 1).

tapp(Tab, X, Y, V) :- nth0(Ix, [0,1], X), nth0(Iy, [0,1], Y),
    I is Ix * 2 + Iy, nth0(I, Tab, V).

% ---- MON 三公理的像（义务） ----
ob_assoc(Tab) :-
    \+ ( member(X, [0,1]), member(Y, [0,1]), member(Z, [0,1]),
         tapp(Tab, X, Y, XY), tapp(Tab, XY, Z, L),
         tapp(Tab, Y, Z, YZ), tapp(Tab, X, YZ, R), L \= R ).
ob_lid(Tab, U) :-
    \+ ( member(X, [0,1]), tapp(Tab, U, X, V), V \= X ).
ob_rid(Tab, U) :-
    \+ ( member(X, [0,1]), tapp(Tab, X, U, V), V \= X ).
mon_obligations(Name) :-
    target(Name, Tab, U),
    ob_assoc(Tab), ob_lid(Tab, U), ob_rid(Tab, U).

% ---- GRP 逆元公理的像：∀x ∃y. y·x = U ∧ x·y = U ----
inv_obligation(Name) :-
    target(Name, Tab, U),
    \+ ( member(X, [0,1]),
         \+ ( member(Y, [0,1]),
              tapp(Tab, Y, X, U), tapp(Tab, X, Y, U) ) ).

% 义务失败时的见证（无逆元的元素）
inv_witness(Name, X) :-
    target(Name, Tab, U),
    member(X, [0,1]),
    \+ ( member(Y, [0,1]), tapp(Tab, Y, X, U), tapp(Tab, X, Y, U) ).

% ---- 运输：唯一双侧幺元定理的像 ----
unique_id_image(Name) :-
    target(Name, Tab, U),
    findall(X, ( member(X, [0,1]),
                 \+ ( member(Y, [0,1]),
                      ( tapp(Tab, X, Y, V1), V1 \= Y
                      ; tapp(Tab, Y, X, V2), V2 \= Y ) ) ),
            Ids),
    Ids == [U].

% ============================================================
% 电池
% ============================================================
chk(1, 'ν⁺（xor 表）：MON 三义务全清偿').
cond(1) :- mon_obligations(xor).
chk(2, 'ν✱（and 表）：MON 三义务全清偿').
cond(2) :- mon_obligations(and).
chk(3, 'Ψ⁺：GRP 逆元像在 xor 表上成立（态射）').
cond(3) :- inv_obligation(xor).
chk(4, 'Ψ✱：GRP 逆元像在 and 表上失败（非态射）').
cond(4) :- \+ inv_obligation(and).
chk(5, '见证机：and 表上无逆元的元素恰是 0').
cond(5) :- findall(X, inv_witness(and, X), [0]).
chk(6, '运输：唯一幺元定理的像在 xor 表成立（幂元=0）').
cond(6) :- unique_id_image(xor).
chk(7, '运输：唯一幺元定理的像在 and 表成立（幂元=1）').
cond(7) :- unique_id_image(and).
chk(8, '定理图合成口味：xor 与 and 两目标共享同一源 MON').
cond(8) :- mon_obligations(xor), mon_obligations(and).

main :-
    ( between(1, 8, I), chk(I, What), \+ cond(I)
    -> format('FAIL ~d  ~w~n', [I, What]), halt(1)
    ;  true ), !,
    format('8 条全过~n'), halt.
