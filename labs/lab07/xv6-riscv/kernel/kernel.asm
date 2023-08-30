
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	dae78793          	addi	a5,a5,-594 # 80005e10 <timervec>
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
    8000012e:	352080e7          	jalr	850(ra) # 8000247c <either_copyin>
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
    800001d4:	ea6080e7          	jalr	-346(ra) # 80002076 <sleep>
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
    80000210:	21a080e7          	jalr	538(ra) # 80002426 <either_copyout>
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
    800002f0:	1e6080e7          	jalr	486(ra) # 800024d2 <procdump>
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
    80000444:	dc2080e7          	jalr	-574(ra) # 80002202 <wakeup>
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
    80000472:	00022797          	auipc	a5,0x22
    80000476:	8a678793          	addi	a5,a5,-1882 # 80021d18 <devsw>
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
    80000892:	974080e7          	jalr	-1676(ra) # 80002202 <wakeup>
    
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
    8000091e:	75c080e7          	jalr	1884(ra) # 80002076 <sleep>
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
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	936080e7          	jalr	-1738(ra) # 800027ee <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	f90080e7          	jalr	-112(ra) # 80005e50 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	ffc080e7          	jalr	-4(ra) # 80001ec4 <scheduler>
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
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	896080e7          	jalr	-1898(ra) # 800027c6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	8b6080e7          	jalr	-1866(ra) # 800027ee <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	efa080e7          	jalr	-262(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	f08080e7          	jalr	-248(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	0ce080e7          	jalr	206(ra) # 8000301e <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	75c080e7          	jalr	1884(ra) # 800036b4 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	70e080e7          	jalr	1806(ra) # 8000466e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	008080e7          	jalr	8(ra) # 80005f70 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d1a080e7          	jalr	-742(ra) # 80001c8a <userinit>
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
    80001858:	27ca0a13          	addi	s4,s4,636 # 80017ad0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8591                	srai	a1,a1,0x4
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
    8000188e:	19048493          	addi	s1,s1,400
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
    80001920:	00016997          	auipc	s3,0x16
    80001924:	1b098993          	addi	s3,s3,432 # 80017ad0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	8791                	srai	a5,a5,0x4
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	19048493          	addi	s1,s1,400
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
    800019ea:	e2a7a783          	lw	a5,-470(a5) # 80008810 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	e16080e7          	jalr	-490(ra) # 80002806 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e007a823          	sw	zero,-496(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	c2a080e7          	jalr	-982(ra) # 80003634 <fsinit>
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
    80001a36:	de278793          	addi	a5,a5,-542 # 80008814 <nextpid>
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
    80001bb4:	00016917          	auipc	s2,0x16
    80001bb8:	f1c90913          	addi	s2,s2,-228 # 80017ad0 <tickslock>
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
    80001bd4:	19048493          	addi	s1,s1,400
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a0bd                	j	80001c4c <allocproc+0xac>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  p->create_time = ticks;
    80001bee:	00007797          	auipc	a5,0x7
    80001bf2:	4427e783          	lwu	a5,1090(a5) # 80009030 <ticks>
    80001bf6:	16f4b423          	sd	a5,360(s1)
  p->run_time = 0;
    80001bfa:	1604b823          	sd	zero,368(s1)
  p->wait_time = 0;
    80001bfe:	1604bc23          	sd	zero,376(s1)
  p->sleep_time = 0;
    80001c02:	1804b023          	sd	zero,384(s1)
  p->exit_time = 0;
    80001c06:	1804b423          	sd	zero,392(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	ed6080e7          	jalr	-298(ra) # 80000ae0 <kalloc>
    80001c12:	892a                	mv	s2,a0
    80001c14:	eca8                	sd	a0,88(s1)
    80001c16:	c131                	beqz	a0,80001c5a <allocproc+0xba>
  p->pagetable = proc_pagetable(p);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	e40080e7          	jalr	-448(ra) # 80001a5a <proc_pagetable>
    80001c22:	892a                	mv	s2,a0
    80001c24:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c26:	c531                	beqz	a0,80001c72 <allocproc+0xd2>
  memset(&p->context, 0, sizeof(p->context));
    80001c28:	07000613          	li	a2,112
    80001c2c:	4581                	li	a1,0
    80001c2e:	06048513          	addi	a0,s1,96
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	09a080e7          	jalr	154(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c3a:	00000797          	auipc	a5,0x0
    80001c3e:	d9478793          	addi	a5,a5,-620 # 800019ce <forkret>
    80001c42:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c44:	60bc                	ld	a5,64(s1)
    80001c46:	6705                	lui	a4,0x1
    80001c48:	97ba                	add	a5,a5,a4
    80001c4a:	f4bc                	sd	a5,104(s1)
}
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	60e2                	ld	ra,24(sp)
    80001c50:	6442                	ld	s0,16(sp)
    80001c52:	64a2                	ld	s1,8(sp)
    80001c54:	6902                	ld	s2,0(sp)
    80001c56:	6105                	addi	sp,sp,32
    80001c58:	8082                	ret
    freeproc(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	eec080e7          	jalr	-276(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	01e080e7          	jalr	30(ra) # 80000c84 <release>
    return 0;
    80001c6e:	84ca                	mv	s1,s2
    80001c70:	bff1                	j	80001c4c <allocproc+0xac>
    freeproc(p);
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	ed4080e7          	jalr	-300(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	006080e7          	jalr	6(ra) # 80000c84 <release>
    return 0;
    80001c86:	84ca                	mv	s1,s2
    80001c88:	b7d1                	j	80001c4c <allocproc+0xac>

0000000080001c8a <userinit>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	f0c080e7          	jalr	-244(ra) # 80001ba0 <allocproc>
    80001c9c:	84aa                	mv	s1,a0
  initproc = p;
    80001c9e:	00007797          	auipc	a5,0x7
    80001ca2:	38a7b523          	sd	a0,906(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca6:	03400613          	li	a2,52
    80001caa:	00007597          	auipc	a1,0x7
    80001cae:	b7658593          	addi	a1,a1,-1162 # 80008820 <initcode>
    80001cb2:	6928                	ld	a0,80(a0)
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	698080e7          	jalr	1688(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cbc:	6785                	lui	a5,0x1
    80001cbe:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cca:	4641                	li	a2,16
    80001ccc:	00006597          	auipc	a1,0x6
    80001cd0:	53458593          	addi	a1,a1,1332 # 80008200 <digits+0x1c0>
    80001cd4:	15848513          	addi	a0,s1,344
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	13e080e7          	jalr	318(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001ce0:	00006517          	auipc	a0,0x6
    80001ce4:	53050513          	addi	a0,a0,1328 # 80008210 <digits+0x1d0>
    80001ce8:	00002097          	auipc	ra,0x2
    80001cec:	382080e7          	jalr	898(ra) # 8000406a <namei>
    80001cf0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf4:	478d                	li	a5,3
    80001cf6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	f8a080e7          	jalr	-118(ra) # 80000c84 <release>
}
    80001d02:	60e2                	ld	ra,24(sp)
    80001d04:	6442                	ld	s0,16(sp)
    80001d06:	64a2                	ld	s1,8(sp)
    80001d08:	6105                	addi	sp,sp,32
    80001d0a:	8082                	ret

0000000080001d0c <growproc>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	e04a                	sd	s2,0(sp)
    80001d16:	1000                	addi	s0,sp,32
    80001d18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	c7c080e7          	jalr	-900(ra) # 80001996 <myproc>
    80001d22:	892a                	mv	s2,a0
  sz = p->sz;
    80001d24:	652c                	ld	a1,72(a0)
    80001d26:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d2a:	00904f63          	bgtz	s1,80001d48 <growproc+0x3c>
  } else if(n < 0){
    80001d2e:	0204cd63          	bltz	s1,80001d68 <growproc+0x5c>
  p->sz = sz;
    80001d32:	1782                	slli	a5,a5,0x20
    80001d34:	9381                	srli	a5,a5,0x20
    80001d36:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d3a:	4501                	li	a0,0
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6902                	ld	s2,0(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d48:	00f4863b          	addw	a2,s1,a5
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	1582                	slli	a1,a1,0x20
    80001d52:	9181                	srli	a1,a1,0x20
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	6b0080e7          	jalr	1712(ra) # 80001406 <uvmalloc>
    80001d5e:	0005079b          	sext.w	a5,a0
    80001d62:	fbe1                	bnez	a5,80001d32 <growproc+0x26>
      return -1;
    80001d64:	557d                	li	a0,-1
    80001d66:	bfd9                	j	80001d3c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d68:	00f4863b          	addw	a2,s1,a5
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	648080e7          	jalr	1608(ra) # 800013be <uvmdealloc>
    80001d7e:	0005079b          	sext.w	a5,a0
    80001d82:	bf45                	j	80001d32 <growproc+0x26>

0000000080001d84 <fork>:
{
    80001d84:	7139                	addi	sp,sp,-64
    80001d86:	fc06                	sd	ra,56(sp)
    80001d88:	f822                	sd	s0,48(sp)
    80001d8a:	f426                	sd	s1,40(sp)
    80001d8c:	f04a                	sd	s2,32(sp)
    80001d8e:	ec4e                	sd	s3,24(sp)
    80001d90:	e852                	sd	s4,16(sp)
    80001d92:	e456                	sd	s5,8(sp)
    80001d94:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	c00080e7          	jalr	-1024(ra) # 80001996 <myproc>
    80001d9e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e00080e7          	jalr	-512(ra) # 80001ba0 <allocproc>
    80001da8:	10050c63          	beqz	a0,80001ec0 <fork+0x13c>
    80001dac:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dae:	048ab603          	ld	a2,72(s5)
    80001db2:	692c                	ld	a1,80(a0)
    80001db4:	050ab503          	ld	a0,80(s5)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	79e080e7          	jalr	1950(ra) # 80001556 <uvmcopy>
    80001dc0:	04054863          	bltz	a0,80001e10 <fork+0x8c>
  np->sz = p->sz;
    80001dc4:	048ab783          	ld	a5,72(s5)
    80001dc8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dcc:	058ab683          	ld	a3,88(s5)
    80001dd0:	87b6                	mv	a5,a3
    80001dd2:	058a3703          	ld	a4,88(s4)
    80001dd6:	12068693          	addi	a3,a3,288
    80001dda:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dde:	6788                	ld	a0,8(a5)
    80001de0:	6b8c                	ld	a1,16(a5)
    80001de2:	6f90                	ld	a2,24(a5)
    80001de4:	01073023          	sd	a6,0(a4)
    80001de8:	e708                	sd	a0,8(a4)
    80001dea:	eb0c                	sd	a1,16(a4)
    80001dec:	ef10                	sd	a2,24(a4)
    80001dee:	02078793          	addi	a5,a5,32
    80001df2:	02070713          	addi	a4,a4,32
    80001df6:	fed792e3          	bne	a5,a3,80001dda <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfa:	058a3783          	ld	a5,88(s4)
    80001dfe:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e02:	0d0a8493          	addi	s1,s5,208
    80001e06:	0d0a0913          	addi	s2,s4,208
    80001e0a:	150a8993          	addi	s3,s5,336
    80001e0e:	a00d                	j	80001e30 <fork+0xac>
    freeproc(np);
    80001e10:	8552                	mv	a0,s4
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	d36080e7          	jalr	-714(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001e1a:	8552                	mv	a0,s4
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e68080e7          	jalr	-408(ra) # 80000c84 <release>
    return -1;
    80001e24:	597d                	li	s2,-1
    80001e26:	a059                	j	80001eac <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	0921                	addi	s2,s2,8
    80001e2c:	01348b63          	beq	s1,s3,80001e42 <fork+0xbe>
    if(p->ofile[i])
    80001e30:	6088                	ld	a0,0(s1)
    80001e32:	d97d                	beqz	a0,80001e28 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e34:	00003097          	auipc	ra,0x3
    80001e38:	8cc080e7          	jalr	-1844(ra) # 80004700 <filedup>
    80001e3c:	00a93023          	sd	a0,0(s2)
    80001e40:	b7e5                	j	80001e28 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e42:	150ab503          	ld	a0,336(s5)
    80001e46:	00002097          	auipc	ra,0x2
    80001e4a:	a2a080e7          	jalr	-1494(ra) # 80003870 <idup>
    80001e4e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e52:	4641                	li	a2,16
    80001e54:	158a8593          	addi	a1,s5,344
    80001e58:	158a0513          	addi	a0,s4,344
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	fba080e7          	jalr	-70(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e64:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e68:	8552                	mv	a0,s4
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e72:	0000f497          	auipc	s1,0xf
    80001e76:	44648493          	addi	s1,s1,1094 # 800112b8 <wait_lock>
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	d54080e7          	jalr	-684(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e84:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	dfa080e7          	jalr	-518(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d3c080e7          	jalr	-708(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e9c:	478d                	li	a5,3
    80001e9e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	de0080e7          	jalr	-544(ra) # 80000c84 <release>
}
    80001eac:	854a                	mv	a0,s2
    80001eae:	70e2                	ld	ra,56(sp)
    80001eb0:	7442                	ld	s0,48(sp)
    80001eb2:	74a2                	ld	s1,40(sp)
    80001eb4:	7902                	ld	s2,32(sp)
    80001eb6:	69e2                	ld	s3,24(sp)
    80001eb8:	6a42                	ld	s4,16(sp)
    80001eba:	6aa2                	ld	s5,8(sp)
    80001ebc:	6121                	addi	sp,sp,64
    80001ebe:	8082                	ret
    return -1;
    80001ec0:	597d                	li	s2,-1
    80001ec2:	b7ed                	j	80001eac <fork+0x128>

0000000080001ec4 <scheduler>:
{
    80001ec4:	7139                	addi	sp,sp,-64
    80001ec6:	fc06                	sd	ra,56(sp)
    80001ec8:	f822                	sd	s0,48(sp)
    80001eca:	f426                	sd	s1,40(sp)
    80001ecc:	f04a                	sd	s2,32(sp)
    80001ece:	ec4e                	sd	s3,24(sp)
    80001ed0:	e852                	sd	s4,16(sp)
    80001ed2:	e456                	sd	s5,8(sp)
    80001ed4:	e05a                	sd	s6,0(sp)
    80001ed6:	0080                	addi	s0,sp,64
    80001ed8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eda:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001edc:	00779a93          	slli	s5,a5,0x7
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	3c070713          	addi	a4,a4,960 # 800112a0 <pid_lock>
    80001ee8:	9756                	add	a4,a4,s5
    80001eea:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	3ea70713          	addi	a4,a4,1002 # 800112d8 <cpus+0x8>
    80001ef6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef8:	498d                	li	s3,3
        p->state = RUNNING;
    80001efa:	4b11                	li	s6,4
        c->proc = p;
    80001efc:	079e                	slli	a5,a5,0x7
    80001efe:	0000fa17          	auipc	s4,0xf
    80001f02:	3a2a0a13          	addi	s4,s4,930 # 800112a0 <pid_lock>
    80001f06:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	00016917          	auipc	s2,0x16
    80001f0c:	bc890913          	addi	s2,s2,-1080 # 80017ad0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f18:	10079073          	csrw	sstatus,a5
    80001f1c:	0000f497          	auipc	s1,0xf
    80001f20:	7b448493          	addi	s1,s1,1972 # 800116d0 <proc>
    80001f24:	a811                	j	80001f38 <scheduler+0x74>
      release(&p->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d5c080e7          	jalr	-676(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f30:	19048493          	addi	s1,s1,400
    80001f34:	fd248ee3          	beq	s1,s2,80001f10 <scheduler+0x4c>
      acquire(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	c96080e7          	jalr	-874(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f42:	4c9c                	lw	a5,24(s1)
    80001f44:	ff3791e3          	bne	a5,s3,80001f26 <scheduler+0x62>
        p->state = RUNNING;
    80001f48:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f4c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f50:	06048593          	addi	a1,s1,96
    80001f54:	8556                	mv	a0,s5
    80001f56:	00001097          	auipc	ra,0x1
    80001f5a:	806080e7          	jalr	-2042(ra) # 8000275c <swtch>
        c->proc = 0;
    80001f5e:	020a3823          	sd	zero,48(s4)
    80001f62:	b7d1                	j	80001f26 <scheduler+0x62>

0000000080001f64 <sched>:
{
    80001f64:	7179                	addi	sp,sp,-48
    80001f66:	f406                	sd	ra,40(sp)
    80001f68:	f022                	sd	s0,32(sp)
    80001f6a:	ec26                	sd	s1,24(sp)
    80001f6c:	e84a                	sd	s2,16(sp)
    80001f6e:	e44e                	sd	s3,8(sp)
    80001f70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	a24080e7          	jalr	-1500(ra) # 80001996 <myproc>
    80001f7a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	bda080e7          	jalr	-1062(ra) # 80000b56 <holding>
    80001f84:	c93d                	beqz	a0,80001ffa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f86:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f88:	2781                	sext.w	a5,a5
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	31470713          	addi	a4,a4,788 # 800112a0 <pid_lock>
    80001f94:	97ba                	add	a5,a5,a4
    80001f96:	0a87a703          	lw	a4,168(a5)
    80001f9a:	4785                	li	a5,1
    80001f9c:	06f71763          	bne	a4,a5,8000200a <sched+0xa6>
  if(p->state == RUNNING)
    80001fa0:	4c98                	lw	a4,24(s1)
    80001fa2:	4791                	li	a5,4
    80001fa4:	06f70b63          	beq	a4,a5,8000201a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fac:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fae:	efb5                	bnez	a5,8000202a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb2:	0000f917          	auipc	s2,0xf
    80001fb6:	2ee90913          	addi	s2,s2,750 # 800112a0 <pid_lock>
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	97ca                	add	a5,a5,s2
    80001fc0:	0ac7a983          	lw	s3,172(a5)
    80001fc4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	0000f597          	auipc	a1,0xf
    80001fce:	30e58593          	addi	a1,a1,782 # 800112d8 <cpus+0x8>
    80001fd2:	95be                	add	a1,a1,a5
    80001fd4:	06048513          	addi	a0,s1,96
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	784080e7          	jalr	1924(ra) # 8000275c <swtch>
    80001fe0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe2:	2781                	sext.w	a5,a5
    80001fe4:	079e                	slli	a5,a5,0x7
    80001fe6:	993e                	add	s2,s2,a5
    80001fe8:	0b392623          	sw	s3,172(s2)
}
    80001fec:	70a2                	ld	ra,40(sp)
    80001fee:	7402                	ld	s0,32(sp)
    80001ff0:	64e2                	ld	s1,24(sp)
    80001ff2:	6942                	ld	s2,16(sp)
    80001ff4:	69a2                	ld	s3,8(sp)
    80001ff6:	6145                	addi	sp,sp,48
    80001ff8:	8082                	ret
    panic("sched p->lock");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	21e50513          	addi	a0,a0,542 # 80008218 <digits+0x1d8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	538080e7          	jalr	1336(ra) # 8000053a <panic>
    panic("sched locks");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	21e50513          	addi	a0,a0,542 # 80008228 <digits+0x1e8>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	528080e7          	jalr	1320(ra) # 8000053a <panic>
    panic("sched running");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	21e50513          	addi	a0,a0,542 # 80008238 <digits+0x1f8>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	518080e7          	jalr	1304(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	21e50513          	addi	a0,a0,542 # 80008248 <digits+0x208>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	508080e7          	jalr	1288(ra) # 8000053a <panic>

000000008000203a <yield>:
{
    8000203a:	1101                	addi	sp,sp,-32
    8000203c:	ec06                	sd	ra,24(sp)
    8000203e:	e822                	sd	s0,16(sp)
    80002040:	e426                	sd	s1,8(sp)
    80002042:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	952080e7          	jalr	-1710(ra) # 80001996 <myproc>
    8000204c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b82080e7          	jalr	-1150(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002056:	478d                	li	a5,3
    80002058:	cc9c                	sw	a5,24(s1)
  sched();
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	f0a080e7          	jalr	-246(ra) # 80001f64 <sched>
  release(&p->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c20080e7          	jalr	-992(ra) # 80000c84 <release>
}
    8000206c:	60e2                	ld	ra,24(sp)
    8000206e:	6442                	ld	s0,16(sp)
    80002070:	64a2                	ld	s1,8(sp)
    80002072:	6105                	addi	sp,sp,32
    80002074:	8082                	ret

0000000080002076 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	89aa                	mv	s3,a0
    80002086:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	90e080e7          	jalr	-1778(ra) # 80001996 <myproc>
    80002090:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b3e080e7          	jalr	-1218(ra) # 80000bd0 <acquire>
  release(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	be8080e7          	jalr	-1048(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    800020a4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a8:	4789                	li	a5,2
    800020aa:	cc9c                	sw	a5,24(s1)

  sched();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	eb8080e7          	jalr	-328(ra) # 80001f64 <sched>

  // Tidy up.
  p->chan = 0;
    800020b4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bca080e7          	jalr	-1078(ra) # 80000c84 <release>
  acquire(lk);
    800020c2:	854a                	mv	a0,s2
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b0c080e7          	jalr	-1268(ra) # 80000bd0 <acquire>
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret

00000000800020da <wait>:
{
    800020da:	715d                	addi	sp,sp,-80
    800020dc:	e486                	sd	ra,72(sp)
    800020de:	e0a2                	sd	s0,64(sp)
    800020e0:	fc26                	sd	s1,56(sp)
    800020e2:	f84a                	sd	s2,48(sp)
    800020e4:	f44e                	sd	s3,40(sp)
    800020e6:	f052                	sd	s4,32(sp)
    800020e8:	ec56                	sd	s5,24(sp)
    800020ea:	e85a                	sd	s6,16(sp)
    800020ec:	e45e                	sd	s7,8(sp)
    800020ee:	e062                	sd	s8,0(sp)
    800020f0:	0880                	addi	s0,sp,80
    800020f2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8a2080e7          	jalr	-1886(ra) # 80001996 <myproc>
    800020fc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020fe:	0000f517          	auipc	a0,0xf
    80002102:	1ba50513          	addi	a0,a0,442 # 800112b8 <wait_lock>
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	aca080e7          	jalr	-1334(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000210e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002110:	4a15                	li	s4,5
        havekids = 1;
    80002112:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002114:	00016997          	auipc	s3,0x16
    80002118:	9bc98993          	addi	s3,s3,-1604 # 80017ad0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000211c:	0000fc17          	auipc	s8,0xf
    80002120:	19cc0c13          	addi	s8,s8,412 # 800112b8 <wait_lock>
    havekids = 0;
    80002124:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002126:	0000f497          	auipc	s1,0xf
    8000212a:	5aa48493          	addi	s1,s1,1450 # 800116d0 <proc>
    8000212e:	a0bd                	j	8000219c <wait+0xc2>
          pid = np->pid;
    80002130:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002134:	000b0e63          	beqz	s6,80002150 <wait+0x76>
    80002138:	4691                	li	a3,4
    8000213a:	02c48613          	addi	a2,s1,44
    8000213e:	85da                	mv	a1,s6
    80002140:	05093503          	ld	a0,80(s2)
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	516080e7          	jalr	1302(ra) # 8000165a <copyout>
    8000214c:	02054563          	bltz	a0,80002176 <wait+0x9c>
          freeproc(np);
    80002150:	8526                	mv	a0,s1
    80002152:	00000097          	auipc	ra,0x0
    80002156:	9f6080e7          	jalr	-1546(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
          release(&wait_lock);
    80002164:	0000f517          	auipc	a0,0xf
    80002168:	15450513          	addi	a0,a0,340 # 800112b8 <wait_lock>
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b18080e7          	jalr	-1256(ra) # 80000c84 <release>
          return pid;
    80002174:	a09d                	j	800021da <wait+0x100>
            release(&np->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b0c080e7          	jalr	-1268(ra) # 80000c84 <release>
            release(&wait_lock);
    80002180:	0000f517          	auipc	a0,0xf
    80002184:	13850513          	addi	a0,a0,312 # 800112b8 <wait_lock>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	afc080e7          	jalr	-1284(ra) # 80000c84 <release>
            return -1;
    80002190:	59fd                	li	s3,-1
    80002192:	a0a1                	j	800021da <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002194:	19048493          	addi	s1,s1,400
    80002198:	03348463          	beq	s1,s3,800021c0 <wait+0xe6>
      if(np->parent == p){
    8000219c:	7c9c                	ld	a5,56(s1)
    8000219e:	ff279be3          	bne	a5,s2,80002194 <wait+0xba>
        acquire(&np->lock);
    800021a2:	8526                	mv	a0,s1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a2c080e7          	jalr	-1492(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    800021ac:	4c9c                	lw	a5,24(s1)
    800021ae:	f94781e3          	beq	a5,s4,80002130 <wait+0x56>
        release(&np->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ad0080e7          	jalr	-1328(ra) # 80000c84 <release>
        havekids = 1;
    800021bc:	8756                	mv	a4,s5
    800021be:	bfd9                	j	80002194 <wait+0xba>
    if(!havekids || p->killed){
    800021c0:	c701                	beqz	a4,800021c8 <wait+0xee>
    800021c2:	02892783          	lw	a5,40(s2)
    800021c6:	c79d                	beqz	a5,800021f4 <wait+0x11a>
      release(&wait_lock);
    800021c8:	0000f517          	auipc	a0,0xf
    800021cc:	0f050513          	addi	a0,a0,240 # 800112b8 <wait_lock>
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	ab4080e7          	jalr	-1356(ra) # 80000c84 <release>
      return -1;
    800021d8:	59fd                	li	s3,-1
}
    800021da:	854e                	mv	a0,s3
    800021dc:	60a6                	ld	ra,72(sp)
    800021de:	6406                	ld	s0,64(sp)
    800021e0:	74e2                	ld	s1,56(sp)
    800021e2:	7942                	ld	s2,48(sp)
    800021e4:	79a2                	ld	s3,40(sp)
    800021e6:	7a02                	ld	s4,32(sp)
    800021e8:	6ae2                	ld	s5,24(sp)
    800021ea:	6b42                	ld	s6,16(sp)
    800021ec:	6ba2                	ld	s7,8(sp)
    800021ee:	6c02                	ld	s8,0(sp)
    800021f0:	6161                	addi	sp,sp,80
    800021f2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021f4:	85e2                	mv	a1,s8
    800021f6:	854a                	mv	a0,s2
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	e7e080e7          	jalr	-386(ra) # 80002076 <sleep>
    havekids = 0;
    80002200:	b715                	j	80002124 <wait+0x4a>

0000000080002202 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002202:	7139                	addi	sp,sp,-64
    80002204:	fc06                	sd	ra,56(sp)
    80002206:	f822                	sd	s0,48(sp)
    80002208:	f426                	sd	s1,40(sp)
    8000220a:	f04a                	sd	s2,32(sp)
    8000220c:	ec4e                	sd	s3,24(sp)
    8000220e:	e852                	sd	s4,16(sp)
    80002210:	e456                	sd	s5,8(sp)
    80002212:	0080                	addi	s0,sp,64
    80002214:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002216:	0000f497          	auipc	s1,0xf
    8000221a:	4ba48493          	addi	s1,s1,1210 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000221e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002220:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002222:	00016917          	auipc	s2,0x16
    80002226:	8ae90913          	addi	s2,s2,-1874 # 80017ad0 <tickslock>
    8000222a:	a811                	j	8000223e <wakeup+0x3c>
      }
      release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002236:	19048493          	addi	s1,s1,400
    8000223a:	03248663          	beq	s1,s2,80002266 <wakeup+0x64>
    if(p != myproc()){
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	758080e7          	jalr	1880(ra) # 80001996 <myproc>
    80002246:	fea488e3          	beq	s1,a0,80002236 <wakeup+0x34>
      acquire(&p->lock);
    8000224a:	8526                	mv	a0,s1
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	984080e7          	jalr	-1660(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002254:	4c9c                	lw	a5,24(s1)
    80002256:	fd379be3          	bne	a5,s3,8000222c <wakeup+0x2a>
    8000225a:	709c                	ld	a5,32(s1)
    8000225c:	fd4798e3          	bne	a5,s4,8000222c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002260:	0154ac23          	sw	s5,24(s1)
    80002264:	b7e1                	j	8000222c <wakeup+0x2a>
    }
  }
}
    80002266:	70e2                	ld	ra,56(sp)
    80002268:	7442                	ld	s0,48(sp)
    8000226a:	74a2                	ld	s1,40(sp)
    8000226c:	7902                	ld	s2,32(sp)
    8000226e:	69e2                	ld	s3,24(sp)
    80002270:	6a42                	ld	s4,16(sp)
    80002272:	6aa2                	ld	s5,8(sp)
    80002274:	6121                	addi	sp,sp,64
    80002276:	8082                	ret

0000000080002278 <reparent>:
{
    80002278:	7179                	addi	sp,sp,-48
    8000227a:	f406                	sd	ra,40(sp)
    8000227c:	f022                	sd	s0,32(sp)
    8000227e:	ec26                	sd	s1,24(sp)
    80002280:	e84a                	sd	s2,16(sp)
    80002282:	e44e                	sd	s3,8(sp)
    80002284:	e052                	sd	s4,0(sp)
    80002286:	1800                	addi	s0,sp,48
    80002288:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000228a:	0000f497          	auipc	s1,0xf
    8000228e:	44648493          	addi	s1,s1,1094 # 800116d0 <proc>
      pp->parent = initproc;
    80002292:	00007a17          	auipc	s4,0x7
    80002296:	d96a0a13          	addi	s4,s4,-618 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000229a:	00016997          	auipc	s3,0x16
    8000229e:	83698993          	addi	s3,s3,-1994 # 80017ad0 <tickslock>
    800022a2:	a029                	j	800022ac <reparent+0x34>
    800022a4:	19048493          	addi	s1,s1,400
    800022a8:	01348d63          	beq	s1,s3,800022c2 <reparent+0x4a>
    if(pp->parent == p){
    800022ac:	7c9c                	ld	a5,56(s1)
    800022ae:	ff279be3          	bne	a5,s2,800022a4 <reparent+0x2c>
      pp->parent = initproc;
    800022b2:	000a3503          	ld	a0,0(s4)
    800022b6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	f4a080e7          	jalr	-182(ra) # 80002202 <wakeup>
    800022c0:	b7d5                	j	800022a4 <reparent+0x2c>
}
    800022c2:	70a2                	ld	ra,40(sp)
    800022c4:	7402                	ld	s0,32(sp)
    800022c6:	64e2                	ld	s1,24(sp)
    800022c8:	6942                	ld	s2,16(sp)
    800022ca:	69a2                	ld	s3,8(sp)
    800022cc:	6a02                	ld	s4,0(sp)
    800022ce:	6145                	addi	sp,sp,48
    800022d0:	8082                	ret

00000000800022d2 <exit>:
{
    800022d2:	7179                	addi	sp,sp,-48
    800022d4:	f406                	sd	ra,40(sp)
    800022d6:	f022                	sd	s0,32(sp)
    800022d8:	ec26                	sd	s1,24(sp)
    800022da:	e84a                	sd	s2,16(sp)
    800022dc:	e44e                	sd	s3,8(sp)
    800022de:	e052                	sd	s4,0(sp)
    800022e0:	1800                	addi	s0,sp,48
    800022e2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	6b2080e7          	jalr	1714(ra) # 80001996 <myproc>
    800022ec:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ee:	00007797          	auipc	a5,0x7
    800022f2:	d3a7b783          	ld	a5,-710(a5) # 80009028 <initproc>
    800022f6:	0d050493          	addi	s1,a0,208
    800022fa:	15050913          	addi	s2,a0,336
    800022fe:	02a79363          	bne	a5,a0,80002324 <exit+0x52>
    panic("init exiting");
    80002302:	00006517          	auipc	a0,0x6
    80002306:	f5e50513          	addi	a0,a0,-162 # 80008260 <digits+0x220>
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	230080e7          	jalr	560(ra) # 8000053a <panic>
      fileclose(f);
    80002312:	00002097          	auipc	ra,0x2
    80002316:	440080e7          	jalr	1088(ra) # 80004752 <fileclose>
      p->ofile[fd] = 0;
    8000231a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000231e:	04a1                	addi	s1,s1,8
    80002320:	01248563          	beq	s1,s2,8000232a <exit+0x58>
    if(p->ofile[fd]){
    80002324:	6088                	ld	a0,0(s1)
    80002326:	f575                	bnez	a0,80002312 <exit+0x40>
    80002328:	bfdd                	j	8000231e <exit+0x4c>
  begin_op();
    8000232a:	00002097          	auipc	ra,0x2
    8000232e:	f60080e7          	jalr	-160(ra) # 8000428a <begin_op>
  iput(p->cwd);
    80002332:	1509b503          	ld	a0,336(s3)
    80002336:	00001097          	auipc	ra,0x1
    8000233a:	732080e7          	jalr	1842(ra) # 80003a68 <iput>
  end_op();
    8000233e:	00002097          	auipc	ra,0x2
    80002342:	fca080e7          	jalr	-54(ra) # 80004308 <end_op>
  p->cwd = 0;
    80002346:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000234a:	0000f497          	auipc	s1,0xf
    8000234e:	f6e48493          	addi	s1,s1,-146 # 800112b8 <wait_lock>
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87c080e7          	jalr	-1924(ra) # 80000bd0 <acquire>
  reparent(p);
    8000235c:	854e                	mv	a0,s3
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	f1a080e7          	jalr	-230(ra) # 80002278 <reparent>
  wakeup(p->parent);
    80002366:	0389b503          	ld	a0,56(s3)
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	e98080e7          	jalr	-360(ra) # 80002202 <wakeup>
  acquire(&p->lock);
    80002372:	854e                	mv	a0,s3
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	85c080e7          	jalr	-1956(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000237c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002380:	4795                	li	a5,5
    80002382:	00f9ac23          	sw	a5,24(s3)
  p->exit_time = ticks;
    80002386:	00007797          	auipc	a5,0x7
    8000238a:	caa7e783          	lwu	a5,-854(a5) # 80009030 <ticks>
    8000238e:	18f9b423          	sd	a5,392(s3)
  release(&wait_lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	8f0080e7          	jalr	-1808(ra) # 80000c84 <release>
  sched();
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	bc8080e7          	jalr	-1080(ra) # 80001f64 <sched>
  panic("zombie exit");
    800023a4:	00006517          	auipc	a0,0x6
    800023a8:	ecc50513          	addi	a0,a0,-308 # 80008270 <digits+0x230>
    800023ac:	ffffe097          	auipc	ra,0xffffe
    800023b0:	18e080e7          	jalr	398(ra) # 8000053a <panic>

00000000800023b4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b4:	7179                	addi	sp,sp,-48
    800023b6:	f406                	sd	ra,40(sp)
    800023b8:	f022                	sd	s0,32(sp)
    800023ba:	ec26                	sd	s1,24(sp)
    800023bc:	e84a                	sd	s2,16(sp)
    800023be:	e44e                	sd	s3,8(sp)
    800023c0:	1800                	addi	s0,sp,48
    800023c2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c4:	0000f497          	auipc	s1,0xf
    800023c8:	30c48493          	addi	s1,s1,780 # 800116d0 <proc>
    800023cc:	00015997          	auipc	s3,0x15
    800023d0:	70498993          	addi	s3,s3,1796 # 80017ad0 <tickslock>
    acquire(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	7fa080e7          	jalr	2042(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023de:	589c                	lw	a5,48(s1)
    800023e0:	01278d63          	beq	a5,s2,800023fa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	89e080e7          	jalr	-1890(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ee:	19048493          	addi	s1,s1,400
    800023f2:	ff3491e3          	bne	s1,s3,800023d4 <kill+0x20>
  }
  return -1;
    800023f6:	557d                	li	a0,-1
    800023f8:	a829                	j	80002412 <kill+0x5e>
      p->killed = 1;
    800023fa:	4785                	li	a5,1
    800023fc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023fe:	4c98                	lw	a4,24(s1)
    80002400:	4789                	li	a5,2
    80002402:	00f70f63          	beq	a4,a5,80002420 <kill+0x6c>
      release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	87c080e7          	jalr	-1924(ra) # 80000c84 <release>
      return 0;
    80002410:	4501                	li	a0,0
}
    80002412:	70a2                	ld	ra,40(sp)
    80002414:	7402                	ld	s0,32(sp)
    80002416:	64e2                	ld	s1,24(sp)
    80002418:	6942                	ld	s2,16(sp)
    8000241a:	69a2                	ld	s3,8(sp)
    8000241c:	6145                	addi	sp,sp,48
    8000241e:	8082                	ret
        p->state = RUNNABLE;
    80002420:	478d                	li	a5,3
    80002422:	cc9c                	sw	a5,24(s1)
    80002424:	b7cd                	j	80002406 <kill+0x52>

0000000080002426 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	e052                	sd	s4,0(sp)
    80002434:	1800                	addi	s0,sp,48
    80002436:	84aa                	mv	s1,a0
    80002438:	892e                	mv	s2,a1
    8000243a:	89b2                	mv	s3,a2
    8000243c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	558080e7          	jalr	1368(ra) # 80001996 <myproc>
  if(user_dst){
    80002446:	c08d                	beqz	s1,80002468 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002448:	86d2                	mv	a3,s4
    8000244a:	864e                	mv	a2,s3
    8000244c:	85ca                	mv	a1,s2
    8000244e:	6928                	ld	a0,80(a0)
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	20a080e7          	jalr	522(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002458:	70a2                	ld	ra,40(sp)
    8000245a:	7402                	ld	s0,32(sp)
    8000245c:	64e2                	ld	s1,24(sp)
    8000245e:	6942                	ld	s2,16(sp)
    80002460:	69a2                	ld	s3,8(sp)
    80002462:	6a02                	ld	s4,0(sp)
    80002464:	6145                	addi	sp,sp,48
    80002466:	8082                	ret
    memmove((char *)dst, src, len);
    80002468:	000a061b          	sext.w	a2,s4
    8000246c:	85ce                	mv	a1,s3
    8000246e:	854a                	mv	a0,s2
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	8b8080e7          	jalr	-1864(ra) # 80000d28 <memmove>
    return 0;
    80002478:	8526                	mv	a0,s1
    8000247a:	bff9                	j	80002458 <either_copyout+0x32>

000000008000247c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	892a                	mv	s2,a0
    8000248e:	84ae                	mv	s1,a1
    80002490:	89b2                	mv	s3,a2
    80002492:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	502080e7          	jalr	1282(ra) # 80001996 <myproc>
  if(user_src){
    8000249c:	c08d                	beqz	s1,800024be <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000249e:	86d2                	mv	a3,s4
    800024a0:	864e                	mv	a2,s3
    800024a2:	85ca                	mv	a1,s2
    800024a4:	6928                	ld	a0,80(a0)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	240080e7          	jalr	576(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6a02                	ld	s4,0(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
    memmove(dst, (char*)src, len);
    800024be:	000a061b          	sext.w	a2,s4
    800024c2:	85ce                	mv	a1,s3
    800024c4:	854a                	mv	a0,s2
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	862080e7          	jalr	-1950(ra) # 80000d28 <memmove>
    return 0;
    800024ce:	8526                	mv	a0,s1
    800024d0:	bff9                	j	800024ae <either_copyin+0x32>

00000000800024d2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024d2:	715d                	addi	sp,sp,-80
    800024d4:	e486                	sd	ra,72(sp)
    800024d6:	e0a2                	sd	s0,64(sp)
    800024d8:	fc26                	sd	s1,56(sp)
    800024da:	f84a                	sd	s2,48(sp)
    800024dc:	f44e                	sd	s3,40(sp)
    800024de:	f052                	sd	s4,32(sp)
    800024e0:	ec56                	sd	s5,24(sp)
    800024e2:	e85a                	sd	s6,16(sp)
    800024e4:	e45e                	sd	s7,8(sp)
    800024e6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024e8:	00006517          	auipc	a0,0x6
    800024ec:	be050513          	addi	a0,a0,-1056 # 800080c8 <digits+0x88>
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	094080e7          	jalr	148(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f8:	0000f497          	auipc	s1,0xf
    800024fc:	33048493          	addi	s1,s1,816 # 80011828 <proc+0x158>
    80002500:	00015917          	auipc	s2,0x15
    80002504:	72890913          	addi	s2,s2,1832 # 80017c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002508:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000250a:	00006997          	auipc	s3,0x6
    8000250e:	d7698993          	addi	s3,s3,-650 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002512:	00006a97          	auipc	s5,0x6
    80002516:	d76a8a93          	addi	s5,s5,-650 # 80008288 <digits+0x248>
    printf("\n");
    8000251a:	00006a17          	auipc	s4,0x6
    8000251e:	baea0a13          	addi	s4,s4,-1106 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002522:	00006b97          	auipc	s7,0x6
    80002526:	d9eb8b93          	addi	s7,s7,-610 # 800082c0 <states.0>
    8000252a:	a00d                	j	8000254c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000252c:	ed86a583          	lw	a1,-296(a3)
    80002530:	8556                	mv	a0,s5
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	052080e7          	jalr	82(ra) # 80000584 <printf>
    printf("\n");
    8000253a:	8552                	mv	a0,s4
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	048080e7          	jalr	72(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002544:	19048493          	addi	s1,s1,400
    80002548:	03248263          	beq	s1,s2,8000256c <procdump+0x9a>
    if(p->state == UNUSED)
    8000254c:	86a6                	mv	a3,s1
    8000254e:	ec04a783          	lw	a5,-320(s1)
    80002552:	dbed                	beqz	a5,80002544 <procdump+0x72>
      state = "???";
    80002554:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002556:	fcfb6be3          	bltu	s6,a5,8000252c <procdump+0x5a>
    8000255a:	02079713          	slli	a4,a5,0x20
    8000255e:	01d75793          	srli	a5,a4,0x1d
    80002562:	97de                	add	a5,a5,s7
    80002564:	6390                	ld	a2,0(a5)
    80002566:	f279                	bnez	a2,8000252c <procdump+0x5a>
      state = "???";
    80002568:	864e                	mv	a2,s3
    8000256a:	b7c9                	j	8000252c <procdump+0x5a>
 }
}
    8000256c:	60a6                	ld	ra,72(sp)
    8000256e:	6406                	ld	s0,64(sp)
    80002570:	74e2                	ld	s1,56(sp)
    80002572:	7942                	ld	s2,48(sp)
    80002574:	79a2                	ld	s3,40(sp)
    80002576:	7a02                	ld	s4,32(sp)
    80002578:	6ae2                	ld	s5,24(sp)
    8000257a:	6b42                	ld	s6,16(sp)
    8000257c:	6ba2                	ld	s7,8(sp)
    8000257e:	6161                	addi	sp,sp,80
    80002580:	8082                	ret

0000000080002582 <update_timings>:

void
update_timings(void)
{
    80002582:	7139                	addi	sp,sp,-64
    80002584:	fc06                	sd	ra,56(sp)
    80002586:	f822                	sd	s0,48(sp)
    80002588:	f426                	sd	s1,40(sp)
    8000258a:	f04a                	sd	s2,32(sp)
    8000258c:	ec4e                	sd	s3,24(sp)
    8000258e:	e852                	sd	s4,16(sp)
    80002590:	e456                	sd	s5,8(sp)
    80002592:	0080                	addi	s0,sp,64
  struct proc* p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002594:	0000f497          	auipc	s1,0xf
    80002598:	13c48493          	addi	s1,s1,316 # 800116d0 <proc>
  {
    acquire(&p->lock);

    if(p->state == RUNNING){
    8000259c:	4991                	li	s3,4
      p->run_time += 1;
    }
	else if(p->state == RUNNABLE) {
    8000259e:	4a0d                	li	s4,3
	  p->wait_time += 1;
	} else if(p->state == SLEEPING){
    800025a0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++)
    800025a2:	00015917          	auipc	s2,0x15
    800025a6:	52e90913          	addi	s2,s2,1326 # 80017ad0 <tickslock>
    800025aa:	a839                	j	800025c8 <update_timings+0x46>
      p->run_time += 1;
    800025ac:	1704b783          	ld	a5,368(s1)
    800025b0:	0785                	addi	a5,a5,1
    800025b2:	16f4b823          	sd	a5,368(s1)
      p->sleep_time += 1;
    }

    release(&p->lock);
    800025b6:	8526                	mv	a0,s1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	6cc080e7          	jalr	1740(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    800025c0:	19048493          	addi	s1,s1,400
    800025c4:	03248a63          	beq	s1,s2,800025f8 <update_timings+0x76>
    acquire(&p->lock);
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	606080e7          	jalr	1542(ra) # 80000bd0 <acquire>
    if(p->state == RUNNING){
    800025d2:	4c9c                	lw	a5,24(s1)
    800025d4:	fd378ce3          	beq	a5,s3,800025ac <update_timings+0x2a>
	else if(p->state == RUNNABLE) {
    800025d8:	01478a63          	beq	a5,s4,800025ec <update_timings+0x6a>
	} else if(p->state == SLEEPING){
    800025dc:	fd579de3          	bne	a5,s5,800025b6 <update_timings+0x34>
      p->sleep_time += 1;
    800025e0:	1804b783          	ld	a5,384(s1)
    800025e4:	0785                	addi	a5,a5,1
    800025e6:	18f4b023          	sd	a5,384(s1)
    800025ea:	b7f1                	j	800025b6 <update_timings+0x34>
	  p->wait_time += 1;
    800025ec:	1784b783          	ld	a5,376(s1)
    800025f0:	0785                	addi	a5,a5,1
    800025f2:	16f4bc23          	sd	a5,376(s1)
    800025f6:	b7c1                	j	800025b6 <update_timings+0x34>
  }
}
    800025f8:	70e2                	ld	ra,56(sp)
    800025fa:	7442                	ld	s0,48(sp)
    800025fc:	74a2                	ld	s1,40(sp)
    800025fe:	7902                	ld	s2,32(sp)
    80002600:	69e2                	ld	s3,24(sp)
    80002602:	6a42                	ld	s4,16(sp)
    80002604:	6aa2                	ld	s5,8(sp)
    80002606:	6121                	addi	sp,sp,64
    80002608:	8082                	ret

000000008000260a <wait2>:

int
wait2(uint64 addr, uint* run, uint* wait, uint* sleepTime)
{
    8000260a:	7159                	addi	sp,sp,-112
    8000260c:	f486                	sd	ra,104(sp)
    8000260e:	f0a2                	sd	s0,96(sp)
    80002610:	eca6                	sd	s1,88(sp)
    80002612:	e8ca                	sd	s2,80(sp)
    80002614:	e4ce                	sd	s3,72(sp)
    80002616:	e0d2                	sd	s4,64(sp)
    80002618:	fc56                	sd	s5,56(sp)
    8000261a:	f85a                	sd	s6,48(sp)
    8000261c:	f45e                	sd	s7,40(sp)
    8000261e:	f062                	sd	s8,32(sp)
    80002620:	ec66                	sd	s9,24(sp)
    80002622:	e86a                	sd	s10,16(sp)
    80002624:	e46e                	sd	s11,8(sp)
    80002626:	1880                	addi	s0,sp,112
    80002628:	8b2a                	mv	s6,a0
    8000262a:	8cae                	mv	s9,a1
    8000262c:	8c32                	mv	s8,a2
    8000262e:	8bb6                	mv	s7,a3
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	366080e7          	jalr	870(ra) # 80001996 <myproc>
    80002638:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000263a:	0000f517          	auipc	a0,0xf
    8000263e:	c7e50513          	addi	a0,a0,-898 # 800112b8 <wait_lock>
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	58e080e7          	jalr	1422(ra) # 80000bd0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    8000264a:	4d01                	li	s10,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    8000264c:	4a15                	li	s4,5
        havekids = 1;
    8000264e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002650:	00015997          	auipc	s3,0x15
    80002654:	48098993          	addi	s3,s3,1152 # 80017ad0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002658:	0000fd97          	auipc	s11,0xf
    8000265c:	c60d8d93          	addi	s11,s11,-928 # 800112b8 <wait_lock>
    havekids = 0;
    80002660:	876a                	mv	a4,s10
    for(np = proc; np < &proc[NPROC]; np++){
    80002662:	0000f497          	auipc	s1,0xf
    80002666:	06e48493          	addi	s1,s1,110 # 800116d0 <proc>
    8000266a:	a059                	j	800026f0 <wait2+0xe6>
          pid = np->pid;
    8000266c:	0304a983          	lw	s3,48(s1)
	  *run = np->run_time;
    80002670:	1704b783          	ld	a5,368(s1)
    80002674:	00fca023          	sw	a5,0(s9)
	  *wait = np->wait_time;
    80002678:	1784b783          	ld	a5,376(s1)
    8000267c:	00fc2023          	sw	a5,0(s8)
	  *sleepTime = np->sleep_time;
    80002680:	1804b783          	ld	a5,384(s1)
    80002684:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002688:	000b0e63          	beqz	s6,800026a4 <wait2+0x9a>
    8000268c:	4691                	li	a3,4
    8000268e:	02c48613          	addi	a2,s1,44
    80002692:	85da                	mv	a1,s6
    80002694:	05093503          	ld	a0,80(s2)
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	fc2080e7          	jalr	-62(ra) # 8000165a <copyout>
    800026a0:	02054563          	bltz	a0,800026ca <wait2+0xc0>
          freeproc(np);
    800026a4:	8526                	mv	a0,s1
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	4a2080e7          	jalr	1186(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5d4080e7          	jalr	1492(ra) # 80000c84 <release>
          release(&wait_lock);
    800026b8:	0000f517          	auipc	a0,0xf
    800026bc:	c0050513          	addi	a0,a0,-1024 # 800112b8 <wait_lock>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5c4080e7          	jalr	1476(ra) # 80000c84 <release>
          return pid;
    800026c8:	a09d                	j	8000272e <wait2+0x124>
            release(&np->lock);
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	5b8080e7          	jalr	1464(ra) # 80000c84 <release>
            release(&wait_lock);
    800026d4:	0000f517          	auipc	a0,0xf
    800026d8:	be450513          	addi	a0,a0,-1052 # 800112b8 <wait_lock>
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	5a8080e7          	jalr	1448(ra) # 80000c84 <release>
            return -1;
    800026e4:	59fd                	li	s3,-1
    800026e6:	a0a1                	j	8000272e <wait2+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    800026e8:	19048493          	addi	s1,s1,400
    800026ec:	03348463          	beq	s1,s3,80002714 <wait2+0x10a>
      if(np->parent == p){
    800026f0:	7c9c                	ld	a5,56(s1)
    800026f2:	ff279be3          	bne	a5,s2,800026e8 <wait2+0xde>
        acquire(&np->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	4d8080e7          	jalr	1240(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002700:	4c9c                	lw	a5,24(s1)
    80002702:	f74785e3          	beq	a5,s4,8000266c <wait2+0x62>
        release(&np->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	57c080e7          	jalr	1404(ra) # 80000c84 <release>
        havekids = 1;
    80002710:	8756                	mv	a4,s5
    80002712:	bfd9                	j	800026e8 <wait2+0xde>
    if(!havekids || p->killed){
    80002714:	c701                	beqz	a4,8000271c <wait2+0x112>
    80002716:	02892783          	lw	a5,40(s2)
    8000271a:	cb95                	beqz	a5,8000274e <wait2+0x144>
      release(&wait_lock);
    8000271c:	0000f517          	auipc	a0,0xf
    80002720:	b9c50513          	addi	a0,a0,-1124 # 800112b8 <wait_lock>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	560080e7          	jalr	1376(ra) # 80000c84 <release>
      return -1;
    8000272c:	59fd                	li	s3,-1
  }
}
    8000272e:	854e                	mv	a0,s3
    80002730:	70a6                	ld	ra,104(sp)
    80002732:	7406                	ld	s0,96(sp)
    80002734:	64e6                	ld	s1,88(sp)
    80002736:	6946                	ld	s2,80(sp)
    80002738:	69a6                	ld	s3,72(sp)
    8000273a:	6a06                	ld	s4,64(sp)
    8000273c:	7ae2                	ld	s5,56(sp)
    8000273e:	7b42                	ld	s6,48(sp)
    80002740:	7ba2                	ld	s7,40(sp)
    80002742:	7c02                	ld	s8,32(sp)
    80002744:	6ce2                	ld	s9,24(sp)
    80002746:	6d42                	ld	s10,16(sp)
    80002748:	6da2                	ld	s11,8(sp)
    8000274a:	6165                	addi	sp,sp,112
    8000274c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000274e:	85ee                	mv	a1,s11
    80002750:	854a                	mv	a0,s2
    80002752:	00000097          	auipc	ra,0x0
    80002756:	924080e7          	jalr	-1756(ra) # 80002076 <sleep>
    havekids = 0;
    8000275a:	b719                	j	80002660 <wait2+0x56>

000000008000275c <swtch>:
    8000275c:	00153023          	sd	ra,0(a0)
    80002760:	00253423          	sd	sp,8(a0)
    80002764:	e900                	sd	s0,16(a0)
    80002766:	ed04                	sd	s1,24(a0)
    80002768:	03253023          	sd	s2,32(a0)
    8000276c:	03353423          	sd	s3,40(a0)
    80002770:	03453823          	sd	s4,48(a0)
    80002774:	03553c23          	sd	s5,56(a0)
    80002778:	05653023          	sd	s6,64(a0)
    8000277c:	05753423          	sd	s7,72(a0)
    80002780:	05853823          	sd	s8,80(a0)
    80002784:	05953c23          	sd	s9,88(a0)
    80002788:	07a53023          	sd	s10,96(a0)
    8000278c:	07b53423          	sd	s11,104(a0)
    80002790:	0005b083          	ld	ra,0(a1)
    80002794:	0085b103          	ld	sp,8(a1)
    80002798:	6980                	ld	s0,16(a1)
    8000279a:	6d84                	ld	s1,24(a1)
    8000279c:	0205b903          	ld	s2,32(a1)
    800027a0:	0285b983          	ld	s3,40(a1)
    800027a4:	0305ba03          	ld	s4,48(a1)
    800027a8:	0385ba83          	ld	s5,56(a1)
    800027ac:	0405bb03          	ld	s6,64(a1)
    800027b0:	0485bb83          	ld	s7,72(a1)
    800027b4:	0505bc03          	ld	s8,80(a1)
    800027b8:	0585bc83          	ld	s9,88(a1)
    800027bc:	0605bd03          	ld	s10,96(a1)
    800027c0:	0685bd83          	ld	s11,104(a1)
    800027c4:	8082                	ret

00000000800027c6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027c6:	1141                	addi	sp,sp,-16
    800027c8:	e406                	sd	ra,8(sp)
    800027ca:	e022                	sd	s0,0(sp)
    800027cc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ce:	00006597          	auipc	a1,0x6
    800027d2:	b2258593          	addi	a1,a1,-1246 # 800082f0 <states.0+0x30>
    800027d6:	00015517          	auipc	a0,0x15
    800027da:	2fa50513          	addi	a0,a0,762 # 80017ad0 <tickslock>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	362080e7          	jalr	866(ra) # 80000b40 <initlock>
}
    800027e6:	60a2                	ld	ra,8(sp)
    800027e8:	6402                	ld	s0,0(sp)
    800027ea:	0141                	addi	sp,sp,16
    800027ec:	8082                	ret

00000000800027ee <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ee:	1141                	addi	sp,sp,-16
    800027f0:	e422                	sd	s0,8(sp)
    800027f2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f4:	00003797          	auipc	a5,0x3
    800027f8:	58c78793          	addi	a5,a5,1420 # 80005d80 <kernelvec>
    800027fc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002800:	6422                	ld	s0,8(sp)
    80002802:	0141                	addi	sp,sp,16
    80002804:	8082                	ret

0000000080002806 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002806:	1141                	addi	sp,sp,-16
    80002808:	e406                	sd	ra,8(sp)
    8000280a:	e022                	sd	s0,0(sp)
    8000280c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	188080e7          	jalr	392(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002816:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000281a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002820:	00004697          	auipc	a3,0x4
    80002824:	7e068693          	addi	a3,a3,2016 # 80007000 <_trampoline>
    80002828:	00004717          	auipc	a4,0x4
    8000282c:	7d870713          	addi	a4,a4,2008 # 80007000 <_trampoline>
    80002830:	8f15                	sub	a4,a4,a3
    80002832:	040007b7          	lui	a5,0x4000
    80002836:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002838:	07b2                	slli	a5,a5,0xc
    8000283a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283c:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002840:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002842:	18002673          	csrr	a2,satp
    80002846:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002848:	6d30                	ld	a2,88(a0)
    8000284a:	6138                	ld	a4,64(a0)
    8000284c:	6585                	lui	a1,0x1
    8000284e:	972e                	add	a4,a4,a1
    80002850:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002852:	6d38                	ld	a4,88(a0)
    80002854:	00000617          	auipc	a2,0x0
    80002858:	14660613          	addi	a2,a2,326 # 8000299a <usertrap>
    8000285c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000285e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002860:	8612                	mv	a2,tp
    80002862:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002864:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002868:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000286c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002874:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002876:	6f18                	ld	a4,24(a4)
    80002878:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000287c:	692c                	ld	a1,80(a0)
    8000287e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002880:	00005717          	auipc	a4,0x5
    80002884:	81070713          	addi	a4,a4,-2032 # 80007090 <userret>
    80002888:	8f15                	sub	a4,a4,a3
    8000288a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000288c:	577d                	li	a4,-1
    8000288e:	177e                	slli	a4,a4,0x3f
    80002890:	8dd9                	or	a1,a1,a4
    80002892:	02000537          	lui	a0,0x2000
    80002896:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002898:	0536                	slli	a0,a0,0xd
    8000289a:	9782                	jalr	a5
}
    8000289c:	60a2                	ld	ra,8(sp)
    8000289e:	6402                	ld	s0,0(sp)
    800028a0:	0141                	addi	sp,sp,16
    800028a2:	8082                	ret

00000000800028a4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028a4:	1101                	addi	sp,sp,-32
    800028a6:	ec06                	sd	ra,24(sp)
    800028a8:	e822                	sd	s0,16(sp)
    800028aa:	e426                	sd	s1,8(sp)
    800028ac:	e04a                	sd	s2,0(sp)
    800028ae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028b0:	00015917          	auipc	s2,0x15
    800028b4:	22090913          	addi	s2,s2,544 # 80017ad0 <tickslock>
    800028b8:	854a                	mv	a0,s2
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	316080e7          	jalr	790(ra) # 80000bd0 <acquire>
  ticks++;
    800028c2:	00006497          	auipc	s1,0x6
    800028c6:	76e48493          	addi	s1,s1,1902 # 80009030 <ticks>
    800028ca:	409c                	lw	a5,0(s1)
    800028cc:	2785                	addiw	a5,a5,1
    800028ce:	c09c                	sw	a5,0(s1)
  update_timings();
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	cb2080e7          	jalr	-846(ra) # 80002582 <update_timings>
  wakeup(&ticks);
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	928080e7          	jalr	-1752(ra) # 80002202 <wakeup>
  release(&tickslock);
    800028e2:	854a                	mv	a0,s2
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	3a0080e7          	jalr	928(ra) # 80000c84 <release>
}
    800028ec:	60e2                	ld	ra,24(sp)
    800028ee:	6442                	ld	s0,16(sp)
    800028f0:	64a2                	ld	s1,8(sp)
    800028f2:	6902                	ld	s2,0(sp)
    800028f4:	6105                	addi	sp,sp,32
    800028f6:	8082                	ret

00000000800028f8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028f8:	1101                	addi	sp,sp,-32
    800028fa:	ec06                	sd	ra,24(sp)
    800028fc:	e822                	sd	s0,16(sp)
    800028fe:	e426                	sd	s1,8(sp)
    80002900:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002902:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002906:	00074d63          	bltz	a4,80002920 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000290a:	57fd                	li	a5,-1
    8000290c:	17fe                	slli	a5,a5,0x3f
    8000290e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002910:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002912:	06f70363          	beq	a4,a5,80002978 <devintr+0x80>
  }
}
    80002916:	60e2                	ld	ra,24(sp)
    80002918:	6442                	ld	s0,16(sp)
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	6105                	addi	sp,sp,32
    8000291e:	8082                	ret
     (scause & 0xff) == 9){
    80002920:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002924:	46a5                	li	a3,9
    80002926:	fed792e3          	bne	a5,a3,8000290a <devintr+0x12>
    int irq = plic_claim();
    8000292a:	00003097          	auipc	ra,0x3
    8000292e:	55e080e7          	jalr	1374(ra) # 80005e88 <plic_claim>
    80002932:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002934:	47a9                	li	a5,10
    80002936:	02f50763          	beq	a0,a5,80002964 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000293a:	4785                	li	a5,1
    8000293c:	02f50963          	beq	a0,a5,8000296e <devintr+0x76>
    return 1;
    80002940:	4505                	li	a0,1
    } else if(irq){
    80002942:	d8f1                	beqz	s1,80002916 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002944:	85a6                	mv	a1,s1
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	9b250513          	addi	a0,a0,-1614 # 800082f8 <states.0+0x38>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c36080e7          	jalr	-970(ra) # 80000584 <printf>
      plic_complete(irq);
    80002956:	8526                	mv	a0,s1
    80002958:	00003097          	auipc	ra,0x3
    8000295c:	554080e7          	jalr	1364(ra) # 80005eac <plic_complete>
    return 1;
    80002960:	4505                	li	a0,1
    80002962:	bf55                	j	80002916 <devintr+0x1e>
      uartintr();
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	02e080e7          	jalr	46(ra) # 80000992 <uartintr>
    8000296c:	b7ed                	j	80002956 <devintr+0x5e>
      virtio_disk_intr();
    8000296e:	00004097          	auipc	ra,0x4
    80002972:	9ca080e7          	jalr	-1590(ra) # 80006338 <virtio_disk_intr>
    80002976:	b7c5                	j	80002956 <devintr+0x5e>
    if(cpuid() == 0){
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	ff2080e7          	jalr	-14(ra) # 8000196a <cpuid>
    80002980:	c901                	beqz	a0,80002990 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002982:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002986:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002988:	14479073          	csrw	sip,a5
    return 2;
    8000298c:	4509                	li	a0,2
    8000298e:	b761                	j	80002916 <devintr+0x1e>
      clockintr();
    80002990:	00000097          	auipc	ra,0x0
    80002994:	f14080e7          	jalr	-236(ra) # 800028a4 <clockintr>
    80002998:	b7ed                	j	80002982 <devintr+0x8a>

000000008000299a <usertrap>:
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	e04a                	sd	s2,0(sp)
    800029a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029aa:	1007f793          	andi	a5,a5,256
    800029ae:	e3ad                	bnez	a5,80002a10 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b0:	00003797          	auipc	a5,0x3
    800029b4:	3d078793          	addi	a5,a5,976 # 80005d80 <kernelvec>
    800029b8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	fda080e7          	jalr	-38(ra) # 80001996 <myproc>
    800029c4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029c6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c8:	14102773          	csrr	a4,sepc
    800029cc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d2:	47a1                	li	a5,8
    800029d4:	04f71c63          	bne	a4,a5,80002a2c <usertrap+0x92>
    if(p->killed)
    800029d8:	551c                	lw	a5,40(a0)
    800029da:	e3b9                	bnez	a5,80002a20 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029dc:	6cb8                	ld	a4,88(s1)
    800029de:	6f1c                	ld	a5,24(a4)
    800029e0:	0791                	addi	a5,a5,4
    800029e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10079073          	csrw	sstatus,a5
    syscall();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	2e0080e7          	jalr	736(ra) # 80002cd0 <syscall>
  if(p->killed)
    800029f8:	549c                	lw	a5,40(s1)
    800029fa:	ebc1                	bnez	a5,80002a8a <usertrap+0xf0>
  usertrapret();
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	e0a080e7          	jalr	-502(ra) # 80002806 <usertrapret>
}
    80002a04:	60e2                	ld	ra,24(sp)
    80002a06:	6442                	ld	s0,16(sp)
    80002a08:	64a2                	ld	s1,8(sp)
    80002a0a:	6902                	ld	s2,0(sp)
    80002a0c:	6105                	addi	sp,sp,32
    80002a0e:	8082                	ret
    panic("usertrap: not from user mode");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	90850513          	addi	a0,a0,-1784 # 80008318 <states.0+0x58>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b22080e7          	jalr	-1246(ra) # 8000053a <panic>
      exit(-1);
    80002a20:	557d                	li	a0,-1
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	8b0080e7          	jalr	-1872(ra) # 800022d2 <exit>
    80002a2a:	bf4d                	j	800029dc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	ecc080e7          	jalr	-308(ra) # 800028f8 <devintr>
    80002a34:	892a                	mv	s2,a0
    80002a36:	c501                	beqz	a0,80002a3e <usertrap+0xa4>
  if(p->killed)
    80002a38:	549c                	lw	a5,40(s1)
    80002a3a:	c3a1                	beqz	a5,80002a7a <usertrap+0xe0>
    80002a3c:	a815                	j	80002a70 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a42:	5890                	lw	a2,48(s1)
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	8f450513          	addi	a0,a0,-1804 # 80008338 <states.0+0x78>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b38080e7          	jalr	-1224(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a58:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	90c50513          	addi	a0,a0,-1780 # 80008368 <states.0+0xa8>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	b20080e7          	jalr	-1248(ra) # 80000584 <printf>
    p->killed = 1;
    80002a6c:	4785                	li	a5,1
    80002a6e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a70:	557d                	li	a0,-1
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	860080e7          	jalr	-1952(ra) # 800022d2 <exit>
  if(which_dev == 2)
    80002a7a:	4789                	li	a5,2
    80002a7c:	f8f910e3          	bne	s2,a5,800029fc <usertrap+0x62>
    yield();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	5ba080e7          	jalr	1466(ra) # 8000203a <yield>
    80002a88:	bf95                	j	800029fc <usertrap+0x62>
  int which_dev = 0;
    80002a8a:	4901                	li	s2,0
    80002a8c:	b7d5                	j	80002a70 <usertrap+0xd6>

0000000080002a8e <kerneltrap>:
{
    80002a8e:	7179                	addi	sp,sp,-48
    80002a90:	f406                	sd	ra,40(sp)
    80002a92:	f022                	sd	s0,32(sp)
    80002a94:	ec26                	sd	s1,24(sp)
    80002a96:	e84a                	sd	s2,16(sp)
    80002a98:	e44e                	sd	s3,8(sp)
    80002a9a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aa8:	1004f793          	andi	a5,s1,256
    80002aac:	cb85                	beqz	a5,80002adc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab4:	ef85                	bnez	a5,80002aec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	e42080e7          	jalr	-446(ra) # 800028f8 <devintr>
    80002abe:	cd1d                	beqz	a0,80002afc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac0:	4789                	li	a5,2
    80002ac2:	06f50a63          	beq	a0,a5,80002b36 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aca:	10049073          	csrw	sstatus,s1
}
    80002ace:	70a2                	ld	ra,40(sp)
    80002ad0:	7402                	ld	s0,32(sp)
    80002ad2:	64e2                	ld	s1,24(sp)
    80002ad4:	6942                	ld	s2,16(sp)
    80002ad6:	69a2                	ld	s3,8(sp)
    80002ad8:	6145                	addi	sp,sp,48
    80002ada:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	8ac50513          	addi	a0,a0,-1876 # 80008388 <states.0+0xc8>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a56080e7          	jalr	-1450(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	8c450513          	addi	a0,a0,-1852 # 800083b0 <states.0+0xf0>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a46080e7          	jalr	-1466(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002afc:	85ce                	mv	a1,s3
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	8d250513          	addi	a0,a0,-1838 # 800083d0 <states.0+0x110>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a7e080e7          	jalr	-1410(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b12:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	8ca50513          	addi	a0,a0,-1846 # 800083e0 <states.0+0x120>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a66080e7          	jalr	-1434(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002b26:	00006517          	auipc	a0,0x6
    80002b2a:	8d250513          	addi	a0,a0,-1838 # 800083f8 <states.0+0x138>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	a0c080e7          	jalr	-1524(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e60080e7          	jalr	-416(ra) # 80001996 <myproc>
    80002b3e:	d541                	beqz	a0,80002ac6 <kerneltrap+0x38>
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	e56080e7          	jalr	-426(ra) # 80001996 <myproc>
    80002b48:	4d18                	lw	a4,24(a0)
    80002b4a:	4791                	li	a5,4
    80002b4c:	f6f71de3          	bne	a4,a5,80002ac6 <kerneltrap+0x38>
    yield();
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	4ea080e7          	jalr	1258(ra) # 8000203a <yield>
    80002b58:	b7bd                	j	80002ac6 <kerneltrap+0x38>

0000000080002b5a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	e426                	sd	s1,8(sp)
    80002b62:	1000                	addi	s0,sp,32
    80002b64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	e30080e7          	jalr	-464(ra) # 80001996 <myproc>
  switch (n) {
    80002b6e:	4795                	li	a5,5
    80002b70:	0497e163          	bltu	a5,s1,80002bb2 <argraw+0x58>
    80002b74:	048a                	slli	s1,s1,0x2
    80002b76:	00006717          	auipc	a4,0x6
    80002b7a:	8ba70713          	addi	a4,a4,-1862 # 80008430 <states.0+0x170>
    80002b7e:	94ba                	add	s1,s1,a4
    80002b80:	409c                	lw	a5,0(s1)
    80002b82:	97ba                	add	a5,a5,a4
    80002b84:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b86:	6d3c                	ld	a5,88(a0)
    80002b88:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret
    return p->trapframe->a1;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	7fa8                	ld	a0,120(a5)
    80002b98:	bfcd                	j	80002b8a <argraw+0x30>
    return p->trapframe->a2;
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	63c8                	ld	a0,128(a5)
    80002b9e:	b7f5                	j	80002b8a <argraw+0x30>
    return p->trapframe->a3;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	67c8                	ld	a0,136(a5)
    80002ba4:	b7dd                	j	80002b8a <argraw+0x30>
    return p->trapframe->a4;
    80002ba6:	6d3c                	ld	a5,88(a0)
    80002ba8:	6bc8                	ld	a0,144(a5)
    80002baa:	b7c5                	j	80002b8a <argraw+0x30>
    return p->trapframe->a5;
    80002bac:	6d3c                	ld	a5,88(a0)
    80002bae:	6fc8                	ld	a0,152(a5)
    80002bb0:	bfe9                	j	80002b8a <argraw+0x30>
  panic("argraw");
    80002bb2:	00006517          	auipc	a0,0x6
    80002bb6:	85650513          	addi	a0,a0,-1962 # 80008408 <states.0+0x148>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	980080e7          	jalr	-1664(ra) # 8000053a <panic>

0000000080002bc2 <fetchaddr>:
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
    80002bce:	84aa                	mv	s1,a0
    80002bd0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	dc4080e7          	jalr	-572(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bda:	653c                	ld	a5,72(a0)
    80002bdc:	02f4f863          	bgeu	s1,a5,80002c0c <fetchaddr+0x4a>
    80002be0:	00848713          	addi	a4,s1,8
    80002be4:	02e7e663          	bltu	a5,a4,80002c10 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002be8:	46a1                	li	a3,8
    80002bea:	8626                	mv	a2,s1
    80002bec:	85ca                	mv	a1,s2
    80002bee:	6928                	ld	a0,80(a0)
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	af6080e7          	jalr	-1290(ra) # 800016e6 <copyin>
    80002bf8:	00a03533          	snez	a0,a0
    80002bfc:	40a00533          	neg	a0,a0
}
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6902                	ld	s2,0(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret
    return -1;
    80002c0c:	557d                	li	a0,-1
    80002c0e:	bfcd                	j	80002c00 <fetchaddr+0x3e>
    80002c10:	557d                	li	a0,-1
    80002c12:	b7fd                	j	80002c00 <fetchaddr+0x3e>

0000000080002c14 <fetchstr>:
{
    80002c14:	7179                	addi	sp,sp,-48
    80002c16:	f406                	sd	ra,40(sp)
    80002c18:	f022                	sd	s0,32(sp)
    80002c1a:	ec26                	sd	s1,24(sp)
    80002c1c:	e84a                	sd	s2,16(sp)
    80002c1e:	e44e                	sd	s3,8(sp)
    80002c20:	1800                	addi	s0,sp,48
    80002c22:	892a                	mv	s2,a0
    80002c24:	84ae                	mv	s1,a1
    80002c26:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	d6e080e7          	jalr	-658(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c30:	86ce                	mv	a3,s3
    80002c32:	864a                	mv	a2,s2
    80002c34:	85a6                	mv	a1,s1
    80002c36:	6928                	ld	a0,80(a0)
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	b3c080e7          	jalr	-1220(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002c40:	00054763          	bltz	a0,80002c4e <fetchstr+0x3a>
  return strlen(buf);
    80002c44:	8526                	mv	a0,s1
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	202080e7          	jalr	514(ra) # 80000e48 <strlen>
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	69a2                	ld	s3,8(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	1000                	addi	s0,sp,32
    80002c66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	ef2080e7          	jalr	-270(ra) # 80002b5a <argraw>
    80002c70:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c72:	4501                	li	a0,0
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	64a2                	ld	s1,8(sp)
    80002c7a:	6105                	addi	sp,sp,32
    80002c7c:	8082                	ret

0000000080002c7e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c7e:	1101                	addi	sp,sp,-32
    80002c80:	ec06                	sd	ra,24(sp)
    80002c82:	e822                	sd	s0,16(sp)
    80002c84:	e426                	sd	s1,8(sp)
    80002c86:	1000                	addi	s0,sp,32
    80002c88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	ed0080e7          	jalr	-304(ra) # 80002b5a <argraw>
    80002c92:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c94:	4501                	li	a0,0
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca0:	1101                	addi	sp,sp,-32
    80002ca2:	ec06                	sd	ra,24(sp)
    80002ca4:	e822                	sd	s0,16(sp)
    80002ca6:	e426                	sd	s1,8(sp)
    80002ca8:	e04a                	sd	s2,0(sp)
    80002caa:	1000                	addi	s0,sp,32
    80002cac:	84ae                	mv	s1,a1
    80002cae:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	eaa080e7          	jalr	-342(ra) # 80002b5a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cb8:	864a                	mv	a2,s2
    80002cba:	85a6                	mv	a1,s1
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	f58080e7          	jalr	-168(ra) # 80002c14 <fetchstr>
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6902                	ld	s2,0(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret

0000000080002cd0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002cd0:	1101                	addi	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	e426                	sd	s1,8(sp)
    80002cd8:	e04a                	sd	s2,0(sp)
    80002cda:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cba080e7          	jalr	-838(ra) # 80001996 <myproc>
    80002ce4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ce6:	05853903          	ld	s2,88(a0)
    80002cea:	0a893783          	ld	a5,168(s2)
    80002cee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf2:	37fd                	addiw	a5,a5,-1
    80002cf4:	4751                	li	a4,20
    80002cf6:	00f76f63          	bltu	a4,a5,80002d14 <syscall+0x44>
    80002cfa:	00369713          	slli	a4,a3,0x3
    80002cfe:	00005797          	auipc	a5,0x5
    80002d02:	74a78793          	addi	a5,a5,1866 # 80008448 <syscalls>
    80002d06:	97ba                	add	a5,a5,a4
    80002d08:	639c                	ld	a5,0(a5)
    80002d0a:	c789                	beqz	a5,80002d14 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d0c:	9782                	jalr	a5
    80002d0e:	06a93823          	sd	a0,112(s2)
    80002d12:	a839                	j	80002d30 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d14:	15848613          	addi	a2,s1,344
    80002d18:	588c                	lw	a1,48(s1)
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	6f650513          	addi	a0,a0,1782 # 80008410 <states.0+0x150>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	862080e7          	jalr	-1950(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2a:	6cbc                	ld	a5,88(s1)
    80002d2c:	577d                	li	a4,-1
    80002d2e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6902                	ld	s2,0(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d44:	fec40593          	addi	a1,s0,-20
    80002d48:	4501                	li	a0,0
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	f12080e7          	jalr	-238(ra) # 80002c5c <argint>
    return -1;
    80002d52:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d54:	00054963          	bltz	a0,80002d66 <sys_exit+0x2a>
  exit(n);
    80002d58:	fec42503          	lw	a0,-20(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	576080e7          	jalr	1398(ra) # 800022d2 <exit>
  return 0;  // not reached
    80002d64:	4781                	li	a5,0
}
    80002d66:	853e                	mv	a0,a5
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret

0000000080002d70 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	c1e080e7          	jalr	-994(ra) # 80001996 <myproc>
}
    80002d80:	5908                	lw	a0,48(a0)
    80002d82:	60a2                	ld	ra,8(sp)
    80002d84:	6402                	ld	s0,0(sp)
    80002d86:	0141                	addi	sp,sp,16
    80002d88:	8082                	ret

0000000080002d8a <sys_fork>:

uint64
sys_fork(void)
{
    80002d8a:	1141                	addi	sp,sp,-16
    80002d8c:	e406                	sd	ra,8(sp)
    80002d8e:	e022                	sd	s0,0(sp)
    80002d90:	0800                	addi	s0,sp,16
  return fork();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	ff2080e7          	jalr	-14(ra) # 80001d84 <fork>
}
    80002d9a:	60a2                	ld	ra,8(sp)
    80002d9c:	6402                	ld	s0,0(sp)
    80002d9e:	0141                	addi	sp,sp,16
    80002da0:	8082                	ret

0000000080002da2 <sys_wait>:

uint64
sys_wait(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002daa:	fe840593          	addi	a1,s0,-24
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	ece080e7          	jalr	-306(ra) # 80002c7e <argaddr>
    80002db8:	87aa                	mv	a5,a0
    return -1;
    80002dba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dbc:	0007c863          	bltz	a5,80002dcc <sys_wait+0x2a>
  return wait(p);
    80002dc0:	fe843503          	ld	a0,-24(s0)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	316080e7          	jalr	790(ra) # 800020da <wait>
}
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	ec26                	sd	s1,24(sp)
    80002ddc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dde:	fdc40593          	addi	a1,s0,-36
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	e78080e7          	jalr	-392(ra) # 80002c5c <argint>
    80002dec:	87aa                	mv	a5,a0
    return -1;
    80002dee:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002df0:	0207c063          	bltz	a5,80002e10 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	ba2080e7          	jalr	-1118(ra) # 80001996 <myproc>
    80002dfc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dfe:	fdc42503          	lw	a0,-36(s0)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	f0a080e7          	jalr	-246(ra) # 80001d0c <growproc>
    80002e0a:	00054863          	bltz	a0,80002e1a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e0e:	8526                	mv	a0,s1
}
    80002e10:	70a2                	ld	ra,40(sp)
    80002e12:	7402                	ld	s0,32(sp)
    80002e14:	64e2                	ld	s1,24(sp)
    80002e16:	6145                	addi	sp,sp,48
    80002e18:	8082                	ret
    return -1;
    80002e1a:	557d                	li	a0,-1
    80002e1c:	bfd5                	j	80002e10 <sys_sbrk+0x3c>

0000000080002e1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e1e:	7139                	addi	sp,sp,-64
    80002e20:	fc06                	sd	ra,56(sp)
    80002e22:	f822                	sd	s0,48(sp)
    80002e24:	f426                	sd	s1,40(sp)
    80002e26:	f04a                	sd	s2,32(sp)
    80002e28:	ec4e                	sd	s3,24(sp)
    80002e2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e2c:	fcc40593          	addi	a1,s0,-52
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	e2a080e7          	jalr	-470(ra) # 80002c5c <argint>
    return -1;
    80002e3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e3c:	06054563          	bltz	a0,80002ea6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e40:	00015517          	auipc	a0,0x15
    80002e44:	c9050513          	addi	a0,a0,-880 # 80017ad0 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	d88080e7          	jalr	-632(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002e50:	00006917          	auipc	s2,0x6
    80002e54:	1e092903          	lw	s2,480(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e58:	fcc42783          	lw	a5,-52(s0)
    80002e5c:	cf85                	beqz	a5,80002e94 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e5e:	00015997          	auipc	s3,0x15
    80002e62:	c7298993          	addi	s3,s3,-910 # 80017ad0 <tickslock>
    80002e66:	00006497          	auipc	s1,0x6
    80002e6a:	1ca48493          	addi	s1,s1,458 # 80009030 <ticks>
    if(myproc()->killed){
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	b28080e7          	jalr	-1240(ra) # 80001996 <myproc>
    80002e76:	551c                	lw	a5,40(a0)
    80002e78:	ef9d                	bnez	a5,80002eb6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e7a:	85ce                	mv	a1,s3
    80002e7c:	8526                	mv	a0,s1
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	1f8080e7          	jalr	504(ra) # 80002076 <sleep>
  while(ticks - ticks0 < n){
    80002e86:	409c                	lw	a5,0(s1)
    80002e88:	412787bb          	subw	a5,a5,s2
    80002e8c:	fcc42703          	lw	a4,-52(s0)
    80002e90:	fce7efe3          	bltu	a5,a4,80002e6e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e94:	00015517          	auipc	a0,0x15
    80002e98:	c3c50513          	addi	a0,a0,-964 # 80017ad0 <tickslock>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	de8080e7          	jalr	-536(ra) # 80000c84 <release>
  return 0;
    80002ea4:	4781                	li	a5,0
}
    80002ea6:	853e                	mv	a0,a5
    80002ea8:	70e2                	ld	ra,56(sp)
    80002eaa:	7442                	ld	s0,48(sp)
    80002eac:	74a2                	ld	s1,40(sp)
    80002eae:	7902                	ld	s2,32(sp)
    80002eb0:	69e2                	ld	s3,24(sp)
    80002eb2:	6121                	addi	sp,sp,64
    80002eb4:	8082                	ret
      release(&tickslock);
    80002eb6:	00015517          	auipc	a0,0x15
    80002eba:	c1a50513          	addi	a0,a0,-998 # 80017ad0 <tickslock>
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	dc6080e7          	jalr	-570(ra) # 80000c84 <release>
      return -1;
    80002ec6:	57fd                	li	a5,-1
    80002ec8:	bff9                	j	80002ea6 <sys_sleep+0x88>

0000000080002eca <sys_kill>:

uint64
sys_kill(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	d84080e7          	jalr	-636(ra) # 80002c5c <argint>
    80002ee0:	87aa                	mv	a5,a0
    return -1;
    80002ee2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ee4:	0007c863          	bltz	a5,80002ef4 <sys_kill+0x2a>
  return kill(pid);
    80002ee8:	fec42503          	lw	a0,-20(s0)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	4c8080e7          	jalr	1224(ra) # 800023b4 <kill>
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	6105                	addi	sp,sp,32
    80002efa:	8082                	ret

0000000080002efc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f06:	00015517          	auipc	a0,0x15
    80002f0a:	bca50513          	addi	a0,a0,-1078 # 80017ad0 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	cc2080e7          	jalr	-830(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002f16:	00006497          	auipc	s1,0x6
    80002f1a:	11a4a483          	lw	s1,282(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f1e:	00015517          	auipc	a0,0x15
    80002f22:	bb250513          	addi	a0,a0,-1102 # 80017ad0 <tickslock>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	d5e080e7          	jalr	-674(ra) # 80000c84 <release>
  return xticks;
}
    80002f2e:	02049513          	slli	a0,s1,0x20
    80002f32:	9101                	srli	a0,a0,0x20
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	64a2                	ld	s1,8(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_wait2>:

uint64
sys_wait2(void)
{
    80002f3e:	715d                	addi	sp,sp,-80
    80002f40:	e486                	sd	ra,72(sp)
    80002f42:	e0a2                	sd	s0,64(sp)
    80002f44:	fc26                	sd	s1,56(sp)
    80002f46:	f84a                	sd	s2,48(sp)
    80002f48:	0880                	addi	s0,sp,80
  uint64 addr, addr1, addr2, addr3;
  uint wtime, rtime, stime;
  if(argaddr(0, &addr) < 0)
    80002f4a:	fd840593          	addi	a1,s0,-40
    80002f4e:	4501                	li	a0,0
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	d2e080e7          	jalr	-722(ra) # 80002c7e <argaddr>
    return -1;
    80002f58:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002f5a:	0a054963          	bltz	a0,8000300c <sys_wait2+0xce>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f5e:	fd040593          	addi	a1,s0,-48
    80002f62:	4505                	li	a0,1
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	d1a080e7          	jalr	-742(ra) # 80002c7e <argaddr>
    return -1;
    80002f6c:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f6e:	08054f63          	bltz	a0,8000300c <sys_wait2+0xce>
  if(argaddr(2, &addr2) < 0)
    80002f72:	fc840593          	addi	a1,s0,-56
    80002f76:	4509                	li	a0,2
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	d06080e7          	jalr	-762(ra) # 80002c7e <argaddr>
    return -1;
    80002f80:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002f82:	08054563          	bltz	a0,8000300c <sys_wait2+0xce>
  if(argaddr(3, &addr3) < 0)
    80002f86:	fc040593          	addi	a1,s0,-64
    80002f8a:	450d                	li	a0,3
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	cf2080e7          	jalr	-782(ra) # 80002c7e <argaddr>
	return -1;
    80002f94:	57fd                	li	a5,-1
  if(argaddr(3, &addr3) < 0)
    80002f96:	06054b63          	bltz	a0,8000300c <sys_wait2+0xce>
  int ret = wait2(addr, &rtime, &wtime, &stime);
    80002f9a:	fb440693          	addi	a3,s0,-76
    80002f9e:	fbc40613          	addi	a2,s0,-68
    80002fa2:	fb840593          	addi	a1,s0,-72
    80002fa6:	fd843503          	ld	a0,-40(s0)
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	660080e7          	jalr	1632(ra) # 8000260a <wait2>
    80002fb2:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	9e2080e7          	jalr	-1566(ra) # 80001996 <myproc>
    80002fbc:	84aa                	mv	s1,a0
  if(copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002fbe:	4691                	li	a3,4
    80002fc0:	fbc40613          	addi	a2,s0,-68
    80002fc4:	fd043583          	ld	a1,-48(s0)
    80002fc8:	6928                	ld	a0,80(a0)
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	690080e7          	jalr	1680(ra) # 8000165a <copyout>
    return -1;
    80002fd2:	57fd                	li	a5,-1
  if(copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002fd4:	02054c63          	bltz	a0,8000300c <sys_wait2+0xce>
  if(copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002fd8:	4691                	li	a3,4
    80002fda:	fb840613          	addi	a2,s0,-72
    80002fde:	fc843583          	ld	a1,-56(s0)
    80002fe2:	68a8                	ld	a0,80(s1)
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	676080e7          	jalr	1654(ra) # 8000165a <copyout>
    return -1;
    80002fec:	57fd                	li	a5,-1
  if(copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002fee:	00054f63          	bltz	a0,8000300c <sys_wait2+0xce>
  if(copyout(p->pagetable, addr3, (char*)&stime, sizeof(int)) < 0)
    80002ff2:	4691                	li	a3,4
    80002ff4:	fb440613          	addi	a2,s0,-76
    80002ff8:	fc043583          	ld	a1,-64(s0)
    80002ffc:	68a8                	ld	a0,80(s1)
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	65c080e7          	jalr	1628(ra) # 8000165a <copyout>
    80003006:	00054a63          	bltz	a0,8000301a <sys_wait2+0xdc>
	return -1;
  return ret;
    8000300a:	87ca                	mv	a5,s2
}
    8000300c:	853e                	mv	a0,a5
    8000300e:	60a6                	ld	ra,72(sp)
    80003010:	6406                	ld	s0,64(sp)
    80003012:	74e2                	ld	s1,56(sp)
    80003014:	7942                	ld	s2,48(sp)
    80003016:	6161                	addi	sp,sp,80
    80003018:	8082                	ret
	return -1;
    8000301a:	57fd                	li	a5,-1
    8000301c:	bfc5                	j	8000300c <sys_wait2+0xce>

000000008000301e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000301e:	7179                	addi	sp,sp,-48
    80003020:	f406                	sd	ra,40(sp)
    80003022:	f022                	sd	s0,32(sp)
    80003024:	ec26                	sd	s1,24(sp)
    80003026:	e84a                	sd	s2,16(sp)
    80003028:	e44e                	sd	s3,8(sp)
    8000302a:	e052                	sd	s4,0(sp)
    8000302c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000302e:	00005597          	auipc	a1,0x5
    80003032:	4ca58593          	addi	a1,a1,1226 # 800084f8 <syscalls+0xb0>
    80003036:	00015517          	auipc	a0,0x15
    8000303a:	ab250513          	addi	a0,a0,-1358 # 80017ae8 <bcache>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	b02080e7          	jalr	-1278(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003046:	0001d797          	auipc	a5,0x1d
    8000304a:	aa278793          	addi	a5,a5,-1374 # 8001fae8 <bcache+0x8000>
    8000304e:	0001d717          	auipc	a4,0x1d
    80003052:	d0270713          	addi	a4,a4,-766 # 8001fd50 <bcache+0x8268>
    80003056:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000305a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000305e:	00015497          	auipc	s1,0x15
    80003062:	aa248493          	addi	s1,s1,-1374 # 80017b00 <bcache+0x18>
    b->next = bcache.head.next;
    80003066:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003068:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000306a:	00005a17          	auipc	s4,0x5
    8000306e:	496a0a13          	addi	s4,s4,1174 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003072:	2b893783          	ld	a5,696(s2)
    80003076:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003078:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000307c:	85d2                	mv	a1,s4
    8000307e:	01048513          	addi	a0,s1,16
    80003082:	00001097          	auipc	ra,0x1
    80003086:	4c2080e7          	jalr	1218(ra) # 80004544 <initsleeplock>
    bcache.head.next->prev = b;
    8000308a:	2b893783          	ld	a5,696(s2)
    8000308e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003090:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003094:	45848493          	addi	s1,s1,1112
    80003098:	fd349de3          	bne	s1,s3,80003072 <binit+0x54>
  }
}
    8000309c:	70a2                	ld	ra,40(sp)
    8000309e:	7402                	ld	s0,32(sp)
    800030a0:	64e2                	ld	s1,24(sp)
    800030a2:	6942                	ld	s2,16(sp)
    800030a4:	69a2                	ld	s3,8(sp)
    800030a6:	6a02                	ld	s4,0(sp)
    800030a8:	6145                	addi	sp,sp,48
    800030aa:	8082                	ret

00000000800030ac <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ac:	7179                	addi	sp,sp,-48
    800030ae:	f406                	sd	ra,40(sp)
    800030b0:	f022                	sd	s0,32(sp)
    800030b2:	ec26                	sd	s1,24(sp)
    800030b4:	e84a                	sd	s2,16(sp)
    800030b6:	e44e                	sd	s3,8(sp)
    800030b8:	1800                	addi	s0,sp,48
    800030ba:	892a                	mv	s2,a0
    800030bc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030be:	00015517          	auipc	a0,0x15
    800030c2:	a2a50513          	addi	a0,a0,-1494 # 80017ae8 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	b0a080e7          	jalr	-1270(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030ce:	0001d497          	auipc	s1,0x1d
    800030d2:	cd24b483          	ld	s1,-814(s1) # 8001fda0 <bcache+0x82b8>
    800030d6:	0001d797          	auipc	a5,0x1d
    800030da:	c7a78793          	addi	a5,a5,-902 # 8001fd50 <bcache+0x8268>
    800030de:	02f48f63          	beq	s1,a5,8000311c <bread+0x70>
    800030e2:	873e                	mv	a4,a5
    800030e4:	a021                	j	800030ec <bread+0x40>
    800030e6:	68a4                	ld	s1,80(s1)
    800030e8:	02e48a63          	beq	s1,a4,8000311c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030ec:	449c                	lw	a5,8(s1)
    800030ee:	ff279ce3          	bne	a5,s2,800030e6 <bread+0x3a>
    800030f2:	44dc                	lw	a5,12(s1)
    800030f4:	ff3799e3          	bne	a5,s3,800030e6 <bread+0x3a>
      b->refcnt++;
    800030f8:	40bc                	lw	a5,64(s1)
    800030fa:	2785                	addiw	a5,a5,1
    800030fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030fe:	00015517          	auipc	a0,0x15
    80003102:	9ea50513          	addi	a0,a0,-1558 # 80017ae8 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	b7e080e7          	jalr	-1154(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000310e:	01048513          	addi	a0,s1,16
    80003112:	00001097          	auipc	ra,0x1
    80003116:	46c080e7          	jalr	1132(ra) # 8000457e <acquiresleep>
      return b;
    8000311a:	a8b9                	j	80003178 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000311c:	0001d497          	auipc	s1,0x1d
    80003120:	c7c4b483          	ld	s1,-900(s1) # 8001fd98 <bcache+0x82b0>
    80003124:	0001d797          	auipc	a5,0x1d
    80003128:	c2c78793          	addi	a5,a5,-980 # 8001fd50 <bcache+0x8268>
    8000312c:	00f48863          	beq	s1,a5,8000313c <bread+0x90>
    80003130:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003132:	40bc                	lw	a5,64(s1)
    80003134:	cf81                	beqz	a5,8000314c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003136:	64a4                	ld	s1,72(s1)
    80003138:	fee49de3          	bne	s1,a4,80003132 <bread+0x86>
  panic("bget: no buffers");
    8000313c:	00005517          	auipc	a0,0x5
    80003140:	3cc50513          	addi	a0,a0,972 # 80008508 <syscalls+0xc0>
    80003144:	ffffd097          	auipc	ra,0xffffd
    80003148:	3f6080e7          	jalr	1014(ra) # 8000053a <panic>
      b->dev = dev;
    8000314c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003150:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003154:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003158:	4785                	li	a5,1
    8000315a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000315c:	00015517          	auipc	a0,0x15
    80003160:	98c50513          	addi	a0,a0,-1652 # 80017ae8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b20080e7          	jalr	-1248(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000316c:	01048513          	addi	a0,s1,16
    80003170:	00001097          	auipc	ra,0x1
    80003174:	40e080e7          	jalr	1038(ra) # 8000457e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003178:	409c                	lw	a5,0(s1)
    8000317a:	cb89                	beqz	a5,8000318c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000317c:	8526                	mv	a0,s1
    8000317e:	70a2                	ld	ra,40(sp)
    80003180:	7402                	ld	s0,32(sp)
    80003182:	64e2                	ld	s1,24(sp)
    80003184:	6942                	ld	s2,16(sp)
    80003186:	69a2                	ld	s3,8(sp)
    80003188:	6145                	addi	sp,sp,48
    8000318a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000318c:	4581                	li	a1,0
    8000318e:	8526                	mv	a0,s1
    80003190:	00003097          	auipc	ra,0x3
    80003194:	f22080e7          	jalr	-222(ra) # 800060b2 <virtio_disk_rw>
    b->valid = 1;
    80003198:	4785                	li	a5,1
    8000319a:	c09c                	sw	a5,0(s1)
  return b;
    8000319c:	b7c5                	j	8000317c <bread+0xd0>

000000008000319e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031aa:	0541                	addi	a0,a0,16
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	46c080e7          	jalr	1132(ra) # 80004618 <holdingsleep>
    800031b4:	cd01                	beqz	a0,800031cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031b6:	4585                	li	a1,1
    800031b8:	8526                	mv	a0,s1
    800031ba:	00003097          	auipc	ra,0x3
    800031be:	ef8080e7          	jalr	-264(ra) # 800060b2 <virtio_disk_rw>
}
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	64a2                	ld	s1,8(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret
    panic("bwrite");
    800031cc:	00005517          	auipc	a0,0x5
    800031d0:	35450513          	addi	a0,a0,852 # 80008520 <syscalls+0xd8>
    800031d4:	ffffd097          	auipc	ra,0xffffd
    800031d8:	366080e7          	jalr	870(ra) # 8000053a <panic>

00000000800031dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ea:	01050913          	addi	s2,a0,16
    800031ee:	854a                	mv	a0,s2
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	428080e7          	jalr	1064(ra) # 80004618 <holdingsleep>
    800031f8:	c92d                	beqz	a0,8000326a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	3d8080e7          	jalr	984(ra) # 800045d4 <releasesleep>

  acquire(&bcache.lock);
    80003204:	00015517          	auipc	a0,0x15
    80003208:	8e450513          	addi	a0,a0,-1820 # 80017ae8 <bcache>
    8000320c:	ffffe097          	auipc	ra,0xffffe
    80003210:	9c4080e7          	jalr	-1596(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003214:	40bc                	lw	a5,64(s1)
    80003216:	37fd                	addiw	a5,a5,-1
    80003218:	0007871b          	sext.w	a4,a5
    8000321c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000321e:	eb05                	bnez	a4,8000324e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003220:	68bc                	ld	a5,80(s1)
    80003222:	64b8                	ld	a4,72(s1)
    80003224:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003226:	64bc                	ld	a5,72(s1)
    80003228:	68b8                	ld	a4,80(s1)
    8000322a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000322c:	0001d797          	auipc	a5,0x1d
    80003230:	8bc78793          	addi	a5,a5,-1860 # 8001fae8 <bcache+0x8000>
    80003234:	2b87b703          	ld	a4,696(a5)
    80003238:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000323a:	0001d717          	auipc	a4,0x1d
    8000323e:	b1670713          	addi	a4,a4,-1258 # 8001fd50 <bcache+0x8268>
    80003242:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003244:	2b87b703          	ld	a4,696(a5)
    80003248:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000324a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000324e:	00015517          	auipc	a0,0x15
    80003252:	89a50513          	addi	a0,a0,-1894 # 80017ae8 <bcache>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	a2e080e7          	jalr	-1490(ra) # 80000c84 <release>
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6902                	ld	s2,0(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret
    panic("brelse");
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	2be50513          	addi	a0,a0,702 # 80008528 <syscalls+0xe0>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	2c8080e7          	jalr	712(ra) # 8000053a <panic>

000000008000327a <bpin>:

void
bpin(struct buf *b) {
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	1000                	addi	s0,sp,32
    80003284:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003286:	00015517          	auipc	a0,0x15
    8000328a:	86250513          	addi	a0,a0,-1950 # 80017ae8 <bcache>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	942080e7          	jalr	-1726(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003296:	40bc                	lw	a5,64(s1)
    80003298:	2785                	addiw	a5,a5,1
    8000329a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000329c:	00015517          	auipc	a0,0x15
    800032a0:	84c50513          	addi	a0,a0,-1972 # 80017ae8 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	9e0080e7          	jalr	-1568(ra) # 80000c84 <release>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <bunpin>:

void
bunpin(struct buf *b) {
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c2:	00015517          	auipc	a0,0x15
    800032c6:	82650513          	addi	a0,a0,-2010 # 80017ae8 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	906080e7          	jalr	-1786(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800032d2:	40bc                	lw	a5,64(s1)
    800032d4:	37fd                	addiw	a5,a5,-1
    800032d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d8:	00015517          	auipc	a0,0x15
    800032dc:	81050513          	addi	a0,a0,-2032 # 80017ae8 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9a4080e7          	jalr	-1628(ra) # 80000c84 <release>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	e04a                	sd	s2,0(sp)
    800032fc:	1000                	addi	s0,sp,32
    800032fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003300:	00d5d59b          	srliw	a1,a1,0xd
    80003304:	0001d797          	auipc	a5,0x1d
    80003308:	ec07a783          	lw	a5,-320(a5) # 800201c4 <sb+0x1c>
    8000330c:	9dbd                	addw	a1,a1,a5
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	d9e080e7          	jalr	-610(ra) # 800030ac <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003316:	0074f713          	andi	a4,s1,7
    8000331a:	4785                	li	a5,1
    8000331c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003320:	14ce                	slli	s1,s1,0x33
    80003322:	90d9                	srli	s1,s1,0x36
    80003324:	00950733          	add	a4,a0,s1
    80003328:	05874703          	lbu	a4,88(a4)
    8000332c:	00e7f6b3          	and	a3,a5,a4
    80003330:	c69d                	beqz	a3,8000335e <bfree+0x6c>
    80003332:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003334:	94aa                	add	s1,s1,a0
    80003336:	fff7c793          	not	a5,a5
    8000333a:	8f7d                	and	a4,a4,a5
    8000333c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003340:	00001097          	auipc	ra,0x1
    80003344:	120080e7          	jalr	288(ra) # 80004460 <log_write>
  brelse(bp);
    80003348:	854a                	mv	a0,s2
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e92080e7          	jalr	-366(ra) # 800031dc <brelse>
}
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6902                	ld	s2,0(sp)
    8000335a:	6105                	addi	sp,sp,32
    8000335c:	8082                	ret
    panic("freeing free block");
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	1d250513          	addi	a0,a0,466 # 80008530 <syscalls+0xe8>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	1d4080e7          	jalr	468(ra) # 8000053a <panic>

000000008000336e <balloc>:
{
    8000336e:	711d                	addi	sp,sp,-96
    80003370:	ec86                	sd	ra,88(sp)
    80003372:	e8a2                	sd	s0,80(sp)
    80003374:	e4a6                	sd	s1,72(sp)
    80003376:	e0ca                	sd	s2,64(sp)
    80003378:	fc4e                	sd	s3,56(sp)
    8000337a:	f852                	sd	s4,48(sp)
    8000337c:	f456                	sd	s5,40(sp)
    8000337e:	f05a                	sd	s6,32(sp)
    80003380:	ec5e                	sd	s7,24(sp)
    80003382:	e862                	sd	s8,16(sp)
    80003384:	e466                	sd	s9,8(sp)
    80003386:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003388:	0001d797          	auipc	a5,0x1d
    8000338c:	e247a783          	lw	a5,-476(a5) # 800201ac <sb+0x4>
    80003390:	cbc1                	beqz	a5,80003420 <balloc+0xb2>
    80003392:	8baa                	mv	s7,a0
    80003394:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003396:	0001db17          	auipc	s6,0x1d
    8000339a:	e12b0b13          	addi	s6,s6,-494 # 800201a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000339e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033a4:	6c89                	lui	s9,0x2
    800033a6:	a831                	j	800033c2 <balloc+0x54>
    brelse(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e32080e7          	jalr	-462(ra) # 800031dc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033b2:	015c87bb          	addw	a5,s9,s5
    800033b6:	00078a9b          	sext.w	s5,a5
    800033ba:	004b2703          	lw	a4,4(s6)
    800033be:	06eaf163          	bgeu	s5,a4,80003420 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800033c2:	41fad79b          	sraiw	a5,s5,0x1f
    800033c6:	0137d79b          	srliw	a5,a5,0x13
    800033ca:	015787bb          	addw	a5,a5,s5
    800033ce:	40d7d79b          	sraiw	a5,a5,0xd
    800033d2:	01cb2583          	lw	a1,28(s6)
    800033d6:	9dbd                	addw	a1,a1,a5
    800033d8:	855e                	mv	a0,s7
    800033da:	00000097          	auipc	ra,0x0
    800033de:	cd2080e7          	jalr	-814(ra) # 800030ac <bread>
    800033e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e4:	004b2503          	lw	a0,4(s6)
    800033e8:	000a849b          	sext.w	s1,s5
    800033ec:	8762                	mv	a4,s8
    800033ee:	faa4fde3          	bgeu	s1,a0,800033a8 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033f2:	00777693          	andi	a3,a4,7
    800033f6:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033fa:	41f7579b          	sraiw	a5,a4,0x1f
    800033fe:	01d7d79b          	srliw	a5,a5,0x1d
    80003402:	9fb9                	addw	a5,a5,a4
    80003404:	4037d79b          	sraiw	a5,a5,0x3
    80003408:	00f90633          	add	a2,s2,a5
    8000340c:	05864603          	lbu	a2,88(a2)
    80003410:	00c6f5b3          	and	a1,a3,a2
    80003414:	cd91                	beqz	a1,80003430 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003416:	2705                	addiw	a4,a4,1
    80003418:	2485                	addiw	s1,s1,1
    8000341a:	fd471ae3          	bne	a4,s4,800033ee <balloc+0x80>
    8000341e:	b769                	j	800033a8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003420:	00005517          	auipc	a0,0x5
    80003424:	12850513          	addi	a0,a0,296 # 80008548 <syscalls+0x100>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	112080e7          	jalr	274(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003430:	97ca                	add	a5,a5,s2
    80003432:	8e55                	or	a2,a2,a3
    80003434:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003438:	854a                	mv	a0,s2
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	026080e7          	jalr	38(ra) # 80004460 <log_write>
        brelse(bp);
    80003442:	854a                	mv	a0,s2
    80003444:	00000097          	auipc	ra,0x0
    80003448:	d98080e7          	jalr	-616(ra) # 800031dc <brelse>
  bp = bread(dev, bno);
    8000344c:	85a6                	mv	a1,s1
    8000344e:	855e                	mv	a0,s7
    80003450:	00000097          	auipc	ra,0x0
    80003454:	c5c080e7          	jalr	-932(ra) # 800030ac <bread>
    80003458:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000345a:	40000613          	li	a2,1024
    8000345e:	4581                	li	a1,0
    80003460:	05850513          	addi	a0,a0,88
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	868080e7          	jalr	-1944(ra) # 80000ccc <memset>
  log_write(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	ff2080e7          	jalr	-14(ra) # 80004460 <log_write>
  brelse(bp);
    80003476:	854a                	mv	a0,s2
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	d64080e7          	jalr	-668(ra) # 800031dc <brelse>
}
    80003480:	8526                	mv	a0,s1
    80003482:	60e6                	ld	ra,88(sp)
    80003484:	6446                	ld	s0,80(sp)
    80003486:	64a6                	ld	s1,72(sp)
    80003488:	6906                	ld	s2,64(sp)
    8000348a:	79e2                	ld	s3,56(sp)
    8000348c:	7a42                	ld	s4,48(sp)
    8000348e:	7aa2                	ld	s5,40(sp)
    80003490:	7b02                	ld	s6,32(sp)
    80003492:	6be2                	ld	s7,24(sp)
    80003494:	6c42                	ld	s8,16(sp)
    80003496:	6ca2                	ld	s9,8(sp)
    80003498:	6125                	addi	sp,sp,96
    8000349a:	8082                	ret

000000008000349c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000349c:	7179                	addi	sp,sp,-48
    8000349e:	f406                	sd	ra,40(sp)
    800034a0:	f022                	sd	s0,32(sp)
    800034a2:	ec26                	sd	s1,24(sp)
    800034a4:	e84a                	sd	s2,16(sp)
    800034a6:	e44e                	sd	s3,8(sp)
    800034a8:	e052                	sd	s4,0(sp)
    800034aa:	1800                	addi	s0,sp,48
    800034ac:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034ae:	47ad                	li	a5,11
    800034b0:	04b7fe63          	bgeu	a5,a1,8000350c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034b4:	ff45849b          	addiw	s1,a1,-12
    800034b8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034bc:	0ff00793          	li	a5,255
    800034c0:	0ae7e463          	bltu	a5,a4,80003568 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034c4:	08052583          	lw	a1,128(a0)
    800034c8:	c5b5                	beqz	a1,80003534 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034ca:	00092503          	lw	a0,0(s2)
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	bde080e7          	jalr	-1058(ra) # 800030ac <bread>
    800034d6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034d8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034dc:	02049713          	slli	a4,s1,0x20
    800034e0:	01e75593          	srli	a1,a4,0x1e
    800034e4:	00b784b3          	add	s1,a5,a1
    800034e8:	0004a983          	lw	s3,0(s1)
    800034ec:	04098e63          	beqz	s3,80003548 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034f0:	8552                	mv	a0,s4
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	cea080e7          	jalr	-790(ra) # 800031dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034fa:	854e                	mv	a0,s3
    800034fc:	70a2                	ld	ra,40(sp)
    800034fe:	7402                	ld	s0,32(sp)
    80003500:	64e2                	ld	s1,24(sp)
    80003502:	6942                	ld	s2,16(sp)
    80003504:	69a2                	ld	s3,8(sp)
    80003506:	6a02                	ld	s4,0(sp)
    80003508:	6145                	addi	sp,sp,48
    8000350a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000350c:	02059793          	slli	a5,a1,0x20
    80003510:	01e7d593          	srli	a1,a5,0x1e
    80003514:	00b504b3          	add	s1,a0,a1
    80003518:	0504a983          	lw	s3,80(s1)
    8000351c:	fc099fe3          	bnez	s3,800034fa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003520:	4108                	lw	a0,0(a0)
    80003522:	00000097          	auipc	ra,0x0
    80003526:	e4c080e7          	jalr	-436(ra) # 8000336e <balloc>
    8000352a:	0005099b          	sext.w	s3,a0
    8000352e:	0534a823          	sw	s3,80(s1)
    80003532:	b7e1                	j	800034fa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003534:	4108                	lw	a0,0(a0)
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	e38080e7          	jalr	-456(ra) # 8000336e <balloc>
    8000353e:	0005059b          	sext.w	a1,a0
    80003542:	08b92023          	sw	a1,128(s2)
    80003546:	b751                	j	800034ca <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003548:	00092503          	lw	a0,0(s2)
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	e22080e7          	jalr	-478(ra) # 8000336e <balloc>
    80003554:	0005099b          	sext.w	s3,a0
    80003558:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000355c:	8552                	mv	a0,s4
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	f02080e7          	jalr	-254(ra) # 80004460 <log_write>
    80003566:	b769                	j	800034f0 <bmap+0x54>
  panic("bmap: out of range");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	ff850513          	addi	a0,a0,-8 # 80008560 <syscalls+0x118>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	fca080e7          	jalr	-54(ra) # 8000053a <panic>

0000000080003578 <iget>:
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	e052                	sd	s4,0(sp)
    80003586:	1800                	addi	s0,sp,48
    80003588:	89aa                	mv	s3,a0
    8000358a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000358c:	0001d517          	auipc	a0,0x1d
    80003590:	c3c50513          	addi	a0,a0,-964 # 800201c8 <itable>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	63c080e7          	jalr	1596(ra) # 80000bd0 <acquire>
  empty = 0;
    8000359c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000359e:	0001d497          	auipc	s1,0x1d
    800035a2:	c4248493          	addi	s1,s1,-958 # 800201e0 <itable+0x18>
    800035a6:	0001e697          	auipc	a3,0x1e
    800035aa:	6ca68693          	addi	a3,a3,1738 # 80021c70 <log>
    800035ae:	a039                	j	800035bc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b0:	02090b63          	beqz	s2,800035e6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035b4:	08848493          	addi	s1,s1,136
    800035b8:	02d48a63          	beq	s1,a3,800035ec <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035bc:	449c                	lw	a5,8(s1)
    800035be:	fef059e3          	blez	a5,800035b0 <iget+0x38>
    800035c2:	4098                	lw	a4,0(s1)
    800035c4:	ff3716e3          	bne	a4,s3,800035b0 <iget+0x38>
    800035c8:	40d8                	lw	a4,4(s1)
    800035ca:	ff4713e3          	bne	a4,s4,800035b0 <iget+0x38>
      ip->ref++;
    800035ce:	2785                	addiw	a5,a5,1
    800035d0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035d2:	0001d517          	auipc	a0,0x1d
    800035d6:	bf650513          	addi	a0,a0,-1034 # 800201c8 <itable>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	6aa080e7          	jalr	1706(ra) # 80000c84 <release>
      return ip;
    800035e2:	8926                	mv	s2,s1
    800035e4:	a03d                	j	80003612 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e6:	f7f9                	bnez	a5,800035b4 <iget+0x3c>
    800035e8:	8926                	mv	s2,s1
    800035ea:	b7e9                	j	800035b4 <iget+0x3c>
  if(empty == 0)
    800035ec:	02090c63          	beqz	s2,80003624 <iget+0xac>
  ip->dev = dev;
    800035f0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035f4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035f8:	4785                	li	a5,1
    800035fa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035fe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003602:	0001d517          	auipc	a0,0x1d
    80003606:	bc650513          	addi	a0,a0,-1082 # 800201c8 <itable>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	67a080e7          	jalr	1658(ra) # 80000c84 <release>
}
    80003612:	854a                	mv	a0,s2
    80003614:	70a2                	ld	ra,40(sp)
    80003616:	7402                	ld	s0,32(sp)
    80003618:	64e2                	ld	s1,24(sp)
    8000361a:	6942                	ld	s2,16(sp)
    8000361c:	69a2                	ld	s3,8(sp)
    8000361e:	6a02                	ld	s4,0(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret
    panic("iget: no inodes");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	f5450513          	addi	a0,a0,-172 # 80008578 <syscalls+0x130>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f0e080e7          	jalr	-242(ra) # 8000053a <panic>

0000000080003634 <fsinit>:
fsinit(int dev) {
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	1800                	addi	s0,sp,48
    80003642:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003644:	4585                	li	a1,1
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	a66080e7          	jalr	-1434(ra) # 800030ac <bread>
    8000364e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003650:	0001d997          	auipc	s3,0x1d
    80003654:	b5898993          	addi	s3,s3,-1192 # 800201a8 <sb>
    80003658:	02000613          	li	a2,32
    8000365c:	05850593          	addi	a1,a0,88
    80003660:	854e                	mv	a0,s3
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	6c6080e7          	jalr	1734(ra) # 80000d28 <memmove>
  brelse(bp);
    8000366a:	8526                	mv	a0,s1
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	b70080e7          	jalr	-1168(ra) # 800031dc <brelse>
  if(sb.magic != FSMAGIC)
    80003674:	0009a703          	lw	a4,0(s3)
    80003678:	102037b7          	lui	a5,0x10203
    8000367c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003680:	02f71263          	bne	a4,a5,800036a4 <fsinit+0x70>
  initlog(dev, &sb);
    80003684:	0001d597          	auipc	a1,0x1d
    80003688:	b2458593          	addi	a1,a1,-1244 # 800201a8 <sb>
    8000368c:	854a                	mv	a0,s2
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	b56080e7          	jalr	-1194(ra) # 800041e4 <initlog>
}
    80003696:	70a2                	ld	ra,40(sp)
    80003698:	7402                	ld	s0,32(sp)
    8000369a:	64e2                	ld	s1,24(sp)
    8000369c:	6942                	ld	s2,16(sp)
    8000369e:	69a2                	ld	s3,8(sp)
    800036a0:	6145                	addi	sp,sp,48
    800036a2:	8082                	ret
    panic("invalid file system");
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	ee450513          	addi	a0,a0,-284 # 80008588 <syscalls+0x140>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	e8e080e7          	jalr	-370(ra) # 8000053a <panic>

00000000800036b4 <iinit>:
{
    800036b4:	7179                	addi	sp,sp,-48
    800036b6:	f406                	sd	ra,40(sp)
    800036b8:	f022                	sd	s0,32(sp)
    800036ba:	ec26                	sd	s1,24(sp)
    800036bc:	e84a                	sd	s2,16(sp)
    800036be:	e44e                	sd	s3,8(sp)
    800036c0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036c2:	00005597          	auipc	a1,0x5
    800036c6:	ede58593          	addi	a1,a1,-290 # 800085a0 <syscalls+0x158>
    800036ca:	0001d517          	auipc	a0,0x1d
    800036ce:	afe50513          	addi	a0,a0,-1282 # 800201c8 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	46e080e7          	jalr	1134(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036da:	0001d497          	auipc	s1,0x1d
    800036de:	b1648493          	addi	s1,s1,-1258 # 800201f0 <itable+0x28>
    800036e2:	0001e997          	auipc	s3,0x1e
    800036e6:	59e98993          	addi	s3,s3,1438 # 80021c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036ea:	00005917          	auipc	s2,0x5
    800036ee:	ebe90913          	addi	s2,s2,-322 # 800085a8 <syscalls+0x160>
    800036f2:	85ca                	mv	a1,s2
    800036f4:	8526                	mv	a0,s1
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	e4e080e7          	jalr	-434(ra) # 80004544 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036fe:	08848493          	addi	s1,s1,136
    80003702:	ff3498e3          	bne	s1,s3,800036f2 <iinit+0x3e>
}
    80003706:	70a2                	ld	ra,40(sp)
    80003708:	7402                	ld	s0,32(sp)
    8000370a:	64e2                	ld	s1,24(sp)
    8000370c:	6942                	ld	s2,16(sp)
    8000370e:	69a2                	ld	s3,8(sp)
    80003710:	6145                	addi	sp,sp,48
    80003712:	8082                	ret

0000000080003714 <ialloc>:
{
    80003714:	715d                	addi	sp,sp,-80
    80003716:	e486                	sd	ra,72(sp)
    80003718:	e0a2                	sd	s0,64(sp)
    8000371a:	fc26                	sd	s1,56(sp)
    8000371c:	f84a                	sd	s2,48(sp)
    8000371e:	f44e                	sd	s3,40(sp)
    80003720:	f052                	sd	s4,32(sp)
    80003722:	ec56                	sd	s5,24(sp)
    80003724:	e85a                	sd	s6,16(sp)
    80003726:	e45e                	sd	s7,8(sp)
    80003728:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000372a:	0001d717          	auipc	a4,0x1d
    8000372e:	a8a72703          	lw	a4,-1398(a4) # 800201b4 <sb+0xc>
    80003732:	4785                	li	a5,1
    80003734:	04e7fa63          	bgeu	a5,a4,80003788 <ialloc+0x74>
    80003738:	8aaa                	mv	s5,a0
    8000373a:	8bae                	mv	s7,a1
    8000373c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000373e:	0001da17          	auipc	s4,0x1d
    80003742:	a6aa0a13          	addi	s4,s4,-1430 # 800201a8 <sb>
    80003746:	00048b1b          	sext.w	s6,s1
    8000374a:	0044d593          	srli	a1,s1,0x4
    8000374e:	018a2783          	lw	a5,24(s4)
    80003752:	9dbd                	addw	a1,a1,a5
    80003754:	8556                	mv	a0,s5
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	956080e7          	jalr	-1706(ra) # 800030ac <bread>
    8000375e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003760:	05850993          	addi	s3,a0,88
    80003764:	00f4f793          	andi	a5,s1,15
    80003768:	079a                	slli	a5,a5,0x6
    8000376a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000376c:	00099783          	lh	a5,0(s3)
    80003770:	c785                	beqz	a5,80003798 <ialloc+0x84>
    brelse(bp);
    80003772:	00000097          	auipc	ra,0x0
    80003776:	a6a080e7          	jalr	-1430(ra) # 800031dc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000377a:	0485                	addi	s1,s1,1
    8000377c:	00ca2703          	lw	a4,12(s4)
    80003780:	0004879b          	sext.w	a5,s1
    80003784:	fce7e1e3          	bltu	a5,a4,80003746 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003788:	00005517          	auipc	a0,0x5
    8000378c:	e2850513          	addi	a0,a0,-472 # 800085b0 <syscalls+0x168>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	daa080e7          	jalr	-598(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003798:	04000613          	li	a2,64
    8000379c:	4581                	li	a1,0
    8000379e:	854e                	mv	a0,s3
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	52c080e7          	jalr	1324(ra) # 80000ccc <memset>
      dip->type = type;
    800037a8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ac:	854a                	mv	a0,s2
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	cb2080e7          	jalr	-846(ra) # 80004460 <log_write>
      brelse(bp);
    800037b6:	854a                	mv	a0,s2
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	a24080e7          	jalr	-1500(ra) # 800031dc <brelse>
      return iget(dev, inum);
    800037c0:	85da                	mv	a1,s6
    800037c2:	8556                	mv	a0,s5
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	db4080e7          	jalr	-588(ra) # 80003578 <iget>
}
    800037cc:	60a6                	ld	ra,72(sp)
    800037ce:	6406                	ld	s0,64(sp)
    800037d0:	74e2                	ld	s1,56(sp)
    800037d2:	7942                	ld	s2,48(sp)
    800037d4:	79a2                	ld	s3,40(sp)
    800037d6:	7a02                	ld	s4,32(sp)
    800037d8:	6ae2                	ld	s5,24(sp)
    800037da:	6b42                	ld	s6,16(sp)
    800037dc:	6ba2                	ld	s7,8(sp)
    800037de:	6161                	addi	sp,sp,80
    800037e0:	8082                	ret

00000000800037e2 <iupdate>:
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	e04a                	sd	s2,0(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f0:	415c                	lw	a5,4(a0)
    800037f2:	0047d79b          	srliw	a5,a5,0x4
    800037f6:	0001d597          	auipc	a1,0x1d
    800037fa:	9ca5a583          	lw	a1,-1590(a1) # 800201c0 <sb+0x18>
    800037fe:	9dbd                	addw	a1,a1,a5
    80003800:	4108                	lw	a0,0(a0)
    80003802:	00000097          	auipc	ra,0x0
    80003806:	8aa080e7          	jalr	-1878(ra) # 800030ac <bread>
    8000380a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000380c:	05850793          	addi	a5,a0,88
    80003810:	40d8                	lw	a4,4(s1)
    80003812:	8b3d                	andi	a4,a4,15
    80003814:	071a                	slli	a4,a4,0x6
    80003816:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003818:	04449703          	lh	a4,68(s1)
    8000381c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003820:	04649703          	lh	a4,70(s1)
    80003824:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003828:	04849703          	lh	a4,72(s1)
    8000382c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003830:	04a49703          	lh	a4,74(s1)
    80003834:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003838:	44f8                	lw	a4,76(s1)
    8000383a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000383c:	03400613          	li	a2,52
    80003840:	05048593          	addi	a1,s1,80
    80003844:	00c78513          	addi	a0,a5,12
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	4e0080e7          	jalr	1248(ra) # 80000d28 <memmove>
  log_write(bp);
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	c0e080e7          	jalr	-1010(ra) # 80004460 <log_write>
  brelse(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	980080e7          	jalr	-1664(ra) # 800031dc <brelse>
}
    80003864:	60e2                	ld	ra,24(sp)
    80003866:	6442                	ld	s0,16(sp)
    80003868:	64a2                	ld	s1,8(sp)
    8000386a:	6902                	ld	s2,0(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret

0000000080003870 <idup>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	1000                	addi	s0,sp,32
    8000387a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000387c:	0001d517          	auipc	a0,0x1d
    80003880:	94c50513          	addi	a0,a0,-1716 # 800201c8 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	34c080e7          	jalr	844(ra) # 80000bd0 <acquire>
  ip->ref++;
    8000388c:	449c                	lw	a5,8(s1)
    8000388e:	2785                	addiw	a5,a5,1
    80003890:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003892:	0001d517          	auipc	a0,0x1d
    80003896:	93650513          	addi	a0,a0,-1738 # 800201c8 <itable>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	3ea080e7          	jalr	1002(ra) # 80000c84 <release>
}
    800038a2:	8526                	mv	a0,s1
    800038a4:	60e2                	ld	ra,24(sp)
    800038a6:	6442                	ld	s0,16(sp)
    800038a8:	64a2                	ld	s1,8(sp)
    800038aa:	6105                	addi	sp,sp,32
    800038ac:	8082                	ret

00000000800038ae <ilock>:
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	e04a                	sd	s2,0(sp)
    800038b8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ba:	c115                	beqz	a0,800038de <ilock+0x30>
    800038bc:	84aa                	mv	s1,a0
    800038be:	451c                	lw	a5,8(a0)
    800038c0:	00f05f63          	blez	a5,800038de <ilock+0x30>
  acquiresleep(&ip->lock);
    800038c4:	0541                	addi	a0,a0,16
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	cb8080e7          	jalr	-840(ra) # 8000457e <acquiresleep>
  if(ip->valid == 0){
    800038ce:	40bc                	lw	a5,64(s1)
    800038d0:	cf99                	beqz	a5,800038ee <ilock+0x40>
}
    800038d2:	60e2                	ld	ra,24(sp)
    800038d4:	6442                	ld	s0,16(sp)
    800038d6:	64a2                	ld	s1,8(sp)
    800038d8:	6902                	ld	s2,0(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret
    panic("ilock");
    800038de:	00005517          	auipc	a0,0x5
    800038e2:	cea50513          	addi	a0,a0,-790 # 800085c8 <syscalls+0x180>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	c54080e7          	jalr	-940(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ee:	40dc                	lw	a5,4(s1)
    800038f0:	0047d79b          	srliw	a5,a5,0x4
    800038f4:	0001d597          	auipc	a1,0x1d
    800038f8:	8cc5a583          	lw	a1,-1844(a1) # 800201c0 <sb+0x18>
    800038fc:	9dbd                	addw	a1,a1,a5
    800038fe:	4088                	lw	a0,0(s1)
    80003900:	fffff097          	auipc	ra,0xfffff
    80003904:	7ac080e7          	jalr	1964(ra) # 800030ac <bread>
    80003908:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000390a:	05850593          	addi	a1,a0,88
    8000390e:	40dc                	lw	a5,4(s1)
    80003910:	8bbd                	andi	a5,a5,15
    80003912:	079a                	slli	a5,a5,0x6
    80003914:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003916:	00059783          	lh	a5,0(a1)
    8000391a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000391e:	00259783          	lh	a5,2(a1)
    80003922:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003926:	00459783          	lh	a5,4(a1)
    8000392a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000392e:	00659783          	lh	a5,6(a1)
    80003932:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003936:	459c                	lw	a5,8(a1)
    80003938:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000393a:	03400613          	li	a2,52
    8000393e:	05b1                	addi	a1,a1,12
    80003940:	05048513          	addi	a0,s1,80
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	3e4080e7          	jalr	996(ra) # 80000d28 <memmove>
    brelse(bp);
    8000394c:	854a                	mv	a0,s2
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	88e080e7          	jalr	-1906(ra) # 800031dc <brelse>
    ip->valid = 1;
    80003956:	4785                	li	a5,1
    80003958:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000395a:	04449783          	lh	a5,68(s1)
    8000395e:	fbb5                	bnez	a5,800038d2 <ilock+0x24>
      panic("ilock: no type");
    80003960:	00005517          	auipc	a0,0x5
    80003964:	c7050513          	addi	a0,a0,-912 # 800085d0 <syscalls+0x188>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	bd2080e7          	jalr	-1070(ra) # 8000053a <panic>

0000000080003970 <iunlock>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	e04a                	sd	s2,0(sp)
    8000397a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000397c:	c905                	beqz	a0,800039ac <iunlock+0x3c>
    8000397e:	84aa                	mv	s1,a0
    80003980:	01050913          	addi	s2,a0,16
    80003984:	854a                	mv	a0,s2
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	c92080e7          	jalr	-878(ra) # 80004618 <holdingsleep>
    8000398e:	cd19                	beqz	a0,800039ac <iunlock+0x3c>
    80003990:	449c                	lw	a5,8(s1)
    80003992:	00f05d63          	blez	a5,800039ac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003996:	854a                	mv	a0,s2
    80003998:	00001097          	auipc	ra,0x1
    8000399c:	c3c080e7          	jalr	-964(ra) # 800045d4 <releasesleep>
}
    800039a0:	60e2                	ld	ra,24(sp)
    800039a2:	6442                	ld	s0,16(sp)
    800039a4:	64a2                	ld	s1,8(sp)
    800039a6:	6902                	ld	s2,0(sp)
    800039a8:	6105                	addi	sp,sp,32
    800039aa:	8082                	ret
    panic("iunlock");
    800039ac:	00005517          	auipc	a0,0x5
    800039b0:	c3450513          	addi	a0,a0,-972 # 800085e0 <syscalls+0x198>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	b86080e7          	jalr	-1146(ra) # 8000053a <panic>

00000000800039bc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039bc:	7179                	addi	sp,sp,-48
    800039be:	f406                	sd	ra,40(sp)
    800039c0:	f022                	sd	s0,32(sp)
    800039c2:	ec26                	sd	s1,24(sp)
    800039c4:	e84a                	sd	s2,16(sp)
    800039c6:	e44e                	sd	s3,8(sp)
    800039c8:	e052                	sd	s4,0(sp)
    800039ca:	1800                	addi	s0,sp,48
    800039cc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039ce:	05050493          	addi	s1,a0,80
    800039d2:	08050913          	addi	s2,a0,128
    800039d6:	a021                	j	800039de <itrunc+0x22>
    800039d8:	0491                	addi	s1,s1,4
    800039da:	01248d63          	beq	s1,s2,800039f4 <itrunc+0x38>
    if(ip->addrs[i]){
    800039de:	408c                	lw	a1,0(s1)
    800039e0:	dde5                	beqz	a1,800039d8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039e2:	0009a503          	lw	a0,0(s3)
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	90c080e7          	jalr	-1780(ra) # 800032f2 <bfree>
      ip->addrs[i] = 0;
    800039ee:	0004a023          	sw	zero,0(s1)
    800039f2:	b7dd                	j	800039d8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039f4:	0809a583          	lw	a1,128(s3)
    800039f8:	e185                	bnez	a1,80003a18 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039fa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039fe:	854e                	mv	a0,s3
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	de2080e7          	jalr	-542(ra) # 800037e2 <iupdate>
}
    80003a08:	70a2                	ld	ra,40(sp)
    80003a0a:	7402                	ld	s0,32(sp)
    80003a0c:	64e2                	ld	s1,24(sp)
    80003a0e:	6942                	ld	s2,16(sp)
    80003a10:	69a2                	ld	s3,8(sp)
    80003a12:	6a02                	ld	s4,0(sp)
    80003a14:	6145                	addi	sp,sp,48
    80003a16:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a18:	0009a503          	lw	a0,0(s3)
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	690080e7          	jalr	1680(ra) # 800030ac <bread>
    80003a24:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a26:	05850493          	addi	s1,a0,88
    80003a2a:	45850913          	addi	s2,a0,1112
    80003a2e:	a021                	j	80003a36 <itrunc+0x7a>
    80003a30:	0491                	addi	s1,s1,4
    80003a32:	01248b63          	beq	s1,s2,80003a48 <itrunc+0x8c>
      if(a[j])
    80003a36:	408c                	lw	a1,0(s1)
    80003a38:	dde5                	beqz	a1,80003a30 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a3a:	0009a503          	lw	a0,0(s3)
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	8b4080e7          	jalr	-1868(ra) # 800032f2 <bfree>
    80003a46:	b7ed                	j	80003a30 <itrunc+0x74>
    brelse(bp);
    80003a48:	8552                	mv	a0,s4
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	792080e7          	jalr	1938(ra) # 800031dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a52:	0809a583          	lw	a1,128(s3)
    80003a56:	0009a503          	lw	a0,0(s3)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	898080e7          	jalr	-1896(ra) # 800032f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a62:	0809a023          	sw	zero,128(s3)
    80003a66:	bf51                	j	800039fa <itrunc+0x3e>

0000000080003a68 <iput>:
{
    80003a68:	1101                	addi	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	e426                	sd	s1,8(sp)
    80003a70:	e04a                	sd	s2,0(sp)
    80003a72:	1000                	addi	s0,sp,32
    80003a74:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a76:	0001c517          	auipc	a0,0x1c
    80003a7a:	75250513          	addi	a0,a0,1874 # 800201c8 <itable>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	152080e7          	jalr	338(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a86:	4498                	lw	a4,8(s1)
    80003a88:	4785                	li	a5,1
    80003a8a:	02f70363          	beq	a4,a5,80003ab0 <iput+0x48>
  ip->ref--;
    80003a8e:	449c                	lw	a5,8(s1)
    80003a90:	37fd                	addiw	a5,a5,-1
    80003a92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a94:	0001c517          	auipc	a0,0x1c
    80003a98:	73450513          	addi	a0,a0,1844 # 800201c8 <itable>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	1e8080e7          	jalr	488(ra) # 80000c84 <release>
}
    80003aa4:	60e2                	ld	ra,24(sp)
    80003aa6:	6442                	ld	s0,16(sp)
    80003aa8:	64a2                	ld	s1,8(sp)
    80003aaa:	6902                	ld	s2,0(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab0:	40bc                	lw	a5,64(s1)
    80003ab2:	dff1                	beqz	a5,80003a8e <iput+0x26>
    80003ab4:	04a49783          	lh	a5,74(s1)
    80003ab8:	fbf9                	bnez	a5,80003a8e <iput+0x26>
    acquiresleep(&ip->lock);
    80003aba:	01048913          	addi	s2,s1,16
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	abe080e7          	jalr	-1346(ra) # 8000457e <acquiresleep>
    release(&itable.lock);
    80003ac8:	0001c517          	auipc	a0,0x1c
    80003acc:	70050513          	addi	a0,a0,1792 # 800201c8 <itable>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	1b4080e7          	jalr	436(ra) # 80000c84 <release>
    itrunc(ip);
    80003ad8:	8526                	mv	a0,s1
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	ee2080e7          	jalr	-286(ra) # 800039bc <itrunc>
    ip->type = 0;
    80003ae2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	cfa080e7          	jalr	-774(ra) # 800037e2 <iupdate>
    ip->valid = 0;
    80003af0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	ade080e7          	jalr	-1314(ra) # 800045d4 <releasesleep>
    acquire(&itable.lock);
    80003afe:	0001c517          	auipc	a0,0x1c
    80003b02:	6ca50513          	addi	a0,a0,1738 # 800201c8 <itable>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	0ca080e7          	jalr	202(ra) # 80000bd0 <acquire>
    80003b0e:	b741                	j	80003a8e <iput+0x26>

0000000080003b10 <iunlockput>:
{
    80003b10:	1101                	addi	sp,sp,-32
    80003b12:	ec06                	sd	ra,24(sp)
    80003b14:	e822                	sd	s0,16(sp)
    80003b16:	e426                	sd	s1,8(sp)
    80003b18:	1000                	addi	s0,sp,32
    80003b1a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	e54080e7          	jalr	-428(ra) # 80003970 <iunlock>
  iput(ip);
    80003b24:	8526                	mv	a0,s1
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	f42080e7          	jalr	-190(ra) # 80003a68 <iput>
}
    80003b2e:	60e2                	ld	ra,24(sp)
    80003b30:	6442                	ld	s0,16(sp)
    80003b32:	64a2                	ld	s1,8(sp)
    80003b34:	6105                	addi	sp,sp,32
    80003b36:	8082                	ret

0000000080003b38 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b38:	1141                	addi	sp,sp,-16
    80003b3a:	e422                	sd	s0,8(sp)
    80003b3c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b3e:	411c                	lw	a5,0(a0)
    80003b40:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b42:	415c                	lw	a5,4(a0)
    80003b44:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b46:	04451783          	lh	a5,68(a0)
    80003b4a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b4e:	04a51783          	lh	a5,74(a0)
    80003b52:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b56:	04c56783          	lwu	a5,76(a0)
    80003b5a:	e99c                	sd	a5,16(a1)
}
    80003b5c:	6422                	ld	s0,8(sp)
    80003b5e:	0141                	addi	sp,sp,16
    80003b60:	8082                	ret

0000000080003b62 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b62:	457c                	lw	a5,76(a0)
    80003b64:	0ed7e963          	bltu	a5,a3,80003c56 <readi+0xf4>
{
    80003b68:	7159                	addi	sp,sp,-112
    80003b6a:	f486                	sd	ra,104(sp)
    80003b6c:	f0a2                	sd	s0,96(sp)
    80003b6e:	eca6                	sd	s1,88(sp)
    80003b70:	e8ca                	sd	s2,80(sp)
    80003b72:	e4ce                	sd	s3,72(sp)
    80003b74:	e0d2                	sd	s4,64(sp)
    80003b76:	fc56                	sd	s5,56(sp)
    80003b78:	f85a                	sd	s6,48(sp)
    80003b7a:	f45e                	sd	s7,40(sp)
    80003b7c:	f062                	sd	s8,32(sp)
    80003b7e:	ec66                	sd	s9,24(sp)
    80003b80:	e86a                	sd	s10,16(sp)
    80003b82:	e46e                	sd	s11,8(sp)
    80003b84:	1880                	addi	s0,sp,112
    80003b86:	8baa                	mv	s7,a0
    80003b88:	8c2e                	mv	s8,a1
    80003b8a:	8ab2                	mv	s5,a2
    80003b8c:	84b6                	mv	s1,a3
    80003b8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b90:	9f35                	addw	a4,a4,a3
    return 0;
    80003b92:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b94:	0ad76063          	bltu	a4,a3,80003c34 <readi+0xd2>
  if(off + n > ip->size)
    80003b98:	00e7f463          	bgeu	a5,a4,80003ba0 <readi+0x3e>
    n = ip->size - off;
    80003b9c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba0:	0a0b0963          	beqz	s6,80003c52 <readi+0xf0>
    80003ba4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003baa:	5cfd                	li	s9,-1
    80003bac:	a82d                	j	80003be6 <readi+0x84>
    80003bae:	020a1d93          	slli	s11,s4,0x20
    80003bb2:	020ddd93          	srli	s11,s11,0x20
    80003bb6:	05890613          	addi	a2,s2,88
    80003bba:	86ee                	mv	a3,s11
    80003bbc:	963a                	add	a2,a2,a4
    80003bbe:	85d6                	mv	a1,s5
    80003bc0:	8562                	mv	a0,s8
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	864080e7          	jalr	-1948(ra) # 80002426 <either_copyout>
    80003bca:	05950d63          	beq	a0,s9,80003c24 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bce:	854a                	mv	a0,s2
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	60c080e7          	jalr	1548(ra) # 800031dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd8:	013a09bb          	addw	s3,s4,s3
    80003bdc:	009a04bb          	addw	s1,s4,s1
    80003be0:	9aee                	add	s5,s5,s11
    80003be2:	0569f763          	bgeu	s3,s6,80003c30 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003be6:	000ba903          	lw	s2,0(s7)
    80003bea:	00a4d59b          	srliw	a1,s1,0xa
    80003bee:	855e                	mv	a0,s7
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	8ac080e7          	jalr	-1876(ra) # 8000349c <bmap>
    80003bf8:	0005059b          	sext.w	a1,a0
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	4ae080e7          	jalr	1198(ra) # 800030ac <bread>
    80003c06:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c08:	3ff4f713          	andi	a4,s1,1023
    80003c0c:	40ed07bb          	subw	a5,s10,a4
    80003c10:	413b06bb          	subw	a3,s6,s3
    80003c14:	8a3e                	mv	s4,a5
    80003c16:	2781                	sext.w	a5,a5
    80003c18:	0006861b          	sext.w	a2,a3
    80003c1c:	f8f679e3          	bgeu	a2,a5,80003bae <readi+0x4c>
    80003c20:	8a36                	mv	s4,a3
    80003c22:	b771                	j	80003bae <readi+0x4c>
      brelse(bp);
    80003c24:	854a                	mv	a0,s2
    80003c26:	fffff097          	auipc	ra,0xfffff
    80003c2a:	5b6080e7          	jalr	1462(ra) # 800031dc <brelse>
      tot = -1;
    80003c2e:	59fd                	li	s3,-1
  }
  return tot;
    80003c30:	0009851b          	sext.w	a0,s3
}
    80003c34:	70a6                	ld	ra,104(sp)
    80003c36:	7406                	ld	s0,96(sp)
    80003c38:	64e6                	ld	s1,88(sp)
    80003c3a:	6946                	ld	s2,80(sp)
    80003c3c:	69a6                	ld	s3,72(sp)
    80003c3e:	6a06                	ld	s4,64(sp)
    80003c40:	7ae2                	ld	s5,56(sp)
    80003c42:	7b42                	ld	s6,48(sp)
    80003c44:	7ba2                	ld	s7,40(sp)
    80003c46:	7c02                	ld	s8,32(sp)
    80003c48:	6ce2                	ld	s9,24(sp)
    80003c4a:	6d42                	ld	s10,16(sp)
    80003c4c:	6da2                	ld	s11,8(sp)
    80003c4e:	6165                	addi	sp,sp,112
    80003c50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c52:	89da                	mv	s3,s6
    80003c54:	bff1                	j	80003c30 <readi+0xce>
    return 0;
    80003c56:	4501                	li	a0,0
}
    80003c58:	8082                	ret

0000000080003c5a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c5a:	457c                	lw	a5,76(a0)
    80003c5c:	10d7e863          	bltu	a5,a3,80003d6c <writei+0x112>
{
    80003c60:	7159                	addi	sp,sp,-112
    80003c62:	f486                	sd	ra,104(sp)
    80003c64:	f0a2                	sd	s0,96(sp)
    80003c66:	eca6                	sd	s1,88(sp)
    80003c68:	e8ca                	sd	s2,80(sp)
    80003c6a:	e4ce                	sd	s3,72(sp)
    80003c6c:	e0d2                	sd	s4,64(sp)
    80003c6e:	fc56                	sd	s5,56(sp)
    80003c70:	f85a                	sd	s6,48(sp)
    80003c72:	f45e                	sd	s7,40(sp)
    80003c74:	f062                	sd	s8,32(sp)
    80003c76:	ec66                	sd	s9,24(sp)
    80003c78:	e86a                	sd	s10,16(sp)
    80003c7a:	e46e                	sd	s11,8(sp)
    80003c7c:	1880                	addi	s0,sp,112
    80003c7e:	8b2a                	mv	s6,a0
    80003c80:	8c2e                	mv	s8,a1
    80003c82:	8ab2                	mv	s5,a2
    80003c84:	8936                	mv	s2,a3
    80003c86:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c88:	00e687bb          	addw	a5,a3,a4
    80003c8c:	0ed7e263          	bltu	a5,a3,80003d70 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c90:	00043737          	lui	a4,0x43
    80003c94:	0ef76063          	bltu	a4,a5,80003d74 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c98:	0c0b8863          	beqz	s7,80003d68 <writei+0x10e>
    80003c9c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ca2:	5cfd                	li	s9,-1
    80003ca4:	a091                	j	80003ce8 <writei+0x8e>
    80003ca6:	02099d93          	slli	s11,s3,0x20
    80003caa:	020ddd93          	srli	s11,s11,0x20
    80003cae:	05848513          	addi	a0,s1,88
    80003cb2:	86ee                	mv	a3,s11
    80003cb4:	8656                	mv	a2,s5
    80003cb6:	85e2                	mv	a1,s8
    80003cb8:	953a                	add	a0,a0,a4
    80003cba:	ffffe097          	auipc	ra,0xffffe
    80003cbe:	7c2080e7          	jalr	1986(ra) # 8000247c <either_copyin>
    80003cc2:	07950263          	beq	a0,s9,80003d26 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cc6:	8526                	mv	a0,s1
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	798080e7          	jalr	1944(ra) # 80004460 <log_write>
    brelse(bp);
    80003cd0:	8526                	mv	a0,s1
    80003cd2:	fffff097          	auipc	ra,0xfffff
    80003cd6:	50a080e7          	jalr	1290(ra) # 800031dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cda:	01498a3b          	addw	s4,s3,s4
    80003cde:	0129893b          	addw	s2,s3,s2
    80003ce2:	9aee                	add	s5,s5,s11
    80003ce4:	057a7663          	bgeu	s4,s7,80003d30 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ce8:	000b2483          	lw	s1,0(s6)
    80003cec:	00a9559b          	srliw	a1,s2,0xa
    80003cf0:	855a                	mv	a0,s6
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	7aa080e7          	jalr	1962(ra) # 8000349c <bmap>
    80003cfa:	0005059b          	sext.w	a1,a0
    80003cfe:	8526                	mv	a0,s1
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	3ac080e7          	jalr	940(ra) # 800030ac <bread>
    80003d08:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d0a:	3ff97713          	andi	a4,s2,1023
    80003d0e:	40ed07bb          	subw	a5,s10,a4
    80003d12:	414b86bb          	subw	a3,s7,s4
    80003d16:	89be                	mv	s3,a5
    80003d18:	2781                	sext.w	a5,a5
    80003d1a:	0006861b          	sext.w	a2,a3
    80003d1e:	f8f674e3          	bgeu	a2,a5,80003ca6 <writei+0x4c>
    80003d22:	89b6                	mv	s3,a3
    80003d24:	b749                	j	80003ca6 <writei+0x4c>
      brelse(bp);
    80003d26:	8526                	mv	a0,s1
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	4b4080e7          	jalr	1204(ra) # 800031dc <brelse>
  }

  if(off > ip->size)
    80003d30:	04cb2783          	lw	a5,76(s6)
    80003d34:	0127f463          	bgeu	a5,s2,80003d3c <writei+0xe2>
    ip->size = off;
    80003d38:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d3c:	855a                	mv	a0,s6
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	aa4080e7          	jalr	-1372(ra) # 800037e2 <iupdate>

  return tot;
    80003d46:	000a051b          	sext.w	a0,s4
}
    80003d4a:	70a6                	ld	ra,104(sp)
    80003d4c:	7406                	ld	s0,96(sp)
    80003d4e:	64e6                	ld	s1,88(sp)
    80003d50:	6946                	ld	s2,80(sp)
    80003d52:	69a6                	ld	s3,72(sp)
    80003d54:	6a06                	ld	s4,64(sp)
    80003d56:	7ae2                	ld	s5,56(sp)
    80003d58:	7b42                	ld	s6,48(sp)
    80003d5a:	7ba2                	ld	s7,40(sp)
    80003d5c:	7c02                	ld	s8,32(sp)
    80003d5e:	6ce2                	ld	s9,24(sp)
    80003d60:	6d42                	ld	s10,16(sp)
    80003d62:	6da2                	ld	s11,8(sp)
    80003d64:	6165                	addi	sp,sp,112
    80003d66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d68:	8a5e                	mv	s4,s7
    80003d6a:	bfc9                	j	80003d3c <writei+0xe2>
    return -1;
    80003d6c:	557d                	li	a0,-1
}
    80003d6e:	8082                	ret
    return -1;
    80003d70:	557d                	li	a0,-1
    80003d72:	bfe1                	j	80003d4a <writei+0xf0>
    return -1;
    80003d74:	557d                	li	a0,-1
    80003d76:	bfd1                	j	80003d4a <writei+0xf0>

0000000080003d78 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d78:	1141                	addi	sp,sp,-16
    80003d7a:	e406                	sd	ra,8(sp)
    80003d7c:	e022                	sd	s0,0(sp)
    80003d7e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d80:	4639                	li	a2,14
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	01a080e7          	jalr	26(ra) # 80000d9c <strncmp>
}
    80003d8a:	60a2                	ld	ra,8(sp)
    80003d8c:	6402                	ld	s0,0(sp)
    80003d8e:	0141                	addi	sp,sp,16
    80003d90:	8082                	ret

0000000080003d92 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d92:	7139                	addi	sp,sp,-64
    80003d94:	fc06                	sd	ra,56(sp)
    80003d96:	f822                	sd	s0,48(sp)
    80003d98:	f426                	sd	s1,40(sp)
    80003d9a:	f04a                	sd	s2,32(sp)
    80003d9c:	ec4e                	sd	s3,24(sp)
    80003d9e:	e852                	sd	s4,16(sp)
    80003da0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003da2:	04451703          	lh	a4,68(a0)
    80003da6:	4785                	li	a5,1
    80003da8:	00f71a63          	bne	a4,a5,80003dbc <dirlookup+0x2a>
    80003dac:	892a                	mv	s2,a0
    80003dae:	89ae                	mv	s3,a1
    80003db0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db2:	457c                	lw	a5,76(a0)
    80003db4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003db6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db8:	e79d                	bnez	a5,80003de6 <dirlookup+0x54>
    80003dba:	a8a5                	j	80003e32 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	82c50513          	addi	a0,a0,-2004 # 800085e8 <syscalls+0x1a0>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	776080e7          	jalr	1910(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003dcc:	00005517          	auipc	a0,0x5
    80003dd0:	83450513          	addi	a0,a0,-1996 # 80008600 <syscalls+0x1b8>
    80003dd4:	ffffc097          	auipc	ra,0xffffc
    80003dd8:	766080e7          	jalr	1894(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ddc:	24c1                	addiw	s1,s1,16
    80003dde:	04c92783          	lw	a5,76(s2)
    80003de2:	04f4f763          	bgeu	s1,a5,80003e30 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de6:	4741                	li	a4,16
    80003de8:	86a6                	mv	a3,s1
    80003dea:	fc040613          	addi	a2,s0,-64
    80003dee:	4581                	li	a1,0
    80003df0:	854a                	mv	a0,s2
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	d70080e7          	jalr	-656(ra) # 80003b62 <readi>
    80003dfa:	47c1                	li	a5,16
    80003dfc:	fcf518e3          	bne	a0,a5,80003dcc <dirlookup+0x3a>
    if(de.inum == 0)
    80003e00:	fc045783          	lhu	a5,-64(s0)
    80003e04:	dfe1                	beqz	a5,80003ddc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e06:	fc240593          	addi	a1,s0,-62
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	f6c080e7          	jalr	-148(ra) # 80003d78 <namecmp>
    80003e14:	f561                	bnez	a0,80003ddc <dirlookup+0x4a>
      if(poff)
    80003e16:	000a0463          	beqz	s4,80003e1e <dirlookup+0x8c>
        *poff = off;
    80003e1a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e1e:	fc045583          	lhu	a1,-64(s0)
    80003e22:	00092503          	lw	a0,0(s2)
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	752080e7          	jalr	1874(ra) # 80003578 <iget>
    80003e2e:	a011                	j	80003e32 <dirlookup+0xa0>
  return 0;
    80003e30:	4501                	li	a0,0
}
    80003e32:	70e2                	ld	ra,56(sp)
    80003e34:	7442                	ld	s0,48(sp)
    80003e36:	74a2                	ld	s1,40(sp)
    80003e38:	7902                	ld	s2,32(sp)
    80003e3a:	69e2                	ld	s3,24(sp)
    80003e3c:	6a42                	ld	s4,16(sp)
    80003e3e:	6121                	addi	sp,sp,64
    80003e40:	8082                	ret

0000000080003e42 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e42:	711d                	addi	sp,sp,-96
    80003e44:	ec86                	sd	ra,88(sp)
    80003e46:	e8a2                	sd	s0,80(sp)
    80003e48:	e4a6                	sd	s1,72(sp)
    80003e4a:	e0ca                	sd	s2,64(sp)
    80003e4c:	fc4e                	sd	s3,56(sp)
    80003e4e:	f852                	sd	s4,48(sp)
    80003e50:	f456                	sd	s5,40(sp)
    80003e52:	f05a                	sd	s6,32(sp)
    80003e54:	ec5e                	sd	s7,24(sp)
    80003e56:	e862                	sd	s8,16(sp)
    80003e58:	e466                	sd	s9,8(sp)
    80003e5a:	e06a                	sd	s10,0(sp)
    80003e5c:	1080                	addi	s0,sp,96
    80003e5e:	84aa                	mv	s1,a0
    80003e60:	8b2e                	mv	s6,a1
    80003e62:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e64:	00054703          	lbu	a4,0(a0)
    80003e68:	02f00793          	li	a5,47
    80003e6c:	02f70363          	beq	a4,a5,80003e92 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e70:	ffffe097          	auipc	ra,0xffffe
    80003e74:	b26080e7          	jalr	-1242(ra) # 80001996 <myproc>
    80003e78:	15053503          	ld	a0,336(a0)
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	9f4080e7          	jalr	-1548(ra) # 80003870 <idup>
    80003e84:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e86:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e8a:	4cb5                	li	s9,13
  len = path - s;
    80003e8c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e8e:	4c05                	li	s8,1
    80003e90:	a87d                	j	80003f4e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e92:	4585                	li	a1,1
    80003e94:	4505                	li	a0,1
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	6e2080e7          	jalr	1762(ra) # 80003578 <iget>
    80003e9e:	8a2a                	mv	s4,a0
    80003ea0:	b7dd                	j	80003e86 <namex+0x44>
      iunlockput(ip);
    80003ea2:	8552                	mv	a0,s4
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	c6c080e7          	jalr	-916(ra) # 80003b10 <iunlockput>
      return 0;
    80003eac:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eae:	8552                	mv	a0,s4
    80003eb0:	60e6                	ld	ra,88(sp)
    80003eb2:	6446                	ld	s0,80(sp)
    80003eb4:	64a6                	ld	s1,72(sp)
    80003eb6:	6906                	ld	s2,64(sp)
    80003eb8:	79e2                	ld	s3,56(sp)
    80003eba:	7a42                	ld	s4,48(sp)
    80003ebc:	7aa2                	ld	s5,40(sp)
    80003ebe:	7b02                	ld	s6,32(sp)
    80003ec0:	6be2                	ld	s7,24(sp)
    80003ec2:	6c42                	ld	s8,16(sp)
    80003ec4:	6ca2                	ld	s9,8(sp)
    80003ec6:	6d02                	ld	s10,0(sp)
    80003ec8:	6125                	addi	sp,sp,96
    80003eca:	8082                	ret
      iunlock(ip);
    80003ecc:	8552                	mv	a0,s4
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	aa2080e7          	jalr	-1374(ra) # 80003970 <iunlock>
      return ip;
    80003ed6:	bfe1                	j	80003eae <namex+0x6c>
      iunlockput(ip);
    80003ed8:	8552                	mv	a0,s4
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	c36080e7          	jalr	-970(ra) # 80003b10 <iunlockput>
      return 0;
    80003ee2:	8a4e                	mv	s4,s3
    80003ee4:	b7e9                	j	80003eae <namex+0x6c>
  len = path - s;
    80003ee6:	40998633          	sub	a2,s3,s1
    80003eea:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003eee:	09acd863          	bge	s9,s10,80003f7e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003ef2:	4639                	li	a2,14
    80003ef4:	85a6                	mv	a1,s1
    80003ef6:	8556                	mv	a0,s5
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e30080e7          	jalr	-464(ra) # 80000d28 <memmove>
    80003f00:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	01279763          	bne	a5,s2,80003f14 <namex+0xd2>
    path++;
    80003f0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0c:	0004c783          	lbu	a5,0(s1)
    80003f10:	ff278de3          	beq	a5,s2,80003f0a <namex+0xc8>
    ilock(ip);
    80003f14:	8552                	mv	a0,s4
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	998080e7          	jalr	-1640(ra) # 800038ae <ilock>
    if(ip->type != T_DIR){
    80003f1e:	044a1783          	lh	a5,68(s4)
    80003f22:	f98790e3          	bne	a5,s8,80003ea2 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003f26:	000b0563          	beqz	s6,80003f30 <namex+0xee>
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	dfd9                	beqz	a5,80003ecc <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f30:	865e                	mv	a2,s7
    80003f32:	85d6                	mv	a1,s5
    80003f34:	8552                	mv	a0,s4
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	e5c080e7          	jalr	-420(ra) # 80003d92 <dirlookup>
    80003f3e:	89aa                	mv	s3,a0
    80003f40:	dd41                	beqz	a0,80003ed8 <namex+0x96>
    iunlockput(ip);
    80003f42:	8552                	mv	a0,s4
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	bcc080e7          	jalr	-1076(ra) # 80003b10 <iunlockput>
    ip = next;
    80003f4c:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f4e:	0004c783          	lbu	a5,0(s1)
    80003f52:	01279763          	bne	a5,s2,80003f60 <namex+0x11e>
    path++;
    80003f56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f58:	0004c783          	lbu	a5,0(s1)
    80003f5c:	ff278de3          	beq	a5,s2,80003f56 <namex+0x114>
  if(*path == 0)
    80003f60:	cb9d                	beqz	a5,80003f96 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003f62:	0004c783          	lbu	a5,0(s1)
    80003f66:	89a6                	mv	s3,s1
  len = path - s;
    80003f68:	8d5e                	mv	s10,s7
    80003f6a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f6c:	01278963          	beq	a5,s2,80003f7e <namex+0x13c>
    80003f70:	dbbd                	beqz	a5,80003ee6 <namex+0xa4>
    path++;
    80003f72:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f74:	0009c783          	lbu	a5,0(s3)
    80003f78:	ff279ce3          	bne	a5,s2,80003f70 <namex+0x12e>
    80003f7c:	b7ad                	j	80003ee6 <namex+0xa4>
    memmove(name, s, len);
    80003f7e:	2601                	sext.w	a2,a2
    80003f80:	85a6                	mv	a1,s1
    80003f82:	8556                	mv	a0,s5
    80003f84:	ffffd097          	auipc	ra,0xffffd
    80003f88:	da4080e7          	jalr	-604(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003f8c:	9d56                	add	s10,s10,s5
    80003f8e:	000d0023          	sb	zero,0(s10)
    80003f92:	84ce                	mv	s1,s3
    80003f94:	b7bd                	j	80003f02 <namex+0xc0>
  if(nameiparent){
    80003f96:	f00b0ce3          	beqz	s6,80003eae <namex+0x6c>
    iput(ip);
    80003f9a:	8552                	mv	a0,s4
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	acc080e7          	jalr	-1332(ra) # 80003a68 <iput>
    return 0;
    80003fa4:	4a01                	li	s4,0
    80003fa6:	b721                	j	80003eae <namex+0x6c>

0000000080003fa8 <dirlink>:
{
    80003fa8:	7139                	addi	sp,sp,-64
    80003faa:	fc06                	sd	ra,56(sp)
    80003fac:	f822                	sd	s0,48(sp)
    80003fae:	f426                	sd	s1,40(sp)
    80003fb0:	f04a                	sd	s2,32(sp)
    80003fb2:	ec4e                	sd	s3,24(sp)
    80003fb4:	e852                	sd	s4,16(sp)
    80003fb6:	0080                	addi	s0,sp,64
    80003fb8:	892a                	mv	s2,a0
    80003fba:	8a2e                	mv	s4,a1
    80003fbc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fbe:	4601                	li	a2,0
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	dd2080e7          	jalr	-558(ra) # 80003d92 <dirlookup>
    80003fc8:	e93d                	bnez	a0,8000403e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fca:	04c92483          	lw	s1,76(s2)
    80003fce:	c49d                	beqz	s1,80003ffc <dirlink+0x54>
    80003fd0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd2:	4741                	li	a4,16
    80003fd4:	86a6                	mv	a3,s1
    80003fd6:	fc040613          	addi	a2,s0,-64
    80003fda:	4581                	li	a1,0
    80003fdc:	854a                	mv	a0,s2
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	b84080e7          	jalr	-1148(ra) # 80003b62 <readi>
    80003fe6:	47c1                	li	a5,16
    80003fe8:	06f51163          	bne	a0,a5,8000404a <dirlink+0xa2>
    if(de.inum == 0)
    80003fec:	fc045783          	lhu	a5,-64(s0)
    80003ff0:	c791                	beqz	a5,80003ffc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	24c1                	addiw	s1,s1,16
    80003ff4:	04c92783          	lw	a5,76(s2)
    80003ff8:	fcf4ede3          	bltu	s1,a5,80003fd2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ffc:	4639                	li	a2,14
    80003ffe:	85d2                	mv	a1,s4
    80004000:	fc240513          	addi	a0,s0,-62
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	dd4080e7          	jalr	-556(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    8000400c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004010:	4741                	li	a4,16
    80004012:	86a6                	mv	a3,s1
    80004014:	fc040613          	addi	a2,s0,-64
    80004018:	4581                	li	a1,0
    8000401a:	854a                	mv	a0,s2
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	c3e080e7          	jalr	-962(ra) # 80003c5a <writei>
    80004024:	872a                	mv	a4,a0
    80004026:	47c1                	li	a5,16
  return 0;
    80004028:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402a:	02f71863          	bne	a4,a5,8000405a <dirlink+0xb2>
}
    8000402e:	70e2                	ld	ra,56(sp)
    80004030:	7442                	ld	s0,48(sp)
    80004032:	74a2                	ld	s1,40(sp)
    80004034:	7902                	ld	s2,32(sp)
    80004036:	69e2                	ld	s3,24(sp)
    80004038:	6a42                	ld	s4,16(sp)
    8000403a:	6121                	addi	sp,sp,64
    8000403c:	8082                	ret
    iput(ip);
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	a2a080e7          	jalr	-1494(ra) # 80003a68 <iput>
    return -1;
    80004046:	557d                	li	a0,-1
    80004048:	b7dd                	j	8000402e <dirlink+0x86>
      panic("dirlink read");
    8000404a:	00004517          	auipc	a0,0x4
    8000404e:	5c650513          	addi	a0,a0,1478 # 80008610 <syscalls+0x1c8>
    80004052:	ffffc097          	auipc	ra,0xffffc
    80004056:	4e8080e7          	jalr	1256(ra) # 8000053a <panic>
    panic("dirlink");
    8000405a:	00004517          	auipc	a0,0x4
    8000405e:	6c650513          	addi	a0,a0,1734 # 80008720 <syscalls+0x2d8>
    80004062:	ffffc097          	auipc	ra,0xffffc
    80004066:	4d8080e7          	jalr	1240(ra) # 8000053a <panic>

000000008000406a <namei>:

struct inode*
namei(char *path)
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004072:	fe040613          	addi	a2,s0,-32
    80004076:	4581                	li	a1,0
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	dca080e7          	jalr	-566(ra) # 80003e42 <namex>
}
    80004080:	60e2                	ld	ra,24(sp)
    80004082:	6442                	ld	s0,16(sp)
    80004084:	6105                	addi	sp,sp,32
    80004086:	8082                	ret

0000000080004088 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004088:	1141                	addi	sp,sp,-16
    8000408a:	e406                	sd	ra,8(sp)
    8000408c:	e022                	sd	s0,0(sp)
    8000408e:	0800                	addi	s0,sp,16
    80004090:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004092:	4585                	li	a1,1
    80004094:	00000097          	auipc	ra,0x0
    80004098:	dae080e7          	jalr	-594(ra) # 80003e42 <namex>
}
    8000409c:	60a2                	ld	ra,8(sp)
    8000409e:	6402                	ld	s0,0(sp)
    800040a0:	0141                	addi	sp,sp,16
    800040a2:	8082                	ret

00000000800040a4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040a4:	1101                	addi	sp,sp,-32
    800040a6:	ec06                	sd	ra,24(sp)
    800040a8:	e822                	sd	s0,16(sp)
    800040aa:	e426                	sd	s1,8(sp)
    800040ac:	e04a                	sd	s2,0(sp)
    800040ae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040b0:	0001e917          	auipc	s2,0x1e
    800040b4:	bc090913          	addi	s2,s2,-1088 # 80021c70 <log>
    800040b8:	01892583          	lw	a1,24(s2)
    800040bc:	02892503          	lw	a0,40(s2)
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	fec080e7          	jalr	-20(ra) # 800030ac <bread>
    800040c8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ca:	02c92683          	lw	a3,44(s2)
    800040ce:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040d0:	02d05863          	blez	a3,80004100 <write_head+0x5c>
    800040d4:	0001e797          	auipc	a5,0x1e
    800040d8:	bcc78793          	addi	a5,a5,-1076 # 80021ca0 <log+0x30>
    800040dc:	05c50713          	addi	a4,a0,92
    800040e0:	36fd                	addiw	a3,a3,-1
    800040e2:	02069613          	slli	a2,a3,0x20
    800040e6:	01e65693          	srli	a3,a2,0x1e
    800040ea:	0001e617          	auipc	a2,0x1e
    800040ee:	bba60613          	addi	a2,a2,-1094 # 80021ca4 <log+0x34>
    800040f2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040f4:	4390                	lw	a2,0(a5)
    800040f6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040f8:	0791                	addi	a5,a5,4
    800040fa:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800040fc:	fed79ce3          	bne	a5,a3,800040f4 <write_head+0x50>
  }
  bwrite(buf);
    80004100:	8526                	mv	a0,s1
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	09c080e7          	jalr	156(ra) # 8000319e <bwrite>
  brelse(buf);
    8000410a:	8526                	mv	a0,s1
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	0d0080e7          	jalr	208(ra) # 800031dc <brelse>
}
    80004114:	60e2                	ld	ra,24(sp)
    80004116:	6442                	ld	s0,16(sp)
    80004118:	64a2                	ld	s1,8(sp)
    8000411a:	6902                	ld	s2,0(sp)
    8000411c:	6105                	addi	sp,sp,32
    8000411e:	8082                	ret

0000000080004120 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004120:	0001e797          	auipc	a5,0x1e
    80004124:	b7c7a783          	lw	a5,-1156(a5) # 80021c9c <log+0x2c>
    80004128:	0af05d63          	blez	a5,800041e2 <install_trans+0xc2>
{
    8000412c:	7139                	addi	sp,sp,-64
    8000412e:	fc06                	sd	ra,56(sp)
    80004130:	f822                	sd	s0,48(sp)
    80004132:	f426                	sd	s1,40(sp)
    80004134:	f04a                	sd	s2,32(sp)
    80004136:	ec4e                	sd	s3,24(sp)
    80004138:	e852                	sd	s4,16(sp)
    8000413a:	e456                	sd	s5,8(sp)
    8000413c:	e05a                	sd	s6,0(sp)
    8000413e:	0080                	addi	s0,sp,64
    80004140:	8b2a                	mv	s6,a0
    80004142:	0001ea97          	auipc	s5,0x1e
    80004146:	b5ea8a93          	addi	s5,s5,-1186 # 80021ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000414a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000414c:	0001e997          	auipc	s3,0x1e
    80004150:	b2498993          	addi	s3,s3,-1244 # 80021c70 <log>
    80004154:	a00d                	j	80004176 <install_trans+0x56>
    brelse(lbuf);
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	084080e7          	jalr	132(ra) # 800031dc <brelse>
    brelse(dbuf);
    80004160:	8526                	mv	a0,s1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	07a080e7          	jalr	122(ra) # 800031dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	2a05                	addiw	s4,s4,1
    8000416c:	0a91                	addi	s5,s5,4
    8000416e:	02c9a783          	lw	a5,44(s3)
    80004172:	04fa5e63          	bge	s4,a5,800041ce <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004176:	0189a583          	lw	a1,24(s3)
    8000417a:	014585bb          	addw	a1,a1,s4
    8000417e:	2585                	addiw	a1,a1,1
    80004180:	0289a503          	lw	a0,40(s3)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	f28080e7          	jalr	-216(ra) # 800030ac <bread>
    8000418c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000418e:	000aa583          	lw	a1,0(s5)
    80004192:	0289a503          	lw	a0,40(s3)
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	f16080e7          	jalr	-234(ra) # 800030ac <bread>
    8000419e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041a0:	40000613          	li	a2,1024
    800041a4:	05890593          	addi	a1,s2,88
    800041a8:	05850513          	addi	a0,a0,88
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	b7c080e7          	jalr	-1156(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	fe8080e7          	jalr	-24(ra) # 8000319e <bwrite>
    if(recovering == 0)
    800041be:	f80b1ce3          	bnez	s6,80004156 <install_trans+0x36>
      bunpin(dbuf);
    800041c2:	8526                	mv	a0,s1
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	0f2080e7          	jalr	242(ra) # 800032b6 <bunpin>
    800041cc:	b769                	j	80004156 <install_trans+0x36>
}
    800041ce:	70e2                	ld	ra,56(sp)
    800041d0:	7442                	ld	s0,48(sp)
    800041d2:	74a2                	ld	s1,40(sp)
    800041d4:	7902                	ld	s2,32(sp)
    800041d6:	69e2                	ld	s3,24(sp)
    800041d8:	6a42                	ld	s4,16(sp)
    800041da:	6aa2                	ld	s5,8(sp)
    800041dc:	6b02                	ld	s6,0(sp)
    800041de:	6121                	addi	sp,sp,64
    800041e0:	8082                	ret
    800041e2:	8082                	ret

00000000800041e4 <initlog>:
{
    800041e4:	7179                	addi	sp,sp,-48
    800041e6:	f406                	sd	ra,40(sp)
    800041e8:	f022                	sd	s0,32(sp)
    800041ea:	ec26                	sd	s1,24(sp)
    800041ec:	e84a                	sd	s2,16(sp)
    800041ee:	e44e                	sd	s3,8(sp)
    800041f0:	1800                	addi	s0,sp,48
    800041f2:	892a                	mv	s2,a0
    800041f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041f6:	0001e497          	auipc	s1,0x1e
    800041fa:	a7a48493          	addi	s1,s1,-1414 # 80021c70 <log>
    800041fe:	00004597          	auipc	a1,0x4
    80004202:	42258593          	addi	a1,a1,1058 # 80008620 <syscalls+0x1d8>
    80004206:	8526                	mv	a0,s1
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	938080e7          	jalr	-1736(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004210:	0149a583          	lw	a1,20(s3)
    80004214:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004216:	0109a783          	lw	a5,16(s3)
    8000421a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000421c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	e8a080e7          	jalr	-374(ra) # 800030ac <bread>
  log.lh.n = lh->n;
    8000422a:	4d34                	lw	a3,88(a0)
    8000422c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000422e:	02d05663          	blez	a3,8000425a <initlog+0x76>
    80004232:	05c50793          	addi	a5,a0,92
    80004236:	0001e717          	auipc	a4,0x1e
    8000423a:	a6a70713          	addi	a4,a4,-1430 # 80021ca0 <log+0x30>
    8000423e:	36fd                	addiw	a3,a3,-1
    80004240:	02069613          	slli	a2,a3,0x20
    80004244:	01e65693          	srli	a3,a2,0x1e
    80004248:	06050613          	addi	a2,a0,96
    8000424c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000424e:	4390                	lw	a2,0(a5)
    80004250:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004252:	0791                	addi	a5,a5,4
    80004254:	0711                	addi	a4,a4,4
    80004256:	fed79ce3          	bne	a5,a3,8000424e <initlog+0x6a>
  brelse(buf);
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	f82080e7          	jalr	-126(ra) # 800031dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004262:	4505                	li	a0,1
    80004264:	00000097          	auipc	ra,0x0
    80004268:	ebc080e7          	jalr	-324(ra) # 80004120 <install_trans>
  log.lh.n = 0;
    8000426c:	0001e797          	auipc	a5,0x1e
    80004270:	a207a823          	sw	zero,-1488(a5) # 80021c9c <log+0x2c>
  write_head(); // clear the log
    80004274:	00000097          	auipc	ra,0x0
    80004278:	e30080e7          	jalr	-464(ra) # 800040a4 <write_head>
}
    8000427c:	70a2                	ld	ra,40(sp)
    8000427e:	7402                	ld	s0,32(sp)
    80004280:	64e2                	ld	s1,24(sp)
    80004282:	6942                	ld	s2,16(sp)
    80004284:	69a2                	ld	s3,8(sp)
    80004286:	6145                	addi	sp,sp,48
    80004288:	8082                	ret

000000008000428a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000428a:	1101                	addi	sp,sp,-32
    8000428c:	ec06                	sd	ra,24(sp)
    8000428e:	e822                	sd	s0,16(sp)
    80004290:	e426                	sd	s1,8(sp)
    80004292:	e04a                	sd	s2,0(sp)
    80004294:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004296:	0001e517          	auipc	a0,0x1e
    8000429a:	9da50513          	addi	a0,a0,-1574 # 80021c70 <log>
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	932080e7          	jalr	-1742(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800042a6:	0001e497          	auipc	s1,0x1e
    800042aa:	9ca48493          	addi	s1,s1,-1590 # 80021c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ae:	4979                	li	s2,30
    800042b0:	a039                	j	800042be <begin_op+0x34>
      sleep(&log, &log.lock);
    800042b2:	85a6                	mv	a1,s1
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	dc0080e7          	jalr	-576(ra) # 80002076 <sleep>
    if(log.committing){
    800042be:	50dc                	lw	a5,36(s1)
    800042c0:	fbed                	bnez	a5,800042b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c2:	5098                	lw	a4,32(s1)
    800042c4:	2705                	addiw	a4,a4,1
    800042c6:	0007069b          	sext.w	a3,a4
    800042ca:	0027179b          	slliw	a5,a4,0x2
    800042ce:	9fb9                	addw	a5,a5,a4
    800042d0:	0017979b          	slliw	a5,a5,0x1
    800042d4:	54d8                	lw	a4,44(s1)
    800042d6:	9fb9                	addw	a5,a5,a4
    800042d8:	00f95963          	bge	s2,a5,800042ea <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042dc:	85a6                	mv	a1,s1
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffe097          	auipc	ra,0xffffe
    800042e4:	d96080e7          	jalr	-618(ra) # 80002076 <sleep>
    800042e8:	bfd9                	j	800042be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ea:	0001e517          	auipc	a0,0x1e
    800042ee:	98650513          	addi	a0,a0,-1658 # 80021c70 <log>
    800042f2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	990080e7          	jalr	-1648(ra) # 80000c84 <release>
      break;
    }
  }
}
    800042fc:	60e2                	ld	ra,24(sp)
    800042fe:	6442                	ld	s0,16(sp)
    80004300:	64a2                	ld	s1,8(sp)
    80004302:	6902                	ld	s2,0(sp)
    80004304:	6105                	addi	sp,sp,32
    80004306:	8082                	ret

0000000080004308 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004308:	7139                	addi	sp,sp,-64
    8000430a:	fc06                	sd	ra,56(sp)
    8000430c:	f822                	sd	s0,48(sp)
    8000430e:	f426                	sd	s1,40(sp)
    80004310:	f04a                	sd	s2,32(sp)
    80004312:	ec4e                	sd	s3,24(sp)
    80004314:	e852                	sd	s4,16(sp)
    80004316:	e456                	sd	s5,8(sp)
    80004318:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000431a:	0001e497          	auipc	s1,0x1e
    8000431e:	95648493          	addi	s1,s1,-1706 # 80021c70 <log>
    80004322:	8526                	mv	a0,s1
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	8ac080e7          	jalr	-1876(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000432c:	509c                	lw	a5,32(s1)
    8000432e:	37fd                	addiw	a5,a5,-1
    80004330:	0007891b          	sext.w	s2,a5
    80004334:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004336:	50dc                	lw	a5,36(s1)
    80004338:	e7b9                	bnez	a5,80004386 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000433a:	04091e63          	bnez	s2,80004396 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000433e:	0001e497          	auipc	s1,0x1e
    80004342:	93248493          	addi	s1,s1,-1742 # 80021c70 <log>
    80004346:	4785                	li	a5,1
    80004348:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	938080e7          	jalr	-1736(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004354:	54dc                	lw	a5,44(s1)
    80004356:	06f04763          	bgtz	a5,800043c4 <end_op+0xbc>
    acquire(&log.lock);
    8000435a:	0001e497          	auipc	s1,0x1e
    8000435e:	91648493          	addi	s1,s1,-1770 # 80021c70 <log>
    80004362:	8526                	mv	a0,s1
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	86c080e7          	jalr	-1940(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000436c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	e90080e7          	jalr	-368(ra) # 80002202 <wakeup>
    release(&log.lock);
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	908080e7          	jalr	-1784(ra) # 80000c84 <release>
}
    80004384:	a03d                	j	800043b2 <end_op+0xaa>
    panic("log.committing");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2a250513          	addi	a0,a0,674 # 80008628 <syscalls+0x1e0>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1ac080e7          	jalr	428(ra) # 8000053a <panic>
    wakeup(&log);
    80004396:	0001e497          	auipc	s1,0x1e
    8000439a:	8da48493          	addi	s1,s1,-1830 # 80021c70 <log>
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	e62080e7          	jalr	-414(ra) # 80002202 <wakeup>
  release(&log.lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8da080e7          	jalr	-1830(ra) # 80000c84 <release>
}
    800043b2:	70e2                	ld	ra,56(sp)
    800043b4:	7442                	ld	s0,48(sp)
    800043b6:	74a2                	ld	s1,40(sp)
    800043b8:	7902                	ld	s2,32(sp)
    800043ba:	69e2                	ld	s3,24(sp)
    800043bc:	6a42                	ld	s4,16(sp)
    800043be:	6aa2                	ld	s5,8(sp)
    800043c0:	6121                	addi	sp,sp,64
    800043c2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c4:	0001ea97          	auipc	s5,0x1e
    800043c8:	8dca8a93          	addi	s5,s5,-1828 # 80021ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043cc:	0001ea17          	auipc	s4,0x1e
    800043d0:	8a4a0a13          	addi	s4,s4,-1884 # 80021c70 <log>
    800043d4:	018a2583          	lw	a1,24(s4)
    800043d8:	012585bb          	addw	a1,a1,s2
    800043dc:	2585                	addiw	a1,a1,1
    800043de:	028a2503          	lw	a0,40(s4)
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	cca080e7          	jalr	-822(ra) # 800030ac <bread>
    800043ea:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ec:	000aa583          	lw	a1,0(s5)
    800043f0:	028a2503          	lw	a0,40(s4)
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	cb8080e7          	jalr	-840(ra) # 800030ac <bread>
    800043fc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043fe:	40000613          	li	a2,1024
    80004402:	05850593          	addi	a1,a0,88
    80004406:	05848513          	addi	a0,s1,88
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	91e080e7          	jalr	-1762(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004412:	8526                	mv	a0,s1
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	d8a080e7          	jalr	-630(ra) # 8000319e <bwrite>
    brelse(from);
    8000441c:	854e                	mv	a0,s3
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	dbe080e7          	jalr	-578(ra) # 800031dc <brelse>
    brelse(to);
    80004426:	8526                	mv	a0,s1
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	db4080e7          	jalr	-588(ra) # 800031dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004430:	2905                	addiw	s2,s2,1
    80004432:	0a91                	addi	s5,s5,4
    80004434:	02ca2783          	lw	a5,44(s4)
    80004438:	f8f94ee3          	blt	s2,a5,800043d4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000443c:	00000097          	auipc	ra,0x0
    80004440:	c68080e7          	jalr	-920(ra) # 800040a4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004444:	4501                	li	a0,0
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	cda080e7          	jalr	-806(ra) # 80004120 <install_trans>
    log.lh.n = 0;
    8000444e:	0001e797          	auipc	a5,0x1e
    80004452:	8407a723          	sw	zero,-1970(a5) # 80021c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	c4e080e7          	jalr	-946(ra) # 800040a4 <write_head>
    8000445e:	bdf5                	j	8000435a <end_op+0x52>

0000000080004460 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	e04a                	sd	s2,0(sp)
    8000446a:	1000                	addi	s0,sp,32
    8000446c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000446e:	0001e917          	auipc	s2,0x1e
    80004472:	80290913          	addi	s2,s2,-2046 # 80021c70 <log>
    80004476:	854a                	mv	a0,s2
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	758080e7          	jalr	1880(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004480:	02c92603          	lw	a2,44(s2)
    80004484:	47f5                	li	a5,29
    80004486:	06c7c563          	blt	a5,a2,800044f0 <log_write+0x90>
    8000448a:	0001e797          	auipc	a5,0x1e
    8000448e:	8027a783          	lw	a5,-2046(a5) # 80021c8c <log+0x1c>
    80004492:	37fd                	addiw	a5,a5,-1
    80004494:	04f65e63          	bge	a2,a5,800044f0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004498:	0001d797          	auipc	a5,0x1d
    8000449c:	7f87a783          	lw	a5,2040(a5) # 80021c90 <log+0x20>
    800044a0:	06f05063          	blez	a5,80004500 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044a4:	4781                	li	a5,0
    800044a6:	06c05563          	blez	a2,80004510 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044aa:	44cc                	lw	a1,12(s1)
    800044ac:	0001d717          	auipc	a4,0x1d
    800044b0:	7f470713          	addi	a4,a4,2036 # 80021ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044b4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b6:	4314                	lw	a3,0(a4)
    800044b8:	04b68c63          	beq	a3,a1,80004510 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044bc:	2785                	addiw	a5,a5,1
    800044be:	0711                	addi	a4,a4,4
    800044c0:	fef61be3          	bne	a2,a5,800044b6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044c4:	0621                	addi	a2,a2,8
    800044c6:	060a                	slli	a2,a2,0x2
    800044c8:	0001d797          	auipc	a5,0x1d
    800044cc:	7a878793          	addi	a5,a5,1960 # 80021c70 <log>
    800044d0:	97b2                	add	a5,a5,a2
    800044d2:	44d8                	lw	a4,12(s1)
    800044d4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044d6:	8526                	mv	a0,s1
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	da2080e7          	jalr	-606(ra) # 8000327a <bpin>
    log.lh.n++;
    800044e0:	0001d717          	auipc	a4,0x1d
    800044e4:	79070713          	addi	a4,a4,1936 # 80021c70 <log>
    800044e8:	575c                	lw	a5,44(a4)
    800044ea:	2785                	addiw	a5,a5,1
    800044ec:	d75c                	sw	a5,44(a4)
    800044ee:	a82d                	j	80004528 <log_write+0xc8>
    panic("too big a transaction");
    800044f0:	00004517          	auipc	a0,0x4
    800044f4:	14850513          	addi	a0,a0,328 # 80008638 <syscalls+0x1f0>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	042080e7          	jalr	66(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004500:	00004517          	auipc	a0,0x4
    80004504:	15050513          	addi	a0,a0,336 # 80008650 <syscalls+0x208>
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	032080e7          	jalr	50(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004510:	00878693          	addi	a3,a5,8
    80004514:	068a                	slli	a3,a3,0x2
    80004516:	0001d717          	auipc	a4,0x1d
    8000451a:	75a70713          	addi	a4,a4,1882 # 80021c70 <log>
    8000451e:	9736                	add	a4,a4,a3
    80004520:	44d4                	lw	a3,12(s1)
    80004522:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004524:	faf609e3          	beq	a2,a5,800044d6 <log_write+0x76>
  }
  release(&log.lock);
    80004528:	0001d517          	auipc	a0,0x1d
    8000452c:	74850513          	addi	a0,a0,1864 # 80021c70 <log>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	754080e7          	jalr	1876(ra) # 80000c84 <release>
}
    80004538:	60e2                	ld	ra,24(sp)
    8000453a:	6442                	ld	s0,16(sp)
    8000453c:	64a2                	ld	s1,8(sp)
    8000453e:	6902                	ld	s2,0(sp)
    80004540:	6105                	addi	sp,sp,32
    80004542:	8082                	ret

0000000080004544 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004544:	1101                	addi	sp,sp,-32
    80004546:	ec06                	sd	ra,24(sp)
    80004548:	e822                	sd	s0,16(sp)
    8000454a:	e426                	sd	s1,8(sp)
    8000454c:	e04a                	sd	s2,0(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
    80004552:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004554:	00004597          	auipc	a1,0x4
    80004558:	11c58593          	addi	a1,a1,284 # 80008670 <syscalls+0x228>
    8000455c:	0521                	addi	a0,a0,8
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	5e2080e7          	jalr	1506(ra) # 80000b40 <initlock>
  lk->name = name;
    80004566:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000456a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000456e:	0204a423          	sw	zero,40(s1)
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000457e:	1101                	addi	sp,sp,-32
    80004580:	ec06                	sd	ra,24(sp)
    80004582:	e822                	sd	s0,16(sp)
    80004584:	e426                	sd	s1,8(sp)
    80004586:	e04a                	sd	s2,0(sp)
    80004588:	1000                	addi	s0,sp,32
    8000458a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000458c:	00850913          	addi	s2,a0,8
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	63e080e7          	jalr	1598(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000459a:	409c                	lw	a5,0(s1)
    8000459c:	cb89                	beqz	a5,800045ae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000459e:	85ca                	mv	a1,s2
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	ad4080e7          	jalr	-1324(ra) # 80002076 <sleep>
  while (lk->locked) {
    800045aa:	409c                	lw	a5,0(s1)
    800045ac:	fbed                	bnez	a5,8000459e <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ae:	4785                	li	a5,1
    800045b0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045b2:	ffffd097          	auipc	ra,0xffffd
    800045b6:	3e4080e7          	jalr	996(ra) # 80001996 <myproc>
    800045ba:	591c                	lw	a5,48(a0)
    800045bc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6c4080e7          	jalr	1732(ra) # 80000c84 <release>
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	e04a                	sd	s2,0(sp)
    800045de:	1000                	addi	s0,sp,32
    800045e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e2:	00850913          	addi	s2,a0,8
    800045e6:	854a                	mv	a0,s2
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5e8080e7          	jalr	1512(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800045f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	c08080e7          	jalr	-1016(ra) # 80002202 <wakeup>
  release(&lk->lk);
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	680080e7          	jalr	1664(ra) # 80000c84 <release>
}
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6902                	ld	s2,0(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret

0000000080004618 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004618:	7179                	addi	sp,sp,-48
    8000461a:	f406                	sd	ra,40(sp)
    8000461c:	f022                	sd	s0,32(sp)
    8000461e:	ec26                	sd	s1,24(sp)
    80004620:	e84a                	sd	s2,16(sp)
    80004622:	e44e                	sd	s3,8(sp)
    80004624:	1800                	addi	s0,sp,48
    80004626:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004628:	00850913          	addi	s2,a0,8
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	5a2080e7          	jalr	1442(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004636:	409c                	lw	a5,0(s1)
    80004638:	ef99                	bnez	a5,80004656 <holdingsleep+0x3e>
    8000463a:	4481                	li	s1,0
  release(&lk->lk);
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	646080e7          	jalr	1606(ra) # 80000c84 <release>
  return r;
}
    80004646:	8526                	mv	a0,s1
    80004648:	70a2                	ld	ra,40(sp)
    8000464a:	7402                	ld	s0,32(sp)
    8000464c:	64e2                	ld	s1,24(sp)
    8000464e:	6942                	ld	s2,16(sp)
    80004650:	69a2                	ld	s3,8(sp)
    80004652:	6145                	addi	sp,sp,48
    80004654:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004656:	0284a983          	lw	s3,40(s1)
    8000465a:	ffffd097          	auipc	ra,0xffffd
    8000465e:	33c080e7          	jalr	828(ra) # 80001996 <myproc>
    80004662:	5904                	lw	s1,48(a0)
    80004664:	413484b3          	sub	s1,s1,s3
    80004668:	0014b493          	seqz	s1,s1
    8000466c:	bfc1                	j	8000463c <holdingsleep+0x24>

000000008000466e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000466e:	1141                	addi	sp,sp,-16
    80004670:	e406                	sd	ra,8(sp)
    80004672:	e022                	sd	s0,0(sp)
    80004674:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004676:	00004597          	auipc	a1,0x4
    8000467a:	00a58593          	addi	a1,a1,10 # 80008680 <syscalls+0x238>
    8000467e:	0001d517          	auipc	a0,0x1d
    80004682:	73a50513          	addi	a0,a0,1850 # 80021db8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	4ba080e7          	jalr	1210(ra) # 80000b40 <initlock>
}
    8000468e:	60a2                	ld	ra,8(sp)
    80004690:	6402                	ld	s0,0(sp)
    80004692:	0141                	addi	sp,sp,16
    80004694:	8082                	ret

0000000080004696 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	71850513          	addi	a0,a0,1816 # 80021db8 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	528080e7          	jalr	1320(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b0:	0001d497          	auipc	s1,0x1d
    800046b4:	72048493          	addi	s1,s1,1824 # 80021dd0 <ftable+0x18>
    800046b8:	0001e717          	auipc	a4,0x1e
    800046bc:	6b870713          	addi	a4,a4,1720 # 80022d70 <ftable+0xfb8>
    if(f->ref == 0){
    800046c0:	40dc                	lw	a5,4(s1)
    800046c2:	cf99                	beqz	a5,800046e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c4:	02848493          	addi	s1,s1,40
    800046c8:	fee49ce3          	bne	s1,a4,800046c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	6ec50513          	addi	a0,a0,1772 # 80021db8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5b0080e7          	jalr	1456(ra) # 80000c84 <release>
  return 0;
    800046dc:	4481                	li	s1,0
    800046de:	a819                	j	800046f4 <filealloc+0x5e>
      f->ref = 1;
    800046e0:	4785                	li	a5,1
    800046e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046e4:	0001d517          	auipc	a0,0x1d
    800046e8:	6d450513          	addi	a0,a0,1748 # 80021db8 <ftable>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	598080e7          	jalr	1432(ra) # 80000c84 <release>
}
    800046f4:	8526                	mv	a0,s1
    800046f6:	60e2                	ld	ra,24(sp)
    800046f8:	6442                	ld	s0,16(sp)
    800046fa:	64a2                	ld	s1,8(sp)
    800046fc:	6105                	addi	sp,sp,32
    800046fe:	8082                	ret

0000000080004700 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	1000                	addi	s0,sp,32
    8000470a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000470c:	0001d517          	auipc	a0,0x1d
    80004710:	6ac50513          	addi	a0,a0,1708 # 80021db8 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	4bc080e7          	jalr	1212(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000471c:	40dc                	lw	a5,4(s1)
    8000471e:	02f05263          	blez	a5,80004742 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004722:	2785                	addiw	a5,a5,1
    80004724:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	69250513          	addi	a0,a0,1682 # 80021db8 <ftable>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	556080e7          	jalr	1366(ra) # 80000c84 <release>
  return f;
}
    80004736:	8526                	mv	a0,s1
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6105                	addi	sp,sp,32
    80004740:	8082                	ret
    panic("filedup");
    80004742:	00004517          	auipc	a0,0x4
    80004746:	f4650513          	addi	a0,a0,-186 # 80008688 <syscalls+0x240>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	df0080e7          	jalr	-528(ra) # 8000053a <panic>

0000000080004752 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004752:	7139                	addi	sp,sp,-64
    80004754:	fc06                	sd	ra,56(sp)
    80004756:	f822                	sd	s0,48(sp)
    80004758:	f426                	sd	s1,40(sp)
    8000475a:	f04a                	sd	s2,32(sp)
    8000475c:	ec4e                	sd	s3,24(sp)
    8000475e:	e852                	sd	s4,16(sp)
    80004760:	e456                	sd	s5,8(sp)
    80004762:	0080                	addi	s0,sp,64
    80004764:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004766:	0001d517          	auipc	a0,0x1d
    8000476a:	65250513          	addi	a0,a0,1618 # 80021db8 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	462080e7          	jalr	1122(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	06f05163          	blez	a5,800047da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000477c:	37fd                	addiw	a5,a5,-1
    8000477e:	0007871b          	sext.w	a4,a5
    80004782:	c0dc                	sw	a5,4(s1)
    80004784:	06e04363          	bgtz	a4,800047ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004788:	0004a903          	lw	s2,0(s1)
    8000478c:	0094ca83          	lbu	s5,9(s1)
    80004790:	0104ba03          	ld	s4,16(s1)
    80004794:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004798:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000479c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047a0:	0001d517          	auipc	a0,0x1d
    800047a4:	61850513          	addi	a0,a0,1560 # 80021db8 <ftable>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4dc080e7          	jalr	1244(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800047b0:	4785                	li	a5,1
    800047b2:	04f90d63          	beq	s2,a5,8000480c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047b6:	3979                	addiw	s2,s2,-2
    800047b8:	4785                	li	a5,1
    800047ba:	0527e063          	bltu	a5,s2,800047fa <fileclose+0xa8>
    begin_op();
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	acc080e7          	jalr	-1332(ra) # 8000428a <begin_op>
    iput(ff.ip);
    800047c6:	854e                	mv	a0,s3
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	2a0080e7          	jalr	672(ra) # 80003a68 <iput>
    end_op();
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	b38080e7          	jalr	-1224(ra) # 80004308 <end_op>
    800047d8:	a00d                	j	800047fa <fileclose+0xa8>
    panic("fileclose");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	eb650513          	addi	a0,a0,-330 # 80008690 <syscalls+0x248>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d58080e7          	jalr	-680(ra) # 8000053a <panic>
    release(&ftable.lock);
    800047ea:	0001d517          	auipc	a0,0x1d
    800047ee:	5ce50513          	addi	a0,a0,1486 # 80021db8 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	492080e7          	jalr	1170(ra) # 80000c84 <release>
  }
}
    800047fa:	70e2                	ld	ra,56(sp)
    800047fc:	7442                	ld	s0,48(sp)
    800047fe:	74a2                	ld	s1,40(sp)
    80004800:	7902                	ld	s2,32(sp)
    80004802:	69e2                	ld	s3,24(sp)
    80004804:	6a42                	ld	s4,16(sp)
    80004806:	6aa2                	ld	s5,8(sp)
    80004808:	6121                	addi	sp,sp,64
    8000480a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000480c:	85d6                	mv	a1,s5
    8000480e:	8552                	mv	a0,s4
    80004810:	00000097          	auipc	ra,0x0
    80004814:	34c080e7          	jalr	844(ra) # 80004b5c <pipeclose>
    80004818:	b7cd                	j	800047fa <fileclose+0xa8>

000000008000481a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000481a:	715d                	addi	sp,sp,-80
    8000481c:	e486                	sd	ra,72(sp)
    8000481e:	e0a2                	sd	s0,64(sp)
    80004820:	fc26                	sd	s1,56(sp)
    80004822:	f84a                	sd	s2,48(sp)
    80004824:	f44e                	sd	s3,40(sp)
    80004826:	0880                	addi	s0,sp,80
    80004828:	84aa                	mv	s1,a0
    8000482a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000482c:	ffffd097          	auipc	ra,0xffffd
    80004830:	16a080e7          	jalr	362(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004834:	409c                	lw	a5,0(s1)
    80004836:	37f9                	addiw	a5,a5,-2
    80004838:	4705                	li	a4,1
    8000483a:	04f76763          	bltu	a4,a5,80004888 <filestat+0x6e>
    8000483e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	06c080e7          	jalr	108(ra) # 800038ae <ilock>
    stati(f->ip, &st);
    8000484a:	fb840593          	addi	a1,s0,-72
    8000484e:	6c88                	ld	a0,24(s1)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	2e8080e7          	jalr	744(ra) # 80003b38 <stati>
    iunlock(f->ip);
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	116080e7          	jalr	278(ra) # 80003970 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004862:	46e1                	li	a3,24
    80004864:	fb840613          	addi	a2,s0,-72
    80004868:	85ce                	mv	a1,s3
    8000486a:	05093503          	ld	a0,80(s2)
    8000486e:	ffffd097          	auipc	ra,0xffffd
    80004872:	dec080e7          	jalr	-532(ra) # 8000165a <copyout>
    80004876:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000487a:	60a6                	ld	ra,72(sp)
    8000487c:	6406                	ld	s0,64(sp)
    8000487e:	74e2                	ld	s1,56(sp)
    80004880:	7942                	ld	s2,48(sp)
    80004882:	79a2                	ld	s3,40(sp)
    80004884:	6161                	addi	sp,sp,80
    80004886:	8082                	ret
  return -1;
    80004888:	557d                	li	a0,-1
    8000488a:	bfc5                	j	8000487a <filestat+0x60>

000000008000488c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000488c:	7179                	addi	sp,sp,-48
    8000488e:	f406                	sd	ra,40(sp)
    80004890:	f022                	sd	s0,32(sp)
    80004892:	ec26                	sd	s1,24(sp)
    80004894:	e84a                	sd	s2,16(sp)
    80004896:	e44e                	sd	s3,8(sp)
    80004898:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000489a:	00854783          	lbu	a5,8(a0)
    8000489e:	c3d5                	beqz	a5,80004942 <fileread+0xb6>
    800048a0:	84aa                	mv	s1,a0
    800048a2:	89ae                	mv	s3,a1
    800048a4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048a6:	411c                	lw	a5,0(a0)
    800048a8:	4705                	li	a4,1
    800048aa:	04e78963          	beq	a5,a4,800048fc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ae:	470d                	li	a4,3
    800048b0:	04e78d63          	beq	a5,a4,8000490a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b4:	4709                	li	a4,2
    800048b6:	06e79e63          	bne	a5,a4,80004932 <fileread+0xa6>
    ilock(f->ip);
    800048ba:	6d08                	ld	a0,24(a0)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	ff2080e7          	jalr	-14(ra) # 800038ae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048c4:	874a                	mv	a4,s2
    800048c6:	5094                	lw	a3,32(s1)
    800048c8:	864e                	mv	a2,s3
    800048ca:	4585                	li	a1,1
    800048cc:	6c88                	ld	a0,24(s1)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	294080e7          	jalr	660(ra) # 80003b62 <readi>
    800048d6:	892a                	mv	s2,a0
    800048d8:	00a05563          	blez	a0,800048e2 <fileread+0x56>
      f->off += r;
    800048dc:	509c                	lw	a5,32(s1)
    800048de:	9fa9                	addw	a5,a5,a0
    800048e0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048e2:	6c88                	ld	a0,24(s1)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	08c080e7          	jalr	140(ra) # 80003970 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048ec:	854a                	mv	a0,s2
    800048ee:	70a2                	ld	ra,40(sp)
    800048f0:	7402                	ld	s0,32(sp)
    800048f2:	64e2                	ld	s1,24(sp)
    800048f4:	6942                	ld	s2,16(sp)
    800048f6:	69a2                	ld	s3,8(sp)
    800048f8:	6145                	addi	sp,sp,48
    800048fa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048fc:	6908                	ld	a0,16(a0)
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	3c0080e7          	jalr	960(ra) # 80004cbe <piperead>
    80004906:	892a                	mv	s2,a0
    80004908:	b7d5                	j	800048ec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000490a:	02451783          	lh	a5,36(a0)
    8000490e:	03079693          	slli	a3,a5,0x30
    80004912:	92c1                	srli	a3,a3,0x30
    80004914:	4725                	li	a4,9
    80004916:	02d76863          	bltu	a4,a3,80004946 <fileread+0xba>
    8000491a:	0792                	slli	a5,a5,0x4
    8000491c:	0001d717          	auipc	a4,0x1d
    80004920:	3fc70713          	addi	a4,a4,1020 # 80021d18 <devsw>
    80004924:	97ba                	add	a5,a5,a4
    80004926:	639c                	ld	a5,0(a5)
    80004928:	c38d                	beqz	a5,8000494a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000492a:	4505                	li	a0,1
    8000492c:	9782                	jalr	a5
    8000492e:	892a                	mv	s2,a0
    80004930:	bf75                	j	800048ec <fileread+0x60>
    panic("fileread");
    80004932:	00004517          	auipc	a0,0x4
    80004936:	d6e50513          	addi	a0,a0,-658 # 800086a0 <syscalls+0x258>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	c00080e7          	jalr	-1024(ra) # 8000053a <panic>
    return -1;
    80004942:	597d                	li	s2,-1
    80004944:	b765                	j	800048ec <fileread+0x60>
      return -1;
    80004946:	597d                	li	s2,-1
    80004948:	b755                	j	800048ec <fileread+0x60>
    8000494a:	597d                	li	s2,-1
    8000494c:	b745                	j	800048ec <fileread+0x60>

000000008000494e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000494e:	715d                	addi	sp,sp,-80
    80004950:	e486                	sd	ra,72(sp)
    80004952:	e0a2                	sd	s0,64(sp)
    80004954:	fc26                	sd	s1,56(sp)
    80004956:	f84a                	sd	s2,48(sp)
    80004958:	f44e                	sd	s3,40(sp)
    8000495a:	f052                	sd	s4,32(sp)
    8000495c:	ec56                	sd	s5,24(sp)
    8000495e:	e85a                	sd	s6,16(sp)
    80004960:	e45e                	sd	s7,8(sp)
    80004962:	e062                	sd	s8,0(sp)
    80004964:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004966:	00954783          	lbu	a5,9(a0)
    8000496a:	10078663          	beqz	a5,80004a76 <filewrite+0x128>
    8000496e:	892a                	mv	s2,a0
    80004970:	8b2e                	mv	s6,a1
    80004972:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004974:	411c                	lw	a5,0(a0)
    80004976:	4705                	li	a4,1
    80004978:	02e78263          	beq	a5,a4,8000499c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497c:	470d                	li	a4,3
    8000497e:	02e78663          	beq	a5,a4,800049aa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004982:	4709                	li	a4,2
    80004984:	0ee79163          	bne	a5,a4,80004a66 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004988:	0ac05d63          	blez	a2,80004a42 <filewrite+0xf4>
    int i = 0;
    8000498c:	4981                	li	s3,0
    8000498e:	6b85                	lui	s7,0x1
    80004990:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004994:	6c05                	lui	s8,0x1
    80004996:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000499a:	a861                	j	80004a32 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000499c:	6908                	ld	a0,16(a0)
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	22e080e7          	jalr	558(ra) # 80004bcc <pipewrite>
    800049a6:	8a2a                	mv	s4,a0
    800049a8:	a045                	j	80004a48 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049aa:	02451783          	lh	a5,36(a0)
    800049ae:	03079693          	slli	a3,a5,0x30
    800049b2:	92c1                	srli	a3,a3,0x30
    800049b4:	4725                	li	a4,9
    800049b6:	0cd76263          	bltu	a4,a3,80004a7a <filewrite+0x12c>
    800049ba:	0792                	slli	a5,a5,0x4
    800049bc:	0001d717          	auipc	a4,0x1d
    800049c0:	35c70713          	addi	a4,a4,860 # 80021d18 <devsw>
    800049c4:	97ba                	add	a5,a5,a4
    800049c6:	679c                	ld	a5,8(a5)
    800049c8:	cbdd                	beqz	a5,80004a7e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049ca:	4505                	li	a0,1
    800049cc:	9782                	jalr	a5
    800049ce:	8a2a                	mv	s4,a0
    800049d0:	a8a5                	j	80004a48 <filewrite+0xfa>
    800049d2:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	8b4080e7          	jalr	-1868(ra) # 8000428a <begin_op>
      ilock(f->ip);
    800049de:	01893503          	ld	a0,24(s2)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	ecc080e7          	jalr	-308(ra) # 800038ae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ea:	8756                	mv	a4,s5
    800049ec:	02092683          	lw	a3,32(s2)
    800049f0:	01698633          	add	a2,s3,s6
    800049f4:	4585                	li	a1,1
    800049f6:	01893503          	ld	a0,24(s2)
    800049fa:	fffff097          	auipc	ra,0xfffff
    800049fe:	260080e7          	jalr	608(ra) # 80003c5a <writei>
    80004a02:	84aa                	mv	s1,a0
    80004a04:	00a05763          	blez	a0,80004a12 <filewrite+0xc4>
        f->off += r;
    80004a08:	02092783          	lw	a5,32(s2)
    80004a0c:	9fa9                	addw	a5,a5,a0
    80004a0e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a12:	01893503          	ld	a0,24(s2)
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	f5a080e7          	jalr	-166(ra) # 80003970 <iunlock>
      end_op();
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	8ea080e7          	jalr	-1814(ra) # 80004308 <end_op>

      if(r != n1){
    80004a26:	009a9f63          	bne	s5,s1,80004a44 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a2a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a2e:	0149db63          	bge	s3,s4,80004a44 <filewrite+0xf6>
      int n1 = n - i;
    80004a32:	413a04bb          	subw	s1,s4,s3
    80004a36:	0004879b          	sext.w	a5,s1
    80004a3a:	f8fbdce3          	bge	s7,a5,800049d2 <filewrite+0x84>
    80004a3e:	84e2                	mv	s1,s8
    80004a40:	bf49                	j	800049d2 <filewrite+0x84>
    int i = 0;
    80004a42:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a44:	013a1f63          	bne	s4,s3,80004a62 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a48:	8552                	mv	a0,s4
    80004a4a:	60a6                	ld	ra,72(sp)
    80004a4c:	6406                	ld	s0,64(sp)
    80004a4e:	74e2                	ld	s1,56(sp)
    80004a50:	7942                	ld	s2,48(sp)
    80004a52:	79a2                	ld	s3,40(sp)
    80004a54:	7a02                	ld	s4,32(sp)
    80004a56:	6ae2                	ld	s5,24(sp)
    80004a58:	6b42                	ld	s6,16(sp)
    80004a5a:	6ba2                	ld	s7,8(sp)
    80004a5c:	6c02                	ld	s8,0(sp)
    80004a5e:	6161                	addi	sp,sp,80
    80004a60:	8082                	ret
    ret = (i == n ? n : -1);
    80004a62:	5a7d                	li	s4,-1
    80004a64:	b7d5                	j	80004a48 <filewrite+0xfa>
    panic("filewrite");
    80004a66:	00004517          	auipc	a0,0x4
    80004a6a:	c4a50513          	addi	a0,a0,-950 # 800086b0 <syscalls+0x268>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	acc080e7          	jalr	-1332(ra) # 8000053a <panic>
    return -1;
    80004a76:	5a7d                	li	s4,-1
    80004a78:	bfc1                	j	80004a48 <filewrite+0xfa>
      return -1;
    80004a7a:	5a7d                	li	s4,-1
    80004a7c:	b7f1                	j	80004a48 <filewrite+0xfa>
    80004a7e:	5a7d                	li	s4,-1
    80004a80:	b7e1                	j	80004a48 <filewrite+0xfa>

0000000080004a82 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a82:	7179                	addi	sp,sp,-48
    80004a84:	f406                	sd	ra,40(sp)
    80004a86:	f022                	sd	s0,32(sp)
    80004a88:	ec26                	sd	s1,24(sp)
    80004a8a:	e84a                	sd	s2,16(sp)
    80004a8c:	e44e                	sd	s3,8(sp)
    80004a8e:	e052                	sd	s4,0(sp)
    80004a90:	1800                	addi	s0,sp,48
    80004a92:	84aa                	mv	s1,a0
    80004a94:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a96:	0005b023          	sd	zero,0(a1)
    80004a9a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	bf8080e7          	jalr	-1032(ra) # 80004696 <filealloc>
    80004aa6:	e088                	sd	a0,0(s1)
    80004aa8:	c551                	beqz	a0,80004b34 <pipealloc+0xb2>
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	bec080e7          	jalr	-1044(ra) # 80004696 <filealloc>
    80004ab2:	00aa3023          	sd	a0,0(s4)
    80004ab6:	c92d                	beqz	a0,80004b28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	028080e7          	jalr	40(ra) # 80000ae0 <kalloc>
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	c125                	beqz	a0,80004b22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ac4:	4985                	li	s3,1
    80004ac6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ace:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ad6:	00004597          	auipc	a1,0x4
    80004ada:	bea58593          	addi	a1,a1,-1046 # 800086c0 <syscalls+0x278>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	062080e7          	jalr	98(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004ae6:	609c                	ld	a5,0(s1)
    80004ae8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aec:	609c                	ld	a5,0(s1)
    80004aee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af2:	609c                	ld	a5,0(s1)
    80004af4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004af8:	609c                	ld	a5,0(s1)
    80004afa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004afe:	000a3783          	ld	a5,0(s4)
    80004b02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b06:	000a3783          	ld	a5,0(s4)
    80004b0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b0e:	000a3783          	ld	a5,0(s4)
    80004b12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b1e:	4501                	li	a0,0
    80004b20:	a025                	j	80004b48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b22:	6088                	ld	a0,0(s1)
    80004b24:	e501                	bnez	a0,80004b2c <pipealloc+0xaa>
    80004b26:	a039                	j	80004b34 <pipealloc+0xb2>
    80004b28:	6088                	ld	a0,0(s1)
    80004b2a:	c51d                	beqz	a0,80004b58 <pipealloc+0xd6>
    fileclose(*f0);
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	c26080e7          	jalr	-986(ra) # 80004752 <fileclose>
  if(*f1)
    80004b34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b38:	557d                	li	a0,-1
  if(*f1)
    80004b3a:	c799                	beqz	a5,80004b48 <pipealloc+0xc6>
    fileclose(*f1);
    80004b3c:	853e                	mv	a0,a5
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	c14080e7          	jalr	-1004(ra) # 80004752 <fileclose>
  return -1;
    80004b46:	557d                	li	a0,-1
}
    80004b48:	70a2                	ld	ra,40(sp)
    80004b4a:	7402                	ld	s0,32(sp)
    80004b4c:	64e2                	ld	s1,24(sp)
    80004b4e:	6942                	ld	s2,16(sp)
    80004b50:	69a2                	ld	s3,8(sp)
    80004b52:	6a02                	ld	s4,0(sp)
    80004b54:	6145                	addi	sp,sp,48
    80004b56:	8082                	ret
  return -1;
    80004b58:	557d                	li	a0,-1
    80004b5a:	b7fd                	j	80004b48 <pipealloc+0xc6>

0000000080004b5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	e04a                	sd	s2,0(sp)
    80004b66:	1000                	addi	s0,sp,32
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	064080e7          	jalr	100(ra) # 80000bd0 <acquire>
  if(writable){
    80004b74:	02090d63          	beqz	s2,80004bae <pipeclose+0x52>
    pi->writeopen = 0;
    80004b78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b7c:	21848513          	addi	a0,s1,536
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	682080e7          	jalr	1666(ra) # 80002202 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b88:	2204b783          	ld	a5,544(s1)
    80004b8c:	eb95                	bnez	a5,80004bc0 <pipeclose+0x64>
    release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	0f4080e7          	jalr	244(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	e48080e7          	jalr	-440(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004ba2:	60e2                	ld	ra,24(sp)
    80004ba4:	6442                	ld	s0,16(sp)
    80004ba6:	64a2                	ld	s1,8(sp)
    80004ba8:	6902                	ld	s2,0(sp)
    80004baa:	6105                	addi	sp,sp,32
    80004bac:	8082                	ret
    pi->readopen = 0;
    80004bae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb2:	21c48513          	addi	a0,s1,540
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	64c080e7          	jalr	1612(ra) # 80002202 <wakeup>
    80004bbe:	b7e9                	j	80004b88 <pipeclose+0x2c>
    release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c2080e7          	jalr	194(ra) # 80000c84 <release>
}
    80004bca:	bfe1                	j	80004ba2 <pipeclose+0x46>

0000000080004bcc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bcc:	711d                	addi	sp,sp,-96
    80004bce:	ec86                	sd	ra,88(sp)
    80004bd0:	e8a2                	sd	s0,80(sp)
    80004bd2:	e4a6                	sd	s1,72(sp)
    80004bd4:	e0ca                	sd	s2,64(sp)
    80004bd6:	fc4e                	sd	s3,56(sp)
    80004bd8:	f852                	sd	s4,48(sp)
    80004bda:	f456                	sd	s5,40(sp)
    80004bdc:	f05a                	sd	s6,32(sp)
    80004bde:	ec5e                	sd	s7,24(sp)
    80004be0:	e862                	sd	s8,16(sp)
    80004be2:	1080                	addi	s0,sp,96
    80004be4:	84aa                	mv	s1,a0
    80004be6:	8aae                	mv	s5,a1
    80004be8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	dac080e7          	jalr	-596(ra) # 80001996 <myproc>
    80004bf2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	fda080e7          	jalr	-38(ra) # 80000bd0 <acquire>
  while(i < n){
    80004bfe:	0b405363          	blez	s4,80004ca4 <pipewrite+0xd8>
  int i = 0;
    80004c02:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c04:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c06:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c0a:	21c48b93          	addi	s7,s1,540
    80004c0e:	a089                	j	80004c50 <pipewrite+0x84>
      release(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	072080e7          	jalr	114(ra) # 80000c84 <release>
      return -1;
    80004c1a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c1c:	854a                	mv	a0,s2
    80004c1e:	60e6                	ld	ra,88(sp)
    80004c20:	6446                	ld	s0,80(sp)
    80004c22:	64a6                	ld	s1,72(sp)
    80004c24:	6906                	ld	s2,64(sp)
    80004c26:	79e2                	ld	s3,56(sp)
    80004c28:	7a42                	ld	s4,48(sp)
    80004c2a:	7aa2                	ld	s5,40(sp)
    80004c2c:	7b02                	ld	s6,32(sp)
    80004c2e:	6be2                	ld	s7,24(sp)
    80004c30:	6c42                	ld	s8,16(sp)
    80004c32:	6125                	addi	sp,sp,96
    80004c34:	8082                	ret
      wakeup(&pi->nread);
    80004c36:	8562                	mv	a0,s8
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	5ca080e7          	jalr	1482(ra) # 80002202 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c40:	85a6                	mv	a1,s1
    80004c42:	855e                	mv	a0,s7
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	432080e7          	jalr	1074(ra) # 80002076 <sleep>
  while(i < n){
    80004c4c:	05495d63          	bge	s2,s4,80004ca6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004c50:	2204a783          	lw	a5,544(s1)
    80004c54:	dfd5                	beqz	a5,80004c10 <pipewrite+0x44>
    80004c56:	0289a783          	lw	a5,40(s3)
    80004c5a:	fbdd                	bnez	a5,80004c10 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c5c:	2184a783          	lw	a5,536(s1)
    80004c60:	21c4a703          	lw	a4,540(s1)
    80004c64:	2007879b          	addiw	a5,a5,512
    80004c68:	fcf707e3          	beq	a4,a5,80004c36 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c6c:	4685                	li	a3,1
    80004c6e:	01590633          	add	a2,s2,s5
    80004c72:	faf40593          	addi	a1,s0,-81
    80004c76:	0509b503          	ld	a0,80(s3)
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	a6c080e7          	jalr	-1428(ra) # 800016e6 <copyin>
    80004c82:	03650263          	beq	a0,s6,80004ca6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c86:	21c4a783          	lw	a5,540(s1)
    80004c8a:	0017871b          	addiw	a4,a5,1
    80004c8e:	20e4ae23          	sw	a4,540(s1)
    80004c92:	1ff7f793          	andi	a5,a5,511
    80004c96:	97a6                	add	a5,a5,s1
    80004c98:	faf44703          	lbu	a4,-81(s0)
    80004c9c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ca0:	2905                	addiw	s2,s2,1
    80004ca2:	b76d                	j	80004c4c <pipewrite+0x80>
  int i = 0;
    80004ca4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ca6:	21848513          	addi	a0,s1,536
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	558080e7          	jalr	1368(ra) # 80002202 <wakeup>
  release(&pi->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	fd0080e7          	jalr	-48(ra) # 80000c84 <release>
  return i;
    80004cbc:	b785                	j	80004c1c <pipewrite+0x50>

0000000080004cbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	715d                	addi	sp,sp,-80
    80004cc0:	e486                	sd	ra,72(sp)
    80004cc2:	e0a2                	sd	s0,64(sp)
    80004cc4:	fc26                	sd	s1,56(sp)
    80004cc6:	f84a                	sd	s2,48(sp)
    80004cc8:	f44e                	sd	s3,40(sp)
    80004cca:	f052                	sd	s4,32(sp)
    80004ccc:	ec56                	sd	s5,24(sp)
    80004cce:	e85a                	sd	s6,16(sp)
    80004cd0:	0880                	addi	s0,sp,80
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	892e                	mv	s2,a1
    80004cd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	cbe080e7          	jalr	-834(ra) # 80001996 <myproc>
    80004ce0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	eec080e7          	jalr	-276(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cec:	2184a703          	lw	a4,536(s1)
    80004cf0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	02f71463          	bne	a4,a5,80004d20 <piperead+0x62>
    80004cfc:	2244a783          	lw	a5,548(s1)
    80004d00:	c385                	beqz	a5,80004d20 <piperead+0x62>
    if(pr->killed){
    80004d02:	028a2783          	lw	a5,40(s4)
    80004d06:	ebc9                	bnez	a5,80004d98 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d08:	85a6                	mv	a1,s1
    80004d0a:	854e                	mv	a0,s3
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	36a080e7          	jalr	874(ra) # 80002076 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d14:	2184a703          	lw	a4,536(s1)
    80004d18:	21c4a783          	lw	a5,540(s1)
    80004d1c:	fef700e3          	beq	a4,a5,80004cfc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d22:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d24:	05505463          	blez	s5,80004d6c <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004d28:	2184a783          	lw	a5,536(s1)
    80004d2c:	21c4a703          	lw	a4,540(s1)
    80004d30:	02f70e63          	beq	a4,a5,80004d6c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d34:	0017871b          	addiw	a4,a5,1
    80004d38:	20e4ac23          	sw	a4,536(s1)
    80004d3c:	1ff7f793          	andi	a5,a5,511
    80004d40:	97a6                	add	a5,a5,s1
    80004d42:	0187c783          	lbu	a5,24(a5)
    80004d46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4a:	4685                	li	a3,1
    80004d4c:	fbf40613          	addi	a2,s0,-65
    80004d50:	85ca                	mv	a1,s2
    80004d52:	050a3503          	ld	a0,80(s4)
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	904080e7          	jalr	-1788(ra) # 8000165a <copyout>
    80004d5e:	01650763          	beq	a0,s6,80004d6c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d62:	2985                	addiw	s3,s3,1
    80004d64:	0905                	addi	s2,s2,1
    80004d66:	fd3a91e3          	bne	s5,s3,80004d28 <piperead+0x6a>
    80004d6a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d6c:	21c48513          	addi	a0,s1,540
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	492080e7          	jalr	1170(ra) # 80002202 <wakeup>
  release(&pi->lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f0a080e7          	jalr	-246(ra) # 80000c84 <release>
  return i;
}
    80004d82:	854e                	mv	a0,s3
    80004d84:	60a6                	ld	ra,72(sp)
    80004d86:	6406                	ld	s0,64(sp)
    80004d88:	74e2                	ld	s1,56(sp)
    80004d8a:	7942                	ld	s2,48(sp)
    80004d8c:	79a2                	ld	s3,40(sp)
    80004d8e:	7a02                	ld	s4,32(sp)
    80004d90:	6ae2                	ld	s5,24(sp)
    80004d92:	6b42                	ld	s6,16(sp)
    80004d94:	6161                	addi	sp,sp,80
    80004d96:	8082                	ret
      release(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	eea080e7          	jalr	-278(ra) # 80000c84 <release>
      return -1;
    80004da2:	59fd                	li	s3,-1
    80004da4:	bff9                	j	80004d82 <piperead+0xc4>

0000000080004da6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004da6:	de010113          	addi	sp,sp,-544
    80004daa:	20113c23          	sd	ra,536(sp)
    80004dae:	20813823          	sd	s0,528(sp)
    80004db2:	20913423          	sd	s1,520(sp)
    80004db6:	21213023          	sd	s2,512(sp)
    80004dba:	ffce                	sd	s3,504(sp)
    80004dbc:	fbd2                	sd	s4,496(sp)
    80004dbe:	f7d6                	sd	s5,488(sp)
    80004dc0:	f3da                	sd	s6,480(sp)
    80004dc2:	efde                	sd	s7,472(sp)
    80004dc4:	ebe2                	sd	s8,464(sp)
    80004dc6:	e7e6                	sd	s9,456(sp)
    80004dc8:	e3ea                	sd	s10,448(sp)
    80004dca:	ff6e                	sd	s11,440(sp)
    80004dcc:	1400                	addi	s0,sp,544
    80004dce:	892a                	mv	s2,a0
    80004dd0:	dea43423          	sd	a0,-536(s0)
    80004dd4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	bbe080e7          	jalr	-1090(ra) # 80001996 <myproc>
    80004de0:	84aa                	mv	s1,a0

  begin_op();
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	4a8080e7          	jalr	1192(ra) # 8000428a <begin_op>

  if((ip = namei(path)) == 0){
    80004dea:	854a                	mv	a0,s2
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	27e080e7          	jalr	638(ra) # 8000406a <namei>
    80004df4:	c93d                	beqz	a0,80004e6a <exec+0xc4>
    80004df6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	ab6080e7          	jalr	-1354(ra) # 800038ae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e00:	04000713          	li	a4,64
    80004e04:	4681                	li	a3,0
    80004e06:	e5040613          	addi	a2,s0,-432
    80004e0a:	4581                	li	a1,0
    80004e0c:	8556                	mv	a0,s5
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	d54080e7          	jalr	-684(ra) # 80003b62 <readi>
    80004e16:	04000793          	li	a5,64
    80004e1a:	00f51a63          	bne	a0,a5,80004e2e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e1e:	e5042703          	lw	a4,-432(s0)
    80004e22:	464c47b7          	lui	a5,0x464c4
    80004e26:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e2a:	04f70663          	beq	a4,a5,80004e76 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e2e:	8556                	mv	a0,s5
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	ce0080e7          	jalr	-800(ra) # 80003b10 <iunlockput>
    end_op();
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	4d0080e7          	jalr	1232(ra) # 80004308 <end_op>
  }
  return -1;
    80004e40:	557d                	li	a0,-1
}
    80004e42:	21813083          	ld	ra,536(sp)
    80004e46:	21013403          	ld	s0,528(sp)
    80004e4a:	20813483          	ld	s1,520(sp)
    80004e4e:	20013903          	ld	s2,512(sp)
    80004e52:	79fe                	ld	s3,504(sp)
    80004e54:	7a5e                	ld	s4,496(sp)
    80004e56:	7abe                	ld	s5,488(sp)
    80004e58:	7b1e                	ld	s6,480(sp)
    80004e5a:	6bfe                	ld	s7,472(sp)
    80004e5c:	6c5e                	ld	s8,464(sp)
    80004e5e:	6cbe                	ld	s9,456(sp)
    80004e60:	6d1e                	ld	s10,448(sp)
    80004e62:	7dfa                	ld	s11,440(sp)
    80004e64:	22010113          	addi	sp,sp,544
    80004e68:	8082                	ret
    end_op();
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	49e080e7          	jalr	1182(ra) # 80004308 <end_op>
    return -1;
    80004e72:	557d                	li	a0,-1
    80004e74:	b7f9                	j	80004e42 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	be2080e7          	jalr	-1054(ra) # 80001a5a <proc_pagetable>
    80004e80:	8b2a                	mv	s6,a0
    80004e82:	d555                	beqz	a0,80004e2e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e84:	e7042783          	lw	a5,-400(s0)
    80004e88:	e8845703          	lhu	a4,-376(s0)
    80004e8c:	c735                	beqz	a4,80004ef8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e8e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e90:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004e94:	6a05                	lui	s4,0x1
    80004e96:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e9a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e9e:	6d85                	lui	s11,0x1
    80004ea0:	7d7d                	lui	s10,0xfffff
    80004ea2:	ac1d                	j	800050d8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea4:	00004517          	auipc	a0,0x4
    80004ea8:	82450513          	addi	a0,a0,-2012 # 800086c8 <syscalls+0x280>
    80004eac:	ffffb097          	auipc	ra,0xffffb
    80004eb0:	68e080e7          	jalr	1678(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb4:	874a                	mv	a4,s2
    80004eb6:	009c86bb          	addw	a3,s9,s1
    80004eba:	4581                	li	a1,0
    80004ebc:	8556                	mv	a0,s5
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	ca4080e7          	jalr	-860(ra) # 80003b62 <readi>
    80004ec6:	2501                	sext.w	a0,a0
    80004ec8:	1aa91863          	bne	s2,a0,80005078 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004ecc:	009d84bb          	addw	s1,s11,s1
    80004ed0:	013d09bb          	addw	s3,s10,s3
    80004ed4:	1f74f263          	bgeu	s1,s7,800050b8 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ed8:	02049593          	slli	a1,s1,0x20
    80004edc:	9181                	srli	a1,a1,0x20
    80004ede:	95e2                	add	a1,a1,s8
    80004ee0:	855a                	mv	a0,s6
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	170080e7          	jalr	368(ra) # 80001052 <walkaddr>
    80004eea:	862a                	mv	a2,a0
    if(pa == 0)
    80004eec:	dd45                	beqz	a0,80004ea4 <exec+0xfe>
      n = PGSIZE;
    80004eee:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ef0:	fd49f2e3          	bgeu	s3,s4,80004eb4 <exec+0x10e>
      n = sz - i;
    80004ef4:	894e                	mv	s2,s3
    80004ef6:	bf7d                	j	80004eb4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ef8:	4481                	li	s1,0
  iunlockput(ip);
    80004efa:	8556                	mv	a0,s5
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	c14080e7          	jalr	-1004(ra) # 80003b10 <iunlockput>
  end_op();
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	404080e7          	jalr	1028(ra) # 80004308 <end_op>
  p = myproc();
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	a8a080e7          	jalr	-1398(ra) # 80001996 <myproc>
    80004f14:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f16:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f1a:	6785                	lui	a5,0x1
    80004f1c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f1e:	97a6                	add	a5,a5,s1
    80004f20:	777d                	lui	a4,0xfffff
    80004f22:	8ff9                	and	a5,a5,a4
    80004f24:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f28:	6609                	lui	a2,0x2
    80004f2a:	963e                	add	a2,a2,a5
    80004f2c:	85be                	mv	a1,a5
    80004f2e:	855a                	mv	a0,s6
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	4d6080e7          	jalr	1238(ra) # 80001406 <uvmalloc>
    80004f38:	8c2a                	mv	s8,a0
  ip = 0;
    80004f3a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f3c:	12050e63          	beqz	a0,80005078 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f40:	75f9                	lui	a1,0xffffe
    80004f42:	95aa                	add	a1,a1,a0
    80004f44:	855a                	mv	a0,s6
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	6e2080e7          	jalr	1762(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f4e:	7afd                	lui	s5,0xfffff
    80004f50:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f52:	df043783          	ld	a5,-528(s0)
    80004f56:	6388                	ld	a0,0(a5)
    80004f58:	c925                	beqz	a0,80004fc8 <exec+0x222>
    80004f5a:	e9040993          	addi	s3,s0,-368
    80004f5e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f62:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f64:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	ee2080e7          	jalr	-286(ra) # 80000e48 <strlen>
    80004f6e:	0015079b          	addiw	a5,a0,1
    80004f72:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f76:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f7a:	13596363          	bltu	s2,s5,800050a0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f7e:	df043d83          	ld	s11,-528(s0)
    80004f82:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f86:	8552                	mv	a0,s4
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	ec0080e7          	jalr	-320(ra) # 80000e48 <strlen>
    80004f90:	0015069b          	addiw	a3,a0,1
    80004f94:	8652                	mv	a2,s4
    80004f96:	85ca                	mv	a1,s2
    80004f98:	855a                	mv	a0,s6
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	6c0080e7          	jalr	1728(ra) # 8000165a <copyout>
    80004fa2:	10054363          	bltz	a0,800050a8 <exec+0x302>
    ustack[argc] = sp;
    80004fa6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004faa:	0485                	addi	s1,s1,1
    80004fac:	008d8793          	addi	a5,s11,8
    80004fb0:	def43823          	sd	a5,-528(s0)
    80004fb4:	008db503          	ld	a0,8(s11)
    80004fb8:	c911                	beqz	a0,80004fcc <exec+0x226>
    if(argc >= MAXARG)
    80004fba:	09a1                	addi	s3,s3,8
    80004fbc:	fb3c95e3          	bne	s9,s3,80004f66 <exec+0x1c0>
  sz = sz1;
    80004fc0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc4:	4a81                	li	s5,0
    80004fc6:	a84d                	j	80005078 <exec+0x2d2>
  sp = sz;
    80004fc8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fcc:	00349793          	slli	a5,s1,0x3
    80004fd0:	f9078793          	addi	a5,a5,-112
    80004fd4:	97a2                	add	a5,a5,s0
    80004fd6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fda:	00148693          	addi	a3,s1,1
    80004fde:	068e                	slli	a3,a3,0x3
    80004fe0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fe4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fe8:	01597663          	bgeu	s2,s5,80004ff4 <exec+0x24e>
  sz = sz1;
    80004fec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ff0:	4a81                	li	s5,0
    80004ff2:	a059                	j	80005078 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ff4:	e9040613          	addi	a2,s0,-368
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	855a                	mv	a0,s6
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	65e080e7          	jalr	1630(ra) # 8000165a <copyout>
    80005004:	0a054663          	bltz	a0,800050b0 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005008:	058bb783          	ld	a5,88(s7)
    8000500c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005010:	de843783          	ld	a5,-536(s0)
    80005014:	0007c703          	lbu	a4,0(a5)
    80005018:	cf11                	beqz	a4,80005034 <exec+0x28e>
    8000501a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000501c:	02f00693          	li	a3,47
    80005020:	a039                	j	8000502e <exec+0x288>
      last = s+1;
    80005022:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005026:	0785                	addi	a5,a5,1
    80005028:	fff7c703          	lbu	a4,-1(a5)
    8000502c:	c701                	beqz	a4,80005034 <exec+0x28e>
    if(*s == '/')
    8000502e:	fed71ce3          	bne	a4,a3,80005026 <exec+0x280>
    80005032:	bfc5                	j	80005022 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005034:	4641                	li	a2,16
    80005036:	de843583          	ld	a1,-536(s0)
    8000503a:	158b8513          	addi	a0,s7,344
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	dd8080e7          	jalr	-552(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005046:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000504a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000504e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005052:	058bb783          	ld	a5,88(s7)
    80005056:	e6843703          	ld	a4,-408(s0)
    8000505a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000505c:	058bb783          	ld	a5,88(s7)
    80005060:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005064:	85ea                	mv	a1,s10
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	a90080e7          	jalr	-1392(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000506e:	0004851b          	sext.w	a0,s1
    80005072:	bbc1                	j	80004e42 <exec+0x9c>
    80005074:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005078:	df843583          	ld	a1,-520(s0)
    8000507c:	855a                	mv	a0,s6
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	a78080e7          	jalr	-1416(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80005086:	da0a94e3          	bnez	s5,80004e2e <exec+0x88>
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	bb5d                	j	80004e42 <exec+0x9c>
    8000508e:	de943c23          	sd	s1,-520(s0)
    80005092:	b7dd                	j	80005078 <exec+0x2d2>
    80005094:	de943c23          	sd	s1,-520(s0)
    80005098:	b7c5                	j	80005078 <exec+0x2d2>
    8000509a:	de943c23          	sd	s1,-520(s0)
    8000509e:	bfe9                	j	80005078 <exec+0x2d2>
  sz = sz1;
    800050a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050a4:	4a81                	li	s5,0
    800050a6:	bfc9                	j	80005078 <exec+0x2d2>
  sz = sz1;
    800050a8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ac:	4a81                	li	s5,0
    800050ae:	b7e9                	j	80005078 <exec+0x2d2>
  sz = sz1;
    800050b0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b4:	4a81                	li	s5,0
    800050b6:	b7c9                	j	80005078 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050b8:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050bc:	e0843783          	ld	a5,-504(s0)
    800050c0:	0017869b          	addiw	a3,a5,1
    800050c4:	e0d43423          	sd	a3,-504(s0)
    800050c8:	e0043783          	ld	a5,-512(s0)
    800050cc:	0387879b          	addiw	a5,a5,56
    800050d0:	e8845703          	lhu	a4,-376(s0)
    800050d4:	e2e6d3e3          	bge	a3,a4,80004efa <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050d8:	2781                	sext.w	a5,a5
    800050da:	e0f43023          	sd	a5,-512(s0)
    800050de:	03800713          	li	a4,56
    800050e2:	86be                	mv	a3,a5
    800050e4:	e1840613          	addi	a2,s0,-488
    800050e8:	4581                	li	a1,0
    800050ea:	8556                	mv	a0,s5
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	a76080e7          	jalr	-1418(ra) # 80003b62 <readi>
    800050f4:	03800793          	li	a5,56
    800050f8:	f6f51ee3          	bne	a0,a5,80005074 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800050fc:	e1842783          	lw	a5,-488(s0)
    80005100:	4705                	li	a4,1
    80005102:	fae79de3          	bne	a5,a4,800050bc <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005106:	e4043603          	ld	a2,-448(s0)
    8000510a:	e3843783          	ld	a5,-456(s0)
    8000510e:	f8f660e3          	bltu	a2,a5,8000508e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005112:	e2843783          	ld	a5,-472(s0)
    80005116:	963e                	add	a2,a2,a5
    80005118:	f6f66ee3          	bltu	a2,a5,80005094 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000511c:	85a6                	mv	a1,s1
    8000511e:	855a                	mv	a0,s6
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	2e6080e7          	jalr	742(ra) # 80001406 <uvmalloc>
    80005128:	dea43c23          	sd	a0,-520(s0)
    8000512c:	d53d                	beqz	a0,8000509a <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000512e:	e2843c03          	ld	s8,-472(s0)
    80005132:	de043783          	ld	a5,-544(s0)
    80005136:	00fc77b3          	and	a5,s8,a5
    8000513a:	ff9d                	bnez	a5,80005078 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000513c:	e2042c83          	lw	s9,-480(s0)
    80005140:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005144:	f60b8ae3          	beqz	s7,800050b8 <exec+0x312>
    80005148:	89de                	mv	s3,s7
    8000514a:	4481                	li	s1,0
    8000514c:	b371                	j	80004ed8 <exec+0x132>

000000008000514e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000514e:	7179                	addi	sp,sp,-48
    80005150:	f406                	sd	ra,40(sp)
    80005152:	f022                	sd	s0,32(sp)
    80005154:	ec26                	sd	s1,24(sp)
    80005156:	e84a                	sd	s2,16(sp)
    80005158:	1800                	addi	s0,sp,48
    8000515a:	892e                	mv	s2,a1
    8000515c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000515e:	fdc40593          	addi	a1,s0,-36
    80005162:	ffffe097          	auipc	ra,0xffffe
    80005166:	afa080e7          	jalr	-1286(ra) # 80002c5c <argint>
    8000516a:	04054063          	bltz	a0,800051aa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000516e:	fdc42703          	lw	a4,-36(s0)
    80005172:	47bd                	li	a5,15
    80005174:	02e7ed63          	bltu	a5,a4,800051ae <argfd+0x60>
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	81e080e7          	jalr	-2018(ra) # 80001996 <myproc>
    80005180:	fdc42703          	lw	a4,-36(s0)
    80005184:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80005188:	078e                	slli	a5,a5,0x3
    8000518a:	953e                	add	a0,a0,a5
    8000518c:	611c                	ld	a5,0(a0)
    8000518e:	c395                	beqz	a5,800051b2 <argfd+0x64>
    return -1;
  if(pfd)
    80005190:	00090463          	beqz	s2,80005198 <argfd+0x4a>
    *pfd = fd;
    80005194:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005198:	4501                	li	a0,0
  if(pf)
    8000519a:	c091                	beqz	s1,8000519e <argfd+0x50>
    *pf = f;
    8000519c:	e09c                	sd	a5,0(s1)
}
    8000519e:	70a2                	ld	ra,40(sp)
    800051a0:	7402                	ld	s0,32(sp)
    800051a2:	64e2                	ld	s1,24(sp)
    800051a4:	6942                	ld	s2,16(sp)
    800051a6:	6145                	addi	sp,sp,48
    800051a8:	8082                	ret
    return -1;
    800051aa:	557d                	li	a0,-1
    800051ac:	bfcd                	j	8000519e <argfd+0x50>
    return -1;
    800051ae:	557d                	li	a0,-1
    800051b0:	b7fd                	j	8000519e <argfd+0x50>
    800051b2:	557d                	li	a0,-1
    800051b4:	b7ed                	j	8000519e <argfd+0x50>

00000000800051b6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051b6:	1101                	addi	sp,sp,-32
    800051b8:	ec06                	sd	ra,24(sp)
    800051ba:	e822                	sd	s0,16(sp)
    800051bc:	e426                	sd	s1,8(sp)
    800051be:	1000                	addi	s0,sp,32
    800051c0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	7d4080e7          	jalr	2004(ra) # 80001996 <myproc>
    800051ca:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051cc:	0d050793          	addi	a5,a0,208
    800051d0:	4501                	li	a0,0
    800051d2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051d4:	6398                	ld	a4,0(a5)
    800051d6:	cb19                	beqz	a4,800051ec <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051d8:	2505                	addiw	a0,a0,1
    800051da:	07a1                	addi	a5,a5,8
    800051dc:	fed51ce3          	bne	a0,a3,800051d4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051e0:	557d                	li	a0,-1
}
    800051e2:	60e2                	ld	ra,24(sp)
    800051e4:	6442                	ld	s0,16(sp)
    800051e6:	64a2                	ld	s1,8(sp)
    800051e8:	6105                	addi	sp,sp,32
    800051ea:	8082                	ret
      p->ofile[fd] = f;
    800051ec:	01a50793          	addi	a5,a0,26
    800051f0:	078e                	slli	a5,a5,0x3
    800051f2:	963e                	add	a2,a2,a5
    800051f4:	e204                	sd	s1,0(a2)
      return fd;
    800051f6:	b7f5                	j	800051e2 <fdalloc+0x2c>

00000000800051f8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051f8:	715d                	addi	sp,sp,-80
    800051fa:	e486                	sd	ra,72(sp)
    800051fc:	e0a2                	sd	s0,64(sp)
    800051fe:	fc26                	sd	s1,56(sp)
    80005200:	f84a                	sd	s2,48(sp)
    80005202:	f44e                	sd	s3,40(sp)
    80005204:	f052                	sd	s4,32(sp)
    80005206:	ec56                	sd	s5,24(sp)
    80005208:	0880                	addi	s0,sp,80
    8000520a:	89ae                	mv	s3,a1
    8000520c:	8ab2                	mv	s5,a2
    8000520e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005210:	fb040593          	addi	a1,s0,-80
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	e74080e7          	jalr	-396(ra) # 80004088 <nameiparent>
    8000521c:	892a                	mv	s2,a0
    8000521e:	12050e63          	beqz	a0,8000535a <create+0x162>
    return 0;

  ilock(dp);
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	68c080e7          	jalr	1676(ra) # 800038ae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000522a:	4601                	li	a2,0
    8000522c:	fb040593          	addi	a1,s0,-80
    80005230:	854a                	mv	a0,s2
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	b60080e7          	jalr	-1184(ra) # 80003d92 <dirlookup>
    8000523a:	84aa                	mv	s1,a0
    8000523c:	c921                	beqz	a0,8000528c <create+0x94>
    iunlockput(dp);
    8000523e:	854a                	mv	a0,s2
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	8d0080e7          	jalr	-1840(ra) # 80003b10 <iunlockput>
    ilock(ip);
    80005248:	8526                	mv	a0,s1
    8000524a:	ffffe097          	auipc	ra,0xffffe
    8000524e:	664080e7          	jalr	1636(ra) # 800038ae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005252:	2981                	sext.w	s3,s3
    80005254:	4789                	li	a5,2
    80005256:	02f99463          	bne	s3,a5,8000527e <create+0x86>
    8000525a:	0444d783          	lhu	a5,68(s1)
    8000525e:	37f9                	addiw	a5,a5,-2
    80005260:	17c2                	slli	a5,a5,0x30
    80005262:	93c1                	srli	a5,a5,0x30
    80005264:	4705                	li	a4,1
    80005266:	00f76c63          	bltu	a4,a5,8000527e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000526a:	8526                	mv	a0,s1
    8000526c:	60a6                	ld	ra,72(sp)
    8000526e:	6406                	ld	s0,64(sp)
    80005270:	74e2                	ld	s1,56(sp)
    80005272:	7942                	ld	s2,48(sp)
    80005274:	79a2                	ld	s3,40(sp)
    80005276:	7a02                	ld	s4,32(sp)
    80005278:	6ae2                	ld	s5,24(sp)
    8000527a:	6161                	addi	sp,sp,80
    8000527c:	8082                	ret
    iunlockput(ip);
    8000527e:	8526                	mv	a0,s1
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	890080e7          	jalr	-1904(ra) # 80003b10 <iunlockput>
    return 0;
    80005288:	4481                	li	s1,0
    8000528a:	b7c5                	j	8000526a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000528c:	85ce                	mv	a1,s3
    8000528e:	00092503          	lw	a0,0(s2)
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	482080e7          	jalr	1154(ra) # 80003714 <ialloc>
    8000529a:	84aa                	mv	s1,a0
    8000529c:	c521                	beqz	a0,800052e4 <create+0xec>
  ilock(ip);
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	610080e7          	jalr	1552(ra) # 800038ae <ilock>
  ip->major = major;
    800052a6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052aa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052ae:	4a05                	li	s4,1
    800052b0:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	52c080e7          	jalr	1324(ra) # 800037e2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052be:	2981                	sext.w	s3,s3
    800052c0:	03498a63          	beq	s3,s4,800052f4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052c4:	40d0                	lw	a2,4(s1)
    800052c6:	fb040593          	addi	a1,s0,-80
    800052ca:	854a                	mv	a0,s2
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	cdc080e7          	jalr	-804(ra) # 80003fa8 <dirlink>
    800052d4:	06054b63          	bltz	a0,8000534a <create+0x152>
  iunlockput(dp);
    800052d8:	854a                	mv	a0,s2
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	836080e7          	jalr	-1994(ra) # 80003b10 <iunlockput>
  return ip;
    800052e2:	b761                	j	8000526a <create+0x72>
    panic("create: ialloc");
    800052e4:	00003517          	auipc	a0,0x3
    800052e8:	40450513          	addi	a0,a0,1028 # 800086e8 <syscalls+0x2a0>
    800052ec:	ffffb097          	auipc	ra,0xffffb
    800052f0:	24e080e7          	jalr	590(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    800052f4:	04a95783          	lhu	a5,74(s2)
    800052f8:	2785                	addiw	a5,a5,1
    800052fa:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052fe:	854a                	mv	a0,s2
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	4e2080e7          	jalr	1250(ra) # 800037e2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005308:	40d0                	lw	a2,4(s1)
    8000530a:	00003597          	auipc	a1,0x3
    8000530e:	3ee58593          	addi	a1,a1,1006 # 800086f8 <syscalls+0x2b0>
    80005312:	8526                	mv	a0,s1
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	c94080e7          	jalr	-876(ra) # 80003fa8 <dirlink>
    8000531c:	00054f63          	bltz	a0,8000533a <create+0x142>
    80005320:	00492603          	lw	a2,4(s2)
    80005324:	00003597          	auipc	a1,0x3
    80005328:	3dc58593          	addi	a1,a1,988 # 80008700 <syscalls+0x2b8>
    8000532c:	8526                	mv	a0,s1
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	c7a080e7          	jalr	-902(ra) # 80003fa8 <dirlink>
    80005336:	f80557e3          	bgez	a0,800052c4 <create+0xcc>
      panic("create dots");
    8000533a:	00003517          	auipc	a0,0x3
    8000533e:	3ce50513          	addi	a0,a0,974 # 80008708 <syscalls+0x2c0>
    80005342:	ffffb097          	auipc	ra,0xffffb
    80005346:	1f8080e7          	jalr	504(ra) # 8000053a <panic>
    panic("create: dirlink");
    8000534a:	00003517          	auipc	a0,0x3
    8000534e:	3ce50513          	addi	a0,a0,974 # 80008718 <syscalls+0x2d0>
    80005352:	ffffb097          	auipc	ra,0xffffb
    80005356:	1e8080e7          	jalr	488(ra) # 8000053a <panic>
    return 0;
    8000535a:	84aa                	mv	s1,a0
    8000535c:	b739                	j	8000526a <create+0x72>

000000008000535e <sys_dup>:
{
    8000535e:	7179                	addi	sp,sp,-48
    80005360:	f406                	sd	ra,40(sp)
    80005362:	f022                	sd	s0,32(sp)
    80005364:	ec26                	sd	s1,24(sp)
    80005366:	e84a                	sd	s2,16(sp)
    80005368:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000536a:	fd840613          	addi	a2,s0,-40
    8000536e:	4581                	li	a1,0
    80005370:	4501                	li	a0,0
    80005372:	00000097          	auipc	ra,0x0
    80005376:	ddc080e7          	jalr	-548(ra) # 8000514e <argfd>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000537c:	02054363          	bltz	a0,800053a2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005380:	fd843903          	ld	s2,-40(s0)
    80005384:	854a                	mv	a0,s2
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	e30080e7          	jalr	-464(ra) # 800051b6 <fdalloc>
    8000538e:	84aa                	mv	s1,a0
    return -1;
    80005390:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005392:	00054863          	bltz	a0,800053a2 <sys_dup+0x44>
  filedup(f);
    80005396:	854a                	mv	a0,s2
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	368080e7          	jalr	872(ra) # 80004700 <filedup>
  return fd;
    800053a0:	87a6                	mv	a5,s1
}
    800053a2:	853e                	mv	a0,a5
    800053a4:	70a2                	ld	ra,40(sp)
    800053a6:	7402                	ld	s0,32(sp)
    800053a8:	64e2                	ld	s1,24(sp)
    800053aa:	6942                	ld	s2,16(sp)
    800053ac:	6145                	addi	sp,sp,48
    800053ae:	8082                	ret

00000000800053b0 <sys_read>:
{
    800053b0:	7179                	addi	sp,sp,-48
    800053b2:	f406                	sd	ra,40(sp)
    800053b4:	f022                	sd	s0,32(sp)
    800053b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b8:	fe840613          	addi	a2,s0,-24
    800053bc:	4581                	li	a1,0
    800053be:	4501                	li	a0,0
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	d8e080e7          	jalr	-626(ra) # 8000514e <argfd>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ca:	04054163          	bltz	a0,8000540c <sys_read+0x5c>
    800053ce:	fe440593          	addi	a1,s0,-28
    800053d2:	4509                	li	a0,2
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	888080e7          	jalr	-1912(ra) # 80002c5c <argint>
    return -1;
    800053dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053de:	02054763          	bltz	a0,8000540c <sys_read+0x5c>
    800053e2:	fd840593          	addi	a1,s0,-40
    800053e6:	4505                	li	a0,1
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	896080e7          	jalr	-1898(ra) # 80002c7e <argaddr>
    return -1;
    800053f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f2:	00054d63          	bltz	a0,8000540c <sys_read+0x5c>
  return fileread(f, p, n);
    800053f6:	fe442603          	lw	a2,-28(s0)
    800053fa:	fd843583          	ld	a1,-40(s0)
    800053fe:	fe843503          	ld	a0,-24(s0)
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	48a080e7          	jalr	1162(ra) # 8000488c <fileread>
    8000540a:	87aa                	mv	a5,a0
}
    8000540c:	853e                	mv	a0,a5
    8000540e:	70a2                	ld	ra,40(sp)
    80005410:	7402                	ld	s0,32(sp)
    80005412:	6145                	addi	sp,sp,48
    80005414:	8082                	ret

0000000080005416 <sys_write>:
{
    80005416:	7179                	addi	sp,sp,-48
    80005418:	f406                	sd	ra,40(sp)
    8000541a:	f022                	sd	s0,32(sp)
    8000541c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541e:	fe840613          	addi	a2,s0,-24
    80005422:	4581                	li	a1,0
    80005424:	4501                	li	a0,0
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	d28080e7          	jalr	-728(ra) # 8000514e <argfd>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005430:	04054163          	bltz	a0,80005472 <sys_write+0x5c>
    80005434:	fe440593          	addi	a1,s0,-28
    80005438:	4509                	li	a0,2
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	822080e7          	jalr	-2014(ra) # 80002c5c <argint>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005444:	02054763          	bltz	a0,80005472 <sys_write+0x5c>
    80005448:	fd840593          	addi	a1,s0,-40
    8000544c:	4505                	li	a0,1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	830080e7          	jalr	-2000(ra) # 80002c7e <argaddr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005458:	00054d63          	bltz	a0,80005472 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000545c:	fe442603          	lw	a2,-28(s0)
    80005460:	fd843583          	ld	a1,-40(s0)
    80005464:	fe843503          	ld	a0,-24(s0)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	4e6080e7          	jalr	1254(ra) # 8000494e <filewrite>
    80005470:	87aa                	mv	a5,a0
}
    80005472:	853e                	mv	a0,a5
    80005474:	70a2                	ld	ra,40(sp)
    80005476:	7402                	ld	s0,32(sp)
    80005478:	6145                	addi	sp,sp,48
    8000547a:	8082                	ret

000000008000547c <sys_close>:
{
    8000547c:	1101                	addi	sp,sp,-32
    8000547e:	ec06                	sd	ra,24(sp)
    80005480:	e822                	sd	s0,16(sp)
    80005482:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005484:	fe040613          	addi	a2,s0,-32
    80005488:	fec40593          	addi	a1,s0,-20
    8000548c:	4501                	li	a0,0
    8000548e:	00000097          	auipc	ra,0x0
    80005492:	cc0080e7          	jalr	-832(ra) # 8000514e <argfd>
    return -1;
    80005496:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005498:	02054463          	bltz	a0,800054c0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000549c:	ffffc097          	auipc	ra,0xffffc
    800054a0:	4fa080e7          	jalr	1274(ra) # 80001996 <myproc>
    800054a4:	fec42783          	lw	a5,-20(s0)
    800054a8:	07e9                	addi	a5,a5,26
    800054aa:	078e                	slli	a5,a5,0x3
    800054ac:	953e                	add	a0,a0,a5
    800054ae:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800054b2:	fe043503          	ld	a0,-32(s0)
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	29c080e7          	jalr	668(ra) # 80004752 <fileclose>
  return 0;
    800054be:	4781                	li	a5,0
}
    800054c0:	853e                	mv	a0,a5
    800054c2:	60e2                	ld	ra,24(sp)
    800054c4:	6442                	ld	s0,16(sp)
    800054c6:	6105                	addi	sp,sp,32
    800054c8:	8082                	ret

00000000800054ca <sys_fstat>:
{
    800054ca:	1101                	addi	sp,sp,-32
    800054cc:	ec06                	sd	ra,24(sp)
    800054ce:	e822                	sd	s0,16(sp)
    800054d0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054d2:	fe840613          	addi	a2,s0,-24
    800054d6:	4581                	li	a1,0
    800054d8:	4501                	li	a0,0
    800054da:	00000097          	auipc	ra,0x0
    800054de:	c74080e7          	jalr	-908(ra) # 8000514e <argfd>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e4:	02054563          	bltz	a0,8000550e <sys_fstat+0x44>
    800054e8:	fe040593          	addi	a1,s0,-32
    800054ec:	4505                	li	a0,1
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	790080e7          	jalr	1936(ra) # 80002c7e <argaddr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054f8:	00054b63          	bltz	a0,8000550e <sys_fstat+0x44>
  return filestat(f, st);
    800054fc:	fe043583          	ld	a1,-32(s0)
    80005500:	fe843503          	ld	a0,-24(s0)
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	316080e7          	jalr	790(ra) # 8000481a <filestat>
    8000550c:	87aa                	mv	a5,a0
}
    8000550e:	853e                	mv	a0,a5
    80005510:	60e2                	ld	ra,24(sp)
    80005512:	6442                	ld	s0,16(sp)
    80005514:	6105                	addi	sp,sp,32
    80005516:	8082                	ret

0000000080005518 <sys_link>:
{
    80005518:	7169                	addi	sp,sp,-304
    8000551a:	f606                	sd	ra,296(sp)
    8000551c:	f222                	sd	s0,288(sp)
    8000551e:	ee26                	sd	s1,280(sp)
    80005520:	ea4a                	sd	s2,272(sp)
    80005522:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005524:	08000613          	li	a2,128
    80005528:	ed040593          	addi	a1,s0,-304
    8000552c:	4501                	li	a0,0
    8000552e:	ffffd097          	auipc	ra,0xffffd
    80005532:	772080e7          	jalr	1906(ra) # 80002ca0 <argstr>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005538:	10054e63          	bltz	a0,80005654 <sys_link+0x13c>
    8000553c:	08000613          	li	a2,128
    80005540:	f5040593          	addi	a1,s0,-176
    80005544:	4505                	li	a0,1
    80005546:	ffffd097          	auipc	ra,0xffffd
    8000554a:	75a080e7          	jalr	1882(ra) # 80002ca0 <argstr>
    return -1;
    8000554e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005550:	10054263          	bltz	a0,80005654 <sys_link+0x13c>
  begin_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	d36080e7          	jalr	-714(ra) # 8000428a <begin_op>
  if((ip = namei(old)) == 0){
    8000555c:	ed040513          	addi	a0,s0,-304
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	b0a080e7          	jalr	-1270(ra) # 8000406a <namei>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c551                	beqz	a0,800055f6 <sys_link+0xde>
  ilock(ip);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	342080e7          	jalr	834(ra) # 800038ae <ilock>
  if(ip->type == T_DIR){
    80005574:	04449703          	lh	a4,68(s1)
    80005578:	4785                	li	a5,1
    8000557a:	08f70463          	beq	a4,a5,80005602 <sys_link+0xea>
  ip->nlink++;
    8000557e:	04a4d783          	lhu	a5,74(s1)
    80005582:	2785                	addiw	a5,a5,1
    80005584:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	258080e7          	jalr	600(ra) # 800037e2 <iupdate>
  iunlock(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	3dc080e7          	jalr	988(ra) # 80003970 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000559c:	fd040593          	addi	a1,s0,-48
    800055a0:	f5040513          	addi	a0,s0,-176
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	ae4080e7          	jalr	-1308(ra) # 80004088 <nameiparent>
    800055ac:	892a                	mv	s2,a0
    800055ae:	c935                	beqz	a0,80005622 <sys_link+0x10a>
  ilock(dp);
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	2fe080e7          	jalr	766(ra) # 800038ae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055b8:	00092703          	lw	a4,0(s2)
    800055bc:	409c                	lw	a5,0(s1)
    800055be:	04f71d63          	bne	a4,a5,80005618 <sys_link+0x100>
    800055c2:	40d0                	lw	a2,4(s1)
    800055c4:	fd040593          	addi	a1,s0,-48
    800055c8:	854a                	mv	a0,s2
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	9de080e7          	jalr	-1570(ra) # 80003fa8 <dirlink>
    800055d2:	04054363          	bltz	a0,80005618 <sys_link+0x100>
  iunlockput(dp);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	538080e7          	jalr	1336(ra) # 80003b10 <iunlockput>
  iput(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	486080e7          	jalr	1158(ra) # 80003a68 <iput>
  end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	d1e080e7          	jalr	-738(ra) # 80004308 <end_op>
  return 0;
    800055f2:	4781                	li	a5,0
    800055f4:	a085                	j	80005654 <sys_link+0x13c>
    end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	d12080e7          	jalr	-750(ra) # 80004308 <end_op>
    return -1;
    800055fe:	57fd                	li	a5,-1
    80005600:	a891                	j	80005654 <sys_link+0x13c>
    iunlockput(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	50c080e7          	jalr	1292(ra) # 80003b10 <iunlockput>
    end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	cfc080e7          	jalr	-772(ra) # 80004308 <end_op>
    return -1;
    80005614:	57fd                	li	a5,-1
    80005616:	a83d                	j	80005654 <sys_link+0x13c>
    iunlockput(dp);
    80005618:	854a                	mv	a0,s2
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	4f6080e7          	jalr	1270(ra) # 80003b10 <iunlockput>
  ilock(ip);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	28a080e7          	jalr	650(ra) # 800038ae <ilock>
  ip->nlink--;
    8000562c:	04a4d783          	lhu	a5,74(s1)
    80005630:	37fd                	addiw	a5,a5,-1
    80005632:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	1aa080e7          	jalr	426(ra) # 800037e2 <iupdate>
  iunlockput(ip);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	4ce080e7          	jalr	1230(ra) # 80003b10 <iunlockput>
  end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	cbe080e7          	jalr	-834(ra) # 80004308 <end_op>
  return -1;
    80005652:	57fd                	li	a5,-1
}
    80005654:	853e                	mv	a0,a5
    80005656:	70b2                	ld	ra,296(sp)
    80005658:	7412                	ld	s0,288(sp)
    8000565a:	64f2                	ld	s1,280(sp)
    8000565c:	6952                	ld	s2,272(sp)
    8000565e:	6155                	addi	sp,sp,304
    80005660:	8082                	ret

0000000080005662 <sys_unlink>:
{
    80005662:	7151                	addi	sp,sp,-240
    80005664:	f586                	sd	ra,232(sp)
    80005666:	f1a2                	sd	s0,224(sp)
    80005668:	eda6                	sd	s1,216(sp)
    8000566a:	e9ca                	sd	s2,208(sp)
    8000566c:	e5ce                	sd	s3,200(sp)
    8000566e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005670:	08000613          	li	a2,128
    80005674:	f3040593          	addi	a1,s0,-208
    80005678:	4501                	li	a0,0
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	626080e7          	jalr	1574(ra) # 80002ca0 <argstr>
    80005682:	18054163          	bltz	a0,80005804 <sys_unlink+0x1a2>
  begin_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	c04080e7          	jalr	-1020(ra) # 8000428a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000568e:	fb040593          	addi	a1,s0,-80
    80005692:	f3040513          	addi	a0,s0,-208
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	9f2080e7          	jalr	-1550(ra) # 80004088 <nameiparent>
    8000569e:	84aa                	mv	s1,a0
    800056a0:	c979                	beqz	a0,80005776 <sys_unlink+0x114>
  ilock(dp);
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	20c080e7          	jalr	524(ra) # 800038ae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056aa:	00003597          	auipc	a1,0x3
    800056ae:	04e58593          	addi	a1,a1,78 # 800086f8 <syscalls+0x2b0>
    800056b2:	fb040513          	addi	a0,s0,-80
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	6c2080e7          	jalr	1730(ra) # 80003d78 <namecmp>
    800056be:	14050a63          	beqz	a0,80005812 <sys_unlink+0x1b0>
    800056c2:	00003597          	auipc	a1,0x3
    800056c6:	03e58593          	addi	a1,a1,62 # 80008700 <syscalls+0x2b8>
    800056ca:	fb040513          	addi	a0,s0,-80
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	6aa080e7          	jalr	1706(ra) # 80003d78 <namecmp>
    800056d6:	12050e63          	beqz	a0,80005812 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056da:	f2c40613          	addi	a2,s0,-212
    800056de:	fb040593          	addi	a1,s0,-80
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	6ae080e7          	jalr	1710(ra) # 80003d92 <dirlookup>
    800056ec:	892a                	mv	s2,a0
    800056ee:	12050263          	beqz	a0,80005812 <sys_unlink+0x1b0>
  ilock(ip);
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	1bc080e7          	jalr	444(ra) # 800038ae <ilock>
  if(ip->nlink < 1)
    800056fa:	04a91783          	lh	a5,74(s2)
    800056fe:	08f05263          	blez	a5,80005782 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005702:	04491703          	lh	a4,68(s2)
    80005706:	4785                	li	a5,1
    80005708:	08f70563          	beq	a4,a5,80005792 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000570c:	4641                	li	a2,16
    8000570e:	4581                	li	a1,0
    80005710:	fc040513          	addi	a0,s0,-64
    80005714:	ffffb097          	auipc	ra,0xffffb
    80005718:	5b8080e7          	jalr	1464(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000571c:	4741                	li	a4,16
    8000571e:	f2c42683          	lw	a3,-212(s0)
    80005722:	fc040613          	addi	a2,s0,-64
    80005726:	4581                	li	a1,0
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	530080e7          	jalr	1328(ra) # 80003c5a <writei>
    80005732:	47c1                	li	a5,16
    80005734:	0af51563          	bne	a0,a5,800057de <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005738:	04491703          	lh	a4,68(s2)
    8000573c:	4785                	li	a5,1
    8000573e:	0af70863          	beq	a4,a5,800057ee <sys_unlink+0x18c>
  iunlockput(dp);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	3cc080e7          	jalr	972(ra) # 80003b10 <iunlockput>
  ip->nlink--;
    8000574c:	04a95783          	lhu	a5,74(s2)
    80005750:	37fd                	addiw	a5,a5,-1
    80005752:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005756:	854a                	mv	a0,s2
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	08a080e7          	jalr	138(ra) # 800037e2 <iupdate>
  iunlockput(ip);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	3ae080e7          	jalr	942(ra) # 80003b10 <iunlockput>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	b9e080e7          	jalr	-1122(ra) # 80004308 <end_op>
  return 0;
    80005772:	4501                	li	a0,0
    80005774:	a84d                	j	80005826 <sys_unlink+0x1c4>
    end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	b92080e7          	jalr	-1134(ra) # 80004308 <end_op>
    return -1;
    8000577e:	557d                	li	a0,-1
    80005780:	a05d                	j	80005826 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005782:	00003517          	auipc	a0,0x3
    80005786:	fa650513          	addi	a0,a0,-90 # 80008728 <syscalls+0x2e0>
    8000578a:	ffffb097          	auipc	ra,0xffffb
    8000578e:	db0080e7          	jalr	-592(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005792:	04c92703          	lw	a4,76(s2)
    80005796:	02000793          	li	a5,32
    8000579a:	f6e7f9e3          	bgeu	a5,a4,8000570c <sys_unlink+0xaa>
    8000579e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057a2:	4741                	li	a4,16
    800057a4:	86ce                	mv	a3,s3
    800057a6:	f1840613          	addi	a2,s0,-232
    800057aa:	4581                	li	a1,0
    800057ac:	854a                	mv	a0,s2
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	3b4080e7          	jalr	948(ra) # 80003b62 <readi>
    800057b6:	47c1                	li	a5,16
    800057b8:	00f51b63          	bne	a0,a5,800057ce <sys_unlink+0x16c>
    if(de.inum != 0)
    800057bc:	f1845783          	lhu	a5,-232(s0)
    800057c0:	e7a1                	bnez	a5,80005808 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057c2:	29c1                	addiw	s3,s3,16
    800057c4:	04c92783          	lw	a5,76(s2)
    800057c8:	fcf9ede3          	bltu	s3,a5,800057a2 <sys_unlink+0x140>
    800057cc:	b781                	j	8000570c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057ce:	00003517          	auipc	a0,0x3
    800057d2:	f7250513          	addi	a0,a0,-142 # 80008740 <syscalls+0x2f8>
    800057d6:	ffffb097          	auipc	ra,0xffffb
    800057da:	d64080e7          	jalr	-668(ra) # 8000053a <panic>
    panic("unlink: writei");
    800057de:	00003517          	auipc	a0,0x3
    800057e2:	f7a50513          	addi	a0,a0,-134 # 80008758 <syscalls+0x310>
    800057e6:	ffffb097          	auipc	ra,0xffffb
    800057ea:	d54080e7          	jalr	-684(ra) # 8000053a <panic>
    dp->nlink--;
    800057ee:	04a4d783          	lhu	a5,74(s1)
    800057f2:	37fd                	addiw	a5,a5,-1
    800057f4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	fe8080e7          	jalr	-24(ra) # 800037e2 <iupdate>
    80005802:	b781                	j	80005742 <sys_unlink+0xe0>
    return -1;
    80005804:	557d                	li	a0,-1
    80005806:	a005                	j	80005826 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	306080e7          	jalr	774(ra) # 80003b10 <iunlockput>
  iunlockput(dp);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	2fc080e7          	jalr	764(ra) # 80003b10 <iunlockput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	aec080e7          	jalr	-1300(ra) # 80004308 <end_op>
  return -1;
    80005824:	557d                	li	a0,-1
}
    80005826:	70ae                	ld	ra,232(sp)
    80005828:	740e                	ld	s0,224(sp)
    8000582a:	64ee                	ld	s1,216(sp)
    8000582c:	694e                	ld	s2,208(sp)
    8000582e:	69ae                	ld	s3,200(sp)
    80005830:	616d                	addi	sp,sp,240
    80005832:	8082                	ret

0000000080005834 <sys_open>:

uint64
sys_open(void)
{
    80005834:	7131                	addi	sp,sp,-192
    80005836:	fd06                	sd	ra,184(sp)
    80005838:	f922                	sd	s0,176(sp)
    8000583a:	f526                	sd	s1,168(sp)
    8000583c:	f14a                	sd	s2,160(sp)
    8000583e:	ed4e                	sd	s3,152(sp)
    80005840:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005842:	08000613          	li	a2,128
    80005846:	f5040593          	addi	a1,s0,-176
    8000584a:	4501                	li	a0,0
    8000584c:	ffffd097          	auipc	ra,0xffffd
    80005850:	454080e7          	jalr	1108(ra) # 80002ca0 <argstr>
    return -1;
    80005854:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005856:	0c054163          	bltz	a0,80005918 <sys_open+0xe4>
    8000585a:	f4c40593          	addi	a1,s0,-180
    8000585e:	4505                	li	a0,1
    80005860:	ffffd097          	auipc	ra,0xffffd
    80005864:	3fc080e7          	jalr	1020(ra) # 80002c5c <argint>
    80005868:	0a054863          	bltz	a0,80005918 <sys_open+0xe4>

  begin_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	a1e080e7          	jalr	-1506(ra) # 8000428a <begin_op>

  if(omode & O_CREATE){
    80005874:	f4c42783          	lw	a5,-180(s0)
    80005878:	2007f793          	andi	a5,a5,512
    8000587c:	cbdd                	beqz	a5,80005932 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000587e:	4681                	li	a3,0
    80005880:	4601                	li	a2,0
    80005882:	4589                	li	a1,2
    80005884:	f5040513          	addi	a0,s0,-176
    80005888:	00000097          	auipc	ra,0x0
    8000588c:	970080e7          	jalr	-1680(ra) # 800051f8 <create>
    80005890:	892a                	mv	s2,a0
    if(ip == 0){
    80005892:	c959                	beqz	a0,80005928 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005894:	04491703          	lh	a4,68(s2)
    80005898:	478d                	li	a5,3
    8000589a:	00f71763          	bne	a4,a5,800058a8 <sys_open+0x74>
    8000589e:	04695703          	lhu	a4,70(s2)
    800058a2:	47a5                	li	a5,9
    800058a4:	0ce7ec63          	bltu	a5,a4,8000597c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	dee080e7          	jalr	-530(ra) # 80004696 <filealloc>
    800058b0:	89aa                	mv	s3,a0
    800058b2:	10050263          	beqz	a0,800059b6 <sys_open+0x182>
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	900080e7          	jalr	-1792(ra) # 800051b6 <fdalloc>
    800058be:	84aa                	mv	s1,a0
    800058c0:	0e054663          	bltz	a0,800059ac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058c4:	04491703          	lh	a4,68(s2)
    800058c8:	478d                	li	a5,3
    800058ca:	0cf70463          	beq	a4,a5,80005992 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058ce:	4789                	li	a5,2
    800058d0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058d4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058d8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058dc:	f4c42783          	lw	a5,-180(s0)
    800058e0:	0017c713          	xori	a4,a5,1
    800058e4:	8b05                	andi	a4,a4,1
    800058e6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058ea:	0037f713          	andi	a4,a5,3
    800058ee:	00e03733          	snez	a4,a4
    800058f2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058f6:	4007f793          	andi	a5,a5,1024
    800058fa:	c791                	beqz	a5,80005906 <sys_open+0xd2>
    800058fc:	04491703          	lh	a4,68(s2)
    80005900:	4789                	li	a5,2
    80005902:	08f70f63          	beq	a4,a5,800059a0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005906:	854a                	mv	a0,s2
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	068080e7          	jalr	104(ra) # 80003970 <iunlock>
  end_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	9f8080e7          	jalr	-1544(ra) # 80004308 <end_op>

  return fd;
}
    80005918:	8526                	mv	a0,s1
    8000591a:	70ea                	ld	ra,184(sp)
    8000591c:	744a                	ld	s0,176(sp)
    8000591e:	74aa                	ld	s1,168(sp)
    80005920:	790a                	ld	s2,160(sp)
    80005922:	69ea                	ld	s3,152(sp)
    80005924:	6129                	addi	sp,sp,192
    80005926:	8082                	ret
      end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	9e0080e7          	jalr	-1568(ra) # 80004308 <end_op>
      return -1;
    80005930:	b7e5                	j	80005918 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005932:	f5040513          	addi	a0,s0,-176
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	734080e7          	jalr	1844(ra) # 8000406a <namei>
    8000593e:	892a                	mv	s2,a0
    80005940:	c905                	beqz	a0,80005970 <sys_open+0x13c>
    ilock(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	f6c080e7          	jalr	-148(ra) # 800038ae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000594a:	04491703          	lh	a4,68(s2)
    8000594e:	4785                	li	a5,1
    80005950:	f4f712e3          	bne	a4,a5,80005894 <sys_open+0x60>
    80005954:	f4c42783          	lw	a5,-180(s0)
    80005958:	dba1                	beqz	a5,800058a8 <sys_open+0x74>
      iunlockput(ip);
    8000595a:	854a                	mv	a0,s2
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	1b4080e7          	jalr	436(ra) # 80003b10 <iunlockput>
      end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	9a4080e7          	jalr	-1628(ra) # 80004308 <end_op>
      return -1;
    8000596c:	54fd                	li	s1,-1
    8000596e:	b76d                	j	80005918 <sys_open+0xe4>
      end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	998080e7          	jalr	-1640(ra) # 80004308 <end_op>
      return -1;
    80005978:	54fd                	li	s1,-1
    8000597a:	bf79                	j	80005918 <sys_open+0xe4>
    iunlockput(ip);
    8000597c:	854a                	mv	a0,s2
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	192080e7          	jalr	402(ra) # 80003b10 <iunlockput>
    end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	982080e7          	jalr	-1662(ra) # 80004308 <end_op>
    return -1;
    8000598e:	54fd                	li	s1,-1
    80005990:	b761                	j	80005918 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005992:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005996:	04691783          	lh	a5,70(s2)
    8000599a:	02f99223          	sh	a5,36(s3)
    8000599e:	bf2d                	j	800058d8 <sys_open+0xa4>
    itrunc(ip);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	01a080e7          	jalr	26(ra) # 800039bc <itrunc>
    800059aa:	bfb1                	j	80005906 <sys_open+0xd2>
      fileclose(f);
    800059ac:	854e                	mv	a0,s3
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	da4080e7          	jalr	-604(ra) # 80004752 <fileclose>
    iunlockput(ip);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	158080e7          	jalr	344(ra) # 80003b10 <iunlockput>
    end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	948080e7          	jalr	-1720(ra) # 80004308 <end_op>
    return -1;
    800059c8:	54fd                	li	s1,-1
    800059ca:	b7b9                	j	80005918 <sys_open+0xe4>

00000000800059cc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059cc:	7175                	addi	sp,sp,-144
    800059ce:	e506                	sd	ra,136(sp)
    800059d0:	e122                	sd	s0,128(sp)
    800059d2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	8b6080e7          	jalr	-1866(ra) # 8000428a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059dc:	08000613          	li	a2,128
    800059e0:	f7040593          	addi	a1,s0,-144
    800059e4:	4501                	li	a0,0
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	2ba080e7          	jalr	698(ra) # 80002ca0 <argstr>
    800059ee:	02054963          	bltz	a0,80005a20 <sys_mkdir+0x54>
    800059f2:	4681                	li	a3,0
    800059f4:	4601                	li	a2,0
    800059f6:	4585                	li	a1,1
    800059f8:	f7040513          	addi	a0,s0,-144
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	7fc080e7          	jalr	2044(ra) # 800051f8 <create>
    80005a04:	cd11                	beqz	a0,80005a20 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	10a080e7          	jalr	266(ra) # 80003b10 <iunlockput>
  end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	8fa080e7          	jalr	-1798(ra) # 80004308 <end_op>
  return 0;
    80005a16:	4501                	li	a0,0
}
    80005a18:	60aa                	ld	ra,136(sp)
    80005a1a:	640a                	ld	s0,128(sp)
    80005a1c:	6149                	addi	sp,sp,144
    80005a1e:	8082                	ret
    end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	8e8080e7          	jalr	-1816(ra) # 80004308 <end_op>
    return -1;
    80005a28:	557d                	li	a0,-1
    80005a2a:	b7fd                	j	80005a18 <sys_mkdir+0x4c>

0000000080005a2c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a2c:	7135                	addi	sp,sp,-160
    80005a2e:	ed06                	sd	ra,152(sp)
    80005a30:	e922                	sd	s0,144(sp)
    80005a32:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	856080e7          	jalr	-1962(ra) # 8000428a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a3c:	08000613          	li	a2,128
    80005a40:	f7040593          	addi	a1,s0,-144
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	25a080e7          	jalr	602(ra) # 80002ca0 <argstr>
    80005a4e:	04054a63          	bltz	a0,80005aa2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a52:	f6c40593          	addi	a1,s0,-148
    80005a56:	4505                	li	a0,1
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	204080e7          	jalr	516(ra) # 80002c5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a60:	04054163          	bltz	a0,80005aa2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a64:	f6840593          	addi	a1,s0,-152
    80005a68:	4509                	li	a0,2
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	1f2080e7          	jalr	498(ra) # 80002c5c <argint>
     argint(1, &major) < 0 ||
    80005a72:	02054863          	bltz	a0,80005aa2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a76:	f6841683          	lh	a3,-152(s0)
    80005a7a:	f6c41603          	lh	a2,-148(s0)
    80005a7e:	458d                	li	a1,3
    80005a80:	f7040513          	addi	a0,s0,-144
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	774080e7          	jalr	1908(ra) # 800051f8 <create>
     argint(2, &minor) < 0 ||
    80005a8c:	c919                	beqz	a0,80005aa2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	082080e7          	jalr	130(ra) # 80003b10 <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	872080e7          	jalr	-1934(ra) # 80004308 <end_op>
  return 0;
    80005a9e:	4501                	li	a0,0
    80005aa0:	a031                	j	80005aac <sys_mknod+0x80>
    end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	866080e7          	jalr	-1946(ra) # 80004308 <end_op>
    return -1;
    80005aaa:	557d                	li	a0,-1
}
    80005aac:	60ea                	ld	ra,152(sp)
    80005aae:	644a                	ld	s0,144(sp)
    80005ab0:	610d                	addi	sp,sp,160
    80005ab2:	8082                	ret

0000000080005ab4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ab4:	7135                	addi	sp,sp,-160
    80005ab6:	ed06                	sd	ra,152(sp)
    80005ab8:	e922                	sd	s0,144(sp)
    80005aba:	e526                	sd	s1,136(sp)
    80005abc:	e14a                	sd	s2,128(sp)
    80005abe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac0:	ffffc097          	auipc	ra,0xffffc
    80005ac4:	ed6080e7          	jalr	-298(ra) # 80001996 <myproc>
    80005ac8:	892a                	mv	s2,a0
  
  begin_op();
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	7c0080e7          	jalr	1984(ra) # 8000428a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ad2:	08000613          	li	a2,128
    80005ad6:	f6040593          	addi	a1,s0,-160
    80005ada:	4501                	li	a0,0
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	1c4080e7          	jalr	452(ra) # 80002ca0 <argstr>
    80005ae4:	04054b63          	bltz	a0,80005b3a <sys_chdir+0x86>
    80005ae8:	f6040513          	addi	a0,s0,-160
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	57e080e7          	jalr	1406(ra) # 8000406a <namei>
    80005af4:	84aa                	mv	s1,a0
    80005af6:	c131                	beqz	a0,80005b3a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	db6080e7          	jalr	-586(ra) # 800038ae <ilock>
  if(ip->type != T_DIR){
    80005b00:	04449703          	lh	a4,68(s1)
    80005b04:	4785                	li	a5,1
    80005b06:	04f71063          	bne	a4,a5,80005b46 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	e64080e7          	jalr	-412(ra) # 80003970 <iunlock>
  iput(p->cwd);
    80005b14:	15093503          	ld	a0,336(s2)
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	f50080e7          	jalr	-176(ra) # 80003a68 <iput>
  end_op();
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	7e8080e7          	jalr	2024(ra) # 80004308 <end_op>
  p->cwd = ip;
    80005b28:	14993823          	sd	s1,336(s2)
  return 0;
    80005b2c:	4501                	li	a0,0
}
    80005b2e:	60ea                	ld	ra,152(sp)
    80005b30:	644a                	ld	s0,144(sp)
    80005b32:	64aa                	ld	s1,136(sp)
    80005b34:	690a                	ld	s2,128(sp)
    80005b36:	610d                	addi	sp,sp,160
    80005b38:	8082                	ret
    end_op();
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	7ce080e7          	jalr	1998(ra) # 80004308 <end_op>
    return -1;
    80005b42:	557d                	li	a0,-1
    80005b44:	b7ed                	j	80005b2e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	fc8080e7          	jalr	-56(ra) # 80003b10 <iunlockput>
    end_op();
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	7b8080e7          	jalr	1976(ra) # 80004308 <end_op>
    return -1;
    80005b58:	557d                	li	a0,-1
    80005b5a:	bfd1                	j	80005b2e <sys_chdir+0x7a>

0000000080005b5c <sys_exec>:

uint64
sys_exec(void)
{
    80005b5c:	7145                	addi	sp,sp,-464
    80005b5e:	e786                	sd	ra,456(sp)
    80005b60:	e3a2                	sd	s0,448(sp)
    80005b62:	ff26                	sd	s1,440(sp)
    80005b64:	fb4a                	sd	s2,432(sp)
    80005b66:	f74e                	sd	s3,424(sp)
    80005b68:	f352                	sd	s4,416(sp)
    80005b6a:	ef56                	sd	s5,408(sp)
    80005b6c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b6e:	08000613          	li	a2,128
    80005b72:	f4040593          	addi	a1,s0,-192
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	128080e7          	jalr	296(ra) # 80002ca0 <argstr>
    return -1;
    80005b80:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b82:	0c054b63          	bltz	a0,80005c58 <sys_exec+0xfc>
    80005b86:	e3840593          	addi	a1,s0,-456
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	0f2080e7          	jalr	242(ra) # 80002c7e <argaddr>
    80005b94:	0c054263          	bltz	a0,80005c58 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b98:	10000613          	li	a2,256
    80005b9c:	4581                	li	a1,0
    80005b9e:	e4040513          	addi	a0,s0,-448
    80005ba2:	ffffb097          	auipc	ra,0xffffb
    80005ba6:	12a080e7          	jalr	298(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005baa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bae:	89a6                	mv	s3,s1
    80005bb0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bb2:	02000a13          	li	s4,32
    80005bb6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bba:	00391513          	slli	a0,s2,0x3
    80005bbe:	e3040593          	addi	a1,s0,-464
    80005bc2:	e3843783          	ld	a5,-456(s0)
    80005bc6:	953e                	add	a0,a0,a5
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	ffa080e7          	jalr	-6(ra) # 80002bc2 <fetchaddr>
    80005bd0:	02054a63          	bltz	a0,80005c04 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bd4:	e3043783          	ld	a5,-464(s0)
    80005bd8:	c3b9                	beqz	a5,80005c1e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	f06080e7          	jalr	-250(ra) # 80000ae0 <kalloc>
    80005be2:	85aa                	mv	a1,a0
    80005be4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005be8:	cd11                	beqz	a0,80005c04 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bea:	6605                	lui	a2,0x1
    80005bec:	e3043503          	ld	a0,-464(s0)
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	024080e7          	jalr	36(ra) # 80002c14 <fetchstr>
    80005bf8:	00054663          	bltz	a0,80005c04 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bfc:	0905                	addi	s2,s2,1
    80005bfe:	09a1                	addi	s3,s3,8
    80005c00:	fb491be3          	bne	s2,s4,80005bb6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c04:	f4040913          	addi	s2,s0,-192
    80005c08:	6088                	ld	a0,0(s1)
    80005c0a:	c531                	beqz	a0,80005c56 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c0c:	ffffb097          	auipc	ra,0xffffb
    80005c10:	dd6080e7          	jalr	-554(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c14:	04a1                	addi	s1,s1,8
    80005c16:	ff2499e3          	bne	s1,s2,80005c08 <sys_exec+0xac>
  return -1;
    80005c1a:	597d                	li	s2,-1
    80005c1c:	a835                	j	80005c58 <sys_exec+0xfc>
      argv[i] = 0;
    80005c1e:	0a8e                	slli	s5,s5,0x3
    80005c20:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005c24:	00878ab3          	add	s5,a5,s0
    80005c28:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c2c:	e4040593          	addi	a1,s0,-448
    80005c30:	f4040513          	addi	a0,s0,-192
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	172080e7          	jalr	370(ra) # 80004da6 <exec>
    80005c3c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c3e:	f4040993          	addi	s3,s0,-192
    80005c42:	6088                	ld	a0,0(s1)
    80005c44:	c911                	beqz	a0,80005c58 <sys_exec+0xfc>
    kfree(argv[i]);
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	d9c080e7          	jalr	-612(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c4e:	04a1                	addi	s1,s1,8
    80005c50:	ff3499e3          	bne	s1,s3,80005c42 <sys_exec+0xe6>
    80005c54:	a011                	j	80005c58 <sys_exec+0xfc>
  return -1;
    80005c56:	597d                	li	s2,-1
}
    80005c58:	854a                	mv	a0,s2
    80005c5a:	60be                	ld	ra,456(sp)
    80005c5c:	641e                	ld	s0,448(sp)
    80005c5e:	74fa                	ld	s1,440(sp)
    80005c60:	795a                	ld	s2,432(sp)
    80005c62:	79ba                	ld	s3,424(sp)
    80005c64:	7a1a                	ld	s4,416(sp)
    80005c66:	6afa                	ld	s5,408(sp)
    80005c68:	6179                	addi	sp,sp,464
    80005c6a:	8082                	ret

0000000080005c6c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c6c:	7139                	addi	sp,sp,-64
    80005c6e:	fc06                	sd	ra,56(sp)
    80005c70:	f822                	sd	s0,48(sp)
    80005c72:	f426                	sd	s1,40(sp)
    80005c74:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c76:	ffffc097          	auipc	ra,0xffffc
    80005c7a:	d20080e7          	jalr	-736(ra) # 80001996 <myproc>
    80005c7e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c80:	fd840593          	addi	a1,s0,-40
    80005c84:	4501                	li	a0,0
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	ff8080e7          	jalr	-8(ra) # 80002c7e <argaddr>
    return -1;
    80005c8e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c90:	0e054063          	bltz	a0,80005d70 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c94:	fc840593          	addi	a1,s0,-56
    80005c98:	fd040513          	addi	a0,s0,-48
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	de6080e7          	jalr	-538(ra) # 80004a82 <pipealloc>
    return -1;
    80005ca4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ca6:	0c054563          	bltz	a0,80005d70 <sys_pipe+0x104>
  fd0 = -1;
    80005caa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cae:	fd043503          	ld	a0,-48(s0)
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	504080e7          	jalr	1284(ra) # 800051b6 <fdalloc>
    80005cba:	fca42223          	sw	a0,-60(s0)
    80005cbe:	08054c63          	bltz	a0,80005d56 <sys_pipe+0xea>
    80005cc2:	fc843503          	ld	a0,-56(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	4f0080e7          	jalr	1264(ra) # 800051b6 <fdalloc>
    80005cce:	fca42023          	sw	a0,-64(s0)
    80005cd2:	06054963          	bltz	a0,80005d44 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd6:	4691                	li	a3,4
    80005cd8:	fc440613          	addi	a2,s0,-60
    80005cdc:	fd843583          	ld	a1,-40(s0)
    80005ce0:	68a8                	ld	a0,80(s1)
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	978080e7          	jalr	-1672(ra) # 8000165a <copyout>
    80005cea:	02054063          	bltz	a0,80005d0a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cee:	4691                	li	a3,4
    80005cf0:	fc040613          	addi	a2,s0,-64
    80005cf4:	fd843583          	ld	a1,-40(s0)
    80005cf8:	0591                	addi	a1,a1,4
    80005cfa:	68a8                	ld	a0,80(s1)
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	95e080e7          	jalr	-1698(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d04:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d06:	06055563          	bgez	a0,80005d70 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d0a:	fc442783          	lw	a5,-60(s0)
    80005d0e:	07e9                	addi	a5,a5,26
    80005d10:	078e                	slli	a5,a5,0x3
    80005d12:	97a6                	add	a5,a5,s1
    80005d14:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d18:	fc042783          	lw	a5,-64(s0)
    80005d1c:	07e9                	addi	a5,a5,26
    80005d1e:	078e                	slli	a5,a5,0x3
    80005d20:	00f48533          	add	a0,s1,a5
    80005d24:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d28:	fd043503          	ld	a0,-48(s0)
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	a26080e7          	jalr	-1498(ra) # 80004752 <fileclose>
    fileclose(wf);
    80005d34:	fc843503          	ld	a0,-56(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	a1a080e7          	jalr	-1510(ra) # 80004752 <fileclose>
    return -1;
    80005d40:	57fd                	li	a5,-1
    80005d42:	a03d                	j	80005d70 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d44:	fc442783          	lw	a5,-60(s0)
    80005d48:	0007c763          	bltz	a5,80005d56 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d4c:	07e9                	addi	a5,a5,26
    80005d4e:	078e                	slli	a5,a5,0x3
    80005d50:	97a6                	add	a5,a5,s1
    80005d52:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005d56:	fd043503          	ld	a0,-48(s0)
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	9f8080e7          	jalr	-1544(ra) # 80004752 <fileclose>
    fileclose(wf);
    80005d62:	fc843503          	ld	a0,-56(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	9ec080e7          	jalr	-1556(ra) # 80004752 <fileclose>
    return -1;
    80005d6e:	57fd                	li	a5,-1
}
    80005d70:	853e                	mv	a0,a5
    80005d72:	70e2                	ld	ra,56(sp)
    80005d74:	7442                	ld	s0,48(sp)
    80005d76:	74a2                	ld	s1,40(sp)
    80005d78:	6121                	addi	sp,sp,64
    80005d7a:	8082                	ret
    80005d7c:	0000                	unimp
	...

0000000080005d80 <kernelvec>:
    80005d80:	7111                	addi	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	ccffc0ef          	jal	ra,80002a8e <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	addi	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	addi	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	addi	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b12080e7          	jalr	-1262(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	slliw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	slliw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	97aa                	add	a5,a5,a0
    80005e7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	addi	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	ada080e7          	jalr	-1318(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5151b          	slliw	a0,a0,0xd
    80005e9c:	0c2017b7          	lui	a5,0xc201
    80005ea0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ea2:	43c8                	lw	a0,4(a5)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	addi	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	addi	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ab2080e7          	jalr	-1358(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	slliw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	addi	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	addi	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	06a7c863          	blt	a5,a0,80005f50 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	0001d717          	auipc	a4,0x1d
    80005ee8:	11c70713          	addi	a4,a4,284 # 80023000 <disk>
    80005eec:	972a                	add	a4,a4,a0
    80005eee:	6789                	lui	a5,0x2
    80005ef0:	97ba                	add	a5,a5,a4
    80005ef2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ef6:	e7ad                	bnez	a5,80005f60 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ef8:	00451793          	slli	a5,a0,0x4
    80005efc:	0001f717          	auipc	a4,0x1f
    80005f00:	10470713          	addi	a4,a4,260 # 80025000 <disk+0x2000>
    80005f04:	6314                	ld	a3,0(a4)
    80005f06:	96be                	add	a3,a3,a5
    80005f08:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f0c:	6314                	ld	a3,0(a4)
    80005f0e:	96be                	add	a3,a3,a5
    80005f10:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f14:	6314                	ld	a3,0(a4)
    80005f16:	96be                	add	a3,a3,a5
    80005f18:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f1c:	6318                	ld	a4,0(a4)
    80005f1e:	97ba                	add	a5,a5,a4
    80005f20:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f24:	0001d717          	auipc	a4,0x1d
    80005f28:	0dc70713          	addi	a4,a4,220 # 80023000 <disk>
    80005f2c:	972a                	add	a4,a4,a0
    80005f2e:	6789                	lui	a5,0x2
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	4705                	li	a4,1
    80005f34:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f38:	0001f517          	auipc	a0,0x1f
    80005f3c:	0e050513          	addi	a0,a0,224 # 80025018 <disk+0x2018>
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	2c2080e7          	jalr	706(ra) # 80002202 <wakeup>
}
    80005f48:	60a2                	ld	ra,8(sp)
    80005f4a:	6402                	ld	s0,0(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret
    panic("free_desc 1");
    80005f50:	00003517          	auipc	a0,0x3
    80005f54:	81850513          	addi	a0,a0,-2024 # 80008768 <syscalls+0x320>
    80005f58:	ffffa097          	auipc	ra,0xffffa
    80005f5c:	5e2080e7          	jalr	1506(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005f60:	00003517          	auipc	a0,0x3
    80005f64:	81850513          	addi	a0,a0,-2024 # 80008778 <syscalls+0x330>
    80005f68:	ffffa097          	auipc	ra,0xffffa
    80005f6c:	5d2080e7          	jalr	1490(ra) # 8000053a <panic>

0000000080005f70 <virtio_disk_init>:
{
    80005f70:	1101                	addi	sp,sp,-32
    80005f72:	ec06                	sd	ra,24(sp)
    80005f74:	e822                	sd	s0,16(sp)
    80005f76:	e426                	sd	s1,8(sp)
    80005f78:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f7a:	00003597          	auipc	a1,0x3
    80005f7e:	80e58593          	addi	a1,a1,-2034 # 80008788 <syscalls+0x340>
    80005f82:	0001f517          	auipc	a0,0x1f
    80005f86:	1a650513          	addi	a0,a0,422 # 80025128 <disk+0x2128>
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	bb6080e7          	jalr	-1098(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f92:	100017b7          	lui	a5,0x10001
    80005f96:	4398                	lw	a4,0(a5)
    80005f98:	2701                	sext.w	a4,a4
    80005f9a:	747277b7          	lui	a5,0x74727
    80005f9e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fa2:	0ef71063          	bne	a4,a5,80006082 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fa6:	100017b7          	lui	a5,0x10001
    80005faa:	43dc                	lw	a5,4(a5)
    80005fac:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fae:	4705                	li	a4,1
    80005fb0:	0ce79963          	bne	a5,a4,80006082 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb4:	100017b7          	lui	a5,0x10001
    80005fb8:	479c                	lw	a5,8(a5)
    80005fba:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fbc:	4709                	li	a4,2
    80005fbe:	0ce79263          	bne	a5,a4,80006082 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fc2:	100017b7          	lui	a5,0x10001
    80005fc6:	47d8                	lw	a4,12(a5)
    80005fc8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fca:	554d47b7          	lui	a5,0x554d4
    80005fce:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fd2:	0af71863          	bne	a4,a5,80006082 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	100017b7          	lui	a5,0x10001
    80005fda:	4705                	li	a4,1
    80005fdc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fde:	470d                	li	a4,3
    80005fe0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fe2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe4:	c7ffe6b7          	lui	a3,0xc7ffe
    80005fe8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fec:	8f75                	and	a4,a4,a3
    80005fee:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	472d                	li	a4,11
    80005ff2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff4:	473d                	li	a4,15
    80005ff6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ff8:	6705                	lui	a4,0x1
    80005ffa:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ffc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006000:	5bdc                	lw	a5,52(a5)
    80006002:	2781                	sext.w	a5,a5
  if(max == 0)
    80006004:	c7d9                	beqz	a5,80006092 <virtio_disk_init+0x122>
  if(max < NUM)
    80006006:	471d                	li	a4,7
    80006008:	08f77d63          	bgeu	a4,a5,800060a2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000600c:	100014b7          	lui	s1,0x10001
    80006010:	47a1                	li	a5,8
    80006012:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006014:	6609                	lui	a2,0x2
    80006016:	4581                	li	a1,0
    80006018:	0001d517          	auipc	a0,0x1d
    8000601c:	fe850513          	addi	a0,a0,-24 # 80023000 <disk>
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	cac080e7          	jalr	-852(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006028:	0001d717          	auipc	a4,0x1d
    8000602c:	fd870713          	addi	a4,a4,-40 # 80023000 <disk>
    80006030:	00c75793          	srli	a5,a4,0xc
    80006034:	2781                	sext.w	a5,a5
    80006036:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006038:	0001f797          	auipc	a5,0x1f
    8000603c:	fc878793          	addi	a5,a5,-56 # 80025000 <disk+0x2000>
    80006040:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006042:	0001d717          	auipc	a4,0x1d
    80006046:	03e70713          	addi	a4,a4,62 # 80023080 <disk+0x80>
    8000604a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000604c:	0001e717          	auipc	a4,0x1e
    80006050:	fb470713          	addi	a4,a4,-76 # 80024000 <disk+0x1000>
    80006054:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006056:	4705                	li	a4,1
    80006058:	00e78c23          	sb	a4,24(a5)
    8000605c:	00e78ca3          	sb	a4,25(a5)
    80006060:	00e78d23          	sb	a4,26(a5)
    80006064:	00e78da3          	sb	a4,27(a5)
    80006068:	00e78e23          	sb	a4,28(a5)
    8000606c:	00e78ea3          	sb	a4,29(a5)
    80006070:	00e78f23          	sb	a4,30(a5)
    80006074:	00e78fa3          	sb	a4,31(a5)
}
    80006078:	60e2                	ld	ra,24(sp)
    8000607a:	6442                	ld	s0,16(sp)
    8000607c:	64a2                	ld	s1,8(sp)
    8000607e:	6105                	addi	sp,sp,32
    80006080:	8082                	ret
    panic("could not find virtio disk");
    80006082:	00002517          	auipc	a0,0x2
    80006086:	71650513          	addi	a0,a0,1814 # 80008798 <syscalls+0x350>
    8000608a:	ffffa097          	auipc	ra,0xffffa
    8000608e:	4b0080e7          	jalr	1200(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006092:	00002517          	auipc	a0,0x2
    80006096:	72650513          	addi	a0,a0,1830 # 800087b8 <syscalls+0x370>
    8000609a:	ffffa097          	auipc	ra,0xffffa
    8000609e:	4a0080e7          	jalr	1184(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    800060a2:	00002517          	auipc	a0,0x2
    800060a6:	73650513          	addi	a0,a0,1846 # 800087d8 <syscalls+0x390>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	490080e7          	jalr	1168(ra) # 8000053a <panic>

00000000800060b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060b2:	7119                	addi	sp,sp,-128
    800060b4:	fc86                	sd	ra,120(sp)
    800060b6:	f8a2                	sd	s0,112(sp)
    800060b8:	f4a6                	sd	s1,104(sp)
    800060ba:	f0ca                	sd	s2,96(sp)
    800060bc:	ecce                	sd	s3,88(sp)
    800060be:	e8d2                	sd	s4,80(sp)
    800060c0:	e4d6                	sd	s5,72(sp)
    800060c2:	e0da                	sd	s6,64(sp)
    800060c4:	fc5e                	sd	s7,56(sp)
    800060c6:	f862                	sd	s8,48(sp)
    800060c8:	f466                	sd	s9,40(sp)
    800060ca:	f06a                	sd	s10,32(sp)
    800060cc:	ec6e                	sd	s11,24(sp)
    800060ce:	0100                	addi	s0,sp,128
    800060d0:	8aaa                	mv	s5,a0
    800060d2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060d4:	00c52c83          	lw	s9,12(a0)
    800060d8:	001c9c9b          	slliw	s9,s9,0x1
    800060dc:	1c82                	slli	s9,s9,0x20
    800060de:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060e2:	0001f517          	auipc	a0,0x1f
    800060e6:	04650513          	addi	a0,a0,70 # 80025128 <disk+0x2128>
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	ae6080e7          	jalr	-1306(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    800060f2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060f6:	0001dc17          	auipc	s8,0x1d
    800060fa:	f0ac0c13          	addi	s8,s8,-246 # 80023000 <disk>
    800060fe:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006100:	4b0d                	li	s6,3
    80006102:	a0ad                	j	8000616c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006104:	00fc0733          	add	a4,s8,a5
    80006108:	975e                	add	a4,a4,s7
    8000610a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000610e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006110:	0207c563          	bltz	a5,8000613a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006114:	2905                	addiw	s2,s2,1
    80006116:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006118:	19690c63          	beq	s2,s6,800062b0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000611c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000611e:	0001f717          	auipc	a4,0x1f
    80006122:	efa70713          	addi	a4,a4,-262 # 80025018 <disk+0x2018>
    80006126:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006128:	00074683          	lbu	a3,0(a4)
    8000612c:	fee1                	bnez	a3,80006104 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000612e:	2785                	addiw	a5,a5,1
    80006130:	0705                	addi	a4,a4,1
    80006132:	fe979be3          	bne	a5,s1,80006128 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006136:	57fd                	li	a5,-1
    80006138:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000613a:	01205d63          	blez	s2,80006154 <virtio_disk_rw+0xa2>
    8000613e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006140:	000a2503          	lw	a0,0(s4)
    80006144:	00000097          	auipc	ra,0x0
    80006148:	d92080e7          	jalr	-622(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    8000614c:	2d85                	addiw	s11,s11,1
    8000614e:	0a11                	addi	s4,s4,4
    80006150:	ff2d98e3          	bne	s11,s2,80006140 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006154:	0001f597          	auipc	a1,0x1f
    80006158:	fd458593          	addi	a1,a1,-44 # 80025128 <disk+0x2128>
    8000615c:	0001f517          	auipc	a0,0x1f
    80006160:	ebc50513          	addi	a0,a0,-324 # 80025018 <disk+0x2018>
    80006164:	ffffc097          	auipc	ra,0xffffc
    80006168:	f12080e7          	jalr	-238(ra) # 80002076 <sleep>
  for(int i = 0; i < 3; i++){
    8000616c:	f8040a13          	addi	s4,s0,-128
{
    80006170:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006172:	894e                	mv	s2,s3
    80006174:	b765                	j	8000611c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006176:	0001f697          	auipc	a3,0x1f
    8000617a:	e8a6b683          	ld	a3,-374(a3) # 80025000 <disk+0x2000>
    8000617e:	96ba                	add	a3,a3,a4
    80006180:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006184:	0001d817          	auipc	a6,0x1d
    80006188:	e7c80813          	addi	a6,a6,-388 # 80023000 <disk>
    8000618c:	0001f697          	auipc	a3,0x1f
    80006190:	e7468693          	addi	a3,a3,-396 # 80025000 <disk+0x2000>
    80006194:	6290                	ld	a2,0(a3)
    80006196:	963a                	add	a2,a2,a4
    80006198:	00c65583          	lhu	a1,12(a2)
    8000619c:	0015e593          	ori	a1,a1,1
    800061a0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800061a4:	f8842603          	lw	a2,-120(s0)
    800061a8:	628c                	ld	a1,0(a3)
    800061aa:	972e                	add	a4,a4,a1
    800061ac:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061b0:	20050593          	addi	a1,a0,512
    800061b4:	0592                	slli	a1,a1,0x4
    800061b6:	95c2                	add	a1,a1,a6
    800061b8:	577d                	li	a4,-1
    800061ba:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061be:	00461713          	slli	a4,a2,0x4
    800061c2:	6290                	ld	a2,0(a3)
    800061c4:	963a                	add	a2,a2,a4
    800061c6:	03078793          	addi	a5,a5,48
    800061ca:	97c2                	add	a5,a5,a6
    800061cc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800061ce:	629c                	ld	a5,0(a3)
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	4605                	li	a2,1
    800061d4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d6:	629c                	ld	a5,0(a3)
    800061d8:	97ba                	add	a5,a5,a4
    800061da:	4809                	li	a6,2
    800061dc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061e0:	629c                	ld	a5,0(a3)
    800061e2:	97ba                	add	a5,a5,a4
    800061e4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061e8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061ec:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061f0:	6698                	ld	a4,8(a3)
    800061f2:	00275783          	lhu	a5,2(a4)
    800061f6:	8b9d                	andi	a5,a5,7
    800061f8:	0786                	slli	a5,a5,0x1
    800061fa:	973e                	add	a4,a4,a5
    800061fc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006200:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006204:	6698                	ld	a4,8(a3)
    80006206:	00275783          	lhu	a5,2(a4)
    8000620a:	2785                	addiw	a5,a5,1
    8000620c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006210:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006214:	100017b7          	lui	a5,0x10001
    80006218:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000621c:	004aa783          	lw	a5,4(s5)
    80006220:	02c79163          	bne	a5,a2,80006242 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006224:	0001f917          	auipc	s2,0x1f
    80006228:	f0490913          	addi	s2,s2,-252 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000622c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000622e:	85ca                	mv	a1,s2
    80006230:	8556                	mv	a0,s5
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	e44080e7          	jalr	-444(ra) # 80002076 <sleep>
  while(b->disk == 1) {
    8000623a:	004aa783          	lw	a5,4(s5)
    8000623e:	fe9788e3          	beq	a5,s1,8000622e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006242:	f8042903          	lw	s2,-128(s0)
    80006246:	20090713          	addi	a4,s2,512
    8000624a:	0712                	slli	a4,a4,0x4
    8000624c:	0001d797          	auipc	a5,0x1d
    80006250:	db478793          	addi	a5,a5,-588 # 80023000 <disk>
    80006254:	97ba                	add	a5,a5,a4
    80006256:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000625a:	0001f997          	auipc	s3,0x1f
    8000625e:	da698993          	addi	s3,s3,-602 # 80025000 <disk+0x2000>
    80006262:	00491713          	slli	a4,s2,0x4
    80006266:	0009b783          	ld	a5,0(s3)
    8000626a:	97ba                	add	a5,a5,a4
    8000626c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006270:	854a                	mv	a0,s2
    80006272:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006276:	00000097          	auipc	ra,0x0
    8000627a:	c60080e7          	jalr	-928(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000627e:	8885                	andi	s1,s1,1
    80006280:	f0ed                	bnez	s1,80006262 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006282:	0001f517          	auipc	a0,0x1f
    80006286:	ea650513          	addi	a0,a0,-346 # 80025128 <disk+0x2128>
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	9fa080e7          	jalr	-1542(ra) # 80000c84 <release>
}
    80006292:	70e6                	ld	ra,120(sp)
    80006294:	7446                	ld	s0,112(sp)
    80006296:	74a6                	ld	s1,104(sp)
    80006298:	7906                	ld	s2,96(sp)
    8000629a:	69e6                	ld	s3,88(sp)
    8000629c:	6a46                	ld	s4,80(sp)
    8000629e:	6aa6                	ld	s5,72(sp)
    800062a0:	6b06                	ld	s6,64(sp)
    800062a2:	7be2                	ld	s7,56(sp)
    800062a4:	7c42                	ld	s8,48(sp)
    800062a6:	7ca2                	ld	s9,40(sp)
    800062a8:	7d02                	ld	s10,32(sp)
    800062aa:	6de2                	ld	s11,24(sp)
    800062ac:	6109                	addi	sp,sp,128
    800062ae:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062b0:	f8042503          	lw	a0,-128(s0)
    800062b4:	20050793          	addi	a5,a0,512
    800062b8:	0792                	slli	a5,a5,0x4
  if(write)
    800062ba:	0001d817          	auipc	a6,0x1d
    800062be:	d4680813          	addi	a6,a6,-698 # 80023000 <disk>
    800062c2:	00f80733          	add	a4,a6,a5
    800062c6:	01a036b3          	snez	a3,s10
    800062ca:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800062ce:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062d2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d6:	7679                	lui	a2,0xffffe
    800062d8:	963e                	add	a2,a2,a5
    800062da:	0001f697          	auipc	a3,0x1f
    800062de:	d2668693          	addi	a3,a3,-730 # 80025000 <disk+0x2000>
    800062e2:	6298                	ld	a4,0(a3)
    800062e4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	0a878593          	addi	a1,a5,168
    800062ea:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ec:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062ee:	6298                	ld	a4,0(a3)
    800062f0:	9732                	add	a4,a4,a2
    800062f2:	45c1                	li	a1,16
    800062f4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062f6:	6298                	ld	a4,0(a3)
    800062f8:	9732                	add	a4,a4,a2
    800062fa:	4585                	li	a1,1
    800062fc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006300:	f8442703          	lw	a4,-124(s0)
    80006304:	628c                	ld	a1,0(a3)
    80006306:	962e                	add	a2,a2,a1
    80006308:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000630c:	0712                	slli	a4,a4,0x4
    8000630e:	6290                	ld	a2,0(a3)
    80006310:	963a                	add	a2,a2,a4
    80006312:	058a8593          	addi	a1,s5,88
    80006316:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006318:	6294                	ld	a3,0(a3)
    8000631a:	96ba                	add	a3,a3,a4
    8000631c:	40000613          	li	a2,1024
    80006320:	c690                	sw	a2,8(a3)
  if(write)
    80006322:	e40d1ae3          	bnez	s10,80006176 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006326:	0001f697          	auipc	a3,0x1f
    8000632a:	cda6b683          	ld	a3,-806(a3) # 80025000 <disk+0x2000>
    8000632e:	96ba                	add	a3,a3,a4
    80006330:	4609                	li	a2,2
    80006332:	00c69623          	sh	a2,12(a3)
    80006336:	b5b9                	j	80006184 <virtio_disk_rw+0xd2>

0000000080006338 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006338:	1101                	addi	sp,sp,-32
    8000633a:	ec06                	sd	ra,24(sp)
    8000633c:	e822                	sd	s0,16(sp)
    8000633e:	e426                	sd	s1,8(sp)
    80006340:	e04a                	sd	s2,0(sp)
    80006342:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006344:	0001f517          	auipc	a0,0x1f
    80006348:	de450513          	addi	a0,a0,-540 # 80025128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	884080e7          	jalr	-1916(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006354:	10001737          	lui	a4,0x10001
    80006358:	533c                	lw	a5,96(a4)
    8000635a:	8b8d                	andi	a5,a5,3
    8000635c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000635e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006362:	0001f797          	auipc	a5,0x1f
    80006366:	c9e78793          	addi	a5,a5,-866 # 80025000 <disk+0x2000>
    8000636a:	6b94                	ld	a3,16(a5)
    8000636c:	0207d703          	lhu	a4,32(a5)
    80006370:	0026d783          	lhu	a5,2(a3)
    80006374:	06f70163          	beq	a4,a5,800063d6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006378:	0001d917          	auipc	s2,0x1d
    8000637c:	c8890913          	addi	s2,s2,-888 # 80023000 <disk>
    80006380:	0001f497          	auipc	s1,0x1f
    80006384:	c8048493          	addi	s1,s1,-896 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006388:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000638c:	6898                	ld	a4,16(s1)
    8000638e:	0204d783          	lhu	a5,32(s1)
    80006392:	8b9d                	andi	a5,a5,7
    80006394:	078e                	slli	a5,a5,0x3
    80006396:	97ba                	add	a5,a5,a4
    80006398:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000639a:	20078713          	addi	a4,a5,512
    8000639e:	0712                	slli	a4,a4,0x4
    800063a0:	974a                	add	a4,a4,s2
    800063a2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063a6:	e731                	bnez	a4,800063f2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063a8:	20078793          	addi	a5,a5,512
    800063ac:	0792                	slli	a5,a5,0x4
    800063ae:	97ca                	add	a5,a5,s2
    800063b0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063b2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063b6:	ffffc097          	auipc	ra,0xffffc
    800063ba:	e4c080e7          	jalr	-436(ra) # 80002202 <wakeup>

    disk.used_idx += 1;
    800063be:	0204d783          	lhu	a5,32(s1)
    800063c2:	2785                	addiw	a5,a5,1
    800063c4:	17c2                	slli	a5,a5,0x30
    800063c6:	93c1                	srli	a5,a5,0x30
    800063c8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063cc:	6898                	ld	a4,16(s1)
    800063ce:	00275703          	lhu	a4,2(a4)
    800063d2:	faf71be3          	bne	a4,a5,80006388 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063d6:	0001f517          	auipc	a0,0x1f
    800063da:	d5250513          	addi	a0,a0,-686 # 80025128 <disk+0x2128>
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	8a6080e7          	jalr	-1882(ra) # 80000c84 <release>
}
    800063e6:	60e2                	ld	ra,24(sp)
    800063e8:	6442                	ld	s0,16(sp)
    800063ea:	64a2                	ld	s1,8(sp)
    800063ec:	6902                	ld	s2,0(sp)
    800063ee:	6105                	addi	sp,sp,32
    800063f0:	8082                	ret
      panic("virtio_disk_intr status");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	40650513          	addi	a0,a0,1030 # 800087f8 <syscalls+0x3b0>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	140080e7          	jalr	320(ra) # 8000053a <panic>
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
