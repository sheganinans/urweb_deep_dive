type counterT = [Id = int, Count = int]

sequence counter_seq
table counters : counterT
	       PRIMARY KEY Id

table changed : {Change : bool}
		 
type counter = $counterT

datatype mod = Incr | Decr
		      
datatype action = New | Mod of int * mod | Del of int

table users : { Client : client, Chan : channel (list counter) }
		  PRIMARY KEY Client

fun changeAbs v = dml (UPDATE changed SET Change = {[v]} WHERE TRUE)

fun   change () = changeAbs True
fun unchange () = changeAbs False

fun mod2Int (m : mod) : int = case m of Incr => 1 | Decr => neg 1
		  
fun update (i : int) (d : mod) =
    dml (UPDATE counters SET Count = Count + {[mod2Int d]} WHERE Id = {[i]})
				 
fun act (a : action) =
    (case a of
	New =>
	n <- nextval counter_seq;
	dml (INSERT INTO counters (Id, Count) VALUES ({[n]}, 0))
      | Mod (i,m) => update i m
      | Del i => dml (DELETE FROM counters WHERE Id = {[i]}));
    change ()

fun biggestId (l : list counter) : int = List.foldl (fn c acc => max c.Id acc) 0 l

fun mod (i : int) (d : int) (l : list counter) : list counter =
    List.mp (fn x => if x.Id = i
		     then x -- #Count ++ {Count = x.Count + d}
		     else x) l
					 
fun render (sl : source (list counter)) (a : action) =
    l <- get sl;
    set sl (case a of
		New => {Id = biggestId l + 1, Count = 0} :: l
	      | Mod (i,m) => mod i (mod2Int m) l
	      | Del i => List.filter (fn x => x.Id <> i) l)
    
fun renderAndSend (sl : source (list counter)) (a : action) =
    render sl a; rpc (act a)
    		 
fun onLoad () =
    me <- self;
    chan <- oneRow1 (SELECT users.Chan FROM users WHERE users.Client = {[me]});
    ctrs <- queryL1 (SELECT * FROM counters);
    send chan.Chan ctrs

fun mapM_ [m] (_ : monad m) [a] [b]
	  (f : a -> m b) (x : list a) : m {} = _ <- List.mapM f x; return ()

task initialize =
  fn () =>
     r <- oneOrNoRows (SELECT * FROM changed);
     case r of
	 None => dml (INSERT INTO changed (Change) VALUES (FALSE))
       | Some s => return ()
								   
task periodic 1 =
  fn () =>
     changed <- oneRow1 (SELECT * FROM changed);
     unchange ();
     if changed.Change
     then ctrs <- queryL1 (SELECT * FROM counters);
	  usrs <- queryL1 (SELECT * FROM users);
	  mapM_ (fn u => send u.Chan ctrs) usrs
     else return ()

								   
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
      
      <button value="Add" onclick={fn _ => _ <- renderAndSend sl New; return ()}/><br/>
	
      <dyn signal={l <- signal sl;
		   return (List.mapX
			       (fn {Id = i, Count = c} => <xml>
				 {[c]}<br/>
				 <button value="Incr" onclick={fn _ => renderAndSend sl (Mod (i, Incr))}/>
				 <button value="Decr" onclick={fn _ => renderAndSend sl (Mod (i, Decr))}/>
				 <button value="Del"  onclick={fn _ => renderAndSend sl (Del i)}/><br/></xml>)
			       (List.sort (fn a b => gt a.Id b.Id) l))}/></body></xml>

