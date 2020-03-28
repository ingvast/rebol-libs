REBOL []
vtc: context [
    
    cc-digit: charset "0123456789"

    eval: func [ code [block!] ]
    [
	rejoin bind code 'eval 
    ]

    loop: func [
	n [integer!] {The number of times to loop }
	code [block!] {The prints to loop}
	/local ret
    ][
	ret: clear ""
	system/words/loop n [ append ret eval code ]
	ret
    ]

    term: none
    ; Mode changes
    insert-mode: rejoin [ escape "[4h" ]
    replace-mode: rejoin [ escape "[4l" ]

    ;   tabs
    set-tab-stop: rejoin [ escape  "H" ]
    clear-tab-stop: rejoin [ escape "[g"]
    clear-all-tab-stops: rejoin [ escape "[3g"]
    
    ;   fonts
    normal: rejoin [ escape "[0m" ]
    underline: rejoin [ escape "[4m" ]
    bold: rejoin [ escape "[1m" ]
    blink: rejoin [ escape "[5m" ]
    reverse: rejoin [ escape "[7m" ]

    ;   Position changes
    save-cursor: rejoin [ escape "7" ]
    restore-cursor: rejoin [ escape "8" ]

    ; Save and restore screen
    save-screen: rejoin [ escape "[?47h" ]
    restore-screen: rejoin [ escape "[?47l" ]

    ; with args
    insert-lines: func [ Pn ][ rejoin [ escape "[" Pn "L" ]]
    delete-lines: func [ Pn ][ rejoin [ escape "[" Pn "M" ]]
    delete-characters: func [Pn][ rejoin [escape "[" Pn "P"]]

    clear-display: rejoin [ escape "[2J" ]
    clear-display-from-home: rejoin [ escape "[1J" ]
    clear-display-to-end: rejoin [ escape "[0J" ]

    clear-line: rejoin [ escape "[2K" ]
    clear-line-from-home: rejoin [ escape "[1K" ]
    clear-line-to-end: rejoin [ escape "[K" ]

    reset-terminal: rejoin [ escape "c" ]

    reset: rejoin [ escape "[0m" ] 
    bold: rejoin [ escape "[1m" ] 
    light: rejoin [ escape "[2m" ] 
    underscore: rejoin [ escape "[4m" ]   
    blink: rejoin [ escape "[5m" ] 
    reverse: rejoin [ escape "[7m" ] 
    hidden: rejoin [ escape "[8m" ] 

    c-black: rejoin [ escape "[30m" ]
    c-red: rejoin [ escape "[31m" ]
    c-green: rejoin [ escape "[32m" ]
    c-yellow: rejoin [ escape "[33m" ]
    c-blue: rejoin [ escape "[34m" ]
    c-magenta: rejoin [ escape "[35m" ]
    c-cyan: rejoin [ escape "[36m" ]
    c-white: rejoin [ escape "[37m" ]
    c-default: rejoin [ escape "[39m" ]

    b-black: rejoin [ escape "[40m" ]
    b-red: rejoin [ escape "[41m" ]
    b-green: rejoin [ escape "[42m" ]
    b-yellow: rejoin [ escape "[44m" ]
    b-blue: rejoin [ escape "[44m" ]
    b-magenta: rejoin [ escape "[45m" ]
    b-cyan: rejoin [ escape "[46m" ]
    b-white: rejoin [ escape "[47m" ]
    b-default: rejoin [ escape "[49m" ]
    
    ; With answers
    get-cursor-pos: rejoin [
        escape "[6n"
    ]

    next-line: rejoin [ escape "E" ] ; Moves cursor to first pos of next line scroll if nessearsy

    move-up: rejoin [ escape "M" ] ; Moves cursor to prev line scroll if nessearsy

    move-down: rejoin [ escape "D" ]; Moves cursor to next line scroll if nessearsy

    scroll-up-page: rejoin [ escape "[5~" ] ;; Cant get to work
    scroll-down-page: rejoin [ escape "[6~" ] ;; Cant get to work

    cur-up: func [ /n Pn ][ rejoin [ escape "[" any [ Pn ""] "A" ] ]
    cur-down: func [ /n Pn ][ rejoin [ escape "[" any [ Pn ""] "B" ] ]
    cur-forward: func [ /n Pn ][ rejoin [ escape "[" any [ Pn ""] "C" ] ]
    cur-backward: func [ /n Pn ][ rejoin [ escape "[" any [ Pn ""] "D" ] ]

    delete-right: func[ /n Pn ][ rejoin [ escape "[" any [ Pn ""] "P" ] ]

    home: rejoin [ escape "[f" ]
    pos: func [ r c ][ rejoin [ escape "[" r ";" c "f" ] ]

    set-margin: func [ Pt Pb ][ rejoin [ escape "[" any [ Pt ""] ";" any [ Pb ""] "r" ]]

    set-pos-abs: rejoin [ escape "[?6l" ]   ; Positions/home relative margin
    set-pos-rel: rejoin [ escape "[?6h" ]   ; Positions/home relative window

    outport: open/direct/binary [ scheme: 'console ]
    inport: outport

    from-term-to-name: [
        "[A" key-arrow-up   "[B" key-arrow-down "[C" key-arrow-right "[D" key-arrow-left
        "[1~" key-home	    "[4~" key-end
        "[2~" key-insert    "^[[3~" key-delete 
        "[5~" key-page-up   "[6~" key-page-down
	"[3~" key-delete    "[2~" key-insert
	"[1~" key-home	    "[4~" key-end
	"^[[5;2~" key-S-page-up   "^[[6;2~" key-S-page-down
    ]

    report-type-args: [
	none
	[]
    ]
    from-term-type: none
    from-term-data: none
    from-term-tmp: none
    from-term-pos-report: [ 
	(from-term-tmp: copy [none none] )
	"["
	copy from-term-tmp/1 some cc-digit
	";" 
	copy from-term-tmp/2 some cc-digit
	"R"
	(
	    from-term-data: as-pair to-integer from-term-tmp/2 to-integer from-term-tmp/1 
	    from-term-type: 'pos-report
	)
    ]
    from-term-reports: [
	from-term-pos-report
    ]

]

vt-set-outport: func [ port [port! ] ][
    close vtc/outport
    vtc/outport: port
]
vt-set-inport: func [ port [port! ] ][
    close vtc/inport
    vtc/inport: port
]

vt-prin: func [ data ][
     prin reform bind data vtc
]
vt-print: func [ data ][
     print reform bind data vtc
]
vt-join: func [ data ][
    rejoin bind data vtc
]

vt-reduce: func [ data ][
    reduce bind data vtc 
]

