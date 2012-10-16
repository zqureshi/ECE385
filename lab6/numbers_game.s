/*
 * ECE 385: Lab 6
 */

.equ ADDR_UART, 0x10001000   /* Address of JTAG UART Port */
.equ ADDR_TIMER, 0x10002000  /* Timer device */
.equ WAIT_CYCLES, 50000000   /* Number of timer cycles to wait */
.equ FLASH_CYCLES, 37500000  /* Number of cycles to wait when flashing */
.equ SPACE, 0x20             /* ASCII space character */

.equ TIMER_INT, 0x00000001	 /* IRQ bit for timer interrupts */
.equ UART_INT,  0x00000100	 /* IRQ bit for JTAG UART interrupts */

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
mov r5, \replacement
call replace_buf_char
.endm

/* Start timer to count for given cycles */
.macro count cycles
movi32 r4, \cycles
call timer_start
.endm

/* Start timer to count for given cycles and wait */
.macro wait cycles
count \cycles
call timer_wait
.endm

.data

BUFFER:
.skip 40, SPACE              /* Standard null-terminated string */
.byte 0x00

RESET_TERM:                  /* Control sequences to reset terminal */
.string "\x1b[2J\x1b[H"

RESET_CURSOR:                /* Reset cursor to home position */
.string "\x1b[H"

OVER_MESSAGE:
.string "GAME OVER!"         /* Message to display when game is over */


.section .exceptions, "ax"

/*
 * Interrupt Service Routine
 * Register Allocation
 * r12: As it is used in main (Address of Timer)
 * r20: Timer interrupt bit in ctl4
 * r21: UART interrupt bit in ctl4
 * r22: Temp/value register for various ops
 */
interrupt_service_routine:
movi32 r20, TIMER_INT
movi32 r21, UART_INT
rdctl r22, ctl4
and r22, r22, r20				     /* Check for timer interrupts */
bne r22, r20, check_uart_interrupt

handle_timer_interrupt:
call lab5_rand               /* Generate random character */
sbl BUFFER r2                /* Insert generated character */

ldb r10, 0(r9)               /* If first character in buffer is not a space */
cmpeqi r16, r10, SPACE       /* then game is over */

count WAIT_CYCLES            /* Restart Timer */

check_uart_interrupt:
rdctl r22, ctl4
and r22, r22, r21				     /* Check for jtag uart interrupts */
bne r22, r21, finish_isr

handle_uart_interrupt:
ldwio r11, 0(r8)             /* Check for input (and implicitly acknowledge interrupts) */
andi r15, r11, 0x1 << 15
beq r0, r15, finish_isr

andi r11, r11, 0xff          /* Remove entered character from buffer */
rbc BUFFER, r11

finish_isr:
print RESET_TERM             /* Display buffer via UART */
print BUFFER
print RESET_CURSOR

subi ea, ea, 4					     /* Subtract 4 from ea so that eret returns to the correct instruction */
eret



.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG UART (Shared by all other methods)
 * r9: Address of buffer    (Shared by the ISR)
 * r10: Current character at buffer
 * r11: Data read from UART
 * r12: Address of Timer    (Shared by the ISR)
 * r15: Temp / Comparison Value
 * r16: Game over flag      (Shared by the ISR)
 * r17: Temp / Control register val
 */
main:
movi32 r8, ADDR_UART         /* Initialize Device Addresses */
movi32 r9, BUFFER
movi32 r12, ADDR_TIMER

rdctl r15, ctl3				       /* Enable timer and jtag uart exceptions */
ori r15, r15, 0x0101
wrctl ctl3, r15

rdctl r15, ctl0	             /* Enable interrupts globally on the processor */
ori r15, r15, 0x0001
wrctl ctl0, r15

/* Setup and enable timer interupt */
count WAIT_CYCLES            /* Start Timer */

/* Setup and enable jtag uart interrupt */
ldwio r15, 4(r8)
ori r15, r15, 0x1
stwio r15, 4(r8)

movi r16, 0x1                 /* Reset game flag */
loop:
bne r0, r16, loop             /* Loop if game not over */


rdctl r15, ctl0	             /* Disable interrupts globally on the processor */
movi32 r17, ~(0x1)
and r15, r15, r17
wrctl ctl0, r15

game_over:                   /* Flash OVER_MESSAGE */
print RESET_TERM
print OVER_MESSAGE
print RESET_CURSOR
wait FLASH_CYCLES

print RESET_TERM
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
timer_start:
movi32 r5, ADDR_TIMER

movi32 r6, 0x0               /* Clear Timer */
stwio r6, 0(r5)

mov r6, r4                   /* Write lower half of period */
andi r6, r6, 0x0000ffff
stwio r6, 8(r5)

mov r6, r4                   /* Write upper half of period */
srli r6, r6, 16
stwio r6, 12(r5)

movi32 r6, 0x5               /* Start Timer with interrupts enabled */
stwio r6, 4(r5)

ret

/*
 * Wait for Timer to count down
 *
 * Register Allocation
 * r5: Address of Timer
 * r6: Value read from Timer
 */
timer_wait:
movi32 r5, ADDR_TIMER

ldwio r6, 0(r5)              /* Check if timer has timed out */
andi r6, r6, 0x1
beq r0, r6, timer_wait

ret
