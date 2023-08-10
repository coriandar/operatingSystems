
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	c1e78793          	addi	a5,a5,-994 # 80005c80 <timervec>
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
    8000012e:	458080e7          	jalr	1112(ra) # 80002582 <either_copyin>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	904080e7          	jalr	-1788(ra) # 80001ac4 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	fb8080e7          	jalr	-72(ra) # 80002188 <sleep>
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
    80000210:	320080e7          	jalr	800(ra) # 8000252c <either_copyout>
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
    800002f0:	2ec080e7          	jalr	748(ra) # 800025d8 <procdump>
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
    80000444:	ed4080e7          	jalr	-300(ra) # 80002314 <wakeup>
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
    80000892:	a86080e7          	jalr	-1402(ra) # 80002314 <wakeup>
    
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
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	86e080e7          	jalr	-1938(ra) # 80002188 <sleep>
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
    80000b6e:	f3e080e7          	jalr	-194(ra) # 80001aa8 <mycpu>
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
    80000ba0:	f0c080e7          	jalr	-244(ra) # 80001aa8 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	f00080e7          	jalr	-256(ra) # 80001aa8 <mycpu>
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
    80000bc4:	ee8080e7          	jalr	-280(ra) # 80001aa8 <mycpu>
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
    80000c04:	ea8080e7          	jalr	-344(ra) # 80001aa8 <mycpu>
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
    80000c30:	e7c080e7          	jalr	-388(ra) # 80001aa8 <mycpu>
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
    80000e7e:	c1e080e7          	jalr	-994(ra) # 80001a98 <cpuid>
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
    80000e9a:	c02080e7          	jalr	-1022(ra) # 80001a98 <cpuid>
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
    80000ebc:	862080e7          	jalr	-1950(ra) # 8000271a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	e00080e7          	jalr	-512(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	10e080e7          	jalr	270(ra) # 80001fd6 <scheduler>
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
    80000f2c:	ac0080e7          	jalr	-1344(ra) # 800019e8 <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	7c2080e7          	jalr	1986(ra) # 800026f2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	7e2080e7          	jalr	2018(ra) # 8000271a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d6a080e7          	jalr	-662(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d78080e7          	jalr	-648(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f40080e7          	jalr	-192(ra) # 80002e90 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	5ce080e7          	jalr	1486(ra) # 80003526 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	580080e7          	jalr	1408(ra) # 800044e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e78080e7          	jalr	-392(ra) # 80005de0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	e2c080e7          	jalr	-468(ra) # 80001d9c <userinit>
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
    80001228:	72e080e7          	jalr	1838(ra) # 80001952 <proc_mapstacks>
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

0000000080001824 <proc_print>:
struct spinlock wait_lock;

// No lock to avoid wedging a stuck machine further.
void
proc_print(void)
{
    80001824:	7159                	addi	sp,sp,-112
    80001826:	f486                	sd	ra,104(sp)
    80001828:	f0a2                	sd	s0,96(sp)
    8000182a:	eca6                	sd	s1,88(sp)
    8000182c:	e8ca                	sd	s2,80(sp)
    8000182e:	e4ce                	sd	s3,72(sp)
    80001830:	e0d2                	sd	s4,64(sp)
    80001832:	fc56                	sd	s5,56(sp)
    80001834:	f85a                	sd	s6,48(sp)
    80001836:	f45e                	sd	s7,40(sp)
    80001838:	f062                	sd	s8,32(sp)
    8000183a:	ec66                	sd	s9,24(sp)
    8000183c:	e86a                	sd	s10,16(sp)
    8000183e:	e46e                	sd	s11,8(sp)
    80001840:	1880                	addi	s0,sp,112

  struct proc *p;
  char *state;
  int counter = 0;

  printf("\n");
    80001842:	00007517          	auipc	a0,0x7
    80001846:	88650513          	addi	a0,a0,-1914 # 800080c8 <digits+0x88>
    8000184a:	fffff097          	auipc	ra,0xfffff
    8000184e:	d3a080e7          	jalr	-710(ra) # 80000584 <printf>

  for(p = proc; p < &proc[NPROC]; p++){
    80001852:	00010497          	auipc	s1,0x10
    80001856:	fd648493          	addi	s1,s1,-42 # 80011828 <proc+0x158>
    8000185a:	00016b97          	auipc	s7,0x16
    8000185e:	9ceb8b93          	addi	s7,s7,-1586 # 80017228 <bcache+0x140>
  int counter = 0;
    80001862:	4a01                	li	s4,0
    if(p->state == UNUSED)
    {
      continue;
    }

    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001864:	4d15                	li	s10,5
    else
    {
      state = "???";
    }

    printf("%d ", p->pid);
    80001866:	00007b17          	auipc	s6,0x7
    8000186a:	97ab0b13          	addi	s6,s6,-1670 # 800081e0 <digits+0x1a0>
    printf("%d ", p->pid == 1 ? 0 : p->parent->pid);
    8000186e:	4c85                	li	s9,1
    printf("%s ", state);
    80001870:	00007a97          	auipc	s5,0x7
    80001874:	978a8a93          	addi	s5,s5,-1672 # 800081e8 <digits+0x1a8>
    printf("%s ", p->name);
    printf("%d", p->sz);
    80001878:	00007c17          	auipc	s8,0x7
    8000187c:	978c0c13          	addi	s8,s8,-1672 # 800081f0 <digits+0x1b0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001880:	00007d97          	auipc	s11,0x7
    80001884:	a88d8d93          	addi	s11,s11,-1400 # 80008308 <states.2>
    80001888:	a0ad                	j	800018f2 <proc_print+0xce>
    printf("%d ", p->pid);
    8000188a:	ed892583          	lw	a1,-296(s2) # ed8 <_entry-0x7ffff128>
    8000188e:	855a                	mv	a0,s6
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	cf4080e7          	jalr	-780(ra) # 80000584 <printf>
    printf("%d ", p->pid == 1 ? 0 : p->parent->pid);
    80001898:	ed892783          	lw	a5,-296(s2)
    8000189c:	4581                	li	a1,0
    8000189e:	01978563          	beq	a5,s9,800018a8 <proc_print+0x84>
    800018a2:	ee093783          	ld	a5,-288(s2)
    800018a6:	5b8c                	lw	a1,48(a5)
    800018a8:	855a                	mv	a0,s6
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	cda080e7          	jalr	-806(ra) # 80000584 <printf>
    printf("%s ", state);
    800018b2:	85ce                	mv	a1,s3
    800018b4:	8556                	mv	a0,s5
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	cce080e7          	jalr	-818(ra) # 80000584 <printf>
    printf("%s ", p->name);
    800018be:	85ca                	mv	a1,s2
    800018c0:	8556                	mv	a0,s5
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	cc2080e7          	jalr	-830(ra) # 80000584 <printf>
    printf("%d", p->sz);
    800018ca:	ef093583          	ld	a1,-272(s2)
    800018ce:	8562                	mv	a0,s8
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	cb4080e7          	jalr	-844(ra) # 80000584 <printf>
    printf("\n");
    800018d8:	00006517          	auipc	a0,0x6
    800018dc:	7f050513          	addi	a0,a0,2032 # 800080c8 <digits+0x88>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	ca4080e7          	jalr	-860(ra) # 80000584 <printf>
    counter++;
    800018e8:	2a05                	addiw	s4,s4,1
  for(p = proc; p < &proc[NPROC]; p++){
    800018ea:	16848493          	addi	s1,s1,360
    800018ee:	03748a63          	beq	s1,s7,80001922 <proc_print+0xfe>
    if(p->state == UNUSED)
    800018f2:	8926                	mv	s2,s1
    800018f4:	ec04a783          	lw	a5,-320(s1)
    800018f8:	dbed                	beqz	a5,800018ea <proc_print+0xc6>
      state = "???";
    800018fa:	00007997          	auipc	s3,0x7
    800018fe:	8de98993          	addi	s3,s3,-1826 # 800081d8 <digits+0x198>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001902:	f8fd64e3          	bltu	s10,a5,8000188a <proc_print+0x66>
    80001906:	02079713          	slli	a4,a5,0x20
    8000190a:	01d75793          	srli	a5,a4,0x1d
    8000190e:	97ee                	add	a5,a5,s11
    80001910:	0007b983          	ld	s3,0(a5)
    80001914:	f6099be3          	bnez	s3,8000188a <proc_print+0x66>
      state = "???";
    80001918:	00007997          	auipc	s3,0x7
    8000191c:	8c098993          	addi	s3,s3,-1856 # 800081d8 <digits+0x198>
    80001920:	b7ad                	j	8000188a <proc_print+0x66>
  }
  printf("There are total of %d processes in the system.", counter);
    80001922:	85d2                	mv	a1,s4
    80001924:	00007517          	auipc	a0,0x7
    80001928:	8d450513          	addi	a0,a0,-1836 # 800081f8 <digits+0x1b8>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	c58080e7          	jalr	-936(ra) # 80000584 <printf>
}
    80001934:	70a6                	ld	ra,104(sp)
    80001936:	7406                	ld	s0,96(sp)
    80001938:	64e6                	ld	s1,88(sp)
    8000193a:	6946                	ld	s2,80(sp)
    8000193c:	69a6                	ld	s3,72(sp)
    8000193e:	6a06                	ld	s4,64(sp)
    80001940:	7ae2                	ld	s5,56(sp)
    80001942:	7b42                	ld	s6,48(sp)
    80001944:	7ba2                	ld	s7,40(sp)
    80001946:	7c02                	ld	s8,32(sp)
    80001948:	6ce2                	ld	s9,24(sp)
    8000194a:	6d42                	ld	s10,16(sp)
    8000194c:	6da2                	ld	s11,8(sp)
    8000194e:	6165                	addi	sp,sp,112
    80001950:	8082                	ret

0000000080001952 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001952:	7139                	addi	sp,sp,-64
    80001954:	fc06                	sd	ra,56(sp)
    80001956:	f822                	sd	s0,48(sp)
    80001958:	f426                	sd	s1,40(sp)
    8000195a:	f04a                	sd	s2,32(sp)
    8000195c:	ec4e                	sd	s3,24(sp)
    8000195e:	e852                	sd	s4,16(sp)
    80001960:	e456                	sd	s5,8(sp)
    80001962:	e05a                	sd	s6,0(sp)
    80001964:	0080                	addi	s0,sp,64
    80001966:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	00010497          	auipc	s1,0x10
    8000196c:	d6848493          	addi	s1,s1,-664 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001970:	8b26                	mv	s6,s1
    80001972:	00006a97          	auipc	s5,0x6
    80001976:	68ea8a93          	addi	s5,s5,1678 # 80008000 <etext>
    8000197a:	04000937          	lui	s2,0x4000
    8000197e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001980:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	00015a17          	auipc	s4,0x15
    80001986:	74ea0a13          	addi	s4,s4,1870 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	156080e7          	jalr	342(ra) # 80000ae0 <kalloc>
    80001992:	862a                	mv	a2,a0
    if(pa == 0)
    80001994:	c131                	beqz	a0,800019d8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001996:	416485b3          	sub	a1,s1,s6
    8000199a:	858d                	srai	a1,a1,0x3
    8000199c:	000ab783          	ld	a5,0(s5)
    800019a0:	02f585b3          	mul	a1,a1,a5
    800019a4:	2585                	addiw	a1,a1,1
    800019a6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019aa:	4719                	li	a4,6
    800019ac:	6685                	lui	a3,0x1
    800019ae:	40b905b3          	sub	a1,s2,a1
    800019b2:	854e                	mv	a0,s3
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	780080e7          	jalr	1920(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	16848493          	addi	s1,s1,360
    800019c0:	fd4495e3          	bne	s1,s4,8000198a <proc_mapstacks+0x38>
  }
}
    800019c4:	70e2                	ld	ra,56(sp)
    800019c6:	7442                	ld	s0,48(sp)
    800019c8:	74a2                	ld	s1,40(sp)
    800019ca:	7902                	ld	s2,32(sp)
    800019cc:	69e2                	ld	s3,24(sp)
    800019ce:	6a42                	ld	s4,16(sp)
    800019d0:	6aa2                	ld	s5,8(sp)
    800019d2:	6b02                	ld	s6,0(sp)
    800019d4:	6121                	addi	sp,sp,64
    800019d6:	8082                	ret
      panic("kalloc");
    800019d8:	00007517          	auipc	a0,0x7
    800019dc:	85050513          	addi	a0,a0,-1968 # 80008228 <digits+0x1e8>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	b5a080e7          	jalr	-1190(ra) # 8000053a <panic>

00000000800019e8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019e8:	7139                	addi	sp,sp,-64
    800019ea:	fc06                	sd	ra,56(sp)
    800019ec:	f822                	sd	s0,48(sp)
    800019ee:	f426                	sd	s1,40(sp)
    800019f0:	f04a                	sd	s2,32(sp)
    800019f2:	ec4e                	sd	s3,24(sp)
    800019f4:	e852                	sd	s4,16(sp)
    800019f6:	e456                	sd	s5,8(sp)
    800019f8:	e05a                	sd	s6,0(sp)
    800019fa:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019fc:	00007597          	auipc	a1,0x7
    80001a00:	83458593          	addi	a1,a1,-1996 # 80008230 <digits+0x1f0>
    80001a04:	00010517          	auipc	a0,0x10
    80001a08:	89c50513          	addi	a0,a0,-1892 # 800112a0 <pid_lock>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	134080e7          	jalr	308(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a14:	00007597          	auipc	a1,0x7
    80001a18:	82458593          	addi	a1,a1,-2012 # 80008238 <digits+0x1f8>
    80001a1c:	00010517          	auipc	a0,0x10
    80001a20:	89c50513          	addi	a0,a0,-1892 # 800112b8 <wait_lock>
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	11c080e7          	jalr	284(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2c:	00010497          	auipc	s1,0x10
    80001a30:	ca448493          	addi	s1,s1,-860 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a34:	00007b17          	auipc	s6,0x7
    80001a38:	814b0b13          	addi	s6,s6,-2028 # 80008248 <digits+0x208>
      p->kstack = KSTACK((int) (p - proc));
    80001a3c:	8aa6                	mv	s5,s1
    80001a3e:	00006a17          	auipc	s4,0x6
    80001a42:	5c2a0a13          	addi	s4,s4,1474 # 80008000 <etext>
    80001a46:	04000937          	lui	s2,0x4000
    80001a4a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a4c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4e:	00015997          	auipc	s3,0x15
    80001a52:	68298993          	addi	s3,s3,1666 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a56:	85da                	mv	a1,s6
    80001a58:	8526                	mv	a0,s1
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	0e6080e7          	jalr	230(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a62:	415487b3          	sub	a5,s1,s5
    80001a66:	878d                	srai	a5,a5,0x3
    80001a68:	000a3703          	ld	a4,0(s4)
    80001a6c:	02e787b3          	mul	a5,a5,a4
    80001a70:	2785                	addiw	a5,a5,1
    80001a72:	00d7979b          	slliw	a5,a5,0xd
    80001a76:	40f907b3          	sub	a5,s2,a5
    80001a7a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7c:	16848493          	addi	s1,s1,360
    80001a80:	fd349be3          	bne	s1,s3,80001a56 <procinit+0x6e>
  }
}
    80001a84:	70e2                	ld	ra,56(sp)
    80001a86:	7442                	ld	s0,48(sp)
    80001a88:	74a2                	ld	s1,40(sp)
    80001a8a:	7902                	ld	s2,32(sp)
    80001a8c:	69e2                	ld	s3,24(sp)
    80001a8e:	6a42                	ld	s4,16(sp)
    80001a90:	6aa2                	ld	s5,8(sp)
    80001a92:	6b02                	ld	s6,0(sp)
    80001a94:	6121                	addi	sp,sp,64
    80001a96:	8082                	ret

0000000080001a98 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a98:	1141                	addi	sp,sp,-16
    80001a9a:	e422                	sd	s0,8(sp)
    80001a9c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a9e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001aa0:	2501                	sext.w	a0,a0
    80001aa2:	6422                	ld	s0,8(sp)
    80001aa4:	0141                	addi	sp,sp,16
    80001aa6:	8082                	ret

0000000080001aa8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
    80001aae:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ab0:	2781                	sext.w	a5,a5
    80001ab2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ab4:	00010517          	auipc	a0,0x10
    80001ab8:	81c50513          	addi	a0,a0,-2020 # 800112d0 <cpus>
    80001abc:	953e                	add	a0,a0,a5
    80001abe:	6422                	ld	s0,8(sp)
    80001ac0:	0141                	addi	sp,sp,16
    80001ac2:	8082                	ret

0000000080001ac4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ac4:	1101                	addi	sp,sp,-32
    80001ac6:	ec06                	sd	ra,24(sp)
    80001ac8:	e822                	sd	s0,16(sp)
    80001aca:	e426                	sd	s1,8(sp)
    80001acc:	1000                	addi	s0,sp,32
  push_off();
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	0b6080e7          	jalr	182(ra) # 80000b84 <push_off>
    80001ad6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ad8:	2781                	sext.w	a5,a5
    80001ada:	079e                	slli	a5,a5,0x7
    80001adc:	0000f717          	auipc	a4,0xf
    80001ae0:	7c470713          	addi	a4,a4,1988 # 800112a0 <pid_lock>
    80001ae4:	97ba                	add	a5,a5,a4
    80001ae6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	13c080e7          	jalr	316(ra) # 80000c24 <pop_off>
  return p;
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001afc:	1141                	addi	sp,sp,-16
    80001afe:	e406                	sd	ra,8(sp)
    80001b00:	e022                	sd	s0,0(sp)
    80001b02:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	fc0080e7          	jalr	-64(ra) # 80001ac4 <myproc>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if (first) {
    80001b14:	00007797          	auipc	a5,0x7
    80001b18:	d8c7a783          	lw	a5,-628(a5) # 800088a0 <first.1>
    80001b1c:	eb89                	bnez	a5,80001b2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b1e:	00001097          	auipc	ra,0x1
    80001b22:	c14080e7          	jalr	-1004(ra) # 80002732 <usertrapret>
}
    80001b26:	60a2                	ld	ra,8(sp)
    80001b28:	6402                	ld	s0,0(sp)
    80001b2a:	0141                	addi	sp,sp,16
    80001b2c:	8082                	ret
    first = 0;
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	d607a923          	sw	zero,-654(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001b36:	4505                	li	a0,1
    80001b38:	00002097          	auipc	ra,0x2
    80001b3c:	96e080e7          	jalr	-1682(ra) # 800034a6 <fsinit>
    80001b40:	bff9                	j	80001b1e <forkret+0x22>

0000000080001b42 <allocpid>:
allocpid() {
    80001b42:	1101                	addi	sp,sp,-32
    80001b44:	ec06                	sd	ra,24(sp)
    80001b46:	e822                	sd	s0,16(sp)
    80001b48:	e426                	sd	s1,8(sp)
    80001b4a:	e04a                	sd	s2,0(sp)
    80001b4c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b4e:	0000f917          	auipc	s2,0xf
    80001b52:	75290913          	addi	s2,s2,1874 # 800112a0 <pid_lock>
    80001b56:	854a                	mv	a0,s2
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	078080e7          	jalr	120(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001b60:	00007797          	auipc	a5,0x7
    80001b64:	d4478793          	addi	a5,a5,-700 # 800088a4 <nextpid>
    80001b68:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b6a:	0014871b          	addiw	a4,s1,1
    80001b6e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b70:	854a                	mv	a0,s2
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	112080e7          	jalr	274(ra) # 80000c84 <release>
}
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	60e2                	ld	ra,24(sp)
    80001b7e:	6442                	ld	s0,16(sp)
    80001b80:	64a2                	ld	s1,8(sp)
    80001b82:	6902                	ld	s2,0(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <proc_pagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	788080e7          	jalr	1928(ra) # 8000131e <uvmcreate>
    80001b9e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ba0:	c121                	beqz	a0,80001be0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ba2:	4729                	li	a4,10
    80001ba4:	00005697          	auipc	a3,0x5
    80001ba8:	45c68693          	addi	a3,a3,1116 # 80007000 <_trampoline>
    80001bac:	6605                	lui	a2,0x1
    80001bae:	040005b7          	lui	a1,0x4000
    80001bb2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bb4:	05b2                	slli	a1,a1,0xc
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	4de080e7          	jalr	1246(ra) # 80001094 <mappages>
    80001bbe:	02054863          	bltz	a0,80001bee <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bc2:	4719                	li	a4,6
    80001bc4:	05893683          	ld	a3,88(s2)
    80001bc8:	6605                	lui	a2,0x1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd0:	05b6                	slli	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	4c0080e7          	jalr	1216(ra) # 80001094 <mappages>
    80001bdc:	02054163          	bltz	a0,80001bfe <proc_pagetable+0x76>
}
    80001be0:	8526                	mv	a0,s1
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6902                	ld	s2,0(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret
    uvmfree(pagetable, 0);
    80001bee:	4581                	li	a1,0
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	92a080e7          	jalr	-1750(ra) # 8000151c <uvmfree>
    return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	b7d5                	j	80001be0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfe:	4681                	li	a3,0
    80001c00:	4605                	li	a2,1
    80001c02:	040005b7          	lui	a1,0x4000
    80001c06:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c08:	05b2                	slli	a1,a1,0xc
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	64e080e7          	jalr	1614(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c14:	4581                	li	a1,0
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	904080e7          	jalr	-1788(ra) # 8000151c <uvmfree>
    return 0;
    80001c20:	4481                	li	s1,0
    80001c22:	bf7d                	j	80001be0 <proc_pagetable+0x58>

0000000080001c24 <proc_freepagetable>:
{
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	e04a                	sd	s2,0(sp)
    80001c2e:	1000                	addi	s0,sp,32
    80001c30:	84aa                	mv	s1,a0
    80001c32:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c34:	4681                	li	a3,0
    80001c36:	4605                	li	a2,1
    80001c38:	040005b7          	lui	a1,0x4000
    80001c3c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c3e:	05b2                	slli	a1,a1,0xc
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	61a080e7          	jalr	1562(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c48:	4681                	li	a3,0
    80001c4a:	4605                	li	a2,1
    80001c4c:	020005b7          	lui	a1,0x2000
    80001c50:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c52:	05b6                	slli	a1,a1,0xd
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	604080e7          	jalr	1540(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001c5e:	85ca                	mv	a1,s2
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	8ba080e7          	jalr	-1862(ra) # 8000151c <uvmfree>
}
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret

0000000080001c76 <freeproc>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	1000                	addi	s0,sp,32
    80001c80:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c82:	6d28                	ld	a0,88(a0)
    80001c84:	c509                	beqz	a0,80001c8e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	d5c080e7          	jalr	-676(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001c8e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c92:	68a8                	ld	a0,80(s1)
    80001c94:	c511                	beqz	a0,80001ca0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c96:	64ac                	ld	a1,72(s1)
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	f8c080e7          	jalr	-116(ra) # 80001c24 <proc_freepagetable>
  p->pagetable = 0;
    80001ca0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ca4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cac:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cb0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cb4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cb8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cbc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cc0:	0004ac23          	sw	zero,24(s1)
}
    80001cc4:	60e2                	ld	ra,24(sp)
    80001cc6:	6442                	ld	s0,16(sp)
    80001cc8:	64a2                	ld	s1,8(sp)
    80001cca:	6105                	addi	sp,sp,32
    80001ccc:	8082                	ret

0000000080001cce <allocproc>:
{
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	e04a                	sd	s2,0(sp)
    80001cd8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	00010497          	auipc	s1,0x10
    80001cde:	9f648493          	addi	s1,s1,-1546 # 800116d0 <proc>
    80001ce2:	00015917          	auipc	s2,0x15
    80001ce6:	3ee90913          	addi	s2,s2,1006 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	ee4080e7          	jalr	-284(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001cf4:	4c9c                	lw	a5,24(s1)
    80001cf6:	cf81                	beqz	a5,80001d0e <allocproc+0x40>
      release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	f8a080e7          	jalr	-118(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d02:	16848493          	addi	s1,s1,360
    80001d06:	ff2492e3          	bne	s1,s2,80001cea <allocproc+0x1c>
  return 0;
    80001d0a:	4481                	li	s1,0
    80001d0c:	a889                	j	80001d5e <allocproc+0x90>
  p->pid = allocpid();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	e34080e7          	jalr	-460(ra) # 80001b42 <allocpid>
    80001d16:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d18:	4785                	li	a5,1
    80001d1a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	dc4080e7          	jalr	-572(ra) # 80000ae0 <kalloc>
    80001d24:	892a                	mv	s2,a0
    80001d26:	eca8                	sd	a0,88(s1)
    80001d28:	c131                	beqz	a0,80001d6c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	e5c080e7          	jalr	-420(ra) # 80001b88 <proc_pagetable>
    80001d34:	892a                	mv	s2,a0
    80001d36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d38:	c531                	beqz	a0,80001d84 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d3a:	07000613          	li	a2,112
    80001d3e:	4581                	li	a1,0
    80001d40:	06048513          	addi	a0,s1,96
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f88080e7          	jalr	-120(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001d4c:	00000797          	auipc	a5,0x0
    80001d50:	db078793          	addi	a5,a5,-592 # 80001afc <forkret>
    80001d54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d56:	60bc                	ld	a5,64(s1)
    80001d58:	6705                	lui	a4,0x1
    80001d5a:	97ba                	add	a5,a5,a4
    80001d5c:	f4bc                	sd	a5,104(s1)
}
    80001d5e:	8526                	mv	a0,s1
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6902                	ld	s2,0(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	f08080e7          	jalr	-248(ra) # 80001c76 <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	f0c080e7          	jalr	-244(ra) # 80000c84 <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	bff1                	j	80001d5e <allocproc+0x90>
    freeproc(p);
    80001d84:	8526                	mv	a0,s1
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ef0080e7          	jalr	-272(ra) # 80001c76 <freeproc>
    release(&p->lock);
    80001d8e:	8526                	mv	a0,s1
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	ef4080e7          	jalr	-268(ra) # 80000c84 <release>
    return 0;
    80001d98:	84ca                	mv	s1,s2
    80001d9a:	b7d1                	j	80001d5e <allocproc+0x90>

0000000080001d9c <userinit>:
{
    80001d9c:	1101                	addi	sp,sp,-32
    80001d9e:	ec06                	sd	ra,24(sp)
    80001da0:	e822                	sd	s0,16(sp)
    80001da2:	e426                	sd	s1,8(sp)
    80001da4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	f28080e7          	jalr	-216(ra) # 80001cce <allocproc>
    80001dae:	84aa                	mv	s1,a0
  initproc = p;
    80001db0:	00007797          	auipc	a5,0x7
    80001db4:	26a7bc23          	sd	a0,632(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001db8:	03400613          	li	a2,52
    80001dbc:	00007597          	auipc	a1,0x7
    80001dc0:	af458593          	addi	a1,a1,-1292 # 800088b0 <initcode>
    80001dc4:	6928                	ld	a0,80(a0)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	586080e7          	jalr	1414(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001dce:	6785                	lui	a5,0x1
    80001dd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dd2:	6cb8                	ld	a4,88(s1)
    80001dd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dd8:	6cb8                	ld	a4,88(s1)
    80001dda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ddc:	4641                	li	a2,16
    80001dde:	00006597          	auipc	a1,0x6
    80001de2:	47258593          	addi	a1,a1,1138 # 80008250 <digits+0x210>
    80001de6:	15848513          	addi	a0,s1,344
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	02c080e7          	jalr	44(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001df2:	00006517          	auipc	a0,0x6
    80001df6:	46e50513          	addi	a0,a0,1134 # 80008260 <digits+0x220>
    80001dfa:	00002097          	auipc	ra,0x2
    80001dfe:	0e2080e7          	jalr	226(ra) # 80003edc <namei>
    80001e02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e06:	478d                	li	a5,3
    80001e08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	e78080e7          	jalr	-392(ra) # 80000c84 <release>
}
    80001e14:	60e2                	ld	ra,24(sp)
    80001e16:	6442                	ld	s0,16(sp)
    80001e18:	64a2                	ld	s1,8(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret

0000000080001e1e <growproc>:
{
    80001e1e:	1101                	addi	sp,sp,-32
    80001e20:	ec06                	sd	ra,24(sp)
    80001e22:	e822                	sd	s0,16(sp)
    80001e24:	e426                	sd	s1,8(sp)
    80001e26:	e04a                	sd	s2,0(sp)
    80001e28:	1000                	addi	s0,sp,32
    80001e2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	c98080e7          	jalr	-872(ra) # 80001ac4 <myproc>
    80001e34:	892a                	mv	s2,a0
  sz = p->sz;
    80001e36:	652c                	ld	a1,72(a0)
    80001e38:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001e3c:	00904f63          	bgtz	s1,80001e5a <growproc+0x3c>
  } else if(n < 0){
    80001e40:	0204cd63          	bltz	s1,80001e7a <growproc+0x5c>
  p->sz = sz;
    80001e44:	1782                	slli	a5,a5,0x20
    80001e46:	9381                	srli	a5,a5,0x20
    80001e48:	04f93423          	sd	a5,72(s2)
  return 0;
    80001e4c:	4501                	li	a0,0
}
    80001e4e:	60e2                	ld	ra,24(sp)
    80001e50:	6442                	ld	s0,16(sp)
    80001e52:	64a2                	ld	s1,8(sp)
    80001e54:	6902                	ld	s2,0(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e5a:	00f4863b          	addw	a2,s1,a5
    80001e5e:	1602                	slli	a2,a2,0x20
    80001e60:	9201                	srli	a2,a2,0x20
    80001e62:	1582                	slli	a1,a1,0x20
    80001e64:	9181                	srli	a1,a1,0x20
    80001e66:	6928                	ld	a0,80(a0)
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	59e080e7          	jalr	1438(ra) # 80001406 <uvmalloc>
    80001e70:	0005079b          	sext.w	a5,a0
    80001e74:	fbe1                	bnez	a5,80001e44 <growproc+0x26>
      return -1;
    80001e76:	557d                	li	a0,-1
    80001e78:	bfd9                	j	80001e4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e7a:	00f4863b          	addw	a2,s1,a5
    80001e7e:	1602                	slli	a2,a2,0x20
    80001e80:	9201                	srli	a2,a2,0x20
    80001e82:	1582                	slli	a1,a1,0x20
    80001e84:	9181                	srli	a1,a1,0x20
    80001e86:	6928                	ld	a0,80(a0)
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	536080e7          	jalr	1334(ra) # 800013be <uvmdealloc>
    80001e90:	0005079b          	sext.w	a5,a0
    80001e94:	bf45                	j	80001e44 <growproc+0x26>

0000000080001e96 <fork>:
{
    80001e96:	7139                	addi	sp,sp,-64
    80001e98:	fc06                	sd	ra,56(sp)
    80001e9a:	f822                	sd	s0,48(sp)
    80001e9c:	f426                	sd	s1,40(sp)
    80001e9e:	f04a                	sd	s2,32(sp)
    80001ea0:	ec4e                	sd	s3,24(sp)
    80001ea2:	e852                	sd	s4,16(sp)
    80001ea4:	e456                	sd	s5,8(sp)
    80001ea6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	c1c080e7          	jalr	-996(ra) # 80001ac4 <myproc>
    80001eb0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	e1c080e7          	jalr	-484(ra) # 80001cce <allocproc>
    80001eba:	10050c63          	beqz	a0,80001fd2 <fork+0x13c>
    80001ebe:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ec0:	048ab603          	ld	a2,72(s5)
    80001ec4:	692c                	ld	a1,80(a0)
    80001ec6:	050ab503          	ld	a0,80(s5)
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	68c080e7          	jalr	1676(ra) # 80001556 <uvmcopy>
    80001ed2:	04054863          	bltz	a0,80001f22 <fork+0x8c>
  np->sz = p->sz;
    80001ed6:	048ab783          	ld	a5,72(s5)
    80001eda:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ede:	058ab683          	ld	a3,88(s5)
    80001ee2:	87b6                	mv	a5,a3
    80001ee4:	058a3703          	ld	a4,88(s4)
    80001ee8:	12068693          	addi	a3,a3,288
    80001eec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef0:	6788                	ld	a0,8(a5)
    80001ef2:	6b8c                	ld	a1,16(a5)
    80001ef4:	6f90                	ld	a2,24(a5)
    80001ef6:	01073023          	sd	a6,0(a4)
    80001efa:	e708                	sd	a0,8(a4)
    80001efc:	eb0c                	sd	a1,16(a4)
    80001efe:	ef10                	sd	a2,24(a4)
    80001f00:	02078793          	addi	a5,a5,32
    80001f04:	02070713          	addi	a4,a4,32
    80001f08:	fed792e3          	bne	a5,a3,80001eec <fork+0x56>
  np->trapframe->a0 = 0;
    80001f0c:	058a3783          	ld	a5,88(s4)
    80001f10:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f14:	0d0a8493          	addi	s1,s5,208
    80001f18:	0d0a0913          	addi	s2,s4,208
    80001f1c:	150a8993          	addi	s3,s5,336
    80001f20:	a00d                	j	80001f42 <fork+0xac>
    freeproc(np);
    80001f22:	8552                	mv	a0,s4
    80001f24:	00000097          	auipc	ra,0x0
    80001f28:	d52080e7          	jalr	-686(ra) # 80001c76 <freeproc>
    release(&np->lock);
    80001f2c:	8552                	mv	a0,s4
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d56080e7          	jalr	-682(ra) # 80000c84 <release>
    return -1;
    80001f36:	597d                	li	s2,-1
    80001f38:	a059                	j	80001fbe <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f3a:	04a1                	addi	s1,s1,8
    80001f3c:	0921                	addi	s2,s2,8
    80001f3e:	01348b63          	beq	s1,s3,80001f54 <fork+0xbe>
    if(p->ofile[i])
    80001f42:	6088                	ld	a0,0(s1)
    80001f44:	d97d                	beqz	a0,80001f3a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f46:	00002097          	auipc	ra,0x2
    80001f4a:	62c080e7          	jalr	1580(ra) # 80004572 <filedup>
    80001f4e:	00a93023          	sd	a0,0(s2)
    80001f52:	b7e5                	j	80001f3a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f54:	150ab503          	ld	a0,336(s5)
    80001f58:	00001097          	auipc	ra,0x1
    80001f5c:	78a080e7          	jalr	1930(ra) # 800036e2 <idup>
    80001f60:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	158a8593          	addi	a1,s5,344
    80001f6a:	158a0513          	addi	a0,s4,344
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	ea8080e7          	jalr	-344(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f76:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f7a:	8552                	mv	a0,s4
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	d08080e7          	jalr	-760(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001f84:	0000f497          	auipc	s1,0xf
    80001f88:	33448493          	addi	s1,s1,820 # 800112b8 <wait_lock>
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	c42080e7          	jalr	-958(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001f96:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	ce8080e7          	jalr	-792(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001fa4:	8552                	mv	a0,s4
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c2a080e7          	jalr	-982(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fb4:	8552                	mv	a0,s4
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	cce080e7          	jalr	-818(ra) # 80000c84 <release>
}
    80001fbe:	854a                	mv	a0,s2
    80001fc0:	70e2                	ld	ra,56(sp)
    80001fc2:	7442                	ld	s0,48(sp)
    80001fc4:	74a2                	ld	s1,40(sp)
    80001fc6:	7902                	ld	s2,32(sp)
    80001fc8:	69e2                	ld	s3,24(sp)
    80001fca:	6a42                	ld	s4,16(sp)
    80001fcc:	6aa2                	ld	s5,8(sp)
    80001fce:	6121                	addi	sp,sp,64
    80001fd0:	8082                	ret
    return -1;
    80001fd2:	597d                	li	s2,-1
    80001fd4:	b7ed                	j	80001fbe <fork+0x128>

0000000080001fd6 <scheduler>:
{
    80001fd6:	7139                	addi	sp,sp,-64
    80001fd8:	fc06                	sd	ra,56(sp)
    80001fda:	f822                	sd	s0,48(sp)
    80001fdc:	f426                	sd	s1,40(sp)
    80001fde:	f04a                	sd	s2,32(sp)
    80001fe0:	ec4e                	sd	s3,24(sp)
    80001fe2:	e852                	sd	s4,16(sp)
    80001fe4:	e456                	sd	s5,8(sp)
    80001fe6:	e05a                	sd	s6,0(sp)
    80001fe8:	0080                	addi	s0,sp,64
    80001fea:	8792                	mv	a5,tp
  int id = r_tp();
    80001fec:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fee:	00779a93          	slli	s5,a5,0x7
    80001ff2:	0000f717          	auipc	a4,0xf
    80001ff6:	2ae70713          	addi	a4,a4,686 # 800112a0 <pid_lock>
    80001ffa:	9756                	add	a4,a4,s5
    80001ffc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002000:	0000f717          	auipc	a4,0xf
    80002004:	2d870713          	addi	a4,a4,728 # 800112d8 <cpus+0x8>
    80002008:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000200a:	498d                	li	s3,3
        p->state = RUNNING;
    8000200c:	4b11                	li	s6,4
        c->proc = p;
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000fa17          	auipc	s4,0xf
    80002014:	290a0a13          	addi	s4,s4,656 # 800112a0 <pid_lock>
    80002018:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201a:	00015917          	auipc	s2,0x15
    8000201e:	0b690913          	addi	s2,s2,182 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002022:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002026:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000202a:	10079073          	csrw	sstatus,a5
    8000202e:	0000f497          	auipc	s1,0xf
    80002032:	6a248493          	addi	s1,s1,1698 # 800116d0 <proc>
    80002036:	a811                	j	8000204a <scheduler+0x74>
      release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c4a080e7          	jalr	-950(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002042:	16848493          	addi	s1,s1,360
    80002046:	fd248ee3          	beq	s1,s2,80002022 <scheduler+0x4c>
      acquire(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b84080e7          	jalr	-1148(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80002054:	4c9c                	lw	a5,24(s1)
    80002056:	ff3791e3          	bne	a5,s3,80002038 <scheduler+0x62>
        p->state = RUNNING;
    8000205a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000205e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002062:	06048593          	addi	a1,s1,96
    80002066:	8556                	mv	a0,s5
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	620080e7          	jalr	1568(ra) # 80002688 <swtch>
        c->proc = 0;
    80002070:	020a3823          	sd	zero,48(s4)
    80002074:	b7d1                	j	80002038 <scheduler+0x62>

0000000080002076 <sched>:
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	a40080e7          	jalr	-1472(ra) # 80001ac4 <myproc>
    8000208c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	ac8080e7          	jalr	-1336(ra) # 80000b56 <holding>
    80002096:	c93d                	beqz	a0,8000210c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002098:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	0000f717          	auipc	a4,0xf
    800020a2:	20270713          	addi	a4,a4,514 # 800112a0 <pid_lock>
    800020a6:	97ba                	add	a5,a5,a4
    800020a8:	0a87a703          	lw	a4,168(a5)
    800020ac:	4785                	li	a5,1
    800020ae:	06f71763          	bne	a4,a5,8000211c <sched+0xa6>
  if(p->state == RUNNING)
    800020b2:	4c98                	lw	a4,24(s1)
    800020b4:	4791                	li	a5,4
    800020b6:	06f70b63          	beq	a4,a5,8000212c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020be:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020c0:	efb5                	bnez	a5,8000213c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020c2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020c4:	0000f917          	auipc	s2,0xf
    800020c8:	1dc90913          	addi	s2,s2,476 # 800112a0 <pid_lock>
    800020cc:	2781                	sext.w	a5,a5
    800020ce:	079e                	slli	a5,a5,0x7
    800020d0:	97ca                	add	a5,a5,s2
    800020d2:	0ac7a983          	lw	s3,172(a5)
    800020d6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d8:	2781                	sext.w	a5,a5
    800020da:	079e                	slli	a5,a5,0x7
    800020dc:	0000f597          	auipc	a1,0xf
    800020e0:	1fc58593          	addi	a1,a1,508 # 800112d8 <cpus+0x8>
    800020e4:	95be                	add	a1,a1,a5
    800020e6:	06048513          	addi	a0,s1,96
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	59e080e7          	jalr	1438(ra) # 80002688 <swtch>
    800020f2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	993e                	add	s2,s2,a5
    800020fa:	0b392623          	sw	s3,172(s2)
}
    800020fe:	70a2                	ld	ra,40(sp)
    80002100:	7402                	ld	s0,32(sp)
    80002102:	64e2                	ld	s1,24(sp)
    80002104:	6942                	ld	s2,16(sp)
    80002106:	69a2                	ld	s3,8(sp)
    80002108:	6145                	addi	sp,sp,48
    8000210a:	8082                	ret
    panic("sched p->lock");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	15c50513          	addi	a0,a0,348 # 80008268 <digits+0x228>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	426080e7          	jalr	1062(ra) # 8000053a <panic>
    panic("sched locks");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	15c50513          	addi	a0,a0,348 # 80008278 <digits+0x238>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	416080e7          	jalr	1046(ra) # 8000053a <panic>
    panic("sched running");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	15c50513          	addi	a0,a0,348 # 80008288 <digits+0x248>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	406080e7          	jalr	1030(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000213c:	00006517          	auipc	a0,0x6
    80002140:	15c50513          	addi	a0,a0,348 # 80008298 <digits+0x258>
    80002144:	ffffe097          	auipc	ra,0xffffe
    80002148:	3f6080e7          	jalr	1014(ra) # 8000053a <panic>

000000008000214c <yield>:
{
    8000214c:	1101                	addi	sp,sp,-32
    8000214e:	ec06                	sd	ra,24(sp)
    80002150:	e822                	sd	s0,16(sp)
    80002152:	e426                	sd	s1,8(sp)
    80002154:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	96e080e7          	jalr	-1682(ra) # 80001ac4 <myproc>
    8000215e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	a70080e7          	jalr	-1424(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002168:	478d                	li	a5,3
    8000216a:	cc9c                	sw	a5,24(s1)
  sched();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	f0a080e7          	jalr	-246(ra) # 80002076 <sched>
  release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b0e080e7          	jalr	-1266(ra) # 80000c84 <release>
}
    8000217e:	60e2                	ld	ra,24(sp)
    80002180:	6442                	ld	s0,16(sp)
    80002182:	64a2                	ld	s1,8(sp)
    80002184:	6105                	addi	sp,sp,32
    80002186:	8082                	ret

0000000080002188 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	1800                	addi	s0,sp,48
    80002196:	89aa                	mv	s3,a0
    80002198:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	92a080e7          	jalr	-1750(ra) # 80001ac4 <myproc>
    800021a2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a2c080e7          	jalr	-1492(ra) # 80000bd0 <acquire>
  release(lk);
    800021ac:	854a                	mv	a0,s2
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	ad6080e7          	jalr	-1322(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    800021b6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021ba:	4789                	li	a5,2
    800021bc:	cc9c                	sw	a5,24(s1)

  sched();
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	eb8080e7          	jalr	-328(ra) # 80002076 <sched>

  // Tidy up.
  p->chan = 0;
    800021c6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	ab8080e7          	jalr	-1352(ra) # 80000c84 <release>
  acquire(lk);
    800021d4:	854a                	mv	a0,s2
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	9fa080e7          	jalr	-1542(ra) # 80000bd0 <acquire>
}
    800021de:	70a2                	ld	ra,40(sp)
    800021e0:	7402                	ld	s0,32(sp)
    800021e2:	64e2                	ld	s1,24(sp)
    800021e4:	6942                	ld	s2,16(sp)
    800021e6:	69a2                	ld	s3,8(sp)
    800021e8:	6145                	addi	sp,sp,48
    800021ea:	8082                	ret

00000000800021ec <wait>:
{
    800021ec:	715d                	addi	sp,sp,-80
    800021ee:	e486                	sd	ra,72(sp)
    800021f0:	e0a2                	sd	s0,64(sp)
    800021f2:	fc26                	sd	s1,56(sp)
    800021f4:	f84a                	sd	s2,48(sp)
    800021f6:	f44e                	sd	s3,40(sp)
    800021f8:	f052                	sd	s4,32(sp)
    800021fa:	ec56                	sd	s5,24(sp)
    800021fc:	e85a                	sd	s6,16(sp)
    800021fe:	e45e                	sd	s7,8(sp)
    80002200:	e062                	sd	s8,0(sp)
    80002202:	0880                	addi	s0,sp,80
    80002204:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	8be080e7          	jalr	-1858(ra) # 80001ac4 <myproc>
    8000220e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002210:	0000f517          	auipc	a0,0xf
    80002214:	0a850513          	addi	a0,a0,168 # 800112b8 <wait_lock>
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9b8080e7          	jalr	-1608(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002220:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002222:	4a15                	li	s4,5
        havekids = 1;
    80002224:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002226:	00015997          	auipc	s3,0x15
    8000222a:	eaa98993          	addi	s3,s3,-342 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222e:	0000fc17          	auipc	s8,0xf
    80002232:	08ac0c13          	addi	s8,s8,138 # 800112b8 <wait_lock>
    havekids = 0;
    80002236:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002238:	0000f497          	auipc	s1,0xf
    8000223c:	49848493          	addi	s1,s1,1176 # 800116d0 <proc>
    80002240:	a0bd                	j	800022ae <wait+0xc2>
          pid = np->pid;
    80002242:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002246:	000b0e63          	beqz	s6,80002262 <wait+0x76>
    8000224a:	4691                	li	a3,4
    8000224c:	02c48613          	addi	a2,s1,44
    80002250:	85da                	mv	a1,s6
    80002252:	05093503          	ld	a0,80(s2)
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	404080e7          	jalr	1028(ra) # 8000165a <copyout>
    8000225e:	02054563          	bltz	a0,80002288 <wait+0x9c>
          freeproc(np);
    80002262:	8526                	mv	a0,s1
    80002264:	00000097          	auipc	ra,0x0
    80002268:	a12080e7          	jalr	-1518(ra) # 80001c76 <freeproc>
          release(&np->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a16080e7          	jalr	-1514(ra) # 80000c84 <release>
          release(&wait_lock);
    80002276:	0000f517          	auipc	a0,0xf
    8000227a:	04250513          	addi	a0,a0,66 # 800112b8 <wait_lock>
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a06080e7          	jalr	-1530(ra) # 80000c84 <release>
          return pid;
    80002286:	a09d                	j	800022ec <wait+0x100>
            release(&np->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9fa080e7          	jalr	-1542(ra) # 80000c84 <release>
            release(&wait_lock);
    80002292:	0000f517          	auipc	a0,0xf
    80002296:	02650513          	addi	a0,a0,38 # 800112b8 <wait_lock>
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9ea080e7          	jalr	-1558(ra) # 80000c84 <release>
            return -1;
    800022a2:	59fd                	li	s3,-1
    800022a4:	a0a1                	j	800022ec <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800022a6:	16848493          	addi	s1,s1,360
    800022aa:	03348463          	beq	s1,s3,800022d2 <wait+0xe6>
      if(np->parent == p){
    800022ae:	7c9c                	ld	a5,56(s1)
    800022b0:	ff279be3          	bne	a5,s2,800022a6 <wait+0xba>
        acquire(&np->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	91a080e7          	jalr	-1766(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    800022be:	4c9c                	lw	a5,24(s1)
    800022c0:	f94781e3          	beq	a5,s4,80002242 <wait+0x56>
        release(&np->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9be080e7          	jalr	-1602(ra) # 80000c84 <release>
        havekids = 1;
    800022ce:	8756                	mv	a4,s5
    800022d0:	bfd9                	j	800022a6 <wait+0xba>
    if(!havekids || p->killed){
    800022d2:	c701                	beqz	a4,800022da <wait+0xee>
    800022d4:	02892783          	lw	a5,40(s2)
    800022d8:	c79d                	beqz	a5,80002306 <wait+0x11a>
      release(&wait_lock);
    800022da:	0000f517          	auipc	a0,0xf
    800022de:	fde50513          	addi	a0,a0,-34 # 800112b8 <wait_lock>
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a2080e7          	jalr	-1630(ra) # 80000c84 <release>
      return -1;
    800022ea:	59fd                	li	s3,-1
}
    800022ec:	854e                	mv	a0,s3
    800022ee:	60a6                	ld	ra,72(sp)
    800022f0:	6406                	ld	s0,64(sp)
    800022f2:	74e2                	ld	s1,56(sp)
    800022f4:	7942                	ld	s2,48(sp)
    800022f6:	79a2                	ld	s3,40(sp)
    800022f8:	7a02                	ld	s4,32(sp)
    800022fa:	6ae2                	ld	s5,24(sp)
    800022fc:	6b42                	ld	s6,16(sp)
    800022fe:	6ba2                	ld	s7,8(sp)
    80002300:	6c02                	ld	s8,0(sp)
    80002302:	6161                	addi	sp,sp,80
    80002304:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002306:	85e2                	mv	a1,s8
    80002308:	854a                	mv	a0,s2
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	e7e080e7          	jalr	-386(ra) # 80002188 <sleep>
    havekids = 0;
    80002312:	b715                	j	80002236 <wait+0x4a>

0000000080002314 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002314:	7139                	addi	sp,sp,-64
    80002316:	fc06                	sd	ra,56(sp)
    80002318:	f822                	sd	s0,48(sp)
    8000231a:	f426                	sd	s1,40(sp)
    8000231c:	f04a                	sd	s2,32(sp)
    8000231e:	ec4e                	sd	s3,24(sp)
    80002320:	e852                	sd	s4,16(sp)
    80002322:	e456                	sd	s5,8(sp)
    80002324:	0080                	addi	s0,sp,64
    80002326:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002328:	0000f497          	auipc	s1,0xf
    8000232c:	3a848493          	addi	s1,s1,936 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002330:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002332:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002334:	00015917          	auipc	s2,0x15
    80002338:	d9c90913          	addi	s2,s2,-612 # 800170d0 <tickslock>
    8000233c:	a811                	j	80002350 <wakeup+0x3c>
      }
      release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	944080e7          	jalr	-1724(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002348:	16848493          	addi	s1,s1,360
    8000234c:	03248663          	beq	s1,s2,80002378 <wakeup+0x64>
    if(p != myproc()){
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	774080e7          	jalr	1908(ra) # 80001ac4 <myproc>
    80002358:	fea488e3          	beq	s1,a0,80002348 <wakeup+0x34>
      acquire(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	872080e7          	jalr	-1934(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002366:	4c9c                	lw	a5,24(s1)
    80002368:	fd379be3          	bne	a5,s3,8000233e <wakeup+0x2a>
    8000236c:	709c                	ld	a5,32(s1)
    8000236e:	fd4798e3          	bne	a5,s4,8000233e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002372:	0154ac23          	sw	s5,24(s1)
    80002376:	b7e1                	j	8000233e <wakeup+0x2a>
    }
  }
}
    80002378:	70e2                	ld	ra,56(sp)
    8000237a:	7442                	ld	s0,48(sp)
    8000237c:	74a2                	ld	s1,40(sp)
    8000237e:	7902                	ld	s2,32(sp)
    80002380:	69e2                	ld	s3,24(sp)
    80002382:	6a42                	ld	s4,16(sp)
    80002384:	6aa2                	ld	s5,8(sp)
    80002386:	6121                	addi	sp,sp,64
    80002388:	8082                	ret

000000008000238a <reparent>:
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	e052                	sd	s4,0(sp)
    80002398:	1800                	addi	s0,sp,48
    8000239a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	33448493          	addi	s1,s1,820 # 800116d0 <proc>
      pp->parent = initproc;
    800023a4:	00007a17          	auipc	s4,0x7
    800023a8:	c84a0a13          	addi	s4,s4,-892 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ac:	00015997          	auipc	s3,0x15
    800023b0:	d2498993          	addi	s3,s3,-732 # 800170d0 <tickslock>
    800023b4:	a029                	j	800023be <reparent+0x34>
    800023b6:	16848493          	addi	s1,s1,360
    800023ba:	01348d63          	beq	s1,s3,800023d4 <reparent+0x4a>
    if(pp->parent == p){
    800023be:	7c9c                	ld	a5,56(s1)
    800023c0:	ff279be3          	bne	a5,s2,800023b6 <reparent+0x2c>
      pp->parent = initproc;
    800023c4:	000a3503          	ld	a0,0(s4)
    800023c8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	f4a080e7          	jalr	-182(ra) # 80002314 <wakeup>
    800023d2:	b7d5                	j	800023b6 <reparent+0x2c>
}
    800023d4:	70a2                	ld	ra,40(sp)
    800023d6:	7402                	ld	s0,32(sp)
    800023d8:	64e2                	ld	s1,24(sp)
    800023da:	6942                	ld	s2,16(sp)
    800023dc:	69a2                	ld	s3,8(sp)
    800023de:	6a02                	ld	s4,0(sp)
    800023e0:	6145                	addi	sp,sp,48
    800023e2:	8082                	ret

00000000800023e4 <exit>:
{
    800023e4:	7179                	addi	sp,sp,-48
    800023e6:	f406                	sd	ra,40(sp)
    800023e8:	f022                	sd	s0,32(sp)
    800023ea:	ec26                	sd	s1,24(sp)
    800023ec:	e84a                	sd	s2,16(sp)
    800023ee:	e44e                	sd	s3,8(sp)
    800023f0:	e052                	sd	s4,0(sp)
    800023f2:	1800                	addi	s0,sp,48
    800023f4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	6ce080e7          	jalr	1742(ra) # 80001ac4 <myproc>
    800023fe:	89aa                	mv	s3,a0
  if(p == initproc)
    80002400:	00007797          	auipc	a5,0x7
    80002404:	c287b783          	ld	a5,-984(a5) # 80009028 <initproc>
    80002408:	0d050493          	addi	s1,a0,208
    8000240c:	15050913          	addi	s2,a0,336
    80002410:	02a79363          	bne	a5,a0,80002436 <exit+0x52>
    panic("init exiting");
    80002414:	00006517          	auipc	a0,0x6
    80002418:	e9c50513          	addi	a0,a0,-356 # 800082b0 <digits+0x270>
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	11e080e7          	jalr	286(ra) # 8000053a <panic>
      fileclose(f);
    80002424:	00002097          	auipc	ra,0x2
    80002428:	1a0080e7          	jalr	416(ra) # 800045c4 <fileclose>
      p->ofile[fd] = 0;
    8000242c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002430:	04a1                	addi	s1,s1,8
    80002432:	01248563          	beq	s1,s2,8000243c <exit+0x58>
    if(p->ofile[fd]){
    80002436:	6088                	ld	a0,0(s1)
    80002438:	f575                	bnez	a0,80002424 <exit+0x40>
    8000243a:	bfdd                	j	80002430 <exit+0x4c>
  begin_op();
    8000243c:	00002097          	auipc	ra,0x2
    80002440:	cc0080e7          	jalr	-832(ra) # 800040fc <begin_op>
  iput(p->cwd);
    80002444:	1509b503          	ld	a0,336(s3)
    80002448:	00001097          	auipc	ra,0x1
    8000244c:	492080e7          	jalr	1170(ra) # 800038da <iput>
  end_op();
    80002450:	00002097          	auipc	ra,0x2
    80002454:	d2a080e7          	jalr	-726(ra) # 8000417a <end_op>
  p->cwd = 0;
    80002458:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000245c:	0000f497          	auipc	s1,0xf
    80002460:	e5c48493          	addi	s1,s1,-420 # 800112b8 <wait_lock>
    80002464:	8526                	mv	a0,s1
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	76a080e7          	jalr	1898(ra) # 80000bd0 <acquire>
  reparent(p);
    8000246e:	854e                	mv	a0,s3
    80002470:	00000097          	auipc	ra,0x0
    80002474:	f1a080e7          	jalr	-230(ra) # 8000238a <reparent>
  wakeup(p->parent);
    80002478:	0389b503          	ld	a0,56(s3)
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	e98080e7          	jalr	-360(ra) # 80002314 <wakeup>
  acquire(&p->lock);
    80002484:	854e                	mv	a0,s3
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	74a080e7          	jalr	1866(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000248e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002492:	4795                	li	a5,5
    80002494:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7ea080e7          	jalr	2026(ra) # 80000c84 <release>
  sched();
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	bd4080e7          	jalr	-1068(ra) # 80002076 <sched>
  panic("zombie exit");
    800024aa:	00006517          	auipc	a0,0x6
    800024ae:	e1650513          	addi	a0,a0,-490 # 800082c0 <digits+0x280>
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	088080e7          	jalr	136(ra) # 8000053a <panic>

00000000800024ba <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	1800                	addi	s0,sp,48
    800024c8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024ca:	0000f497          	auipc	s1,0xf
    800024ce:	20648493          	addi	s1,s1,518 # 800116d0 <proc>
    800024d2:	00015997          	auipc	s3,0x15
    800024d6:	bfe98993          	addi	s3,s3,-1026 # 800170d0 <tickslock>
    acquire(&p->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	6f4080e7          	jalr	1780(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800024e4:	589c                	lw	a5,48(s1)
    800024e6:	01278d63          	beq	a5,s2,80002500 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ea:	8526                	mv	a0,s1
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	798080e7          	jalr	1944(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f4:	16848493          	addi	s1,s1,360
    800024f8:	ff3491e3          	bne	s1,s3,800024da <kill+0x20>
  }
  return -1;
    800024fc:	557d                	li	a0,-1
    800024fe:	a829                	j	80002518 <kill+0x5e>
      p->killed = 1;
    80002500:	4785                	li	a5,1
    80002502:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002504:	4c98                	lw	a4,24(s1)
    80002506:	4789                	li	a5,2
    80002508:	00f70f63          	beq	a4,a5,80002526 <kill+0x6c>
      release(&p->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	776080e7          	jalr	1910(ra) # 80000c84 <release>
      return 0;
    80002516:	4501                	li	a0,0
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret
        p->state = RUNNABLE;
    80002526:	478d                	li	a5,3
    80002528:	cc9c                	sw	a5,24(s1)
    8000252a:	b7cd                	j	8000250c <kill+0x52>

000000008000252c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000252c:	7179                	addi	sp,sp,-48
    8000252e:	f406                	sd	ra,40(sp)
    80002530:	f022                	sd	s0,32(sp)
    80002532:	ec26                	sd	s1,24(sp)
    80002534:	e84a                	sd	s2,16(sp)
    80002536:	e44e                	sd	s3,8(sp)
    80002538:	e052                	sd	s4,0(sp)
    8000253a:	1800                	addi	s0,sp,48
    8000253c:	84aa                	mv	s1,a0
    8000253e:	892e                	mv	s2,a1
    80002540:	89b2                	mv	s3,a2
    80002542:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	580080e7          	jalr	1408(ra) # 80001ac4 <myproc>
  if(user_dst){
    8000254c:	c08d                	beqz	s1,8000256e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000254e:	86d2                	mv	a3,s4
    80002550:	864e                	mv	a2,s3
    80002552:	85ca                	mv	a1,s2
    80002554:	6928                	ld	a0,80(a0)
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	104080e7          	jalr	260(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000255e:	70a2                	ld	ra,40(sp)
    80002560:	7402                	ld	s0,32(sp)
    80002562:	64e2                	ld	s1,24(sp)
    80002564:	6942                	ld	s2,16(sp)
    80002566:	69a2                	ld	s3,8(sp)
    80002568:	6a02                	ld	s4,0(sp)
    8000256a:	6145                	addi	sp,sp,48
    8000256c:	8082                	ret
    memmove((char *)dst, src, len);
    8000256e:	000a061b          	sext.w	a2,s4
    80002572:	85ce                	mv	a1,s3
    80002574:	854a                	mv	a0,s2
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	7b2080e7          	jalr	1970(ra) # 80000d28 <memmove>
    return 0;
    8000257e:	8526                	mv	a0,s1
    80002580:	bff9                	j	8000255e <either_copyout+0x32>

0000000080002582 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002582:	7179                	addi	sp,sp,-48
    80002584:	f406                	sd	ra,40(sp)
    80002586:	f022                	sd	s0,32(sp)
    80002588:	ec26                	sd	s1,24(sp)
    8000258a:	e84a                	sd	s2,16(sp)
    8000258c:	e44e                	sd	s3,8(sp)
    8000258e:	e052                	sd	s4,0(sp)
    80002590:	1800                	addi	s0,sp,48
    80002592:	892a                	mv	s2,a0
    80002594:	84ae                	mv	s1,a1
    80002596:	89b2                	mv	s3,a2
    80002598:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	52a080e7          	jalr	1322(ra) # 80001ac4 <myproc>
  if(user_src){
    800025a2:	c08d                	beqz	s1,800025c4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a4:	86d2                	mv	a3,s4
    800025a6:	864e                	mv	a2,s3
    800025a8:	85ca                	mv	a1,s2
    800025aa:	6928                	ld	a0,80(a0)
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	13a080e7          	jalr	314(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b4:	70a2                	ld	ra,40(sp)
    800025b6:	7402                	ld	s0,32(sp)
    800025b8:	64e2                	ld	s1,24(sp)
    800025ba:	6942                	ld	s2,16(sp)
    800025bc:	69a2                	ld	s3,8(sp)
    800025be:	6a02                	ld	s4,0(sp)
    800025c0:	6145                	addi	sp,sp,48
    800025c2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c4:	000a061b          	sext.w	a2,s4
    800025c8:	85ce                	mv	a1,s3
    800025ca:	854a                	mv	a0,s2
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	75c080e7          	jalr	1884(ra) # 80000d28 <memmove>
    return 0;
    800025d4:	8526                	mv	a0,s1
    800025d6:	bff9                	j	800025b4 <either_copyin+0x32>

00000000800025d8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d8:	715d                	addi	sp,sp,-80
    800025da:	e486                	sd	ra,72(sp)
    800025dc:	e0a2                	sd	s0,64(sp)
    800025de:	fc26                	sd	s1,56(sp)
    800025e0:	f84a                	sd	s2,48(sp)
    800025e2:	f44e                	sd	s3,40(sp)
    800025e4:	f052                	sd	s4,32(sp)
    800025e6:	ec56                	sd	s5,24(sp)
    800025e8:	e85a                	sd	s6,16(sp)
    800025ea:	e45e                	sd	s7,8(sp)
    800025ec:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ee:	00006517          	auipc	a0,0x6
    800025f2:	ada50513          	addi	a0,a0,-1318 # 800080c8 <digits+0x88>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	f8e080e7          	jalr	-114(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fe:	0000f497          	auipc	s1,0xf
    80002602:	22a48493          	addi	s1,s1,554 # 80011828 <proc+0x158>
    80002606:	00015917          	auipc	s2,0x15
    8000260a:	c2290913          	addi	s2,s2,-990 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002610:	00006997          	auipc	s3,0x6
    80002614:	bc898993          	addi	s3,s3,-1080 # 800081d8 <digits+0x198>
    printf("%d %s %s", p->pid, state, p->name);
    80002618:	00006a97          	auipc	s5,0x6
    8000261c:	cb8a8a93          	addi	s5,s5,-840 # 800082d0 <digits+0x290>
    printf("\n");
    80002620:	00006a17          	auipc	s4,0x6
    80002624:	aa8a0a13          	addi	s4,s4,-1368 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002628:	00006b97          	auipc	s7,0x6
    8000262c:	ce0b8b93          	addi	s7,s7,-800 # 80008308 <states.2>
    80002630:	a00d                	j	80002652 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002632:	ed86a583          	lw	a1,-296(a3)
    80002636:	8556                	mv	a0,s5
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	f4c080e7          	jalr	-180(ra) # 80000584 <printf>
    printf("\n");
    80002640:	8552                	mv	a0,s4
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	f42080e7          	jalr	-190(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264a:	16848493          	addi	s1,s1,360
    8000264e:	03248263          	beq	s1,s2,80002672 <procdump+0x9a>
    if(p->state == UNUSED)
    80002652:	86a6                	mv	a3,s1
    80002654:	ec04a783          	lw	a5,-320(s1)
    80002658:	dbed                	beqz	a5,8000264a <procdump+0x72>
      state = "???";
    8000265a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265c:	fcfb6be3          	bltu	s6,a5,80002632 <procdump+0x5a>
    80002660:	02079713          	slli	a4,a5,0x20
    80002664:	01d75793          	srli	a5,a4,0x1d
    80002668:	97de                	add	a5,a5,s7
    8000266a:	7b90                	ld	a2,48(a5)
    8000266c:	f279                	bnez	a2,80002632 <procdump+0x5a>
      state = "???";
    8000266e:	864e                	mv	a2,s3
    80002670:	b7c9                	j	80002632 <procdump+0x5a>
  }
}
    80002672:	60a6                	ld	ra,72(sp)
    80002674:	6406                	ld	s0,64(sp)
    80002676:	74e2                	ld	s1,56(sp)
    80002678:	7942                	ld	s2,48(sp)
    8000267a:	79a2                	ld	s3,40(sp)
    8000267c:	7a02                	ld	s4,32(sp)
    8000267e:	6ae2                	ld	s5,24(sp)
    80002680:	6b42                	ld	s6,16(sp)
    80002682:	6ba2                	ld	s7,8(sp)
    80002684:	6161                	addi	sp,sp,80
    80002686:	8082                	ret

0000000080002688 <swtch>:
    80002688:	00153023          	sd	ra,0(a0)
    8000268c:	00253423          	sd	sp,8(a0)
    80002690:	e900                	sd	s0,16(a0)
    80002692:	ed04                	sd	s1,24(a0)
    80002694:	03253023          	sd	s2,32(a0)
    80002698:	03353423          	sd	s3,40(a0)
    8000269c:	03453823          	sd	s4,48(a0)
    800026a0:	03553c23          	sd	s5,56(a0)
    800026a4:	05653023          	sd	s6,64(a0)
    800026a8:	05753423          	sd	s7,72(a0)
    800026ac:	05853823          	sd	s8,80(a0)
    800026b0:	05953c23          	sd	s9,88(a0)
    800026b4:	07a53023          	sd	s10,96(a0)
    800026b8:	07b53423          	sd	s11,104(a0)
    800026bc:	0005b083          	ld	ra,0(a1)
    800026c0:	0085b103          	ld	sp,8(a1)
    800026c4:	6980                	ld	s0,16(a1)
    800026c6:	6d84                	ld	s1,24(a1)
    800026c8:	0205b903          	ld	s2,32(a1)
    800026cc:	0285b983          	ld	s3,40(a1)
    800026d0:	0305ba03          	ld	s4,48(a1)
    800026d4:	0385ba83          	ld	s5,56(a1)
    800026d8:	0405bb03          	ld	s6,64(a1)
    800026dc:	0485bb83          	ld	s7,72(a1)
    800026e0:	0505bc03          	ld	s8,80(a1)
    800026e4:	0585bc83          	ld	s9,88(a1)
    800026e8:	0605bd03          	ld	s10,96(a1)
    800026ec:	0685bd83          	ld	s11,104(a1)
    800026f0:	8082                	ret

00000000800026f2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f2:	1141                	addi	sp,sp,-16
    800026f4:	e406                	sd	ra,8(sp)
    800026f6:	e022                	sd	s0,0(sp)
    800026f8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fa:	00006597          	auipc	a1,0x6
    800026fe:	c6e58593          	addi	a1,a1,-914 # 80008368 <states.0+0x30>
    80002702:	00015517          	auipc	a0,0x15
    80002706:	9ce50513          	addi	a0,a0,-1586 # 800170d0 <tickslock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	436080e7          	jalr	1078(ra) # 80000b40 <initlock>
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e422                	sd	s0,8(sp)
    8000271e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	00003797          	auipc	a5,0x3
    80002724:	4d078793          	addi	a5,a5,1232 # 80005bf0 <kernelvec>
    80002728:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272c:	6422                	ld	s0,8(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	38a080e7          	jalr	906(ra) # 80001ac4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002742:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002746:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274c:	00005697          	auipc	a3,0x5
    80002750:	8b468693          	addi	a3,a3,-1868 # 80007000 <_trampoline>
    80002754:	00005717          	auipc	a4,0x5
    80002758:	8ac70713          	addi	a4,a4,-1876 # 80007000 <_trampoline>
    8000275c:	8f15                	sub	a4,a4,a3
    8000275e:	040007b7          	lui	a5,0x4000
    80002762:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002764:	07b2                	slli	a5,a5,0xc
    80002766:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002768:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000276e:	18002673          	csrr	a2,satp
    80002772:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002774:	6d30                	ld	a2,88(a0)
    80002776:	6138                	ld	a4,64(a0)
    80002778:	6585                	lui	a1,0x1
    8000277a:	972e                	add	a4,a4,a1
    8000277c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000277e:	6d38                	ld	a4,88(a0)
    80002780:	00000617          	auipc	a2,0x0
    80002784:	13860613          	addi	a2,a2,312 # 800028b8 <usertrap>
    80002788:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278c:	8612                	mv	a2,tp
    8000278e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002794:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002798:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a2:	6f18                	ld	a4,24(a4)
    800027a4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027a8:	692c                	ld	a1,80(a0)
    800027aa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ac:	00005717          	auipc	a4,0x5
    800027b0:	8e470713          	addi	a4,a4,-1820 # 80007090 <userret>
    800027b4:	8f15                	sub	a4,a4,a3
    800027b6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027b8:	577d                	li	a4,-1
    800027ba:	177e                	slli	a4,a4,0x3f
    800027bc:	8dd9                	or	a1,a1,a4
    800027be:	02000537          	lui	a0,0x2000
    800027c2:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800027c4:	0536                	slli	a0,a0,0xd
    800027c6:	9782                	jalr	a5
}
    800027c8:	60a2                	ld	ra,8(sp)
    800027ca:	6402                	ld	s0,0(sp)
    800027cc:	0141                	addi	sp,sp,16
    800027ce:	8082                	ret

00000000800027d0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d0:	1101                	addi	sp,sp,-32
    800027d2:	ec06                	sd	ra,24(sp)
    800027d4:	e822                	sd	s0,16(sp)
    800027d6:	e426                	sd	s1,8(sp)
    800027d8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027da:	00015497          	auipc	s1,0x15
    800027de:	8f648493          	addi	s1,s1,-1802 # 800170d0 <tickslock>
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	3ec080e7          	jalr	1004(ra) # 80000bd0 <acquire>
  ticks++;
    800027ec:	00007517          	auipc	a0,0x7
    800027f0:	84450513          	addi	a0,a0,-1980 # 80009030 <ticks>
    800027f4:	411c                	lw	a5,0(a0)
    800027f6:	2785                	addiw	a5,a5,1
    800027f8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	b1a080e7          	jalr	-1254(ra) # 80002314 <wakeup>
  release(&tickslock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	480080e7          	jalr	1152(ra) # 80000c84 <release>
}
    8000280c:	60e2                	ld	ra,24(sp)
    8000280e:	6442                	ld	s0,16(sp)
    80002810:	64a2                	ld	s1,8(sp)
    80002812:	6105                	addi	sp,sp,32
    80002814:	8082                	ret

0000000080002816 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002816:	1101                	addi	sp,sp,-32
    80002818:	ec06                	sd	ra,24(sp)
    8000281a:	e822                	sd	s0,16(sp)
    8000281c:	e426                	sd	s1,8(sp)
    8000281e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002820:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002824:	00074d63          	bltz	a4,8000283e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002828:	57fd                	li	a5,-1
    8000282a:	17fe                	slli	a5,a5,0x3f
    8000282c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000282e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002830:	06f70363          	beq	a4,a5,80002896 <devintr+0x80>
  }
}
    80002834:	60e2                	ld	ra,24(sp)
    80002836:	6442                	ld	s0,16(sp)
    80002838:	64a2                	ld	s1,8(sp)
    8000283a:	6105                	addi	sp,sp,32
    8000283c:	8082                	ret
     (scause & 0xff) == 9){
    8000283e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002842:	46a5                	li	a3,9
    80002844:	fed792e3          	bne	a5,a3,80002828 <devintr+0x12>
    int irq = plic_claim();
    80002848:	00003097          	auipc	ra,0x3
    8000284c:	4b0080e7          	jalr	1200(ra) # 80005cf8 <plic_claim>
    80002850:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002852:	47a9                	li	a5,10
    80002854:	02f50763          	beq	a0,a5,80002882 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002858:	4785                	li	a5,1
    8000285a:	02f50963          	beq	a0,a5,8000288c <devintr+0x76>
    return 1;
    8000285e:	4505                	li	a0,1
    } else if(irq){
    80002860:	d8f1                	beqz	s1,80002834 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002862:	85a6                	mv	a1,s1
    80002864:	00006517          	auipc	a0,0x6
    80002868:	b0c50513          	addi	a0,a0,-1268 # 80008370 <states.0+0x38>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	d18080e7          	jalr	-744(ra) # 80000584 <printf>
      plic_complete(irq);
    80002874:	8526                	mv	a0,s1
    80002876:	00003097          	auipc	ra,0x3
    8000287a:	4a6080e7          	jalr	1190(ra) # 80005d1c <plic_complete>
    return 1;
    8000287e:	4505                	li	a0,1
    80002880:	bf55                	j	80002834 <devintr+0x1e>
      uartintr();
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	110080e7          	jalr	272(ra) # 80000992 <uartintr>
    8000288a:	b7ed                	j	80002874 <devintr+0x5e>
      virtio_disk_intr();
    8000288c:	00004097          	auipc	ra,0x4
    80002890:	91c080e7          	jalr	-1764(ra) # 800061a8 <virtio_disk_intr>
    80002894:	b7c5                	j	80002874 <devintr+0x5e>
    if(cpuid() == 0){
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	202080e7          	jalr	514(ra) # 80001a98 <cpuid>
    8000289e:	c901                	beqz	a0,800028ae <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a6:	14479073          	csrw	sip,a5
    return 2;
    800028aa:	4509                	li	a0,2
    800028ac:	b761                	j	80002834 <devintr+0x1e>
      clockintr();
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	f22080e7          	jalr	-222(ra) # 800027d0 <clockintr>
    800028b6:	b7ed                	j	800028a0 <devintr+0x8a>

00000000800028b8 <usertrap>:
{
    800028b8:	1101                	addi	sp,sp,-32
    800028ba:	ec06                	sd	ra,24(sp)
    800028bc:	e822                	sd	s0,16(sp)
    800028be:	e426                	sd	s1,8(sp)
    800028c0:	e04a                	sd	s2,0(sp)
    800028c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028c8:	1007f793          	andi	a5,a5,256
    800028cc:	e3ad                	bnez	a5,8000292e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ce:	00003797          	auipc	a5,0x3
    800028d2:	32278793          	addi	a5,a5,802 # 80005bf0 <kernelvec>
    800028d6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	1ea080e7          	jalr	490(ra) # 80001ac4 <myproc>
    800028e2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e6:	14102773          	csrr	a4,sepc
    800028ea:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ec:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f0:	47a1                	li	a5,8
    800028f2:	04f71c63          	bne	a4,a5,8000294a <usertrap+0x92>
    if(p->killed)
    800028f6:	551c                	lw	a5,40(a0)
    800028f8:	e3b9                	bnez	a5,8000293e <usertrap+0x86>
    p->trapframe->epc += 4;
    800028fa:	6cb8                	ld	a4,88(s1)
    800028fc:	6f1c                	ld	a5,24(a4)
    800028fe:	0791                	addi	a5,a5,4
    80002900:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002902:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002906:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290a:	10079073          	csrw	sstatus,a5
    syscall();
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	2e0080e7          	jalr	736(ra) # 80002bee <syscall>
  if(p->killed)
    80002916:	549c                	lw	a5,40(s1)
    80002918:	ebc1                	bnez	a5,800029a8 <usertrap+0xf0>
  usertrapret();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	e18080e7          	jalr	-488(ra) # 80002732 <usertrapret>
}
    80002922:	60e2                	ld	ra,24(sp)
    80002924:	6442                	ld	s0,16(sp)
    80002926:	64a2                	ld	s1,8(sp)
    80002928:	6902                	ld	s2,0(sp)
    8000292a:	6105                	addi	sp,sp,32
    8000292c:	8082                	ret
    panic("usertrap: not from user mode");
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a6250513          	addi	a0,a0,-1438 # 80008390 <states.0+0x58>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c04080e7          	jalr	-1020(ra) # 8000053a <panic>
      exit(-1);
    8000293e:	557d                	li	a0,-1
    80002940:	00000097          	auipc	ra,0x0
    80002944:	aa4080e7          	jalr	-1372(ra) # 800023e4 <exit>
    80002948:	bf4d                	j	800028fa <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	ecc080e7          	jalr	-308(ra) # 80002816 <devintr>
    80002952:	892a                	mv	s2,a0
    80002954:	c501                	beqz	a0,8000295c <usertrap+0xa4>
  if(p->killed)
    80002956:	549c                	lw	a5,40(s1)
    80002958:	c3a1                	beqz	a5,80002998 <usertrap+0xe0>
    8000295a:	a815                	j	8000298e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002960:	5890                	lw	a2,48(s1)
    80002962:	00006517          	auipc	a0,0x6
    80002966:	a4e50513          	addi	a0,a0,-1458 # 800083b0 <states.0+0x78>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c1a080e7          	jalr	-998(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002972:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002976:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	a6650513          	addi	a0,a0,-1434 # 800083e0 <states.0+0xa8>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c02080e7          	jalr	-1022(ra) # 80000584 <printf>
    p->killed = 1;
    8000298a:	4785                	li	a5,1
    8000298c:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000298e:	557d                	li	a0,-1
    80002990:	00000097          	auipc	ra,0x0
    80002994:	a54080e7          	jalr	-1452(ra) # 800023e4 <exit>
  if(which_dev == 2)
    80002998:	4789                	li	a5,2
    8000299a:	f8f910e3          	bne	s2,a5,8000291a <usertrap+0x62>
    yield();
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	7ae080e7          	jalr	1966(ra) # 8000214c <yield>
    800029a6:	bf95                	j	8000291a <usertrap+0x62>
  int which_dev = 0;
    800029a8:	4901                	li	s2,0
    800029aa:	b7d5                	j	8000298e <usertrap+0xd6>

00000000800029ac <kerneltrap>:
{
    800029ac:	7179                	addi	sp,sp,-48
    800029ae:	f406                	sd	ra,40(sp)
    800029b0:	f022                	sd	s0,32(sp)
    800029b2:	ec26                	sd	s1,24(sp)
    800029b4:	e84a                	sd	s2,16(sp)
    800029b6:	e44e                	sd	s3,8(sp)
    800029b8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ba:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029be:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029c6:	1004f793          	andi	a5,s1,256
    800029ca:	cb85                	beqz	a5,800029fa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029cc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d2:	ef85                	bnez	a5,80002a0a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	e42080e7          	jalr	-446(ra) # 80002816 <devintr>
    800029dc:	cd1d                	beqz	a0,80002a1a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029de:	4789                	li	a5,2
    800029e0:	06f50a63          	beq	a0,a5,80002a54 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e8:	10049073          	csrw	sstatus,s1
}
    800029ec:	70a2                	ld	ra,40(sp)
    800029ee:	7402                	ld	s0,32(sp)
    800029f0:	64e2                	ld	s1,24(sp)
    800029f2:	6942                	ld	s2,16(sp)
    800029f4:	69a2                	ld	s3,8(sp)
    800029f6:	6145                	addi	sp,sp,48
    800029f8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	a0650513          	addi	a0,a0,-1530 # 80008400 <states.0+0xc8>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b38080e7          	jalr	-1224(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	a1e50513          	addi	a0,a0,-1506 # 80008428 <states.0+0xf0>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b28080e7          	jalr	-1240(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002a1a:	85ce                	mv	a1,s3
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	a2c50513          	addi	a0,a0,-1492 # 80008448 <states.0+0x110>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b60080e7          	jalr	-1184(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a30:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	a2450513          	addi	a0,a0,-1500 # 80008458 <states.0+0x120>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b48080e7          	jalr	-1208(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	a2c50513          	addi	a0,a0,-1492 # 80008470 <states.0+0x138>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	aee080e7          	jalr	-1298(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	070080e7          	jalr	112(ra) # 80001ac4 <myproc>
    80002a5c:	d541                	beqz	a0,800029e4 <kerneltrap+0x38>
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	066080e7          	jalr	102(ra) # 80001ac4 <myproc>
    80002a66:	4d18                	lw	a4,24(a0)
    80002a68:	4791                	li	a5,4
    80002a6a:	f6f71de3          	bne	a4,a5,800029e4 <kerneltrap+0x38>
    yield();
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	6de080e7          	jalr	1758(ra) # 8000214c <yield>
    80002a76:	b7bd                	j	800029e4 <kerneltrap+0x38>

0000000080002a78 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a78:	1101                	addi	sp,sp,-32
    80002a7a:	ec06                	sd	ra,24(sp)
    80002a7c:	e822                	sd	s0,16(sp)
    80002a7e:	e426                	sd	s1,8(sp)
    80002a80:	1000                	addi	s0,sp,32
    80002a82:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	040080e7          	jalr	64(ra) # 80001ac4 <myproc>
  switch (n) {
    80002a8c:	4795                	li	a5,5
    80002a8e:	0497e163          	bltu	a5,s1,80002ad0 <argraw+0x58>
    80002a92:	048a                	slli	s1,s1,0x2
    80002a94:	00006717          	auipc	a4,0x6
    80002a98:	a1470713          	addi	a4,a4,-1516 # 800084a8 <states.0+0x170>
    80002a9c:	94ba                	add	s1,s1,a4
    80002a9e:	409c                	lw	a5,0(s1)
    80002aa0:	97ba                	add	a5,a5,a4
    80002aa2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
    return p->trapframe->a1;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	7fa8                	ld	a0,120(a5)
    80002ab6:	bfcd                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a2;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	63c8                	ld	a0,128(a5)
    80002abc:	b7f5                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a3;
    80002abe:	6d3c                	ld	a5,88(a0)
    80002ac0:	67c8                	ld	a0,136(a5)
    80002ac2:	b7dd                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a4;
    80002ac4:	6d3c                	ld	a5,88(a0)
    80002ac6:	6bc8                	ld	a0,144(a5)
    80002ac8:	b7c5                	j	80002aa8 <argraw+0x30>
    return p->trapframe->a5;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	6fc8                	ld	a0,152(a5)
    80002ace:	bfe9                	j	80002aa8 <argraw+0x30>
  panic("argraw");
    80002ad0:	00006517          	auipc	a0,0x6
    80002ad4:	9b050513          	addi	a0,a0,-1616 # 80008480 <states.0+0x148>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	a62080e7          	jalr	-1438(ra) # 8000053a <panic>

0000000080002ae0 <fetchaddr>:
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84aa                	mv	s1,a0
    80002aee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	fd4080e7          	jalr	-44(ra) # 80001ac4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002af8:	653c                	ld	a5,72(a0)
    80002afa:	02f4f863          	bgeu	s1,a5,80002b2a <fetchaddr+0x4a>
    80002afe:	00848713          	addi	a4,s1,8
    80002b02:	02e7e663          	bltu	a5,a4,80002b2e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b06:	46a1                	li	a3,8
    80002b08:	8626                	mv	a2,s1
    80002b0a:	85ca                	mv	a1,s2
    80002b0c:	6928                	ld	a0,80(a0)
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	bd8080e7          	jalr	-1064(ra) # 800016e6 <copyin>
    80002b16:	00a03533          	snez	a0,a0
    80002b1a:	40a00533          	neg	a0,a0
}
    80002b1e:	60e2                	ld	ra,24(sp)
    80002b20:	6442                	ld	s0,16(sp)
    80002b22:	64a2                	ld	s1,8(sp)
    80002b24:	6902                	ld	s2,0(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret
    return -1;
    80002b2a:	557d                	li	a0,-1
    80002b2c:	bfcd                	j	80002b1e <fetchaddr+0x3e>
    80002b2e:	557d                	li	a0,-1
    80002b30:	b7fd                	j	80002b1e <fetchaddr+0x3e>

0000000080002b32 <fetchstr>:
{
    80002b32:	7179                	addi	sp,sp,-48
    80002b34:	f406                	sd	ra,40(sp)
    80002b36:	f022                	sd	s0,32(sp)
    80002b38:	ec26                	sd	s1,24(sp)
    80002b3a:	e84a                	sd	s2,16(sp)
    80002b3c:	e44e                	sd	s3,8(sp)
    80002b3e:	1800                	addi	s0,sp,48
    80002b40:	892a                	mv	s2,a0
    80002b42:	84ae                	mv	s1,a1
    80002b44:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	f7e080e7          	jalr	-130(ra) # 80001ac4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b4e:	86ce                	mv	a3,s3
    80002b50:	864a                	mv	a2,s2
    80002b52:	85a6                	mv	a1,s1
    80002b54:	6928                	ld	a0,80(a0)
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	c1e080e7          	jalr	-994(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002b5e:	00054763          	bltz	a0,80002b6c <fetchstr+0x3a>
  return strlen(buf);
    80002b62:	8526                	mv	a0,s1
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	2e4080e7          	jalr	740(ra) # 80000e48 <strlen>
}
    80002b6c:	70a2                	ld	ra,40(sp)
    80002b6e:	7402                	ld	s0,32(sp)
    80002b70:	64e2                	ld	s1,24(sp)
    80002b72:	6942                	ld	s2,16(sp)
    80002b74:	69a2                	ld	s3,8(sp)
    80002b76:	6145                	addi	sp,sp,48
    80002b78:	8082                	ret

0000000080002b7a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b7a:	1101                	addi	sp,sp,-32
    80002b7c:	ec06                	sd	ra,24(sp)
    80002b7e:	e822                	sd	s0,16(sp)
    80002b80:	e426                	sd	s1,8(sp)
    80002b82:	1000                	addi	s0,sp,32
    80002b84:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	ef2080e7          	jalr	-270(ra) # 80002a78 <argraw>
    80002b8e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b90:	4501                	li	a0,0
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	ed0080e7          	jalr	-304(ra) # 80002a78 <argraw>
    80002bb0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb2:	4501                	li	a0,0
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret

0000000080002bbe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	e04a                	sd	s2,0(sp)
    80002bc8:	1000                	addi	s0,sp,32
    80002bca:	84ae                	mv	s1,a1
    80002bcc:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	eaa080e7          	jalr	-342(ra) # 80002a78 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bd6:	864a                	mv	a2,s2
    80002bd8:	85a6                	mv	a1,s1
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	f58080e7          	jalr	-168(ra) # 80002b32 <fetchstr>
}
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6902                	ld	s2,0(sp)
    80002bea:	6105                	addi	sp,sp,32
    80002bec:	8082                	ret

0000000080002bee <syscall>:
[SYS_showprocs]   sys_showprocs,
};

void
syscall(void)
{
    80002bee:	1101                	addi	sp,sp,-32
    80002bf0:	ec06                	sd	ra,24(sp)
    80002bf2:	e822                	sd	s0,16(sp)
    80002bf4:	e426                	sd	s1,8(sp)
    80002bf6:	e04a                	sd	s2,0(sp)
    80002bf8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	eca080e7          	jalr	-310(ra) # 80001ac4 <myproc>
    80002c02:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c04:	05853903          	ld	s2,88(a0)
    80002c08:	0a893783          	ld	a5,168(s2)
    80002c0c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c10:	37fd                	addiw	a5,a5,-1
    80002c12:	4759                	li	a4,22
    80002c14:	00f76f63          	bltu	a4,a5,80002c32 <syscall+0x44>
    80002c18:	00369713          	slli	a4,a3,0x3
    80002c1c:	00006797          	auipc	a5,0x6
    80002c20:	8a478793          	addi	a5,a5,-1884 # 800084c0 <syscalls>
    80002c24:	97ba                	add	a5,a5,a4
    80002c26:	639c                	ld	a5,0(a5)
    80002c28:	c789                	beqz	a5,80002c32 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c2a:	9782                	jalr	a5
    80002c2c:	06a93823          	sd	a0,112(s2)
    80002c30:	a839                	j	80002c4e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c32:	15848613          	addi	a2,s1,344
    80002c36:	588c                	lw	a1,48(s1)
    80002c38:	00006517          	auipc	a0,0x6
    80002c3c:	85050513          	addi	a0,a0,-1968 # 80008488 <states.0+0x150>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	944080e7          	jalr	-1724(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c48:	6cbc                	ld	a5,88(s1)
    80002c4a:	577d                	li	a4,-1
    80002c4c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret

0000000080002c5a <sys_getthisprocsize>:
#include "spinlock.h"
#include "proc.h"

// new call
uint64 sys_getthisprocsize(void)
{
    80002c5a:	1141                	addi	sp,sp,-16
    80002c5c:	e406                	sd	ra,8(sp)
    80002c5e:	e022                	sd	s0,0(sp)
    80002c60:	0800                	addi	s0,sp,16
  struct proc *p = myproc(); // Pointer to the PCB structure
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	e62080e7          	jalr	-414(ra) # 80001ac4 <myproc>
  return p->sz; // returns the size in bytes
}
    80002c6a:	6528                	ld	a0,72(a0)
    80002c6c:	60a2                	ld	ra,8(sp)
    80002c6e:	6402                	ld	s0,0(sp)
    80002c70:	0141                	addi	sp,sp,16
    80002c72:	8082                	ret

0000000080002c74 <sys_showprocs>:

// new show procs call
uint64 sys_showprocs(void)
{
    80002c74:	1141                	addi	sp,sp,-16
    80002c76:	e406                	sd	ra,8(sp)
    80002c78:	e022                	sd	s0,0(sp)
    80002c7a:	0800                	addi	s0,sp,16
  proc_print();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	ba8080e7          	jalr	-1112(ra) # 80001824 <proc_print>
  return 1; // if successful
}
    80002c84:	4505                	li	a0,1
    80002c86:	60a2                	ld	ra,8(sp)
    80002c88:	6402                	ld	s0,0(sp)
    80002c8a:	0141                	addi	sp,sp,16
    80002c8c:	8082                	ret

0000000080002c8e <sys_exit>:

uint64
sys_exit(void)
{
    80002c8e:	1101                	addi	sp,sp,-32
    80002c90:	ec06                	sd	ra,24(sp)
    80002c92:	e822                	sd	s0,16(sp)
    80002c94:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c96:	fec40593          	addi	a1,s0,-20
    80002c9a:	4501                	li	a0,0
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	ede080e7          	jalr	-290(ra) # 80002b7a <argint>
    return -1;
    80002ca4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca6:	00054963          	bltz	a0,80002cb8 <sys_exit+0x2a>
  exit(n);
    80002caa:	fec42503          	lw	a0,-20(s0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	736080e7          	jalr	1846(ra) # 800023e4 <exit>
  return 0;  // not reached
    80002cb6:	4781                	li	a5,0
}
    80002cb8:	853e                	mv	a0,a5
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret

0000000080002cc2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc2:	1141                	addi	sp,sp,-16
    80002cc4:	e406                	sd	ra,8(sp)
    80002cc6:	e022                	sd	s0,0(sp)
    80002cc8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	dfa080e7          	jalr	-518(ra) # 80001ac4 <myproc>
}
    80002cd2:	5908                	lw	a0,48(a0)
    80002cd4:	60a2                	ld	ra,8(sp)
    80002cd6:	6402                	ld	s0,0(sp)
    80002cd8:	0141                	addi	sp,sp,16
    80002cda:	8082                	ret

0000000080002cdc <sys_fork>:

uint64
sys_fork(void)
{
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e406                	sd	ra,8(sp)
    80002ce0:	e022                	sd	s0,0(sp)
    80002ce2:	0800                	addi	s0,sp,16
  return fork();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	1b2080e7          	jalr	434(ra) # 80001e96 <fork>
}
    80002cec:	60a2                	ld	ra,8(sp)
    80002cee:	6402                	ld	s0,0(sp)
    80002cf0:	0141                	addi	sp,sp,16
    80002cf2:	8082                	ret

0000000080002cf4 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf4:	1101                	addi	sp,sp,-32
    80002cf6:	ec06                	sd	ra,24(sp)
    80002cf8:	e822                	sd	s0,16(sp)
    80002cfa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfc:	fe840593          	addi	a1,s0,-24
    80002d00:	4501                	li	a0,0
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	e9a080e7          	jalr	-358(ra) # 80002b9c <argaddr>
    80002d0a:	87aa                	mv	a5,a0
    return -1;
    80002d0c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d0e:	0007c863          	bltz	a5,80002d1e <sys_wait+0x2a>
  return wait(p);
    80002d12:	fe843503          	ld	a0,-24(s0)
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	4d6080e7          	jalr	1238(ra) # 800021ec <wait>
}
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	6105                	addi	sp,sp,32
    80002d24:	8082                	ret

0000000080002d26 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d26:	7179                	addi	sp,sp,-48
    80002d28:	f406                	sd	ra,40(sp)
    80002d2a:	f022                	sd	s0,32(sp)
    80002d2c:	ec26                	sd	s1,24(sp)
    80002d2e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d30:	fdc40593          	addi	a1,s0,-36
    80002d34:	4501                	li	a0,0
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	e44080e7          	jalr	-444(ra) # 80002b7a <argint>
    80002d3e:	87aa                	mv	a5,a0
    return -1;
    80002d40:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d42:	0207c063          	bltz	a5,80002d62 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	d7e080e7          	jalr	-642(ra) # 80001ac4 <myproc>
    80002d4e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d50:	fdc42503          	lw	a0,-36(s0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	0ca080e7          	jalr	202(ra) # 80001e1e <growproc>
    80002d5c:	00054863          	bltz	a0,80002d6c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d60:	8526                	mv	a0,s1
}
    80002d62:	70a2                	ld	ra,40(sp)
    80002d64:	7402                	ld	s0,32(sp)
    80002d66:	64e2                	ld	s1,24(sp)
    80002d68:	6145                	addi	sp,sp,48
    80002d6a:	8082                	ret
    return -1;
    80002d6c:	557d                	li	a0,-1
    80002d6e:	bfd5                	j	80002d62 <sys_sbrk+0x3c>

0000000080002d70 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d70:	7139                	addi	sp,sp,-64
    80002d72:	fc06                	sd	ra,56(sp)
    80002d74:	f822                	sd	s0,48(sp)
    80002d76:	f426                	sd	s1,40(sp)
    80002d78:	f04a                	sd	s2,32(sp)
    80002d7a:	ec4e                	sd	s3,24(sp)
    80002d7c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d7e:	fcc40593          	addi	a1,s0,-52
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	df6080e7          	jalr	-522(ra) # 80002b7a <argint>
    return -1;
    80002d8c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d8e:	06054563          	bltz	a0,80002df8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d92:	00014517          	auipc	a0,0x14
    80002d96:	33e50513          	addi	a0,a0,830 # 800170d0 <tickslock>
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	e36080e7          	jalr	-458(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002da2:	00006917          	auipc	s2,0x6
    80002da6:	28e92903          	lw	s2,654(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002daa:	fcc42783          	lw	a5,-52(s0)
    80002dae:	cf85                	beqz	a5,80002de6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db0:	00014997          	auipc	s3,0x14
    80002db4:	32098993          	addi	s3,s3,800 # 800170d0 <tickslock>
    80002db8:	00006497          	auipc	s1,0x6
    80002dbc:	27848493          	addi	s1,s1,632 # 80009030 <ticks>
    if(myproc()->killed){
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	d04080e7          	jalr	-764(ra) # 80001ac4 <myproc>
    80002dc8:	551c                	lw	a5,40(a0)
    80002dca:	ef9d                	bnez	a5,80002e08 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dcc:	85ce                	mv	a1,s3
    80002dce:	8526                	mv	a0,s1
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	3b8080e7          	jalr	952(ra) # 80002188 <sleep>
  while(ticks - ticks0 < n){
    80002dd8:	409c                	lw	a5,0(s1)
    80002dda:	412787bb          	subw	a5,a5,s2
    80002dde:	fcc42703          	lw	a4,-52(s0)
    80002de2:	fce7efe3          	bltu	a5,a4,80002dc0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002de6:	00014517          	auipc	a0,0x14
    80002dea:	2ea50513          	addi	a0,a0,746 # 800170d0 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	e96080e7          	jalr	-362(ra) # 80000c84 <release>
  return 0;
    80002df6:	4781                	li	a5,0
}
    80002df8:	853e                	mv	a0,a5
    80002dfa:	70e2                	ld	ra,56(sp)
    80002dfc:	7442                	ld	s0,48(sp)
    80002dfe:	74a2                	ld	s1,40(sp)
    80002e00:	7902                	ld	s2,32(sp)
    80002e02:	69e2                	ld	s3,24(sp)
    80002e04:	6121                	addi	sp,sp,64
    80002e06:	8082                	ret
      release(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	2c850513          	addi	a0,a0,712 # 800170d0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e74080e7          	jalr	-396(ra) # 80000c84 <release>
      return -1;
    80002e18:	57fd                	li	a5,-1
    80002e1a:	bff9                	j	80002df8 <sys_sleep+0x88>

0000000080002e1c <sys_kill>:

uint64
sys_kill(void)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e24:	fec40593          	addi	a1,s0,-20
    80002e28:	4501                	li	a0,0
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	d50080e7          	jalr	-688(ra) # 80002b7a <argint>
    80002e32:	87aa                	mv	a5,a0
    return -1;
    80002e34:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e36:	0007c863          	bltz	a5,80002e46 <sys_kill+0x2a>
  return kill(pid);
    80002e3a:	fec42503          	lw	a0,-20(s0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	67c080e7          	jalr	1660(ra) # 800024ba <kill>
}
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret

0000000080002e4e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e58:	00014517          	auipc	a0,0x14
    80002e5c:	27850513          	addi	a0,a0,632 # 800170d0 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	d70080e7          	jalr	-656(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002e68:	00006497          	auipc	s1,0x6
    80002e6c:	1c84a483          	lw	s1,456(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e70:	00014517          	auipc	a0,0x14
    80002e74:	26050513          	addi	a0,a0,608 # 800170d0 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	e0c080e7          	jalr	-500(ra) # 80000c84 <release>
  return xticks;
}
    80002e80:	02049513          	slli	a0,s1,0x20
    80002e84:	9101                	srli	a0,a0,0x20
    80002e86:	60e2                	ld	ra,24(sp)
    80002e88:	6442                	ld	s0,16(sp)
    80002e8a:	64a2                	ld	s1,8(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	e052                	sd	s4,0(sp)
    80002e9e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea0:	00005597          	auipc	a1,0x5
    80002ea4:	6e058593          	addi	a1,a1,1760 # 80008580 <syscalls+0xc0>
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	24050513          	addi	a0,a0,576 # 800170e8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	c90080e7          	jalr	-880(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eb8:	0001c797          	auipc	a5,0x1c
    80002ebc:	23078793          	addi	a5,a5,560 # 8001f0e8 <bcache+0x8000>
    80002ec0:	0001c717          	auipc	a4,0x1c
    80002ec4:	49070713          	addi	a4,a4,1168 # 8001f350 <bcache+0x8268>
    80002ec8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ecc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed0:	00014497          	auipc	s1,0x14
    80002ed4:	23048493          	addi	s1,s1,560 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ed8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eda:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002edc:	00005a17          	auipc	s4,0x5
    80002ee0:	6aca0a13          	addi	s4,s4,1708 # 80008588 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ee4:	2b893783          	ld	a5,696(s2)
    80002ee8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eea:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eee:	85d2                	mv	a1,s4
    80002ef0:	01048513          	addi	a0,s1,16
    80002ef4:	00001097          	auipc	ra,0x1
    80002ef8:	4c2080e7          	jalr	1218(ra) # 800043b6 <initsleeplock>
    bcache.head.next->prev = b;
    80002efc:	2b893783          	ld	a5,696(s2)
    80002f00:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f02:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f06:	45848493          	addi	s1,s1,1112
    80002f0a:	fd349de3          	bne	s1,s3,80002ee4 <binit+0x54>
  }
}
    80002f0e:	70a2                	ld	ra,40(sp)
    80002f10:	7402                	ld	s0,32(sp)
    80002f12:	64e2                	ld	s1,24(sp)
    80002f14:	6942                	ld	s2,16(sp)
    80002f16:	69a2                	ld	s3,8(sp)
    80002f18:	6a02                	ld	s4,0(sp)
    80002f1a:	6145                	addi	sp,sp,48
    80002f1c:	8082                	ret

0000000080002f1e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f1e:	7179                	addi	sp,sp,-48
    80002f20:	f406                	sd	ra,40(sp)
    80002f22:	f022                	sd	s0,32(sp)
    80002f24:	ec26                	sd	s1,24(sp)
    80002f26:	e84a                	sd	s2,16(sp)
    80002f28:	e44e                	sd	s3,8(sp)
    80002f2a:	1800                	addi	s0,sp,48
    80002f2c:	892a                	mv	s2,a0
    80002f2e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f30:	00014517          	auipc	a0,0x14
    80002f34:	1b850513          	addi	a0,a0,440 # 800170e8 <bcache>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	c98080e7          	jalr	-872(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f40:	0001c497          	auipc	s1,0x1c
    80002f44:	4604b483          	ld	s1,1120(s1) # 8001f3a0 <bcache+0x82b8>
    80002f48:	0001c797          	auipc	a5,0x1c
    80002f4c:	40878793          	addi	a5,a5,1032 # 8001f350 <bcache+0x8268>
    80002f50:	02f48f63          	beq	s1,a5,80002f8e <bread+0x70>
    80002f54:	873e                	mv	a4,a5
    80002f56:	a021                	j	80002f5e <bread+0x40>
    80002f58:	68a4                	ld	s1,80(s1)
    80002f5a:	02e48a63          	beq	s1,a4,80002f8e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f5e:	449c                	lw	a5,8(s1)
    80002f60:	ff279ce3          	bne	a5,s2,80002f58 <bread+0x3a>
    80002f64:	44dc                	lw	a5,12(s1)
    80002f66:	ff3799e3          	bne	a5,s3,80002f58 <bread+0x3a>
      b->refcnt++;
    80002f6a:	40bc                	lw	a5,64(s1)
    80002f6c:	2785                	addiw	a5,a5,1
    80002f6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f70:	00014517          	auipc	a0,0x14
    80002f74:	17850513          	addi	a0,a0,376 # 800170e8 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	d0c080e7          	jalr	-756(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f80:	01048513          	addi	a0,s1,16
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	46c080e7          	jalr	1132(ra) # 800043f0 <acquiresleep>
      return b;
    80002f8c:	a8b9                	j	80002fea <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f8e:	0001c497          	auipc	s1,0x1c
    80002f92:	40a4b483          	ld	s1,1034(s1) # 8001f398 <bcache+0x82b0>
    80002f96:	0001c797          	auipc	a5,0x1c
    80002f9a:	3ba78793          	addi	a5,a5,954 # 8001f350 <bcache+0x8268>
    80002f9e:	00f48863          	beq	s1,a5,80002fae <bread+0x90>
    80002fa2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fa4:	40bc                	lw	a5,64(s1)
    80002fa6:	cf81                	beqz	a5,80002fbe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	64a4                	ld	s1,72(s1)
    80002faa:	fee49de3          	bne	s1,a4,80002fa4 <bread+0x86>
  panic("bget: no buffers");
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	5e250513          	addi	a0,a0,1506 # 80008590 <syscalls+0xd0>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	584080e7          	jalr	1412(ra) # 8000053a <panic>
      b->dev = dev;
    80002fbe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fc2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fc6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fca:	4785                	li	a5,1
    80002fcc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	11a50513          	addi	a0,a0,282 # 800170e8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	cae080e7          	jalr	-850(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002fde:	01048513          	addi	a0,s1,16
    80002fe2:	00001097          	auipc	ra,0x1
    80002fe6:	40e080e7          	jalr	1038(ra) # 800043f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fea:	409c                	lw	a5,0(s1)
    80002fec:	cb89                	beqz	a5,80002ffe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fee:	8526                	mv	a0,s1
    80002ff0:	70a2                	ld	ra,40(sp)
    80002ff2:	7402                	ld	s0,32(sp)
    80002ff4:	64e2                	ld	s1,24(sp)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	6145                	addi	sp,sp,48
    80002ffc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ffe:	4581                	li	a1,0
    80003000:	8526                	mv	a0,s1
    80003002:	00003097          	auipc	ra,0x3
    80003006:	f20080e7          	jalr	-224(ra) # 80005f22 <virtio_disk_rw>
    b->valid = 1;
    8000300a:	4785                	li	a5,1
    8000300c:	c09c                	sw	a5,0(s1)
  return b;
    8000300e:	b7c5                	j	80002fee <bread+0xd0>

0000000080003010 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	e426                	sd	s1,8(sp)
    80003018:	1000                	addi	s0,sp,32
    8000301a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000301c:	0541                	addi	a0,a0,16
    8000301e:	00001097          	auipc	ra,0x1
    80003022:	46c080e7          	jalr	1132(ra) # 8000448a <holdingsleep>
    80003026:	cd01                	beqz	a0,8000303e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003028:	4585                	li	a1,1
    8000302a:	8526                	mv	a0,s1
    8000302c:	00003097          	auipc	ra,0x3
    80003030:	ef6080e7          	jalr	-266(ra) # 80005f22 <virtio_disk_rw>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret
    panic("bwrite");
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	56a50513          	addi	a0,a0,1386 # 800085a8 <syscalls+0xe8>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	4f4080e7          	jalr	1268(ra) # 8000053a <panic>

000000008000304e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	e04a                	sd	s2,0(sp)
    80003058:	1000                	addi	s0,sp,32
    8000305a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000305c:	01050913          	addi	s2,a0,16
    80003060:	854a                	mv	a0,s2
    80003062:	00001097          	auipc	ra,0x1
    80003066:	428080e7          	jalr	1064(ra) # 8000448a <holdingsleep>
    8000306a:	c92d                	beqz	a0,800030dc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000306c:	854a                	mv	a0,s2
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	3d8080e7          	jalr	984(ra) # 80004446 <releasesleep>

  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	07250513          	addi	a0,a0,114 # 800170e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b52080e7          	jalr	-1198(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	37fd                	addiw	a5,a5,-1
    8000308a:	0007871b          	sext.w	a4,a5
    8000308e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003090:	eb05                	bnez	a4,800030c0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003092:	68bc                	ld	a5,80(s1)
    80003094:	64b8                	ld	a4,72(s1)
    80003096:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003098:	64bc                	ld	a5,72(s1)
    8000309a:	68b8                	ld	a4,80(s1)
    8000309c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000309e:	0001c797          	auipc	a5,0x1c
    800030a2:	04a78793          	addi	a5,a5,74 # 8001f0e8 <bcache+0x8000>
    800030a6:	2b87b703          	ld	a4,696(a5)
    800030aa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ac:	0001c717          	auipc	a4,0x1c
    800030b0:	2a470713          	addi	a4,a4,676 # 8001f350 <bcache+0x8268>
    800030b4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030b6:	2b87b703          	ld	a4,696(a5)
    800030ba:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030bc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	02850513          	addi	a0,a0,40 # 800170e8 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	bbc080e7          	jalr	-1092(ra) # 80000c84 <release>
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6902                	ld	s2,0(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("brelse");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	4d450513          	addi	a0,a0,1236 # 800085b0 <syscalls+0xf0>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	456080e7          	jalr	1110(ra) # 8000053a <panic>

00000000800030ec <bpin>:

void
bpin(struct buf *b) {
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	1000                	addi	s0,sp,32
    800030f6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	ff050513          	addi	a0,a0,-16 # 800170e8 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	ad0080e7          	jalr	-1328(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003108:	40bc                	lw	a5,64(s1)
    8000310a:	2785                	addiw	a5,a5,1
    8000310c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	fda50513          	addi	a0,a0,-38 # 800170e8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b6e080e7          	jalr	-1170(ra) # 80000c84 <release>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret

0000000080003128 <bunpin>:

void
bunpin(struct buf *b) {
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	e426                	sd	s1,8(sp)
    80003130:	1000                	addi	s0,sp,32
    80003132:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	fb450513          	addi	a0,a0,-76 # 800170e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	a94080e7          	jalr	-1388(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	37fd                	addiw	a5,a5,-1
    80003148:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	f9e50513          	addi	a0,a0,-98 # 800170e8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b32080e7          	jalr	-1230(ra) # 80000c84 <release>
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	64a2                	ld	s1,8(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret

0000000080003164 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	e04a                	sd	s2,0(sp)
    8000316e:	1000                	addi	s0,sp,32
    80003170:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003172:	00d5d59b          	srliw	a1,a1,0xd
    80003176:	0001c797          	auipc	a5,0x1c
    8000317a:	64e7a783          	lw	a5,1614(a5) # 8001f7c4 <sb+0x1c>
    8000317e:	9dbd                	addw	a1,a1,a5
    80003180:	00000097          	auipc	ra,0x0
    80003184:	d9e080e7          	jalr	-610(ra) # 80002f1e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003188:	0074f713          	andi	a4,s1,7
    8000318c:	4785                	li	a5,1
    8000318e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003192:	14ce                	slli	s1,s1,0x33
    80003194:	90d9                	srli	s1,s1,0x36
    80003196:	00950733          	add	a4,a0,s1
    8000319a:	05874703          	lbu	a4,88(a4)
    8000319e:	00e7f6b3          	and	a3,a5,a4
    800031a2:	c69d                	beqz	a3,800031d0 <bfree+0x6c>
    800031a4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031a6:	94aa                	add	s1,s1,a0
    800031a8:	fff7c793          	not	a5,a5
    800031ac:	8f7d                	and	a4,a4,a5
    800031ae:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031b2:	00001097          	auipc	ra,0x1
    800031b6:	120080e7          	jalr	288(ra) # 800042d2 <log_write>
  brelse(bp);
    800031ba:	854a                	mv	a0,s2
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	e92080e7          	jalr	-366(ra) # 8000304e <brelse>
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    panic("freeing free block");
    800031d0:	00005517          	auipc	a0,0x5
    800031d4:	3e850513          	addi	a0,a0,1000 # 800085b8 <syscalls+0xf8>
    800031d8:	ffffd097          	auipc	ra,0xffffd
    800031dc:	362080e7          	jalr	866(ra) # 8000053a <panic>

00000000800031e0 <balloc>:
{
    800031e0:	711d                	addi	sp,sp,-96
    800031e2:	ec86                	sd	ra,88(sp)
    800031e4:	e8a2                	sd	s0,80(sp)
    800031e6:	e4a6                	sd	s1,72(sp)
    800031e8:	e0ca                	sd	s2,64(sp)
    800031ea:	fc4e                	sd	s3,56(sp)
    800031ec:	f852                	sd	s4,48(sp)
    800031ee:	f456                	sd	s5,40(sp)
    800031f0:	f05a                	sd	s6,32(sp)
    800031f2:	ec5e                	sd	s7,24(sp)
    800031f4:	e862                	sd	s8,16(sp)
    800031f6:	e466                	sd	s9,8(sp)
    800031f8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031fa:	0001c797          	auipc	a5,0x1c
    800031fe:	5b27a783          	lw	a5,1458(a5) # 8001f7ac <sb+0x4>
    80003202:	cbc1                	beqz	a5,80003292 <balloc+0xb2>
    80003204:	8baa                	mv	s7,a0
    80003206:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003208:	0001cb17          	auipc	s6,0x1c
    8000320c:	5a0b0b13          	addi	s6,s6,1440 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003210:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003212:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003214:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003216:	6c89                	lui	s9,0x2
    80003218:	a831                	j	80003234 <balloc+0x54>
    brelse(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	e32080e7          	jalr	-462(ra) # 8000304e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003224:	015c87bb          	addw	a5,s9,s5
    80003228:	00078a9b          	sext.w	s5,a5
    8000322c:	004b2703          	lw	a4,4(s6)
    80003230:	06eaf163          	bgeu	s5,a4,80003292 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003234:	41fad79b          	sraiw	a5,s5,0x1f
    80003238:	0137d79b          	srliw	a5,a5,0x13
    8000323c:	015787bb          	addw	a5,a5,s5
    80003240:	40d7d79b          	sraiw	a5,a5,0xd
    80003244:	01cb2583          	lw	a1,28(s6)
    80003248:	9dbd                	addw	a1,a1,a5
    8000324a:	855e                	mv	a0,s7
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	cd2080e7          	jalr	-814(ra) # 80002f1e <bread>
    80003254:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003256:	004b2503          	lw	a0,4(s6)
    8000325a:	000a849b          	sext.w	s1,s5
    8000325e:	8762                	mv	a4,s8
    80003260:	faa4fde3          	bgeu	s1,a0,8000321a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003264:	00777693          	andi	a3,a4,7
    80003268:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000326c:	41f7579b          	sraiw	a5,a4,0x1f
    80003270:	01d7d79b          	srliw	a5,a5,0x1d
    80003274:	9fb9                	addw	a5,a5,a4
    80003276:	4037d79b          	sraiw	a5,a5,0x3
    8000327a:	00f90633          	add	a2,s2,a5
    8000327e:	05864603          	lbu	a2,88(a2)
    80003282:	00c6f5b3          	and	a1,a3,a2
    80003286:	cd91                	beqz	a1,800032a2 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	2705                	addiw	a4,a4,1
    8000328a:	2485                	addiw	s1,s1,1
    8000328c:	fd471ae3          	bne	a4,s4,80003260 <balloc+0x80>
    80003290:	b769                	j	8000321a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003292:	00005517          	auipc	a0,0x5
    80003296:	33e50513          	addi	a0,a0,830 # 800085d0 <syscalls+0x110>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2a0080e7          	jalr	672(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032a2:	97ca                	add	a5,a5,s2
    800032a4:	8e55                	or	a2,a2,a3
    800032a6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032aa:	854a                	mv	a0,s2
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	026080e7          	jalr	38(ra) # 800042d2 <log_write>
        brelse(bp);
    800032b4:	854a                	mv	a0,s2
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	d98080e7          	jalr	-616(ra) # 8000304e <brelse>
  bp = bread(dev, bno);
    800032be:	85a6                	mv	a1,s1
    800032c0:	855e                	mv	a0,s7
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	c5c080e7          	jalr	-932(ra) # 80002f1e <bread>
    800032ca:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032cc:	40000613          	li	a2,1024
    800032d0:	4581                	li	a1,0
    800032d2:	05850513          	addi	a0,a0,88
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	9f6080e7          	jalr	-1546(ra) # 80000ccc <memset>
  log_write(bp);
    800032de:	854a                	mv	a0,s2
    800032e0:	00001097          	auipc	ra,0x1
    800032e4:	ff2080e7          	jalr	-14(ra) # 800042d2 <log_write>
  brelse(bp);
    800032e8:	854a                	mv	a0,s2
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	d64080e7          	jalr	-668(ra) # 8000304e <brelse>
}
    800032f2:	8526                	mv	a0,s1
    800032f4:	60e6                	ld	ra,88(sp)
    800032f6:	6446                	ld	s0,80(sp)
    800032f8:	64a6                	ld	s1,72(sp)
    800032fa:	6906                	ld	s2,64(sp)
    800032fc:	79e2                	ld	s3,56(sp)
    800032fe:	7a42                	ld	s4,48(sp)
    80003300:	7aa2                	ld	s5,40(sp)
    80003302:	7b02                	ld	s6,32(sp)
    80003304:	6be2                	ld	s7,24(sp)
    80003306:	6c42                	ld	s8,16(sp)
    80003308:	6ca2                	ld	s9,8(sp)
    8000330a:	6125                	addi	sp,sp,96
    8000330c:	8082                	ret

000000008000330e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	e84a                	sd	s2,16(sp)
    80003318:	e44e                	sd	s3,8(sp)
    8000331a:	e052                	sd	s4,0(sp)
    8000331c:	1800                	addi	s0,sp,48
    8000331e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003320:	47ad                	li	a5,11
    80003322:	04b7fe63          	bgeu	a5,a1,8000337e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003326:	ff45849b          	addiw	s1,a1,-12
    8000332a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000332e:	0ff00793          	li	a5,255
    80003332:	0ae7e463          	bltu	a5,a4,800033da <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003336:	08052583          	lw	a1,128(a0)
    8000333a:	c5b5                	beqz	a1,800033a6 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000333c:	00092503          	lw	a0,0(s2)
    80003340:	00000097          	auipc	ra,0x0
    80003344:	bde080e7          	jalr	-1058(ra) # 80002f1e <bread>
    80003348:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000334a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000334e:	02049713          	slli	a4,s1,0x20
    80003352:	01e75593          	srli	a1,a4,0x1e
    80003356:	00b784b3          	add	s1,a5,a1
    8000335a:	0004a983          	lw	s3,0(s1)
    8000335e:	04098e63          	beqz	s3,800033ba <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003362:	8552                	mv	a0,s4
    80003364:	00000097          	auipc	ra,0x0
    80003368:	cea080e7          	jalr	-790(ra) # 8000304e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000336c:	854e                	mv	a0,s3
    8000336e:	70a2                	ld	ra,40(sp)
    80003370:	7402                	ld	s0,32(sp)
    80003372:	64e2                	ld	s1,24(sp)
    80003374:	6942                	ld	s2,16(sp)
    80003376:	69a2                	ld	s3,8(sp)
    80003378:	6a02                	ld	s4,0(sp)
    8000337a:	6145                	addi	sp,sp,48
    8000337c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000337e:	02059793          	slli	a5,a1,0x20
    80003382:	01e7d593          	srli	a1,a5,0x1e
    80003386:	00b504b3          	add	s1,a0,a1
    8000338a:	0504a983          	lw	s3,80(s1)
    8000338e:	fc099fe3          	bnez	s3,8000336c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003392:	4108                	lw	a0,0(a0)
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e4c080e7          	jalr	-436(ra) # 800031e0 <balloc>
    8000339c:	0005099b          	sext.w	s3,a0
    800033a0:	0534a823          	sw	s3,80(s1)
    800033a4:	b7e1                	j	8000336c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033a6:	4108                	lw	a0,0(a0)
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	e38080e7          	jalr	-456(ra) # 800031e0 <balloc>
    800033b0:	0005059b          	sext.w	a1,a0
    800033b4:	08b92023          	sw	a1,128(s2)
    800033b8:	b751                	j	8000333c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033ba:	00092503          	lw	a0,0(s2)
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	e22080e7          	jalr	-478(ra) # 800031e0 <balloc>
    800033c6:	0005099b          	sext.w	s3,a0
    800033ca:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ce:	8552                	mv	a0,s4
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	f02080e7          	jalr	-254(ra) # 800042d2 <log_write>
    800033d8:	b769                	j	80003362 <bmap+0x54>
  panic("bmap: out of range");
    800033da:	00005517          	auipc	a0,0x5
    800033de:	20e50513          	addi	a0,a0,526 # 800085e8 <syscalls+0x128>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	158080e7          	jalr	344(ra) # 8000053a <panic>

00000000800033ea <iget>:
{
    800033ea:	7179                	addi	sp,sp,-48
    800033ec:	f406                	sd	ra,40(sp)
    800033ee:	f022                	sd	s0,32(sp)
    800033f0:	ec26                	sd	s1,24(sp)
    800033f2:	e84a                	sd	s2,16(sp)
    800033f4:	e44e                	sd	s3,8(sp)
    800033f6:	e052                	sd	s4,0(sp)
    800033f8:	1800                	addi	s0,sp,48
    800033fa:	89aa                	mv	s3,a0
    800033fc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033fe:	0001c517          	auipc	a0,0x1c
    80003402:	3ca50513          	addi	a0,a0,970 # 8001f7c8 <itable>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	7ca080e7          	jalr	1994(ra) # 80000bd0 <acquire>
  empty = 0;
    8000340e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003410:	0001c497          	auipc	s1,0x1c
    80003414:	3d048493          	addi	s1,s1,976 # 8001f7e0 <itable+0x18>
    80003418:	0001e697          	auipc	a3,0x1e
    8000341c:	e5868693          	addi	a3,a3,-424 # 80021270 <log>
    80003420:	a039                	j	8000342e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003422:	02090b63          	beqz	s2,80003458 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003426:	08848493          	addi	s1,s1,136
    8000342a:	02d48a63          	beq	s1,a3,8000345e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000342e:	449c                	lw	a5,8(s1)
    80003430:	fef059e3          	blez	a5,80003422 <iget+0x38>
    80003434:	4098                	lw	a4,0(s1)
    80003436:	ff3716e3          	bne	a4,s3,80003422 <iget+0x38>
    8000343a:	40d8                	lw	a4,4(s1)
    8000343c:	ff4713e3          	bne	a4,s4,80003422 <iget+0x38>
      ip->ref++;
    80003440:	2785                	addiw	a5,a5,1
    80003442:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003444:	0001c517          	auipc	a0,0x1c
    80003448:	38450513          	addi	a0,a0,900 # 8001f7c8 <itable>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	838080e7          	jalr	-1992(ra) # 80000c84 <release>
      return ip;
    80003454:	8926                	mv	s2,s1
    80003456:	a03d                	j	80003484 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003458:	f7f9                	bnez	a5,80003426 <iget+0x3c>
    8000345a:	8926                	mv	s2,s1
    8000345c:	b7e9                	j	80003426 <iget+0x3c>
  if(empty == 0)
    8000345e:	02090c63          	beqz	s2,80003496 <iget+0xac>
  ip->dev = dev;
    80003462:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003466:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000346a:	4785                	li	a5,1
    8000346c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003470:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003474:	0001c517          	auipc	a0,0x1c
    80003478:	35450513          	addi	a0,a0,852 # 8001f7c8 <itable>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	808080e7          	jalr	-2040(ra) # 80000c84 <release>
}
    80003484:	854a                	mv	a0,s2
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	69a2                	ld	s3,8(sp)
    80003490:	6a02                	ld	s4,0(sp)
    80003492:	6145                	addi	sp,sp,48
    80003494:	8082                	ret
    panic("iget: no inodes");
    80003496:	00005517          	auipc	a0,0x5
    8000349a:	16a50513          	addi	a0,a0,362 # 80008600 <syscalls+0x140>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	09c080e7          	jalr	156(ra) # 8000053a <panic>

00000000800034a6 <fsinit>:
fsinit(int dev) {
    800034a6:	7179                	addi	sp,sp,-48
    800034a8:	f406                	sd	ra,40(sp)
    800034aa:	f022                	sd	s0,32(sp)
    800034ac:	ec26                	sd	s1,24(sp)
    800034ae:	e84a                	sd	s2,16(sp)
    800034b0:	e44e                	sd	s3,8(sp)
    800034b2:	1800                	addi	s0,sp,48
    800034b4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034b6:	4585                	li	a1,1
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	a66080e7          	jalr	-1434(ra) # 80002f1e <bread>
    800034c0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034c2:	0001c997          	auipc	s3,0x1c
    800034c6:	2e698993          	addi	s3,s3,742 # 8001f7a8 <sb>
    800034ca:	02000613          	li	a2,32
    800034ce:	05850593          	addi	a1,a0,88
    800034d2:	854e                	mv	a0,s3
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	854080e7          	jalr	-1964(ra) # 80000d28 <memmove>
  brelse(bp);
    800034dc:	8526                	mv	a0,s1
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	b70080e7          	jalr	-1168(ra) # 8000304e <brelse>
  if(sb.magic != FSMAGIC)
    800034e6:	0009a703          	lw	a4,0(s3)
    800034ea:	102037b7          	lui	a5,0x10203
    800034ee:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034f2:	02f71263          	bne	a4,a5,80003516 <fsinit+0x70>
  initlog(dev, &sb);
    800034f6:	0001c597          	auipc	a1,0x1c
    800034fa:	2b258593          	addi	a1,a1,690 # 8001f7a8 <sb>
    800034fe:	854a                	mv	a0,s2
    80003500:	00001097          	auipc	ra,0x1
    80003504:	b56080e7          	jalr	-1194(ra) # 80004056 <initlog>
}
    80003508:	70a2                	ld	ra,40(sp)
    8000350a:	7402                	ld	s0,32(sp)
    8000350c:	64e2                	ld	s1,24(sp)
    8000350e:	6942                	ld	s2,16(sp)
    80003510:	69a2                	ld	s3,8(sp)
    80003512:	6145                	addi	sp,sp,48
    80003514:	8082                	ret
    panic("invalid file system");
    80003516:	00005517          	auipc	a0,0x5
    8000351a:	0fa50513          	addi	a0,a0,250 # 80008610 <syscalls+0x150>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	01c080e7          	jalr	28(ra) # 8000053a <panic>

0000000080003526 <iinit>:
{
    80003526:	7179                	addi	sp,sp,-48
    80003528:	f406                	sd	ra,40(sp)
    8000352a:	f022                	sd	s0,32(sp)
    8000352c:	ec26                	sd	s1,24(sp)
    8000352e:	e84a                	sd	s2,16(sp)
    80003530:	e44e                	sd	s3,8(sp)
    80003532:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003534:	00005597          	auipc	a1,0x5
    80003538:	0f458593          	addi	a1,a1,244 # 80008628 <syscalls+0x168>
    8000353c:	0001c517          	auipc	a0,0x1c
    80003540:	28c50513          	addi	a0,a0,652 # 8001f7c8 <itable>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	5fc080e7          	jalr	1532(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000354c:	0001c497          	auipc	s1,0x1c
    80003550:	2a448493          	addi	s1,s1,676 # 8001f7f0 <itable+0x28>
    80003554:	0001e997          	auipc	s3,0x1e
    80003558:	d2c98993          	addi	s3,s3,-724 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000355c:	00005917          	auipc	s2,0x5
    80003560:	0d490913          	addi	s2,s2,212 # 80008630 <syscalls+0x170>
    80003564:	85ca                	mv	a1,s2
    80003566:	8526                	mv	a0,s1
    80003568:	00001097          	auipc	ra,0x1
    8000356c:	e4e080e7          	jalr	-434(ra) # 800043b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003570:	08848493          	addi	s1,s1,136
    80003574:	ff3498e3          	bne	s1,s3,80003564 <iinit+0x3e>
}
    80003578:	70a2                	ld	ra,40(sp)
    8000357a:	7402                	ld	s0,32(sp)
    8000357c:	64e2                	ld	s1,24(sp)
    8000357e:	6942                	ld	s2,16(sp)
    80003580:	69a2                	ld	s3,8(sp)
    80003582:	6145                	addi	sp,sp,48
    80003584:	8082                	ret

0000000080003586 <ialloc>:
{
    80003586:	715d                	addi	sp,sp,-80
    80003588:	e486                	sd	ra,72(sp)
    8000358a:	e0a2                	sd	s0,64(sp)
    8000358c:	fc26                	sd	s1,56(sp)
    8000358e:	f84a                	sd	s2,48(sp)
    80003590:	f44e                	sd	s3,40(sp)
    80003592:	f052                	sd	s4,32(sp)
    80003594:	ec56                	sd	s5,24(sp)
    80003596:	e85a                	sd	s6,16(sp)
    80003598:	e45e                	sd	s7,8(sp)
    8000359a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000359c:	0001c717          	auipc	a4,0x1c
    800035a0:	21872703          	lw	a4,536(a4) # 8001f7b4 <sb+0xc>
    800035a4:	4785                	li	a5,1
    800035a6:	04e7fa63          	bgeu	a5,a4,800035fa <ialloc+0x74>
    800035aa:	8aaa                	mv	s5,a0
    800035ac:	8bae                	mv	s7,a1
    800035ae:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b0:	0001ca17          	auipc	s4,0x1c
    800035b4:	1f8a0a13          	addi	s4,s4,504 # 8001f7a8 <sb>
    800035b8:	00048b1b          	sext.w	s6,s1
    800035bc:	0044d593          	srli	a1,s1,0x4
    800035c0:	018a2783          	lw	a5,24(s4)
    800035c4:	9dbd                	addw	a1,a1,a5
    800035c6:	8556                	mv	a0,s5
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	956080e7          	jalr	-1706(ra) # 80002f1e <bread>
    800035d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035d2:	05850993          	addi	s3,a0,88
    800035d6:	00f4f793          	andi	a5,s1,15
    800035da:	079a                	slli	a5,a5,0x6
    800035dc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035de:	00099783          	lh	a5,0(s3)
    800035e2:	c785                	beqz	a5,8000360a <ialloc+0x84>
    brelse(bp);
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	a6a080e7          	jalr	-1430(ra) # 8000304e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ec:	0485                	addi	s1,s1,1
    800035ee:	00ca2703          	lw	a4,12(s4)
    800035f2:	0004879b          	sext.w	a5,s1
    800035f6:	fce7e1e3          	bltu	a5,a4,800035b8 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035fa:	00005517          	auipc	a0,0x5
    800035fe:	03e50513          	addi	a0,a0,62 # 80008638 <syscalls+0x178>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	f38080e7          	jalr	-200(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    8000360a:	04000613          	li	a2,64
    8000360e:	4581                	li	a1,0
    80003610:	854e                	mv	a0,s3
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	6ba080e7          	jalr	1722(ra) # 80000ccc <memset>
      dip->type = type;
    8000361a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000361e:	854a                	mv	a0,s2
    80003620:	00001097          	auipc	ra,0x1
    80003624:	cb2080e7          	jalr	-846(ra) # 800042d2 <log_write>
      brelse(bp);
    80003628:	854a                	mv	a0,s2
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	a24080e7          	jalr	-1500(ra) # 8000304e <brelse>
      return iget(dev, inum);
    80003632:	85da                	mv	a1,s6
    80003634:	8556                	mv	a0,s5
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	db4080e7          	jalr	-588(ra) # 800033ea <iget>
}
    8000363e:	60a6                	ld	ra,72(sp)
    80003640:	6406                	ld	s0,64(sp)
    80003642:	74e2                	ld	s1,56(sp)
    80003644:	7942                	ld	s2,48(sp)
    80003646:	79a2                	ld	s3,40(sp)
    80003648:	7a02                	ld	s4,32(sp)
    8000364a:	6ae2                	ld	s5,24(sp)
    8000364c:	6b42                	ld	s6,16(sp)
    8000364e:	6ba2                	ld	s7,8(sp)
    80003650:	6161                	addi	sp,sp,80
    80003652:	8082                	ret

0000000080003654 <iupdate>:
{
    80003654:	1101                	addi	sp,sp,-32
    80003656:	ec06                	sd	ra,24(sp)
    80003658:	e822                	sd	s0,16(sp)
    8000365a:	e426                	sd	s1,8(sp)
    8000365c:	e04a                	sd	s2,0(sp)
    8000365e:	1000                	addi	s0,sp,32
    80003660:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003662:	415c                	lw	a5,4(a0)
    80003664:	0047d79b          	srliw	a5,a5,0x4
    80003668:	0001c597          	auipc	a1,0x1c
    8000366c:	1585a583          	lw	a1,344(a1) # 8001f7c0 <sb+0x18>
    80003670:	9dbd                	addw	a1,a1,a5
    80003672:	4108                	lw	a0,0(a0)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	8aa080e7          	jalr	-1878(ra) # 80002f1e <bread>
    8000367c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000367e:	05850793          	addi	a5,a0,88
    80003682:	40d8                	lw	a4,4(s1)
    80003684:	8b3d                	andi	a4,a4,15
    80003686:	071a                	slli	a4,a4,0x6
    80003688:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000368a:	04449703          	lh	a4,68(s1)
    8000368e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003692:	04649703          	lh	a4,70(s1)
    80003696:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000369a:	04849703          	lh	a4,72(s1)
    8000369e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036a2:	04a49703          	lh	a4,74(s1)
    800036a6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036aa:	44f8                	lw	a4,76(s1)
    800036ac:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ae:	03400613          	li	a2,52
    800036b2:	05048593          	addi	a1,s1,80
    800036b6:	00c78513          	addi	a0,a5,12
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	66e080e7          	jalr	1646(ra) # 80000d28 <memmove>
  log_write(bp);
    800036c2:	854a                	mv	a0,s2
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	c0e080e7          	jalr	-1010(ra) # 800042d2 <log_write>
  brelse(bp);
    800036cc:	854a                	mv	a0,s2
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	980080e7          	jalr	-1664(ra) # 8000304e <brelse>
}
    800036d6:	60e2                	ld	ra,24(sp)
    800036d8:	6442                	ld	s0,16(sp)
    800036da:	64a2                	ld	s1,8(sp)
    800036dc:	6902                	ld	s2,0(sp)
    800036de:	6105                	addi	sp,sp,32
    800036e0:	8082                	ret

00000000800036e2 <idup>:
{
    800036e2:	1101                	addi	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	1000                	addi	s0,sp,32
    800036ec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036ee:	0001c517          	auipc	a0,0x1c
    800036f2:	0da50513          	addi	a0,a0,218 # 8001f7c8 <itable>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	4da080e7          	jalr	1242(ra) # 80000bd0 <acquire>
  ip->ref++;
    800036fe:	449c                	lw	a5,8(s1)
    80003700:	2785                	addiw	a5,a5,1
    80003702:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003704:	0001c517          	auipc	a0,0x1c
    80003708:	0c450513          	addi	a0,a0,196 # 8001f7c8 <itable>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	578080e7          	jalr	1400(ra) # 80000c84 <release>
}
    80003714:	8526                	mv	a0,s1
    80003716:	60e2                	ld	ra,24(sp)
    80003718:	6442                	ld	s0,16(sp)
    8000371a:	64a2                	ld	s1,8(sp)
    8000371c:	6105                	addi	sp,sp,32
    8000371e:	8082                	ret

0000000080003720 <ilock>:
{
    80003720:	1101                	addi	sp,sp,-32
    80003722:	ec06                	sd	ra,24(sp)
    80003724:	e822                	sd	s0,16(sp)
    80003726:	e426                	sd	s1,8(sp)
    80003728:	e04a                	sd	s2,0(sp)
    8000372a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000372c:	c115                	beqz	a0,80003750 <ilock+0x30>
    8000372e:	84aa                	mv	s1,a0
    80003730:	451c                	lw	a5,8(a0)
    80003732:	00f05f63          	blez	a5,80003750 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003736:	0541                	addi	a0,a0,16
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	cb8080e7          	jalr	-840(ra) # 800043f0 <acquiresleep>
  if(ip->valid == 0){
    80003740:	40bc                	lw	a5,64(s1)
    80003742:	cf99                	beqz	a5,80003760 <ilock+0x40>
}
    80003744:	60e2                	ld	ra,24(sp)
    80003746:	6442                	ld	s0,16(sp)
    80003748:	64a2                	ld	s1,8(sp)
    8000374a:	6902                	ld	s2,0(sp)
    8000374c:	6105                	addi	sp,sp,32
    8000374e:	8082                	ret
    panic("ilock");
    80003750:	00005517          	auipc	a0,0x5
    80003754:	f0050513          	addi	a0,a0,-256 # 80008650 <syscalls+0x190>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	de2080e7          	jalr	-542(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003760:	40dc                	lw	a5,4(s1)
    80003762:	0047d79b          	srliw	a5,a5,0x4
    80003766:	0001c597          	auipc	a1,0x1c
    8000376a:	05a5a583          	lw	a1,90(a1) # 8001f7c0 <sb+0x18>
    8000376e:	9dbd                	addw	a1,a1,a5
    80003770:	4088                	lw	a0,0(s1)
    80003772:	fffff097          	auipc	ra,0xfffff
    80003776:	7ac080e7          	jalr	1964(ra) # 80002f1e <bread>
    8000377a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000377c:	05850593          	addi	a1,a0,88
    80003780:	40dc                	lw	a5,4(s1)
    80003782:	8bbd                	andi	a5,a5,15
    80003784:	079a                	slli	a5,a5,0x6
    80003786:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003788:	00059783          	lh	a5,0(a1)
    8000378c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003790:	00259783          	lh	a5,2(a1)
    80003794:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003798:	00459783          	lh	a5,4(a1)
    8000379c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a0:	00659783          	lh	a5,6(a1)
    800037a4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037a8:	459c                	lw	a5,8(a1)
    800037aa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ac:	03400613          	li	a2,52
    800037b0:	05b1                	addi	a1,a1,12
    800037b2:	05048513          	addi	a0,s1,80
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	572080e7          	jalr	1394(ra) # 80000d28 <memmove>
    brelse(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	88e080e7          	jalr	-1906(ra) # 8000304e <brelse>
    ip->valid = 1;
    800037c8:	4785                	li	a5,1
    800037ca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037cc:	04449783          	lh	a5,68(s1)
    800037d0:	fbb5                	bnez	a5,80003744 <ilock+0x24>
      panic("ilock: no type");
    800037d2:	00005517          	auipc	a0,0x5
    800037d6:	e8650513          	addi	a0,a0,-378 # 80008658 <syscalls+0x198>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	d60080e7          	jalr	-672(ra) # 8000053a <panic>

00000000800037e2 <iunlock>:
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	e04a                	sd	s2,0(sp)
    800037ec:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037ee:	c905                	beqz	a0,8000381e <iunlock+0x3c>
    800037f0:	84aa                	mv	s1,a0
    800037f2:	01050913          	addi	s2,a0,16
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	c92080e7          	jalr	-878(ra) # 8000448a <holdingsleep>
    80003800:	cd19                	beqz	a0,8000381e <iunlock+0x3c>
    80003802:	449c                	lw	a5,8(s1)
    80003804:	00f05d63          	blez	a5,8000381e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003808:	854a                	mv	a0,s2
    8000380a:	00001097          	auipc	ra,0x1
    8000380e:	c3c080e7          	jalr	-964(ra) # 80004446 <releasesleep>
}
    80003812:	60e2                	ld	ra,24(sp)
    80003814:	6442                	ld	s0,16(sp)
    80003816:	64a2                	ld	s1,8(sp)
    80003818:	6902                	ld	s2,0(sp)
    8000381a:	6105                	addi	sp,sp,32
    8000381c:	8082                	ret
    panic("iunlock");
    8000381e:	00005517          	auipc	a0,0x5
    80003822:	e4a50513          	addi	a0,a0,-438 # 80008668 <syscalls+0x1a8>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	d14080e7          	jalr	-748(ra) # 8000053a <panic>

000000008000382e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000382e:	7179                	addi	sp,sp,-48
    80003830:	f406                	sd	ra,40(sp)
    80003832:	f022                	sd	s0,32(sp)
    80003834:	ec26                	sd	s1,24(sp)
    80003836:	e84a                	sd	s2,16(sp)
    80003838:	e44e                	sd	s3,8(sp)
    8000383a:	e052                	sd	s4,0(sp)
    8000383c:	1800                	addi	s0,sp,48
    8000383e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003840:	05050493          	addi	s1,a0,80
    80003844:	08050913          	addi	s2,a0,128
    80003848:	a021                	j	80003850 <itrunc+0x22>
    8000384a:	0491                	addi	s1,s1,4
    8000384c:	01248d63          	beq	s1,s2,80003866 <itrunc+0x38>
    if(ip->addrs[i]){
    80003850:	408c                	lw	a1,0(s1)
    80003852:	dde5                	beqz	a1,8000384a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003854:	0009a503          	lw	a0,0(s3)
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	90c080e7          	jalr	-1780(ra) # 80003164 <bfree>
      ip->addrs[i] = 0;
    80003860:	0004a023          	sw	zero,0(s1)
    80003864:	b7dd                	j	8000384a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003866:	0809a583          	lw	a1,128(s3)
    8000386a:	e185                	bnez	a1,8000388a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000386c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003870:	854e                	mv	a0,s3
    80003872:	00000097          	auipc	ra,0x0
    80003876:	de2080e7          	jalr	-542(ra) # 80003654 <iupdate>
}
    8000387a:	70a2                	ld	ra,40(sp)
    8000387c:	7402                	ld	s0,32(sp)
    8000387e:	64e2                	ld	s1,24(sp)
    80003880:	6942                	ld	s2,16(sp)
    80003882:	69a2                	ld	s3,8(sp)
    80003884:	6a02                	ld	s4,0(sp)
    80003886:	6145                	addi	sp,sp,48
    80003888:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000388a:	0009a503          	lw	a0,0(s3)
    8000388e:	fffff097          	auipc	ra,0xfffff
    80003892:	690080e7          	jalr	1680(ra) # 80002f1e <bread>
    80003896:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003898:	05850493          	addi	s1,a0,88
    8000389c:	45850913          	addi	s2,a0,1112
    800038a0:	a021                	j	800038a8 <itrunc+0x7a>
    800038a2:	0491                	addi	s1,s1,4
    800038a4:	01248b63          	beq	s1,s2,800038ba <itrunc+0x8c>
      if(a[j])
    800038a8:	408c                	lw	a1,0(s1)
    800038aa:	dde5                	beqz	a1,800038a2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	8b4080e7          	jalr	-1868(ra) # 80003164 <bfree>
    800038b8:	b7ed                	j	800038a2 <itrunc+0x74>
    brelse(bp);
    800038ba:	8552                	mv	a0,s4
    800038bc:	fffff097          	auipc	ra,0xfffff
    800038c0:	792080e7          	jalr	1938(ra) # 8000304e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038c4:	0809a583          	lw	a1,128(s3)
    800038c8:	0009a503          	lw	a0,0(s3)
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	898080e7          	jalr	-1896(ra) # 80003164 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038d4:	0809a023          	sw	zero,128(s3)
    800038d8:	bf51                	j	8000386c <itrunc+0x3e>

00000000800038da <iput>:
{
    800038da:	1101                	addi	sp,sp,-32
    800038dc:	ec06                	sd	ra,24(sp)
    800038de:	e822                	sd	s0,16(sp)
    800038e0:	e426                	sd	s1,8(sp)
    800038e2:	e04a                	sd	s2,0(sp)
    800038e4:	1000                	addi	s0,sp,32
    800038e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038e8:	0001c517          	auipc	a0,0x1c
    800038ec:	ee050513          	addi	a0,a0,-288 # 8001f7c8 <itable>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	2e0080e7          	jalr	736(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038f8:	4498                	lw	a4,8(s1)
    800038fa:	4785                	li	a5,1
    800038fc:	02f70363          	beq	a4,a5,80003922 <iput+0x48>
  ip->ref--;
    80003900:	449c                	lw	a5,8(s1)
    80003902:	37fd                	addiw	a5,a5,-1
    80003904:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003906:	0001c517          	auipc	a0,0x1c
    8000390a:	ec250513          	addi	a0,a0,-318 # 8001f7c8 <itable>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	376080e7          	jalr	886(ra) # 80000c84 <release>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6902                	ld	s2,0(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003922:	40bc                	lw	a5,64(s1)
    80003924:	dff1                	beqz	a5,80003900 <iput+0x26>
    80003926:	04a49783          	lh	a5,74(s1)
    8000392a:	fbf9                	bnez	a5,80003900 <iput+0x26>
    acquiresleep(&ip->lock);
    8000392c:	01048913          	addi	s2,s1,16
    80003930:	854a                	mv	a0,s2
    80003932:	00001097          	auipc	ra,0x1
    80003936:	abe080e7          	jalr	-1346(ra) # 800043f0 <acquiresleep>
    release(&itable.lock);
    8000393a:	0001c517          	auipc	a0,0x1c
    8000393e:	e8e50513          	addi	a0,a0,-370 # 8001f7c8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	342080e7          	jalr	834(ra) # 80000c84 <release>
    itrunc(ip);
    8000394a:	8526                	mv	a0,s1
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	ee2080e7          	jalr	-286(ra) # 8000382e <itrunc>
    ip->type = 0;
    80003954:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003958:	8526                	mv	a0,s1
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	cfa080e7          	jalr	-774(ra) # 80003654 <iupdate>
    ip->valid = 0;
    80003962:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003966:	854a                	mv	a0,s2
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	ade080e7          	jalr	-1314(ra) # 80004446 <releasesleep>
    acquire(&itable.lock);
    80003970:	0001c517          	auipc	a0,0x1c
    80003974:	e5850513          	addi	a0,a0,-424 # 8001f7c8 <itable>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	258080e7          	jalr	600(ra) # 80000bd0 <acquire>
    80003980:	b741                	j	80003900 <iput+0x26>

0000000080003982 <iunlockput>:
{
    80003982:	1101                	addi	sp,sp,-32
    80003984:	ec06                	sd	ra,24(sp)
    80003986:	e822                	sd	s0,16(sp)
    80003988:	e426                	sd	s1,8(sp)
    8000398a:	1000                	addi	s0,sp,32
    8000398c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	e54080e7          	jalr	-428(ra) # 800037e2 <iunlock>
  iput(ip);
    80003996:	8526                	mv	a0,s1
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	f42080e7          	jalr	-190(ra) # 800038da <iput>
}
    800039a0:	60e2                	ld	ra,24(sp)
    800039a2:	6442                	ld	s0,16(sp)
    800039a4:	64a2                	ld	s1,8(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret

00000000800039aa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039aa:	1141                	addi	sp,sp,-16
    800039ac:	e422                	sd	s0,8(sp)
    800039ae:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b0:	411c                	lw	a5,0(a0)
    800039b2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039b4:	415c                	lw	a5,4(a0)
    800039b6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039b8:	04451783          	lh	a5,68(a0)
    800039bc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c0:	04a51783          	lh	a5,74(a0)
    800039c4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039c8:	04c56783          	lwu	a5,76(a0)
    800039cc:	e99c                	sd	a5,16(a1)
}
    800039ce:	6422                	ld	s0,8(sp)
    800039d0:	0141                	addi	sp,sp,16
    800039d2:	8082                	ret

00000000800039d4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039d4:	457c                	lw	a5,76(a0)
    800039d6:	0ed7e963          	bltu	a5,a3,80003ac8 <readi+0xf4>
{
    800039da:	7159                	addi	sp,sp,-112
    800039dc:	f486                	sd	ra,104(sp)
    800039de:	f0a2                	sd	s0,96(sp)
    800039e0:	eca6                	sd	s1,88(sp)
    800039e2:	e8ca                	sd	s2,80(sp)
    800039e4:	e4ce                	sd	s3,72(sp)
    800039e6:	e0d2                	sd	s4,64(sp)
    800039e8:	fc56                	sd	s5,56(sp)
    800039ea:	f85a                	sd	s6,48(sp)
    800039ec:	f45e                	sd	s7,40(sp)
    800039ee:	f062                	sd	s8,32(sp)
    800039f0:	ec66                	sd	s9,24(sp)
    800039f2:	e86a                	sd	s10,16(sp)
    800039f4:	e46e                	sd	s11,8(sp)
    800039f6:	1880                	addi	s0,sp,112
    800039f8:	8baa                	mv	s7,a0
    800039fa:	8c2e                	mv	s8,a1
    800039fc:	8ab2                	mv	s5,a2
    800039fe:	84b6                	mv	s1,a3
    80003a00:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a02:	9f35                	addw	a4,a4,a3
    return 0;
    80003a04:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a06:	0ad76063          	bltu	a4,a3,80003aa6 <readi+0xd2>
  if(off + n > ip->size)
    80003a0a:	00e7f463          	bgeu	a5,a4,80003a12 <readi+0x3e>
    n = ip->size - off;
    80003a0e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a12:	0a0b0963          	beqz	s6,80003ac4 <readi+0xf0>
    80003a16:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a18:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a1c:	5cfd                	li	s9,-1
    80003a1e:	a82d                	j	80003a58 <readi+0x84>
    80003a20:	020a1d93          	slli	s11,s4,0x20
    80003a24:	020ddd93          	srli	s11,s11,0x20
    80003a28:	05890613          	addi	a2,s2,88
    80003a2c:	86ee                	mv	a3,s11
    80003a2e:	963a                	add	a2,a2,a4
    80003a30:	85d6                	mv	a1,s5
    80003a32:	8562                	mv	a0,s8
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	af8080e7          	jalr	-1288(ra) # 8000252c <either_copyout>
    80003a3c:	05950d63          	beq	a0,s9,80003a96 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a40:	854a                	mv	a0,s2
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	60c080e7          	jalr	1548(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4a:	013a09bb          	addw	s3,s4,s3
    80003a4e:	009a04bb          	addw	s1,s4,s1
    80003a52:	9aee                	add	s5,s5,s11
    80003a54:	0569f763          	bgeu	s3,s6,80003aa2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a58:	000ba903          	lw	s2,0(s7)
    80003a5c:	00a4d59b          	srliw	a1,s1,0xa
    80003a60:	855e                	mv	a0,s7
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	8ac080e7          	jalr	-1876(ra) # 8000330e <bmap>
    80003a6a:	0005059b          	sext.w	a1,a0
    80003a6e:	854a                	mv	a0,s2
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	4ae080e7          	jalr	1198(ra) # 80002f1e <bread>
    80003a78:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7a:	3ff4f713          	andi	a4,s1,1023
    80003a7e:	40ed07bb          	subw	a5,s10,a4
    80003a82:	413b06bb          	subw	a3,s6,s3
    80003a86:	8a3e                	mv	s4,a5
    80003a88:	2781                	sext.w	a5,a5
    80003a8a:	0006861b          	sext.w	a2,a3
    80003a8e:	f8f679e3          	bgeu	a2,a5,80003a20 <readi+0x4c>
    80003a92:	8a36                	mv	s4,a3
    80003a94:	b771                	j	80003a20 <readi+0x4c>
      brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	5b6080e7          	jalr	1462(ra) # 8000304e <brelse>
      tot = -1;
    80003aa0:	59fd                	li	s3,-1
  }
  return tot;
    80003aa2:	0009851b          	sext.w	a0,s3
}
    80003aa6:	70a6                	ld	ra,104(sp)
    80003aa8:	7406                	ld	s0,96(sp)
    80003aaa:	64e6                	ld	s1,88(sp)
    80003aac:	6946                	ld	s2,80(sp)
    80003aae:	69a6                	ld	s3,72(sp)
    80003ab0:	6a06                	ld	s4,64(sp)
    80003ab2:	7ae2                	ld	s5,56(sp)
    80003ab4:	7b42                	ld	s6,48(sp)
    80003ab6:	7ba2                	ld	s7,40(sp)
    80003ab8:	7c02                	ld	s8,32(sp)
    80003aba:	6ce2                	ld	s9,24(sp)
    80003abc:	6d42                	ld	s10,16(sp)
    80003abe:	6da2                	ld	s11,8(sp)
    80003ac0:	6165                	addi	sp,sp,112
    80003ac2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac4:	89da                	mv	s3,s6
    80003ac6:	bff1                	j	80003aa2 <readi+0xce>
    return 0;
    80003ac8:	4501                	li	a0,0
}
    80003aca:	8082                	ret

0000000080003acc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003acc:	457c                	lw	a5,76(a0)
    80003ace:	10d7e863          	bltu	a5,a3,80003bde <writei+0x112>
{
    80003ad2:	7159                	addi	sp,sp,-112
    80003ad4:	f486                	sd	ra,104(sp)
    80003ad6:	f0a2                	sd	s0,96(sp)
    80003ad8:	eca6                	sd	s1,88(sp)
    80003ada:	e8ca                	sd	s2,80(sp)
    80003adc:	e4ce                	sd	s3,72(sp)
    80003ade:	e0d2                	sd	s4,64(sp)
    80003ae0:	fc56                	sd	s5,56(sp)
    80003ae2:	f85a                	sd	s6,48(sp)
    80003ae4:	f45e                	sd	s7,40(sp)
    80003ae6:	f062                	sd	s8,32(sp)
    80003ae8:	ec66                	sd	s9,24(sp)
    80003aea:	e86a                	sd	s10,16(sp)
    80003aec:	e46e                	sd	s11,8(sp)
    80003aee:	1880                	addi	s0,sp,112
    80003af0:	8b2a                	mv	s6,a0
    80003af2:	8c2e                	mv	s8,a1
    80003af4:	8ab2                	mv	s5,a2
    80003af6:	8936                	mv	s2,a3
    80003af8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003afa:	00e687bb          	addw	a5,a3,a4
    80003afe:	0ed7e263          	bltu	a5,a3,80003be2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b02:	00043737          	lui	a4,0x43
    80003b06:	0ef76063          	bltu	a4,a5,80003be6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b0a:	0c0b8863          	beqz	s7,80003bda <writei+0x10e>
    80003b0e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b10:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b14:	5cfd                	li	s9,-1
    80003b16:	a091                	j	80003b5a <writei+0x8e>
    80003b18:	02099d93          	slli	s11,s3,0x20
    80003b1c:	020ddd93          	srli	s11,s11,0x20
    80003b20:	05848513          	addi	a0,s1,88
    80003b24:	86ee                	mv	a3,s11
    80003b26:	8656                	mv	a2,s5
    80003b28:	85e2                	mv	a1,s8
    80003b2a:	953a                	add	a0,a0,a4
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	a56080e7          	jalr	-1450(ra) # 80002582 <either_copyin>
    80003b34:	07950263          	beq	a0,s9,80003b98 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	798080e7          	jalr	1944(ra) # 800042d2 <log_write>
    brelse(bp);
    80003b42:	8526                	mv	a0,s1
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	50a080e7          	jalr	1290(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b4c:	01498a3b          	addw	s4,s3,s4
    80003b50:	0129893b          	addw	s2,s3,s2
    80003b54:	9aee                	add	s5,s5,s11
    80003b56:	057a7663          	bgeu	s4,s7,80003ba2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b5a:	000b2483          	lw	s1,0(s6)
    80003b5e:	00a9559b          	srliw	a1,s2,0xa
    80003b62:	855a                	mv	a0,s6
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	7aa080e7          	jalr	1962(ra) # 8000330e <bmap>
    80003b6c:	0005059b          	sext.w	a1,a0
    80003b70:	8526                	mv	a0,s1
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	3ac080e7          	jalr	940(ra) # 80002f1e <bread>
    80003b7a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7c:	3ff97713          	andi	a4,s2,1023
    80003b80:	40ed07bb          	subw	a5,s10,a4
    80003b84:	414b86bb          	subw	a3,s7,s4
    80003b88:	89be                	mv	s3,a5
    80003b8a:	2781                	sext.w	a5,a5
    80003b8c:	0006861b          	sext.w	a2,a3
    80003b90:	f8f674e3          	bgeu	a2,a5,80003b18 <writei+0x4c>
    80003b94:	89b6                	mv	s3,a3
    80003b96:	b749                	j	80003b18 <writei+0x4c>
      brelse(bp);
    80003b98:	8526                	mv	a0,s1
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	4b4080e7          	jalr	1204(ra) # 8000304e <brelse>
  }

  if(off > ip->size)
    80003ba2:	04cb2783          	lw	a5,76(s6)
    80003ba6:	0127f463          	bgeu	a5,s2,80003bae <writei+0xe2>
    ip->size = off;
    80003baa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bae:	855a                	mv	a0,s6
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	aa4080e7          	jalr	-1372(ra) # 80003654 <iupdate>

  return tot;
    80003bb8:	000a051b          	sext.w	a0,s4
}
    80003bbc:	70a6                	ld	ra,104(sp)
    80003bbe:	7406                	ld	s0,96(sp)
    80003bc0:	64e6                	ld	s1,88(sp)
    80003bc2:	6946                	ld	s2,80(sp)
    80003bc4:	69a6                	ld	s3,72(sp)
    80003bc6:	6a06                	ld	s4,64(sp)
    80003bc8:	7ae2                	ld	s5,56(sp)
    80003bca:	7b42                	ld	s6,48(sp)
    80003bcc:	7ba2                	ld	s7,40(sp)
    80003bce:	7c02                	ld	s8,32(sp)
    80003bd0:	6ce2                	ld	s9,24(sp)
    80003bd2:	6d42                	ld	s10,16(sp)
    80003bd4:	6da2                	ld	s11,8(sp)
    80003bd6:	6165                	addi	sp,sp,112
    80003bd8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bda:	8a5e                	mv	s4,s7
    80003bdc:	bfc9                	j	80003bae <writei+0xe2>
    return -1;
    80003bde:	557d                	li	a0,-1
}
    80003be0:	8082                	ret
    return -1;
    80003be2:	557d                	li	a0,-1
    80003be4:	bfe1                	j	80003bbc <writei+0xf0>
    return -1;
    80003be6:	557d                	li	a0,-1
    80003be8:	bfd1                	j	80003bbc <writei+0xf0>

0000000080003bea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bea:	1141                	addi	sp,sp,-16
    80003bec:	e406                	sd	ra,8(sp)
    80003bee:	e022                	sd	s0,0(sp)
    80003bf0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bf2:	4639                	li	a2,14
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	1a8080e7          	jalr	424(ra) # 80000d9c <strncmp>
}
    80003bfc:	60a2                	ld	ra,8(sp)
    80003bfe:	6402                	ld	s0,0(sp)
    80003c00:	0141                	addi	sp,sp,16
    80003c02:	8082                	ret

0000000080003c04 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c04:	7139                	addi	sp,sp,-64
    80003c06:	fc06                	sd	ra,56(sp)
    80003c08:	f822                	sd	s0,48(sp)
    80003c0a:	f426                	sd	s1,40(sp)
    80003c0c:	f04a                	sd	s2,32(sp)
    80003c0e:	ec4e                	sd	s3,24(sp)
    80003c10:	e852                	sd	s4,16(sp)
    80003c12:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c14:	04451703          	lh	a4,68(a0)
    80003c18:	4785                	li	a5,1
    80003c1a:	00f71a63          	bne	a4,a5,80003c2e <dirlookup+0x2a>
    80003c1e:	892a                	mv	s2,a0
    80003c20:	89ae                	mv	s3,a1
    80003c22:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c24:	457c                	lw	a5,76(a0)
    80003c26:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c28:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2a:	e79d                	bnez	a5,80003c58 <dirlookup+0x54>
    80003c2c:	a8a5                	j	80003ca4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	a4250513          	addi	a0,a0,-1470 # 80008670 <syscalls+0x1b0>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	904080e7          	jalr	-1788(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	a4a50513          	addi	a0,a0,-1462 # 80008688 <syscalls+0x1c8>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f4080e7          	jalr	-1804(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4e:	24c1                	addiw	s1,s1,16
    80003c50:	04c92783          	lw	a5,76(s2)
    80003c54:	04f4f763          	bgeu	s1,a5,80003ca2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c58:	4741                	li	a4,16
    80003c5a:	86a6                	mv	a3,s1
    80003c5c:	fc040613          	addi	a2,s0,-64
    80003c60:	4581                	li	a1,0
    80003c62:	854a                	mv	a0,s2
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	d70080e7          	jalr	-656(ra) # 800039d4 <readi>
    80003c6c:	47c1                	li	a5,16
    80003c6e:	fcf518e3          	bne	a0,a5,80003c3e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c72:	fc045783          	lhu	a5,-64(s0)
    80003c76:	dfe1                	beqz	a5,80003c4e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c78:	fc240593          	addi	a1,s0,-62
    80003c7c:	854e                	mv	a0,s3
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	f6c080e7          	jalr	-148(ra) # 80003bea <namecmp>
    80003c86:	f561                	bnez	a0,80003c4e <dirlookup+0x4a>
      if(poff)
    80003c88:	000a0463          	beqz	s4,80003c90 <dirlookup+0x8c>
        *poff = off;
    80003c8c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c90:	fc045583          	lhu	a1,-64(s0)
    80003c94:	00092503          	lw	a0,0(s2)
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	752080e7          	jalr	1874(ra) # 800033ea <iget>
    80003ca0:	a011                	j	80003ca4 <dirlookup+0xa0>
  return 0;
    80003ca2:	4501                	li	a0,0
}
    80003ca4:	70e2                	ld	ra,56(sp)
    80003ca6:	7442                	ld	s0,48(sp)
    80003ca8:	74a2                	ld	s1,40(sp)
    80003caa:	7902                	ld	s2,32(sp)
    80003cac:	69e2                	ld	s3,24(sp)
    80003cae:	6a42                	ld	s4,16(sp)
    80003cb0:	6121                	addi	sp,sp,64
    80003cb2:	8082                	ret

0000000080003cb4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cb4:	711d                	addi	sp,sp,-96
    80003cb6:	ec86                	sd	ra,88(sp)
    80003cb8:	e8a2                	sd	s0,80(sp)
    80003cba:	e4a6                	sd	s1,72(sp)
    80003cbc:	e0ca                	sd	s2,64(sp)
    80003cbe:	fc4e                	sd	s3,56(sp)
    80003cc0:	f852                	sd	s4,48(sp)
    80003cc2:	f456                	sd	s5,40(sp)
    80003cc4:	f05a                	sd	s6,32(sp)
    80003cc6:	ec5e                	sd	s7,24(sp)
    80003cc8:	e862                	sd	s8,16(sp)
    80003cca:	e466                	sd	s9,8(sp)
    80003ccc:	e06a                	sd	s10,0(sp)
    80003cce:	1080                	addi	s0,sp,96
    80003cd0:	84aa                	mv	s1,a0
    80003cd2:	8b2e                	mv	s6,a1
    80003cd4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cd6:	00054703          	lbu	a4,0(a0)
    80003cda:	02f00793          	li	a5,47
    80003cde:	02f70363          	beq	a4,a5,80003d04 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce2:	ffffe097          	auipc	ra,0xffffe
    80003ce6:	de2080e7          	jalr	-542(ra) # 80001ac4 <myproc>
    80003cea:	15053503          	ld	a0,336(a0)
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	9f4080e7          	jalr	-1548(ra) # 800036e2 <idup>
    80003cf6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cf8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cfc:	4cb5                	li	s9,13
  len = path - s;
    80003cfe:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d00:	4c05                	li	s8,1
    80003d02:	a87d                	j	80003dc0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d04:	4585                	li	a1,1
    80003d06:	4505                	li	a0,1
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	6e2080e7          	jalr	1762(ra) # 800033ea <iget>
    80003d10:	8a2a                	mv	s4,a0
    80003d12:	b7dd                	j	80003cf8 <namex+0x44>
      iunlockput(ip);
    80003d14:	8552                	mv	a0,s4
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	c6c080e7          	jalr	-916(ra) # 80003982 <iunlockput>
      return 0;
    80003d1e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d20:	8552                	mv	a0,s4
    80003d22:	60e6                	ld	ra,88(sp)
    80003d24:	6446                	ld	s0,80(sp)
    80003d26:	64a6                	ld	s1,72(sp)
    80003d28:	6906                	ld	s2,64(sp)
    80003d2a:	79e2                	ld	s3,56(sp)
    80003d2c:	7a42                	ld	s4,48(sp)
    80003d2e:	7aa2                	ld	s5,40(sp)
    80003d30:	7b02                	ld	s6,32(sp)
    80003d32:	6be2                	ld	s7,24(sp)
    80003d34:	6c42                	ld	s8,16(sp)
    80003d36:	6ca2                	ld	s9,8(sp)
    80003d38:	6d02                	ld	s10,0(sp)
    80003d3a:	6125                	addi	sp,sp,96
    80003d3c:	8082                	ret
      iunlock(ip);
    80003d3e:	8552                	mv	a0,s4
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	aa2080e7          	jalr	-1374(ra) # 800037e2 <iunlock>
      return ip;
    80003d48:	bfe1                	j	80003d20 <namex+0x6c>
      iunlockput(ip);
    80003d4a:	8552                	mv	a0,s4
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	c36080e7          	jalr	-970(ra) # 80003982 <iunlockput>
      return 0;
    80003d54:	8a4e                	mv	s4,s3
    80003d56:	b7e9                	j	80003d20 <namex+0x6c>
  len = path - s;
    80003d58:	40998633          	sub	a2,s3,s1
    80003d5c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d60:	09acd863          	bge	s9,s10,80003df0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d64:	4639                	li	a2,14
    80003d66:	85a6                	mv	a1,s1
    80003d68:	8556                	mv	a0,s5
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	fbe080e7          	jalr	-66(ra) # 80000d28 <memmove>
    80003d72:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d74:	0004c783          	lbu	a5,0(s1)
    80003d78:	01279763          	bne	a5,s2,80003d86 <namex+0xd2>
    path++;
    80003d7c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d7e:	0004c783          	lbu	a5,0(s1)
    80003d82:	ff278de3          	beq	a5,s2,80003d7c <namex+0xc8>
    ilock(ip);
    80003d86:	8552                	mv	a0,s4
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	998080e7          	jalr	-1640(ra) # 80003720 <ilock>
    if(ip->type != T_DIR){
    80003d90:	044a1783          	lh	a5,68(s4)
    80003d94:	f98790e3          	bne	a5,s8,80003d14 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d98:	000b0563          	beqz	s6,80003da2 <namex+0xee>
    80003d9c:	0004c783          	lbu	a5,0(s1)
    80003da0:	dfd9                	beqz	a5,80003d3e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003da2:	865e                	mv	a2,s7
    80003da4:	85d6                	mv	a1,s5
    80003da6:	8552                	mv	a0,s4
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	e5c080e7          	jalr	-420(ra) # 80003c04 <dirlookup>
    80003db0:	89aa                	mv	s3,a0
    80003db2:	dd41                	beqz	a0,80003d4a <namex+0x96>
    iunlockput(ip);
    80003db4:	8552                	mv	a0,s4
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	bcc080e7          	jalr	-1076(ra) # 80003982 <iunlockput>
    ip = next;
    80003dbe:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	01279763          	bne	a5,s2,80003dd2 <namex+0x11e>
    path++;
    80003dc8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dca:	0004c783          	lbu	a5,0(s1)
    80003dce:	ff278de3          	beq	a5,s2,80003dc8 <namex+0x114>
  if(*path == 0)
    80003dd2:	cb9d                	beqz	a5,80003e08 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003dd4:	0004c783          	lbu	a5,0(s1)
    80003dd8:	89a6                	mv	s3,s1
  len = path - s;
    80003dda:	8d5e                	mv	s10,s7
    80003ddc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dde:	01278963          	beq	a5,s2,80003df0 <namex+0x13c>
    80003de2:	dbbd                	beqz	a5,80003d58 <namex+0xa4>
    path++;
    80003de4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003de6:	0009c783          	lbu	a5,0(s3)
    80003dea:	ff279ce3          	bne	a5,s2,80003de2 <namex+0x12e>
    80003dee:	b7ad                	j	80003d58 <namex+0xa4>
    memmove(name, s, len);
    80003df0:	2601                	sext.w	a2,a2
    80003df2:	85a6                	mv	a1,s1
    80003df4:	8556                	mv	a0,s5
    80003df6:	ffffd097          	auipc	ra,0xffffd
    80003dfa:	f32080e7          	jalr	-206(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003dfe:	9d56                	add	s10,s10,s5
    80003e00:	000d0023          	sb	zero,0(s10)
    80003e04:	84ce                	mv	s1,s3
    80003e06:	b7bd                	j	80003d74 <namex+0xc0>
  if(nameiparent){
    80003e08:	f00b0ce3          	beqz	s6,80003d20 <namex+0x6c>
    iput(ip);
    80003e0c:	8552                	mv	a0,s4
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	acc080e7          	jalr	-1332(ra) # 800038da <iput>
    return 0;
    80003e16:	4a01                	li	s4,0
    80003e18:	b721                	j	80003d20 <namex+0x6c>

0000000080003e1a <dirlink>:
{
    80003e1a:	7139                	addi	sp,sp,-64
    80003e1c:	fc06                	sd	ra,56(sp)
    80003e1e:	f822                	sd	s0,48(sp)
    80003e20:	f426                	sd	s1,40(sp)
    80003e22:	f04a                	sd	s2,32(sp)
    80003e24:	ec4e                	sd	s3,24(sp)
    80003e26:	e852                	sd	s4,16(sp)
    80003e28:	0080                	addi	s0,sp,64
    80003e2a:	892a                	mv	s2,a0
    80003e2c:	8a2e                	mv	s4,a1
    80003e2e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e30:	4601                	li	a2,0
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	dd2080e7          	jalr	-558(ra) # 80003c04 <dirlookup>
    80003e3a:	e93d                	bnez	a0,80003eb0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3c:	04c92483          	lw	s1,76(s2)
    80003e40:	c49d                	beqz	s1,80003e6e <dirlink+0x54>
    80003e42:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e44:	4741                	li	a4,16
    80003e46:	86a6                	mv	a3,s1
    80003e48:	fc040613          	addi	a2,s0,-64
    80003e4c:	4581                	li	a1,0
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	b84080e7          	jalr	-1148(ra) # 800039d4 <readi>
    80003e58:	47c1                	li	a5,16
    80003e5a:	06f51163          	bne	a0,a5,80003ebc <dirlink+0xa2>
    if(de.inum == 0)
    80003e5e:	fc045783          	lhu	a5,-64(s0)
    80003e62:	c791                	beqz	a5,80003e6e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e64:	24c1                	addiw	s1,s1,16
    80003e66:	04c92783          	lw	a5,76(s2)
    80003e6a:	fcf4ede3          	bltu	s1,a5,80003e44 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e6e:	4639                	li	a2,14
    80003e70:	85d2                	mv	a1,s4
    80003e72:	fc240513          	addi	a0,s0,-62
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	f62080e7          	jalr	-158(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003e7e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e82:	4741                	li	a4,16
    80003e84:	86a6                	mv	a3,s1
    80003e86:	fc040613          	addi	a2,s0,-64
    80003e8a:	4581                	li	a1,0
    80003e8c:	854a                	mv	a0,s2
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	c3e080e7          	jalr	-962(ra) # 80003acc <writei>
    80003e96:	872a                	mv	a4,a0
    80003e98:	47c1                	li	a5,16
  return 0;
    80003e9a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9c:	02f71863          	bne	a4,a5,80003ecc <dirlink+0xb2>
}
    80003ea0:	70e2                	ld	ra,56(sp)
    80003ea2:	7442                	ld	s0,48(sp)
    80003ea4:	74a2                	ld	s1,40(sp)
    80003ea6:	7902                	ld	s2,32(sp)
    80003ea8:	69e2                	ld	s3,24(sp)
    80003eaa:	6a42                	ld	s4,16(sp)
    80003eac:	6121                	addi	sp,sp,64
    80003eae:	8082                	ret
    iput(ip);
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	a2a080e7          	jalr	-1494(ra) # 800038da <iput>
    return -1;
    80003eb8:	557d                	li	a0,-1
    80003eba:	b7dd                	j	80003ea0 <dirlink+0x86>
      panic("dirlink read");
    80003ebc:	00004517          	auipc	a0,0x4
    80003ec0:	7dc50513          	addi	a0,a0,2012 # 80008698 <syscalls+0x1d8>
    80003ec4:	ffffc097          	auipc	ra,0xffffc
    80003ec8:	676080e7          	jalr	1654(ra) # 8000053a <panic>
    panic("dirlink");
    80003ecc:	00005517          	auipc	a0,0x5
    80003ed0:	8dc50513          	addi	a0,a0,-1828 # 800087a8 <syscalls+0x2e8>
    80003ed4:	ffffc097          	auipc	ra,0xffffc
    80003ed8:	666080e7          	jalr	1638(ra) # 8000053a <panic>

0000000080003edc <namei>:

struct inode*
namei(char *path)
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee4:	fe040613          	addi	a2,s0,-32
    80003ee8:	4581                	li	a1,0
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	dca080e7          	jalr	-566(ra) # 80003cb4 <namex>
}
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	6105                	addi	sp,sp,32
    80003ef8:	8082                	ret

0000000080003efa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003efa:	1141                	addi	sp,sp,-16
    80003efc:	e406                	sd	ra,8(sp)
    80003efe:	e022                	sd	s0,0(sp)
    80003f00:	0800                	addi	s0,sp,16
    80003f02:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f04:	4585                	li	a1,1
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	dae080e7          	jalr	-594(ra) # 80003cb4 <namex>
}
    80003f0e:	60a2                	ld	ra,8(sp)
    80003f10:	6402                	ld	s0,0(sp)
    80003f12:	0141                	addi	sp,sp,16
    80003f14:	8082                	ret

0000000080003f16 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f16:	1101                	addi	sp,sp,-32
    80003f18:	ec06                	sd	ra,24(sp)
    80003f1a:	e822                	sd	s0,16(sp)
    80003f1c:	e426                	sd	s1,8(sp)
    80003f1e:	e04a                	sd	s2,0(sp)
    80003f20:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f22:	0001d917          	auipc	s2,0x1d
    80003f26:	34e90913          	addi	s2,s2,846 # 80021270 <log>
    80003f2a:	01892583          	lw	a1,24(s2)
    80003f2e:	02892503          	lw	a0,40(s2)
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	fec080e7          	jalr	-20(ra) # 80002f1e <bread>
    80003f3a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f3c:	02c92683          	lw	a3,44(s2)
    80003f40:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f42:	02d05863          	blez	a3,80003f72 <write_head+0x5c>
    80003f46:	0001d797          	auipc	a5,0x1d
    80003f4a:	35a78793          	addi	a5,a5,858 # 800212a0 <log+0x30>
    80003f4e:	05c50713          	addi	a4,a0,92
    80003f52:	36fd                	addiw	a3,a3,-1
    80003f54:	02069613          	slli	a2,a3,0x20
    80003f58:	01e65693          	srli	a3,a2,0x1e
    80003f5c:	0001d617          	auipc	a2,0x1d
    80003f60:	34860613          	addi	a2,a2,840 # 800212a4 <log+0x34>
    80003f64:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f66:	4390                	lw	a2,0(a5)
    80003f68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f6a:	0791                	addi	a5,a5,4
    80003f6c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f6e:	fed79ce3          	bne	a5,a3,80003f66 <write_head+0x50>
  }
  bwrite(buf);
    80003f72:	8526                	mv	a0,s1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	09c080e7          	jalr	156(ra) # 80003010 <bwrite>
  brelse(buf);
    80003f7c:	8526                	mv	a0,s1
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	0d0080e7          	jalr	208(ra) # 8000304e <brelse>
}
    80003f86:	60e2                	ld	ra,24(sp)
    80003f88:	6442                	ld	s0,16(sp)
    80003f8a:	64a2                	ld	s1,8(sp)
    80003f8c:	6902                	ld	s2,0(sp)
    80003f8e:	6105                	addi	sp,sp,32
    80003f90:	8082                	ret

0000000080003f92 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f92:	0001d797          	auipc	a5,0x1d
    80003f96:	30a7a783          	lw	a5,778(a5) # 8002129c <log+0x2c>
    80003f9a:	0af05d63          	blez	a5,80004054 <install_trans+0xc2>
{
    80003f9e:	7139                	addi	sp,sp,-64
    80003fa0:	fc06                	sd	ra,56(sp)
    80003fa2:	f822                	sd	s0,48(sp)
    80003fa4:	f426                	sd	s1,40(sp)
    80003fa6:	f04a                	sd	s2,32(sp)
    80003fa8:	ec4e                	sd	s3,24(sp)
    80003faa:	e852                	sd	s4,16(sp)
    80003fac:	e456                	sd	s5,8(sp)
    80003fae:	e05a                	sd	s6,0(sp)
    80003fb0:	0080                	addi	s0,sp,64
    80003fb2:	8b2a                	mv	s6,a0
    80003fb4:	0001da97          	auipc	s5,0x1d
    80003fb8:	2eca8a93          	addi	s5,s5,748 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fbc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fbe:	0001d997          	auipc	s3,0x1d
    80003fc2:	2b298993          	addi	s3,s3,690 # 80021270 <log>
    80003fc6:	a00d                	j	80003fe8 <install_trans+0x56>
    brelse(lbuf);
    80003fc8:	854a                	mv	a0,s2
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	084080e7          	jalr	132(ra) # 8000304e <brelse>
    brelse(dbuf);
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	07a080e7          	jalr	122(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	2a05                	addiw	s4,s4,1
    80003fde:	0a91                	addi	s5,s5,4
    80003fe0:	02c9a783          	lw	a5,44(s3)
    80003fe4:	04fa5e63          	bge	s4,a5,80004040 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fe8:	0189a583          	lw	a1,24(s3)
    80003fec:	014585bb          	addw	a1,a1,s4
    80003ff0:	2585                	addiw	a1,a1,1
    80003ff2:	0289a503          	lw	a0,40(s3)
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	f28080e7          	jalr	-216(ra) # 80002f1e <bread>
    80003ffe:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004000:	000aa583          	lw	a1,0(s5)
    80004004:	0289a503          	lw	a0,40(s3)
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	f16080e7          	jalr	-234(ra) # 80002f1e <bread>
    80004010:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004012:	40000613          	li	a2,1024
    80004016:	05890593          	addi	a1,s2,88
    8000401a:	05850513          	addi	a0,a0,88
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	d0a080e7          	jalr	-758(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004026:	8526                	mv	a0,s1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	fe8080e7          	jalr	-24(ra) # 80003010 <bwrite>
    if(recovering == 0)
    80004030:	f80b1ce3          	bnez	s6,80003fc8 <install_trans+0x36>
      bunpin(dbuf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	0f2080e7          	jalr	242(ra) # 80003128 <bunpin>
    8000403e:	b769                	j	80003fc8 <install_trans+0x36>
}
    80004040:	70e2                	ld	ra,56(sp)
    80004042:	7442                	ld	s0,48(sp)
    80004044:	74a2                	ld	s1,40(sp)
    80004046:	7902                	ld	s2,32(sp)
    80004048:	69e2                	ld	s3,24(sp)
    8000404a:	6a42                	ld	s4,16(sp)
    8000404c:	6aa2                	ld	s5,8(sp)
    8000404e:	6b02                	ld	s6,0(sp)
    80004050:	6121                	addi	sp,sp,64
    80004052:	8082                	ret
    80004054:	8082                	ret

0000000080004056 <initlog>:
{
    80004056:	7179                	addi	sp,sp,-48
    80004058:	f406                	sd	ra,40(sp)
    8000405a:	f022                	sd	s0,32(sp)
    8000405c:	ec26                	sd	s1,24(sp)
    8000405e:	e84a                	sd	s2,16(sp)
    80004060:	e44e                	sd	s3,8(sp)
    80004062:	1800                	addi	s0,sp,48
    80004064:	892a                	mv	s2,a0
    80004066:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004068:	0001d497          	auipc	s1,0x1d
    8000406c:	20848493          	addi	s1,s1,520 # 80021270 <log>
    80004070:	00004597          	auipc	a1,0x4
    80004074:	63858593          	addi	a1,a1,1592 # 800086a8 <syscalls+0x1e8>
    80004078:	8526                	mv	a0,s1
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	ac6080e7          	jalr	-1338(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004082:	0149a583          	lw	a1,20(s3)
    80004086:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004088:	0109a783          	lw	a5,16(s3)
    8000408c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004092:	854a                	mv	a0,s2
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	e8a080e7          	jalr	-374(ra) # 80002f1e <bread>
  log.lh.n = lh->n;
    8000409c:	4d34                	lw	a3,88(a0)
    8000409e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	02d05663          	blez	a3,800040cc <initlog+0x76>
    800040a4:	05c50793          	addi	a5,a0,92
    800040a8:	0001d717          	auipc	a4,0x1d
    800040ac:	1f870713          	addi	a4,a4,504 # 800212a0 <log+0x30>
    800040b0:	36fd                	addiw	a3,a3,-1
    800040b2:	02069613          	slli	a2,a3,0x20
    800040b6:	01e65693          	srli	a3,a2,0x1e
    800040ba:	06050613          	addi	a2,a0,96
    800040be:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040c0:	4390                	lw	a2,0(a5)
    800040c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c4:	0791                	addi	a5,a5,4
    800040c6:	0711                	addi	a4,a4,4
    800040c8:	fed79ce3          	bne	a5,a3,800040c0 <initlog+0x6a>
  brelse(buf);
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	f82080e7          	jalr	-126(ra) # 8000304e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040d4:	4505                	li	a0,1
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	ebc080e7          	jalr	-324(ra) # 80003f92 <install_trans>
  log.lh.n = 0;
    800040de:	0001d797          	auipc	a5,0x1d
    800040e2:	1a07af23          	sw	zero,446(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	e30080e7          	jalr	-464(ra) # 80003f16 <write_head>
}
    800040ee:	70a2                	ld	ra,40(sp)
    800040f0:	7402                	ld	s0,32(sp)
    800040f2:	64e2                	ld	s1,24(sp)
    800040f4:	6942                	ld	s2,16(sp)
    800040f6:	69a2                	ld	s3,8(sp)
    800040f8:	6145                	addi	sp,sp,48
    800040fa:	8082                	ret

00000000800040fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040fc:	1101                	addi	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	e426                	sd	s1,8(sp)
    80004104:	e04a                	sd	s2,0(sp)
    80004106:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004108:	0001d517          	auipc	a0,0x1d
    8000410c:	16850513          	addi	a0,a0,360 # 80021270 <log>
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	ac0080e7          	jalr	-1344(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004118:	0001d497          	auipc	s1,0x1d
    8000411c:	15848493          	addi	s1,s1,344 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004120:	4979                	li	s2,30
    80004122:	a039                	j	80004130 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004124:	85a6                	mv	a1,s1
    80004126:	8526                	mv	a0,s1
    80004128:	ffffe097          	auipc	ra,0xffffe
    8000412c:	060080e7          	jalr	96(ra) # 80002188 <sleep>
    if(log.committing){
    80004130:	50dc                	lw	a5,36(s1)
    80004132:	fbed                	bnez	a5,80004124 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004134:	5098                	lw	a4,32(s1)
    80004136:	2705                	addiw	a4,a4,1
    80004138:	0007069b          	sext.w	a3,a4
    8000413c:	0027179b          	slliw	a5,a4,0x2
    80004140:	9fb9                	addw	a5,a5,a4
    80004142:	0017979b          	slliw	a5,a5,0x1
    80004146:	54d8                	lw	a4,44(s1)
    80004148:	9fb9                	addw	a5,a5,a4
    8000414a:	00f95963          	bge	s2,a5,8000415c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414e:	85a6                	mv	a1,s1
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	036080e7          	jalr	54(ra) # 80002188 <sleep>
    8000415a:	bfd9                	j	80004130 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000415c:	0001d517          	auipc	a0,0x1d
    80004160:	11450513          	addi	a0,a0,276 # 80021270 <log>
    80004164:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b1e080e7          	jalr	-1250(ra) # 80000c84 <release>
      break;
    }
  }
}
    8000416e:	60e2                	ld	ra,24(sp)
    80004170:	6442                	ld	s0,16(sp)
    80004172:	64a2                	ld	s1,8(sp)
    80004174:	6902                	ld	s2,0(sp)
    80004176:	6105                	addi	sp,sp,32
    80004178:	8082                	ret

000000008000417a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000417a:	7139                	addi	sp,sp,-64
    8000417c:	fc06                	sd	ra,56(sp)
    8000417e:	f822                	sd	s0,48(sp)
    80004180:	f426                	sd	s1,40(sp)
    80004182:	f04a                	sd	s2,32(sp)
    80004184:	ec4e                	sd	s3,24(sp)
    80004186:	e852                	sd	s4,16(sp)
    80004188:	e456                	sd	s5,8(sp)
    8000418a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	0e448493          	addi	s1,s1,228 # 80021270 <log>
    80004194:	8526                	mv	a0,s1
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a3a080e7          	jalr	-1478(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	37fd                	addiw	a5,a5,-1
    800041a2:	0007891b          	sext.w	s2,a5
    800041a6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	e7b9                	bnez	a5,800041f8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041ac:	04091e63          	bnez	s2,80004208 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041b0:	0001d497          	auipc	s1,0x1d
    800041b4:	0c048493          	addi	s1,s1,192 # 80021270 <log>
    800041b8:	4785                	li	a5,1
    800041ba:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	ac6080e7          	jalr	-1338(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c6:	54dc                	lw	a5,44(s1)
    800041c8:	06f04763          	bgtz	a5,80004236 <end_op+0xbc>
    acquire(&log.lock);
    800041cc:	0001d497          	auipc	s1,0x1d
    800041d0:	0a448493          	addi	s1,s1,164 # 80021270 <log>
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	9fa080e7          	jalr	-1542(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800041de:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffe097          	auipc	ra,0xffffe
    800041e8:	130080e7          	jalr	304(ra) # 80002314 <wakeup>
    release(&log.lock);
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	a96080e7          	jalr	-1386(ra) # 80000c84 <release>
}
    800041f6:	a03d                	j	80004224 <end_op+0xaa>
    panic("log.committing");
    800041f8:	00004517          	auipc	a0,0x4
    800041fc:	4b850513          	addi	a0,a0,1208 # 800086b0 <syscalls+0x1f0>
    80004200:	ffffc097          	auipc	ra,0xffffc
    80004204:	33a080e7          	jalr	826(ra) # 8000053a <panic>
    wakeup(&log);
    80004208:	0001d497          	auipc	s1,0x1d
    8000420c:	06848493          	addi	s1,s1,104 # 80021270 <log>
    80004210:	8526                	mv	a0,s1
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	102080e7          	jalr	258(ra) # 80002314 <wakeup>
  release(&log.lock);
    8000421a:	8526                	mv	a0,s1
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	a68080e7          	jalr	-1432(ra) # 80000c84 <release>
}
    80004224:	70e2                	ld	ra,56(sp)
    80004226:	7442                	ld	s0,48(sp)
    80004228:	74a2                	ld	s1,40(sp)
    8000422a:	7902                	ld	s2,32(sp)
    8000422c:	69e2                	ld	s3,24(sp)
    8000422e:	6a42                	ld	s4,16(sp)
    80004230:	6aa2                	ld	s5,8(sp)
    80004232:	6121                	addi	sp,sp,64
    80004234:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004236:	0001da97          	auipc	s5,0x1d
    8000423a:	06aa8a93          	addi	s5,s5,106 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423e:	0001da17          	auipc	s4,0x1d
    80004242:	032a0a13          	addi	s4,s4,50 # 80021270 <log>
    80004246:	018a2583          	lw	a1,24(s4)
    8000424a:	012585bb          	addw	a1,a1,s2
    8000424e:	2585                	addiw	a1,a1,1
    80004250:	028a2503          	lw	a0,40(s4)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	cca080e7          	jalr	-822(ra) # 80002f1e <bread>
    8000425c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425e:	000aa583          	lw	a1,0(s5)
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cb8080e7          	jalr	-840(ra) # 80002f1e <bread>
    8000426e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004270:	40000613          	li	a2,1024
    80004274:	05850593          	addi	a1,a0,88
    80004278:	05848513          	addi	a0,s1,88
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	aac080e7          	jalr	-1364(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	d8a080e7          	jalr	-630(ra) # 80003010 <bwrite>
    brelse(from);
    8000428e:	854e                	mv	a0,s3
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	dbe080e7          	jalr	-578(ra) # 8000304e <brelse>
    brelse(to);
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	db4080e7          	jalr	-588(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a2:	2905                	addiw	s2,s2,1
    800042a4:	0a91                	addi	s5,s5,4
    800042a6:	02ca2783          	lw	a5,44(s4)
    800042aa:	f8f94ee3          	blt	s2,a5,80004246 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	c68080e7          	jalr	-920(ra) # 80003f16 <write_head>
    install_trans(0); // Now install writes to home locations
    800042b6:	4501                	li	a0,0
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	cda080e7          	jalr	-806(ra) # 80003f92 <install_trans>
    log.lh.n = 0;
    800042c0:	0001d797          	auipc	a5,0x1d
    800042c4:	fc07ae23          	sw	zero,-36(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	c4e080e7          	jalr	-946(ra) # 80003f16 <write_head>
    800042d0:	bdf5                	j	800041cc <end_op+0x52>

00000000800042d2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
    800042de:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042e0:	0001d917          	auipc	s2,0x1d
    800042e4:	f9090913          	addi	s2,s2,-112 # 80021270 <log>
    800042e8:	854a                	mv	a0,s2
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	8e6080e7          	jalr	-1818(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042f2:	02c92603          	lw	a2,44(s2)
    800042f6:	47f5                	li	a5,29
    800042f8:	06c7c563          	blt	a5,a2,80004362 <log_write+0x90>
    800042fc:	0001d797          	auipc	a5,0x1d
    80004300:	f907a783          	lw	a5,-112(a5) # 8002128c <log+0x1c>
    80004304:	37fd                	addiw	a5,a5,-1
    80004306:	04f65e63          	bge	a2,a5,80004362 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000430a:	0001d797          	auipc	a5,0x1d
    8000430e:	f867a783          	lw	a5,-122(a5) # 80021290 <log+0x20>
    80004312:	06f05063          	blez	a5,80004372 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004316:	4781                	li	a5,0
    80004318:	06c05563          	blez	a2,80004382 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000431c:	44cc                	lw	a1,12(s1)
    8000431e:	0001d717          	auipc	a4,0x1d
    80004322:	f8270713          	addi	a4,a4,-126 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004326:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004328:	4314                	lw	a3,0(a4)
    8000432a:	04b68c63          	beq	a3,a1,80004382 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	2785                	addiw	a5,a5,1
    80004330:	0711                	addi	a4,a4,4
    80004332:	fef61be3          	bne	a2,a5,80004328 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004336:	0621                	addi	a2,a2,8
    80004338:	060a                	slli	a2,a2,0x2
    8000433a:	0001d797          	auipc	a5,0x1d
    8000433e:	f3678793          	addi	a5,a5,-202 # 80021270 <log>
    80004342:	97b2                	add	a5,a5,a2
    80004344:	44d8                	lw	a4,12(s1)
    80004346:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	da2080e7          	jalr	-606(ra) # 800030ec <bpin>
    log.lh.n++;
    80004352:	0001d717          	auipc	a4,0x1d
    80004356:	f1e70713          	addi	a4,a4,-226 # 80021270 <log>
    8000435a:	575c                	lw	a5,44(a4)
    8000435c:	2785                	addiw	a5,a5,1
    8000435e:	d75c                	sw	a5,44(a4)
    80004360:	a82d                	j	8000439a <log_write+0xc8>
    panic("too big a transaction");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	35e50513          	addi	a0,a0,862 # 800086c0 <syscalls+0x200>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d0080e7          	jalr	464(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	36650513          	addi	a0,a0,870 # 800086d8 <syscalls+0x218>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c0080e7          	jalr	448(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004382:	00878693          	addi	a3,a5,8
    80004386:	068a                	slli	a3,a3,0x2
    80004388:	0001d717          	auipc	a4,0x1d
    8000438c:	ee870713          	addi	a4,a4,-280 # 80021270 <log>
    80004390:	9736                	add	a4,a4,a3
    80004392:	44d4                	lw	a3,12(s1)
    80004394:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004396:	faf609e3          	beq	a2,a5,80004348 <log_write+0x76>
  }
  release(&log.lock);
    8000439a:	0001d517          	auipc	a0,0x1d
    8000439e:	ed650513          	addi	a0,a0,-298 # 80021270 <log>
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8e2080e7          	jalr	-1822(ra) # 80000c84 <release>
}
    800043aa:	60e2                	ld	ra,24(sp)
    800043ac:	6442                	ld	s0,16(sp)
    800043ae:	64a2                	ld	s1,8(sp)
    800043b0:	6902                	ld	s2,0(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
    800043c2:	84aa                	mv	s1,a0
    800043c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043c6:	00004597          	auipc	a1,0x4
    800043ca:	33258593          	addi	a1,a1,818 # 800086f8 <syscalls+0x238>
    800043ce:	0521                	addi	a0,a0,8
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	770080e7          	jalr	1904(ra) # 80000b40 <initlock>
  lk->name = name;
    800043d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e0:	0204a423          	sw	zero,40(s1)
}
    800043e4:	60e2                	ld	ra,24(sp)
    800043e6:	6442                	ld	s0,16(sp)
    800043e8:	64a2                	ld	s1,8(sp)
    800043ea:	6902                	ld	s2,0(sp)
    800043ec:	6105                	addi	sp,sp,32
    800043ee:	8082                	ret

00000000800043f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f0:	1101                	addi	sp,sp,-32
    800043f2:	ec06                	sd	ra,24(sp)
    800043f4:	e822                	sd	s0,16(sp)
    800043f6:	e426                	sd	s1,8(sp)
    800043f8:	e04a                	sd	s2,0(sp)
    800043fa:	1000                	addi	s0,sp,32
    800043fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043fe:	00850913          	addi	s2,a0,8
    80004402:	854a                	mv	a0,s2
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7cc080e7          	jalr	1996(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000440c:	409c                	lw	a5,0(s1)
    8000440e:	cb89                	beqz	a5,80004420 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004410:	85ca                	mv	a1,s2
    80004412:	8526                	mv	a0,s1
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	d74080e7          	jalr	-652(ra) # 80002188 <sleep>
  while (lk->locked) {
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	fbed                	bnez	a5,80004410 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004420:	4785                	li	a5,1
    80004422:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	6a0080e7          	jalr	1696(ra) # 80001ac4 <myproc>
    8000442c:	591c                	lw	a5,48(a0)
    8000442e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004430:	854a                	mv	a0,s2
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	852080e7          	jalr	-1966(ra) # 80000c84 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	776080e7          	jalr	1910(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004462:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004466:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffe097          	auipc	ra,0xffffe
    80004470:	ea8080e7          	jalr	-344(ra) # 80002314 <wakeup>
  release(&lk->lk);
    80004474:	854a                	mv	a0,s2
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	80e080e7          	jalr	-2034(ra) # 80000c84 <release>
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000448a:	7179                	addi	sp,sp,-48
    8000448c:	f406                	sd	ra,40(sp)
    8000448e:	f022                	sd	s0,32(sp)
    80004490:	ec26                	sd	s1,24(sp)
    80004492:	e84a                	sd	s2,16(sp)
    80004494:	e44e                	sd	s3,8(sp)
    80004496:	1800                	addi	s0,sp,48
    80004498:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000449a:	00850913          	addi	s2,a0,8
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	730080e7          	jalr	1840(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	ef99                	bnez	a5,800044c8 <holdingsleep+0x3e>
    800044ac:	4481                	li	s1,0
  release(&lk->lk);
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7d4080e7          	jalr	2004(ra) # 80000c84 <release>
  return r;
}
    800044b8:	8526                	mv	a0,s1
    800044ba:	70a2                	ld	ra,40(sp)
    800044bc:	7402                	ld	s0,32(sp)
    800044be:	64e2                	ld	s1,24(sp)
    800044c0:	6942                	ld	s2,16(sp)
    800044c2:	69a2                	ld	s3,8(sp)
    800044c4:	6145                	addi	sp,sp,48
    800044c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c8:	0284a983          	lw	s3,40(s1)
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	5f8080e7          	jalr	1528(ra) # 80001ac4 <myproc>
    800044d4:	5904                	lw	s1,48(a0)
    800044d6:	413484b3          	sub	s1,s1,s3
    800044da:	0014b493          	seqz	s1,s1
    800044de:	bfc1                	j	800044ae <holdingsleep+0x24>

00000000800044e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e406                	sd	ra,8(sp)
    800044e4:	e022                	sd	s0,0(sp)
    800044e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044e8:	00004597          	auipc	a1,0x4
    800044ec:	22058593          	addi	a1,a1,544 # 80008708 <syscalls+0x248>
    800044f0:	0001d517          	auipc	a0,0x1d
    800044f4:	ec850513          	addi	a0,a0,-312 # 800213b8 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	648080e7          	jalr	1608(ra) # 80000b40 <initlock>
}
    80004500:	60a2                	ld	ra,8(sp)
    80004502:	6402                	ld	s0,0(sp)
    80004504:	0141                	addi	sp,sp,16
    80004506:	8082                	ret

0000000080004508 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	ea650513          	addi	a0,a0,-346 # 800213b8 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6b6080e7          	jalr	1718(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004522:	0001d497          	auipc	s1,0x1d
    80004526:	eae48493          	addi	s1,s1,-338 # 800213d0 <ftable+0x18>
    8000452a:	0001e717          	auipc	a4,0x1e
    8000452e:	e4670713          	addi	a4,a4,-442 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	cf99                	beqz	a5,80004552 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	02848493          	addi	s1,s1,40
    8000453a:	fee49ce3          	bne	s1,a4,80004532 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000453e:	0001d517          	auipc	a0,0x1d
    80004542:	e7a50513          	addi	a0,a0,-390 # 800213b8 <ftable>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	73e080e7          	jalr	1854(ra) # 80000c84 <release>
  return 0;
    8000454e:	4481                	li	s1,0
    80004550:	a819                	j	80004566 <filealloc+0x5e>
      f->ref = 1;
    80004552:	4785                	li	a5,1
    80004554:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004556:	0001d517          	auipc	a0,0x1d
    8000455a:	e6250513          	addi	a0,a0,-414 # 800213b8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	726080e7          	jalr	1830(ra) # 80000c84 <release>
}
    80004566:	8526                	mv	a0,s1
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000457e:	0001d517          	auipc	a0,0x1d
    80004582:	e3a50513          	addi	a0,a0,-454 # 800213b8 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	64a080e7          	jalr	1610(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	02f05263          	blez	a5,800045b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004594:	2785                	addiw	a5,a5,1
    80004596:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	e2050513          	addi	a0,a0,-480 # 800213b8 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6e4080e7          	jalr	1764(ra) # 80000c84 <release>
  return f;
}
    800045a8:	8526                	mv	a0,s1
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret
    panic("filedup");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	15c50513          	addi	a0,a0,348 # 80008710 <syscalls+0x250>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f7e080e7          	jalr	-130(ra) # 8000053a <panic>

00000000800045c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045c4:	7139                	addi	sp,sp,-64
    800045c6:	fc06                	sd	ra,56(sp)
    800045c8:	f822                	sd	s0,48(sp)
    800045ca:	f426                	sd	s1,40(sp)
    800045cc:	f04a                	sd	s2,32(sp)
    800045ce:	ec4e                	sd	s3,24(sp)
    800045d0:	e852                	sd	s4,16(sp)
    800045d2:	e456                	sd	s5,8(sp)
    800045d4:	0080                	addi	s0,sp,64
    800045d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	de050513          	addi	a0,a0,-544 # 800213b8 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	5f0080e7          	jalr	1520(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800045e8:	40dc                	lw	a5,4(s1)
    800045ea:	06f05163          	blez	a5,8000464c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ee:	37fd                	addiw	a5,a5,-1
    800045f0:	0007871b          	sext.w	a4,a5
    800045f4:	c0dc                	sw	a5,4(s1)
    800045f6:	06e04363          	bgtz	a4,8000465c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045fa:	0004a903          	lw	s2,0(s1)
    800045fe:	0094ca83          	lbu	s5,9(s1)
    80004602:	0104ba03          	ld	s4,16(s1)
    80004606:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000460a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000460e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	da650513          	addi	a0,a0,-602 # 800213b8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	66a080e7          	jalr	1642(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004622:	4785                	li	a5,1
    80004624:	04f90d63          	beq	s2,a5,8000467e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004628:	3979                	addiw	s2,s2,-2
    8000462a:	4785                	li	a5,1
    8000462c:	0527e063          	bltu	a5,s2,8000466c <fileclose+0xa8>
    begin_op();
    80004630:	00000097          	auipc	ra,0x0
    80004634:	acc080e7          	jalr	-1332(ra) # 800040fc <begin_op>
    iput(ff.ip);
    80004638:	854e                	mv	a0,s3
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	2a0080e7          	jalr	672(ra) # 800038da <iput>
    end_op();
    80004642:	00000097          	auipc	ra,0x0
    80004646:	b38080e7          	jalr	-1224(ra) # 8000417a <end_op>
    8000464a:	a00d                	j	8000466c <fileclose+0xa8>
    panic("fileclose");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	0cc50513          	addi	a0,a0,204 # 80008718 <syscalls+0x258>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	ee6080e7          	jalr	-282(ra) # 8000053a <panic>
    release(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	d5c50513          	addi	a0,a0,-676 # 800213b8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	620080e7          	jalr	1568(ra) # 80000c84 <release>
  }
}
    8000466c:	70e2                	ld	ra,56(sp)
    8000466e:	7442                	ld	s0,48(sp)
    80004670:	74a2                	ld	s1,40(sp)
    80004672:	7902                	ld	s2,32(sp)
    80004674:	69e2                	ld	s3,24(sp)
    80004676:	6a42                	ld	s4,16(sp)
    80004678:	6aa2                	ld	s5,8(sp)
    8000467a:	6121                	addi	sp,sp,64
    8000467c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000467e:	85d6                	mv	a1,s5
    80004680:	8552                	mv	a0,s4
    80004682:	00000097          	auipc	ra,0x0
    80004686:	34c080e7          	jalr	844(ra) # 800049ce <pipeclose>
    8000468a:	b7cd                	j	8000466c <fileclose+0xa8>

000000008000468c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000468c:	715d                	addi	sp,sp,-80
    8000468e:	e486                	sd	ra,72(sp)
    80004690:	e0a2                	sd	s0,64(sp)
    80004692:	fc26                	sd	s1,56(sp)
    80004694:	f84a                	sd	s2,48(sp)
    80004696:	f44e                	sd	s3,40(sp)
    80004698:	0880                	addi	s0,sp,80
    8000469a:	84aa                	mv	s1,a0
    8000469c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000469e:	ffffd097          	auipc	ra,0xffffd
    800046a2:	426080e7          	jalr	1062(ra) # 80001ac4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046a6:	409c                	lw	a5,0(s1)
    800046a8:	37f9                	addiw	a5,a5,-2
    800046aa:	4705                	li	a4,1
    800046ac:	04f76763          	bltu	a4,a5,800046fa <filestat+0x6e>
    800046b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	06c080e7          	jalr	108(ra) # 80003720 <ilock>
    stati(f->ip, &st);
    800046bc:	fb840593          	addi	a1,s0,-72
    800046c0:	6c88                	ld	a0,24(s1)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	2e8080e7          	jalr	744(ra) # 800039aa <stati>
    iunlock(f->ip);
    800046ca:	6c88                	ld	a0,24(s1)
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	116080e7          	jalr	278(ra) # 800037e2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046d4:	46e1                	li	a3,24
    800046d6:	fb840613          	addi	a2,s0,-72
    800046da:	85ce                	mv	a1,s3
    800046dc:	05093503          	ld	a0,80(s2)
    800046e0:	ffffd097          	auipc	ra,0xffffd
    800046e4:	f7a080e7          	jalr	-134(ra) # 8000165a <copyout>
    800046e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ec:	60a6                	ld	ra,72(sp)
    800046ee:	6406                	ld	s0,64(sp)
    800046f0:	74e2                	ld	s1,56(sp)
    800046f2:	7942                	ld	s2,48(sp)
    800046f4:	79a2                	ld	s3,40(sp)
    800046f6:	6161                	addi	sp,sp,80
    800046f8:	8082                	ret
  return -1;
    800046fa:	557d                	li	a0,-1
    800046fc:	bfc5                	j	800046ec <filestat+0x60>

00000000800046fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046fe:	7179                	addi	sp,sp,-48
    80004700:	f406                	sd	ra,40(sp)
    80004702:	f022                	sd	s0,32(sp)
    80004704:	ec26                	sd	s1,24(sp)
    80004706:	e84a                	sd	s2,16(sp)
    80004708:	e44e                	sd	s3,8(sp)
    8000470a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000470c:	00854783          	lbu	a5,8(a0)
    80004710:	c3d5                	beqz	a5,800047b4 <fileread+0xb6>
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
    80004716:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004718:	411c                	lw	a5,0(a0)
    8000471a:	4705                	li	a4,1
    8000471c:	04e78963          	beq	a5,a4,8000476e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004720:	470d                	li	a4,3
    80004722:	04e78d63          	beq	a5,a4,8000477c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004726:	4709                	li	a4,2
    80004728:	06e79e63          	bne	a5,a4,800047a4 <fileread+0xa6>
    ilock(f->ip);
    8000472c:	6d08                	ld	a0,24(a0)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	ff2080e7          	jalr	-14(ra) # 80003720 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004736:	874a                	mv	a4,s2
    80004738:	5094                	lw	a3,32(s1)
    8000473a:	864e                	mv	a2,s3
    8000473c:	4585                	li	a1,1
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	294080e7          	jalr	660(ra) # 800039d4 <readi>
    80004748:	892a                	mv	s2,a0
    8000474a:	00a05563          	blez	a0,80004754 <fileread+0x56>
      f->off += r;
    8000474e:	509c                	lw	a5,32(s1)
    80004750:	9fa9                	addw	a5,a5,a0
    80004752:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	08c080e7          	jalr	140(ra) # 800037e2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000475e:	854a                	mv	a0,s2
    80004760:	70a2                	ld	ra,40(sp)
    80004762:	7402                	ld	s0,32(sp)
    80004764:	64e2                	ld	s1,24(sp)
    80004766:	6942                	ld	s2,16(sp)
    80004768:	69a2                	ld	s3,8(sp)
    8000476a:	6145                	addi	sp,sp,48
    8000476c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000476e:	6908                	ld	a0,16(a0)
    80004770:	00000097          	auipc	ra,0x0
    80004774:	3c0080e7          	jalr	960(ra) # 80004b30 <piperead>
    80004778:	892a                	mv	s2,a0
    8000477a:	b7d5                	j	8000475e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000477c:	02451783          	lh	a5,36(a0)
    80004780:	03079693          	slli	a3,a5,0x30
    80004784:	92c1                	srli	a3,a3,0x30
    80004786:	4725                	li	a4,9
    80004788:	02d76863          	bltu	a4,a3,800047b8 <fileread+0xba>
    8000478c:	0792                	slli	a5,a5,0x4
    8000478e:	0001d717          	auipc	a4,0x1d
    80004792:	b8a70713          	addi	a4,a4,-1142 # 80021318 <devsw>
    80004796:	97ba                	add	a5,a5,a4
    80004798:	639c                	ld	a5,0(a5)
    8000479a:	c38d                	beqz	a5,800047bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000479c:	4505                	li	a0,1
    8000479e:	9782                	jalr	a5
    800047a0:	892a                	mv	s2,a0
    800047a2:	bf75                	j	8000475e <fileread+0x60>
    panic("fileread");
    800047a4:	00004517          	auipc	a0,0x4
    800047a8:	f8450513          	addi	a0,a0,-124 # 80008728 <syscalls+0x268>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	d8e080e7          	jalr	-626(ra) # 8000053a <panic>
    return -1;
    800047b4:	597d                	li	s2,-1
    800047b6:	b765                	j	8000475e <fileread+0x60>
      return -1;
    800047b8:	597d                	li	s2,-1
    800047ba:	b755                	j	8000475e <fileread+0x60>
    800047bc:	597d                	li	s2,-1
    800047be:	b745                	j	8000475e <fileread+0x60>

00000000800047c0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047c0:	715d                	addi	sp,sp,-80
    800047c2:	e486                	sd	ra,72(sp)
    800047c4:	e0a2                	sd	s0,64(sp)
    800047c6:	fc26                	sd	s1,56(sp)
    800047c8:	f84a                	sd	s2,48(sp)
    800047ca:	f44e                	sd	s3,40(sp)
    800047cc:	f052                	sd	s4,32(sp)
    800047ce:	ec56                	sd	s5,24(sp)
    800047d0:	e85a                	sd	s6,16(sp)
    800047d2:	e45e                	sd	s7,8(sp)
    800047d4:	e062                	sd	s8,0(sp)
    800047d6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047d8:	00954783          	lbu	a5,9(a0)
    800047dc:	10078663          	beqz	a5,800048e8 <filewrite+0x128>
    800047e0:	892a                	mv	s2,a0
    800047e2:	8b2e                	mv	s6,a1
    800047e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e6:	411c                	lw	a5,0(a0)
    800047e8:	4705                	li	a4,1
    800047ea:	02e78263          	beq	a5,a4,8000480e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ee:	470d                	li	a4,3
    800047f0:	02e78663          	beq	a5,a4,8000481c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f4:	4709                	li	a4,2
    800047f6:	0ee79163          	bne	a5,a4,800048d8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047fa:	0ac05d63          	blez	a2,800048b4 <filewrite+0xf4>
    int i = 0;
    800047fe:	4981                	li	s3,0
    80004800:	6b85                	lui	s7,0x1
    80004802:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004806:	6c05                	lui	s8,0x1
    80004808:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000480c:	a861                	j	800048a4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000480e:	6908                	ld	a0,16(a0)
    80004810:	00000097          	auipc	ra,0x0
    80004814:	22e080e7          	jalr	558(ra) # 80004a3e <pipewrite>
    80004818:	8a2a                	mv	s4,a0
    8000481a:	a045                	j	800048ba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000481c:	02451783          	lh	a5,36(a0)
    80004820:	03079693          	slli	a3,a5,0x30
    80004824:	92c1                	srli	a3,a3,0x30
    80004826:	4725                	li	a4,9
    80004828:	0cd76263          	bltu	a4,a3,800048ec <filewrite+0x12c>
    8000482c:	0792                	slli	a5,a5,0x4
    8000482e:	0001d717          	auipc	a4,0x1d
    80004832:	aea70713          	addi	a4,a4,-1302 # 80021318 <devsw>
    80004836:	97ba                	add	a5,a5,a4
    80004838:	679c                	ld	a5,8(a5)
    8000483a:	cbdd                	beqz	a5,800048f0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000483c:	4505                	li	a0,1
    8000483e:	9782                	jalr	a5
    80004840:	8a2a                	mv	s4,a0
    80004842:	a8a5                	j	800048ba <filewrite+0xfa>
    80004844:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8b4080e7          	jalr	-1868(ra) # 800040fc <begin_op>
      ilock(f->ip);
    80004850:	01893503          	ld	a0,24(s2)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	ecc080e7          	jalr	-308(ra) # 80003720 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485c:	8756                	mv	a4,s5
    8000485e:	02092683          	lw	a3,32(s2)
    80004862:	01698633          	add	a2,s3,s6
    80004866:	4585                	li	a1,1
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	260080e7          	jalr	608(ra) # 80003acc <writei>
    80004874:	84aa                	mv	s1,a0
    80004876:	00a05763          	blez	a0,80004884 <filewrite+0xc4>
        f->off += r;
    8000487a:	02092783          	lw	a5,32(s2)
    8000487e:	9fa9                	addw	a5,a5,a0
    80004880:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004884:	01893503          	ld	a0,24(s2)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f5a080e7          	jalr	-166(ra) # 800037e2 <iunlock>
      end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8ea080e7          	jalr	-1814(ra) # 8000417a <end_op>

      if(r != n1){
    80004898:	009a9f63          	bne	s5,s1,800048b6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000489c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a0:	0149db63          	bge	s3,s4,800048b6 <filewrite+0xf6>
      int n1 = n - i;
    800048a4:	413a04bb          	subw	s1,s4,s3
    800048a8:	0004879b          	sext.w	a5,s1
    800048ac:	f8fbdce3          	bge	s7,a5,80004844 <filewrite+0x84>
    800048b0:	84e2                	mv	s1,s8
    800048b2:	bf49                	j	80004844 <filewrite+0x84>
    int i = 0;
    800048b4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048b6:	013a1f63          	bne	s4,s3,800048d4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ba:	8552                	mv	a0,s4
    800048bc:	60a6                	ld	ra,72(sp)
    800048be:	6406                	ld	s0,64(sp)
    800048c0:	74e2                	ld	s1,56(sp)
    800048c2:	7942                	ld	s2,48(sp)
    800048c4:	79a2                	ld	s3,40(sp)
    800048c6:	7a02                	ld	s4,32(sp)
    800048c8:	6ae2                	ld	s5,24(sp)
    800048ca:	6b42                	ld	s6,16(sp)
    800048cc:	6ba2                	ld	s7,8(sp)
    800048ce:	6c02                	ld	s8,0(sp)
    800048d0:	6161                	addi	sp,sp,80
    800048d2:	8082                	ret
    ret = (i == n ? n : -1);
    800048d4:	5a7d                	li	s4,-1
    800048d6:	b7d5                	j	800048ba <filewrite+0xfa>
    panic("filewrite");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	e6050513          	addi	a0,a0,-416 # 80008738 <syscalls+0x278>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c5a080e7          	jalr	-934(ra) # 8000053a <panic>
    return -1;
    800048e8:	5a7d                	li	s4,-1
    800048ea:	bfc1                	j	800048ba <filewrite+0xfa>
      return -1;
    800048ec:	5a7d                	li	s4,-1
    800048ee:	b7f1                	j	800048ba <filewrite+0xfa>
    800048f0:	5a7d                	li	s4,-1
    800048f2:	b7e1                	j	800048ba <filewrite+0xfa>

00000000800048f4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048f4:	7179                	addi	sp,sp,-48
    800048f6:	f406                	sd	ra,40(sp)
    800048f8:	f022                	sd	s0,32(sp)
    800048fa:	ec26                	sd	s1,24(sp)
    800048fc:	e84a                	sd	s2,16(sp)
    800048fe:	e44e                	sd	s3,8(sp)
    80004900:	e052                	sd	s4,0(sp)
    80004902:	1800                	addi	s0,sp,48
    80004904:	84aa                	mv	s1,a0
    80004906:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004908:	0005b023          	sd	zero,0(a1)
    8000490c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004910:	00000097          	auipc	ra,0x0
    80004914:	bf8080e7          	jalr	-1032(ra) # 80004508 <filealloc>
    80004918:	e088                	sd	a0,0(s1)
    8000491a:	c551                	beqz	a0,800049a6 <pipealloc+0xb2>
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	bec080e7          	jalr	-1044(ra) # 80004508 <filealloc>
    80004924:	00aa3023          	sd	a0,0(s4)
    80004928:	c92d                	beqz	a0,8000499a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	1b6080e7          	jalr	438(ra) # 80000ae0 <kalloc>
    80004932:	892a                	mv	s2,a0
    80004934:	c125                	beqz	a0,80004994 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004936:	4985                	li	s3,1
    80004938:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000493c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004940:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004944:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004948:	00004597          	auipc	a1,0x4
    8000494c:	e0058593          	addi	a1,a1,-512 # 80008748 <syscalls+0x288>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	1f0080e7          	jalr	496(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004958:	609c                	ld	a5,0(s1)
    8000495a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000495e:	609c                	ld	a5,0(s1)
    80004960:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004964:	609c                	ld	a5,0(s1)
    80004966:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000496a:	609c                	ld	a5,0(s1)
    8000496c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004978:	000a3783          	ld	a5,0(s4)
    8000497c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004980:	000a3783          	ld	a5,0(s4)
    80004984:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004988:	000a3783          	ld	a5,0(s4)
    8000498c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004990:	4501                	li	a0,0
    80004992:	a025                	j	800049ba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004994:	6088                	ld	a0,0(s1)
    80004996:	e501                	bnez	a0,8000499e <pipealloc+0xaa>
    80004998:	a039                	j	800049a6 <pipealloc+0xb2>
    8000499a:	6088                	ld	a0,0(s1)
    8000499c:	c51d                	beqz	a0,800049ca <pipealloc+0xd6>
    fileclose(*f0);
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	c26080e7          	jalr	-986(ra) # 800045c4 <fileclose>
  if(*f1)
    800049a6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049aa:	557d                	li	a0,-1
  if(*f1)
    800049ac:	c799                	beqz	a5,800049ba <pipealloc+0xc6>
    fileclose(*f1);
    800049ae:	853e                	mv	a0,a5
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	c14080e7          	jalr	-1004(ra) # 800045c4 <fileclose>
  return -1;
    800049b8:	557d                	li	a0,-1
}
    800049ba:	70a2                	ld	ra,40(sp)
    800049bc:	7402                	ld	s0,32(sp)
    800049be:	64e2                	ld	s1,24(sp)
    800049c0:	6942                	ld	s2,16(sp)
    800049c2:	69a2                	ld	s3,8(sp)
    800049c4:	6a02                	ld	s4,0(sp)
    800049c6:	6145                	addi	sp,sp,48
    800049c8:	8082                	ret
  return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	b7fd                	j	800049ba <pipealloc+0xc6>

00000000800049ce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049ce:	1101                	addi	sp,sp,-32
    800049d0:	ec06                	sd	ra,24(sp)
    800049d2:	e822                	sd	s0,16(sp)
    800049d4:	e426                	sd	s1,8(sp)
    800049d6:	e04a                	sd	s2,0(sp)
    800049d8:	1000                	addi	s0,sp,32
    800049da:	84aa                	mv	s1,a0
    800049dc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	1f2080e7          	jalr	498(ra) # 80000bd0 <acquire>
  if(writable){
    800049e6:	02090d63          	beqz	s2,80004a20 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ee:	21848513          	addi	a0,s1,536
    800049f2:	ffffe097          	auipc	ra,0xffffe
    800049f6:	922080e7          	jalr	-1758(ra) # 80002314 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049fa:	2204b783          	ld	a5,544(s1)
    800049fe:	eb95                	bnez	a5,80004a32 <pipeclose+0x64>
    release(&pi->lock);
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	282080e7          	jalr	642(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	fd6080e7          	jalr	-42(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004a14:	60e2                	ld	ra,24(sp)
    80004a16:	6442                	ld	s0,16(sp)
    80004a18:	64a2                	ld	s1,8(sp)
    80004a1a:	6902                	ld	s2,0(sp)
    80004a1c:	6105                	addi	sp,sp,32
    80004a1e:	8082                	ret
    pi->readopen = 0;
    80004a20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a24:	21c48513          	addi	a0,s1,540
    80004a28:	ffffe097          	auipc	ra,0xffffe
    80004a2c:	8ec080e7          	jalr	-1812(ra) # 80002314 <wakeup>
    80004a30:	b7e9                	j	800049fa <pipeclose+0x2c>
    release(&pi->lock);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80004a3c:	bfe1                	j	80004a14 <pipeclose+0x46>

0000000080004a3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a3e:	711d                	addi	sp,sp,-96
    80004a40:	ec86                	sd	ra,88(sp)
    80004a42:	e8a2                	sd	s0,80(sp)
    80004a44:	e4a6                	sd	s1,72(sp)
    80004a46:	e0ca                	sd	s2,64(sp)
    80004a48:	fc4e                	sd	s3,56(sp)
    80004a4a:	f852                	sd	s4,48(sp)
    80004a4c:	f456                	sd	s5,40(sp)
    80004a4e:	f05a                	sd	s6,32(sp)
    80004a50:	ec5e                	sd	s7,24(sp)
    80004a52:	e862                	sd	s8,16(sp)
    80004a54:	1080                	addi	s0,sp,96
    80004a56:	84aa                	mv	s1,a0
    80004a58:	8aae                	mv	s5,a1
    80004a5a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a5c:	ffffd097          	auipc	ra,0xffffd
    80004a60:	068080e7          	jalr	104(ra) # 80001ac4 <myproc>
    80004a64:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	168080e7          	jalr	360(ra) # 80000bd0 <acquire>
  while(i < n){
    80004a70:	0b405363          	blez	s4,80004b16 <pipewrite+0xd8>
  int i = 0;
    80004a74:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a76:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a78:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a7c:	21c48b93          	addi	s7,s1,540
    80004a80:	a089                	j	80004ac2 <pipewrite+0x84>
      release(&pi->lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	200080e7          	jalr	512(ra) # 80000c84 <release>
      return -1;
    80004a8c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a8e:	854a                	mv	a0,s2
    80004a90:	60e6                	ld	ra,88(sp)
    80004a92:	6446                	ld	s0,80(sp)
    80004a94:	64a6                	ld	s1,72(sp)
    80004a96:	6906                	ld	s2,64(sp)
    80004a98:	79e2                	ld	s3,56(sp)
    80004a9a:	7a42                	ld	s4,48(sp)
    80004a9c:	7aa2                	ld	s5,40(sp)
    80004a9e:	7b02                	ld	s6,32(sp)
    80004aa0:	6be2                	ld	s7,24(sp)
    80004aa2:	6c42                	ld	s8,16(sp)
    80004aa4:	6125                	addi	sp,sp,96
    80004aa6:	8082                	ret
      wakeup(&pi->nread);
    80004aa8:	8562                	mv	a0,s8
    80004aaa:	ffffe097          	auipc	ra,0xffffe
    80004aae:	86a080e7          	jalr	-1942(ra) # 80002314 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ab2:	85a6                	mv	a1,s1
    80004ab4:	855e                	mv	a0,s7
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	6d2080e7          	jalr	1746(ra) # 80002188 <sleep>
  while(i < n){
    80004abe:	05495d63          	bge	s2,s4,80004b18 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ac2:	2204a783          	lw	a5,544(s1)
    80004ac6:	dfd5                	beqz	a5,80004a82 <pipewrite+0x44>
    80004ac8:	0289a783          	lw	a5,40(s3)
    80004acc:	fbdd                	bnez	a5,80004a82 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ace:	2184a783          	lw	a5,536(s1)
    80004ad2:	21c4a703          	lw	a4,540(s1)
    80004ad6:	2007879b          	addiw	a5,a5,512
    80004ada:	fcf707e3          	beq	a4,a5,80004aa8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ade:	4685                	li	a3,1
    80004ae0:	01590633          	add	a2,s2,s5
    80004ae4:	faf40593          	addi	a1,s0,-81
    80004ae8:	0509b503          	ld	a0,80(s3)
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	bfa080e7          	jalr	-1030(ra) # 800016e6 <copyin>
    80004af4:	03650263          	beq	a0,s6,80004b18 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004af8:	21c4a783          	lw	a5,540(s1)
    80004afc:	0017871b          	addiw	a4,a5,1
    80004b00:	20e4ae23          	sw	a4,540(s1)
    80004b04:	1ff7f793          	andi	a5,a5,511
    80004b08:	97a6                	add	a5,a5,s1
    80004b0a:	faf44703          	lbu	a4,-81(s0)
    80004b0e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b12:	2905                	addiw	s2,s2,1
    80004b14:	b76d                	j	80004abe <pipewrite+0x80>
  int i = 0;
    80004b16:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b18:	21848513          	addi	a0,s1,536
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	7f8080e7          	jalr	2040(ra) # 80002314 <wakeup>
  release(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	15e080e7          	jalr	350(ra) # 80000c84 <release>
  return i;
    80004b2e:	b785                	j	80004a8e <pipewrite+0x50>

0000000080004b30 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b30:	715d                	addi	sp,sp,-80
    80004b32:	e486                	sd	ra,72(sp)
    80004b34:	e0a2                	sd	s0,64(sp)
    80004b36:	fc26                	sd	s1,56(sp)
    80004b38:	f84a                	sd	s2,48(sp)
    80004b3a:	f44e                	sd	s3,40(sp)
    80004b3c:	f052                	sd	s4,32(sp)
    80004b3e:	ec56                	sd	s5,24(sp)
    80004b40:	e85a                	sd	s6,16(sp)
    80004b42:	0880                	addi	s0,sp,80
    80004b44:	84aa                	mv	s1,a0
    80004b46:	892e                	mv	s2,a1
    80004b48:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	f7a080e7          	jalr	-134(ra) # 80001ac4 <myproc>
    80004b52:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	07a080e7          	jalr	122(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5e:	2184a703          	lw	a4,536(s1)
    80004b62:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b66:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6a:	02f71463          	bne	a4,a5,80004b92 <piperead+0x62>
    80004b6e:	2244a783          	lw	a5,548(s1)
    80004b72:	c385                	beqz	a5,80004b92 <piperead+0x62>
    if(pr->killed){
    80004b74:	028a2783          	lw	a5,40(s4)
    80004b78:	ebc9                	bnez	a5,80004c0a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b7a:	85a6                	mv	a1,s1
    80004b7c:	854e                	mv	a0,s3
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	60a080e7          	jalr	1546(ra) # 80002188 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b86:	2184a703          	lw	a4,536(s1)
    80004b8a:	21c4a783          	lw	a5,540(s1)
    80004b8e:	fef700e3          	beq	a4,a5,80004b6e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b94:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b96:	05505463          	blez	s5,80004bde <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b9a:	2184a783          	lw	a5,536(s1)
    80004b9e:	21c4a703          	lw	a4,540(s1)
    80004ba2:	02f70e63          	beq	a4,a5,80004bde <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ba6:	0017871b          	addiw	a4,a5,1
    80004baa:	20e4ac23          	sw	a4,536(s1)
    80004bae:	1ff7f793          	andi	a5,a5,511
    80004bb2:	97a6                	add	a5,a5,s1
    80004bb4:	0187c783          	lbu	a5,24(a5)
    80004bb8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bbc:	4685                	li	a3,1
    80004bbe:	fbf40613          	addi	a2,s0,-65
    80004bc2:	85ca                	mv	a1,s2
    80004bc4:	050a3503          	ld	a0,80(s4)
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	a92080e7          	jalr	-1390(ra) # 8000165a <copyout>
    80004bd0:	01650763          	beq	a0,s6,80004bde <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bd4:	2985                	addiw	s3,s3,1
    80004bd6:	0905                	addi	s2,s2,1
    80004bd8:	fd3a91e3          	bne	s5,s3,80004b9a <piperead+0x6a>
    80004bdc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bde:	21c48513          	addi	a0,s1,540
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	732080e7          	jalr	1842(ra) # 80002314 <wakeup>
  release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	098080e7          	jalr	152(ra) # 80000c84 <release>
  return i;
}
    80004bf4:	854e                	mv	a0,s3
    80004bf6:	60a6                	ld	ra,72(sp)
    80004bf8:	6406                	ld	s0,64(sp)
    80004bfa:	74e2                	ld	s1,56(sp)
    80004bfc:	7942                	ld	s2,48(sp)
    80004bfe:	79a2                	ld	s3,40(sp)
    80004c00:	7a02                	ld	s4,32(sp)
    80004c02:	6ae2                	ld	s5,24(sp)
    80004c04:	6b42                	ld	s6,16(sp)
    80004c06:	6161                	addi	sp,sp,80
    80004c08:	8082                	ret
      release(&pi->lock);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	078080e7          	jalr	120(ra) # 80000c84 <release>
      return -1;
    80004c14:	59fd                	li	s3,-1
    80004c16:	bff9                	j	80004bf4 <piperead+0xc4>

0000000080004c18 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c18:	de010113          	addi	sp,sp,-544
    80004c1c:	20113c23          	sd	ra,536(sp)
    80004c20:	20813823          	sd	s0,528(sp)
    80004c24:	20913423          	sd	s1,520(sp)
    80004c28:	21213023          	sd	s2,512(sp)
    80004c2c:	ffce                	sd	s3,504(sp)
    80004c2e:	fbd2                	sd	s4,496(sp)
    80004c30:	f7d6                	sd	s5,488(sp)
    80004c32:	f3da                	sd	s6,480(sp)
    80004c34:	efde                	sd	s7,472(sp)
    80004c36:	ebe2                	sd	s8,464(sp)
    80004c38:	e7e6                	sd	s9,456(sp)
    80004c3a:	e3ea                	sd	s10,448(sp)
    80004c3c:	ff6e                	sd	s11,440(sp)
    80004c3e:	1400                	addi	s0,sp,544
    80004c40:	892a                	mv	s2,a0
    80004c42:	dea43423          	sd	a0,-536(s0)
    80004c46:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	e7a080e7          	jalr	-390(ra) # 80001ac4 <myproc>
    80004c52:	84aa                	mv	s1,a0

  begin_op();
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	4a8080e7          	jalr	1192(ra) # 800040fc <begin_op>

  if((ip = namei(path)) == 0){
    80004c5c:	854a                	mv	a0,s2
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	27e080e7          	jalr	638(ra) # 80003edc <namei>
    80004c66:	c93d                	beqz	a0,80004cdc <exec+0xc4>
    80004c68:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	ab6080e7          	jalr	-1354(ra) # 80003720 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c72:	04000713          	li	a4,64
    80004c76:	4681                	li	a3,0
    80004c78:	e5040613          	addi	a2,s0,-432
    80004c7c:	4581                	li	a1,0
    80004c7e:	8556                	mv	a0,s5
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	d54080e7          	jalr	-684(ra) # 800039d4 <readi>
    80004c88:	04000793          	li	a5,64
    80004c8c:	00f51a63          	bne	a0,a5,80004ca0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c90:	e5042703          	lw	a4,-432(s0)
    80004c94:	464c47b7          	lui	a5,0x464c4
    80004c98:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c9c:	04f70663          	beq	a4,a5,80004ce8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ca0:	8556                	mv	a0,s5
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	ce0080e7          	jalr	-800(ra) # 80003982 <iunlockput>
    end_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	4d0080e7          	jalr	1232(ra) # 8000417a <end_op>
  }
  return -1;
    80004cb2:	557d                	li	a0,-1
}
    80004cb4:	21813083          	ld	ra,536(sp)
    80004cb8:	21013403          	ld	s0,528(sp)
    80004cbc:	20813483          	ld	s1,520(sp)
    80004cc0:	20013903          	ld	s2,512(sp)
    80004cc4:	79fe                	ld	s3,504(sp)
    80004cc6:	7a5e                	ld	s4,496(sp)
    80004cc8:	7abe                	ld	s5,488(sp)
    80004cca:	7b1e                	ld	s6,480(sp)
    80004ccc:	6bfe                	ld	s7,472(sp)
    80004cce:	6c5e                	ld	s8,464(sp)
    80004cd0:	6cbe                	ld	s9,456(sp)
    80004cd2:	6d1e                	ld	s10,448(sp)
    80004cd4:	7dfa                	ld	s11,440(sp)
    80004cd6:	22010113          	addi	sp,sp,544
    80004cda:	8082                	ret
    end_op();
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	49e080e7          	jalr	1182(ra) # 8000417a <end_op>
    return -1;
    80004ce4:	557d                	li	a0,-1
    80004ce6:	b7f9                	j	80004cb4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	e9e080e7          	jalr	-354(ra) # 80001b88 <proc_pagetable>
    80004cf2:	8b2a                	mv	s6,a0
    80004cf4:	d555                	beqz	a0,80004ca0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf6:	e7042783          	lw	a5,-400(s0)
    80004cfa:	e8845703          	lhu	a4,-376(s0)
    80004cfe:	c735                	beqz	a4,80004d6a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d00:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d02:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004d06:	6a05                	lui	s4,0x1
    80004d08:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d0c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d10:	6d85                	lui	s11,0x1
    80004d12:	7d7d                	lui	s10,0xfffff
    80004d14:	ac1d                	j	80004f4a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d16:	00004517          	auipc	a0,0x4
    80004d1a:	a3a50513          	addi	a0,a0,-1478 # 80008750 <syscalls+0x290>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	81c080e7          	jalr	-2020(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d26:	874a                	mv	a4,s2
    80004d28:	009c86bb          	addw	a3,s9,s1
    80004d2c:	4581                	li	a1,0
    80004d2e:	8556                	mv	a0,s5
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	ca4080e7          	jalr	-860(ra) # 800039d4 <readi>
    80004d38:	2501                	sext.w	a0,a0
    80004d3a:	1aa91863          	bne	s2,a0,80004eea <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d3e:	009d84bb          	addw	s1,s11,s1
    80004d42:	013d09bb          	addw	s3,s10,s3
    80004d46:	1f74f263          	bgeu	s1,s7,80004f2a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d4a:	02049593          	slli	a1,s1,0x20
    80004d4e:	9181                	srli	a1,a1,0x20
    80004d50:	95e2                	add	a1,a1,s8
    80004d52:	855a                	mv	a0,s6
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	2fe080e7          	jalr	766(ra) # 80001052 <walkaddr>
    80004d5c:	862a                	mv	a2,a0
    if(pa == 0)
    80004d5e:	dd45                	beqz	a0,80004d16 <exec+0xfe>
      n = PGSIZE;
    80004d60:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d62:	fd49f2e3          	bgeu	s3,s4,80004d26 <exec+0x10e>
      n = sz - i;
    80004d66:	894e                	mv	s2,s3
    80004d68:	bf7d                	j	80004d26 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d6a:	4481                	li	s1,0
  iunlockput(ip);
    80004d6c:	8556                	mv	a0,s5
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	c14080e7          	jalr	-1004(ra) # 80003982 <iunlockput>
  end_op();
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	404080e7          	jalr	1028(ra) # 8000417a <end_op>
  p = myproc();
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	d46080e7          	jalr	-698(ra) # 80001ac4 <myproc>
    80004d86:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d88:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d8c:	6785                	lui	a5,0x1
    80004d8e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d90:	97a6                	add	a5,a5,s1
    80004d92:	777d                	lui	a4,0xfffff
    80004d94:	8ff9                	and	a5,a5,a4
    80004d96:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d9a:	6609                	lui	a2,0x2
    80004d9c:	963e                	add	a2,a2,a5
    80004d9e:	85be                	mv	a1,a5
    80004da0:	855a                	mv	a0,s6
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	664080e7          	jalr	1636(ra) # 80001406 <uvmalloc>
    80004daa:	8c2a                	mv	s8,a0
  ip = 0;
    80004dac:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dae:	12050e63          	beqz	a0,80004eea <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004db2:	75f9                	lui	a1,0xffffe
    80004db4:	95aa                	add	a1,a1,a0
    80004db6:	855a                	mv	a0,s6
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	870080e7          	jalr	-1936(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dc0:	7afd                	lui	s5,0xfffff
    80004dc2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dc4:	df043783          	ld	a5,-528(s0)
    80004dc8:	6388                	ld	a0,0(a5)
    80004dca:	c925                	beqz	a0,80004e3a <exec+0x222>
    80004dcc:	e9040993          	addi	s3,s0,-368
    80004dd0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dd4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dd6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	070080e7          	jalr	112(ra) # 80000e48 <strlen>
    80004de0:	0015079b          	addiw	a5,a0,1
    80004de4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004de8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dec:	13596363          	bltu	s2,s5,80004f12 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004df0:	df043d83          	ld	s11,-528(s0)
    80004df4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004df8:	8552                	mv	a0,s4
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	04e080e7          	jalr	78(ra) # 80000e48 <strlen>
    80004e02:	0015069b          	addiw	a3,a0,1
    80004e06:	8652                	mv	a2,s4
    80004e08:	85ca                	mv	a1,s2
    80004e0a:	855a                	mv	a0,s6
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	84e080e7          	jalr	-1970(ra) # 8000165a <copyout>
    80004e14:	10054363          	bltz	a0,80004f1a <exec+0x302>
    ustack[argc] = sp;
    80004e18:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e1c:	0485                	addi	s1,s1,1
    80004e1e:	008d8793          	addi	a5,s11,8
    80004e22:	def43823          	sd	a5,-528(s0)
    80004e26:	008db503          	ld	a0,8(s11)
    80004e2a:	c911                	beqz	a0,80004e3e <exec+0x226>
    if(argc >= MAXARG)
    80004e2c:	09a1                	addi	s3,s3,8
    80004e2e:	fb3c95e3          	bne	s9,s3,80004dd8 <exec+0x1c0>
  sz = sz1;
    80004e32:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e36:	4a81                	li	s5,0
    80004e38:	a84d                	j	80004eea <exec+0x2d2>
  sp = sz;
    80004e3a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e3c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e3e:	00349793          	slli	a5,s1,0x3
    80004e42:	f9078793          	addi	a5,a5,-112
    80004e46:	97a2                	add	a5,a5,s0
    80004e48:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e4c:	00148693          	addi	a3,s1,1
    80004e50:	068e                	slli	a3,a3,0x3
    80004e52:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e56:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e5a:	01597663          	bgeu	s2,s5,80004e66 <exec+0x24e>
  sz = sz1;
    80004e5e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e62:	4a81                	li	s5,0
    80004e64:	a059                	j	80004eea <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e66:	e9040613          	addi	a2,s0,-368
    80004e6a:	85ca                	mv	a1,s2
    80004e6c:	855a                	mv	a0,s6
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	7ec080e7          	jalr	2028(ra) # 8000165a <copyout>
    80004e76:	0a054663          	bltz	a0,80004f22 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e7a:	058bb783          	ld	a5,88(s7)
    80004e7e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e82:	de843783          	ld	a5,-536(s0)
    80004e86:	0007c703          	lbu	a4,0(a5)
    80004e8a:	cf11                	beqz	a4,80004ea6 <exec+0x28e>
    80004e8c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e8e:	02f00693          	li	a3,47
    80004e92:	a039                	j	80004ea0 <exec+0x288>
      last = s+1;
    80004e94:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e98:	0785                	addi	a5,a5,1
    80004e9a:	fff7c703          	lbu	a4,-1(a5)
    80004e9e:	c701                	beqz	a4,80004ea6 <exec+0x28e>
    if(*s == '/')
    80004ea0:	fed71ce3          	bne	a4,a3,80004e98 <exec+0x280>
    80004ea4:	bfc5                	j	80004e94 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ea6:	4641                	li	a2,16
    80004ea8:	de843583          	ld	a1,-536(s0)
    80004eac:	158b8513          	addi	a0,s7,344
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	f66080e7          	jalr	-154(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eb8:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ebc:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ec0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ec4:	058bb783          	ld	a5,88(s7)
    80004ec8:	e6843703          	ld	a4,-408(s0)
    80004ecc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ece:	058bb783          	ld	a5,88(s7)
    80004ed2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ed6:	85ea                	mv	a1,s10
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	d4c080e7          	jalr	-692(ra) # 80001c24 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ee0:	0004851b          	sext.w	a0,s1
    80004ee4:	bbc1                	j	80004cb4 <exec+0x9c>
    80004ee6:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004eea:	df843583          	ld	a1,-520(s0)
    80004eee:	855a                	mv	a0,s6
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	d34080e7          	jalr	-716(ra) # 80001c24 <proc_freepagetable>
  if(ip){
    80004ef8:	da0a94e3          	bnez	s5,80004ca0 <exec+0x88>
  return -1;
    80004efc:	557d                	li	a0,-1
    80004efe:	bb5d                	j	80004cb4 <exec+0x9c>
    80004f00:	de943c23          	sd	s1,-520(s0)
    80004f04:	b7dd                	j	80004eea <exec+0x2d2>
    80004f06:	de943c23          	sd	s1,-520(s0)
    80004f0a:	b7c5                	j	80004eea <exec+0x2d2>
    80004f0c:	de943c23          	sd	s1,-520(s0)
    80004f10:	bfe9                	j	80004eea <exec+0x2d2>
  sz = sz1;
    80004f12:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f16:	4a81                	li	s5,0
    80004f18:	bfc9                	j	80004eea <exec+0x2d2>
  sz = sz1;
    80004f1a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f1e:	4a81                	li	s5,0
    80004f20:	b7e9                	j	80004eea <exec+0x2d2>
  sz = sz1;
    80004f22:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f26:	4a81                	li	s5,0
    80004f28:	b7c9                	j	80004eea <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f2a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f2e:	e0843783          	ld	a5,-504(s0)
    80004f32:	0017869b          	addiw	a3,a5,1
    80004f36:	e0d43423          	sd	a3,-504(s0)
    80004f3a:	e0043783          	ld	a5,-512(s0)
    80004f3e:	0387879b          	addiw	a5,a5,56
    80004f42:	e8845703          	lhu	a4,-376(s0)
    80004f46:	e2e6d3e3          	bge	a3,a4,80004d6c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f4a:	2781                	sext.w	a5,a5
    80004f4c:	e0f43023          	sd	a5,-512(s0)
    80004f50:	03800713          	li	a4,56
    80004f54:	86be                	mv	a3,a5
    80004f56:	e1840613          	addi	a2,s0,-488
    80004f5a:	4581                	li	a1,0
    80004f5c:	8556                	mv	a0,s5
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	a76080e7          	jalr	-1418(ra) # 800039d4 <readi>
    80004f66:	03800793          	li	a5,56
    80004f6a:	f6f51ee3          	bne	a0,a5,80004ee6 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f6e:	e1842783          	lw	a5,-488(s0)
    80004f72:	4705                	li	a4,1
    80004f74:	fae79de3          	bne	a5,a4,80004f2e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f78:	e4043603          	ld	a2,-448(s0)
    80004f7c:	e3843783          	ld	a5,-456(s0)
    80004f80:	f8f660e3          	bltu	a2,a5,80004f00 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f84:	e2843783          	ld	a5,-472(s0)
    80004f88:	963e                	add	a2,a2,a5
    80004f8a:	f6f66ee3          	bltu	a2,a5,80004f06 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f8e:	85a6                	mv	a1,s1
    80004f90:	855a                	mv	a0,s6
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	474080e7          	jalr	1140(ra) # 80001406 <uvmalloc>
    80004f9a:	dea43c23          	sd	a0,-520(s0)
    80004f9e:	d53d                	beqz	a0,80004f0c <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004fa0:	e2843c03          	ld	s8,-472(s0)
    80004fa4:	de043783          	ld	a5,-544(s0)
    80004fa8:	00fc77b3          	and	a5,s8,a5
    80004fac:	ff9d                	bnez	a5,80004eea <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fae:	e2042c83          	lw	s9,-480(s0)
    80004fb2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fb6:	f60b8ae3          	beqz	s7,80004f2a <exec+0x312>
    80004fba:	89de                	mv	s3,s7
    80004fbc:	4481                	li	s1,0
    80004fbe:	b371                	j	80004d4a <exec+0x132>

0000000080004fc0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fc0:	7179                	addi	sp,sp,-48
    80004fc2:	f406                	sd	ra,40(sp)
    80004fc4:	f022                	sd	s0,32(sp)
    80004fc6:	ec26                	sd	s1,24(sp)
    80004fc8:	e84a                	sd	s2,16(sp)
    80004fca:	1800                	addi	s0,sp,48
    80004fcc:	892e                	mv	s2,a1
    80004fce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fd0:	fdc40593          	addi	a1,s0,-36
    80004fd4:	ffffe097          	auipc	ra,0xffffe
    80004fd8:	ba6080e7          	jalr	-1114(ra) # 80002b7a <argint>
    80004fdc:	04054063          	bltz	a0,8000501c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fe0:	fdc42703          	lw	a4,-36(s0)
    80004fe4:	47bd                	li	a5,15
    80004fe6:	02e7ed63          	bltu	a5,a4,80005020 <argfd+0x60>
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	ada080e7          	jalr	-1318(ra) # 80001ac4 <myproc>
    80004ff2:	fdc42703          	lw	a4,-36(s0)
    80004ff6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004ffa:	078e                	slli	a5,a5,0x3
    80004ffc:	953e                	add	a0,a0,a5
    80004ffe:	611c                	ld	a5,0(a0)
    80005000:	c395                	beqz	a5,80005024 <argfd+0x64>
    return -1;
  if(pfd)
    80005002:	00090463          	beqz	s2,8000500a <argfd+0x4a>
    *pfd = fd;
    80005006:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000500a:	4501                	li	a0,0
  if(pf)
    8000500c:	c091                	beqz	s1,80005010 <argfd+0x50>
    *pf = f;
    8000500e:	e09c                	sd	a5,0(s1)
}
    80005010:	70a2                	ld	ra,40(sp)
    80005012:	7402                	ld	s0,32(sp)
    80005014:	64e2                	ld	s1,24(sp)
    80005016:	6942                	ld	s2,16(sp)
    80005018:	6145                	addi	sp,sp,48
    8000501a:	8082                	ret
    return -1;
    8000501c:	557d                	li	a0,-1
    8000501e:	bfcd                	j	80005010 <argfd+0x50>
    return -1;
    80005020:	557d                	li	a0,-1
    80005022:	b7fd                	j	80005010 <argfd+0x50>
    80005024:	557d                	li	a0,-1
    80005026:	b7ed                	j	80005010 <argfd+0x50>

0000000080005028 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005028:	1101                	addi	sp,sp,-32
    8000502a:	ec06                	sd	ra,24(sp)
    8000502c:	e822                	sd	s0,16(sp)
    8000502e:	e426                	sd	s1,8(sp)
    80005030:	1000                	addi	s0,sp,32
    80005032:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	a90080e7          	jalr	-1392(ra) # 80001ac4 <myproc>
    8000503c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000503e:	0d050793          	addi	a5,a0,208
    80005042:	4501                	li	a0,0
    80005044:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005046:	6398                	ld	a4,0(a5)
    80005048:	cb19                	beqz	a4,8000505e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000504a:	2505                	addiw	a0,a0,1
    8000504c:	07a1                	addi	a5,a5,8
    8000504e:	fed51ce3          	bne	a0,a3,80005046 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005052:	557d                	li	a0,-1
}
    80005054:	60e2                	ld	ra,24(sp)
    80005056:	6442                	ld	s0,16(sp)
    80005058:	64a2                	ld	s1,8(sp)
    8000505a:	6105                	addi	sp,sp,32
    8000505c:	8082                	ret
      p->ofile[fd] = f;
    8000505e:	01a50793          	addi	a5,a0,26
    80005062:	078e                	slli	a5,a5,0x3
    80005064:	963e                	add	a2,a2,a5
    80005066:	e204                	sd	s1,0(a2)
      return fd;
    80005068:	b7f5                	j	80005054 <fdalloc+0x2c>

000000008000506a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000506a:	715d                	addi	sp,sp,-80
    8000506c:	e486                	sd	ra,72(sp)
    8000506e:	e0a2                	sd	s0,64(sp)
    80005070:	fc26                	sd	s1,56(sp)
    80005072:	f84a                	sd	s2,48(sp)
    80005074:	f44e                	sd	s3,40(sp)
    80005076:	f052                	sd	s4,32(sp)
    80005078:	ec56                	sd	s5,24(sp)
    8000507a:	0880                	addi	s0,sp,80
    8000507c:	89ae                	mv	s3,a1
    8000507e:	8ab2                	mv	s5,a2
    80005080:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005082:	fb040593          	addi	a1,s0,-80
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	e74080e7          	jalr	-396(ra) # 80003efa <nameiparent>
    8000508e:	892a                	mv	s2,a0
    80005090:	12050e63          	beqz	a0,800051cc <create+0x162>
    return 0;

  ilock(dp);
    80005094:	ffffe097          	auipc	ra,0xffffe
    80005098:	68c080e7          	jalr	1676(ra) # 80003720 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000509c:	4601                	li	a2,0
    8000509e:	fb040593          	addi	a1,s0,-80
    800050a2:	854a                	mv	a0,s2
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	b60080e7          	jalr	-1184(ra) # 80003c04 <dirlookup>
    800050ac:	84aa                	mv	s1,a0
    800050ae:	c921                	beqz	a0,800050fe <create+0x94>
    iunlockput(dp);
    800050b0:	854a                	mv	a0,s2
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	8d0080e7          	jalr	-1840(ra) # 80003982 <iunlockput>
    ilock(ip);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	664080e7          	jalr	1636(ra) # 80003720 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050c4:	2981                	sext.w	s3,s3
    800050c6:	4789                	li	a5,2
    800050c8:	02f99463          	bne	s3,a5,800050f0 <create+0x86>
    800050cc:	0444d783          	lhu	a5,68(s1)
    800050d0:	37f9                	addiw	a5,a5,-2
    800050d2:	17c2                	slli	a5,a5,0x30
    800050d4:	93c1                	srli	a5,a5,0x30
    800050d6:	4705                	li	a4,1
    800050d8:	00f76c63          	bltu	a4,a5,800050f0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050dc:	8526                	mv	a0,s1
    800050de:	60a6                	ld	ra,72(sp)
    800050e0:	6406                	ld	s0,64(sp)
    800050e2:	74e2                	ld	s1,56(sp)
    800050e4:	7942                	ld	s2,48(sp)
    800050e6:	79a2                	ld	s3,40(sp)
    800050e8:	7a02                	ld	s4,32(sp)
    800050ea:	6ae2                	ld	s5,24(sp)
    800050ec:	6161                	addi	sp,sp,80
    800050ee:	8082                	ret
    iunlockput(ip);
    800050f0:	8526                	mv	a0,s1
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	890080e7          	jalr	-1904(ra) # 80003982 <iunlockput>
    return 0;
    800050fa:	4481                	li	s1,0
    800050fc:	b7c5                	j	800050dc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050fe:	85ce                	mv	a1,s3
    80005100:	00092503          	lw	a0,0(s2)
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	482080e7          	jalr	1154(ra) # 80003586 <ialloc>
    8000510c:	84aa                	mv	s1,a0
    8000510e:	c521                	beqz	a0,80005156 <create+0xec>
  ilock(ip);
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	610080e7          	jalr	1552(ra) # 80003720 <ilock>
  ip->major = major;
    80005118:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000511c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005120:	4a05                	li	s4,1
    80005122:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005126:	8526                	mv	a0,s1
    80005128:	ffffe097          	auipc	ra,0xffffe
    8000512c:	52c080e7          	jalr	1324(ra) # 80003654 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005130:	2981                	sext.w	s3,s3
    80005132:	03498a63          	beq	s3,s4,80005166 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005136:	40d0                	lw	a2,4(s1)
    80005138:	fb040593          	addi	a1,s0,-80
    8000513c:	854a                	mv	a0,s2
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	cdc080e7          	jalr	-804(ra) # 80003e1a <dirlink>
    80005146:	06054b63          	bltz	a0,800051bc <create+0x152>
  iunlockput(dp);
    8000514a:	854a                	mv	a0,s2
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	836080e7          	jalr	-1994(ra) # 80003982 <iunlockput>
  return ip;
    80005154:	b761                	j	800050dc <create+0x72>
    panic("create: ialloc");
    80005156:	00003517          	auipc	a0,0x3
    8000515a:	61a50513          	addi	a0,a0,1562 # 80008770 <syscalls+0x2b0>
    8000515e:	ffffb097          	auipc	ra,0xffffb
    80005162:	3dc080e7          	jalr	988(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005166:	04a95783          	lhu	a5,74(s2)
    8000516a:	2785                	addiw	a5,a5,1
    8000516c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005170:	854a                	mv	a0,s2
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	4e2080e7          	jalr	1250(ra) # 80003654 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000517a:	40d0                	lw	a2,4(s1)
    8000517c:	00003597          	auipc	a1,0x3
    80005180:	60458593          	addi	a1,a1,1540 # 80008780 <syscalls+0x2c0>
    80005184:	8526                	mv	a0,s1
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	c94080e7          	jalr	-876(ra) # 80003e1a <dirlink>
    8000518e:	00054f63          	bltz	a0,800051ac <create+0x142>
    80005192:	00492603          	lw	a2,4(s2)
    80005196:	00003597          	auipc	a1,0x3
    8000519a:	5f258593          	addi	a1,a1,1522 # 80008788 <syscalls+0x2c8>
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	c7a080e7          	jalr	-902(ra) # 80003e1a <dirlink>
    800051a8:	f80557e3          	bgez	a0,80005136 <create+0xcc>
      panic("create dots");
    800051ac:	00003517          	auipc	a0,0x3
    800051b0:	5e450513          	addi	a0,a0,1508 # 80008790 <syscalls+0x2d0>
    800051b4:	ffffb097          	auipc	ra,0xffffb
    800051b8:	386080e7          	jalr	902(ra) # 8000053a <panic>
    panic("create: dirlink");
    800051bc:	00003517          	auipc	a0,0x3
    800051c0:	5e450513          	addi	a0,a0,1508 # 800087a0 <syscalls+0x2e0>
    800051c4:	ffffb097          	auipc	ra,0xffffb
    800051c8:	376080e7          	jalr	886(ra) # 8000053a <panic>
    return 0;
    800051cc:	84aa                	mv	s1,a0
    800051ce:	b739                	j	800050dc <create+0x72>

00000000800051d0 <sys_dup>:
{
    800051d0:	7179                	addi	sp,sp,-48
    800051d2:	f406                	sd	ra,40(sp)
    800051d4:	f022                	sd	s0,32(sp)
    800051d6:	ec26                	sd	s1,24(sp)
    800051d8:	e84a                	sd	s2,16(sp)
    800051da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051dc:	fd840613          	addi	a2,s0,-40
    800051e0:	4581                	li	a1,0
    800051e2:	4501                	li	a0,0
    800051e4:	00000097          	auipc	ra,0x0
    800051e8:	ddc080e7          	jalr	-548(ra) # 80004fc0 <argfd>
    return -1;
    800051ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ee:	02054363          	bltz	a0,80005214 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051f2:	fd843903          	ld	s2,-40(s0)
    800051f6:	854a                	mv	a0,s2
    800051f8:	00000097          	auipc	ra,0x0
    800051fc:	e30080e7          	jalr	-464(ra) # 80005028 <fdalloc>
    80005200:	84aa                	mv	s1,a0
    return -1;
    80005202:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005204:	00054863          	bltz	a0,80005214 <sys_dup+0x44>
  filedup(f);
    80005208:	854a                	mv	a0,s2
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	368080e7          	jalr	872(ra) # 80004572 <filedup>
  return fd;
    80005212:	87a6                	mv	a5,s1
}
    80005214:	853e                	mv	a0,a5
    80005216:	70a2                	ld	ra,40(sp)
    80005218:	7402                	ld	s0,32(sp)
    8000521a:	64e2                	ld	s1,24(sp)
    8000521c:	6942                	ld	s2,16(sp)
    8000521e:	6145                	addi	sp,sp,48
    80005220:	8082                	ret

0000000080005222 <sys_read>:
{
    80005222:	7179                	addi	sp,sp,-48
    80005224:	f406                	sd	ra,40(sp)
    80005226:	f022                	sd	s0,32(sp)
    80005228:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522a:	fe840613          	addi	a2,s0,-24
    8000522e:	4581                	li	a1,0
    80005230:	4501                	li	a0,0
    80005232:	00000097          	auipc	ra,0x0
    80005236:	d8e080e7          	jalr	-626(ra) # 80004fc0 <argfd>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523c:	04054163          	bltz	a0,8000527e <sys_read+0x5c>
    80005240:	fe440593          	addi	a1,s0,-28
    80005244:	4509                	li	a0,2
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	934080e7          	jalr	-1740(ra) # 80002b7a <argint>
    return -1;
    8000524e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005250:	02054763          	bltz	a0,8000527e <sys_read+0x5c>
    80005254:	fd840593          	addi	a1,s0,-40
    80005258:	4505                	li	a0,1
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	942080e7          	jalr	-1726(ra) # 80002b9c <argaddr>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005264:	00054d63          	bltz	a0,8000527e <sys_read+0x5c>
  return fileread(f, p, n);
    80005268:	fe442603          	lw	a2,-28(s0)
    8000526c:	fd843583          	ld	a1,-40(s0)
    80005270:	fe843503          	ld	a0,-24(s0)
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	48a080e7          	jalr	1162(ra) # 800046fe <fileread>
    8000527c:	87aa                	mv	a5,a0
}
    8000527e:	853e                	mv	a0,a5
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret

0000000080005288 <sys_write>:
{
    80005288:	7179                	addi	sp,sp,-48
    8000528a:	f406                	sd	ra,40(sp)
    8000528c:	f022                	sd	s0,32(sp)
    8000528e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005290:	fe840613          	addi	a2,s0,-24
    80005294:	4581                	li	a1,0
    80005296:	4501                	li	a0,0
    80005298:	00000097          	auipc	ra,0x0
    8000529c:	d28080e7          	jalr	-728(ra) # 80004fc0 <argfd>
    return -1;
    800052a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	04054163          	bltz	a0,800052e4 <sys_write+0x5c>
    800052a6:	fe440593          	addi	a1,s0,-28
    800052aa:	4509                	li	a0,2
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	8ce080e7          	jalr	-1842(ra) # 80002b7a <argint>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b6:	02054763          	bltz	a0,800052e4 <sys_write+0x5c>
    800052ba:	fd840593          	addi	a1,s0,-40
    800052be:	4505                	li	a0,1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	8dc080e7          	jalr	-1828(ra) # 80002b9c <argaddr>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	00054d63          	bltz	a0,800052e4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052ce:	fe442603          	lw	a2,-28(s0)
    800052d2:	fd843583          	ld	a1,-40(s0)
    800052d6:	fe843503          	ld	a0,-24(s0)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	4e6080e7          	jalr	1254(ra) # 800047c0 <filewrite>
    800052e2:	87aa                	mv	a5,a0
}
    800052e4:	853e                	mv	a0,a5
    800052e6:	70a2                	ld	ra,40(sp)
    800052e8:	7402                	ld	s0,32(sp)
    800052ea:	6145                	addi	sp,sp,48
    800052ec:	8082                	ret

00000000800052ee <sys_close>:
{
    800052ee:	1101                	addi	sp,sp,-32
    800052f0:	ec06                	sd	ra,24(sp)
    800052f2:	e822                	sd	s0,16(sp)
    800052f4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052f6:	fe040613          	addi	a2,s0,-32
    800052fa:	fec40593          	addi	a1,s0,-20
    800052fe:	4501                	li	a0,0
    80005300:	00000097          	auipc	ra,0x0
    80005304:	cc0080e7          	jalr	-832(ra) # 80004fc0 <argfd>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000530a:	02054463          	bltz	a0,80005332 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	7b6080e7          	jalr	1974(ra) # 80001ac4 <myproc>
    80005316:	fec42783          	lw	a5,-20(s0)
    8000531a:	07e9                	addi	a5,a5,26
    8000531c:	078e                	slli	a5,a5,0x3
    8000531e:	953e                	add	a0,a0,a5
    80005320:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005324:	fe043503          	ld	a0,-32(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	29c080e7          	jalr	668(ra) # 800045c4 <fileclose>
  return 0;
    80005330:	4781                	li	a5,0
}
    80005332:	853e                	mv	a0,a5
    80005334:	60e2                	ld	ra,24(sp)
    80005336:	6442                	ld	s0,16(sp)
    80005338:	6105                	addi	sp,sp,32
    8000533a:	8082                	ret

000000008000533c <sys_fstat>:
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	c74080e7          	jalr	-908(ra) # 80004fc0 <argfd>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005356:	02054563          	bltz	a0,80005380 <sys_fstat+0x44>
    8000535a:	fe040593          	addi	a1,s0,-32
    8000535e:	4505                	li	a0,1
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	83c080e7          	jalr	-1988(ra) # 80002b9c <argaddr>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000536a:	00054b63          	bltz	a0,80005380 <sys_fstat+0x44>
  return filestat(f, st);
    8000536e:	fe043583          	ld	a1,-32(s0)
    80005372:	fe843503          	ld	a0,-24(s0)
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	316080e7          	jalr	790(ra) # 8000468c <filestat>
    8000537e:	87aa                	mv	a5,a0
}
    80005380:	853e                	mv	a0,a5
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	6105                	addi	sp,sp,32
    80005388:	8082                	ret

000000008000538a <sys_link>:
{
    8000538a:	7169                	addi	sp,sp,-304
    8000538c:	f606                	sd	ra,296(sp)
    8000538e:	f222                	sd	s0,288(sp)
    80005390:	ee26                	sd	s1,280(sp)
    80005392:	ea4a                	sd	s2,272(sp)
    80005394:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005396:	08000613          	li	a2,128
    8000539a:	ed040593          	addi	a1,s0,-304
    8000539e:	4501                	li	a0,0
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	81e080e7          	jalr	-2018(ra) # 80002bbe <argstr>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053aa:	10054e63          	bltz	a0,800054c6 <sys_link+0x13c>
    800053ae:	08000613          	li	a2,128
    800053b2:	f5040593          	addi	a1,s0,-176
    800053b6:	4505                	li	a0,1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	806080e7          	jalr	-2042(ra) # 80002bbe <argstr>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c2:	10054263          	bltz	a0,800054c6 <sys_link+0x13c>
  begin_op();
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	d36080e7          	jalr	-714(ra) # 800040fc <begin_op>
  if((ip = namei(old)) == 0){
    800053ce:	ed040513          	addi	a0,s0,-304
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	b0a080e7          	jalr	-1270(ra) # 80003edc <namei>
    800053da:	84aa                	mv	s1,a0
    800053dc:	c551                	beqz	a0,80005468 <sys_link+0xde>
  ilock(ip);
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	342080e7          	jalr	834(ra) # 80003720 <ilock>
  if(ip->type == T_DIR){
    800053e6:	04449703          	lh	a4,68(s1)
    800053ea:	4785                	li	a5,1
    800053ec:	08f70463          	beq	a4,a5,80005474 <sys_link+0xea>
  ip->nlink++;
    800053f0:	04a4d783          	lhu	a5,74(s1)
    800053f4:	2785                	addiw	a5,a5,1
    800053f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053fa:	8526                	mv	a0,s1
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	258080e7          	jalr	600(ra) # 80003654 <iupdate>
  iunlock(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	3dc080e7          	jalr	988(ra) # 800037e2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000540e:	fd040593          	addi	a1,s0,-48
    80005412:	f5040513          	addi	a0,s0,-176
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	ae4080e7          	jalr	-1308(ra) # 80003efa <nameiparent>
    8000541e:	892a                	mv	s2,a0
    80005420:	c935                	beqz	a0,80005494 <sys_link+0x10a>
  ilock(dp);
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	2fe080e7          	jalr	766(ra) # 80003720 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000542a:	00092703          	lw	a4,0(s2)
    8000542e:	409c                	lw	a5,0(s1)
    80005430:	04f71d63          	bne	a4,a5,8000548a <sys_link+0x100>
    80005434:	40d0                	lw	a2,4(s1)
    80005436:	fd040593          	addi	a1,s0,-48
    8000543a:	854a                	mv	a0,s2
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	9de080e7          	jalr	-1570(ra) # 80003e1a <dirlink>
    80005444:	04054363          	bltz	a0,8000548a <sys_link+0x100>
  iunlockput(dp);
    80005448:	854a                	mv	a0,s2
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	538080e7          	jalr	1336(ra) # 80003982 <iunlockput>
  iput(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	486080e7          	jalr	1158(ra) # 800038da <iput>
  end_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	d1e080e7          	jalr	-738(ra) # 8000417a <end_op>
  return 0;
    80005464:	4781                	li	a5,0
    80005466:	a085                	j	800054c6 <sys_link+0x13c>
    end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	d12080e7          	jalr	-750(ra) # 8000417a <end_op>
    return -1;
    80005470:	57fd                	li	a5,-1
    80005472:	a891                	j	800054c6 <sys_link+0x13c>
    iunlockput(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	50c080e7          	jalr	1292(ra) # 80003982 <iunlockput>
    end_op();
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	cfc080e7          	jalr	-772(ra) # 8000417a <end_op>
    return -1;
    80005486:	57fd                	li	a5,-1
    80005488:	a83d                	j	800054c6 <sys_link+0x13c>
    iunlockput(dp);
    8000548a:	854a                	mv	a0,s2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	4f6080e7          	jalr	1270(ra) # 80003982 <iunlockput>
  ilock(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	28a080e7          	jalr	650(ra) # 80003720 <ilock>
  ip->nlink--;
    8000549e:	04a4d783          	lhu	a5,74(s1)
    800054a2:	37fd                	addiw	a5,a5,-1
    800054a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	1aa080e7          	jalr	426(ra) # 80003654 <iupdate>
  iunlockput(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	4ce080e7          	jalr	1230(ra) # 80003982 <iunlockput>
  end_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	cbe080e7          	jalr	-834(ra) # 8000417a <end_op>
  return -1;
    800054c4:	57fd                	li	a5,-1
}
    800054c6:	853e                	mv	a0,a5
    800054c8:	70b2                	ld	ra,296(sp)
    800054ca:	7412                	ld	s0,288(sp)
    800054cc:	64f2                	ld	s1,280(sp)
    800054ce:	6952                	ld	s2,272(sp)
    800054d0:	6155                	addi	sp,sp,304
    800054d2:	8082                	ret

00000000800054d4 <sys_unlink>:
{
    800054d4:	7151                	addi	sp,sp,-240
    800054d6:	f586                	sd	ra,232(sp)
    800054d8:	f1a2                	sd	s0,224(sp)
    800054da:	eda6                	sd	s1,216(sp)
    800054dc:	e9ca                	sd	s2,208(sp)
    800054de:	e5ce                	sd	s3,200(sp)
    800054e0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054e2:	08000613          	li	a2,128
    800054e6:	f3040593          	addi	a1,s0,-208
    800054ea:	4501                	li	a0,0
    800054ec:	ffffd097          	auipc	ra,0xffffd
    800054f0:	6d2080e7          	jalr	1746(ra) # 80002bbe <argstr>
    800054f4:	18054163          	bltz	a0,80005676 <sys_unlink+0x1a2>
  begin_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	c04080e7          	jalr	-1020(ra) # 800040fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005500:	fb040593          	addi	a1,s0,-80
    80005504:	f3040513          	addi	a0,s0,-208
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	9f2080e7          	jalr	-1550(ra) # 80003efa <nameiparent>
    80005510:	84aa                	mv	s1,a0
    80005512:	c979                	beqz	a0,800055e8 <sys_unlink+0x114>
  ilock(dp);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	20c080e7          	jalr	524(ra) # 80003720 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000551c:	00003597          	auipc	a1,0x3
    80005520:	26458593          	addi	a1,a1,612 # 80008780 <syscalls+0x2c0>
    80005524:	fb040513          	addi	a0,s0,-80
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	6c2080e7          	jalr	1730(ra) # 80003bea <namecmp>
    80005530:	14050a63          	beqz	a0,80005684 <sys_unlink+0x1b0>
    80005534:	00003597          	auipc	a1,0x3
    80005538:	25458593          	addi	a1,a1,596 # 80008788 <syscalls+0x2c8>
    8000553c:	fb040513          	addi	a0,s0,-80
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	6aa080e7          	jalr	1706(ra) # 80003bea <namecmp>
    80005548:	12050e63          	beqz	a0,80005684 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000554c:	f2c40613          	addi	a2,s0,-212
    80005550:	fb040593          	addi	a1,s0,-80
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	6ae080e7          	jalr	1710(ra) # 80003c04 <dirlookup>
    8000555e:	892a                	mv	s2,a0
    80005560:	12050263          	beqz	a0,80005684 <sys_unlink+0x1b0>
  ilock(ip);
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	1bc080e7          	jalr	444(ra) # 80003720 <ilock>
  if(ip->nlink < 1)
    8000556c:	04a91783          	lh	a5,74(s2)
    80005570:	08f05263          	blez	a5,800055f4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005574:	04491703          	lh	a4,68(s2)
    80005578:	4785                	li	a5,1
    8000557a:	08f70563          	beq	a4,a5,80005604 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000557e:	4641                	li	a2,16
    80005580:	4581                	li	a1,0
    80005582:	fc040513          	addi	a0,s0,-64
    80005586:	ffffb097          	auipc	ra,0xffffb
    8000558a:	746080e7          	jalr	1862(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000558e:	4741                	li	a4,16
    80005590:	f2c42683          	lw	a3,-212(s0)
    80005594:	fc040613          	addi	a2,s0,-64
    80005598:	4581                	li	a1,0
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	530080e7          	jalr	1328(ra) # 80003acc <writei>
    800055a4:	47c1                	li	a5,16
    800055a6:	0af51563          	bne	a0,a5,80005650 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055aa:	04491703          	lh	a4,68(s2)
    800055ae:	4785                	li	a5,1
    800055b0:	0af70863          	beq	a4,a5,80005660 <sys_unlink+0x18c>
  iunlockput(dp);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	3cc080e7          	jalr	972(ra) # 80003982 <iunlockput>
  ip->nlink--;
    800055be:	04a95783          	lhu	a5,74(s2)
    800055c2:	37fd                	addiw	a5,a5,-1
    800055c4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055c8:	854a                	mv	a0,s2
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	08a080e7          	jalr	138(ra) # 80003654 <iupdate>
  iunlockput(ip);
    800055d2:	854a                	mv	a0,s2
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	3ae080e7          	jalr	942(ra) # 80003982 <iunlockput>
  end_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	b9e080e7          	jalr	-1122(ra) # 8000417a <end_op>
  return 0;
    800055e4:	4501                	li	a0,0
    800055e6:	a84d                	j	80005698 <sys_unlink+0x1c4>
    end_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	b92080e7          	jalr	-1134(ra) # 8000417a <end_op>
    return -1;
    800055f0:	557d                	li	a0,-1
    800055f2:	a05d                	j	80005698 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055f4:	00003517          	auipc	a0,0x3
    800055f8:	1bc50513          	addi	a0,a0,444 # 800087b0 <syscalls+0x2f0>
    800055fc:	ffffb097          	auipc	ra,0xffffb
    80005600:	f3e080e7          	jalr	-194(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005604:	04c92703          	lw	a4,76(s2)
    80005608:	02000793          	li	a5,32
    8000560c:	f6e7f9e3          	bgeu	a5,a4,8000557e <sys_unlink+0xaa>
    80005610:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005614:	4741                	li	a4,16
    80005616:	86ce                	mv	a3,s3
    80005618:	f1840613          	addi	a2,s0,-232
    8000561c:	4581                	li	a1,0
    8000561e:	854a                	mv	a0,s2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	3b4080e7          	jalr	948(ra) # 800039d4 <readi>
    80005628:	47c1                	li	a5,16
    8000562a:	00f51b63          	bne	a0,a5,80005640 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000562e:	f1845783          	lhu	a5,-232(s0)
    80005632:	e7a1                	bnez	a5,8000567a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005634:	29c1                	addiw	s3,s3,16
    80005636:	04c92783          	lw	a5,76(s2)
    8000563a:	fcf9ede3          	bltu	s3,a5,80005614 <sys_unlink+0x140>
    8000563e:	b781                	j	8000557e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005640:	00003517          	auipc	a0,0x3
    80005644:	18850513          	addi	a0,a0,392 # 800087c8 <syscalls+0x308>
    80005648:	ffffb097          	auipc	ra,0xffffb
    8000564c:	ef2080e7          	jalr	-270(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005650:	00003517          	auipc	a0,0x3
    80005654:	19050513          	addi	a0,a0,400 # 800087e0 <syscalls+0x320>
    80005658:	ffffb097          	auipc	ra,0xffffb
    8000565c:	ee2080e7          	jalr	-286(ra) # 8000053a <panic>
    dp->nlink--;
    80005660:	04a4d783          	lhu	a5,74(s1)
    80005664:	37fd                	addiw	a5,a5,-1
    80005666:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	fe8080e7          	jalr	-24(ra) # 80003654 <iupdate>
    80005674:	b781                	j	800055b4 <sys_unlink+0xe0>
    return -1;
    80005676:	557d                	li	a0,-1
    80005678:	a005                	j	80005698 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	306080e7          	jalr	774(ra) # 80003982 <iunlockput>
  iunlockput(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	2fc080e7          	jalr	764(ra) # 80003982 <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	aec080e7          	jalr	-1300(ra) # 8000417a <end_op>
  return -1;
    80005696:	557d                	li	a0,-1
}
    80005698:	70ae                	ld	ra,232(sp)
    8000569a:	740e                	ld	s0,224(sp)
    8000569c:	64ee                	ld	s1,216(sp)
    8000569e:	694e                	ld	s2,208(sp)
    800056a0:	69ae                	ld	s3,200(sp)
    800056a2:	616d                	addi	sp,sp,240
    800056a4:	8082                	ret

00000000800056a6 <sys_open>:

uint64
sys_open(void)
{
    800056a6:	7131                	addi	sp,sp,-192
    800056a8:	fd06                	sd	ra,184(sp)
    800056aa:	f922                	sd	s0,176(sp)
    800056ac:	f526                	sd	s1,168(sp)
    800056ae:	f14a                	sd	s2,160(sp)
    800056b0:	ed4e                	sd	s3,152(sp)
    800056b2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056b4:	08000613          	li	a2,128
    800056b8:	f5040593          	addi	a1,s0,-176
    800056bc:	4501                	li	a0,0
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	500080e7          	jalr	1280(ra) # 80002bbe <argstr>
    return -1;
    800056c6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c8:	0c054163          	bltz	a0,8000578a <sys_open+0xe4>
    800056cc:	f4c40593          	addi	a1,s0,-180
    800056d0:	4505                	li	a0,1
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	4a8080e7          	jalr	1192(ra) # 80002b7a <argint>
    800056da:	0a054863          	bltz	a0,8000578a <sys_open+0xe4>

  begin_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	a1e080e7          	jalr	-1506(ra) # 800040fc <begin_op>

  if(omode & O_CREATE){
    800056e6:	f4c42783          	lw	a5,-180(s0)
    800056ea:	2007f793          	andi	a5,a5,512
    800056ee:	cbdd                	beqz	a5,800057a4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056f0:	4681                	li	a3,0
    800056f2:	4601                	li	a2,0
    800056f4:	4589                	li	a1,2
    800056f6:	f5040513          	addi	a0,s0,-176
    800056fa:	00000097          	auipc	ra,0x0
    800056fe:	970080e7          	jalr	-1680(ra) # 8000506a <create>
    80005702:	892a                	mv	s2,a0
    if(ip == 0){
    80005704:	c959                	beqz	a0,8000579a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005706:	04491703          	lh	a4,68(s2)
    8000570a:	478d                	li	a5,3
    8000570c:	00f71763          	bne	a4,a5,8000571a <sys_open+0x74>
    80005710:	04695703          	lhu	a4,70(s2)
    80005714:	47a5                	li	a5,9
    80005716:	0ce7ec63          	bltu	a5,a4,800057ee <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	dee080e7          	jalr	-530(ra) # 80004508 <filealloc>
    80005722:	89aa                	mv	s3,a0
    80005724:	10050263          	beqz	a0,80005828 <sys_open+0x182>
    80005728:	00000097          	auipc	ra,0x0
    8000572c:	900080e7          	jalr	-1792(ra) # 80005028 <fdalloc>
    80005730:	84aa                	mv	s1,a0
    80005732:	0e054663          	bltz	a0,8000581e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005736:	04491703          	lh	a4,68(s2)
    8000573a:	478d                	li	a5,3
    8000573c:	0cf70463          	beq	a4,a5,80005804 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005740:	4789                	li	a5,2
    80005742:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005746:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000574a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000574e:	f4c42783          	lw	a5,-180(s0)
    80005752:	0017c713          	xori	a4,a5,1
    80005756:	8b05                	andi	a4,a4,1
    80005758:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000575c:	0037f713          	andi	a4,a5,3
    80005760:	00e03733          	snez	a4,a4
    80005764:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005768:	4007f793          	andi	a5,a5,1024
    8000576c:	c791                	beqz	a5,80005778 <sys_open+0xd2>
    8000576e:	04491703          	lh	a4,68(s2)
    80005772:	4789                	li	a5,2
    80005774:	08f70f63          	beq	a4,a5,80005812 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	068080e7          	jalr	104(ra) # 800037e2 <iunlock>
  end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	9f8080e7          	jalr	-1544(ra) # 8000417a <end_op>

  return fd;
}
    8000578a:	8526                	mv	a0,s1
    8000578c:	70ea                	ld	ra,184(sp)
    8000578e:	744a                	ld	s0,176(sp)
    80005790:	74aa                	ld	s1,168(sp)
    80005792:	790a                	ld	s2,160(sp)
    80005794:	69ea                	ld	s3,152(sp)
    80005796:	6129                	addi	sp,sp,192
    80005798:	8082                	ret
      end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	9e0080e7          	jalr	-1568(ra) # 8000417a <end_op>
      return -1;
    800057a2:	b7e5                	j	8000578a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057a4:	f5040513          	addi	a0,s0,-176
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	734080e7          	jalr	1844(ra) # 80003edc <namei>
    800057b0:	892a                	mv	s2,a0
    800057b2:	c905                	beqz	a0,800057e2 <sys_open+0x13c>
    ilock(ip);
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	f6c080e7          	jalr	-148(ra) # 80003720 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057bc:	04491703          	lh	a4,68(s2)
    800057c0:	4785                	li	a5,1
    800057c2:	f4f712e3          	bne	a4,a5,80005706 <sys_open+0x60>
    800057c6:	f4c42783          	lw	a5,-180(s0)
    800057ca:	dba1                	beqz	a5,8000571a <sys_open+0x74>
      iunlockput(ip);
    800057cc:	854a                	mv	a0,s2
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	1b4080e7          	jalr	436(ra) # 80003982 <iunlockput>
      end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	9a4080e7          	jalr	-1628(ra) # 8000417a <end_op>
      return -1;
    800057de:	54fd                	li	s1,-1
    800057e0:	b76d                	j	8000578a <sys_open+0xe4>
      end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	998080e7          	jalr	-1640(ra) # 8000417a <end_op>
      return -1;
    800057ea:	54fd                	li	s1,-1
    800057ec:	bf79                	j	8000578a <sys_open+0xe4>
    iunlockput(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	192080e7          	jalr	402(ra) # 80003982 <iunlockput>
    end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	982080e7          	jalr	-1662(ra) # 8000417a <end_op>
    return -1;
    80005800:	54fd                	li	s1,-1
    80005802:	b761                	j	8000578a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005804:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005808:	04691783          	lh	a5,70(s2)
    8000580c:	02f99223          	sh	a5,36(s3)
    80005810:	bf2d                	j	8000574a <sys_open+0xa4>
    itrunc(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	01a080e7          	jalr	26(ra) # 8000382e <itrunc>
    8000581c:	bfb1                	j	80005778 <sys_open+0xd2>
      fileclose(f);
    8000581e:	854e                	mv	a0,s3
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	da4080e7          	jalr	-604(ra) # 800045c4 <fileclose>
    iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	158080e7          	jalr	344(ra) # 80003982 <iunlockput>
    end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	948080e7          	jalr	-1720(ra) # 8000417a <end_op>
    return -1;
    8000583a:	54fd                	li	s1,-1
    8000583c:	b7b9                	j	8000578a <sys_open+0xe4>

000000008000583e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000583e:	7175                	addi	sp,sp,-144
    80005840:	e506                	sd	ra,136(sp)
    80005842:	e122                	sd	s0,128(sp)
    80005844:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	8b6080e7          	jalr	-1866(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000584e:	08000613          	li	a2,128
    80005852:	f7040593          	addi	a1,s0,-144
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	366080e7          	jalr	870(ra) # 80002bbe <argstr>
    80005860:	02054963          	bltz	a0,80005892 <sys_mkdir+0x54>
    80005864:	4681                	li	a3,0
    80005866:	4601                	li	a2,0
    80005868:	4585                	li	a1,1
    8000586a:	f7040513          	addi	a0,s0,-144
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	7fc080e7          	jalr	2044(ra) # 8000506a <create>
    80005876:	cd11                	beqz	a0,80005892 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	10a080e7          	jalr	266(ra) # 80003982 <iunlockput>
  end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	8fa080e7          	jalr	-1798(ra) # 8000417a <end_op>
  return 0;
    80005888:	4501                	li	a0,0
}
    8000588a:	60aa                	ld	ra,136(sp)
    8000588c:	640a                	ld	s0,128(sp)
    8000588e:	6149                	addi	sp,sp,144
    80005890:	8082                	ret
    end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	8e8080e7          	jalr	-1816(ra) # 8000417a <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b7fd                	j	8000588a <sys_mkdir+0x4c>

000000008000589e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000589e:	7135                	addi	sp,sp,-160
    800058a0:	ed06                	sd	ra,152(sp)
    800058a2:	e922                	sd	s0,144(sp)
    800058a4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	856080e7          	jalr	-1962(ra) # 800040fc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ae:	08000613          	li	a2,128
    800058b2:	f7040593          	addi	a1,s0,-144
    800058b6:	4501                	li	a0,0
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	306080e7          	jalr	774(ra) # 80002bbe <argstr>
    800058c0:	04054a63          	bltz	a0,80005914 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058c4:	f6c40593          	addi	a1,s0,-148
    800058c8:	4505                	li	a0,1
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	2b0080e7          	jalr	688(ra) # 80002b7a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058d2:	04054163          	bltz	a0,80005914 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058d6:	f6840593          	addi	a1,s0,-152
    800058da:	4509                	li	a0,2
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	29e080e7          	jalr	670(ra) # 80002b7a <argint>
     argint(1, &major) < 0 ||
    800058e4:	02054863          	bltz	a0,80005914 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058e8:	f6841683          	lh	a3,-152(s0)
    800058ec:	f6c41603          	lh	a2,-148(s0)
    800058f0:	458d                	li	a1,3
    800058f2:	f7040513          	addi	a0,s0,-144
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	774080e7          	jalr	1908(ra) # 8000506a <create>
     argint(2, &minor) < 0 ||
    800058fe:	c919                	beqz	a0,80005914 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	082080e7          	jalr	130(ra) # 80003982 <iunlockput>
  end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	872080e7          	jalr	-1934(ra) # 8000417a <end_op>
  return 0;
    80005910:	4501                	li	a0,0
    80005912:	a031                	j	8000591e <sys_mknod+0x80>
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	866080e7          	jalr	-1946(ra) # 8000417a <end_op>
    return -1;
    8000591c:	557d                	li	a0,-1
}
    8000591e:	60ea                	ld	ra,152(sp)
    80005920:	644a                	ld	s0,144(sp)
    80005922:	610d                	addi	sp,sp,160
    80005924:	8082                	ret

0000000080005926 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005926:	7135                	addi	sp,sp,-160
    80005928:	ed06                	sd	ra,152(sp)
    8000592a:	e922                	sd	s0,144(sp)
    8000592c:	e526                	sd	s1,136(sp)
    8000592e:	e14a                	sd	s2,128(sp)
    80005930:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005932:	ffffc097          	auipc	ra,0xffffc
    80005936:	192080e7          	jalr	402(ra) # 80001ac4 <myproc>
    8000593a:	892a                	mv	s2,a0
  
  begin_op();
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	7c0080e7          	jalr	1984(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005944:	08000613          	li	a2,128
    80005948:	f6040593          	addi	a1,s0,-160
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	270080e7          	jalr	624(ra) # 80002bbe <argstr>
    80005956:	04054b63          	bltz	a0,800059ac <sys_chdir+0x86>
    8000595a:	f6040513          	addi	a0,s0,-160
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	57e080e7          	jalr	1406(ra) # 80003edc <namei>
    80005966:	84aa                	mv	s1,a0
    80005968:	c131                	beqz	a0,800059ac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	db6080e7          	jalr	-586(ra) # 80003720 <ilock>
  if(ip->type != T_DIR){
    80005972:	04449703          	lh	a4,68(s1)
    80005976:	4785                	li	a5,1
    80005978:	04f71063          	bne	a4,a5,800059b8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	e64080e7          	jalr	-412(ra) # 800037e2 <iunlock>
  iput(p->cwd);
    80005986:	15093503          	ld	a0,336(s2)
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	f50080e7          	jalr	-176(ra) # 800038da <iput>
  end_op();
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	7e8080e7          	jalr	2024(ra) # 8000417a <end_op>
  p->cwd = ip;
    8000599a:	14993823          	sd	s1,336(s2)
  return 0;
    8000599e:	4501                	li	a0,0
}
    800059a0:	60ea                	ld	ra,152(sp)
    800059a2:	644a                	ld	s0,144(sp)
    800059a4:	64aa                	ld	s1,136(sp)
    800059a6:	690a                	ld	s2,128(sp)
    800059a8:	610d                	addi	sp,sp,160
    800059aa:	8082                	ret
    end_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	7ce080e7          	jalr	1998(ra) # 8000417a <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	b7ed                	j	800059a0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	fc8080e7          	jalr	-56(ra) # 80003982 <iunlockput>
    end_op();
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	7b8080e7          	jalr	1976(ra) # 8000417a <end_op>
    return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	bfd1                	j	800059a0 <sys_chdir+0x7a>

00000000800059ce <sys_exec>:

uint64
sys_exec(void)
{
    800059ce:	7145                	addi	sp,sp,-464
    800059d0:	e786                	sd	ra,456(sp)
    800059d2:	e3a2                	sd	s0,448(sp)
    800059d4:	ff26                	sd	s1,440(sp)
    800059d6:	fb4a                	sd	s2,432(sp)
    800059d8:	f74e                	sd	s3,424(sp)
    800059da:	f352                	sd	s4,416(sp)
    800059dc:	ef56                	sd	s5,408(sp)
    800059de:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059e0:	08000613          	li	a2,128
    800059e4:	f4040593          	addi	a1,s0,-192
    800059e8:	4501                	li	a0,0
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	1d4080e7          	jalr	468(ra) # 80002bbe <argstr>
    return -1;
    800059f2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059f4:	0c054b63          	bltz	a0,80005aca <sys_exec+0xfc>
    800059f8:	e3840593          	addi	a1,s0,-456
    800059fc:	4505                	li	a0,1
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	19e080e7          	jalr	414(ra) # 80002b9c <argaddr>
    80005a06:	0c054263          	bltz	a0,80005aca <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a0a:	10000613          	li	a2,256
    80005a0e:	4581                	li	a1,0
    80005a10:	e4040513          	addi	a0,s0,-448
    80005a14:	ffffb097          	auipc	ra,0xffffb
    80005a18:	2b8080e7          	jalr	696(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a1c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a20:	89a6                	mv	s3,s1
    80005a22:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a24:	02000a13          	li	s4,32
    80005a28:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a2c:	00391513          	slli	a0,s2,0x3
    80005a30:	e3040593          	addi	a1,s0,-464
    80005a34:	e3843783          	ld	a5,-456(s0)
    80005a38:	953e                	add	a0,a0,a5
    80005a3a:	ffffd097          	auipc	ra,0xffffd
    80005a3e:	0a6080e7          	jalr	166(ra) # 80002ae0 <fetchaddr>
    80005a42:	02054a63          	bltz	a0,80005a76 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a46:	e3043783          	ld	a5,-464(s0)
    80005a4a:	c3b9                	beqz	a5,80005a90 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	094080e7          	jalr	148(ra) # 80000ae0 <kalloc>
    80005a54:	85aa                	mv	a1,a0
    80005a56:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a5a:	cd11                	beqz	a0,80005a76 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a5c:	6605                	lui	a2,0x1
    80005a5e:	e3043503          	ld	a0,-464(s0)
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	0d0080e7          	jalr	208(ra) # 80002b32 <fetchstr>
    80005a6a:	00054663          	bltz	a0,80005a76 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a6e:	0905                	addi	s2,s2,1
    80005a70:	09a1                	addi	s3,s3,8
    80005a72:	fb491be3          	bne	s2,s4,80005a28 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a76:	f4040913          	addi	s2,s0,-192
    80005a7a:	6088                	ld	a0,0(s1)
    80005a7c:	c531                	beqz	a0,80005ac8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	f64080e7          	jalr	-156(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a86:	04a1                	addi	s1,s1,8
    80005a88:	ff2499e3          	bne	s1,s2,80005a7a <sys_exec+0xac>
  return -1;
    80005a8c:	597d                	li	s2,-1
    80005a8e:	a835                	j	80005aca <sys_exec+0xfc>
      argv[i] = 0;
    80005a90:	0a8e                	slli	s5,s5,0x3
    80005a92:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a96:	00878ab3          	add	s5,a5,s0
    80005a9a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a9e:	e4040593          	addi	a1,s0,-448
    80005aa2:	f4040513          	addi	a0,s0,-192
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	172080e7          	jalr	370(ra) # 80004c18 <exec>
    80005aae:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab0:	f4040993          	addi	s3,s0,-192
    80005ab4:	6088                	ld	a0,0(s1)
    80005ab6:	c911                	beqz	a0,80005aca <sys_exec+0xfc>
    kfree(argv[i]);
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	f2a080e7          	jalr	-214(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac0:	04a1                	addi	s1,s1,8
    80005ac2:	ff3499e3          	bne	s1,s3,80005ab4 <sys_exec+0xe6>
    80005ac6:	a011                	j	80005aca <sys_exec+0xfc>
  return -1;
    80005ac8:	597d                	li	s2,-1
}
    80005aca:	854a                	mv	a0,s2
    80005acc:	60be                	ld	ra,456(sp)
    80005ace:	641e                	ld	s0,448(sp)
    80005ad0:	74fa                	ld	s1,440(sp)
    80005ad2:	795a                	ld	s2,432(sp)
    80005ad4:	79ba                	ld	s3,424(sp)
    80005ad6:	7a1a                	ld	s4,416(sp)
    80005ad8:	6afa                	ld	s5,408(sp)
    80005ada:	6179                	addi	sp,sp,464
    80005adc:	8082                	ret

0000000080005ade <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ade:	7139                	addi	sp,sp,-64
    80005ae0:	fc06                	sd	ra,56(sp)
    80005ae2:	f822                	sd	s0,48(sp)
    80005ae4:	f426                	sd	s1,40(sp)
    80005ae6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ae8:	ffffc097          	auipc	ra,0xffffc
    80005aec:	fdc080e7          	jalr	-36(ra) # 80001ac4 <myproc>
    80005af0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005af2:	fd840593          	addi	a1,s0,-40
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	0a4080e7          	jalr	164(ra) # 80002b9c <argaddr>
    return -1;
    80005b00:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b02:	0e054063          	bltz	a0,80005be2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b06:	fc840593          	addi	a1,s0,-56
    80005b0a:	fd040513          	addi	a0,s0,-48
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	de6080e7          	jalr	-538(ra) # 800048f4 <pipealloc>
    return -1;
    80005b16:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b18:	0c054563          	bltz	a0,80005be2 <sys_pipe+0x104>
  fd0 = -1;
    80005b1c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b20:	fd043503          	ld	a0,-48(s0)
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	504080e7          	jalr	1284(ra) # 80005028 <fdalloc>
    80005b2c:	fca42223          	sw	a0,-60(s0)
    80005b30:	08054c63          	bltz	a0,80005bc8 <sys_pipe+0xea>
    80005b34:	fc843503          	ld	a0,-56(s0)
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	4f0080e7          	jalr	1264(ra) # 80005028 <fdalloc>
    80005b40:	fca42023          	sw	a0,-64(s0)
    80005b44:	06054963          	bltz	a0,80005bb6 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b48:	4691                	li	a3,4
    80005b4a:	fc440613          	addi	a2,s0,-60
    80005b4e:	fd843583          	ld	a1,-40(s0)
    80005b52:	68a8                	ld	a0,80(s1)
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	b06080e7          	jalr	-1274(ra) # 8000165a <copyout>
    80005b5c:	02054063          	bltz	a0,80005b7c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b60:	4691                	li	a3,4
    80005b62:	fc040613          	addi	a2,s0,-64
    80005b66:	fd843583          	ld	a1,-40(s0)
    80005b6a:	0591                	addi	a1,a1,4
    80005b6c:	68a8                	ld	a0,80(s1)
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	aec080e7          	jalr	-1300(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b76:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b78:	06055563          	bgez	a0,80005be2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b7c:	fc442783          	lw	a5,-60(s0)
    80005b80:	07e9                	addi	a5,a5,26
    80005b82:	078e                	slli	a5,a5,0x3
    80005b84:	97a6                	add	a5,a5,s1
    80005b86:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b8a:	fc042783          	lw	a5,-64(s0)
    80005b8e:	07e9                	addi	a5,a5,26
    80005b90:	078e                	slli	a5,a5,0x3
    80005b92:	00f48533          	add	a0,s1,a5
    80005b96:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b9a:	fd043503          	ld	a0,-48(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	a26080e7          	jalr	-1498(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005ba6:	fc843503          	ld	a0,-56(s0)
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	a1a080e7          	jalr	-1510(ra) # 800045c4 <fileclose>
    return -1;
    80005bb2:	57fd                	li	a5,-1
    80005bb4:	a03d                	j	80005be2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bb6:	fc442783          	lw	a5,-60(s0)
    80005bba:	0007c763          	bltz	a5,80005bc8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bbe:	07e9                	addi	a5,a5,26
    80005bc0:	078e                	slli	a5,a5,0x3
    80005bc2:	97a6                	add	a5,a5,s1
    80005bc4:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bc8:	fd043503          	ld	a0,-48(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	9f8080e7          	jalr	-1544(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005bd4:	fc843503          	ld	a0,-56(s0)
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	9ec080e7          	jalr	-1556(ra) # 800045c4 <fileclose>
    return -1;
    80005be0:	57fd                	li	a5,-1
}
    80005be2:	853e                	mv	a0,a5
    80005be4:	70e2                	ld	ra,56(sp)
    80005be6:	7442                	ld	s0,48(sp)
    80005be8:	74a2                	ld	s1,40(sp)
    80005bea:	6121                	addi	sp,sp,64
    80005bec:	8082                	ret
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	d7dfc0ef          	jal	ra,800029ac <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	6d0c                	ld	a1,24(a0)
    80005c8c:	7110                	ld	a2,32(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	dd0080e7          	jalr	-560(ra) # 80001a98 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	97aa                	add	a5,a5,a0
    80005cec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	d98080e7          	jalr	-616(ra) # 80001a98 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5151b          	slliw	a0,a0,0xd
    80005d0c:	0c2017b7          	lui	a5,0xc201
    80005d10:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d12:	43c8                	lw	a0,4(a5)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	d70080e7          	jalr	-656(ra) # 80001a98 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	06a7c863          	blt	a5,a0,80005dc0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005d54:	0001d717          	auipc	a4,0x1d
    80005d58:	2ac70713          	addi	a4,a4,684 # 80023000 <disk>
    80005d5c:	972a                	add	a4,a4,a0
    80005d5e:	6789                	lui	a5,0x2
    80005d60:	97ba                	add	a5,a5,a4
    80005d62:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d66:	e7ad                	bnez	a5,80005dd0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d68:	00451793          	slli	a5,a0,0x4
    80005d6c:	0001f717          	auipc	a4,0x1f
    80005d70:	29470713          	addi	a4,a4,660 # 80025000 <disk+0x2000>
    80005d74:	6314                	ld	a3,0(a4)
    80005d76:	96be                	add	a3,a3,a5
    80005d78:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d7c:	6314                	ld	a3,0(a4)
    80005d7e:	96be                	add	a3,a3,a5
    80005d80:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d84:	6314                	ld	a3,0(a4)
    80005d86:	96be                	add	a3,a3,a5
    80005d88:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d8c:	6318                	ld	a4,0(a4)
    80005d8e:	97ba                	add	a5,a5,a4
    80005d90:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d94:	0001d717          	auipc	a4,0x1d
    80005d98:	26c70713          	addi	a4,a4,620 # 80023000 <disk>
    80005d9c:	972a                	add	a4,a4,a0
    80005d9e:	6789                	lui	a5,0x2
    80005da0:	97ba                	add	a5,a5,a4
    80005da2:	4705                	li	a4,1
    80005da4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005da8:	0001f517          	auipc	a0,0x1f
    80005dac:	27050513          	addi	a0,a0,624 # 80025018 <disk+0x2018>
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	564080e7          	jalr	1380(ra) # 80002314 <wakeup>
}
    80005db8:	60a2                	ld	ra,8(sp)
    80005dba:	6402                	ld	s0,0(sp)
    80005dbc:	0141                	addi	sp,sp,16
    80005dbe:	8082                	ret
    panic("free_desc 1");
    80005dc0:	00003517          	auipc	a0,0x3
    80005dc4:	a3050513          	addi	a0,a0,-1488 # 800087f0 <syscalls+0x330>
    80005dc8:	ffffa097          	auipc	ra,0xffffa
    80005dcc:	772080e7          	jalr	1906(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005dd0:	00003517          	auipc	a0,0x3
    80005dd4:	a3050513          	addi	a0,a0,-1488 # 80008800 <syscalls+0x340>
    80005dd8:	ffffa097          	auipc	ra,0xffffa
    80005ddc:	762080e7          	jalr	1890(ra) # 8000053a <panic>

0000000080005de0 <virtio_disk_init>:
{
    80005de0:	1101                	addi	sp,sp,-32
    80005de2:	ec06                	sd	ra,24(sp)
    80005de4:	e822                	sd	s0,16(sp)
    80005de6:	e426                	sd	s1,8(sp)
    80005de8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dea:	00003597          	auipc	a1,0x3
    80005dee:	a2658593          	addi	a1,a1,-1498 # 80008810 <syscalls+0x350>
    80005df2:	0001f517          	auipc	a0,0x1f
    80005df6:	33650513          	addi	a0,a0,822 # 80025128 <disk+0x2128>
    80005dfa:	ffffb097          	auipc	ra,0xffffb
    80005dfe:	d46080e7          	jalr	-698(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e02:	100017b7          	lui	a5,0x10001
    80005e06:	4398                	lw	a4,0(a5)
    80005e08:	2701                	sext.w	a4,a4
    80005e0a:	747277b7          	lui	a5,0x74727
    80005e0e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e12:	0ef71063          	bne	a4,a5,80005ef2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e16:	100017b7          	lui	a5,0x10001
    80005e1a:	43dc                	lw	a5,4(a5)
    80005e1c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1e:	4705                	li	a4,1
    80005e20:	0ce79963          	bne	a5,a4,80005ef2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e24:	100017b7          	lui	a5,0x10001
    80005e28:	479c                	lw	a5,8(a5)
    80005e2a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2c:	4709                	li	a4,2
    80005e2e:	0ce79263          	bne	a5,a4,80005ef2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e32:	100017b7          	lui	a5,0x10001
    80005e36:	47d8                	lw	a4,12(a5)
    80005e38:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3a:	554d47b7          	lui	a5,0x554d4
    80005e3e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e42:	0af71863          	bne	a4,a5,80005ef2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e46:	100017b7          	lui	a5,0x10001
    80005e4a:	4705                	li	a4,1
    80005e4c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	470d                	li	a4,3
    80005e50:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e52:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e54:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e58:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e5c:	8f75                	and	a4,a4,a3
    80005e5e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e60:	472d                	li	a4,11
    80005e62:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e64:	473d                	li	a4,15
    80005e66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e68:	6705                	lui	a4,0x1
    80005e6a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e6c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e70:	5bdc                	lw	a5,52(a5)
    80005e72:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e74:	c7d9                	beqz	a5,80005f02 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e76:	471d                	li	a4,7
    80005e78:	08f77d63          	bgeu	a4,a5,80005f12 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e7c:	100014b7          	lui	s1,0x10001
    80005e80:	47a1                	li	a5,8
    80005e82:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e84:	6609                	lui	a2,0x2
    80005e86:	4581                	li	a1,0
    80005e88:	0001d517          	auipc	a0,0x1d
    80005e8c:	17850513          	addi	a0,a0,376 # 80023000 <disk>
    80005e90:	ffffb097          	auipc	ra,0xffffb
    80005e94:	e3c080e7          	jalr	-452(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e98:	0001d717          	auipc	a4,0x1d
    80005e9c:	16870713          	addi	a4,a4,360 # 80023000 <disk>
    80005ea0:	00c75793          	srli	a5,a4,0xc
    80005ea4:	2781                	sext.w	a5,a5
    80005ea6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ea8:	0001f797          	auipc	a5,0x1f
    80005eac:	15878793          	addi	a5,a5,344 # 80025000 <disk+0x2000>
    80005eb0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005eb2:	0001d717          	auipc	a4,0x1d
    80005eb6:	1ce70713          	addi	a4,a4,462 # 80023080 <disk+0x80>
    80005eba:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ebc:	0001e717          	auipc	a4,0x1e
    80005ec0:	14470713          	addi	a4,a4,324 # 80024000 <disk+0x1000>
    80005ec4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ec6:	4705                	li	a4,1
    80005ec8:	00e78c23          	sb	a4,24(a5)
    80005ecc:	00e78ca3          	sb	a4,25(a5)
    80005ed0:	00e78d23          	sb	a4,26(a5)
    80005ed4:	00e78da3          	sb	a4,27(a5)
    80005ed8:	00e78e23          	sb	a4,28(a5)
    80005edc:	00e78ea3          	sb	a4,29(a5)
    80005ee0:	00e78f23          	sb	a4,30(a5)
    80005ee4:	00e78fa3          	sb	a4,31(a5)
}
    80005ee8:	60e2                	ld	ra,24(sp)
    80005eea:	6442                	ld	s0,16(sp)
    80005eec:	64a2                	ld	s1,8(sp)
    80005eee:	6105                	addi	sp,sp,32
    80005ef0:	8082                	ret
    panic("could not find virtio disk");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	92e50513          	addi	a0,a0,-1746 # 80008820 <syscalls+0x360>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	640080e7          	jalr	1600(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	93e50513          	addi	a0,a0,-1730 # 80008840 <syscalls+0x380>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	630080e7          	jalr	1584(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	94e50513          	addi	a0,a0,-1714 # 80008860 <syscalls+0x3a0>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	620080e7          	jalr	1568(ra) # 8000053a <panic>

0000000080005f22 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f22:	7119                	addi	sp,sp,-128
    80005f24:	fc86                	sd	ra,120(sp)
    80005f26:	f8a2                	sd	s0,112(sp)
    80005f28:	f4a6                	sd	s1,104(sp)
    80005f2a:	f0ca                	sd	s2,96(sp)
    80005f2c:	ecce                	sd	s3,88(sp)
    80005f2e:	e8d2                	sd	s4,80(sp)
    80005f30:	e4d6                	sd	s5,72(sp)
    80005f32:	e0da                	sd	s6,64(sp)
    80005f34:	fc5e                	sd	s7,56(sp)
    80005f36:	f862                	sd	s8,48(sp)
    80005f38:	f466                	sd	s9,40(sp)
    80005f3a:	f06a                	sd	s10,32(sp)
    80005f3c:	ec6e                	sd	s11,24(sp)
    80005f3e:	0100                	addi	s0,sp,128
    80005f40:	8aaa                	mv	s5,a0
    80005f42:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f44:	00c52c83          	lw	s9,12(a0)
    80005f48:	001c9c9b          	slliw	s9,s9,0x1
    80005f4c:	1c82                	slli	s9,s9,0x20
    80005f4e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f52:	0001f517          	auipc	a0,0x1f
    80005f56:	1d650513          	addi	a0,a0,470 # 80025128 <disk+0x2128>
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	c76080e7          	jalr	-906(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005f62:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f64:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f66:	0001dc17          	auipc	s8,0x1d
    80005f6a:	09ac0c13          	addi	s8,s8,154 # 80023000 <disk>
    80005f6e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f70:	4b0d                	li	s6,3
    80005f72:	a0ad                	j	80005fdc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f74:	00fc0733          	add	a4,s8,a5
    80005f78:	975e                	add	a4,a4,s7
    80005f7a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f7e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f80:	0207c563          	bltz	a5,80005faa <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f84:	2905                	addiw	s2,s2,1
    80005f86:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f88:	19690c63          	beq	s2,s6,80006120 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f8c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f8e:	0001f717          	auipc	a4,0x1f
    80005f92:	08a70713          	addi	a4,a4,138 # 80025018 <disk+0x2018>
    80005f96:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f98:	00074683          	lbu	a3,0(a4)
    80005f9c:	fee1                	bnez	a3,80005f74 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f9e:	2785                	addiw	a5,a5,1
    80005fa0:	0705                	addi	a4,a4,1
    80005fa2:	fe979be3          	bne	a5,s1,80005f98 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fa6:	57fd                	li	a5,-1
    80005fa8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005faa:	01205d63          	blez	s2,80005fc4 <virtio_disk_rw+0xa2>
    80005fae:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fb0:	000a2503          	lw	a0,0(s4)
    80005fb4:	00000097          	auipc	ra,0x0
    80005fb8:	d92080e7          	jalr	-622(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fbc:	2d85                	addiw	s11,s11,1
    80005fbe:	0a11                	addi	s4,s4,4
    80005fc0:	ff2d98e3          	bne	s11,s2,80005fb0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fc4:	0001f597          	auipc	a1,0x1f
    80005fc8:	16458593          	addi	a1,a1,356 # 80025128 <disk+0x2128>
    80005fcc:	0001f517          	auipc	a0,0x1f
    80005fd0:	04c50513          	addi	a0,a0,76 # 80025018 <disk+0x2018>
    80005fd4:	ffffc097          	auipc	ra,0xffffc
    80005fd8:	1b4080e7          	jalr	436(ra) # 80002188 <sleep>
  for(int i = 0; i < 3; i++){
    80005fdc:	f8040a13          	addi	s4,s0,-128
{
    80005fe0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fe2:	894e                	mv	s2,s3
    80005fe4:	b765                	j	80005f8c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fe6:	0001f697          	auipc	a3,0x1f
    80005fea:	01a6b683          	ld	a3,26(a3) # 80025000 <disk+0x2000>
    80005fee:	96ba                	add	a3,a3,a4
    80005ff0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ff4:	0001d817          	auipc	a6,0x1d
    80005ff8:	00c80813          	addi	a6,a6,12 # 80023000 <disk>
    80005ffc:	0001f697          	auipc	a3,0x1f
    80006000:	00468693          	addi	a3,a3,4 # 80025000 <disk+0x2000>
    80006004:	6290                	ld	a2,0(a3)
    80006006:	963a                	add	a2,a2,a4
    80006008:	00c65583          	lhu	a1,12(a2)
    8000600c:	0015e593          	ori	a1,a1,1
    80006010:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006014:	f8842603          	lw	a2,-120(s0)
    80006018:	628c                	ld	a1,0(a3)
    8000601a:	972e                	add	a4,a4,a1
    8000601c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006020:	20050593          	addi	a1,a0,512
    80006024:	0592                	slli	a1,a1,0x4
    80006026:	95c2                	add	a1,a1,a6
    80006028:	577d                	li	a4,-1
    8000602a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000602e:	00461713          	slli	a4,a2,0x4
    80006032:	6290                	ld	a2,0(a3)
    80006034:	963a                	add	a2,a2,a4
    80006036:	03078793          	addi	a5,a5,48
    8000603a:	97c2                	add	a5,a5,a6
    8000603c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000603e:	629c                	ld	a5,0(a3)
    80006040:	97ba                	add	a5,a5,a4
    80006042:	4605                	li	a2,1
    80006044:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006046:	629c                	ld	a5,0(a3)
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	4809                	li	a6,2
    8000604c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006050:	629c                	ld	a5,0(a3)
    80006052:	97ba                	add	a5,a5,a4
    80006054:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006058:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000605c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006060:	6698                	ld	a4,8(a3)
    80006062:	00275783          	lhu	a5,2(a4)
    80006066:	8b9d                	andi	a5,a5,7
    80006068:	0786                	slli	a5,a5,0x1
    8000606a:	973e                	add	a4,a4,a5
    8000606c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006070:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006074:	6698                	ld	a4,8(a3)
    80006076:	00275783          	lhu	a5,2(a4)
    8000607a:	2785                	addiw	a5,a5,1
    8000607c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006080:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000608c:	004aa783          	lw	a5,4(s5)
    80006090:	02c79163          	bne	a5,a2,800060b2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006094:	0001f917          	auipc	s2,0x1f
    80006098:	09490913          	addi	s2,s2,148 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000609c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000609e:	85ca                	mv	a1,s2
    800060a0:	8556                	mv	a0,s5
    800060a2:	ffffc097          	auipc	ra,0xffffc
    800060a6:	0e6080e7          	jalr	230(ra) # 80002188 <sleep>
  while(b->disk == 1) {
    800060aa:	004aa783          	lw	a5,4(s5)
    800060ae:	fe9788e3          	beq	a5,s1,8000609e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060b2:	f8042903          	lw	s2,-128(s0)
    800060b6:	20090713          	addi	a4,s2,512
    800060ba:	0712                	slli	a4,a4,0x4
    800060bc:	0001d797          	auipc	a5,0x1d
    800060c0:	f4478793          	addi	a5,a5,-188 # 80023000 <disk>
    800060c4:	97ba                	add	a5,a5,a4
    800060c6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060ca:	0001f997          	auipc	s3,0x1f
    800060ce:	f3698993          	addi	s3,s3,-202 # 80025000 <disk+0x2000>
    800060d2:	00491713          	slli	a4,s2,0x4
    800060d6:	0009b783          	ld	a5,0(s3)
    800060da:	97ba                	add	a5,a5,a4
    800060dc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060e0:	854a                	mv	a0,s2
    800060e2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060e6:	00000097          	auipc	ra,0x0
    800060ea:	c60080e7          	jalr	-928(ra) # 80005d46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ee:	8885                	andi	s1,s1,1
    800060f0:	f0ed                	bnez	s1,800060d2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060f2:	0001f517          	auipc	a0,0x1f
    800060f6:	03650513          	addi	a0,a0,54 # 80025128 <disk+0x2128>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	b8a080e7          	jalr	-1142(ra) # 80000c84 <release>
}
    80006102:	70e6                	ld	ra,120(sp)
    80006104:	7446                	ld	s0,112(sp)
    80006106:	74a6                	ld	s1,104(sp)
    80006108:	7906                	ld	s2,96(sp)
    8000610a:	69e6                	ld	s3,88(sp)
    8000610c:	6a46                	ld	s4,80(sp)
    8000610e:	6aa6                	ld	s5,72(sp)
    80006110:	6b06                	ld	s6,64(sp)
    80006112:	7be2                	ld	s7,56(sp)
    80006114:	7c42                	ld	s8,48(sp)
    80006116:	7ca2                	ld	s9,40(sp)
    80006118:	7d02                	ld	s10,32(sp)
    8000611a:	6de2                	ld	s11,24(sp)
    8000611c:	6109                	addi	sp,sp,128
    8000611e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006120:	f8042503          	lw	a0,-128(s0)
    80006124:	20050793          	addi	a5,a0,512
    80006128:	0792                	slli	a5,a5,0x4
  if(write)
    8000612a:	0001d817          	auipc	a6,0x1d
    8000612e:	ed680813          	addi	a6,a6,-298 # 80023000 <disk>
    80006132:	00f80733          	add	a4,a6,a5
    80006136:	01a036b3          	snez	a3,s10
    8000613a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000613e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006142:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006146:	7679                	lui	a2,0xffffe
    80006148:	963e                	add	a2,a2,a5
    8000614a:	0001f697          	auipc	a3,0x1f
    8000614e:	eb668693          	addi	a3,a3,-330 # 80025000 <disk+0x2000>
    80006152:	6298                	ld	a4,0(a3)
    80006154:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006156:	0a878593          	addi	a1,a5,168
    8000615a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000615c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000615e:	6298                	ld	a4,0(a3)
    80006160:	9732                	add	a4,a4,a2
    80006162:	45c1                	li	a1,16
    80006164:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006166:	6298                	ld	a4,0(a3)
    80006168:	9732                	add	a4,a4,a2
    8000616a:	4585                	li	a1,1
    8000616c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006170:	f8442703          	lw	a4,-124(s0)
    80006174:	628c                	ld	a1,0(a3)
    80006176:	962e                	add	a2,a2,a1
    80006178:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000617c:	0712                	slli	a4,a4,0x4
    8000617e:	6290                	ld	a2,0(a3)
    80006180:	963a                	add	a2,a2,a4
    80006182:	058a8593          	addi	a1,s5,88
    80006186:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006188:	6294                	ld	a3,0(a3)
    8000618a:	96ba                	add	a3,a3,a4
    8000618c:	40000613          	li	a2,1024
    80006190:	c690                	sw	a2,8(a3)
  if(write)
    80006192:	e40d1ae3          	bnez	s10,80005fe6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006196:	0001f697          	auipc	a3,0x1f
    8000619a:	e6a6b683          	ld	a3,-406(a3) # 80025000 <disk+0x2000>
    8000619e:	96ba                	add	a3,a3,a4
    800061a0:	4609                	li	a2,2
    800061a2:	00c69623          	sh	a2,12(a3)
    800061a6:	b5b9                	j	80005ff4 <virtio_disk_rw+0xd2>

00000000800061a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061a8:	1101                	addi	sp,sp,-32
    800061aa:	ec06                	sd	ra,24(sp)
    800061ac:	e822                	sd	s0,16(sp)
    800061ae:	e426                	sd	s1,8(sp)
    800061b0:	e04a                	sd	s2,0(sp)
    800061b2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061b4:	0001f517          	auipc	a0,0x1f
    800061b8:	f7450513          	addi	a0,a0,-140 # 80025128 <disk+0x2128>
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	a14080e7          	jalr	-1516(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061c4:	10001737          	lui	a4,0x10001
    800061c8:	533c                	lw	a5,96(a4)
    800061ca:	8b8d                	andi	a5,a5,3
    800061cc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061d2:	0001f797          	auipc	a5,0x1f
    800061d6:	e2e78793          	addi	a5,a5,-466 # 80025000 <disk+0x2000>
    800061da:	6b94                	ld	a3,16(a5)
    800061dc:	0207d703          	lhu	a4,32(a5)
    800061e0:	0026d783          	lhu	a5,2(a3)
    800061e4:	06f70163          	beq	a4,a5,80006246 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061e8:	0001d917          	auipc	s2,0x1d
    800061ec:	e1890913          	addi	s2,s2,-488 # 80023000 <disk>
    800061f0:	0001f497          	auipc	s1,0x1f
    800061f4:	e1048493          	addi	s1,s1,-496 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061f8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061fc:	6898                	ld	a4,16(s1)
    800061fe:	0204d783          	lhu	a5,32(s1)
    80006202:	8b9d                	andi	a5,a5,7
    80006204:	078e                	slli	a5,a5,0x3
    80006206:	97ba                	add	a5,a5,a4
    80006208:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000620a:	20078713          	addi	a4,a5,512
    8000620e:	0712                	slli	a4,a4,0x4
    80006210:	974a                	add	a4,a4,s2
    80006212:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006216:	e731                	bnez	a4,80006262 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006218:	20078793          	addi	a5,a5,512
    8000621c:	0792                	slli	a5,a5,0x4
    8000621e:	97ca                	add	a5,a5,s2
    80006220:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006222:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006226:	ffffc097          	auipc	ra,0xffffc
    8000622a:	0ee080e7          	jalr	238(ra) # 80002314 <wakeup>

    disk.used_idx += 1;
    8000622e:	0204d783          	lhu	a5,32(s1)
    80006232:	2785                	addiw	a5,a5,1
    80006234:	17c2                	slli	a5,a5,0x30
    80006236:	93c1                	srli	a5,a5,0x30
    80006238:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000623c:	6898                	ld	a4,16(s1)
    8000623e:	00275703          	lhu	a4,2(a4)
    80006242:	faf71be3          	bne	a4,a5,800061f8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006246:	0001f517          	auipc	a0,0x1f
    8000624a:	ee250513          	addi	a0,a0,-286 # 80025128 <disk+0x2128>
    8000624e:	ffffb097          	auipc	ra,0xffffb
    80006252:	a36080e7          	jalr	-1482(ra) # 80000c84 <release>
}
    80006256:	60e2                	ld	ra,24(sp)
    80006258:	6442                	ld	s0,16(sp)
    8000625a:	64a2                	ld	s1,8(sp)
    8000625c:	6902                	ld	s2,0(sp)
    8000625e:	6105                	addi	sp,sp,32
    80006260:	8082                	ret
      panic("virtio_disk_intr status");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	61e50513          	addi	a0,a0,1566 # 80008880 <syscalls+0x3c0>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d0080e7          	jalr	720(ra) # 8000053a <panic>
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
