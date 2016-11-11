#include "p16F628A.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
	CBLOCK	0x20
	    i, aux, pos, id
	    receiveTime, waitTime
	    dataAddr:6, dataReceivedAddr:6
	    counterMask1, counterMask2
	    dataOutMask1, dataOutMask2
	    dataInMask1, dataInMask2
	    counterOutput, dataOut, dataIn
	    receiveCounter
	    flags, sync, receive, wait
	ENDC
	
	ORG	0x00
	GOTO	setup
	
	ORG	0x04
	BTFSC	INTCON, INTF
	CALL	startSyncDelay
	BTFSC	INTCON, T0IF
	CALL	handleTimeOut
	RETFIE
	
;----------------INT HANDLERS----------------
getDataIn:
	MOVLF	0x00, dataIn
	MOVF	dataInMask1, W
	ANDWF	PORTA, W
	MOVWF	dataIn
	MOVF	dataInMask2, W
	ANDWF	PORTB, W
	MOVWF	aux
	BCF	STATUS, C
	RRF	aux, F
	MOVF	aux, W
	IORWF	dataIn, F
	MOVLF	0x04, i
loop3:	
	BCF	STATUS, C
	RRF	dataIn, F
	DECFSZ	i
	GOTO	loop3
	RETURN
	

startSyncDelay:
	BCF	INTCON, INTE
	BCF	INTCON,	INTF
	
	CLRF	flags
	CLRF	receiveCounter
	BSF	flags, sync
	MOVFF	receiveTime, TMR0
	BSF	INTCON, T0IE
	RETURN
	
;----------------TIMEOUT----------------
handleTimeOut:
	BCF	INTCON, T0IE
	BCF	INTCON, T0IF
    
	BTFSC	flags, sync
	GOTO	receiveHandler
	BTFSC	flags, receive
	GOTO	waitHandler
	BTFSC	flags, wait
	GOTO	receiveHandler
	RETURN
	
waitHandler:
	CLRF	flags
	BSF	flags, wait
	
	MOVFF	waitTime, TMR0
	BSF	INTCON, T0IE
	RETURN
	
receiveHandler:
	CLRF	flags
	BSF	flags, receive
	
	;choose type of interrupt
	BTFSC	PORTB, RA5      ;int_type
	GOTO	updateDisplay	;int_type = 1
	GOTO	receiveData	;int_type = 0
	
receiveData:
	;check end of receive data
	MOVLW	0x07
	SUBWF	receiveCounter, W
	BTFSS	STATUS, Z
	GOTO	endReceive
	GOTO	continue
	
endReceive:
	BSF	INTCON, INTE
	RETURN
	
continue:
	CALL	getDataIn
	
	MOVLW	0x00
	SUBWF	receiveCounter
	BTFSC	STATUS, Z
	GOTO	first
	GOTO	other
first:
	MOVF	id, W
	SUBWF	dataIn
	BTFSS	STATUS, Z
	RETURN
	
	INCF	receiveCounter
	MOVFF	receiveTime, TMR0
	BSF	INTCON, T0IE
	RETURN
other:
	ASI	dataAddr, receiveCounter
	MOVFF   dataIn, INDF
	INCF	receiveCounter
	MOVFF	receiveTime, TMR0
	BSF	INTCON, T0IE
	RETURN
	
updateDisplay:
	CALL	getDataIn
	MOVF	id, W
	SUBWF	dataIn
	BTFSS	STATUS, Z
	RETURN
    
	MOVLF	0x06, i
loop2:
	DECF	i
	ASI	dataReceivedAddr, i
	MOVFF   INDF, aux
	ASI	dataAddr, i
	INCF	i
	MOVFF   aux, INDF
	DECFSZ	i
	GOTO	loop2
	BSF	INTCON, INTE
	RETURN
	
;----------------ROUTINES----------------
getCounterValue:
	MOVF	pos, W
	ADDWF	PCL, F
	NOP
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
	DECF	pos
	ASI	dataAddr, pos
	INCF	pos
	MOVFF	INDF, dataOut
	
	MOVLW	b'00011100'
	MOVWF	dataOut
	
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
	MOVLF	0x06, pos
	MOVLF	0x00, flags
	MOVLF	0x00, sync
	MOVLF	0x01, receive
	MOVLF	0x02, wait
	MOVLF	d'000', receiveTime ;1ms
	MOVLF	d'000', waitTime    ;3ms
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
	MOVLF	0x06, pos
	GOTO	mainLoop
	
	END
	
