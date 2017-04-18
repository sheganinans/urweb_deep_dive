datatype mod = Incr | Decr

type counterT = [Id = int, Count = int]
			   
type counter = $counterT
		      
datatype diff
  = New of counter
  | Del of int
  | Mod of int * mod

sequence counter_seq
table counters : counterT
		 PRIMARY KEY Id

table users : { Client : client, Chan : channel diff }
		  PRIMARY KEY Client

fun mod2Int (m : mod) : int = case m of Incr => 1 | Decr => neg 1
		  
fun update (i : int) (d : mod) =
    dml (UPDATE counters SET Count = Count + {[mod2Int d]} WHERE Id = {[i]})
	      
fun render (diff : diff) (sl : source (list counter)) =
    l <- get sl;
    case diff of
	New  c     => set sl (c :: l)
      | Del  i     => set sl (List.filter (fn x => x.Id <> i) l)
      | Mod (i, m) => set sl (List.mp (fn x => if eq x.Id i
					       then  x -- #Count ++ {Count = x.Count + (mod2Int m)}
					       else x) l)

fun mapM_ [m] (_ : monad m) [a] [b]
	  (f : a -> m b) (x : list a) : m {} = _ <- List.mapM f x; return ()
	
fun newCounter () =
    n <- nextval counter_seq;
    dml (INSERT INTO counters (Id, Count) VALUES ({[n]}, 0));
    usrs <- queryL1 (SELECT users.Chan FROM users);
    mapM_ (fn x => send x.Chan (New {Id = n, Count = 0})) usrs
    
fun onLoad () =
    me <- self;
    chan <- oneRow1 (SELECT users.Chan FROM users WHERE users.Client = {[me]});
    ctrs <- queryL1 (SELECT counters.Id, counters.Count FROM counters);
    mapM_ (fn x => send chan.Chan (New {Id = x.Id, Count = x.Count})) ctrs
		      
fun mod (diff : diff) =
    case diff of
	Mod (id, m) => (
	r <- oneOrNoRows1 (SELECT * FROM counters WHERE counters.Id = {[id]});
	case r of
	    Some c => update c.Id m;
	    usrs <- queryL1 (SELECT users.Chan FROM users);
	    mapM_ (fn x => send x.Chan diff) usrs
	  | None => return ())
      | Del id =>
	dml (DELETE FROM counters WHERE Id = {[id]});
	usrs <- queryL1 (SELECT * FROM users);
	mapM_ (fn x => send x.Chan diff) usrs
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
