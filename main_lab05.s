; Archivo: main_lab05.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR 8 bits INTERRUPCIONES
; Hardware: PUSHBUTTONS
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
  
  //--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
  
  
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
    
POP:
    SWAPF   STATUS_TEMP, W	; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS		; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE			

//----------------------------INT SUBRUTINAS------------------------------------
INT_IOCRB:			; SUBRUTINA DE INTERRUPCIÓN EN PORTB
    BANKSEL PORTA		; SELECCIONAR BANCO 0
    BTFSS   PORTB, BINC		; REVISAR SI EL BIT DEL PRIMER BOTON EN RB0 HA CAMBIADO A 0
    INCF    PORTA		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) INCREMENTAR CUENTA EN PORTA
    BTFSS   PORTB, BDEC		; REVISAR SI EL BIT DEL SEGUNDO BOTON EN RB1 HA CAMBIADO A 0
    DECF    PORTA		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) DISMINUIR LA CUENTA EN PORTA
    BCF	    RBIF		; LIMPIAR LA BANDERA DE PORTB
    RETURN 

PSECT code, delta=2, abs
ORG 100h			; posición 100h para el codigo    
    
//-----------------------------MAIN CONFIG--------------------------------------
main:
    CALL    IO_CONFIG		; INICIAR CONFIGURACION DE INPUTS/OUTPUTS
    CALL    IOCRB_CONFIG	; INICAR CONFIGURACIÓN DE INTERRUPT ON CHANGE PARA PORTB
    CALL    INT_CONFIG		; INICIAR CONFIGURACIÓN DE INTERRUPCIONES
    BANKSEL PORTA
    
loop:				; LOOP DE CODIGO GENERICO PARA REALIZAR MIENTRAS NO HAY INTERRUPCION
    
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
    
    BCF	    OPTION_REG, 7	; LIMPIAR RBPU PARA DESBLOQUEAR EL MODO PULL-UP EN PORTB
    BSF	    WPUB, BINC		; SETEAR WPUB PARA ATVICAR EL PIN 0 DEL PORTB COMO WEAK PULL-UP
    BSF	    WPUB, BDEC		; SETEAR WPUB PARA ACTIVAR EL PIN 1 DEL PORTB COMO WEAK PULL-UP
    
    BANKSEL PORTA		; SELECCIONAR BANCO 0 PARA PORT
    CLRF PORTA			; LIMPIAR VALORES EN PORTA
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
    RETURN

END