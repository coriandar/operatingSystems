#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int value = 5;

int main()
{
   pid_t pid;
   pid=fork();

   value += 15;
   printf("%d: value = %d\n", pid, value);
   return 0;
}
