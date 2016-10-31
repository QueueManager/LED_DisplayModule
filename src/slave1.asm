#include "p16F628A.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
	CBLOCK	0x20
	    i, aux, pos, id, t0
	    dataAddr:6, dataReceivedAddr:6
	    counterMask1, counterMask2
	    dataOutMask1, dataOutMask2
	    dataInMask1, dataInMask2
	    counterOutput, dataOut, dataIn
	ENDC
	
	ORG	0x00
	GOTO	setup
	
	ORG	0x04
	BTFSC	INTCON, INTF
	CALL	intHandler
	BTFSC	INTCON, T0IF
	CALL	receiveData
	RETFIE
	
;----------------INT HANDLERS----------------
getDataIn:
	MOVLF	0x00, dataIn
	RETURN
	
intHandler:
	BCF	INTCON, INTE
	BCF	INTCON,	INTF
	
	CALL	getDataIn
	MOVF	id, W
	SUBWF	dataIn
	BTFSS	STATUS, Z
	RETURN
	
	BTFSS	PORTB, RA5        ;int_type
	CALL	startReceiveData  ;int_type 0
	CALL	updateDisplay	  ;int_type 1
	RETURN
	
startReceiveData:
	MOVLF	0x00, i
	MOVFF	t0, TMR0
	BSF	INTCON, T0IE
	RETURN

receiveData:
	BCF	INTCON, T0IE
	BCF	INTCON, T0IF
	CALL	getDataIn
	ASI	dataAddr, i
	MOVFF   dataIn, INDF
	
	MOVLW	0x05
	SUBWF	i
	BTFSC	STATUS, Z
	GOTO	equal5
	GOTO	diff5
equal5:
	BSF	INTCON, INTE
	RETURN
diff5:
	INCF	i
	MOVFF	t0, TMR0
	BSF	INTCON, T0IE
	RETURN
	
updateDisplay:
	MOVLW	0x05, i
loop2:
	ASI	dataReceivedAddr, i
	MOVFF   INDF, aux
	ASI	dataAddr, i
	MOVFF   aux, INDF
	DECFSZ	i
	GOTO	loop2
	BSF	INTCON, INTE
	RETURN
	
;----------------ROUTINES----------------
getCounterValue:
	ADDWF	PCL, pos
	RETLW	b'01011110'
	RETLW	b'01011101'
	RETLW	b'01011011'
	RETLW	b'01010111'
	RETLW	b'01001111'
	RETLW	b'00011111'
	
counterRoutine:
	CALL	getCounterValue
	MOVWF	counterOutput
	MOVF	counterMask1, W
	ANDWF	counterOutput, F
	MOVF	counterMask2, W
	ANDWF	PORTA, W
	IORWF	counterOutput, W
	MOVWF	PORTA
	RETURN
	
displayData:
	ASI	dataAddr, pos
	MOVFF	INDF, dataOut
	MOVF	dataOutMask1, W
	ANDWF	dataOut, F
	MOVF	dataOutMask2, W
	ANDWF	PORTB, W
	IORWF	dataOut, W
	MOVWF	PORTB
	RETURN
	
;--------------------SETUP--------------------
clearData:
	MOVLF	0x0C, i
loop1:
	DECF	i
	ASI	dataAddr, i
	INCF	i
	MOVLF	0x00, INDF
	DECFSZ	i
	GOTO	loop1
	RETURN

setup:
	MOVLF	0x00, id    ;0x00 -> Slave1 
			    ;0x0F -> Slave2
	MOVLF	0x05, pos
	MOVLF	d'241', t0
	MOVLF	b'01011111', counterMask1
	MOVLF	b'10100000', counterMask2
	MOVLF	b'00011110', dataOutMask1
	MOVLF	b'11100001', dataOutMask2
	MOVLF	b'10000000', dataInMask1
	MOVLF	b'11100000', dataInMask2
	MOVLF	b'10100000', TRISA
	MOVLF	b'11100001', TRISB
	MOVLF	b'10010000', INTCON
	MOVLF	b'11010011', OPTION_REG
	
	BANKSEL	PCON
	BCF	PCON, OSCF
	BANKSEL	PORTA
	CLRF	PORTA
	CLRF	PORTB
	
	CALL	clearData
	
;----------------MAIN_LOOP----------------
mainLoop:
	CALL	counterRoutine
	CALL	displayData
	DECFSZ	pos
	GOTO	mainLoop
	MOVLF	0x05, pos
	GOTO	mainLoop
	
	END
