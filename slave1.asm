#include "p16F628A.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

	CBLOCK	RA0
	    counterOut0, counterOut1, counterOut2, counterOut3, counterOut4
	    int_type, counterOut5, dataIn3
	ENDC
	
	CBLOCK	RB0
	    int_flag, dataOut0, dataOut1, dataOut2, dataOut3, dataIn0, dataIn1
	    dataIn2
	ENDC
	
	CBLOCK	0x20
	    data_adr:6, data_received:6, i
	    counter, mask1, mask2
	ENDC
	
	ORG	0x00
	GOTO	setup
	
	ORG	0x04
	BTFSC	INTCON, INTF
	CALL	int_handler
	RETFIE

int_handler:
	BCF	INTCON, INTE
	BTFSS	PORTB, int_type
	CALL	start_receive_data  ;int_type 0
	CALL	blink_display	    ;int_type 1
	RETURN
	
;----------------INT_HANDLERS----------------	
start_receive_data:
	;start tmr0
	RETURN

receive_data:
	
	RETURN
	
blink_display:
	
	RETURN
	
;----------------MAIN_ROUTINES----------------
counter_routine:
	MOVF	mask1, W	    ;move counter to porta
	ANDWF	counter, F 
	MOVF	mask2, W
	ANDWF	PORTA, W
	IORWF	counter, W
	MOVWF	PORTA
	
	MOVLW	b'00011111'
	SUBWF	counter, W
	BTFSC	STATUS, Z
	GOTO	equal
	BSF	STATUS, C
	RLF	counter
	RETURN
equal:
	MOVLF	b'11111110', counter
	RETURN
	
display_data:
    
	RETURN
	
;--------------------SETUP--------------------
setup:
	MOVLF	b'11111110', counter
	MOVLF	b'00111111', mask1
	MOVLF	b'11000000', mask2
	MOVLF	b'10100000', TRISA
	MOVLF	b'11100001', TRISB
	MOVLF	b'10010000', INTCON
	MOVLF	b'11010000', OPTION_REG
	
	BANKSEL	PCON
	BCF	PCON, OSCF
	BANKSEL	PORTA
	CLRF	PORTA
	CLRF	PORTB
	
	MOVLF	0x0C, i
clear_data:
	DECF	i
	ASI	data_adr, i
	INCF	i
	MOVLF	0x00, INDF
	DECFSZ	i
	GOTO	clear_data
	
;----------------MAIN_LOOP----------------
main_loop:
	CALL	counter_routine
	;CALL	display_data
	GOTO	main_loop
	
	END