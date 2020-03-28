REBOL [
    title: {Library taht extends the possibilities of VID}
    author: {Johan Ingvast}
    copyright: {Bioservo Technologies AB, 2016}
    doc: {
	Adds the following styles:
	    lbl-field
		A field with which shows a centered grayed text when empty.
		The text is used to tell what the field should contain.
		use as:
		    lbl-field 300 "" "Write your name"
	}
]


stylize/master [
    lbl-field: field
	font [ colors: reduce [ black gray ] ]
	with [
	    label: make face [
		edge: none text: "Type here" size: 50x20
		offset: 0x0
		font: make font [ color: gray style: 'italic] color: none
	    ]
	    append init [ label: make label []  label/size: size ]
	    feel: make feel [
		redraw: func [ face act pos ][
		    if act = 'show [
			check-label face
			if  block? face/colors [
			    face/color: pick face/colors face <> system/view/focal-face
			]
		    ]
		    true
		]
		check-label: func [ face ][
		    either any [ not face/text empty? face/text ] [
			unless face/pane [
			    face/pane: face/label
			    show face
			]
		    ] [
			face/pane: none
		    ]
		]
	    ]
	    multi: make multi [
		text: func [ face blk ][
		    if string? blk/1 [ face/text: blk/1 ]
		    if string? blk/2 [ face/label/text: blk/2 ]
		]
	    ]
	    resize: func [ face  ][
		face/label/size: face/size 
	    ]
	    doc: make doc [
		string: "First string is default value, second the text shown when empty"
	    ]
	]
    check-list: panel [
	across space 0x0
	panel [
	    across space 0x0
	    list 
		with [
		    row-offset: 0
		    row-of-list: func [ face /local parent ][
			parent: face/parent-face
			to-integer parent/offset/y / parent/size/y + 1
		    ]
		]
		[
		    space 10x0 across
		    check [
			unless face/parent-face [ exit ]
			use [ base-face row-number line row-offset ][
			    base-face: face/parent-face/parent-face/parent-face/parent-face
			    row-number: base-face/list/row-of-list face
			    
			    line: pick base-face/matrix-filtered base-face/list/row-offset + row-number

			    line/1: not line/1
			    show face
			]
		    ]
		    text  400 no-wrap
		]
		supply [
		    unless face/parent-face [ exit ]

		    use [ base-face ][

			base-face: face/parent-face/parent-face/parent-face/parent-face

			count: count + any [ attempt [base-face/list/row-offset ] 0 ]
			if count > length? base-face/matrix-filtered [
			    face/access/set-face* face none
			    exit
			]
			if count < 0 [ exit ]

			face/access/set-face* face base-face/matrix-filtered/:count/:index
		    ]
		]
	    scroller 15x200 [
		use [ table-size-y list base-face list ] [
		    unless face/parent-face [ exit ]

		    base-face: face/parent-face/parent-face
		    list: base-face/list

		    table-size-y: length? base-face/matrix-filtered
		    list/row-offset: max 0
				to-integer 1 + table-size-y - (list/size/y / list/subface/size/y) * value
		    show list
		]
	    ]
	]
	with [
	    resize: func [ face ][
		face/pane/1/size: face/size - as-pair face/pane/2/size/x 0
		face/pane/2/offset/x: face/pane/1/size/x
		face/pane/2/resize/y face/size/y
	    ]
	]
	return
	lbl-field 250  "" "Filter" [
	    use [ num-rows txt base-face ][
		face/parent-face/filter-list base-face: face/parent-face value
		txt: select face/parent-face/pane face
		txt/text: either (length? base-face/matrix) = length? base-face/matrix-filtered 
		[ "" ][ rejoin [ length? base-face/matrix-filtered "/" length? base-face/matrix ] ]
		show txt
	    ]
	]
	info 100
    ]
    with [
	longest-text:
	list-pane:
	list: 
	scroller: 
	filter-field:  none
	filter-info:
	matrix: none
	matrix-filtered: none

	filter-list: func [ base-face filt-str /local filt-blk ] [
	    either any [ not filt-str empty? filt-str ] [
		base-face/matrix-filtered: copy matrix
		show list
	    ][
		either find filt-str " " [
		    if error? err: try [
			filt-blk: load/all filt-str
			remove-each x base-face/matrix-filtered: copy matrix [ not parse/case/all x/2 filt-blk ]
		    ] [
			err: disarm err
			print mold err
		    ]
		] [
		    remove-each x base-face/matrix-filtered: copy matrix [ not find x/2 filt-str ]
		]
		use [ table-size-y list ] [
		    list: base-face/list
		    table-size-y: length? base-face/matrix-filtered
		    list/row-offset: max 0
				to-integer 1 + table-size-y - (list/size/y / list/subface/size/y) * base-face/scroller/data
		    show list
		]
	    ]
	]

	resize: func [ face ] [
	    face/list-pane/size: face/size - as-pair 0 face/filter-field/size/y + 0
	    face/filter-field/offset/y: face/list-pane/size/y + 0
	    face/filter-info/offset/y: face/list-pane/size/y + 0
	    face/filter-info/size/x: 74
	    face/filter-info/offset/x: face/size/x - 74
	    face/filter-field/size/x: face/size/x - face/filter-info/size/x
	    foreach x face/pane [ all [ any [ block? x object? x ] get in x 'resize x/resize x ]]
	]

	append init [
	    list-pane: pane/1
	    list: list-pane/pane/1
	    scroller: list-pane/pane/2
	    filter-field: pane/2
	    filter-info: pane/3

	    longest-text: 0
	    foreach x matrix [
		list/subface/text: x/2
		longest-text: max longest-text pick size-text list/subface 1
	    ]

	    svv/vid-styles/list list reduce [ 'data matrix ]
	    resize self
	]

	repend words: any [ block? words copy [] ] [
	    'data func [ new args ][
		new/matrix-filtered: new/matrix: second args
		next args
	    ]
	]
    ]
]
