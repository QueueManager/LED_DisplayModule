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
	
ASI	macro	baseAddr, index
	    MOVLF   baseAddr, FSR
	    BANKSEL index
	    MOVF    index, W
	    BANKSEL baseAddr
	    ADDWF   baseAddr, F
	endm
	
#endif
