/*
 * ECE 385: Final Project
 */
 
.macro MOVI32 reg, val   # movia replacement 
  movhi \reg, %hi(\val)
  ori \reg, \reg, %lo(\val)
.endm

.macro count cycles                      # Start timer to count for given cycles
  movi32 r4, \cycles
  call timer_start
.endm

.equ ADDR_AUDIO, 0x10003040
.equ ADDR_TIMER, 0x10002000  # Timer device
.equ ADDR_AUDIO, 0x10003040  # Audio Device
.equ ADDR_BTTN, 0x10000050   # Push Buttons
.equ TIMER_INT, 0x00000001   # IRQ bit for timer interrupts
.equ BTTN_INT, 0x00000002    # IRQ for push buttons
.equ WAIT_CYCLES, 800        # 48000Hz

.equ SAMPLE_RATE, 48000      # Sample Rate of Timer
.equ FREQ, 100               # Frequency to output
.equ VOL,  0x0fffffff        # Volume of output

.equ FREQ_BT1, 200               # Frequency for Button 1
.equ FREQ_BT2, 400               # Frequency for Button 2
.equ FREQ_BT3, 800               # Frequency for Button 3

.global start

.section .exceptions, "ax"
/*
 * Interrupt Service Routine
 * r8: Frequency Counter
 * r9: Sign bit
 * r10: Samples to output
 * r20: Timer interrupt bit in ctl4
 * r21: Temp/value register for various ops
 * r24: Multiplier result / temp
 */
interrupt_service_routine:

handle_timer_interrupt:
movi32 r20, TIMER_INT
rdctl r21, ctl4
and r21, r21, r20            # Check for timer interrupts
bne r21, r20, check_push_button

/* Check audio FIFO */
movi32 r21, ADDR_AUDIO
ldwio r24, 4(r21)
srli r24, r24, 24
beq r0, r24, reset_timer

/* Add stuff to sound buffer */
addi r8, r8, -1
bgt r8, r0, output_audio

calculate_sample:
/* Calculate samples to output for frequency */
movi32 r8, SAMPLE_RATE
sub r9, r0, r9
mov r24, r10
muli r24, r24, 2
div r8, r8, r24
movi32 r21, 10

output_audio:
movi32 r21, ADDR_AUDIO
movi32 r24, VOL
mul r24, r24, r9
stwio r24,  8(r21)    # Output to left channel
stwio r24, 12(r21)    # Output to right channel

reset_timer:
count WAIT_CYCLES            # Restart Timer

check_push_button:
movi32 r20, BTTN_INT
rdctl r21, ctl4
and r21, r21, r20            # Check for push_button interrupts
bne r21, r20, exit_isr

read_push_buttons:
movi32 r21, ADDR_BTTN
ldwio r24, 12(r21)

check_button_1:
movi32 r21, 0x1 << 1         # Check button 1
and r21, r21, r24
beq r0, r21, check_button_2
movi32 r10, FREQ_BT1

check_button_2:
movi32 r21, 0x1 << 2         # Check button 2
and r21, r21, r24
beq r0, r21, check_button_3
movi32 r10, FREQ_BT2

check_button_3:
movi32 r21, 0x1 << 3         # Check button 3
and r21, r21, r24
beq r0, r21, acknowledge_push_button
movi32 r10, FREQ_BT3

acknowledge_push_button:
movi32 r21, ADDR_BTTN
stwio r0, 12(r21)

addi sp, sp, -12             # Backup registers to stack
stw r8, 0(sp)
stw r9, 4(sp)
stw r10, 8(sp)

mov r4, r10                  # Call the printFreq function
call printFreq

ldw r8, 0(sp)                # Restore registers from stack
ldw r9, 4(sp)
ldw r10, 8(sp)
addi sp, sp, 12

exit_isr:
subi ea, ea, 4               # Subtract 4 from ea so that eret returns to the correct instruction
eret

/*
 * Register Allocation
 * r16: General use register
 */

start:

# Configure audio frequencies
movi32 r8, 0
movi32 r9, -1
movi32 r10, FREQ

rdctl r16, ctl3              # Enable timer exceptions
ori r16, r16, TIMER_INT | BTTN_INT
wrctl ctl3, r16

movia r2, ADDR_BTTN          # Enable interrupts on push buttons 1,2, and 3
movia r3, 0xe
stwio r3, 8(r2)

rdctl r16, ctl0              # Enable interrupts globally on the processor
ori r16, r16, 0x0001
wrctl ctl0, r16

count WAIT_CYCLES            # Start timer

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
