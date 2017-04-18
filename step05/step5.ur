type counter = {Count : int, Show : bool}

fun update [nm :: Name] [t ::: Type] [fs] [fs ~ [nm = t]]
	   (f : t -> t) (r : $([nm = t] ++ fs)) : $([nm = t] ++ fs) = (r -- nm ++ {nm = f r.nm})
	       
fun getSet [a] (sa : source a) (f : a -> a) : transaction {} = s <- get sa; set sa (f s)

fun updtSrcRec [nm :: Name] [t ::: Type] [fs] [fs ~ [nm = t]]
	       (f : t -> t) (s : source $([nm = t] ++ fs)) : transaction {} = getSet s (update [nm] f)
	       
fun showCounter (sc : source counter) : xbody =
    <xml>
      <dyn signal={c <- signal sc; return <xml>{[c.Count]}</xml>}/><br/>
      <button value="Incr" onclick={fn _ => updtSrcRec [#Count] (fn x => x + 1) sc}/>
      <button value="Decr" onclick={fn _ => updtSrcRec [#Count] (fn x => x - 1) sc}/>
      <button value="Del"  onclick={fn _ => updtSrcRec [#Show]  (fn _ => False) sc}/><br/>
    </xml>
    
fun notFalse [m] (_ : monad m) [nm :: Name] [fs] [fs ~ [nm = bool]]
	     (r : $([nm = bool] ++ fs)) : m bool = return (r.nm <> False)
    
fun filterSrcByName [m] (_ : monad m) [nm ::: Name] [fs] [fs ~ [nm = bool]]
		    (grab : source $([nm = bool] ++ fs) -> m $([nm = bool] ++ fs))
		    (filter : $([nm = bool] ++ fs) -> m bool)
		    (l : list (source $([nm = bool] ++ fs))) :
    m (list (source $([nm = bool] ++ fs))) = List.filterM (fn xs => x <- grab xs; filter x) l
    
fun filterShowByGrab [m] (_ : monad m) [fs] [fs ~ [Show = bool]]
		     (grab : source $([Show = bool] ++ fs) -> m $([Show = bool] ++ fs)) =
    filterSrcByName grab (notFalse [#Show])
    
fun main () =
    ls <- source ([] : list (source counter));
    return <xml><body>
      <button value="Add" onclick={fn _ =>
				      l <- get ls;
				      ll <- filterShowByGrab get l;
				      nsc <- source {Count = 0, Show = True};
				      set ls (nsc :: ll)}/><br/>
      <dyn signal={l <- signal ls;
		   ll <- filterShowByGrab signal l;
	           return (List.mapX showCounter (List.rev ll))}/></body></xml>
