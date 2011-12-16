%%Author : Massih
%%Creation Date : 8-Nov-2011 
-module(peers_interactor).
-export([init/1,start_link/1,terminate/2,handle_cast/2,handle_call/3,handle_info/2]).
-export([test/0,handshake/1,test2/1,test1/1]).
-behaviour(gen_server).
-include("defs.hrl").

init([Torrent, Ip, Port])->
    %%gen_server:cast(Torrent#torrent.id, {peer_spawned, list_to_atom(Ip)}),
    %%gen_server:cast(msg_controller, {subscribe, list_to_atom(Ip), [{available_pieces, Torrent#torrent.id}, {get_blocks, Torrent#torrent.id}]}),
    io:format("connecting to ip: ~p~n in port : ~p~n",[Ip,Port]),
    %%----------------------------------HARD CODED--------------------------PEER_ID
    Msg = list_to_binary([<<19>>,<<"BitTorrent protocol">>,
			  <<0,0,0,0,0,0,0,0>>,
			  atom_to_list(Torrent#torrent.id),
			  list_to_binary("-AZ4004-znmphhbrij37")]),
    io:format("HANDSHAKWE MSG IS ~p~n",[Msg]),
    Connection =  gen_tcp:connect(Ip,Port,[list,{active,true},{packet,0}]),
    %%[Socket,PID] = case Connection of
    case Connection of    
	{ok,Socket}->
	    put(am_interested,0),
	    put(am_choking,1),
	    put(peer_interested,0),
	    put(peer_choking,1),
	    put(peer_have_list,dict:new()),
	    put(requested_piece,{-1,-1}),
	    put(downloaded_piece,[]),
	    put(torrent,Torrent),
	    PID = peer_message_handler:start(self()),
	    gen_tcp:send(Socket,Msg),
	    {ok,[Torrent,Socket,PID]};
	    %%[S,Pid];
	%%loop(Socket,-1,PID);
	{error,Error} -> %% should kill this process before going to loop %% HOW ?????
	    io:format("Error in handshake !!! ~p~n",[Error]),
	    gen_server:cast(msg_controller,{notify,error,{peer_handshake_error,Error}}),
	    {stop,ignore};
	_ ->{stop,ignore}
    end.    
    %%handshake([Torrent, Ip, Port]),
    %%{ok,[Torrent,Socket,PID ]}.

terminate(_Reason,Data)->
    {stop,Data}.

start_link([Torrent, Ip, Port])->
    gen_server:start_link({local,list_to_atom(Ip)},?MODULE,[Torrent, Ip, Port],[]).

handle_call(Request,_From,Data) ->
    {reply,null,Data}.

handle_cast(Request,Data)->
    {noreply,Data}.

handle_info({tcp,_,Msg},[_Torrent,_Socket,PID ]) ->
	    %%io:format("message is ~p~n",[Msg]),
	    PID ! Msg ,
    {noreply,[_Torrent,_Socket,PID ]};

handle_info({tcp_closed,_Msg},_Data) ->
    io:format("CLOSED !!!!!!!! ~w~n",[_Msg]),
    gen_server:cast(logger,{peer_connection_closed}),
    {noreply,_Data};

handle_info(M,[Torrent,Socket,PID])->
    case M of
	{handshake_response,Handshake_response}->
	    io:format("handshake response is : ~w~n",[Handshake_response]);
	    %%loop(Socket,Remain,PID);
	{bitfield,Bitfield} ->
	    io:format("bitfield recieved and saved !!! ~n");
	    %%put(bitfield,Bitfield),
	    %%loop(Socket,Remain,PID);	    
	send_interest ->
	    send_interest(Socket);
	    %%loop(Socket,Remain,PID);
	get_unchoke ->
	    io:format("get unchoke !!!~n"),
	    put(am_choking,0),
	    send_interest(Socket),
	    send_request(get(peer_have_list),Socket),
	    io:format("pieces are ~w~n",[dict:to_list(get(peer_have_list))]);
	    %%loop(Socket,Remain,PID);
	get_choke ->
	    io:format("get choke !!!~n"),
	    put(am_choking,1);
	    %%loop(Socket,Remain,PID);
	get_keep_alive ->
	    io:format("get keep alive !!! ~n"),
	    gen_tcp:send(Socket,<<0,0,0,0>>);
	    %%loop(Socket,Remain,PID);
	{peer_have_piece,Piece_index} ->
	    Dict = get(peer_have_list),
	    %%Dict2 = dict:append(Piece_index,create_blocks_list(dict:new(),262144) ,Dict),
	    Dict2 = dict:append(Piece_index,[],Dict),
	    put(peer_have_list,Dict2);
	    %%loop(Socket,Remain,PID);
	{recieved_piece,Index,Begin,Block} ->
	    io:format("*************Piece recieved index is :~p     begin is : ~p~n block length is :~p~n",[Index,Begin,byte_size(Block)]),
	    %% save blocks to send them when a piece downloaded completely
%%%%%New_Blocks
	    New_blocks = get(downloaded_piece) ++ [[Index,Begin,Block]],
	    put(downloaded_piece,New_blocks),
	    send_request(get(peer_have_list),Socket);
	    %%Block_list = dict:fetch(Index,get(peer_have_list)),
	    %%gen_server:cast(msg_controller,{notify,set_block,{Tid,[Pid,Index,Begin,Block]}})
	    
	    %%TEST
	    %% file_handler ! {set_block,Index,Begin,list_to_binary(Block)},
	    %%gen_server:cast(intermediate,{notify,set_block,[Index,Begin,list_to_binary(Block)] }),
	    %%
	    %%loop(Socket,Remain,PID);
	_Other ->
	    io:format("receive unknown message from a peer !!! ~n~w~n",[length(_Other)])
	    %%loop(Socket,Remain,PID)
    end,
    {noreply,[Torrent,Socket,PID]}.
	
    

handshake([Torrent, Ip, Port])->
    io:format("connecting to ip: ~p~n in port : ~p~n",[Ip,Port]),
    %%----------------------------------HARD CODED--------------------------PEER_ID
    Msg = list_to_binary([<<19>>,<<"BitTorrent protocol">>,
			  <<0,0,0,0,0,0,0,0>>,
			  atom_to_list(Torrent#torrent.id),
			  list_to_binary("-AZ4004-znmphhbrij37")]),
    Connection =  gen_tcp:connect(Ip,Port,[list,{active,true},{packet,0}]),
    io:format("HANDSHAKWE MSG IS ~p~n",[Msg]),
    case Connection of
	{ok,Socket}->
	    put(am_interested,0),
	    put(am_choking,1),
	    put(peer_interested,0),
	    put(peer_choking,1),
	    put(peer_have_list,dict:new()),
	    put(requested_piece,{-1,-1}),
	    put(downloaded_piece,[]),
	    put(torrent,Torrent),
	    PID = peer_message_handler:start(self()),
	    gen_tcp:send(Socket,Msg);
	    %%loop(Socket,-1,PID);
	{error,Error} ->
	    io:format("Error in handshake !!! ~p~n",[Error]),
	    gen_server:cast(msg_controller,{notify,error,{peer_handshake_error,Error}})
    end.

    
test()->
    URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A&peer_id=-AZ4004-znmphhbrij37&port=6881&downloaded=10&left=1588&event=started&numwant=12&compact=1",
    inets:start(),
    {ok,Result} = httpc:request(URL),
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=interpreter:get_tracker_response_info(Decoded_Body),
    [IP,PORT] = hd(Peers),
    R = interpreter:create_record("fedora.torrent"),
    spawn(peers_interactor,handshake,[[R,IP,PORT]]).

test2(File)->
    R = interpreter:create_record(File),
    TR = hd(R#torrent.trackers),
    T = TR#tracker_info{event="started"},
    URL = tracker_interactor:make_url(T),
    %%URL = "http://tracker.opensuse.org:6969/announce?info_hash=%C0%EE%71%85%11%81%68%26%EC%97%66%85%07%91%F8%65%C6%53%5F%E8&peer_id=-AZ4004-znmphhbrij37&port=6881&downloaded=0&left=4429185024&event=started&numwant=50&uploaded=0&compact=1",
    inets:start(),
    {ok,Result} = httpc:request(URL),
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=interpreter:get_tracker_response_info(Decoded_Body),
    io:format("seed ~p~n , leech ~p~n peers: ~p~n",[Seeds,Leechers,Peers]),
    [IP,PORT] = lists:nth(2,Peers),
    start_link([R,IP,PORT]).
    %%spawn(peers_interactor,handshake,[[R,IP,PORT]]).
    

test1(File)->
    R = interpreter:create_record(File),
    TR = R#torrent.trackers,
    trlist(TR,R).
 
trlist([],_)->
    ok;
trlist([H|T],Tr) ->  
    H2= H#tracker_info{event="started"},
    URL = tracker_interactor:make_url(H2),
    inets:start(),
    {ok,Result} = httpc:request(URL),
     {Status_line, _Headers, Body} = Result,
    case Status_line of
	{"HTTP/1.0",200,"OK"} ->    
	    io:format("result is : ~p~n",[Result]);
	_-> io:format("Tracker is not Available !!!!")
    end,
    trlist(T,Tr).


loop(Socket,Remain,PID)->
    receive 
	{tcp,_,Msg} ->
	    io:format("message is ~p~n",[Msg]),
	    PID ! Msg ,
	    loop(Socket,Remain,PID);
	    %%messages_loop(Socket,Msg,Remain);
	{tcp_closed,_R} ->
	    io:format("CLOSED !!!!!!!! ~w~n",[_R]),
	    gen_server:cast(logger,{peer_connection_closed}),
	    loop(Socket,Remain,PID);
	{handshake_response,Handshake_response}->
	    io:format("handshake response is : ~w~n",[Handshake_response]),
	    loop(Socket,Remain,PID);
	{bitfield,Bitfield} ->
	    io:format("bitfield recieved and saved !!! ~n"),
	    %%put(bitfield,Bitfield),
	    loop(Socket,Remain,PID);	    
	send_interest ->
	    send_interest(Socket),
	    loop(Socket,Remain,PID);
	get_unchoke ->
	    io:format("get unchoke !!!~n"),
	    put(am_choking,0),
	    send_interest(Socket),
	    send_request(get(peer_have_list),Socket),
	    io:format("pieces are ~w~n",[dict:to_list(get(peer_have_list))]),
	    loop(Socket,Remain,PID);
	get_choke ->
	    io:format("get choke !!!~n"),
	    put(am_choking,1),
	    loop(Socket,Remain,PID);
	get_keep_alive ->
	    io:format("get keep alive !!! ~n"),
	    gen_tcp:send(Socket,<<0,0,0,0>>),
	    loop(Socket,Remain,PID);
	{peer_have_piece,Piece_index} ->
	    Dict = get(peer_have_list),
	    %%Dict2 = dict:append(Piece_index,create_blocks_list(dict:new(),262144) ,Dict),
	    Dict2 = dict:append(Piece_index,[],Dict),
	    put(peer_have_list,Dict2),
	    loop(Socket,Remain,PID);
	{recieved_piece,Index,Begin,Block} ->
	    io:format("*************Piece recieved index is :~p     begin is : ~p~n block length is :~p~n",[Index,Begin,byte_size(Block)]),
	    %% save blocks to send them when a piece downloaded completely
	    %%%%%New_Blocks
	    New_blocks = get(downloaded_piece) ++ [[Index,Begin,Block]],
	    put(downloaded_piece,New_blocks),
	    send_request(get(peer_have_list),Socket),
	    %%Block_list = dict:fetch(Index,get(peer_have_list)),
	    %%gen_server:cast(msg_controller,{notify,set_block,{Tid,[Pid,Index,Begin,Block]}})
	    
	    %%TEST
	    %% file_handler ! {set_block,Index,Begin,list_to_binary(Block)},
	    %%gen_server:cast(intermediate,{notify,set_block,[Index,Begin,list_to_binary(Block)] }),
	    %%
	    loop(Socket,Remain,PID);
	_Other ->
	    io:format("receive unknown message from a peer !!! ~n~w~n",[length(_Other)]),
	    loop(Socket,Remain,PID)
    after 50000 ->
	    PID ! stop,
	    erase(torrent),
	    io:format("time out  !!!~n and all dic info is ~w~n",[erase()]),
	    gen_tcp:close(Socket)
    end.

create_blocks_list(Dict,0) ->
    dict:store(0,0,Dict);
create_blocks_list(Dict,Num) ->
    create_blocks_list(dict:store(Num-32768,0,Dict),Num-32768).



send_interest(Socket)->
    case get(am_interested) of
	0 ->
	    io:format("sending interest !!!~n"),
	    put(am_interested,1),
	    gen_tcp:send(Socket,<<0,0,0,1,2>>);
	1 ->
	    io:format("already interested !!! ~n")
    end.

%%send_request([],_) -> 
%%    io:format("nothing to send request~n");
send_request(Dict,Socket)->
    All_pieces = dict:fetch_keys(Dict),
    if 
	length(All_pieces) > 0 ->
	    io:format("in the request function ~n"),
	    Torrent = get(torrent),
	    Last_piece = (Torrent#torrent.number_of_pieces - 1),
	    Piece_length = Torrent#torrent.piece_length,
	    Last_piece_length = Torrent#torrent.file_length - ((Last_piece) * Piece_length ),
	    Block_length = 16384,
	    io:format("LP is ~p~n P_len is: ~p~n lplen is : ~p~n and allfile is : ~p~n",[Last_piece,Piece_length,Last_piece_length,Torrent#torrent.file_length]),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	    {I,B} = case get(requested_piece) of
			{-1,-1} ->
			    In  = hd(All_pieces),
			    {In,0};
			_R ->
			    _R
		    end,
	    Length = case I of
			 Last_piece ->
			     check_last(B,Block_length,Last_piece_length,I,Dict);
			 _ ->
			     check_last(B,Block_length,Piece_length,I,Dict)
		     end,
	    io:format("Index is :~p~n",[I]),
	    %%Request = <<0,0,0,13,6,I:32,B:32,Length:32>>,
	    Request = <<0,0,0,13,6,I:32,B:32,Length:32>>,
	    io:format("Request  is : ~p~n",[Request]),
	    %%io:format("I DONT SEND REQUEST,OK?????");
	    gen_tcp:send(Socket,Request);
	true ->
	    io:format("Unchoke but Havent recieve any piece index !!!!")
    end.

check_last(Begin,Length,Size,Index,Dict)->
    if 
	Size =< Begin+Length  ->
	    New_length = Size - Begin,
	    put(requested_piece,{-1,-1}),
	    New_dict = dict:erase(Index,Dict),
	    io:format("send all blocks of a piece together : ~p~n",[length(get(downloaded_piece))]),
	    T = get(torrent),
	    io:format("sending piece from peers"),
	    gen_server:cast(msg_controller,{notify,set_blocks,{T#torrent.id,get(downloaded_piece)} }),
	    put(downloaded_piece,[]),
	    put(peer_have_list,New_dict);
	Size > Begin+Length ->
	    New_length = Length,
	    put(requested_piece,{Index,Length})
    end,
    New_length.

    %%Index = <<I:32/binary>>,
    %%B = <<0:32>>,
    %%BS = <<32768:32>>,
    %%send_request(T,Socket).


	    %% case get(requested_piece) of
	    %% 	{-1,-1} ->
	    %% 	    I = hd(All_pieces),
	    %% 	    %%DONT FORGET TO CHECK FOR LAST PIECE*********************************
	    %% 	    %% HERE
	    %% 	    Block = 0,
	    %% 	    Length = case I of
	    %% 			  Last_piece ->
	    %% 			     check_last(Block,Piece_length,Last_piece_length,I);
	    %% 			 _ ->
	    %% 			     put(requested_piece,{I,Block}),
	    %% 			     Block + Piece_length
	    %% 		     end,
	    %% 	    Request = <<0,0,0,13,6,I:32/integer-big,Block:32/integer-big,Length:32/integer-big>>,
	    %% 	    io:format("sending request for piece index : ~w~n",[Request]),
	    %% 	    %%New_dict = dict:store(I,[0],Dict),
	    %% 	    %%put(peer_have_list,New_dict),
	    %% 	    gen_tcp:send(Socket,Request);
	    %% 	{I,B} ->
	    %% 	    case I of
	    %% 		Last_piece ->			    
	    %% 	    %%B = lists:last(dict:fetch(I,Dict)),
	    %% 	    %%----------------------------HARD CODED-----------------------(Block size,Piece size)
	    %% 	    Next_block = B + Piece_length,
	    %% 	    Request = <<0,0,0,13,6,I:32/integer-big,Next_block:32/integer-big,32768:32/integer-big>>,
	    %% 	    gen_tcp:send(Socket,Request),
	    %% 	    if 
	    %% 		Next_block == Piece_length ->  %%262144 is piece_length
	    %% 		    put(requested_piece,{-1,-1}),
	    %% 		    New_dict = dict:erase(I,Dict),
	    %% 		    io:format("send all blocks of a piece together : ~p~n",[length(get(downloaded_piece))]),
	    %% 		    gen_server:cast(intermediate,{notify,set_block,{1,get(downloaded_piece)} }),
	    %% 		    put(downloaded_piece,[]),
	    %% 		    put(peer_have_list,New_dict);
	    %% 		true ->
	    %% 		    put(requested_piece,{I,Next_block}) 
	    %% 		    %%New_dict = dict:store(I,B++[Next_block],Dict),
	    %% 		    %%put(peer_have_list,New_dict)
	    %% 	    end
	    %% end;
