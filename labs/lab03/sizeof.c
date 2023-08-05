#include <stdio.h>

void main()
{
  char c  = 'A';
  int i = 1;
  float f = 2.0f;
  double d = 3.0;
  long l = 4L;

  char* pc = &c;
  int* pi = &i;
  float* pf = &f;
  double* pd = &d;
  long* pl = &l;

  printf("The value of char <c> is %c at address %p.\n", c, pc);
  printf("The value of int <i> is %d at address %p.\n", i, pi);
  printf("The value of float <f> is %f at address %p.\n", f, pf);
  printf("The value of double <d> is %lf at address %p.\n", d, pd);
  printf("The value of long <l> is %ld at address %p.\n", l, pl);
  printf("\n");

  printf("The value of char* <c> is %p at address %p.\n", pc, &pc);
  printf("The value of int* <i> is %p at address %p.\n", pi, &pi);
  printf("The value of float* <f> is %p at address %p.\n", pf, &pf);
  printf("The value of double* <d> is %p at address %p.\n", pd, &pd);
  printf("The value of long* <l> is %p at address %p.\n", pl, &pl);
  printf("\n");

  printf("The size of of char is %ld bytes.\n", sizeof(char));
  printf("The size of of int is %ld bytes.\n", sizeof(int));
  printf("The size of of float is %ld bytes.\n", sizeof(float));
  printf("The size of of double is %ld bytes.\n", sizeof(double));
  printf("The size of of long is %ld bytes.\n", sizeof(long));
  printf("\n");
}
