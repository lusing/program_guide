-module(e11_binary_bitstring).
-export([split_header/1, to_hex/1]).

split_header(<<Type:8, Len:16, Payload/binary>>) when byte_size(Payload) =:= Len ->
    {ok, Type, Payload};
split_header(_) ->
    {error, invalid_packet}.

to_hex(Bin) when is_binary(Bin) ->
    lists:flatten([io_lib:format("~2.16.0B", [X]) || <<X:8>> <= Bin]).

