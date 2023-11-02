# _Operating System Concepts_
## __1.1 What Operating Systems Do__
- An operating system can be roughly divided into four components:
    1. Hardware - provides basic computing resources for system.
    2. OS - controls hardware, coordinates its use among various apps/users.
    3. Application Programs - define ways in which these resources are used.
    4. User
- Can a computer system as consisting of hardware, software, and data.
- OS provides and `environment` within which other programs can do work.
--------------------------------------------------
### __1.1.1 User View__
- User view of PC varies according to interface being used.
- PC/laptop, designed for one user to monopolize resources.
- Goal is to maximise the work that user is performing.
- In this case, OS designed mostly for `ease of use`, with some attention paid to performance and security and none paid to `resource utilization` (how various hardware and software resources are shared).
- Some computers hace little or no user view. For example, `embedded computers` in home devices and automobiles may have numeric keypads and may turn indicator lights on or off to show status, but they and their operating systems and application are designed primarily to run without user intervention.

#### Abstract view of components of computer system
```js
       +-------+
       | user  |
       +-------+
           |
+-----------------------+
| application programs  |
+-----------------------+
   |        |        |
+-----------------------+
| operating system      |
+-----------------------+
   |        |        |
+-----------------------+
| computer hardware     |
+-----------------------+
```
--------------------------------------------------
### __1.1.2 System View__
- System view, OS is `resource allocator`.
- computer system has many resources that may be required to solve a problem.
- OS acts as the manager of these resources.
- OS must decide how to allocate them to specific programs and users so that it can operate the computer system efficiently and fairly.
- Slightly different view emphasizes the need to control various I/O devices and user programs.
- OS is a `control program`, manages the execution of user programs to prevent errors and improper use of the computer. It is especially concerned with the operation and control of I/O devices.
--------------------------------------------------
### __1.1.3 Defining Operating Systems__
- OS covers many roles and functions.
- In general no completely adequate definition of and operating system.
- Exist as they offer a reasonable way to solve the problem of creating a usable computing system.
- Fundamental goal of computer systems is to execute programs and to make solving user problems easier.
- In addition, no universally accepted definition of what is part of the operating system.
- Simple viewpoint is that it includes everything a vendor ships system.
- More common definition, one we normally follow is that OS is the one program running at all times on computer - the `kernal`.
- Along with kernal there are two types of programs: `system programs` and `application programs`

### Summary
- OS includes the always running `kernal`, middleware frameworks that ease application development and provide features, and system programs that aid in managing the system while it is running.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __1.2 Computer-System Organization__
- A modern general-purpose computer system consists of one or more CPUs and a number of device controllers connected through a common `bus` that provides access between components and shared memory.
- Each device controller is in charge of a specific type of device.
- Depending on controller more than one device may be attached.
- Typically, OS have a `device driver` for each device controller. This device driver understands the device controller and provides the rest of the OS with a uniform interface to the device.
- CPU and device controllers can execute in parallel, competing for memory cycles.
- To ensure orderly access to the shared memory, a memory controller synchronizes access to the memory.
--------------------------------------------------
### __1.2.1 Interrupts__
#### 1.2.1.1 Overview
- To inform that an operation has finished.
- Hardware may trigger an interrupt at any time sending a signal to the CPU, usually bu way of the system bus.
- Interrupts are used for many other purposes as well and are a key part of how operating systems and hardware interact.
- When CPU is interrupted, it stops what it is doing and immediately transfers execution to a fixed location.
- The fixed location ususally contains the starting adress where the service routine for the interrupt is located.
- The interrupt service routine executes; on completion, the CPU resumes the interrupted computation.
- Interrupt must transfer control to the appropriate interrupt service routine.
- Must be handled quickly as happen very frequently.
- A table of pointers to interrupt routines can be used instead to provide the necessary speed. The interrupt routine is called indirectly through the table, with no intermediate routine needed.
- Generally, the table of pointers is stored in low memory(first hundred or so locations).
- This array or `interrupt vector`, of addresses is then indexed by a unique number, given with the interrupt request, to provide the address of the interrupt service routine for the interrupting device.
- Interrupt architecture, must also save the state of whatever was interrupted.
#### 1.2.1.2 Implementation
- Basic interrupt mechanism, CPU hardware has a wire called `interrupt-request line` that the CPU senses after executing every instruction.
- When CPU detects that a controller has asserted a signal on the interrupt-request line, it reads the interrupt number and jumps to the `interrupt-handler routine` by using the interrupt number as an index into the interrupt vector. It then starts execution at the address associated with that index.
- Interrupt handler saves any state it will be changing during its operation, determines the cause of the interrupt, performs the necessary processing, performs a state restore, and executes a `return_from_interrupt` instruction to return the CPU to the execution state prior to the interrupt.
##### Interrupt steps
- Say that device controller `raises` an interrupt by asserting a signal on the interrupt request line.
- The CPU `catches` the interrupt.
- Then `dispatches` it to the nterrupt handler
- Handler `clears` the interrupt by servicing the device.
- Basic interrupt mechanism described enables the CPU to respond to an asynchronous event, as when a device controller becomes ready for service.
##### Interrupt handing features
- In a modern OS, however, we need more sophisticated interrupt-handling features:
    1. Need the ability to derfer interrupt handling during critical processing.
    2. Need an efficient way to dispatch to the proper interrupt handler for a device.
    3. Need multilevel interrupts, so that the OS can distinguish between high- and low-priority interrupts and can respond with the appropriate degree or urgency.
- In modern computer hardware, these three features are provided by the CPU and the `interrupt-controller hardware.`
##### Interrupt request lines.
- Most CPUs have two interrupt request lines. One is the `nonmaskable interrupt`, reserved for events such as unrecoverable memory errors.
- Second line is `maskable`, it can be turned off by the CPU before the execution of critical instruction sequences that must not be interrupted. The maskable interrupt is used by device controllers to request service.
##### Interrupt Chainging
- Computers have more devices that they have address elements in the interrupt vector. Common way to solve this problem is to use `interrupt chaining` in which each element in the interrupt vector points to the head of a list of interrupt handlers.
- When an interrupt  is raised, the handlers on the corresponding list are called one by one, until one is found that can service the request.
- This structure is compromise between the overhead of a huge interrupt table and the inefficiency of dispatching to a single interrupt handler.
##### Interrupt priorty levels
- The interrupt mechanism also implements a system of `interrupt priority levels`.
- These levels enable the CPU to defer the handling of low-priority interrupts without masking all interrupts and makes it possible for a high-priority interrupt to preempt the execution of a low-priority interrupt.
##### Interrupt summary
- Interrupts are used through modern OS to handle asynchronous events (and others).
- Device controllers and hardware faults raise interrupts.
- To enable the most urgent work to be done first, modern computers use a system of interrupt priorities.
- Because interrupts are used so heavily for time-sensitive processing, efficient interrupt handling is required for good system performance.

```java
             CPU
             1
       +---------------+       +---------------+
       | device driver |   2   |               |
 ----> | initiates I/O | ----> | initiates I/O | ----
|      |               |       |               |     |
|      +---------------+       +---------------+     |
|             |                                      |
|      CPU executing checks for                      |
|      interrupts between instructions             3 |
|             |                                      |
|             ▼                                      |
|      +---------------+       +---------------+     |
|      | CPU receiving |   4   | input ready,  |     |
|      | interrupt,    | <---- | output        | <---
|      | transfers to  |       | complete, or  |
|      | interrupt     |       | error         |
|      | handler       |       | generates     |
|      |               |       | interrupt     |
|      |               |       | signal        |
|      +---------------+       +---------------+
| 7         5 |
|             ▼
|      +---------------+
|      | interrupt     |
|      | handler       |
|      | processes     |
|      | data, returns |
|      | from          |
|      | interrupt     |
|      +---------------+
|           6 |
|             ▼
|      +---------------+
|      | CPU resumes   |
 ----- | processing    |
       | of            |
       | interrupted   |
       | tasks         |
       +---------------+
```
--------------------------------------------------
### __1.2.2 Storage Structure__
- CPU can load instructions only from memory.
- So any program must first be loaded into memory to run.
- General-purpose computers run most of their programs from rewritable memory, RAM (main memory).
- RAM commonly implemented in a semiconductor tech called `dynamic random-access memory (DRAM)`.
- First program to run on power-on is a `bootstrap program`, which then loads OS, RAM volatile so can't hold the bootstrap.
- `Electrically erasable programmable read-only memory (EEPROM)`can be changed but cannot be changed frequently. In addition, it is low speed, contains mostly static programs and data, infrequently used. i.e iphone use EEPROM to store serial number and hardware infor about the device.

#### Bytes
- All forms of memory provide an array of bytes. Each byte has its own address. Interaction is achieved through a sequence of load or stor instructions to specific memory addresses.
- The load instruction moves a byte or word from main memory to an internal register within the CPU, whereas the store instruction moves the content of a register to main memory.
- Aside from explicit loads and stores, the CPU automatically loads instructions from main memory for execution from the location stored in the program counter.

#### Instructions
- Typical instructin - execution cycle, as executed on a system with a `von Neumann architecture`, first fetches and instruction from memory and stores that instruction in the `instruction register`.
- Instruction is the decoded and may cause operands to be fetched from memory and stored in some internal register.
- After instruction on the operands has been executed, the result may be stored back in memory.
- Notice that only the memory unit sees only a stream of memory addresses. it does not know how they are generated (by the instruction counter, indexing, indirection, literal addresses, or some other means) or what they are for (instructions or data).
- Accordingly can also ignore how a memory address is generated by a program.
- We are interested only in the sequence of memory addresses generated by the running program.
- Ideally want the programs and data to reside in main memory permanently. This arrangement usually is not possible on most systems for two reasons:
    1. Main memory is usually too small to store all need program and data permanently.
    2. Main memory, as mentioned, is volatile - it loses its contents when power is turned oof or otherwise lost.

#### Secondary storage
- Main requirement is that it be able to hold large quantities fo data permanently.

#### Storage Definitions and Notation
- Basic unit is `bit`
- `byte` is `8bits`
- `word` which is a given computer architecture's native unit of data.
- `word` made up of one or more bytes, i.e., pc with 64-bit registers and 64-bit memory addressing typically has 64-bit (8-byte) words.
- Computer executes many operations in its native word size rather than a byte at a time.
- Computer storage, along with most computer throughpur, is generally measured and manipulated in bytes and collections of bytes.

```java
+----+--------------+
| KB | 1024^1 bytes |
+----+--------------+
| MB | 1024^2 bytes |
+----+--------------+
| GB | 1024^3 bytes |
+----+--------------+
| TB | 1024^4 bytes |
+----+--------------+
| PB | 1024^5 bytes |
+----+--------------+
```

#### Common terminology
- Volatile storage will be referred to simply as `memory`.
- If need to emphasize a particular type of storage device, will be explicit.
- Nonvolatile storage, referred to as `NVS`. Vast majority of time spent will be secondary storage. Two distinct types:
    - __Mechanical__, i.e., HDD, optical disks
    - __Electrical__, i.e., flash memory, FRAM, NRAM, SSD

#### Summary
- Design of complete storage sustem must only use as much expensive memory as necessary while providing as much inexpensive, nonvolatile storage as posisble.
- Caches can be installed to improve performance where a large disparity in access time ot transfer rate exists between two components.
--------------------------------------------------
### __1.2.3 I/O Structure__
- Large portion of OS code is dedicated to managing I/O, both because of its importanec to the reliability and performance of a system and because of the varying nature of the devices.
- General-purpose computer system consists of multiple devices, all of which exchange data via a common bus. (Small amounts data).
- `Direct memory access (DMA)` for (bulk data).
- After setting up buffers, pointers, and counters for the I/O device, the deivce controller transfers and entire block of data directly to or from the device and main memory, with no intervention by the CPU.
- Only one interrupt is generated per block, to tell the device driver that the operation has completed, rather than the one interrupt per byte generated for low-speed devices.
- While the device controller is performing these operations, the CPU is available to accomplish other work.
- Some high-end systems use switch rahter than bus architecture. On these systems, multiple components can talk to other components concurrently, rather than competing for cycles on a shared bus.
- In this case, DMA is even more effective.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __1.3 Computer-System Architecture__
- ``Core` is component that executes instructions and registers for storing data locally.
--------------------------------------------------
### __1.3.1 Single-Processor Systems__
- Single processing core.
- The one main CPU with its core is capable of executing a general-purpose instruction set, including instructions from processes.
- These systems have other special-purpose processors as well.
- They may come is the form of device-specific processors, such as disk, keyboard, and graphic controllers.
- All of these special-purpose processors run a limited instruction set and do no run processes.
- Sometimes they are managed by the OS, in that the OS sends them information about their next task and monitors their status.
- In other systems or circumstances, special-purpose processors are low-level components built into the hardware. The OS cannot communicate with these processors; they do their jobs autonomously.
--------------------------------------------------
### __1.3.2 Multi-Processor Systems__
- Two or more.
- Processors share the computer bus and sometimes the clock, memory, and peripheral devices.
- The primary advantage of multiprocessor systems is increased throughput.
- Speed-up ratio with `N` processors is not `N``, however; it is less than `N`.
- When multiple processors cooperate on a task, a certain amount of overhead is incurred in keepig all the parts working correctly. This overhead, plus contention for shared resources, lowers the expected gain from additional processors.
- Benefit of this model is that many processes can run simultaneously wihtout causing performance to deteriorate significantly.
- However, one may be sitting idle, while another is overloaded.
- These inefficiencies can be avoided if the processors share certain data structures.
- This will allow for processes and reosources such as memory to be shared dynamically among the various processors and can lower the workload variance among the processors. Such a system must be written carefully.
#### Symmetric Multiprocessing (SMP)
- Each peer CPU processor performs all task, including operating-system functions and user processes.
- Each processor own set of registers as well as a private or local cache.
- However all processors share physical memory over the system bus.
#### Definition of multicore
- Evolved over time now includes `multicore` systems, in which multiple computing cores reside in a single chip.
- Multicore can be more efficient than multiple chips with single cores because on-chip communication is faster than between-chip communicaiton.
- One chip with multiple cores uses significantly less power than multple single-core chips, an important issue for mobile devices as well as laptops.
- Most architectures adopt multicore approach, where L2 cache is local to chip but shared by the two processing cores. Combining local and shared caches, where local, lower-level caches are generallu smaller and faster than higher-level shared caches.
- Aside from architectural considerations such as cahce, memory, and bus contention, a mulitcore processor with N cores appears to the operating system as N standard CPUs.
- This puts pressure on OS designers and app programmers to make efficient use of these processing cores.
- Virtually all modern OS, windows, macOS, linux, android, iOS support `multicore SMP` systems.

```java
+---------------------------------------------+
|                processor(0)                 |
| +----------------+       +----------------+ |
| |   CPU core(0)  |       |   CPU core(1)  | |
| | +------------+ |       | +------------+ | |
| | | registers  | |       | | registers  | | |
| | +------------+ |       | +------------+ | |
| |        |       |       |        |       | |
| | +------------+ |       | +------------+ | |
| | | L1 cache   | |       | | L1 cache   | | |
| | +------------+ |       | +------------+ | |
| |        |       |       |        |       | |
| +----------------+       +----------------+ |
|          |                        |         |
|   +-------------------------------------+   |
|   |              L2 cache               |   |
|   +-------------------------------------+   |
|                      |                      |
+---------------------------------------------+
                       |
                       |
+---------------------------------------------+
|                 main memory                 |
+---------------------------------------------+
```

#### Non-uniform memory access (NUMA)
- Adding additional CPUs to a multiprocessor system will increase computating power; however, does not scale well, as once add to many CPUs, contention for system bus becomes a bottleneck and performance begins to degrade.
- Alternative approach is instead to provide each CPU (or groups of CPU) with its own local memory that is accessed via a small, fast local bus. The CPUs are connected by a `shared system interconnect`, so that all CPUs share one physical address space.
- Advantage is that, when a CPU accesses its local memory, not only is it fast, but there is also no contention over the system interconnect.
- Can scale more effectively as more processors are added.
- Potential drawback, is increased latency when a CPU must access remote memory across the system interconnect, creating a possible performance penalty.
- Basically, CPU(0) cannot access the local memory of CPU(3) as quickly as it can access its own local memory, slowing down performance.
- Penalties can be minimized through careful CPU scheduling and memory management.
- Can scale to large number of processors, popular on servers as well as high-performance computing systems.

```java
+-----------+                 +-----------+
| memory(0) |                 | memory(1) |
+-----------+                 +-----------+
      |                             |
+-----------+  interconnect   +-----------+
| CPU(0)    | --------------- | CPU(1)    |
+-----------+ --------------  +-----------+
      | |                         | |
      | |                         | |
      | |   ----------------------  |
      | |  |                        |
      |  -------------------------  |
      |    |                      | |
      |    |                      | |
      |    |                      | |
+-----------+ --------------- +-----------+
| CPU(2)    | --------------- | CPU(3)    |
+-----------+                 +-----------+
      |                             |
+-----------+                 +-----------+
| memory(2) |                 | memory(3) |
+-----------+                 +-----------+
```

### Blade servers
- Systems in which multiple processor boards, I/O boards, and networking boards are placed in the same chassis.
- Difference is that each blade-processor board boots independently and runs its own OS.
- Essence, these servers consist of multiple independent multiprocessor systems.
--------------------------------------------------
### __1.3.3 Clustered Systems__
- Gathers together multiple CPUs.
- Differ from multiprocessor systems in that they are composed of two or more individual systems or nodes joined together.
- Each node is typically a multicore system.
- Such systems considered `loosely coupled`

```java
+-----------+   interconnect   +-----------+   interconnect   +-----------+
| computer  | ---------------- | computer  | ---------------- | computer  |
+-----------+                  +-----------+                  +-----------+
      |                              |                              |
      |                              |                              |
      |                              |                              |
      |                         +---------+                         |
       ------------------------ |   SAN   | ------------------------
                                +---------+
```

#### Definition clustered system
- Definition of clustered is not concrete.
- Generally accepted term is that clustered computer share storage and are closely linked via a local-area network LAN or a faster interconnect, such as InfiniBand.

#### High-availability service
- Clustering is usually used to provide high-availability service.
- Provides increased reliability, which is crucial in many applications. The ability to continue providing service proportional to the level of surviving hardware is called `graceful degradation`.
- Some systems go beyond graceful degradation and are called `fault tolerant`, because they can suffer a failure of any single component and still continue operation. Requires a mechanism to allow the failure to be detected, diagnosed, and, if possible, corrected.
- Service that will continue even if one or more systems in cluster fail.
- Generally, we obtain high availability by adding a level of redundancy in the system.
- A layer of cluster software runs on the cluster nodes. Each node can monitor one or more of the others (over the network).
- IF the monitored machine fails, the monitoring machine can take owernship of its storage and restart the applications that were running on the failed machine.
- The users and clients of the apps see only a brief interruption of service.

#### Asymmetric Clustering
- One machine is in `hot-standby mode` while the other is running the applications.
- Hot-standby host machine does nothin but monitor the active server.
- If server fails, the hot-standby host becomes the active server.

#### Symmetric Clustering
- Two or more hosts are running applications and are monitoring each other.
- Structure more effiecient, as it uses all of the available hardware.
- However, requires that more than one application be available to run.

#### High-performance computing
- Since clusters consist of several computer systems connected via a network, clusters can also be used to provide high-performance computing environments.
- Can supply significantly greater computational power than single-processor or even SMP (symmetric multiprocessing) systems because they can run an app concurrently on all computers in the cluster.
- Application must have ben written specifically to take advantage of the cluster, however.
- This involves a technique know as `paralelization`, which divides a program into seperate components that run in parallel on individual cores in a computer or computers in a cluster.
- Typically these app are designed so that once each computing node in the cluster has solved its portion of the problem, the results from all the nodes are combined into a final solution.

#### Parallel cluster
- Other forms of clusters include parallel clusters and clustering over a wide-area network (WAN).
- Parallel clusters allow multiple hosts to access the same data on shared storage.
- As most OS lack support for simultaneous data access by multiple hosts, parallel clusters usually require the use of special version of software and special releases of applications.

#### Distributed lock manager(DLM)
- Oracle Real Application Cluster is version of Oracle's database that has been designed to run on parallel cluster.
- Each machine has full access to all the data in database.
- To provide shared access, the system must also supply access control and locking to ensure no conflicting operations occur.
- Known as `DLM`

#### Storage-area Networks (SAN)
- Rapidly changing, many improvements made possible to (SAN).
- Allows many systems to attach to a pool of storage,
- If app and data are stored on the SAN, then cluster software can assign the app to run on any host that is attached to the SAN.
- If host fails, then any other host can take over.
- In database cluster, dozens of hosts can share the same database, greatly increasing performance and reliability.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __1.5 Resource Management__
- OS is a `resource manager`. System's CPU, memory space, file-storage space, and I/O devices are among the resources that the OS must manage.
--------------------------------------------------
### __1.5.1 Process Management__
- Program in execution is a process.
- For now, consider a process to be an instance of a program in execution, but later see this concept is more general.
- It is possible to provide system calls that allow processes to create subprocesses to execute concurrenly.
- Process needs certain resources, including CPU time, memory, files, and I/O devices to accomplish its task.
- Resources typically allocated to the process while it's running.
- In additon to various physical and logical resources that a process obtains when created, various initialization data (input) may be passed along. i.e. process running webbrowser, process given URL as input, execute appropriate instructions and system calls to obtain and display content. When process terminates, OS will reclaim any reusable resources.
- `Emphasis` that program by itself is not a process. A `program` is a passive entity, like contents of a file stored on disk, whereas a process is an active entity.
- A single-threaded process has one `program counter` specifying the next instruction to execute.
- Execution of such a process must be sequential. The CPU executes one instruction of the process after another, until the process completes.
- Further, at any time, one instruction at most is executed on behalf of the process. Thus, although two process may be associated with the same program, they are nevertheless considered two seperate execution sequences.
- Multithreaded process has multiple program counters, each pointing to the next instruction to execute for a given thread.
- A process is the unit of work in a system. A system consists of a collection of processes, some of which are OS processes (those that execute system code) and the rest of which are user processes.
- All these processes can potentially execute concurrently—by multiplexing on a single CPU core—or in parallel across multiple CPU cores.
#### OS is responsible for following activites in connection with process management:
- Creating and deleting both user and system processes.
- Scheduling processes and threads on the CPUs.
- Suspending and resuming processes.
- Providing mechanisms for process synchronization.
- Providing mechanisms for process communicaiton.
--------------------------------------------------
### __1.5.2 Memory Management__
- Main memory is central to operation of a modern computer system.
- Repository of quickly accessible data shared by the CPU and I/O devices.
- Generally the only large storage device CPU is able to address and access directly.
- For CPU to process data from disk, those data must first be transferred to main memory by CPU-generated I/O calls. In the same way, instrcutions must be in memory for the CPU to execute them.
- CPU reads instructions from main memory during the `instruction-fetch` cycle
- Both reads and writes data from main memory during `data-fetch` cycle.
- For program to be executed, it must be mapped to absolute addresses and loaded into memory.
- As program executes, it accesses program instructions and data from memory by generating these absolute addresses. Eventually, the program terminates, its memory space is declared available, and the next program can be loaded and executed.
- To improve both the utilization of the CPU and the speed of the computer's response to its users, general-purpose computers must keep several programs in memory, creating a need for memory management. Many different memory-management schemes are used, scehemes reflect various approaches, effectiveness depends on factors, such as hardware.
- OS is responsible for following activites in connection with memory management:
    - Keep track of which parts of memory are currently begin used and which process is using them.
    - Allocating and deallocating memory space as needed.
    - Deciding which processes (or parts of processes) and data to moce into and out of memory.
--------------------------------------------------
### __1.5.3 File-System Management__
- OS provides a uniform, logical view of information storage.
- File management is one of most visible componenets of an OS. Computers can store information on several different types of phsyical media.
- A file is a collection of related information defined by its creator. Commonlet represent programs and data.
- Data files may be numeric, alphabetic, alphanumeric, or binary.
- Concept of file is extremely general one.
- OS implements the abstract concept of a file by managing mass storage media and the devices that control them.
- OS is responsible for following activites in connection with file management:
    - Creating and deleting files.
    - Creating and deleting directories to organize files.
    - Supporting primitives for manipulating files and directories.
    - Mapping onto mass storage.
    - Backing up files on stable (nonvolatile) storage media.
--------------------------------------------------
### __1.5.4 Mass-Storage Management__
- Most programs - inclu. compilers, web browsers, word processors, and games -  are stored on these devices until loaded into memory.
- The programs then use the devices as both the source and destination of their processing.
- Due to frequent, extensive access, must be used efficiently.
- OS is responsible for following activites in connection with secondary storage management:
    - Mounting and unmounting
    - Free-space management
    - Storage allocation
    - Disk scheduling
    - Partitioning
    - Protection
--------------------------------------------------
### __1.5.5 Cache Management__
- Important princuple of computer systems.
- Information normally kept in some storage system (main memory).
- As it is used, it is copied into a faster storage system (the cache) on a temp basis.
- When need a particular piece of information, first check cache.
- If not use info from source, put copy into cache.
- Internal programmable registers provide a high-speed cache for main memory.
- Programmer or compiler implements the register-allocation and register-replacement algorithms to decide which information to keep in registers and which to keep in main memory.
- Other caches are implemented totally for hardware. For instances, most systems have an instruction cache to hold instructions expected to be executed next.
- Without this cache, CPU would have to wait several cycles while an instruction is fetched from main memory.
- Due to limited cache size `cache management` is an important design problem.
- Movement of information between levels of a storage hierarchy may be either explicit or implicit, depending on the hardware design and the controlling OS software. For instance, data transfer from cache to CPU and registers is usually a hardware function, with no OS intervention. In contrast, transfer of data from disk to memory is usually controlled by the OS.

#### Characteristics of various types of storage
```java
+-------------------+-----------+-----------+------------+-----------+------------+
| LEVEL             | 1         | 2         | 3          | 4         | 5          |
+-------------------+-----------+-----------+------------+-----------+------------+
| Name              | registers | cache     | main mem   | ssd       | magnetic d |
+-------------------+-----------+-----------+------------+-----------+------------+
| Typical size      | < 1KB     | < 16MB    | < 64GB     | < 1TB     | < 10TB     |
+-------------------+-----------+-----------+------------+-----------+------------+
| Implemetation     | custom    | on-chip   | CMOS       | flash     | magnetic   |
| technology        | mem with  | or        | SRAM       | memory    | disk       |
|                   | multiple  | off-chip  |            |           |            |
|                   | ports     | CMOS      |            |           |            |
|                   | CMOS      | SRAM      |            |           |            |
+-------------------+-----------+-----------+------------+-----------+------------+
| Access time(ns)   | 0.25 -    | 0.5 -     | 80 -       | 25000 -   | 5000000    |
|                   | 0.5       | 25        | 250        | 50000     |            |
+-------------------+-----------+-----------+------------+-----------+------------+
| Bandwidth(MB/sec) | 20000 -   | 5000 -    | 1000 -     | 500       | 20 - 150   |
|                   | 100000    | 10000     | 5000       |           |            |
+-------------------+-----------+-----------+------------+-----------+------------+
| Managed by        | compiler  | hardware  | OS         | OS        | OS         |
+-------------------+-----------+-----------+------------+-----------+------------+
| Backed by         | cache     | main mem  | disk       | disk      | disk/tape  |
+-------------------+-----------+-----------+------------+-----------+------------+
```

#### Migration of interger A from disk to register
```java
+----------+     +------+     +-------+     +----------+
| magnetic |     | main |     |       |     | hardware |
| disk     | --> | mem  | --> | cache | --> | register |
|          |     |      |     |       |     |          |
+----------+     +------+     +-------+     +----------+
```

--------------------------------------------------
### __1.5.6 I/O System Management__
- One of the purposes of an OS is to hide peculiarties of specific hardware devices from the user. For example, in UNIX, peculiarities of I/O devices are hidden from the bulk of the OS itself by the `I/O subsystem`
- Only the device driver knows the peculiarities of the specific device to which it is assigned.
- I/O subsystem consists of several components:
    - A memory-management component that includes buffering, caching, and spooling.
    - A general device-driver interface
    - Drivers for specific hardware devices

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __2.1 Operating System Services__
- OS provides an environment for execution of programs. It makes certain services available to programs and to the users of those programs. The specific services provided, or course, differ from one OS to another, but can identify common classes.
- __User interface:__
    - Several forms, common GUI.
- __Program execution:__
    - System must be able to load a program into memory to run.
    - Program must be able to end its execution, either normally or abnormally.
- __I/O operations:__
    - Program may require file or I/O, for specific devices, special functions may be desired.
    - Provides means to do I/O.
- __File-system manipulation:__
    - Programs beed to read and write files and directories.
    - Create, delete, search
    - Some OS with permission management.
    - Many OS provide variety of file systems.
- __Communications:__
    - Process need exchange info with another process.
    - May occur between processes that are executing on the same computer or between processes that are executing on different computer systems tied together by network.
    - May be implemented via `shared memory`, or `message passing`.
- __Error detection:__
    - Detecting and correcting errors constantly.
    - Errors occur software/ hardware.
- __Resource allocation:__
    - Multiple processes need resources allocated to each.
- __Logging:__
    - Tracks which programs use how much and what kinds of computer resources.
- __Protection and security:__
    - Should not be possible for one process to interfere with others or with OS itself.
    - Protection involces ensuring that all access to system resources is controlled.
    - Security from outsiders through user authentication.

### __View of OS services__
```java
+----------------------------------------------------------------------------------------------+
|                          user and other system components                                    |
+----------------------------------------------------------------------------------------------+
|                               +------+-------+-----+                                         |
|                               | GUI  | touch | CLI |                                         |
|                               +--------------------+                                         |
|                               | user interfaces    |                                         |
|                               +--------------------+                                         |
+----------------------------------------------------------------------------------------------+
|                                     system calls                                             |
+----------------------------------------------------------------------------------------------+
| +------------------------------------------------------------------------------------------+ |
| | +-----------+ +------------+ +---------+ +---------------+ +------------+ +------------+ | |
| | | program   | | I/O        | | file    | | communication | | resource   | | accounting | | |
| | | execution | | operations | | systems | |               | | allocation | |            | | |
| | +-----------+ +------------+ +---------+ +---------------+ +------------+ +------------+ | |
| |        +-----------+                                              +------------+         | |
| |        | error     |                                              | protection |         | |
| |        | detection |                                              | & security |         | |
| |        +-----------+                                              +------------+         | |
| |                                     services                                             | |
| +------------------------------------------------------------------------------------------+ |
|                                   operating system                                           |
+----------------------------------------------------------------------------------------------+
|                                       hardware                                               |
+----------------------------------------------------------------------------------------------+
```

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __2.2 User and Operating-System Interface__
### __2.2.1 Command Interpreters__
- Most OS, incluing Linux, UNIX, and windows, treat the command interpreter as a special program that is running when a process is initiated or when a user first logs on.
- On systems with `multiple` command interpreters, interpreters know as `shells`.
- __Linux / UNIX:__
    - C Shell
    - Bourne-Again shell (BASH)
    - Korn shell
- Main function is to get and execute the next user-specified command.
- Many commands at this level manipulate files.
#### Approach 01
- Command interpreter itself contains the code to execute the command.
- For example to delete a file may cause the command intrepreter to jump to a section of its code that sets up the parameters and maked the appropriate system call. In this case the number of commands that can be given determines the size of the command intrepreter, since each command requires its own implementing code.
#### Approach 02
- Alternative approach, used by UNIX among other OS, implements most commands through system programs.
- In this case the command interpreter does not understand the command in any way; it merely uses the command to identify a file to be loaded into memory and executed.
- Thus `rm file.txt`, would search for file called `rm` load into memory, and execute it with the parameter `file.txt`
- Logic associated with the `rm` command would be defined completely by the code in the file `rm`
- This way programmers can add new commands to system easily by creating new files with the proper program logic.
- Command-interpreter which can be small, does not have to be changed for new commands to be added.
--------------------------------------------------
### __2.2.2 Graphical User Interface__
- Mouse-based window-and menu system.
--------------------------------------------------
### __2.2.3 Touch-Screen Interface__
- Smartphones and tablets.
--------------------------------------------------
### __2.2.4 Choice of Interface__
- System adminstrators / power users = CLI.
- CLI faster access to certain tasks, easier for repetitive.
- The user interface can vary from system to system and even from user to user within a system; however it typically is substantially removed from the actual system structure.
- The design of a usefule intuitive UI is therefore `NOT` a direct function of the OS.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __2.8 User and Operating-System Interface__
### __2.8.1 Monolithic Structure__
- Tightly coupled.
- Simplest structure for oganizing OS is no structure at all.
- That is to place all functionality of the kernal into a single, static binary file that runs in a single address space.
- Common technique for design OS.
- Original UNIX OS, example of limited structuring, consisting of kernal and system programs.
- Kernal provides fs, CPU sche, mem management, oter OS functions through system calls.

#### Monolithic advantage
- Monolithic kernals seem simple, but are difficult to implement and extend.
- Pro: distinct performance advantage.
- Con: very little overhead in system-call interface
- Despite drawbacks, speed and efficiency explains why we still see evidence of this structure in UNIX, Linux, and Windows.

#### Traditional UNIX system structure
```java
+----------------------------------------------------------------+
|                          (users)                               |
+----------------------------------------------------------------+
|                   shells & commands                            |
|                   compilers & interpreters                     |
|                   system libraries                             |
+----------------------------------------------------------------+
|               "system-call interface to kernal"                | ---
+----------------------------------------------------------------+   k|
| signals terminal       file system           CPU scheduling    |   e|
| handling               swapping block I/O    page replacement  |   r|
| character I/O system   system                demand paging     |   n|
| terminal dirvers       disk & tape drivers   virtual memory    |   a|
+----------------------------------------------------------------+   l|
|               "kernal interface to hardware"                   | ---
+----------------------+--------------------+--------------------+
| terminal controllers | device controllers | memory controllers |
| terminals            | disk and tapes     | physical memory    |
+----------------------+--------------------+--------------------+
```

#### Linux
- Linux OS is based on UNIX and is structured similary.
- App typically use the `glibc` standard C library when communicating with the system call interface to the kernal.
- Linux kernal is monolithic in that it runs entirely in kernal mode in a single address space.
- Also has a modular that allows the kernal to be modified during run time.
```java
+-----------------------+
| appications           |
|      +----------------+
|      | glibc standard |
|      | c lib          |
+------+----------------+
     |             |
     ▼             ▼
+-----------------------+
| system-call interface |
+-----------------------+
     |             |
     ▼             ▼
+----------+------------+
| file     | CPU        |
| systems  | scheduler  |
+----------+------------+
| networks | memory     |
| (TCP/IP) | manager    |
+----------+------------+
| block    | character  |
| devices  | devices    |
+----------+------------+
     |             |
     ▼             ▼
+-----------------------+
|    device drivers     |
+-----------------------+
     |             |
     ▼             ▼
+-----------------------+
|       hardware        |
+-----------------------+
```
--------------------------------------------------
### __2.8.2 Layered Approach__
- Loosely coupled.
- Divided into seperate, smaller components that have specific and limited functionality.
- All these components comprise the kernel.
#### Layers (Levels)
- `Layered approach`, OS broken into number of layers (levels)
- Layer 0: hardware
- Layer N: user interface
- Layer is an implementation of an abstract object made up of data and the operations that can manipulate those data.
- Typical OS layer, consists of data structures and a set of functions that can be invoked by higher-level layers.
#### Layered advantage
- Simplicity of construction and debugging.
- Layers are selected so that each uses functions(operations) and services of only lower-level layers.
- Each layer implemented only with operations provided by lower-level layers. Layer does not need to know how these operations are implemented; only what these operations do.
- Hence, each layer `hides` the existence of certain data structures, operations, and hardware from higher-level layers.
#### Layered disadvantage
- Relatively few OS use `pure` layered approach, challenge of appropriately defining the functionality of each layer.
- Overall performance is poor due to overhead of requiring a user program to traverse through multiple layers to obtain an OS service.
- `Some` layering `is` common in contemporary OS, Generally these system have fewer layers with more functionality, providing most of the advantages of modularized code while avoiding the problems of layer definition and interaction.
#### Layered usage
- Computer networks(TCP/IP):
    - Transmission Control Protocol (TCP): responsible for reliable data delivery between devices over the network. Breaks data into smaller packets, numbers them, and ensures they are reassembled correctly at the destination.
    - Internet Protocol (IP): responsible for addressing and routing data packets across the network. Assigns unique IP addresses to devices connected to the network, enabling them to be identified and located.
- Web applications.
--------------------------------------------------
### __2.8.3 Microkernals__
- Structures the OS by removing all nonessential components from the kernal and implementing them as user-level programs that reside in separate address spaces.
- Result is smaller lightweight kernal.
- Typically `microkernals` provide minimal process and memory management, in addition to a communication facility.

#### Main function
- Main function of microkernel is to provide communication between the client program and the various service that are also running in user space.
- Communication provided through message passing.
- i.e., if client program want to access a file, it must interact with the file server. Client program and service never interact directly. Rather they communicate indirectly exchanging messages with the microkernel.
- Similar to API.

#### Microkernel advantage
- Easier to extend OS.
- All new services added to user space, no modification to kernel.
- When kernal need modify, fewer changes.
- Easier to port from one hardware to another.
- More secure, reliable as most services are running as user processes.

#### Microkernel disadvantage
- Performance can suffer dues to increased system-function overhead.
- When two user-level services must communicate, messages must be copied between services, which reside in seperate address spaces.
- Additionally, OS may have switch from one process to the next to exhange the messages.
- Overhead for copy messages/switching processes, is largest stopper of growth.

#### Microkernal usage
- `Darwin`, kernel component of macOS and iOS.


#### Architecture of a typical microkernel
```java
  +---------------+   +------------+   +------------+
  | application   |   | file       |   | device     | user mode
  | program       |   | system     |   | driver     |
  +---------------+   +------------+   +------------+
       ^                ^        ^               ^
       |                |        |               |
+-----------------------------------------------------+
|      | messages       |        | messages      |    |
|       ----------------          ---------------     |
| +---------------+   +------------+   +------------+ |
| | interprocess  |   | memory     |   | CPU        | | kernel mode
| | communication |   | management |   | scheduling | |
| +---------------+   +------------+   +------------+ |
|                      microkernel                    |
+-----------------------------------------------------+
         ^                   ^                 ^
         |                   |                 |
         ▼                   ▼                 ▼
+-----------------------------------------------------+
|                       hardware                      |
+-----------------------------------------------------+
```
--------------------------------------------------
### __2.8.4 Modules__
- Perhaps best current methodolofy for OS design involves using `loadable kernel modeule (LKMS)`.
- Kernel has a set of core components and can link in additional services via modules, either at boot, or during runtime.
- Idea of design is for the kernel to provide core services, while other services are implemented dynamically, as the kernal is running.
- Linking service dynamically is preferable to adding new features directly to the kernel, which would require recompiling the kernal every time a change was made.
- i.e., build CPU scheduling and memory management algorithms directly into the kernal, and then add support for different file systems by way of loadable modules.
#### Modules advantage
- Overall result resembles a layered system in that each kernel section has defined, protected interfaces; but is more flexible than a layered system, because any module can call any other module.
- Similar approach to microkernal in that the primary module has only core fucntions and knowledge of how to lead and communicate with other modules; but is more efficient, because modules do not need to invoke message passing in order to communicate.
- For `Linux`, LKMs allow a dynamic and modular kernel, while maintaining the performance benefits of a monolithic system.
#### Modules implementation
- Common in modern implementations of UNIX, such as Linux, macOS, and Solaris, as well as Windows.
- Linux uses loadable kernel modules, primarily for supporting device drivers and file systems.
- `LKMs` can be "inserted" into the kernel at boot/runtime, i.e., when USB plugged in, can dynamically load the driver.
- `LKMs` can be removed during runtime as well.
--------------------------------------------------
### __2.8.5 Hybrid Systems__
- In practice, very few OS adopt a single, striclty defined structure.
- Combine different structures, resulting in hybrid systems.
- i.e., Linux:
    - monolithic, OS single address spave efficient performance.
    - also modular, new functionality dynamically added to kernel.
- i.e., Windows:
    - largely monolithic
    - retains behavious typical of micokernel systems
    - provide support for dynamically loaded kernel modules.

#### Windows Subsystem for Linux
- Windows uses a hybrid architecture that provide subsystems to emulate different OS env.
- These `user-mode subsystems` communicate with the Windows kernal to provide actual services.
- Win10, `WSL` allows native Linux app to run on win10.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __3.1 Process Concept__
- Although we personally prefer the more contemporary term process, the term job has historical significance, as much of operating system theory and terminology was developed during a time when the major activity of operating systems was job processing.
- Therefore, in some appropriate instances we use job when describing the role of the operating system.
- As an example, it would be misleading to avoid the use of commonly accepted terms that include the word job (such as job scheduling) simply because process has superseded job.
### __3.1.1 The Process__
- Process is a program in execution.
- Status of the current activity of a process is represented by the value of the `program counter` and te contents of the processor's registers.
#### Program
- Program is not process itself. It's a `passive` entity, such as a file containing a list of instructions stored on disk.
- In contrast, process is and `active entity`, with a program counter specifying the next instruction to execute and a set of associated resources.
- Program becomes a process when an executable file is loaded into memory.
- Two common techniques for loading executable files are double-clicking the icon, and entering the name of executable file in cli (as prog.exe or a.out).
#### Stack and Heap
- Each time function is called, an `activation record` containing function parameters, local variables, and the return address is pushed onto the stack; when control is returned from the function, the activation record is popped from the stack.
- Similarly, the heap will grow as memory is dynamically allocated, and will shrink when memory is returned to the system.
- Although stack and heap sections grow `toward` one another, OS must ensure they do `NOT` overlap.
#### Layout of a process in memory
```java
+-------+ max
| stack | // temp data store when invoke func
+-------+
|   |   |
|   ▼   | // stack and heap can grow dynamically
|       | // during program execution.
|   ▲   |
|   |   |
+-------+
| heap  | // mem dynamically allocated during runtiime
+-------+
| data  | // global variables
+-------+
| text  | // executable code
+-------+ 0
```
#### Processes
- Although 2 process may be associated with the same program, they are nevertheless considered two separate execution sequences.
- For instance, several users may be running different copies of the mail program, or the same user may invoke many copies of the web browser program.
- Each of these is a seperate process; and although the text sections are equivalent, the data, heap, and stack sections vary.
- Also common to have process that spawns many processes as it runs.
- Process itself can be execution environment for other code, JVM.
    - Command `java Program` runs the JVM as ordinary process, which in turn executes the Java program in the vm. Same concept as simulation.
--------------------------------------------------
### __3.1.2 Process State__
- Changes `state` as process executes.
- State defined in part by the current activity of that process.
#### States
- `New`, process is being created.
- `Running`, instructions are being executed.
- `Waiting`, process is waiting for some event to occur.
- `Ready`, process is waiting to be assigned to a processor.
- `Terminated`, process has finished execution.

#### Diagram of process state
```java
  +------------+                       +------------+
  |    new     |                       | terminated |
  +------------+                       +------------+
          | admitted                        ▲
          |    ----------------------       | exit
          ▼   ▼     interrupt        |      |
         +-------+                  +---------+
         | ready |                  | running |
         +-------+                  +---------+
          ▲    |  scheduler dispatch  ▲     |
          |     ----------------------      |
          |                                 |
          |          +---------+            |
           --------- | waiting | <----------
                     +---------+
    I/O or event                     I/O or event
    completion                       wait
```
--------------------------------------------------
### __3.1.3 Process Control Block__
- `PCB` serves as the repository for all the data needed to start, or restart, a process, along with some accounting data.
- Each process is represented in the OS by a `process control block (PCB)`.
- Also caled a `task control block`.
- __Process state:__
    - State may be new, ready, running, waiting, halted...
- __Program counter:__
    - Indicated the address of the next instruction to be executed for this process.
- __CPU registers:__
    - Registers vary in number and type, depending on the computer architecture.
    - Include accumulators, index registers, stack pointers, and general-purpose registers, plus any conition-code info.
    - Program counter and state must be saved during interrupt.
    - Allows of process to continue correctly after.
- __CPU-scheduling info:__
    - Includes a process priority, pointers to scheduling queues, and any other scheduling parameters.
- __Memory-management info:__
    - May include such items as the value of the base and limit registers and the page tables, or the segment tables, depending on the memory system used by the OS.
- __Accounting info:__
    - Includes amount of CPU and real time used, time limits, account numbers, jobs or process numbers...
- __I/O status info:__
    - Includes list of I/O devices allocated to the process, a list of open files, and so on.

#### Process control block(PCB) Diagram
```java
+--------------------+
| process state      |
+--------------------+
| process number     |
+--------------------+
| process counter    |
+--------------------+
|                    |
|     registers      |
|                    |
+--------------------+
| memory limits      |
+--------------------+
| list of open files |
+--------------------+
|                    |
|        •••         |
|                    |
+--------------------+
```
--------------------------------------------------
### __3.1.4 Threads__
- On systems that support threads, the PCB is expanded to include information for each thread.
- Other changes throughout the system are also needed to support threads.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __3.2 Process Scheduling__
- Objective of multiprogramming is to have some process running at all times so as to maximize CPU utilization.
- Objective of time sharing is to switch a CPU core among processes so frequently that users can interact with each program while it's running.
- `Process scheduler` selects and available process for program execution on a core.
- Each CPU core can run one process at a time.
- For systems with a single CPU core, there will never be more than one process running at a time.
- If there are more processes than cores, excess processes will have to wait until a core is free and can be rescheduled.
- Number of processes currently in memory is known as the `degree of multiprogramming`.
#### I/O Bound
- one that spends more of its time doing I/O than it spends doing computations.
#### CPU Bound
- in contrast, generates I/O requests infrequently, more time computations.
--------------------------------------------------
### __3.2.1 Scheduling Queues__
- As processes enter the system, they are put into a `ready queue`, where they are ready and waiting to execute on a CPU's core.
- Queue generally stored as a `linked list`.
- A ready-queue header contains pointers to the first PCB in the list, and each PCB includes a pointer field that points to the next PCB in the ready queue.
- System also includes other queues.
- When a process is allocated a CPU core, it executes for a while and eventually terminates, is interrupted, or waits for the occurance of a particular event, such as the completion of an I/O request.
- Once the process is allocated a CPU core and is executing, one of several events could occur:
    - Process could issue an I/O request and then be placed in an I/O wait queue.
    - Process could create a new child process and then be placed in a wait queue while it awaits the child's termination.
    - Process could be removed forcibly from the core, as a result of an interrupt or having its time slice expire, and be put back in the ready queue.

#### Queueing-diagram representation of process scheduling
- Two types of queues are present: the ready & wait queues.
```java
 --> +-------------+                                 \\\\\\\\\\\\\\ ---->
 --> | ready queue | ------------------------------> \ CPU        \ <---
|    +-------------+                                 \            \     |
|                                                    \\\\\\\\\\\\\\     |
|                                                                       |
|    \\\\\\\\\\\\\\      +----------------+      +----------------+     |
|--- \ I/O        \ <--- | I/O            | <--- | I/O            | <---|
|    \            \      | wait queue     |      | request        |     |
|    \\\\\\\\\\\\\\      +----------------+      +----------------+     |
|                                                                       |
|                                                +----------------+     |
|----------------------------------------------- | time slice     | <---|
|                                                | expired        |     |
|                                                +----------------+     |
|                                                                       |
|    \\\\\\\\\\\\\\      +----------------+      +----------------+     |
|--- \ child      \ <--- | child termi..  | <--- | create child   | <---|
|    \ terminates \      | wait queue     |      | process        |     |
|    \\\\\\\\\\\\\\      +----------------+      +----------------+     |
|                                                                       |
|    \\\\\\\\\\\\\\      +----------------+      +----------------+     |
 --- \ interrupt  \ <--- | interrupt      | <--- | wait for an    | <---
     \ occurs     \      | wait queue     |      | interrupt      |
     \\\\\\\\\\\\\\      +----------------+      +----------------+
```
--------------------------------------------------
### __3.2.2 CPU Scheduling__
- A process migrates among the ready queue and various wait queues throughout its lifetime.
- Role of `CPU scheduler` is to select from among the processes that are in the ready queue and allocatea CPU core to one of them.
- `CPU scheduler` must select a new process for the CPU frequently.

#### I/O & CPU bound processes
- An I/O-bound process may execute for only a few milliseconds before waiting for an I/O request.
- Although a CPU-bound process will requires a CPU core for longer durations, teh scheduler is unlikely to grant the core to a process for an extended period.
- Instead, likely designed to forcibly remove the CPU from a process and schedule another process to run.
- CPU scheduler executes `once every 100 miliseconds`, although typically much more frequently.

#### Swapping
- Some operating systems have an intermediate form of scheduling, known as `swapping`, whose key idea is that sometime it can be advantageous to remove a process from memory and reudce the degree of multiprogramming.
- Later process can be reintroduced to memory and resume.
- `Swapping` because a process can be "swapped out" from memory to disk.
- Typically only necessary when memory has been overcommited and must be free up.
--------------------------------------------------
### __3.2.3 Context Switch__
- Interrupts cause system to change a CPU core from it current task and to run a kernel routine.
- When occures need to save current `context` of the process running on the CPU core., so can be restored. Save states.
- Context is represented in the PCB of the process, includes the value of the CPU registers, the process state, and memory-management info.
#### State save
- Generically, it performs a `state save` of current state of CPU core, be it in kernel or user mode, and then `state restore` to resume operations.
#### Switching CPU core process
- Requires performing a state save of current process and a state restore of a different process.
- When context switch occurs, the kernal saves the context of the old process in its PCB and loads te saved context of the new process scheduled to run.
- Context switching is pure overhead, because the system does no useful work while switching.
- A typical speed is `several microseconds`.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __3.3 Operations on Processes__
- Processes in most systems can execute concurrently, and they may be created and deleted dynamically.

### __3.3.1 Process Creation__
- During course of execution, a process may create several new processes.
- Creating process is `parent process`.
- New processes are `children` of that process.
- Each new process may create other processes, forming `tree` of processes.

#### Process identifie (pid)
- Unique integer number, used to identify processes.
- Can be used as index to access various attributes of a process within the kernel.

#### fork()
- a Unix or Linux system call to create a new process by duplicating an existing running process.
- The new process is a child process of the calling parent process.
- `2^n - 1`, number of child processes, count last row.

#### systemd (Linux)
- Always `pid of 1`.
- Root parent process for all user processes.

#### init and systemd processes
- Traditional UNIX systems identify the process `init` as the root of all child processes.
- `init` (System V init) is assigned pid of 1, first process created at boot.
- Linux systems initially adopted `System V init` approach, but recent distros have replaced it with `systemd`.
- `systemd`, similar to `init`, but more flexible and can provide more services than init.

#### List processes
```java
ps -el
```

#### Child processes
- When process creates child, child will need certain resources (CPU time, memory, files, I/O devices) to accomplish its task.
- May be able to obtain its resources directly from the OS, or constrained to  subset of resources of parent.
- Restricting a child process to a subset of parents resources prevents any process from overloading the system by creating too many chile processes.

#### Parent process
- May need to partition its resources amoung its children, or may be able to share some resources (such as memory ot files) among several children.
- May also pass along initialization data (input) to child.

#### Execution possibilities for new process
1. Parent continues to execute concurrently with its children.
2. Parent waits until some or all of its children have terminated.

#### Address-space possibilities for new process
1. Child is a dup of parent process (same program & data as parent).
2. Child has a new program loaded into it.
--------------------------------------------------
### __3.3.2 Process Termination__
- Process terminates when it finished executing its final statement and asks the OS system to delete it by using `exit()` system call.
- Process then may return status value(int) to its waiting parent process (via wait() system all).
- All resources of process are deallocated and reclaimed by OS.

#### wait()
- system call, make a parent process wait for the termination of one of its child processes.
- This allows the parent process to synchronize with the child process and obtain information about its termination status.

#### Termination via system call
- Usually such a system call can only be invoked by the parent of process that is to be terminated.
- Parent need to know the identities of its children if it is to terminate them.
- When one process creates a new process, the identity of the newly created process is passed to the parent.

#### Reasons for parent to terminate its children
- Child has exceeded its usage of some of the resources that it has been allocated.
- Task assigned to child no longer required.
- Parent is exiting, OS doesn't allow child to continue if parent terminates.

#### Cascading termination
- Some systems do not allow a child to exist if its parent has terminated.
- If parent terminated, then all its children must be terminated.
- Normally initiated by OS.

#### Process table
- When process terminated, resources are dealocated.
- However entry in process table must remain until the parent calls `wait()`, as process table contains the process's exit status.

#### Zombie process
- Process that has terminated, but parent has not called `wait()`
- All process transition to this state when they terminated.
- Generally only exist as zombies briefly.
- Once parent calls `wait()`, process identifier of zombie process and its entry in the process table are released.

#### Orphans
- Parent does not invoke `wait()`.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __3.4 Interprocess Communication__
- Processes executing concurrently in the os may be either independent processes or cooperatin processes.
#### Independent process
- if it does not share data with any other process executing in the system.
#### Cooperating process
- if it can affect or be affected by the other processes executing in the system. i.e sharing data.

### __3.4.1 Reason for providing environment that allows coop__
#### Information sharing
- Since several apps may be interest in the same piece of info (i.e copy/pasting).
- Must provide and environment to allow concurrent access to such information.
#### Computation speedup
- Want particular task to run faster, must break into subtask.
- Each subtaske execute in parallel.
- Achievable if multiple processing cores.
#### Modularity
- Want to construct system in modular fashion.
- Dividing system functions into seperate processes of threads.

### __3.4.2 Interprocess Communication (IPC) Mechanism__
- Require for cooperating processes.
- Allow processes to exchange data.
#### Fundamental models of IPC
- Both common in OS, many OS implement both.
1. `shared memory`
2. `message passing`

##### Shared memory model
- Region of memory that is shared by cooperating processes is established.
- Processes can then exchange information by reading and writing data to the shared region.
- Can be faster than message passing, as does not require system calls.
- Only required to establish shared-memory regions.
- Once established, all accesses are treated as routine memory accesses, no kernel assitance.
```java
    +------------+
 -- | process A  |
|   +------------+
 -->| shared mem |<--
    +------------+   |
    | process B  | --
    +------------+
    |            |
    |            |
    |            |
    +------------+
    | kernel     |
    +------------+
```

##### Message passing model
- Communication takes place by means of messages exchanged between the cooperating processes.
- Useful for exchanging smaller amounts of data., as not conflicts need be avoided.
- Easier to implement in distributed system, compared to shared memory.
- Implemented with system calls, more time consuming task of kernel intervention.
```java
    +------------+
    | process A  | --
    +------------+   |
 -- | process B  |   |
|   +------------+   |
|   |            |   |
|   |            |   |
|   |            |   |
|   +------------+   |
|   | message qu |   |
|   +------------+   |
 -->|m0|m1|..|mn |<--
    +------------+
    | kernel     |
    +------------+
```
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __3.7 Examples of IPC Systems__
### __3.7.4 Pipes__
- IPC mechanism.
- Act a conduit allowing two processes to communicate.

#### __3.7.4.1 Ordinary Pipes__
- Allow two processes to communicate in standard producer-consumer fashion.
- Once processes have finished communicating and have terminated, ordinary pipes cease to exist.
- Unidirectional, allowing only one way communication.
- Two pipes required for two-way communication, each pipe sending data in diff direction.
- UNIX treats pipe as a special type of file, thus can be accesses using ordinary `read()` and `write()` system calls.

##### Communicate
- `producer` writes to one end of the pipe (the write end)
- `consumer` reads from other end (the read end)
```c
pip(int fd[])
// fd file descriptors
fd[0] // read end
fd[1] // write end
```

##### Access
- Ordinary pipe cannot be accessed from outside the process that created it.
- Typically, parent process creates a pipe and used it to communicate with child process that it creates via `fork()`
- Pipe special file, so child inherits from parent.
- Any writes by parent to its write end of pipe `fd[1]` can be read by the child from its read end `fd[0]`.

#### __3.7.4.2 Named Pipes__
- Provide more powerful communication tool than ordinary pipes.
- Bi-directional.
- No parent-child relationship required.
- Once named pipe established, several processes can use it for communication.
- Continue to exist after communicating processes have finished.
- `FIFOs` in UNIX systems.
- Appear as typical files in file system.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __4.1 Threads & Concurrency
### __4.1.1 Motivation__
- Most software applications that run on modern computers are multithreaded.
- Application is implemented as a seperate process with several threads of control.
- Applications can also be designed to perform several CPU-intensive tasks in parallel across the multiple computing cores.
- Most OS kernals are also typically multithreaded.
- Many applications can also take advantage of multiple threads, including basic sorting, trees, and graph algotrithms.
--------------------------------------------------
### __4.1.2 Benefits__
#### 1. Responsiveness
- May allow program to continue running even if part of it is blocked or it performing a lengthy operation.
- Especially useful in designing user interfaces.
- If time-consuming operation is performed in a seperate, asynchronous thread, the application remains resposive to user.

#### 2. Resource sharing
- Threads share memory and resources of the process to which they belong by default.
- Benefit of sharing code and data is that it allows an application to have several different threads of activity within the same address space.

#### 3. Economy
- Allocating memory and resources for process creation is costly.
- Threads share the resources of the process, more economical to create and context-switch threads.
- In general thread creation consumes less time and memory thatn process creation.
- Additionally, context switching is typically faster between threads than between processes.

#### 4. Scalability
- Benefits of multithreading can be even greater in a multiprocessor architecture, where threads may be running in parallel on different processing cores.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __4.2 Multicore Programming__
- On a system with a `single computing core`, concurrency means that the execution of the threads will be interleaved over time, because the processing core is capable of executing only one thread at a time.
- On a system with `mutilple core`, concurrency means that some threads can run in parallel, because the system can assign a seperate thread to each core.
- `Concurrency` supports more that one task by allowing all the tasks to make progress.
- `Parallelism` can perform more than one task simultaneouly.
- Possible to have concurrency without parallelism.

### __4.2.1 Programming Challenges__
#### 1. Identifying task.
- Involves examining application to find areas that can be divided into seperate, concurrent tasks.
- Ideally tasks are independent of one another and thus can run in parallel on individual cores.

#### 2. Balance
- Must also ensure that tasks perform equal work of equal value.
- Some instances, certain task may not contribute as much value to the overall process as other tasks.
- Using a seperate execution core to run that task may not be worth the cost.

#### 3. Data splitting
- The data accesses and manipulated by the task must be divided to run on seperate cores.

#### 4. Data dependency
- Data accessed must be examined for dependencies between two or more tasks.
- When one task depends on data from another, programmers must ensure that the execution of the tasks synchronized to accomodate the data dependency.

#### 5. Testing and debugging
- Running in parallel on multiple cores, many different execution pathsa are possible.
- Therefore inherently more difficult to debug/test.
--------------------------------------------------
### __4.2.2 Types of Parallelism__
#### Data parallelism
- Focuses on distributing subsets of the the same data across multiple computing cores and performing the same operation on each core.

#### Task parallelism
- Involves distributing tasks (threads) across multiple computing cores.
- Each thread is performing a unqiue operation.
- Different threads may be operating on the same data, or they may be operating on different data.
- Threads are operating in parallel on seperate computing cores, but each is performing a unqiue operation.

#### Summary
- Fundamentally, then, data parallelism involves distribution of data across multiple cores, and task parallelism involves distrubtion of tasks across multiple cores.
- Data and task parallelism are not mutually exclusive, and an application may in fact use a hybrid of these two strategies.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __4.3 Multithreading Models__
- `User threads`, are supported above the kernel and are managed without kernel support.
- `Kernal threads` are supported and managed directly by the OS.
- Relationship must exist between user and kernel threads.

### __4.3.1 Many-to-One Model__
- Maps many user-level threads to one kernel thread.
- Thread mananagement is done by the thread library in user space, so it is efficient.
- However, entire process with block is a thread makes a blocking system call.
- Only one thread can access the kernel at a time, multiple threads are unable to run in parallel on multicore systems.
--------------------------------------------------
### __4.3.2 One-to-One Model__
- Maps each user thread to a kernel thread.
- Provides more concurrency than the many-to-one model by allowign another thread to run when a thread makes a blocking system call.
- Also allows multiple threads to run in parallel on multiprocessors.
- Only drawbacks to this model is that creating a user thread requires creating a corresponding kernel thread, and a large number of kernel threads may burden the performance of a system.
--------------------------------------------------
### __4.3.3 Many-to-Many Model__
- Multiplexes many user-level threads to a smaller or equal number of kernel threads.
- The number of kernel threads may be specific to either a particular application or a particular machine.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __4.4 Thread Libraries__
- Provides programmer with an API for creating and managing threads.
- `First approach`, provide a library entirely in user space with no kernel support:
    - All code and data structures for the library exist in user space.
    - Invoking a function in library results in a local function call in user space and not a system call.
- `Second approach`, implement a kernel-level library supported directly by OS:
    - Code and data structures for library exist in kernel space.
    - Invoking a function in API for library typically results in a system call to the kernel.

### __4.4.1 Pthreads__
- Refers to the POSIX standard (IEEE 1003.1c) defining an API for thread creation and synchronization. This is `specification` for thread behaviour not `implementation`.
- In Pthreads program, seperate threads begin execution in a specified function.
--------------------------------------------------
### __4.4.2 Windows Threads__
- Similar to creating threads to the Pthreads technique.
- Data shared by the seperate threads are declared globally.
--------------------------------------------------
### __4.4.3 Java Threads__
- Fundamental model of program execution in a Java.
- All Java program comprise at least a single thread of control.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __4.6 Threading Issues__
### __4.6.1 The fork() and exex() System Calls__
- Some UNIX systems have chosen to have two versions of fork(), one that duplicates all threads and another that duplicates only the thread that invoked the fork() system call.
- If a thread invokes the exec() system call, the program specified in the parameter to exec() will replace the entire process—including all threads.
- Which of the two versions of fork() to use depends on the application. If exec() is called immediately after forking, then duplicating all threads is unnecessary, as the program specified in the parameters to exec() will replace the process. In this instance, duplicating only the calling thread is appropri- ate. If, however, the separate process does not call exec() after forking, the separate process should duplicate all threads.
--------------------------------------------------
### __4.6.2 Signal Handling__
- `signal` used to notify a process that a particular event has occured.
- Received either synchronously or asynchronously, depending on the source of and reason for the event being signaled.

#### All signals follow same pattern
1. A signal generated by the occurrance of a particular event.
2. The signal is delivered to a process.
3. Once delivered, signal must be handled.

#### Synchronous signals
- Delivered to the same process that performed the operation that caused the signal (reason why synchronous).

#### Asynchronous signals
- Typically sent to another process.

#### Signal Handlers
- `handled` by one of two possible handlers:
    1. A default signal handler.
    2. A user-defined signal handler.

#### Default signal handlers
- Every signal has default that kernel runs when handling signal.
- Default action can be overridden by a `user-define signal handler` that is called to handle the signal.
- Signals are handled in different ways. Some ignored, while others handled by terminating program.

#### Handling signals in single-threaded program
- Signals are always delivered to a process.

#### Handling signals in multi-threaded program
1. Deliver signal to the thread to which the signal applies.
2. Deliver the signal to every thread in the process.
3. Deliver the signal to certain threads in the process.
4. Assign a specific thread to receive all signals for the process.
--------------------------------------------------
### __4.6.3 Thread Cancellation__
- Involves terminating a thread before it has completed.
- Thread to be cancelled is often referred to as the `target thread`

#### Scenario 1: Asynchronous cancellation
- One thread immeditely terminated the target thread.

#### Scenario 2: Deferred cancellation
- Target thread periodically checks whether its should terminate, allowing it an oppurtunity to terminate itself in an oderly fashion.
--------------------------------------------------
### __4.6.4 Thread-Local Storage__
- Threads belonging to a process share the data of the process.
- Data sharing provides one of the benefits of multithreaded programming.
- Some instance each thread might need its own copy of certain data.
- For example, in a transaction-processing system, we might service each transaction in a separate thread. Furthermore, each transaction might be assigned a unique identifier. To associate each thread with its unique transaction identifier, we could use thread-local storage.
--------------------------------------------------
### __4.6.5 Scheduler Activations__
- One scheme for communication between user-thread library and the kernel is known as `scheduler activation`.
- Kernel provides an application with a set of virtual processors (LWPs)
- The application can schedule user threads onto and available virtual processor.
- Furthermore, the kernel must inform an application about certain events.
- This procedure is known as an `upcall`. Upcalls handled by the thread library with an `upcall handler` and upcall handlers must run on a virtual processor.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __5.1 Basic Concepts__
- Scheduling is fundamental OS function.
- Almost all computer resources are scheduled before use.

### __5.1.1 CPU-I/O Burst Cycle__
- Success of CPU scheduling depends on na observed proerty of processes: process execution consists of a `cycle` of CPU execution and I/O wait.
- Processes alternate between these two states.
- Process execution begins with a `CPU burst`, that is followed by an `I/O burst`, which is followed by another CPU burst,... so on....
- Eventually final CPU burst ends with a system request to terminate execution.
#### Burst lengths
- An I/O bound program typically has many `short` CPU bursts.
- CPU-bound program might have few `long` CPU bursts.
- This distribution can be important when implementing a CPU-scheduling algorithm.
--------------------------------------------------
### __5.1.2 CPU Scheduler__
- Whenever CPU becomes idle, OS must select one of the processes in ready queue to be executed.
- Selection process carried out by `CPU scheduler`.
#### Ready queue
- Ready queue can be implemented in FIFO, priorirty, a tree, unordered linked list.
- Conceptually, all processes in ready queue are lined up waiting for chance to run on CPU.
- Records in the queues are generally `process control blocks` (PCB) of the processes.
--------------------------------------------------
### __5.1.3 Preemptive and Nonpreemptive Scheduling__
#### CPU-scheduling decisions, circumstances
1. When a process switches from running to waiting state.
2. When a process switches from running to ready state.
3. When a process switches from waiting to ready state.
4. When a process terminates.

#### Nonpreemptive or cooperative
- Circumstance `1` and `4`.
- Once CPU has been allocated to a process, process keeps the CPU until it releases it either by terminating or by switching to the waiting state.

#### Preemptive
- Circumstance `2` and `3`.
- Almost all modern OS use preemtive.
- Can cause race conditions.
--------------------------------------------------
### __5.1.4 Dispatcher__
- Module that gives control of the CPU's core to the process selected by the CPU scheduler.
- Dispatcher should be as fast as possible, since it is invoked during every context switch.
#### Dispatch latency
- Time it takes dispatcher to stop one process and start another running.
#### Function involves:
- Switching context from one process to another.
- Switching to user mode.
- Jumping to the proper locaiton in the user program to resume that program.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __5.2 Scheduling Criteria__
### CPU utilization
- Important keep CPU as busy as possible.
- Real world, utilisation should range from 40% (light) to 90% (heavy)

### Throughput
- Measure of work is number of processes that are completed per time unit, called `throughput`.
- For long processes this rate may be one process over several seconds.
- For short transactions, may be tens of processes per second.

### Turnaround time
- Interval from the time of submission of a process to the time of completion.
- Sum of period spent waiting in the ready queue, exectuing on CPU, and doing I/O.

### Waiting time
- Sum of periods spent waiting in the ready queue.

### Response time
- Time it takes to start responding, not the time it takes to output a repsonse.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __5.3 Scheduling Algorithms__
### __5.3.1 First-Come, First-Served Scheduling__
- `FCFS`
- Simplest CPU-scheduling.
- Process that requess the CPU first is allocated the CPU first.
- Implementation managed with FIFO queue.
- Average waiting time is often long.
--------------------------------------------------
### __5.3.2 Shortest-Job-First Scheduling__
- `SJF`
- "Shortest-next-CPU-burst" algorithm.
- Associates with each process the length of the process's next CPU burst.
- When CPU is available, it's assigned to the process that has the smallest next CPU burst.
- If next CPU bursts of two processes are the same, `FCFS` is used to break tie.
--------------------------------------------------
### __5.3.3 Round-Robin Scheduling__
- Similar to `FCFS` but preemption is added to enable system to switch between processes.
- Small unit of time, called a `time quantum` or `time slice` is defined.
- `Time quantum` generally 10 to 100 milliseconds in length.
- Ready queue treated as a `circular queue`.
- CPU scheduler goes around the ready queue, allocatin the CPU to each process for a time interval of up to 1 time quantum.
--------------------------------------------------
### __5.3.4 Priority Scheduling__
- `SJF` is a special case of the general `priority-scheduling` algorithm.
- A priority is associated with each process, and the CPU is allocated to the process with the highest priority.
- Equal-priorty processes are scheduled in FCFS order.
- SJF is simply a priority algorithm where the priority is the inverse of the next CPU burst.
- The large the CPU burst, the lower the priority, and vice versa.
--------------------------------------------------
### __5.3.5 Multilevel Queue Scheduling__
- A multilevel queue scheduling algorithm can also be used to partition processes into several separate queues based on the process type.
--------------------------------------------------
### __5.3.6 Multilevel Feedback Queue Scheduling__
-  allows a process to move between queues.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __6.6 Semaphores__
- Mutex locks are generally considered the simplest of synchronization tools.
- Semaphores a more robust tool.
- An integer variable, accessed only through standard atomic operation: `wait()` and `signal()`
- All modifications to the integer value of the semaphore in the wait() and signal() operations must be executed atomically. 
- That is, when one process modifies the semaphore value, no other process can simultaneously modify that same semaphore value.

### __6.6.1 Semaphore Usage__
#### Counting semaphore
- Range over an unrestricted domain.
- Can be used to control access to a given resource consisting of a finite number of instances.
- Semaphore initialized to the number of resources available.
- Each process that wishes to use a resource
performs a wait() operation on the semaphore (thereby decrementing the count)
- When a process releases a resource, it performs a signal() operation (incrementing the count).
- When the count for the semaphore goes to 0, all resources are being used. After that, processes that wish to use a resource will block until the count becomes greater than 0.

#### Binary semaphore
- Range only between 0 and 1.
- Behave similarly to mutex locks.
--------------------------------------------------
### __6.6.2 Semaphore Implementation__
- When a process executes the wait() operation and finds that the semaphore value is not positive, it must wait. 
- However, rather than engaging in busy waiting, the process can suspend itself.
- The suspend operation places a process into a waiting queue associated with the semaphore, and the state of the process is switched to the waiting state. 
- Then control is transferred to the CPU scheduler, which selects another process to execute.
- Aprocess that is suspended, waiting on a semaphore S, should be restarted when some other process executes a signal() operation. 
-  The process is restarted by a wakeup() operation, which changes the process from the waiting state to the ready state. The process is then placed in the ready queue.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __9.1 Main Memory__
- CPU fetches instructions from memory according to the value of the program counter.
- These instructions may cause additional loading from and storing to specific memory addresses.

### __9.1.1 Basic Hardware__
- Main memory and the registers built into each processing core are the only general-purpose storage that the CPU can access directly.
- Any instructions in execution, and any data being used by instructions must be in one of these direct-access storage devices.
- If data are not in memory, must be moved there before CPU can operate on them.
- Memory access may take many cycles of CPU clock.

#### Seperate per-process memory space
- Protects the processes from each other and is fundamental to having multiple processes loaded in memory for concurrent execution.
- To seperate memory spaes, need ability to determine range of legal addresses that the process may access and to ensure that the process can acces only these legal addresses.
- Protection by using two registers.
- Protection achieved by having CPU hardware compare every address generated in user mode with registers.
- Basae and limit can only be loaded by OS, which uses privileged instruction.

#### Base register
- Holds smalled legal physical memory address

#### Limit register
- Specifies the size of the range


--------------------------------------------------
### __9.1.2 Address Binding__
- Addresses in source program are generally symbolic.
- A compiler `bind` these symbolic address to relocatable addresses.
- Linker in turn binds the relocatable addresses to `absolute` addresses.
- Each binding is a mapping from one address space to another.

#### Multistep processing of a user program
```java
+-------------+
| source      |
| program     |
+-------------+ ---
       |           |
       ▼           |
+-------------+    | compile
| compiler    |    | time
+-------------+    |
       |           |
       ▼           |
+-------------+ ---
| obj file    |
+-------------+
       |
       ▼
+-------------+
| linker      |
+-------------+ ---
       |           |
       ▼           |
+-------------+    | load
| exe file    |    | time
+-------------+    |
       |           |
       ▼           |
+-------------+ ---
| loader      |
+-------------+
       |
       ▼
+-------------+ ---
| program in  |    | execution time
| memory      |    | (run time)
+-------------+ ---
```

#### Compile time
- If know at compilte time where the process will reside in memory, then`absolute code` can be generated.
- If later, starting location changes, necessary to recompile.

#### Load time
- If not know at compile time where process will reside in memory.
- Then the compiler must generate `relocatable code`
- In this case, final binding is delayed until load time.
- If starting address changes, we only need reload user code to incorporate changed value.

#### Exectuion time
- If process can be moved during its execution from one memory segment to another, then binding must be delayed until run time.
- Special hardware must be available for this scheme to work.
- `Most OS use this method.`

--------------------------------------------------
### __9.1.3 Logical Versus Physical Address Space__
- Binding address at either compile of load time generates identical logical and physical addresses.
- Execution-time `address-binding-scheme` results in differing logical and physical addresses.

#### Logical Address
- Address generated by CPU.
- Virtual address.
- Range: `0 to max`

#### Physical Address
- Address seen by memory unit.
- That is, one loaded into the `memory-address register` of memory.
- Range: `R + 0 to R + max`

#### Physical Address Space
- Set of all physical addresses corresponding to these logical addresses.
- This in execution-time address-binding scheme, logical and physical address spaces differ.

#### Memory Management Unit (MMU)
```java
+-----+         +-----+         +-----------------+
| CPU | ------> | MMU | ------> | Physical memory |
+-----+         +-----+         +-----------------+
     logical addr     physical addr
```

#### Run-time mapping
- From virtual to physical is done by hardware device `MMU`.

#### User programs
- User program never accesses real physical addresses.
- Program can create pointer.
- User program deals with logical addresses.
- Memory mapping hardware converts logical to physical.
- User program generates only logical addresses and thinks that the process runs in memory location from `0 to max`.
- However, these logical address must be mapped to physical address before they are used.
- Concept of a logical address space that is bound to a seperate physical address space is `central` to proper memory management.

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __9.4 Structure of the Page Table__
### __9.4.1 Hierarchical Paging__
- Paging scheme that consists of two or more levels of page tables in a hierarchical manner.
- Modern OS support large logical address space. `2^32` to  `2^64`
- Bad to allocate the page table continuously in main memory.
- Simple solution is to divide page table into smaller pieces.
#### Two-level paging algorithm
- In which page table itself is also paged.
- Address translation works from the outer page table inward, scheme also know as `forward-mapped` page table.
- System with 64-bit logical address space, two-level paging scheme no longer appropriate.
#### Multi-level paging algorithm
- Avoid large page table, divide the outer pages into smaller pieces.
--------------------------------------------------
### __9.4.2 Hashed Page Tables__
- Handles address spaces larger than 32 bits.
- Hashed value being the virutal page number.
- Each entry in hash table contains a linked list of elements that hash to the same location.
- Each element consists of three fields:
    1. virtual page number,
    2. value of mapped page frame,
    3. a pointer to next element in linked list.
#### Algorithm
- Virtual page number in virtual address is hashed into the hash table.
- Virtual page number is compared with field 1 in the first element in the linked list.
- If match, corresponding page frame (field 2) is used to form the desired physical address.
- No match, subsequent entries in the linked list are searched for a matching virutal page number.
#### 64-bit address
- Variation uses `clustered page tables`.
- Similar to hash table, however, each entry refers to several pages.
#### Single page-table entry
- can store the mappings for multuple physical-page frames.
#### Clustered page table
- Particularly useful for `sparse` address sapves, where memory references are noncontiguous and scattered throughout the address space.
--------------------------------------------------
### __9.4.3 Inverted Page Tables__
- Typical page table drawback is that each page table may consist of millions of entries.
- Table may consume large amounts of physical memory just to keep track of how other phyiscal memory is being used.
#### Inverted page table
- Has one entry for each real page (or frame) of memory.
- Each entry consists of the virtual address of the page stored in that real memory location, wth information about the process that owns the page.
- Thus, only one page table is in the system, and it has only one entry for each page of physical memory.
- Often require that an address-sace identifier be stored in each entry of the page table, since table ususally contains several different address spaces mapping physical memory.
#### Inverted page-table entry
- Is a pair `<process-id, page-number>`
- where process-id assume role of address-space identifier.
#### Perfomance
- Decreases amount of memory used.
- Increases amount of tme needed to search table when page reference occurs.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __9.5 Swapping__
- Process instructions and data they operate on must be in memory to be executed.
- However, a process, can be `swapped` temporarily out to memory to a `backing store` and the brought back into memory for continued execution.
- Increases degree of multiprogramming in a system, as swapping makes possible for total physical address space of all processes to exceed the real physical memory of the system.

### __9.5.1 Standard Swapping__
- Involves moving entire processes between main memory and a backing store.
- Backing store is commonly fast secondary storage.
- When process or part swapped to the backing store, data structures associated with process must be written to the backing store.
- Multithreaded process, all per-thread data structures must be swapped as well.
#### Advantage
- Allows physical memory to be oversubscribed, so system can accomodate more process than there is actual physical memory to store them.
- Idle or mostly idle process are good candidates for swapping, any memory that has been allocated to these inactive processes can then be dedicated to active processes.
- If and active process that has been swapped out becomes active once again, it must then be swapped back in.
--------------------------------------------------
### __9.5.2 Swapping with Paging__
- Standard swapping was traditional in UNIX system.
- Generally, `no longer` used  in contemporary systems, to slow.
- Most systems, incl. Linux and Windows now use variation  of swapping in which pages of a process - rather than entire process - can be swapped.
- Allows for oversubscribed memory, but does not incur cost of swapping entire processes, as presumably only a small number of pages will be involved in swapping.
#### Contemporary terms
- `Swapping` now generally refers to standard swapping
- `Paging` refers to swapping with paging.
#### Page out/in operation
- Moves a page from memory to the backing store.
- Reverse is know as `page  in`
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __10.2 Demand Paging__
#### Page
- A page, memory page, or virtual page is a fixed-length contiguous block of virtual memory, described by a single entry in the page table. - It is the smallest unit of data for memory management in a virtual memory operating system.

### __10.2.1 Basic Concepts__
- Load pages only as they are needed.
- Loaded only when they are `demanded` during program execution.
- Crucial requirements for demand paging is ability to restart any instruction after a page fault.
- Because save state of interrupted process when the page fault occurs, must be able to restart the process in `exactly` the same plave and state.

#### Valid-invalid scheme
- Used to distinguish if in memory or secondary storage.
- Set to `valid`, associated page is both legal and in memory.
- Set to `invalid`, page either not valid, or valid but in secondary.
- Access to page marked as invalid = `page fault`.

#### Handling page fault
1. Check internal table for this process to deteremine whether the reference was a valid or an invalid memory access.
2. If reference was invalid, terminate process. If was valid but we have not yet brought in that page, we now page it in.
3. We find free frame.
4. Schedule a secondary storage operation to read the desired page into the newly allocated frame.
5. Storage read is complete, we modify the internal table kept with the process and the page table to indicate that the page is now in memory.
6. Restart the instruction that was interrupted by the trap. Process can now access the page as through it had always been in memory.

#### Pure demand paging
- Never bring a page into memory until it is required.

#### Hardware to support demand paging
- Same as hardware for paging and swapping
- `Page table`, this tble has the ability to mark an entry invalid through a valid-invalid bit or a special value of protection bits.
- `Secondary memory`, holds those pages that are not present in main memory.
--------------------------------------------------
### __10.2.2 Free-Frame List__
- When page fault occurs, OS must bring the desired page from secondary storage into main memory.
- To resolve page faults, most OS maintain a `free-frame list`, a pool of free frames for satisfying such requests.
- Free frames must also be allocated when the stack or heap segments from a process expand.
#### Zero-fill-on-demand
- OS typically allocate free frames with this technique.
- Zero-fill-on-demand frames are `zeroed-out` before being allocated, thus erasing previous contents.
#### System start up
- All available memory is plaved on the free-frame list.
- As free frames are requested, the size of the free-frame list shrinks.
- At some point, list either falls to zero, or falls below a certain threshold, at which point it must be repopulated.

--------------------------------------------------
### __10.2.3 Performance of Demand Paging__
- Can significantly affect the performance of a computer system.
#### Effective access time
```
effective access time = (1-p) x ma + p x page fault time
```
#### Three major task components of the page-fault service time
1. Service the page-fault interrupt.
2. Read in the page.
3. Restart the process.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __10.3 Copy-on-Write__
- Allows the parent and child processes initially to share the same pages.
- Shared pages are marked as copy-on-write pages
- If either process writes to a shared pages, a copy of the shared page is created.
- Only pages that need to be modified need be marked as copy-on-write.
### vfork()
- Does not use copy-on-write.
- Parent process is suspended, child process uses the address spave of the parent.
- If child process changes any pages of parent's address space, altered pages will be visible to the parent once it resumes.
- `vfork()` intended to be used when the child process calls `exec()` immediately after creation.
- Because no copying of pages takes place, vfork() is an extremely efficient method of process creation and is sometimes used to implement UNIX command-line shell interfaces.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __10.4 Page Replacement__
### __10.4.1 Basic Page Replacement__
- If no frame is free, we find one that is not currently being used and free it.
- Free a frame by writing its contents to swap space and changing the pages tbale to indicate that the page is no longer in memory.
- Page replacement is basic to demand paging.
- Completes the seperation between logical memory and physical memory.
#### Required algorithms to implement demand paging
1. ``Frame-allocation algorithm`
2. ``Page-replacement algorithm`

#### Belady's anomaly
- For some page-replacement algorithms, the page-fault rate may `increase` as the number of allocated frames increases.
--------------------------------------------------
### __10.4.2 FIFO Page Replacement__
- First in, first out.
- Associates with each page the time when that page was brought into memory.
- When page must be replaced, the older page is chosen.
- Can create FIFO queue to hold all pages in memory.
--------------------------------------------------
### __10.4.3 Optimal Page Replacement__
- Use of this page-replacement algorithm guarantees the lowest possible page-fault rate for a fixed number of frame, never suffer from Belady's anomaly.
- `Replace the page that will not be used for the longest period of time`.
--------------------------------------------------
### __10.4.4 LRU Page Replacement__
- If we use the recent past as an approximation of the near future, then we can replace the page that has not been used for the longest period of time.
- This approach is the `least recently used` (LRU) algorithm.
- LRU replacement associates with each page the time of that page’s last use.
- When a page must be replaced, LRU chooses the page that has not been used for the longest period of time.
--------------------------------------------------
### __10.4.5 LRU-Approximation Page Replacement__
--------------------------------------------------
### __10.4.6 Counting-Based Page Replacement__
- It requires that the page with smallest count to be replaced. It is based on the argument that the page with the smallest count was probably just brought in and has yet to be used.
--------------------------------------------------
### __10.4.7 Page-Buffering Algorithms__
- As an add-on to any previous algorithm.
- A pool of free frames is maintained.
- When a page fault occurs, the desired page is read into a free frame from the pool. The victim frame is later swapped out if necessary and put into the free frames pool.
--------------------------------------------------
### __10.4.8 Applications and Page Replacement__
- A typical example is a database, which provides its own memory management and I/O buffering. Applications like this understand their memory use and storage use better than does an operating system that is implementing algorithms for general-purpose use. Furthermore, if the operating system is buffering I/O and the application is doing so as well, then twice the memory is being used for a set of I/O.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.1 Overview of Mass-Storage Structure__
### __11.1.1 Hard Disk Drives__
- Relatively simple, each disk `platter` has a flat circular shape.
- Two surfaces of platter are covered with a magnetic material.
- Store information by recording it magnetically on the platters, and we read information by detecting the magnetic pattern on the platters.
- A `read-write head` "flies" just above each surface of every platter.
--------------------------------------------------
### __11.1.2 Nonvolatile Memory Devices__
- Are electrical rather than mechanical.
- Most commonly, such a device is composed of a controller and flash NAND die semiconductor chips, which are used to store data.
--------------------------------------------------
### __11.1.3 Volatile Memory__
- These "drives" can be used as raw block devices, but more commonly, file systems are created on them for standard file operations.
- RAM drives are useful as high-speed temporary storage space.
- Faster than NVM.
--------------------------------------------------
### __11.1.4 Secondary Storage Connection Methods__
- Secondary storage device is attached to the computer by the system bus or and `I/O bus`.
- Data transfers on a bus are carried out by special electronic processors called `controllers`.
- The `host controller` is the controller at the computer end of the bus.
- The `device controller` is built into each storage device.
--------------------------------------------------
### __11.1.5 Address Mapping__
- Storage devices are addresses as large one-dimensional arrays of `logical blocks`, where the logical block is the smallest unit of transfer.
- Each logical block maps to a physical sector or semiconductor page.
- The one-dimensional array of logical blocks is mapped onto the sectors or pages of the device.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.2 HSS Scheduling__
### __11.2.1 FCFS Scheduling__
- Simplest, first-come-first-served.
- Generally does not provide the fastest service.
- Can have wild swing between cylinders.
--------------------------------------------------
### __11.2.2 SCAN Scheduling__
- Also called `elevator algorithm`, first service all requests going up then down.
- Disk arm starts at one end of the disk and moves towards the other end.
- Servicing requests as it reaches each cylinder, until it gets to the other end of the disk.
- At the other end, the direction of head movement is reversed, and servicing continues.
- Head continuously scans back and forth.
--------------------------------------------------
### __11.2.3 C-SCAN Scheduling__
- Ciruclar SCAN, variant of SCAN.
- Designed to provice more uniform wait time.
- Similar to SCAN, but when head reaches end of disk, it immediately returns to begining of disk without servicing on return trip.
--------------------------------------------------
### __11.2.4 Selection of a Disk-Scheduling Algorithm__
#### Starvation
- Starvation in operating system occurs when a process waits for an indefinite time to get the resource it requires.
- Starvation is a scheduler issue. 

#### Deadlock
- Deadlock is a process design/distributed design issue.
- Deadlock is also known as circular waiting.

#### Selection
- SCAN and C-SCAN perform better for systems that place a heavy load on the disk, as less likely to cause starvation problem.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.3 NVM Scheduling__
- NVM devices offer much less of an advantage for raw sequential throughput, where HDD head seeks are minimized and reading and writing of data to the media are emphasized. In those cases, for reads, performance for the two types of devices can range from equivalent to an order of magnitude advantage for NVM devices.
- Writing to NVM is slower than reading.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.4 Error Detection and Correction__
- Error detection determines if a problem has occurred
- Parity is one form of `checksums`, which use modular arithmetic to compute, store, and compare values on fixed-length words. 
- Another error-detection method, common in networking, is a `cyclic redundancy check (CRCs)`, which uses a hash function to detect multiple-bit errors
- An `error-correction code (ECC)` not only detects the problem, but also corrects it.
- Error detection and correction are frequently differentiators between consumer products and enterprise products. ECC is used in some systems for DRAM error correction and data path protection, for example.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.5 Storage Device Management__
### __11.5.1 Drive Formatting, Partitions, and Volumes__
- New storage device is a blank slate.
- Before a storage device can store data, it must be divided into sectors that the controller can read and write.
--------------------------------------------------
### __11.5.2 Boot Block__
- This initial bootstrap loader tends to be simple. For most computers, the bootstrap is stored in NVM flash memory firmware on the system motherboard and mapped to a known memory location.
- It can be updated by product manufacturers as needed, but also can be written to by viruses, infecting the system. It initializes all aspects of the system, from CPU registers to device controllers and the contents of main memory.
--------------------------------------------------
### __11.5.3 Bad Blocks__
- More frequently, one or more sectors become defective. Most disks even come from the factory with bad blocks. Depending on the disk and controller in use, these blocks are handled in a variety of ways.
- On older disks, such as some disks with IDE controllers, bad blocks are handled manually.
- More sophisticated disks are smarter about bad-block recovery. The controller maintains a list of bad blocks on the disk. The list is initialized during the low-level formatting at the factory and is updated over the life of the disk.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __11.8 RAID Structure__
### __11.8.1 Improvement of Reliability via Redundancy__
- store extra information that is not normally needed but can be used in the event of disk failure to rebuild the lost information. 
--------------------------------------------------
### __11.8.2 Improvement of Performance via Parallelism__
- With multiple drives, we can improve the transfer rate as well (or instead) by striping data across the drives. In its simplest form, `data striping` consists of splitting the bits of each byte across multiple drives; such striping is called bit-level striping.
--------------------------------------------------
### __11.8.3 RAID Levels__
#### RAID level 0
- Non-redundant striping.
- Refers to drive arraus with striping at the level of blocks but without any redundancy.

#### RAID level 1
- Mirrored disks.

#### RAID level 4
- Block-interleaved parity.
- Also known as memory-style error-correcting-code organization.

#### RAID level 5
- Block-interleaved distributed parity.
- Differs from level 4 in that it spreads data and parity among all N+1 drives.

#### RAID level 6
- Also called P + Q redundnacy scheme.

#### Multidimensional RAID level 6
- Logically arranges drives into rows and columns (two or more dimensional arrays) and implements RAID level 6 both horizontally along the rows and vertically down the columns.
--------------------------------------------------
### __11.8.4 Selecting a RAID Level__
- RAID level 0 is used in high-performance applications where data loss is not critical.
- RAID level 1 is popular for applications that require high reliability with fast recovery.
--------------------------------------------------
### __11.8.5 Extensions__
- The concepts of RAID have been generalized to other storage devices, including arrays of tapes, and even to the broadcast of data over wireless systems.
- Commonly, tape-drive robots containing multiple tape drives will stripe data across all the drives to increase throughput and decrease backup time.
--------------------------------------------------
### __11.8.6 Problems with RAID__
- Unfortunately, RAID does not always assure that data are available for the operating system and its users.
--------------------------------------------------
### __11.8.7 Object Storage__
- Another approach to data storage is to start with a storage pool and place objects in that pool.
- Rather than being user-oriented, object storage is computer-oriented, designed to be used by programs.

#### Typical sequence
1. Create an object within the storage poo, and receive and object ID.
2. Access the object when needed via the object ID.
3. Delete the object via the object ID.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __12.2 I/O Hardware__
- A device communicates with a computer system by sending signals over a cable or even through the air.

### __12.2.1 Memory-Mapped I/O__
- controller has one or more registers for data and control signals.
- The processor communicates with the controller by reading and writing bit patterns in these registers. 
#### Registers (status)
- `data-in register`
- `data-out register`
- `status register`
- `control register`
--------------------------------------------------
### __12.2.2 Pollinig__
- Assume that 2 bits are used to coordinate the producer–consumer relationship between the controller and the host. The controller indicates its state through the busy bit in the status register.
- The controller sets the busy bit when it is busy working and clears the busy bit when it is ready to accept the next command.
- The host signals its wishes via the command-ready bit in the command register.
- The host sets the command-ready bit when a command is available for the controller to execute.
- In many computer architectures, three CPU-instruction cycles are sufficient to poll a device: read a device register, logical-and to extract a status bit, and branch if not zero.
--------------------------------------------------
### __12.2.3 Interrupts__
- CPU hardware has a wire called the interrupt-request line that the CPU senses after executing every instruction.
- When the CPU detects that a controller has asserted a signal on the interrupt-request line, the CPU performs a state save and jumps to the interrupt-handler routine at a fixed address in memory. 
- The interrupt handler determines the cause of the interrupt, performs the necessary processing, performs a state restore, and executes a return from interrupt instruction to return the CPU to the execution state prior to the interrupt.
--------------------------------------------------
### __12.2.4 Direct Memory Access__
- wasteful to use an expensive general-purpose processor to watch status bits and to feed data into a controller register one byte at a time—a process termed programmed I/O (PIO). 
- Computers avoid burdening the main CPU with PIO by offloading some of this work to a special-purpose processor called a direct- memory-access (DMA) controller. 
--------------------------------------------------
### __12.2.5 I/O Hardware Summary__
#### Main Concepts
- A bus
- A controller
- An I/O port and its registers
- The handshaking relationship between the host and a device controller
- The execution of this handshaking in a polling loop or via interrupts
- The offloading of this work to a DMA controller for large transfers
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __12.3 Application I/O Interface__
### __12.3.1 Block and Character Devices__
--------------------------------------------------
### __12.3.2 Network Devices__
--------------------------------------------------
### __12.3.3 Clocks and Timers__
--------------------------------------------------
### __12.3.4 Nonblocking and Asynchronous I/O__
--------------------------------------------------
### __12.3.5 Vectored I/O__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.1 File Concept__
- OS abstracts from the physical properties of its storage devices to defin a logical storage unit, the `fil`.
- Files are mapped by the OS onto physical devices.
- A file is a named collection of related information that is recorded on secondary storage.
- User perspective, file is the smallest allotment of logical secondary storage; that is data cannot be written to secondary storage unless they are within a file.

### __13.1.1 File Attributes__
- `Name`. Symbolic file name is the only information kept in humna-readable form.
- `Identifie`. This unique tag, usually a number, identifies the file within the file system; it is the non-human-readable name for the file.
- `Type`. This information is needed for systems that support different types of files.
- `Location`. This information is needed for systems that support different types of files.
- `Size`. The current size of the file (in bytes, word, or blocks) and possibly the maximum allowed size are included in this attribute.
- `Protection`. Access-control information determines who can do reading, writing, executing, and so on.
- `Timestamps and user identificatio`. This information may be kept for creation, last modification, and last use. These data can be useful for protection, security, and usage monitoring.
--------------------------------------------------
### __13.1.2 File Operations__
- `Creating a fil`. Requires space in the `fs`, and an entry for new file must be made in a directory.
- `Opening a fil`. If successfull, open() call returns a file handle that is used as an argument in the other calls.
- `Writing a fil`. System call specifying both the open file handle and the information to be written to the file.
- `Reading a fil`. System call that specifies the file handle and where (in memory) the next block of the file should be put.
- `Repositioning within a file`. Current-file-position pointer of the open file is repositioned to a given value.
- `Deleting a fil`. Search directory for the named file. Fouund associated directory entry, release all file space, so that it can be reused by other files, and erase or mark as free the directory entry.
- `Truncating a fil`. May want to erase content of a file, but keep its attributes. Allows all attributes to remain unchanged - except for the file length.

#### Several pieces of information are associated with an open file
- `File pointer`. This pointer is unique to each process operating on the file and therefore must be kept separate from the on-disk file attributes.
- `File-open count`. Tracks the number of opens and closes and reaches zero on the last close.
- `Location of the fil`. Most file operations require the system to read or write data within the file. The information needed to locate the file is kept in memory so that the system does not have to read it from the directory structure for each operation.
- `Access rights`. Each process opens a file in an access mode. This information is stored on the per-process table so the operating system can allow or deny subsequent I/O requests.
--------------------------------------------------
### __13.1.3 File Types__
- System uses the extension to indicate the type of the file and the type of operations that be done on that file.
- The UNIX system uses a `magic number` stored at the beginning of some binary files to indicate the type of data in the file.
--------------------------------------------------
### __13.1.4 File Structure__
- File types also can be used to indicate the internal structure of the file.
- Source and object files that match the expectations of the programs that read them.
- Certain files must conform to a required structure that is understood by the OS.
--------------------------------------------------
### __13.1.5 Internal File Structure__
- The logical record size, physical block size, and packing technique determine how many logical records are in each physical block.
- The packing can be done either by the user’s application program or by the operating system.
- In either case, the file may be considered a sequence of blocks. All the basic I/O functions operate in terms of blocks.
- The conversion from logical records to physical blocks is a relatively simple software problem.
- Because disk space is always allocated in blocks, some portion of the last block of each file is generally wasted.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.2 Access Methods__
### __13.2.1 Sequential Access__
- Simplest access method. Most common.
- Information in the file is processed in order, one record after another.
--------------------------------------------------
### __13.2.2 Direct Access__
- File made up of fixed-length `logical records` that allow programs to read and write records rapidly in no particular order.
- The direct-access method is based on a disk model of a file, since disks allow random access to any file block. 
- For direct access, the file is viewed as a numbered sequence of blocks or records. 
--------------------------------------------------
### __13.2.3 Other Access Methods__
- Other access methods can be built on top of a direct-access method.
- These methods generally involve the construction of an index for the file.
- The `index`, like and index in the back of a book, contains pointers to the various blocks.
- To find a record in the file, we first search the index and then use the pointer to access teh file directly and to find the desired record.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.3 Directory Structure__
#### Operations performed on a directory:
- `Search for a fil`.
- `Create a fil`.
- `Delete a fil`.
- `List a directoty`.
- `Rename a fil`.
- `Traverse the file system`.

### __13.3.1 Single-Level Directory__
- Simplest directory structure.
- All files are contained in the same directory.
- Since all files in same `dir`, must have unique names.
--------------------------------------------------
### __13.3.2 Two-Level Directory__
- Each user has own `user fil directory (UFD)`.
- UFDs have similar structure, but each lists only the files of a single user.
- When a user job starts or a user logs in, the system's `master fil directory (MFD)` is searched.
- The MFD is indexed by user name or account number, and each entry points to the UFD for that user.
--------------------------------------------------
### __13.3.3 Tree-Level Directories__
- A tree is the most common directory structure. The tree has a root directory, and every file in the system has a unique path name.
- A directory (or subdirectory) contains a set of files or subdirectories. In many implementations, a directory is simply another file, but it is treated in a special way. All directories have the same internal format. One bit in each directory entry defines the entry as a file (0) or as a subdirectory (1). 
--------------------------------------------------
### __13.3.4 Acrylic-Graph Directories__
- A shared directory or file exists in the file system in two (or more) places at once.
- A tree structure prohibits the sharing of files or directories. An acyclic graph—that is, a graph with no cycles—allows directories to share subdirec- tories and files.
- The same file or subdirectory may be in two different directories. The acyclic graph is a natural generalization of the tree-structured directory scheme.
--------------------------------------------------
### __13.3.5 General-Graph Directory__
- A serious problem with using an acyclic-graph structure is ensuring that there are no cycles.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.4 Protection__
### __13.4.1 Types of Access__
- `Read`. Read from the file.
- `Write`. Write or rewrite the file.
- `Execute`. Load the file into memory and execute it.
- `Append`. Write new information at the end of the file.
- `Delete`. Delete the file and free its space for possible reuse.
- `List`. List the name and attributes of the file.
- `Attribute change`. Changing the attributes of the file.
- Other operations, such as renaming, copying, and editing the file, may also be controlled.
--------------------------------------------------
### __13.4.2 Access Control__
- The most common approach to the protection problem is to make access dependent on the identity of the user. 

#### Classification of users
- `Owner`. The user who created the file is the owner.
- `Group`. A set of users who are sharing the file and need similar access is a group, or work group.
- `Other`. All other users in the system.
--------------------------------------------------
### __13.4.3 Other Protection Approaches__
- Another approach to the protection problem is to associate a password with each file. 
- More commonly encryption of a partition or individual files provides strong protection, but password management is key.
- In a multilevel directory structure, we need to protect not only individual
files but also collections of files in subdirectories; that is, we need to provide a mechanism for directory protection.
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.5 Memory-Mapped Files__
- One other very commonly user method for accessing files.
- Allows a part of the virtual address space to be logically associated with the file.

### __13.5.1 Basic Mechanism__
- Memory mapping a file is accomplished by mapping a disk block to a page (or pages) in memory. 
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __13.6 Summary__
- A file is an abstract data type defined and implemented by the OS. It is a sequence of logical records.
- Major task for OS is to map the logical file concept onto physical storage devices. Since physical record size may not be same as logical record size, may be neccessary to order logical records into physical records.
- Within `fs` useful to create directories to allow files to be organized. A single-level directory in a multiuser system causes naming problems, since each file must have a unique name. A two-level directory solves this problem by creating a separate directory for each user’s files. The directory lists the files by name and includes the file’s location on the disk, length, type, owner, time of creation, time of last use, and so on.
- The natural generalization of a two-level directory is a tree-structured directory. A tree-structured directory allows a user to create subdirectories to organize files. Acyclic-graph directory structures enable users to share subdirectories and files but complicate searching and deletion. A general graph structure allows complete flexibility in the sharing of files and directories but sometimes requires garbage collection to recover unused disk space.
- Remote file systems present challenges in reliability, performance, and security. Distributed information systems maintain user, host, and access information so that clients and servers can share state information to manage use and access.
- Since files are the main information-storage mechanism in most computer systems, file protection is needed on multiuser systems. Access to files can be controlled separately for each type of access—read, write, execute, append, delete, list directory, and so on. File p
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __18.1 Virtual Machines__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __18.2 History__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __18.3 Benefits and Features__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __18.4 Building Blocks__
### __18.4.1 Trap-and-Emulate__
--------------------------------------------------
### __18.4.2 Binary Translation__
--------------------------------------------------
### __18.4.3 Hardware Assisstance__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __18.5 Types of VMs and Their Implementations__
### __18.5.1 The Virtual Macine Life Cycle__
--------------------------------------------------
### __18.5.2 Type 0 Hypervisor__
--------------------------------------------------
### __18.5.3 Type 1 Hypervisor__
--------------------------------------------------
### __18.5.4 Type 2 Hypervisor__
--------------------------------------------------
### __18.5.5 Paravirtualization__
--------------------------------------------------
### __18.5.6 Programming-Environment Virtualization__
--------------------------------------------------
### __18.5.7 Emulation__
--------------------------------------------------
### __18.5.8 Application Containment__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

## __20.3 Kernel Modules__
### __20.3.1 Module Management__
--------------------------------------------------
### __20.3.2 Driver Registration__
--------------------------------------------------
### __20.3.3 Conflict Resolution__
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
▲
