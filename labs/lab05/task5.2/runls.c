#include <stdio.h>
#include <unistd.h>

int main()
{
  // cli arfs are passed individually to the function
  execl("/bin/ls", "ls", "-l", 0);
  printf("This is printed only if there is an error with exec()\n");
}

