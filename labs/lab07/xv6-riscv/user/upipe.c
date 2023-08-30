// Program to demonstrate parent-child process communication using pipe

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main() 
{
   int p[2];  // file descriptors for the pipe
   char *argv[2];
   argv[0] = "wc";
   argv[1] = 0;  // NULL

   pipe(p);  // creates a new pipe: records the read and write file descriptors in the array p

   int r = fork();
   if (r < 0) {
   }
   
   if (r == 0) {
		// redirection
      close(0);
      dup(p[0]);  // stdin = <- pipe

      close(p[0]);
      close(p[1]);

      exec("wc", argv);
   } else {
      close(p[0]);

      write(p[1], "hello world\n", 12);  // pipe <- str

      close(p[1]);
      wait(0);
   }

   exit(0);
}

