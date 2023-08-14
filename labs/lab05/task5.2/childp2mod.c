#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int value = 5;

int main()
{
   pid_t pid;
   pid=fork();

   value += 15;

   if(pid > 0)
   {
     printf("ChildPID: %d: value = %d\n", pid, value);
     return 0;
   }

   else if(pid == 0)
   {
     wait(NULL); // syscall to wait until child completes exec
     printf("ParentPID: %d: value = %d\n", pid, value);
     return 0;
   }
}
