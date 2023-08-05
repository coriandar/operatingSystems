#include <stdio.h>
extern int c;

void main()
{
	int a;
	int b;
	a = 4;
	b = 2;
	c = a + b;
	printf("Result of addition is %d\n", c);
}
