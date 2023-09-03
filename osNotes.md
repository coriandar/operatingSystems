
### __Create archive with tar__
#### Remove xv6 bloat
```java
cd xv6-riscv
make clean
```
#### Syntax
```java
tar -cvf <name of archive.tar> <path to directory to archive>
tar -cvf Lab3-55.tar lab3-55/
tar cvf Lab3-55.tar lab3-55/ //without hyphen is same as above.
```

#### Flags
```java
-c // create new archive.
-v // verbose, display name of files and directories as it processes.
-f // file, used to specify filename of the archive.
```

#### Checking
```java
tar -tf Lab5-55.tar // check sub-dir & files archived.
```
--------------------------------------------------
### __Extract archive with tar__
#### Syntax
```java
tar -xvf <name of archive.tar>
tar -xvf Lab3-55.tar`
```

#### Flags
```java
-x // extract archive.
-v // verbose, display name of files and directories as it processes.
-f // file, used to specify filename of the archive.
```
--------------------------------------------------
### __Qemu__
- Exit. `ctrl+a`, then release, press `x`.
--------------------------------------------------
### __Add a System Call to xv6-riscv__
1. New system call function prototype has been added to the list of existing system calls in `user.h`. i.e., `int getthisprocsize(void);`
2. Add an stub entry to `usys.pl` i.e., `entry("getthisprocsize");`
3. Give new system call a number in `syscall.h`, i.e., `#define SYS_getthisprocsize 22`
4. Add new system call function prototype to the existing list of `extern` functions in `syscall.c`, i.e., where `extern uint65 sys_close(void);` is, add to be last one like: `extern uint64 sys_getthisprocsize(void);`
5. Add new system call to the static array of pointers in `syscall.c`.
    - Imediately below there is a static array of pointers:
    ```c
    // A static variable remains in memory for the whole duration that the program is running. 
    static uint64 (*syscalls[])(void) = {
    . . .
    [SYS_close] sys_close,
    };
    ```
    - Add one corresponding to the new system call to the end of it. `[SYS_getthisprocsize] sys_getthisprocsize,`
6. Make sure system call function implementation has been entered into the appropriate C file of the kernel.
7. Test with: `make qemu`
--------------------------------------------------
### __Basic Linux Shell Commands__
```java
cat // creating & displaying short files
chmod // change file/dir permissions
date // display current date
echo // display argument in console
grep // search withn file/dir for specified text
gzip // file/dir archiver of .zip
gunzip // file/dir archiver of .zip
head // display the first few lines of file
less // display contents of file
setenv // set env variable within shell
sort // sort contents of file
tail // display last few lines of file
tar // create/extraxt archive .tar
wc // count num of char, words, lines
```
--------------------------------------------------
### __Makefile__
#### `<VARNAME> =`
- Define a variable name and initialize it to something
```c
 K=kernel
 QEMU = qemu-system-riscv64
```

#### `$<VARNAME>` or `$(<VARNAME>)`
- Replace with the value of the variable
```c
$K //will be replaced by kernel
$(QEMU) //will be replaced by qemu-system-riscv64
```

#### `<label>` or `<filename>`: other labels or filenames
- The label or filename before the colon is dependent on (or associated with) the labels and filenames that follow.
- If the date of the dependent files are newer then the following lines of actions will be taken. Otherwise ignore.
```c
$U/usys.o :  $U/usys.S
$(CC) $(CFLAGS) -c -o $U/usys.o $U/usys.S
// If usys.S has a newer date than usys.o, then it indicates that usys.o is out-of-date.
// The action is to compile usys.S to produce usys.o 
```

#### % (Wildcard)
- `%.o` means any file with extension .o

#### / (line continuation)
- The current line continues on the next line.
--------------------------------------------------
