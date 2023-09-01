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
- user/[user.h][user_h] | [usys.pl][usys_pl] | [syscall.h][syscall_h] | [syscall.c][syscall_c] | [syscall.c][syscall_c] | [sysproc.c][sysproc_c] | [proc.c][proc_c] | [defs.h][defs_h] | [ps.c][ps_c] | [Makefile][Makefile_]

[user_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/user.h
[usys_pl]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/usys.pl
[syscall_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/syscall.h
[syscall_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/syscall.c
[sysproc_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/sysproc.c
[proc_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/proc.c
[defs_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/kernel/defs.h
[ps_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/user/ps.c
[Makefile_]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab4-55/xv6-riscv/Makefile
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
kernel/sysproc.c // implement system call
kernel/riscv.h // define PTE_A
user/pgaccess_test.h // add riscv.h, has PGSIZE defined
/Makefile // add _userprog

// add nextaddr function
kernel/vm.c // calls walk
kernel/defs.h // calls walk
```
- [user.h][user_h] | [usys.pl][usys_pl] | [syscall.h][syscall_h] | [syscall.c][syscall_c] | [sysproc.c][sysproc_c] | [riscv.h][riscv_h] | [pgaccess_test.h][pgaccess_test_h] | [Makefile][Makefile_] | [vm.c][vm_c] | [defs.h][defs_h]

[user_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/user.h
[usys_pl]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/usys.pl
[syscall_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/syscall.h
[syscall_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/syscall.c
[sysproc_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/sysproc.c
[riscv_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/riscv.h
[pgaccess_test_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/user/pgaccess_test.c
[Makefile_]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/Makefile
[vm_c]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/vm.c
[defs_h]: https://github.com/coriandar/operatingSystems/blob/main/assignments/lab6-55/xv6-riscv/kernel/defs.h
--------------------------------------------------
