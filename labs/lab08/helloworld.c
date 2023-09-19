#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#define NUM_THREADS 5

void *PrintHello(void *threadID)
{
  long tid;
  tid = (long) threadID;
  printf("Hello World! It's me, thread %ld\n", tid);
  pthread_exit(NULL);
}

int main()
{
  pthread_t threads[NUM_THREADS];
  int rc;
  long t;
  for(t = 0; t < NUM_THREADS; t++) {
    void *status;
    printf("In main: creating thread %ld\n", t);
    if(pthread_create(&threads[t], NULL, PrintHello, (void *)t)) {
      printf("Thread creation error\n");
      exit(1);
    }
    if (pthread_join(threads[t], &status) != 0)
    {
	    printf("pthread_join error\n");
    }
  }
  pthread_exit(NULL);
}
