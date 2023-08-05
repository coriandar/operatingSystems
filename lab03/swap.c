#include <stdio.h>

void swap_nums(int* x, int* y)
{
  // swap values stored at pointer
  int tmp = *x;
  //printf("%d\n", *x);
  *x = *y;
  *y = tmp;
}

void swap_pointers(char** x, char** y)
{
  // swap pointers stored at pointer
  char *tmp = *x; // get pointer value
  *x = *y;
  *y = tmp;
}

int main()
{
  int a = 3;
  int b = 4;
  swap_nums(&a, &b);
  printf("a is %d\n", a);
  printf("b is %d\n", b);
 
  char *s1 = "I should print second";
  char *s2 = "I should print first";
  swap_pointers(&s1, &s2);
  printf("s1 is %s\n", s1);
  printf("s2 is %s\n", s2);

  return 0;
}
