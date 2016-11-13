/*
 * File:   master.c
 * Author: matheustenorio
 *
 * Created on 13 de Novembro de 2016, 09:36
 */

// PIC16F628A Configuration Bit Settings

// 'C' source line config statements

// CONFIG
#pragma config FOSC = INTOSCCLK // Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RA5/MCLR/VPP Pin Function Select bit (RA5/MCLR/VPP pin function is digital input, MCLR internally tied to VDD)
#pragma config BOREN = OFF      // Brown-out Detect Enable bit (BOD disabled)
#pragma config LVP = OFF        // Low-Voltage Programming Enable bit (RB4/PGM pin has digital I/O function, HV on MCLR must be used for programming)
#pragma config CPD = OFF        // Data EE Memory Code Protection bit (Data memory code protection off)
#pragma config CP = OFF         // Flash Program Memory Code Protection bit (Code protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>

#define BAUD     "AT+CIOBAUD=9200#"
#define SET_IP   "AT+CIPSTA_DEF=\"192.168.0.103\"#"
#define RESET    "AT+RST#"
#define STA_MODE "AT+CWMODE=1#"
#define CONNECT  "AT+CWJAP=\"dlink\",\"\"#"
#define MUX      "AT+CIPMUX=1#"
#define SERVER   "AT+CIPSERVER=1,1000#"
#define TX_TIME  600 //50ms

#define SLAVE1          0x00
#define SLAVE2          0x0F
#define SEND_DATA_TIME  600   //50ms
#define HOLD_TIME       1800  //150ms
#define BUZZER_TIME     24000 //2s
#define MASK1           0b00001111
#define MASK2           0b11110000

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

void TX_Serial(char* data) {
    int i = 0;
    while (data[i] != '#') {
        while (!PIR1bits.TXIF);
        TXREG = data[i];
        i++;
    }
    _delay(TX_TIME);
}

void setupWifi() {
    TX_Serial(BAUD);
    TX_Serial(SET_IP);
    TX_Serial(RESET);
    TX_Serial(STA_MODE);
    TX_Serial(CONNECT);
    TX_Serial(MUX);
    TX_Serial(SERVER);
}

char* getWifiData() {
    char dataInDirty[3] = {0x01, 0x06, 0x59};
    char dataIn[6];
    
    while (dataInCounter < 3) {
        dataInDirty[dataInCounter] = RX_Serial();
    }

    char guichet = dataInDirty[0];
    long int password = dataInDirty[1] << 8;
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
    char dataOut = MASK1 & data;
    char w = MASK2 & PORTA;
    PORTA = dataOut | w;
}

void sendDataToSlave(char id, char* data) {
    for (int i = 0; i < 7; ++i) {
        _delay(SEND_DATA_TIME);
        if (i == 0) {
            updatePortA(id);
            PORTBbits.RB4 = 0;
            PORTBbits.RB3 = 1;
        }
        else {
            updatePortA(data[i]);
        }
        _delay(HOLD_TIME);
    }
}

void updateDisplay(char id) {
    _delay(SEND_DATA_TIME);
    updatePortA(id);
    PORTBbits.RB4 = 1;
    PORTBbits.RB3 = 1;
    _delay(HOLD_TIME);
}

void triggerBuzzer() {
    PORTAbits.RA4 = 1;
    _delay(BUZZER_TIME);
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
        sendDataToSlave(SLAVE1, dataIn);
        sendDataToSlave(SLAVE2, dataSlave1);
    }
    
    updateDisplay(SLAVE1);
    updateDisplay(SLAVE2);
    
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
    
    sendDataToSlave(SLAVE1, dataSlave1);
    sendDataToSlave(SLAVE2, dataSlave2);
    
    updateDisplay(SLAVE1);
    updateDisplay(SLAVE2);
    
    triggerBuzzer();
    
    PIE1bits.RCIE = 1;
    INTCONbits.INTE = 1;
}

void interrupt int_handler() {
    if (PIR1bits.RCIF) 
        handleWifiData();
    if (INTCONbits.INTF)
        handleBtnPressed();
}

//------------------MAIN----------------
void main(void) {
    TRISA      = 0b11100000;
    TRISB      = 0b11100011;
    INTCON     = 0b11010000;
    PIE1       = 0b00110000;
    OPTION_REG = 0b10010000;
    PCONbits.OSCF = 0;

    TXSTA      = 0b00100000;
    RCSTA      = 0b10000000;
    
    PORTA      = 0;
    PORTB      = 0;
    
    setupWifi();
    
    while (1);
}
