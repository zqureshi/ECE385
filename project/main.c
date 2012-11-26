#include <stdio.h>
#include <string.h>

#define LCD_ADDR 0x10003050
#define SWITCH_ADDR 0x10000040
#define BIT_0_MASK 0x1
#define SWITCH_COUNT 10

/*
 * Output the given frequency to the DE1/2 LCD
 * @freq  The frequency to output
 */
void printFreq(int freq) {
  char line[17];
  sprintf(line, "%d Hz", freq);

  volatile char * LCD_display_ptr = (char *) LCD_ADDR;
  char *text_ptr = line;

	while ( *(text_ptr) ) {
		*(LCD_display_ptr + 1) = *(text_ptr);
		++text_ptr;
	}
}

/*
 * Calculate frequency to output from base note and switch values
 * @base Note to output
 */
int calcFreq(int base) {
  int switch_value = *((int *)SWITCH_ADDR);

  for(int i = 0; i < SWITCH_COUNT; i++) {
    if(BIT_0_MASK & switch_value)
      base *= 2;
    switch_value = switch_value >> 1;
  }

  return base;
}

int main() {
  /* Do nothing */
  start();

  return 0;
}

