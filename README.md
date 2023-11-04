### __Quick Links__
- [Resources.md][resources_md]
- [Formulas.md][formulas_md]
- [Readings.md][readings_md]

[resources_md]: https://github.com/coriandar/operatingSystems/blob/main/os/_00_Resources.md
[formulas_md]: https://github.com/coriandar/operatingSystems/blob/main/os/_00_Formulas.md
[readings_md]: https://github.com/coriandar/operatingSystems/tree/main/os

--------------------------------------------------
### __Assignment 02__
#### Shell script Operators
```java
-eq // equal to
-ne // not equal to
-gt // greater than
-lt // less than
-ge // greater than or equal to
-le // less than or equal to
-! // negation (not)
```
--------------------------------------------------
### __Assignment 03__
#### Compiler
```c
gcc prog1.c prog2.c // compile with linking, compiles one at time, a.out
gcc prog1.c prog2.c -o lab2prog // change output name
gcc -c prog2.c // compile without linking, output object file
gcc prog1.c prog2.c -o lab2linked // link object files
```
--------------------------------------------------
### __Assignment 04__
#### Add `showprocs` system call
```c
user/user.h // add prototype
user/usys.pl // add entry stub
kernel/syscall.h // add to last with num
kernel/syscall.c // add prototype
kernel/syscall.c // add pointer
kernel/sysproc.c // implement system call

// implement showprocs
kernel/proc.c // implement new fun
kernel/defs.h // add prototype for new func
user/ps.c // add code to call make call
/Makefile // add _userprog\
```
- [user.h][user_h_4] | [usys.pl][usys_pl_4] | [syscall.h][syscall_h_4] | [syscall.c][syscall_c_4] | [syscall.c][syscall_c_4] | [sysproc.c][sysproc_c_4] | [proc.c][proc_c_4] | [defs.h][defs_h_4] | [ps.c][ps_c_4] | [Makefile][Makefile__4]

[user_h_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/user.h#L29
[usys_pl_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/usys.pl#L20
[syscall_h_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/syscall.h#L24
[syscall_c_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/syscall.c#L108
[sysproc_c_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/sysproc.c#L18
[proc_c_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/proc.c#L31
[defs_h_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/defs.h#L107
[ps_c_4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/ps.c
[Makefile__4]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/Makefile#L136
--------------------------------------------------
### __Assignment 05__
#### exec()
- Letters following `exec` refer to:
```java
e // and array of pointer to env variables is explicitly passed to the new process image.
l // cli args are passed individually to function.
p // uses PATH env var to find file to be executed.
v // cli args passed to the function as an array of pointers.
```

#### fork()
- Creates exact copy of parent process, not very useful.
- Often `exec()` system call is made in child process, exec diff program.

#### pipe()
```java
fd[0] // read end of pipe, receive
fd[1] // write end of pipe, send

  Parent                                     Child
        |||||||||||||||||||||||||||||||||||||
fd[0] <---------------------------------------- fd[1]
fd[1] ----------------------------------------> fd[0]
        |||||||||||||||||||||||||||||||||||||
```
--------------------------------------------------
### __Assignment 06__
#### Add sys_pageAccess
- Take start address of virtual address.
- From that get to page table.
- Check the flag of each entry in pagetable.
- Track each entry in unsigned int, bits
- 32bit, 0 false, 1 for true.
- Return manual modified bitmap to test first.

```c
user/user.h // add prototype
user/usys.pl // add entry stub
kernel/syscall.h // add to last with num
kernel/syscall.c // add prototype, add pointer
kernel/riscv.h // define PTE_A
kernel/sysproc.c // implement system call
user/pgaccess_test.h // add riscv.h, has PGSIZE defined
/Makefile // add _userprog

// add nextaddr function
kernel/defs.h // calls walk
kernel/vm.c // calls walk
```
- [user.h][user_h_6] | [usys.pl][usys_pl_6] | [syscall.h][syscall_h_6] | [syscall.c][syscall_c_6] | [riscv.h][riscv_h_6] | [sysproc.c][sysproc_c_6] | [pgaccess_test.h][pgaccess_test_h_6] | [Makefile][Makefile__6] | [defs.h][defs_h_6] | [vm.c][vm_c_6]

[user_h_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/user.h#L27
[usys_pl_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/usys.pl#L39
[syscall_h_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/syscall.h#L23
[syscall_c_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/syscall.c#L107
[riscv_h_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/riscv.h#L346
[sysproc_c_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/sysproc.c#L11
[pgaccess_test_h_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/pgaccess_test.c
[Makefile__6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/Makefile#L135
[defs_h_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/defs.h#L174
[vm_c_6]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/vm.c#L149
--------------------------------------------------
### __Assignment 07__
#### Compiling
```c
make clean // always run first

make qemu SCHEDULER=RR // set to round robin
make qemu SCHEDULER=FCFS // set to first-come-first-served
make qemu SCHEDULER=PRIORITY // set to priority scheduler
make qemu CPUS=1 // compile xv6 assuming 1 CPU
make qemu SCHEDULER=PRIORITY CPUS=1
```

#### Add sys_chpriority
```c
user/user.h // add prototype
user/usys.pl // add entry stub
kernel/syscall.h // add to last with num
kernel/syscall.c // add prototype, add pointer
kernel/sysproc.c // implement system call
/Makefile // add _userprog

// implement changepriority()
kernel/defs.h
kernel/proc.c
```
- [user.h][user_h_7] | [usys.pl][usys_pl_7] | [syscall.h][syscall_h_7] | [syscall.c][syscall_c_7] | [sysproc.c][sysproc_c_7] | [Makefile][Makefile__7] | [defs.h][defs_h_7] | [proc.c][proc_c_7]

#### Implement Priority Based scheduling
```c
kernel/proc.h // struct proc() add nice
kernel/proc.c // allocproc() initialize nice value
kernel/proc.c // scheduler() priority algorithm to scheduler(void)
```
- [proc.h][proc_h_7] | [allocproc()][allocproc__7] | [scheduler()][scheduler__7]

[user_h_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/user/user.h#L27
[usys_pl_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/user/usys.pl#L40
[syscall_h_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/syscall.h#L24
[syscall_c_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/syscall.c#L108
[sysproc_c_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/sysproc.c#L11
[Makefile__7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/Makefile#L144
[defs_h_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/defs.h#L110
[proc_c_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/proc.c#L561
[proc_h_7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/proc.h#L117
[allocproc__7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/proc.c#L127
[scheduler__7]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab7-55/xv6-riscv/kernel/proc.c#L519
--------------------------------------------------
### __Assignment 08__
```c
make test1
make test2
```
--------------------------------------------------
### __Assignment 09__
```c
make qemu CPUS=1
sematest // run
rwsematest // main testing

kernel/semaphore.h
kernel/semaphore.c
```
- [semaphore.h][semaphore_h_9] | [semaphore.c][semaphore_c_9]

[semaphore_h_9]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab9-55/xv6-riscv/kernel/semaphore.h
[semaphore_c_9]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab9-55/xv6-riscv/kernel/semaphore.c
--------------------------------------------------
### __Assignment 10__
- [Lab10.md][lab10_md]

[lab10_md]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab10-55/Lab10-55.md
--------------------------------------------------
### __Assignment 11__
- [Lab11.md][lab11_md]

[lab11_md]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab11-55/Lab11-55.md
--------------------------------------------------