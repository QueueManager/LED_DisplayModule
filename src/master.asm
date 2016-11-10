#include "p16f628a.inc"
#include "utils.inc"
    
; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
	CBLOCK	0x20
	    i
	    holdTime, buzzerTime
	    dataReceivedAddr:6, slave1Data:6
	    dataOutMask1, dataOutMask2
	    dataOut
	ENDC
	
	ORG	0x00
	GOTO	setup
	
	ORG	0x04
	BTFSC	PIR1, RCIF //temp
	CALL	handleWifiData
	BTFSC	INTCON, INTF
	CALL	handleBtnPressed
	RETFIE
	
;----------------INT HANDLERS----------------	
handleWifiData:
    
	RETURN

handleBtnPressed:
    
	RETURN
;----------------ROUTINES----------------
getWifiData:
	//copy data from wifi to dataReceivedAddr
	RETURN

answerWifi:
    
	RETURN
	
sendDataToSlaves:
    
	RETURN
	
updateDisplays:
    
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
	MOVLW	0x0C
	SUBWF	i, W
	BTFSS	STATUS, Z
	GOTO	loop1
	RETURN

setup:
	MOVLF	d'000', holdTime  ;XXms
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
