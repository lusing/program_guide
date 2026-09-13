-module(e24_file_io).
-export([write_lines/2, read_file/1]).

write_lines(Path, Lines) when is_list(Path), is_list(Lines) ->
    Bin = iolist_to_binary([[Line, "\n"] || Line <- Lines]),
    file:write_file(Path, Bin).

read_file(Path) when is_list(Path) ->
    file:read_file(Path).

