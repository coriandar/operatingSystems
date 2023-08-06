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