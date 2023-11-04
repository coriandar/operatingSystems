## Fork()
### Including the initial parent process, how many processes are created:
```c
int main()
{
   fork();
   fork();
   fork();
   return 0;
}
/**
forks parent and children each time
7 processes + 1 parent = 8 total

       +--------+
       | parent |
       +--------+
           |
       +--------+
fork() | child  |
       +--------+
           |
       +--------+ +-------+
fork() | child  | | child |
       +--------+ +-------+
           |
       +--------+ +-------+ +-------+ +-------+
fork() | child  | | child | | child | | child |
       +--------+ +-------+ +-------+ +-------+
*/
```
--------------------------------------------------

## Pages
### Page Number
```c
// if 2kB (2048)
// v addr = $3028 (12344)
pageNumber = Logical address / Page size
// ex: 12344 / 2048 = 6 (decimal)
```

### Offset of virtual address
```c
// if 2kB (2048)
// v addr = $3A38 (14904)
offset = Virtual Address %  Page Size
// ex: 14904 % 2048 = 568 = $238
```

### Page table
- What is the physical address corresponding to the virtual address `$07D0`?
- offset of `7D0` never changes
- do not need to calculate backwards.
- index 0 of pagetable = 2 then `$27D0`

### Effectiveness Equation
- Higher the hit ration, the more efficient the memory access.
```java
               Number of TLB hit
Hit ratio = ------------------------ x 100%
            Total num of page lookup
```

### Effective Memory-access Time
- `TLB hit ratio = 90%`
- TLB Access time = 10ns
- Main memory access time = 100ns
- if page hit rate increases, then effective access time decreases.
```java
Effective access time = 0.9 x 10 + ((1 - 0.9) x (10 + 100))
                      = 9 + 11 = 20ns

// increase hit rate to 95%
Effective access time = 0.95 x 10 + ((1 - 0.95) x (10 + 100))
                      = 9.5 + 5.5 = 15ns

// In a demand paging system, assume that it takes 1000 ms to service a page fault and the memory access time is 40 ms. What is the average access time if the page fault rate is 1%
// fault = 1% : TLB hit = 99%
// TLB access = 40ms
// service/main mem access = 1000ms
Effective access time = 0.99 x 40 + ((1 - 0.99) x (40 + 1000))
                      = 39.6 + 10.4  = 50ms
```

### How large is each page of memory
- The size of each page of memory can be calculated using the virtual address space and the size of the page table fields.
- Given that the computer uses a 32-bit address, the total number of possible addresses is 2^32.
- The virtual address space is divided into three parts: a 9-bit top-level page table field, an 11-bit second-level page table field, and an offset. This means that the total number of bits used for `addressing is 9 (top-level) + 11 (second-level) + 12 (offset) = 32 bits.`
- The size of each page of memory is determined by the size of the `offset (12 bits in this case)`. Each page is `2^12 bytes or 4 KB (kilobytes) in size` as 2^12 bytes equals 4096 bytes (4 KB).

### Find physical address if paging not used
```c
Physical Address = Base Address + Virtual Address
// must use hexademical calculator
// ex: $4600(base), $1234(virtual)
// physical = $4600 + $1234 = $5834
```

--------------------------------------------------

## CPU Scheduling
### Turnaround Time
- If no arival times stated, assume to be 0.

--------------------------------------------------

## Multithreading
### Semaphore
- Like bouncer.
- initial state set to max amount allowed in.
- two atomic operations, `Wait (P, decrements)`, and `Signal (V, increments)`

--------------------------------------------------

## Filesystem
### Data block
```c
total_blocks = total_data_size / block_size

// ex: A file system organize data into 4kB blocks. How much space should be reserved for the data block bitmap if a maximum of 4GB of data needs to be accommodated? 
// total_data_size = 4 * 1024 * 1024 # 4GB in kB
// block_size = 4 # in kB
// total_blocks = 1048576

// Since 1 byte = 8 bits, convert the size of the bitmap from bits to bytes by dividing by 8.
bitmap_size_bits = total_blocks
bitmap_size_bytes = bitmap_size_bits / 8
// 1048576 / 8 = 131072 bytes

bitmap_size_KB = bitmap_size_bytes / 1024
// 128

bitmap_size_blocks = bitmap_size_KB / block_size
// 128/4 = 32
```

--------------------------------------------------

## RAID Logical Block
### RAID Level 5 Left-symmetric
#### chunk size = 1 block
```c
// refer week 11 RAID slides
+--------+--------+--------+--------+--------+
| Disk 0 | Disk 1 | Disk 2 | Disk 3 | Disk 4 |
+--------+--------+--------+--------+--------+
|   0    |   1    |   2    |   3    |   P0   |
+--------+--------+--------+--------+--------+
|   5    |   6    |   7    |   P1   |   4    |
+--------+--------+--------+--------+--------+
|   10   |   11   |   P2   |   8    |   9    |
+--------+--------+--------+--------+--------+
|   15   |   P3   |   12   |   13   |   14   |
+--------+--------+--------+--------+--------+
|   P4   |   16   |   17   |   18   |   19   |
+--------+--------+--------+--------+--------+
```

#### chunk size = 2 block
```c
// logical block number 16 is placed on disk 3
+--------+--------+--------+--------+--------+
| Disk 0 | Disk 1 | Disk 2 | Disk 3 | Disk 4 |
+--------+--------+--------+--------+--------+
|  0,1   |   2,3  |   4,5  |   6,7  |   P0   |
+--------+--------+--------+--------+--------+
|  10,11 |  12,13 |  14,15 |   P1   |   8,9  |
+--------+--------+--------+--------+--------+
| 20,21  | 22,23  |   P2   | 16,17  | 18,19  |
+--------+--------+--------+--------+--------+
| 30,31  |   P3   | 24,25  | 26,27  | 28,29  |
+--------+--------+--------+--------+--------+
|   P4   | 32,33  | 34,35  | 36,37  | 38,39  |
+--------+--------+--------+--------+--------+
```

### RAID Level 5 Left-asymmetric
#### chunk size = 1 block
```c
// refer week 11 RAID slides
+--------+--------+--------+--------+--------+
| Disk 0 | Disk 1 | Disk 2 | Disk 3 | Disk 4 |
+--------+--------+--------+--------+--------+
|   0    |   1    |   2    |   3    |   P0   |
+--------+--------+--------+--------+--------+
|   4    |   5    |   6    |   P1   |   7    |
+--------+--------+--------+--------+--------+
|   8    |   9    |   P2   |   10   |   11   |
+--------+--------+--------+--------+--------+
|   12   |   P3   |   13   |   14   |   15   |
+--------+--------+--------+--------+--------+
|   P4   |   16   |   17   |   18   |   19   |
+--------+--------+--------+--------+--------+
```

#### chunk size = 2 block
```c
// logical block number 23 is placed on disk 4
+--------+--------+--------+--------+--------+
| Disk 0 | Disk 1 | Disk 2 | Disk 3 | Disk 4 |
+--------+--------+--------+--------+--------+
|  0,1   |   2,3  |   4,5  |   6,7  |   P0   |
+--------+--------+--------+--------+--------+
|  8,9   |  10,11 |  12,13 |   P1   | 14,15  |
+--------+--------+--------+--------+--------+
| 16,17  | 18,19  |   P2   | 20,21  | 22,23  |
+--------+--------+--------+--------+--------+
| 24,25  |   P3   | 26,27  | 28,29  | 30,31  |
+--------+--------+--------+--------+--------+
|   P4   | 32,33  | 34,35  | 36,37  | 38,39  |
+--------+--------+--------+--------+--------+
```

--------------------------------------------------

### I/O Time
```java
// week 11 disks
T(I/O) = T(seek) + T(rotation) + T(transfer)

// convert to milliseconds then divide by 2
// 1 minute = 60000ms
// rotational latency
T(rotation) = (1 / (RPM / 60000)) / 2

// A certain magnetic hard disk has a rotation speed of 12,000 RPM and a nominal transfer rate of 100 MB/s. Assuming a seek time of 10ms, what is the rate of I/O for 1MB of data?
// data = 1024KB
// seek = 10ms
// rotation = 12000 RPM = 1/12000 => ms = 5ms /2 = 2.5ms
// transfer = 1024KB / 102400KB/s = 0.01s => 10ms
// T(I/O) = 10ms + 2.5ms + 10ms
```

### Rate of I/O
```java
R(I/O) = Size(Transfer) / T(I/O)
// R(I/O) = 1024KB / 22.5ms = 45.51MB/s
// or
// R(I/O) = 1MB / 22.5ms = 44.44MB/s
```

### Find Rate I/O
- From lecture slides week 11
```java
// data = 4KB
// seek = 9ms
// rotation = 4ms
// transfer = 4KB / 107520KB/s = 0.04ms
T(I/O) = T(seek) + T(rotation) + T(transfer)
T(rotation) = (1 / (7200RPM / 60000)) / 2
// T(I/O) = 9ms + 4ms + 0.04ms = 13.04ms

R(I/O) = Size(Transfer) / T(I/O)
// R(I/O) = 4KB / 13.04ms = 0.3067 => 0.31MB/s
```

--------------------------------------------------
### HDD Scheduling
- OS is responsible for using the hardware efficiently.

```java
Fast access time = minimize seek time.
Disk bandwidth = 
                     Total number of bytes transferred
    -----------------------------------------------------------------------
    Time of completion of last transfer - time of first request for service
```
--------------------------------------------------

### struct dinode
- `NIDIRECT + 1` = 12 + 1

--------------------------------------------------
