### __Create archive with tar__
#### Format
- `tar -cvf <name of archive.tar> <path to directory to archive>`

#### Flags
- `-c`: create new archive.
- `-v`: verbose, display name of files and directories as it processes.
- `-f`: file, used to specify filename of the archive.

#### Archiving
- Where 55 is group number.
- Where `pwd` is one before lab3-55.
- `tar -cvf Lab3-55.tar lab3-55/`
- `tar cvf Lab3-55.tar lab3-55/`, without hyphen is same as above.
--------------------------------------------------
### __Extract archive with tar__
#### Format
- `tar -xvf <name of archive.tar>`

#### Flags
- `-x`: extract archive.
- `-v`: verbose, display name of files and directories as it processes.
- `-f`: file, used to specify filename of the archive.

#### Extracting
- `tar -xvf Lab3-55.tar`
--------------------------------------------------
### __Compiler__
```c
gcc prog1.c prog2.c // compile with linking, compiles one at time, a.out
gcc prog1.c prog2.c -o lab2prog // change output name
gcc -c prog2.c // compile without linking, output object file
gcc prog1.c prog2.c -o lab2linked // link object files
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
### __Shell script Operators__
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
### __Basic Linux Shell Commands__
```js
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