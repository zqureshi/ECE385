/*
 * ECE 385: Lab 5
 *
 * Zeeshan Qureshi (zeeshan.qureshi@mail.utoronto.ca)
 */

.equ ADDR_UART, 0x10001000   /* Address of JTAG UART Port */
.equ SPACE, 0x20             /* ASCII space character */

.data

BUFFER:
.skip 10, SPACE              /* Standard null-terminated array */
.byte 0x00

RESET_TERM:                  /* Control sequences to reset terminal */
.string "\x1b[2J\x1b[H"

/*
 * Macro to call output_string with the address of the string provided
 */
.macro print string
movia r4, \string
call output_string
.endm

/*
 * Macro to call shift_buf_left with the string and replacement character
 */
.macro sbl string replacement
movia r4, \string
movi r5, \replacement
call shift_buf_left
.endm

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG UART (Shared by all other methods)
 */
main:
movia r8, ADDR_UART

loop:
print RESET_TERM
print BUFFER
sbl BUFFER, 0x31
br loop

/*
 * Write buffer to UART
 *
 * Register Allocation
 * r4: Argument: Address of output buffer
 * r5: Current character in buffer
 * r6: Spaces in output buffer
 */
output_string:

ldwio r6, 4(r8)              /* Wait for space in UART buffer */
srli r6, r6, 16
beq r0, r6, output_string

ldb r5, 0(r4)                /* Load current character */
beq r0, r5, os_exit          /* If reached null, then exit */
stwio r5, 0(r8)              /* Output current char to UART */
addi r4, r4, 1               /* Move to next character */
br output_string

os_exit:
ret

/*
 * Shift each character in the buffer 1 position to the left, discarding
 * the leftmost character and inserting the replacement char at the end.
 *
 * Register Allocation
 * r4: Argument: Address of buffer
 * r5: Argument: Replacement character to insert at end
 * r6: Current character in buffer
 */
shift_buf_left:
ldb r6, 0(r4)                /* If buffer is empty, then exit */
beq r0, r6, sbl_exit

sbl_loop:
ldb r6, 1(r4)                /* Read next character and put in curr pos */
beq r0, r6, sbl_ins_rep
stb r6, 0(r4)
addi r4, r4, 1
br sbl_loop

sbl_ins_rep:
stb r5, 0(r4)                /* Insert replacement char at the position */

sbl_exit:
ret
