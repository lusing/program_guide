-module(e25_regex_demo).
-export([is_email_like/1, extract_numbers/1]).

is_email_like(Text) when is_list(Text) ->
    case re:run(Text, "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", [unicode]) of
        {match, _} -> true;
        nomatch -> false
    end.

extract_numbers(Text) when is_list(Text) ->
    case re:run(Text, "\\d+", [global, {capture, all, list}]) of
        {match, Matches} -> [lists:nth(1, M) || M <- Matches];
        nomatch -> []
    end.

