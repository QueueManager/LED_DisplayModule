#include "p16f628a.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
	CBLOCK	0x20
	    i, targetID, dataOut
	    flags, isEqual
	    slave1, slave2
	    timeParam, sendTime, holdTime, buzzerTime
	    dataOutMask1, dataOutMask2
	    dataReceivedAddr:6, slave1DataAddr:6
	    dataOutAddr:6
	ENDC
	
	ORG	0x00
	GOTO	setup
	
	ORG	0x04
	BTFSC	PIR1, RCIF
	CALL	handleWifiData
	BTFSC	INTCON, INTF
	CALL	handleBtnPressed
	RETFIE
	
;----------------INT HANDLERS----------------	
handleWifiData:
	CALL	getWifiData
	
	CALL	answerWifi
	
	CALL	checkDiffWithSlave1
	
	BTFSS	flags, isEqual
	GOTO	send
	GOTO	update
	
send:
	MOVLF	slave1, targetID
	;dataOutAddr = dataReceivedAddr
	CALL	sendDataToSlave
	
	MOVLF	slave2, targetID
	;dataOutAddr = slave1DataAddr
	CALL	sendDataToSlave
update:
	MOVLF	slave1, targetID
	CALL	updateDisplay
	
	MOVLF	slave2, targetID
	CALL	updateDisplay
	
	CALL	triggerBuzzer
	
	RETURN
	
handleBtnPressed:
	MOVLF	slave1, targetID
	CALL	setDataTest1
	CALL	sendDataToSlave
	
	MOVLF	slave2, targetID
	CALL	setDataTest2
	CALL	sendDataToSlave
	
	MOVLF	slave1, targetID
	CALL	updateDisplay
	
	MOVLF	slave2, targetID
	CALL	updateDisplay
	
	CALL	triggerBuzzer
	
	RETURN
;----------------ROUTINES----------------
delay_ms:
	;(timeParam)
	RETURN
	
setDataTest1:
    
	RETURN

setDataTest2:
    
	RETURN
	
checkDiffWithSlave1:
    
	RETURN
	
getWifiData:
	;copy data from wifi to dataReceivedAddr
	RETURN

answerWifi:
    
	RETURN
	
sendDataToSlave:
	;(targetID, dataOutAddr)
	RETURN
	
updateDisplay:
	;(targetID)
	RETURN
	
triggerBuzzer:
    
	RETURN
;--------------------SETUP--------------------
clearData:
	MOVLF	0x00, i
loop1:
	ASI	dataReceivedAddr, i
	INCF	i
	MOVLF	0x00, INDF
	MOVLW	0x12
	SUBWF	i, W
	BTFSS	STATUS, Z
	GOTO	loop1
	RETURN

setup:
	MOVLF	0x00, slave1
	MOVLF	0x0F, slave2
	MOVLF	0x00, flags
	MOVLF	0x00, isEqual
	MOVLF	d'000', sendTime  ;1ms
	MOVLF	d'000', holdTime  ;3ms
	MOVLF	d'000', buzzerTime  ;2s
	MOVLF	b'00011111', dataOutMask1
	MOVLF	b'11100001', dataOutMask2
	MOVLF	b'11100000', TRISA
	MOVLF	b'11100011', TRISB
	MOVLF	b'11000000', INTCON
	MOVLF	b'00110000', PIE1
	MOVLF	b'11010011', OPTION_REG
	
	BANKSEL	PCON
	BCF	PCON, OSCF
	BANKSEL	PORTA
	CLRF	PORTA
	CLRF	PORTB
	
	CALL	clearData
	
;----------------MAIN_LOOP----------------
	GOTO	$
	
	END
