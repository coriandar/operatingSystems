#include "kernel/types.h"
#include "user/user.h"

int main(void)
{
  int sz = getthisprocsize();
  printf("The size of my process address space is %d bytes\n", sz);
  exit(0);
}
