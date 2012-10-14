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

.text
.global main

/*
 * Register Allocation
 * r8: Address of JTAG 1 Port
 * r9: Value to be written to JP1
 */
main:
movi32 r8, ADDR_JP1
movi32 r9, DIRECTION_CONFIG

stwio r9, 4(r8)                        /* Initialize Direction Register */

movi32 r9, 0xffffffff                  /* Turn motor off */
stwio r9, 0(r8)

movi32 r9, 0xfffffffc                  /* Turn motor right */
stwio r9, 0(r8)

movi32 r9, 0xfffffffe                  /* Turn motor left */
stwio r9, 0(r8)

br main
