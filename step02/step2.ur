fun newCounter () : transaction xbody =
    x <- source 0;
    return <xml>
      <dyn signal={n <- signal x; return <xml>{[n]}</xml>}/><br/>
      <button value="Incr" onclick={fn _ => n <- get x; set x (n + 1)}/>
      <button value="Decr" onclick={fn _ => n <- get x; set x (n - 1)}/>
    </xml>
	       
fun main () =
    ls <- source ([] : list xbody);
    return <xml><body>
      <button value="Add" onclick={fn _ =>
				      l <- get ls;
				      c <- newCounter ();
				      set ls (c :: l)}/>
      <button value="Del" onclick={fn _ =>
				      l <- get ls;
				      case l of
					  []     => return ()
					| _ :: l => set ls l}/><br/>
      <dyn signal={l <- signal ls;
		   return (List.mapX (fn x => <xml>{x}<br/></xml>) (List.rev l))}/>
    </body></xml>
