%% ============================================================
%% evt_counter —— gen_event 处理器：数事件
%%
%%   handler 的状态就是回调的第二个参数（这里是计数），
%%   swap_handler 时 terminate 的返回值会传给新实例的 init。
%% ============================================================
-module(evt_counter).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2,
         terminate/2, code_change/3]).

%% swap 接力：新 init 收到 {swap 的 Args2, 老 terminate 的返回值}
init({_Args2, {ok, Carried}}) when is_integer(Carried) -> {ok, Carried};
init(_) -> {ok, 0}.

handle_event(_Event, Count) -> {ok, Count + 1}.

handle_call(get_count, Count) -> {ok, Count, Count}.

handle_info(_Info, Count) -> {ok, Count}.

%% swap/delete 都走这里；返回 {ok, 值} 时——swap 的新实例 init 拿到它，
%% delete_handler 的返回值就是它（状态外带的唯一通道）
terminate(_Args, Count) -> {ok, Count}.

code_change(_OldVsn, Count, _Extra) -> {ok, Count}.
