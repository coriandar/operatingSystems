#include "kernel/types.h"
#include "kernel/riscv.h"
#include "kernel/spinlock.h"
#include "kernel/semaphore.h"
#include "kernel/defs.h"

void initsema(struct semaphore* s, int count) {
  s->value = count;
  initlock(&s->lk, "Counting Semaphore");
}

int downsema(struct semaphore* s) {
  acquire(&s->lk);
  while (s->value <=0)
    sleep(s,&s->lk);
  s->value--;
  release(&s->lk);
  return s->value;
}

int upsema(struct semaphore* s) {
  acquire(&s->lk);
  s->value++;
  wakeup(s);
  release(&s->lk);
  return s->value;
}

void initrwsema(struct rwsemaphore *rws)
{
   // Lecture slide page 14
   rws->readers = 0;
   initsema(&rws->mutex, 1);
   initsema(&rws->roomEmpty, 1); 
}

// A Reader enters room
int downreadsema(struct rwsemaphore *rws)
{
   downsema(&rws->mutex); // Locking mutex
   rws->readers++;

   if (rws->readers == 1)
   {
      downsema(&rws->roomEmpty); // Locking roomEmpty
   }

   upsema(&rws->mutex); // Unlocking mutex

   return rws->readers;
}

// A Reader exits room
int upreadsema(struct rwsemaphore *rws)
{
    downsema(&rws->mutex);
    rws->readers--;

    if (rws->readers == 0)
    {
       upsema(&rws->roomEmpty); // Unlocking roomEmpty
    }

    upsema(&rws->mutex);

    return rws->readers;
}

// A Writer enters room
void downwritesema(struct rwsemaphore *rws)
{
   downsema(&rws->roomEmpty);
}

// A writer exits room
void upwritesema(struct rwsemaphore *rws)
{
   upsema(&rws->roomEmpty);
}
