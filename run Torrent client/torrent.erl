%% Author: Johan and Massih

-module(torrent).
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
-behaviour(gen_server).
-include("defs.hrl").

init([Id, Torrent_info]) ->
    gen_server:cast(msg_controller, {subscribe, Id, [{torrent_status, Id}, 
						     {downloaded, Id},
						     {left, Id}]}),
    Dict = dict:new(),
    Dynamics = {Torrent_info#torrent.downloaded, Torrent_info#torrent.left, Torrent_info#torrent.max_peers},
    spawn(fun() -> spawn_trackers(Torrent_info#torrent.trackers, Dict, 1, Id) end),
    {ok, {Id, Dict, 0, Dynamics}}.

terminate(_Reason, {_Id, _Dict, _Entries, _Dynamics}) ->
    ok.

start_link([Id, Torrent_info]) ->
    gen_server:start_link({local, Id}, ?MODULE, [Id, Torrent_info], []).

handle_cast({trackerinfo, {NewDict, NewEntries}}, {Id, _Dict, _Entries, Dynamics}) ->
    {noreply, {Id, NewDict, NewEntries, Dynamics}}; 

handle_cast({notify, Tag, {Id, Value}}, {Id, Dict, Entries, {Downloaded, Left, Max_peers}}) ->
    case Tag of 
	downloaded     -> Dynamics = {Value, Left, Max_peers};
        left           -> Dynamics = {Downloaded, Value, Max_peers};
	max_peers      -> Dynamics = {Downloaded, Left, Value};
        torrent_status -> notify_trackers(Dict, Value, Entries),
			  Dynamics = {Downloaded, Left, Max_peers}
    end,
    {noreply, {Id, Dict, Entries, Dynamics}}.

handle_call(get_dynamics, _From, {Id, Dict, Entries, Dynamics}) ->
    {reply, Dynamics, {Id, Dict, Entries, Dynamics}}.

%% Starts each tracker trough the dynamic supervisor, sends started to them.
%% Gets the interval for said tracker, and updates the record with new interval,
%% sends the information to the blackboard, spawns the interval loop for said tracker
%% with the empty flag. Store the information in the dict.
%% Loop until all trackers are spawned.
%% 
%% H = tracker record
%% Dict = new dict which get filled with....
%% Entries = number of entries
%% Id = torrent id

spawn_trackers([], Dict Entries, Id) ->
    gen_server:cast(Id, {trackerinfo, {Dict, Entries}});
spawn_trackers([H|T], Dict, Entries, Id) -> 
    {_, Pid} = dynamic_supervisor:start_tracker(H),
    Result = gen_server:call(Pid, info_to_send(Id,"started")),
    [Seeders,Leechers,Interval,Peers] = Result,
    NewH = H#tracker_info{interval=Interval},
    gen_server:cast(msg_controller, {notify, seeders, {Id, Seeders}}),
    gen_server:cast(msg_controller, {notify, leechers, {Id, Leechers}}),
    gen_server:cast(msg_controller, {notify, peers, {Id, Peers}}),
    LoopId = spawn_link(fun() -> interval_loop(Id, NewH, Pid, "") end),
    NewDict = dict:store(Entries, {Pid, NewH, LoopId}, Dict),
    spawn_trackers(T, NewDict, Entries+1, Id).

%% Receive pause, completed and resume for changing the state of the interval.
%% Get the updated info from the torrent process, so the updated information
%% is sent to the trackers. Done like this to keep the interval intact.

interval_loop(TorrentId, Tracker, Pid, Event) ->
    receive
	pause ->
	    {Downloaded, Left} = gen_server:call(TorrentId, get_dynamics),
            interval_loop(TorrentId, Tracker#tracker_info{downloaded=Downloaded, left=Left}, Pid, "pause");
	completed -> 
	     {Downloaded, Left} = gen_server:call(TorrentId, get_dynamics),
            interval_loop(TorrentId, Tracker#tracker_info{downloaded=Downloaded, left=Left}, Pid, "completed");
	resume ->
	    {Downloaded, Left} = gen_server:call(TorrentId, get_dynamics),
	    interval_loop(TorrentId, Tracker#tracker_info{downloaded=Downloaded, left=Left}, Pid, "")
    after Tracker#tracker_info.interval ->
	    gen_server:call(Pid, info_to_send(TorrentId, Event))
    end,
    interval_loop(TorrentId, Tracker, Pid, Event).

%% Assembles the information to send to said tracker.

info_to_send(TorrentId, Event) ->
    {Downloaded, Left, Max_peers} = gen_server:call(TorrentId, get_dynamics),
    {tracker_request_info, {Downloaded, Left, Event, Max_peers}}.

%% Sends from torrent id to interval loop of each tracker. 

notify_trackers(_Dict, _Event, 0) -> ok;
notify_trackers(Dict, Event, Entries) ->
    {_, _, LoopId} = dict:find(Dict, Entries), 
    LoopId ! Event,
    notify_trackers(Dict, Event, Entries-1).
		 
    
