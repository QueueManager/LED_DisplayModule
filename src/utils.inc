#ifndef	UTILS
#define UTILS
MOVLF	macro	literal, file
	    MOVLW   literal
	    BANKSEL file
	    MOVWF   file
	endm
	
MOVFF	macro	first, second
	    BANKSEL first
	    MOVF    first, W
	    BANKSEL second
	    MOVWF   second
	endm
	
SWAP	macro	first, second
	    BANKSEL first
	    MOVF    first, W	;w = first + second
	    BANKSEL second
	    ADDWF   second, W	
	
	    BANKSEL first
	    SUBWF   first, F	;w = w - first
	    COMF    first
	    INCF    first		
	
	    BANKSEL second
	    SUBWF   second, F	;w = w - second
	    COMF    second
	    INCF    second		
	endm
	
SETBANK	macro   bank
	    if bank == 0x00
		BANKSEL h'00'
	    endif
	    if bank == 0x01
		BANKSEL h'80'
	    endif
	    if bank == 0x02
		BANKSEL h'100'
	    endif
	    if bank == 0x03
		BANKSEL h'180'
	    endif
	endm    
	
ADDLF	macro	literal, file, d
	    MOVLW   literal
	    BANKSEL file
	    ADDWF   file, d
	endm
	
;0 - w
;1 - 1st
;2 - 2nd
ADDFF	macro	first, second, d
	    BANKSEL first
	    MOVF    first, W
	    BANKSEL second
	    ADDWF   second, W
	    if d == 1
		BANKSEL	first
		MOVWF	first
	    endif
	    if d == 2
		MOVWF	second
	    endif
	endm

;0 - w
;1 - 1st
;2 - 2nd
;first - second
SUBFF	macro	first, second, d
	    BANKSEL second
	    MOVF    second, W
	    BANKSEL first
	    SUBWF   first, W
	    if d == 1
		MOVWF	first
	    endif
	    if d == 2
		BANKSEL second
		MOVWF	second
	    endif
	endm
	
ASI	macro	baseAdr, index
	    MOVLF   baseAdr, FSR
	    BANKSEL index
	    ADDFF   index, FSR, 2
	endm
#endif
