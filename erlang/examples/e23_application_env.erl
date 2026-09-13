-module(e23_application_env).
-export([set_env/3, get_env/3]).

set_env(App, Key, Value) ->
    application:set_env(App, Key, Value).

get_env(App, Key, Default) ->
    case application:get_env(App, Key) of
        {ok, Value} -> Value;
        undefined -> Default
    end.

