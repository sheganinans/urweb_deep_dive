fun newCounter () : transaction xbody =
    x <- source 0;
    return <xml>
      <dyn signal={n <- signal x; return <xml>{[n]}</xml>}/><br/>
      <button value="Incr" onclick={fn _ => n <- get x; set x (n + 1)}/>
      <button value="Decr" onclick={fn _ => n <- get x; set x (n - 1)}/>
    </xml>
	       
fun main () =
    c <- newCounter ();
    return <xml><body>{[c]}</body></xml>
