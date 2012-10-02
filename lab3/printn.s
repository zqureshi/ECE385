/*
 * ECE 385: Lab 3
 */

/* Print codes */
.equ SYM_OCT,  0x6f        /* 'o' */
.equ SYM_DEC,  0x64        /* 'd' */
.equ SYM_HEX,  0x68        /* 'h' */

.text
.global printn

/*
 * Register Allocation:
 * r16: Text pointer
 * r17: Stack argument counter
 *
 * r8 (temp): Current symbol
 * r9 (temp): Symbol to compare to
 */
printn:
addi sp,sp,-24    /* Make space on stack for r7, r6, r5, ra, r16, r17 */

stw r7,20(sp)
stw r6,16(sp)
stw r5,12(sp)

stw ra,8(sp)      /* Backup ra since it'll be overwritten by subroutine call */

stw r16,4(sp)     /* Backup r16 and r17 since they are callee-saved */
stw r17,0(sp)

mov r16,r4        /* Set up Text pointer */

mov r17,sp        /* Set up argument counter */
addi r17,r17,12

loop:
ldb r8,(r16)      /* Read current character pointed to */
beq r8,r0,exit    /* Reached end of string */

movi r9,SYM_OCT   /* If 'o' print current argument in Octal */
beq r8,r9,oct

movi r9,SYM_DEC   /* If 'd' print current argument in Decimal */
beq r8,r9,dec

movi r9,SYM_HEX   /* If 'h' print current argument in Hex */
beq r8,r9,hex

br exit           /* Invalid symbol, should not be here, exit */

oct:
ldw r4,(r17)
call printOct
br increment

dec:
ldw r4,(r17)
call printDec
br increment

hex:
ldw r4,(r17)
call printHex
br increment

increment:        /* Increment text pointer and argument pointer */
addi r16,r16,1
addi r17,r17,4
br loop

exit:
ldw r17,0(sp)     /* Restore r16 and r17 */
ldw r16,4(sp)

ldw ra,8(sp)      /* Restore ra */

addi sp,sp,24     /* Clear stack frame */

ret
