/*
 * ECE385: Lab 4
 *
 * Zeeshan Qureshi (zeeshan.qureshi@mail.utoronto.ca)
 */

/* MOVIA replacement */
.macro MOVI32 reg, val
  movhi \reg, %hi(\val)
  ori \reg, \reg, %lo(\val)
.endm

/* Device Addresses */
.equ ADDR_JP1, 0x10000060              /* JTAG 1 Port */
.equ ADDR_TIMER, 0x10002000            /* Timer device */
/* Lego configuration */
.equ DIRECTION_CONFIG, 0x07f557ff      /* Direction Register Configuration */
.equ S0_BAL, 5                         /* Value of Sensor 0 when balanced */
/* Timer configuration */
.equ ON_CYCLES, 5000                   /* Cycles to turn motor on for */
.equ OFF_CYCLES, 5000                  /* Cycles to keep motor off for */

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG 1 Port
 * r9: Value to be written to JP1
 * r10: Value read frow JP1
 * r11: Value of comparison
 */
main:
movi32 r8, ADDR_JP1
movi32 r9, DIRECTION_CONFIG

stwio r9, 4(r8)                        /* Initialize Direction Register */

movi32 r9, 0xffffffff                  /* Turn off sensors and motors */
stwio r9, 0(r8)

loop:

/* Read sensor value and decide motor direction */
ldwio r10, 0(r8)                       /* Enable Sensor 0 */
movi32 r9, ~(0x1 << 10)
and r9, r9, r10
stwio r9, 0(r8)

wait_s0:
ldwio r10, 0(r8)                       /* Read value of JP1 */
srli r10, r10, 11
andi r10, r10, 0x1
beq r0, r10, calc_dir                  /* Bit 11 is low if sensor value ready */
br wait_s0

calc_dir:
ldwio r10, 0(r8)                       /* Read data from JP1 */
srli r10, r10, 27                      /* Move bits 27-30 to 0-3 */
andi r10, r10, 0xf                     /* Clear out other bits */
cmpnei r11, r10, S0_BAL                /* If balanced, turn motor off */
beq r0, r11, motor_off
cmpgtui r11, r10, S0_BAL               /* If S0 < BAL turn left */
beq r0, r11, turn_left
cmpltui r11, r10, S0_BAL               /* If S0 > BAL turn right */
beq r0, r11, turn_right

motor_off:
movi32 r9, 0xffffffff                  /* If balanced, turn motor off */
br update

turn_right:
movi32 r9, 0xfffffffc                  /* Turn motor right */
br update

turn_left:
movi32 r9, 0xfffffffe                  /* Turn motor left */
br update

update:
stwio r9, 0(r8)
br loop

/*
 * Register Allocation
 * Note: We're not backing up registers while calling or inside subroutine
 * since this is a small program and we already know which registers we will
 * be using.
 * r4: (Argument) Number of cycles to wait
 * r16: Address of Timer Device
 * r17: Value read from / write to Timer
 */
timer_countdown:
movi32 r16, ADDR_TIMER

movi32 r17, 0x0                        /* Clear Timer */
stwio r17, 0(r16)

mov r17, r4                            /* Write lower half of period */
andi r17, r17, 0x0000ffff
stwio r17, 8(r16)

mov r17, r4                            /* Write upper half of period */
srli r17, r17, 16
stwio r17, 12(r16)

movi32 r17, 0x4                        /* Start Timer */
stwio r17, 4(r16)

timer_wait:
ldwio r17, 0(r16)                      /* Check if timer has timed out */
andi r17, r17, 0x1
beq r0, r17, timer_wait

ret
