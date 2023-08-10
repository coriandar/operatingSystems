
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
   showprocs();
   8:	00000097          	auipc	ra,0x0
   c:	27e080e7          	jalr	638(ra) # 286 <showprocs>
   return 0;
}
  10:	4501                	li	a0,0
  12:	60a2                	ld	ra,8(sp)
  14:	6402                	ld	s0,0(sp)
  16:	0141                	addi	sp,sp,16
  18:	8082                	ret

000000000000001a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  1a:	1141                	addi	sp,sp,-16
  1c:	e422                	sd	s0,8(sp)
  1e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  20:	87aa                	mv	a5,a0
  22:	0585                	addi	a1,a1,1
  24:	0785                	addi	a5,a5,1
  26:	fff5c703          	lbu	a4,-1(a1)
  2a:	fee78fa3          	sb	a4,-1(a5)
  2e:	fb75                	bnez	a4,22 <strcpy+0x8>
    ;
  return os;
}
  30:	6422                	ld	s0,8(sp)
  32:	0141                	addi	sp,sp,16
  34:	8082                	ret

0000000000000036 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  36:	1141                	addi	sp,sp,-16
  38:	e422                	sd	s0,8(sp)
  3a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  3c:	00054783          	lbu	a5,0(a0)
  40:	cb91                	beqz	a5,54 <strcmp+0x1e>
  42:	0005c703          	lbu	a4,0(a1)
  46:	00f71763          	bne	a4,a5,54 <strcmp+0x1e>
    p++, q++;
  4a:	0505                	addi	a0,a0,1
  4c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  4e:	00054783          	lbu	a5,0(a0)
  52:	fbe5                	bnez	a5,42 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  54:	0005c503          	lbu	a0,0(a1)
}
  58:	40a7853b          	subw	a0,a5,a0
  5c:	6422                	ld	s0,8(sp)
  5e:	0141                	addi	sp,sp,16
  60:	8082                	ret

0000000000000062 <strlen>:

uint
strlen(const char *s)
{
  62:	1141                	addi	sp,sp,-16
  64:	e422                	sd	s0,8(sp)
  66:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  68:	00054783          	lbu	a5,0(a0)
  6c:	cf91                	beqz	a5,88 <strlen+0x26>
  6e:	0505                	addi	a0,a0,1
  70:	87aa                	mv	a5,a0
  72:	4685                	li	a3,1
  74:	9e89                	subw	a3,a3,a0
  76:	00f6853b          	addw	a0,a3,a5
  7a:	0785                	addi	a5,a5,1
  7c:	fff7c703          	lbu	a4,-1(a5)
  80:	fb7d                	bnez	a4,76 <strlen+0x14>
    ;
  return n;
}
  82:	6422                	ld	s0,8(sp)
  84:	0141                	addi	sp,sp,16
  86:	8082                	ret
  for(n = 0; s[n]; n++)
  88:	4501                	li	a0,0
  8a:	bfe5                	j	82 <strlen+0x20>

000000000000008c <memset>:

void*
memset(void *dst, int c, uint n)
{
  8c:	1141                	addi	sp,sp,-16
  8e:	e422                	sd	s0,8(sp)
  90:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  92:	ca19                	beqz	a2,a8 <memset+0x1c>
  94:	87aa                	mv	a5,a0
  96:	1602                	slli	a2,a2,0x20
  98:	9201                	srli	a2,a2,0x20
  9a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  9e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  a2:	0785                	addi	a5,a5,1
  a4:	fee79de3          	bne	a5,a4,9e <memset+0x12>
  }
  return dst;
}
  a8:	6422                	ld	s0,8(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret

00000000000000ae <strchr>:

char*
strchr(const char *s, char c)
{
  ae:	1141                	addi	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	addi	s0,sp,16
  for(; *s; s++)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	cb99                	beqz	a5,ce <strchr+0x20>
    if(*s == c)
  ba:	00f58763          	beq	a1,a5,c8 <strchr+0x1a>
  for(; *s; s++)
  be:	0505                	addi	a0,a0,1
  c0:	00054783          	lbu	a5,0(a0)
  c4:	fbfd                	bnez	a5,ba <strchr+0xc>
      return (char*)s;
  return 0;
  c6:	4501                	li	a0,0
}
  c8:	6422                	ld	s0,8(sp)
  ca:	0141                	addi	sp,sp,16
  cc:	8082                	ret
  return 0;
  ce:	4501                	li	a0,0
  d0:	bfe5                	j	c8 <strchr+0x1a>

00000000000000d2 <gets>:

char*
gets(char *buf, int max)
{
  d2:	711d                	addi	sp,sp,-96
  d4:	ec86                	sd	ra,88(sp)
  d6:	e8a2                	sd	s0,80(sp)
  d8:	e4a6                	sd	s1,72(sp)
  da:	e0ca                	sd	s2,64(sp)
  dc:	fc4e                	sd	s3,56(sp)
  de:	f852                	sd	s4,48(sp)
  e0:	f456                	sd	s5,40(sp)
  e2:	f05a                	sd	s6,32(sp)
  e4:	ec5e                	sd	s7,24(sp)
  e6:	1080                	addi	s0,sp,96
  e8:	8baa                	mv	s7,a0
  ea:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
  ec:	892a                	mv	s2,a0
  ee:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
  f0:	4aa9                	li	s5,10
  f2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
  f4:	89a6                	mv	s3,s1
  f6:	2485                	addiw	s1,s1,1
  f8:	0344d863          	bge	s1,s4,128 <gets+0x56>
    cc = read(0, &c, 1);
  fc:	4605                	li	a2,1
  fe:	faf40593          	addi	a1,s0,-81
 102:	4501                	li	a0,0
 104:	00000097          	auipc	ra,0x0
 108:	1aa080e7          	jalr	426(ra) # 2ae <read>
    if(cc < 1)
 10c:	00a05e63          	blez	a0,128 <gets+0x56>
    buf[i++] = c;
 110:	faf44783          	lbu	a5,-81(s0)
 114:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 118:	01578763          	beq	a5,s5,126 <gets+0x54>
 11c:	0905                	addi	s2,s2,1
 11e:	fd679be3          	bne	a5,s6,f4 <gets+0x22>
  for(i=0; i+1 < max; ){
 122:	89a6                	mv	s3,s1
 124:	a011                	j	128 <gets+0x56>
 126:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 128:	99de                	add	s3,s3,s7
 12a:	00098023          	sb	zero,0(s3)
  return buf;
}
 12e:	855e                	mv	a0,s7
 130:	60e6                	ld	ra,88(sp)
 132:	6446                	ld	s0,80(sp)
 134:	64a6                	ld	s1,72(sp)
 136:	6906                	ld	s2,64(sp)
 138:	79e2                	ld	s3,56(sp)
 13a:	7a42                	ld	s4,48(sp)
 13c:	7aa2                	ld	s5,40(sp)
 13e:	7b02                	ld	s6,32(sp)
 140:	6be2                	ld	s7,24(sp)
 142:	6125                	addi	sp,sp,96
 144:	8082                	ret

0000000000000146 <stat>:

int
stat(const char *n, struct stat *st)
{
 146:	1101                	addi	sp,sp,-32
 148:	ec06                	sd	ra,24(sp)
 14a:	e822                	sd	s0,16(sp)
 14c:	e426                	sd	s1,8(sp)
 14e:	e04a                	sd	s2,0(sp)
 150:	1000                	addi	s0,sp,32
 152:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 154:	4581                	li	a1,0
 156:	00000097          	auipc	ra,0x0
 15a:	180080e7          	jalr	384(ra) # 2d6 <open>
  if(fd < 0)
 15e:	02054563          	bltz	a0,188 <stat+0x42>
 162:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 164:	85ca                	mv	a1,s2
 166:	00000097          	auipc	ra,0x0
 16a:	188080e7          	jalr	392(ra) # 2ee <fstat>
 16e:	892a                	mv	s2,a0
  close(fd);
 170:	8526                	mv	a0,s1
 172:	00000097          	auipc	ra,0x0
 176:	14c080e7          	jalr	332(ra) # 2be <close>
  return r;
}
 17a:	854a                	mv	a0,s2
 17c:	60e2                	ld	ra,24(sp)
 17e:	6442                	ld	s0,16(sp)
 180:	64a2                	ld	s1,8(sp)
 182:	6902                	ld	s2,0(sp)
 184:	6105                	addi	sp,sp,32
 186:	8082                	ret
    return -1;
 188:	597d                	li	s2,-1
 18a:	bfc5                	j	17a <stat+0x34>

000000000000018c <atoi>:

int
atoi(const char *s)
{
 18c:	1141                	addi	sp,sp,-16
 18e:	e422                	sd	s0,8(sp)
 190:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 192:	00054683          	lbu	a3,0(a0)
 196:	fd06879b          	addiw	a5,a3,-48
 19a:	0ff7f793          	zext.b	a5,a5
 19e:	4625                	li	a2,9
 1a0:	02f66863          	bltu	a2,a5,1d0 <atoi+0x44>
 1a4:	872a                	mv	a4,a0
  n = 0;
 1a6:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1a8:	0705                	addi	a4,a4,1
 1aa:	0025179b          	slliw	a5,a0,0x2
 1ae:	9fa9                	addw	a5,a5,a0
 1b0:	0017979b          	slliw	a5,a5,0x1
 1b4:	9fb5                	addw	a5,a5,a3
 1b6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1ba:	00074683          	lbu	a3,0(a4)
 1be:	fd06879b          	addiw	a5,a3,-48
 1c2:	0ff7f793          	zext.b	a5,a5
 1c6:	fef671e3          	bgeu	a2,a5,1a8 <atoi+0x1c>
  return n;
}
 1ca:	6422                	ld	s0,8(sp)
 1cc:	0141                	addi	sp,sp,16
 1ce:	8082                	ret
  n = 0;
 1d0:	4501                	li	a0,0
 1d2:	bfe5                	j	1ca <atoi+0x3e>

00000000000001d4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1d4:	1141                	addi	sp,sp,-16
 1d6:	e422                	sd	s0,8(sp)
 1d8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1da:	02b57463          	bgeu	a0,a1,202 <memmove+0x2e>
    while(n-- > 0)
 1de:	00c05f63          	blez	a2,1fc <memmove+0x28>
 1e2:	1602                	slli	a2,a2,0x20
 1e4:	9201                	srli	a2,a2,0x20
 1e6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 1ea:	872a                	mv	a4,a0
      *dst++ = *src++;
 1ec:	0585                	addi	a1,a1,1
 1ee:	0705                	addi	a4,a4,1
 1f0:	fff5c683          	lbu	a3,-1(a1)
 1f4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 1f8:	fee79ae3          	bne	a5,a4,1ec <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 1fc:	6422                	ld	s0,8(sp)
 1fe:	0141                	addi	sp,sp,16
 200:	8082                	ret
    dst += n;
 202:	00c50733          	add	a4,a0,a2
    src += n;
 206:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 208:	fec05ae3          	blez	a2,1fc <memmove+0x28>
 20c:	fff6079b          	addiw	a5,a2,-1
 210:	1782                	slli	a5,a5,0x20
 212:	9381                	srli	a5,a5,0x20
 214:	fff7c793          	not	a5,a5
 218:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 21a:	15fd                	addi	a1,a1,-1
 21c:	177d                	addi	a4,a4,-1
 21e:	0005c683          	lbu	a3,0(a1)
 222:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 226:	fee79ae3          	bne	a5,a4,21a <memmove+0x46>
 22a:	bfc9                	j	1fc <memmove+0x28>

000000000000022c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 22c:	1141                	addi	sp,sp,-16
 22e:	e422                	sd	s0,8(sp)
 230:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 232:	ca05                	beqz	a2,262 <memcmp+0x36>
 234:	fff6069b          	addiw	a3,a2,-1
 238:	1682                	slli	a3,a3,0x20
 23a:	9281                	srli	a3,a3,0x20
 23c:	0685                	addi	a3,a3,1
 23e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 240:	00054783          	lbu	a5,0(a0)
 244:	0005c703          	lbu	a4,0(a1)
 248:	00e79863          	bne	a5,a4,258 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 24c:	0505                	addi	a0,a0,1
    p2++;
 24e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 250:	fed518e3          	bne	a0,a3,240 <memcmp+0x14>
  }
  return 0;
 254:	4501                	li	a0,0
 256:	a019                	j	25c <memcmp+0x30>
      return *p1 - *p2;
 258:	40e7853b          	subw	a0,a5,a4
}
 25c:	6422                	ld	s0,8(sp)
 25e:	0141                	addi	sp,sp,16
 260:	8082                	ret
  return 0;
 262:	4501                	li	a0,0
 264:	bfe5                	j	25c <memcmp+0x30>

0000000000000266 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 266:	1141                	addi	sp,sp,-16
 268:	e406                	sd	ra,8(sp)
 26a:	e022                	sd	s0,0(sp)
 26c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 26e:	00000097          	auipc	ra,0x0
 272:	f66080e7          	jalr	-154(ra) # 1d4 <memmove>
}
 276:	60a2                	ld	ra,8(sp)
 278:	6402                	ld	s0,0(sp)
 27a:	0141                	addi	sp,sp,16
 27c:	8082                	ret

000000000000027e <getthisprocsize>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global getthisprocsize
getthisprocsize:
 li a7, SYS_getthisprocsize
 27e:	48d9                	li	a7,22
 ecall
 280:	00000073          	ecall
 ret
 284:	8082                	ret

0000000000000286 <showprocs>:
.global showprocs
showprocs:
 li a7, SYS_showprocs
 286:	48dd                	li	a7,23
 ecall
 288:	00000073          	ecall
 ret
 28c:	8082                	ret

000000000000028e <fork>:
.global fork
fork:
 li a7, SYS_fork
 28e:	4885                	li	a7,1
 ecall
 290:	00000073          	ecall
 ret
 294:	8082                	ret

0000000000000296 <exit>:
.global exit
exit:
 li a7, SYS_exit
 296:	4889                	li	a7,2
 ecall
 298:	00000073          	ecall
 ret
 29c:	8082                	ret

000000000000029e <wait>:
.global wait
wait:
 li a7, SYS_wait
 29e:	488d                	li	a7,3
 ecall
 2a0:	00000073          	ecall
 ret
 2a4:	8082                	ret

00000000000002a6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2a6:	4891                	li	a7,4
 ecall
 2a8:	00000073          	ecall
 ret
 2ac:	8082                	ret

00000000000002ae <read>:
.global read
read:
 li a7, SYS_read
 2ae:	4895                	li	a7,5
 ecall
 2b0:	00000073          	ecall
 ret
 2b4:	8082                	ret

00000000000002b6 <write>:
.global write
write:
 li a7, SYS_write
 2b6:	48c1                	li	a7,16
 ecall
 2b8:	00000073          	ecall
 ret
 2bc:	8082                	ret

00000000000002be <close>:
.global close
close:
 li a7, SYS_close
 2be:	48d5                	li	a7,21
 ecall
 2c0:	00000073          	ecall
 ret
 2c4:	8082                	ret

00000000000002c6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2c6:	4899                	li	a7,6
 ecall
 2c8:	00000073          	ecall
 ret
 2cc:	8082                	ret

00000000000002ce <exec>:
.global exec
exec:
 li a7, SYS_exec
 2ce:	489d                	li	a7,7
 ecall
 2d0:	00000073          	ecall
 ret
 2d4:	8082                	ret

00000000000002d6 <open>:
.global open
open:
 li a7, SYS_open
 2d6:	48bd                	li	a7,15
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2de:	48c5                	li	a7,17
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2e6:	48c9                	li	a7,18
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2ee:	48a1                	li	a7,8
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <link>:
.global link
link:
 li a7, SYS_link
 2f6:	48cd                	li	a7,19
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2fe:	48d1                	li	a7,20
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 306:	48a5                	li	a7,9
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <dup>:
.global dup
dup:
 li a7, SYS_dup
 30e:	48a9                	li	a7,10
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 316:	48ad                	li	a7,11
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 31e:	48b1                	li	a7,12
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 326:	48b5                	li	a7,13
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 32e:	48b9                	li	a7,14
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 336:	1101                	addi	sp,sp,-32
 338:	ec06                	sd	ra,24(sp)
 33a:	e822                	sd	s0,16(sp)
 33c:	1000                	addi	s0,sp,32
 33e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 342:	4605                	li	a2,1
 344:	fef40593          	addi	a1,s0,-17
 348:	00000097          	auipc	ra,0x0
 34c:	f6e080e7          	jalr	-146(ra) # 2b6 <write>
}
 350:	60e2                	ld	ra,24(sp)
 352:	6442                	ld	s0,16(sp)
 354:	6105                	addi	sp,sp,32
 356:	8082                	ret

0000000000000358 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 358:	7139                	addi	sp,sp,-64
 35a:	fc06                	sd	ra,56(sp)
 35c:	f822                	sd	s0,48(sp)
 35e:	f426                	sd	s1,40(sp)
 360:	f04a                	sd	s2,32(sp)
 362:	ec4e                	sd	s3,24(sp)
 364:	0080                	addi	s0,sp,64
 366:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 368:	c299                	beqz	a3,36e <printint+0x16>
 36a:	0805c963          	bltz	a1,3fc <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 36e:	2581                	sext.w	a1,a1
  neg = 0;
 370:	4881                	li	a7,0
 372:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 376:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 378:	2601                	sext.w	a2,a2
 37a:	00000517          	auipc	a0,0x0
 37e:	49650513          	addi	a0,a0,1174 # 810 <digits>
 382:	883a                	mv	a6,a4
 384:	2705                	addiw	a4,a4,1
 386:	02c5f7bb          	remuw	a5,a1,a2
 38a:	1782                	slli	a5,a5,0x20
 38c:	9381                	srli	a5,a5,0x20
 38e:	97aa                	add	a5,a5,a0
 390:	0007c783          	lbu	a5,0(a5)
 394:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 398:	0005879b          	sext.w	a5,a1
 39c:	02c5d5bb          	divuw	a1,a1,a2
 3a0:	0685                	addi	a3,a3,1
 3a2:	fec7f0e3          	bgeu	a5,a2,382 <printint+0x2a>
  if(neg)
 3a6:	00088c63          	beqz	a7,3be <printint+0x66>
    buf[i++] = '-';
 3aa:	fd070793          	addi	a5,a4,-48
 3ae:	00878733          	add	a4,a5,s0
 3b2:	02d00793          	li	a5,45
 3b6:	fef70823          	sb	a5,-16(a4)
 3ba:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3be:	02e05863          	blez	a4,3ee <printint+0x96>
 3c2:	fc040793          	addi	a5,s0,-64
 3c6:	00e78933          	add	s2,a5,a4
 3ca:	fff78993          	addi	s3,a5,-1
 3ce:	99ba                	add	s3,s3,a4
 3d0:	377d                	addiw	a4,a4,-1
 3d2:	1702                	slli	a4,a4,0x20
 3d4:	9301                	srli	a4,a4,0x20
 3d6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3da:	fff94583          	lbu	a1,-1(s2)
 3de:	8526                	mv	a0,s1
 3e0:	00000097          	auipc	ra,0x0
 3e4:	f56080e7          	jalr	-170(ra) # 336 <putc>
  while(--i >= 0)
 3e8:	197d                	addi	s2,s2,-1
 3ea:	ff3918e3          	bne	s2,s3,3da <printint+0x82>
}
 3ee:	70e2                	ld	ra,56(sp)
 3f0:	7442                	ld	s0,48(sp)
 3f2:	74a2                	ld	s1,40(sp)
 3f4:	7902                	ld	s2,32(sp)
 3f6:	69e2                	ld	s3,24(sp)
 3f8:	6121                	addi	sp,sp,64
 3fa:	8082                	ret
    x = -xx;
 3fc:	40b005bb          	negw	a1,a1
    neg = 1;
 400:	4885                	li	a7,1
    x = -xx;
 402:	bf85                	j	372 <printint+0x1a>

0000000000000404 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 404:	7119                	addi	sp,sp,-128
 406:	fc86                	sd	ra,120(sp)
 408:	f8a2                	sd	s0,112(sp)
 40a:	f4a6                	sd	s1,104(sp)
 40c:	f0ca                	sd	s2,96(sp)
 40e:	ecce                	sd	s3,88(sp)
 410:	e8d2                	sd	s4,80(sp)
 412:	e4d6                	sd	s5,72(sp)
 414:	e0da                	sd	s6,64(sp)
 416:	fc5e                	sd	s7,56(sp)
 418:	f862                	sd	s8,48(sp)
 41a:	f466                	sd	s9,40(sp)
 41c:	f06a                	sd	s10,32(sp)
 41e:	ec6e                	sd	s11,24(sp)
 420:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 422:	0005c903          	lbu	s2,0(a1)
 426:	18090f63          	beqz	s2,5c4 <vprintf+0x1c0>
 42a:	8aaa                	mv	s5,a0
 42c:	8b32                	mv	s6,a2
 42e:	00158493          	addi	s1,a1,1
  state = 0;
 432:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 434:	02500a13          	li	s4,37
 438:	4c55                	li	s8,21
 43a:	00000c97          	auipc	s9,0x0
 43e:	37ec8c93          	addi	s9,s9,894 # 7b8 <malloc+0xf0>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 442:	02800d93          	li	s11,40
  putc(fd, 'x');
 446:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 448:	00000b97          	auipc	s7,0x0
 44c:	3c8b8b93          	addi	s7,s7,968 # 810 <digits>
 450:	a839                	j	46e <vprintf+0x6a>
        putc(fd, c);
 452:	85ca                	mv	a1,s2
 454:	8556                	mv	a0,s5
 456:	00000097          	auipc	ra,0x0
 45a:	ee0080e7          	jalr	-288(ra) # 336 <putc>
 45e:	a019                	j	464 <vprintf+0x60>
    } else if(state == '%'){
 460:	01498d63          	beq	s3,s4,47a <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 464:	0485                	addi	s1,s1,1
 466:	fff4c903          	lbu	s2,-1(s1)
 46a:	14090d63          	beqz	s2,5c4 <vprintf+0x1c0>
    if(state == 0){
 46e:	fe0999e3          	bnez	s3,460 <vprintf+0x5c>
      if(c == '%'){
 472:	ff4910e3          	bne	s2,s4,452 <vprintf+0x4e>
        state = '%';
 476:	89d2                	mv	s3,s4
 478:	b7f5                	j	464 <vprintf+0x60>
      if(c == 'd'){
 47a:	11490c63          	beq	s2,s4,592 <vprintf+0x18e>
 47e:	f9d9079b          	addiw	a5,s2,-99
 482:	0ff7f793          	zext.b	a5,a5
 486:	10fc6e63          	bltu	s8,a5,5a2 <vprintf+0x19e>
 48a:	f9d9079b          	addiw	a5,s2,-99
 48e:	0ff7f713          	zext.b	a4,a5
 492:	10ec6863          	bltu	s8,a4,5a2 <vprintf+0x19e>
 496:	00271793          	slli	a5,a4,0x2
 49a:	97e6                	add	a5,a5,s9
 49c:	439c                	lw	a5,0(a5)
 49e:	97e6                	add	a5,a5,s9
 4a0:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4a2:	008b0913          	addi	s2,s6,8
 4a6:	4685                	li	a3,1
 4a8:	4629                	li	a2,10
 4aa:	000b2583          	lw	a1,0(s6)
 4ae:	8556                	mv	a0,s5
 4b0:	00000097          	auipc	ra,0x0
 4b4:	ea8080e7          	jalr	-344(ra) # 358 <printint>
 4b8:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4ba:	4981                	li	s3,0
 4bc:	b765                	j	464 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4be:	008b0913          	addi	s2,s6,8
 4c2:	4681                	li	a3,0
 4c4:	4629                	li	a2,10
 4c6:	000b2583          	lw	a1,0(s6)
 4ca:	8556                	mv	a0,s5
 4cc:	00000097          	auipc	ra,0x0
 4d0:	e8c080e7          	jalr	-372(ra) # 358 <printint>
 4d4:	8b4a                	mv	s6,s2
      state = 0;
 4d6:	4981                	li	s3,0
 4d8:	b771                	j	464 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4da:	008b0913          	addi	s2,s6,8
 4de:	4681                	li	a3,0
 4e0:	866a                	mv	a2,s10
 4e2:	000b2583          	lw	a1,0(s6)
 4e6:	8556                	mv	a0,s5
 4e8:	00000097          	auipc	ra,0x0
 4ec:	e70080e7          	jalr	-400(ra) # 358 <printint>
 4f0:	8b4a                	mv	s6,s2
      state = 0;
 4f2:	4981                	li	s3,0
 4f4:	bf85                	j	464 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 4f6:	008b0793          	addi	a5,s6,8
 4fa:	f8f43423          	sd	a5,-120(s0)
 4fe:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 502:	03000593          	li	a1,48
 506:	8556                	mv	a0,s5
 508:	00000097          	auipc	ra,0x0
 50c:	e2e080e7          	jalr	-466(ra) # 336 <putc>
  putc(fd, 'x');
 510:	07800593          	li	a1,120
 514:	8556                	mv	a0,s5
 516:	00000097          	auipc	ra,0x0
 51a:	e20080e7          	jalr	-480(ra) # 336 <putc>
 51e:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 520:	03c9d793          	srli	a5,s3,0x3c
 524:	97de                	add	a5,a5,s7
 526:	0007c583          	lbu	a1,0(a5)
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	e0a080e7          	jalr	-502(ra) # 336 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 534:	0992                	slli	s3,s3,0x4
 536:	397d                	addiw	s2,s2,-1
 538:	fe0914e3          	bnez	s2,520 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 53c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 540:	4981                	li	s3,0
 542:	b70d                	j	464 <vprintf+0x60>
        s = va_arg(ap, char*);
 544:	008b0913          	addi	s2,s6,8
 548:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 54c:	02098163          	beqz	s3,56e <vprintf+0x16a>
        while(*s != 0){
 550:	0009c583          	lbu	a1,0(s3)
 554:	c5ad                	beqz	a1,5be <vprintf+0x1ba>
          putc(fd, *s);
 556:	8556                	mv	a0,s5
 558:	00000097          	auipc	ra,0x0
 55c:	dde080e7          	jalr	-546(ra) # 336 <putc>
          s++;
 560:	0985                	addi	s3,s3,1
        while(*s != 0){
 562:	0009c583          	lbu	a1,0(s3)
 566:	f9e5                	bnez	a1,556 <vprintf+0x152>
        s = va_arg(ap, char*);
 568:	8b4a                	mv	s6,s2
      state = 0;
 56a:	4981                	li	s3,0
 56c:	bde5                	j	464 <vprintf+0x60>
          s = "(null)";
 56e:	00000997          	auipc	s3,0x0
 572:	24298993          	addi	s3,s3,578 # 7b0 <malloc+0xe8>
        while(*s != 0){
 576:	85ee                	mv	a1,s11
 578:	bff9                	j	556 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 57a:	008b0913          	addi	s2,s6,8
 57e:	000b4583          	lbu	a1,0(s6)
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	db2080e7          	jalr	-590(ra) # 336 <putc>
 58c:	8b4a                	mv	s6,s2
      state = 0;
 58e:	4981                	li	s3,0
 590:	bdd1                	j	464 <vprintf+0x60>
        putc(fd, c);
 592:	85d2                	mv	a1,s4
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	da0080e7          	jalr	-608(ra) # 336 <putc>
      state = 0;
 59e:	4981                	li	s3,0
 5a0:	b5d1                	j	464 <vprintf+0x60>
        putc(fd, '%');
 5a2:	85d2                	mv	a1,s4
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	d90080e7          	jalr	-624(ra) # 336 <putc>
        putc(fd, c);
 5ae:	85ca                	mv	a1,s2
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	d84080e7          	jalr	-636(ra) # 336 <putc>
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	b565                	j	464 <vprintf+0x60>
        s = va_arg(ap, char*);
 5be:	8b4a                	mv	s6,s2
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	b54d                	j	464 <vprintf+0x60>
    }
  }
}
 5c4:	70e6                	ld	ra,120(sp)
 5c6:	7446                	ld	s0,112(sp)
 5c8:	74a6                	ld	s1,104(sp)
 5ca:	7906                	ld	s2,96(sp)
 5cc:	69e6                	ld	s3,88(sp)
 5ce:	6a46                	ld	s4,80(sp)
 5d0:	6aa6                	ld	s5,72(sp)
 5d2:	6b06                	ld	s6,64(sp)
 5d4:	7be2                	ld	s7,56(sp)
 5d6:	7c42                	ld	s8,48(sp)
 5d8:	7ca2                	ld	s9,40(sp)
 5da:	7d02                	ld	s10,32(sp)
 5dc:	6de2                	ld	s11,24(sp)
 5de:	6109                	addi	sp,sp,128
 5e0:	8082                	ret

00000000000005e2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5e2:	715d                	addi	sp,sp,-80
 5e4:	ec06                	sd	ra,24(sp)
 5e6:	e822                	sd	s0,16(sp)
 5e8:	1000                	addi	s0,sp,32
 5ea:	e010                	sd	a2,0(s0)
 5ec:	e414                	sd	a3,8(s0)
 5ee:	e818                	sd	a4,16(s0)
 5f0:	ec1c                	sd	a5,24(s0)
 5f2:	03043023          	sd	a6,32(s0)
 5f6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 5fa:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 5fe:	8622                	mv	a2,s0
 600:	00000097          	auipc	ra,0x0
 604:	e04080e7          	jalr	-508(ra) # 404 <vprintf>
}
 608:	60e2                	ld	ra,24(sp)
 60a:	6442                	ld	s0,16(sp)
 60c:	6161                	addi	sp,sp,80
 60e:	8082                	ret

0000000000000610 <printf>:

void
printf(const char *fmt, ...)
{
 610:	711d                	addi	sp,sp,-96
 612:	ec06                	sd	ra,24(sp)
 614:	e822                	sd	s0,16(sp)
 616:	1000                	addi	s0,sp,32
 618:	e40c                	sd	a1,8(s0)
 61a:	e810                	sd	a2,16(s0)
 61c:	ec14                	sd	a3,24(s0)
 61e:	f018                	sd	a4,32(s0)
 620:	f41c                	sd	a5,40(s0)
 622:	03043823          	sd	a6,48(s0)
 626:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 62a:	00840613          	addi	a2,s0,8
 62e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 632:	85aa                	mv	a1,a0
 634:	4505                	li	a0,1
 636:	00000097          	auipc	ra,0x0
 63a:	dce080e7          	jalr	-562(ra) # 404 <vprintf>
}
 63e:	60e2                	ld	ra,24(sp)
 640:	6442                	ld	s0,16(sp)
 642:	6125                	addi	sp,sp,96
 644:	8082                	ret

0000000000000646 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 646:	1141                	addi	sp,sp,-16
 648:	e422                	sd	s0,8(sp)
 64a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 64c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 650:	00000797          	auipc	a5,0x0
 654:	1d87b783          	ld	a5,472(a5) # 828 <freep>
 658:	a02d                	j	682 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 65a:	4618                	lw	a4,8(a2)
 65c:	9f2d                	addw	a4,a4,a1
 65e:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 662:	6398                	ld	a4,0(a5)
 664:	6310                	ld	a2,0(a4)
 666:	a83d                	j	6a4 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 668:	ff852703          	lw	a4,-8(a0)
 66c:	9f31                	addw	a4,a4,a2
 66e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 670:	ff053683          	ld	a3,-16(a0)
 674:	a091                	j	6b8 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 676:	6398                	ld	a4,0(a5)
 678:	00e7e463          	bltu	a5,a4,680 <free+0x3a>
 67c:	00e6ea63          	bltu	a3,a4,690 <free+0x4a>
{
 680:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 682:	fed7fae3          	bgeu	a5,a3,676 <free+0x30>
 686:	6398                	ld	a4,0(a5)
 688:	00e6e463          	bltu	a3,a4,690 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68c:	fee7eae3          	bltu	a5,a4,680 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 690:	ff852583          	lw	a1,-8(a0)
 694:	6390                	ld	a2,0(a5)
 696:	02059813          	slli	a6,a1,0x20
 69a:	01c85713          	srli	a4,a6,0x1c
 69e:	9736                	add	a4,a4,a3
 6a0:	fae60de3          	beq	a2,a4,65a <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6a4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6a8:	4790                	lw	a2,8(a5)
 6aa:	02061593          	slli	a1,a2,0x20
 6ae:	01c5d713          	srli	a4,a1,0x1c
 6b2:	973e                	add	a4,a4,a5
 6b4:	fae68ae3          	beq	a3,a4,668 <free+0x22>
    p->s.ptr = bp->s.ptr;
 6b8:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6ba:	00000717          	auipc	a4,0x0
 6be:	16f73723          	sd	a5,366(a4) # 828 <freep>
}
 6c2:	6422                	ld	s0,8(sp)
 6c4:	0141                	addi	sp,sp,16
 6c6:	8082                	ret

00000000000006c8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6c8:	7139                	addi	sp,sp,-64
 6ca:	fc06                	sd	ra,56(sp)
 6cc:	f822                	sd	s0,48(sp)
 6ce:	f426                	sd	s1,40(sp)
 6d0:	f04a                	sd	s2,32(sp)
 6d2:	ec4e                	sd	s3,24(sp)
 6d4:	e852                	sd	s4,16(sp)
 6d6:	e456                	sd	s5,8(sp)
 6d8:	e05a                	sd	s6,0(sp)
 6da:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6dc:	02051493          	slli	s1,a0,0x20
 6e0:	9081                	srli	s1,s1,0x20
 6e2:	04bd                	addi	s1,s1,15
 6e4:	8091                	srli	s1,s1,0x4
 6e6:	0014899b          	addiw	s3,s1,1
 6ea:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6ec:	00000517          	auipc	a0,0x0
 6f0:	13c53503          	ld	a0,316(a0) # 828 <freep>
 6f4:	c515                	beqz	a0,720 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6f6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 6f8:	4798                	lw	a4,8(a5)
 6fa:	02977f63          	bgeu	a4,s1,738 <malloc+0x70>
 6fe:	8a4e                	mv	s4,s3
 700:	0009871b          	sext.w	a4,s3
 704:	6685                	lui	a3,0x1
 706:	00d77363          	bgeu	a4,a3,70c <malloc+0x44>
 70a:	6a05                	lui	s4,0x1
 70c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 710:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 714:	00000917          	auipc	s2,0x0
 718:	11490913          	addi	s2,s2,276 # 828 <freep>
  if(p == (char*)-1)
 71c:	5afd                	li	s5,-1
 71e:	a895                	j	792 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 720:	00000797          	auipc	a5,0x0
 724:	11078793          	addi	a5,a5,272 # 830 <base>
 728:	00000717          	auipc	a4,0x0
 72c:	10f73023          	sd	a5,256(a4) # 828 <freep>
 730:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 732:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 736:	b7e1                	j	6fe <malloc+0x36>
      if(p->s.size == nunits)
 738:	02e48c63          	beq	s1,a4,770 <malloc+0xa8>
        p->s.size -= nunits;
 73c:	4137073b          	subw	a4,a4,s3
 740:	c798                	sw	a4,8(a5)
        p += p->s.size;
 742:	02071693          	slli	a3,a4,0x20
 746:	01c6d713          	srli	a4,a3,0x1c
 74a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 74c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 750:	00000717          	auipc	a4,0x0
 754:	0ca73c23          	sd	a0,216(a4) # 828 <freep>
      return (void*)(p + 1);
 758:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 75c:	70e2                	ld	ra,56(sp)
 75e:	7442                	ld	s0,48(sp)
 760:	74a2                	ld	s1,40(sp)
 762:	7902                	ld	s2,32(sp)
 764:	69e2                	ld	s3,24(sp)
 766:	6a42                	ld	s4,16(sp)
 768:	6aa2                	ld	s5,8(sp)
 76a:	6b02                	ld	s6,0(sp)
 76c:	6121                	addi	sp,sp,64
 76e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 770:	6398                	ld	a4,0(a5)
 772:	e118                	sd	a4,0(a0)
 774:	bff1                	j	750 <malloc+0x88>
  hp->s.size = nu;
 776:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 77a:	0541                	addi	a0,a0,16
 77c:	00000097          	auipc	ra,0x0
 780:	eca080e7          	jalr	-310(ra) # 646 <free>
  return freep;
 784:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 788:	d971                	beqz	a0,75c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 78a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 78c:	4798                	lw	a4,8(a5)
 78e:	fa9775e3          	bgeu	a4,s1,738 <malloc+0x70>
    if(p == freep)
 792:	00093703          	ld	a4,0(s2)
 796:	853e                	mv	a0,a5
 798:	fef719e3          	bne	a4,a5,78a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 79c:	8552                	mv	a0,s4
 79e:	00000097          	auipc	ra,0x0
 7a2:	b80080e7          	jalr	-1152(ra) # 31e <sbrk>
  if(p == (char*)-1)
 7a6:	fd5518e3          	bne	a0,s5,776 <malloc+0xae>
        return 0;
 7aa:	4501                	li	a0,0
 7ac:	bf45                	j	75c <malloc+0x94>
