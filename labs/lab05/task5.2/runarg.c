#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
  //execl("/bin/ls", "ls", "-l", 0);
  if (argc != 3)
  {
    printf("This is printed only if there is an error with exec()\n");
  }
  else
  {
    //execl("/bin/ls", argv[1], argv[2], 0);
    // missing sentinel indicated end of arg list
    // execv is used to replace the current process with new process
    // int execv(const char *path, char *const argv[])
    // const, declare variable pointer

    // build args array
    char *const args[] = { argv[1], argv[2], NULL };
    //execv("/bin/ls", argv[1], argv[2], NULL);
    execv("/bin/ls", args);
  }
}
