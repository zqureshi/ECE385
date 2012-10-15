.include "nios_macros.s"

/***
 * Generates a random ASCII number from 0-9, or a space.
 * Number or space is returned in r2.
 * Uses only r2 and r3.
 *
 * Created: Nick Roberts August 7, 2007
 * Modified: Peter Yiannacouras August 7, 2007
 * Rewritten: Andrew House September 14, 2009
 * Modified: Henry Wong Feb 9, 2012
 **/
.global lab5_rand

lab5_rand:
  movia r2, RANDOM_SEED
  ldw r3, (r2)               #r3 holds random seed

  movia r2, 1103515245
  mul r3, r3, r2
  addi r3,r3,12345           # Linear congruential generator: seed = seed * 1103515245 + 12345

  movia r2, RANDOM_SEED
  stw r3, (r2)               # update seed

  andi   r2,r3,0x1f          # r2 = seed & 0x1f [0-31]
  cmpgei r3,r2,30
  bne    r3,r0,Random_Space  # Any number too large [30-31] becomes a space
                             # avg. 2 spaces for every 32 characters
  muli r2,r2,43
  srai r2,r2,7               # Scale: [0-29] * 43 / 128 --> [0-9]
  addi   r2,r2,0x30          # Change to corresponding ASCII character.
  ret

Random_Space:
  movui  r2, 0x20            # ASCII code for a blank space.
  ret

RANDOM_SEED:
  .word 0xa


