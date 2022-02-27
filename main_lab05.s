; Archivo: main_lab05.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR 8 bits INTERRUPCIONES
; Hardware: PUSHBUTTONS Y DISPLAY 7SEG
;
; Creado: 21 feb, 2022
; Última modificación: 23 feb, 2022

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887  

//---------------------------CONFIGURACION WORD1--------------------------------
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

//---------------------------CONFIGURACION WORD2--------------------------------
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

BINC EQU 0
BDEC EQU 1
  
//------------------------------------MACROS------------------------------------ 
  RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0		; 
    MOVLW   TMR_VAR		;
    MOVWF   TMR0		; 
    BCF	    T0IF		; 
    ENDM
 
//--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
  
PSECT udata_bank0
    valor:		DS 1	;
    bandera:		DS 1	; 
    nibbles:		DS 2	; 
    display:		DS 2	;
    display2:		DS 1	;
    num:		DS 1	;
    centenas:		DS 1	;
    decenas:		DS 1	;
    unidades:		DS 1	;
    cont:		DS 2	;
  
 //-----------------------------Vector reset------------------------------------
 PSECT resVect, class = CODE, abs, delta = 2;
 ORG 00h			; Posición 0000h RESET
 resetVec:			; Etiqueta para el vector de reset
    PAGESEL main
    goto main
  
 PSECT intVect, class = CODE, abs, delta = 2, abs
 ORG 04h			; Posición de la interrupción
 
//--------------------------VECTOR INTERRUPCIONES------------------------------- 
PUSH:
    MOVWF   W_TEMP		; COLOCAR FALOR DEL REGISTRO W EN VARIABLE TEMPORAL
    SWAPF   STATUS, W		; INTERCAMBIAR STATUS CON REGISTRO W
    MOVWF   STATUS_TEMP		; CARGAR VALOR REGISTRO W A VARAIBLE TEMPORAL
    
ISR: 
    BTFSC   RBIF		; INT PORTB, SI=1 NO=0
    CALL    INT_IOCRB		; SI -> CORRER SUBRUTINA DE INTERRUPCIÓN
    
    BTFSC   T0IF
    CALL    INT_TMR0
    
POP:
    SWAPF   STATUS_TEMP, W	; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS		; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE			

PSECT code, delta=2, abs
ORG 100h			; posición 100h para el codigo    
    
//----------------------------INT SUBRUTINAS------------------------------------
INT_IOCRB:			; SUBRUTINA DE INTERRUPCIÓN EN PORTB
    BANKSEL PORTA		; SELECCIONAR BANCO 0
    BTFSS   PORTB, BINC		; REVISAR SI EL BIT DEL PRIMER BOTON EN RB0 HA CAMBIADO A 0
    INCF    PORTD		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) INCREMENTAR CUENTA EN PORTA
    BTFSS   PORTB, BDEC		; REVISAR SI EL BIT DEL SEGUNDO BOTON EN RB1 HA CAMBIADO A 0
    DECF    PORTD		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) DISMINUIR LA CUENTA EN PORTA
    BCF	    RBIF		; LIMPIAR LA BANDERA DE PORTB
    RETURN 

INT_TMR0:
    RESET_TMR0 178		; 
    RETURN    
    
//-----------------------------MAIN CONFIG--------------------------------------
main:
    CALL    IO_CONFIG		; INICIAR CONFIGURACION DE INPUTS/OUTPUTS
    CALL    IOCRB_CONFIG	; INICAR CONFIGURACIÓN DE INTERRUPT ON CHANGE PARA PORTB
    CALL    CLK_CONFIG
    CALL    TMR0_CONFIG
    CALL    INT_CONFIG		; INICIAR CONFIGURACIÓN DE INTERRUPCIONES
    BANKSEL PORTA
    
loop:				; LOOP DE CODIGO GENERICO PARA REALIZAR MIENTRAS NO HAY INTERRUPCION
    MOVF PORTD, W
    MOVWF valor
    CALL DEC_SPLITTER
    GOTO loop
    
//------------------------------SUBRUTINAS--------------------------------------  
IO_CONFIG:			; CONFIGURACION DE PUERTOS
    BANKSEL ANSEL		; SELECCIONAR BANCO 3 PARA ANSEL
    CLRF ANSEL			; PORTA COMO DIGITAL
    CLRF ANSELH			; PORTB COMO DIGITAL
    
    BANKSEL TRISA		; SELECIONAR BANCO 1 PARA TRIS
    BSF TRISB, BINC		; DEFINIR PIN 0 PORTB COMO ENTRADA
    BSF TRISB, BDEC		; DEFINIR PIN 1 PORTB COMO ENTRADA
    CLRF TRISA			; DEFINIR PORTA COMO SALIDA
    CLRF TRISC			; DEFINIR PORTC COMO SALIDA
    CLRF TRISE
    MOVLW 0XC0			;
    MOVWF TRISD			;
    
    BCF	    OPTION_REG, 7	; LIMPIAR RBPU PARA DESBLOQUEAR EL MODO PULL-UP EN PORTB
    BSF	    WPUB, BINC		; SETEAR WPUB PARA ATVICAR EL PIN 0 DEL PORTB COMO WEAK PULL-UP
    BSF	    WPUB, BDEC		; SETEAR WPUB PARA ACTIVAR EL PIN 1 DEL PORTB COMO WEAK PULL-UP
    
    BANKSEL PORTA		; SELECCIONAR BANCO 0 PARA PORT
    CLRF PORTA			; LIMPIAR VALORES EN PORTA
    CLRF PORTC			;
    CLRF PORTD			;
    CLRF PORTE
    RETURN
    
IOCRB_CONFIG:			; CONFIGURACION INTERRUPT ON CHANGE
    BANKSEL IOCB		; SELECCIONAR BANCO DONDE SE ENCUENTRA IOCB
    BSF	    IOCB, BINC		; ACTIVAR IOCB PARA PUSHBOTTON 1
    BSF	    IOCB, BDEC		; ACTIVAR IOCB PARA PUSHBOTTON 2
    
    BANKSEL PORTA		; SELECCIONAR EL BANCO 0
    MOVF    PORTB, W		; CARGAR EL VALOR DEL PORTB A W PARA CORREGIR MISMATCH
    BCF	    RBIF		; LIMPIAR BANDERA DE INTERRUPCIÓN EN PORTB
    RETURN
    
INT_CONFIG:			; CONFIGURACION INTERRUPCIONES
    BANKSEL INTCON		; SELECCIONAR BANCO 0 PARA INTCON
    BSF GIE			; ACTIVAR INTERRUPCIONES GLOBALES
    BSF RBIE			; ACTIVAR CAMBIO DE INTERRUPCIONES EN PORTB
    BCF RBIF			; LIMPIAR BANDERA DE CAMBIO EN PORTB POR SEGURIDAD
    BSF T0IE
    BCF T0IF
    RETURN
    
CLK_CONFIG:
    BANKSEL OSCCON		; cambiamos a banco 1
    BSF	    OSCCON, 0		; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6		;
    BSF	    OSCCON, 5		;
    BSF	    OSCCON, 4		; IRCF<2:0> -> 111 8MHz
    RETURN
    
TMR0_CONFIG:
    BANKSEL OPTION_REG		; 
    BCF	    T0CS		; 
    BCF	    PSA			; 
    BSF	    PS2			;
    BSF	    PS1			;
    BSF	    PS0			; 
    
    BANKSEL TMR0		; 
    MOVLW   178			;
    MOVWF   TMR0		; 
    BCF	    T0IF		; 
    RETURN 

DEC_SPLITTER:
    MOVF    valor, W
    SUBLW   0x64
    MOVWF   PORTE
    MOVWF   num
    INCF    centenas
    BTFSS   STATUS, 0
    GOTO    $-5
    DECF    centenas
    MOVF    centenas, W
    MOVWF   PORTA
    BCF	    STATUS, 0
    MOVF    num, W
    ADDLW   0x64
    MOVWF   PORTE
    SUBLW   0xA
    MOVWF   PORTE
    MOVWF   num
    INCF    decenas
    BTFSS   STATUS, 0
    GOTO    $-5
    DECF    decenas
    MOVF    decenas, W
    MOVWF   PORTC
    RETURN
    


    
//---------------------------INDICE DISPLAY 7SEG--------------------------------
PSECT HEX_INDEX, class = CODE, abs, delta = 2
ORG 200h			; POSICIÓN DE LA TABLA

HEX_INDEX:
    CLRF PCLATH
    BSF PCLATH, 1		; PCLATH en 01
    ANDLW 0x0F
    ADDWF PCL			; PC = PCLATH + PCL | SUMAR W CON PCL PARA INDICAR POSICIÓN EN PC
    RETLW 00111111B		; 0
    RETLW 00000110B		; 1
    RETLW 01011011B		; 2
    RETLW 01001111B		; 3
    RETLW 01100110B		; 4
    RETLW 01101101B		; 5
    RETLW 01111101B		; 6
    RETLW 00000111B		; 7
    RETLW 01111111B		; 8 
    RETLW 01101111B		; 9
    RETLW 01110111B		; A
    RETLW 01111100B		; b
    RETLW 00111001B		; C
    RETLW 01011110B		; D
    RETLW 01111001B		; C
    RETLW 01110001B		; F    
END