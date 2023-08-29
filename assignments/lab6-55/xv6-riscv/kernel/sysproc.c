#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

// You should copy this kernel function to sysproc.c
// and set up a system call for pageAccess() in xv6

int
sys_pageAccess(void)
{
    // Get the three function arguments from the pageAccess() system call
	uint64 usrpage_ptr;  // First argument - pointer to user space address
	int npages;          // Second argument - the number of pages to examine
	uint64 usraddr;      // Third argument - pointer to the bitmap
	argaddr(0, &usrpage_ptr);
	argint(1, &npages);
	argaddr(2, &usraddr);

	if (argaddr(0, &usrpage_ptr) < 0 || argint(1, &npages) < 0 || argaddr(2, &usraddr) < 0) {
        return -1;
    }

	struct proc* p = myproc();
    uint64 bitmap = 0; // create bitmap
	// . . . Add your code for this function here . . .
	//uint64 bitmap; // pointer to unsigned integer, copy to usraddr
    for(int i = 0; i < npages; i++) {
        uint64 virtualAddress = usrpage_ptr + i * PGSIZE; // get va
        pte_t *pte = nextaddr(p->pagetable, virtualAddress); // this uses walk
        if (pte) {
            if ((*pte) & PTE_A) {
                *pte &= ~PTE_A; // clear PTE_A
                bitmap |= (1 << i); // update bitmap
            }
        }
    }

	// Return the bitmap pointer to the user program
	copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap));
	return 0;
}


uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
