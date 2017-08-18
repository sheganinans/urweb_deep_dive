val max_counters = 500
val max_dels_per_sec = 5
val max_acts_per_sec = 5000
		       
type counterT = [Id = int, Count = int, Show = bool]

table counters : counterT PRIMARY KEY Id,
      CONSTRAINT KeyRangeLower CHECK Id > 0,
      CONSTRAINT KeyRangeUpper CHECK Id <= {[max_counters]}

table prevCounters : counterT PRIMARY KEY Id,
      CONSTRAINT Keys FOREIGN KEY Id REFERENCES counters (Id)
		 
type counter = $counterT

table limits : { Mods : int, Clears : int }

table id_pool : { Id : int }
      CONSTRAINT RefCounter FOREIGN KEY Id REFERENCES counters (Id),
      CONSTRAINT MaxId CHECK Id <= {[max_counters]}
	       
structure In = struct
    datatype mod = Incr | Decr

    datatype protocol
      = New
      | Mod   of int * mod
      | Clear of int end
		 
structure Out = struct
    datatype mod
      = Set   of int * int
      | Clear of int
		 
    datatype protocol
      = Init  of list counter
      | Mod   of list mod end
	    
table users : { Client : client, Chan : channel Out.protocol } PRIMARY KEY Client
	      
fun mapM_ [m] (_ : monad m) [a] [b] (f : a -> m b) (x : list a) : m {} = _ <- List.mapM f x; return ()

fun oneTo (i : int) : list int =
    let go 1 where fun go (x : int) = if x = i then [] else x :: go (x + 1) end

 task initialize =
  fn () =>
     dml (DELETE FROM limits WHERE TRUE);
     dml (INSERT INTO limits (Mods, Clears) VALUES (0,0));

     dml (DELETE FROM id_pool WHERE TRUE);
  
     dml (DELETE FROM prevCounters WHERE TRUE);
     dml (DELETE FROM     counters WHERE TRUE);
     mapM_ (fn i => dml (INSERT INTO     counters (Id,Count,Show) VALUES ({[i]}, 0, TRUE))) (oneTo max_counters);
     mapM_ (fn i => dml (INSERT INTO prevCounters (Id,Count,Show) VALUES ({[i]}, 0, TRUE))) (oneTo max_counters)

task periodic 1 =
  fn () =>
     limits_now <- oneRow1 (SELECT * FROM limits);
     dml (UPDATE limits SET Mods = 0, Clears = 0 WHERE TRUE);
     if limits_now.Mods = 0 then return ()
     else
	 counters <- queryL1 (SELECT counters.Id, counters.Count, counters.Show
			      FROM counters
				JOIN prevCounters ON counters.Id = prevCounters.Id
			       WHERE counters.Count <> prevCounters.Count
				 OR  counters.Show  <> prevCounters.Show);
	 mapM_ (fn c => dml (UPDATE prevCounters
			     SET Count = {[c.Count]}, Show = {[c.Show]}
			     WHERE Id = {[c.Id]})) counters;
	 usrs <- queryL1 (SELECT * FROM users);
	 counters |> List.mp (fn x => if x.Show
				      then Out.Set (x.Id, x.Count)
				      else Out.Clear x.Id)
		  |> fn mods => mapM_ (fn u => send u.Chan (Out.Mod mods)) usrs
				
task clientLeaves = fn client => dml (DELETE FROM users WHERE Client = {[client]})

fun onLoad () =
    me <- self;
    chan <- oneRow1 (SELECT users.Chan FROM users WHERE users.Client = {[me]});
    ctrs <- queryL1 (SELECT * FROM counters ORDER BY counters.Id ASC);
    send chan.Chan (Out.Init ctrs)

fun serverHandler (msg : In.protocol) =
    limits_now <- oneRow1 (SELECT * FROM limits);
    dml (UPDATE limits SET Mods = {[limits_now.Mods + 1]} WHERE TRUE);
    if limits_now.Mods > max_acts_per_sec then return ()
    else 
	case msg of
	    In.New =>
	    (possible_id <- oneOrNoRows1 (SELECT id_pool.Id FROM id_pool);
	     case possible_id of
		 None => return ()
	       | Some id =>
		 dml (UPDATE counters SET Count = 0, Show = TRUE WHERE Id = {[id.Id]});	    
		 dml (DELETE FROM id_pool WHERE Id = {[id.Id]}))
	  | In.Mod (id,mod) =>
	    counter <- oneRow1 (SELECT counters.Show, counters.Count
				FROM counters WHERE counters.Id = {[id]});
	    if not <| counter.Show then return ()
	    else dml (UPDATE counters
		      SET Count = {[counter.Count + case mod of In.Incr => 1 | In.Decr => -1]}
		      WHERE Id = {[id]})
	  | In.Clear id =>
	    if limits_now.Clears > max_dels_per_sec
	    then return ()
	    else dml (UPDATE counters SET Show = FALSE WHERE Id = {[id]});
		 dml (INSERT INTO id_pool (Id) VALUES ({[id]}));
		 dml (UPDATE limits SET Clears = {[limits_now.Clears + 1]} WHERE TRUE)
    
fun clientHandler (sl : list (source counter)) (msg : Out.protocol) =
    let case msg of
	    Out.Init l => mapM_ (fn m => set (getAt m.Id) m) l
	  | Out.Mod  m =>
	    mapM_ (fn m => case m of
			       Out.Set  (id,amt) => set (getAt id) {Id = id, Count = amt, Show = True}
			     | Out.Clear id      => set (getAt id) {Id = id, Count = 0, Show = False}) m
    where fun getAt i = Option.unsafeGet <| List.nth sl (i-1) end
    
fun newSrcList (i : int) : transaction (list (source counter)) =
    let fun go j =
	    if i < j then return [] else
		s <- source {Id = j, Count = 0, Show = True};
		xs <- go (j+1);
		return (s :: xs)
    in go 1 end
	
style wide_div
style const_button
style exclaim_button
style counter_container
      
fun rpc_button (v : string) (msg : In.protocol) : xbody =
    <xml><div class={const_button}
              onclick={fn _ => rpc (serverHandler msg)}>{[v]}</div></xml>
      
fun show_counter (c : counter) : xbody = 
    <xml><div class={wide_div}>
      {[c.Count]}</div>
      {rpc_button "⇧" (In.Mod (c.Id, In.Incr))}
      {rpc_button "☢" (In.Clear c.Id)}
      {rpc_button "⇩" (In.Mod (c.Id, In.Decr))}</xml>

fun main () =
    me <- self;
    chan <- channel;
    dml (INSERT INTO users (Client, Chan) VALUES ({[me]}, {[chan]}));

    sl <- newSrcList (max_counters-1);
    
    return <xml><head><link rel="stylesheet" type="text/css" href="/style1.css"/></head>
      <body onload={let fun loop () =
			    msg <- recv chan;
			    clientHandler sl msg;
			    loop ()
		    in rpc (onLoad ()); loop () end}>

	<button value="Add" onclick={fn _ => rpc (serverHandler In.New)}/><br/>

	<div class={counter_container}>{List.foldl join <xml/> <|
		    List.mp (fn c => <xml><dyn signal={
				     c <- signal c;
				     return <| if not c.Show
					       then <xml><button class={exclaim_button} value="!"/></xml>
					       else <xml>{show_counter c}</xml>}/></xml>) sl}</div>
      </body></xml>
