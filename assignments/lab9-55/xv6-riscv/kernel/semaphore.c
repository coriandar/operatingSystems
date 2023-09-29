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
}

// A Reader enters room
int downreadsema(struct rwsemaphore *rws)
{
}

// A Reader exits room
int upreadsema(struct rwsemaphore *rws)
{
}

// A Writer enters room
void downwritesema(struct rwsemaphore *rws)
{
}

// A writer exits room
void upwritesema(struct rwsemaphore *rws)
{
}
