-module(e26_term_binary).
-export([encode/1, decode/1]).

encode(Term) ->
    term_to_binary(Term).

decode(Bin) when is_binary(Bin) ->
    binary_to_term(Bin).

