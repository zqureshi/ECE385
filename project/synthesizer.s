/*
 * ECE 385: Final Project
 */
 
.macro MOVI32 reg, val		 # movia replacement 
  movhi \reg, %hi(\val)
  ori \reg, \reg, %lo(\val)
.endm

.macro count cycles			 #Start timer to count for given cycles
movi32 r4, \cycles
call timer_start
.endm

.equ ADDR_AUDIO, 0x10003040
.equ ADDR_TIMER, 0x10002000  #Timer device
.equ TIMER_INT, 0x00000001   #IRQ bit for timer interrupts
.equ WAIT_CYCLES, 1136

.global start

.section .exceptions, "ax"
/*
 * Interrupt Service Routine
 * r20: Timer interrupt bit in ctl4
 * r21: Temp/value register for various ops

 */
interrupt_service_routine:

handle_timer_interrupt:
movi32 r20, TIMER_INT
rdctl r21, ctl4
and r21, r21, r20            #Check for timer interrupts
bne r21, r20, check_push_button

/* Add stuff to sound buffer */

count WAIT_CYCLES            #Restart Timer

check_push_button:

/* Check for push button interrupts */

subi ea, ea, 4               #Subtract 4 from ea so that eret returns to the correct instruction
eret

/*
 * Register Allocation
 * r16: General use register
 */

start:

rdctl r16, ctl3              #Enable timer exceptions
ori r16, r16, 0x0001
wrctl ctl3, r16

rdctl r16, ctl0              #Enable interrupts globally on the processor
ori r16, r16, 0x0001
wrctl ctl0, r16

count WAIT_CYCLES			 #Start timer

eternal_loop:
br eternal_loop






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

