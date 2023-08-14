#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int value = 5;

int main()
{
   pid_t pid;
   pid=fork(); // forks the process
   if(pid == 0)
   {
      value += 15;
      printf("%d: value = %d\n", pid, value);
      return 0;
   }
   else if (pid > 0)
   {
      wait(NULL);
      printf("%d: value = %d\n", pid, value); // Line A
      return 0;
   }
}
