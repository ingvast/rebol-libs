REBOL [
    title: {Standard charsets to be used for parse}
    author: {Johan Ingvast}
    copyright: {Bioservo Technologies AB 2014}
]
cc-alpha: charset [ #"a" - #"z" #"A" - #"Z" ]
cc-digit: charset [ #"0" - #"9" ]
cc-alphanum: union cc-alpha cc-digit
cc-decimal-separator: #"."
cc-integer: [ opt #"-" some cc-digit ]
cc-real: [
    opt #"-"  [
	[
	    any cc-digit cc-decimal-separator any cc-digit opt [ 
		[ #"e" | #"E" ] cc-integer ]
	] | [
	    any cc-digit [ #"e" | #"E" ] cc-integer 
	]
    ]
]
cc-number: [ cc-integer | cc-real ]
cc-space: charset " ^-"

cc: context [
    alpha: charset [ #"a" - #"z" #"A" - #"Z" ]
    digit: charset [ #"0" - #"9" ]
    digit*: complement digit
    alphanum: union alpha digit
    decimal-separator: #"."
    integer: [ opt #"-" some digit ]
    real: [
	opt #"-"  
	[
	    any digit
	    opt decimal-separator
	    any digit
	    opt
	    [ 
		[ #"e" | #"E" ]
		some integer
	    ]
	]
    ]
    number: [ real | integer ]
    space: charset " ^-"

    time: use [ here ] [
	[ 2 digit ":" 2 digit ":" 2 digit here: digit* :here ]
    ]

    hexchar: charset [ #"0" - #"9" #"a" - #"f"  #"A" - #"F" ]
    hex: [ some hexchar ]
    hexmarker: "0x"
    hex-full: [ hex-marker hex ]
    to-end-of-line: reduce [ 'any complement charset reduce [ newline ] ]

    quote*: complement charset {"}
    string-result: none
    string: [ ( string-result: none ) {"} copy string-result any [ quote* | {""} ] {"} ]
]
