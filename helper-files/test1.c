#include <avr/io.h>
#include <util/delay_basic.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>
#include "test1.h"

void test1(uint16_t arg) {
  DDRD |= (1 << PD5);
  if (arg) {
    PORTD |= (1 << PD5);
  } else {
    PORTD &= ~(1 << PD5);
  }
}
