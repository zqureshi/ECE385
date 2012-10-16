/*
 * ECE 385: Lab 5
 *
 * Zeeshan Qureshi (zeeshan.qureshi@mail.utoronto.ca)
 */

.equ ADDR_UART, 0x10001000   /* Address of JTAG UART Port */
.equ ADDR_TIMER, 0x10002000  /* Timer device */
.equ WAIT_CYCLES, 50000000   /* Number of timer cycles to wait */
.equ FLASH_CYCLES, 37500000  /* Number of cycles to wait when flashing */
.equ SPACE, 0x20             /* ASCII space character */

/* MOVIA replacement */
.macro MOVI32 reg, val
  movhi \reg, %hi(\val)
  ori \reg, \reg, %lo(\val)
.endm

/* Call output_string with the address of the string provided */
.macro print string
movi32 r4, \string
call output_string
.endm

/* Call shift_buf_left with the string and replacement character */
.macro sbl string replacement
movi32 r4, \string
mov r5, \replacement
call shift_buf_left
.endm

/* Call replace_buf_char with the string and replacement character */
.macro rbc string replacement
movi32 r4, \string
movi32 r5, \replacement
call replace_buf_char
.endm

/* Wait for given cycles by polling timer */
.macro wait cycles
movi32 r4, \cycles
call timer_countdown
.endm

.data

BUFFER:
.skip 10, SPACE              /* Standard null-terminated array */
.byte 0x00

RESET_TERM:                  /* Control sequences to reset terminal */
.string "\x1b[2J\x1b[H"

RESET_CURSOR:                /* Reset cursor to home position */
.string "\x1b[H"

OVER_MESSAGE:
.string "GAME OVER!"          /* Message to display when game is over */

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG UART (Shared by all other methods)
 * r9: Address of buffer
 * r10: Current character at buffer
 * r11: Data read from UART
 * r15: Temp / Comparison Value
 */
main:
movi32 r8, ADDR_UART
movi32 r9, BUFFER

loop:
call lab5_rand               /* Generate random character */

ldb r10, 0(r9)               /* If first character in buffer is not a space */
cmpeqi r16, r10, SPACE       /* then game is over */
beq r0, r16, game_over

sbl BUFFER r2                /* Insert generated character and display */
print RESET_TERM
print BUFFER
print RESET_CURSOR

wait WAIT_CYCLES
br loop

game_over:                   /* Flash OVER_MESSAGE */
print RESET_TERM
wait FLASH_CYCLES
print OVER_MESSAGE
print RESET_CURSOR
wait FLASH_CYCLES
br game_over

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

/*
 * Remove the specified character from each location in the buffer
 * and replace with a <SPACE>.
 *
 * Register Allocation:
 * r4: Argument: Address of buffer
 * r5: Argument: Character to remove
 * r6: Current character at buffer
 */
replace_buf_char:
ldb r6, 0(r4)
beq r0, r6, rbc_exit         /* If buffer is empty, exit */
bne r5, r6, rbc_continue     /* If not the character to replace, continue */
movi32 r6, SPACE             /* Replace with a space */
stbio r6, 0(r4)
rbc_continue:
addi r4, r4, 1               /* Move to next character */
br replace_buf_char

rbc_exit:
ret

/*
 * Start Timer to run for WAIT_CYCLES
 *
 * Register Allocation
 * r4: Argemunt: Number of cycles to wait
 * r5: Address of Timer Device
 * r6: Value read from / write to Timer
 */
timer_countdown:
movi32 r5, ADDR_TIMER

movi32 r6, 0x0                        /* Clear Timer */
stwio r6, 0(r5)

mov r6, r4                            /* Write lower half of period */
andi r6, r6, 0x0000ffff
stwio r6, 8(r5)

mov r6, r4                            /* Write upper half of period */
srli r6, r6, 16
stwio r6, 12(r5)

movi32 r6, 0x4                        /* Start Timer */
stwio r6, 4(r5)

timer_wait:
ldwio r6, 0(r5)                      /* Check if timer has timed out */
andi r6, r6, 0x1
beq r0, r6, timer_wait

ret
