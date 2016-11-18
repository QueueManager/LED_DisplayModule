/*
 * File:   master.c
 * Author: matheustenorio
 *
 * Created on 13 de Novembro de 2016, 09:36
 */

// PIC16F628A Configuration Bit Settings

// 'C' source line config statements

// CONFIG
#pragma config FOSC = INTOSCIO  // Oscillator Selection bits (INTOSC oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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

#define SET_IP   "AT+CIPSTA_DEF=\"192.168.0.103\"\r\n#"
#define RESET    "AT+RST\r\n#"
#define STA_MODE "AT+CWMODE=1\r\n#"
#define CONNECT  "AT+CWJAP_CUR=\"dlink\",\"\"\r\n#"
#define MUX      "AT+CIPMUX=1\r\n#"
#define SERVER   "AT+CIPSERVER=1,1000\r\n#"
#define TX_TIME  50000 //50ms

#define SLAVE1          0x00
#define SLAVE2          0x01
#define HALF_HOLD_TIME  30000   //30ms
#define MASK1           0b00001111
#define MASK2           0b11110000

//----------GLOBAL_VARIABLES---------
char dataSlave1[6] = {0x00};
char dataSlave2[3][6];
char dataInCounter = 0;
char j = 0;

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
    
    /*
    dataIn[0] = guichet / 10;
    dataIn[1] = guichet % 10;
    dataIn[2] = password / 1000;
    dataIn[3] = (password % 1000) / 100;
    dataIn[4] = ((password % 1000) % 100) / 10;
    dataIn[5] = (((password % 1000) % 100) % 10);*/
    
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
    char three = data & 0b00001110; 
    char one   = (data & 0b00000001) << 7;
    char dataOut = MASK1 & (three|one);
    char w = MASK2 & PORTA;
    
    PORTA = dataOut | w;
}

void delaySlave(char time)
{
    char total = time*50;
    for (int p=0 ; p < total ; p++)
    {
        p = p + 0 ;
    }
}

void sendDataToSlave(char id, char* data) {
    PORTBbits.RB4 = id;
    for (int i = 0; i < 6; ++i) {
        PORTBbits.RB3 = 0;
        updatePortA(data[i]);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        PORTBbits.RB3 = 1;
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
        delaySlave(50);
    }
    PORTBbits.RB3 = 0;
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
    
    PIE1bits.RCIE = 1;
    INTCONbits.INTE = 1;
}

void handleBtnPressed(int j) {
    PIE1bits.RCIE = 0;
    PIR1bits.RCIF = 0;
    INTCONbits.INTE = 0;
    INTCONbits.INTF = 0;
    
    //dataSlave1[0] = 0x00;
    //dataSlave1[1] = 0x02;
    //dataSlave1[2] = 0x01;
    //dataSlave1[3] = 0x04;
    //dataSlave1[4] = 0x07;
    //dataSlave1[5] = 0x09;

    for (int i = 0; i < 6; i++) {
        dataSlave2[j][i] = ((j*2+i)%4)*2+1;
    }
    
    sendDataToSlave(SLAVE2, dataSlave2[j]);
    /*delaySlave(50);
    delaySlave(50);
    delaySlave(50);
    delaySlave(50);
    delaySlave(50);
    
    delaySlave(50);
    delaySlave(50);
    delaySlave(50);
    delaySlave(50);
    delaySlave(50);*/
    //sendDataToSlave(SLAVE1, dataSlave1);
    
    PIE1bits.RCIE = 1;
    INTCONbits.INTE = 1;
}

void interrupt int_handler() {
    if (PIR1bits.RCIF) 
        handleWifiData();
    else if (INTCONbits.INTF) {
        j = (j+1)%3;
        delaySlave(50);
        delaySlave(50);
        handleBtnPressed(j);
    }
}

//------------------MAIN----------------
void main(void) {
    TRISA      = 0b01100001;
    TRISB      = 0b11100011;
    INTCON     = 0b11010000;
    PIE1       = 0b00110000;
    OPTION_REG = 0b10010000;
    PCONbits.OSCF = 1;

    while (1){}
}
