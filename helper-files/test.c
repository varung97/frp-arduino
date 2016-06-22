#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include "test.h"

bool test(uint16_t arg, bool arg1) {
  return (arg % 2) || arg1;
}
