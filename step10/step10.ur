type counterT = [Id = int, Count = int]

sequence counter_seq
table counters : counterT
	       PRIMARY KEY Id
		 
type counter = $counterT

datatype mod = Incr | Decr
		      
datatype action = New | Mod of int * mod | Del of int

table users : { Client : client, Chan : channel (list counter) }
		  PRIMARY KEY Client

fun mod2Int (m : mod) : int = case m of Incr => 1 | Decr => neg 1
		  
fun update (i : int) (d : mod) =
    dml (UPDATE counters SET Count = Count + {[mod2Int d]} WHERE Id = {[i]})
	      
fun act (a : action) =
    case a of
	New  =>
	n <- nextval counter_seq;
	dml (INSERT INTO counters (Id, Count) VALUES ({[n]}, 0))
      | Mod (i,m) => update i m
      | Del i => dml (DELETE FROM counters WHERE Id = {[i]})

fun onLoad () =
    me <- self;
    chan <- oneRow1 (SELECT users.Chan FROM users WHERE users.Client = {[me]});
    ctrs <- queryL1 (SELECT * FROM counters);
    send chan.Chan ctrs

fun mapM_ [m] (_ : monad m) [a] [b]
	  (f : a -> m b) (x : list a) : m {} = _ <- List.mapM f x; return ()

task periodic 1 =
  fn () =>
     ctrs <- queryL1 (SELECT * FROM counters);
     usrs <- queryL1 (SELECT * FROM users);
     mapM_ (fn u => send u.Chan ctrs) usrs
								   
fun main () =
    me <- self;
    chan <- channel;
    dml (INSERT INTO users (Client, Chan) VALUES ({[me]}, {[chan]}));
    
    sl <- source ([] : list counter);

    return <xml><body onload={let fun loop () =
				      x <- recv chan;
				      set sl x;
				      loop ()
			      in rpc (onLoad ());
				 loop ()
			      end}>
      
      <button value="Add" onclick={fn _ => _ <- rpc (act New); return ()}/><br/>
	
      <dyn signal={l <- signal sl;
		   return (List.mapX
			       (fn {Id = i, Count = c} => <xml>
				 {[c]}<br/>
				 <button value="Incr" onclick={fn _ => rpc (act (Mod (i, Incr)))}/>
				 <button value="Decr" onclick={fn _ => rpc (act (Mod (i, Decr)))}/>
				 <button value="Del"  onclick={fn _ => rpc (act (Del i))}/><br/></xml>)
			       (List.sort (fn a b => gt a.Id b.Id) l))}/></body></xml>
