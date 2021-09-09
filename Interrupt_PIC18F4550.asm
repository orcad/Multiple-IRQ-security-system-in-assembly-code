
; *************************************************************
; *** Interrupt assisted Switching using PIC18F4550
; *** This code is written in Assembly and is assembled 
; *** by using Microchip mpasm, MPLABX and ICD3 programmer.
; *** Designed by Engineer: Firas Faham
; *** Development board used: LAB-XUSB from ME Labs
; *** September 6, 2021  Rev0.0
; *************************************************************
; 
; Code Operation 
; SW13 is ON Switch / SW14 is OFF Switch - refer to LAB-XUSB Schematic.
; The code sets up the IRQ and pins then go to endless loop waiting 
; for the ON or OFF switch to be pressed. Once pressed then LED1
; on PORT RD0 turns ON, Also Auxulary pin RC0 on PORT C turns ON.
; ON Switch turns ON RD0 and OFF Switch turns OFF RD0.
; ********************************************************

; File = Interrupt_PIC18F4550.asm
; Using PIC18F4550

#include "p18f4550.inc"

; CONFIG1L
  CONFIG  PLLDIV = 1            ; PLL Prescaler Selection bits (No prescale (4 MHz oscillator input drives PLL directly))
  CONFIG  CPUDIV = OSC1_PLL2    ; System Clock Postscaler Selection bits ([Primary Oscillator Src: /1][96 MHz PLL Src: /2])
  CONFIG  USBDIV = 1            ; USB Clock Selection bit (used in Full-Speed USB mode only; UCFG:FSEN = 1) (USB clock source comes directly from the primary oscillator block with no postscale)

; CONFIG1H
  CONFIG  FOSC = INTOSC_HS      ; Oscillator Selection bits (Internal oscillator, HS oscillator used by USB (INTHS))
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

; CONFIG2L
  CONFIG  PWRT = OFF            ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  BOR = ON              ; Brown-out Reset Enable bits (Brown-out Reset enabled in hardware only (SBOREN is disabled))
  CONFIG  BORV = 3              ; Brown-out Reset Voltage bits (Minimum setting 2.05V)
  CONFIG  VREGEN = OFF          ; USB Voltage Regulator Enable bit (USB voltage regulator disabled)

; CONFIG2H
  CONFIG  WDT = OFF             ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
  CONFIG  WDTPS = 32768         ; Watchdog Timer Postscale Select bits (1:32768)

; CONFIG3H
  CONFIG  CCP2MX = ON           ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
  CONFIG  PBADEN = ON           ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as analog input channels on Reset)
  CONFIG  LPT1OSC = OFF         ; Low-Power Timer 1 Oscillator Enable bit (Timer1 configured for higher power operation)
  CONFIG  MCLRE = ON            ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)

; CONFIG4L
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  LVP = OFF             ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
  CONFIG  ICPRT = OFF           ; Dedicated In-Circuit Debug/Programming Port (ICPORT) Enable bit (ICPORT disabled)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
   
; CONFIG5L
  CONFIG  CP0 = OFF             ; Code Protection bit (Block 0 (000800-001FFFh) is not code-protected)
  CONFIG  CP1 = OFF             ; Code Protection bit (Block 1 (002000-003FFFh) is not code-protected)
  CONFIG  CP2 = OFF             ; Code Protection bit (Block 2 (004000-005FFFh) is not code-protected)
  CONFIG  CP3 = OFF             ; Code Protection bit (Block 3 (006000-007FFFh) is not code-protected)

; CONFIG5H
  CONFIG  CPB = OFF             ; Boot Block Code Protection bit (Boot block (000000-0007FFh) is not code-protected)
  CONFIG  CPD = OFF             ; Data EEPROM Code Protection bit (Data EEPROM is not code-protected)

; CONFIG6L
  CONFIG  WRT0 = OFF            ; Write Protection bit (Block 0 (000800-001FFFh) is not write-protected)
  CONFIG  WRT1 = OFF            ; Write Protection bit (Block 1 (002000-003FFFh) is not write-protected)
  CONFIG  WRT2 = OFF            ; Write Protection bit (Block 2 (004000-005FFFh) is not write-protected)
  CONFIG  WRT3 = OFF            ; Write Protection bit (Block 3 (006000-007FFFh) is not write-protected)

; CONFIG6H
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) are not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot block (000000-0007FFh) is not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM is not write-protected)

; CONFIG7L
  CONFIG  EBTR0 = OFF           ; Table Read Protection bit (Block 0 (000800-001FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Table Read Protection bit (Block 1 (002000-003FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR2 = OFF           ; Table Read Protection bit (Block 2 (004000-005FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR3 = OFF           ; Table Read Protection bit (Block 3 (006000-007FFFh) is not protected from table reads executed in other blocks)

; CONFIG7H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protection bit (Boot block (000000-0007FFh) is not protected from table reads executed in other blocks)

    ;Config settings
    ;errorlevel -302                 ;surpress the 'not in bank0' warning


; **********************************************
; On POWER UP start at address 0
ORG 0
GOTO MAIN

; Interrupt vector starts here at address 0x08
ORG 0x08

; RB4 is ON Switch and RB5 is OFF Switch.
BTFSS PORTB,4   ; SW13 ON SW pressed - Has the RB IRQ ocured on Port B?
GOTO isr_rb_ON

BTFSS PORTB,5   ; SW14 OFF SW pressed - Has the RB IRQ ocured on Port B?
GOTO clear_LED

RETFIE


; ************** Start from Power ON ****************
MAIN
org 2AH

; Setup the Oscillator
; The osciilator speed is important for delays between the 
; current IRQ and the next IRQ. Also it help reduce Switch bouncing.
;bit 6-4 IRCF2:IRCF0: Internal Oscillator Frequency Select bits
;111 = 8 MHz (INTOSC drives clock directly)
;110 = 4 MHz
;101 = 2 MHz
;100 = 1 MHz(3)
;011 = 500 kHz
;010 = 250 kHz
;001 = 125 kHz
;000 = 31 kHz (from either INTOSC/256 or INTRC directly)(2);;

   ;movlw      b'00101000'     ;set cpu clock speed of 250 KHz
   ;movlw      b'01111000'      ;set cpu clock speed of 8 MHz
   ;movlw      b'01101000'      ;set cpu clock speed of 4 MHz
	movlw      b'01001000'      ;set cpu clock speed of 4 MHz
    movwf      OSCCON


; Make PORT B as Digital IO pins / no Analog pins
MOVLW b'00001110' ; Set RB<4:0> as 0Eh or 0x0E
MOVWF ADCON1 ; digital I/O pin

BCF ADCON0,ADON  ; Disable AD converter

; Make RB4 and RB5 Input for KBI0 and KBI1 Interrupt
; See schematic of LAB-XUSB Development board from ME Labs
BSF TRISB, 4   ; SW13 RB4 is now Input for KBI0 Interrupt On Change
BSF TRISB, 5   ; SW14 RB5 is now Input for KBI1 Interrupt On Change

; This section will prevent Switch inputs from interferrence
; SetUp RB0, RB1 and RB2 OUTPUT High
BCF TRISB, 0 ; Make pins OUTPUT
BCF TRISB, 1
BCF TRISB, 2

BCF PORTB, 0 ; Clear those Output pins.
BCF PORTB, 1
BCF PORTB, 2

; Setup Pull Up resisotrs for PORT B
BCF INTCON2, RBPU ; Enable all PULL UPs on PORB pins 

; Setup RB3 as Outpout Low for IRQ Switches 
BCF TRISB, 3  ; Make RB3 Output pin
BCF PORTB, 3  ; Make it LOW

; Setup Port D0 as main Output ******************
BCF TRISD, 0   ; RD0 > LED Output
BCF PORTD, 0   ; Initialize OFF RD0

; Setup Port C0 as Auxulary Output ******************
BCF TRISC, 0   ; RC0 > LED Output
BCF PORTC, 0   ; Initialize OFF RC0

; Enable Interrupts ******************
BCF INTCON, RBIF ; Clear IF on RB pins
BSF INTCON, RBIE ; Enable Interrupt On Change for RB port
BSF INTCON, GIE ; Enable Global Interrupt

BCF PORTD, 0  ; Keep
BCF PORTC, 0  ; Keep

; ****************  main IRQ loop ****************
xyz: ; Loop here forever while waiting for PORTB Interrupt-on-Change
; Place your system code here
; this code will be interrupted by the change-on-pin IRQ (two levels of IRQ)
; of the PIC18 chip, or any other compatible PIC chip.
nop
BRA xyz

; *************** ON *** Interrupt-On-Change ****************
ORG 200h

isr_rb_ON

BCF INTCON, RBIF
BCF INTCON, INT0IF
BCF INTCON3, INT1IF

BSF PORTD, 0
BSF PORTC, 0

; Create independent delay function
; or use in seperate routine / call fucntion.
DelayON1 db 0xAB  ; Inner Delay loop
DelayON2 db 0x0A  ; Outer delay loop

     isr_rb_ON2
     decfsz     DelayON1,f        ; Wait for a while.
     bra        isr_rb_ON2        ; The Inner loop 
     ;decfsz     DelayON2,f        ; The outer loop 
     ;bra        isr_rb_ON2        ; Escape here

RETFIE
 
; *************** OFF *** Interrupt-On-Change ****************
ORG 400h

clear_LED

BCF INTCON, RBIF
BCF INTCON, INT0IF
BCF INTCON3, INT1IF

BCF PORTD, 0
BCF PORTC, 0

; Create independent delay function
; or use in seperate routine / call fucntion.
DelayOFF1 db 0xAB  ; Inner Delay loop
DelayOFF2 db 0x0A  ; Outer delay loop
     clear_LED2
     decfsz     DelayOFF1,f       ; Wait for a while.
     bra        clear_LED2        ; The Inner loop 
     ;decfsz     DelayOFF2,f       ; The outer loop 
     ;bra        clear_LED2        ; Escape here

RETFIE

end

; end 