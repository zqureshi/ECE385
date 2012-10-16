/*
 * ECE 385: Lab 5
 *
 * Zeeshan Qureshi (zeeshan.qureshi@mail.utoronto.ca)
 */

.equ ADDR_UART, 0x10001000   /* Address of JTAG UART Port */
.equ BUFFER_LEN, 40          /* Length of output buffer */
.equ SPACE, 0x20             /* ASCII space character */

BUFFER:
.skip 40, SPACE              /* Standard null-terminated array */
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

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG UART (Shared by all other methods)
 */
main:
movia r8, ADDR_UART

print RESET_TERM
print BUFFER
br main

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
