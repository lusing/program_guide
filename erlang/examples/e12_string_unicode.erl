-module(e12_string_unicode).
-export([normalize_space/1, greet/1]).

normalize_space(Text) when is_list(Text) ->
    string:trim(re:replace(Text, "\\s+", " ", [global, {return, list}])).

greet(Name) ->
    NameBin = unicode:characters_to_binary(Name),
    <<"Hello, ", NameBin/binary>>.

