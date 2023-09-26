#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

#define NUMPROCS 10

int main()
{
  int i, pid;

  testlock();  // main process acquires the sleeplock

  // First create NUMPROCS child processes
  for(i = 0; i < NUMPROCS; i++) {
    pid = fork();
    if(pid) {
      printf("process %d is created\n", i);
      sleep(10);
    }
    else
      break;
  }

  if(pid) {
    testlock();    // main process releases the sleeplock
    for(i = 0; i < NUMPROCS; i++)
      wait(0);     // wait for each child process to complete
  }
  else {           // child process
    testlock();    // tries to acquire sleeplock, made to sleep if held by another process
    printf("%d have acquired lock\n", i);   // acquired the sleeplock
    testlock();    // releases the sleeplock held
  }

  exit(0);
}
