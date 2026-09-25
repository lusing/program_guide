%% ============================================================
%% lock_statem —— gen_statem 门禁锁（教科书经典例）
%%
%%   callback_mode() -> state_functions：每个状态一个同名回调函数，
%%   事件按 {call,From} / cast / info / timeout 四类分派。
%%   数据是一张 map：#{code := 密码, entered := 已按的数字}。
%%
%%   两个 state_timeout：
%%     locked：部分输入 1000ms 没下文 → 清零（重新等完整密码）
%%     open  ：开门 500ms → 自动落锁
%% ============================================================
-module(lock_statem).

-behaviour(gen_statem).

-export([start_link/1, button/1, status/0, stop/0]).
-export([callback_mode/0, init/1, locked/3, open/3, terminate/3,
         code_change/4]).

%% ---- 客户端 API ----
start_link(Code) when is_list(Code) ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, Code, []).

button(Digit) -> gen_statem:call(?MODULE, {button, Digit}).

status() -> gen_statem:call(?MODULE, status).

stop() -> gen_statem:stop(?MODULE).

%% ---- gen_statem 回调 ----
callback_mode() -> state_functions.

init(Code) -> {ok, locked, #{code => Code, entered => []}}.

%% ---- 状态 locked：按对了开门，按错了清零 ----
locked({call, From}, {button, D}, #{code := Code, entered := Entered} = Data) ->
    Now = Entered ++ [D],
    case Now =:= Code of
        true ->
            {next_state, open, Data#{entered => []},
             [{reply, From, unlock}, {state_timeout, 500, auto_lock}]};
        false ->
            Prefix = lists:prefix(Now, Code),
            NewEntered = case Prefix of true -> Now; false -> [] end,
            {keep_state, Data#{entered => NewEntered},
             [{reply, From, case Prefix of true -> partial; false -> wrong end},
              {state_timeout, 1000, clear}]}
    end;
locked({call, From}, status, Data) ->
    {keep_state, Data, [{reply, From, {locked, maps:get(entered, Data)}}]};
locked(state_timeout, clear, Data) ->
    %% 部分输入超时：清零继续等
    {keep_state, Data#{entered => []}}.

%% ---- 状态 open：500ms 自动落锁 ----
open(state_timeout, auto_lock, Data) ->
    {next_state, locked, Data};
open({call, From}, {button, _D}, Data) ->
    {keep_state, Data, [{reply, From, still_open}]};
open({call, From}, status, Data) ->
    {keep_state, Data, [{reply, From, {open, maps:get(entered, Data)}}]}.

terminate(_Reason, _State, _Data) -> ok.

code_change(_OldVsn, State, Data, _Extra) -> {ok, State, Data}.
