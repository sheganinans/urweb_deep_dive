# Ur/Web Deep Dive.

For the intermediate functional programmer.

# Step 1: Single counter.

The focus of our entire tutorial, the humble counter:

![step01_01](https://i.imgur.com/awyUikP.png, "One counter")

The following code below put into a .ur file (coupled with the proper .urs and .urp files) creates a page with exactly the contents of the image above.

    fun newCounter () : transaction xbody =
		x <- source 0;
		return <xml>
			<dyn signal={n <- signal x; return <xml>{[n]}</xml>}/><br/>
			<button value="Incr" onclick={fn _ => n <- get x; set x (n + 1)}/>
			<button value="Decr" onclick={fn _ => n <- get x; set x (n - 1)}/>
		</xml>
	       
    fun main () =
		c <- newCounter ();
		return <xml><body>{c}</body></xml>

This code also points out the finer points of the Ur/Web syntax. The 4th line in the code above has the characters "{[n]}". However, this is not syntax sugar for creating a list with a single element n. There is actually no syntax sugar for lists in Ur/Web (It's all: 1 :: 2 :: 3 :: []). Because in Ur/Web it is possible to interpolate XML inside of Ur/Web inside of XML inside of SQL inside of ..., it is important to differentiate between interpolating different types of values.

![step01_02](https://i.imgur.com/07fygYa.png, "XML & Ur interpolation")

The above code is perfect to show all the elements of the interpolation syntax for XML. Interpolation always uses {}, so as you can see the first type of interpolation "computed XML fragment" is used on the last line "<body>{c}</body>", the second type "injection of an Ur expression, via Top.txt function" is obviously used on line 4 mentioned earlier, and the last type "computed value" is used on lines 4, 5, and 6. As you can see the computed value interpolations in the code line up exactly with the syntax defined in the whitepaper, looking at the last line of the image the {e} line is a case of "Attribue value v" and v is used on the line "Tag g" in "h (x[=v])*" and as you can see g is used in "XML pieces on lines "<g/>" and "<g>l*</x>". Looking at the code on the increment button, the button is g, on click is x, and the interpolation of the get and set functions is v.

Exercise: Implement a (* 2) button.

# Step 2: Stack of counters.

Ok, one counter is boring, let's get some more counters on the screen.

![step02_01](https://i.imgur.com/nrcSodf.png, "Stack")

Click the Del button, buttom element disappears:

![step02_02](https://i.imgur.com/lplNc7t.png, "Stack after")

The code reuses most of the same code, it just adds more logic, making a stack of counters.

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

The stack is just the source "ls", which holds a mutable list of xml, which is then turned into a signal and drawn to the DOM on the last line in the built in Ur/Web tag "<dyn signal/>". A signal tag can take an immutable signal (view) of some piece of mutable data and it expects a piece of xml to be returned with possibly some values interpolated into it. The buttons mutate the state of ls and the dyn tag displays the contents.

Exercise: Implement the clear button.

# Step 3: Heap of counters.

Before

![step03_01](https://i.imgur.com/vvDgakW.png, "Heap")

After

![step03_02](https://i.imgur.com/xppjMZa.png, "Heap after")

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

# Step 4: Abstracting updates. (Skip to step 7!)

# Step 5: Abstracting filtering.

# Step 6: DOM Garbage Collection.

# Step 7: Persisting to DB.

# Step 8: Realtime updates.

# Step 9: Init batching

# Step 10: Reducing database load

# Step 11: Client side responsiveness

# Step 12: Making the database lazy

# Step 13: Making the client lazy

# Step 14: The one source of truth, the database!
