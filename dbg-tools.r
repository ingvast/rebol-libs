REBOL [
    usage: {
	Load this file at the beginning of your file. Run the program.
	Call show-changed-vars 
	and you'll get a list of all the variables you have introduced into the 
	global scope}
    author: {Johan Ingvast}
    copyright: {Bioservo Technologies AB, 2015}
]

tic: func [
    {Returns a function that returns time since it was created or restarted
     Usage:
	>> a: tic
	>> a
	== 0:00:02.34555
     Use refinement /reset to restart the timer.
	>> a/reset
	== 0:00:10.00005
	>> a
	== 0:00:01.03005
     Create with /seconds to make the function return seconds instead of time
    }
    /seconds
    /local toc
][
    context [
	t: now/time/precise
	set 'toc func [
	    {Usage: see tic}
	    /reset
	] compose [
	    also 
		(
		    either seconds [
			[to-decimal]
		    ][
			[]
		    ]
		) 
		now/time/precise - t
		if reset [
		    t: now/time/precise
		]
	]
    ]
    :toc
]

run: func [ blk /local e ][
    if  error? e: try blk [
	return probe err: disarm e
    ]
    return e
]

either all [system/version/1 = 2 system/version/2 = 7 system/version/3 = 8] [
    context [
	{Fixing a fault with obj-dump that assumes that all first member of an object is self.
	 this is not true, e.g. the binding is to a function}
	 ; Rebuilding the function obj-dump
	 args: first :dump-obj
	 body: second :dump-obj
	 replace body
	    [ vals: next second obj ]
	    [
		vals: second obj
		if words/1 = 'self [ words: next words  vals: next vals]
	    ]
	replace body
	    [ foreach word next words ]
	    [ foreach word words ]
	set 'dump-obj func args body

	test: [
	    f: func [ a b c ][ asdf a b]
	    e: disarm try [ f 1 2 3 ]
	    o: bind? e/near/2
	    print dump-obj o
	]
    ]
][
    print "**********************************************************************"
    print "Check that obj-dump returns the right things even from function scopes"
    print "If not, try to use the fix for version 2.7.8 in dbg-tools.r"
    print "**********************************************************************"
]



dbg-tool: make object! [
    ; What variables are left in global space
    remove-unset: func [ words ][
	remove-each x words [
	    not value? in system/words x
	]
    ]

    changed: func [
	/local end-point
    ][
	end-point: remove-unset first system/words
	intersect end-point difference end-point start-point
    ]

    set 'show-changed-vars func [ /local v ] [
	v: changed
	new-line/all/skip v on 4
	print "List of variables that are changed"
	print mold v
    ]

    start-point: remove-unset first system/words

    set 'source func [
	{Overloads the normal source function}
	'var [path! word!]
    ][
	print mold either path? var [
	    get in  do copy/part var (length? var) - 1 last var
	][
	    get var
	]
    ]

    marker: none

    set 'remove-pre-hook func [
	'f [ word! path! ]
    ][
	either  path? f [
	    f-name: last f
	    remove back tail f
	    f-obj: first reduce reduce [ f ]
	    the-func: get in f-obj f-name
	][
	    f-name: f
	    the-func: get f
	]

	if main: second :the-func [
	    args: first :the-func
	    ; Check if a hook is already set, then remove it
	    ; The hook is surrunded by "marker"
	    p1: find main 'marker
	    if all [ p1 same? 'marker first p1 ] [
		p2: find next p1 'marker
		if all [ p2 same? 'marker first p2 ] [
		    remove/part p1 next p2
		]
	    ]
	]
    ]

    set 'insert-pre-hook func [
	'f [ word! path! ] {The word bound to a function, that will get a new function with a pre-hook}
	code [ block! ]
	/print-ctx
	/local args main additional
	    p1 p2
	    name
	    the-func f-name  f-obj
    ] [
	either  path? f [
	    f-name: last f
	    remove back tail f
	    f-obj: first reduce reduce [ f ]
	    the-func: get in f-obj f-name
	][
	    f-name: f
	    the-func: get f
	]

	either main: second :the-func [
	    args: first :the-func
	    ; Check if a hook is already set, then remove it
	    ; The hook is surrunded by "marker"
	    p1: find main 'marker
	    if all [ p1 same? 'marker first p1 ] [
		p2: find next p1 'marker
		if all [ p2 same? 'marker first p2 ] [
		    remove/part p1 next p2
		]
	    ]
	    additional: reduce [ 'marker 'print [ "Function" f-name ] ]
	    if print-ctx [
		append additional [ print [ "Environment:" ] ]
		foreach x args [
		    name: switch type? x compose [
			(lit-word!)   [ join "'" to-string x ]
			(refinement!) [ join "/" to-string x ]
			(word!)	    [ to-string x ]
		    ]
		    append additional compose/deep [
			print [ tab (name) ( x ) ] 
		    ]
		]
	    ]
	    append additional code
	    append additional 'marker
	    insert main additional
	] [
	    make error! "Not possible to insert hook"
	]

	either f-name = f [
	    set f func args main
	][
	    set in f-obj f-name func args main
	]
    ]
    set 'dbg-tic func [
	{Returns a function that returns time since it was created or restarted
	 Usage:
	    >> a: tic
	    >> a
	    == 0:00:02.34555
	 Use refinement /reset to restart the timer.
	    >> a/reset
	    == 0:00:10.00005
	    >> a
	    == 0:00:01.03005
	 Create with /seconds to make the function return seconds instead of time
	}
	/seconds
	/local toc
    ][
	context [
	    t: now/time/precise
	    set 'toc func [
		{Usage: see tic}
		/reset
	    ] compose [
		also 
		    (
			either seconds [
			    [to-decimal]
			][
			    []
			]
		    ) 
		    now/time/precise - t
		    if reset [
			t: now/time/precise
		    ]
	    ]
	]
	:toc
    ]
]
comment [
    ; Still prototypical
    ; Functions where profiling is added  has altered behaviour. They will return wrong value
    list-of-functions: make hash! 500

    list-profile: func [
    ][
	foreach [ f v ] list-of-functions [
	    print [ v all [ v/2 != 0 v/3 / v/2 ] ]
	]
    ]

    make-return-ctx: func [
	:fun [ function! ]
	'toc [ word! ]
    ] [
	context [
	    return: func [ [throw] val [any-type!]] [
		function-exit-code fun do get toc
		system/words/return val
	    ]
	    exit: func [ [throw] ] [
		function-exit-code fun do get toc
		system/words/exit
	    ]
	]
    ]

    function-entry-code: func [
	:f-self
	/local tic v
    ][
	v: select list-of-functions :f-self
	v/2: v/2 + 1
	dbg-tic
    ]
    function-exit-code: func [
	:f-self
	toc [ time! decimal! ]
	/local v
    ][
	v: select list-of-functions :f-self
	v/3: v/3 + toc
    ]

    append-profiling: func [
	f [ function! ]
	f-name [ word! ]
	/local tmp
    ][
	if find list-of-functions :f [ exit ] ; Profiling function already added
	append list-of-functions reduce [ :f reduce [ f-name 0 0 ] ]
	tmp: second :f
	tmp: to-paren tmp
	clear second :f
	append/only second :f tmp
	context [
	    tic: none
	    bind second :f make-return-ctx f tic
	    insert second :f compose [ tic: function-entry-code (:f) also ]
	    append second :f compose [ function-exit-code (:f) tic ]
	]
    ]

    find-all: func [
	{Find indefinitely deep in block the values}
	block [ block! ] 
	value 
	/deep {Search also in blocks}
	/local ret p
    ][
	p: block
	ret: copy []
	while [ p: find p value ][
	    append/only ret p
	    p: next p
	]

	if deep [
	    p: block
	    while [ p: find p block! ][
		append ret find-all/deep first p value
		p: next p
	    ]
	]
	ret
    ]

    find-all-functions: func [
	{Find indefinitely deep in block the values}
	block [ block! ] 
	/deep {Search also in blocks}
	/local ret p
    ][
	p: block
	ret: copy []
	forall block [
	    if all [
		word? first block
		bound? first block
		function? get first block
	    ][
		append/only ret block
	    ]
	]

	if deep [
	    p: block
	    while [ p: find p block! ][
		append ret find-all-functions/deep first p 
		p: next p
	    ]
	]
	ret
    ]

    profile-all: func [
	f [function!]
	f-name [word!]
	/local name functions 
    ][
	append-profiling :f f-name
	probe type? :f
	dbg: functions: find-all-functions/deep probe second :f
	foreach x functions [
	    name: back x
	    name: name/1
	    switch/default  type? name [
		set-path! [ name: to-path name ]
		set-word! [ name: to-word name ]
	    ] [ name: none ]
	    profile-all first x ?? name
	]
    ]

    test: func [ a b /ext ][
	if ext [ exit ]
	if a = b [
	    return true 
	]
	return false
    ]

    ;append-profiling :test 'test

    trace on
    profile-all :? '?

]
