#include<stdio.h>
#include<string.h>

#define LCD_ADDR 0x10003050

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

int main() {
  /* Do nothing */
  start();

  return 0;
}

