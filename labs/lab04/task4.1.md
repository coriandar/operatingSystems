## What is the name of the variable that contains a list of the user program i.e., cat.c, grep.c...?
- UPGROGS

## Which files and/or labels are associated with `qemu` label?
- $K/kernal
- fs.img

## What action will be performed if any of the files associated with the above labels/files have been changed?
- $(QEMU) $(QEMUOPTS).
- Which means run qemu-system-riscv64 with options $(QEMUOPTS)

## Apart from `make qemu`, what other possibilities are there?
- `make qemu-gbd`
- gdb is debugger, make a version of qemu that allows gdb running on another machine to connect to xv6 kernel for debugging.
