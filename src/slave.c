/*
 * File:   slave.c
 * Author: matheustenorio
 *
 * Created on 13 de Novembro de 2016, 15:25
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

#define ID              0x01 // 0x01 slave2 | 0x00 slave1
#define COUNTER_MASK    0b10100000
#define DATA_OUT_MASK1  0b00011110
#define DATA_OUT_MASK2  0b11100001
#define DATA_IN_MASK1   0b10000000
#define DATA_IN_MASK2   0b11100000
#define inverter(data) ((data&0x02)<<3)|((data&0x04)<<1)|((data&0x08)>>1)|((data&0x10)>>3)

//----------GLOBAL_VARIABLES---------
char counter[6] = 
{   
    0b00011111,
    0b01011011,
    0b01011101,
    0b01011110,
    0b01010111,
    0b01001111
};
char dataReceived[6] = {0x00};
char dataOut[6] = {0x08, 0x08, 0x08, 0x08, 0x08, 0x08};
char receiveCounter = 0x00;

//-------------ROUTINES--------------
char getDataIn() {
    char dataIn = 0x00;
    
    dataIn = ((PORTB & DATA_IN_MASK2) >> 1);
    dataIn = dataIn | (PORTA & DATA_IN_MASK1);
    
    return dataIn >> 4;
}

void receiveData() {
    INTCONbits.INTE = 0;
    INTCONbits.INTF = 0;
    
    if (receiveCounter >= 6) {
        receiveCounter = 0;
    }
    
    dataOut[receiveCounter] = getDataIn();
    receiveCounter++;
    
    INTCONbits.INTE = 1;
}

//------------INTERRUPTS-------------

void interrupt int_handler() {
    if (INTCONbits.INTF && (PORTAbits.RA5 == ID)) {
        receiveData();
    }
}

void delay()
{
    for (int p=0 ; p < 50 ; p++)
    {
        p = p + 0 ;
    }
}

char hash_func(char i)
{
    char j=0;
    if(i == 0)
        j = 1;
    if(i == 1)
        j = 0;
    if(i == 2)
        j = 3;
    if(i == 3)
        j = 4;
    if(i == 4)
        j = 5;
    if(i == 5)
        j = 2;
    
    return j;
}

void main(void) {
    //setup
    TRISA      = 0b10100000;
    TRISB      = 0b11100001;
    INTCON     = 0b10010000;
    OPTION_REG = 0b11010000;
    PCONbits.OSCF = 1;
    
    PORTA = 0x00;
    PORTB = 0x00;
    
    char i = 0;
    char j;
    while (1) {
        if (i >= 6)
            i = 0;
        
        j = i;
        //counter routine
        PORTA = (PORTA & COUNTER_MASK) | counter[i];
        
        delay();
        
        //display data
        PORTB = (PORTB & DATA_OUT_MASK2) | ( inverter(dataOut[j] << 1) & DATA_OUT_MASK1);
            
        ++i;
    }
}
