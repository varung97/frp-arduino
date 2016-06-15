#include "test.h"
#include <stdlib.h>
#include <time.h>

int test();

int test() {
  srand(time(NULL));
  return 1;
  return rand() % 2;
}
