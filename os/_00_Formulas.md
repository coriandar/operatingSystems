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

### How large is each page of memory
- The size of each page of memory can be calculated using the virtual address space and the size of the page table fields.
- The virtual address space is divided into three parts: a 9-bit top-level page table field, an 11-bit second-level page table field, and an offset. This means that the total number of bits used for addressing is 9 (top-level) + 11 (second-level) + 12 (offset) = 32 bits.
- Given that the computer uses a 32-bit address, the total number of possible addresses is 2^32.
- The size of each page of memory is determined by the size of the offset. Since the offset is 12 bits, each page is 2^12 bytes or 4 KB (kilobytes) in size.
- This is because 2^12 bytes equals 4096 bytes, which is the size of 4 KB.