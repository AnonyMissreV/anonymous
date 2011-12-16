%% @author Max Mirkia <max.mirkia@gmail.com>
%% @doc Controlls all messages in the system 
%% <p>This module acts as the controller . It is the intended
%% entry-point for a human  being to query etorrent for what it is
%% doing right now. A number of commands exist, which can be asked for
%% with the help/0 call. From there the rest of the commands can be
%% perused.</p>
%% @end
-module(msg_controller).

-define(SERVER, msg_controller).

-compile(export_all).
-export([start_link/0, start_link/1, init/1, handle_cast/2, terminate/2]).

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------

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
	    case (Id == -1) of
		true -> 
		    notify_processes(dict:fetch(Event,Interests), Id, Event, Var),	    
		    io:format(" event sent to ~w for torrent id ~w~n", [Event,Id]);
		false ->
		    case whereis(Id) of
			undefined ->
			    io:format(" given torrent id, ~w~n is undefined ", [Id]);
			_Else ->
			    notify_processes(dict:fetch(Event,Interests), Id, Event, Var),	    
			    io:format(" event sent to ~w for torrent id ~w~n", [Event,Id])
		    end
            end;
	false ->
	    io:format("no subscriber found for event ~p~n", [Event])
    end,
    {noreply, Interests};

handle_cast({subscribe,ProcessName,[{Interest, Id}|T]}, Interests) ->
    io:format("~p subscribed~n", [ProcessName]),		
%   case dict:find(ProcessName, Processes) of
%	{ok, _ProcessesName} ->
	    {noreply, subscribe_processIntrest([{Interest, Id}|T], ProcessName, Interests)};		
%	error->
%	    io:format("no process id found for ~p~n", [ProcessName]),
%	    {noreply, Interests}	
%    end;

handle_cast({register, ProcessName}, Interests) ->
    io:format("received msg register_nick~n"),
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

handle_cast({notify,exit,exit}, Interests) ->
    io:format("Shutting down~n"),
    gen_server:cast(static_supervisor, stop),
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
	io:format("dict updated: ~p, ~p~n", [ProcessName, Interest]),
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
