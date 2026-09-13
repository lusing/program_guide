-module(e09_counter_server).
-behaviour(gen_server).

-export([start_link/0, stop/0, get/0, inc/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:call(?SERVER, stop).

get() ->
    gen_server:call(?SERVER, get).

inc() ->
    gen_server:cast(?SERVER, inc).

init([]) ->
    {ok, 0}.

handle_call(get, _From, Count) ->
    {reply, Count, Count};
handle_call(stop, _From, Count) ->
    {stop, normal, ok, Count};
handle_call(_Req, _From, Count) ->
    {reply, {error, unknown_call}, Count}.

handle_cast(inc, Count) ->
    {noreply, Count + 1};
handle_cast(_Msg, Count) ->
    {noreply, Count}.

handle_info(_Info, Count) ->
    {noreply, Count}.

terminate(_Reason, _Count) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

