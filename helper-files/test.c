#include "test.h"
#include <stdlib.h>
#include <time.h>

int test();

int test(uint16_t arg, uint16_t arg1, uint16_t arg2) {
  return ((arg * arg1 * arg2) % 10) * 10;
}
