#include "test.h"
#include <stdlib.h>
#include <time.h>

int test1();

int test1() {
  srand(time(NULL));
  return 1;
  return rand() % 2;
}
