
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	ade78793          	addi	a5,a5,-1314 # 80005b40 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	32a080e7          	jalr	810(ra) # 80002454 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e8a080e7          	jalr	-374(ra) # 8000205a <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	1f2080e7          	jalr	498(ra) # 800023fe <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1be080e7          	jalr	446(ra) # 800024aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	da6080e7          	jalr	-602(ra) # 800021e6 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	958080e7          	jalr	-1704(ra) # 800021e6 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	740080e7          	jalr	1856(ra) # 8000205a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	734080e7          	jalr	1844(ra) # 800025ec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	cc0080e7          	jalr	-832(ra) # 80005b80 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fe0080e7          	jalr	-32(ra) # 80001ea8 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	694080e7          	jalr	1684(ra) # 800025c4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	6b4080e7          	jalr	1716(ra) # 800025ec <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	c2a080e7          	jalr	-982(ra) # 80005b6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	c38080e7          	jalr	-968(ra) # 80005b80 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	df8080e7          	jalr	-520(ra) # 80002d48 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	486080e7          	jalr	1158(ra) # 800033de <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	438080e7          	jalr	1080(ra) # 80004398 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	d38080e7          	jalr	-712(ra) # 80005ca0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	16848493          	addi	s1,s1,360
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e3a7a783          	lw	a5,-454(a5) # 80008820 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	c14080e7          	jalr	-1004(ra) # 80002604 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a023          	sw	zero,-480(a5) # 80008820 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	954080e7          	jalr	-1708(ra) # 8000335e <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	df278793          	addi	a5,a5,-526 # 80008824 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	ba258593          	addi	a1,a1,-1118 # 80008830 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	0c8080e7          	jalr	200(ra) # 80003d94 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  } else if(n < 0){
    80001d12:	0204cd63          	bltz	s1,80001d4c <growproc+0x5c>
  p->sz = sz;
    80001d16:	1782                	slli	a5,a5,0x20
    80001d18:	9381                	srli	a5,a5,0x20
    80001d1a:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2c:	00f4863b          	addw	a2,s1,a5
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	1582                	slli	a1,a1,0x20
    80001d36:	9181                	srli	a1,a1,0x20
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6cc080e7          	jalr	1740(ra) # 80001406 <uvmalloc>
    80001d42:	0005079b          	sext.w	a5,a0
    80001d46:	fbe1                	bnez	a5,80001d16 <growproc+0x26>
      return -1;
    80001d48:	557d                	li	a0,-1
    80001d4a:	bfd9                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4c:	00f4863b          	addw	a2,s1,a5
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	664080e7          	jalr	1636(ra) # 800013be <uvmdealloc>
    80001d62:	0005079b          	sext.w	a5,a0
    80001d66:	bf45                	j	80001d16 <growproc+0x26>

0000000080001d68 <fork>:
{
    80001d68:	7139                	addi	sp,sp,-64
    80001d6a:	fc06                	sd	ra,56(sp)
    80001d6c:	f822                	sd	s0,48(sp)
    80001d6e:	f426                	sd	s1,40(sp)
    80001d70:	f04a                	sd	s2,32(sp)
    80001d72:	ec4e                	sd	s3,24(sp)
    80001d74:	e852                	sd	s4,16(sp)
    80001d76:	e456                	sd	s5,8(sp)
    80001d78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c1c080e7          	jalr	-996(ra) # 80001996 <myproc>
    80001d82:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e1c080e7          	jalr	-484(ra) # 80001ba0 <allocproc>
    80001d8c:	10050c63          	beqz	a0,80001ea4 <fork+0x13c>
    80001d90:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d92:	048ab603          	ld	a2,72(s5)
    80001d96:	692c                	ld	a1,80(a0)
    80001d98:	050ab503          	ld	a0,80(s5)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	7ba080e7          	jalr	1978(ra) # 80001556 <uvmcopy>
    80001da4:	04054863          	bltz	a0,80001df4 <fork+0x8c>
  np->sz = p->sz;
    80001da8:	048ab783          	ld	a5,72(s5)
    80001dac:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db0:	058ab683          	ld	a3,88(s5)
    80001db4:	87b6                	mv	a5,a3
    80001db6:	058a3703          	ld	a4,88(s4)
    80001dba:	12068693          	addi	a3,a3,288
    80001dbe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc2:	6788                	ld	a0,8(a5)
    80001dc4:	6b8c                	ld	a1,16(a5)
    80001dc6:	6f90                	ld	a2,24(a5)
    80001dc8:	01073023          	sd	a6,0(a4)
    80001dcc:	e708                	sd	a0,8(a4)
    80001dce:	eb0c                	sd	a1,16(a4)
    80001dd0:	ef10                	sd	a2,24(a4)
    80001dd2:	02078793          	addi	a5,a5,32
    80001dd6:	02070713          	addi	a4,a4,32
    80001dda:	fed792e3          	bne	a5,a3,80001dbe <fork+0x56>
  np->trapframe->a0 = 0;
    80001dde:	058a3783          	ld	a5,88(s4)
    80001de2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de6:	0d0a8493          	addi	s1,s5,208
    80001dea:	0d0a0913          	addi	s2,s4,208
    80001dee:	150a8993          	addi	s3,s5,336
    80001df2:	a00d                	j	80001e14 <fork+0xac>
    freeproc(np);
    80001df4:	8552                	mv	a0,s4
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	d52080e7          	jalr	-686(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfe:	8552                	mv	a0,s4
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	e84080e7          	jalr	-380(ra) # 80000c84 <release>
    return -1;
    80001e08:	597d                	li	s2,-1
    80001e0a:	a059                	j	80001e90 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e0c:	04a1                	addi	s1,s1,8
    80001e0e:	0921                	addi	s2,s2,8
    80001e10:	01348b63          	beq	s1,s3,80001e26 <fork+0xbe>
    if(p->ofile[i])
    80001e14:	6088                	ld	a0,0(s1)
    80001e16:	d97d                	beqz	a0,80001e0c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e18:	00002097          	auipc	ra,0x2
    80001e1c:	612080e7          	jalr	1554(ra) # 8000442a <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00001097          	auipc	ra,0x1
    80001e2e:	770080e7          	jalr	1904(ra) # 8000359a <idup>
    80001e32:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	158a8593          	addi	a1,s5,344
    80001e3c:	158a0513          	addi	a0,s4,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	fd6080e7          	jalr	-42(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e36080e7          	jalr	-458(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e56:	0000f497          	auipc	s1,0xf
    80001e5a:	46248493          	addi	s1,s1,1122 # 800112b8 <wait_lock>
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d70080e7          	jalr	-656(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e68:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e16080e7          	jalr	-490(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d58080e7          	jalr	-680(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e80:	478d                	li	a5,3
    80001e82:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfc080e7          	jalr	-516(ra) # 80000c84 <release>
}
    80001e90:	854a                	mv	a0,s2
    80001e92:	70e2                	ld	ra,56(sp)
    80001e94:	7442                	ld	s0,48(sp)
    80001e96:	74a2                	ld	s1,40(sp)
    80001e98:	7902                	ld	s2,32(sp)
    80001e9a:	69e2                	ld	s3,24(sp)
    80001e9c:	6a42                	ld	s4,16(sp)
    80001e9e:	6aa2                	ld	s5,8(sp)
    80001ea0:	6121                	addi	sp,sp,64
    80001ea2:	8082                	ret
    return -1;
    80001ea4:	597d                	li	s2,-1
    80001ea6:	b7ed                	j	80001e90 <fork+0x128>

0000000080001ea8 <scheduler>:
{
    80001ea8:	7139                	addi	sp,sp,-64
    80001eaa:	fc06                	sd	ra,56(sp)
    80001eac:	f822                	sd	s0,48(sp)
    80001eae:	f426                	sd	s1,40(sp)
    80001eb0:	f04a                	sd	s2,32(sp)
    80001eb2:	ec4e                	sd	s3,24(sp)
    80001eb4:	e852                	sd	s4,16(sp)
    80001eb6:	e456                	sd	s5,8(sp)
    80001eb8:	e05a                	sd	s6,0(sp)
    80001eba:	0080                	addi	s0,sp,64
    80001ebc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ebe:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec0:	00779a93          	slli	s5,a5,0x7
    80001ec4:	0000f717          	auipc	a4,0xf
    80001ec8:	3dc70713          	addi	a4,a4,988 # 800112a0 <pid_lock>
    80001ecc:	9756                	add	a4,a4,s5
    80001ece:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	40670713          	addi	a4,a4,1030 # 800112d8 <cpus+0x8>
    80001eda:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001edc:	498d                	li	s3,3
        p->state = RUNNING;
    80001ede:	4b11                	li	s6,4
        c->proc = p;
    80001ee0:	079e                	slli	a5,a5,0x7
    80001ee2:	0000fa17          	auipc	s4,0xf
    80001ee6:	3bea0a13          	addi	s4,s4,958 # 800112a0 <pid_lock>
    80001eea:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eec:	00015917          	auipc	s2,0x15
    80001ef0:	1e490913          	addi	s2,s2,484 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efc:	10079073          	csrw	sstatus,a5
    80001f00:	0000f497          	auipc	s1,0xf
    80001f04:	7d048493          	addi	s1,s1,2000 # 800116d0 <proc>
    80001f08:	a811                	j	80001f1c <scheduler+0x74>
      release(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d78080e7          	jalr	-648(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f14:	16848493          	addi	s1,s1,360
    80001f18:	fd248ee3          	beq	s1,s2,80001ef4 <scheduler+0x4c>
      acquire(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cb2080e7          	jalr	-846(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f26:	4c9c                	lw	a5,24(s1)
    80001f28:	ff3791e3          	bne	a5,s3,80001f0a <scheduler+0x62>
        p->state = RUNNING;
    80001f2c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f30:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f34:	06048593          	addi	a1,s1,96
    80001f38:	8556                	mv	a0,s5
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	620080e7          	jalr	1568(ra) # 8000255a <swtch>
        c->proc = 0;
    80001f42:	020a3823          	sd	zero,48(s4)
    80001f46:	b7d1                	j	80001f0a <scheduler+0x62>

0000000080001f48 <sched>:
{
    80001f48:	7179                	addi	sp,sp,-48
    80001f4a:	f406                	sd	ra,40(sp)
    80001f4c:	f022                	sd	s0,32(sp)
    80001f4e:	ec26                	sd	s1,24(sp)
    80001f50:	e84a                	sd	s2,16(sp)
    80001f52:	e44e                	sd	s3,8(sp)
    80001f54:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	a40080e7          	jalr	-1472(ra) # 80001996 <myproc>
    80001f5e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	bf6080e7          	jalr	-1034(ra) # 80000b56 <holding>
    80001f68:	c93d                	beqz	a0,80001fde <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f6c:	2781                	sext.w	a5,a5
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000f717          	auipc	a4,0xf
    80001f74:	33070713          	addi	a4,a4,816 # 800112a0 <pid_lock>
    80001f78:	97ba                	add	a5,a5,a4
    80001f7a:	0a87a703          	lw	a4,168(a5)
    80001f7e:	4785                	li	a5,1
    80001f80:	06f71763          	bne	a4,a5,80001fee <sched+0xa6>
  if(p->state == RUNNING)
    80001f84:	4c98                	lw	a4,24(s1)
    80001f86:	4791                	li	a5,4
    80001f88:	06f70b63          	beq	a4,a5,80001ffe <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f90:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f92:	efb5                	bnez	a5,8000200e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f96:	0000f917          	auipc	s2,0xf
    80001f9a:	30a90913          	addi	s2,s2,778 # 800112a0 <pid_lock>
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	97ca                	add	a5,a5,s2
    80001fa4:	0ac7a983          	lw	s3,172(a5)
    80001fa8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	0000f597          	auipc	a1,0xf
    80001fb2:	32a58593          	addi	a1,a1,810 # 800112d8 <cpus+0x8>
    80001fb6:	95be                	add	a1,a1,a5
    80001fb8:	06048513          	addi	a0,s1,96
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	59e080e7          	jalr	1438(ra) # 8000255a <swtch>
    80001fc4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	993e                	add	s2,s2,a5
    80001fcc:	0b392623          	sw	s3,172(s2)
}
    80001fd0:	70a2                	ld	ra,40(sp)
    80001fd2:	7402                	ld	s0,32(sp)
    80001fd4:	64e2                	ld	s1,24(sp)
    80001fd6:	6942                	ld	s2,16(sp)
    80001fd8:	69a2                	ld	s3,8(sp)
    80001fda:	6145                	addi	sp,sp,48
    80001fdc:	8082                	ret
    panic("sched p->lock");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	23a50513          	addi	a0,a0,570 # 80008218 <digits+0x1d8>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	554080e7          	jalr	1364(ra) # 8000053a <panic>
    panic("sched locks");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	23a50513          	addi	a0,a0,570 # 80008228 <digits+0x1e8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	544080e7          	jalr	1348(ra) # 8000053a <panic>
    panic("sched running");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	23a50513          	addi	a0,a0,570 # 80008238 <digits+0x1f8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	534080e7          	jalr	1332(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	23a50513          	addi	a0,a0,570 # 80008248 <digits+0x208>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	524080e7          	jalr	1316(ra) # 8000053a <panic>

000000008000201e <yield>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	96e080e7          	jalr	-1682(ra) # 80001996 <myproc>
    80002030:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	b9e080e7          	jalr	-1122(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000203a:	478d                	li	a5,3
    8000203c:	cc9c                	sw	a5,24(s1)
  sched();
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	f0a080e7          	jalr	-246(ra) # 80001f48 <sched>
  release(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c3c080e7          	jalr	-964(ra) # 80000c84 <release>
}
    80002050:	60e2                	ld	ra,24(sp)
    80002052:	6442                	ld	s0,16(sp)
    80002054:	64a2                	ld	s1,8(sp)
    80002056:	6105                	addi	sp,sp,32
    80002058:	8082                	ret

000000008000205a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000205a:	7179                	addi	sp,sp,-48
    8000205c:	f406                	sd	ra,40(sp)
    8000205e:	f022                	sd	s0,32(sp)
    80002060:	ec26                	sd	s1,24(sp)
    80002062:	e84a                	sd	s2,16(sp)
    80002064:	e44e                	sd	s3,8(sp)
    80002066:	1800                	addi	s0,sp,48
    80002068:	89aa                	mv	s3,a0
    8000206a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	92a080e7          	jalr	-1750(ra) # 80001996 <myproc>
    80002074:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b5a080e7          	jalr	-1190(ra) # 80000bd0 <acquire>
  release(lk);
    8000207e:	854a                	mv	a0,s2
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	c04080e7          	jalr	-1020(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002088:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000208c:	4789                	li	a5,2
    8000208e:	cc9c                	sw	a5,24(s1)

  sched();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	eb8080e7          	jalr	-328(ra) # 80001f48 <sched>

  // Tidy up.
  p->chan = 0;
    80002098:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	be6080e7          	jalr	-1050(ra) # 80000c84 <release>
  acquire(lk);
    800020a6:	854a                	mv	a0,s2
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b28080e7          	jalr	-1240(ra) # 80000bd0 <acquire>
}
    800020b0:	70a2                	ld	ra,40(sp)
    800020b2:	7402                	ld	s0,32(sp)
    800020b4:	64e2                	ld	s1,24(sp)
    800020b6:	6942                	ld	s2,16(sp)
    800020b8:	69a2                	ld	s3,8(sp)
    800020ba:	6145                	addi	sp,sp,48
    800020bc:	8082                	ret

00000000800020be <wait>:
{
    800020be:	715d                	addi	sp,sp,-80
    800020c0:	e486                	sd	ra,72(sp)
    800020c2:	e0a2                	sd	s0,64(sp)
    800020c4:	fc26                	sd	s1,56(sp)
    800020c6:	f84a                	sd	s2,48(sp)
    800020c8:	f44e                	sd	s3,40(sp)
    800020ca:	f052                	sd	s4,32(sp)
    800020cc:	ec56                	sd	s5,24(sp)
    800020ce:	e85a                	sd	s6,16(sp)
    800020d0:	e45e                	sd	s7,8(sp)
    800020d2:	e062                	sd	s8,0(sp)
    800020d4:	0880                	addi	s0,sp,80
    800020d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	8be080e7          	jalr	-1858(ra) # 80001996 <myproc>
    800020e0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e2:	0000f517          	auipc	a0,0xf
    800020e6:	1d650513          	addi	a0,a0,470 # 800112b8 <wait_lock>
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ae6080e7          	jalr	-1306(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f4:	4a15                	li	s4,5
        havekids = 1;
    800020f6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020f8:	00015997          	auipc	s3,0x15
    800020fc:	fd898993          	addi	s3,s3,-40 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002100:	0000fc17          	auipc	s8,0xf
    80002104:	1b8c0c13          	addi	s8,s8,440 # 800112b8 <wait_lock>
    havekids = 0;
    80002108:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000210a:	0000f497          	auipc	s1,0xf
    8000210e:	5c648493          	addi	s1,s1,1478 # 800116d0 <proc>
    80002112:	a0bd                	j	80002180 <wait+0xc2>
          pid = np->pid;
    80002114:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002118:	000b0e63          	beqz	s6,80002134 <wait+0x76>
    8000211c:	4691                	li	a3,4
    8000211e:	02c48613          	addi	a2,s1,44
    80002122:	85da                	mv	a1,s6
    80002124:	05093503          	ld	a0,80(s2)
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	532080e7          	jalr	1330(ra) # 8000165a <copyout>
    80002130:	02054563          	bltz	a0,8000215a <wait+0x9c>
          freeproc(np);
    80002134:	8526                	mv	a0,s1
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	a12080e7          	jalr	-1518(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b44080e7          	jalr	-1212(ra) # 80000c84 <release>
          release(&wait_lock);
    80002148:	0000f517          	auipc	a0,0xf
    8000214c:	17050513          	addi	a0,a0,368 # 800112b8 <wait_lock>
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b34080e7          	jalr	-1228(ra) # 80000c84 <release>
          return pid;
    80002158:	a09d                	j	800021be <wait+0x100>
            release(&np->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
            release(&wait_lock);
    80002164:	0000f517          	auipc	a0,0xf
    80002168:	15450513          	addi	a0,a0,340 # 800112b8 <wait_lock>
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b18080e7          	jalr	-1256(ra) # 80000c84 <release>
            return -1;
    80002174:	59fd                	li	s3,-1
    80002176:	a0a1                	j	800021be <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002178:	16848493          	addi	s1,s1,360
    8000217c:	03348463          	beq	s1,s3,800021a4 <wait+0xe6>
      if(np->parent == p){
    80002180:	7c9c                	ld	a5,56(s1)
    80002182:	ff279be3          	bne	a5,s2,80002178 <wait+0xba>
        acquire(&np->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a48080e7          	jalr	-1464(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002190:	4c9c                	lw	a5,24(s1)
    80002192:	f94781e3          	beq	a5,s4,80002114 <wait+0x56>
        release(&np->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	aec080e7          	jalr	-1300(ra) # 80000c84 <release>
        havekids = 1;
    800021a0:	8756                	mv	a4,s5
    800021a2:	bfd9                	j	80002178 <wait+0xba>
    if(!havekids || p->killed){
    800021a4:	c701                	beqz	a4,800021ac <wait+0xee>
    800021a6:	02892783          	lw	a5,40(s2)
    800021aa:	c79d                	beqz	a5,800021d8 <wait+0x11a>
      release(&wait_lock);
    800021ac:	0000f517          	auipc	a0,0xf
    800021b0:	10c50513          	addi	a0,a0,268 # 800112b8 <wait_lock>
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ad0080e7          	jalr	-1328(ra) # 80000c84 <release>
      return -1;
    800021bc:	59fd                	li	s3,-1
}
    800021be:	854e                	mv	a0,s3
    800021c0:	60a6                	ld	ra,72(sp)
    800021c2:	6406                	ld	s0,64(sp)
    800021c4:	74e2                	ld	s1,56(sp)
    800021c6:	7942                	ld	s2,48(sp)
    800021c8:	79a2                	ld	s3,40(sp)
    800021ca:	7a02                	ld	s4,32(sp)
    800021cc:	6ae2                	ld	s5,24(sp)
    800021ce:	6b42                	ld	s6,16(sp)
    800021d0:	6ba2                	ld	s7,8(sp)
    800021d2:	6c02                	ld	s8,0(sp)
    800021d4:	6161                	addi	sp,sp,80
    800021d6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d8:	85e2                	mv	a1,s8
    800021da:	854a                	mv	a0,s2
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	e7e080e7          	jalr	-386(ra) # 8000205a <sleep>
    havekids = 0;
    800021e4:	b715                	j	80002108 <wait+0x4a>

00000000800021e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e6:	7139                	addi	sp,sp,-64
    800021e8:	fc06                	sd	ra,56(sp)
    800021ea:	f822                	sd	s0,48(sp)
    800021ec:	f426                	sd	s1,40(sp)
    800021ee:	f04a                	sd	s2,32(sp)
    800021f0:	ec4e                	sd	s3,24(sp)
    800021f2:	e852                	sd	s4,16(sp)
    800021f4:	e456                	sd	s5,8(sp)
    800021f6:	0080                	addi	s0,sp,64
    800021f8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	4d648493          	addi	s1,s1,1238 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002202:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002204:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	00015917          	auipc	s2,0x15
    8000220a:	eca90913          	addi	s2,s2,-310 # 800170d0 <tickslock>
    8000220e:	a811                	j	80002222 <wakeup+0x3c>
      }
      release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a72080e7          	jalr	-1422(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	16848493          	addi	s1,s1,360
    8000221e:	03248663          	beq	s1,s2,8000224a <wakeup+0x64>
    if(p != myproc()){
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	774080e7          	jalr	1908(ra) # 80001996 <myproc>
    8000222a:	fea488e3          	beq	s1,a0,8000221a <wakeup+0x34>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9a0080e7          	jalr	-1632(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002238:	4c9c                	lw	a5,24(s1)
    8000223a:	fd379be3          	bne	a5,s3,80002210 <wakeup+0x2a>
    8000223e:	709c                	ld	a5,32(s1)
    80002240:	fd4798e3          	bne	a5,s4,80002210 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002244:	0154ac23          	sw	s5,24(s1)
    80002248:	b7e1                	j	80002210 <wakeup+0x2a>
    }
  }
}
    8000224a:	70e2                	ld	ra,56(sp)
    8000224c:	7442                	ld	s0,48(sp)
    8000224e:	74a2                	ld	s1,40(sp)
    80002250:	7902                	ld	s2,32(sp)
    80002252:	69e2                	ld	s3,24(sp)
    80002254:	6a42                	ld	s4,16(sp)
    80002256:	6aa2                	ld	s5,8(sp)
    80002258:	6121                	addi	sp,sp,64
    8000225a:	8082                	ret

000000008000225c <reparent>:
{
    8000225c:	7179                	addi	sp,sp,-48
    8000225e:	f406                	sd	ra,40(sp)
    80002260:	f022                	sd	s0,32(sp)
    80002262:	ec26                	sd	s1,24(sp)
    80002264:	e84a                	sd	s2,16(sp)
    80002266:	e44e                	sd	s3,8(sp)
    80002268:	e052                	sd	s4,0(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	46248493          	addi	s1,s1,1122 # 800116d0 <proc>
      pp->parent = initproc;
    80002276:	00007a17          	auipc	s4,0x7
    8000227a:	db2a0a13          	addi	s4,s4,-590 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227e:	00015997          	auipc	s3,0x15
    80002282:	e5298993          	addi	s3,s3,-430 # 800170d0 <tickslock>
    80002286:	a029                	j	80002290 <reparent+0x34>
    80002288:	16848493          	addi	s1,s1,360
    8000228c:	01348d63          	beq	s1,s3,800022a6 <reparent+0x4a>
    if(pp->parent == p){
    80002290:	7c9c                	ld	a5,56(s1)
    80002292:	ff279be3          	bne	a5,s2,80002288 <reparent+0x2c>
      pp->parent = initproc;
    80002296:	000a3503          	ld	a0,0(s4)
    8000229a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	f4a080e7          	jalr	-182(ra) # 800021e6 <wakeup>
    800022a4:	b7d5                	j	80002288 <reparent+0x2c>
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6a02                	ld	s4,0(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret

00000000800022b6 <exit>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	6ce080e7          	jalr	1742(ra) # 80001996 <myproc>
    800022d0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d2:	00007797          	auipc	a5,0x7
    800022d6:	d567b783          	ld	a5,-682(a5) # 80009028 <initproc>
    800022da:	0d050493          	addi	s1,a0,208
    800022de:	15050913          	addi	s2,a0,336
    800022e2:	02a79363          	bne	a5,a0,80002308 <exit+0x52>
    panic("init exiting");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f7a50513          	addi	a0,a0,-134 # 80008260 <digits+0x220>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	24c080e7          	jalr	588(ra) # 8000053a <panic>
      fileclose(f);
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	186080e7          	jalr	390(ra) # 8000447c <fileclose>
      p->ofile[fd] = 0;
    800022fe:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002302:	04a1                	addi	s1,s1,8
    80002304:	01248563          	beq	s1,s2,8000230e <exit+0x58>
    if(p->ofile[fd]){
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	f575                	bnez	a0,800022f6 <exit+0x40>
    8000230c:	bfdd                	j	80002302 <exit+0x4c>
  begin_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	ca6080e7          	jalr	-858(ra) # 80003fb4 <begin_op>
  iput(p->cwd);
    80002316:	1509b503          	ld	a0,336(s3)
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	478080e7          	jalr	1144(ra) # 80003792 <iput>
  end_op();
    80002322:	00002097          	auipc	ra,0x2
    80002326:	d10080e7          	jalr	-752(ra) # 80004032 <end_op>
  p->cwd = 0;
    8000232a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232e:	0000f497          	auipc	s1,0xf
    80002332:	f8a48493          	addi	s1,s1,-118 # 800112b8 <wait_lock>
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	898080e7          	jalr	-1896(ra) # 80000bd0 <acquire>
  reparent(p);
    80002340:	854e                	mv	a0,s3
    80002342:	00000097          	auipc	ra,0x0
    80002346:	f1a080e7          	jalr	-230(ra) # 8000225c <reparent>
  wakeup(p->parent);
    8000234a:	0389b503          	ld	a0,56(s3)
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	e98080e7          	jalr	-360(ra) # 800021e6 <wakeup>
  acquire(&p->lock);
    80002356:	854e                	mv	a0,s3
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	878080e7          	jalr	-1928(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002360:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002364:	4795                	li	a5,5
    80002366:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	918080e7          	jalr	-1768(ra) # 80000c84 <release>
  sched();
    80002374:	00000097          	auipc	ra,0x0
    80002378:	bd4080e7          	jalr	-1068(ra) # 80001f48 <sched>
  panic("zombie exit");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	ef450513          	addi	a0,a0,-268 # 80008270 <digits+0x230>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>

000000008000238c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000238c:	7179                	addi	sp,sp,-48
    8000238e:	f406                	sd	ra,40(sp)
    80002390:	f022                	sd	s0,32(sp)
    80002392:	ec26                	sd	s1,24(sp)
    80002394:	e84a                	sd	s2,16(sp)
    80002396:	e44e                	sd	s3,8(sp)
    80002398:	1800                	addi	s0,sp,48
    8000239a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	33448493          	addi	s1,s1,820 # 800116d0 <proc>
    800023a4:	00015997          	auipc	s3,0x15
    800023a8:	d2c98993          	addi	s3,s3,-724 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	822080e7          	jalr	-2014(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023b6:	589c                	lw	a5,48(s1)
    800023b8:	01278d63          	beq	a5,s2,800023d2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8c6080e7          	jalr	-1850(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	16848493          	addi	s1,s1,360
    800023ca:	ff3491e3          	bne	s1,s3,800023ac <kill+0x20>
  }
  return -1;
    800023ce:	557d                	li	a0,-1
    800023d0:	a829                	j	800023ea <kill+0x5e>
      p->killed = 1;
    800023d2:	4785                	li	a5,1
    800023d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d6:	4c98                	lw	a4,24(s1)
    800023d8:	4789                	li	a5,2
    800023da:	00f70f63          	beq	a4,a5,800023f8 <kill+0x6c>
      release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8a4080e7          	jalr	-1884(ra) # 80000c84 <release>
      return 0;
    800023e8:	4501                	li	a0,0
}
    800023ea:	70a2                	ld	ra,40(sp)
    800023ec:	7402                	ld	s0,32(sp)
    800023ee:	64e2                	ld	s1,24(sp)
    800023f0:	6942                	ld	s2,16(sp)
    800023f2:	69a2                	ld	s3,8(sp)
    800023f4:	6145                	addi	sp,sp,48
    800023f6:	8082                	ret
        p->state = RUNNABLE;
    800023f8:	478d                	li	a5,3
    800023fa:	cc9c                	sw	a5,24(s1)
    800023fc:	b7cd                	j	800023de <kill+0x52>

00000000800023fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	84aa                	mv	s1,a0
    80002410:	892e                	mv	s2,a1
    80002412:	89b2                	mv	s3,a2
    80002414:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	580080e7          	jalr	1408(ra) # 80001996 <myproc>
  if(user_dst){
    8000241e:	c08d                	beqz	s1,80002440 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002420:	86d2                	mv	a3,s4
    80002422:	864e                	mv	a2,s3
    80002424:	85ca                	mv	a1,s2
    80002426:	6928                	ld	a0,80(a0)
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	232080e7          	jalr	562(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6a02                	ld	s4,0(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    memmove((char *)dst, src, len);
    80002440:	000a061b          	sext.w	a2,s4
    80002444:	85ce                	mv	a1,s3
    80002446:	854a                	mv	a0,s2
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8e0080e7          	jalr	-1824(ra) # 80000d28 <memmove>
    return 0;
    80002450:	8526                	mv	a0,s1
    80002452:	bff9                	j	80002430 <either_copyout+0x32>

0000000080002454 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	892a                	mv	s2,a0
    80002466:	84ae                	mv	s1,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	52a080e7          	jalr	1322(ra) # 80001996 <myproc>
  if(user_src){
    80002474:	c08d                	beqz	s1,80002496 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	268080e7          	jalr	616(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
    memmove(dst, (char*)src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	88a080e7          	jalr	-1910(ra) # 80000d28 <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyin+0x32>

00000000800024aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024aa:	715d                	addi	sp,sp,-80
    800024ac:	e486                	sd	ra,72(sp)
    800024ae:	e0a2                	sd	s0,64(sp)
    800024b0:	fc26                	sd	s1,56(sp)
    800024b2:	f84a                	sd	s2,48(sp)
    800024b4:	f44e                	sd	s3,40(sp)
    800024b6:	f052                	sd	s4,32(sp)
    800024b8:	ec56                	sd	s5,24(sp)
    800024ba:	e85a                	sd	s6,16(sp)
    800024bc:	e45e                	sd	s7,8(sp)
    800024be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	c0850513          	addi	a0,a0,-1016 # 800080c8 <digits+0x88>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	0bc080e7          	jalr	188(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	0000f497          	auipc	s1,0xf
    800024d4:	35848493          	addi	s1,s1,856 # 80011828 <proc+0x158>
    800024d8:	00015917          	auipc	s2,0x15
    800024dc:	d5090913          	addi	s2,s2,-688 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024e2:	00006997          	auipc	s3,0x6
    800024e6:	d9e98993          	addi	s3,s3,-610 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024ea:	00006a97          	auipc	s5,0x6
    800024ee:	d9ea8a93          	addi	s5,s5,-610 # 80008288 <digits+0x248>
    printf("\n");
    800024f2:	00006a17          	auipc	s4,0x6
    800024f6:	bd6a0a13          	addi	s4,s4,-1066 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fa:	00006b97          	auipc	s7,0x6
    800024fe:	dc6b8b93          	addi	s7,s7,-570 # 800082c0 <states.0>
    80002502:	a00d                	j	80002524 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002504:	ed86a583          	lw	a1,-296(a3)
    80002508:	8556                	mv	a0,s5
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	07a080e7          	jalr	122(ra) # 80000584 <printf>
    printf("\n");
    80002512:	8552                	mv	a0,s4
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	070080e7          	jalr	112(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251c:	16848493          	addi	s1,s1,360
    80002520:	03248263          	beq	s1,s2,80002544 <procdump+0x9a>
    if(p->state == UNUSED)
    80002524:	86a6                	mv	a3,s1
    80002526:	ec04a783          	lw	a5,-320(s1)
    8000252a:	dbed                	beqz	a5,8000251c <procdump+0x72>
      state = "???";
    8000252c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	fcfb6be3          	bltu	s6,a5,80002504 <procdump+0x5a>
    80002532:	02079713          	slli	a4,a5,0x20
    80002536:	01d75793          	srli	a5,a4,0x1d
    8000253a:	97de                	add	a5,a5,s7
    8000253c:	6390                	ld	a2,0(a5)
    8000253e:	f279                	bnez	a2,80002504 <procdump+0x5a>
      state = "???";
    80002540:	864e                	mv	a2,s3
    80002542:	b7c9                	j	80002504 <procdump+0x5a>
  }
}
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6161                	addi	sp,sp,80
    80002558:	8082                	ret

000000008000255a <swtch>:
    8000255a:	00153023          	sd	ra,0(a0)
    8000255e:	00253423          	sd	sp,8(a0)
    80002562:	e900                	sd	s0,16(a0)
    80002564:	ed04                	sd	s1,24(a0)
    80002566:	03253023          	sd	s2,32(a0)
    8000256a:	03353423          	sd	s3,40(a0)
    8000256e:	03453823          	sd	s4,48(a0)
    80002572:	03553c23          	sd	s5,56(a0)
    80002576:	05653023          	sd	s6,64(a0)
    8000257a:	05753423          	sd	s7,72(a0)
    8000257e:	05853823          	sd	s8,80(a0)
    80002582:	05953c23          	sd	s9,88(a0)
    80002586:	07a53023          	sd	s10,96(a0)
    8000258a:	07b53423          	sd	s11,104(a0)
    8000258e:	0005b083          	ld	ra,0(a1)
    80002592:	0085b103          	ld	sp,8(a1)
    80002596:	6980                	ld	s0,16(a1)
    80002598:	6d84                	ld	s1,24(a1)
    8000259a:	0205b903          	ld	s2,32(a1)
    8000259e:	0285b983          	ld	s3,40(a1)
    800025a2:	0305ba03          	ld	s4,48(a1)
    800025a6:	0385ba83          	ld	s5,56(a1)
    800025aa:	0405bb03          	ld	s6,64(a1)
    800025ae:	0485bb83          	ld	s7,72(a1)
    800025b2:	0505bc03          	ld	s8,80(a1)
    800025b6:	0585bc83          	ld	s9,88(a1)
    800025ba:	0605bd03          	ld	s10,96(a1)
    800025be:	0685bd83          	ld	s11,104(a1)
    800025c2:	8082                	ret

00000000800025c4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025c4:	1141                	addi	sp,sp,-16
    800025c6:	e406                	sd	ra,8(sp)
    800025c8:	e022                	sd	s0,0(sp)
    800025ca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025cc:	00006597          	auipc	a1,0x6
    800025d0:	d2458593          	addi	a1,a1,-732 # 800082f0 <states.0+0x30>
    800025d4:	00015517          	auipc	a0,0x15
    800025d8:	afc50513          	addi	a0,a0,-1284 # 800170d0 <tickslock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	564080e7          	jalr	1380(ra) # 80000b40 <initlock>
}
    800025e4:	60a2                	ld	ra,8(sp)
    800025e6:	6402                	ld	s0,0(sp)
    800025e8:	0141                	addi	sp,sp,16
    800025ea:	8082                	ret

00000000800025ec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025ec:	1141                	addi	sp,sp,-16
    800025ee:	e422                	sd	s0,8(sp)
    800025f0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025f2:	00003797          	auipc	a5,0x3
    800025f6:	4be78793          	addi	a5,a5,1214 # 80005ab0 <kernelvec>
    800025fa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025fe:	6422                	ld	s0,8(sp)
    80002600:	0141                	addi	sp,sp,16
    80002602:	8082                	ret

0000000080002604 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002604:	1141                	addi	sp,sp,-16
    80002606:	e406                	sd	ra,8(sp)
    80002608:	e022                	sd	s0,0(sp)
    8000260a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	38a080e7          	jalr	906(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002614:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002618:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000261a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000261e:	00005697          	auipc	a3,0x5
    80002622:	9e268693          	addi	a3,a3,-1566 # 80007000 <_trampoline>
    80002626:	00005717          	auipc	a4,0x5
    8000262a:	9da70713          	addi	a4,a4,-1574 # 80007000 <_trampoline>
    8000262e:	8f15                	sub	a4,a4,a3
    80002630:	040007b7          	lui	a5,0x4000
    80002634:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002636:	07b2                	slli	a5,a5,0xc
    80002638:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000263a:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000263e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002640:	18002673          	csrr	a2,satp
    80002644:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002646:	6d30                	ld	a2,88(a0)
    80002648:	6138                	ld	a4,64(a0)
    8000264a:	6585                	lui	a1,0x1
    8000264c:	972e                	add	a4,a4,a1
    8000264e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002650:	6d38                	ld	a4,88(a0)
    80002652:	00000617          	auipc	a2,0x0
    80002656:	13860613          	addi	a2,a2,312 # 8000278a <usertrap>
    8000265a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000265c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000265e:	8612                	mv	a2,tp
    80002660:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002662:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002666:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000266a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002672:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002674:	6f18                	ld	a4,24(a4)
    80002676:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000267a:	692c                	ld	a1,80(a0)
    8000267c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000267e:	00005717          	auipc	a4,0x5
    80002682:	a1270713          	addi	a4,a4,-1518 # 80007090 <userret>
    80002686:	8f15                	sub	a4,a4,a3
    80002688:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000268a:	577d                	li	a4,-1
    8000268c:	177e                	slli	a4,a4,0x3f
    8000268e:	8dd9                	or	a1,a1,a4
    80002690:	02000537          	lui	a0,0x2000
    80002694:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002696:	0536                	slli	a0,a0,0xd
    80002698:	9782                	jalr	a5
}
    8000269a:	60a2                	ld	ra,8(sp)
    8000269c:	6402                	ld	s0,0(sp)
    8000269e:	0141                	addi	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026a2:	1101                	addi	sp,sp,-32
    800026a4:	ec06                	sd	ra,24(sp)
    800026a6:	e822                	sd	s0,16(sp)
    800026a8:	e426                	sd	s1,8(sp)
    800026aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ac:	00015497          	auipc	s1,0x15
    800026b0:	a2448493          	addi	s1,s1,-1500 # 800170d0 <tickslock>
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	51a080e7          	jalr	1306(ra) # 80000bd0 <acquire>
  ticks++;
    800026be:	00007517          	auipc	a0,0x7
    800026c2:	97250513          	addi	a0,a0,-1678 # 80009030 <ticks>
    800026c6:	411c                	lw	a5,0(a0)
    800026c8:	2785                	addiw	a5,a5,1
    800026ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	b1a080e7          	jalr	-1254(ra) # 800021e6 <wakeup>
  release(&tickslock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5ae080e7          	jalr	1454(ra) # 80000c84 <release>
}
    800026de:	60e2                	ld	ra,24(sp)
    800026e0:	6442                	ld	s0,16(sp)
    800026e2:	64a2                	ld	s1,8(sp)
    800026e4:	6105                	addi	sp,sp,32
    800026e6:	8082                	ret

00000000800026e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026e8:	1101                	addi	sp,sp,-32
    800026ea:	ec06                	sd	ra,24(sp)
    800026ec:	e822                	sd	s0,16(sp)
    800026ee:	e426                	sd	s1,8(sp)
    800026f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026f6:	00074d63          	bltz	a4,80002710 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026fa:	57fd                	li	a5,-1
    800026fc:	17fe                	slli	a5,a5,0x3f
    800026fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002700:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002702:	06f70363          	beq	a4,a5,80002768 <devintr+0x80>
  }
}
    80002706:	60e2                	ld	ra,24(sp)
    80002708:	6442                	ld	s0,16(sp)
    8000270a:	64a2                	ld	s1,8(sp)
    8000270c:	6105                	addi	sp,sp,32
    8000270e:	8082                	ret
     (scause & 0xff) == 9){
    80002710:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002714:	46a5                	li	a3,9
    80002716:	fed792e3          	bne	a5,a3,800026fa <devintr+0x12>
    int irq = plic_claim();
    8000271a:	00003097          	auipc	ra,0x3
    8000271e:	49e080e7          	jalr	1182(ra) # 80005bb8 <plic_claim>
    80002722:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002724:	47a9                	li	a5,10
    80002726:	02f50763          	beq	a0,a5,80002754 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000272a:	4785                	li	a5,1
    8000272c:	02f50963          	beq	a0,a5,8000275e <devintr+0x76>
    return 1;
    80002730:	4505                	li	a0,1
    } else if(irq){
    80002732:	d8f1                	beqz	s1,80002706 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002734:	85a6                	mv	a1,s1
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	bc250513          	addi	a0,a0,-1086 # 800082f8 <states.0+0x38>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	e46080e7          	jalr	-442(ra) # 80000584 <printf>
      plic_complete(irq);
    80002746:	8526                	mv	a0,s1
    80002748:	00003097          	auipc	ra,0x3
    8000274c:	494080e7          	jalr	1172(ra) # 80005bdc <plic_complete>
    return 1;
    80002750:	4505                	li	a0,1
    80002752:	bf55                	j	80002706 <devintr+0x1e>
      uartintr();
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	23e080e7          	jalr	574(ra) # 80000992 <uartintr>
    8000275c:	b7ed                	j	80002746 <devintr+0x5e>
      virtio_disk_intr();
    8000275e:	00004097          	auipc	ra,0x4
    80002762:	90a080e7          	jalr	-1782(ra) # 80006068 <virtio_disk_intr>
    80002766:	b7c5                	j	80002746 <devintr+0x5e>
    if(cpuid() == 0){
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	202080e7          	jalr	514(ra) # 8000196a <cpuid>
    80002770:	c901                	beqz	a0,80002780 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002772:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002776:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002778:	14479073          	csrw	sip,a5
    return 2;
    8000277c:	4509                	li	a0,2
    8000277e:	b761                	j	80002706 <devintr+0x1e>
      clockintr();
    80002780:	00000097          	auipc	ra,0x0
    80002784:	f22080e7          	jalr	-222(ra) # 800026a2 <clockintr>
    80002788:	b7ed                	j	80002772 <devintr+0x8a>

000000008000278a <usertrap>:
{
    8000278a:	1101                	addi	sp,sp,-32
    8000278c:	ec06                	sd	ra,24(sp)
    8000278e:	e822                	sd	s0,16(sp)
    80002790:	e426                	sd	s1,8(sp)
    80002792:	e04a                	sd	s2,0(sp)
    80002794:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002796:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000279a:	1007f793          	andi	a5,a5,256
    8000279e:	e3ad                	bnez	a5,80002800 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a0:	00003797          	auipc	a5,0x3
    800027a4:	31078793          	addi	a5,a5,784 # 80005ab0 <kernelvec>
    800027a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	1ea080e7          	jalr	490(ra) # 80001996 <myproc>
    800027b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027b8:	14102773          	csrr	a4,sepc
    800027bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027c2:	47a1                	li	a5,8
    800027c4:	04f71c63          	bne	a4,a5,8000281c <usertrap+0x92>
    if(p->killed)
    800027c8:	551c                	lw	a5,40(a0)
    800027ca:	e3b9                	bnez	a5,80002810 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027cc:	6cb8                	ld	a4,88(s1)
    800027ce:	6f1c                	ld	a5,24(a4)
    800027d0:	0791                	addi	a5,a5,4
    800027d2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027dc:	10079073          	csrw	sstatus,a5
    syscall();
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	2e0080e7          	jalr	736(ra) # 80002ac0 <syscall>
  if(p->killed)
    800027e8:	549c                	lw	a5,40(s1)
    800027ea:	ebc1                	bnez	a5,8000287a <usertrap+0xf0>
  usertrapret();
    800027ec:	00000097          	auipc	ra,0x0
    800027f0:	e18080e7          	jalr	-488(ra) # 80002604 <usertrapret>
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6902                	ld	s2,0(sp)
    800027fc:	6105                	addi	sp,sp,32
    800027fe:	8082                	ret
    panic("usertrap: not from user mode");
    80002800:	00006517          	auipc	a0,0x6
    80002804:	b1850513          	addi	a0,a0,-1256 # 80008318 <states.0+0x58>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	d32080e7          	jalr	-718(ra) # 8000053a <panic>
      exit(-1);
    80002810:	557d                	li	a0,-1
    80002812:	00000097          	auipc	ra,0x0
    80002816:	aa4080e7          	jalr	-1372(ra) # 800022b6 <exit>
    8000281a:	bf4d                	j	800027cc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	ecc080e7          	jalr	-308(ra) # 800026e8 <devintr>
    80002824:	892a                	mv	s2,a0
    80002826:	c501                	beqz	a0,8000282e <usertrap+0xa4>
  if(p->killed)
    80002828:	549c                	lw	a5,40(s1)
    8000282a:	c3a1                	beqz	a5,8000286a <usertrap+0xe0>
    8000282c:	a815                	j	80002860 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000282e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002832:	5890                	lw	a2,48(s1)
    80002834:	00006517          	auipc	a0,0x6
    80002838:	b0450513          	addi	a0,a0,-1276 # 80008338 <states.0+0x78>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d48080e7          	jalr	-696(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002844:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002848:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	b1c50513          	addi	a0,a0,-1252 # 80008368 <states.0+0xa8>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d30080e7          	jalr	-720(ra) # 80000584 <printf>
    p->killed = 1;
    8000285c:	4785                	li	a5,1
    8000285e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002860:	557d                	li	a0,-1
    80002862:	00000097          	auipc	ra,0x0
    80002866:	a54080e7          	jalr	-1452(ra) # 800022b6 <exit>
  if(which_dev == 2)
    8000286a:	4789                	li	a5,2
    8000286c:	f8f910e3          	bne	s2,a5,800027ec <usertrap+0x62>
    yield();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	7ae080e7          	jalr	1966(ra) # 8000201e <yield>
    80002878:	bf95                	j	800027ec <usertrap+0x62>
  int which_dev = 0;
    8000287a:	4901                	li	s2,0
    8000287c:	b7d5                	j	80002860 <usertrap+0xd6>

000000008000287e <kerneltrap>:
{
    8000287e:	7179                	addi	sp,sp,-48
    80002880:	f406                	sd	ra,40(sp)
    80002882:	f022                	sd	s0,32(sp)
    80002884:	ec26                	sd	s1,24(sp)
    80002886:	e84a                	sd	s2,16(sp)
    80002888:	e44e                	sd	s3,8(sp)
    8000288a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002894:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002898:	1004f793          	andi	a5,s1,256
    8000289c:	cb85                	beqz	a5,800028cc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028a2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028a4:	ef85                	bnez	a5,800028dc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	e42080e7          	jalr	-446(ra) # 800026e8 <devintr>
    800028ae:	cd1d                	beqz	a0,800028ec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028b0:	4789                	li	a5,2
    800028b2:	06f50a63          	beq	a0,a5,80002926 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10049073          	csrw	sstatus,s1
}
    800028be:	70a2                	ld	ra,40(sp)
    800028c0:	7402                	ld	s0,32(sp)
    800028c2:	64e2                	ld	s1,24(sp)
    800028c4:	6942                	ld	s2,16(sp)
    800028c6:	69a2                	ld	s3,8(sp)
    800028c8:	6145                	addi	sp,sp,48
    800028ca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028cc:	00006517          	auipc	a0,0x6
    800028d0:	abc50513          	addi	a0,a0,-1348 # 80008388 <states.0+0xc8>
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	c66080e7          	jalr	-922(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	ad450513          	addi	a0,a0,-1324 # 800083b0 <states.0+0xf0>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c56080e7          	jalr	-938(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    800028ec:	85ce                	mv	a1,s3
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	ae250513          	addi	a0,a0,-1310 # 800083d0 <states.0+0x110>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c8e080e7          	jalr	-882(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002902:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	ada50513          	addi	a0,a0,-1318 # 800083e0 <states.0+0x120>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c76080e7          	jalr	-906(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	ae250513          	addi	a0,a0,-1310 # 800083f8 <states.0+0x138>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c1c080e7          	jalr	-996(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	070080e7          	jalr	112(ra) # 80001996 <myproc>
    8000292e:	d541                	beqz	a0,800028b6 <kerneltrap+0x38>
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	066080e7          	jalr	102(ra) # 80001996 <myproc>
    80002938:	4d18                	lw	a4,24(a0)
    8000293a:	4791                	li	a5,4
    8000293c:	f6f71de3          	bne	a4,a5,800028b6 <kerneltrap+0x38>
    yield();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	6de080e7          	jalr	1758(ra) # 8000201e <yield>
    80002948:	b7bd                	j	800028b6 <kerneltrap+0x38>

000000008000294a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000294a:	1101                	addi	sp,sp,-32
    8000294c:	ec06                	sd	ra,24(sp)
    8000294e:	e822                	sd	s0,16(sp)
    80002950:	e426                	sd	s1,8(sp)
    80002952:	1000                	addi	s0,sp,32
    80002954:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	040080e7          	jalr	64(ra) # 80001996 <myproc>
  switch (n) {
    8000295e:	4795                	li	a5,5
    80002960:	0497e163          	bltu	a5,s1,800029a2 <argraw+0x58>
    80002964:	048a                	slli	s1,s1,0x2
    80002966:	00006717          	auipc	a4,0x6
    8000296a:	aca70713          	addi	a4,a4,-1334 # 80008430 <states.0+0x170>
    8000296e:	94ba                	add	s1,s1,a4
    80002970:	409c                	lw	a5,0(s1)
    80002972:	97ba                	add	a5,a5,a4
    80002974:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002976:	6d3c                	ld	a5,88(a0)
    80002978:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret
    return p->trapframe->a1;
    80002984:	6d3c                	ld	a5,88(a0)
    80002986:	7fa8                	ld	a0,120(a5)
    80002988:	bfcd                	j	8000297a <argraw+0x30>
    return p->trapframe->a2;
    8000298a:	6d3c                	ld	a5,88(a0)
    8000298c:	63c8                	ld	a0,128(a5)
    8000298e:	b7f5                	j	8000297a <argraw+0x30>
    return p->trapframe->a3;
    80002990:	6d3c                	ld	a5,88(a0)
    80002992:	67c8                	ld	a0,136(a5)
    80002994:	b7dd                	j	8000297a <argraw+0x30>
    return p->trapframe->a4;
    80002996:	6d3c                	ld	a5,88(a0)
    80002998:	6bc8                	ld	a0,144(a5)
    8000299a:	b7c5                	j	8000297a <argraw+0x30>
    return p->trapframe->a5;
    8000299c:	6d3c                	ld	a5,88(a0)
    8000299e:	6fc8                	ld	a0,152(a5)
    800029a0:	bfe9                	j	8000297a <argraw+0x30>
  panic("argraw");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	a6650513          	addi	a0,a0,-1434 # 80008408 <states.0+0x148>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b90080e7          	jalr	-1136(ra) # 8000053a <panic>

00000000800029b2 <fetchaddr>:
{
    800029b2:	1101                	addi	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	e426                	sd	s1,8(sp)
    800029ba:	e04a                	sd	s2,0(sp)
    800029bc:	1000                	addi	s0,sp,32
    800029be:	84aa                	mv	s1,a0
    800029c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	fd4080e7          	jalr	-44(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ca:	653c                	ld	a5,72(a0)
    800029cc:	02f4f863          	bgeu	s1,a5,800029fc <fetchaddr+0x4a>
    800029d0:	00848713          	addi	a4,s1,8
    800029d4:	02e7e663          	bltu	a5,a4,80002a00 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029d8:	46a1                	li	a3,8
    800029da:	8626                	mv	a2,s1
    800029dc:	85ca                	mv	a1,s2
    800029de:	6928                	ld	a0,80(a0)
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	d06080e7          	jalr	-762(ra) # 800016e6 <copyin>
    800029e8:	00a03533          	snez	a0,a0
    800029ec:	40a00533          	neg	a0,a0
}
    800029f0:	60e2                	ld	ra,24(sp)
    800029f2:	6442                	ld	s0,16(sp)
    800029f4:	64a2                	ld	s1,8(sp)
    800029f6:	6902                	ld	s2,0(sp)
    800029f8:	6105                	addi	sp,sp,32
    800029fa:	8082                	ret
    return -1;
    800029fc:	557d                	li	a0,-1
    800029fe:	bfcd                	j	800029f0 <fetchaddr+0x3e>
    80002a00:	557d                	li	a0,-1
    80002a02:	b7fd                	j	800029f0 <fetchaddr+0x3e>

0000000080002a04 <fetchstr>:
{
    80002a04:	7179                	addi	sp,sp,-48
    80002a06:	f406                	sd	ra,40(sp)
    80002a08:	f022                	sd	s0,32(sp)
    80002a0a:	ec26                	sd	s1,24(sp)
    80002a0c:	e84a                	sd	s2,16(sp)
    80002a0e:	e44e                	sd	s3,8(sp)
    80002a10:	1800                	addi	s0,sp,48
    80002a12:	892a                	mv	s2,a0
    80002a14:	84ae                	mv	s1,a1
    80002a16:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	f7e080e7          	jalr	-130(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a20:	86ce                	mv	a3,s3
    80002a22:	864a                	mv	a2,s2
    80002a24:	85a6                	mv	a1,s1
    80002a26:	6928                	ld	a0,80(a0)
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	d4c080e7          	jalr	-692(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002a30:	00054763          	bltz	a0,80002a3e <fetchstr+0x3a>
  return strlen(buf);
    80002a34:	8526                	mv	a0,s1
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	412080e7          	jalr	1042(ra) # 80000e48 <strlen>
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret

0000000080002a4c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	1000                	addi	s0,sp,32
    80002a56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	ef2080e7          	jalr	-270(ra) # 8000294a <argraw>
    80002a60:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a62:	4501                	li	a0,0
    80002a64:	60e2                	ld	ra,24(sp)
    80002a66:	6442                	ld	s0,16(sp)
    80002a68:	64a2                	ld	s1,8(sp)
    80002a6a:	6105                	addi	sp,sp,32
    80002a6c:	8082                	ret

0000000080002a6e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	addi	s0,sp,32
    80002a78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	ed0080e7          	jalr	-304(ra) # 8000294a <argraw>
    80002a82:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a84:	4501                	li	a0,0
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret

0000000080002a90 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	e04a                	sd	s2,0(sp)
    80002a9a:	1000                	addi	s0,sp,32
    80002a9c:	84ae                	mv	s1,a1
    80002a9e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	eaa080e7          	jalr	-342(ra) # 8000294a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002aa8:	864a                	mv	a2,s2
    80002aaa:	85a6                	mv	a1,s1
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	f58080e7          	jalr	-168(ra) # 80002a04 <fetchstr>
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6902                	ld	s2,0(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <syscall>:
[SYS_getthisprocsize]   sys_getthisprocsize,
};

void
syscall(void)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	e04a                	sd	s2,0(sp)
    80002aca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	eca080e7          	jalr	-310(ra) # 80001996 <myproc>
    80002ad4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ad6:	05853903          	ld	s2,88(a0)
    80002ada:	0a893783          	ld	a5,168(s2)
    80002ade:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ae2:	37fd                	addiw	a5,a5,-1
    80002ae4:	4755                	li	a4,21
    80002ae6:	00f76f63          	bltu	a4,a5,80002b04 <syscall+0x44>
    80002aea:	00369713          	slli	a4,a3,0x3
    80002aee:	00006797          	auipc	a5,0x6
    80002af2:	95a78793          	addi	a5,a5,-1702 # 80008448 <syscalls>
    80002af6:	97ba                	add	a5,a5,a4
    80002af8:	639c                	ld	a5,0(a5)
    80002afa:	c789                	beqz	a5,80002b04 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002afc:	9782                	jalr	a5
    80002afe:	06a93823          	sd	a0,112(s2)
    80002b02:	a839                	j	80002b20 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b04:	15848613          	addi	a2,s1,344
    80002b08:	588c                	lw	a1,48(s1)
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	90650513          	addi	a0,a0,-1786 # 80008410 <states.0+0x150>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a72080e7          	jalr	-1422(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b1a:	6cbc                	ld	a5,88(s1)
    80002b1c:	577d                	li	a4,-1
    80002b1e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6902                	ld	s2,0(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret

0000000080002b2c <sys_getthisprocsize>:
#include "spinlock.h"
#include "proc.h"

// new call
uint64 sys_getthisprocsize(void)
{
    80002b2c:	1141                	addi	sp,sp,-16
    80002b2e:	e406                	sd	ra,8(sp)
    80002b30:	e022                	sd	s0,0(sp)
    80002b32:	0800                	addi	s0,sp,16
  struct proc *p = myproc(); // Pointer to the PCB structure
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	e62080e7          	jalr	-414(ra) # 80001996 <myproc>
  return p->sz; // returns the size in bytes
}
    80002b3c:	6528                	ld	a0,72(a0)
    80002b3e:	60a2                	ld	ra,8(sp)
    80002b40:	6402                	ld	s0,0(sp)
    80002b42:	0141                	addi	sp,sp,16
    80002b44:	8082                	ret

0000000080002b46 <sys_exit>:

uint64
sys_exit(void)
{
    80002b46:	1101                	addi	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b4e:	fec40593          	addi	a1,s0,-20
    80002b52:	4501                	li	a0,0
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	ef8080e7          	jalr	-264(ra) # 80002a4c <argint>
    return -1;
    80002b5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b5e:	00054963          	bltz	a0,80002b70 <sys_exit+0x2a>
  exit(n);
    80002b62:	fec42503          	lw	a0,-20(s0)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	750080e7          	jalr	1872(ra) # 800022b6 <exit>
  return 0;  // not reached
    80002b6e:	4781                	li	a5,0
}
    80002b70:	853e                	mv	a0,a5
    80002b72:	60e2                	ld	ra,24(sp)
    80002b74:	6442                	ld	s0,16(sp)
    80002b76:	6105                	addi	sp,sp,32
    80002b78:	8082                	ret

0000000080002b7a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b7a:	1141                	addi	sp,sp,-16
    80002b7c:	e406                	sd	ra,8(sp)
    80002b7e:	e022                	sd	s0,0(sp)
    80002b80:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	e14080e7          	jalr	-492(ra) # 80001996 <myproc>
}
    80002b8a:	5908                	lw	a0,48(a0)
    80002b8c:	60a2                	ld	ra,8(sp)
    80002b8e:	6402                	ld	s0,0(sp)
    80002b90:	0141                	addi	sp,sp,16
    80002b92:	8082                	ret

0000000080002b94 <sys_fork>:

uint64
sys_fork(void)
{
    80002b94:	1141                	addi	sp,sp,-16
    80002b96:	e406                	sd	ra,8(sp)
    80002b98:	e022                	sd	s0,0(sp)
    80002b9a:	0800                	addi	s0,sp,16
  return fork();
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	1cc080e7          	jalr	460(ra) # 80001d68 <fork>
}
    80002ba4:	60a2                	ld	ra,8(sp)
    80002ba6:	6402                	ld	s0,0(sp)
    80002ba8:	0141                	addi	sp,sp,16
    80002baa:	8082                	ret

0000000080002bac <sys_wait>:

uint64
sys_wait(void)
{
    80002bac:	1101                	addi	sp,sp,-32
    80002bae:	ec06                	sd	ra,24(sp)
    80002bb0:	e822                	sd	s0,16(sp)
    80002bb2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bb4:	fe840593          	addi	a1,s0,-24
    80002bb8:	4501                	li	a0,0
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	eb4080e7          	jalr	-332(ra) # 80002a6e <argaddr>
    80002bc2:	87aa                	mv	a5,a0
    return -1;
    80002bc4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bc6:	0007c863          	bltz	a5,80002bd6 <sys_wait+0x2a>
  return wait(p);
    80002bca:	fe843503          	ld	a0,-24(s0)
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	4f0080e7          	jalr	1264(ra) # 800020be <wait>
}
    80002bd6:	60e2                	ld	ra,24(sp)
    80002bd8:	6442                	ld	s0,16(sp)
    80002bda:	6105                	addi	sp,sp,32
    80002bdc:	8082                	ret

0000000080002bde <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bde:	7179                	addi	sp,sp,-48
    80002be0:	f406                	sd	ra,40(sp)
    80002be2:	f022                	sd	s0,32(sp)
    80002be4:	ec26                	sd	s1,24(sp)
    80002be6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002be8:	fdc40593          	addi	a1,s0,-36
    80002bec:	4501                	li	a0,0
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	e5e080e7          	jalr	-418(ra) # 80002a4c <argint>
    80002bf6:	87aa                	mv	a5,a0
    return -1;
    80002bf8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002bfa:	0207c063          	bltz	a5,80002c1a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	d98080e7          	jalr	-616(ra) # 80001996 <myproc>
    80002c06:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c08:	fdc42503          	lw	a0,-36(s0)
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	0e4080e7          	jalr	228(ra) # 80001cf0 <growproc>
    80002c14:	00054863          	bltz	a0,80002c24 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c18:	8526                	mv	a0,s1
}
    80002c1a:	70a2                	ld	ra,40(sp)
    80002c1c:	7402                	ld	s0,32(sp)
    80002c1e:	64e2                	ld	s1,24(sp)
    80002c20:	6145                	addi	sp,sp,48
    80002c22:	8082                	ret
    return -1;
    80002c24:	557d                	li	a0,-1
    80002c26:	bfd5                	j	80002c1a <sys_sbrk+0x3c>

0000000080002c28 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c28:	7139                	addi	sp,sp,-64
    80002c2a:	fc06                	sd	ra,56(sp)
    80002c2c:	f822                	sd	s0,48(sp)
    80002c2e:	f426                	sd	s1,40(sp)
    80002c30:	f04a                	sd	s2,32(sp)
    80002c32:	ec4e                	sd	s3,24(sp)
    80002c34:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c36:	fcc40593          	addi	a1,s0,-52
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	e10080e7          	jalr	-496(ra) # 80002a4c <argint>
    return -1;
    80002c44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c46:	06054563          	bltz	a0,80002cb0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c4a:	00014517          	auipc	a0,0x14
    80002c4e:	48650513          	addi	a0,a0,1158 # 800170d0 <tickslock>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	f7e080e7          	jalr	-130(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002c5a:	00006917          	auipc	s2,0x6
    80002c5e:	3d692903          	lw	s2,982(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c62:	fcc42783          	lw	a5,-52(s0)
    80002c66:	cf85                	beqz	a5,80002c9e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c68:	00014997          	auipc	s3,0x14
    80002c6c:	46898993          	addi	s3,s3,1128 # 800170d0 <tickslock>
    80002c70:	00006497          	auipc	s1,0x6
    80002c74:	3c048493          	addi	s1,s1,960 # 80009030 <ticks>
    if(myproc()->killed){
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	d1e080e7          	jalr	-738(ra) # 80001996 <myproc>
    80002c80:	551c                	lw	a5,40(a0)
    80002c82:	ef9d                	bnez	a5,80002cc0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c84:	85ce                	mv	a1,s3
    80002c86:	8526                	mv	a0,s1
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	3d2080e7          	jalr	978(ra) # 8000205a <sleep>
  while(ticks - ticks0 < n){
    80002c90:	409c                	lw	a5,0(s1)
    80002c92:	412787bb          	subw	a5,a5,s2
    80002c96:	fcc42703          	lw	a4,-52(s0)
    80002c9a:	fce7efe3          	bltu	a5,a4,80002c78 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c9e:	00014517          	auipc	a0,0x14
    80002ca2:	43250513          	addi	a0,a0,1074 # 800170d0 <tickslock>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	fde080e7          	jalr	-34(ra) # 80000c84 <release>
  return 0;
    80002cae:	4781                	li	a5,0
}
    80002cb0:	853e                	mv	a0,a5
    80002cb2:	70e2                	ld	ra,56(sp)
    80002cb4:	7442                	ld	s0,48(sp)
    80002cb6:	74a2                	ld	s1,40(sp)
    80002cb8:	7902                	ld	s2,32(sp)
    80002cba:	69e2                	ld	s3,24(sp)
    80002cbc:	6121                	addi	sp,sp,64
    80002cbe:	8082                	ret
      release(&tickslock);
    80002cc0:	00014517          	auipc	a0,0x14
    80002cc4:	41050513          	addi	a0,a0,1040 # 800170d0 <tickslock>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fbc080e7          	jalr	-68(ra) # 80000c84 <release>
      return -1;
    80002cd0:	57fd                	li	a5,-1
    80002cd2:	bff9                	j	80002cb0 <sys_sleep+0x88>

0000000080002cd4 <sys_kill>:

uint64
sys_kill(void)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cdc:	fec40593          	addi	a1,s0,-20
    80002ce0:	4501                	li	a0,0
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	d6a080e7          	jalr	-662(ra) # 80002a4c <argint>
    80002cea:	87aa                	mv	a5,a0
    return -1;
    80002cec:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cee:	0007c863          	bltz	a5,80002cfe <sys_kill+0x2a>
  return kill(pid);
    80002cf2:	fec42503          	lw	a0,-20(s0)
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	696080e7          	jalr	1686(ra) # 8000238c <kill>
}
    80002cfe:	60e2                	ld	ra,24(sp)
    80002d00:	6442                	ld	s0,16(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret

0000000080002d06 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	e426                	sd	s1,8(sp)
    80002d0e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d10:	00014517          	auipc	a0,0x14
    80002d14:	3c050513          	addi	a0,a0,960 # 800170d0 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	eb8080e7          	jalr	-328(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002d20:	00006497          	auipc	s1,0x6
    80002d24:	3104a483          	lw	s1,784(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d28:	00014517          	auipc	a0,0x14
    80002d2c:	3a850513          	addi	a0,a0,936 # 800170d0 <tickslock>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	f54080e7          	jalr	-172(ra) # 80000c84 <release>
  return xticks;
}
    80002d38:	02049513          	slli	a0,s1,0x20
    80002d3c:	9101                	srli	a0,a0,0x20
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	64a2                	ld	s1,8(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret

0000000080002d48 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d48:	7179                	addi	sp,sp,-48
    80002d4a:	f406                	sd	ra,40(sp)
    80002d4c:	f022                	sd	s0,32(sp)
    80002d4e:	ec26                	sd	s1,24(sp)
    80002d50:	e84a                	sd	s2,16(sp)
    80002d52:	e44e                	sd	s3,8(sp)
    80002d54:	e052                	sd	s4,0(sp)
    80002d56:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d58:	00005597          	auipc	a1,0x5
    80002d5c:	7a858593          	addi	a1,a1,1960 # 80008500 <syscalls+0xb8>
    80002d60:	00014517          	auipc	a0,0x14
    80002d64:	38850513          	addi	a0,a0,904 # 800170e8 <bcache>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	dd8080e7          	jalr	-552(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d70:	0001c797          	auipc	a5,0x1c
    80002d74:	37878793          	addi	a5,a5,888 # 8001f0e8 <bcache+0x8000>
    80002d78:	0001c717          	auipc	a4,0x1c
    80002d7c:	5d870713          	addi	a4,a4,1496 # 8001f350 <bcache+0x8268>
    80002d80:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d84:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d88:	00014497          	auipc	s1,0x14
    80002d8c:	37848493          	addi	s1,s1,888 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d90:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d92:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d94:	00005a17          	auipc	s4,0x5
    80002d98:	774a0a13          	addi	s4,s4,1908 # 80008508 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002d9c:	2b893783          	ld	a5,696(s2)
    80002da0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002da2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002da6:	85d2                	mv	a1,s4
    80002da8:	01048513          	addi	a0,s1,16
    80002dac:	00001097          	auipc	ra,0x1
    80002db0:	4c2080e7          	jalr	1218(ra) # 8000426e <initsleeplock>
    bcache.head.next->prev = b;
    80002db4:	2b893783          	ld	a5,696(s2)
    80002db8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dba:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dbe:	45848493          	addi	s1,s1,1112
    80002dc2:	fd349de3          	bne	s1,s3,80002d9c <binit+0x54>
  }
}
    80002dc6:	70a2                	ld	ra,40(sp)
    80002dc8:	7402                	ld	s0,32(sp)
    80002dca:	64e2                	ld	s1,24(sp)
    80002dcc:	6942                	ld	s2,16(sp)
    80002dce:	69a2                	ld	s3,8(sp)
    80002dd0:	6a02                	ld	s4,0(sp)
    80002dd2:	6145                	addi	sp,sp,48
    80002dd4:	8082                	ret

0000000080002dd6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dd6:	7179                	addi	sp,sp,-48
    80002dd8:	f406                	sd	ra,40(sp)
    80002dda:	f022                	sd	s0,32(sp)
    80002ddc:	ec26                	sd	s1,24(sp)
    80002dde:	e84a                	sd	s2,16(sp)
    80002de0:	e44e                	sd	s3,8(sp)
    80002de2:	1800                	addi	s0,sp,48
    80002de4:	892a                	mv	s2,a0
    80002de6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002de8:	00014517          	auipc	a0,0x14
    80002dec:	30050513          	addi	a0,a0,768 # 800170e8 <bcache>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	de0080e7          	jalr	-544(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002df8:	0001c497          	auipc	s1,0x1c
    80002dfc:	5a84b483          	ld	s1,1448(s1) # 8001f3a0 <bcache+0x82b8>
    80002e00:	0001c797          	auipc	a5,0x1c
    80002e04:	55078793          	addi	a5,a5,1360 # 8001f350 <bcache+0x8268>
    80002e08:	02f48f63          	beq	s1,a5,80002e46 <bread+0x70>
    80002e0c:	873e                	mv	a4,a5
    80002e0e:	a021                	j	80002e16 <bread+0x40>
    80002e10:	68a4                	ld	s1,80(s1)
    80002e12:	02e48a63          	beq	s1,a4,80002e46 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e16:	449c                	lw	a5,8(s1)
    80002e18:	ff279ce3          	bne	a5,s2,80002e10 <bread+0x3a>
    80002e1c:	44dc                	lw	a5,12(s1)
    80002e1e:	ff3799e3          	bne	a5,s3,80002e10 <bread+0x3a>
      b->refcnt++;
    80002e22:	40bc                	lw	a5,64(s1)
    80002e24:	2785                	addiw	a5,a5,1
    80002e26:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e28:	00014517          	auipc	a0,0x14
    80002e2c:	2c050513          	addi	a0,a0,704 # 800170e8 <bcache>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	e54080e7          	jalr	-428(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002e38:	01048513          	addi	a0,s1,16
    80002e3c:	00001097          	auipc	ra,0x1
    80002e40:	46c080e7          	jalr	1132(ra) # 800042a8 <acquiresleep>
      return b;
    80002e44:	a8b9                	j	80002ea2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e46:	0001c497          	auipc	s1,0x1c
    80002e4a:	5524b483          	ld	s1,1362(s1) # 8001f398 <bcache+0x82b0>
    80002e4e:	0001c797          	auipc	a5,0x1c
    80002e52:	50278793          	addi	a5,a5,1282 # 8001f350 <bcache+0x8268>
    80002e56:	00f48863          	beq	s1,a5,80002e66 <bread+0x90>
    80002e5a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e5c:	40bc                	lw	a5,64(s1)
    80002e5e:	cf81                	beqz	a5,80002e76 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e60:	64a4                	ld	s1,72(s1)
    80002e62:	fee49de3          	bne	s1,a4,80002e5c <bread+0x86>
  panic("bget: no buffers");
    80002e66:	00005517          	auipc	a0,0x5
    80002e6a:	6aa50513          	addi	a0,a0,1706 # 80008510 <syscalls+0xc8>
    80002e6e:	ffffd097          	auipc	ra,0xffffd
    80002e72:	6cc080e7          	jalr	1740(ra) # 8000053a <panic>
      b->dev = dev;
    80002e76:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e7a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e7e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e82:	4785                	li	a5,1
    80002e84:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e86:	00014517          	auipc	a0,0x14
    80002e8a:	26250513          	addi	a0,a0,610 # 800170e8 <bcache>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	df6080e7          	jalr	-522(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002e96:	01048513          	addi	a0,s1,16
    80002e9a:	00001097          	auipc	ra,0x1
    80002e9e:	40e080e7          	jalr	1038(ra) # 800042a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ea2:	409c                	lw	a5,0(s1)
    80002ea4:	cb89                	beqz	a5,80002eb6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ea6:	8526                	mv	a0,s1
    80002ea8:	70a2                	ld	ra,40(sp)
    80002eaa:	7402                	ld	s0,32(sp)
    80002eac:	64e2                	ld	s1,24(sp)
    80002eae:	6942                	ld	s2,16(sp)
    80002eb0:	69a2                	ld	s3,8(sp)
    80002eb2:	6145                	addi	sp,sp,48
    80002eb4:	8082                	ret
    virtio_disk_rw(b, 0);
    80002eb6:	4581                	li	a1,0
    80002eb8:	8526                	mv	a0,s1
    80002eba:	00003097          	auipc	ra,0x3
    80002ebe:	f28080e7          	jalr	-216(ra) # 80005de2 <virtio_disk_rw>
    b->valid = 1;
    80002ec2:	4785                	li	a5,1
    80002ec4:	c09c                	sw	a5,0(s1)
  return b;
    80002ec6:	b7c5                	j	80002ea6 <bread+0xd0>

0000000080002ec8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
    80002ed2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ed4:	0541                	addi	a0,a0,16
    80002ed6:	00001097          	auipc	ra,0x1
    80002eda:	46c080e7          	jalr	1132(ra) # 80004342 <holdingsleep>
    80002ede:	cd01                	beqz	a0,80002ef6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ee0:	4585                	li	a1,1
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	00003097          	auipc	ra,0x3
    80002ee8:	efe080e7          	jalr	-258(ra) # 80005de2 <virtio_disk_rw>
}
    80002eec:	60e2                	ld	ra,24(sp)
    80002eee:	6442                	ld	s0,16(sp)
    80002ef0:	64a2                	ld	s1,8(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret
    panic("bwrite");
    80002ef6:	00005517          	auipc	a0,0x5
    80002efa:	63250513          	addi	a0,a0,1586 # 80008528 <syscalls+0xe0>
    80002efe:	ffffd097          	auipc	ra,0xffffd
    80002f02:	63c080e7          	jalr	1596(ra) # 8000053a <panic>

0000000080002f06 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	e426                	sd	s1,8(sp)
    80002f0e:	e04a                	sd	s2,0(sp)
    80002f10:	1000                	addi	s0,sp,32
    80002f12:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f14:	01050913          	addi	s2,a0,16
    80002f18:	854a                	mv	a0,s2
    80002f1a:	00001097          	auipc	ra,0x1
    80002f1e:	428080e7          	jalr	1064(ra) # 80004342 <holdingsleep>
    80002f22:	c92d                	beqz	a0,80002f94 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f24:	854a                	mv	a0,s2
    80002f26:	00001097          	auipc	ra,0x1
    80002f2a:	3d8080e7          	jalr	984(ra) # 800042fe <releasesleep>

  acquire(&bcache.lock);
    80002f2e:	00014517          	auipc	a0,0x14
    80002f32:	1ba50513          	addi	a0,a0,442 # 800170e8 <bcache>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	c9a080e7          	jalr	-870(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002f3e:	40bc                	lw	a5,64(s1)
    80002f40:	37fd                	addiw	a5,a5,-1
    80002f42:	0007871b          	sext.w	a4,a5
    80002f46:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f48:	eb05                	bnez	a4,80002f78 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f4a:	68bc                	ld	a5,80(s1)
    80002f4c:	64b8                	ld	a4,72(s1)
    80002f4e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f50:	64bc                	ld	a5,72(s1)
    80002f52:	68b8                	ld	a4,80(s1)
    80002f54:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f56:	0001c797          	auipc	a5,0x1c
    80002f5a:	19278793          	addi	a5,a5,402 # 8001f0e8 <bcache+0x8000>
    80002f5e:	2b87b703          	ld	a4,696(a5)
    80002f62:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f64:	0001c717          	auipc	a4,0x1c
    80002f68:	3ec70713          	addi	a4,a4,1004 # 8001f350 <bcache+0x8268>
    80002f6c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f6e:	2b87b703          	ld	a4,696(a5)
    80002f72:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f74:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f78:	00014517          	auipc	a0,0x14
    80002f7c:	17050513          	addi	a0,a0,368 # 800170e8 <bcache>
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	d04080e7          	jalr	-764(ra) # 80000c84 <release>
}
    80002f88:	60e2                	ld	ra,24(sp)
    80002f8a:	6442                	ld	s0,16(sp)
    80002f8c:	64a2                	ld	s1,8(sp)
    80002f8e:	6902                	ld	s2,0(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret
    panic("brelse");
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	59c50513          	addi	a0,a0,1436 # 80008530 <syscalls+0xe8>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	59e080e7          	jalr	1438(ra) # 8000053a <panic>

0000000080002fa4 <bpin>:

void
bpin(struct buf *b) {
    80002fa4:	1101                	addi	sp,sp,-32
    80002fa6:	ec06                	sd	ra,24(sp)
    80002fa8:	e822                	sd	s0,16(sp)
    80002faa:	e426                	sd	s1,8(sp)
    80002fac:	1000                	addi	s0,sp,32
    80002fae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fb0:	00014517          	auipc	a0,0x14
    80002fb4:	13850513          	addi	a0,a0,312 # 800170e8 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	c18080e7          	jalr	-1000(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80002fc0:	40bc                	lw	a5,64(s1)
    80002fc2:	2785                	addiw	a5,a5,1
    80002fc4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	12250513          	addi	a0,a0,290 # 800170e8 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	cb6080e7          	jalr	-842(ra) # 80000c84 <release>
}
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	64a2                	ld	s1,8(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret

0000000080002fe0 <bunpin>:

void
bunpin(struct buf *b) {
    80002fe0:	1101                	addi	sp,sp,-32
    80002fe2:	ec06                	sd	ra,24(sp)
    80002fe4:	e822                	sd	s0,16(sp)
    80002fe6:	e426                	sd	s1,8(sp)
    80002fe8:	1000                	addi	s0,sp,32
    80002fea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fec:	00014517          	auipc	a0,0x14
    80002ff0:	0fc50513          	addi	a0,a0,252 # 800170e8 <bcache>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	bdc080e7          	jalr	-1060(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002ffc:	40bc                	lw	a5,64(s1)
    80002ffe:	37fd                	addiw	a5,a5,-1
    80003000:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	0e650513          	addi	a0,a0,230 # 800170e8 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c7a080e7          	jalr	-902(ra) # 80000c84 <release>
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	64a2                	ld	s1,8(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	e426                	sd	s1,8(sp)
    80003024:	e04a                	sd	s2,0(sp)
    80003026:	1000                	addi	s0,sp,32
    80003028:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000302a:	00d5d59b          	srliw	a1,a1,0xd
    8000302e:	0001c797          	auipc	a5,0x1c
    80003032:	7967a783          	lw	a5,1942(a5) # 8001f7c4 <sb+0x1c>
    80003036:	9dbd                	addw	a1,a1,a5
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	d9e080e7          	jalr	-610(ra) # 80002dd6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003040:	0074f713          	andi	a4,s1,7
    80003044:	4785                	li	a5,1
    80003046:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000304a:	14ce                	slli	s1,s1,0x33
    8000304c:	90d9                	srli	s1,s1,0x36
    8000304e:	00950733          	add	a4,a0,s1
    80003052:	05874703          	lbu	a4,88(a4)
    80003056:	00e7f6b3          	and	a3,a5,a4
    8000305a:	c69d                	beqz	a3,80003088 <bfree+0x6c>
    8000305c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000305e:	94aa                	add	s1,s1,a0
    80003060:	fff7c793          	not	a5,a5
    80003064:	8f7d                	and	a4,a4,a5
    80003066:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000306a:	00001097          	auipc	ra,0x1
    8000306e:	120080e7          	jalr	288(ra) # 8000418a <log_write>
  brelse(bp);
    80003072:	854a                	mv	a0,s2
    80003074:	00000097          	auipc	ra,0x0
    80003078:	e92080e7          	jalr	-366(ra) # 80002f06 <brelse>
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6902                	ld	s2,0(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret
    panic("freeing free block");
    80003088:	00005517          	auipc	a0,0x5
    8000308c:	4b050513          	addi	a0,a0,1200 # 80008538 <syscalls+0xf0>
    80003090:	ffffd097          	auipc	ra,0xffffd
    80003094:	4aa080e7          	jalr	1194(ra) # 8000053a <panic>

0000000080003098 <balloc>:
{
    80003098:	711d                	addi	sp,sp,-96
    8000309a:	ec86                	sd	ra,88(sp)
    8000309c:	e8a2                	sd	s0,80(sp)
    8000309e:	e4a6                	sd	s1,72(sp)
    800030a0:	e0ca                	sd	s2,64(sp)
    800030a2:	fc4e                	sd	s3,56(sp)
    800030a4:	f852                	sd	s4,48(sp)
    800030a6:	f456                	sd	s5,40(sp)
    800030a8:	f05a                	sd	s6,32(sp)
    800030aa:	ec5e                	sd	s7,24(sp)
    800030ac:	e862                	sd	s8,16(sp)
    800030ae:	e466                	sd	s9,8(sp)
    800030b0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030b2:	0001c797          	auipc	a5,0x1c
    800030b6:	6fa7a783          	lw	a5,1786(a5) # 8001f7ac <sb+0x4>
    800030ba:	cbc1                	beqz	a5,8000314a <balloc+0xb2>
    800030bc:	8baa                	mv	s7,a0
    800030be:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030c0:	0001cb17          	auipc	s6,0x1c
    800030c4:	6e8b0b13          	addi	s6,s6,1768 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030c8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030ca:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030cc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030ce:	6c89                	lui	s9,0x2
    800030d0:	a831                	j	800030ec <balloc+0x54>
    brelse(bp);
    800030d2:	854a                	mv	a0,s2
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	e32080e7          	jalr	-462(ra) # 80002f06 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030dc:	015c87bb          	addw	a5,s9,s5
    800030e0:	00078a9b          	sext.w	s5,a5
    800030e4:	004b2703          	lw	a4,4(s6)
    800030e8:	06eaf163          	bgeu	s5,a4,8000314a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800030ec:	41fad79b          	sraiw	a5,s5,0x1f
    800030f0:	0137d79b          	srliw	a5,a5,0x13
    800030f4:	015787bb          	addw	a5,a5,s5
    800030f8:	40d7d79b          	sraiw	a5,a5,0xd
    800030fc:	01cb2583          	lw	a1,28(s6)
    80003100:	9dbd                	addw	a1,a1,a5
    80003102:	855e                	mv	a0,s7
    80003104:	00000097          	auipc	ra,0x0
    80003108:	cd2080e7          	jalr	-814(ra) # 80002dd6 <bread>
    8000310c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000310e:	004b2503          	lw	a0,4(s6)
    80003112:	000a849b          	sext.w	s1,s5
    80003116:	8762                	mv	a4,s8
    80003118:	faa4fde3          	bgeu	s1,a0,800030d2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000311c:	00777693          	andi	a3,a4,7
    80003120:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003124:	41f7579b          	sraiw	a5,a4,0x1f
    80003128:	01d7d79b          	srliw	a5,a5,0x1d
    8000312c:	9fb9                	addw	a5,a5,a4
    8000312e:	4037d79b          	sraiw	a5,a5,0x3
    80003132:	00f90633          	add	a2,s2,a5
    80003136:	05864603          	lbu	a2,88(a2)
    8000313a:	00c6f5b3          	and	a1,a3,a2
    8000313e:	cd91                	beqz	a1,8000315a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003140:	2705                	addiw	a4,a4,1
    80003142:	2485                	addiw	s1,s1,1
    80003144:	fd471ae3          	bne	a4,s4,80003118 <balloc+0x80>
    80003148:	b769                	j	800030d2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000314a:	00005517          	auipc	a0,0x5
    8000314e:	40650513          	addi	a0,a0,1030 # 80008550 <syscalls+0x108>
    80003152:	ffffd097          	auipc	ra,0xffffd
    80003156:	3e8080e7          	jalr	1000(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000315a:	97ca                	add	a5,a5,s2
    8000315c:	8e55                	or	a2,a2,a3
    8000315e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003162:	854a                	mv	a0,s2
    80003164:	00001097          	auipc	ra,0x1
    80003168:	026080e7          	jalr	38(ra) # 8000418a <log_write>
        brelse(bp);
    8000316c:	854a                	mv	a0,s2
    8000316e:	00000097          	auipc	ra,0x0
    80003172:	d98080e7          	jalr	-616(ra) # 80002f06 <brelse>
  bp = bread(dev, bno);
    80003176:	85a6                	mv	a1,s1
    80003178:	855e                	mv	a0,s7
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	c5c080e7          	jalr	-932(ra) # 80002dd6 <bread>
    80003182:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003184:	40000613          	li	a2,1024
    80003188:	4581                	li	a1,0
    8000318a:	05850513          	addi	a0,a0,88
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	b3e080e7          	jalr	-1218(ra) # 80000ccc <memset>
  log_write(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	ff2080e7          	jalr	-14(ra) # 8000418a <log_write>
  brelse(bp);
    800031a0:	854a                	mv	a0,s2
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	d64080e7          	jalr	-668(ra) # 80002f06 <brelse>
}
    800031aa:	8526                	mv	a0,s1
    800031ac:	60e6                	ld	ra,88(sp)
    800031ae:	6446                	ld	s0,80(sp)
    800031b0:	64a6                	ld	s1,72(sp)
    800031b2:	6906                	ld	s2,64(sp)
    800031b4:	79e2                	ld	s3,56(sp)
    800031b6:	7a42                	ld	s4,48(sp)
    800031b8:	7aa2                	ld	s5,40(sp)
    800031ba:	7b02                	ld	s6,32(sp)
    800031bc:	6be2                	ld	s7,24(sp)
    800031be:	6c42                	ld	s8,16(sp)
    800031c0:	6ca2                	ld	s9,8(sp)
    800031c2:	6125                	addi	sp,sp,96
    800031c4:	8082                	ret

00000000800031c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031c6:	7179                	addi	sp,sp,-48
    800031c8:	f406                	sd	ra,40(sp)
    800031ca:	f022                	sd	s0,32(sp)
    800031cc:	ec26                	sd	s1,24(sp)
    800031ce:	e84a                	sd	s2,16(sp)
    800031d0:	e44e                	sd	s3,8(sp)
    800031d2:	e052                	sd	s4,0(sp)
    800031d4:	1800                	addi	s0,sp,48
    800031d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031d8:	47ad                	li	a5,11
    800031da:	04b7fe63          	bgeu	a5,a1,80003236 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031de:	ff45849b          	addiw	s1,a1,-12
    800031e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031e6:	0ff00793          	li	a5,255
    800031ea:	0ae7e463          	bltu	a5,a4,80003292 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031ee:	08052583          	lw	a1,128(a0)
    800031f2:	c5b5                	beqz	a1,8000325e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800031f4:	00092503          	lw	a0,0(s2)
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	bde080e7          	jalr	-1058(ra) # 80002dd6 <bread>
    80003200:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003202:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003206:	02049713          	slli	a4,s1,0x20
    8000320a:	01e75593          	srli	a1,a4,0x1e
    8000320e:	00b784b3          	add	s1,a5,a1
    80003212:	0004a983          	lw	s3,0(s1)
    80003216:	04098e63          	beqz	s3,80003272 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000321a:	8552                	mv	a0,s4
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	cea080e7          	jalr	-790(ra) # 80002f06 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003224:	854e                	mv	a0,s3
    80003226:	70a2                	ld	ra,40(sp)
    80003228:	7402                	ld	s0,32(sp)
    8000322a:	64e2                	ld	s1,24(sp)
    8000322c:	6942                	ld	s2,16(sp)
    8000322e:	69a2                	ld	s3,8(sp)
    80003230:	6a02                	ld	s4,0(sp)
    80003232:	6145                	addi	sp,sp,48
    80003234:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003236:	02059793          	slli	a5,a1,0x20
    8000323a:	01e7d593          	srli	a1,a5,0x1e
    8000323e:	00b504b3          	add	s1,a0,a1
    80003242:	0504a983          	lw	s3,80(s1)
    80003246:	fc099fe3          	bnez	s3,80003224 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000324a:	4108                	lw	a0,0(a0)
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	e4c080e7          	jalr	-436(ra) # 80003098 <balloc>
    80003254:	0005099b          	sext.w	s3,a0
    80003258:	0534a823          	sw	s3,80(s1)
    8000325c:	b7e1                	j	80003224 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000325e:	4108                	lw	a0,0(a0)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e38080e7          	jalr	-456(ra) # 80003098 <balloc>
    80003268:	0005059b          	sext.w	a1,a0
    8000326c:	08b92023          	sw	a1,128(s2)
    80003270:	b751                	j	800031f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003272:	00092503          	lw	a0,0(s2)
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	e22080e7          	jalr	-478(ra) # 80003098 <balloc>
    8000327e:	0005099b          	sext.w	s3,a0
    80003282:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003286:	8552                	mv	a0,s4
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	f02080e7          	jalr	-254(ra) # 8000418a <log_write>
    80003290:	b769                	j	8000321a <bmap+0x54>
  panic("bmap: out of range");
    80003292:	00005517          	auipc	a0,0x5
    80003296:	2d650513          	addi	a0,a0,726 # 80008568 <syscalls+0x120>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2a0080e7          	jalr	672(ra) # 8000053a <panic>

00000000800032a2 <iget>:
{
    800032a2:	7179                	addi	sp,sp,-48
    800032a4:	f406                	sd	ra,40(sp)
    800032a6:	f022                	sd	s0,32(sp)
    800032a8:	ec26                	sd	s1,24(sp)
    800032aa:	e84a                	sd	s2,16(sp)
    800032ac:	e44e                	sd	s3,8(sp)
    800032ae:	e052                	sd	s4,0(sp)
    800032b0:	1800                	addi	s0,sp,48
    800032b2:	89aa                	mv	s3,a0
    800032b4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032b6:	0001c517          	auipc	a0,0x1c
    800032ba:	51250513          	addi	a0,a0,1298 # 8001f7c8 <itable>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	912080e7          	jalr	-1774(ra) # 80000bd0 <acquire>
  empty = 0;
    800032c6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032c8:	0001c497          	auipc	s1,0x1c
    800032cc:	51848493          	addi	s1,s1,1304 # 8001f7e0 <itable+0x18>
    800032d0:	0001e697          	auipc	a3,0x1e
    800032d4:	fa068693          	addi	a3,a3,-96 # 80021270 <log>
    800032d8:	a039                	j	800032e6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032da:	02090b63          	beqz	s2,80003310 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032de:	08848493          	addi	s1,s1,136
    800032e2:	02d48a63          	beq	s1,a3,80003316 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032e6:	449c                	lw	a5,8(s1)
    800032e8:	fef059e3          	blez	a5,800032da <iget+0x38>
    800032ec:	4098                	lw	a4,0(s1)
    800032ee:	ff3716e3          	bne	a4,s3,800032da <iget+0x38>
    800032f2:	40d8                	lw	a4,4(s1)
    800032f4:	ff4713e3          	bne	a4,s4,800032da <iget+0x38>
      ip->ref++;
    800032f8:	2785                	addiw	a5,a5,1
    800032fa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800032fc:	0001c517          	auipc	a0,0x1c
    80003300:	4cc50513          	addi	a0,a0,1228 # 8001f7c8 <itable>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	980080e7          	jalr	-1664(ra) # 80000c84 <release>
      return ip;
    8000330c:	8926                	mv	s2,s1
    8000330e:	a03d                	j	8000333c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003310:	f7f9                	bnez	a5,800032de <iget+0x3c>
    80003312:	8926                	mv	s2,s1
    80003314:	b7e9                	j	800032de <iget+0x3c>
  if(empty == 0)
    80003316:	02090c63          	beqz	s2,8000334e <iget+0xac>
  ip->dev = dev;
    8000331a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000331e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003322:	4785                	li	a5,1
    80003324:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003328:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000332c:	0001c517          	auipc	a0,0x1c
    80003330:	49c50513          	addi	a0,a0,1180 # 8001f7c8 <itable>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	950080e7          	jalr	-1712(ra) # 80000c84 <release>
}
    8000333c:	854a                	mv	a0,s2
    8000333e:	70a2                	ld	ra,40(sp)
    80003340:	7402                	ld	s0,32(sp)
    80003342:	64e2                	ld	s1,24(sp)
    80003344:	6942                	ld	s2,16(sp)
    80003346:	69a2                	ld	s3,8(sp)
    80003348:	6a02                	ld	s4,0(sp)
    8000334a:	6145                	addi	sp,sp,48
    8000334c:	8082                	ret
    panic("iget: no inodes");
    8000334e:	00005517          	auipc	a0,0x5
    80003352:	23250513          	addi	a0,a0,562 # 80008580 <syscalls+0x138>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	1e4080e7          	jalr	484(ra) # 8000053a <panic>

000000008000335e <fsinit>:
fsinit(int dev) {
    8000335e:	7179                	addi	sp,sp,-48
    80003360:	f406                	sd	ra,40(sp)
    80003362:	f022                	sd	s0,32(sp)
    80003364:	ec26                	sd	s1,24(sp)
    80003366:	e84a                	sd	s2,16(sp)
    80003368:	e44e                	sd	s3,8(sp)
    8000336a:	1800                	addi	s0,sp,48
    8000336c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000336e:	4585                	li	a1,1
    80003370:	00000097          	auipc	ra,0x0
    80003374:	a66080e7          	jalr	-1434(ra) # 80002dd6 <bread>
    80003378:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000337a:	0001c997          	auipc	s3,0x1c
    8000337e:	42e98993          	addi	s3,s3,1070 # 8001f7a8 <sb>
    80003382:	02000613          	li	a2,32
    80003386:	05850593          	addi	a1,a0,88
    8000338a:	854e                	mv	a0,s3
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	99c080e7          	jalr	-1636(ra) # 80000d28 <memmove>
  brelse(bp);
    80003394:	8526                	mv	a0,s1
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	b70080e7          	jalr	-1168(ra) # 80002f06 <brelse>
  if(sb.magic != FSMAGIC)
    8000339e:	0009a703          	lw	a4,0(s3)
    800033a2:	102037b7          	lui	a5,0x10203
    800033a6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033aa:	02f71263          	bne	a4,a5,800033ce <fsinit+0x70>
  initlog(dev, &sb);
    800033ae:	0001c597          	auipc	a1,0x1c
    800033b2:	3fa58593          	addi	a1,a1,1018 # 8001f7a8 <sb>
    800033b6:	854a                	mv	a0,s2
    800033b8:	00001097          	auipc	ra,0x1
    800033bc:	b56080e7          	jalr	-1194(ra) # 80003f0e <initlog>
}
    800033c0:	70a2                	ld	ra,40(sp)
    800033c2:	7402                	ld	s0,32(sp)
    800033c4:	64e2                	ld	s1,24(sp)
    800033c6:	6942                	ld	s2,16(sp)
    800033c8:	69a2                	ld	s3,8(sp)
    800033ca:	6145                	addi	sp,sp,48
    800033cc:	8082                	ret
    panic("invalid file system");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	1c250513          	addi	a0,a0,450 # 80008590 <syscalls+0x148>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	164080e7          	jalr	356(ra) # 8000053a <panic>

00000000800033de <iinit>:
{
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033ec:	00005597          	auipc	a1,0x5
    800033f0:	1bc58593          	addi	a1,a1,444 # 800085a8 <syscalls+0x160>
    800033f4:	0001c517          	auipc	a0,0x1c
    800033f8:	3d450513          	addi	a0,a0,980 # 8001f7c8 <itable>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	744080e7          	jalr	1860(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003404:	0001c497          	auipc	s1,0x1c
    80003408:	3ec48493          	addi	s1,s1,1004 # 8001f7f0 <itable+0x28>
    8000340c:	0001e997          	auipc	s3,0x1e
    80003410:	e7498993          	addi	s3,s3,-396 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003414:	00005917          	auipc	s2,0x5
    80003418:	19c90913          	addi	s2,s2,412 # 800085b0 <syscalls+0x168>
    8000341c:	85ca                	mv	a1,s2
    8000341e:	8526                	mv	a0,s1
    80003420:	00001097          	auipc	ra,0x1
    80003424:	e4e080e7          	jalr	-434(ra) # 8000426e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003428:	08848493          	addi	s1,s1,136
    8000342c:	ff3498e3          	bne	s1,s3,8000341c <iinit+0x3e>
}
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6145                	addi	sp,sp,48
    8000343c:	8082                	ret

000000008000343e <ialloc>:
{
    8000343e:	715d                	addi	sp,sp,-80
    80003440:	e486                	sd	ra,72(sp)
    80003442:	e0a2                	sd	s0,64(sp)
    80003444:	fc26                	sd	s1,56(sp)
    80003446:	f84a                	sd	s2,48(sp)
    80003448:	f44e                	sd	s3,40(sp)
    8000344a:	f052                	sd	s4,32(sp)
    8000344c:	ec56                	sd	s5,24(sp)
    8000344e:	e85a                	sd	s6,16(sp)
    80003450:	e45e                	sd	s7,8(sp)
    80003452:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003454:	0001c717          	auipc	a4,0x1c
    80003458:	36072703          	lw	a4,864(a4) # 8001f7b4 <sb+0xc>
    8000345c:	4785                	li	a5,1
    8000345e:	04e7fa63          	bgeu	a5,a4,800034b2 <ialloc+0x74>
    80003462:	8aaa                	mv	s5,a0
    80003464:	8bae                	mv	s7,a1
    80003466:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003468:	0001ca17          	auipc	s4,0x1c
    8000346c:	340a0a13          	addi	s4,s4,832 # 8001f7a8 <sb>
    80003470:	00048b1b          	sext.w	s6,s1
    80003474:	0044d593          	srli	a1,s1,0x4
    80003478:	018a2783          	lw	a5,24(s4)
    8000347c:	9dbd                	addw	a1,a1,a5
    8000347e:	8556                	mv	a0,s5
    80003480:	00000097          	auipc	ra,0x0
    80003484:	956080e7          	jalr	-1706(ra) # 80002dd6 <bread>
    80003488:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000348a:	05850993          	addi	s3,a0,88
    8000348e:	00f4f793          	andi	a5,s1,15
    80003492:	079a                	slli	a5,a5,0x6
    80003494:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003496:	00099783          	lh	a5,0(s3)
    8000349a:	c785                	beqz	a5,800034c2 <ialloc+0x84>
    brelse(bp);
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	a6a080e7          	jalr	-1430(ra) # 80002f06 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034a4:	0485                	addi	s1,s1,1
    800034a6:	00ca2703          	lw	a4,12(s4)
    800034aa:	0004879b          	sext.w	a5,s1
    800034ae:	fce7e1e3          	bltu	a5,a4,80003470 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	10650513          	addi	a0,a0,262 # 800085b8 <syscalls+0x170>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	080080e7          	jalr	128(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800034c2:	04000613          	li	a2,64
    800034c6:	4581                	li	a1,0
    800034c8:	854e                	mv	a0,s3
    800034ca:	ffffe097          	auipc	ra,0xffffe
    800034ce:	802080e7          	jalr	-2046(ra) # 80000ccc <memset>
      dip->type = type;
    800034d2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034d6:	854a                	mv	a0,s2
    800034d8:	00001097          	auipc	ra,0x1
    800034dc:	cb2080e7          	jalr	-846(ra) # 8000418a <log_write>
      brelse(bp);
    800034e0:	854a                	mv	a0,s2
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	a24080e7          	jalr	-1500(ra) # 80002f06 <brelse>
      return iget(dev, inum);
    800034ea:	85da                	mv	a1,s6
    800034ec:	8556                	mv	a0,s5
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	db4080e7          	jalr	-588(ra) # 800032a2 <iget>
}
    800034f6:	60a6                	ld	ra,72(sp)
    800034f8:	6406                	ld	s0,64(sp)
    800034fa:	74e2                	ld	s1,56(sp)
    800034fc:	7942                	ld	s2,48(sp)
    800034fe:	79a2                	ld	s3,40(sp)
    80003500:	7a02                	ld	s4,32(sp)
    80003502:	6ae2                	ld	s5,24(sp)
    80003504:	6b42                	ld	s6,16(sp)
    80003506:	6ba2                	ld	s7,8(sp)
    80003508:	6161                	addi	sp,sp,80
    8000350a:	8082                	ret

000000008000350c <iupdate>:
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	e426                	sd	s1,8(sp)
    80003514:	e04a                	sd	s2,0(sp)
    80003516:	1000                	addi	s0,sp,32
    80003518:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000351a:	415c                	lw	a5,4(a0)
    8000351c:	0047d79b          	srliw	a5,a5,0x4
    80003520:	0001c597          	auipc	a1,0x1c
    80003524:	2a05a583          	lw	a1,672(a1) # 8001f7c0 <sb+0x18>
    80003528:	9dbd                	addw	a1,a1,a5
    8000352a:	4108                	lw	a0,0(a0)
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	8aa080e7          	jalr	-1878(ra) # 80002dd6 <bread>
    80003534:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003536:	05850793          	addi	a5,a0,88
    8000353a:	40d8                	lw	a4,4(s1)
    8000353c:	8b3d                	andi	a4,a4,15
    8000353e:	071a                	slli	a4,a4,0x6
    80003540:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003542:	04449703          	lh	a4,68(s1)
    80003546:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000354a:	04649703          	lh	a4,70(s1)
    8000354e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003552:	04849703          	lh	a4,72(s1)
    80003556:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000355a:	04a49703          	lh	a4,74(s1)
    8000355e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003562:	44f8                	lw	a4,76(s1)
    80003564:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003566:	03400613          	li	a2,52
    8000356a:	05048593          	addi	a1,s1,80
    8000356e:	00c78513          	addi	a0,a5,12
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	7b6080e7          	jalr	1974(ra) # 80000d28 <memmove>
  log_write(bp);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	c0e080e7          	jalr	-1010(ra) # 8000418a <log_write>
  brelse(bp);
    80003584:	854a                	mv	a0,s2
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	980080e7          	jalr	-1664(ra) # 80002f06 <brelse>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	64a2                	ld	s1,8(sp)
    80003594:	6902                	ld	s2,0(sp)
    80003596:	6105                	addi	sp,sp,32
    80003598:	8082                	ret

000000008000359a <idup>:
{
    8000359a:	1101                	addi	sp,sp,-32
    8000359c:	ec06                	sd	ra,24(sp)
    8000359e:	e822                	sd	s0,16(sp)
    800035a0:	e426                	sd	s1,8(sp)
    800035a2:	1000                	addi	s0,sp,32
    800035a4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035a6:	0001c517          	auipc	a0,0x1c
    800035aa:	22250513          	addi	a0,a0,546 # 8001f7c8 <itable>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	622080e7          	jalr	1570(ra) # 80000bd0 <acquire>
  ip->ref++;
    800035b6:	449c                	lw	a5,8(s1)
    800035b8:	2785                	addiw	a5,a5,1
    800035ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035bc:	0001c517          	auipc	a0,0x1c
    800035c0:	20c50513          	addi	a0,a0,524 # 8001f7c8 <itable>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	6c0080e7          	jalr	1728(ra) # 80000c84 <release>
}
    800035cc:	8526                	mv	a0,s1
    800035ce:	60e2                	ld	ra,24(sp)
    800035d0:	6442                	ld	s0,16(sp)
    800035d2:	64a2                	ld	s1,8(sp)
    800035d4:	6105                	addi	sp,sp,32
    800035d6:	8082                	ret

00000000800035d8 <ilock>:
{
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	e426                	sd	s1,8(sp)
    800035e0:	e04a                	sd	s2,0(sp)
    800035e2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035e4:	c115                	beqz	a0,80003608 <ilock+0x30>
    800035e6:	84aa                	mv	s1,a0
    800035e8:	451c                	lw	a5,8(a0)
    800035ea:	00f05f63          	blez	a5,80003608 <ilock+0x30>
  acquiresleep(&ip->lock);
    800035ee:	0541                	addi	a0,a0,16
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	cb8080e7          	jalr	-840(ra) # 800042a8 <acquiresleep>
  if(ip->valid == 0){
    800035f8:	40bc                	lw	a5,64(s1)
    800035fa:	cf99                	beqz	a5,80003618 <ilock+0x40>
}
    800035fc:	60e2                	ld	ra,24(sp)
    800035fe:	6442                	ld	s0,16(sp)
    80003600:	64a2                	ld	s1,8(sp)
    80003602:	6902                	ld	s2,0(sp)
    80003604:	6105                	addi	sp,sp,32
    80003606:	8082                	ret
    panic("ilock");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	fc850513          	addi	a0,a0,-56 # 800085d0 <syscalls+0x188>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f2a080e7          	jalr	-214(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003618:	40dc                	lw	a5,4(s1)
    8000361a:	0047d79b          	srliw	a5,a5,0x4
    8000361e:	0001c597          	auipc	a1,0x1c
    80003622:	1a25a583          	lw	a1,418(a1) # 8001f7c0 <sb+0x18>
    80003626:	9dbd                	addw	a1,a1,a5
    80003628:	4088                	lw	a0,0(s1)
    8000362a:	fffff097          	auipc	ra,0xfffff
    8000362e:	7ac080e7          	jalr	1964(ra) # 80002dd6 <bread>
    80003632:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003634:	05850593          	addi	a1,a0,88
    80003638:	40dc                	lw	a5,4(s1)
    8000363a:	8bbd                	andi	a5,a5,15
    8000363c:	079a                	slli	a5,a5,0x6
    8000363e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003640:	00059783          	lh	a5,0(a1)
    80003644:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003648:	00259783          	lh	a5,2(a1)
    8000364c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003650:	00459783          	lh	a5,4(a1)
    80003654:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003658:	00659783          	lh	a5,6(a1)
    8000365c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003660:	459c                	lw	a5,8(a1)
    80003662:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003664:	03400613          	li	a2,52
    80003668:	05b1                	addi	a1,a1,12
    8000366a:	05048513          	addi	a0,s1,80
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	6ba080e7          	jalr	1722(ra) # 80000d28 <memmove>
    brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	88e080e7          	jalr	-1906(ra) # 80002f06 <brelse>
    ip->valid = 1;
    80003680:	4785                	li	a5,1
    80003682:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003684:	04449783          	lh	a5,68(s1)
    80003688:	fbb5                	bnez	a5,800035fc <ilock+0x24>
      panic("ilock: no type");
    8000368a:	00005517          	auipc	a0,0x5
    8000368e:	f4e50513          	addi	a0,a0,-178 # 800085d8 <syscalls+0x190>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	ea8080e7          	jalr	-344(ra) # 8000053a <panic>

000000008000369a <iunlock>:
{
    8000369a:	1101                	addi	sp,sp,-32
    8000369c:	ec06                	sd	ra,24(sp)
    8000369e:	e822                	sd	s0,16(sp)
    800036a0:	e426                	sd	s1,8(sp)
    800036a2:	e04a                	sd	s2,0(sp)
    800036a4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036a6:	c905                	beqz	a0,800036d6 <iunlock+0x3c>
    800036a8:	84aa                	mv	s1,a0
    800036aa:	01050913          	addi	s2,a0,16
    800036ae:	854a                	mv	a0,s2
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	c92080e7          	jalr	-878(ra) # 80004342 <holdingsleep>
    800036b8:	cd19                	beqz	a0,800036d6 <iunlock+0x3c>
    800036ba:	449c                	lw	a5,8(s1)
    800036bc:	00f05d63          	blez	a5,800036d6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	c3c080e7          	jalr	-964(ra) # 800042fe <releasesleep>
}
    800036ca:	60e2                	ld	ra,24(sp)
    800036cc:	6442                	ld	s0,16(sp)
    800036ce:	64a2                	ld	s1,8(sp)
    800036d0:	6902                	ld	s2,0(sp)
    800036d2:	6105                	addi	sp,sp,32
    800036d4:	8082                	ret
    panic("iunlock");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	f1250513          	addi	a0,a0,-238 # 800085e8 <syscalls+0x1a0>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e5c080e7          	jalr	-420(ra) # 8000053a <panic>

00000000800036e6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036e6:	7179                	addi	sp,sp,-48
    800036e8:	f406                	sd	ra,40(sp)
    800036ea:	f022                	sd	s0,32(sp)
    800036ec:	ec26                	sd	s1,24(sp)
    800036ee:	e84a                	sd	s2,16(sp)
    800036f0:	e44e                	sd	s3,8(sp)
    800036f2:	e052                	sd	s4,0(sp)
    800036f4:	1800                	addi	s0,sp,48
    800036f6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036f8:	05050493          	addi	s1,a0,80
    800036fc:	08050913          	addi	s2,a0,128
    80003700:	a021                	j	80003708 <itrunc+0x22>
    80003702:	0491                	addi	s1,s1,4
    80003704:	01248d63          	beq	s1,s2,8000371e <itrunc+0x38>
    if(ip->addrs[i]){
    80003708:	408c                	lw	a1,0(s1)
    8000370a:	dde5                	beqz	a1,80003702 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000370c:	0009a503          	lw	a0,0(s3)
    80003710:	00000097          	auipc	ra,0x0
    80003714:	90c080e7          	jalr	-1780(ra) # 8000301c <bfree>
      ip->addrs[i] = 0;
    80003718:	0004a023          	sw	zero,0(s1)
    8000371c:	b7dd                	j	80003702 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000371e:	0809a583          	lw	a1,128(s3)
    80003722:	e185                	bnez	a1,80003742 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003724:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003728:	854e                	mv	a0,s3
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	de2080e7          	jalr	-542(ra) # 8000350c <iupdate>
}
    80003732:	70a2                	ld	ra,40(sp)
    80003734:	7402                	ld	s0,32(sp)
    80003736:	64e2                	ld	s1,24(sp)
    80003738:	6942                	ld	s2,16(sp)
    8000373a:	69a2                	ld	s3,8(sp)
    8000373c:	6a02                	ld	s4,0(sp)
    8000373e:	6145                	addi	sp,sp,48
    80003740:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003742:	0009a503          	lw	a0,0(s3)
    80003746:	fffff097          	auipc	ra,0xfffff
    8000374a:	690080e7          	jalr	1680(ra) # 80002dd6 <bread>
    8000374e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003750:	05850493          	addi	s1,a0,88
    80003754:	45850913          	addi	s2,a0,1112
    80003758:	a021                	j	80003760 <itrunc+0x7a>
    8000375a:	0491                	addi	s1,s1,4
    8000375c:	01248b63          	beq	s1,s2,80003772 <itrunc+0x8c>
      if(a[j])
    80003760:	408c                	lw	a1,0(s1)
    80003762:	dde5                	beqz	a1,8000375a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003764:	0009a503          	lw	a0,0(s3)
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	8b4080e7          	jalr	-1868(ra) # 8000301c <bfree>
    80003770:	b7ed                	j	8000375a <itrunc+0x74>
    brelse(bp);
    80003772:	8552                	mv	a0,s4
    80003774:	fffff097          	auipc	ra,0xfffff
    80003778:	792080e7          	jalr	1938(ra) # 80002f06 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000377c:	0809a583          	lw	a1,128(s3)
    80003780:	0009a503          	lw	a0,0(s3)
    80003784:	00000097          	auipc	ra,0x0
    80003788:	898080e7          	jalr	-1896(ra) # 8000301c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000378c:	0809a023          	sw	zero,128(s3)
    80003790:	bf51                	j	80003724 <itrunc+0x3e>

0000000080003792 <iput>:
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	e04a                	sd	s2,0(sp)
    8000379c:	1000                	addi	s0,sp,32
    8000379e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037a0:	0001c517          	auipc	a0,0x1c
    800037a4:	02850513          	addi	a0,a0,40 # 8001f7c8 <itable>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	428080e7          	jalr	1064(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037b0:	4498                	lw	a4,8(s1)
    800037b2:	4785                	li	a5,1
    800037b4:	02f70363          	beq	a4,a5,800037da <iput+0x48>
  ip->ref--;
    800037b8:	449c                	lw	a5,8(s1)
    800037ba:	37fd                	addiw	a5,a5,-1
    800037bc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037be:	0001c517          	auipc	a0,0x1c
    800037c2:	00a50513          	addi	a0,a0,10 # 8001f7c8 <itable>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	4be080e7          	jalr	1214(ra) # 80000c84 <release>
}
    800037ce:	60e2                	ld	ra,24(sp)
    800037d0:	6442                	ld	s0,16(sp)
    800037d2:	64a2                	ld	s1,8(sp)
    800037d4:	6902                	ld	s2,0(sp)
    800037d6:	6105                	addi	sp,sp,32
    800037d8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037da:	40bc                	lw	a5,64(s1)
    800037dc:	dff1                	beqz	a5,800037b8 <iput+0x26>
    800037de:	04a49783          	lh	a5,74(s1)
    800037e2:	fbf9                	bnez	a5,800037b8 <iput+0x26>
    acquiresleep(&ip->lock);
    800037e4:	01048913          	addi	s2,s1,16
    800037e8:	854a                	mv	a0,s2
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	abe080e7          	jalr	-1346(ra) # 800042a8 <acquiresleep>
    release(&itable.lock);
    800037f2:	0001c517          	auipc	a0,0x1c
    800037f6:	fd650513          	addi	a0,a0,-42 # 8001f7c8 <itable>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	48a080e7          	jalr	1162(ra) # 80000c84 <release>
    itrunc(ip);
    80003802:	8526                	mv	a0,s1
    80003804:	00000097          	auipc	ra,0x0
    80003808:	ee2080e7          	jalr	-286(ra) # 800036e6 <itrunc>
    ip->type = 0;
    8000380c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003810:	8526                	mv	a0,s1
    80003812:	00000097          	auipc	ra,0x0
    80003816:	cfa080e7          	jalr	-774(ra) # 8000350c <iupdate>
    ip->valid = 0;
    8000381a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	ade080e7          	jalr	-1314(ra) # 800042fe <releasesleep>
    acquire(&itable.lock);
    80003828:	0001c517          	auipc	a0,0x1c
    8000382c:	fa050513          	addi	a0,a0,-96 # 8001f7c8 <itable>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	3a0080e7          	jalr	928(ra) # 80000bd0 <acquire>
    80003838:	b741                	j	800037b8 <iput+0x26>

000000008000383a <iunlockput>:
{
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84aa                	mv	s1,a0
  iunlock(ip);
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	e54080e7          	jalr	-428(ra) # 8000369a <iunlock>
  iput(ip);
    8000384e:	8526                	mv	a0,s1
    80003850:	00000097          	auipc	ra,0x0
    80003854:	f42080e7          	jalr	-190(ra) # 80003792 <iput>
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003862:	1141                	addi	sp,sp,-16
    80003864:	e422                	sd	s0,8(sp)
    80003866:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003868:	411c                	lw	a5,0(a0)
    8000386a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000386c:	415c                	lw	a5,4(a0)
    8000386e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003870:	04451783          	lh	a5,68(a0)
    80003874:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003878:	04a51783          	lh	a5,74(a0)
    8000387c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003880:	04c56783          	lwu	a5,76(a0)
    80003884:	e99c                	sd	a5,16(a1)
}
    80003886:	6422                	ld	s0,8(sp)
    80003888:	0141                	addi	sp,sp,16
    8000388a:	8082                	ret

000000008000388c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000388c:	457c                	lw	a5,76(a0)
    8000388e:	0ed7e963          	bltu	a5,a3,80003980 <readi+0xf4>
{
    80003892:	7159                	addi	sp,sp,-112
    80003894:	f486                	sd	ra,104(sp)
    80003896:	f0a2                	sd	s0,96(sp)
    80003898:	eca6                	sd	s1,88(sp)
    8000389a:	e8ca                	sd	s2,80(sp)
    8000389c:	e4ce                	sd	s3,72(sp)
    8000389e:	e0d2                	sd	s4,64(sp)
    800038a0:	fc56                	sd	s5,56(sp)
    800038a2:	f85a                	sd	s6,48(sp)
    800038a4:	f45e                	sd	s7,40(sp)
    800038a6:	f062                	sd	s8,32(sp)
    800038a8:	ec66                	sd	s9,24(sp)
    800038aa:	e86a                	sd	s10,16(sp)
    800038ac:	e46e                	sd	s11,8(sp)
    800038ae:	1880                	addi	s0,sp,112
    800038b0:	8baa                	mv	s7,a0
    800038b2:	8c2e                	mv	s8,a1
    800038b4:	8ab2                	mv	s5,a2
    800038b6:	84b6                	mv	s1,a3
    800038b8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038ba:	9f35                	addw	a4,a4,a3
    return 0;
    800038bc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038be:	0ad76063          	bltu	a4,a3,8000395e <readi+0xd2>
  if(off + n > ip->size)
    800038c2:	00e7f463          	bgeu	a5,a4,800038ca <readi+0x3e>
    n = ip->size - off;
    800038c6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038ca:	0a0b0963          	beqz	s6,8000397c <readi+0xf0>
    800038ce:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038d0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038d4:	5cfd                	li	s9,-1
    800038d6:	a82d                	j	80003910 <readi+0x84>
    800038d8:	020a1d93          	slli	s11,s4,0x20
    800038dc:	020ddd93          	srli	s11,s11,0x20
    800038e0:	05890613          	addi	a2,s2,88
    800038e4:	86ee                	mv	a3,s11
    800038e6:	963a                	add	a2,a2,a4
    800038e8:	85d6                	mv	a1,s5
    800038ea:	8562                	mv	a0,s8
    800038ec:	fffff097          	auipc	ra,0xfffff
    800038f0:	b12080e7          	jalr	-1262(ra) # 800023fe <either_copyout>
    800038f4:	05950d63          	beq	a0,s9,8000394e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800038f8:	854a                	mv	a0,s2
    800038fa:	fffff097          	auipc	ra,0xfffff
    800038fe:	60c080e7          	jalr	1548(ra) # 80002f06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003902:	013a09bb          	addw	s3,s4,s3
    80003906:	009a04bb          	addw	s1,s4,s1
    8000390a:	9aee                	add	s5,s5,s11
    8000390c:	0569f763          	bgeu	s3,s6,8000395a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003910:	000ba903          	lw	s2,0(s7)
    80003914:	00a4d59b          	srliw	a1,s1,0xa
    80003918:	855e                	mv	a0,s7
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	8ac080e7          	jalr	-1876(ra) # 800031c6 <bmap>
    80003922:	0005059b          	sext.w	a1,a0
    80003926:	854a                	mv	a0,s2
    80003928:	fffff097          	auipc	ra,0xfffff
    8000392c:	4ae080e7          	jalr	1198(ra) # 80002dd6 <bread>
    80003930:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003932:	3ff4f713          	andi	a4,s1,1023
    80003936:	40ed07bb          	subw	a5,s10,a4
    8000393a:	413b06bb          	subw	a3,s6,s3
    8000393e:	8a3e                	mv	s4,a5
    80003940:	2781                	sext.w	a5,a5
    80003942:	0006861b          	sext.w	a2,a3
    80003946:	f8f679e3          	bgeu	a2,a5,800038d8 <readi+0x4c>
    8000394a:	8a36                	mv	s4,a3
    8000394c:	b771                	j	800038d8 <readi+0x4c>
      brelse(bp);
    8000394e:	854a                	mv	a0,s2
    80003950:	fffff097          	auipc	ra,0xfffff
    80003954:	5b6080e7          	jalr	1462(ra) # 80002f06 <brelse>
      tot = -1;
    80003958:	59fd                	li	s3,-1
  }
  return tot;
    8000395a:	0009851b          	sext.w	a0,s3
}
    8000395e:	70a6                	ld	ra,104(sp)
    80003960:	7406                	ld	s0,96(sp)
    80003962:	64e6                	ld	s1,88(sp)
    80003964:	6946                	ld	s2,80(sp)
    80003966:	69a6                	ld	s3,72(sp)
    80003968:	6a06                	ld	s4,64(sp)
    8000396a:	7ae2                	ld	s5,56(sp)
    8000396c:	7b42                	ld	s6,48(sp)
    8000396e:	7ba2                	ld	s7,40(sp)
    80003970:	7c02                	ld	s8,32(sp)
    80003972:	6ce2                	ld	s9,24(sp)
    80003974:	6d42                	ld	s10,16(sp)
    80003976:	6da2                	ld	s11,8(sp)
    80003978:	6165                	addi	sp,sp,112
    8000397a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000397c:	89da                	mv	s3,s6
    8000397e:	bff1                	j	8000395a <readi+0xce>
    return 0;
    80003980:	4501                	li	a0,0
}
    80003982:	8082                	ret

0000000080003984 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003984:	457c                	lw	a5,76(a0)
    80003986:	10d7e863          	bltu	a5,a3,80003a96 <writei+0x112>
{
    8000398a:	7159                	addi	sp,sp,-112
    8000398c:	f486                	sd	ra,104(sp)
    8000398e:	f0a2                	sd	s0,96(sp)
    80003990:	eca6                	sd	s1,88(sp)
    80003992:	e8ca                	sd	s2,80(sp)
    80003994:	e4ce                	sd	s3,72(sp)
    80003996:	e0d2                	sd	s4,64(sp)
    80003998:	fc56                	sd	s5,56(sp)
    8000399a:	f85a                	sd	s6,48(sp)
    8000399c:	f45e                	sd	s7,40(sp)
    8000399e:	f062                	sd	s8,32(sp)
    800039a0:	ec66                	sd	s9,24(sp)
    800039a2:	e86a                	sd	s10,16(sp)
    800039a4:	e46e                	sd	s11,8(sp)
    800039a6:	1880                	addi	s0,sp,112
    800039a8:	8b2a                	mv	s6,a0
    800039aa:	8c2e                	mv	s8,a1
    800039ac:	8ab2                	mv	s5,a2
    800039ae:	8936                	mv	s2,a3
    800039b0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039b2:	00e687bb          	addw	a5,a3,a4
    800039b6:	0ed7e263          	bltu	a5,a3,80003a9a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039ba:	00043737          	lui	a4,0x43
    800039be:	0ef76063          	bltu	a4,a5,80003a9e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039c2:	0c0b8863          	beqz	s7,80003a92 <writei+0x10e>
    800039c6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039cc:	5cfd                	li	s9,-1
    800039ce:	a091                	j	80003a12 <writei+0x8e>
    800039d0:	02099d93          	slli	s11,s3,0x20
    800039d4:	020ddd93          	srli	s11,s11,0x20
    800039d8:	05848513          	addi	a0,s1,88
    800039dc:	86ee                	mv	a3,s11
    800039de:	8656                	mv	a2,s5
    800039e0:	85e2                	mv	a1,s8
    800039e2:	953a                	add	a0,a0,a4
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	a70080e7          	jalr	-1424(ra) # 80002454 <either_copyin>
    800039ec:	07950263          	beq	a0,s9,80003a50 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039f0:	8526                	mv	a0,s1
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	798080e7          	jalr	1944(ra) # 8000418a <log_write>
    brelse(bp);
    800039fa:	8526                	mv	a0,s1
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	50a080e7          	jalr	1290(ra) # 80002f06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a04:	01498a3b          	addw	s4,s3,s4
    80003a08:	0129893b          	addw	s2,s3,s2
    80003a0c:	9aee                	add	s5,s5,s11
    80003a0e:	057a7663          	bgeu	s4,s7,80003a5a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a12:	000b2483          	lw	s1,0(s6)
    80003a16:	00a9559b          	srliw	a1,s2,0xa
    80003a1a:	855a                	mv	a0,s6
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	7aa080e7          	jalr	1962(ra) # 800031c6 <bmap>
    80003a24:	0005059b          	sext.w	a1,a0
    80003a28:	8526                	mv	a0,s1
    80003a2a:	fffff097          	auipc	ra,0xfffff
    80003a2e:	3ac080e7          	jalr	940(ra) # 80002dd6 <bread>
    80003a32:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a34:	3ff97713          	andi	a4,s2,1023
    80003a38:	40ed07bb          	subw	a5,s10,a4
    80003a3c:	414b86bb          	subw	a3,s7,s4
    80003a40:	89be                	mv	s3,a5
    80003a42:	2781                	sext.w	a5,a5
    80003a44:	0006861b          	sext.w	a2,a3
    80003a48:	f8f674e3          	bgeu	a2,a5,800039d0 <writei+0x4c>
    80003a4c:	89b6                	mv	s3,a3
    80003a4e:	b749                	j	800039d0 <writei+0x4c>
      brelse(bp);
    80003a50:	8526                	mv	a0,s1
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	4b4080e7          	jalr	1204(ra) # 80002f06 <brelse>
  }

  if(off > ip->size)
    80003a5a:	04cb2783          	lw	a5,76(s6)
    80003a5e:	0127f463          	bgeu	a5,s2,80003a66 <writei+0xe2>
    ip->size = off;
    80003a62:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a66:	855a                	mv	a0,s6
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	aa4080e7          	jalr	-1372(ra) # 8000350c <iupdate>

  return tot;
    80003a70:	000a051b          	sext.w	a0,s4
}
    80003a74:	70a6                	ld	ra,104(sp)
    80003a76:	7406                	ld	s0,96(sp)
    80003a78:	64e6                	ld	s1,88(sp)
    80003a7a:	6946                	ld	s2,80(sp)
    80003a7c:	69a6                	ld	s3,72(sp)
    80003a7e:	6a06                	ld	s4,64(sp)
    80003a80:	7ae2                	ld	s5,56(sp)
    80003a82:	7b42                	ld	s6,48(sp)
    80003a84:	7ba2                	ld	s7,40(sp)
    80003a86:	7c02                	ld	s8,32(sp)
    80003a88:	6ce2                	ld	s9,24(sp)
    80003a8a:	6d42                	ld	s10,16(sp)
    80003a8c:	6da2                	ld	s11,8(sp)
    80003a8e:	6165                	addi	sp,sp,112
    80003a90:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a92:	8a5e                	mv	s4,s7
    80003a94:	bfc9                	j	80003a66 <writei+0xe2>
    return -1;
    80003a96:	557d                	li	a0,-1
}
    80003a98:	8082                	ret
    return -1;
    80003a9a:	557d                	li	a0,-1
    80003a9c:	bfe1                	j	80003a74 <writei+0xf0>
    return -1;
    80003a9e:	557d                	li	a0,-1
    80003aa0:	bfd1                	j	80003a74 <writei+0xf0>

0000000080003aa2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003aa2:	1141                	addi	sp,sp,-16
    80003aa4:	e406                	sd	ra,8(sp)
    80003aa6:	e022                	sd	s0,0(sp)
    80003aa8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003aaa:	4639                	li	a2,14
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	2f0080e7          	jalr	752(ra) # 80000d9c <strncmp>
}
    80003ab4:	60a2                	ld	ra,8(sp)
    80003ab6:	6402                	ld	s0,0(sp)
    80003ab8:	0141                	addi	sp,sp,16
    80003aba:	8082                	ret

0000000080003abc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003abc:	7139                	addi	sp,sp,-64
    80003abe:	fc06                	sd	ra,56(sp)
    80003ac0:	f822                	sd	s0,48(sp)
    80003ac2:	f426                	sd	s1,40(sp)
    80003ac4:	f04a                	sd	s2,32(sp)
    80003ac6:	ec4e                	sd	s3,24(sp)
    80003ac8:	e852                	sd	s4,16(sp)
    80003aca:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003acc:	04451703          	lh	a4,68(a0)
    80003ad0:	4785                	li	a5,1
    80003ad2:	00f71a63          	bne	a4,a5,80003ae6 <dirlookup+0x2a>
    80003ad6:	892a                	mv	s2,a0
    80003ad8:	89ae                	mv	s3,a1
    80003ada:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003adc:	457c                	lw	a5,76(a0)
    80003ade:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ae0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ae2:	e79d                	bnez	a5,80003b10 <dirlookup+0x54>
    80003ae4:	a8a5                	j	80003b5c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ae6:	00005517          	auipc	a0,0x5
    80003aea:	b0a50513          	addi	a0,a0,-1270 # 800085f0 <syscalls+0x1a8>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	a4c080e7          	jalr	-1460(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003af6:	00005517          	auipc	a0,0x5
    80003afa:	b1250513          	addi	a0,a0,-1262 # 80008608 <syscalls+0x1c0>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	a3c080e7          	jalr	-1476(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b06:	24c1                	addiw	s1,s1,16
    80003b08:	04c92783          	lw	a5,76(s2)
    80003b0c:	04f4f763          	bgeu	s1,a5,80003b5a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b10:	4741                	li	a4,16
    80003b12:	86a6                	mv	a3,s1
    80003b14:	fc040613          	addi	a2,s0,-64
    80003b18:	4581                	li	a1,0
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	d70080e7          	jalr	-656(ra) # 8000388c <readi>
    80003b24:	47c1                	li	a5,16
    80003b26:	fcf518e3          	bne	a0,a5,80003af6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b2a:	fc045783          	lhu	a5,-64(s0)
    80003b2e:	dfe1                	beqz	a5,80003b06 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b30:	fc240593          	addi	a1,s0,-62
    80003b34:	854e                	mv	a0,s3
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	f6c080e7          	jalr	-148(ra) # 80003aa2 <namecmp>
    80003b3e:	f561                	bnez	a0,80003b06 <dirlookup+0x4a>
      if(poff)
    80003b40:	000a0463          	beqz	s4,80003b48 <dirlookup+0x8c>
        *poff = off;
    80003b44:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b48:	fc045583          	lhu	a1,-64(s0)
    80003b4c:	00092503          	lw	a0,0(s2)
    80003b50:	fffff097          	auipc	ra,0xfffff
    80003b54:	752080e7          	jalr	1874(ra) # 800032a2 <iget>
    80003b58:	a011                	j	80003b5c <dirlookup+0xa0>
  return 0;
    80003b5a:	4501                	li	a0,0
}
    80003b5c:	70e2                	ld	ra,56(sp)
    80003b5e:	7442                	ld	s0,48(sp)
    80003b60:	74a2                	ld	s1,40(sp)
    80003b62:	7902                	ld	s2,32(sp)
    80003b64:	69e2                	ld	s3,24(sp)
    80003b66:	6a42                	ld	s4,16(sp)
    80003b68:	6121                	addi	sp,sp,64
    80003b6a:	8082                	ret

0000000080003b6c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b6c:	711d                	addi	sp,sp,-96
    80003b6e:	ec86                	sd	ra,88(sp)
    80003b70:	e8a2                	sd	s0,80(sp)
    80003b72:	e4a6                	sd	s1,72(sp)
    80003b74:	e0ca                	sd	s2,64(sp)
    80003b76:	fc4e                	sd	s3,56(sp)
    80003b78:	f852                	sd	s4,48(sp)
    80003b7a:	f456                	sd	s5,40(sp)
    80003b7c:	f05a                	sd	s6,32(sp)
    80003b7e:	ec5e                	sd	s7,24(sp)
    80003b80:	e862                	sd	s8,16(sp)
    80003b82:	e466                	sd	s9,8(sp)
    80003b84:	e06a                	sd	s10,0(sp)
    80003b86:	1080                	addi	s0,sp,96
    80003b88:	84aa                	mv	s1,a0
    80003b8a:	8b2e                	mv	s6,a1
    80003b8c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b8e:	00054703          	lbu	a4,0(a0)
    80003b92:	02f00793          	li	a5,47
    80003b96:	02f70363          	beq	a4,a5,80003bbc <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b9a:	ffffe097          	auipc	ra,0xffffe
    80003b9e:	dfc080e7          	jalr	-516(ra) # 80001996 <myproc>
    80003ba2:	15053503          	ld	a0,336(a0)
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	9f4080e7          	jalr	-1548(ra) # 8000359a <idup>
    80003bae:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003bb0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003bb4:	4cb5                	li	s9,13
  len = path - s;
    80003bb6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bb8:	4c05                	li	s8,1
    80003bba:	a87d                	j	80003c78 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003bbc:	4585                	li	a1,1
    80003bbe:	4505                	li	a0,1
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	6e2080e7          	jalr	1762(ra) # 800032a2 <iget>
    80003bc8:	8a2a                	mv	s4,a0
    80003bca:	b7dd                	j	80003bb0 <namex+0x44>
      iunlockput(ip);
    80003bcc:	8552                	mv	a0,s4
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	c6c080e7          	jalr	-916(ra) # 8000383a <iunlockput>
      return 0;
    80003bd6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bd8:	8552                	mv	a0,s4
    80003bda:	60e6                	ld	ra,88(sp)
    80003bdc:	6446                	ld	s0,80(sp)
    80003bde:	64a6                	ld	s1,72(sp)
    80003be0:	6906                	ld	s2,64(sp)
    80003be2:	79e2                	ld	s3,56(sp)
    80003be4:	7a42                	ld	s4,48(sp)
    80003be6:	7aa2                	ld	s5,40(sp)
    80003be8:	7b02                	ld	s6,32(sp)
    80003bea:	6be2                	ld	s7,24(sp)
    80003bec:	6c42                	ld	s8,16(sp)
    80003bee:	6ca2                	ld	s9,8(sp)
    80003bf0:	6d02                	ld	s10,0(sp)
    80003bf2:	6125                	addi	sp,sp,96
    80003bf4:	8082                	ret
      iunlock(ip);
    80003bf6:	8552                	mv	a0,s4
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	aa2080e7          	jalr	-1374(ra) # 8000369a <iunlock>
      return ip;
    80003c00:	bfe1                	j	80003bd8 <namex+0x6c>
      iunlockput(ip);
    80003c02:	8552                	mv	a0,s4
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	c36080e7          	jalr	-970(ra) # 8000383a <iunlockput>
      return 0;
    80003c0c:	8a4e                	mv	s4,s3
    80003c0e:	b7e9                	j	80003bd8 <namex+0x6c>
  len = path - s;
    80003c10:	40998633          	sub	a2,s3,s1
    80003c14:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c18:	09acd863          	bge	s9,s10,80003ca8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c1c:	4639                	li	a2,14
    80003c1e:	85a6                	mv	a1,s1
    80003c20:	8556                	mv	a0,s5
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	106080e7          	jalr	262(ra) # 80000d28 <memmove>
    80003c2a:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c2c:	0004c783          	lbu	a5,0(s1)
    80003c30:	01279763          	bne	a5,s2,80003c3e <namex+0xd2>
    path++;
    80003c34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c36:	0004c783          	lbu	a5,0(s1)
    80003c3a:	ff278de3          	beq	a5,s2,80003c34 <namex+0xc8>
    ilock(ip);
    80003c3e:	8552                	mv	a0,s4
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	998080e7          	jalr	-1640(ra) # 800035d8 <ilock>
    if(ip->type != T_DIR){
    80003c48:	044a1783          	lh	a5,68(s4)
    80003c4c:	f98790e3          	bne	a5,s8,80003bcc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003c50:	000b0563          	beqz	s6,80003c5a <namex+0xee>
    80003c54:	0004c783          	lbu	a5,0(s1)
    80003c58:	dfd9                	beqz	a5,80003bf6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c5a:	865e                	mv	a2,s7
    80003c5c:	85d6                	mv	a1,s5
    80003c5e:	8552                	mv	a0,s4
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	e5c080e7          	jalr	-420(ra) # 80003abc <dirlookup>
    80003c68:	89aa                	mv	s3,a0
    80003c6a:	dd41                	beqz	a0,80003c02 <namex+0x96>
    iunlockput(ip);
    80003c6c:	8552                	mv	a0,s4
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	bcc080e7          	jalr	-1076(ra) # 8000383a <iunlockput>
    ip = next;
    80003c76:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003c78:	0004c783          	lbu	a5,0(s1)
    80003c7c:	01279763          	bne	a5,s2,80003c8a <namex+0x11e>
    path++;
    80003c80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c82:	0004c783          	lbu	a5,0(s1)
    80003c86:	ff278de3          	beq	a5,s2,80003c80 <namex+0x114>
  if(*path == 0)
    80003c8a:	cb9d                	beqz	a5,80003cc0 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003c8c:	0004c783          	lbu	a5,0(s1)
    80003c90:	89a6                	mv	s3,s1
  len = path - s;
    80003c92:	8d5e                	mv	s10,s7
    80003c94:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003c96:	01278963          	beq	a5,s2,80003ca8 <namex+0x13c>
    80003c9a:	dbbd                	beqz	a5,80003c10 <namex+0xa4>
    path++;
    80003c9c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003c9e:	0009c783          	lbu	a5,0(s3)
    80003ca2:	ff279ce3          	bne	a5,s2,80003c9a <namex+0x12e>
    80003ca6:	b7ad                	j	80003c10 <namex+0xa4>
    memmove(name, s, len);
    80003ca8:	2601                	sext.w	a2,a2
    80003caa:	85a6                	mv	a1,s1
    80003cac:	8556                	mv	a0,s5
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	07a080e7          	jalr	122(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003cb6:	9d56                	add	s10,s10,s5
    80003cb8:	000d0023          	sb	zero,0(s10)
    80003cbc:	84ce                	mv	s1,s3
    80003cbe:	b7bd                	j	80003c2c <namex+0xc0>
  if(nameiparent){
    80003cc0:	f00b0ce3          	beqz	s6,80003bd8 <namex+0x6c>
    iput(ip);
    80003cc4:	8552                	mv	a0,s4
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	acc080e7          	jalr	-1332(ra) # 80003792 <iput>
    return 0;
    80003cce:	4a01                	li	s4,0
    80003cd0:	b721                	j	80003bd8 <namex+0x6c>

0000000080003cd2 <dirlink>:
{
    80003cd2:	7139                	addi	sp,sp,-64
    80003cd4:	fc06                	sd	ra,56(sp)
    80003cd6:	f822                	sd	s0,48(sp)
    80003cd8:	f426                	sd	s1,40(sp)
    80003cda:	f04a                	sd	s2,32(sp)
    80003cdc:	ec4e                	sd	s3,24(sp)
    80003cde:	e852                	sd	s4,16(sp)
    80003ce0:	0080                	addi	s0,sp,64
    80003ce2:	892a                	mv	s2,a0
    80003ce4:	8a2e                	mv	s4,a1
    80003ce6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ce8:	4601                	li	a2,0
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	dd2080e7          	jalr	-558(ra) # 80003abc <dirlookup>
    80003cf2:	e93d                	bnez	a0,80003d68 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf4:	04c92483          	lw	s1,76(s2)
    80003cf8:	c49d                	beqz	s1,80003d26 <dirlink+0x54>
    80003cfa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfc:	4741                	li	a4,16
    80003cfe:	86a6                	mv	a3,s1
    80003d00:	fc040613          	addi	a2,s0,-64
    80003d04:	4581                	li	a1,0
    80003d06:	854a                	mv	a0,s2
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	b84080e7          	jalr	-1148(ra) # 8000388c <readi>
    80003d10:	47c1                	li	a5,16
    80003d12:	06f51163          	bne	a0,a5,80003d74 <dirlink+0xa2>
    if(de.inum == 0)
    80003d16:	fc045783          	lhu	a5,-64(s0)
    80003d1a:	c791                	beqz	a5,80003d26 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d1c:	24c1                	addiw	s1,s1,16
    80003d1e:	04c92783          	lw	a5,76(s2)
    80003d22:	fcf4ede3          	bltu	s1,a5,80003cfc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d26:	4639                	li	a2,14
    80003d28:	85d2                	mv	a1,s4
    80003d2a:	fc240513          	addi	a0,s0,-62
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	0aa080e7          	jalr	170(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003d36:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d3a:	4741                	li	a4,16
    80003d3c:	86a6                	mv	a3,s1
    80003d3e:	fc040613          	addi	a2,s0,-64
    80003d42:	4581                	li	a1,0
    80003d44:	854a                	mv	a0,s2
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	c3e080e7          	jalr	-962(ra) # 80003984 <writei>
    80003d4e:	872a                	mv	a4,a0
    80003d50:	47c1                	li	a5,16
  return 0;
    80003d52:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d54:	02f71863          	bne	a4,a5,80003d84 <dirlink+0xb2>
}
    80003d58:	70e2                	ld	ra,56(sp)
    80003d5a:	7442                	ld	s0,48(sp)
    80003d5c:	74a2                	ld	s1,40(sp)
    80003d5e:	7902                	ld	s2,32(sp)
    80003d60:	69e2                	ld	s3,24(sp)
    80003d62:	6a42                	ld	s4,16(sp)
    80003d64:	6121                	addi	sp,sp,64
    80003d66:	8082                	ret
    iput(ip);
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	a2a080e7          	jalr	-1494(ra) # 80003792 <iput>
    return -1;
    80003d70:	557d                	li	a0,-1
    80003d72:	b7dd                	j	80003d58 <dirlink+0x86>
      panic("dirlink read");
    80003d74:	00005517          	auipc	a0,0x5
    80003d78:	8a450513          	addi	a0,a0,-1884 # 80008618 <syscalls+0x1d0>
    80003d7c:	ffffc097          	auipc	ra,0xffffc
    80003d80:	7be080e7          	jalr	1982(ra) # 8000053a <panic>
    panic("dirlink");
    80003d84:	00005517          	auipc	a0,0x5
    80003d88:	9a450513          	addi	a0,a0,-1628 # 80008728 <syscalls+0x2e0>
    80003d8c:	ffffc097          	auipc	ra,0xffffc
    80003d90:	7ae080e7          	jalr	1966(ra) # 8000053a <panic>

0000000080003d94 <namei>:

struct inode*
namei(char *path)
{
    80003d94:	1101                	addi	sp,sp,-32
    80003d96:	ec06                	sd	ra,24(sp)
    80003d98:	e822                	sd	s0,16(sp)
    80003d9a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d9c:	fe040613          	addi	a2,s0,-32
    80003da0:	4581                	li	a1,0
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	dca080e7          	jalr	-566(ra) # 80003b6c <namex>
}
    80003daa:	60e2                	ld	ra,24(sp)
    80003dac:	6442                	ld	s0,16(sp)
    80003dae:	6105                	addi	sp,sp,32
    80003db0:	8082                	ret

0000000080003db2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003db2:	1141                	addi	sp,sp,-16
    80003db4:	e406                	sd	ra,8(sp)
    80003db6:	e022                	sd	s0,0(sp)
    80003db8:	0800                	addi	s0,sp,16
    80003dba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dbc:	4585                	li	a1,1
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	dae080e7          	jalr	-594(ra) # 80003b6c <namex>
}
    80003dc6:	60a2                	ld	ra,8(sp)
    80003dc8:	6402                	ld	s0,0(sp)
    80003dca:	0141                	addi	sp,sp,16
    80003dcc:	8082                	ret

0000000080003dce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dce:	1101                	addi	sp,sp,-32
    80003dd0:	ec06                	sd	ra,24(sp)
    80003dd2:	e822                	sd	s0,16(sp)
    80003dd4:	e426                	sd	s1,8(sp)
    80003dd6:	e04a                	sd	s2,0(sp)
    80003dd8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dda:	0001d917          	auipc	s2,0x1d
    80003dde:	49690913          	addi	s2,s2,1174 # 80021270 <log>
    80003de2:	01892583          	lw	a1,24(s2)
    80003de6:	02892503          	lw	a0,40(s2)
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	fec080e7          	jalr	-20(ra) # 80002dd6 <bread>
    80003df2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003df4:	02c92683          	lw	a3,44(s2)
    80003df8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003dfa:	02d05863          	blez	a3,80003e2a <write_head+0x5c>
    80003dfe:	0001d797          	auipc	a5,0x1d
    80003e02:	4a278793          	addi	a5,a5,1186 # 800212a0 <log+0x30>
    80003e06:	05c50713          	addi	a4,a0,92
    80003e0a:	36fd                	addiw	a3,a3,-1
    80003e0c:	02069613          	slli	a2,a3,0x20
    80003e10:	01e65693          	srli	a3,a2,0x1e
    80003e14:	0001d617          	auipc	a2,0x1d
    80003e18:	49060613          	addi	a2,a2,1168 # 800212a4 <log+0x34>
    80003e1c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e1e:	4390                	lw	a2,0(a5)
    80003e20:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e22:	0791                	addi	a5,a5,4
    80003e24:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e26:	fed79ce3          	bne	a5,a3,80003e1e <write_head+0x50>
  }
  bwrite(buf);
    80003e2a:	8526                	mv	a0,s1
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	09c080e7          	jalr	156(ra) # 80002ec8 <bwrite>
  brelse(buf);
    80003e34:	8526                	mv	a0,s1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	0d0080e7          	jalr	208(ra) # 80002f06 <brelse>
}
    80003e3e:	60e2                	ld	ra,24(sp)
    80003e40:	6442                	ld	s0,16(sp)
    80003e42:	64a2                	ld	s1,8(sp)
    80003e44:	6902                	ld	s2,0(sp)
    80003e46:	6105                	addi	sp,sp,32
    80003e48:	8082                	ret

0000000080003e4a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e4a:	0001d797          	auipc	a5,0x1d
    80003e4e:	4527a783          	lw	a5,1106(a5) # 8002129c <log+0x2c>
    80003e52:	0af05d63          	blez	a5,80003f0c <install_trans+0xc2>
{
    80003e56:	7139                	addi	sp,sp,-64
    80003e58:	fc06                	sd	ra,56(sp)
    80003e5a:	f822                	sd	s0,48(sp)
    80003e5c:	f426                	sd	s1,40(sp)
    80003e5e:	f04a                	sd	s2,32(sp)
    80003e60:	ec4e                	sd	s3,24(sp)
    80003e62:	e852                	sd	s4,16(sp)
    80003e64:	e456                	sd	s5,8(sp)
    80003e66:	e05a                	sd	s6,0(sp)
    80003e68:	0080                	addi	s0,sp,64
    80003e6a:	8b2a                	mv	s6,a0
    80003e6c:	0001da97          	auipc	s5,0x1d
    80003e70:	434a8a93          	addi	s5,s5,1076 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e74:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e76:	0001d997          	auipc	s3,0x1d
    80003e7a:	3fa98993          	addi	s3,s3,1018 # 80021270 <log>
    80003e7e:	a00d                	j	80003ea0 <install_trans+0x56>
    brelse(lbuf);
    80003e80:	854a                	mv	a0,s2
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	084080e7          	jalr	132(ra) # 80002f06 <brelse>
    brelse(dbuf);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	07a080e7          	jalr	122(ra) # 80002f06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e94:	2a05                	addiw	s4,s4,1
    80003e96:	0a91                	addi	s5,s5,4
    80003e98:	02c9a783          	lw	a5,44(s3)
    80003e9c:	04fa5e63          	bge	s4,a5,80003ef8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ea0:	0189a583          	lw	a1,24(s3)
    80003ea4:	014585bb          	addw	a1,a1,s4
    80003ea8:	2585                	addiw	a1,a1,1
    80003eaa:	0289a503          	lw	a0,40(s3)
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	f28080e7          	jalr	-216(ra) # 80002dd6 <bread>
    80003eb6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003eb8:	000aa583          	lw	a1,0(s5)
    80003ebc:	0289a503          	lw	a0,40(s3)
    80003ec0:	fffff097          	auipc	ra,0xfffff
    80003ec4:	f16080e7          	jalr	-234(ra) # 80002dd6 <bread>
    80003ec8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eca:	40000613          	li	a2,1024
    80003ece:	05890593          	addi	a1,s2,88
    80003ed2:	05850513          	addi	a0,a0,88
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	e52080e7          	jalr	-430(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ede:	8526                	mv	a0,s1
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	fe8080e7          	jalr	-24(ra) # 80002ec8 <bwrite>
    if(recovering == 0)
    80003ee8:	f80b1ce3          	bnez	s6,80003e80 <install_trans+0x36>
      bunpin(dbuf);
    80003eec:	8526                	mv	a0,s1
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	0f2080e7          	jalr	242(ra) # 80002fe0 <bunpin>
    80003ef6:	b769                	j	80003e80 <install_trans+0x36>
}
    80003ef8:	70e2                	ld	ra,56(sp)
    80003efa:	7442                	ld	s0,48(sp)
    80003efc:	74a2                	ld	s1,40(sp)
    80003efe:	7902                	ld	s2,32(sp)
    80003f00:	69e2                	ld	s3,24(sp)
    80003f02:	6a42                	ld	s4,16(sp)
    80003f04:	6aa2                	ld	s5,8(sp)
    80003f06:	6b02                	ld	s6,0(sp)
    80003f08:	6121                	addi	sp,sp,64
    80003f0a:	8082                	ret
    80003f0c:	8082                	ret

0000000080003f0e <initlog>:
{
    80003f0e:	7179                	addi	sp,sp,-48
    80003f10:	f406                	sd	ra,40(sp)
    80003f12:	f022                	sd	s0,32(sp)
    80003f14:	ec26                	sd	s1,24(sp)
    80003f16:	e84a                	sd	s2,16(sp)
    80003f18:	e44e                	sd	s3,8(sp)
    80003f1a:	1800                	addi	s0,sp,48
    80003f1c:	892a                	mv	s2,a0
    80003f1e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f20:	0001d497          	auipc	s1,0x1d
    80003f24:	35048493          	addi	s1,s1,848 # 80021270 <log>
    80003f28:	00004597          	auipc	a1,0x4
    80003f2c:	70058593          	addi	a1,a1,1792 # 80008628 <syscalls+0x1e0>
    80003f30:	8526                	mv	a0,s1
    80003f32:	ffffd097          	auipc	ra,0xffffd
    80003f36:	c0e080e7          	jalr	-1010(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80003f3a:	0149a583          	lw	a1,20(s3)
    80003f3e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f40:	0109a783          	lw	a5,16(s3)
    80003f44:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f46:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	e8a080e7          	jalr	-374(ra) # 80002dd6 <bread>
  log.lh.n = lh->n;
    80003f54:	4d34                	lw	a3,88(a0)
    80003f56:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f58:	02d05663          	blez	a3,80003f84 <initlog+0x76>
    80003f5c:	05c50793          	addi	a5,a0,92
    80003f60:	0001d717          	auipc	a4,0x1d
    80003f64:	34070713          	addi	a4,a4,832 # 800212a0 <log+0x30>
    80003f68:	36fd                	addiw	a3,a3,-1
    80003f6a:	02069613          	slli	a2,a3,0x20
    80003f6e:	01e65693          	srli	a3,a2,0x1e
    80003f72:	06050613          	addi	a2,a0,96
    80003f76:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f78:	4390                	lw	a2,0(a5)
    80003f7a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7c:	0791                	addi	a5,a5,4
    80003f7e:	0711                	addi	a4,a4,4
    80003f80:	fed79ce3          	bne	a5,a3,80003f78 <initlog+0x6a>
  brelse(buf);
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	f82080e7          	jalr	-126(ra) # 80002f06 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f8c:	4505                	li	a0,1
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	ebc080e7          	jalr	-324(ra) # 80003e4a <install_trans>
  log.lh.n = 0;
    80003f96:	0001d797          	auipc	a5,0x1d
    80003f9a:	3007a323          	sw	zero,774(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	e30080e7          	jalr	-464(ra) # 80003dce <write_head>
}
    80003fa6:	70a2                	ld	ra,40(sp)
    80003fa8:	7402                	ld	s0,32(sp)
    80003faa:	64e2                	ld	s1,24(sp)
    80003fac:	6942                	ld	s2,16(sp)
    80003fae:	69a2                	ld	s3,8(sp)
    80003fb0:	6145                	addi	sp,sp,48
    80003fb2:	8082                	ret

0000000080003fb4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fb4:	1101                	addi	sp,sp,-32
    80003fb6:	ec06                	sd	ra,24(sp)
    80003fb8:	e822                	sd	s0,16(sp)
    80003fba:	e426                	sd	s1,8(sp)
    80003fbc:	e04a                	sd	s2,0(sp)
    80003fbe:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fc0:	0001d517          	auipc	a0,0x1d
    80003fc4:	2b050513          	addi	a0,a0,688 # 80021270 <log>
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	c08080e7          	jalr	-1016(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80003fd0:	0001d497          	auipc	s1,0x1d
    80003fd4:	2a048493          	addi	s1,s1,672 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fd8:	4979                	li	s2,30
    80003fda:	a039                	j	80003fe8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fdc:	85a6                	mv	a1,s1
    80003fde:	8526                	mv	a0,s1
    80003fe0:	ffffe097          	auipc	ra,0xffffe
    80003fe4:	07a080e7          	jalr	122(ra) # 8000205a <sleep>
    if(log.committing){
    80003fe8:	50dc                	lw	a5,36(s1)
    80003fea:	fbed                	bnez	a5,80003fdc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fec:	5098                	lw	a4,32(s1)
    80003fee:	2705                	addiw	a4,a4,1
    80003ff0:	0007069b          	sext.w	a3,a4
    80003ff4:	0027179b          	slliw	a5,a4,0x2
    80003ff8:	9fb9                	addw	a5,a5,a4
    80003ffa:	0017979b          	slliw	a5,a5,0x1
    80003ffe:	54d8                	lw	a4,44(s1)
    80004000:	9fb9                	addw	a5,a5,a4
    80004002:	00f95963          	bge	s2,a5,80004014 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004006:	85a6                	mv	a1,s1
    80004008:	8526                	mv	a0,s1
    8000400a:	ffffe097          	auipc	ra,0xffffe
    8000400e:	050080e7          	jalr	80(ra) # 8000205a <sleep>
    80004012:	bfd9                	j	80003fe8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004014:	0001d517          	auipc	a0,0x1d
    80004018:	25c50513          	addi	a0,a0,604 # 80021270 <log>
    8000401c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	c66080e7          	jalr	-922(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004026:	60e2                	ld	ra,24(sp)
    80004028:	6442                	ld	s0,16(sp)
    8000402a:	64a2                	ld	s1,8(sp)
    8000402c:	6902                	ld	s2,0(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004032:	7139                	addi	sp,sp,-64
    80004034:	fc06                	sd	ra,56(sp)
    80004036:	f822                	sd	s0,48(sp)
    80004038:	f426                	sd	s1,40(sp)
    8000403a:	f04a                	sd	s2,32(sp)
    8000403c:	ec4e                	sd	s3,24(sp)
    8000403e:	e852                	sd	s4,16(sp)
    80004040:	e456                	sd	s5,8(sp)
    80004042:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004044:	0001d497          	auipc	s1,0x1d
    80004048:	22c48493          	addi	s1,s1,556 # 80021270 <log>
    8000404c:	8526                	mv	a0,s1
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	b82080e7          	jalr	-1150(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004056:	509c                	lw	a5,32(s1)
    80004058:	37fd                	addiw	a5,a5,-1
    8000405a:	0007891b          	sext.w	s2,a5
    8000405e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004060:	50dc                	lw	a5,36(s1)
    80004062:	e7b9                	bnez	a5,800040b0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004064:	04091e63          	bnez	s2,800040c0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004068:	0001d497          	auipc	s1,0x1d
    8000406c:	20848493          	addi	s1,s1,520 # 80021270 <log>
    80004070:	4785                	li	a5,1
    80004072:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004074:	8526                	mv	a0,s1
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	c0e080e7          	jalr	-1010(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000407e:	54dc                	lw	a5,44(s1)
    80004080:	06f04763          	bgtz	a5,800040ee <end_op+0xbc>
    acquire(&log.lock);
    80004084:	0001d497          	auipc	s1,0x1d
    80004088:	1ec48493          	addi	s1,s1,492 # 80021270 <log>
    8000408c:	8526                	mv	a0,s1
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	b42080e7          	jalr	-1214(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004096:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000409a:	8526                	mv	a0,s1
    8000409c:	ffffe097          	auipc	ra,0xffffe
    800040a0:	14a080e7          	jalr	330(ra) # 800021e6 <wakeup>
    release(&log.lock);
    800040a4:	8526                	mv	a0,s1
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	bde080e7          	jalr	-1058(ra) # 80000c84 <release>
}
    800040ae:	a03d                	j	800040dc <end_op+0xaa>
    panic("log.committing");
    800040b0:	00004517          	auipc	a0,0x4
    800040b4:	58050513          	addi	a0,a0,1408 # 80008630 <syscalls+0x1e8>
    800040b8:	ffffc097          	auipc	ra,0xffffc
    800040bc:	482080e7          	jalr	1154(ra) # 8000053a <panic>
    wakeup(&log);
    800040c0:	0001d497          	auipc	s1,0x1d
    800040c4:	1b048493          	addi	s1,s1,432 # 80021270 <log>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	11c080e7          	jalr	284(ra) # 800021e6 <wakeup>
  release(&log.lock);
    800040d2:	8526                	mv	a0,s1
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	bb0080e7          	jalr	-1104(ra) # 80000c84 <release>
}
    800040dc:	70e2                	ld	ra,56(sp)
    800040de:	7442                	ld	s0,48(sp)
    800040e0:	74a2                	ld	s1,40(sp)
    800040e2:	7902                	ld	s2,32(sp)
    800040e4:	69e2                	ld	s3,24(sp)
    800040e6:	6a42                	ld	s4,16(sp)
    800040e8:	6aa2                	ld	s5,8(sp)
    800040ea:	6121                	addi	sp,sp,64
    800040ec:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ee:	0001da97          	auipc	s5,0x1d
    800040f2:	1b2a8a93          	addi	s5,s5,434 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040f6:	0001da17          	auipc	s4,0x1d
    800040fa:	17aa0a13          	addi	s4,s4,378 # 80021270 <log>
    800040fe:	018a2583          	lw	a1,24(s4)
    80004102:	012585bb          	addw	a1,a1,s2
    80004106:	2585                	addiw	a1,a1,1
    80004108:	028a2503          	lw	a0,40(s4)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	cca080e7          	jalr	-822(ra) # 80002dd6 <bread>
    80004114:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004116:	000aa583          	lw	a1,0(s5)
    8000411a:	028a2503          	lw	a0,40(s4)
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	cb8080e7          	jalr	-840(ra) # 80002dd6 <bread>
    80004126:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004128:	40000613          	li	a2,1024
    8000412c:	05850593          	addi	a1,a0,88
    80004130:	05848513          	addi	a0,s1,88
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	bf4080e7          	jalr	-1036(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000413c:	8526                	mv	a0,s1
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	d8a080e7          	jalr	-630(ra) # 80002ec8 <bwrite>
    brelse(from);
    80004146:	854e                	mv	a0,s3
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	dbe080e7          	jalr	-578(ra) # 80002f06 <brelse>
    brelse(to);
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	db4080e7          	jalr	-588(ra) # 80002f06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415a:	2905                	addiw	s2,s2,1
    8000415c:	0a91                	addi	s5,s5,4
    8000415e:	02ca2783          	lw	a5,44(s4)
    80004162:	f8f94ee3          	blt	s2,a5,800040fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	c68080e7          	jalr	-920(ra) # 80003dce <write_head>
    install_trans(0); // Now install writes to home locations
    8000416e:	4501                	li	a0,0
    80004170:	00000097          	auipc	ra,0x0
    80004174:	cda080e7          	jalr	-806(ra) # 80003e4a <install_trans>
    log.lh.n = 0;
    80004178:	0001d797          	auipc	a5,0x1d
    8000417c:	1207a223          	sw	zero,292(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004180:	00000097          	auipc	ra,0x0
    80004184:	c4e080e7          	jalr	-946(ra) # 80003dce <write_head>
    80004188:	bdf5                	j	80004084 <end_op+0x52>

000000008000418a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	e04a                	sd	s2,0(sp)
    80004194:	1000                	addi	s0,sp,32
    80004196:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004198:	0001d917          	auipc	s2,0x1d
    8000419c:	0d890913          	addi	s2,s2,216 # 80021270 <log>
    800041a0:	854a                	mv	a0,s2
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	a2e080e7          	jalr	-1490(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041aa:	02c92603          	lw	a2,44(s2)
    800041ae:	47f5                	li	a5,29
    800041b0:	06c7c563          	blt	a5,a2,8000421a <log_write+0x90>
    800041b4:	0001d797          	auipc	a5,0x1d
    800041b8:	0d87a783          	lw	a5,216(a5) # 8002128c <log+0x1c>
    800041bc:	37fd                	addiw	a5,a5,-1
    800041be:	04f65e63          	bge	a2,a5,8000421a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041c2:	0001d797          	auipc	a5,0x1d
    800041c6:	0ce7a783          	lw	a5,206(a5) # 80021290 <log+0x20>
    800041ca:	06f05063          	blez	a5,8000422a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041ce:	4781                	li	a5,0
    800041d0:	06c05563          	blez	a2,8000423a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041d4:	44cc                	lw	a1,12(s1)
    800041d6:	0001d717          	auipc	a4,0x1d
    800041da:	0ca70713          	addi	a4,a4,202 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041e0:	4314                	lw	a3,0(a4)
    800041e2:	04b68c63          	beq	a3,a1,8000423a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041e6:	2785                	addiw	a5,a5,1
    800041e8:	0711                	addi	a4,a4,4
    800041ea:	fef61be3          	bne	a2,a5,800041e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041ee:	0621                	addi	a2,a2,8
    800041f0:	060a                	slli	a2,a2,0x2
    800041f2:	0001d797          	auipc	a5,0x1d
    800041f6:	07e78793          	addi	a5,a5,126 # 80021270 <log>
    800041fa:	97b2                	add	a5,a5,a2
    800041fc:	44d8                	lw	a4,12(s1)
    800041fe:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004200:	8526                	mv	a0,s1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	da2080e7          	jalr	-606(ra) # 80002fa4 <bpin>
    log.lh.n++;
    8000420a:	0001d717          	auipc	a4,0x1d
    8000420e:	06670713          	addi	a4,a4,102 # 80021270 <log>
    80004212:	575c                	lw	a5,44(a4)
    80004214:	2785                	addiw	a5,a5,1
    80004216:	d75c                	sw	a5,44(a4)
    80004218:	a82d                	j	80004252 <log_write+0xc8>
    panic("too big a transaction");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	42650513          	addi	a0,a0,1062 # 80008640 <syscalls+0x1f8>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	318080e7          	jalr	792(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	42e50513          	addi	a0,a0,1070 # 80008658 <syscalls+0x210>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	308080e7          	jalr	776(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000423a:	00878693          	addi	a3,a5,8
    8000423e:	068a                	slli	a3,a3,0x2
    80004240:	0001d717          	auipc	a4,0x1d
    80004244:	03070713          	addi	a4,a4,48 # 80021270 <log>
    80004248:	9736                	add	a4,a4,a3
    8000424a:	44d4                	lw	a3,12(s1)
    8000424c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000424e:	faf609e3          	beq	a2,a5,80004200 <log_write+0x76>
  }
  release(&log.lock);
    80004252:	0001d517          	auipc	a0,0x1d
    80004256:	01e50513          	addi	a0,a0,30 # 80021270 <log>
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	a2a080e7          	jalr	-1494(ra) # 80000c84 <release>
}
    80004262:	60e2                	ld	ra,24(sp)
    80004264:	6442                	ld	s0,16(sp)
    80004266:	64a2                	ld	s1,8(sp)
    80004268:	6902                	ld	s2,0(sp)
    8000426a:	6105                	addi	sp,sp,32
    8000426c:	8082                	ret

000000008000426e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000426e:	1101                	addi	sp,sp,-32
    80004270:	ec06                	sd	ra,24(sp)
    80004272:	e822                	sd	s0,16(sp)
    80004274:	e426                	sd	s1,8(sp)
    80004276:	e04a                	sd	s2,0(sp)
    80004278:	1000                	addi	s0,sp,32
    8000427a:	84aa                	mv	s1,a0
    8000427c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000427e:	00004597          	auipc	a1,0x4
    80004282:	3fa58593          	addi	a1,a1,1018 # 80008678 <syscalls+0x230>
    80004286:	0521                	addi	a0,a0,8
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	8b8080e7          	jalr	-1864(ra) # 80000b40 <initlock>
  lk->name = name;
    80004290:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004294:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004298:	0204a423          	sw	zero,40(s1)
}
    8000429c:	60e2                	ld	ra,24(sp)
    8000429e:	6442                	ld	s0,16(sp)
    800042a0:	64a2                	ld	s1,8(sp)
    800042a2:	6902                	ld	s2,0(sp)
    800042a4:	6105                	addi	sp,sp,32
    800042a6:	8082                	ret

00000000800042a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	e04a                	sd	s2,0(sp)
    800042b2:	1000                	addi	s0,sp,32
    800042b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042b6:	00850913          	addi	s2,a0,8
    800042ba:	854a                	mv	a0,s2
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	914080e7          	jalr	-1772(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800042c4:	409c                	lw	a5,0(s1)
    800042c6:	cb89                	beqz	a5,800042d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042c8:	85ca                	mv	a1,s2
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	d8e080e7          	jalr	-626(ra) # 8000205a <sleep>
  while (lk->locked) {
    800042d4:	409c                	lw	a5,0(s1)
    800042d6:	fbed                	bnez	a5,800042c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042d8:	4785                	li	a5,1
    800042da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	6ba080e7          	jalr	1722(ra) # 80001996 <myproc>
    800042e4:	591c                	lw	a5,48(a0)
    800042e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042e8:	854a                	mv	a0,s2
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	99a080e7          	jalr	-1638(ra) # 80000c84 <release>
}
    800042f2:	60e2                	ld	ra,24(sp)
    800042f4:	6442                	ld	s0,16(sp)
    800042f6:	64a2                	ld	s1,8(sp)
    800042f8:	6902                	ld	s2,0(sp)
    800042fa:	6105                	addi	sp,sp,32
    800042fc:	8082                	ret

00000000800042fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042fe:	1101                	addi	sp,sp,-32
    80004300:	ec06                	sd	ra,24(sp)
    80004302:	e822                	sd	s0,16(sp)
    80004304:	e426                	sd	s1,8(sp)
    80004306:	e04a                	sd	s2,0(sp)
    80004308:	1000                	addi	s0,sp,32
    8000430a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000430c:	00850913          	addi	s2,a0,8
    80004310:	854a                	mv	a0,s2
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	8be080e7          	jalr	-1858(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000431a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000431e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004322:	8526                	mv	a0,s1
    80004324:	ffffe097          	auipc	ra,0xffffe
    80004328:	ec2080e7          	jalr	-318(ra) # 800021e6 <wakeup>
  release(&lk->lk);
    8000432c:	854a                	mv	a0,s2
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	956080e7          	jalr	-1706(ra) # 80000c84 <release>
}
    80004336:	60e2                	ld	ra,24(sp)
    80004338:	6442                	ld	s0,16(sp)
    8000433a:	64a2                	ld	s1,8(sp)
    8000433c:	6902                	ld	s2,0(sp)
    8000433e:	6105                	addi	sp,sp,32
    80004340:	8082                	ret

0000000080004342 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004342:	7179                	addi	sp,sp,-48
    80004344:	f406                	sd	ra,40(sp)
    80004346:	f022                	sd	s0,32(sp)
    80004348:	ec26                	sd	s1,24(sp)
    8000434a:	e84a                	sd	s2,16(sp)
    8000434c:	e44e                	sd	s3,8(sp)
    8000434e:	1800                	addi	s0,sp,48
    80004350:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004352:	00850913          	addi	s2,a0,8
    80004356:	854a                	mv	a0,s2
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	878080e7          	jalr	-1928(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004360:	409c                	lw	a5,0(s1)
    80004362:	ef99                	bnez	a5,80004380 <holdingsleep+0x3e>
    80004364:	4481                	li	s1,0
  release(&lk->lk);
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	91c080e7          	jalr	-1764(ra) # 80000c84 <release>
  return r;
}
    80004370:	8526                	mv	a0,s1
    80004372:	70a2                	ld	ra,40(sp)
    80004374:	7402                	ld	s0,32(sp)
    80004376:	64e2                	ld	s1,24(sp)
    80004378:	6942                	ld	s2,16(sp)
    8000437a:	69a2                	ld	s3,8(sp)
    8000437c:	6145                	addi	sp,sp,48
    8000437e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004380:	0284a983          	lw	s3,40(s1)
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	612080e7          	jalr	1554(ra) # 80001996 <myproc>
    8000438c:	5904                	lw	s1,48(a0)
    8000438e:	413484b3          	sub	s1,s1,s3
    80004392:	0014b493          	seqz	s1,s1
    80004396:	bfc1                	j	80004366 <holdingsleep+0x24>

0000000080004398 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004398:	1141                	addi	sp,sp,-16
    8000439a:	e406                	sd	ra,8(sp)
    8000439c:	e022                	sd	s0,0(sp)
    8000439e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043a0:	00004597          	auipc	a1,0x4
    800043a4:	2e858593          	addi	a1,a1,744 # 80008688 <syscalls+0x240>
    800043a8:	0001d517          	auipc	a0,0x1d
    800043ac:	01050513          	addi	a0,a0,16 # 800213b8 <ftable>
    800043b0:	ffffc097          	auipc	ra,0xffffc
    800043b4:	790080e7          	jalr	1936(ra) # 80000b40 <initlock>
}
    800043b8:	60a2                	ld	ra,8(sp)
    800043ba:	6402                	ld	s0,0(sp)
    800043bc:	0141                	addi	sp,sp,16
    800043be:	8082                	ret

00000000800043c0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043c0:	1101                	addi	sp,sp,-32
    800043c2:	ec06                	sd	ra,24(sp)
    800043c4:	e822                	sd	s0,16(sp)
    800043c6:	e426                	sd	s1,8(sp)
    800043c8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043ca:	0001d517          	auipc	a0,0x1d
    800043ce:	fee50513          	addi	a0,a0,-18 # 800213b8 <ftable>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	7fe080e7          	jalr	2046(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043da:	0001d497          	auipc	s1,0x1d
    800043de:	ff648493          	addi	s1,s1,-10 # 800213d0 <ftable+0x18>
    800043e2:	0001e717          	auipc	a4,0x1e
    800043e6:	f8e70713          	addi	a4,a4,-114 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043ea:	40dc                	lw	a5,4(s1)
    800043ec:	cf99                	beqz	a5,8000440a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043ee:	02848493          	addi	s1,s1,40
    800043f2:	fee49ce3          	bne	s1,a4,800043ea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043f6:	0001d517          	auipc	a0,0x1d
    800043fa:	fc250513          	addi	a0,a0,-62 # 800213b8 <ftable>
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	886080e7          	jalr	-1914(ra) # 80000c84 <release>
  return 0;
    80004406:	4481                	li	s1,0
    80004408:	a819                	j	8000441e <filealloc+0x5e>
      f->ref = 1;
    8000440a:	4785                	li	a5,1
    8000440c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000440e:	0001d517          	auipc	a0,0x1d
    80004412:	faa50513          	addi	a0,a0,-86 # 800213b8 <ftable>
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	86e080e7          	jalr	-1938(ra) # 80000c84 <release>
}
    8000441e:	8526                	mv	a0,s1
    80004420:	60e2                	ld	ra,24(sp)
    80004422:	6442                	ld	s0,16(sp)
    80004424:	64a2                	ld	s1,8(sp)
    80004426:	6105                	addi	sp,sp,32
    80004428:	8082                	ret

000000008000442a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	1000                	addi	s0,sp,32
    80004434:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004436:	0001d517          	auipc	a0,0x1d
    8000443a:	f8250513          	addi	a0,a0,-126 # 800213b8 <ftable>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	792080e7          	jalr	1938(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004446:	40dc                	lw	a5,4(s1)
    80004448:	02f05263          	blez	a5,8000446c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000444c:	2785                	addiw	a5,a5,1
    8000444e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004450:	0001d517          	auipc	a0,0x1d
    80004454:	f6850513          	addi	a0,a0,-152 # 800213b8 <ftable>
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	82c080e7          	jalr	-2004(ra) # 80000c84 <release>
  return f;
}
    80004460:	8526                	mv	a0,s1
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6105                	addi	sp,sp,32
    8000446a:	8082                	ret
    panic("filedup");
    8000446c:	00004517          	auipc	a0,0x4
    80004470:	22450513          	addi	a0,a0,548 # 80008690 <syscalls+0x248>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	0c6080e7          	jalr	198(ra) # 8000053a <panic>

000000008000447c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000447c:	7139                	addi	sp,sp,-64
    8000447e:	fc06                	sd	ra,56(sp)
    80004480:	f822                	sd	s0,48(sp)
    80004482:	f426                	sd	s1,40(sp)
    80004484:	f04a                	sd	s2,32(sp)
    80004486:	ec4e                	sd	s3,24(sp)
    80004488:	e852                	sd	s4,16(sp)
    8000448a:	e456                	sd	s5,8(sp)
    8000448c:	0080                	addi	s0,sp,64
    8000448e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004490:	0001d517          	auipc	a0,0x1d
    80004494:	f2850513          	addi	a0,a0,-216 # 800213b8 <ftable>
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	738080e7          	jalr	1848(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800044a0:	40dc                	lw	a5,4(s1)
    800044a2:	06f05163          	blez	a5,80004504 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044a6:	37fd                	addiw	a5,a5,-1
    800044a8:	0007871b          	sext.w	a4,a5
    800044ac:	c0dc                	sw	a5,4(s1)
    800044ae:	06e04363          	bgtz	a4,80004514 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044b2:	0004a903          	lw	s2,0(s1)
    800044b6:	0094ca83          	lbu	s5,9(s1)
    800044ba:	0104ba03          	ld	s4,16(s1)
    800044be:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044c2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044c6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044ca:	0001d517          	auipc	a0,0x1d
    800044ce:	eee50513          	addi	a0,a0,-274 # 800213b8 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7b2080e7          	jalr	1970(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800044da:	4785                	li	a5,1
    800044dc:	04f90d63          	beq	s2,a5,80004536 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044e0:	3979                	addiw	s2,s2,-2
    800044e2:	4785                	li	a5,1
    800044e4:	0527e063          	bltu	a5,s2,80004524 <fileclose+0xa8>
    begin_op();
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	acc080e7          	jalr	-1332(ra) # 80003fb4 <begin_op>
    iput(ff.ip);
    800044f0:	854e                	mv	a0,s3
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	2a0080e7          	jalr	672(ra) # 80003792 <iput>
    end_op();
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	b38080e7          	jalr	-1224(ra) # 80004032 <end_op>
    80004502:	a00d                	j	80004524 <fileclose+0xa8>
    panic("fileclose");
    80004504:	00004517          	auipc	a0,0x4
    80004508:	19450513          	addi	a0,a0,404 # 80008698 <syscalls+0x250>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	02e080e7          	jalr	46(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004514:	0001d517          	auipc	a0,0x1d
    80004518:	ea450513          	addi	a0,a0,-348 # 800213b8 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	768080e7          	jalr	1896(ra) # 80000c84 <release>
  }
}
    80004524:	70e2                	ld	ra,56(sp)
    80004526:	7442                	ld	s0,48(sp)
    80004528:	74a2                	ld	s1,40(sp)
    8000452a:	7902                	ld	s2,32(sp)
    8000452c:	69e2                	ld	s3,24(sp)
    8000452e:	6a42                	ld	s4,16(sp)
    80004530:	6aa2                	ld	s5,8(sp)
    80004532:	6121                	addi	sp,sp,64
    80004534:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004536:	85d6                	mv	a1,s5
    80004538:	8552                	mv	a0,s4
    8000453a:	00000097          	auipc	ra,0x0
    8000453e:	34c080e7          	jalr	844(ra) # 80004886 <pipeclose>
    80004542:	b7cd                	j	80004524 <fileclose+0xa8>

0000000080004544 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004544:	715d                	addi	sp,sp,-80
    80004546:	e486                	sd	ra,72(sp)
    80004548:	e0a2                	sd	s0,64(sp)
    8000454a:	fc26                	sd	s1,56(sp)
    8000454c:	f84a                	sd	s2,48(sp)
    8000454e:	f44e                	sd	s3,40(sp)
    80004550:	0880                	addi	s0,sp,80
    80004552:	84aa                	mv	s1,a0
    80004554:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004556:	ffffd097          	auipc	ra,0xffffd
    8000455a:	440080e7          	jalr	1088(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000455e:	409c                	lw	a5,0(s1)
    80004560:	37f9                	addiw	a5,a5,-2
    80004562:	4705                	li	a4,1
    80004564:	04f76763          	bltu	a4,a5,800045b2 <filestat+0x6e>
    80004568:	892a                	mv	s2,a0
    ilock(f->ip);
    8000456a:	6c88                	ld	a0,24(s1)
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	06c080e7          	jalr	108(ra) # 800035d8 <ilock>
    stati(f->ip, &st);
    80004574:	fb840593          	addi	a1,s0,-72
    80004578:	6c88                	ld	a0,24(s1)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	2e8080e7          	jalr	744(ra) # 80003862 <stati>
    iunlock(f->ip);
    80004582:	6c88                	ld	a0,24(s1)
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	116080e7          	jalr	278(ra) # 8000369a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000458c:	46e1                	li	a3,24
    8000458e:	fb840613          	addi	a2,s0,-72
    80004592:	85ce                	mv	a1,s3
    80004594:	05093503          	ld	a0,80(s2)
    80004598:	ffffd097          	auipc	ra,0xffffd
    8000459c:	0c2080e7          	jalr	194(ra) # 8000165a <copyout>
    800045a0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045a4:	60a6                	ld	ra,72(sp)
    800045a6:	6406                	ld	s0,64(sp)
    800045a8:	74e2                	ld	s1,56(sp)
    800045aa:	7942                	ld	s2,48(sp)
    800045ac:	79a2                	ld	s3,40(sp)
    800045ae:	6161                	addi	sp,sp,80
    800045b0:	8082                	ret
  return -1;
    800045b2:	557d                	li	a0,-1
    800045b4:	bfc5                	j	800045a4 <filestat+0x60>

00000000800045b6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045b6:	7179                	addi	sp,sp,-48
    800045b8:	f406                	sd	ra,40(sp)
    800045ba:	f022                	sd	s0,32(sp)
    800045bc:	ec26                	sd	s1,24(sp)
    800045be:	e84a                	sd	s2,16(sp)
    800045c0:	e44e                	sd	s3,8(sp)
    800045c2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045c4:	00854783          	lbu	a5,8(a0)
    800045c8:	c3d5                	beqz	a5,8000466c <fileread+0xb6>
    800045ca:	84aa                	mv	s1,a0
    800045cc:	89ae                	mv	s3,a1
    800045ce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045d0:	411c                	lw	a5,0(a0)
    800045d2:	4705                	li	a4,1
    800045d4:	04e78963          	beq	a5,a4,80004626 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045d8:	470d                	li	a4,3
    800045da:	04e78d63          	beq	a5,a4,80004634 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045de:	4709                	li	a4,2
    800045e0:	06e79e63          	bne	a5,a4,8000465c <fileread+0xa6>
    ilock(f->ip);
    800045e4:	6d08                	ld	a0,24(a0)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	ff2080e7          	jalr	-14(ra) # 800035d8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045ee:	874a                	mv	a4,s2
    800045f0:	5094                	lw	a3,32(s1)
    800045f2:	864e                	mv	a2,s3
    800045f4:	4585                	li	a1,1
    800045f6:	6c88                	ld	a0,24(s1)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	294080e7          	jalr	660(ra) # 8000388c <readi>
    80004600:	892a                	mv	s2,a0
    80004602:	00a05563          	blez	a0,8000460c <fileread+0x56>
      f->off += r;
    80004606:	509c                	lw	a5,32(s1)
    80004608:	9fa9                	addw	a5,a5,a0
    8000460a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000460c:	6c88                	ld	a0,24(s1)
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	08c080e7          	jalr	140(ra) # 8000369a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004616:	854a                	mv	a0,s2
    80004618:	70a2                	ld	ra,40(sp)
    8000461a:	7402                	ld	s0,32(sp)
    8000461c:	64e2                	ld	s1,24(sp)
    8000461e:	6942                	ld	s2,16(sp)
    80004620:	69a2                	ld	s3,8(sp)
    80004622:	6145                	addi	sp,sp,48
    80004624:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004626:	6908                	ld	a0,16(a0)
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	3c0080e7          	jalr	960(ra) # 800049e8 <piperead>
    80004630:	892a                	mv	s2,a0
    80004632:	b7d5                	j	80004616 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004634:	02451783          	lh	a5,36(a0)
    80004638:	03079693          	slli	a3,a5,0x30
    8000463c:	92c1                	srli	a3,a3,0x30
    8000463e:	4725                	li	a4,9
    80004640:	02d76863          	bltu	a4,a3,80004670 <fileread+0xba>
    80004644:	0792                	slli	a5,a5,0x4
    80004646:	0001d717          	auipc	a4,0x1d
    8000464a:	cd270713          	addi	a4,a4,-814 # 80021318 <devsw>
    8000464e:	97ba                	add	a5,a5,a4
    80004650:	639c                	ld	a5,0(a5)
    80004652:	c38d                	beqz	a5,80004674 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004654:	4505                	li	a0,1
    80004656:	9782                	jalr	a5
    80004658:	892a                	mv	s2,a0
    8000465a:	bf75                	j	80004616 <fileread+0x60>
    panic("fileread");
    8000465c:	00004517          	auipc	a0,0x4
    80004660:	04c50513          	addi	a0,a0,76 # 800086a8 <syscalls+0x260>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	ed6080e7          	jalr	-298(ra) # 8000053a <panic>
    return -1;
    8000466c:	597d                	li	s2,-1
    8000466e:	b765                	j	80004616 <fileread+0x60>
      return -1;
    80004670:	597d                	li	s2,-1
    80004672:	b755                	j	80004616 <fileread+0x60>
    80004674:	597d                	li	s2,-1
    80004676:	b745                	j	80004616 <fileread+0x60>

0000000080004678 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004678:	715d                	addi	sp,sp,-80
    8000467a:	e486                	sd	ra,72(sp)
    8000467c:	e0a2                	sd	s0,64(sp)
    8000467e:	fc26                	sd	s1,56(sp)
    80004680:	f84a                	sd	s2,48(sp)
    80004682:	f44e                	sd	s3,40(sp)
    80004684:	f052                	sd	s4,32(sp)
    80004686:	ec56                	sd	s5,24(sp)
    80004688:	e85a                	sd	s6,16(sp)
    8000468a:	e45e                	sd	s7,8(sp)
    8000468c:	e062                	sd	s8,0(sp)
    8000468e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004690:	00954783          	lbu	a5,9(a0)
    80004694:	10078663          	beqz	a5,800047a0 <filewrite+0x128>
    80004698:	892a                	mv	s2,a0
    8000469a:	8b2e                	mv	s6,a1
    8000469c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000469e:	411c                	lw	a5,0(a0)
    800046a0:	4705                	li	a4,1
    800046a2:	02e78263          	beq	a5,a4,800046c6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046a6:	470d                	li	a4,3
    800046a8:	02e78663          	beq	a5,a4,800046d4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ac:	4709                	li	a4,2
    800046ae:	0ee79163          	bne	a5,a4,80004790 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046b2:	0ac05d63          	blez	a2,8000476c <filewrite+0xf4>
    int i = 0;
    800046b6:	4981                	li	s3,0
    800046b8:	6b85                	lui	s7,0x1
    800046ba:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046be:	6c05                	lui	s8,0x1
    800046c0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046c4:	a861                	j	8000475c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046c6:	6908                	ld	a0,16(a0)
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	22e080e7          	jalr	558(ra) # 800048f6 <pipewrite>
    800046d0:	8a2a                	mv	s4,a0
    800046d2:	a045                	j	80004772 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046d4:	02451783          	lh	a5,36(a0)
    800046d8:	03079693          	slli	a3,a5,0x30
    800046dc:	92c1                	srli	a3,a3,0x30
    800046de:	4725                	li	a4,9
    800046e0:	0cd76263          	bltu	a4,a3,800047a4 <filewrite+0x12c>
    800046e4:	0792                	slli	a5,a5,0x4
    800046e6:	0001d717          	auipc	a4,0x1d
    800046ea:	c3270713          	addi	a4,a4,-974 # 80021318 <devsw>
    800046ee:	97ba                	add	a5,a5,a4
    800046f0:	679c                	ld	a5,8(a5)
    800046f2:	cbdd                	beqz	a5,800047a8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800046f4:	4505                	li	a0,1
    800046f6:	9782                	jalr	a5
    800046f8:	8a2a                	mv	s4,a0
    800046fa:	a8a5                	j	80004772 <filewrite+0xfa>
    800046fc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004700:	00000097          	auipc	ra,0x0
    80004704:	8b4080e7          	jalr	-1868(ra) # 80003fb4 <begin_op>
      ilock(f->ip);
    80004708:	01893503          	ld	a0,24(s2)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	ecc080e7          	jalr	-308(ra) # 800035d8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004714:	8756                	mv	a4,s5
    80004716:	02092683          	lw	a3,32(s2)
    8000471a:	01698633          	add	a2,s3,s6
    8000471e:	4585                	li	a1,1
    80004720:	01893503          	ld	a0,24(s2)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	260080e7          	jalr	608(ra) # 80003984 <writei>
    8000472c:	84aa                	mv	s1,a0
    8000472e:	00a05763          	blez	a0,8000473c <filewrite+0xc4>
        f->off += r;
    80004732:	02092783          	lw	a5,32(s2)
    80004736:	9fa9                	addw	a5,a5,a0
    80004738:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000473c:	01893503          	ld	a0,24(s2)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	f5a080e7          	jalr	-166(ra) # 8000369a <iunlock>
      end_op();
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	8ea080e7          	jalr	-1814(ra) # 80004032 <end_op>

      if(r != n1){
    80004750:	009a9f63          	bne	s5,s1,8000476e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004754:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004758:	0149db63          	bge	s3,s4,8000476e <filewrite+0xf6>
      int n1 = n - i;
    8000475c:	413a04bb          	subw	s1,s4,s3
    80004760:	0004879b          	sext.w	a5,s1
    80004764:	f8fbdce3          	bge	s7,a5,800046fc <filewrite+0x84>
    80004768:	84e2                	mv	s1,s8
    8000476a:	bf49                	j	800046fc <filewrite+0x84>
    int i = 0;
    8000476c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000476e:	013a1f63          	bne	s4,s3,8000478c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004772:	8552                	mv	a0,s4
    80004774:	60a6                	ld	ra,72(sp)
    80004776:	6406                	ld	s0,64(sp)
    80004778:	74e2                	ld	s1,56(sp)
    8000477a:	7942                	ld	s2,48(sp)
    8000477c:	79a2                	ld	s3,40(sp)
    8000477e:	7a02                	ld	s4,32(sp)
    80004780:	6ae2                	ld	s5,24(sp)
    80004782:	6b42                	ld	s6,16(sp)
    80004784:	6ba2                	ld	s7,8(sp)
    80004786:	6c02                	ld	s8,0(sp)
    80004788:	6161                	addi	sp,sp,80
    8000478a:	8082                	ret
    ret = (i == n ? n : -1);
    8000478c:	5a7d                	li	s4,-1
    8000478e:	b7d5                	j	80004772 <filewrite+0xfa>
    panic("filewrite");
    80004790:	00004517          	auipc	a0,0x4
    80004794:	f2850513          	addi	a0,a0,-216 # 800086b8 <syscalls+0x270>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	da2080e7          	jalr	-606(ra) # 8000053a <panic>
    return -1;
    800047a0:	5a7d                	li	s4,-1
    800047a2:	bfc1                	j	80004772 <filewrite+0xfa>
      return -1;
    800047a4:	5a7d                	li	s4,-1
    800047a6:	b7f1                	j	80004772 <filewrite+0xfa>
    800047a8:	5a7d                	li	s4,-1
    800047aa:	b7e1                	j	80004772 <filewrite+0xfa>

00000000800047ac <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047ac:	7179                	addi	sp,sp,-48
    800047ae:	f406                	sd	ra,40(sp)
    800047b0:	f022                	sd	s0,32(sp)
    800047b2:	ec26                	sd	s1,24(sp)
    800047b4:	e84a                	sd	s2,16(sp)
    800047b6:	e44e                	sd	s3,8(sp)
    800047b8:	e052                	sd	s4,0(sp)
    800047ba:	1800                	addi	s0,sp,48
    800047bc:	84aa                	mv	s1,a0
    800047be:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047c0:	0005b023          	sd	zero,0(a1)
    800047c4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	bf8080e7          	jalr	-1032(ra) # 800043c0 <filealloc>
    800047d0:	e088                	sd	a0,0(s1)
    800047d2:	c551                	beqz	a0,8000485e <pipealloc+0xb2>
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	bec080e7          	jalr	-1044(ra) # 800043c0 <filealloc>
    800047dc:	00aa3023          	sd	a0,0(s4)
    800047e0:	c92d                	beqz	a0,80004852 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	2fe080e7          	jalr	766(ra) # 80000ae0 <kalloc>
    800047ea:	892a                	mv	s2,a0
    800047ec:	c125                	beqz	a0,8000484c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047ee:	4985                	li	s3,1
    800047f0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047f4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800047f8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800047fc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004800:	00004597          	auipc	a1,0x4
    80004804:	ec858593          	addi	a1,a1,-312 # 800086c8 <syscalls+0x280>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	338080e7          	jalr	824(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004810:	609c                	ld	a5,0(s1)
    80004812:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004816:	609c                	ld	a5,0(s1)
    80004818:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000481c:	609c                	ld	a5,0(s1)
    8000481e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004822:	609c                	ld	a5,0(s1)
    80004824:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004828:	000a3783          	ld	a5,0(s4)
    8000482c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004830:	000a3783          	ld	a5,0(s4)
    80004834:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004838:	000a3783          	ld	a5,0(s4)
    8000483c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004840:	000a3783          	ld	a5,0(s4)
    80004844:	0127b823          	sd	s2,16(a5)
  return 0;
    80004848:	4501                	li	a0,0
    8000484a:	a025                	j	80004872 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000484c:	6088                	ld	a0,0(s1)
    8000484e:	e501                	bnez	a0,80004856 <pipealloc+0xaa>
    80004850:	a039                	j	8000485e <pipealloc+0xb2>
    80004852:	6088                	ld	a0,0(s1)
    80004854:	c51d                	beqz	a0,80004882 <pipealloc+0xd6>
    fileclose(*f0);
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	c26080e7          	jalr	-986(ra) # 8000447c <fileclose>
  if(*f1)
    8000485e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004862:	557d                	li	a0,-1
  if(*f1)
    80004864:	c799                	beqz	a5,80004872 <pipealloc+0xc6>
    fileclose(*f1);
    80004866:	853e                	mv	a0,a5
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	c14080e7          	jalr	-1004(ra) # 8000447c <fileclose>
  return -1;
    80004870:	557d                	li	a0,-1
}
    80004872:	70a2                	ld	ra,40(sp)
    80004874:	7402                	ld	s0,32(sp)
    80004876:	64e2                	ld	s1,24(sp)
    80004878:	6942                	ld	s2,16(sp)
    8000487a:	69a2                	ld	s3,8(sp)
    8000487c:	6a02                	ld	s4,0(sp)
    8000487e:	6145                	addi	sp,sp,48
    80004880:	8082                	ret
  return -1;
    80004882:	557d                	li	a0,-1
    80004884:	b7fd                	j	80004872 <pipealloc+0xc6>

0000000080004886 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004886:	1101                	addi	sp,sp,-32
    80004888:	ec06                	sd	ra,24(sp)
    8000488a:	e822                	sd	s0,16(sp)
    8000488c:	e426                	sd	s1,8(sp)
    8000488e:	e04a                	sd	s2,0(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
    80004894:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	33a080e7          	jalr	826(ra) # 80000bd0 <acquire>
  if(writable){
    8000489e:	02090d63          	beqz	s2,800048d8 <pipeclose+0x52>
    pi->writeopen = 0;
    800048a2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048a6:	21848513          	addi	a0,s1,536
    800048aa:	ffffe097          	auipc	ra,0xffffe
    800048ae:	93c080e7          	jalr	-1732(ra) # 800021e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048b2:	2204b783          	ld	a5,544(s1)
    800048b6:	eb95                	bnez	a5,800048ea <pipeclose+0x64>
    release(&pi->lock);
    800048b8:	8526                	mv	a0,s1
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	3ca080e7          	jalr	970(ra) # 80000c84 <release>
    kfree((char*)pi);
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	11e080e7          	jalr	286(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800048cc:	60e2                	ld	ra,24(sp)
    800048ce:	6442                	ld	s0,16(sp)
    800048d0:	64a2                	ld	s1,8(sp)
    800048d2:	6902                	ld	s2,0(sp)
    800048d4:	6105                	addi	sp,sp,32
    800048d6:	8082                	ret
    pi->readopen = 0;
    800048d8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048dc:	21c48513          	addi	a0,s1,540
    800048e0:	ffffe097          	auipc	ra,0xffffe
    800048e4:	906080e7          	jalr	-1786(ra) # 800021e6 <wakeup>
    800048e8:	b7e9                	j	800048b2 <pipeclose+0x2c>
    release(&pi->lock);
    800048ea:	8526                	mv	a0,s1
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	398080e7          	jalr	920(ra) # 80000c84 <release>
}
    800048f4:	bfe1                	j	800048cc <pipeclose+0x46>

00000000800048f6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800048f6:	711d                	addi	sp,sp,-96
    800048f8:	ec86                	sd	ra,88(sp)
    800048fa:	e8a2                	sd	s0,80(sp)
    800048fc:	e4a6                	sd	s1,72(sp)
    800048fe:	e0ca                	sd	s2,64(sp)
    80004900:	fc4e                	sd	s3,56(sp)
    80004902:	f852                	sd	s4,48(sp)
    80004904:	f456                	sd	s5,40(sp)
    80004906:	f05a                	sd	s6,32(sp)
    80004908:	ec5e                	sd	s7,24(sp)
    8000490a:	e862                	sd	s8,16(sp)
    8000490c:	1080                	addi	s0,sp,96
    8000490e:	84aa                	mv	s1,a0
    80004910:	8aae                	mv	s5,a1
    80004912:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004914:	ffffd097          	auipc	ra,0xffffd
    80004918:	082080e7          	jalr	130(ra) # 80001996 <myproc>
    8000491c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000491e:	8526                	mv	a0,s1
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	2b0080e7          	jalr	688(ra) # 80000bd0 <acquire>
  while(i < n){
    80004928:	0b405363          	blez	s4,800049ce <pipewrite+0xd8>
  int i = 0;
    8000492c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000492e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004930:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004934:	21c48b93          	addi	s7,s1,540
    80004938:	a089                	j	8000497a <pipewrite+0x84>
      release(&pi->lock);
    8000493a:	8526                	mv	a0,s1
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	348080e7          	jalr	840(ra) # 80000c84 <release>
      return -1;
    80004944:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004946:	854a                	mv	a0,s2
    80004948:	60e6                	ld	ra,88(sp)
    8000494a:	6446                	ld	s0,80(sp)
    8000494c:	64a6                	ld	s1,72(sp)
    8000494e:	6906                	ld	s2,64(sp)
    80004950:	79e2                	ld	s3,56(sp)
    80004952:	7a42                	ld	s4,48(sp)
    80004954:	7aa2                	ld	s5,40(sp)
    80004956:	7b02                	ld	s6,32(sp)
    80004958:	6be2                	ld	s7,24(sp)
    8000495a:	6c42                	ld	s8,16(sp)
    8000495c:	6125                	addi	sp,sp,96
    8000495e:	8082                	ret
      wakeup(&pi->nread);
    80004960:	8562                	mv	a0,s8
    80004962:	ffffe097          	auipc	ra,0xffffe
    80004966:	884080e7          	jalr	-1916(ra) # 800021e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000496a:	85a6                	mv	a1,s1
    8000496c:	855e                	mv	a0,s7
    8000496e:	ffffd097          	auipc	ra,0xffffd
    80004972:	6ec080e7          	jalr	1772(ra) # 8000205a <sleep>
  while(i < n){
    80004976:	05495d63          	bge	s2,s4,800049d0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000497a:	2204a783          	lw	a5,544(s1)
    8000497e:	dfd5                	beqz	a5,8000493a <pipewrite+0x44>
    80004980:	0289a783          	lw	a5,40(s3)
    80004984:	fbdd                	bnez	a5,8000493a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004986:	2184a783          	lw	a5,536(s1)
    8000498a:	21c4a703          	lw	a4,540(s1)
    8000498e:	2007879b          	addiw	a5,a5,512
    80004992:	fcf707e3          	beq	a4,a5,80004960 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004996:	4685                	li	a3,1
    80004998:	01590633          	add	a2,s2,s5
    8000499c:	faf40593          	addi	a1,s0,-81
    800049a0:	0509b503          	ld	a0,80(s3)
    800049a4:	ffffd097          	auipc	ra,0xffffd
    800049a8:	d42080e7          	jalr	-702(ra) # 800016e6 <copyin>
    800049ac:	03650263          	beq	a0,s6,800049d0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049b0:	21c4a783          	lw	a5,540(s1)
    800049b4:	0017871b          	addiw	a4,a5,1
    800049b8:	20e4ae23          	sw	a4,540(s1)
    800049bc:	1ff7f793          	andi	a5,a5,511
    800049c0:	97a6                	add	a5,a5,s1
    800049c2:	faf44703          	lbu	a4,-81(s0)
    800049c6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049ca:	2905                	addiw	s2,s2,1
    800049cc:	b76d                	j	80004976 <pipewrite+0x80>
  int i = 0;
    800049ce:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049d0:	21848513          	addi	a0,s1,536
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	812080e7          	jalr	-2030(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>
  return i;
    800049e6:	b785                	j	80004946 <pipewrite+0x50>

00000000800049e8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049e8:	715d                	addi	sp,sp,-80
    800049ea:	e486                	sd	ra,72(sp)
    800049ec:	e0a2                	sd	s0,64(sp)
    800049ee:	fc26                	sd	s1,56(sp)
    800049f0:	f84a                	sd	s2,48(sp)
    800049f2:	f44e                	sd	s3,40(sp)
    800049f4:	f052                	sd	s4,32(sp)
    800049f6:	ec56                	sd	s5,24(sp)
    800049f8:	e85a                	sd	s6,16(sp)
    800049fa:	0880                	addi	s0,sp,80
    800049fc:	84aa                	mv	s1,a0
    800049fe:	892e                	mv	s2,a1
    80004a00:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a02:	ffffd097          	auipc	ra,0xffffd
    80004a06:	f94080e7          	jalr	-108(ra) # 80001996 <myproc>
    80004a0a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	1c2080e7          	jalr	450(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a16:	2184a703          	lw	a4,536(s1)
    80004a1a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a1e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a22:	02f71463          	bne	a4,a5,80004a4a <piperead+0x62>
    80004a26:	2244a783          	lw	a5,548(s1)
    80004a2a:	c385                	beqz	a5,80004a4a <piperead+0x62>
    if(pr->killed){
    80004a2c:	028a2783          	lw	a5,40(s4)
    80004a30:	ebc9                	bnez	a5,80004ac2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a32:	85a6                	mv	a1,s1
    80004a34:	854e                	mv	a0,s3
    80004a36:	ffffd097          	auipc	ra,0xffffd
    80004a3a:	624080e7          	jalr	1572(ra) # 8000205a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a3e:	2184a703          	lw	a4,536(s1)
    80004a42:	21c4a783          	lw	a5,540(s1)
    80004a46:	fef700e3          	beq	a4,a5,80004a26 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a4c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a4e:	05505463          	blez	s5,80004a96 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004a52:	2184a783          	lw	a5,536(s1)
    80004a56:	21c4a703          	lw	a4,540(s1)
    80004a5a:	02f70e63          	beq	a4,a5,80004a96 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a5e:	0017871b          	addiw	a4,a5,1
    80004a62:	20e4ac23          	sw	a4,536(s1)
    80004a66:	1ff7f793          	andi	a5,a5,511
    80004a6a:	97a6                	add	a5,a5,s1
    80004a6c:	0187c783          	lbu	a5,24(a5)
    80004a70:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a74:	4685                	li	a3,1
    80004a76:	fbf40613          	addi	a2,s0,-65
    80004a7a:	85ca                	mv	a1,s2
    80004a7c:	050a3503          	ld	a0,80(s4)
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	bda080e7          	jalr	-1062(ra) # 8000165a <copyout>
    80004a88:	01650763          	beq	a0,s6,80004a96 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a8c:	2985                	addiw	s3,s3,1
    80004a8e:	0905                	addi	s2,s2,1
    80004a90:	fd3a91e3          	bne	s5,s3,80004a52 <piperead+0x6a>
    80004a94:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a96:	21c48513          	addi	a0,s1,540
    80004a9a:	ffffd097          	auipc	ra,0xffffd
    80004a9e:	74c080e7          	jalr	1868(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1e0080e7          	jalr	480(ra) # 80000c84 <release>
  return i;
}
    80004aac:	854e                	mv	a0,s3
    80004aae:	60a6                	ld	ra,72(sp)
    80004ab0:	6406                	ld	s0,64(sp)
    80004ab2:	74e2                	ld	s1,56(sp)
    80004ab4:	7942                	ld	s2,48(sp)
    80004ab6:	79a2                	ld	s3,40(sp)
    80004ab8:	7a02                	ld	s4,32(sp)
    80004aba:	6ae2                	ld	s5,24(sp)
    80004abc:	6b42                	ld	s6,16(sp)
    80004abe:	6161                	addi	sp,sp,80
    80004ac0:	8082                	ret
      release(&pi->lock);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	1c0080e7          	jalr	448(ra) # 80000c84 <release>
      return -1;
    80004acc:	59fd                	li	s3,-1
    80004ace:	bff9                	j	80004aac <piperead+0xc4>

0000000080004ad0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ad0:	de010113          	addi	sp,sp,-544
    80004ad4:	20113c23          	sd	ra,536(sp)
    80004ad8:	20813823          	sd	s0,528(sp)
    80004adc:	20913423          	sd	s1,520(sp)
    80004ae0:	21213023          	sd	s2,512(sp)
    80004ae4:	ffce                	sd	s3,504(sp)
    80004ae6:	fbd2                	sd	s4,496(sp)
    80004ae8:	f7d6                	sd	s5,488(sp)
    80004aea:	f3da                	sd	s6,480(sp)
    80004aec:	efde                	sd	s7,472(sp)
    80004aee:	ebe2                	sd	s8,464(sp)
    80004af0:	e7e6                	sd	s9,456(sp)
    80004af2:	e3ea                	sd	s10,448(sp)
    80004af4:	ff6e                	sd	s11,440(sp)
    80004af6:	1400                	addi	s0,sp,544
    80004af8:	892a                	mv	s2,a0
    80004afa:	dea43423          	sd	a0,-536(s0)
    80004afe:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	e94080e7          	jalr	-364(ra) # 80001996 <myproc>
    80004b0a:	84aa                	mv	s1,a0

  begin_op();
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	4a8080e7          	jalr	1192(ra) # 80003fb4 <begin_op>

  if((ip = namei(path)) == 0){
    80004b14:	854a                	mv	a0,s2
    80004b16:	fffff097          	auipc	ra,0xfffff
    80004b1a:	27e080e7          	jalr	638(ra) # 80003d94 <namei>
    80004b1e:	c93d                	beqz	a0,80004b94 <exec+0xc4>
    80004b20:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	ab6080e7          	jalr	-1354(ra) # 800035d8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b2a:	04000713          	li	a4,64
    80004b2e:	4681                	li	a3,0
    80004b30:	e5040613          	addi	a2,s0,-432
    80004b34:	4581                	li	a1,0
    80004b36:	8556                	mv	a0,s5
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	d54080e7          	jalr	-684(ra) # 8000388c <readi>
    80004b40:	04000793          	li	a5,64
    80004b44:	00f51a63          	bne	a0,a5,80004b58 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b48:	e5042703          	lw	a4,-432(s0)
    80004b4c:	464c47b7          	lui	a5,0x464c4
    80004b50:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b54:	04f70663          	beq	a4,a5,80004ba0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b58:	8556                	mv	a0,s5
    80004b5a:	fffff097          	auipc	ra,0xfffff
    80004b5e:	ce0080e7          	jalr	-800(ra) # 8000383a <iunlockput>
    end_op();
    80004b62:	fffff097          	auipc	ra,0xfffff
    80004b66:	4d0080e7          	jalr	1232(ra) # 80004032 <end_op>
  }
  return -1;
    80004b6a:	557d                	li	a0,-1
}
    80004b6c:	21813083          	ld	ra,536(sp)
    80004b70:	21013403          	ld	s0,528(sp)
    80004b74:	20813483          	ld	s1,520(sp)
    80004b78:	20013903          	ld	s2,512(sp)
    80004b7c:	79fe                	ld	s3,504(sp)
    80004b7e:	7a5e                	ld	s4,496(sp)
    80004b80:	7abe                	ld	s5,488(sp)
    80004b82:	7b1e                	ld	s6,480(sp)
    80004b84:	6bfe                	ld	s7,472(sp)
    80004b86:	6c5e                	ld	s8,464(sp)
    80004b88:	6cbe                	ld	s9,456(sp)
    80004b8a:	6d1e                	ld	s10,448(sp)
    80004b8c:	7dfa                	ld	s11,440(sp)
    80004b8e:	22010113          	addi	sp,sp,544
    80004b92:	8082                	ret
    end_op();
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	49e080e7          	jalr	1182(ra) # 80004032 <end_op>
    return -1;
    80004b9c:	557d                	li	a0,-1
    80004b9e:	b7f9                	j	80004b6c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	eb8080e7          	jalr	-328(ra) # 80001a5a <proc_pagetable>
    80004baa:	8b2a                	mv	s6,a0
    80004bac:	d555                	beqz	a0,80004b58 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bae:	e7042783          	lw	a5,-400(s0)
    80004bb2:	e8845703          	lhu	a4,-376(s0)
    80004bb6:	c735                	beqz	a4,80004c22 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004bb8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bba:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004bbe:	6a05                	lui	s4,0x1
    80004bc0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004bc4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004bc8:	6d85                	lui	s11,0x1
    80004bca:	7d7d                	lui	s10,0xfffff
    80004bcc:	ac1d                	j	80004e02 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bce:	00004517          	auipc	a0,0x4
    80004bd2:	b0250513          	addi	a0,a0,-1278 # 800086d0 <syscalls+0x288>
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	964080e7          	jalr	-1692(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bde:	874a                	mv	a4,s2
    80004be0:	009c86bb          	addw	a3,s9,s1
    80004be4:	4581                	li	a1,0
    80004be6:	8556                	mv	a0,s5
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	ca4080e7          	jalr	-860(ra) # 8000388c <readi>
    80004bf0:	2501                	sext.w	a0,a0
    80004bf2:	1aa91863          	bne	s2,a0,80004da2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004bf6:	009d84bb          	addw	s1,s11,s1
    80004bfa:	013d09bb          	addw	s3,s10,s3
    80004bfe:	1f74f263          	bgeu	s1,s7,80004de2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c02:	02049593          	slli	a1,s1,0x20
    80004c06:	9181                	srli	a1,a1,0x20
    80004c08:	95e2                	add	a1,a1,s8
    80004c0a:	855a                	mv	a0,s6
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	446080e7          	jalr	1094(ra) # 80001052 <walkaddr>
    80004c14:	862a                	mv	a2,a0
    if(pa == 0)
    80004c16:	dd45                	beqz	a0,80004bce <exec+0xfe>
      n = PGSIZE;
    80004c18:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c1a:	fd49f2e3          	bgeu	s3,s4,80004bde <exec+0x10e>
      n = sz - i;
    80004c1e:	894e                	mv	s2,s3
    80004c20:	bf7d                	j	80004bde <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c22:	4481                	li	s1,0
  iunlockput(ip);
    80004c24:	8556                	mv	a0,s5
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	c14080e7          	jalr	-1004(ra) # 8000383a <iunlockput>
  end_op();
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	404080e7          	jalr	1028(ra) # 80004032 <end_op>
  p = myproc();
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	d60080e7          	jalr	-672(ra) # 80001996 <myproc>
    80004c3e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c40:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c44:	6785                	lui	a5,0x1
    80004c46:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004c48:	97a6                	add	a5,a5,s1
    80004c4a:	777d                	lui	a4,0xfffff
    80004c4c:	8ff9                	and	a5,a5,a4
    80004c4e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c52:	6609                	lui	a2,0x2
    80004c54:	963e                	add	a2,a2,a5
    80004c56:	85be                	mv	a1,a5
    80004c58:	855a                	mv	a0,s6
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	7ac080e7          	jalr	1964(ra) # 80001406 <uvmalloc>
    80004c62:	8c2a                	mv	s8,a0
  ip = 0;
    80004c64:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c66:	12050e63          	beqz	a0,80004da2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c6a:	75f9                	lui	a1,0xffffe
    80004c6c:	95aa                	add	a1,a1,a0
    80004c6e:	855a                	mv	a0,s6
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	9b8080e7          	jalr	-1608(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c78:	7afd                	lui	s5,0xfffff
    80004c7a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c7c:	df043783          	ld	a5,-528(s0)
    80004c80:	6388                	ld	a0,0(a5)
    80004c82:	c925                	beqz	a0,80004cf2 <exec+0x222>
    80004c84:	e9040993          	addi	s3,s0,-368
    80004c88:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004c8c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c8e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	1b8080e7          	jalr	440(ra) # 80000e48 <strlen>
    80004c98:	0015079b          	addiw	a5,a0,1
    80004c9c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ca0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004ca4:	13596363          	bltu	s2,s5,80004dca <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ca8:	df043d83          	ld	s11,-528(s0)
    80004cac:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004cb0:	8552                	mv	a0,s4
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	196080e7          	jalr	406(ra) # 80000e48 <strlen>
    80004cba:	0015069b          	addiw	a3,a0,1
    80004cbe:	8652                	mv	a2,s4
    80004cc0:	85ca                	mv	a1,s2
    80004cc2:	855a                	mv	a0,s6
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	996080e7          	jalr	-1642(ra) # 8000165a <copyout>
    80004ccc:	10054363          	bltz	a0,80004dd2 <exec+0x302>
    ustack[argc] = sp;
    80004cd0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cd4:	0485                	addi	s1,s1,1
    80004cd6:	008d8793          	addi	a5,s11,8
    80004cda:	def43823          	sd	a5,-528(s0)
    80004cde:	008db503          	ld	a0,8(s11)
    80004ce2:	c911                	beqz	a0,80004cf6 <exec+0x226>
    if(argc >= MAXARG)
    80004ce4:	09a1                	addi	s3,s3,8
    80004ce6:	fb3c95e3          	bne	s9,s3,80004c90 <exec+0x1c0>
  sz = sz1;
    80004cea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004cee:	4a81                	li	s5,0
    80004cf0:	a84d                	j	80004da2 <exec+0x2d2>
  sp = sz;
    80004cf2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cf4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004cf6:	00349793          	slli	a5,s1,0x3
    80004cfa:	f9078793          	addi	a5,a5,-112
    80004cfe:	97a2                	add	a5,a5,s0
    80004d00:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d04:	00148693          	addi	a3,s1,1
    80004d08:	068e                	slli	a3,a3,0x3
    80004d0a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d0e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d12:	01597663          	bgeu	s2,s5,80004d1e <exec+0x24e>
  sz = sz1;
    80004d16:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d1a:	4a81                	li	s5,0
    80004d1c:	a059                	j	80004da2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d1e:	e9040613          	addi	a2,s0,-368
    80004d22:	85ca                	mv	a1,s2
    80004d24:	855a                	mv	a0,s6
    80004d26:	ffffd097          	auipc	ra,0xffffd
    80004d2a:	934080e7          	jalr	-1740(ra) # 8000165a <copyout>
    80004d2e:	0a054663          	bltz	a0,80004dda <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d32:	058bb783          	ld	a5,88(s7)
    80004d36:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d3a:	de843783          	ld	a5,-536(s0)
    80004d3e:	0007c703          	lbu	a4,0(a5)
    80004d42:	cf11                	beqz	a4,80004d5e <exec+0x28e>
    80004d44:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d46:	02f00693          	li	a3,47
    80004d4a:	a039                	j	80004d58 <exec+0x288>
      last = s+1;
    80004d4c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d50:	0785                	addi	a5,a5,1
    80004d52:	fff7c703          	lbu	a4,-1(a5)
    80004d56:	c701                	beqz	a4,80004d5e <exec+0x28e>
    if(*s == '/')
    80004d58:	fed71ce3          	bne	a4,a3,80004d50 <exec+0x280>
    80004d5c:	bfc5                	j	80004d4c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d5e:	4641                	li	a2,16
    80004d60:	de843583          	ld	a1,-536(s0)
    80004d64:	158b8513          	addi	a0,s7,344
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	0ae080e7          	jalr	174(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d70:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d74:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004d78:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d7c:	058bb783          	ld	a5,88(s7)
    80004d80:	e6843703          	ld	a4,-408(s0)
    80004d84:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d86:	058bb783          	ld	a5,88(s7)
    80004d8a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004d8e:	85ea                	mv	a1,s10
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	d66080e7          	jalr	-666(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004d98:	0004851b          	sext.w	a0,s1
    80004d9c:	bbc1                	j	80004b6c <exec+0x9c>
    80004d9e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004da2:	df843583          	ld	a1,-520(s0)
    80004da6:	855a                	mv	a0,s6
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	d4e080e7          	jalr	-690(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004db0:	da0a94e3          	bnez	s5,80004b58 <exec+0x88>
  return -1;
    80004db4:	557d                	li	a0,-1
    80004db6:	bb5d                	j	80004b6c <exec+0x9c>
    80004db8:	de943c23          	sd	s1,-520(s0)
    80004dbc:	b7dd                	j	80004da2 <exec+0x2d2>
    80004dbe:	de943c23          	sd	s1,-520(s0)
    80004dc2:	b7c5                	j	80004da2 <exec+0x2d2>
    80004dc4:	de943c23          	sd	s1,-520(s0)
    80004dc8:	bfe9                	j	80004da2 <exec+0x2d2>
  sz = sz1;
    80004dca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dce:	4a81                	li	s5,0
    80004dd0:	bfc9                	j	80004da2 <exec+0x2d2>
  sz = sz1;
    80004dd2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd6:	4a81                	li	s5,0
    80004dd8:	b7e9                	j	80004da2 <exec+0x2d2>
  sz = sz1;
    80004dda:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dde:	4a81                	li	s5,0
    80004de0:	b7c9                	j	80004da2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004de2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de6:	e0843783          	ld	a5,-504(s0)
    80004dea:	0017869b          	addiw	a3,a5,1
    80004dee:	e0d43423          	sd	a3,-504(s0)
    80004df2:	e0043783          	ld	a5,-512(s0)
    80004df6:	0387879b          	addiw	a5,a5,56
    80004dfa:	e8845703          	lhu	a4,-376(s0)
    80004dfe:	e2e6d3e3          	bge	a3,a4,80004c24 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e02:	2781                	sext.w	a5,a5
    80004e04:	e0f43023          	sd	a5,-512(s0)
    80004e08:	03800713          	li	a4,56
    80004e0c:	86be                	mv	a3,a5
    80004e0e:	e1840613          	addi	a2,s0,-488
    80004e12:	4581                	li	a1,0
    80004e14:	8556                	mv	a0,s5
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	a76080e7          	jalr	-1418(ra) # 8000388c <readi>
    80004e1e:	03800793          	li	a5,56
    80004e22:	f6f51ee3          	bne	a0,a5,80004d9e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e26:	e1842783          	lw	a5,-488(s0)
    80004e2a:	4705                	li	a4,1
    80004e2c:	fae79de3          	bne	a5,a4,80004de6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e30:	e4043603          	ld	a2,-448(s0)
    80004e34:	e3843783          	ld	a5,-456(s0)
    80004e38:	f8f660e3          	bltu	a2,a5,80004db8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e3c:	e2843783          	ld	a5,-472(s0)
    80004e40:	963e                	add	a2,a2,a5
    80004e42:	f6f66ee3          	bltu	a2,a5,80004dbe <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e46:	85a6                	mv	a1,s1
    80004e48:	855a                	mv	a0,s6
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	5bc080e7          	jalr	1468(ra) # 80001406 <uvmalloc>
    80004e52:	dea43c23          	sd	a0,-520(s0)
    80004e56:	d53d                	beqz	a0,80004dc4 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004e58:	e2843c03          	ld	s8,-472(s0)
    80004e5c:	de043783          	ld	a5,-544(s0)
    80004e60:	00fc77b3          	and	a5,s8,a5
    80004e64:	ff9d                	bnez	a5,80004da2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e66:	e2042c83          	lw	s9,-480(s0)
    80004e6a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e6e:	f60b8ae3          	beqz	s7,80004de2 <exec+0x312>
    80004e72:	89de                	mv	s3,s7
    80004e74:	4481                	li	s1,0
    80004e76:	b371                	j	80004c02 <exec+0x132>

0000000080004e78 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e78:	7179                	addi	sp,sp,-48
    80004e7a:	f406                	sd	ra,40(sp)
    80004e7c:	f022                	sd	s0,32(sp)
    80004e7e:	ec26                	sd	s1,24(sp)
    80004e80:	e84a                	sd	s2,16(sp)
    80004e82:	1800                	addi	s0,sp,48
    80004e84:	892e                	mv	s2,a1
    80004e86:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e88:	fdc40593          	addi	a1,s0,-36
    80004e8c:	ffffe097          	auipc	ra,0xffffe
    80004e90:	bc0080e7          	jalr	-1088(ra) # 80002a4c <argint>
    80004e94:	04054063          	bltz	a0,80004ed4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e98:	fdc42703          	lw	a4,-36(s0)
    80004e9c:	47bd                	li	a5,15
    80004e9e:	02e7ed63          	bltu	a5,a4,80004ed8 <argfd+0x60>
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	af4080e7          	jalr	-1292(ra) # 80001996 <myproc>
    80004eaa:	fdc42703          	lw	a4,-36(s0)
    80004eae:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004eb2:	078e                	slli	a5,a5,0x3
    80004eb4:	953e                	add	a0,a0,a5
    80004eb6:	611c                	ld	a5,0(a0)
    80004eb8:	c395                	beqz	a5,80004edc <argfd+0x64>
    return -1;
  if(pfd)
    80004eba:	00090463          	beqz	s2,80004ec2 <argfd+0x4a>
    *pfd = fd;
    80004ebe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ec2:	4501                	li	a0,0
  if(pf)
    80004ec4:	c091                	beqz	s1,80004ec8 <argfd+0x50>
    *pf = f;
    80004ec6:	e09c                	sd	a5,0(s1)
}
    80004ec8:	70a2                	ld	ra,40(sp)
    80004eca:	7402                	ld	s0,32(sp)
    80004ecc:	64e2                	ld	s1,24(sp)
    80004ece:	6942                	ld	s2,16(sp)
    80004ed0:	6145                	addi	sp,sp,48
    80004ed2:	8082                	ret
    return -1;
    80004ed4:	557d                	li	a0,-1
    80004ed6:	bfcd                	j	80004ec8 <argfd+0x50>
    return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	b7fd                	j	80004ec8 <argfd+0x50>
    80004edc:	557d                	li	a0,-1
    80004ede:	b7ed                	j	80004ec8 <argfd+0x50>

0000000080004ee0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ee0:	1101                	addi	sp,sp,-32
    80004ee2:	ec06                	sd	ra,24(sp)
    80004ee4:	e822                	sd	s0,16(sp)
    80004ee6:	e426                	sd	s1,8(sp)
    80004ee8:	1000                	addi	s0,sp,32
    80004eea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004eec:	ffffd097          	auipc	ra,0xffffd
    80004ef0:	aaa080e7          	jalr	-1366(ra) # 80001996 <myproc>
    80004ef4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ef6:	0d050793          	addi	a5,a0,208
    80004efa:	4501                	li	a0,0
    80004efc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004efe:	6398                	ld	a4,0(a5)
    80004f00:	cb19                	beqz	a4,80004f16 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f02:	2505                	addiw	a0,a0,1
    80004f04:	07a1                	addi	a5,a5,8
    80004f06:	fed51ce3          	bne	a0,a3,80004efe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f0a:	557d                	li	a0,-1
}
    80004f0c:	60e2                	ld	ra,24(sp)
    80004f0e:	6442                	ld	s0,16(sp)
    80004f10:	64a2                	ld	s1,8(sp)
    80004f12:	6105                	addi	sp,sp,32
    80004f14:	8082                	ret
      p->ofile[fd] = f;
    80004f16:	01a50793          	addi	a5,a0,26
    80004f1a:	078e                	slli	a5,a5,0x3
    80004f1c:	963e                	add	a2,a2,a5
    80004f1e:	e204                	sd	s1,0(a2)
      return fd;
    80004f20:	b7f5                	j	80004f0c <fdalloc+0x2c>

0000000080004f22 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f22:	715d                	addi	sp,sp,-80
    80004f24:	e486                	sd	ra,72(sp)
    80004f26:	e0a2                	sd	s0,64(sp)
    80004f28:	fc26                	sd	s1,56(sp)
    80004f2a:	f84a                	sd	s2,48(sp)
    80004f2c:	f44e                	sd	s3,40(sp)
    80004f2e:	f052                	sd	s4,32(sp)
    80004f30:	ec56                	sd	s5,24(sp)
    80004f32:	0880                	addi	s0,sp,80
    80004f34:	89ae                	mv	s3,a1
    80004f36:	8ab2                	mv	s5,a2
    80004f38:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f3a:	fb040593          	addi	a1,s0,-80
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	e74080e7          	jalr	-396(ra) # 80003db2 <nameiparent>
    80004f46:	892a                	mv	s2,a0
    80004f48:	12050e63          	beqz	a0,80005084 <create+0x162>
    return 0;

  ilock(dp);
    80004f4c:	ffffe097          	auipc	ra,0xffffe
    80004f50:	68c080e7          	jalr	1676(ra) # 800035d8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f54:	4601                	li	a2,0
    80004f56:	fb040593          	addi	a1,s0,-80
    80004f5a:	854a                	mv	a0,s2
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	b60080e7          	jalr	-1184(ra) # 80003abc <dirlookup>
    80004f64:	84aa                	mv	s1,a0
    80004f66:	c921                	beqz	a0,80004fb6 <create+0x94>
    iunlockput(dp);
    80004f68:	854a                	mv	a0,s2
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	8d0080e7          	jalr	-1840(ra) # 8000383a <iunlockput>
    ilock(ip);
    80004f72:	8526                	mv	a0,s1
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	664080e7          	jalr	1636(ra) # 800035d8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f7c:	2981                	sext.w	s3,s3
    80004f7e:	4789                	li	a5,2
    80004f80:	02f99463          	bne	s3,a5,80004fa8 <create+0x86>
    80004f84:	0444d783          	lhu	a5,68(s1)
    80004f88:	37f9                	addiw	a5,a5,-2
    80004f8a:	17c2                	slli	a5,a5,0x30
    80004f8c:	93c1                	srli	a5,a5,0x30
    80004f8e:	4705                	li	a4,1
    80004f90:	00f76c63          	bltu	a4,a5,80004fa8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f94:	8526                	mv	a0,s1
    80004f96:	60a6                	ld	ra,72(sp)
    80004f98:	6406                	ld	s0,64(sp)
    80004f9a:	74e2                	ld	s1,56(sp)
    80004f9c:	7942                	ld	s2,48(sp)
    80004f9e:	79a2                	ld	s3,40(sp)
    80004fa0:	7a02                	ld	s4,32(sp)
    80004fa2:	6ae2                	ld	s5,24(sp)
    80004fa4:	6161                	addi	sp,sp,80
    80004fa6:	8082                	ret
    iunlockput(ip);
    80004fa8:	8526                	mv	a0,s1
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	890080e7          	jalr	-1904(ra) # 8000383a <iunlockput>
    return 0;
    80004fb2:	4481                	li	s1,0
    80004fb4:	b7c5                	j	80004f94 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fb6:	85ce                	mv	a1,s3
    80004fb8:	00092503          	lw	a0,0(s2)
    80004fbc:	ffffe097          	auipc	ra,0xffffe
    80004fc0:	482080e7          	jalr	1154(ra) # 8000343e <ialloc>
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	c521                	beqz	a0,8000500e <create+0xec>
  ilock(ip);
    80004fc8:	ffffe097          	auipc	ra,0xffffe
    80004fcc:	610080e7          	jalr	1552(ra) # 800035d8 <ilock>
  ip->major = major;
    80004fd0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fd4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fd8:	4a05                	li	s4,1
    80004fda:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004fde:	8526                	mv	a0,s1
    80004fe0:	ffffe097          	auipc	ra,0xffffe
    80004fe4:	52c080e7          	jalr	1324(ra) # 8000350c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fe8:	2981                	sext.w	s3,s3
    80004fea:	03498a63          	beq	s3,s4,8000501e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80004fee:	40d0                	lw	a2,4(s1)
    80004ff0:	fb040593          	addi	a1,s0,-80
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	cdc080e7          	jalr	-804(ra) # 80003cd2 <dirlink>
    80004ffe:	06054b63          	bltz	a0,80005074 <create+0x152>
  iunlockput(dp);
    80005002:	854a                	mv	a0,s2
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	836080e7          	jalr	-1994(ra) # 8000383a <iunlockput>
  return ip;
    8000500c:	b761                	j	80004f94 <create+0x72>
    panic("create: ialloc");
    8000500e:	00003517          	auipc	a0,0x3
    80005012:	6e250513          	addi	a0,a0,1762 # 800086f0 <syscalls+0x2a8>
    80005016:	ffffb097          	auipc	ra,0xffffb
    8000501a:	524080e7          	jalr	1316(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000501e:	04a95783          	lhu	a5,74(s2)
    80005022:	2785                	addiw	a5,a5,1
    80005024:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005028:	854a                	mv	a0,s2
    8000502a:	ffffe097          	auipc	ra,0xffffe
    8000502e:	4e2080e7          	jalr	1250(ra) # 8000350c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005032:	40d0                	lw	a2,4(s1)
    80005034:	00003597          	auipc	a1,0x3
    80005038:	6cc58593          	addi	a1,a1,1740 # 80008700 <syscalls+0x2b8>
    8000503c:	8526                	mv	a0,s1
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	c94080e7          	jalr	-876(ra) # 80003cd2 <dirlink>
    80005046:	00054f63          	bltz	a0,80005064 <create+0x142>
    8000504a:	00492603          	lw	a2,4(s2)
    8000504e:	00003597          	auipc	a1,0x3
    80005052:	6ba58593          	addi	a1,a1,1722 # 80008708 <syscalls+0x2c0>
    80005056:	8526                	mv	a0,s1
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	c7a080e7          	jalr	-902(ra) # 80003cd2 <dirlink>
    80005060:	f80557e3          	bgez	a0,80004fee <create+0xcc>
      panic("create dots");
    80005064:	00003517          	auipc	a0,0x3
    80005068:	6ac50513          	addi	a0,a0,1708 # 80008710 <syscalls+0x2c8>
    8000506c:	ffffb097          	auipc	ra,0xffffb
    80005070:	4ce080e7          	jalr	1230(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005074:	00003517          	auipc	a0,0x3
    80005078:	6ac50513          	addi	a0,a0,1708 # 80008720 <syscalls+0x2d8>
    8000507c:	ffffb097          	auipc	ra,0xffffb
    80005080:	4be080e7          	jalr	1214(ra) # 8000053a <panic>
    return 0;
    80005084:	84aa                	mv	s1,a0
    80005086:	b739                	j	80004f94 <create+0x72>

0000000080005088 <sys_dup>:
{
    80005088:	7179                	addi	sp,sp,-48
    8000508a:	f406                	sd	ra,40(sp)
    8000508c:	f022                	sd	s0,32(sp)
    8000508e:	ec26                	sd	s1,24(sp)
    80005090:	e84a                	sd	s2,16(sp)
    80005092:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005094:	fd840613          	addi	a2,s0,-40
    80005098:	4581                	li	a1,0
    8000509a:	4501                	li	a0,0
    8000509c:	00000097          	auipc	ra,0x0
    800050a0:	ddc080e7          	jalr	-548(ra) # 80004e78 <argfd>
    return -1;
    800050a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050a6:	02054363          	bltz	a0,800050cc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050aa:	fd843903          	ld	s2,-40(s0)
    800050ae:	854a                	mv	a0,s2
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	e30080e7          	jalr	-464(ra) # 80004ee0 <fdalloc>
    800050b8:	84aa                	mv	s1,a0
    return -1;
    800050ba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050bc:	00054863          	bltz	a0,800050cc <sys_dup+0x44>
  filedup(f);
    800050c0:	854a                	mv	a0,s2
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	368080e7          	jalr	872(ra) # 8000442a <filedup>
  return fd;
    800050ca:	87a6                	mv	a5,s1
}
    800050cc:	853e                	mv	a0,a5
    800050ce:	70a2                	ld	ra,40(sp)
    800050d0:	7402                	ld	s0,32(sp)
    800050d2:	64e2                	ld	s1,24(sp)
    800050d4:	6942                	ld	s2,16(sp)
    800050d6:	6145                	addi	sp,sp,48
    800050d8:	8082                	ret

00000000800050da <sys_read>:
{
    800050da:	7179                	addi	sp,sp,-48
    800050dc:	f406                	sd	ra,40(sp)
    800050de:	f022                	sd	s0,32(sp)
    800050e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050e2:	fe840613          	addi	a2,s0,-24
    800050e6:	4581                	li	a1,0
    800050e8:	4501                	li	a0,0
    800050ea:	00000097          	auipc	ra,0x0
    800050ee:	d8e080e7          	jalr	-626(ra) # 80004e78 <argfd>
    return -1;
    800050f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050f4:	04054163          	bltz	a0,80005136 <sys_read+0x5c>
    800050f8:	fe440593          	addi	a1,s0,-28
    800050fc:	4509                	li	a0,2
    800050fe:	ffffe097          	auipc	ra,0xffffe
    80005102:	94e080e7          	jalr	-1714(ra) # 80002a4c <argint>
    return -1;
    80005106:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005108:	02054763          	bltz	a0,80005136 <sys_read+0x5c>
    8000510c:	fd840593          	addi	a1,s0,-40
    80005110:	4505                	li	a0,1
    80005112:	ffffe097          	auipc	ra,0xffffe
    80005116:	95c080e7          	jalr	-1700(ra) # 80002a6e <argaddr>
    return -1;
    8000511a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000511c:	00054d63          	bltz	a0,80005136 <sys_read+0x5c>
  return fileread(f, p, n);
    80005120:	fe442603          	lw	a2,-28(s0)
    80005124:	fd843583          	ld	a1,-40(s0)
    80005128:	fe843503          	ld	a0,-24(s0)
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	48a080e7          	jalr	1162(ra) # 800045b6 <fileread>
    80005134:	87aa                	mv	a5,a0
}
    80005136:	853e                	mv	a0,a5
    80005138:	70a2                	ld	ra,40(sp)
    8000513a:	7402                	ld	s0,32(sp)
    8000513c:	6145                	addi	sp,sp,48
    8000513e:	8082                	ret

0000000080005140 <sys_write>:
{
    80005140:	7179                	addi	sp,sp,-48
    80005142:	f406                	sd	ra,40(sp)
    80005144:	f022                	sd	s0,32(sp)
    80005146:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005148:	fe840613          	addi	a2,s0,-24
    8000514c:	4581                	li	a1,0
    8000514e:	4501                	li	a0,0
    80005150:	00000097          	auipc	ra,0x0
    80005154:	d28080e7          	jalr	-728(ra) # 80004e78 <argfd>
    return -1;
    80005158:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515a:	04054163          	bltz	a0,8000519c <sys_write+0x5c>
    8000515e:	fe440593          	addi	a1,s0,-28
    80005162:	4509                	li	a0,2
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	8e8080e7          	jalr	-1816(ra) # 80002a4c <argint>
    return -1;
    8000516c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000516e:	02054763          	bltz	a0,8000519c <sys_write+0x5c>
    80005172:	fd840593          	addi	a1,s0,-40
    80005176:	4505                	li	a0,1
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	8f6080e7          	jalr	-1802(ra) # 80002a6e <argaddr>
    return -1;
    80005180:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005182:	00054d63          	bltz	a0,8000519c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005186:	fe442603          	lw	a2,-28(s0)
    8000518a:	fd843583          	ld	a1,-40(s0)
    8000518e:	fe843503          	ld	a0,-24(s0)
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	4e6080e7          	jalr	1254(ra) # 80004678 <filewrite>
    8000519a:	87aa                	mv	a5,a0
}
    8000519c:	853e                	mv	a0,a5
    8000519e:	70a2                	ld	ra,40(sp)
    800051a0:	7402                	ld	s0,32(sp)
    800051a2:	6145                	addi	sp,sp,48
    800051a4:	8082                	ret

00000000800051a6 <sys_close>:
{
    800051a6:	1101                	addi	sp,sp,-32
    800051a8:	ec06                	sd	ra,24(sp)
    800051aa:	e822                	sd	s0,16(sp)
    800051ac:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051ae:	fe040613          	addi	a2,s0,-32
    800051b2:	fec40593          	addi	a1,s0,-20
    800051b6:	4501                	li	a0,0
    800051b8:	00000097          	auipc	ra,0x0
    800051bc:	cc0080e7          	jalr	-832(ra) # 80004e78 <argfd>
    return -1;
    800051c0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051c2:	02054463          	bltz	a0,800051ea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051c6:	ffffc097          	auipc	ra,0xffffc
    800051ca:	7d0080e7          	jalr	2000(ra) # 80001996 <myproc>
    800051ce:	fec42783          	lw	a5,-20(s0)
    800051d2:	07e9                	addi	a5,a5,26
    800051d4:	078e                	slli	a5,a5,0x3
    800051d6:	953e                	add	a0,a0,a5
    800051d8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800051dc:	fe043503          	ld	a0,-32(s0)
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	29c080e7          	jalr	668(ra) # 8000447c <fileclose>
  return 0;
    800051e8:	4781                	li	a5,0
}
    800051ea:	853e                	mv	a0,a5
    800051ec:	60e2                	ld	ra,24(sp)
    800051ee:	6442                	ld	s0,16(sp)
    800051f0:	6105                	addi	sp,sp,32
    800051f2:	8082                	ret

00000000800051f4 <sys_fstat>:
{
    800051f4:	1101                	addi	sp,sp,-32
    800051f6:	ec06                	sd	ra,24(sp)
    800051f8:	e822                	sd	s0,16(sp)
    800051fa:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051fc:	fe840613          	addi	a2,s0,-24
    80005200:	4581                	li	a1,0
    80005202:	4501                	li	a0,0
    80005204:	00000097          	auipc	ra,0x0
    80005208:	c74080e7          	jalr	-908(ra) # 80004e78 <argfd>
    return -1;
    8000520c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000520e:	02054563          	bltz	a0,80005238 <sys_fstat+0x44>
    80005212:	fe040593          	addi	a1,s0,-32
    80005216:	4505                	li	a0,1
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	856080e7          	jalr	-1962(ra) # 80002a6e <argaddr>
    return -1;
    80005220:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005222:	00054b63          	bltz	a0,80005238 <sys_fstat+0x44>
  return filestat(f, st);
    80005226:	fe043583          	ld	a1,-32(s0)
    8000522a:	fe843503          	ld	a0,-24(s0)
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	316080e7          	jalr	790(ra) # 80004544 <filestat>
    80005236:	87aa                	mv	a5,a0
}
    80005238:	853e                	mv	a0,a5
    8000523a:	60e2                	ld	ra,24(sp)
    8000523c:	6442                	ld	s0,16(sp)
    8000523e:	6105                	addi	sp,sp,32
    80005240:	8082                	ret

0000000080005242 <sys_link>:
{
    80005242:	7169                	addi	sp,sp,-304
    80005244:	f606                	sd	ra,296(sp)
    80005246:	f222                	sd	s0,288(sp)
    80005248:	ee26                	sd	s1,280(sp)
    8000524a:	ea4a                	sd	s2,272(sp)
    8000524c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000524e:	08000613          	li	a2,128
    80005252:	ed040593          	addi	a1,s0,-304
    80005256:	4501                	li	a0,0
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	838080e7          	jalr	-1992(ra) # 80002a90 <argstr>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005262:	10054e63          	bltz	a0,8000537e <sys_link+0x13c>
    80005266:	08000613          	li	a2,128
    8000526a:	f5040593          	addi	a1,s0,-176
    8000526e:	4505                	li	a0,1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	820080e7          	jalr	-2016(ra) # 80002a90 <argstr>
    return -1;
    80005278:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000527a:	10054263          	bltz	a0,8000537e <sys_link+0x13c>
  begin_op();
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	d36080e7          	jalr	-714(ra) # 80003fb4 <begin_op>
  if((ip = namei(old)) == 0){
    80005286:	ed040513          	addi	a0,s0,-304
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	b0a080e7          	jalr	-1270(ra) # 80003d94 <namei>
    80005292:	84aa                	mv	s1,a0
    80005294:	c551                	beqz	a0,80005320 <sys_link+0xde>
  ilock(ip);
    80005296:	ffffe097          	auipc	ra,0xffffe
    8000529a:	342080e7          	jalr	834(ra) # 800035d8 <ilock>
  if(ip->type == T_DIR){
    8000529e:	04449703          	lh	a4,68(s1)
    800052a2:	4785                	li	a5,1
    800052a4:	08f70463          	beq	a4,a5,8000532c <sys_link+0xea>
  ip->nlink++;
    800052a8:	04a4d783          	lhu	a5,74(s1)
    800052ac:	2785                	addiw	a5,a5,1
    800052ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052b2:	8526                	mv	a0,s1
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	258080e7          	jalr	600(ra) # 8000350c <iupdate>
  iunlock(ip);
    800052bc:	8526                	mv	a0,s1
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	3dc080e7          	jalr	988(ra) # 8000369a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052c6:	fd040593          	addi	a1,s0,-48
    800052ca:	f5040513          	addi	a0,s0,-176
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	ae4080e7          	jalr	-1308(ra) # 80003db2 <nameiparent>
    800052d6:	892a                	mv	s2,a0
    800052d8:	c935                	beqz	a0,8000534c <sys_link+0x10a>
  ilock(dp);
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	2fe080e7          	jalr	766(ra) # 800035d8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052e2:	00092703          	lw	a4,0(s2)
    800052e6:	409c                	lw	a5,0(s1)
    800052e8:	04f71d63          	bne	a4,a5,80005342 <sys_link+0x100>
    800052ec:	40d0                	lw	a2,4(s1)
    800052ee:	fd040593          	addi	a1,s0,-48
    800052f2:	854a                	mv	a0,s2
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	9de080e7          	jalr	-1570(ra) # 80003cd2 <dirlink>
    800052fc:	04054363          	bltz	a0,80005342 <sys_link+0x100>
  iunlockput(dp);
    80005300:	854a                	mv	a0,s2
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	538080e7          	jalr	1336(ra) # 8000383a <iunlockput>
  iput(ip);
    8000530a:	8526                	mv	a0,s1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	486080e7          	jalr	1158(ra) # 80003792 <iput>
  end_op();
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	d1e080e7          	jalr	-738(ra) # 80004032 <end_op>
  return 0;
    8000531c:	4781                	li	a5,0
    8000531e:	a085                	j	8000537e <sys_link+0x13c>
    end_op();
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	d12080e7          	jalr	-750(ra) # 80004032 <end_op>
    return -1;
    80005328:	57fd                	li	a5,-1
    8000532a:	a891                	j	8000537e <sys_link+0x13c>
    iunlockput(ip);
    8000532c:	8526                	mv	a0,s1
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	50c080e7          	jalr	1292(ra) # 8000383a <iunlockput>
    end_op();
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	cfc080e7          	jalr	-772(ra) # 80004032 <end_op>
    return -1;
    8000533e:	57fd                	li	a5,-1
    80005340:	a83d                	j	8000537e <sys_link+0x13c>
    iunlockput(dp);
    80005342:	854a                	mv	a0,s2
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	4f6080e7          	jalr	1270(ra) # 8000383a <iunlockput>
  ilock(ip);
    8000534c:	8526                	mv	a0,s1
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	28a080e7          	jalr	650(ra) # 800035d8 <ilock>
  ip->nlink--;
    80005356:	04a4d783          	lhu	a5,74(s1)
    8000535a:	37fd                	addiw	a5,a5,-1
    8000535c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	1aa080e7          	jalr	426(ra) # 8000350c <iupdate>
  iunlockput(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	4ce080e7          	jalr	1230(ra) # 8000383a <iunlockput>
  end_op();
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	cbe080e7          	jalr	-834(ra) # 80004032 <end_op>
  return -1;
    8000537c:	57fd                	li	a5,-1
}
    8000537e:	853e                	mv	a0,a5
    80005380:	70b2                	ld	ra,296(sp)
    80005382:	7412                	ld	s0,288(sp)
    80005384:	64f2                	ld	s1,280(sp)
    80005386:	6952                	ld	s2,272(sp)
    80005388:	6155                	addi	sp,sp,304
    8000538a:	8082                	ret

000000008000538c <sys_unlink>:
{
    8000538c:	7151                	addi	sp,sp,-240
    8000538e:	f586                	sd	ra,232(sp)
    80005390:	f1a2                	sd	s0,224(sp)
    80005392:	eda6                	sd	s1,216(sp)
    80005394:	e9ca                	sd	s2,208(sp)
    80005396:	e5ce                	sd	s3,200(sp)
    80005398:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000539a:	08000613          	li	a2,128
    8000539e:	f3040593          	addi	a1,s0,-208
    800053a2:	4501                	li	a0,0
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	6ec080e7          	jalr	1772(ra) # 80002a90 <argstr>
    800053ac:	18054163          	bltz	a0,8000552e <sys_unlink+0x1a2>
  begin_op();
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	c04080e7          	jalr	-1020(ra) # 80003fb4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053b8:	fb040593          	addi	a1,s0,-80
    800053bc:	f3040513          	addi	a0,s0,-208
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	9f2080e7          	jalr	-1550(ra) # 80003db2 <nameiparent>
    800053c8:	84aa                	mv	s1,a0
    800053ca:	c979                	beqz	a0,800054a0 <sys_unlink+0x114>
  ilock(dp);
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	20c080e7          	jalr	524(ra) # 800035d8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053d4:	00003597          	auipc	a1,0x3
    800053d8:	32c58593          	addi	a1,a1,812 # 80008700 <syscalls+0x2b8>
    800053dc:	fb040513          	addi	a0,s0,-80
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	6c2080e7          	jalr	1730(ra) # 80003aa2 <namecmp>
    800053e8:	14050a63          	beqz	a0,8000553c <sys_unlink+0x1b0>
    800053ec:	00003597          	auipc	a1,0x3
    800053f0:	31c58593          	addi	a1,a1,796 # 80008708 <syscalls+0x2c0>
    800053f4:	fb040513          	addi	a0,s0,-80
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	6aa080e7          	jalr	1706(ra) # 80003aa2 <namecmp>
    80005400:	12050e63          	beqz	a0,8000553c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005404:	f2c40613          	addi	a2,s0,-212
    80005408:	fb040593          	addi	a1,s0,-80
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	6ae080e7          	jalr	1710(ra) # 80003abc <dirlookup>
    80005416:	892a                	mv	s2,a0
    80005418:	12050263          	beqz	a0,8000553c <sys_unlink+0x1b0>
  ilock(ip);
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	1bc080e7          	jalr	444(ra) # 800035d8 <ilock>
  if(ip->nlink < 1)
    80005424:	04a91783          	lh	a5,74(s2)
    80005428:	08f05263          	blez	a5,800054ac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000542c:	04491703          	lh	a4,68(s2)
    80005430:	4785                	li	a5,1
    80005432:	08f70563          	beq	a4,a5,800054bc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005436:	4641                	li	a2,16
    80005438:	4581                	li	a1,0
    8000543a:	fc040513          	addi	a0,s0,-64
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	88e080e7          	jalr	-1906(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005446:	4741                	li	a4,16
    80005448:	f2c42683          	lw	a3,-212(s0)
    8000544c:	fc040613          	addi	a2,s0,-64
    80005450:	4581                	li	a1,0
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	530080e7          	jalr	1328(ra) # 80003984 <writei>
    8000545c:	47c1                	li	a5,16
    8000545e:	0af51563          	bne	a0,a5,80005508 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005462:	04491703          	lh	a4,68(s2)
    80005466:	4785                	li	a5,1
    80005468:	0af70863          	beq	a4,a5,80005518 <sys_unlink+0x18c>
  iunlockput(dp);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	3cc080e7          	jalr	972(ra) # 8000383a <iunlockput>
  ip->nlink--;
    80005476:	04a95783          	lhu	a5,74(s2)
    8000547a:	37fd                	addiw	a5,a5,-1
    8000547c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005480:	854a                	mv	a0,s2
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	08a080e7          	jalr	138(ra) # 8000350c <iupdate>
  iunlockput(ip);
    8000548a:	854a                	mv	a0,s2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	3ae080e7          	jalr	942(ra) # 8000383a <iunlockput>
  end_op();
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	b9e080e7          	jalr	-1122(ra) # 80004032 <end_op>
  return 0;
    8000549c:	4501                	li	a0,0
    8000549e:	a84d                	j	80005550 <sys_unlink+0x1c4>
    end_op();
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	b92080e7          	jalr	-1134(ra) # 80004032 <end_op>
    return -1;
    800054a8:	557d                	li	a0,-1
    800054aa:	a05d                	j	80005550 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ac:	00003517          	auipc	a0,0x3
    800054b0:	28450513          	addi	a0,a0,644 # 80008730 <syscalls+0x2e8>
    800054b4:	ffffb097          	auipc	ra,0xffffb
    800054b8:	086080e7          	jalr	134(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054bc:	04c92703          	lw	a4,76(s2)
    800054c0:	02000793          	li	a5,32
    800054c4:	f6e7f9e3          	bgeu	a5,a4,80005436 <sys_unlink+0xaa>
    800054c8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054cc:	4741                	li	a4,16
    800054ce:	86ce                	mv	a3,s3
    800054d0:	f1840613          	addi	a2,s0,-232
    800054d4:	4581                	li	a1,0
    800054d6:	854a                	mv	a0,s2
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	3b4080e7          	jalr	948(ra) # 8000388c <readi>
    800054e0:	47c1                	li	a5,16
    800054e2:	00f51b63          	bne	a0,a5,800054f8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054e6:	f1845783          	lhu	a5,-232(s0)
    800054ea:	e7a1                	bnez	a5,80005532 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ec:	29c1                	addiw	s3,s3,16
    800054ee:	04c92783          	lw	a5,76(s2)
    800054f2:	fcf9ede3          	bltu	s3,a5,800054cc <sys_unlink+0x140>
    800054f6:	b781                	j	80005436 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054f8:	00003517          	auipc	a0,0x3
    800054fc:	25050513          	addi	a0,a0,592 # 80008748 <syscalls+0x300>
    80005500:	ffffb097          	auipc	ra,0xffffb
    80005504:	03a080e7          	jalr	58(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005508:	00003517          	auipc	a0,0x3
    8000550c:	25850513          	addi	a0,a0,600 # 80008760 <syscalls+0x318>
    80005510:	ffffb097          	auipc	ra,0xffffb
    80005514:	02a080e7          	jalr	42(ra) # 8000053a <panic>
    dp->nlink--;
    80005518:	04a4d783          	lhu	a5,74(s1)
    8000551c:	37fd                	addiw	a5,a5,-1
    8000551e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	fe8080e7          	jalr	-24(ra) # 8000350c <iupdate>
    8000552c:	b781                	j	8000546c <sys_unlink+0xe0>
    return -1;
    8000552e:	557d                	li	a0,-1
    80005530:	a005                	j	80005550 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005532:	854a                	mv	a0,s2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	306080e7          	jalr	774(ra) # 8000383a <iunlockput>
  iunlockput(dp);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	2fc080e7          	jalr	764(ra) # 8000383a <iunlockput>
  end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	aec080e7          	jalr	-1300(ra) # 80004032 <end_op>
  return -1;
    8000554e:	557d                	li	a0,-1
}
    80005550:	70ae                	ld	ra,232(sp)
    80005552:	740e                	ld	s0,224(sp)
    80005554:	64ee                	ld	s1,216(sp)
    80005556:	694e                	ld	s2,208(sp)
    80005558:	69ae                	ld	s3,200(sp)
    8000555a:	616d                	addi	sp,sp,240
    8000555c:	8082                	ret

000000008000555e <sys_open>:

uint64
sys_open(void)
{
    8000555e:	7131                	addi	sp,sp,-192
    80005560:	fd06                	sd	ra,184(sp)
    80005562:	f922                	sd	s0,176(sp)
    80005564:	f526                	sd	s1,168(sp)
    80005566:	f14a                	sd	s2,160(sp)
    80005568:	ed4e                	sd	s3,152(sp)
    8000556a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000556c:	08000613          	li	a2,128
    80005570:	f5040593          	addi	a1,s0,-176
    80005574:	4501                	li	a0,0
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	51a080e7          	jalr	1306(ra) # 80002a90 <argstr>
    return -1;
    8000557e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005580:	0c054163          	bltz	a0,80005642 <sys_open+0xe4>
    80005584:	f4c40593          	addi	a1,s0,-180
    80005588:	4505                	li	a0,1
    8000558a:	ffffd097          	auipc	ra,0xffffd
    8000558e:	4c2080e7          	jalr	1218(ra) # 80002a4c <argint>
    80005592:	0a054863          	bltz	a0,80005642 <sys_open+0xe4>

  begin_op();
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	a1e080e7          	jalr	-1506(ra) # 80003fb4 <begin_op>

  if(omode & O_CREATE){
    8000559e:	f4c42783          	lw	a5,-180(s0)
    800055a2:	2007f793          	andi	a5,a5,512
    800055a6:	cbdd                	beqz	a5,8000565c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055a8:	4681                	li	a3,0
    800055aa:	4601                	li	a2,0
    800055ac:	4589                	li	a1,2
    800055ae:	f5040513          	addi	a0,s0,-176
    800055b2:	00000097          	auipc	ra,0x0
    800055b6:	970080e7          	jalr	-1680(ra) # 80004f22 <create>
    800055ba:	892a                	mv	s2,a0
    if(ip == 0){
    800055bc:	c959                	beqz	a0,80005652 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055be:	04491703          	lh	a4,68(s2)
    800055c2:	478d                	li	a5,3
    800055c4:	00f71763          	bne	a4,a5,800055d2 <sys_open+0x74>
    800055c8:	04695703          	lhu	a4,70(s2)
    800055cc:	47a5                	li	a5,9
    800055ce:	0ce7ec63          	bltu	a5,a4,800056a6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	dee080e7          	jalr	-530(ra) # 800043c0 <filealloc>
    800055da:	89aa                	mv	s3,a0
    800055dc:	10050263          	beqz	a0,800056e0 <sys_open+0x182>
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	900080e7          	jalr	-1792(ra) # 80004ee0 <fdalloc>
    800055e8:	84aa                	mv	s1,a0
    800055ea:	0e054663          	bltz	a0,800056d6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055ee:	04491703          	lh	a4,68(s2)
    800055f2:	478d                	li	a5,3
    800055f4:	0cf70463          	beq	a4,a5,800056bc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055f8:	4789                	li	a5,2
    800055fa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055fe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005602:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005606:	f4c42783          	lw	a5,-180(s0)
    8000560a:	0017c713          	xori	a4,a5,1
    8000560e:	8b05                	andi	a4,a4,1
    80005610:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005614:	0037f713          	andi	a4,a5,3
    80005618:	00e03733          	snez	a4,a4
    8000561c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005620:	4007f793          	andi	a5,a5,1024
    80005624:	c791                	beqz	a5,80005630 <sys_open+0xd2>
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	4789                	li	a5,2
    8000562c:	08f70f63          	beq	a4,a5,800056ca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	068080e7          	jalr	104(ra) # 8000369a <iunlock>
  end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	9f8080e7          	jalr	-1544(ra) # 80004032 <end_op>

  return fd;
}
    80005642:	8526                	mv	a0,s1
    80005644:	70ea                	ld	ra,184(sp)
    80005646:	744a                	ld	s0,176(sp)
    80005648:	74aa                	ld	s1,168(sp)
    8000564a:	790a                	ld	s2,160(sp)
    8000564c:	69ea                	ld	s3,152(sp)
    8000564e:	6129                	addi	sp,sp,192
    80005650:	8082                	ret
      end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	9e0080e7          	jalr	-1568(ra) # 80004032 <end_op>
      return -1;
    8000565a:	b7e5                	j	80005642 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000565c:	f5040513          	addi	a0,s0,-176
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	734080e7          	jalr	1844(ra) # 80003d94 <namei>
    80005668:	892a                	mv	s2,a0
    8000566a:	c905                	beqz	a0,8000569a <sys_open+0x13c>
    ilock(ip);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	f6c080e7          	jalr	-148(ra) # 800035d8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005674:	04491703          	lh	a4,68(s2)
    80005678:	4785                	li	a5,1
    8000567a:	f4f712e3          	bne	a4,a5,800055be <sys_open+0x60>
    8000567e:	f4c42783          	lw	a5,-180(s0)
    80005682:	dba1                	beqz	a5,800055d2 <sys_open+0x74>
      iunlockput(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	1b4080e7          	jalr	436(ra) # 8000383a <iunlockput>
      end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	9a4080e7          	jalr	-1628(ra) # 80004032 <end_op>
      return -1;
    80005696:	54fd                	li	s1,-1
    80005698:	b76d                	j	80005642 <sys_open+0xe4>
      end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	998080e7          	jalr	-1640(ra) # 80004032 <end_op>
      return -1;
    800056a2:	54fd                	li	s1,-1
    800056a4:	bf79                	j	80005642 <sys_open+0xe4>
    iunlockput(ip);
    800056a6:	854a                	mv	a0,s2
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	192080e7          	jalr	402(ra) # 8000383a <iunlockput>
    end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	982080e7          	jalr	-1662(ra) # 80004032 <end_op>
    return -1;
    800056b8:	54fd                	li	s1,-1
    800056ba:	b761                	j	80005642 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056bc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056c0:	04691783          	lh	a5,70(s2)
    800056c4:	02f99223          	sh	a5,36(s3)
    800056c8:	bf2d                	j	80005602 <sys_open+0xa4>
    itrunc(ip);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	01a080e7          	jalr	26(ra) # 800036e6 <itrunc>
    800056d4:	bfb1                	j	80005630 <sys_open+0xd2>
      fileclose(f);
    800056d6:	854e                	mv	a0,s3
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	da4080e7          	jalr	-604(ra) # 8000447c <fileclose>
    iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	158080e7          	jalr	344(ra) # 8000383a <iunlockput>
    end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	948080e7          	jalr	-1720(ra) # 80004032 <end_op>
    return -1;
    800056f2:	54fd                	li	s1,-1
    800056f4:	b7b9                	j	80005642 <sys_open+0xe4>

00000000800056f6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056f6:	7175                	addi	sp,sp,-144
    800056f8:	e506                	sd	ra,136(sp)
    800056fa:	e122                	sd	s0,128(sp)
    800056fc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	8b6080e7          	jalr	-1866(ra) # 80003fb4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005706:	08000613          	li	a2,128
    8000570a:	f7040593          	addi	a1,s0,-144
    8000570e:	4501                	li	a0,0
    80005710:	ffffd097          	auipc	ra,0xffffd
    80005714:	380080e7          	jalr	896(ra) # 80002a90 <argstr>
    80005718:	02054963          	bltz	a0,8000574a <sys_mkdir+0x54>
    8000571c:	4681                	li	a3,0
    8000571e:	4601                	li	a2,0
    80005720:	4585                	li	a1,1
    80005722:	f7040513          	addi	a0,s0,-144
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	7fc080e7          	jalr	2044(ra) # 80004f22 <create>
    8000572e:	cd11                	beqz	a0,8000574a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	10a080e7          	jalr	266(ra) # 8000383a <iunlockput>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	8fa080e7          	jalr	-1798(ra) # 80004032 <end_op>
  return 0;
    80005740:	4501                	li	a0,0
}
    80005742:	60aa                	ld	ra,136(sp)
    80005744:	640a                	ld	s0,128(sp)
    80005746:	6149                	addi	sp,sp,144
    80005748:	8082                	ret
    end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	8e8080e7          	jalr	-1816(ra) # 80004032 <end_op>
    return -1;
    80005752:	557d                	li	a0,-1
    80005754:	b7fd                	j	80005742 <sys_mkdir+0x4c>

0000000080005756 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005756:	7135                	addi	sp,sp,-160
    80005758:	ed06                	sd	ra,152(sp)
    8000575a:	e922                	sd	s0,144(sp)
    8000575c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	856080e7          	jalr	-1962(ra) # 80003fb4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005766:	08000613          	li	a2,128
    8000576a:	f7040593          	addi	a1,s0,-144
    8000576e:	4501                	li	a0,0
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	320080e7          	jalr	800(ra) # 80002a90 <argstr>
    80005778:	04054a63          	bltz	a0,800057cc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000577c:	f6c40593          	addi	a1,s0,-148
    80005780:	4505                	li	a0,1
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	2ca080e7          	jalr	714(ra) # 80002a4c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000578a:	04054163          	bltz	a0,800057cc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000578e:	f6840593          	addi	a1,s0,-152
    80005792:	4509                	li	a0,2
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	2b8080e7          	jalr	696(ra) # 80002a4c <argint>
     argint(1, &major) < 0 ||
    8000579c:	02054863          	bltz	a0,800057cc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057a0:	f6841683          	lh	a3,-152(s0)
    800057a4:	f6c41603          	lh	a2,-148(s0)
    800057a8:	458d                	li	a1,3
    800057aa:	f7040513          	addi	a0,s0,-144
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	774080e7          	jalr	1908(ra) # 80004f22 <create>
     argint(2, &minor) < 0 ||
    800057b6:	c919                	beqz	a0,800057cc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	082080e7          	jalr	130(ra) # 8000383a <iunlockput>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	872080e7          	jalr	-1934(ra) # 80004032 <end_op>
  return 0;
    800057c8:	4501                	li	a0,0
    800057ca:	a031                	j	800057d6 <sys_mknod+0x80>
    end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	866080e7          	jalr	-1946(ra) # 80004032 <end_op>
    return -1;
    800057d4:	557d                	li	a0,-1
}
    800057d6:	60ea                	ld	ra,152(sp)
    800057d8:	644a                	ld	s0,144(sp)
    800057da:	610d                	addi	sp,sp,160
    800057dc:	8082                	ret

00000000800057de <sys_chdir>:

uint64
sys_chdir(void)
{
    800057de:	7135                	addi	sp,sp,-160
    800057e0:	ed06                	sd	ra,152(sp)
    800057e2:	e922                	sd	s0,144(sp)
    800057e4:	e526                	sd	s1,136(sp)
    800057e6:	e14a                	sd	s2,128(sp)
    800057e8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057ea:	ffffc097          	auipc	ra,0xffffc
    800057ee:	1ac080e7          	jalr	428(ra) # 80001996 <myproc>
    800057f2:	892a                	mv	s2,a0
  
  begin_op();
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	7c0080e7          	jalr	1984(ra) # 80003fb4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057fc:	08000613          	li	a2,128
    80005800:	f6040593          	addi	a1,s0,-160
    80005804:	4501                	li	a0,0
    80005806:	ffffd097          	auipc	ra,0xffffd
    8000580a:	28a080e7          	jalr	650(ra) # 80002a90 <argstr>
    8000580e:	04054b63          	bltz	a0,80005864 <sys_chdir+0x86>
    80005812:	f6040513          	addi	a0,s0,-160
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	57e080e7          	jalr	1406(ra) # 80003d94 <namei>
    8000581e:	84aa                	mv	s1,a0
    80005820:	c131                	beqz	a0,80005864 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	db6080e7          	jalr	-586(ra) # 800035d8 <ilock>
  if(ip->type != T_DIR){
    8000582a:	04449703          	lh	a4,68(s1)
    8000582e:	4785                	li	a5,1
    80005830:	04f71063          	bne	a4,a5,80005870 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	e64080e7          	jalr	-412(ra) # 8000369a <iunlock>
  iput(p->cwd);
    8000583e:	15093503          	ld	a0,336(s2)
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	f50080e7          	jalr	-176(ra) # 80003792 <iput>
  end_op();
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	7e8080e7          	jalr	2024(ra) # 80004032 <end_op>
  p->cwd = ip;
    80005852:	14993823          	sd	s1,336(s2)
  return 0;
    80005856:	4501                	li	a0,0
}
    80005858:	60ea                	ld	ra,152(sp)
    8000585a:	644a                	ld	s0,144(sp)
    8000585c:	64aa                	ld	s1,136(sp)
    8000585e:	690a                	ld	s2,128(sp)
    80005860:	610d                	addi	sp,sp,160
    80005862:	8082                	ret
    end_op();
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	7ce080e7          	jalr	1998(ra) # 80004032 <end_op>
    return -1;
    8000586c:	557d                	li	a0,-1
    8000586e:	b7ed                	j	80005858 <sys_chdir+0x7a>
    iunlockput(ip);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	fc8080e7          	jalr	-56(ra) # 8000383a <iunlockput>
    end_op();
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	7b8080e7          	jalr	1976(ra) # 80004032 <end_op>
    return -1;
    80005882:	557d                	li	a0,-1
    80005884:	bfd1                	j	80005858 <sys_chdir+0x7a>

0000000080005886 <sys_exec>:

uint64
sys_exec(void)
{
    80005886:	7145                	addi	sp,sp,-464
    80005888:	e786                	sd	ra,456(sp)
    8000588a:	e3a2                	sd	s0,448(sp)
    8000588c:	ff26                	sd	s1,440(sp)
    8000588e:	fb4a                	sd	s2,432(sp)
    80005890:	f74e                	sd	s3,424(sp)
    80005892:	f352                	sd	s4,416(sp)
    80005894:	ef56                	sd	s5,408(sp)
    80005896:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005898:	08000613          	li	a2,128
    8000589c:	f4040593          	addi	a1,s0,-192
    800058a0:	4501                	li	a0,0
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	1ee080e7          	jalr	494(ra) # 80002a90 <argstr>
    return -1;
    800058aa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058ac:	0c054b63          	bltz	a0,80005982 <sys_exec+0xfc>
    800058b0:	e3840593          	addi	a1,s0,-456
    800058b4:	4505                	li	a0,1
    800058b6:	ffffd097          	auipc	ra,0xffffd
    800058ba:	1b8080e7          	jalr	440(ra) # 80002a6e <argaddr>
    800058be:	0c054263          	bltz	a0,80005982 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800058c2:	10000613          	li	a2,256
    800058c6:	4581                	li	a1,0
    800058c8:	e4040513          	addi	a0,s0,-448
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	400080e7          	jalr	1024(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058d4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058d8:	89a6                	mv	s3,s1
    800058da:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058dc:	02000a13          	li	s4,32
    800058e0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058e4:	00391513          	slli	a0,s2,0x3
    800058e8:	e3040593          	addi	a1,s0,-464
    800058ec:	e3843783          	ld	a5,-456(s0)
    800058f0:	953e                	add	a0,a0,a5
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	0c0080e7          	jalr	192(ra) # 800029b2 <fetchaddr>
    800058fa:	02054a63          	bltz	a0,8000592e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800058fe:	e3043783          	ld	a5,-464(s0)
    80005902:	c3b9                	beqz	a5,80005948 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	1dc080e7          	jalr	476(ra) # 80000ae0 <kalloc>
    8000590c:	85aa                	mv	a1,a0
    8000590e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005912:	cd11                	beqz	a0,8000592e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005914:	6605                	lui	a2,0x1
    80005916:	e3043503          	ld	a0,-464(s0)
    8000591a:	ffffd097          	auipc	ra,0xffffd
    8000591e:	0ea080e7          	jalr	234(ra) # 80002a04 <fetchstr>
    80005922:	00054663          	bltz	a0,8000592e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005926:	0905                	addi	s2,s2,1
    80005928:	09a1                	addi	s3,s3,8
    8000592a:	fb491be3          	bne	s2,s4,800058e0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000592e:	f4040913          	addi	s2,s0,-192
    80005932:	6088                	ld	a0,0(s1)
    80005934:	c531                	beqz	a0,80005980 <sys_exec+0xfa>
    kfree(argv[i]);
    80005936:	ffffb097          	auipc	ra,0xffffb
    8000593a:	0ac080e7          	jalr	172(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593e:	04a1                	addi	s1,s1,8
    80005940:	ff2499e3          	bne	s1,s2,80005932 <sys_exec+0xac>
  return -1;
    80005944:	597d                	li	s2,-1
    80005946:	a835                	j	80005982 <sys_exec+0xfc>
      argv[i] = 0;
    80005948:	0a8e                	slli	s5,s5,0x3
    8000594a:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    8000594e:	00878ab3          	add	s5,a5,s0
    80005952:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005956:	e4040593          	addi	a1,s0,-448
    8000595a:	f4040513          	addi	a0,s0,-192
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	172080e7          	jalr	370(ra) # 80004ad0 <exec>
    80005966:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005968:	f4040993          	addi	s3,s0,-192
    8000596c:	6088                	ld	a0,0(s1)
    8000596e:	c911                	beqz	a0,80005982 <sys_exec+0xfc>
    kfree(argv[i]);
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	072080e7          	jalr	114(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005978:	04a1                	addi	s1,s1,8
    8000597a:	ff3499e3          	bne	s1,s3,8000596c <sys_exec+0xe6>
    8000597e:	a011                	j	80005982 <sys_exec+0xfc>
  return -1;
    80005980:	597d                	li	s2,-1
}
    80005982:	854a                	mv	a0,s2
    80005984:	60be                	ld	ra,456(sp)
    80005986:	641e                	ld	s0,448(sp)
    80005988:	74fa                	ld	s1,440(sp)
    8000598a:	795a                	ld	s2,432(sp)
    8000598c:	79ba                	ld	s3,424(sp)
    8000598e:	7a1a                	ld	s4,416(sp)
    80005990:	6afa                	ld	s5,408(sp)
    80005992:	6179                	addi	sp,sp,464
    80005994:	8082                	ret

0000000080005996 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005996:	7139                	addi	sp,sp,-64
    80005998:	fc06                	sd	ra,56(sp)
    8000599a:	f822                	sd	s0,48(sp)
    8000599c:	f426                	sd	s1,40(sp)
    8000599e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059a0:	ffffc097          	auipc	ra,0xffffc
    800059a4:	ff6080e7          	jalr	-10(ra) # 80001996 <myproc>
    800059a8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059aa:	fd840593          	addi	a1,s0,-40
    800059ae:	4501                	li	a0,0
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	0be080e7          	jalr	190(ra) # 80002a6e <argaddr>
    return -1;
    800059b8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059ba:	0e054063          	bltz	a0,80005a9a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059be:	fc840593          	addi	a1,s0,-56
    800059c2:	fd040513          	addi	a0,s0,-48
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	de6080e7          	jalr	-538(ra) # 800047ac <pipealloc>
    return -1;
    800059ce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059d0:	0c054563          	bltz	a0,80005a9a <sys_pipe+0x104>
  fd0 = -1;
    800059d4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059d8:	fd043503          	ld	a0,-48(s0)
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	504080e7          	jalr	1284(ra) # 80004ee0 <fdalloc>
    800059e4:	fca42223          	sw	a0,-60(s0)
    800059e8:	08054c63          	bltz	a0,80005a80 <sys_pipe+0xea>
    800059ec:	fc843503          	ld	a0,-56(s0)
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	4f0080e7          	jalr	1264(ra) # 80004ee0 <fdalloc>
    800059f8:	fca42023          	sw	a0,-64(s0)
    800059fc:	06054963          	bltz	a0,80005a6e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a00:	4691                	li	a3,4
    80005a02:	fc440613          	addi	a2,s0,-60
    80005a06:	fd843583          	ld	a1,-40(s0)
    80005a0a:	68a8                	ld	a0,80(s1)
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	c4e080e7          	jalr	-946(ra) # 8000165a <copyout>
    80005a14:	02054063          	bltz	a0,80005a34 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a18:	4691                	li	a3,4
    80005a1a:	fc040613          	addi	a2,s0,-64
    80005a1e:	fd843583          	ld	a1,-40(s0)
    80005a22:	0591                	addi	a1,a1,4
    80005a24:	68a8                	ld	a0,80(s1)
    80005a26:	ffffc097          	auipc	ra,0xffffc
    80005a2a:	c34080e7          	jalr	-972(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a2e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a30:	06055563          	bgez	a0,80005a9a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a34:	fc442783          	lw	a5,-60(s0)
    80005a38:	07e9                	addi	a5,a5,26
    80005a3a:	078e                	slli	a5,a5,0x3
    80005a3c:	97a6                	add	a5,a5,s1
    80005a3e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a42:	fc042783          	lw	a5,-64(s0)
    80005a46:	07e9                	addi	a5,a5,26
    80005a48:	078e                	slli	a5,a5,0x3
    80005a4a:	00f48533          	add	a0,s1,a5
    80005a4e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a52:	fd043503          	ld	a0,-48(s0)
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	a26080e7          	jalr	-1498(ra) # 8000447c <fileclose>
    fileclose(wf);
    80005a5e:	fc843503          	ld	a0,-56(s0)
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	a1a080e7          	jalr	-1510(ra) # 8000447c <fileclose>
    return -1;
    80005a6a:	57fd                	li	a5,-1
    80005a6c:	a03d                	j	80005a9a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a6e:	fc442783          	lw	a5,-60(s0)
    80005a72:	0007c763          	bltz	a5,80005a80 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a76:	07e9                	addi	a5,a5,26
    80005a78:	078e                	slli	a5,a5,0x3
    80005a7a:	97a6                	add	a5,a5,s1
    80005a7c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005a80:	fd043503          	ld	a0,-48(s0)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	9f8080e7          	jalr	-1544(ra) # 8000447c <fileclose>
    fileclose(wf);
    80005a8c:	fc843503          	ld	a0,-56(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	9ec080e7          	jalr	-1556(ra) # 8000447c <fileclose>
    return -1;
    80005a98:	57fd                	li	a5,-1
}
    80005a9a:	853e                	mv	a0,a5
    80005a9c:	70e2                	ld	ra,56(sp)
    80005a9e:	7442                	ld	s0,48(sp)
    80005aa0:	74a2                	ld	s1,40(sp)
    80005aa2:	6121                	addi	sp,sp,64
    80005aa4:	8082                	ret
	...

0000000080005ab0 <kernelvec>:
    80005ab0:	7111                	addi	sp,sp,-256
    80005ab2:	e006                	sd	ra,0(sp)
    80005ab4:	e40a                	sd	sp,8(sp)
    80005ab6:	e80e                	sd	gp,16(sp)
    80005ab8:	ec12                	sd	tp,24(sp)
    80005aba:	f016                	sd	t0,32(sp)
    80005abc:	f41a                	sd	t1,40(sp)
    80005abe:	f81e                	sd	t2,48(sp)
    80005ac0:	fc22                	sd	s0,56(sp)
    80005ac2:	e0a6                	sd	s1,64(sp)
    80005ac4:	e4aa                	sd	a0,72(sp)
    80005ac6:	e8ae                	sd	a1,80(sp)
    80005ac8:	ecb2                	sd	a2,88(sp)
    80005aca:	f0b6                	sd	a3,96(sp)
    80005acc:	f4ba                	sd	a4,104(sp)
    80005ace:	f8be                	sd	a5,112(sp)
    80005ad0:	fcc2                	sd	a6,120(sp)
    80005ad2:	e146                	sd	a7,128(sp)
    80005ad4:	e54a                	sd	s2,136(sp)
    80005ad6:	e94e                	sd	s3,144(sp)
    80005ad8:	ed52                	sd	s4,152(sp)
    80005ada:	f156                	sd	s5,160(sp)
    80005adc:	f55a                	sd	s6,168(sp)
    80005ade:	f95e                	sd	s7,176(sp)
    80005ae0:	fd62                	sd	s8,184(sp)
    80005ae2:	e1e6                	sd	s9,192(sp)
    80005ae4:	e5ea                	sd	s10,200(sp)
    80005ae6:	e9ee                	sd	s11,208(sp)
    80005ae8:	edf2                	sd	t3,216(sp)
    80005aea:	f1f6                	sd	t4,224(sp)
    80005aec:	f5fa                	sd	t5,232(sp)
    80005aee:	f9fe                	sd	t6,240(sp)
    80005af0:	d8ffc0ef          	jal	ra,8000287e <kerneltrap>
    80005af4:	6082                	ld	ra,0(sp)
    80005af6:	6122                	ld	sp,8(sp)
    80005af8:	61c2                	ld	gp,16(sp)
    80005afa:	7282                	ld	t0,32(sp)
    80005afc:	7322                	ld	t1,40(sp)
    80005afe:	73c2                	ld	t2,48(sp)
    80005b00:	7462                	ld	s0,56(sp)
    80005b02:	6486                	ld	s1,64(sp)
    80005b04:	6526                	ld	a0,72(sp)
    80005b06:	65c6                	ld	a1,80(sp)
    80005b08:	6666                	ld	a2,88(sp)
    80005b0a:	7686                	ld	a3,96(sp)
    80005b0c:	7726                	ld	a4,104(sp)
    80005b0e:	77c6                	ld	a5,112(sp)
    80005b10:	7866                	ld	a6,120(sp)
    80005b12:	688a                	ld	a7,128(sp)
    80005b14:	692a                	ld	s2,136(sp)
    80005b16:	69ca                	ld	s3,144(sp)
    80005b18:	6a6a                	ld	s4,152(sp)
    80005b1a:	7a8a                	ld	s5,160(sp)
    80005b1c:	7b2a                	ld	s6,168(sp)
    80005b1e:	7bca                	ld	s7,176(sp)
    80005b20:	7c6a                	ld	s8,184(sp)
    80005b22:	6c8e                	ld	s9,192(sp)
    80005b24:	6d2e                	ld	s10,200(sp)
    80005b26:	6dce                	ld	s11,208(sp)
    80005b28:	6e6e                	ld	t3,216(sp)
    80005b2a:	7e8e                	ld	t4,224(sp)
    80005b2c:	7f2e                	ld	t5,232(sp)
    80005b2e:	7fce                	ld	t6,240(sp)
    80005b30:	6111                	addi	sp,sp,256
    80005b32:	10200073          	sret
    80005b36:	00000013          	nop
    80005b3a:	00000013          	nop
    80005b3e:	0001                	nop

0000000080005b40 <timervec>:
    80005b40:	34051573          	csrrw	a0,mscratch,a0
    80005b44:	e10c                	sd	a1,0(a0)
    80005b46:	e510                	sd	a2,8(a0)
    80005b48:	e914                	sd	a3,16(a0)
    80005b4a:	6d0c                	ld	a1,24(a0)
    80005b4c:	7110                	ld	a2,32(a0)
    80005b4e:	6194                	ld	a3,0(a1)
    80005b50:	96b2                	add	a3,a3,a2
    80005b52:	e194                	sd	a3,0(a1)
    80005b54:	4589                	li	a1,2
    80005b56:	14459073          	csrw	sip,a1
    80005b5a:	6914                	ld	a3,16(a0)
    80005b5c:	6510                	ld	a2,8(a0)
    80005b5e:	610c                	ld	a1,0(a0)
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	30200073          	mret
	...

0000000080005b6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b6a:	1141                	addi	sp,sp,-16
    80005b6c:	e422                	sd	s0,8(sp)
    80005b6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b70:	0c0007b7          	lui	a5,0xc000
    80005b74:	4705                	li	a4,1
    80005b76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b78:	c3d8                	sw	a4,4(a5)
}
    80005b7a:	6422                	ld	s0,8(sp)
    80005b7c:	0141                	addi	sp,sp,16
    80005b7e:	8082                	ret

0000000080005b80 <plicinithart>:

void
plicinithart(void)
{
    80005b80:	1141                	addi	sp,sp,-16
    80005b82:	e406                	sd	ra,8(sp)
    80005b84:	e022                	sd	s0,0(sp)
    80005b86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	de2080e7          	jalr	-542(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b90:	0085171b          	slliw	a4,a0,0x8
    80005b94:	0c0027b7          	lui	a5,0xc002
    80005b98:	97ba                	add	a5,a5,a4
    80005b9a:	40200713          	li	a4,1026
    80005b9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ba2:	00d5151b          	slliw	a0,a0,0xd
    80005ba6:	0c2017b7          	lui	a5,0xc201
    80005baa:	97aa                	add	a5,a5,a0
    80005bac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005bb0:	60a2                	ld	ra,8(sp)
    80005bb2:	6402                	ld	s0,0(sp)
    80005bb4:	0141                	addi	sp,sp,16
    80005bb6:	8082                	ret

0000000080005bb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bb8:	1141                	addi	sp,sp,-16
    80005bba:	e406                	sd	ra,8(sp)
    80005bbc:	e022                	sd	s0,0(sp)
    80005bbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	daa080e7          	jalr	-598(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bc8:	00d5151b          	slliw	a0,a0,0xd
    80005bcc:	0c2017b7          	lui	a5,0xc201
    80005bd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005bd2:	43c8                	lw	a0,4(a5)
    80005bd4:	60a2                	ld	ra,8(sp)
    80005bd6:	6402                	ld	s0,0(sp)
    80005bd8:	0141                	addi	sp,sp,16
    80005bda:	8082                	ret

0000000080005bdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bdc:	1101                	addi	sp,sp,-32
    80005bde:	ec06                	sd	ra,24(sp)
    80005be0:	e822                	sd	s0,16(sp)
    80005be2:	e426                	sd	s1,8(sp)
    80005be4:	1000                	addi	s0,sp,32
    80005be6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d82080e7          	jalr	-638(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005bf0:	00d5151b          	slliw	a0,a0,0xd
    80005bf4:	0c2017b7          	lui	a5,0xc201
    80005bf8:	97aa                	add	a5,a5,a0
    80005bfa:	c3c4                	sw	s1,4(a5)
}
    80005bfc:	60e2                	ld	ra,24(sp)
    80005bfe:	6442                	ld	s0,16(sp)
    80005c00:	64a2                	ld	s1,8(sp)
    80005c02:	6105                	addi	sp,sp,32
    80005c04:	8082                	ret

0000000080005c06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c06:	1141                	addi	sp,sp,-16
    80005c08:	e406                	sd	ra,8(sp)
    80005c0a:	e022                	sd	s0,0(sp)
    80005c0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c0e:	479d                	li	a5,7
    80005c10:	06a7c863          	blt	a5,a0,80005c80 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005c14:	0001d717          	auipc	a4,0x1d
    80005c18:	3ec70713          	addi	a4,a4,1004 # 80023000 <disk>
    80005c1c:	972a                	add	a4,a4,a0
    80005c1e:	6789                	lui	a5,0x2
    80005c20:	97ba                	add	a5,a5,a4
    80005c22:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c26:	e7ad                	bnez	a5,80005c90 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c28:	00451793          	slli	a5,a0,0x4
    80005c2c:	0001f717          	auipc	a4,0x1f
    80005c30:	3d470713          	addi	a4,a4,980 # 80025000 <disk+0x2000>
    80005c34:	6314                	ld	a3,0(a4)
    80005c36:	96be                	add	a3,a3,a5
    80005c38:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c3c:	6314                	ld	a3,0(a4)
    80005c3e:	96be                	add	a3,a3,a5
    80005c40:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c44:	6314                	ld	a3,0(a4)
    80005c46:	96be                	add	a3,a3,a5
    80005c48:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c4c:	6318                	ld	a4,0(a4)
    80005c4e:	97ba                	add	a5,a5,a4
    80005c50:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c54:	0001d717          	auipc	a4,0x1d
    80005c58:	3ac70713          	addi	a4,a4,940 # 80023000 <disk>
    80005c5c:	972a                	add	a4,a4,a0
    80005c5e:	6789                	lui	a5,0x2
    80005c60:	97ba                	add	a5,a5,a4
    80005c62:	4705                	li	a4,1
    80005c64:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c68:	0001f517          	auipc	a0,0x1f
    80005c6c:	3b050513          	addi	a0,a0,944 # 80025018 <disk+0x2018>
    80005c70:	ffffc097          	auipc	ra,0xffffc
    80005c74:	576080e7          	jalr	1398(ra) # 800021e6 <wakeup>
}
    80005c78:	60a2                	ld	ra,8(sp)
    80005c7a:	6402                	ld	s0,0(sp)
    80005c7c:	0141                	addi	sp,sp,16
    80005c7e:	8082                	ret
    panic("free_desc 1");
    80005c80:	00003517          	auipc	a0,0x3
    80005c84:	af050513          	addi	a0,a0,-1296 # 80008770 <syscalls+0x328>
    80005c88:	ffffb097          	auipc	ra,0xffffb
    80005c8c:	8b2080e7          	jalr	-1870(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005c90:	00003517          	auipc	a0,0x3
    80005c94:	af050513          	addi	a0,a0,-1296 # 80008780 <syscalls+0x338>
    80005c98:	ffffb097          	auipc	ra,0xffffb
    80005c9c:	8a2080e7          	jalr	-1886(ra) # 8000053a <panic>

0000000080005ca0 <virtio_disk_init>:
{
    80005ca0:	1101                	addi	sp,sp,-32
    80005ca2:	ec06                	sd	ra,24(sp)
    80005ca4:	e822                	sd	s0,16(sp)
    80005ca6:	e426                	sd	s1,8(sp)
    80005ca8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005caa:	00003597          	auipc	a1,0x3
    80005cae:	ae658593          	addi	a1,a1,-1306 # 80008790 <syscalls+0x348>
    80005cb2:	0001f517          	auipc	a0,0x1f
    80005cb6:	47650513          	addi	a0,a0,1142 # 80025128 <disk+0x2128>
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	e86080e7          	jalr	-378(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cc2:	100017b7          	lui	a5,0x10001
    80005cc6:	4398                	lw	a4,0(a5)
    80005cc8:	2701                	sext.w	a4,a4
    80005cca:	747277b7          	lui	a5,0x74727
    80005cce:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cd2:	0ef71063          	bne	a4,a5,80005db2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cd6:	100017b7          	lui	a5,0x10001
    80005cda:	43dc                	lw	a5,4(a5)
    80005cdc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cde:	4705                	li	a4,1
    80005ce0:	0ce79963          	bne	a5,a4,80005db2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ce4:	100017b7          	lui	a5,0x10001
    80005ce8:	479c                	lw	a5,8(a5)
    80005cea:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cec:	4709                	li	a4,2
    80005cee:	0ce79263          	bne	a5,a4,80005db2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cf2:	100017b7          	lui	a5,0x10001
    80005cf6:	47d8                	lw	a4,12(a5)
    80005cf8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cfa:	554d47b7          	lui	a5,0x554d4
    80005cfe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d02:	0af71863          	bne	a4,a5,80005db2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d06:	100017b7          	lui	a5,0x10001
    80005d0a:	4705                	li	a4,1
    80005d0c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d0e:	470d                	li	a4,3
    80005d10:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d12:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d14:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d18:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d1c:	8f75                	and	a4,a4,a3
    80005d1e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d20:	472d                	li	a4,11
    80005d22:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d24:	473d                	li	a4,15
    80005d26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d28:	6705                	lui	a4,0x1
    80005d2a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d2c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d30:	5bdc                	lw	a5,52(a5)
    80005d32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d34:	c7d9                	beqz	a5,80005dc2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005d36:	471d                	li	a4,7
    80005d38:	08f77d63          	bgeu	a4,a5,80005dd2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d3c:	100014b7          	lui	s1,0x10001
    80005d40:	47a1                	li	a5,8
    80005d42:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d44:	6609                	lui	a2,0x2
    80005d46:	4581                	li	a1,0
    80005d48:	0001d517          	auipc	a0,0x1d
    80005d4c:	2b850513          	addi	a0,a0,696 # 80023000 <disk>
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	f7c080e7          	jalr	-132(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d58:	0001d717          	auipc	a4,0x1d
    80005d5c:	2a870713          	addi	a4,a4,680 # 80023000 <disk>
    80005d60:	00c75793          	srli	a5,a4,0xc
    80005d64:	2781                	sext.w	a5,a5
    80005d66:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d68:	0001f797          	auipc	a5,0x1f
    80005d6c:	29878793          	addi	a5,a5,664 # 80025000 <disk+0x2000>
    80005d70:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d72:	0001d717          	auipc	a4,0x1d
    80005d76:	30e70713          	addi	a4,a4,782 # 80023080 <disk+0x80>
    80005d7a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d7c:	0001e717          	auipc	a4,0x1e
    80005d80:	28470713          	addi	a4,a4,644 # 80024000 <disk+0x1000>
    80005d84:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d86:	4705                	li	a4,1
    80005d88:	00e78c23          	sb	a4,24(a5)
    80005d8c:	00e78ca3          	sb	a4,25(a5)
    80005d90:	00e78d23          	sb	a4,26(a5)
    80005d94:	00e78da3          	sb	a4,27(a5)
    80005d98:	00e78e23          	sb	a4,28(a5)
    80005d9c:	00e78ea3          	sb	a4,29(a5)
    80005da0:	00e78f23          	sb	a4,30(a5)
    80005da4:	00e78fa3          	sb	a4,31(a5)
}
    80005da8:	60e2                	ld	ra,24(sp)
    80005daa:	6442                	ld	s0,16(sp)
    80005dac:	64a2                	ld	s1,8(sp)
    80005dae:	6105                	addi	sp,sp,32
    80005db0:	8082                	ret
    panic("could not find virtio disk");
    80005db2:	00003517          	auipc	a0,0x3
    80005db6:	9ee50513          	addi	a0,a0,-1554 # 800087a0 <syscalls+0x358>
    80005dba:	ffffa097          	auipc	ra,0xffffa
    80005dbe:	780080e7          	jalr	1920(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005dc2:	00003517          	auipc	a0,0x3
    80005dc6:	9fe50513          	addi	a0,a0,-1538 # 800087c0 <syscalls+0x378>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	770080e7          	jalr	1904(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	a0e50513          	addi	a0,a0,-1522 # 800087e0 <syscalls+0x398>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	760080e7          	jalr	1888(ra) # 8000053a <panic>

0000000080005de2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005de2:	7119                	addi	sp,sp,-128
    80005de4:	fc86                	sd	ra,120(sp)
    80005de6:	f8a2                	sd	s0,112(sp)
    80005de8:	f4a6                	sd	s1,104(sp)
    80005dea:	f0ca                	sd	s2,96(sp)
    80005dec:	ecce                	sd	s3,88(sp)
    80005dee:	e8d2                	sd	s4,80(sp)
    80005df0:	e4d6                	sd	s5,72(sp)
    80005df2:	e0da                	sd	s6,64(sp)
    80005df4:	fc5e                	sd	s7,56(sp)
    80005df6:	f862                	sd	s8,48(sp)
    80005df8:	f466                	sd	s9,40(sp)
    80005dfa:	f06a                	sd	s10,32(sp)
    80005dfc:	ec6e                	sd	s11,24(sp)
    80005dfe:	0100                	addi	s0,sp,128
    80005e00:	8aaa                	mv	s5,a0
    80005e02:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e04:	00c52c83          	lw	s9,12(a0)
    80005e08:	001c9c9b          	slliw	s9,s9,0x1
    80005e0c:	1c82                	slli	s9,s9,0x20
    80005e0e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e12:	0001f517          	auipc	a0,0x1f
    80005e16:	31650513          	addi	a0,a0,790 # 80025128 <disk+0x2128>
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	db6080e7          	jalr	-586(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005e22:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e24:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e26:	0001dc17          	auipc	s8,0x1d
    80005e2a:	1dac0c13          	addi	s8,s8,474 # 80023000 <disk>
    80005e2e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e30:	4b0d                	li	s6,3
    80005e32:	a0ad                	j	80005e9c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e34:	00fc0733          	add	a4,s8,a5
    80005e38:	975e                	add	a4,a4,s7
    80005e3a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e3e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e40:	0207c563          	bltz	a5,80005e6a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e44:	2905                	addiw	s2,s2,1
    80005e46:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005e48:	19690c63          	beq	s2,s6,80005fe0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005e4c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e4e:	0001f717          	auipc	a4,0x1f
    80005e52:	1ca70713          	addi	a4,a4,458 # 80025018 <disk+0x2018>
    80005e56:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e58:	00074683          	lbu	a3,0(a4)
    80005e5c:	fee1                	bnez	a3,80005e34 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e5e:	2785                	addiw	a5,a5,1
    80005e60:	0705                	addi	a4,a4,1
    80005e62:	fe979be3          	bne	a5,s1,80005e58 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e66:	57fd                	li	a5,-1
    80005e68:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e6a:	01205d63          	blez	s2,80005e84 <virtio_disk_rw+0xa2>
    80005e6e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e70:	000a2503          	lw	a0,0(s4)
    80005e74:	00000097          	auipc	ra,0x0
    80005e78:	d92080e7          	jalr	-622(ra) # 80005c06 <free_desc>
      for(int j = 0; j < i; j++)
    80005e7c:	2d85                	addiw	s11,s11,1
    80005e7e:	0a11                	addi	s4,s4,4
    80005e80:	ff2d98e3          	bne	s11,s2,80005e70 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e84:	0001f597          	auipc	a1,0x1f
    80005e88:	2a458593          	addi	a1,a1,676 # 80025128 <disk+0x2128>
    80005e8c:	0001f517          	auipc	a0,0x1f
    80005e90:	18c50513          	addi	a0,a0,396 # 80025018 <disk+0x2018>
    80005e94:	ffffc097          	auipc	ra,0xffffc
    80005e98:	1c6080e7          	jalr	454(ra) # 8000205a <sleep>
  for(int i = 0; i < 3; i++){
    80005e9c:	f8040a13          	addi	s4,s0,-128
{
    80005ea0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005ea2:	894e                	mv	s2,s3
    80005ea4:	b765                	j	80005e4c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005ea6:	0001f697          	auipc	a3,0x1f
    80005eaa:	15a6b683          	ld	a3,346(a3) # 80025000 <disk+0x2000>
    80005eae:	96ba                	add	a3,a3,a4
    80005eb0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005eb4:	0001d817          	auipc	a6,0x1d
    80005eb8:	14c80813          	addi	a6,a6,332 # 80023000 <disk>
    80005ebc:	0001f697          	auipc	a3,0x1f
    80005ec0:	14468693          	addi	a3,a3,324 # 80025000 <disk+0x2000>
    80005ec4:	6290                	ld	a2,0(a3)
    80005ec6:	963a                	add	a2,a2,a4
    80005ec8:	00c65583          	lhu	a1,12(a2)
    80005ecc:	0015e593          	ori	a1,a1,1
    80005ed0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005ed4:	f8842603          	lw	a2,-120(s0)
    80005ed8:	628c                	ld	a1,0(a3)
    80005eda:	972e                	add	a4,a4,a1
    80005edc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005ee0:	20050593          	addi	a1,a0,512
    80005ee4:	0592                	slli	a1,a1,0x4
    80005ee6:	95c2                	add	a1,a1,a6
    80005ee8:	577d                	li	a4,-1
    80005eea:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005eee:	00461713          	slli	a4,a2,0x4
    80005ef2:	6290                	ld	a2,0(a3)
    80005ef4:	963a                	add	a2,a2,a4
    80005ef6:	03078793          	addi	a5,a5,48
    80005efa:	97c2                	add	a5,a5,a6
    80005efc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005efe:	629c                	ld	a5,0(a3)
    80005f00:	97ba                	add	a5,a5,a4
    80005f02:	4605                	li	a2,1
    80005f04:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f06:	629c                	ld	a5,0(a3)
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	4809                	li	a6,2
    80005f0c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f10:	629c                	ld	a5,0(a3)
    80005f12:	97ba                	add	a5,a5,a4
    80005f14:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f18:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005f1c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f20:	6698                	ld	a4,8(a3)
    80005f22:	00275783          	lhu	a5,2(a4)
    80005f26:	8b9d                	andi	a5,a5,7
    80005f28:	0786                	slli	a5,a5,0x1
    80005f2a:	973e                	add	a4,a4,a5
    80005f2c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80005f30:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005f34:	6698                	ld	a4,8(a3)
    80005f36:	00275783          	lhu	a5,2(a4)
    80005f3a:	2785                	addiw	a5,a5,1
    80005f3c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005f40:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f4c:	004aa783          	lw	a5,4(s5)
    80005f50:	02c79163          	bne	a5,a2,80005f72 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f54:	0001f917          	auipc	s2,0x1f
    80005f58:	1d490913          	addi	s2,s2,468 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005f5c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f5e:	85ca                	mv	a1,s2
    80005f60:	8556                	mv	a0,s5
    80005f62:	ffffc097          	auipc	ra,0xffffc
    80005f66:	0f8080e7          	jalr	248(ra) # 8000205a <sleep>
  while(b->disk == 1) {
    80005f6a:	004aa783          	lw	a5,4(s5)
    80005f6e:	fe9788e3          	beq	a5,s1,80005f5e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f72:	f8042903          	lw	s2,-128(s0)
    80005f76:	20090713          	addi	a4,s2,512
    80005f7a:	0712                	slli	a4,a4,0x4
    80005f7c:	0001d797          	auipc	a5,0x1d
    80005f80:	08478793          	addi	a5,a5,132 # 80023000 <disk>
    80005f84:	97ba                	add	a5,a5,a4
    80005f86:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005f8a:	0001f997          	auipc	s3,0x1f
    80005f8e:	07698993          	addi	s3,s3,118 # 80025000 <disk+0x2000>
    80005f92:	00491713          	slli	a4,s2,0x4
    80005f96:	0009b783          	ld	a5,0(s3)
    80005f9a:	97ba                	add	a5,a5,a4
    80005f9c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005fa0:	854a                	mv	a0,s2
    80005fa2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005fa6:	00000097          	auipc	ra,0x0
    80005faa:	c60080e7          	jalr	-928(ra) # 80005c06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005fae:	8885                	andi	s1,s1,1
    80005fb0:	f0ed                	bnez	s1,80005f92 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fb2:	0001f517          	auipc	a0,0x1f
    80005fb6:	17650513          	addi	a0,a0,374 # 80025128 <disk+0x2128>
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	cca080e7          	jalr	-822(ra) # 80000c84 <release>
}
    80005fc2:	70e6                	ld	ra,120(sp)
    80005fc4:	7446                	ld	s0,112(sp)
    80005fc6:	74a6                	ld	s1,104(sp)
    80005fc8:	7906                	ld	s2,96(sp)
    80005fca:	69e6                	ld	s3,88(sp)
    80005fcc:	6a46                	ld	s4,80(sp)
    80005fce:	6aa6                	ld	s5,72(sp)
    80005fd0:	6b06                	ld	s6,64(sp)
    80005fd2:	7be2                	ld	s7,56(sp)
    80005fd4:	7c42                	ld	s8,48(sp)
    80005fd6:	7ca2                	ld	s9,40(sp)
    80005fd8:	7d02                	ld	s10,32(sp)
    80005fda:	6de2                	ld	s11,24(sp)
    80005fdc:	6109                	addi	sp,sp,128
    80005fde:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fe0:	f8042503          	lw	a0,-128(s0)
    80005fe4:	20050793          	addi	a5,a0,512
    80005fe8:	0792                	slli	a5,a5,0x4
  if(write)
    80005fea:	0001d817          	auipc	a6,0x1d
    80005fee:	01680813          	addi	a6,a6,22 # 80023000 <disk>
    80005ff2:	00f80733          	add	a4,a6,a5
    80005ff6:	01a036b3          	snez	a3,s10
    80005ffa:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80005ffe:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006002:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006006:	7679                	lui	a2,0xffffe
    80006008:	963e                	add	a2,a2,a5
    8000600a:	0001f697          	auipc	a3,0x1f
    8000600e:	ff668693          	addi	a3,a3,-10 # 80025000 <disk+0x2000>
    80006012:	6298                	ld	a4,0(a3)
    80006014:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006016:	0a878593          	addi	a1,a5,168
    8000601a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000601c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000601e:	6298                	ld	a4,0(a3)
    80006020:	9732                	add	a4,a4,a2
    80006022:	45c1                	li	a1,16
    80006024:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006026:	6298                	ld	a4,0(a3)
    80006028:	9732                	add	a4,a4,a2
    8000602a:	4585                	li	a1,1
    8000602c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006030:	f8442703          	lw	a4,-124(s0)
    80006034:	628c                	ld	a1,0(a3)
    80006036:	962e                	add	a2,a2,a1
    80006038:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000603c:	0712                	slli	a4,a4,0x4
    8000603e:	6290                	ld	a2,0(a3)
    80006040:	963a                	add	a2,a2,a4
    80006042:	058a8593          	addi	a1,s5,88
    80006046:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006048:	6294                	ld	a3,0(a3)
    8000604a:	96ba                	add	a3,a3,a4
    8000604c:	40000613          	li	a2,1024
    80006050:	c690                	sw	a2,8(a3)
  if(write)
    80006052:	e40d1ae3          	bnez	s10,80005ea6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006056:	0001f697          	auipc	a3,0x1f
    8000605a:	faa6b683          	ld	a3,-86(a3) # 80025000 <disk+0x2000>
    8000605e:	96ba                	add	a3,a3,a4
    80006060:	4609                	li	a2,2
    80006062:	00c69623          	sh	a2,12(a3)
    80006066:	b5b9                	j	80005eb4 <virtio_disk_rw+0xd2>

0000000080006068 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006068:	1101                	addi	sp,sp,-32
    8000606a:	ec06                	sd	ra,24(sp)
    8000606c:	e822                	sd	s0,16(sp)
    8000606e:	e426                	sd	s1,8(sp)
    80006070:	e04a                	sd	s2,0(sp)
    80006072:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006074:	0001f517          	auipc	a0,0x1f
    80006078:	0b450513          	addi	a0,a0,180 # 80025128 <disk+0x2128>
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	b54080e7          	jalr	-1196(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006084:	10001737          	lui	a4,0x10001
    80006088:	533c                	lw	a5,96(a4)
    8000608a:	8b8d                	andi	a5,a5,3
    8000608c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000608e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006092:	0001f797          	auipc	a5,0x1f
    80006096:	f6e78793          	addi	a5,a5,-146 # 80025000 <disk+0x2000>
    8000609a:	6b94                	ld	a3,16(a5)
    8000609c:	0207d703          	lhu	a4,32(a5)
    800060a0:	0026d783          	lhu	a5,2(a3)
    800060a4:	06f70163          	beq	a4,a5,80006106 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060a8:	0001d917          	auipc	s2,0x1d
    800060ac:	f5890913          	addi	s2,s2,-168 # 80023000 <disk>
    800060b0:	0001f497          	auipc	s1,0x1f
    800060b4:	f5048493          	addi	s1,s1,-176 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060b8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060bc:	6898                	ld	a4,16(s1)
    800060be:	0204d783          	lhu	a5,32(s1)
    800060c2:	8b9d                	andi	a5,a5,7
    800060c4:	078e                	slli	a5,a5,0x3
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060ca:	20078713          	addi	a4,a5,512
    800060ce:	0712                	slli	a4,a4,0x4
    800060d0:	974a                	add	a4,a4,s2
    800060d2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800060d6:	e731                	bnez	a4,80006122 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800060d8:	20078793          	addi	a5,a5,512
    800060dc:	0792                	slli	a5,a5,0x4
    800060de:	97ca                	add	a5,a5,s2
    800060e0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800060e2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800060e6:	ffffc097          	auipc	ra,0xffffc
    800060ea:	100080e7          	jalr	256(ra) # 800021e6 <wakeup>

    disk.used_idx += 1;
    800060ee:	0204d783          	lhu	a5,32(s1)
    800060f2:	2785                	addiw	a5,a5,1
    800060f4:	17c2                	slli	a5,a5,0x30
    800060f6:	93c1                	srli	a5,a5,0x30
    800060f8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800060fc:	6898                	ld	a4,16(s1)
    800060fe:	00275703          	lhu	a4,2(a4)
    80006102:	faf71be3          	bne	a4,a5,800060b8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006106:	0001f517          	auipc	a0,0x1f
    8000610a:	02250513          	addi	a0,a0,34 # 80025128 <disk+0x2128>
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	b76080e7          	jalr	-1162(ra) # 80000c84 <release>
}
    80006116:	60e2                	ld	ra,24(sp)
    80006118:	6442                	ld	s0,16(sp)
    8000611a:	64a2                	ld	s1,8(sp)
    8000611c:	6902                	ld	s2,0(sp)
    8000611e:	6105                	addi	sp,sp,32
    80006120:	8082                	ret
      panic("virtio_disk_intr status");
    80006122:	00002517          	auipc	a0,0x2
    80006126:	6de50513          	addi	a0,a0,1758 # 80008800 <syscalls+0x3b8>
    8000612a:	ffffa097          	auipc	ra,0xffffa
    8000612e:	410080e7          	jalr	1040(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
