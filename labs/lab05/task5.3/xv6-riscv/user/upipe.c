// Program to demonstrate parent-child process communication using pipe

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main() 
{
   int p[2];  // file descriptors for the pipe
   char *argv[2];
   argv[0] = "wc"; // word count
   argv[1] = 0;  // NULL

   pipe(p);  // creates a new pipe: records the read and write file descriptors in the array p

   int r = fork();
   if (r < 0) {
   }
   
   if (r == 0) {
		// redirection
		
      // default file descriptor 0 represents std input.
      // this statement will close the std input, i.e the program
      // is no longer reading input from it.
      close(0);

      // dup sys call create a copy of file descriptor given in the arg
      // uses lowest unused descriptor.
      // since descriptor 0 has been closed in the previous statement,
      // dup(p[1]); will duplicate descriptor p[1] as descriptor 0.
      dup(p[0]);  // stdin = <- pipe

      close(p[0]);
      close(p[1]);

      exec("wc", argv);
   } else {
      close(p[0]);

      write(p[1], "hello world\n", 12);  // pipe <- str

      // important to close the file descriptors that are not used. It is also
      // important to close the file descriptor after writing to it.
      close(p[1]); // if not here, will not complete
      // prevent from becoming an orphan
      wait(0); // this to make sure does not print as $ 1 2 12
   }

   exit(0);
}

// 5. expected output: 1 2 12
// q. output may appear after the shell prompt has been printed
// a. Parent process terminates, its own parent(shell) has been waiting for
//    its termination is now running, printing a prompt.
//    Then `wc` prints its output before terminating.

