#include "p16f628a.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
	CBLOCK	0x20
	    i, aux, targetID, dataOut
	    flags, isEqual
	    slave1, slave2
	    sendTime, holdTime, buzzerTime
	    dataOutMask, sendCounter
	    dataReceivedAddr:6, slave1DataAddr:6
	    dataOutAddr:6
	    timeParam, addr1Param, addr2Param
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
	MOVFF	dataOutAddr, addr1Param
	MOVFF	dataReceivedAddr, addr2Param
	CALL	copyArray
	
	CALL	sendDataToSlave
	
	MOVLF	slave2, targetID
	;dataOutAddr = slave1DataAddr
	MOVFF	dataOutAddr, addr1Param
	MOVFF	slave1DataAddr, addr2Param
	CALL	copyArray
	
	CALL	sendDataToSlave
update:
	MOVLF	slave1, targetID
	CALL	updateDisplay
	
	MOVLF	slave2, targetID
	CALL	updateDisplay
	
	CALL	triggerBuzzer
	
	RETURN
	
copyArray:
	;(addr1Param, addr2Param)
	;addr1Param = addr2Param
	MOVLF	0x00, i
loop4:
	ASI	addr2Param, i
	MOVFF	INDF, aux
	ASI	addr1Param, i
	MOVFF	aux, INDF
	INCF	i
	MOVLW	0x06
	SUBWF	i, W
	BTFSS	STATUS, Z
	GOTO	loop4
	RETURN
	
handleBtnPressed:
	MOVFF	slave1, targetID
	CALL	setDataTest1
	CALL	sendDataToSlave
	
	MOVFF	slave2, targetID
	CALL	setDataTest2
	CALL	sendDataToSlave
	
	MOVFF	slave1, targetID
	CALL	updateDisplay
	
	MOVFF	slave2, targetID
	CALL	updateDisplay
	
	CALL	triggerBuzzer
	
	RETURN
;----------------ROUTINES----------------
;-----------------UTILS------------------
buzzerDelay:
	MOVLF	d'255', i
	MOVLF	d'130', buzzerTime ;2s
loop1:
	DECFSZ	i
	GOTO	loop1
	DECFSZ	buzzerTime
	GOTO	loop1
	RETURN

delay_ms:
	;(timeParam)
	DECFSZ	timeParam
	GOTO	delay_ms
	RETURN
	
setDataTest1:
	MOVLF	0x00, i
	ASI	dataOutAddr, i
	MOVLF	0x00, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x01, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x01, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x07, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x03, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x09, INDF
	RETURN

setDataTest2:
	MOVLF	0x00, i
	ASI	dataOutAddr, i
	MOVLF	0x00, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x02, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x00, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x06, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x02, INDF
	INCF	i
	ASI	dataOutAddr, i
	MOVLF	0x05, INDF
	RETURN
	
checkDiffWithSlave1:
	MOVLF	0x06, i
loop2:
	DECF	i
	ASI	dataReceivedAddr, i
	MOVFF	INDF, aux
	ASI	slave1DataAddr, i
	INCF	i
	MOVF	INDF, W
	SUBWF	aux, W
	BTFSS	STATUS, Z
	GOTO	diff1
	GOTO	equal1
equal1:
	DECFSZ	i
	GOTO	loop2
	BSF	flags, isEqual
	RETURN
diff1:
	BCF	flags, isEqual
	RETURN
	
;-------------------WIFI-------------------
getWifiData:
	;copy data from wifi to dataReceivedAddr
	RETURN

answerWifi:
    
	RETURN
;----------------SEND DATA----------------
sendDataToSlave:
	;(targetID, dataOutAddr)
	MOVLF	0x00, sendCounter
loop3:
	CALL	sendData
	MOVFF	sendTime, timeParam
	CALL	delay_ms
	
	;holdData
	MOVFF	holdTime, timeParam
	CALL	delay_ms
	
	INCF	sendCounter
	MOVLW	0x07
	SUBWF	sendCounter, W
	BTFSS	STATUS, Z
	GOTO	loop3
	RETURN
	
sendData:
	MOVLW	0x00
	SUBWF	sendCounter, W
	BTFSC	STATUS, Z
	GOTO	first
	GOTO	others
first:
	MOVFF	targetID, dataOut
	GOTO	final
others:
	DECF	sendCounter
	ASI	dataOutAddr, sendCounter
	INCF	sendCounter
	MOVFF	INDF, dataOut
final:
	MOVF	dataOutMask, W
	ANDWF	PORTA, W
	IORWF	dataOut, F
	MOVFF	dataOut, PORTA
	
	BCF	PORTB, RB4 ;int_type = 0
	BSF	PORTB, RB3 ;int = 1
	RETURN
;----------------UPDATE DISPLAY----------------
updateDisplay:
	;(targetID)
	MOVFF	targetID, dataOut
	
	MOVF	dataOutMask, W
	ANDWF	PORTA, W
	IORWF	dataOut, F
	MOVFF	dataOut, PORTA
	
	BSF	PORTB, RB4 ;int_type = 0
	BSF	PORTB, RB3 ;int = 1
	RETURN
	
triggerBuzzer:
	BSF	PORTA, RA4
	CALL	buzzerDelay
	BCF	PORTA, RA4
	RETURN
;--------------------SETUP--------------------
clearData:
	MOVLF	0x00, i
loop5:
	ASI	dataReceivedAddr, i
	INCF	i
	MOVLF	0x00, INDF
	MOVLW	0x12
	SUBWF	i, W
	BTFSS	STATUS, Z
	GOTO	loop5
	RETURN

setup:
	MOVLF	0x00, slave1
	MOVLF	0x0F, slave2
	MOVLF	0x00, flags
	MOVLF	0x00, isEqual
	MOVLF	d'16', sendTime  ;1ms
	MOVLF	d'47', holdTime  ;3ms
	MOVLF	b'11110001', dataOutMask
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
