# _Fundamentals of Linux_
## __2.01 The Linux Command Line__
- Is `shell`.
- Terminal screen or window lets access a Linux server's I/O.
- Shell just program that runs on server.
--------------------------------------------------
## __2.02 File globbing__
- For dealing with a lot of input files.
### Wildcard
```java
echo li*.conf // contains li*anything*.conf
```

### Question mark
```java
ls -d rc?.d// list all files have only ran char as third.
ls -d rc???.d// can be used multiple times
```

### Square brackets
- Defines ranges of allowed characters at a specific position.
```java
ls -l sub[ug]id // starting with sub, have u or g as fourth.
ls -l sub[012]id // can use numbers
```

### Minus
- Consecutive ranges of num/char
```java
ls /bin/m[a-z] [a-z] // all three-letter comman names in bin
```

### Exclamation
- Used in brackets to define something that must be in expansion results.
```java
ls -d rc[!256].d // exlude files with 256 as third char.
```

### Mixing
```java
ls /bin/[mM]ail* // list all mail programs in bin dir
```
--------------------------------------------------
## __2.03 Quoting commands__
1. Quoting
    - Putting special char and space into single quotes prevents shell expansion, treats as normal alphanumeric.
    - In single quotes nothing ever gets expanded, double quotes few exceptions.
2. Escaping
    - Does almost same as quotes.
    - Only disable shell expansion and every special meaning for next, and only the next, immediate char after backslash.
--------------------------------------------------
## __2.04 Getting help__
- `man mv`, manual for move.
--------------------------------------------------
## __2.05 Working with the Linux shell__
### Shortcuts
```java
ctrl + e // move cursor end of line
ctrl + a > ctrl + e > ctrl + a // sequence go back beginning
ctrl + arrow // move next/prev word
ctrl + k // delete text from cursor to end of command line
ctrl + u // delete text from cursor to start of command line

ctrl + r // search through command history, cycle through results
alt + . // insert last argument from prev command
ctrl + alt + e // expand a line manually without executing

man bash // more
```
--------------------------------------------------
## __2.06 Understanding standard streams__
- stdin, stdout, stderr, the three standard streams.
- Called streams as data is flowing continuously through a specific channel and gets processes or generated consecutively by the command.
- Can change `stdin` and `stdout` locations using certain files; this is called `redirection`.

### Redirection
- Input channel redirection `<`
- Output channel redirection `>`
- Address specific channel, correspondin nums `stdin(0), stdout(1), stderr(3)`
- When using output redir, stdout is expected, don't have write explicitly.
- 99% of all cases only redirect `stdout` and `stderr`

### stdout
```java
ls /var/lib/systemd/ > /tmp/stdout-output.txt // stdout channel
ls /var/lib/systemd/ 2> /tmp/stdout-output.txt // error message to txt
```

### Pipes
- One most fundamental concepts.
- Get one command output as input for another command.
```java
cat names.txt | sort // prints out names from txt, sorted.
cat names.txt | sort | uniq // only unique
cat names.txt | sort | uniq | wc // count words
```

### Appending
```java
echo 'World' >> /output.txt // use extra greater than to append
```
--------------------------------------------------
## __2.07 Understanding regular expressions__
```java
n // match end of line
t // match spave at the top
^ // match begin of line
$ // match end of line
[x] // classes of char to match at specific postion. Can define range.
[^x] // matches all char not defined in brackets
() // grouping
1 // user for back referencing.
a|b // means that at this position a or b are allowed
x* // match zero or multiple occurrance of x char at this position
y+ // match one or more multiple occurances of y char at this position
. // match any char at specific position
```

### grep
- Single quote meta characters, good practice.
- One of most important command-line tools.
- often used as a filter as part of a greater pipe.
- Goes through a text file or input stream, line by line, tries match search pattern.
```java
egrep // extended
grep -E // extended
grep -i // ignore case
grep -v // not contain
egrep '^day' /etc/services // match all lines starting with day
```
--------------------------------------------------
## __2.08 Working with sed__
- sed = stream editor.
- Processes files on a line-by-line basis.
- Often used in shell scripts to transform any command's output to a desired form for further processing.
- `sed [OPTION] 'pattern rule' FILE`

### Common Pattern
1. Used with a regular expression or other pattern to define which lines to change in an input file or stream,
2. Then provide a rule on how to change or transform the matched line.
```java
// 1. pipe the /etc/services file stream using cat into sed
// 2. sed processes the input stream line-by-line
// 3. all lines are not between line number 20 to 50 get handled directly over to the stdout channel, while lines number 20 to 50 get suppressed completely.
cat /etc/services | sed '20,50 d'
```

### Substitution mode
- Most important usage.
- Used to automate file or text editing without user interaction.
```java
// search for pattern between first slashes
//  and if and only if this pattern matches the text somewhere in the line in this file,
// will it be replaced by the text to be found between the other slash.
sed 's/hi/hello/' FILENAME // replace hi with hello first occurance
cat /text | sed 's/hi/hello/g' | less // all occurances
```
--------------------------------------------------
## __2.09 Working with awk__
- Text processing and manipulation.
- Language for actions similar to C.
- Contains programming constructs, incl variable, control flow.
- Enable create rule and action pairs, and for each record that matches this rule or condition, action will fire.
- Rules are called `patterns`, can use extended regex.
- Basic structure `awk [pattern] {action}...INPUTFILE`

```java
awk '{print $1}' /etc/networks // print out field 1 of all the lines of etc/networks file
```

--------------------------------------------------
## __2.10 Navigating the Linux filesystem__
```java
/bin // essential command needed for system
/boot // files needed for booting
/dev // device files fo system
/home // user home dir
/lib // libraries essential for binaries in /bin and /sbin
/media // mount point for removable media
/mnt // temporarily mounted filesystems
/opt // optional app software packages
/proc // virtual filesystem providing process and kernal info
/root // home dir of root user
/run // runtime variable data
/sbin // essential system binaries
/srv // data that should be served by system
/sys // infor about devices connected
/tmp // temp files
/usr // majority of user util/apps
/var // dir for all files expected to continually change
```
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
## __3.01 The Linux Filesystem__
- File's filename and data are two seperate concepts, not stored together.
--------------------------------------------------
## __3.02 Working with file links__
- Connecting filename to actual data is managed by filesystem using a table or database data structure, `title allocation table`.
- `Inode` is the actual entry point to beginning of specific files's data on hard disk.
- Simply: Inode represents the actual data of a file.

### Hardlink
- Filesystem management takes care that every normal file, upon creation, has one link entry in its allocation table to connect the actual filename to Inode.
- Very rare to create additional.
- File only, not for directories.

### Symbolic link
- Soft links.
- Type will commonly be used.
- Can use with directories.
- Link to filename not to Inode.
- If move or delete file/dir, break link.

### Manage links
```java
ln [OPTION] FILENAME // syntax
ln -s /etc/passwd // create symlink in current dir
```

--------------------------------------------------
## __3.03 Searching for files__
- `man find` get all flags.

```java
// background is it goes through the /etc directory and picks up all the files and subdir included in the /etc directory and it processes them recursively one by one.
find /etc -type f -name hello.txt
find / -type d -perm 777 // find all dir with rwx, print default
find / -type d -perm 777 chmod 755 {}; // change to 755
```
--------------------------------------------------
## __3.04 Working with users and groups__
- Every user has exactly one UID, can belong multiple groups/group id.
- Groups drastically simplify permission management.
--------------------------------------------------
## __3.05 Working with file permissions__
### Octal notations
```java
0 // ---
1 // --x
2 // -w-
4 // r--

3 // -wx
5 // r-x
6 // rw-
7 // rwx
```

### chown
```java
chown [username] : [groupname] [file] // syntax
chown :project_b file 4 // change only group
```

### chgrp
```java
chgrp project_a file 4 // change username & group
```

--------------------------------------------------
## __3.06 Working with text files__
### cat
```java
// concats three files to new file
cat /etc/passwd /etc/grp /etc/services > /tmp/concetenated-file
```

### head
```java
head /tmp/output // display first 10 lines
head -20 /tmp/output // display first 20 lines
```

### tail
```java
tail /tmp/output // display last 10 lines
tail -20 /tmp/output// display last 20 lines
```

### less
```java
less /tmp/output // display page, space next page, b back.
```

--------------------------------------------------
## __3.07 Working with VIM text editor__
- VIM, improved version and fully compatible to vi, text editor for UNIX developed in '70's.

### Marker
```java
ma // create marker called 'a', char [a-z]
`a // goes to marker a
```
- Very useful feature is to set marks at specific lines for referencing.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------