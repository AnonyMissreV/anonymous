-module(msg_controller).

-define(SERVER, msg_controller).

-compile(export_all).
-export([start_link/0, start_link/1, init/1, handle_cast/2, terminate/2]).

start_link() ->
    start_link([]).

start_link(Interests) ->
    gen_server:start_link({local, msg_controller}, ?MODULE, Interests, []).

init(Interests) ->
%  server_util:start(?SERVER, {msg_controller, route_messages, [dict:new(),dict:new()]}),
    msg_logger:start(),
    {ok, Interests}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(msg_controller, stop).

stop() ->
    server_util:stop(?SERVER),
    msg_logger:stop().

handle_cast(stop, _LoopData) ->
    {stop, normal, _LoopData};

handle_cast({notify,Event,{Id,Var}}, Interests) ->
    io:format("received msg ~p,~n ", [Event]),
    case dict:is_key(Event,Interests) of
	true ->
	    io:format(" event found ~w~n", [Event]),			     
	    notify_processes(dict:fetch(Event,Interests), Id, Event, Var);		
	false ->
	    io:format("no subscriber found for event ~p,~n", [Event])
    end,
    {noreply, Interests};

handle_cast({subscribe,ProcessName,[{Interest, Id}|T]}, Interests) ->
    io:format("received msg subscribe"),		
%   case dict:find(ProcessName, Processes) of
%	{ok, _ProcessesName} ->
	    {noreply, subscribe_processIntrest([{Interest, Id}|T], ProcessName, Interests)};		
%	error->
%	    io:format("no process id found for ~p~n", [ProcessName]),
%	    {noreply, Interests}	
%    end;

handle_cast({register, ProcessName}, Interests) ->
    io:format("received msg register_nick"),
    Messages = msg_logger:find_messages(ProcessName),
    lists:foreach(fun(Msg) -> gen_server:cast(ProcessName, Msg) end, Messages),
      {noreply, Interests};

%handle_cast({unregister, ProcessName}, Interests) ->
%      case dict:find(ProcessName, Processes) of
%	{ok, _ProcessName} ->
%	  gen_server:cast(ProcessesName, stop),
%	  {noreply, Interests};
%	error ->
%	  io:format("Error! Unknown client: ~p~n", [ProcessName]),
%	  {noreply, Interests}
%    end;

handle_cast({shutdown}, Interests) ->
      io:format("Shutting down~n"),
      gen_server:cast(msg_controller, stop),
      {noreply, Interests};

handle_cast({Oops}, Interests) ->
      io:format("Warning! Received: ~p~n", [Oops]),
      {noreply, Interests}.

% send_chat_message(Addressee, MessageBody) ->
%	?SERVER!{send_chat_msg, Addressee, MessageBody}.

%register_nick(ProcessName, ProcessesPid) ->
%	?SERVER!{register_nick, ProcessName, ProcessesPid}.

%unregister_nick(ProcessName) ->
%	?SERVER!{unregister_nick, ProcessName}.


subscribe_processIntrest([],_ProcessName, Interests) ->
	Interests;


subscribe_processIntrest([{Interest, Id}|T], ProcessName, Interests) ->
	NewDict = dict:append(Interest,{ProcessName, Id}, Interests),
	io:format(" dic updated"),
	subscribe_processIntrest(T, ProcessName, NewDict).
	
notify_processes([], _, _, _) ->	
	ok;

notify_processes([{Subscriber,TorrentId}|T], TorrentId, Event, Var) ->
        gen_server:cast(Subscriber, {notify, Event, {TorrentId, Var}}), %%REMEMBER TO REGISTER ALL PROCESSES
	io:format("event sent to ~p,~n", [Subscriber]),
	notify_processes(T, TorrentId, Event, Var);

notify_processes([{Subscriber,Id}|T], TorrentId, Event, Var) ->	
        case Id of
	    -1 -> 
		gen_server:cast(Subscriber, {notify, Event, {TorrentId, Var}}),
		io:format("event sent to ~p~n", [Subscriber]),
		notify_processes(T, TorrentId, Event, Var);
	    _Else ->
	        notify_processes(T, TorrentId, Event, Var)
        end.
