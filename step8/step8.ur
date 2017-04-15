datatype mod = Incr | Decr

datatype diff
  = New of int * int
  | Del of int
  | Mod of int * mod

type counterT = [Id = int, Count = int]
			   
type counter = $counterT

sequence counter_seq
table counters : counterT

table users : { Client : client, Chan : channel diff }
		  PRIMARY KEY Client
		 
fun render (diff : diff) (sl : source (list counter)) =
    l <- get sl;
    case diff of
	New (i, c) => set sl ({Id = i, Count = c} :: l)
      | Del  i     => set sl (List.filter (fn x => x.Id <> i) l)
      | Mod (i, m) => set sl (List.mp (fn x => if eq x.Id i
					       then case m of
							Incr => x -- #Count ++ {Count = x.Count + 1}
						      | Decr => x -- #Count ++ {Count = x.Count - 1}
					       else x) l)

fun mapM_ [m] (_ : monad m) [a] [b]
	  (f : a -> m b) (x : list a) : m {} = _ <- List.mapM f x; return ()
	
fun newCounter () =
    n <- nextval counter_seq;
    dml (INSERT INTO counters (Id, Count) VALUES ({[n]}, 0));
    usrs <- queryL (SELECT * FROM users);
    mapM_ (fn x => send x.Users.Chan (New (n, 0))) usrs
    
fun onLoad () =
    me <- self;
    chan <- oneRow1 (SELECT * FROM users WHERE users.Client = {[me]});
    ctrs <- queryL1 (SELECT counters.Id, counters.Count FROM counters);
    mapM_ (fn x => send chan.Chan (New (x.Id, x.Count))) ctrs

fun updateCount i c = dml (UPDATE counters SET Count = {[c]} WHERE Id = {[i]})
		      
fun mod (diff : diff) =
    case diff of
	Mod (id, m) => (
	r <- oneOrNoRows (SELECT * FROM counters WHERE counters.Id = {[id]});
	case r of
	    Some c => let val c = c.Counters
		      in (case m of
			      Incr => updateCount (c.Count + 1) c.Id
			    | Decr => updateCount (c.Count - 1) c.Id);
			 usrs <- queryL (SELECT * FROM users);
			 mapM_ (fn x => send x.Users.Chan diff) usrs
		      end
	  | None => return ())
      | Del id =>
	dml (DELETE FROM counters WHERE Id = {[id]});
	usrs <- queryL (SELECT * FROM users);
	mapM_ (fn x => send x.Users.Chan diff) usrs
      | _ => return ()
    
fun main () =
    me <- self;
    chan <- channel;
    dml (INSERT INTO users (Client, Chan) VALUES ({[me]}, {[chan]}));
    
    sl <- source ([] : list counter);

    return <xml><body onload={let fun loop () =
				      x <- recv chan;
				      render x sl;
				      loop ()
			      in rpc (onLoad ());
				 loop ()
			      end}>
      
      <button value="Add" onclick={fn _ => _ <- rpc (newCounter ()); return ()}/><br/>
	
      <dyn signal={l <- signal sl;
		   return (List.mapX
			       (fn {Id = i, Count = c} => <xml>
				 {[c]}<br/>
				 <button value="Incr" onclick={fn _ => rpc (mod (Mod (i, Incr)))}/>
				 <button value="Decr" onclick={fn _ => rpc (mod (Mod (i, Decr)))}/>
				 <button value="Del"  onclick={fn _ => rpc (mod (Del i))}/><br/></xml>)
			       (List.sort (fn a b => gt a.Id b.Id) l))}/></body></xml>
