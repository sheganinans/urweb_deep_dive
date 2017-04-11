open List

style style1

sequence seq

table state : { Id : int, Count : int }
		  PRIMARY KEY Id

fun main () =
    v <- queryX (SELECT * FROM state ORDER BY state.Id)
		(fn x => <xml>{[x.State.Count]}<br/>
		  <form class={style1}><submit value="Incr" action={incr x.State.Id}/></form>
		  <form class={style1}><submit value="Decr" action={decr x.State.Id}/></form>
		  <form class={style1}><submit value="Del"  action={del  x.State.Id}/></form><br/></xml>);
    return <xml>
      <body>
	<form>
	  <submit value="Add" action={addCounter}/>
	</form><br/>
	{v}</body></xml>
			
and addCounter _ =
    n <- nextval seq;
    dml (INSERT INTO state (Id, Count) VALUES ({[n]}, 0));
    main ()

and incr (id : int) () =
    dml (UPDATE state SET Count = Count + 1 WHERE Id = {[id]});
    main ()

and decr (id : int) () =
    dml (UPDATE state SET Count = Count - 1 WHERE Id = {[id]});
    main ()

and del (id : int) () =
    dml (DELETE FROM state WHERE Id = {[id]});
    main ()
