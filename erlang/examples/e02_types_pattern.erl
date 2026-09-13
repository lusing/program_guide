-module(e02_types_pattern).
-export([describe/1, demo/0]).

describe({user, Name, Age}) when is_list(Name), is_integer(Age) ->
    {ok, io_lib:format("user=~s age=~p", [Name, Age])};
describe(#{name := Name, age := Age}) when is_binary(Name), is_integer(Age) ->
    {ok, io_lib:format("user=~ts age=~p", [Name, Age])};
describe(_) ->
    {error, invalid_data}.

demo() ->
    A = describe({user, "alice", 21}),
    B = describe(#{name => <<"bob">>, age => 32}),
    {A, B}.

