/*
 * File:   master.c
 * Author: matheustenorio
 *
 * Created on 13 de Novembro de 2016, 09:36
 */

#include <xc.h>

#define _XTAL_FREQ      48000

#define slave1          0x00
#define slave2          0x0F
#define sendDataTime    1
#define holdTime        3
#define buzzerTime      2000
#define mask1           0b00001111
#define mask2           0b11110000


//----------GLOBAL_VARIABLES---------
char dataSlave1[6] = {0x00};
char dataSlave2[6] = {0x00};
char dataInCounter = 0;

//------------------ROUTINES----------------
char RX_Serial() {
    if (RCSTAbits.OERR) {
        //overflow
        RCSTAbits.CREN = 0;
        RCSTAbits.CREN = 1;
    }
    
    if (PIR1bits.RCIF) {
        dataInCounter++;
    }
    
    return RCREG;
}

char* getWifiData() {
    char dataInDirty[3];
    char dataIn[6];
    
    while (dataInCounter < 3) {
        dataInDirty[dataInCounter] = RX_Serial();
    }

    char guichet = dataInDirty[0];
    long int password = dataInDirty[1];
    password = dataInDirty[1] << 4;
    password = password | dataInDirty[2];
    
    dataIn[0] = guichet / 10;
    dataIn[1] = guichet % 10;
    dataIn[2] = password / 1000;
    dataIn[3] = (password % 1000) / 100;
    dataIn[4] = ((password % 1000) % 100) / 10;
    dataIn[5] = (((password % 1000) % 100) % 10);
    
    dataInCounter = 0;
    return dataIn;
}

short isEqual(char* data1, char* data2) {
    for(int i = 0; i < 6; ++i) {
        if (data1[i] != data2[i])
            return 0;
    }
    return 1;
}

void updatePortA(char data) {
    char dataOut = mask1 & data;
    char w = mask2 & PORTA;
    PORTA = dataOut | w;
}

void sendDataToSlave(char id, char* data) {
    for (int i = 0; i < 7; ++i) {
        __delay_ms(sendDataTime);
        if (i == 0) {
            updatePortA(id);
            PORTBbits.RB4 = 0;
            PORTBbits.RB3 = 1;
        }
        else {
            updatePortA(data[i]);
        }
        __delay_ms(holdTime);
    }
}

void updateDisplay(char id) {
    __delay_ms(sendDataTime);
    updatePortA(id);
    PORTBbits.RB4 = 1;
    PORTBbits.RB3 = 1;
    __delay_ms(holdTime);
}

void triggerBuzzer() {
    PORTAbits.RA4 = 1;
    __delay_ms(buzzerTime);
    PORTAbits.RA4 = 0;
}

//------------INTERRUPTS-------------
void handleWifiData() {
    PIE1bits.RCIE = 0;
    PIR1bits.RCIF = 0;
    INTCONbits.INTE = 0;
    INTCONbits.INTF = 0;
    
    char* dataIn = getWifiData();
    
    if (!isEqual(dataIn, dataSlave1)) {
        sendDataToSlave(slave1, dataIn);
        sendDataToSlave(slave2, dataSlave1);
    }
    
    updateDisplay(slave1);
    updateDisplay(slave2);
    
    triggerBuzzer();
    
    PIE1bits.RCIE = 1;
    INTCONbits.INTE = 1;
}

void handleBtnPressed() {
    PIE1bits.RCIE = 0;
    PIR1bits.RCIF = 0;
    INTCONbits.INTE = 0;
    INTCONbits.INTF = 0;
    
    dataSlave1[0] = 0x00;
    dataSlave1[1] = 0x01;
    dataSlave1[2] = 0x01;
    dataSlave1[3] = 0x07;
    dataSlave1[4] = 0x03;
    dataSlave1[5] = 0x09;

    dataSlave2[0] = 0x00;
    dataSlave2[1] = 0x02;
    dataSlave2[2] = 0x00;
    dataSlave2[3] = 0x06;
    dataSlave2[4] = 0x02;
    dataSlave2[5] = 0x05;
    
    updateDisplay(slave1);
    updateDisplay(slave2);
    
    triggerBuzzer();
    
    PIE1bits.RCIE = 1;
    INTCONbits.INTE = 1;
}

void interrupt int_handler() {
    if (PIR1bits.RCIF) 
        handleWifiData();
    else if (INTCONbits.INTF)
        handleBtnPressed();
}

//------------------MAIN----------------
void main(void) {
    TRISA      = 0b11100000;
    TRISB      = 0b11100011;
    INTCON     = 0b11000000;
    PIE1       = 0b00110000;
    OPTION_REG = 0b11010011;
    
    TXSTA      = 0b00000000;
    RCSTA      = 0b00000000;
    
    PORTA      = 0b00000000;
    PORTB      = 0b00000001;
    
    while (1);
}
