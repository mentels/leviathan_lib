-module(leviathan_docker_events).

-compile(export_all).

-include("leviathan_logger.hrl").



event_listener() ->
    DockerEventsBin = "/usr/bin/docker events --until=\"\"",
    spawn(fun()->Port = open_port({spawn, DockerEventsBin}, []),
    		      loop(Port) end).

loop(Port) ->
    receive
	{Port, {data, Data}} ->
	    io:format("events received: ~p~n",[Data]),
	    Parsed = parse_event(Data),
	    io:format("parsed: ~p~n",[Parsed]),
	    Mapped = event2map(Parsed),
	    io:format("mapped: ~p~n",[Mapped]),
	    handle_event(Mapped),
	    loop(Port);
	{'EXIT', Port, Reason} ->
	    exit({port_terminated,Reason})
    end.

parse_event(EventString)->
	Stripped = string:strip(EventString,right,$\n),
	Tokens = string:tokens(Stripped," "),
	lists:map(fun(Token)->T1=string:strip(Token,right,$)),
	                      T2=string:strip(T1,right,$:),
	                      string:strip(T2,left,$() end,
			      Tokens).

event2map(ParsedEvent)->
	[Timestamp,Cid,"from",Tag,Event]= ParsedEvent,
	#{ event => list_to_atom(Event), cid => Cid, tag => Tag, time => Timestamp }.


handle_event(#{ event := create, cid := Cid})->
    Cins = leviathan_utils:container_get_cins(Cid),
    io:format("~p cins =~p~n",[Cid,Cins]);
handle_event(#{ cid := Cid}) ->
    io:format("~p ignored~n",[Cid]).

				  		 
	
		       
get_events(Time)->
    Cmd = "echo \"GET /events?since=" ++ integer_to_list(Time) ++ " HTTP/1.1\r\n\" | nc -U /var/run/docker.sock",
    Results = os:cmd(Cmd),
    Tokens = string:tokens(Results,"\r\n"),
    lists:foldl(fun(Str,Acc)->case string:substr(Str,1,1) of 
				  "{" -> Acc ++ Str;
				  _ -> Acc 
			      end end,[],Tokens).




%% helpers

now_secs({MegaSecs,Secs,_}) ->
    MegaSecs*1000000 + Secs.


	