/*
 * ECE385: Lab 4
 *
 * Zeeshan Qureshi
 */

/* MOVIA replacement */
.macro MOVI32 reg, val
  movhi \reg, %hi(\val)
  ori \reg, \reg, %lo(\val)
.endm

.equ ADDR_JP1, 0x10000060              /* Address of JTAG 1 Port */
.equ DIRECTION_CONFIG, 0x07f557ff      /* Direction Register Configuration */
.equ S0_BAL, 6                         /* Value of Sensor 0 when balanced */

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG 1 Port
 * r9: Value to be written to JP1
 * r10: Value read frow JP1
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
cmpltui r10, r10, S0_BAL               /* If S0 < BAL turn left, else right */
beq r0, r10, turn_right
br turn_left

turn_right:
movi32 r9, 0xfffffffc                  /* Turn motor right */
br update

turn_left:
movi32 r9, 0xfffffffe                  /* Turn motor left */
br update

update:
stwio r9, 0(r8)
br loop
