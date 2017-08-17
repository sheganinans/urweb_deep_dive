type counter = {Count : int, Show : bool}

fun showCounter (sc : source counter) : xbody =
    <xml>
      <dyn signal={c <- signal sc; return <xml>{[c.Count]}</xml>}/><br/>
      <button value="Incr" onclick={fn _ =>
				       c <- get sc
				       set sc ((c -- #Count) ++ {Count = c.Count + 1})}/>
      <button value="Decr" onclick={fn _ =>
				       c <- get sc
				       set sc ((c -- #Count) ++ {Count = c.Count - 1})}/>
      <button value="Del"  onclick={fn _ =>
				       c <- get sc
				       set sc ((c -- #Show)  ++ {Show  = False      })}/><br/>
    </xml>
	       
fun main () =
    ls <- source ([] : list (source counter));
    return <xml><body>
      <button value="Add" onclick={fn _ =>
				      l <- get ls;
				      ll <- List.filterM (fn xs => x <- get xs; return (x.Show <> False)) l;
				      nsc <- source {Count = 0, Show = True};
				      set ls (nsc :: ll)}/><br/>
      <dyn signal={l <- signal ls;
		   ll <- List.filterM (fn xs => x <- signal xs; return (x.Show <> False)) l;
	           return (List.mapX showCounter (List.rev ll))}/></body></xml>
