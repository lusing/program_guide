-module(e04_recursion_guards).
-export([factorial/1, fib/1]).

factorial(N) when is_integer(N), N >= 0 ->
    factorial_loop(N, 1).

factorial_loop(0, Acc) ->
    Acc;
factorial_loop(N, Acc) ->
    factorial_loop(N - 1, N * Acc).

fib(N) when is_integer(N), N >= 0 ->
    fib_loop(N, 0, 1).

fib_loop(0, A, _) ->
    A;
fib_loop(N, A, B) ->
    fib_loop(N - 1, B, A + B).

