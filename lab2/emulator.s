/*
 * ECE385: Lab 2
 * Zeeshan Qureshi (zeeshan.qureshi@mail.utoronto.ca)
 */

/* LED Locations */
.equ RED_LEDS,   0x10000000
.equ GREEN_LEDS, 0x10000010

/* Define Op Codes for the emulated machine */
.equ OP_CLR,  0x0  /* Clear accumulator */
.equ OP_ADD,  0x1  /* Add number to accumulator */
.equ OP_SUB,  0x2  /* Subtract number from accumulator */
.equ OP_EXIT, 0x3  /* Exit program */
.equ OP_SUBR, 0x4  /* Subtract acc from operand and store in acc */
.equ OP_BLT,  0x5  /* Branch to inst if acc < 0 */

/* Heap + Pregram instructions to emulate */
.data

/* The accumulator that stores the numbers */
.align 2
ACC:
.word 0xff

/* Program instructions to emulate */
.align 2
START:
.word OP_CLR
.word SET_ACC_VAL
SET_ACC_VAL:
.word OP_SUB
.word 77
.word CHECK_ACC_VAL
CHECK_ACC_VAL:
.word OP_BLT
.word INVERSE_ACC_SIGN
.word FIN
INVERSE_ACC_SIGN:
.word OP_SUBR
.word 0
.word FIN
FIN:
.word OP_EXIT

/* NIOS II Program
 *
 * Register Allocation:
 * r8: LED location
 * r9: Accumulator location
 * r10: Accumulator value (temp)
 * r11: Program counter
 * r12: Program counter value
 * r13: Opcode test value
 * r14: Temp A
 * r15: Temp B
 */
.text
.global MAIN

MAIN:
movia r8,RED_LEDS      /* Store LED location */
movia r9,ACC           /* Store Accumulator location */
movia r11,START        /* Point PC to first instruction of program */

EMULATE:
ldw r10,(r9)           /* Load accumulator value */
ldw r12,(r11)          /* Load OpCode from location in PC */
stwio r10,(r8)         /* Write accumulator value out to Red LEDs */
stwio r12,0x10(r8)     /* Write OpCode out to Green LEDs */

movi r13,OP_CLR        /* Test if OpCode at PC is OP_CLR */
beq r13,r12,CLR

movi r13,OP_ADD        /* Test if OpCode at PC is OP_ADD */
beq r13,r12,ADD

movi r13,OP_SUB        /* Test if OpCode at PC is OP_SUB */
beq r13,r12,SUB

movi r13,OP_EXIT       /* Test if OpCode at PC is OP_EXIT */
beq r13,r12,EXIT

movi r13,OP_SUBR       /* Test if OpCode at PC is OP_SUBR */
beq r13,r12,SUBR

movi r13,OP_BLT       /* Test if OpCode at PC is OP_BLT */
beq r13,r12,BLT

br EXIT                /* If we're here means there's an invalid OpCode was present */

CLR:
stw r0,(r9)

ldw r11,4(r11)
br EMULATE

ADD:
ldw r10,(r9)
ldw r14,4(r11)
add r10,r10,r14
stw r10,(r9)

ldw r11,8(r11)
br EMULATE

SUB:
ldw r10,(r9)
ldw r14,4(r11)
sub r10,r10,r14
stw r10,(r9)

ldw r11,8(r11)
br EMULATE

SUBR:
ldw r10,(r9)
ldw r14,4(r11)
sub r10,r14,r10
stw r10,(r9)

ldw r11,8(r11)
br EMULATE

BLT:                   /* Delicious! */
ldw r10,(r9)

bge r10,r0,GREATER
ldw r11,4(r11)
br EMULATE

GREATER:
ldw r11,8(r11)
br EMULATE

EXIT:
br EXIT
