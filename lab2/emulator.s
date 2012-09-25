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

/* Heap + Pregram instructions to emulate */
.data

/* The accumulator that stores the numbers */
.align 2
acc:
.word 0xff

/* Program instructions to emulate */
.align 2
start:
.word 0
.word instr_1
instr_1:
.word 1
.word 10
.word end
end:
.word 3

/* NIOS II Program
 *
 * Register Allocation:
 * r8: LED location
 * r9: Accumulator location
 * r10: Accumulator value (temp)
 * r11: Program counter
 */
.text
.global main

main:
movia  r8,GREEN_LEDS    /* Store LED location */
movia  r9,acc           /* Store Accumulator location */
ldw    r10,(r9)         /* Move acc value to temp register */
stwio  r10,(r8)         /* Write accumulator value to LED */

loop:
br loop
