## 2017
### What is the main difference between User Level Processes and Kernel Level processes?
- `User level processes:` These processes are unpriveleged processes. They cannot directly access the hardware and different services of the system. To access the hardware and system services, they are dependen on Kernel Level Processes.
- `Kernel level processes:` These processes are privileged processes and they can access hardware directly and other system services.

### How a computer system differentiate between User Level Process and Kernel Level Process?
- In the processor, there is a Privilege Bit to identify the User Level Process and Kernel Level Process.

### Explain why cache is necessary to speed up process execution in the CPU?
- Cache is a small memory space in the CPU. Operating System transfer partial data and some instructions of currently running process from memory (RAM) into cache to speed up the access of CPU. In this way, we can increase the execution speed of a process.

### What is the main difference between Hot Cache and Cold Cache?
- `Hot Cache:` when cache contain the data and instructions of a currently running process then it is said the cache is hot and it will help to increase the execution speed of the current running process.
- `Cold Cache:` when cache does not contain the data and instruction of a currently running process then it is said the cache is cold and it will slowdown the execution speed of the current running process.

### Name three basic services of an Operating System.
- Process management
- File management
- Memory management
- Device management
- Storage management
- I/O management

### Fill in blanks...
- A program on Hard Disk (secondary storage) is a `Static` entity.
- A program in memory (RAM) is an `Active` entity.

### If two process P1 and P2 are running at the same time, what are the valid virtual address spave ranges they can have.
- P1: 0 - 64,000

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
