-module(e30_logger_demo).
-export([event/2]).

event(Level, Msg) when is_atom(Level), is_list(Msg) ->
    Meta = #{module => ?MODULE, ts_ms => erlang:system_time(millisecond)},
    #{level => Level, message => Msg, meta => Meta}.

