-module(talkToJava).
-export([start/0]).
-include("defs.hrl").

start() ->
    ComputerName = net_adm:localhost(),
    NodeName = "javaNode@" ++ ComputerName,
    NodeAtom = list_to_atom(NodeName),
    timer:sleep(2000),
    {mailbox, NodeAtom} ! {self(), "startconnection"},
%%  gen_server:cast(msg_controller, {subscribe, gui, [{exit,-1}, {torrent_info,-1}, {torrent_status,-1}, 
%%                                                      {tracker_info,-1}, {seeders,-1}, {leechers,-1}, 
%%                                                      {uploaded,-1}, {downloaded,-1}, {left,-1}, {torrent_size,-1}, {pieces,-1},
%%                                                      {download_speed,-1}, {upload_speed,-1}]}),
    rec(NodeAtom).


rec(NodeAtom) ->

    receive

        %%receives from java
	{_From, connok} ->
	    io:format("Message received: ~p~n", [connectionok]);   
	{_Fron, exit} ->
	    io:format("Message received: ~p~n", [exited]);
	%%gen_server:cast(msg_controller, {notify, exit, exit})
	{_From, open,FileDir} ->
	    io:format("Message received: ~p~n", [FileDir]);
	%%gen_server:cast(msg_controller, {notify, torrent_status, {torrent1, opened}}),
	%%gen_server:cast(msg_controller, {notify, torrent_filepath,{torrent1, FileDir}}),
	{_From, start} ->
	    io:format("Message received: ~p~n", [started]);
	%%gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, started}}),
	{_From, stop} ->
	    io:format("Message received: ~p~n", [stopped]);
	%%gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, stopped}}),
	{_From, pause} ->
	    io:format("Message received: ~p~n", [paused]);
	%%gen_server:cast(msg_controller, {notify, torrent_status, {torrent1, paused}}),
	{_From, delete} ->
	    io:format("Message received: ~p~n", [deleted]);
	%%gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, deleted}}),
	{_From, dir,DirList} ->
	    io:format("Counter is at value: ~p~n", [DirList]);
	%%gen_server:cast(msg_controller, {notify, default_path,{torrent1, DirList}});

       	%%receives from other erlang modules sends back to notice java

	{notify, torrent_info, {TorrentId, Value}} ->
	    Seeders = integer_to_list(Value#torrent.seeders),
	    Leechers = integer_to_list(Value#torrent.leechers),
	    Size = integer_to_list(Value#torrent.size),
	    Downloaded = integer_to_list(Value#torrent.downloaded),
	    Files = Value#torrent.files,
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 5, Seeders},
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 6, Leechers},
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 1, Size},
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 7, Downloaded},
	    sendFiled(Files, NodeAtom, TorrentId);

	{notify, tracker_info, {TorrentId, Value}} ->
	    Uploaded = integer_to_list(Value#tracker_info.uploaded),
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 8, Uploaded};
	    
	{notify, file_path, {TorrentId, Value}} ->
	    Files = integer_to_list(Value#file_path.files),
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 13, Files};

	{notify, torrent_status, {TorrentId, Value}} ->
	    case Value of
		finished -> {mailbox2, NodeAtom} ! {self(), TorrentId, 14, Value};
	        _ -> ok
	    end;

	{notify, torrent_size, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 1, Value};
	{notify, download_speed, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 3, Value};
	{notify, upload_speed, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 4, Value};
	{notify, seeders, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 5, Value};
	{notify, leechers, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 6, Value};
	{notify, downloaded, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 7, Value};
	{notify, uploaded, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 8, Value};
	{notify, finished, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 9, "Torrent finished downloading"}

    end,
    rec(NodeAtom).

sendFiles([],_,_) ->
    ok;
sendFiles([H|T], NodeAtom, TorrentId) ->
    {mailbox2, NodeAtom} ! {self(), TorrentId, 10, H},
    sendFiles(T, NodeAtom, TorrentId).

