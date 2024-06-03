
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae010113          	addi	sp,sp,-1312 # 80008ae0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	94e70713          	addi	a4,a4,-1714 # 800089a0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e3c78793          	addi	a5,a5,-452 # 80005ea0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc9cf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f9478793          	addi	a5,a5,-108 # 80001042 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	550080e7          	jalr	1360(ra) # 8000267c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

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
    8000018e:	95650513          	addi	a0,a0,-1706 # 80010ae0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	c0e080e7          	jalr	-1010(ra) # 80000da0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	94648493          	addi	s1,s1,-1722 # 80010ae0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9d690913          	addi	s2,s2,-1578 # 80010b78 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

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
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9b6080e7          	jalr	-1610(ra) # 80001b76 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2fe080e7          	jalr	766(ra) # 800024c6 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	048080e7          	jalr	72(ra) # 8000221e <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	414080e7          	jalr	1044(ra) # 80002626 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8ba50513          	addi	a0,a0,-1862 # 80010ae0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c26080e7          	jalr	-986(ra) # 80000e54 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8a450513          	addi	a0,a0,-1884 # 80010ae0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	c10080e7          	jalr	-1008(ra) # 80000e54 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	90f72323          	sw	a5,-1786(a4) # 80010b78 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	81450513          	addi	a0,a0,-2028 # 80010ae0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	acc080e7          	jalr	-1332(ra) # 80000da0 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3e0080e7          	jalr	992(ra) # 800026d2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7e650513          	addi	a0,a0,2022 # 80010ae0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b52080e7          	jalr	-1198(ra) # 80000e54 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7c270713          	addi	a4,a4,1986 # 80010ae0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	79878793          	addi	a5,a5,1944 # 80010ae0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8027a783          	lw	a5,-2046(a5) # 80010b78 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	75670713          	addi	a4,a4,1878 # 80010ae0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	74648493          	addi	s1,s1,1862 # 80010ae0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	70a70713          	addi	a4,a4,1802 # 80010ae0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	78f72a23          	sw	a5,1940(a4) # 80010b80 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6ce78793          	addi	a5,a5,1742 # 80010ae0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	74c7a323          	sw	a2,1862(a5) # 80010b7c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	73a50513          	addi	a0,a0,1850 # 80010b78 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e3c080e7          	jalr	-452(ra) # 80002282 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	68050513          	addi	a0,a0,1664 # 80010ae0 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	8a8080e7          	jalr	-1880(ra) # 80000d10 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	82078793          	addi	a5,a5,-2016 # 80020c98 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6407ab23          	sw	zero,1622(a5) # 80010ba0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b3c50513          	addi	a0,a0,-1220 # 800080a8 <digits+0x68>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	3ef72123          	sw	a5,994(a4) # 80008960 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	5e6dad83          	lw	s11,1510(s11) # 80010ba0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	59050513          	addi	a0,a0,1424 # 80010b88 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	7a0080e7          	jalr	1952(ra) # 80000da0 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	43250513          	addi	a0,a0,1074 # 80010b88 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	6f6080e7          	jalr	1782(ra) # 80000e54 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	41648493          	addi	s1,s1,1046 # 80010b88 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	58c080e7          	jalr	1420(ra) # 80000d10 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	3d650513          	addi	a0,a0,982 # 80010ba8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	536080e7          	jalr	1334(ra) # 80000d10 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	55e080e7          	jalr	1374(ra) # 80000d54 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1627a783          	lw	a5,354(a5) # 80008960 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	5d0080e7          	jalr	1488(ra) # 80000df4 <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1327b783          	ld	a5,306(a5) # 80008968 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	13273703          	ld	a4,306(a4) # 80008970 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	348a0a13          	addi	s4,s4,840 # 80010ba8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	10048493          	addi	s1,s1,256 # 80008968 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	10098993          	addi	s3,s3,256 # 80008970 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	9f0080e7          	jalr	-1552(ra) # 80002282 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	2da50513          	addi	a0,a0,730 # 80010ba8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	4ca080e7          	jalr	1226(ra) # 80000da0 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0827a783          	lw	a5,130(a5) # 80008960 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	08873703          	ld	a4,136(a4) # 80008970 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0787b783          	ld	a5,120(a5) # 80008968 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	2ac98993          	addi	s3,s3,684 # 80010ba8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	06448493          	addi	s1,s1,100 # 80008968 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	06490913          	addi	s2,s2,100 # 80008970 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	902080e7          	jalr	-1790(ra) # 8000221e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	27648493          	addi	s1,s1,630 # 80010ba8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	02e7b523          	sd	a4,42(a5) # 80008970 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	4fc080e7          	jalr	1276(ra) # 80000e54 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	1ec48493          	addi	s1,s1,492 # 80010ba8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	3da080e7          	jalr	986(ra) # 80000da0 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	47c080e7          	jalr	1148(ra) # 80000e54 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	43278793          	addi	a5,a5,1074 # 80021e30 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	486080e7          	jalr	1158(ra) # 80000e9c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	1c290913          	addi	s2,s2,450 # 80010be0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	378080e7          	jalr	888(ra) # 80000da0 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	418080e7          	jalr	1048(ra) # 80000e54 <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000aaa:	1101                	addi	sp,sp,-32
    80000aac:	ec06                	sd	ra,24(sp)
    80000aae:	e822                	sd	s0,16(sp)
    80000ab0:	e426                	sd	s1,8(sp)
    80000ab2:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000ab4:	00010497          	auipc	s1,0x10
    80000ab8:	12c48493          	addi	s1,s1,300 # 80010be0 <kmem>
    80000abc:	8526                	mv	a0,s1
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	2e2080e7          	jalr	738(ra) # 80000da0 <acquire>
  r = kmem.freelist;
    80000ac6:	6c84                	ld	s1,24(s1)
  if(r)
    80000ac8:	c885                	beqz	s1,80000af8 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000aca:	609c                	ld	a5,0(s1)
    80000acc:	00010517          	auipc	a0,0x10
    80000ad0:	11450513          	addi	a0,a0,276 # 80010be0 <kmem>
    80000ad4:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	37e080e7          	jalr	894(ra) # 80000e54 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ade:	6605                	lui	a2,0x1
    80000ae0:	4595                	li	a1,5
    80000ae2:	8526                	mv	a0,s1
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	3b8080e7          	jalr	952(ra) # 80000e9c <memset>
  return (void*)r;
}
    80000aec:	8526                	mv	a0,s1
    80000aee:	60e2                	ld	ra,24(sp)
    80000af0:	6442                	ld	s0,16(sp)
    80000af2:	64a2                	ld	s1,8(sp)
    80000af4:	6105                	addi	sp,sp,32
    80000af6:	8082                	ret
  release(&kmem.lock);
    80000af8:	00010517          	auipc	a0,0x10
    80000afc:	0e850513          	addi	a0,a0,232 # 80010be0 <kmem>
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	354080e7          	jalr	852(ra) # 80000e54 <release>
  if(r)
    80000b08:	b7d5                	j	80000aec <kalloc+0x42>

0000000080000b0a <heap_init>:
struct {
    struct spinlock lock;
    struct heap_block *free_list;
} heap;

void heap_init(void *heap_start, int size) {
    80000b0a:	7179                	addi	sp,sp,-48
    80000b0c:	f406                	sd	ra,40(sp)
    80000b0e:	f022                	sd	s0,32(sp)
    80000b10:	ec26                	sd	s1,24(sp)
    80000b12:	e84a                	sd	s2,16(sp)
    80000b14:	e44e                	sd	s3,8(sp)
    80000b16:	1800                	addi	s0,sp,48
    80000b18:	892a                	mv	s2,a0
    80000b1a:	84ae                	mv	s1,a1
    initlock(&heap.lock, "heap");
    80000b1c:	00010997          	auipc	s3,0x10
    80000b20:	0c498993          	addi	s3,s3,196 # 80010be0 <kmem>
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	addi	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	0d450513          	addi	a0,a0,212 # 80010c00 <heap>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1dc080e7          	jalr	476(ra) # 80000d10 <initlock>
    heap.free_list = (struct heap_block*)heap_start;
    80000b3c:	0329bc23          	sd	s2,56(s3)
    heap.free_list->size = size - sizeof(struct heap_block);
    80000b40:	34c1                	addiw	s1,s1,-16
    80000b42:	00992023          	sw	s1,0(s2)
    heap.free_list->next = 0;
    80000b46:	0389b783          	ld	a5,56(s3)
    80000b4a:	0007b423          	sd	zero,8(a5)
    heap.free_list->free = 1;
    80000b4e:	0389b783          	ld	a5,56(s3)
    80000b52:	4705                	li	a4,1
    80000b54:	c3d8                	sw	a4,4(a5)
}
    80000b56:	70a2                	ld	ra,40(sp)
    80000b58:	7402                	ld	s0,32(sp)
    80000b5a:	64e2                	ld	s1,24(sp)
    80000b5c:	6942                	ld	s2,16(sp)
    80000b5e:	69a2                	ld	s3,8(sp)
    80000b60:	6145                	addi	sp,sp,48
    80000b62:	8082                	ret

0000000080000b64 <kinit>:
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  initlock(&kmem.lock, "kmem");
    80000b6e:	00007597          	auipc	a1,0x7
    80000b72:	50258593          	addi	a1,a1,1282 # 80008070 <digits+0x30>
    80000b76:	00010517          	auipc	a0,0x10
    80000b7a:	06a50513          	addi	a0,a0,106 # 80010be0 <kmem>
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	192080e7          	jalr	402(ra) # 80000d10 <initlock>
    freerange(end, heap_start);
    80000b86:	08700493          	li	s1,135
    80000b8a:	01849593          	slli	a1,s1,0x18
    80000b8e:	00021517          	auipc	a0,0x21
    80000b92:	2a250513          	addi	a0,a0,674 # 80021e30 <end>
    80000b96:	00000097          	auipc	ra,0x0
    80000b9a:	eca080e7          	jalr	-310(ra) # 80000a60 <freerange>
    heap_init(heap_start, HEAP_SIZE);
    80000b9e:	010005b7          	lui	a1,0x1000
    80000ba2:	01849513          	slli	a0,s1,0x18
    80000ba6:	00000097          	auipc	ra,0x0
    80000baa:	f64080e7          	jalr	-156(ra) # 80000b0a <heap_init>
}
    80000bae:	60e2                	ld	ra,24(sp)
    80000bb0:	6442                	ld	s0,16(sp)
    80000bb2:	64a2                	ld	s1,8(sp)
    80000bb4:	6105                	addi	sp,sp,32
    80000bb6:	8082                	ret

0000000080000bb8 <malloc>:


void *malloc(int size) {
    80000bb8:	1101                	addi	sp,sp,-32
    80000bba:	ec06                	sd	ra,24(sp)
    80000bbc:	e822                	sd	s0,16(sp)
    80000bbe:	e426                	sd	s1,8(sp)
    80000bc0:	e04a                	sd	s2,0(sp)
    80000bc2:	1000                	addi	s0,sp,32
    80000bc4:	892a                	mv	s2,a0
    struct heap_block *curr;
    void *result = 0;

    acquire(&heap.lock);
    80000bc6:	00010517          	auipc	a0,0x10
    80000bca:	03a50513          	addi	a0,a0,58 # 80010c00 <heap>
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1d2080e7          	jalr	466(ra) # 80000da0 <acquire>

    for (curr = heap.free_list; curr != 0; curr = curr->next) {
    80000bd6:	00010497          	auipc	s1,0x10
    80000bda:	0424b483          	ld	s1,66(s1) # 80010c18 <heap+0x18>
    80000bde:	cc9d                	beqz	s1,80000c1c <malloc+0x64>
        if (curr->free && curr->size >= size + sizeof(struct heap_block)) {
    80000be0:	01090713          	addi	a4,s2,16
    80000be4:	a019                	j	80000bea <malloc+0x32>
    for (curr = heap.free_list; curr != 0; curr = curr->next) {
    80000be6:	6484                	ld	s1,8(s1)
    80000be8:	c895                	beqz	s1,80000c1c <malloc+0x64>
        if (curr->free && curr->size >= size + sizeof(struct heap_block)) {
    80000bea:	40dc                	lw	a5,4(s1)
    80000bec:	dfed                	beqz	a5,80000be6 <malloc+0x2e>
    80000bee:	409c                	lw	a5,0(s1)
    80000bf0:	fee7ebe3          	bltu	a5,a4,80000be6 <malloc+0x2e>

                if(curr->size - size - sizeof(struct heap_block) != 0){
    80000bf4:	412787bb          	subw	a5,a5,s2
    80000bf8:	0007861b          	sext.w	a2,a5
    80000bfc:	46c1                	li	a3,16
    80000bfe:	00d60a63          	beq	a2,a3,80000c12 <malloc+0x5a>
                  struct heap_block *new_block = (struct heap_block*)((char*)curr + sizeof(struct heap_block) + size);
    80000c02:	9726                	add	a4,a4,s1
                  new_block->size = curr->size - size - sizeof(struct heap_block);
    80000c04:	37c1                	addiw	a5,a5,-16
    80000c06:	c31c                	sw	a5,0(a4)
                  new_block->next = curr->next;
    80000c08:	649c                	ld	a5,8(s1)
    80000c0a:	e71c                	sd	a5,8(a4)
                  new_block->free = 1;
    80000c0c:	4785                	li	a5,1
    80000c0e:	c35c                	sw	a5,4(a4)
                  curr->next = new_block;
    80000c10:	e498                	sd	a4,8(s1)
                }
                
            curr->size = size;
    80000c12:	0124a023          	sw	s2,0(s1)
            curr->free = 0;
    80000c16:	0004a223          	sw	zero,4(s1)
            result = (void*)((char*)curr + sizeof(struct heap_block));
    80000c1a:	04c1                	addi	s1,s1,16
            break;
        }
    }
    release(&heap.lock);
    80000c1c:	00010517          	auipc	a0,0x10
    80000c20:	fe450513          	addi	a0,a0,-28 # 80010c00 <heap>
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	230080e7          	jalr	560(ra) # 80000e54 <release>
    return result;
}
    80000c2c:	8526                	mv	a0,s1
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6902                	ld	s2,0(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret

0000000080000c3a <free>:

void free(void *ptr) {
    if(!ptr)
    80000c3a:	c93d                	beqz	a0,80000cb0 <free+0x76>
void free(void *ptr) {
    80000c3c:	1101                	addi	sp,sp,-32
    80000c3e:	ec06                	sd	ra,24(sp)
    80000c40:	e822                	sd	s0,16(sp)
    80000c42:	e426                	sd	s1,8(sp)
    80000c44:	1000                	addi	s0,sp,32
    80000c46:	84aa                	mv	s1,a0
        return;

    struct heap_block *block = (struct heap_block*)((char*)ptr - sizeof(struct heap_block));
    acquire(&heap.lock);
    80000c48:	00010517          	auipc	a0,0x10
    80000c4c:	fb850513          	addi	a0,a0,-72 # 80010c00 <heap>
    80000c50:	00000097          	auipc	ra,0x0
    80000c54:	150080e7          	jalr	336(ra) # 80000da0 <acquire>
    block->free = 1;
    80000c58:	4785                	li	a5,1
    80000c5a:	fef4aa23          	sw	a5,-12(s1)
    block->size += sizeof(struct heap_block);
    80000c5e:	ff04a783          	lw	a5,-16(s1)
    80000c62:	27c1                	addiw	a5,a5,16
    80000c64:	fef4a823          	sw	a5,-16(s1)

    struct heap_block *curr = heap.free_list;
    80000c68:	00010797          	auipc	a5,0x10
    80000c6c:	fb07b783          	ld	a5,-80(a5) # 80010c18 <heap+0x18>
    while (curr != 0){
    80000c70:	e385                	bnez	a5,80000c90 <free+0x56>
            curr->next = curr->next->next;
        }else{
            curr = curr->next;
        }
    }
    release(&heap.lock);
    80000c72:	00010517          	auipc	a0,0x10
    80000c76:	f8e50513          	addi	a0,a0,-114 # 80010c00 <heap>
    80000c7a:	00000097          	auipc	ra,0x0
    80000c7e:	1da080e7          	jalr	474(ra) # 80000e54 <release>
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
            curr = curr->next;
    80000c8c:	679c                	ld	a5,8(a5)
    while (curr != 0){
    80000c8e:	d3f5                	beqz	a5,80000c72 <free+0x38>
        if (curr->free && curr->next && curr->next->free) {
    80000c90:	43d8                	lw	a4,4(a5)
    80000c92:	df6d                	beqz	a4,80000c8c <free+0x52>
    80000c94:	6798                	ld	a4,8(a5)
    80000c96:	df71                	beqz	a4,80000c72 <free+0x38>
    80000c98:	4354                	lw	a3,4(a4)
    80000c9a:	ca89                	beqz	a3,80000cac <free+0x72>
            curr->size += curr->next->size + sizeof(struct heap_block);
    80000c9c:	4394                	lw	a3,0(a5)
    80000c9e:	26c1                	addiw	a3,a3,16
    80000ca0:	4310                	lw	a2,0(a4)
    80000ca2:	9eb1                	addw	a3,a3,a2
    80000ca4:	c394                	sw	a3,0(a5)
            curr->next = curr->next->next;
    80000ca6:	6718                	ld	a4,8(a4)
    80000ca8:	e798                	sd	a4,8(a5)
    while (curr != 0){
    80000caa:	b7dd                	j	80000c90 <free+0x56>
            curr = curr->next;
    80000cac:	679c                	ld	a5,8(a5)
    while (curr != 0){
    80000cae:	b7cd                	j	80000c90 <free+0x56>
    80000cb0:	8082                	ret

0000000080000cb2 <printheap>:

void printheap(){
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	e04a                	sd	s2,0(sp)
    80000cbc:	1000                	addi	s0,sp,32
    acquire(&heap.lock);
    80000cbe:	00010517          	auipc	a0,0x10
    80000cc2:	f4250513          	addi	a0,a0,-190 # 80010c00 <heap>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	0da080e7          	jalr	218(ra) # 80000da0 <acquire>

    for (struct heap_block *curr = heap.free_list; curr != 0; curr = curr->next) {
    80000cce:	00010497          	auipc	s1,0x10
    80000cd2:	f4a4b483          	ld	s1,-182(s1) # 80010c18 <heap+0x18>
    80000cd6:	cc99                	beqz	s1,80000cf4 <printheap+0x42>
        printf("the heap is  at  %p ,free state is %d,size is %d\n", curr,curr->free,curr->size);
    80000cd8:	00007917          	auipc	s2,0x7
    80000cdc:	3a090913          	addi	s2,s2,928 # 80008078 <digits+0x38>
    80000ce0:	4094                	lw	a3,0(s1)
    80000ce2:	40d0                	lw	a2,4(s1)
    80000ce4:	85a6                	mv	a1,s1
    80000ce6:	854a                	mv	a0,s2
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	8a0080e7          	jalr	-1888(ra) # 80000588 <printf>
    for (struct heap_block *curr = heap.free_list; curr != 0; curr = curr->next) {
    80000cf0:	6484                	ld	s1,8(s1)
    80000cf2:	f4fd                	bnez	s1,80000ce0 <printheap+0x2e>

    }

    release(&heap.lock);
    80000cf4:	00010517          	auipc	a0,0x10
    80000cf8:	f0c50513          	addi	a0,a0,-244 # 80010c00 <heap>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	158080e7          	jalr	344(ra) # 80000e54 <release>
};
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6902                	ld	s2,0(sp)
    80000d0c:	6105                	addi	sp,sp,32
    80000d0e:	8082                	ret

0000000080000d10 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d10:	1141                	addi	sp,sp,-16
    80000d12:	e422                	sd	s0,8(sp)
    80000d14:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d16:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d18:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d1c:	00053823          	sd	zero,16(a0)
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret

0000000080000d26 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d26:	411c                	lw	a5,0(a0)
    80000d28:	e399                	bnez	a5,80000d2e <holding+0x8>
    80000d2a:	4501                	li	a0,0
  return r;
}
    80000d2c:	8082                	ret
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d38:	6904                	ld	s1,16(a0)
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	e20080e7          	jalr	-480(ra) # 80001b5a <mycpu>
    80000d42:	40a48533          	sub	a0,s1,a0
    80000d46:	00153513          	seqz	a0,a0
}
    80000d4a:	60e2                	ld	ra,24(sp)
    80000d4c:	6442                	ld	s0,16(sp)
    80000d4e:	64a2                	ld	s1,8(sp)
    80000d50:	6105                	addi	sp,sp,32
    80000d52:	8082                	ret

0000000080000d54 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d54:	1101                	addi	sp,sp,-32
    80000d56:	ec06                	sd	ra,24(sp)
    80000d58:	e822                	sd	s0,16(sp)
    80000d5a:	e426                	sd	s1,8(sp)
    80000d5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d5e:	100024f3          	csrr	s1,sstatus
    80000d62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d66:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d68:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d6c:	00001097          	auipc	ra,0x1
    80000d70:	dee080e7          	jalr	-530(ra) # 80001b5a <mycpu>
    80000d74:	5d3c                	lw	a5,120(a0)
    80000d76:	cf89                	beqz	a5,80000d90 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d78:	00001097          	auipc	ra,0x1
    80000d7c:	de2080e7          	jalr	-542(ra) # 80001b5a <mycpu>
    80000d80:	5d3c                	lw	a5,120(a0)
    80000d82:	2785                	addiw	a5,a5,1
    80000d84:	dd3c                	sw	a5,120(a0)
}
    80000d86:	60e2                	ld	ra,24(sp)
    80000d88:	6442                	ld	s0,16(sp)
    80000d8a:	64a2                	ld	s1,8(sp)
    80000d8c:	6105                	addi	sp,sp,32
    80000d8e:	8082                	ret
    mycpu()->intena = old;
    80000d90:	00001097          	auipc	ra,0x1
    80000d94:	dca080e7          	jalr	-566(ra) # 80001b5a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d98:	8085                	srli	s1,s1,0x1
    80000d9a:	8885                	andi	s1,s1,1
    80000d9c:	dd64                	sw	s1,124(a0)
    80000d9e:	bfe9                	j	80000d78 <push_off+0x24>

0000000080000da0 <acquire>:
{
    80000da0:	1101                	addi	sp,sp,-32
    80000da2:	ec06                	sd	ra,24(sp)
    80000da4:	e822                	sd	s0,16(sp)
    80000da6:	e426                	sd	s1,8(sp)
    80000da8:	1000                	addi	s0,sp,32
    80000daa:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000dac:	00000097          	auipc	ra,0x0
    80000db0:	fa8080e7          	jalr	-88(ra) # 80000d54 <push_off>
  if(holding(lk))
    80000db4:	8526                	mv	a0,s1
    80000db6:	00000097          	auipc	ra,0x0
    80000dba:	f70080e7          	jalr	-144(ra) # 80000d26 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dbe:	4705                	li	a4,1
  if(holding(lk))
    80000dc0:	e115                	bnez	a0,80000de4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dc2:	87ba                	mv	a5,a4
    80000dc4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dc8:	2781                	sext.w	a5,a5
    80000dca:	ffe5                	bnez	a5,80000dc2 <acquire+0x22>
  __sync_synchronize();
    80000dcc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dd0:	00001097          	auipc	ra,0x1
    80000dd4:	d8a080e7          	jalr	-630(ra) # 80001b5a <mycpu>
    80000dd8:	e888                	sd	a0,16(s1)
}
    80000dda:	60e2                	ld	ra,24(sp)
    80000ddc:	6442                	ld	s0,16(sp)
    80000dde:	64a2                	ld	s1,8(sp)
    80000de0:	6105                	addi	sp,sp,32
    80000de2:	8082                	ret
    panic("acquire");
    80000de4:	00007517          	auipc	a0,0x7
    80000de8:	2cc50513          	addi	a0,a0,716 # 800080b0 <digits+0x70>
    80000dec:	fffff097          	auipc	ra,0xfffff
    80000df0:	752080e7          	jalr	1874(ra) # 8000053e <panic>

0000000080000df4 <pop_off>:

void
pop_off(void)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e406                	sd	ra,8(sp)
    80000df8:	e022                	sd	s0,0(sp)
    80000dfa:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dfc:	00001097          	auipc	ra,0x1
    80000e00:	d5e080e7          	jalr	-674(ra) # 80001b5a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e04:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e08:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e0a:	e78d                	bnez	a5,80000e34 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e0c:	5d3c                	lw	a5,120(a0)
    80000e0e:	02f05b63          	blez	a5,80000e44 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e12:	37fd                	addiw	a5,a5,-1
    80000e14:	0007871b          	sext.w	a4,a5
    80000e18:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e1a:	eb09                	bnez	a4,80000e2c <pop_off+0x38>
    80000e1c:	5d7c                	lw	a5,124(a0)
    80000e1e:	c799                	beqz	a5,80000e2c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e28:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e2c:	60a2                	ld	ra,8(sp)
    80000e2e:	6402                	ld	s0,0(sp)
    80000e30:	0141                	addi	sp,sp,16
    80000e32:	8082                	ret
    panic("pop_off - interruptible");
    80000e34:	00007517          	auipc	a0,0x7
    80000e38:	28450513          	addi	a0,a0,644 # 800080b8 <digits+0x78>
    80000e3c:	fffff097          	auipc	ra,0xfffff
    80000e40:	702080e7          	jalr	1794(ra) # 8000053e <panic>
    panic("pop_off");
    80000e44:	00007517          	auipc	a0,0x7
    80000e48:	28c50513          	addi	a0,a0,652 # 800080d0 <digits+0x90>
    80000e4c:	fffff097          	auipc	ra,0xfffff
    80000e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>

0000000080000e54 <release>:
{
    80000e54:	1101                	addi	sp,sp,-32
    80000e56:	ec06                	sd	ra,24(sp)
    80000e58:	e822                	sd	s0,16(sp)
    80000e5a:	e426                	sd	s1,8(sp)
    80000e5c:	1000                	addi	s0,sp,32
    80000e5e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e60:	00000097          	auipc	ra,0x0
    80000e64:	ec6080e7          	jalr	-314(ra) # 80000d26 <holding>
    80000e68:	c115                	beqz	a0,80000e8c <release+0x38>
  lk->cpu = 0;
    80000e6a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e6e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e72:	0f50000f          	fence	iorw,ow
    80000e76:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e7a:	00000097          	auipc	ra,0x0
    80000e7e:	f7a080e7          	jalr	-134(ra) # 80000df4 <pop_off>
}
    80000e82:	60e2                	ld	ra,24(sp)
    80000e84:	6442                	ld	s0,16(sp)
    80000e86:	64a2                	ld	s1,8(sp)
    80000e88:	6105                	addi	sp,sp,32
    80000e8a:	8082                	ret
    panic("release");
    80000e8c:	00007517          	auipc	a0,0x7
    80000e90:	24c50513          	addi	a0,a0,588 # 800080d8 <digits+0x98>
    80000e94:	fffff097          	auipc	ra,0xfffff
    80000e98:	6aa080e7          	jalr	1706(ra) # 8000053e <panic>

0000000080000e9c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ea2:	ca19                	beqz	a2,80000eb8 <memset+0x1c>
    80000ea4:	87aa                	mv	a5,a0
    80000ea6:	1602                	slli	a2,a2,0x20
    80000ea8:	9201                	srli	a2,a2,0x20
    80000eaa:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000eae:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	fee79de3          	bne	a5,a4,80000eae <memset+0x12>
  }
  return dst;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ec4:	ca05                	beqz	a2,80000ef4 <memcmp+0x36>
    80000ec6:	fff6069b          	addiw	a3,a2,-1
    80000eca:	1682                	slli	a3,a3,0x20
    80000ecc:	9281                	srli	a3,a3,0x20
    80000ece:	0685                	addi	a3,a3,1
    80000ed0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ed2:	00054783          	lbu	a5,0(a0)
    80000ed6:	0005c703          	lbu	a4,0(a1) # 1000000 <_entry-0x7f000000>
    80000eda:	00e79863          	bne	a5,a4,80000eea <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ede:	0505                	addi	a0,a0,1
    80000ee0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ee2:	fed518e3          	bne	a0,a3,80000ed2 <memcmp+0x14>
  }

  return 0;
    80000ee6:	4501                	li	a0,0
    80000ee8:	a019                	j	80000eee <memcmp+0x30>
      return *s1 - *s2;
    80000eea:	40e7853b          	subw	a0,a5,a4
}
    80000eee:	6422                	ld	s0,8(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
  return 0;
    80000ef4:	4501                	li	a0,0
    80000ef6:	bfe5                	j	80000eee <memcmp+0x30>

0000000080000ef8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e422                	sd	s0,8(sp)
    80000efc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000efe:	c205                	beqz	a2,80000f1e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f00:	02a5e263          	bltu	a1,a0,80000f24 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f04:	1602                	slli	a2,a2,0x20
    80000f06:	9201                	srli	a2,a2,0x20
    80000f08:	00c587b3          	add	a5,a1,a2
{
    80000f0c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f0e:	0585                	addi	a1,a1,1
    80000f10:	0705                	addi	a4,a4,1
    80000f12:	fff5c683          	lbu	a3,-1(a1)
    80000f16:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f1a:	fef59ae3          	bne	a1,a5,80000f0e <memmove+0x16>

  return dst;
}
    80000f1e:	6422                	ld	s0,8(sp)
    80000f20:	0141                	addi	sp,sp,16
    80000f22:	8082                	ret
  if(s < d && s + n > d){
    80000f24:	02061693          	slli	a3,a2,0x20
    80000f28:	9281                	srli	a3,a3,0x20
    80000f2a:	00d58733          	add	a4,a1,a3
    80000f2e:	fce57be3          	bgeu	a0,a4,80000f04 <memmove+0xc>
    d += n;
    80000f32:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f34:	fff6079b          	addiw	a5,a2,-1
    80000f38:	1782                	slli	a5,a5,0x20
    80000f3a:	9381                	srli	a5,a5,0x20
    80000f3c:	fff7c793          	not	a5,a5
    80000f40:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f42:	177d                	addi	a4,a4,-1
    80000f44:	16fd                	addi	a3,a3,-1
    80000f46:	00074603          	lbu	a2,0(a4)
    80000f4a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f4e:	fee79ae3          	bne	a5,a4,80000f42 <memmove+0x4a>
    80000f52:	b7f1                	j	80000f1e <memmove+0x26>

0000000080000f54 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f54:	1141                	addi	sp,sp,-16
    80000f56:	e406                	sd	ra,8(sp)
    80000f58:	e022                	sd	s0,0(sp)
    80000f5a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	f9c080e7          	jalr	-100(ra) # 80000ef8 <memmove>
}
    80000f64:	60a2                	ld	ra,8(sp)
    80000f66:	6402                	ld	s0,0(sp)
    80000f68:	0141                	addi	sp,sp,16
    80000f6a:	8082                	ret

0000000080000f6c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f6c:	1141                	addi	sp,sp,-16
    80000f6e:	e422                	sd	s0,8(sp)
    80000f70:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f72:	ce11                	beqz	a2,80000f8e <strncmp+0x22>
    80000f74:	00054783          	lbu	a5,0(a0)
    80000f78:	cf89                	beqz	a5,80000f92 <strncmp+0x26>
    80000f7a:	0005c703          	lbu	a4,0(a1)
    80000f7e:	00f71a63          	bne	a4,a5,80000f92 <strncmp+0x26>
    n--, p++, q++;
    80000f82:	367d                	addiw	a2,a2,-1
    80000f84:	0505                	addi	a0,a0,1
    80000f86:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f88:	f675                	bnez	a2,80000f74 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f8a:	4501                	li	a0,0
    80000f8c:	a809                	j	80000f9e <strncmp+0x32>
    80000f8e:	4501                	li	a0,0
    80000f90:	a039                	j	80000f9e <strncmp+0x32>
  if(n == 0)
    80000f92:	ca09                	beqz	a2,80000fa4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f94:	00054503          	lbu	a0,0(a0)
    80000f98:	0005c783          	lbu	a5,0(a1)
    80000f9c:	9d1d                	subw	a0,a0,a5
}
    80000f9e:	6422                	ld	s0,8(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret
    return 0;
    80000fa4:	4501                	li	a0,0
    80000fa6:	bfe5                	j	80000f9e <strncmp+0x32>

0000000080000fa8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fae:	872a                	mv	a4,a0
    80000fb0:	8832                	mv	a6,a2
    80000fb2:	367d                	addiw	a2,a2,-1
    80000fb4:	01005963          	blez	a6,80000fc6 <strncpy+0x1e>
    80000fb8:	0705                	addi	a4,a4,1
    80000fba:	0005c783          	lbu	a5,0(a1)
    80000fbe:	fef70fa3          	sb	a5,-1(a4)
    80000fc2:	0585                	addi	a1,a1,1
    80000fc4:	f7f5                	bnez	a5,80000fb0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fc6:	86ba                	mv	a3,a4
    80000fc8:	00c05c63          	blez	a2,80000fe0 <strncpy+0x38>
    *s++ = 0;
    80000fcc:	0685                	addi	a3,a3,1
    80000fce:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fd2:	fff6c793          	not	a5,a3
    80000fd6:	9fb9                	addw	a5,a5,a4
    80000fd8:	010787bb          	addw	a5,a5,a6
    80000fdc:	fef048e3          	bgtz	a5,80000fcc <strncpy+0x24>
  return os;
}
    80000fe0:	6422                	ld	s0,8(sp)
    80000fe2:	0141                	addi	sp,sp,16
    80000fe4:	8082                	ret

0000000080000fe6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fe6:	1141                	addi	sp,sp,-16
    80000fe8:	e422                	sd	s0,8(sp)
    80000fea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fec:	02c05363          	blez	a2,80001012 <safestrcpy+0x2c>
    80000ff0:	fff6069b          	addiw	a3,a2,-1
    80000ff4:	1682                	slli	a3,a3,0x20
    80000ff6:	9281                	srli	a3,a3,0x20
    80000ff8:	96ae                	add	a3,a3,a1
    80000ffa:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ffc:	00d58963          	beq	a1,a3,8000100e <safestrcpy+0x28>
    80001000:	0585                	addi	a1,a1,1
    80001002:	0785                	addi	a5,a5,1
    80001004:	fff5c703          	lbu	a4,-1(a1)
    80001008:	fee78fa3          	sb	a4,-1(a5)
    8000100c:	fb65                	bnez	a4,80000ffc <safestrcpy+0x16>
    ;
  *s = 0;
    8000100e:	00078023          	sb	zero,0(a5)
  return os;
}
    80001012:	6422                	ld	s0,8(sp)
    80001014:	0141                	addi	sp,sp,16
    80001016:	8082                	ret

0000000080001018 <strlen>:

int
strlen(const char *s)
{
    80001018:	1141                	addi	sp,sp,-16
    8000101a:	e422                	sd	s0,8(sp)
    8000101c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000101e:	00054783          	lbu	a5,0(a0)
    80001022:	cf91                	beqz	a5,8000103e <strlen+0x26>
    80001024:	0505                	addi	a0,a0,1
    80001026:	87aa                	mv	a5,a0
    80001028:	4685                	li	a3,1
    8000102a:	9e89                	subw	a3,a3,a0
    8000102c:	00f6853b          	addw	a0,a3,a5
    80001030:	0785                	addi	a5,a5,1
    80001032:	fff7c703          	lbu	a4,-1(a5)
    80001036:	fb7d                	bnez	a4,8000102c <strlen+0x14>
    ;
  return n;
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret
  for(n = 0; s[n]; n++)
    8000103e:	4501                	li	a0,0
    80001040:	bfe5                	j	80001038 <strlen+0x20>

0000000080001042 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001042:	1141                	addi	sp,sp,-16
    80001044:	e406                	sd	ra,8(sp)
    80001046:	e022                	sd	s0,0(sp)
    80001048:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000104a:	00001097          	auipc	ra,0x1
    8000104e:	b00080e7          	jalr	-1280(ra) # 80001b4a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001052:	00008717          	auipc	a4,0x8
    80001056:	92670713          	addi	a4,a4,-1754 # 80008978 <started>
  if(cpuid() == 0){
    8000105a:	c139                	beqz	a0,800010a0 <main+0x5e>
    while(started == 0)
    8000105c:	431c                	lw	a5,0(a4)
    8000105e:	2781                	sext.w	a5,a5
    80001060:	dff5                	beqz	a5,8000105c <main+0x1a>
      ;
    __sync_synchronize();
    80001062:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001066:	00001097          	auipc	ra,0x1
    8000106a:	ae4080e7          	jalr	-1308(ra) # 80001b4a <cpuid>
    8000106e:	85aa                	mv	a1,a0
    80001070:	00007517          	auipc	a0,0x7
    80001074:	08850513          	addi	a0,a0,136 # 800080f8 <digits+0xb8>
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	510080e7          	jalr	1296(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80001080:	00000097          	auipc	ra,0x0
    80001084:	0d8080e7          	jalr	216(ra) # 80001158 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001088:	00001097          	auipc	ra,0x1
    8000108c:	7de080e7          	jalr	2014(ra) # 80002866 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001090:	00005097          	auipc	ra,0x5
    80001094:	e50080e7          	jalr	-432(ra) # 80005ee0 <plicinithart>
  }

  scheduler();        
    80001098:	00001097          	auipc	ra,0x1
    8000109c:	fd4080e7          	jalr	-44(ra) # 8000206c <scheduler>
    consoleinit();
    800010a0:	fffff097          	auipc	ra,0xfffff
    800010a4:	3b0080e7          	jalr	944(ra) # 80000450 <consoleinit>
    printfinit();
    800010a8:	fffff097          	auipc	ra,0xfffff
    800010ac:	6c0080e7          	jalr	1728(ra) # 80000768 <printfinit>
    printf("\n");
    800010b0:	00007517          	auipc	a0,0x7
    800010b4:	ff850513          	addi	a0,a0,-8 # 800080a8 <digits+0x68>
    800010b8:	fffff097          	auipc	ra,0xfffff
    800010bc:	4d0080e7          	jalr	1232(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    800010c0:	00007517          	auipc	a0,0x7
    800010c4:	02050513          	addi	a0,a0,32 # 800080e0 <digits+0xa0>
    800010c8:	fffff097          	auipc	ra,0xfffff
    800010cc:	4c0080e7          	jalr	1216(ra) # 80000588 <printf>
    printf("\n");
    800010d0:	00007517          	auipc	a0,0x7
    800010d4:	fd850513          	addi	a0,a0,-40 # 800080a8 <digits+0x68>
    800010d8:	fffff097          	auipc	ra,0xfffff
    800010dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    800010e0:	00000097          	auipc	ra,0x0
    800010e4:	a84080e7          	jalr	-1404(ra) # 80000b64 <kinit>
    kvminit();       // create kernel page table
    800010e8:	00000097          	auipc	ra,0x0
    800010ec:	326080e7          	jalr	806(ra) # 8000140e <kvminit>
    kvminithart();   // turn on paging
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	068080e7          	jalr	104(ra) # 80001158 <kvminithart>
    procinit();      // process table
    800010f8:	00001097          	auipc	ra,0x1
    800010fc:	99e080e7          	jalr	-1634(ra) # 80001a96 <procinit>
    trapinit();      // trap vectors
    80001100:	00001097          	auipc	ra,0x1
    80001104:	73e080e7          	jalr	1854(ra) # 8000283e <trapinit>
    trapinithart();  // install kernel trap vector
    80001108:	00001097          	auipc	ra,0x1
    8000110c:	75e080e7          	jalr	1886(ra) # 80002866 <trapinithart>
    plicinit();      // set up interrupt controller
    80001110:	00005097          	auipc	ra,0x5
    80001114:	dba080e7          	jalr	-582(ra) # 80005eca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001118:	00005097          	auipc	ra,0x5
    8000111c:	dc8080e7          	jalr	-568(ra) # 80005ee0 <plicinithart>
    binit();         // buffer cache
    80001120:	00002097          	auipc	ra,0x2
    80001124:	f66080e7          	jalr	-154(ra) # 80003086 <binit>
    iinit();         // inode table
    80001128:	00002097          	auipc	ra,0x2
    8000112c:	60a080e7          	jalr	1546(ra) # 80003732 <iinit>
    fileinit();      // file table
    80001130:	00003097          	auipc	ra,0x3
    80001134:	5a8080e7          	jalr	1448(ra) # 800046d8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001138:	00005097          	auipc	ra,0x5
    8000113c:	eb0080e7          	jalr	-336(ra) # 80005fe8 <virtio_disk_init>
    userinit();      // first user process
    80001140:	00001097          	auipc	ra,0x1
    80001144:	d0e080e7          	jalr	-754(ra) # 80001e4e <userinit>
    __sync_synchronize();
    80001148:	0ff0000f          	fence
    started = 1;
    8000114c:	4785                	li	a5,1
    8000114e:	00008717          	auipc	a4,0x8
    80001152:	82f72523          	sw	a5,-2006(a4) # 80008978 <started>
    80001156:	b789                	j	80001098 <main+0x56>

0000000080001158 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e422                	sd	s0,8(sp)
    8000115c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000115e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001162:	00008797          	auipc	a5,0x8
    80001166:	81e7b783          	ld	a5,-2018(a5) # 80008980 <kernel_pagetable>
    8000116a:	83b1                	srli	a5,a5,0xc
    8000116c:	577d                	li	a4,-1
    8000116e:	177e                	slli	a4,a4,0x3f
    80001170:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001172:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001176:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000117a:	6422                	ld	s0,8(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret

0000000080001180 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001180:	7139                	addi	sp,sp,-64
    80001182:	fc06                	sd	ra,56(sp)
    80001184:	f822                	sd	s0,48(sp)
    80001186:	f426                	sd	s1,40(sp)
    80001188:	f04a                	sd	s2,32(sp)
    8000118a:	ec4e                	sd	s3,24(sp)
    8000118c:	e852                	sd	s4,16(sp)
    8000118e:	e456                	sd	s5,8(sp)
    80001190:	e05a                	sd	s6,0(sp)
    80001192:	0080                	addi	s0,sp,64
    80001194:	84aa                	mv	s1,a0
    80001196:	89ae                	mv	s3,a1
    80001198:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000119a:	57fd                	li	a5,-1
    8000119c:	83e9                	srli	a5,a5,0x1a
    8000119e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011a0:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011a2:	04b7f263          	bgeu	a5,a1,800011e6 <walk+0x66>
    panic("walk");
    800011a6:	00007517          	auipc	a0,0x7
    800011aa:	f6a50513          	addi	a0,a0,-150 # 80008110 <digits+0xd0>
    800011ae:	fffff097          	auipc	ra,0xfffff
    800011b2:	390080e7          	jalr	912(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011b6:	060a8663          	beqz	s5,80001222 <walk+0xa2>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	8f0080e7          	jalr	-1808(ra) # 80000aaa <kalloc>
    800011c2:	84aa                	mv	s1,a0
    800011c4:	c529                	beqz	a0,8000120e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011c6:	6605                	lui	a2,0x1
    800011c8:	4581                	li	a1,0
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	cd2080e7          	jalr	-814(ra) # 80000e9c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011d2:	00c4d793          	srli	a5,s1,0xc
    800011d6:	07aa                	slli	a5,a5,0xa
    800011d8:	0017e793          	ori	a5,a5,1
    800011dc:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011e0:	3a5d                	addiw	s4,s4,-9
    800011e2:	036a0063          	beq	s4,s6,80001202 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011e6:	0149d933          	srl	s2,s3,s4
    800011ea:	1ff97913          	andi	s2,s2,511
    800011ee:	090e                	slli	s2,s2,0x3
    800011f0:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011f2:	00093483          	ld	s1,0(s2)
    800011f6:	0014f793          	andi	a5,s1,1
    800011fa:	dfd5                	beqz	a5,800011b6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011fc:	80a9                	srli	s1,s1,0xa
    800011fe:	04b2                	slli	s1,s1,0xc
    80001200:	b7c5                	j	800011e0 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001202:	00c9d513          	srli	a0,s3,0xc
    80001206:	1ff57513          	andi	a0,a0,511
    8000120a:	050e                	slli	a0,a0,0x3
    8000120c:	9526                	add	a0,a0,s1
}
    8000120e:	70e2                	ld	ra,56(sp)
    80001210:	7442                	ld	s0,48(sp)
    80001212:	74a2                	ld	s1,40(sp)
    80001214:	7902                	ld	s2,32(sp)
    80001216:	69e2                	ld	s3,24(sp)
    80001218:	6a42                	ld	s4,16(sp)
    8000121a:	6aa2                	ld	s5,8(sp)
    8000121c:	6b02                	ld	s6,0(sp)
    8000121e:	6121                	addi	sp,sp,64
    80001220:	8082                	ret
        return 0;
    80001222:	4501                	li	a0,0
    80001224:	b7ed                	j	8000120e <walk+0x8e>

0000000080001226 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001226:	57fd                	li	a5,-1
    80001228:	83e9                	srli	a5,a5,0x1a
    8000122a:	00b7f463          	bgeu	a5,a1,80001232 <walkaddr+0xc>
    return 0;
    8000122e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001230:	8082                	ret
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e406                	sd	ra,8(sp)
    80001236:	e022                	sd	s0,0(sp)
    80001238:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000123a:	4601                	li	a2,0
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f44080e7          	jalr	-188(ra) # 80001180 <walk>
  if(pte == 0)
    80001244:	c105                	beqz	a0,80001264 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001246:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001248:	0117f693          	andi	a3,a5,17
    8000124c:	4745                	li	a4,17
    return 0;
    8000124e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001250:	00e68663          	beq	a3,a4,8000125c <walkaddr+0x36>
}
    80001254:	60a2                	ld	ra,8(sp)
    80001256:	6402                	ld	s0,0(sp)
    80001258:	0141                	addi	sp,sp,16
    8000125a:	8082                	ret
  pa = PTE2PA(*pte);
    8000125c:	00a7d513          	srli	a0,a5,0xa
    80001260:	0532                	slli	a0,a0,0xc
  return pa;
    80001262:	bfcd                	j	80001254 <walkaddr+0x2e>
    return 0;
    80001264:	4501                	li	a0,0
    80001266:	b7fd                	j	80001254 <walkaddr+0x2e>

0000000080001268 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001268:	715d                	addi	sp,sp,-80
    8000126a:	e486                	sd	ra,72(sp)
    8000126c:	e0a2                	sd	s0,64(sp)
    8000126e:	fc26                	sd	s1,56(sp)
    80001270:	f84a                	sd	s2,48(sp)
    80001272:	f44e                	sd	s3,40(sp)
    80001274:	f052                	sd	s4,32(sp)
    80001276:	ec56                	sd	s5,24(sp)
    80001278:	e85a                	sd	s6,16(sp)
    8000127a:	e45e                	sd	s7,8(sp)
    8000127c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000127e:	c639                	beqz	a2,800012cc <mappages+0x64>
    80001280:	8aaa                	mv	s5,a0
    80001282:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001284:	77fd                	lui	a5,0xfffff
    80001286:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000128a:	15fd                	addi	a1,a1,-1
    8000128c:	00c589b3          	add	s3,a1,a2
    80001290:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001294:	8952                	mv	s2,s4
    80001296:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000129a:	6b85                	lui	s7,0x1
    8000129c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012a0:	4605                	li	a2,1
    800012a2:	85ca                	mv	a1,s2
    800012a4:	8556                	mv	a0,s5
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	eda080e7          	jalr	-294(ra) # 80001180 <walk>
    800012ae:	cd1d                	beqz	a0,800012ec <mappages+0x84>
    if(*pte & PTE_V)
    800012b0:	611c                	ld	a5,0(a0)
    800012b2:	8b85                	andi	a5,a5,1
    800012b4:	e785                	bnez	a5,800012dc <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012b6:	80b1                	srli	s1,s1,0xc
    800012b8:	04aa                	slli	s1,s1,0xa
    800012ba:	0164e4b3          	or	s1,s1,s6
    800012be:	0014e493          	ori	s1,s1,1
    800012c2:	e104                	sd	s1,0(a0)
    if(a == last)
    800012c4:	05390063          	beq	s2,s3,80001304 <mappages+0x9c>
    a += PGSIZE;
    800012c8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012ca:	bfc9                	j	8000129c <mappages+0x34>
    panic("mappages: size");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("mappages: remap");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      return -1;
    800012ec:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012ee:	60a6                	ld	ra,72(sp)
    800012f0:	6406                	ld	s0,64(sp)
    800012f2:	74e2                	ld	s1,56(sp)
    800012f4:	7942                	ld	s2,48(sp)
    800012f6:	79a2                	ld	s3,40(sp)
    800012f8:	7a02                	ld	s4,32(sp)
    800012fa:	6ae2                	ld	s5,24(sp)
    800012fc:	6b42                	ld	s6,16(sp)
    800012fe:	6ba2                	ld	s7,8(sp)
    80001300:	6161                	addi	sp,sp,80
    80001302:	8082                	ret
  return 0;
    80001304:	4501                	li	a0,0
    80001306:	b7e5                	j	800012ee <mappages+0x86>

0000000080001308 <kvmmap>:
{
    80001308:	1141                	addi	sp,sp,-16
    8000130a:	e406                	sd	ra,8(sp)
    8000130c:	e022                	sd	s0,0(sp)
    8000130e:	0800                	addi	s0,sp,16
    80001310:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001312:	86b2                	mv	a3,a2
    80001314:	863e                	mv	a2,a5
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f52080e7          	jalr	-174(ra) # 80001268 <mappages>
    8000131e:	e509                	bnez	a0,80001328 <kvmmap+0x20>
}
    80001320:	60a2                	ld	ra,8(sp)
    80001322:	6402                	ld	s0,0(sp)
    80001324:	0141                	addi	sp,sp,16
    80001326:	8082                	ret
    panic("kvmmap");
    80001328:	00007517          	auipc	a0,0x7
    8000132c:	e1050513          	addi	a0,a0,-496 # 80008138 <digits+0xf8>
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	20e080e7          	jalr	526(ra) # 8000053e <panic>

0000000080001338 <kvmmake>:
{
    80001338:	1101                	addi	sp,sp,-32
    8000133a:	ec06                	sd	ra,24(sp)
    8000133c:	e822                	sd	s0,16(sp)
    8000133e:	e426                	sd	s1,8(sp)
    80001340:	e04a                	sd	s2,0(sp)
    80001342:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	766080e7          	jalr	1894(ra) # 80000aaa <kalloc>
    8000134c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000134e:	6605                	lui	a2,0x1
    80001350:	4581                	li	a1,0
    80001352:	00000097          	auipc	ra,0x0
    80001356:	b4a080e7          	jalr	-1206(ra) # 80000e9c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000135a:	4719                	li	a4,6
    8000135c:	6685                	lui	a3,0x1
    8000135e:	10000637          	lui	a2,0x10000
    80001362:	100005b7          	lui	a1,0x10000
    80001366:	8526                	mv	a0,s1
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	fa0080e7          	jalr	-96(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001370:	4719                	li	a4,6
    80001372:	6685                	lui	a3,0x1
    80001374:	10001637          	lui	a2,0x10001
    80001378:	100015b7          	lui	a1,0x10001
    8000137c:	8526                	mv	a0,s1
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	f8a080e7          	jalr	-118(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001386:	4719                	li	a4,6
    80001388:	004006b7          	lui	a3,0x400
    8000138c:	0c000637          	lui	a2,0xc000
    80001390:	0c0005b7          	lui	a1,0xc000
    80001394:	8526                	mv	a0,s1
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	f72080e7          	jalr	-142(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000139e:	00007917          	auipc	s2,0x7
    800013a2:	c6290913          	addi	s2,s2,-926 # 80008000 <etext>
    800013a6:	4729                	li	a4,10
    800013a8:	80007697          	auipc	a3,0x80007
    800013ac:	c5868693          	addi	a3,a3,-936 # 8000 <_entry-0x7fff8000>
    800013b0:	4605                	li	a2,1
    800013b2:	067e                	slli	a2,a2,0x1f
    800013b4:	85b2                	mv	a1,a2
    800013b6:	8526                	mv	a0,s1
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	f50080e7          	jalr	-176(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013c0:	4719                	li	a4,6
    800013c2:	46c5                	li	a3,17
    800013c4:	06ee                	slli	a3,a3,0x1b
    800013c6:	412686b3          	sub	a3,a3,s2
    800013ca:	864a                	mv	a2,s2
    800013cc:	85ca                	mv	a1,s2
    800013ce:	8526                	mv	a0,s1
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	f38080e7          	jalr	-200(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013d8:	4729                	li	a4,10
    800013da:	6685                	lui	a3,0x1
    800013dc:	00006617          	auipc	a2,0x6
    800013e0:	c2460613          	addi	a2,a2,-988 # 80007000 <_trampoline>
    800013e4:	040005b7          	lui	a1,0x4000
    800013e8:	15fd                	addi	a1,a1,-1
    800013ea:	05b2                	slli	a1,a1,0xc
    800013ec:	8526                	mv	a0,s1
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	f1a080e7          	jalr	-230(ra) # 80001308 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013f6:	8526                	mv	a0,s1
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	608080e7          	jalr	1544(ra) # 80001a00 <proc_mapstacks>
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6902                	ld	s2,0(sp)
    8000140a:	6105                	addi	sp,sp,32
    8000140c:	8082                	ret

000000008000140e <kvminit>:
{
    8000140e:	1141                	addi	sp,sp,-16
    80001410:	e406                	sd	ra,8(sp)
    80001412:	e022                	sd	s0,0(sp)
    80001414:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	f22080e7          	jalr	-222(ra) # 80001338 <kvmmake>
    8000141e:	00007797          	auipc	a5,0x7
    80001422:	56a7b123          	sd	a0,1378(a5) # 80008980 <kernel_pagetable>
}
    80001426:	60a2                	ld	ra,8(sp)
    80001428:	6402                	ld	s0,0(sp)
    8000142a:	0141                	addi	sp,sp,16
    8000142c:	8082                	ret

000000008000142e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000142e:	715d                	addi	sp,sp,-80
    80001430:	e486                	sd	ra,72(sp)
    80001432:	e0a2                	sd	s0,64(sp)
    80001434:	fc26                	sd	s1,56(sp)
    80001436:	f84a                	sd	s2,48(sp)
    80001438:	f44e                	sd	s3,40(sp)
    8000143a:	f052                	sd	s4,32(sp)
    8000143c:	ec56                	sd	s5,24(sp)
    8000143e:	e85a                	sd	s6,16(sp)
    80001440:	e45e                	sd	s7,8(sp)
    80001442:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001444:	03459793          	slli	a5,a1,0x34
    80001448:	e795                	bnez	a5,80001474 <uvmunmap+0x46>
    8000144a:	8a2a                	mv	s4,a0
    8000144c:	892e                	mv	s2,a1
    8000144e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001450:	0632                	slli	a2,a2,0xc
    80001452:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001456:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001458:	6b05                	lui	s6,0x1
    8000145a:	0735e263          	bltu	a1,s3,800014be <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000145e:	60a6                	ld	ra,72(sp)
    80001460:	6406                	ld	s0,64(sp)
    80001462:	74e2                	ld	s1,56(sp)
    80001464:	7942                	ld	s2,48(sp)
    80001466:	79a2                	ld	s3,40(sp)
    80001468:	7a02                	ld	s4,32(sp)
    8000146a:	6ae2                	ld	s5,24(sp)
    8000146c:	6b42                	ld	s6,16(sp)
    8000146e:	6ba2                	ld	s7,8(sp)
    80001470:	6161                	addi	sp,sp,80
    80001472:	8082                	ret
    panic("uvmunmap: not aligned");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	ccc50513          	addi	a0,a0,-820 # 80008140 <digits+0x100>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0c2080e7          	jalr	194(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001484:	00007517          	auipc	a0,0x7
    80001488:	cd450513          	addi	a0,a0,-812 # 80008158 <digits+0x118>
    8000148c:	fffff097          	auipc	ra,0xfffff
    80001490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001494:	00007517          	auipc	a0,0x7
    80001498:	cd450513          	addi	a0,a0,-812 # 80008168 <digits+0x128>
    8000149c:	fffff097          	auipc	ra,0xfffff
    800014a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800014a4:	00007517          	auipc	a0,0x7
    800014a8:	cdc50513          	addi	a0,a0,-804 # 80008180 <digits+0x140>
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
    *pte = 0;
    800014b4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014b8:	995a                	add	s2,s2,s6
    800014ba:	fb3972e3          	bgeu	s2,s3,8000145e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014be:	4601                	li	a2,0
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8552                	mv	a0,s4
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	cbc080e7          	jalr	-836(ra) # 80001180 <walk>
    800014cc:	84aa                	mv	s1,a0
    800014ce:	d95d                	beqz	a0,80001484 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014d0:	6108                	ld	a0,0(a0)
    800014d2:	00157793          	andi	a5,a0,1
    800014d6:	dfdd                	beqz	a5,80001494 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014d8:	3ff57793          	andi	a5,a0,1023
    800014dc:	fd7784e3          	beq	a5,s7,800014a4 <uvmunmap+0x76>
    if(do_free){
    800014e0:	fc0a8ae3          	beqz	s5,800014b4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014e4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014e6:	0532                	slli	a0,a0,0xc
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	502080e7          	jalr	1282(ra) # 800009ea <kfree>
    800014f0:	b7d1                	j	800014b4 <uvmunmap+0x86>

00000000800014f2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014f2:	1101                	addi	sp,sp,-32
    800014f4:	ec06                	sd	ra,24(sp)
    800014f6:	e822                	sd	s0,16(sp)
    800014f8:	e426                	sd	s1,8(sp)
    800014fa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014fc:	fffff097          	auipc	ra,0xfffff
    80001500:	5ae080e7          	jalr	1454(ra) # 80000aaa <kalloc>
    80001504:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001506:	c519                	beqz	a0,80001514 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001508:	6605                	lui	a2,0x1
    8000150a:	4581                	li	a1,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	990080e7          	jalr	-1648(ra) # 80000e9c <memset>
  return pagetable;
}
    80001514:	8526                	mv	a0,s1
    80001516:	60e2                	ld	ra,24(sp)
    80001518:	6442                	ld	s0,16(sp)
    8000151a:	64a2                	ld	s1,8(sp)
    8000151c:	6105                	addi	sp,sp,32
    8000151e:	8082                	ret

0000000080001520 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001520:	7179                	addi	sp,sp,-48
    80001522:	f406                	sd	ra,40(sp)
    80001524:	f022                	sd	s0,32(sp)
    80001526:	ec26                	sd	s1,24(sp)
    80001528:	e84a                	sd	s2,16(sp)
    8000152a:	e44e                	sd	s3,8(sp)
    8000152c:	e052                	sd	s4,0(sp)
    8000152e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001530:	6785                	lui	a5,0x1
    80001532:	04f67863          	bgeu	a2,a5,80001582 <uvmfirst+0x62>
    80001536:	8a2a                	mv	s4,a0
    80001538:	89ae                	mv	s3,a1
    8000153a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000153c:	fffff097          	auipc	ra,0xfffff
    80001540:	56e080e7          	jalr	1390(ra) # 80000aaa <kalloc>
    80001544:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001546:	6605                	lui	a2,0x1
    80001548:	4581                	li	a1,0
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	952080e7          	jalr	-1710(ra) # 80000e9c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001552:	4779                	li	a4,30
    80001554:	86ca                	mv	a3,s2
    80001556:	6605                	lui	a2,0x1
    80001558:	4581                	li	a1,0
    8000155a:	8552                	mv	a0,s4
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	d0c080e7          	jalr	-756(ra) # 80001268 <mappages>
  memmove(mem, src, sz);
    80001564:	8626                	mv	a2,s1
    80001566:	85ce                	mv	a1,s3
    80001568:	854a                	mv	a0,s2
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	98e080e7          	jalr	-1650(ra) # 80000ef8 <memmove>
}
    80001572:	70a2                	ld	ra,40(sp)
    80001574:	7402                	ld	s0,32(sp)
    80001576:	64e2                	ld	s1,24(sp)
    80001578:	6942                	ld	s2,16(sp)
    8000157a:	69a2                	ld	s3,8(sp)
    8000157c:	6a02                	ld	s4,0(sp)
    8000157e:	6145                	addi	sp,sp,48
    80001580:	8082                	ret
    panic("uvmfirst: more than a page");
    80001582:	00007517          	auipc	a0,0x7
    80001586:	c1650513          	addi	a0,a0,-1002 # 80008198 <digits+0x158>
    8000158a:	fffff097          	auipc	ra,0xfffff
    8000158e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>

0000000080001592 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001592:	1101                	addi	sp,sp,-32
    80001594:	ec06                	sd	ra,24(sp)
    80001596:	e822                	sd	s0,16(sp)
    80001598:	e426                	sd	s1,8(sp)
    8000159a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000159c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000159e:	00b67d63          	bgeu	a2,a1,800015b8 <uvmdealloc+0x26>
    800015a2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015a4:	6785                	lui	a5,0x1
    800015a6:	17fd                	addi	a5,a5,-1
    800015a8:	00f60733          	add	a4,a2,a5
    800015ac:	767d                	lui	a2,0xfffff
    800015ae:	8f71                	and	a4,a4,a2
    800015b0:	97ae                	add	a5,a5,a1
    800015b2:	8ff1                	and	a5,a5,a2
    800015b4:	00f76863          	bltu	a4,a5,800015c4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015b8:	8526                	mv	a0,s1
    800015ba:	60e2                	ld	ra,24(sp)
    800015bc:	6442                	ld	s0,16(sp)
    800015be:	64a2                	ld	s1,8(sp)
    800015c0:	6105                	addi	sp,sp,32
    800015c2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015c4:	8f99                	sub	a5,a5,a4
    800015c6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015c8:	4685                	li	a3,1
    800015ca:	0007861b          	sext.w	a2,a5
    800015ce:	85ba                	mv	a1,a4
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	e5e080e7          	jalr	-418(ra) # 8000142e <uvmunmap>
    800015d8:	b7c5                	j	800015b8 <uvmdealloc+0x26>

00000000800015da <uvmalloc>:
  if(newsz < oldsz)
    800015da:	0ab66563          	bltu	a2,a1,80001684 <uvmalloc+0xaa>
{
    800015de:	7139                	addi	sp,sp,-64
    800015e0:	fc06                	sd	ra,56(sp)
    800015e2:	f822                	sd	s0,48(sp)
    800015e4:	f426                	sd	s1,40(sp)
    800015e6:	f04a                	sd	s2,32(sp)
    800015e8:	ec4e                	sd	s3,24(sp)
    800015ea:	e852                	sd	s4,16(sp)
    800015ec:	e456                	sd	s5,8(sp)
    800015ee:	e05a                	sd	s6,0(sp)
    800015f0:	0080                	addi	s0,sp,64
    800015f2:	8aaa                	mv	s5,a0
    800015f4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015f6:	6985                	lui	s3,0x1
    800015f8:	19fd                	addi	s3,s3,-1
    800015fa:	95ce                	add	a1,a1,s3
    800015fc:	79fd                	lui	s3,0xfffff
    800015fe:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001602:	08c9f363          	bgeu	s3,a2,80001688 <uvmalloc+0xae>
    80001606:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001608:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	49e080e7          	jalr	1182(ra) # 80000aaa <kalloc>
    80001614:	84aa                	mv	s1,a0
    if(mem == 0){
    80001616:	c51d                	beqz	a0,80001644 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001618:	6605                	lui	a2,0x1
    8000161a:	4581                	li	a1,0
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	880080e7          	jalr	-1920(ra) # 80000e9c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001624:	875a                	mv	a4,s6
    80001626:	86a6                	mv	a3,s1
    80001628:	6605                	lui	a2,0x1
    8000162a:	85ca                	mv	a1,s2
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c3a080e7          	jalr	-966(ra) # 80001268 <mappages>
    80001636:	e90d                	bnez	a0,80001668 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001638:	6785                	lui	a5,0x1
    8000163a:	993e                	add	s2,s2,a5
    8000163c:	fd4968e3          	bltu	s2,s4,8000160c <uvmalloc+0x32>
  return newsz;
    80001640:	8552                	mv	a0,s4
    80001642:	a809                	j	80001654 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001644:	864e                	mv	a2,s3
    80001646:	85ca                	mv	a1,s2
    80001648:	8556                	mv	a0,s5
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	f48080e7          	jalr	-184(ra) # 80001592 <uvmdealloc>
      return 0;
    80001652:	4501                	li	a0,0
}
    80001654:	70e2                	ld	ra,56(sp)
    80001656:	7442                	ld	s0,48(sp)
    80001658:	74a2                	ld	s1,40(sp)
    8000165a:	7902                	ld	s2,32(sp)
    8000165c:	69e2                	ld	s3,24(sp)
    8000165e:	6a42                	ld	s4,16(sp)
    80001660:	6aa2                	ld	s5,8(sp)
    80001662:	6b02                	ld	s6,0(sp)
    80001664:	6121                	addi	sp,sp,64
    80001666:	8082                	ret
      kfree(mem);
    80001668:	8526                	mv	a0,s1
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	380080e7          	jalr	896(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001672:	864e                	mv	a2,s3
    80001674:	85ca                	mv	a1,s2
    80001676:	8556                	mv	a0,s5
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	f1a080e7          	jalr	-230(ra) # 80001592 <uvmdealloc>
      return 0;
    80001680:	4501                	li	a0,0
    80001682:	bfc9                	j	80001654 <uvmalloc+0x7a>
    return oldsz;
    80001684:	852e                	mv	a0,a1
}
    80001686:	8082                	ret
  return newsz;
    80001688:	8532                	mv	a0,a2
    8000168a:	b7e9                	j	80001654 <uvmalloc+0x7a>

000000008000168c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000168c:	7179                	addi	sp,sp,-48
    8000168e:	f406                	sd	ra,40(sp)
    80001690:	f022                	sd	s0,32(sp)
    80001692:	ec26                	sd	s1,24(sp)
    80001694:	e84a                	sd	s2,16(sp)
    80001696:	e44e                	sd	s3,8(sp)
    80001698:	e052                	sd	s4,0(sp)
    8000169a:	1800                	addi	s0,sp,48
    8000169c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000169e:	84aa                	mv	s1,a0
    800016a0:	6905                	lui	s2,0x1
    800016a2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016a4:	4985                	li	s3,1
    800016a6:	a821                	j	800016be <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016a8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016aa:	0532                	slli	a0,a0,0xc
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	fe0080e7          	jalr	-32(ra) # 8000168c <freewalk>
      pagetable[i] = 0;
    800016b4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016b8:	04a1                	addi	s1,s1,8
    800016ba:	03248163          	beq	s1,s2,800016dc <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016be:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016c0:	00f57793          	andi	a5,a0,15
    800016c4:	ff3782e3          	beq	a5,s3,800016a8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016c8:	8905                	andi	a0,a0,1
    800016ca:	d57d                	beqz	a0,800016b8 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016cc:	00007517          	auipc	a0,0x7
    800016d0:	aec50513          	addi	a0,a0,-1300 # 800081b8 <digits+0x178>
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800016dc:	8552                	mv	a0,s4
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	30c080e7          	jalr	780(ra) # 800009ea <kfree>
}
    800016e6:	70a2                	ld	ra,40(sp)
    800016e8:	7402                	ld	s0,32(sp)
    800016ea:	64e2                	ld	s1,24(sp)
    800016ec:	6942                	ld	s2,16(sp)
    800016ee:	69a2                	ld	s3,8(sp)
    800016f0:	6a02                	ld	s4,0(sp)
    800016f2:	6145                	addi	sp,sp,48
    800016f4:	8082                	ret

00000000800016f6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016f6:	1101                	addi	sp,sp,-32
    800016f8:	ec06                	sd	ra,24(sp)
    800016fa:	e822                	sd	s0,16(sp)
    800016fc:	e426                	sd	s1,8(sp)
    800016fe:	1000                	addi	s0,sp,32
    80001700:	84aa                	mv	s1,a0
  if(sz > 0)
    80001702:	e999                	bnez	a1,80001718 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001704:	8526                	mv	a0,s1
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	f86080e7          	jalr	-122(ra) # 8000168c <freewalk>
}
    8000170e:	60e2                	ld	ra,24(sp)
    80001710:	6442                	ld	s0,16(sp)
    80001712:	64a2                	ld	s1,8(sp)
    80001714:	6105                	addi	sp,sp,32
    80001716:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001718:	6605                	lui	a2,0x1
    8000171a:	167d                	addi	a2,a2,-1
    8000171c:	962e                	add	a2,a2,a1
    8000171e:	4685                	li	a3,1
    80001720:	8231                	srli	a2,a2,0xc
    80001722:	4581                	li	a1,0
    80001724:	00000097          	auipc	ra,0x0
    80001728:	d0a080e7          	jalr	-758(ra) # 8000142e <uvmunmap>
    8000172c:	bfe1                	j	80001704 <uvmfree+0xe>

000000008000172e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000172e:	c679                	beqz	a2,800017fc <uvmcopy+0xce>
{
    80001730:	715d                	addi	sp,sp,-80
    80001732:	e486                	sd	ra,72(sp)
    80001734:	e0a2                	sd	s0,64(sp)
    80001736:	fc26                	sd	s1,56(sp)
    80001738:	f84a                	sd	s2,48(sp)
    8000173a:	f44e                	sd	s3,40(sp)
    8000173c:	f052                	sd	s4,32(sp)
    8000173e:	ec56                	sd	s5,24(sp)
    80001740:	e85a                	sd	s6,16(sp)
    80001742:	e45e                	sd	s7,8(sp)
    80001744:	0880                	addi	s0,sp,80
    80001746:	8b2a                	mv	s6,a0
    80001748:	8aae                	mv	s5,a1
    8000174a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000174c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000174e:	4601                	li	a2,0
    80001750:	85ce                	mv	a1,s3
    80001752:	855a                	mv	a0,s6
    80001754:	00000097          	auipc	ra,0x0
    80001758:	a2c080e7          	jalr	-1492(ra) # 80001180 <walk>
    8000175c:	c531                	beqz	a0,800017a8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000175e:	6118                	ld	a4,0(a0)
    80001760:	00177793          	andi	a5,a4,1
    80001764:	cbb1                	beqz	a5,800017b8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001766:	00a75593          	srli	a1,a4,0xa
    8000176a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000176e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001772:	fffff097          	auipc	ra,0xfffff
    80001776:	338080e7          	jalr	824(ra) # 80000aaa <kalloc>
    8000177a:	892a                	mv	s2,a0
    8000177c:	c939                	beqz	a0,800017d2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000177e:	6605                	lui	a2,0x1
    80001780:	85de                	mv	a1,s7
    80001782:	fffff097          	auipc	ra,0xfffff
    80001786:	776080e7          	jalr	1910(ra) # 80000ef8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000178a:	8726                	mv	a4,s1
    8000178c:	86ca                	mv	a3,s2
    8000178e:	6605                	lui	a2,0x1
    80001790:	85ce                	mv	a1,s3
    80001792:	8556                	mv	a0,s5
    80001794:	00000097          	auipc	ra,0x0
    80001798:	ad4080e7          	jalr	-1324(ra) # 80001268 <mappages>
    8000179c:	e515                	bnez	a0,800017c8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000179e:	6785                	lui	a5,0x1
    800017a0:	99be                	add	s3,s3,a5
    800017a2:	fb49e6e3          	bltu	s3,s4,8000174e <uvmcopy+0x20>
    800017a6:	a081                	j	800017e6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800017a8:	00007517          	auipc	a0,0x7
    800017ac:	a2050513          	addi	a0,a0,-1504 # 800081c8 <digits+0x188>
    800017b0:	fffff097          	auipc	ra,0xfffff
    800017b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800017b8:	00007517          	auipc	a0,0x7
    800017bc:	a3050513          	addi	a0,a0,-1488 # 800081e8 <digits+0x1a8>
    800017c0:	fffff097          	auipc	ra,0xfffff
    800017c4:	d7e080e7          	jalr	-642(ra) # 8000053e <panic>
      kfree(mem);
    800017c8:	854a                	mv	a0,s2
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	220080e7          	jalr	544(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017d2:	4685                	li	a3,1
    800017d4:	00c9d613          	srli	a2,s3,0xc
    800017d8:	4581                	li	a1,0
    800017da:	8556                	mv	a0,s5
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	c52080e7          	jalr	-942(ra) # 8000142e <uvmunmap>
  return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret
  return 0;
    800017fc:	4501                	li	a0,0
}
    800017fe:	8082                	ret

0000000080001800 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001800:	1141                	addi	sp,sp,-16
    80001802:	e406                	sd	ra,8(sp)
    80001804:	e022                	sd	s0,0(sp)
    80001806:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001808:	4601                	li	a2,0
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	976080e7          	jalr	-1674(ra) # 80001180 <walk>
  if(pte == 0)
    80001812:	c901                	beqz	a0,80001822 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001814:	611c                	ld	a5,0(a0)
    80001816:	9bbd                	andi	a5,a5,-17
    80001818:	e11c                	sd	a5,0(a0)
}
    8000181a:	60a2                	ld	ra,8(sp)
    8000181c:	6402                	ld	s0,0(sp)
    8000181e:	0141                	addi	sp,sp,16
    80001820:	8082                	ret
    panic("uvmclear");
    80001822:	00007517          	auipc	a0,0x7
    80001826:	9e650513          	addi	a0,a0,-1562 # 80008208 <digits+0x1c8>
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080001832 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001832:	c6bd                	beqz	a3,800018a0 <copyout+0x6e>
{
    80001834:	715d                	addi	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	e062                	sd	s8,0(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8b2a                	mv	s6,a0
    8000184e:	8c2e                	mv	s8,a1
    80001850:	8a32                	mv	s4,a2
    80001852:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001854:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001856:	6a85                	lui	s5,0x1
    80001858:	a015                	j	8000187c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000185a:	9562                	add	a0,a0,s8
    8000185c:	0004861b          	sext.w	a2,s1
    80001860:	85d2                	mv	a1,s4
    80001862:	41250533          	sub	a0,a0,s2
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	692080e7          	jalr	1682(ra) # 80000ef8 <memmove>

    len -= n;
    8000186e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001872:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001874:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001878:	02098263          	beqz	s3,8000189c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000187c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001880:	85ca                	mv	a1,s2
    80001882:	855a                	mv	a0,s6
    80001884:	00000097          	auipc	ra,0x0
    80001888:	9a2080e7          	jalr	-1630(ra) # 80001226 <walkaddr>
    if(pa0 == 0)
    8000188c:	cd01                	beqz	a0,800018a4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000188e:	418904b3          	sub	s1,s2,s8
    80001892:	94d6                	add	s1,s1,s5
    if(n > len)
    80001894:	fc99f3e3          	bgeu	s3,s1,8000185a <copyout+0x28>
    80001898:	84ce                	mv	s1,s3
    8000189a:	b7c1                	j	8000185a <copyout+0x28>
  }
  return 0;
    8000189c:	4501                	li	a0,0
    8000189e:	a021                	j	800018a6 <copyout+0x74>
    800018a0:	4501                	li	a0,0
}
    800018a2:	8082                	ret
      return -1;
    800018a4:	557d                	li	a0,-1
}
    800018a6:	60a6                	ld	ra,72(sp)
    800018a8:	6406                	ld	s0,64(sp)
    800018aa:	74e2                	ld	s1,56(sp)
    800018ac:	7942                	ld	s2,48(sp)
    800018ae:	79a2                	ld	s3,40(sp)
    800018b0:	7a02                	ld	s4,32(sp)
    800018b2:	6ae2                	ld	s5,24(sp)
    800018b4:	6b42                	ld	s6,16(sp)
    800018b6:	6ba2                	ld	s7,8(sp)
    800018b8:	6c02                	ld	s8,0(sp)
    800018ba:	6161                	addi	sp,sp,80
    800018bc:	8082                	ret

00000000800018be <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018be:	caa5                	beqz	a3,8000192e <copyin+0x70>
{
    800018c0:	715d                	addi	sp,sp,-80
    800018c2:	e486                	sd	ra,72(sp)
    800018c4:	e0a2                	sd	s0,64(sp)
    800018c6:	fc26                	sd	s1,56(sp)
    800018c8:	f84a                	sd	s2,48(sp)
    800018ca:	f44e                	sd	s3,40(sp)
    800018cc:	f052                	sd	s4,32(sp)
    800018ce:	ec56                	sd	s5,24(sp)
    800018d0:	e85a                	sd	s6,16(sp)
    800018d2:	e45e                	sd	s7,8(sp)
    800018d4:	e062                	sd	s8,0(sp)
    800018d6:	0880                	addi	s0,sp,80
    800018d8:	8b2a                	mv	s6,a0
    800018da:	8a2e                	mv	s4,a1
    800018dc:	8c32                	mv	s8,a2
    800018de:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018e0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e2:	6a85                	lui	s5,0x1
    800018e4:	a01d                	j	8000190a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018e6:	018505b3          	add	a1,a0,s8
    800018ea:	0004861b          	sext.w	a2,s1
    800018ee:	412585b3          	sub	a1,a1,s2
    800018f2:	8552                	mv	a0,s4
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	604080e7          	jalr	1540(ra) # 80000ef8 <memmove>

    len -= n;
    800018fc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001900:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001902:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001906:	02098263          	beqz	s3,8000192a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000190a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000190e:	85ca                	mv	a1,s2
    80001910:	855a                	mv	a0,s6
    80001912:	00000097          	auipc	ra,0x0
    80001916:	914080e7          	jalr	-1772(ra) # 80001226 <walkaddr>
    if(pa0 == 0)
    8000191a:	cd01                	beqz	a0,80001932 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000191c:	418904b3          	sub	s1,s2,s8
    80001920:	94d6                	add	s1,s1,s5
    if(n > len)
    80001922:	fc99f2e3          	bgeu	s3,s1,800018e6 <copyin+0x28>
    80001926:	84ce                	mv	s1,s3
    80001928:	bf7d                	j	800018e6 <copyin+0x28>
  }
  return 0;
    8000192a:	4501                	li	a0,0
    8000192c:	a021                	j	80001934 <copyin+0x76>
    8000192e:	4501                	li	a0,0
}
    80001930:	8082                	ret
      return -1;
    80001932:	557d                	li	a0,-1
}
    80001934:	60a6                	ld	ra,72(sp)
    80001936:	6406                	ld	s0,64(sp)
    80001938:	74e2                	ld	s1,56(sp)
    8000193a:	7942                	ld	s2,48(sp)
    8000193c:	79a2                	ld	s3,40(sp)
    8000193e:	7a02                	ld	s4,32(sp)
    80001940:	6ae2                	ld	s5,24(sp)
    80001942:	6b42                	ld	s6,16(sp)
    80001944:	6ba2                	ld	s7,8(sp)
    80001946:	6c02                	ld	s8,0(sp)
    80001948:	6161                	addi	sp,sp,80
    8000194a:	8082                	ret

000000008000194c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000194c:	c6c5                	beqz	a3,800019f4 <copyinstr+0xa8>
{
    8000194e:	715d                	addi	sp,sp,-80
    80001950:	e486                	sd	ra,72(sp)
    80001952:	e0a2                	sd	s0,64(sp)
    80001954:	fc26                	sd	s1,56(sp)
    80001956:	f84a                	sd	s2,48(sp)
    80001958:	f44e                	sd	s3,40(sp)
    8000195a:	f052                	sd	s4,32(sp)
    8000195c:	ec56                	sd	s5,24(sp)
    8000195e:	e85a                	sd	s6,16(sp)
    80001960:	e45e                	sd	s7,8(sp)
    80001962:	0880                	addi	s0,sp,80
    80001964:	8a2a                	mv	s4,a0
    80001966:	8b2e                	mv	s6,a1
    80001968:	8bb2                	mv	s7,a2
    8000196a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000196c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000196e:	6985                	lui	s3,0x1
    80001970:	a035                	j	8000199c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001972:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001976:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001978:	0017b793          	seqz	a5,a5
    8000197c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001980:	60a6                	ld	ra,72(sp)
    80001982:	6406                	ld	s0,64(sp)
    80001984:	74e2                	ld	s1,56(sp)
    80001986:	7942                	ld	s2,48(sp)
    80001988:	79a2                	ld	s3,40(sp)
    8000198a:	7a02                	ld	s4,32(sp)
    8000198c:	6ae2                	ld	s5,24(sp)
    8000198e:	6b42                	ld	s6,16(sp)
    80001990:	6ba2                	ld	s7,8(sp)
    80001992:	6161                	addi	sp,sp,80
    80001994:	8082                	ret
    srcva = va0 + PGSIZE;
    80001996:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000199a:	c8a9                	beqz	s1,800019ec <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000199c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019a0:	85ca                	mv	a1,s2
    800019a2:	8552                	mv	a0,s4
    800019a4:	00000097          	auipc	ra,0x0
    800019a8:	882080e7          	jalr	-1918(ra) # 80001226 <walkaddr>
    if(pa0 == 0)
    800019ac:	c131                	beqz	a0,800019f0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019ae:	41790833          	sub	a6,s2,s7
    800019b2:	984e                	add	a6,a6,s3
    if(n > max)
    800019b4:	0104f363          	bgeu	s1,a6,800019ba <copyinstr+0x6e>
    800019b8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019ba:	955e                	add	a0,a0,s7
    800019bc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019c0:	fc080be3          	beqz	a6,80001996 <copyinstr+0x4a>
    800019c4:	985a                	add	a6,a6,s6
    800019c6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019c8:	41650633          	sub	a2,a0,s6
    800019cc:	14fd                	addi	s1,s1,-1
    800019ce:	9b26                	add	s6,s6,s1
    800019d0:	00f60733          	add	a4,a2,a5
    800019d4:	00074703          	lbu	a4,0(a4)
    800019d8:	df49                	beqz	a4,80001972 <copyinstr+0x26>
        *dst = *p;
    800019da:	00e78023          	sb	a4,0(a5)
      --max;
    800019de:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019e2:	0785                	addi	a5,a5,1
    while(n > 0){
    800019e4:	ff0796e3          	bne	a5,a6,800019d0 <copyinstr+0x84>
      dst++;
    800019e8:	8b42                	mv	s6,a6
    800019ea:	b775                	j	80001996 <copyinstr+0x4a>
    800019ec:	4781                	li	a5,0
    800019ee:	b769                	j	80001978 <copyinstr+0x2c>
      return -1;
    800019f0:	557d                	li	a0,-1
    800019f2:	b779                	j	80001980 <copyinstr+0x34>
  int got_null = 0;
    800019f4:	4781                	li	a5,0
  if(got_null){
    800019f6:	0017b793          	seqz	a5,a5
    800019fa:	40f00533          	neg	a0,a5
}
    800019fe:	8082                	ret

0000000080001a00 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a00:	7139                	addi	sp,sp,-64
    80001a02:	fc06                	sd	ra,56(sp)
    80001a04:	f822                	sd	s0,48(sp)
    80001a06:	f426                	sd	s1,40(sp)
    80001a08:	f04a                	sd	s2,32(sp)
    80001a0a:	ec4e                	sd	s3,24(sp)
    80001a0c:	e852                	sd	s4,16(sp)
    80001a0e:	e456                	sd	s5,8(sp)
    80001a10:	e05a                	sd	s6,0(sp)
    80001a12:	0080                	addi	s0,sp,64
    80001a14:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a16:	0000f497          	auipc	s1,0xf
    80001a1a:	63a48493          	addi	s1,s1,1594 # 80011050 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a1e:	8b26                	mv	s6,s1
    80001a20:	00006a97          	auipc	s5,0x6
    80001a24:	5e0a8a93          	addi	s5,s5,1504 # 80008000 <etext>
    80001a28:	04000937          	lui	s2,0x4000
    80001a2c:	197d                	addi	s2,s2,-1
    80001a2e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a30:	00015a17          	auipc	s4,0x15
    80001a34:	020a0a13          	addi	s4,s4,32 # 80016a50 <tickslock>
    char *pa = kalloc();
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	072080e7          	jalr	114(ra) # 80000aaa <kalloc>
    80001a40:	862a                	mv	a2,a0
    if(pa == 0)
    80001a42:	c131                	beqz	a0,80001a86 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a44:	416485b3          	sub	a1,s1,s6
    80001a48:	858d                	srai	a1,a1,0x3
    80001a4a:	000ab783          	ld	a5,0(s5)
    80001a4e:	02f585b3          	mul	a1,a1,a5
    80001a52:	2585                	addiw	a1,a1,1
    80001a54:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a58:	4719                	li	a4,6
    80001a5a:	6685                	lui	a3,0x1
    80001a5c:	40b905b3          	sub	a1,s2,a1
    80001a60:	854e                	mv	a0,s3
    80001a62:	00000097          	auipc	ra,0x0
    80001a66:	8a6080e7          	jalr	-1882(ra) # 80001308 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6a:	16848493          	addi	s1,s1,360
    80001a6e:	fd4495e3          	bne	s1,s4,80001a38 <proc_mapstacks+0x38>
  }
}
    80001a72:	70e2                	ld	ra,56(sp)
    80001a74:	7442                	ld	s0,48(sp)
    80001a76:	74a2                	ld	s1,40(sp)
    80001a78:	7902                	ld	s2,32(sp)
    80001a7a:	69e2                	ld	s3,24(sp)
    80001a7c:	6a42                	ld	s4,16(sp)
    80001a7e:	6aa2                	ld	s5,8(sp)
    80001a80:	6b02                	ld	s6,0(sp)
    80001a82:	6121                	addi	sp,sp,64
    80001a84:	8082                	ret
      panic("kalloc");
    80001a86:	00006517          	auipc	a0,0x6
    80001a8a:	79250513          	addi	a0,a0,1938 # 80008218 <digits+0x1d8>
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>

0000000080001a96 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a96:	7139                	addi	sp,sp,-64
    80001a98:	fc06                	sd	ra,56(sp)
    80001a9a:	f822                	sd	s0,48(sp)
    80001a9c:	f426                	sd	s1,40(sp)
    80001a9e:	f04a                	sd	s2,32(sp)
    80001aa0:	ec4e                	sd	s3,24(sp)
    80001aa2:	e852                	sd	s4,16(sp)
    80001aa4:	e456                	sd	s5,8(sp)
    80001aa6:	e05a                	sd	s6,0(sp)
    80001aa8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001aaa:	00006597          	auipc	a1,0x6
    80001aae:	77658593          	addi	a1,a1,1910 # 80008220 <digits+0x1e0>
    80001ab2:	0000f517          	auipc	a0,0xf
    80001ab6:	16e50513          	addi	a0,a0,366 # 80010c20 <pid_lock>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	256080e7          	jalr	598(ra) # 80000d10 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ac2:	00006597          	auipc	a1,0x6
    80001ac6:	76658593          	addi	a1,a1,1894 # 80008228 <digits+0x1e8>
    80001aca:	0000f517          	auipc	a0,0xf
    80001ace:	16e50513          	addi	a0,a0,366 # 80010c38 <wait_lock>
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	23e080e7          	jalr	574(ra) # 80000d10 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ada:	0000f497          	auipc	s1,0xf
    80001ade:	57648493          	addi	s1,s1,1398 # 80011050 <proc>
      initlock(&p->lock, "proc");
    80001ae2:	00006b17          	auipc	s6,0x6
    80001ae6:	756b0b13          	addi	s6,s6,1878 # 80008238 <digits+0x1f8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001aea:	8aa6                	mv	s5,s1
    80001aec:	00006a17          	auipc	s4,0x6
    80001af0:	514a0a13          	addi	s4,s4,1300 # 80008000 <etext>
    80001af4:	04000937          	lui	s2,0x4000
    80001af8:	197d                	addi	s2,s2,-1
    80001afa:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001afc:	00015997          	auipc	s3,0x15
    80001b00:	f5498993          	addi	s3,s3,-172 # 80016a50 <tickslock>
      initlock(&p->lock, "proc");
    80001b04:	85da                	mv	a1,s6
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	208080e7          	jalr	520(ra) # 80000d10 <initlock>
      p->state = UNUSED;
    80001b10:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b14:	415487b3          	sub	a5,s1,s5
    80001b18:	878d                	srai	a5,a5,0x3
    80001b1a:	000a3703          	ld	a4,0(s4)
    80001b1e:	02e787b3          	mul	a5,a5,a4
    80001b22:	2785                	addiw	a5,a5,1
    80001b24:	00d7979b          	slliw	a5,a5,0xd
    80001b28:	40f907b3          	sub	a5,s2,a5
    80001b2c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2e:	16848493          	addi	s1,s1,360
    80001b32:	fd3499e3          	bne	s1,s3,80001b04 <procinit+0x6e>
  }
}
    80001b36:	70e2                	ld	ra,56(sp)
    80001b38:	7442                	ld	s0,48(sp)
    80001b3a:	74a2                	ld	s1,40(sp)
    80001b3c:	7902                	ld	s2,32(sp)
    80001b3e:	69e2                	ld	s3,24(sp)
    80001b40:	6a42                	ld	s4,16(sp)
    80001b42:	6aa2                	ld	s5,8(sp)
    80001b44:	6b02                	ld	s6,0(sp)
    80001b46:	6121                	addi	sp,sp,64
    80001b48:	8082                	ret

0000000080001b4a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b4a:	1141                	addi	sp,sp,-16
    80001b4c:	e422                	sd	s0,8(sp)
    80001b4e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b50:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b52:	2501                	sext.w	a0,a0
    80001b54:	6422                	ld	s0,8(sp)
    80001b56:	0141                	addi	sp,sp,16
    80001b58:	8082                	ret

0000000080001b5a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001b5a:	1141                	addi	sp,sp,-16
    80001b5c:	e422                	sd	s0,8(sp)
    80001b5e:	0800                	addi	s0,sp,16
    80001b60:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b62:	2781                	sext.w	a5,a5
    80001b64:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b66:	0000f517          	auipc	a0,0xf
    80001b6a:	0ea50513          	addi	a0,a0,234 # 80010c50 <cpus>
    80001b6e:	953e                	add	a0,a0,a5
    80001b70:	6422                	ld	s0,8(sp)
    80001b72:	0141                	addi	sp,sp,16
    80001b74:	8082                	ret

0000000080001b76 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	1000                	addi	s0,sp,32
  push_off();
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	1d4080e7          	jalr	468(ra) # 80000d54 <push_off>
    80001b88:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b8a:	2781                	sext.w	a5,a5
    80001b8c:	079e                	slli	a5,a5,0x7
    80001b8e:	0000f717          	auipc	a4,0xf
    80001b92:	09270713          	addi	a4,a4,146 # 80010c20 <pid_lock>
    80001b96:	97ba                	add	a5,a5,a4
    80001b98:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	25a080e7          	jalr	602(ra) # 80000df4 <pop_off>
  return p;
}
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6105                	addi	sp,sp,32
    80001bac:	8082                	ret

0000000080001bae <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bae:	1141                	addi	sp,sp,-16
    80001bb0:	e406                	sd	ra,8(sp)
    80001bb2:	e022                	sd	s0,0(sp)
    80001bb4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bb6:	00000097          	auipc	ra,0x0
    80001bba:	fc0080e7          	jalr	-64(ra) # 80001b76 <myproc>
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	296080e7          	jalr	662(ra) # 80000e54 <release>

  if (first) {
    80001bc6:	00007797          	auipc	a5,0x7
    80001bca:	d4a7a783          	lw	a5,-694(a5) # 80008910 <first.1>
    80001bce:	eb89                	bnez	a5,80001be0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bd0:	00001097          	auipc	ra,0x1
    80001bd4:	cae080e7          	jalr	-850(ra) # 8000287e <usertrapret>
}
    80001bd8:	60a2                	ld	ra,8(sp)
    80001bda:	6402                	ld	s0,0(sp)
    80001bdc:	0141                	addi	sp,sp,16
    80001bde:	8082                	ret
    first = 0;
    80001be0:	00007797          	auipc	a5,0x7
    80001be4:	d207a823          	sw	zero,-720(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001be8:	4505                	li	a0,1
    80001bea:	00002097          	auipc	ra,0x2
    80001bee:	ac8080e7          	jalr	-1336(ra) # 800036b2 <fsinit>
    80001bf2:	bff9                	j	80001bd0 <forkret+0x22>

0000000080001bf4 <allocpid>:
{
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	e04a                	sd	s2,0(sp)
    80001bfe:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c00:	0000f917          	auipc	s2,0xf
    80001c04:	02090913          	addi	s2,s2,32 # 80010c20 <pid_lock>
    80001c08:	854a                	mv	a0,s2
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	196080e7          	jalr	406(ra) # 80000da0 <acquire>
  pid = nextpid;
    80001c12:	00007797          	auipc	a5,0x7
    80001c16:	d0278793          	addi	a5,a5,-766 # 80008914 <nextpid>
    80001c1a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c1c:	0014871b          	addiw	a4,s1,1
    80001c20:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c22:	854a                	mv	a0,s2
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	230080e7          	jalr	560(ra) # 80000e54 <release>
}
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	60e2                	ld	ra,24(sp)
    80001c30:	6442                	ld	s0,16(sp)
    80001c32:	64a2                	ld	s1,8(sp)
    80001c34:	6902                	ld	s2,0(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret

0000000080001c3a <proc_pagetable>:
{
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
    80001c46:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	8aa080e7          	jalr	-1878(ra) # 800014f2 <uvmcreate>
    80001c50:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c52:	c121                	beqz	a0,80001c92 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c54:	4729                	li	a4,10
    80001c56:	00005697          	auipc	a3,0x5
    80001c5a:	3aa68693          	addi	a3,a3,938 # 80007000 <_trampoline>
    80001c5e:	6605                	lui	a2,0x1
    80001c60:	040005b7          	lui	a1,0x4000
    80001c64:	15fd                	addi	a1,a1,-1
    80001c66:	05b2                	slli	a1,a1,0xc
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	600080e7          	jalr	1536(ra) # 80001268 <mappages>
    80001c70:	02054863          	bltz	a0,80001ca0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c74:	4719                	li	a4,6
    80001c76:	05893683          	ld	a3,88(s2)
    80001c7a:	6605                	lui	a2,0x1
    80001c7c:	020005b7          	lui	a1,0x2000
    80001c80:	15fd                	addi	a1,a1,-1
    80001c82:	05b6                	slli	a1,a1,0xd
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	5e2080e7          	jalr	1506(ra) # 80001268 <mappages>
    80001c8e:	02054163          	bltz	a0,80001cb0 <proc_pagetable+0x76>
}
    80001c92:	8526                	mv	a0,s1
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6902                	ld	s2,0(sp)
    80001c9c:	6105                	addi	sp,sp,32
    80001c9e:	8082                	ret
    uvmfree(pagetable, 0);
    80001ca0:	4581                	li	a1,0
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	a52080e7          	jalr	-1454(ra) # 800016f6 <uvmfree>
    return 0;
    80001cac:	4481                	li	s1,0
    80001cae:	b7d5                	j	80001c92 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cb0:	4681                	li	a3,0
    80001cb2:	4605                	li	a2,1
    80001cb4:	040005b7          	lui	a1,0x4000
    80001cb8:	15fd                	addi	a1,a1,-1
    80001cba:	05b2                	slli	a1,a1,0xc
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	770080e7          	jalr	1904(ra) # 8000142e <uvmunmap>
    uvmfree(pagetable, 0);
    80001cc6:	4581                	li	a1,0
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	a2c080e7          	jalr	-1492(ra) # 800016f6 <uvmfree>
    return 0;
    80001cd2:	4481                	li	s1,0
    80001cd4:	bf7d                	j	80001c92 <proc_pagetable+0x58>

0000000080001cd6 <proc_freepagetable>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	e04a                	sd	s2,0(sp)
    80001ce0:	1000                	addi	s0,sp,32
    80001ce2:	84aa                	mv	s1,a0
    80001ce4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce6:	4681                	li	a3,0
    80001ce8:	4605                	li	a2,1
    80001cea:	040005b7          	lui	a1,0x4000
    80001cee:	15fd                	addi	a1,a1,-1
    80001cf0:	05b2                	slli	a1,a1,0xc
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	73c080e7          	jalr	1852(ra) # 8000142e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cfa:	4681                	li	a3,0
    80001cfc:	4605                	li	a2,1
    80001cfe:	020005b7          	lui	a1,0x2000
    80001d02:	15fd                	addi	a1,a1,-1
    80001d04:	05b6                	slli	a1,a1,0xd
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	726080e7          	jalr	1830(ra) # 8000142e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d10:	85ca                	mv	a1,s2
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	9e2080e7          	jalr	-1566(ra) # 800016f6 <uvmfree>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6902                	ld	s2,0(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret

0000000080001d28 <freeproc>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d34:	6d28                	ld	a0,88(a0)
    80001d36:	c509                	beqz	a0,80001d40 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	cb2080e7          	jalr	-846(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001d40:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d44:	68a8                	ld	a0,80(s1)
    80001d46:	c511                	beqz	a0,80001d52 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d48:	64ac                	ld	a1,72(s1)
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	f8c080e7          	jalr	-116(ra) # 80001cd6 <proc_freepagetable>
  p->pagetable = 0;
    80001d52:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d56:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d5a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d5e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d62:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d66:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d6a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d6e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d72:	0004ac23          	sw	zero,24(s1)
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret

0000000080001d80 <allocproc>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	e04a                	sd	s2,0(sp)
    80001d8a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8c:	0000f497          	auipc	s1,0xf
    80001d90:	2c448493          	addi	s1,s1,708 # 80011050 <proc>
    80001d94:	00015917          	auipc	s2,0x15
    80001d98:	cbc90913          	addi	s2,s2,-836 # 80016a50 <tickslock>
    acquire(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	002080e7          	jalr	2(ra) # 80000da0 <acquire>
    if(p->state == UNUSED) {
    80001da6:	4c9c                	lw	a5,24(s1)
    80001da8:	cf81                	beqz	a5,80001dc0 <allocproc+0x40>
      release(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	0a8080e7          	jalr	168(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db4:	16848493          	addi	s1,s1,360
    80001db8:	ff2492e3          	bne	s1,s2,80001d9c <allocproc+0x1c>
  return 0;
    80001dbc:	4481                	li	s1,0
    80001dbe:	a889                	j	80001e10 <allocproc+0x90>
  p->pid = allocpid();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	e34080e7          	jalr	-460(ra) # 80001bf4 <allocpid>
    80001dc8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dca:	4785                	li	a5,1
    80001dcc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	cdc080e7          	jalr	-804(ra) # 80000aaa <kalloc>
    80001dd6:	892a                	mv	s2,a0
    80001dd8:	eca8                	sd	a0,88(s1)
    80001dda:	c131                	beqz	a0,80001e1e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	e5c080e7          	jalr	-420(ra) # 80001c3a <proc_pagetable>
    80001de6:	892a                	mv	s2,a0
    80001de8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dea:	c531                	beqz	a0,80001e36 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001dec:	07000613          	li	a2,112
    80001df0:	4581                	li	a1,0
    80001df2:	06048513          	addi	a0,s1,96
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	0a6080e7          	jalr	166(ra) # 80000e9c <memset>
  p->context.ra = (uint64)forkret;
    80001dfe:	00000797          	auipc	a5,0x0
    80001e02:	db078793          	addi	a5,a5,-592 # 80001bae <forkret>
    80001e06:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e08:	60bc                	ld	a5,64(s1)
    80001e0a:	6705                	lui	a4,0x1
    80001e0c:	97ba                	add	a5,a5,a4
    80001e0e:	f4bc                	sd	a5,104(s1)
}
    80001e10:	8526                	mv	a0,s1
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6902                	ld	s2,0(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret
    freeproc(p);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	f08080e7          	jalr	-248(ra) # 80001d28 <freeproc>
    release(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	02a080e7          	jalr	42(ra) # 80000e54 <release>
    return 0;
    80001e32:	84ca                	mv	s1,s2
    80001e34:	bff1                	j	80001e10 <allocproc+0x90>
    freeproc(p);
    80001e36:	8526                	mv	a0,s1
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	ef0080e7          	jalr	-272(ra) # 80001d28 <freeproc>
    release(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	012080e7          	jalr	18(ra) # 80000e54 <release>
    return 0;
    80001e4a:	84ca                	mv	s1,s2
    80001e4c:	b7d1                	j	80001e10 <allocproc+0x90>

0000000080001e4e <userinit>:
{
    80001e4e:	1101                	addi	sp,sp,-32
    80001e50:	ec06                	sd	ra,24(sp)
    80001e52:	e822                	sd	s0,16(sp)
    80001e54:	e426                	sd	s1,8(sp)
    80001e56:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	f28080e7          	jalr	-216(ra) # 80001d80 <allocproc>
    80001e60:	84aa                	mv	s1,a0
  initproc = p;
    80001e62:	00007797          	auipc	a5,0x7
    80001e66:	b2a7b323          	sd	a0,-1242(a5) # 80008988 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e6a:	03400613          	li	a2,52
    80001e6e:	00007597          	auipc	a1,0x7
    80001e72:	ab258593          	addi	a1,a1,-1358 # 80008920 <initcode>
    80001e76:	6928                	ld	a0,80(a0)
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	6a8080e7          	jalr	1704(ra) # 80001520 <uvmfirst>
  p->sz = PGSIZE;
    80001e80:	6785                	lui	a5,0x1
    80001e82:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e84:	6cb8                	ld	a4,88(s1)
    80001e86:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e8a:	6cb8                	ld	a4,88(s1)
    80001e8c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e8e:	4641                	li	a2,16
    80001e90:	00006597          	auipc	a1,0x6
    80001e94:	3b058593          	addi	a1,a1,944 # 80008240 <digits+0x200>
    80001e98:	15848513          	addi	a0,s1,344
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	14a080e7          	jalr	330(ra) # 80000fe6 <safestrcpy>
  p->cwd = namei("/");
    80001ea4:	00006517          	auipc	a0,0x6
    80001ea8:	3ac50513          	addi	a0,a0,940 # 80008250 <digits+0x210>
    80001eac:	00002097          	auipc	ra,0x2
    80001eb0:	228080e7          	jalr	552(ra) # 800040d4 <namei>
    80001eb4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eb8:	478d                	li	a5,3
    80001eba:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	f96080e7          	jalr	-106(ra) # 80000e54 <release>
}
    80001ec6:	60e2                	ld	ra,24(sp)
    80001ec8:	6442                	ld	s0,16(sp)
    80001eca:	64a2                	ld	s1,8(sp)
    80001ecc:	6105                	addi	sp,sp,32
    80001ece:	8082                	ret

0000000080001ed0 <growproc>:
{
    80001ed0:	1101                	addi	sp,sp,-32
    80001ed2:	ec06                	sd	ra,24(sp)
    80001ed4:	e822                	sd	s0,16(sp)
    80001ed6:	e426                	sd	s1,8(sp)
    80001ed8:	e04a                	sd	s2,0(sp)
    80001eda:	1000                	addi	s0,sp,32
    80001edc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	c98080e7          	jalr	-872(ra) # 80001b76 <myproc>
    80001ee6:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ee8:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001eea:	01204c63          	bgtz	s2,80001f02 <growproc+0x32>
  } else if(n < 0){
    80001eee:	02094663          	bltz	s2,80001f1a <growproc+0x4a>
  p->sz = sz;
    80001ef2:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ef4:	4501                	li	a0,0
}
    80001ef6:	60e2                	ld	ra,24(sp)
    80001ef8:	6442                	ld	s0,16(sp)
    80001efa:	64a2                	ld	s1,8(sp)
    80001efc:	6902                	ld	s2,0(sp)
    80001efe:	6105                	addi	sp,sp,32
    80001f00:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f02:	4691                	li	a3,4
    80001f04:	00b90633          	add	a2,s2,a1
    80001f08:	6928                	ld	a0,80(a0)
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	6d0080e7          	jalr	1744(ra) # 800015da <uvmalloc>
    80001f12:	85aa                	mv	a1,a0
    80001f14:	fd79                	bnez	a0,80001ef2 <growproc+0x22>
      return -1;
    80001f16:	557d                	li	a0,-1
    80001f18:	bff9                	j	80001ef6 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f1a:	00b90633          	add	a2,s2,a1
    80001f1e:	6928                	ld	a0,80(a0)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	672080e7          	jalr	1650(ra) # 80001592 <uvmdealloc>
    80001f28:	85aa                	mv	a1,a0
    80001f2a:	b7e1                	j	80001ef2 <growproc+0x22>

0000000080001f2c <fork>:
{
    80001f2c:	7139                	addi	sp,sp,-64
    80001f2e:	fc06                	sd	ra,56(sp)
    80001f30:	f822                	sd	s0,48(sp)
    80001f32:	f426                	sd	s1,40(sp)
    80001f34:	f04a                	sd	s2,32(sp)
    80001f36:	ec4e                	sd	s3,24(sp)
    80001f38:	e852                	sd	s4,16(sp)
    80001f3a:	e456                	sd	s5,8(sp)
    80001f3c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	c38080e7          	jalr	-968(ra) # 80001b76 <myproc>
    80001f46:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	e38080e7          	jalr	-456(ra) # 80001d80 <allocproc>
    80001f50:	10050c63          	beqz	a0,80002068 <fork+0x13c>
    80001f54:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f56:	048ab603          	ld	a2,72(s5)
    80001f5a:	692c                	ld	a1,80(a0)
    80001f5c:	050ab503          	ld	a0,80(s5)
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	7ce080e7          	jalr	1998(ra) # 8000172e <uvmcopy>
    80001f68:	04054863          	bltz	a0,80001fb8 <fork+0x8c>
  np->sz = p->sz;
    80001f6c:	048ab783          	ld	a5,72(s5)
    80001f70:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f74:	058ab683          	ld	a3,88(s5)
    80001f78:	87b6                	mv	a5,a3
    80001f7a:	058a3703          	ld	a4,88(s4)
    80001f7e:	12068693          	addi	a3,a3,288
    80001f82:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f86:	6788                	ld	a0,8(a5)
    80001f88:	6b8c                	ld	a1,16(a5)
    80001f8a:	6f90                	ld	a2,24(a5)
    80001f8c:	01073023          	sd	a6,0(a4)
    80001f90:	e708                	sd	a0,8(a4)
    80001f92:	eb0c                	sd	a1,16(a4)
    80001f94:	ef10                	sd	a2,24(a4)
    80001f96:	02078793          	addi	a5,a5,32
    80001f9a:	02070713          	addi	a4,a4,32
    80001f9e:	fed792e3          	bne	a5,a3,80001f82 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fa2:	058a3783          	ld	a5,88(s4)
    80001fa6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001faa:	0d0a8493          	addi	s1,s5,208
    80001fae:	0d0a0913          	addi	s2,s4,208
    80001fb2:	150a8993          	addi	s3,s5,336
    80001fb6:	a00d                	j	80001fd8 <fork+0xac>
    freeproc(np);
    80001fb8:	8552                	mv	a0,s4
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	d6e080e7          	jalr	-658(ra) # 80001d28 <freeproc>
    release(&np->lock);
    80001fc2:	8552                	mv	a0,s4
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	e90080e7          	jalr	-368(ra) # 80000e54 <release>
    return -1;
    80001fcc:	597d                	li	s2,-1
    80001fce:	a059                	j	80002054 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001fd0:	04a1                	addi	s1,s1,8
    80001fd2:	0921                	addi	s2,s2,8
    80001fd4:	01348b63          	beq	s1,s3,80001fea <fork+0xbe>
    if(p->ofile[i])
    80001fd8:	6088                	ld	a0,0(s1)
    80001fda:	d97d                	beqz	a0,80001fd0 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	78e080e7          	jalr	1934(ra) # 8000476a <filedup>
    80001fe4:	00a93023          	sd	a0,0(s2)
    80001fe8:	b7e5                	j	80001fd0 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001fea:	150ab503          	ld	a0,336(s5)
    80001fee:	00002097          	auipc	ra,0x2
    80001ff2:	902080e7          	jalr	-1790(ra) # 800038f0 <idup>
    80001ff6:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ffa:	4641                	li	a2,16
    80001ffc:	158a8593          	addi	a1,s5,344
    80002000:	158a0513          	addi	a0,s4,344
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	fe2080e7          	jalr	-30(ra) # 80000fe6 <safestrcpy>
  pid = np->pid;
    8000200c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002010:	8552                	mv	a0,s4
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	e42080e7          	jalr	-446(ra) # 80000e54 <release>
  acquire(&wait_lock);
    8000201a:	0000f497          	auipc	s1,0xf
    8000201e:	c1e48493          	addi	s1,s1,-994 # 80010c38 <wait_lock>
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	d7c080e7          	jalr	-644(ra) # 80000da0 <acquire>
  np->parent = p;
    8000202c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002030:	8526                	mv	a0,s1
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	e22080e7          	jalr	-478(ra) # 80000e54 <release>
  acquire(&np->lock);
    8000203a:	8552                	mv	a0,s4
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	d64080e7          	jalr	-668(ra) # 80000da0 <acquire>
  np->state = RUNNABLE;
    80002044:	478d                	li	a5,3
    80002046:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000204a:	8552                	mv	a0,s4
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	e08080e7          	jalr	-504(ra) # 80000e54 <release>
}
    80002054:	854a                	mv	a0,s2
    80002056:	70e2                	ld	ra,56(sp)
    80002058:	7442                	ld	s0,48(sp)
    8000205a:	74a2                	ld	s1,40(sp)
    8000205c:	7902                	ld	s2,32(sp)
    8000205e:	69e2                	ld	s3,24(sp)
    80002060:	6a42                	ld	s4,16(sp)
    80002062:	6aa2                	ld	s5,8(sp)
    80002064:	6121                	addi	sp,sp,64
    80002066:	8082                	ret
    return -1;
    80002068:	597d                	li	s2,-1
    8000206a:	b7ed                	j	80002054 <fork+0x128>

000000008000206c <scheduler>:
{
    8000206c:	7139                	addi	sp,sp,-64
    8000206e:	fc06                	sd	ra,56(sp)
    80002070:	f822                	sd	s0,48(sp)
    80002072:	f426                	sd	s1,40(sp)
    80002074:	f04a                	sd	s2,32(sp)
    80002076:	ec4e                	sd	s3,24(sp)
    80002078:	e852                	sd	s4,16(sp)
    8000207a:	e456                	sd	s5,8(sp)
    8000207c:	e05a                	sd	s6,0(sp)
    8000207e:	0080                	addi	s0,sp,64
    80002080:	8792                	mv	a5,tp
  int id = r_tp();
    80002082:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002084:	00779a93          	slli	s5,a5,0x7
    80002088:	0000f717          	auipc	a4,0xf
    8000208c:	b9870713          	addi	a4,a4,-1128 # 80010c20 <pid_lock>
    80002090:	9756                	add	a4,a4,s5
    80002092:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002096:	0000f717          	auipc	a4,0xf
    8000209a:	bc270713          	addi	a4,a4,-1086 # 80010c58 <cpus+0x8>
    8000209e:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020a0:	498d                	li	s3,3
        p->state = RUNNING;
    800020a2:	4b11                	li	s6,4
        c->proc = p;
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	0000fa17          	auipc	s4,0xf
    800020aa:	b7aa0a13          	addi	s4,s4,-1158 # 80010c20 <pid_lock>
    800020ae:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b0:	00015917          	auipc	s2,0x15
    800020b4:	9a090913          	addi	s2,s2,-1632 # 80016a50 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020bc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c0:	10079073          	csrw	sstatus,a5
    800020c4:	0000f497          	auipc	s1,0xf
    800020c8:	f8c48493          	addi	s1,s1,-116 # 80011050 <proc>
    800020cc:	a811                	j	800020e0 <scheduler+0x74>
      release(&p->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	d84080e7          	jalr	-636(ra) # 80000e54 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	16848493          	addi	s1,s1,360
    800020dc:	fd248ee3          	beq	s1,s2,800020b8 <scheduler+0x4c>
      acquire(&p->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	cbe080e7          	jalr	-834(ra) # 80000da0 <acquire>
      if(p->state == RUNNABLE) {
    800020ea:	4c9c                	lw	a5,24(s1)
    800020ec:	ff3791e3          	bne	a5,s3,800020ce <scheduler+0x62>
        p->state = RUNNING;
    800020f0:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020f4:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020f8:	06048593          	addi	a1,s1,96
    800020fc:	8556                	mv	a0,s5
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	6d6080e7          	jalr	1750(ra) # 800027d4 <swtch>
        c->proc = 0;
    80002106:	020a3823          	sd	zero,48(s4)
    8000210a:	b7d1                	j	800020ce <scheduler+0x62>

000000008000210c <sched>:
{
    8000210c:	7179                	addi	sp,sp,-48
    8000210e:	f406                	sd	ra,40(sp)
    80002110:	f022                	sd	s0,32(sp)
    80002112:	ec26                	sd	s1,24(sp)
    80002114:	e84a                	sd	s2,16(sp)
    80002116:	e44e                	sd	s3,8(sp)
    80002118:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	a5c080e7          	jalr	-1444(ra) # 80001b76 <myproc>
    80002122:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	c02080e7          	jalr	-1022(ra) # 80000d26 <holding>
    8000212c:	c93d                	beqz	a0,800021a2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000212e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	0000f717          	auipc	a4,0xf
    80002138:	aec70713          	addi	a4,a4,-1300 # 80010c20 <pid_lock>
    8000213c:	97ba                	add	a5,a5,a4
    8000213e:	0a87a703          	lw	a4,168(a5)
    80002142:	4785                	li	a5,1
    80002144:	06f71763          	bne	a4,a5,800021b2 <sched+0xa6>
  if(p->state == RUNNING)
    80002148:	4c98                	lw	a4,24(s1)
    8000214a:	4791                	li	a5,4
    8000214c:	06f70b63          	beq	a4,a5,800021c2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002150:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002154:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002156:	efb5                	bnez	a5,800021d2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002158:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000215a:	0000f917          	auipc	s2,0xf
    8000215e:	ac690913          	addi	s2,s2,-1338 # 80010c20 <pid_lock>
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	97ca                	add	a5,a5,s2
    80002168:	0ac7a983          	lw	s3,172(a5)
    8000216c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000216e:	2781                	sext.w	a5,a5
    80002170:	079e                	slli	a5,a5,0x7
    80002172:	0000f597          	auipc	a1,0xf
    80002176:	ae658593          	addi	a1,a1,-1306 # 80010c58 <cpus+0x8>
    8000217a:	95be                	add	a1,a1,a5
    8000217c:	06048513          	addi	a0,s1,96
    80002180:	00000097          	auipc	ra,0x0
    80002184:	654080e7          	jalr	1620(ra) # 800027d4 <swtch>
    80002188:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	0b37a623          	sw	s3,172(a5)
}
    80002194:	70a2                	ld	ra,40(sp)
    80002196:	7402                	ld	s0,32(sp)
    80002198:	64e2                	ld	s1,24(sp)
    8000219a:	6942                	ld	s2,16(sp)
    8000219c:	69a2                	ld	s3,8(sp)
    8000219e:	6145                	addi	sp,sp,48
    800021a0:	8082                	ret
    panic("sched p->lock");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	0b650513          	addi	a0,a0,182 # 80008258 <digits+0x218>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
    panic("sched locks");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	0b650513          	addi	a0,a0,182 # 80008268 <digits+0x228>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	384080e7          	jalr	900(ra) # 8000053e <panic>
    panic("sched running");
    800021c2:	00006517          	auipc	a0,0x6
    800021c6:	0b650513          	addi	a0,a0,182 # 80008278 <digits+0x238>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	374080e7          	jalr	884(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	0b650513          	addi	a0,a0,182 # 80008288 <digits+0x248>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	364080e7          	jalr	868(ra) # 8000053e <panic>

00000000800021e2 <yield>:
{
    800021e2:	1101                	addi	sp,sp,-32
    800021e4:	ec06                	sd	ra,24(sp)
    800021e6:	e822                	sd	s0,16(sp)
    800021e8:	e426                	sd	s1,8(sp)
    800021ea:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	98a080e7          	jalr	-1654(ra) # 80001b76 <myproc>
    800021f4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	baa080e7          	jalr	-1110(ra) # 80000da0 <acquire>
  p->state = RUNNABLE;
    800021fe:	478d                	li	a5,3
    80002200:	cc9c                	sw	a5,24(s1)
  sched();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	f0a080e7          	jalr	-246(ra) # 8000210c <sched>
  release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	c48080e7          	jalr	-952(ra) # 80000e54 <release>
}
    80002214:	60e2                	ld	ra,24(sp)
    80002216:	6442                	ld	s0,16(sp)
    80002218:	64a2                	ld	s1,8(sp)
    8000221a:	6105                	addi	sp,sp,32
    8000221c:	8082                	ret

000000008000221e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000221e:	7179                	addi	sp,sp,-48
    80002220:	f406                	sd	ra,40(sp)
    80002222:	f022                	sd	s0,32(sp)
    80002224:	ec26                	sd	s1,24(sp)
    80002226:	e84a                	sd	s2,16(sp)
    80002228:	e44e                	sd	s3,8(sp)
    8000222a:	1800                	addi	s0,sp,48
    8000222c:	89aa                	mv	s3,a0
    8000222e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	946080e7          	jalr	-1722(ra) # 80001b76 <myproc>
    80002238:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	b66080e7          	jalr	-1178(ra) # 80000da0 <acquire>
  release(lk);
    80002242:	854a                	mv	a0,s2
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	c10080e7          	jalr	-1008(ra) # 80000e54 <release>

  // Go to sleep.
  p->chan = chan;
    8000224c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002250:	4789                	li	a5,2
    80002252:	cc9c                	sw	a5,24(s1)

  sched();
    80002254:	00000097          	auipc	ra,0x0
    80002258:	eb8080e7          	jalr	-328(ra) # 8000210c <sched>

  // Tidy up.
  p->chan = 0;
    8000225c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002260:	8526                	mv	a0,s1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	bf2080e7          	jalr	-1038(ra) # 80000e54 <release>
  acquire(lk);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	b34080e7          	jalr	-1228(ra) # 80000da0 <acquire>
}
    80002274:	70a2                	ld	ra,40(sp)
    80002276:	7402                	ld	s0,32(sp)
    80002278:	64e2                	ld	s1,24(sp)
    8000227a:	6942                	ld	s2,16(sp)
    8000227c:	69a2                	ld	s3,8(sp)
    8000227e:	6145                	addi	sp,sp,48
    80002280:	8082                	ret

0000000080002282 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002282:	7139                	addi	sp,sp,-64
    80002284:	fc06                	sd	ra,56(sp)
    80002286:	f822                	sd	s0,48(sp)
    80002288:	f426                	sd	s1,40(sp)
    8000228a:	f04a                	sd	s2,32(sp)
    8000228c:	ec4e                	sd	s3,24(sp)
    8000228e:	e852                	sd	s4,16(sp)
    80002290:	e456                	sd	s5,8(sp)
    80002292:	0080                	addi	s0,sp,64
    80002294:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002296:	0000f497          	auipc	s1,0xf
    8000229a:	dba48493          	addi	s1,s1,-582 # 80011050 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000229e:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022a0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022a2:	00014917          	auipc	s2,0x14
    800022a6:	7ae90913          	addi	s2,s2,1966 # 80016a50 <tickslock>
    800022aa:	a811                	j	800022be <wakeup+0x3c>
      }
      release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	ba6080e7          	jalr	-1114(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022b6:	16848493          	addi	s1,s1,360
    800022ba:	03248663          	beq	s1,s2,800022e6 <wakeup+0x64>
    if(p != myproc()){
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	8b8080e7          	jalr	-1864(ra) # 80001b76 <myproc>
    800022c6:	fea488e3          	beq	s1,a0,800022b6 <wakeup+0x34>
      acquire(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	ad4080e7          	jalr	-1324(ra) # 80000da0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022d4:	4c9c                	lw	a5,24(s1)
    800022d6:	fd379be3          	bne	a5,s3,800022ac <wakeup+0x2a>
    800022da:	709c                	ld	a5,32(s1)
    800022dc:	fd4798e3          	bne	a5,s4,800022ac <wakeup+0x2a>
        p->state = RUNNABLE;
    800022e0:	0154ac23          	sw	s5,24(s1)
    800022e4:	b7e1                	j	800022ac <wakeup+0x2a>
    }
  }
}
    800022e6:	70e2                	ld	ra,56(sp)
    800022e8:	7442                	ld	s0,48(sp)
    800022ea:	74a2                	ld	s1,40(sp)
    800022ec:	7902                	ld	s2,32(sp)
    800022ee:	69e2                	ld	s3,24(sp)
    800022f0:	6a42                	ld	s4,16(sp)
    800022f2:	6aa2                	ld	s5,8(sp)
    800022f4:	6121                	addi	sp,sp,64
    800022f6:	8082                	ret

00000000800022f8 <reparent>:
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	e052                	sd	s4,0(sp)
    80002306:	1800                	addi	s0,sp,48
    80002308:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000230a:	0000f497          	auipc	s1,0xf
    8000230e:	d4648493          	addi	s1,s1,-698 # 80011050 <proc>
      pp->parent = initproc;
    80002312:	00006a17          	auipc	s4,0x6
    80002316:	676a0a13          	addi	s4,s4,1654 # 80008988 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000231a:	00014997          	auipc	s3,0x14
    8000231e:	73698993          	addi	s3,s3,1846 # 80016a50 <tickslock>
    80002322:	a029                	j	8000232c <reparent+0x34>
    80002324:	16848493          	addi	s1,s1,360
    80002328:	01348d63          	beq	s1,s3,80002342 <reparent+0x4a>
    if(pp->parent == p){
    8000232c:	7c9c                	ld	a5,56(s1)
    8000232e:	ff279be3          	bne	a5,s2,80002324 <reparent+0x2c>
      pp->parent = initproc;
    80002332:	000a3503          	ld	a0,0(s4)
    80002336:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	f4a080e7          	jalr	-182(ra) # 80002282 <wakeup>
    80002340:	b7d5                	j	80002324 <reparent+0x2c>
}
    80002342:	70a2                	ld	ra,40(sp)
    80002344:	7402                	ld	s0,32(sp)
    80002346:	64e2                	ld	s1,24(sp)
    80002348:	6942                	ld	s2,16(sp)
    8000234a:	69a2                	ld	s3,8(sp)
    8000234c:	6a02                	ld	s4,0(sp)
    8000234e:	6145                	addi	sp,sp,48
    80002350:	8082                	ret

0000000080002352 <exit>:
{
    80002352:	7179                	addi	sp,sp,-48
    80002354:	f406                	sd	ra,40(sp)
    80002356:	f022                	sd	s0,32(sp)
    80002358:	ec26                	sd	s1,24(sp)
    8000235a:	e84a                	sd	s2,16(sp)
    8000235c:	e44e                	sd	s3,8(sp)
    8000235e:	e052                	sd	s4,0(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	812080e7          	jalr	-2030(ra) # 80001b76 <myproc>
    8000236c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000236e:	00006797          	auipc	a5,0x6
    80002372:	61a7b783          	ld	a5,1562(a5) # 80008988 <initproc>
    80002376:	0d050493          	addi	s1,a0,208
    8000237a:	15050913          	addi	s2,a0,336
    8000237e:	02a79363          	bne	a5,a0,800023a4 <exit+0x52>
    panic("init exiting");
    80002382:	00006517          	auipc	a0,0x6
    80002386:	f1e50513          	addi	a0,a0,-226 # 800082a0 <digits+0x260>
    8000238a:	ffffe097          	auipc	ra,0xffffe
    8000238e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>
      fileclose(f);
    80002392:	00002097          	auipc	ra,0x2
    80002396:	42a080e7          	jalr	1066(ra) # 800047bc <fileclose>
      p->ofile[fd] = 0;
    8000239a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000239e:	04a1                	addi	s1,s1,8
    800023a0:	01248563          	beq	s1,s2,800023aa <exit+0x58>
    if(p->ofile[fd]){
    800023a4:	6088                	ld	a0,0(s1)
    800023a6:	f575                	bnez	a0,80002392 <exit+0x40>
    800023a8:	bfdd                	j	8000239e <exit+0x4c>
  begin_op();
    800023aa:	00002097          	auipc	ra,0x2
    800023ae:	f46080e7          	jalr	-186(ra) # 800042f0 <begin_op>
  iput(p->cwd);
    800023b2:	1509b503          	ld	a0,336(s3)
    800023b6:	00001097          	auipc	ra,0x1
    800023ba:	732080e7          	jalr	1842(ra) # 80003ae8 <iput>
  end_op();
    800023be:	00002097          	auipc	ra,0x2
    800023c2:	fb2080e7          	jalr	-78(ra) # 80004370 <end_op>
  p->cwd = 0;
    800023c6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023ca:	0000f497          	auipc	s1,0xf
    800023ce:	86e48493          	addi	s1,s1,-1938 # 80010c38 <wait_lock>
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	9cc080e7          	jalr	-1588(ra) # 80000da0 <acquire>
  reparent(p);
    800023dc:	854e                	mv	a0,s3
    800023de:	00000097          	auipc	ra,0x0
    800023e2:	f1a080e7          	jalr	-230(ra) # 800022f8 <reparent>
  wakeup(p->parent);
    800023e6:	0389b503          	ld	a0,56(s3)
    800023ea:	00000097          	auipc	ra,0x0
    800023ee:	e98080e7          	jalr	-360(ra) # 80002282 <wakeup>
  acquire(&p->lock);
    800023f2:	854e                	mv	a0,s3
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	9ac080e7          	jalr	-1620(ra) # 80000da0 <acquire>
  p->xstate = status;
    800023fc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002400:	4795                	li	a5,5
    80002402:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	a4c080e7          	jalr	-1460(ra) # 80000e54 <release>
  sched();
    80002410:	00000097          	auipc	ra,0x0
    80002414:	cfc080e7          	jalr	-772(ra) # 8000210c <sched>
  panic("zombie exit");
    80002418:	00006517          	auipc	a0,0x6
    8000241c:	e9850513          	addi	a0,a0,-360 # 800082b0 <digits+0x270>
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	11e080e7          	jalr	286(ra) # 8000053e <panic>

0000000080002428 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002428:	7179                	addi	sp,sp,-48
    8000242a:	f406                	sd	ra,40(sp)
    8000242c:	f022                	sd	s0,32(sp)
    8000242e:	ec26                	sd	s1,24(sp)
    80002430:	e84a                	sd	s2,16(sp)
    80002432:	e44e                	sd	s3,8(sp)
    80002434:	1800                	addi	s0,sp,48
    80002436:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	c1848493          	addi	s1,s1,-1000 # 80011050 <proc>
    80002440:	00014997          	auipc	s3,0x14
    80002444:	61098993          	addi	s3,s3,1552 # 80016a50 <tickslock>
    acquire(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	956080e7          	jalr	-1706(ra) # 80000da0 <acquire>
    if(p->pid == pid){
    80002452:	589c                	lw	a5,48(s1)
    80002454:	01278d63          	beq	a5,s2,8000246e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	9fa080e7          	jalr	-1542(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002462:	16848493          	addi	s1,s1,360
    80002466:	ff3491e3          	bne	s1,s3,80002448 <kill+0x20>
  }
  return -1;
    8000246a:	557d                	li	a0,-1
    8000246c:	a829                	j	80002486 <kill+0x5e>
      p->killed = 1;
    8000246e:	4785                	li	a5,1
    80002470:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002472:	4c98                	lw	a4,24(s1)
    80002474:	4789                	li	a5,2
    80002476:	00f70f63          	beq	a4,a5,80002494 <kill+0x6c>
      release(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	9d8080e7          	jalr	-1576(ra) # 80000e54 <release>
      return 0;
    80002484:	4501                	li	a0,0
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret
        p->state = RUNNABLE;
    80002494:	478d                	li	a5,3
    80002496:	cc9c                	sw	a5,24(s1)
    80002498:	b7cd                	j	8000247a <kill+0x52>

000000008000249a <setkilled>:

void
setkilled(struct proc *p)
{
    8000249a:	1101                	addi	sp,sp,-32
    8000249c:	ec06                	sd	ra,24(sp)
    8000249e:	e822                	sd	s0,16(sp)
    800024a0:	e426                	sd	s1,8(sp)
    800024a2:	1000                	addi	s0,sp,32
    800024a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	8fa080e7          	jalr	-1798(ra) # 80000da0 <acquire>
  p->killed = 1;
    800024ae:	4785                	li	a5,1
    800024b0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	9a0080e7          	jalr	-1632(ra) # 80000e54 <release>
}
    800024bc:	60e2                	ld	ra,24(sp)
    800024be:	6442                	ld	s0,16(sp)
    800024c0:	64a2                	ld	s1,8(sp)
    800024c2:	6105                	addi	sp,sp,32
    800024c4:	8082                	ret

00000000800024c6 <killed>:

int
killed(struct proc *p)
{
    800024c6:	1101                	addi	sp,sp,-32
    800024c8:	ec06                	sd	ra,24(sp)
    800024ca:	e822                	sd	s0,16(sp)
    800024cc:	e426                	sd	s1,8(sp)
    800024ce:	e04a                	sd	s2,0(sp)
    800024d0:	1000                	addi	s0,sp,32
    800024d2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	8cc080e7          	jalr	-1844(ra) # 80000da0 <acquire>
  k = p->killed;
    800024dc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	972080e7          	jalr	-1678(ra) # 80000e54 <release>
  return k;
}
    800024ea:	854a                	mv	a0,s2
    800024ec:	60e2                	ld	ra,24(sp)
    800024ee:	6442                	ld	s0,16(sp)
    800024f0:	64a2                	ld	s1,8(sp)
    800024f2:	6902                	ld	s2,0(sp)
    800024f4:	6105                	addi	sp,sp,32
    800024f6:	8082                	ret

00000000800024f8 <wait>:
{
    800024f8:	715d                	addi	sp,sp,-80
    800024fa:	e486                	sd	ra,72(sp)
    800024fc:	e0a2                	sd	s0,64(sp)
    800024fe:	fc26                	sd	s1,56(sp)
    80002500:	f84a                	sd	s2,48(sp)
    80002502:	f44e                	sd	s3,40(sp)
    80002504:	f052                	sd	s4,32(sp)
    80002506:	ec56                	sd	s5,24(sp)
    80002508:	e85a                	sd	s6,16(sp)
    8000250a:	e45e                	sd	s7,8(sp)
    8000250c:	e062                	sd	s8,0(sp)
    8000250e:	0880                	addi	s0,sp,80
    80002510:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	664080e7          	jalr	1636(ra) # 80001b76 <myproc>
    8000251a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000251c:	0000e517          	auipc	a0,0xe
    80002520:	71c50513          	addi	a0,a0,1820 # 80010c38 <wait_lock>
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	87c080e7          	jalr	-1924(ra) # 80000da0 <acquire>
    havekids = 0;
    8000252c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000252e:	4a15                	li	s4,5
        havekids = 1;
    80002530:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002532:	00014997          	auipc	s3,0x14
    80002536:	51e98993          	addi	s3,s3,1310 # 80016a50 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000253a:	0000ec17          	auipc	s8,0xe
    8000253e:	6fec0c13          	addi	s8,s8,1790 # 80010c38 <wait_lock>
    havekids = 0;
    80002542:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002544:	0000f497          	auipc	s1,0xf
    80002548:	b0c48493          	addi	s1,s1,-1268 # 80011050 <proc>
    8000254c:	a0bd                	j	800025ba <wait+0xc2>
          pid = pp->pid;
    8000254e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002552:	000b0e63          	beqz	s6,8000256e <wait+0x76>
    80002556:	4691                	li	a3,4
    80002558:	02c48613          	addi	a2,s1,44
    8000255c:	85da                	mv	a1,s6
    8000255e:	05093503          	ld	a0,80(s2)
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	2d0080e7          	jalr	720(ra) # 80001832 <copyout>
    8000256a:	02054563          	bltz	a0,80002594 <wait+0x9c>
          freeproc(pp);
    8000256e:	8526                	mv	a0,s1
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	7b8080e7          	jalr	1976(ra) # 80001d28 <freeproc>
          release(&pp->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	8da080e7          	jalr	-1830(ra) # 80000e54 <release>
          release(&wait_lock);
    80002582:	0000e517          	auipc	a0,0xe
    80002586:	6b650513          	addi	a0,a0,1718 # 80010c38 <wait_lock>
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	8ca080e7          	jalr	-1846(ra) # 80000e54 <release>
          return pid;
    80002592:	a0b5                	j	800025fe <wait+0x106>
            release(&pp->lock);
    80002594:	8526                	mv	a0,s1
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	8be080e7          	jalr	-1858(ra) # 80000e54 <release>
            release(&wait_lock);
    8000259e:	0000e517          	auipc	a0,0xe
    800025a2:	69a50513          	addi	a0,a0,1690 # 80010c38 <wait_lock>
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	8ae080e7          	jalr	-1874(ra) # 80000e54 <release>
            return -1;
    800025ae:	59fd                	li	s3,-1
    800025b0:	a0b9                	j	800025fe <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025b2:	16848493          	addi	s1,s1,360
    800025b6:	03348463          	beq	s1,s3,800025de <wait+0xe6>
      if(pp->parent == p){
    800025ba:	7c9c                	ld	a5,56(s1)
    800025bc:	ff279be3          	bne	a5,s2,800025b2 <wait+0xba>
        acquire(&pp->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	7de080e7          	jalr	2014(ra) # 80000da0 <acquire>
        if(pp->state == ZOMBIE){
    800025ca:	4c9c                	lw	a5,24(s1)
    800025cc:	f94781e3          	beq	a5,s4,8000254e <wait+0x56>
        release(&pp->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	fffff097          	auipc	ra,0xfffff
    800025d6:	882080e7          	jalr	-1918(ra) # 80000e54 <release>
        havekids = 1;
    800025da:	8756                	mv	a4,s5
    800025dc:	bfd9                	j	800025b2 <wait+0xba>
    if(!havekids || killed(p)){
    800025de:	c719                	beqz	a4,800025ec <wait+0xf4>
    800025e0:	854a                	mv	a0,s2
    800025e2:	00000097          	auipc	ra,0x0
    800025e6:	ee4080e7          	jalr	-284(ra) # 800024c6 <killed>
    800025ea:	c51d                	beqz	a0,80002618 <wait+0x120>
      release(&wait_lock);
    800025ec:	0000e517          	auipc	a0,0xe
    800025f0:	64c50513          	addi	a0,a0,1612 # 80010c38 <wait_lock>
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	860080e7          	jalr	-1952(ra) # 80000e54 <release>
      return -1;
    800025fc:	59fd                	li	s3,-1
}
    800025fe:	854e                	mv	a0,s3
    80002600:	60a6                	ld	ra,72(sp)
    80002602:	6406                	ld	s0,64(sp)
    80002604:	74e2                	ld	s1,56(sp)
    80002606:	7942                	ld	s2,48(sp)
    80002608:	79a2                	ld	s3,40(sp)
    8000260a:	7a02                	ld	s4,32(sp)
    8000260c:	6ae2                	ld	s5,24(sp)
    8000260e:	6b42                	ld	s6,16(sp)
    80002610:	6ba2                	ld	s7,8(sp)
    80002612:	6c02                	ld	s8,0(sp)
    80002614:	6161                	addi	sp,sp,80
    80002616:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002618:	85e2                	mv	a1,s8
    8000261a:	854a                	mv	a0,s2
    8000261c:	00000097          	auipc	ra,0x0
    80002620:	c02080e7          	jalr	-1022(ra) # 8000221e <sleep>
    havekids = 0;
    80002624:	bf39                	j	80002542 <wait+0x4a>

0000000080002626 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002626:	7179                	addi	sp,sp,-48
    80002628:	f406                	sd	ra,40(sp)
    8000262a:	f022                	sd	s0,32(sp)
    8000262c:	ec26                	sd	s1,24(sp)
    8000262e:	e84a                	sd	s2,16(sp)
    80002630:	e44e                	sd	s3,8(sp)
    80002632:	e052                	sd	s4,0(sp)
    80002634:	1800                	addi	s0,sp,48
    80002636:	84aa                	mv	s1,a0
    80002638:	892e                	mv	s2,a1
    8000263a:	89b2                	mv	s3,a2
    8000263c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	538080e7          	jalr	1336(ra) # 80001b76 <myproc>
  if(user_dst){
    80002646:	c08d                	beqz	s1,80002668 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002648:	86d2                	mv	a3,s4
    8000264a:	864e                	mv	a2,s3
    8000264c:	85ca                	mv	a1,s2
    8000264e:	6928                	ld	a0,80(a0)
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	1e2080e7          	jalr	482(ra) # 80001832 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002658:	70a2                	ld	ra,40(sp)
    8000265a:	7402                	ld	s0,32(sp)
    8000265c:	64e2                	ld	s1,24(sp)
    8000265e:	6942                	ld	s2,16(sp)
    80002660:	69a2                	ld	s3,8(sp)
    80002662:	6a02                	ld	s4,0(sp)
    80002664:	6145                	addi	sp,sp,48
    80002666:	8082                	ret
    memmove((char *)dst, src, len);
    80002668:	000a061b          	sext.w	a2,s4
    8000266c:	85ce                	mv	a1,s3
    8000266e:	854a                	mv	a0,s2
    80002670:	fffff097          	auipc	ra,0xfffff
    80002674:	888080e7          	jalr	-1912(ra) # 80000ef8 <memmove>
    return 0;
    80002678:	8526                	mv	a0,s1
    8000267a:	bff9                	j	80002658 <either_copyout+0x32>

000000008000267c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	e052                	sd	s4,0(sp)
    8000268a:	1800                	addi	s0,sp,48
    8000268c:	892a                	mv	s2,a0
    8000268e:	84ae                	mv	s1,a1
    80002690:	89b2                	mv	s3,a2
    80002692:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	4e2080e7          	jalr	1250(ra) # 80001b76 <myproc>
  if(user_src){
    8000269c:	c08d                	beqz	s1,800026be <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000269e:	86d2                	mv	a3,s4
    800026a0:	864e                	mv	a2,s3
    800026a2:	85ca                	mv	a1,s2
    800026a4:	6928                	ld	a0,80(a0)
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	218080e7          	jalr	536(ra) # 800018be <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026ae:	70a2                	ld	ra,40(sp)
    800026b0:	7402                	ld	s0,32(sp)
    800026b2:	64e2                	ld	s1,24(sp)
    800026b4:	6942                	ld	s2,16(sp)
    800026b6:	69a2                	ld	s3,8(sp)
    800026b8:	6a02                	ld	s4,0(sp)
    800026ba:	6145                	addi	sp,sp,48
    800026bc:	8082                	ret
    memmove(dst, (char*)src, len);
    800026be:	000a061b          	sext.w	a2,s4
    800026c2:	85ce                	mv	a1,s3
    800026c4:	854a                	mv	a0,s2
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	832080e7          	jalr	-1998(ra) # 80000ef8 <memmove>
    return 0;
    800026ce:	8526                	mv	a0,s1
    800026d0:	bff9                	j	800026ae <either_copyin+0x32>

00000000800026d2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026d2:	715d                	addi	sp,sp,-80
    800026d4:	e486                	sd	ra,72(sp)
    800026d6:	e0a2                	sd	s0,64(sp)
    800026d8:	fc26                	sd	s1,56(sp)
    800026da:	f84a                	sd	s2,48(sp)
    800026dc:	f44e                	sd	s3,40(sp)
    800026de:	f052                	sd	s4,32(sp)
    800026e0:	ec56                	sd	s5,24(sp)
    800026e2:	e85a                	sd	s6,16(sp)
    800026e4:	e45e                	sd	s7,8(sp)
    800026e6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026e8:	00006517          	auipc	a0,0x6
    800026ec:	9c050513          	addi	a0,a0,-1600 # 800080a8 <digits+0x68>
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	e98080e7          	jalr	-360(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026f8:	0000f497          	auipc	s1,0xf
    800026fc:	ab048493          	addi	s1,s1,-1360 # 800111a8 <proc+0x158>
    80002700:	00014917          	auipc	s2,0x14
    80002704:	4a890913          	addi	s2,s2,1192 # 80016ba8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002708:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000270a:	00006997          	auipc	s3,0x6
    8000270e:	bb698993          	addi	s3,s3,-1098 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002712:	00006a97          	auipc	s5,0x6
    80002716:	bb6a8a93          	addi	s5,s5,-1098 # 800082c8 <digits+0x288>
    printf("\n");
    8000271a:	00006a17          	auipc	s4,0x6
    8000271e:	98ea0a13          	addi	s4,s4,-1650 # 800080a8 <digits+0x68>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002722:	00006b97          	auipc	s7,0x6
    80002726:	be6b8b93          	addi	s7,s7,-1050 # 80008308 <states.0>
    8000272a:	a00d                	j	8000274c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000272c:	ed86a583          	lw	a1,-296(a3)
    80002730:	8556                	mv	a0,s5
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	e56080e7          	jalr	-426(ra) # 80000588 <printf>
    printf("\n");
    8000273a:	8552                	mv	a0,s4
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	e4c080e7          	jalr	-436(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002744:	16848493          	addi	s1,s1,360
    80002748:	03248163          	beq	s1,s2,8000276a <procdump+0x98>
    if(p->state == UNUSED)
    8000274c:	86a6                	mv	a3,s1
    8000274e:	ec04a783          	lw	a5,-320(s1)
    80002752:	dbed                	beqz	a5,80002744 <procdump+0x72>
      state = "???";
    80002754:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002756:	fcfb6be3          	bltu	s6,a5,8000272c <procdump+0x5a>
    8000275a:	1782                	slli	a5,a5,0x20
    8000275c:	9381                	srli	a5,a5,0x20
    8000275e:	078e                	slli	a5,a5,0x3
    80002760:	97de                	add	a5,a5,s7
    80002762:	6390                	ld	a2,0(a5)
    80002764:	f661                	bnez	a2,8000272c <procdump+0x5a>
      state = "???";
    80002766:	864e                	mv	a2,s3
    80002768:	b7d1                	j	8000272c <procdump+0x5a>
  }
}
    8000276a:	60a6                	ld	ra,72(sp)
    8000276c:	6406                	ld	s0,64(sp)
    8000276e:	74e2                	ld	s1,56(sp)
    80002770:	7942                	ld	s2,48(sp)
    80002772:	79a2                	ld	s3,40(sp)
    80002774:	7a02                	ld	s4,32(sp)
    80002776:	6ae2                	ld	s5,24(sp)
    80002778:	6b42                	ld	s6,16(sp)
    8000277a:	6ba2                	ld	s7,8(sp)
    8000277c:	6161                	addi	sp,sp,80
    8000277e:	8082                	ret

0000000080002780 <nproc>:


uint64
nproc(void)
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	1800                	addi	s0,sp,48
  uint64 counter = 0;
  struct proc *p;
  for(p = proc;p<&proc[NPROC];++p){
    8000278e:	0000f497          	auipc	s1,0xf
    80002792:	8c248493          	addi	s1,s1,-1854 # 80011050 <proc>
  uint64 counter = 0;
    80002796:	4901                	li	s2,0
  for(p = proc;p<&proc[NPROC];++p){
    80002798:	00014997          	auipc	s3,0x14
    8000279c:	2b898993          	addi	s3,s3,696 # 80016a50 <tickslock>
    acquire(&p->lock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	5fe080e7          	jalr	1534(ra) # 80000da0 <acquire>
    if(p->state != UNUSED){
    800027aa:	4c9c                	lw	a5,24(s1)
      ++counter;
    800027ac:	00f037b3          	snez	a5,a5
    800027b0:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	6a0080e7          	jalr	1696(ra) # 80000e54 <release>
  for(p = proc;p<&proc[NPROC];++p){
    800027bc:	16848493          	addi	s1,s1,360
    800027c0:	ff3490e3          	bne	s1,s3,800027a0 <nproc+0x20>
  }
  return counter;
}
    800027c4:	854a                	mv	a0,s2
    800027c6:	70a2                	ld	ra,40(sp)
    800027c8:	7402                	ld	s0,32(sp)
    800027ca:	64e2                	ld	s1,24(sp)
    800027cc:	6942                	ld	s2,16(sp)
    800027ce:	69a2                	ld	s3,8(sp)
    800027d0:	6145                	addi	sp,sp,48
    800027d2:	8082                	ret

00000000800027d4 <swtch>:
    800027d4:	00153023          	sd	ra,0(a0)
    800027d8:	00253423          	sd	sp,8(a0)
    800027dc:	e900                	sd	s0,16(a0)
    800027de:	ed04                	sd	s1,24(a0)
    800027e0:	03253023          	sd	s2,32(a0)
    800027e4:	03353423          	sd	s3,40(a0)
    800027e8:	03453823          	sd	s4,48(a0)
    800027ec:	03553c23          	sd	s5,56(a0)
    800027f0:	05653023          	sd	s6,64(a0)
    800027f4:	05753423          	sd	s7,72(a0)
    800027f8:	05853823          	sd	s8,80(a0)
    800027fc:	05953c23          	sd	s9,88(a0)
    80002800:	07a53023          	sd	s10,96(a0)
    80002804:	07b53423          	sd	s11,104(a0)
    80002808:	0005b083          	ld	ra,0(a1)
    8000280c:	0085b103          	ld	sp,8(a1)
    80002810:	6980                	ld	s0,16(a1)
    80002812:	6d84                	ld	s1,24(a1)
    80002814:	0205b903          	ld	s2,32(a1)
    80002818:	0285b983          	ld	s3,40(a1)
    8000281c:	0305ba03          	ld	s4,48(a1)
    80002820:	0385ba83          	ld	s5,56(a1)
    80002824:	0405bb03          	ld	s6,64(a1)
    80002828:	0485bb83          	ld	s7,72(a1)
    8000282c:	0505bc03          	ld	s8,80(a1)
    80002830:	0585bc83          	ld	s9,88(a1)
    80002834:	0605bd03          	ld	s10,96(a1)
    80002838:	0685bd83          	ld	s11,104(a1)
    8000283c:	8082                	ret

000000008000283e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000283e:	1141                	addi	sp,sp,-16
    80002840:	e406                	sd	ra,8(sp)
    80002842:	e022                	sd	s0,0(sp)
    80002844:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002846:	00006597          	auipc	a1,0x6
    8000284a:	af258593          	addi	a1,a1,-1294 # 80008338 <states.0+0x30>
    8000284e:	00014517          	auipc	a0,0x14
    80002852:	20250513          	addi	a0,a0,514 # 80016a50 <tickslock>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	4ba080e7          	jalr	1210(ra) # 80000d10 <initlock>
}
    8000285e:	60a2                	ld	ra,8(sp)
    80002860:	6402                	ld	s0,0(sp)
    80002862:	0141                	addi	sp,sp,16
    80002864:	8082                	ret

0000000080002866 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002866:	1141                	addi	sp,sp,-16
    80002868:	e422                	sd	s0,8(sp)
    8000286a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000286c:	00003797          	auipc	a5,0x3
    80002870:	5a478793          	addi	a5,a5,1444 # 80005e10 <kernelvec>
    80002874:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002878:	6422                	ld	s0,8(sp)
    8000287a:	0141                	addi	sp,sp,16
    8000287c:	8082                	ret

000000008000287e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000287e:	1141                	addi	sp,sp,-16
    80002880:	e406                	sd	ra,8(sp)
    80002882:	e022                	sd	s0,0(sp)
    80002884:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	2f0080e7          	jalr	752(ra) # 80001b76 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002892:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002894:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002898:	00004617          	auipc	a2,0x4
    8000289c:	76860613          	addi	a2,a2,1896 # 80007000 <_trampoline>
    800028a0:	00004697          	auipc	a3,0x4
    800028a4:	76068693          	addi	a3,a3,1888 # 80007000 <_trampoline>
    800028a8:	8e91                	sub	a3,a3,a2
    800028aa:	040007b7          	lui	a5,0x4000
    800028ae:	17fd                	addi	a5,a5,-1
    800028b0:	07b2                	slli	a5,a5,0xc
    800028b2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028ba:	180026f3          	csrr	a3,satp
    800028be:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c0:	6d38                	ld	a4,88(a0)
    800028c2:	6134                	ld	a3,64(a0)
    800028c4:	6585                	lui	a1,0x1
    800028c6:	96ae                	add	a3,a3,a1
    800028c8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028ca:	6d38                	ld	a4,88(a0)
    800028cc:	00000697          	auipc	a3,0x0
    800028d0:	13068693          	addi	a3,a3,304 # 800029fc <usertrap>
    800028d4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028d6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028d8:	8692                	mv	a3,tp
    800028da:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028dc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ee:	6f18                	ld	a4,24(a4)
    800028f0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f4:	6928                	ld	a0,80(a0)
    800028f6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028f8:	00004717          	auipc	a4,0x4
    800028fc:	7a470713          	addi	a4,a4,1956 # 8000709c <userret>
    80002900:	8f11                	sub	a4,a4,a2
    80002902:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002904:	577d                	li	a4,-1
    80002906:	177e                	slli	a4,a4,0x3f
    80002908:	8d59                	or	a0,a0,a4
    8000290a:	9782                	jalr	a5
}
    8000290c:	60a2                	ld	ra,8(sp)
    8000290e:	6402                	ld	s0,0(sp)
    80002910:	0141                	addi	sp,sp,16
    80002912:	8082                	ret

0000000080002914 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002914:	1101                	addi	sp,sp,-32
    80002916:	ec06                	sd	ra,24(sp)
    80002918:	e822                	sd	s0,16(sp)
    8000291a:	e426                	sd	s1,8(sp)
    8000291c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000291e:	00014497          	auipc	s1,0x14
    80002922:	13248493          	addi	s1,s1,306 # 80016a50 <tickslock>
    80002926:	8526                	mv	a0,s1
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	478080e7          	jalr	1144(ra) # 80000da0 <acquire>
  ticks++;
    80002930:	00006517          	auipc	a0,0x6
    80002934:	06050513          	addi	a0,a0,96 # 80008990 <ticks>
    80002938:	411c                	lw	a5,0(a0)
    8000293a:	2785                	addiw	a5,a5,1
    8000293c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	944080e7          	jalr	-1724(ra) # 80002282 <wakeup>
  release(&tickslock);
    80002946:	8526                	mv	a0,s1
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	50c080e7          	jalr	1292(ra) # 80000e54 <release>
}
    80002950:	60e2                	ld	ra,24(sp)
    80002952:	6442                	ld	s0,16(sp)
    80002954:	64a2                	ld	s1,8(sp)
    80002956:	6105                	addi	sp,sp,32
    80002958:	8082                	ret

000000008000295a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000295a:	1101                	addi	sp,sp,-32
    8000295c:	ec06                	sd	ra,24(sp)
    8000295e:	e822                	sd	s0,16(sp)
    80002960:	e426                	sd	s1,8(sp)
    80002962:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002964:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002968:	00074d63          	bltz	a4,80002982 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000296c:	57fd                	li	a5,-1
    8000296e:	17fe                	slli	a5,a5,0x3f
    80002970:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002972:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002974:	06f70363          	beq	a4,a5,800029da <devintr+0x80>
  }
}
    80002978:	60e2                	ld	ra,24(sp)
    8000297a:	6442                	ld	s0,16(sp)
    8000297c:	64a2                	ld	s1,8(sp)
    8000297e:	6105                	addi	sp,sp,32
    80002980:	8082                	ret
     (scause & 0xff) == 9){
    80002982:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002986:	46a5                	li	a3,9
    80002988:	fed792e3          	bne	a5,a3,8000296c <devintr+0x12>
    int irq = plic_claim();
    8000298c:	00003097          	auipc	ra,0x3
    80002990:	58c080e7          	jalr	1420(ra) # 80005f18 <plic_claim>
    80002994:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002996:	47a9                	li	a5,10
    80002998:	02f50763          	beq	a0,a5,800029c6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000299c:	4785                	li	a5,1
    8000299e:	02f50963          	beq	a0,a5,800029d0 <devintr+0x76>
    return 1;
    800029a2:	4505                	li	a0,1
    } else if(irq){
    800029a4:	d8f1                	beqz	s1,80002978 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029a6:	85a6                	mv	a1,s1
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	99850513          	addi	a0,a0,-1640 # 80008340 <states.0+0x38>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bd8080e7          	jalr	-1064(ra) # 80000588 <printf>
      plic_complete(irq);
    800029b8:	8526                	mv	a0,s1
    800029ba:	00003097          	auipc	ra,0x3
    800029be:	582080e7          	jalr	1410(ra) # 80005f3c <plic_complete>
    return 1;
    800029c2:	4505                	li	a0,1
    800029c4:	bf55                	j	80002978 <devintr+0x1e>
      uartintr();
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	fd4080e7          	jalr	-44(ra) # 8000099a <uartintr>
    800029ce:	b7ed                	j	800029b8 <devintr+0x5e>
      virtio_disk_intr();
    800029d0:	00004097          	auipc	ra,0x4
    800029d4:	a38080e7          	jalr	-1480(ra) # 80006408 <virtio_disk_intr>
    800029d8:	b7c5                	j	800029b8 <devintr+0x5e>
    if(cpuid() == 0){
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	170080e7          	jalr	368(ra) # 80001b4a <cpuid>
    800029e2:	c901                	beqz	a0,800029f2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029e4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ea:	14479073          	csrw	sip,a5
    return 2;
    800029ee:	4509                	li	a0,2
    800029f0:	b761                	j	80002978 <devintr+0x1e>
      clockintr();
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	f22080e7          	jalr	-222(ra) # 80002914 <clockintr>
    800029fa:	b7ed                	j	800029e4 <devintr+0x8a>

00000000800029fc <usertrap>:
{
    800029fc:	1101                	addi	sp,sp,-32
    800029fe:	ec06                	sd	ra,24(sp)
    80002a00:	e822                	sd	s0,16(sp)
    80002a02:	e426                	sd	s1,8(sp)
    80002a04:	e04a                	sd	s2,0(sp)
    80002a06:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a0c:	1007f793          	andi	a5,a5,256
    80002a10:	e3b1                	bnez	a5,80002a54 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a12:	00003797          	auipc	a5,0x3
    80002a16:	3fe78793          	addi	a5,a5,1022 # 80005e10 <kernelvec>
    80002a1a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	158080e7          	jalr	344(ra) # 80001b76 <myproc>
    80002a26:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a28:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2a:	14102773          	csrr	a4,sepc
    80002a2e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a30:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a34:	47a1                	li	a5,8
    80002a36:	02f70763          	beq	a4,a5,80002a64 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	f20080e7          	jalr	-224(ra) # 8000295a <devintr>
    80002a42:	892a                	mv	s2,a0
    80002a44:	c151                	beqz	a0,80002ac8 <usertrap+0xcc>
  if(killed(p))
    80002a46:	8526                	mv	a0,s1
    80002a48:	00000097          	auipc	ra,0x0
    80002a4c:	a7e080e7          	jalr	-1410(ra) # 800024c6 <killed>
    80002a50:	c929                	beqz	a0,80002aa2 <usertrap+0xa6>
    80002a52:	a099                	j	80002a98 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	90c50513          	addi	a0,a0,-1780 # 80008360 <states.0+0x58>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    if(killed(p))
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	a62080e7          	jalr	-1438(ra) # 800024c6 <killed>
    80002a6c:	e921                	bnez	a0,80002abc <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a6e:	6cb8                	ld	a4,88(s1)
    80002a70:	6f1c                	ld	a5,24(a4)
    80002a72:	0791                	addi	a5,a5,4
    80002a74:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7e:	10079073          	csrw	sstatus,a5
    syscall();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	2d4080e7          	jalr	724(ra) # 80002d56 <syscall>
  if(killed(p))
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	a3a080e7          	jalr	-1478(ra) # 800024c6 <killed>
    80002a94:	c911                	beqz	a0,80002aa8 <usertrap+0xac>
    80002a96:	4901                	li	s2,0
    exit(-1);
    80002a98:	557d                	li	a0,-1
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	8b8080e7          	jalr	-1864(ra) # 80002352 <exit>
  if(which_dev == 2)
    80002aa2:	4789                	li	a5,2
    80002aa4:	04f90f63          	beq	s2,a5,80002b02 <usertrap+0x106>
  usertrapret();
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	dd6080e7          	jalr	-554(ra) # 8000287e <usertrapret>
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6902                	ld	s2,0(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret
      exit(-1);
    80002abc:	557d                	li	a0,-1
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	894080e7          	jalr	-1900(ra) # 80002352 <exit>
    80002ac6:	b765                	j	80002a6e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002acc:	5890                	lw	a2,48(s1)
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	8b250513          	addi	a0,a0,-1870 # 80008380 <states.0+0x78>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ab2080e7          	jalr	-1358(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ade:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	8ca50513          	addi	a0,a0,-1846 # 800083b0 <states.0+0xa8>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9a080e7          	jalr	-1382(ra) # 80000588 <printf>
    setkilled(p);
    80002af6:	8526                	mv	a0,s1
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	9a2080e7          	jalr	-1630(ra) # 8000249a <setkilled>
    80002b00:	b769                	j	80002a8a <usertrap+0x8e>
    yield();
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	6e0080e7          	jalr	1760(ra) # 800021e2 <yield>
    80002b0a:	bf79                	j	80002aa8 <usertrap+0xac>

0000000080002b0c <kerneltrap>:
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b22:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b26:	1004f793          	andi	a5,s1,256
    80002b2a:	cb85                	beqz	a5,80002b5a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b30:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b32:	ef85                	bnez	a5,80002b6a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	e26080e7          	jalr	-474(ra) # 8000295a <devintr>
    80002b3c:	cd1d                	beqz	a0,80002b7a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b3e:	4789                	li	a5,2
    80002b40:	06f50a63          	beq	a0,a5,80002bb4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b44:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b48:	10049073          	csrw	sstatus,s1
}
    80002b4c:	70a2                	ld	ra,40(sp)
    80002b4e:	7402                	ld	s0,32(sp)
    80002b50:	64e2                	ld	s1,24(sp)
    80002b52:	6942                	ld	s2,16(sp)
    80002b54:	69a2                	ld	s3,8(sp)
    80002b56:	6145                	addi	sp,sp,48
    80002b58:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	87650513          	addi	a0,a0,-1930 # 800083d0 <states.0+0xc8>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	9dc080e7          	jalr	-1572(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	88e50513          	addi	a0,a0,-1906 # 800083f8 <states.0+0xf0>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	9cc080e7          	jalr	-1588(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b7a:	85ce                	mv	a1,s3
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	89c50513          	addi	a0,a0,-1892 # 80008418 <states.0+0x110>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a04080e7          	jalr	-1532(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b90:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	89450513          	addi	a0,a0,-1900 # 80008428 <states.0+0x120>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9ec080e7          	jalr	-1556(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	89c50513          	addi	a0,a0,-1892 # 80008440 <states.0+0x138>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	992080e7          	jalr	-1646(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	fc2080e7          	jalr	-62(ra) # 80001b76 <myproc>
    80002bbc:	d541                	beqz	a0,80002b44 <kerneltrap+0x38>
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	fb8080e7          	jalr	-72(ra) # 80001b76 <myproc>
    80002bc6:	4d18                	lw	a4,24(a0)
    80002bc8:	4791                	li	a5,4
    80002bca:	f6f71de3          	bne	a4,a5,80002b44 <kerneltrap+0x38>
    yield();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	614080e7          	jalr	1556(ra) # 800021e2 <yield>
    80002bd6:	b7bd                	j	80002b44 <kerneltrap+0x38>

0000000080002bd8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	1000                	addi	s0,sp,32
    80002be2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	f92080e7          	jalr	-110(ra) # 80001b76 <myproc>
  switch (n) {
    80002bec:	4795                	li	a5,5
    80002bee:	0497e163          	bltu	a5,s1,80002c30 <argraw+0x58>
    80002bf2:	048a                	slli	s1,s1,0x2
    80002bf4:	00006717          	auipc	a4,0x6
    80002bf8:	88470713          	addi	a4,a4,-1916 # 80008478 <states.0+0x170>
    80002bfc:	94ba                	add	s1,s1,a4
    80002bfe:	409c                	lw	a5,0(s1)
    80002c00:	97ba                	add	a5,a5,a4
    80002c02:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c04:	6d3c                	ld	a5,88(a0)
    80002c06:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret
    return p->trapframe->a1;
    80002c12:	6d3c                	ld	a5,88(a0)
    80002c14:	7fa8                	ld	a0,120(a5)
    80002c16:	bfcd                	j	80002c08 <argraw+0x30>
    return p->trapframe->a2;
    80002c18:	6d3c                	ld	a5,88(a0)
    80002c1a:	63c8                	ld	a0,128(a5)
    80002c1c:	b7f5                	j	80002c08 <argraw+0x30>
    return p->trapframe->a3;
    80002c1e:	6d3c                	ld	a5,88(a0)
    80002c20:	67c8                	ld	a0,136(a5)
    80002c22:	b7dd                	j	80002c08 <argraw+0x30>
    return p->trapframe->a4;
    80002c24:	6d3c                	ld	a5,88(a0)
    80002c26:	6bc8                	ld	a0,144(a5)
    80002c28:	b7c5                	j	80002c08 <argraw+0x30>
    return p->trapframe->a5;
    80002c2a:	6d3c                	ld	a5,88(a0)
    80002c2c:	6fc8                	ld	a0,152(a5)
    80002c2e:	bfe9                	j	80002c08 <argraw+0x30>
  panic("argraw");
    80002c30:	00006517          	auipc	a0,0x6
    80002c34:	82050513          	addi	a0,a0,-2016 # 80008450 <states.0+0x148>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	906080e7          	jalr	-1786(ra) # 8000053e <panic>

0000000080002c40 <fetchaddr>:
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	e04a                	sd	s2,0(sp)
    80002c4a:	1000                	addi	s0,sp,32
    80002c4c:	84aa                	mv	s1,a0
    80002c4e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	f26080e7          	jalr	-218(ra) # 80001b76 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c58:	653c                	ld	a5,72(a0)
    80002c5a:	02f4f863          	bgeu	s1,a5,80002c8a <fetchaddr+0x4a>
    80002c5e:	00848713          	addi	a4,s1,8
    80002c62:	02e7e663          	bltu	a5,a4,80002c8e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c66:	46a1                	li	a3,8
    80002c68:	8626                	mv	a2,s1
    80002c6a:	85ca                	mv	a1,s2
    80002c6c:	6928                	ld	a0,80(a0)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	c50080e7          	jalr	-944(ra) # 800018be <copyin>
    80002c76:	00a03533          	snez	a0,a0
    80002c7a:	40a00533          	neg	a0,a0
}
    80002c7e:	60e2                	ld	ra,24(sp)
    80002c80:	6442                	ld	s0,16(sp)
    80002c82:	64a2                	ld	s1,8(sp)
    80002c84:	6902                	ld	s2,0(sp)
    80002c86:	6105                	addi	sp,sp,32
    80002c88:	8082                	ret
    return -1;
    80002c8a:	557d                	li	a0,-1
    80002c8c:	bfcd                	j	80002c7e <fetchaddr+0x3e>
    80002c8e:	557d                	li	a0,-1
    80002c90:	b7fd                	j	80002c7e <fetchaddr+0x3e>

0000000080002c92 <fetchstr>:
{
    80002c92:	7179                	addi	sp,sp,-48
    80002c94:	f406                	sd	ra,40(sp)
    80002c96:	f022                	sd	s0,32(sp)
    80002c98:	ec26                	sd	s1,24(sp)
    80002c9a:	e84a                	sd	s2,16(sp)
    80002c9c:	e44e                	sd	s3,8(sp)
    80002c9e:	1800                	addi	s0,sp,48
    80002ca0:	892a                	mv	s2,a0
    80002ca2:	84ae                	mv	s1,a1
    80002ca4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	ed0080e7          	jalr	-304(ra) # 80001b76 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cae:	86ce                	mv	a3,s3
    80002cb0:	864a                	mv	a2,s2
    80002cb2:	85a6                	mv	a1,s1
    80002cb4:	6928                	ld	a0,80(a0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	c96080e7          	jalr	-874(ra) # 8000194c <copyinstr>
    80002cbe:	00054e63          	bltz	a0,80002cda <fetchstr+0x48>
  return strlen(buf);
    80002cc2:	8526                	mv	a0,s1
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	354080e7          	jalr	852(ra) # 80001018 <strlen>
}
    80002ccc:	70a2                	ld	ra,40(sp)
    80002cce:	7402                	ld	s0,32(sp)
    80002cd0:	64e2                	ld	s1,24(sp)
    80002cd2:	6942                	ld	s2,16(sp)
    80002cd4:	69a2                	ld	s3,8(sp)
    80002cd6:	6145                	addi	sp,sp,48
    80002cd8:	8082                	ret
    return -1;
    80002cda:	557d                	li	a0,-1
    80002cdc:	bfc5                	j	80002ccc <fetchstr+0x3a>

0000000080002cde <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	e426                	sd	s1,8(sp)
    80002ce6:	1000                	addi	s0,sp,32
    80002ce8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cea:	00000097          	auipc	ra,0x0
    80002cee:	eee080e7          	jalr	-274(ra) # 80002bd8 <argraw>
    80002cf2:	c088                	sw	a0,0(s1)
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	ece080e7          	jalr	-306(ra) # 80002bd8 <argraw>
    80002d12:	e088                	sd	a0,0(s1)
}
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	64a2                	ld	s1,8(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d1e:	7179                	addi	sp,sp,-48
    80002d20:	f406                	sd	ra,40(sp)
    80002d22:	f022                	sd	s0,32(sp)
    80002d24:	ec26                	sd	s1,24(sp)
    80002d26:	e84a                	sd	s2,16(sp)
    80002d28:	1800                	addi	s0,sp,48
    80002d2a:	84ae                	mv	s1,a1
    80002d2c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d2e:	fd840593          	addi	a1,s0,-40
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	fcc080e7          	jalr	-52(ra) # 80002cfe <argaddr>
  return fetchstr(addr, buf, max);
    80002d3a:	864a                	mv	a2,s2
    80002d3c:	85a6                	mv	a1,s1
    80002d3e:	fd843503          	ld	a0,-40(s0)
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	f50080e7          	jalr	-176(ra) # 80002c92 <fetchstr>
}
    80002d4a:	70a2                	ld	ra,40(sp)
    80002d4c:	7402                	ld	s0,32(sp)
    80002d4e:	64e2                	ld	s1,24(sp)
    80002d50:	6942                	ld	s2,16(sp)
    80002d52:	6145                	addi	sp,sp,48
    80002d54:	8082                	ret

0000000080002d56 <syscall>:



void
syscall(void)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	e16080e7          	jalr	-490(ra) # 80001b76 <myproc>
    80002d68:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d6a:	6d3c                	ld	a5,88(a0)
    80002d6c:	77dc                	ld	a5,168(a5)
    80002d6e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d72:	37fd                	addiw	a5,a5,-1
    80002d74:	4759                	li	a4,22
    80002d76:	00f76f63          	bltu	a4,a5,80002d94 <syscall+0x3e>
    80002d7a:	00369713          	slli	a4,a3,0x3
    80002d7e:	00005797          	auipc	a5,0x5
    80002d82:	71278793          	addi	a5,a5,1810 # 80008490 <syscalls>
    80002d86:	97ba                	add	a5,a5,a4
    80002d88:	639c                	ld	a5,0(a5)
    80002d8a:	c789                	beqz	a5,80002d94 <syscall+0x3e>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    uint64 ret = syscalls[num]();
    80002d8c:	9782                	jalr	a5
    p->trapframe->a0 = ret;
    80002d8e:	6cbc                	ld	a5,88(s1)
    80002d90:	fba8                	sd	a0,112(a5)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d92:	a839                	j	80002db0 <syscall+0x5a>

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d94:	15848613          	addi	a2,s1,344
    80002d98:	588c                	lw	a1,48(s1)
    80002d9a:	00005517          	auipc	a0,0x5
    80002d9e:	6be50513          	addi	a0,a0,1726 # 80008458 <states.0+0x150>
    80002da2:	ffffd097          	auipc	ra,0xffffd
    80002da6:	7e6080e7          	jalr	2022(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002daa:	6cbc                	ld	a5,88(s1)
    80002dac:	577d                	li	a4,-1
    80002dae:	fbb8                	sd	a4,112(a5)
  }
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dc2:	fec40593          	addi	a1,s0,-20
    80002dc6:	4501                	li	a0,0
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	f16080e7          	jalr	-234(ra) # 80002cde <argint>
  exit(n);
    80002dd0:	fec42503          	lw	a0,-20(s0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	57e080e7          	jalr	1406(ra) # 80002352 <exit>
  return 0;  // not reached
}
    80002ddc:	4501                	li	a0,0
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	d88080e7          	jalr	-632(ra) # 80001b76 <myproc>
}
    80002df6:	5908                	lw	a0,48(a0)
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	addi	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <sys_fork>:

uint64
sys_fork(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e406                	sd	ra,8(sp)
    80002e04:	e022                	sd	s0,0(sp)
    80002e06:	0800                	addi	s0,sp,16
  return fork();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	124080e7          	jalr	292(ra) # 80001f2c <fork>
}
    80002e10:	60a2                	ld	ra,8(sp)
    80002e12:	6402                	ld	s0,0(sp)
    80002e14:	0141                	addi	sp,sp,16
    80002e16:	8082                	ret

0000000080002e18 <sys_wait>:

uint64
sys_wait(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e20:	fe840593          	addi	a1,s0,-24
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	ed8080e7          	jalr	-296(ra) # 80002cfe <argaddr>
  return wait(p);
    80002e2e:	fe843503          	ld	a0,-24(s0)
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	6c6080e7          	jalr	1734(ra) # 800024f8 <wait>
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret

0000000080002e42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e42:	7179                	addi	sp,sp,-48
    80002e44:	f406                	sd	ra,40(sp)
    80002e46:	f022                	sd	s0,32(sp)
    80002e48:	ec26                	sd	s1,24(sp)
    80002e4a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e4c:	fdc40593          	addi	a1,s0,-36
    80002e50:	4501                	li	a0,0
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	e8c080e7          	jalr	-372(ra) # 80002cde <argint>
  addr = myproc()->sz;
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	d1c080e7          	jalr	-740(ra) # 80001b76 <myproc>
    80002e62:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e64:	fdc42503          	lw	a0,-36(s0)
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	068080e7          	jalr	104(ra) # 80001ed0 <growproc>
    80002e70:	00054863          	bltz	a0,80002e80 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e74:	8526                	mv	a0,s1
    80002e76:	70a2                	ld	ra,40(sp)
    80002e78:	7402                	ld	s0,32(sp)
    80002e7a:	64e2                	ld	s1,24(sp)
    80002e7c:	6145                	addi	sp,sp,48
    80002e7e:	8082                	ret
    return -1;
    80002e80:	54fd                	li	s1,-1
    80002e82:	bfcd                	j	80002e74 <sys_sbrk+0x32>

0000000080002e84 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e84:	7139                	addi	sp,sp,-64
    80002e86:	fc06                	sd	ra,56(sp)
    80002e88:	f822                	sd	s0,48(sp)
    80002e8a:	f426                	sd	s1,40(sp)
    80002e8c:	f04a                	sd	s2,32(sp)
    80002e8e:	ec4e                	sd	s3,24(sp)
    80002e90:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e92:	fcc40593          	addi	a1,s0,-52
    80002e96:	4501                	li	a0,0
    80002e98:	00000097          	auipc	ra,0x0
    80002e9c:	e46080e7          	jalr	-442(ra) # 80002cde <argint>
  acquire(&tickslock);
    80002ea0:	00014517          	auipc	a0,0x14
    80002ea4:	bb050513          	addi	a0,a0,-1104 # 80016a50 <tickslock>
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	ef8080e7          	jalr	-264(ra) # 80000da0 <acquire>
  ticks0 = ticks;
    80002eb0:	00006917          	auipc	s2,0x6
    80002eb4:	ae092903          	lw	s2,-1312(s2) # 80008990 <ticks>
  while(ticks - ticks0 < n){
    80002eb8:	fcc42783          	lw	a5,-52(s0)
    80002ebc:	cf9d                	beqz	a5,80002efa <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ebe:	00014997          	auipc	s3,0x14
    80002ec2:	b9298993          	addi	s3,s3,-1134 # 80016a50 <tickslock>
    80002ec6:	00006497          	auipc	s1,0x6
    80002eca:	aca48493          	addi	s1,s1,-1334 # 80008990 <ticks>
    if(killed(myproc())){
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	ca8080e7          	jalr	-856(ra) # 80001b76 <myproc>
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	5f0080e7          	jalr	1520(ra) # 800024c6 <killed>
    80002ede:	ed15                	bnez	a0,80002f1a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ee0:	85ce                	mv	a1,s3
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	33a080e7          	jalr	826(ra) # 8000221e <sleep>
  while(ticks - ticks0 < n){
    80002eec:	409c                	lw	a5,0(s1)
    80002eee:	412787bb          	subw	a5,a5,s2
    80002ef2:	fcc42703          	lw	a4,-52(s0)
    80002ef6:	fce7ece3          	bltu	a5,a4,80002ece <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002efa:	00014517          	auipc	a0,0x14
    80002efe:	b5650513          	addi	a0,a0,-1194 # 80016a50 <tickslock>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	f52080e7          	jalr	-174(ra) # 80000e54 <release>
  return 0;
    80002f0a:	4501                	li	a0,0
}
    80002f0c:	70e2                	ld	ra,56(sp)
    80002f0e:	7442                	ld	s0,48(sp)
    80002f10:	74a2                	ld	s1,40(sp)
    80002f12:	7902                	ld	s2,32(sp)
    80002f14:	69e2                	ld	s3,24(sp)
    80002f16:	6121                	addi	sp,sp,64
    80002f18:	8082                	ret
      release(&tickslock);
    80002f1a:	00014517          	auipc	a0,0x14
    80002f1e:	b3650513          	addi	a0,a0,-1226 # 80016a50 <tickslock>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	f32080e7          	jalr	-206(ra) # 80000e54 <release>
      return -1;
    80002f2a:	557d                	li	a0,-1
    80002f2c:	b7c5                	j	80002f0c <sys_sleep+0x88>

0000000080002f2e <sys_kill>:

uint64
sys_kill(void)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f36:	fec40593          	addi	a1,s0,-20
    80002f3a:	4501                	li	a0,0
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	da2080e7          	jalr	-606(ra) # 80002cde <argint>
  return kill(pid);
    80002f44:	fec42503          	lw	a0,-20(s0)
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	4e0080e7          	jalr	1248(ra) # 80002428 <kill>
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret

0000000080002f58 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f62:	00014517          	auipc	a0,0x14
    80002f66:	aee50513          	addi	a0,a0,-1298 # 80016a50 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	e36080e7          	jalr	-458(ra) # 80000da0 <acquire>
  xticks = ticks;
    80002f72:	00006497          	auipc	s1,0x6
    80002f76:	a1e4a483          	lw	s1,-1506(s1) # 80008990 <ticks>
  release(&tickslock);
    80002f7a:	00014517          	auipc	a0,0x14
    80002f7e:	ad650513          	addi	a0,a0,-1322 # 80016a50 <tickslock>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	ed2080e7          	jalr	-302(ra) # 80000e54 <release>
  return xticks;
}
    80002f8a:	02049513          	slli	a0,s1,0x20
    80002f8e:	9101                	srli	a0,a0,0x20
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	64a2                	ld	s1,8(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <sys_getprocs>:

uint64
sys_getprocs(void)
{
    80002f9a:	1141                	addi	sp,sp,-16
    80002f9c:	e406                	sd	ra,8(sp)
    80002f9e:	e022                	sd	s0,0(sp)
    80002fa0:	0800                	addi	s0,sp,16
  return nproc();
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	7de080e7          	jalr	2014(ra) # 80002780 <nproc>
}
    80002faa:	60a2                	ld	ra,8(sp)
    80002fac:	6402                	ld	s0,0(sp)
    80002fae:	0141                	addi	sp,sp,16
    80002fb0:	8082                	ret

0000000080002fb2 <sys_heap_demo>:

uint64 
sys_heap_demo(void) {
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
    void *a = malloc(100);
    80002fbc:	06400513          	li	a0,100
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	bf8080e7          	jalr	-1032(ra) # 80000bb8 <malloc>
    80002fc8:	84aa                	mv	s1,a0
    printf("Allocated 100 bytes at %p\n", a);
    80002fca:	85aa                	mv	a1,a0
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	58450513          	addi	a0,a0,1412 # 80008550 <syscalls+0xc0>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	5b4080e7          	jalr	1460(ra) # 80000588 <printf>
    printheap();
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	cd6080e7          	jalr	-810(ra) # 80000cb2 <printheap>
    void *c = malloc(50);
    80002fe4:	03200513          	li	a0,50
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	bd0080e7          	jalr	-1072(ra) # 80000bb8 <malloc>
    80002ff0:	85aa                	mv	a1,a0
    printf("Allocated 50 bytes at %p\n", c);
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	57e50513          	addi	a0,a0,1406 # 80008570 <syscalls+0xe0>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58e080e7          	jalr	1422(ra) # 80000588 <printf>
    printheap();
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	cb0080e7          	jalr	-848(ra) # 80000cb2 <printheap>
    free(a);
    8000300a:	8526                	mv	a0,s1
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	c2e080e7          	jalr	-978(ra) # 80000c3a <free>
    printf("Freed 100 bytes from %p\n", a);
    80003014:	85a6                	mv	a1,s1
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	57a50513          	addi	a0,a0,1402 # 80008590 <syscalls+0x100>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	56a080e7          	jalr	1386(ra) # 80000588 <printf>
    printheap();
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	c8c080e7          	jalr	-884(ra) # 80000cb2 <printheap>


    // free(c);
    // printf("Freed 50 bytes from %p\n", c);
    // printheap();
    void *b = malloc(50);
    8000302e:	03200513          	li	a0,50
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	b86080e7          	jalr	-1146(ra) # 80000bb8 <malloc>
    8000303a:	85aa                	mv	a1,a0
    printf("Allocated 50 bytes at %p\n", b);
    8000303c:	00005517          	auipc	a0,0x5
    80003040:	53450513          	addi	a0,a0,1332 # 80008570 <syscalls+0xe0>
    80003044:	ffffd097          	auipc	ra,0xffffd
    80003048:	544080e7          	jalr	1348(ra) # 80000588 <printf>
    printheap();
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c66080e7          	jalr	-922(ra) # 80000cb2 <printheap>
    
    void *d = malloc(34);
    80003054:	02200513          	li	a0,34
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	b60080e7          	jalr	-1184(ra) # 80000bb8 <malloc>
    80003060:	85aa                	mv	a1,a0
    printf("Allocated 34 bytes at %p\n", d);
    80003062:	00005517          	auipc	a0,0x5
    80003066:	54e50513          	addi	a0,a0,1358 # 800085b0 <syscalls+0x120>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	51e080e7          	jalr	1310(ra) # 80000588 <printf>
    printheap();
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c40080e7          	jalr	-960(ra) # 80000cb2 <printheap>
    return 0;
    8000307a:	4501                	li	a0,0
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6105                	addi	sp,sp,32
    80003084:	8082                	ret

0000000080003086 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003086:	7179                	addi	sp,sp,-48
    80003088:	f406                	sd	ra,40(sp)
    8000308a:	f022                	sd	s0,32(sp)
    8000308c:	ec26                	sd	s1,24(sp)
    8000308e:	e84a                	sd	s2,16(sp)
    80003090:	e44e                	sd	s3,8(sp)
    80003092:	e052                	sd	s4,0(sp)
    80003094:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003096:	00005597          	auipc	a1,0x5
    8000309a:	53a58593          	addi	a1,a1,1338 # 800085d0 <syscalls+0x140>
    8000309e:	00014517          	auipc	a0,0x14
    800030a2:	9ca50513          	addi	a0,a0,-1590 # 80016a68 <bcache>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	c6a080e7          	jalr	-918(ra) # 80000d10 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030ae:	0001c797          	auipc	a5,0x1c
    800030b2:	9ba78793          	addi	a5,a5,-1606 # 8001ea68 <bcache+0x8000>
    800030b6:	0001c717          	auipc	a4,0x1c
    800030ba:	c1a70713          	addi	a4,a4,-998 # 8001ecd0 <bcache+0x8268>
    800030be:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030c2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030c6:	00014497          	auipc	s1,0x14
    800030ca:	9ba48493          	addi	s1,s1,-1606 # 80016a80 <bcache+0x18>
    b->next = bcache.head.next;
    800030ce:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030d0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030d2:	00005a17          	auipc	s4,0x5
    800030d6:	506a0a13          	addi	s4,s4,1286 # 800085d8 <syscalls+0x148>
    b->next = bcache.head.next;
    800030da:	2b893783          	ld	a5,696(s2)
    800030de:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030e0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030e4:	85d2                	mv	a1,s4
    800030e6:	01048513          	addi	a0,s1,16
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	4c4080e7          	jalr	1220(ra) # 800045ae <initsleeplock>
    bcache.head.next->prev = b;
    800030f2:	2b893783          	ld	a5,696(s2)
    800030f6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030f8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030fc:	45848493          	addi	s1,s1,1112
    80003100:	fd349de3          	bne	s1,s3,800030da <binit+0x54>
  }
}
    80003104:	70a2                	ld	ra,40(sp)
    80003106:	7402                	ld	s0,32(sp)
    80003108:	64e2                	ld	s1,24(sp)
    8000310a:	6942                	ld	s2,16(sp)
    8000310c:	69a2                	ld	s3,8(sp)
    8000310e:	6a02                	ld	s4,0(sp)
    80003110:	6145                	addi	sp,sp,48
    80003112:	8082                	ret

0000000080003114 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003114:	7179                	addi	sp,sp,-48
    80003116:	f406                	sd	ra,40(sp)
    80003118:	f022                	sd	s0,32(sp)
    8000311a:	ec26                	sd	s1,24(sp)
    8000311c:	e84a                	sd	s2,16(sp)
    8000311e:	e44e                	sd	s3,8(sp)
    80003120:	1800                	addi	s0,sp,48
    80003122:	892a                	mv	s2,a0
    80003124:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	94250513          	addi	a0,a0,-1726 # 80016a68 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	c72080e7          	jalr	-910(ra) # 80000da0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003136:	0001c497          	auipc	s1,0x1c
    8000313a:	bea4b483          	ld	s1,-1046(s1) # 8001ed20 <bcache+0x82b8>
    8000313e:	0001c797          	auipc	a5,0x1c
    80003142:	b9278793          	addi	a5,a5,-1134 # 8001ecd0 <bcache+0x8268>
    80003146:	02f48f63          	beq	s1,a5,80003184 <bread+0x70>
    8000314a:	873e                	mv	a4,a5
    8000314c:	a021                	j	80003154 <bread+0x40>
    8000314e:	68a4                	ld	s1,80(s1)
    80003150:	02e48a63          	beq	s1,a4,80003184 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003154:	449c                	lw	a5,8(s1)
    80003156:	ff279ce3          	bne	a5,s2,8000314e <bread+0x3a>
    8000315a:	44dc                	lw	a5,12(s1)
    8000315c:	ff3799e3          	bne	a5,s3,8000314e <bread+0x3a>
      b->refcnt++;
    80003160:	40bc                	lw	a5,64(s1)
    80003162:	2785                	addiw	a5,a5,1
    80003164:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003166:	00014517          	auipc	a0,0x14
    8000316a:	90250513          	addi	a0,a0,-1790 # 80016a68 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	ce6080e7          	jalr	-794(ra) # 80000e54 <release>
      acquiresleep(&b->lock);
    80003176:	01048513          	addi	a0,s1,16
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	46e080e7          	jalr	1134(ra) # 800045e8 <acquiresleep>
      return b;
    80003182:	a8b9                	j	800031e0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003184:	0001c497          	auipc	s1,0x1c
    80003188:	b944b483          	ld	s1,-1132(s1) # 8001ed18 <bcache+0x82b0>
    8000318c:	0001c797          	auipc	a5,0x1c
    80003190:	b4478793          	addi	a5,a5,-1212 # 8001ecd0 <bcache+0x8268>
    80003194:	00f48863          	beq	s1,a5,800031a4 <bread+0x90>
    80003198:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000319a:	40bc                	lw	a5,64(s1)
    8000319c:	cf81                	beqz	a5,800031b4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000319e:	64a4                	ld	s1,72(s1)
    800031a0:	fee49de3          	bne	s1,a4,8000319a <bread+0x86>
  panic("bget: no buffers");
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	43c50513          	addi	a0,a0,1084 # 800085e0 <syscalls+0x150>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
      b->dev = dev;
    800031b4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031b8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031bc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031c0:	4785                	li	a5,1
    800031c2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031c4:	00014517          	auipc	a0,0x14
    800031c8:	8a450513          	addi	a0,a0,-1884 # 80016a68 <bcache>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	c88080e7          	jalr	-888(ra) # 80000e54 <release>
      acquiresleep(&b->lock);
    800031d4:	01048513          	addi	a0,s1,16
    800031d8:	00001097          	auipc	ra,0x1
    800031dc:	410080e7          	jalr	1040(ra) # 800045e8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031e0:	409c                	lw	a5,0(s1)
    800031e2:	cb89                	beqz	a5,800031f4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031e4:	8526                	mv	a0,s1
    800031e6:	70a2                	ld	ra,40(sp)
    800031e8:	7402                	ld	s0,32(sp)
    800031ea:	64e2                	ld	s1,24(sp)
    800031ec:	6942                	ld	s2,16(sp)
    800031ee:	69a2                	ld	s3,8(sp)
    800031f0:	6145                	addi	sp,sp,48
    800031f2:	8082                	ret
    virtio_disk_rw(b, 0);
    800031f4:	4581                	li	a1,0
    800031f6:	8526                	mv	a0,s1
    800031f8:	00003097          	auipc	ra,0x3
    800031fc:	fdc080e7          	jalr	-36(ra) # 800061d4 <virtio_disk_rw>
    b->valid = 1;
    80003200:	4785                	li	a5,1
    80003202:	c09c                	sw	a5,0(s1)
  return b;
    80003204:	b7c5                	j	800031e4 <bread+0xd0>

0000000080003206 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	e426                	sd	s1,8(sp)
    8000320e:	1000                	addi	s0,sp,32
    80003210:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003212:	0541                	addi	a0,a0,16
    80003214:	00001097          	auipc	ra,0x1
    80003218:	46e080e7          	jalr	1134(ra) # 80004682 <holdingsleep>
    8000321c:	cd01                	beqz	a0,80003234 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000321e:	4585                	li	a1,1
    80003220:	8526                	mv	a0,s1
    80003222:	00003097          	auipc	ra,0x3
    80003226:	fb2080e7          	jalr	-78(ra) # 800061d4 <virtio_disk_rw>
}
    8000322a:	60e2                	ld	ra,24(sp)
    8000322c:	6442                	ld	s0,16(sp)
    8000322e:	64a2                	ld	s1,8(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret
    panic("bwrite");
    80003234:	00005517          	auipc	a0,0x5
    80003238:	3c450513          	addi	a0,a0,964 # 800085f8 <syscalls+0x168>
    8000323c:	ffffd097          	auipc	ra,0xffffd
    80003240:	302080e7          	jalr	770(ra) # 8000053e <panic>

0000000080003244 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	e04a                	sd	s2,0(sp)
    8000324e:	1000                	addi	s0,sp,32
    80003250:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003252:	01050913          	addi	s2,a0,16
    80003256:	854a                	mv	a0,s2
    80003258:	00001097          	auipc	ra,0x1
    8000325c:	42a080e7          	jalr	1066(ra) # 80004682 <holdingsleep>
    80003260:	c92d                	beqz	a0,800032d2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003262:	854a                	mv	a0,s2
    80003264:	00001097          	auipc	ra,0x1
    80003268:	3da080e7          	jalr	986(ra) # 8000463e <releasesleep>

  acquire(&bcache.lock);
    8000326c:	00013517          	auipc	a0,0x13
    80003270:	7fc50513          	addi	a0,a0,2044 # 80016a68 <bcache>
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	b2c080e7          	jalr	-1236(ra) # 80000da0 <acquire>
  b->refcnt--;
    8000327c:	40bc                	lw	a5,64(s1)
    8000327e:	37fd                	addiw	a5,a5,-1
    80003280:	0007871b          	sext.w	a4,a5
    80003284:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003286:	eb05                	bnez	a4,800032b6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003288:	68bc                	ld	a5,80(s1)
    8000328a:	64b8                	ld	a4,72(s1)
    8000328c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000328e:	64bc                	ld	a5,72(s1)
    80003290:	68b8                	ld	a4,80(s1)
    80003292:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003294:	0001b797          	auipc	a5,0x1b
    80003298:	7d478793          	addi	a5,a5,2004 # 8001ea68 <bcache+0x8000>
    8000329c:	2b87b703          	ld	a4,696(a5)
    800032a0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032a2:	0001c717          	auipc	a4,0x1c
    800032a6:	a2e70713          	addi	a4,a4,-1490 # 8001ecd0 <bcache+0x8268>
    800032aa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ac:	2b87b703          	ld	a4,696(a5)
    800032b0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032b2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032b6:	00013517          	auipc	a0,0x13
    800032ba:	7b250513          	addi	a0,a0,1970 # 80016a68 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	b96080e7          	jalr	-1130(ra) # 80000e54 <release>
}
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	64a2                	ld	s1,8(sp)
    800032cc:	6902                	ld	s2,0(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret
    panic("brelse");
    800032d2:	00005517          	auipc	a0,0x5
    800032d6:	32e50513          	addi	a0,a0,814 # 80008600 <syscalls+0x170>
    800032da:	ffffd097          	auipc	ra,0xffffd
    800032de:	264080e7          	jalr	612(ra) # 8000053e <panic>

00000000800032e2 <bpin>:

void
bpin(struct buf *b) {
    800032e2:	1101                	addi	sp,sp,-32
    800032e4:	ec06                	sd	ra,24(sp)
    800032e6:	e822                	sd	s0,16(sp)
    800032e8:	e426                	sd	s1,8(sp)
    800032ea:	1000                	addi	s0,sp,32
    800032ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ee:	00013517          	auipc	a0,0x13
    800032f2:	77a50513          	addi	a0,a0,1914 # 80016a68 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	aaa080e7          	jalr	-1366(ra) # 80000da0 <acquire>
  b->refcnt++;
    800032fe:	40bc                	lw	a5,64(s1)
    80003300:	2785                	addiw	a5,a5,1
    80003302:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003304:	00013517          	auipc	a0,0x13
    80003308:	76450513          	addi	a0,a0,1892 # 80016a68 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	b48080e7          	jalr	-1208(ra) # 80000e54 <release>
}
    80003314:	60e2                	ld	ra,24(sp)
    80003316:	6442                	ld	s0,16(sp)
    80003318:	64a2                	ld	s1,8(sp)
    8000331a:	6105                	addi	sp,sp,32
    8000331c:	8082                	ret

000000008000331e <bunpin>:

void
bunpin(struct buf *b) {
    8000331e:	1101                	addi	sp,sp,-32
    80003320:	ec06                	sd	ra,24(sp)
    80003322:	e822                	sd	s0,16(sp)
    80003324:	e426                	sd	s1,8(sp)
    80003326:	1000                	addi	s0,sp,32
    80003328:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000332a:	00013517          	auipc	a0,0x13
    8000332e:	73e50513          	addi	a0,a0,1854 # 80016a68 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	a6e080e7          	jalr	-1426(ra) # 80000da0 <acquire>
  b->refcnt--;
    8000333a:	40bc                	lw	a5,64(s1)
    8000333c:	37fd                	addiw	a5,a5,-1
    8000333e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003340:	00013517          	auipc	a0,0x13
    80003344:	72850513          	addi	a0,a0,1832 # 80016a68 <bcache>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	b0c080e7          	jalr	-1268(ra) # 80000e54 <release>
}
    80003350:	60e2                	ld	ra,24(sp)
    80003352:	6442                	ld	s0,16(sp)
    80003354:	64a2                	ld	s1,8(sp)
    80003356:	6105                	addi	sp,sp,32
    80003358:	8082                	ret

000000008000335a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000335a:	1101                	addi	sp,sp,-32
    8000335c:	ec06                	sd	ra,24(sp)
    8000335e:	e822                	sd	s0,16(sp)
    80003360:	e426                	sd	s1,8(sp)
    80003362:	e04a                	sd	s2,0(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003368:	00d5d59b          	srliw	a1,a1,0xd
    8000336c:	0001c797          	auipc	a5,0x1c
    80003370:	dd87a783          	lw	a5,-552(a5) # 8001f144 <sb+0x1c>
    80003374:	9dbd                	addw	a1,a1,a5
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	d9e080e7          	jalr	-610(ra) # 80003114 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000337e:	0074f713          	andi	a4,s1,7
    80003382:	4785                	li	a5,1
    80003384:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003388:	14ce                	slli	s1,s1,0x33
    8000338a:	90d9                	srli	s1,s1,0x36
    8000338c:	00950733          	add	a4,a0,s1
    80003390:	05874703          	lbu	a4,88(a4)
    80003394:	00e7f6b3          	and	a3,a5,a4
    80003398:	c69d                	beqz	a3,800033c6 <bfree+0x6c>
    8000339a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000339c:	94aa                	add	s1,s1,a0
    8000339e:	fff7c793          	not	a5,a5
    800033a2:	8ff9                	and	a5,a5,a4
    800033a4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033a8:	00001097          	auipc	ra,0x1
    800033ac:	120080e7          	jalr	288(ra) # 800044c8 <log_write>
  brelse(bp);
    800033b0:	854a                	mv	a0,s2
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	e92080e7          	jalr	-366(ra) # 80003244 <brelse>
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	64a2                	ld	s1,8(sp)
    800033c0:	6902                	ld	s2,0(sp)
    800033c2:	6105                	addi	sp,sp,32
    800033c4:	8082                	ret
    panic("freeing free block");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	24250513          	addi	a0,a0,578 # 80008608 <syscalls+0x178>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800033d6 <balloc>:
{
    800033d6:	711d                	addi	sp,sp,-96
    800033d8:	ec86                	sd	ra,88(sp)
    800033da:	e8a2                	sd	s0,80(sp)
    800033dc:	e4a6                	sd	s1,72(sp)
    800033de:	e0ca                	sd	s2,64(sp)
    800033e0:	fc4e                	sd	s3,56(sp)
    800033e2:	f852                	sd	s4,48(sp)
    800033e4:	f456                	sd	s5,40(sp)
    800033e6:	f05a                	sd	s6,32(sp)
    800033e8:	ec5e                	sd	s7,24(sp)
    800033ea:	e862                	sd	s8,16(sp)
    800033ec:	e466                	sd	s9,8(sp)
    800033ee:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033f0:	0001c797          	auipc	a5,0x1c
    800033f4:	d3c7a783          	lw	a5,-708(a5) # 8001f12c <sb+0x4>
    800033f8:	10078163          	beqz	a5,800034fa <balloc+0x124>
    800033fc:	8baa                	mv	s7,a0
    800033fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003400:	0001cb17          	auipc	s6,0x1c
    80003404:	d28b0b13          	addi	s6,s6,-728 # 8001f128 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003408:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000340a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000340e:	6c89                	lui	s9,0x2
    80003410:	a061                	j	80003498 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003412:	974a                	add	a4,a4,s2
    80003414:	8fd5                	or	a5,a5,a3
    80003416:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000341a:	854a                	mv	a0,s2
    8000341c:	00001097          	auipc	ra,0x1
    80003420:	0ac080e7          	jalr	172(ra) # 800044c8 <log_write>
        brelse(bp);
    80003424:	854a                	mv	a0,s2
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	e1e080e7          	jalr	-482(ra) # 80003244 <brelse>
  bp = bread(dev, bno);
    8000342e:	85a6                	mv	a1,s1
    80003430:	855e                	mv	a0,s7
    80003432:	00000097          	auipc	ra,0x0
    80003436:	ce2080e7          	jalr	-798(ra) # 80003114 <bread>
    8000343a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000343c:	40000613          	li	a2,1024
    80003440:	4581                	li	a1,0
    80003442:	05850513          	addi	a0,a0,88
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	a56080e7          	jalr	-1450(ra) # 80000e9c <memset>
  log_write(bp);
    8000344e:	854a                	mv	a0,s2
    80003450:	00001097          	auipc	ra,0x1
    80003454:	078080e7          	jalr	120(ra) # 800044c8 <log_write>
  brelse(bp);
    80003458:	854a                	mv	a0,s2
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	dea080e7          	jalr	-534(ra) # 80003244 <brelse>
}
    80003462:	8526                	mv	a0,s1
    80003464:	60e6                	ld	ra,88(sp)
    80003466:	6446                	ld	s0,80(sp)
    80003468:	64a6                	ld	s1,72(sp)
    8000346a:	6906                	ld	s2,64(sp)
    8000346c:	79e2                	ld	s3,56(sp)
    8000346e:	7a42                	ld	s4,48(sp)
    80003470:	7aa2                	ld	s5,40(sp)
    80003472:	7b02                	ld	s6,32(sp)
    80003474:	6be2                	ld	s7,24(sp)
    80003476:	6c42                	ld	s8,16(sp)
    80003478:	6ca2                	ld	s9,8(sp)
    8000347a:	6125                	addi	sp,sp,96
    8000347c:	8082                	ret
    brelse(bp);
    8000347e:	854a                	mv	a0,s2
    80003480:	00000097          	auipc	ra,0x0
    80003484:	dc4080e7          	jalr	-572(ra) # 80003244 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003488:	015c87bb          	addw	a5,s9,s5
    8000348c:	00078a9b          	sext.w	s5,a5
    80003490:	004b2703          	lw	a4,4(s6)
    80003494:	06eaf363          	bgeu	s5,a4,800034fa <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003498:	41fad79b          	sraiw	a5,s5,0x1f
    8000349c:	0137d79b          	srliw	a5,a5,0x13
    800034a0:	015787bb          	addw	a5,a5,s5
    800034a4:	40d7d79b          	sraiw	a5,a5,0xd
    800034a8:	01cb2583          	lw	a1,28(s6)
    800034ac:	9dbd                	addw	a1,a1,a5
    800034ae:	855e                	mv	a0,s7
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	c64080e7          	jalr	-924(ra) # 80003114 <bread>
    800034b8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ba:	004b2503          	lw	a0,4(s6)
    800034be:	000a849b          	sext.w	s1,s5
    800034c2:	8662                	mv	a2,s8
    800034c4:	faa4fde3          	bgeu	s1,a0,8000347e <balloc+0xa8>
      m = 1 << (bi % 8);
    800034c8:	41f6579b          	sraiw	a5,a2,0x1f
    800034cc:	01d7d69b          	srliw	a3,a5,0x1d
    800034d0:	00c6873b          	addw	a4,a3,a2
    800034d4:	00777793          	andi	a5,a4,7
    800034d8:	9f95                	subw	a5,a5,a3
    800034da:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034de:	4037571b          	sraiw	a4,a4,0x3
    800034e2:	00e906b3          	add	a3,s2,a4
    800034e6:	0586c683          	lbu	a3,88(a3)
    800034ea:	00d7f5b3          	and	a1,a5,a3
    800034ee:	d195                	beqz	a1,80003412 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f0:	2605                	addiw	a2,a2,1
    800034f2:	2485                	addiw	s1,s1,1
    800034f4:	fd4618e3          	bne	a2,s4,800034c4 <balloc+0xee>
    800034f8:	b759                	j	8000347e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034fa:	00005517          	auipc	a0,0x5
    800034fe:	12650513          	addi	a0,a0,294 # 80008620 <syscalls+0x190>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	086080e7          	jalr	134(ra) # 80000588 <printf>
  return 0;
    8000350a:	4481                	li	s1,0
    8000350c:	bf99                	j	80003462 <balloc+0x8c>

000000008000350e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000350e:	7179                	addi	sp,sp,-48
    80003510:	f406                	sd	ra,40(sp)
    80003512:	f022                	sd	s0,32(sp)
    80003514:	ec26                	sd	s1,24(sp)
    80003516:	e84a                	sd	s2,16(sp)
    80003518:	e44e                	sd	s3,8(sp)
    8000351a:	e052                	sd	s4,0(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003520:	47ad                	li	a5,11
    80003522:	02b7e763          	bltu	a5,a1,80003550 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003526:	02059493          	slli	s1,a1,0x20
    8000352a:	9081                	srli	s1,s1,0x20
    8000352c:	048a                	slli	s1,s1,0x2
    8000352e:	94aa                	add	s1,s1,a0
    80003530:	0504a903          	lw	s2,80(s1)
    80003534:	06091e63          	bnez	s2,800035b0 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003538:	4108                	lw	a0,0(a0)
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	e9c080e7          	jalr	-356(ra) # 800033d6 <balloc>
    80003542:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003546:	06090563          	beqz	s2,800035b0 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000354a:	0524a823          	sw	s2,80(s1)
    8000354e:	a08d                	j	800035b0 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003550:	ff45849b          	addiw	s1,a1,-12
    80003554:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003558:	0ff00793          	li	a5,255
    8000355c:	08e7e563          	bltu	a5,a4,800035e6 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003560:	08052903          	lw	s2,128(a0)
    80003564:	00091d63          	bnez	s2,8000357e <bmap+0x70>
      addr = balloc(ip->dev);
    80003568:	4108                	lw	a0,0(a0)
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	e6c080e7          	jalr	-404(ra) # 800033d6 <balloc>
    80003572:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003576:	02090d63          	beqz	s2,800035b0 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000357a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000357e:	85ca                	mv	a1,s2
    80003580:	0009a503          	lw	a0,0(s3)
    80003584:	00000097          	auipc	ra,0x0
    80003588:	b90080e7          	jalr	-1136(ra) # 80003114 <bread>
    8000358c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000358e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003592:	02049593          	slli	a1,s1,0x20
    80003596:	9181                	srli	a1,a1,0x20
    80003598:	058a                	slli	a1,a1,0x2
    8000359a:	00b784b3          	add	s1,a5,a1
    8000359e:	0004a903          	lw	s2,0(s1)
    800035a2:	02090063          	beqz	s2,800035c2 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035a6:	8552                	mv	a0,s4
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	c9c080e7          	jalr	-868(ra) # 80003244 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035b0:	854a                	mv	a0,s2
    800035b2:	70a2                	ld	ra,40(sp)
    800035b4:	7402                	ld	s0,32(sp)
    800035b6:	64e2                	ld	s1,24(sp)
    800035b8:	6942                	ld	s2,16(sp)
    800035ba:	69a2                	ld	s3,8(sp)
    800035bc:	6a02                	ld	s4,0(sp)
    800035be:	6145                	addi	sp,sp,48
    800035c0:	8082                	ret
      addr = balloc(ip->dev);
    800035c2:	0009a503          	lw	a0,0(s3)
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	e10080e7          	jalr	-496(ra) # 800033d6 <balloc>
    800035ce:	0005091b          	sext.w	s2,a0
      if(addr){
    800035d2:	fc090ae3          	beqz	s2,800035a6 <bmap+0x98>
        a[bn] = addr;
    800035d6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035da:	8552                	mv	a0,s4
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	eec080e7          	jalr	-276(ra) # 800044c8 <log_write>
    800035e4:	b7c9                	j	800035a6 <bmap+0x98>
  panic("bmap: out of range");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	05250513          	addi	a0,a0,82 # 80008638 <syscalls+0x1a8>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800035f6 <iget>:
{
    800035f6:	7179                	addi	sp,sp,-48
    800035f8:	f406                	sd	ra,40(sp)
    800035fa:	f022                	sd	s0,32(sp)
    800035fc:	ec26                	sd	s1,24(sp)
    800035fe:	e84a                	sd	s2,16(sp)
    80003600:	e44e                	sd	s3,8(sp)
    80003602:	e052                	sd	s4,0(sp)
    80003604:	1800                	addi	s0,sp,48
    80003606:	89aa                	mv	s3,a0
    80003608:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000360a:	0001c517          	auipc	a0,0x1c
    8000360e:	b3e50513          	addi	a0,a0,-1218 # 8001f148 <itable>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	78e080e7          	jalr	1934(ra) # 80000da0 <acquire>
  empty = 0;
    8000361a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000361c:	0001c497          	auipc	s1,0x1c
    80003620:	b4448493          	addi	s1,s1,-1212 # 8001f160 <itable+0x18>
    80003624:	0001d697          	auipc	a3,0x1d
    80003628:	5cc68693          	addi	a3,a3,1484 # 80020bf0 <log>
    8000362c:	a039                	j	8000363a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000362e:	02090b63          	beqz	s2,80003664 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003632:	08848493          	addi	s1,s1,136
    80003636:	02d48a63          	beq	s1,a3,8000366a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000363a:	449c                	lw	a5,8(s1)
    8000363c:	fef059e3          	blez	a5,8000362e <iget+0x38>
    80003640:	4098                	lw	a4,0(s1)
    80003642:	ff3716e3          	bne	a4,s3,8000362e <iget+0x38>
    80003646:	40d8                	lw	a4,4(s1)
    80003648:	ff4713e3          	bne	a4,s4,8000362e <iget+0x38>
      ip->ref++;
    8000364c:	2785                	addiw	a5,a5,1
    8000364e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003650:	0001c517          	auipc	a0,0x1c
    80003654:	af850513          	addi	a0,a0,-1288 # 8001f148 <itable>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	7fc080e7          	jalr	2044(ra) # 80000e54 <release>
      return ip;
    80003660:	8926                	mv	s2,s1
    80003662:	a03d                	j	80003690 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003664:	f7f9                	bnez	a5,80003632 <iget+0x3c>
    80003666:	8926                	mv	s2,s1
    80003668:	b7e9                	j	80003632 <iget+0x3c>
  if(empty == 0)
    8000366a:	02090c63          	beqz	s2,800036a2 <iget+0xac>
  ip->dev = dev;
    8000366e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003672:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003676:	4785                	li	a5,1
    80003678:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000367c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003680:	0001c517          	auipc	a0,0x1c
    80003684:	ac850513          	addi	a0,a0,-1336 # 8001f148 <itable>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	7cc080e7          	jalr	1996(ra) # 80000e54 <release>
}
    80003690:	854a                	mv	a0,s2
    80003692:	70a2                	ld	ra,40(sp)
    80003694:	7402                	ld	s0,32(sp)
    80003696:	64e2                	ld	s1,24(sp)
    80003698:	6942                	ld	s2,16(sp)
    8000369a:	69a2                	ld	s3,8(sp)
    8000369c:	6a02                	ld	s4,0(sp)
    8000369e:	6145                	addi	sp,sp,48
    800036a0:	8082                	ret
    panic("iget: no inodes");
    800036a2:	00005517          	auipc	a0,0x5
    800036a6:	fae50513          	addi	a0,a0,-82 # 80008650 <syscalls+0x1c0>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>

00000000800036b2 <fsinit>:
fsinit(int dev) {
    800036b2:	7179                	addi	sp,sp,-48
    800036b4:	f406                	sd	ra,40(sp)
    800036b6:	f022                	sd	s0,32(sp)
    800036b8:	ec26                	sd	s1,24(sp)
    800036ba:	e84a                	sd	s2,16(sp)
    800036bc:	e44e                	sd	s3,8(sp)
    800036be:	1800                	addi	s0,sp,48
    800036c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036c2:	4585                	li	a1,1
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	a50080e7          	jalr	-1456(ra) # 80003114 <bread>
    800036cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036ce:	0001c997          	auipc	s3,0x1c
    800036d2:	a5a98993          	addi	s3,s3,-1446 # 8001f128 <sb>
    800036d6:	02000613          	li	a2,32
    800036da:	05850593          	addi	a1,a0,88
    800036de:	854e                	mv	a0,s3
    800036e0:	ffffe097          	auipc	ra,0xffffe
    800036e4:	818080e7          	jalr	-2024(ra) # 80000ef8 <memmove>
  brelse(bp);
    800036e8:	8526                	mv	a0,s1
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	b5a080e7          	jalr	-1190(ra) # 80003244 <brelse>
  if(sb.magic != FSMAGIC)
    800036f2:	0009a703          	lw	a4,0(s3)
    800036f6:	102037b7          	lui	a5,0x10203
    800036fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036fe:	02f71263          	bne	a4,a5,80003722 <fsinit+0x70>
  initlog(dev, &sb);
    80003702:	0001c597          	auipc	a1,0x1c
    80003706:	a2658593          	addi	a1,a1,-1498 # 8001f128 <sb>
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	b40080e7          	jalr	-1216(ra) # 8000424c <initlog>
}
    80003714:	70a2                	ld	ra,40(sp)
    80003716:	7402                	ld	s0,32(sp)
    80003718:	64e2                	ld	s1,24(sp)
    8000371a:	6942                	ld	s2,16(sp)
    8000371c:	69a2                	ld	s3,8(sp)
    8000371e:	6145                	addi	sp,sp,48
    80003720:	8082                	ret
    panic("invalid file system");
    80003722:	00005517          	auipc	a0,0x5
    80003726:	f3e50513          	addi	a0,a0,-194 # 80008660 <syscalls+0x1d0>
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	e14080e7          	jalr	-492(ra) # 8000053e <panic>

0000000080003732 <iinit>:
{
    80003732:	7179                	addi	sp,sp,-48
    80003734:	f406                	sd	ra,40(sp)
    80003736:	f022                	sd	s0,32(sp)
    80003738:	ec26                	sd	s1,24(sp)
    8000373a:	e84a                	sd	s2,16(sp)
    8000373c:	e44e                	sd	s3,8(sp)
    8000373e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003740:	00005597          	auipc	a1,0x5
    80003744:	f3858593          	addi	a1,a1,-200 # 80008678 <syscalls+0x1e8>
    80003748:	0001c517          	auipc	a0,0x1c
    8000374c:	a0050513          	addi	a0,a0,-1536 # 8001f148 <itable>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	5c0080e7          	jalr	1472(ra) # 80000d10 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003758:	0001c497          	auipc	s1,0x1c
    8000375c:	a1848493          	addi	s1,s1,-1512 # 8001f170 <itable+0x28>
    80003760:	0001d997          	auipc	s3,0x1d
    80003764:	4a098993          	addi	s3,s3,1184 # 80020c00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003768:	00005917          	auipc	s2,0x5
    8000376c:	f1890913          	addi	s2,s2,-232 # 80008680 <syscalls+0x1f0>
    80003770:	85ca                	mv	a1,s2
    80003772:	8526                	mv	a0,s1
    80003774:	00001097          	auipc	ra,0x1
    80003778:	e3a080e7          	jalr	-454(ra) # 800045ae <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000377c:	08848493          	addi	s1,s1,136
    80003780:	ff3498e3          	bne	s1,s3,80003770 <iinit+0x3e>
}
    80003784:	70a2                	ld	ra,40(sp)
    80003786:	7402                	ld	s0,32(sp)
    80003788:	64e2                	ld	s1,24(sp)
    8000378a:	6942                	ld	s2,16(sp)
    8000378c:	69a2                	ld	s3,8(sp)
    8000378e:	6145                	addi	sp,sp,48
    80003790:	8082                	ret

0000000080003792 <ialloc>:
{
    80003792:	715d                	addi	sp,sp,-80
    80003794:	e486                	sd	ra,72(sp)
    80003796:	e0a2                	sd	s0,64(sp)
    80003798:	fc26                	sd	s1,56(sp)
    8000379a:	f84a                	sd	s2,48(sp)
    8000379c:	f44e                	sd	s3,40(sp)
    8000379e:	f052                	sd	s4,32(sp)
    800037a0:	ec56                	sd	s5,24(sp)
    800037a2:	e85a                	sd	s6,16(sp)
    800037a4:	e45e                	sd	s7,8(sp)
    800037a6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037a8:	0001c717          	auipc	a4,0x1c
    800037ac:	98c72703          	lw	a4,-1652(a4) # 8001f134 <sb+0xc>
    800037b0:	4785                	li	a5,1
    800037b2:	04e7fa63          	bgeu	a5,a4,80003806 <ialloc+0x74>
    800037b6:	8aaa                	mv	s5,a0
    800037b8:	8bae                	mv	s7,a1
    800037ba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037bc:	0001ca17          	auipc	s4,0x1c
    800037c0:	96ca0a13          	addi	s4,s4,-1684 # 8001f128 <sb>
    800037c4:	00048b1b          	sext.w	s6,s1
    800037c8:	0044d793          	srli	a5,s1,0x4
    800037cc:	018a2583          	lw	a1,24(s4)
    800037d0:	9dbd                	addw	a1,a1,a5
    800037d2:	8556                	mv	a0,s5
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	940080e7          	jalr	-1728(ra) # 80003114 <bread>
    800037dc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037de:	05850993          	addi	s3,a0,88
    800037e2:	00f4f793          	andi	a5,s1,15
    800037e6:	079a                	slli	a5,a5,0x6
    800037e8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ea:	00099783          	lh	a5,0(s3)
    800037ee:	c3a1                	beqz	a5,8000382e <ialloc+0x9c>
    brelse(bp);
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	a54080e7          	jalr	-1452(ra) # 80003244 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f8:	0485                	addi	s1,s1,1
    800037fa:	00ca2703          	lw	a4,12(s4)
    800037fe:	0004879b          	sext.w	a5,s1
    80003802:	fce7e1e3          	bltu	a5,a4,800037c4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003806:	00005517          	auipc	a0,0x5
    8000380a:	e8250513          	addi	a0,a0,-382 # 80008688 <syscalls+0x1f8>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	d7a080e7          	jalr	-646(ra) # 80000588 <printf>
  return 0;
    80003816:	4501                	li	a0,0
}
    80003818:	60a6                	ld	ra,72(sp)
    8000381a:	6406                	ld	s0,64(sp)
    8000381c:	74e2                	ld	s1,56(sp)
    8000381e:	7942                	ld	s2,48(sp)
    80003820:	79a2                	ld	s3,40(sp)
    80003822:	7a02                	ld	s4,32(sp)
    80003824:	6ae2                	ld	s5,24(sp)
    80003826:	6b42                	ld	s6,16(sp)
    80003828:	6ba2                	ld	s7,8(sp)
    8000382a:	6161                	addi	sp,sp,80
    8000382c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000382e:	04000613          	li	a2,64
    80003832:	4581                	li	a1,0
    80003834:	854e                	mv	a0,s3
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	666080e7          	jalr	1638(ra) # 80000e9c <memset>
      dip->type = type;
    8000383e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003842:	854a                	mv	a0,s2
    80003844:	00001097          	auipc	ra,0x1
    80003848:	c84080e7          	jalr	-892(ra) # 800044c8 <log_write>
      brelse(bp);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	9f6080e7          	jalr	-1546(ra) # 80003244 <brelse>
      return iget(dev, inum);
    80003856:	85da                	mv	a1,s6
    80003858:	8556                	mv	a0,s5
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	d9c080e7          	jalr	-612(ra) # 800035f6 <iget>
    80003862:	bf5d                	j	80003818 <ialloc+0x86>

0000000080003864 <iupdate>:
{
    80003864:	1101                	addi	sp,sp,-32
    80003866:	ec06                	sd	ra,24(sp)
    80003868:	e822                	sd	s0,16(sp)
    8000386a:	e426                	sd	s1,8(sp)
    8000386c:	e04a                	sd	s2,0(sp)
    8000386e:	1000                	addi	s0,sp,32
    80003870:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003872:	415c                	lw	a5,4(a0)
    80003874:	0047d79b          	srliw	a5,a5,0x4
    80003878:	0001c597          	auipc	a1,0x1c
    8000387c:	8c85a583          	lw	a1,-1848(a1) # 8001f140 <sb+0x18>
    80003880:	9dbd                	addw	a1,a1,a5
    80003882:	4108                	lw	a0,0(a0)
    80003884:	00000097          	auipc	ra,0x0
    80003888:	890080e7          	jalr	-1904(ra) # 80003114 <bread>
    8000388c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000388e:	05850793          	addi	a5,a0,88
    80003892:	40c8                	lw	a0,4(s1)
    80003894:	893d                	andi	a0,a0,15
    80003896:	051a                	slli	a0,a0,0x6
    80003898:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000389a:	04449703          	lh	a4,68(s1)
    8000389e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038a2:	04649703          	lh	a4,70(s1)
    800038a6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038aa:	04849703          	lh	a4,72(s1)
    800038ae:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038b2:	04a49703          	lh	a4,74(s1)
    800038b6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038ba:	44f8                	lw	a4,76(s1)
    800038bc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038be:	03400613          	li	a2,52
    800038c2:	05048593          	addi	a1,s1,80
    800038c6:	0531                	addi	a0,a0,12
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	630080e7          	jalr	1584(ra) # 80000ef8 <memmove>
  log_write(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	bf6080e7          	jalr	-1034(ra) # 800044c8 <log_write>
  brelse(bp);
    800038da:	854a                	mv	a0,s2
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	968080e7          	jalr	-1688(ra) # 80003244 <brelse>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6902                	ld	s2,0(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret

00000000800038f0 <idup>:
{
    800038f0:	1101                	addi	sp,sp,-32
    800038f2:	ec06                	sd	ra,24(sp)
    800038f4:	e822                	sd	s0,16(sp)
    800038f6:	e426                	sd	s1,8(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038fc:	0001c517          	auipc	a0,0x1c
    80003900:	84c50513          	addi	a0,a0,-1972 # 8001f148 <itable>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	49c080e7          	jalr	1180(ra) # 80000da0 <acquire>
  ip->ref++;
    8000390c:	449c                	lw	a5,8(s1)
    8000390e:	2785                	addiw	a5,a5,1
    80003910:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003912:	0001c517          	auipc	a0,0x1c
    80003916:	83650513          	addi	a0,a0,-1994 # 8001f148 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	53a080e7          	jalr	1338(ra) # 80000e54 <release>
}
    80003922:	8526                	mv	a0,s1
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6105                	addi	sp,sp,32
    8000392c:	8082                	ret

000000008000392e <ilock>:
{
    8000392e:	1101                	addi	sp,sp,-32
    80003930:	ec06                	sd	ra,24(sp)
    80003932:	e822                	sd	s0,16(sp)
    80003934:	e426                	sd	s1,8(sp)
    80003936:	e04a                	sd	s2,0(sp)
    80003938:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000393a:	c115                	beqz	a0,8000395e <ilock+0x30>
    8000393c:	84aa                	mv	s1,a0
    8000393e:	451c                	lw	a5,8(a0)
    80003940:	00f05f63          	blez	a5,8000395e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003944:	0541                	addi	a0,a0,16
    80003946:	00001097          	auipc	ra,0x1
    8000394a:	ca2080e7          	jalr	-862(ra) # 800045e8 <acquiresleep>
  if(ip->valid == 0){
    8000394e:	40bc                	lw	a5,64(s1)
    80003950:	cf99                	beqz	a5,8000396e <ilock+0x40>
}
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6902                	ld	s2,0(sp)
    8000395a:	6105                	addi	sp,sp,32
    8000395c:	8082                	ret
    panic("ilock");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	d4250513          	addi	a0,a0,-702 # 800086a0 <syscalls+0x210>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000396e:	40dc                	lw	a5,4(s1)
    80003970:	0047d79b          	srliw	a5,a5,0x4
    80003974:	0001b597          	auipc	a1,0x1b
    80003978:	7cc5a583          	lw	a1,1996(a1) # 8001f140 <sb+0x18>
    8000397c:	9dbd                	addw	a1,a1,a5
    8000397e:	4088                	lw	a0,0(s1)
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	794080e7          	jalr	1940(ra) # 80003114 <bread>
    80003988:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000398a:	05850593          	addi	a1,a0,88
    8000398e:	40dc                	lw	a5,4(s1)
    80003990:	8bbd                	andi	a5,a5,15
    80003992:	079a                	slli	a5,a5,0x6
    80003994:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003996:	00059783          	lh	a5,0(a1)
    8000399a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000399e:	00259783          	lh	a5,2(a1)
    800039a2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039a6:	00459783          	lh	a5,4(a1)
    800039aa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039ae:	00659783          	lh	a5,6(a1)
    800039b2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039b6:	459c                	lw	a5,8(a1)
    800039b8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039ba:	03400613          	li	a2,52
    800039be:	05b1                	addi	a1,a1,12
    800039c0:	05048513          	addi	a0,s1,80
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	534080e7          	jalr	1332(ra) # 80000ef8 <memmove>
    brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	876080e7          	jalr	-1930(ra) # 80003244 <brelse>
    ip->valid = 1;
    800039d6:	4785                	li	a5,1
    800039d8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039da:	04449783          	lh	a5,68(s1)
    800039de:	fbb5                	bnez	a5,80003952 <ilock+0x24>
      panic("ilock: no type");
    800039e0:	00005517          	auipc	a0,0x5
    800039e4:	cc850513          	addi	a0,a0,-824 # 800086a8 <syscalls+0x218>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	b56080e7          	jalr	-1194(ra) # 8000053e <panic>

00000000800039f0 <iunlock>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039fc:	c905                	beqz	a0,80003a2c <iunlock+0x3c>
    800039fe:	84aa                	mv	s1,a0
    80003a00:	01050913          	addi	s2,a0,16
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	c7c080e7          	jalr	-900(ra) # 80004682 <holdingsleep>
    80003a0e:	cd19                	beqz	a0,80003a2c <iunlock+0x3c>
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	00f05d63          	blez	a5,80003a2c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	c26080e7          	jalr	-986(ra) # 8000463e <releasesleep>
}
    80003a20:	60e2                	ld	ra,24(sp)
    80003a22:	6442                	ld	s0,16(sp)
    80003a24:	64a2                	ld	s1,8(sp)
    80003a26:	6902                	ld	s2,0(sp)
    80003a28:	6105                	addi	sp,sp,32
    80003a2a:	8082                	ret
    panic("iunlock");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	c8c50513          	addi	a0,a0,-884 # 800086b8 <syscalls+0x228>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>

0000000080003a3c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	e052                	sd	s4,0(sp)
    80003a4a:	1800                	addi	s0,sp,48
    80003a4c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a4e:	05050493          	addi	s1,a0,80
    80003a52:	08050913          	addi	s2,a0,128
    80003a56:	a021                	j	80003a5e <itrunc+0x22>
    80003a58:	0491                	addi	s1,s1,4
    80003a5a:	01248d63          	beq	s1,s2,80003a74 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a5e:	408c                	lw	a1,0(s1)
    80003a60:	dde5                	beqz	a1,80003a58 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a62:	0009a503          	lw	a0,0(s3)
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	8f4080e7          	jalr	-1804(ra) # 8000335a <bfree>
      ip->addrs[i] = 0;
    80003a6e:	0004a023          	sw	zero,0(s1)
    80003a72:	b7dd                	j	80003a58 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a74:	0809a583          	lw	a1,128(s3)
    80003a78:	e185                	bnez	a1,80003a98 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a7a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a7e:	854e                	mv	a0,s3
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	de4080e7          	jalr	-540(ra) # 80003864 <iupdate>
}
    80003a88:	70a2                	ld	ra,40(sp)
    80003a8a:	7402                	ld	s0,32(sp)
    80003a8c:	64e2                	ld	s1,24(sp)
    80003a8e:	6942                	ld	s2,16(sp)
    80003a90:	69a2                	ld	s3,8(sp)
    80003a92:	6a02                	ld	s4,0(sp)
    80003a94:	6145                	addi	sp,sp,48
    80003a96:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a98:	0009a503          	lw	a0,0(s3)
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	678080e7          	jalr	1656(ra) # 80003114 <bread>
    80003aa4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aa6:	05850493          	addi	s1,a0,88
    80003aaa:	45850913          	addi	s2,a0,1112
    80003aae:	a021                	j	80003ab6 <itrunc+0x7a>
    80003ab0:	0491                	addi	s1,s1,4
    80003ab2:	01248b63          	beq	s1,s2,80003ac8 <itrunc+0x8c>
      if(a[j])
    80003ab6:	408c                	lw	a1,0(s1)
    80003ab8:	dde5                	beqz	a1,80003ab0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	89c080e7          	jalr	-1892(ra) # 8000335a <bfree>
    80003ac6:	b7ed                	j	80003ab0 <itrunc+0x74>
    brelse(bp);
    80003ac8:	8552                	mv	a0,s4
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	77a080e7          	jalr	1914(ra) # 80003244 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ad2:	0809a583          	lw	a1,128(s3)
    80003ad6:	0009a503          	lw	a0,0(s3)
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	880080e7          	jalr	-1920(ra) # 8000335a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ae2:	0809a023          	sw	zero,128(s3)
    80003ae6:	bf51                	j	80003a7a <itrunc+0x3e>

0000000080003ae8 <iput>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	e04a                	sd	s2,0(sp)
    80003af2:	1000                	addi	s0,sp,32
    80003af4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003af6:	0001b517          	auipc	a0,0x1b
    80003afa:	65250513          	addi	a0,a0,1618 # 8001f148 <itable>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	2a2080e7          	jalr	674(ra) # 80000da0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b06:	4498                	lw	a4,8(s1)
    80003b08:	4785                	li	a5,1
    80003b0a:	02f70363          	beq	a4,a5,80003b30 <iput+0x48>
  ip->ref--;
    80003b0e:	449c                	lw	a5,8(s1)
    80003b10:	37fd                	addiw	a5,a5,-1
    80003b12:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b14:	0001b517          	auipc	a0,0x1b
    80003b18:	63450513          	addi	a0,a0,1588 # 8001f148 <itable>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	338080e7          	jalr	824(ra) # 80000e54 <release>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6902                	ld	s2,0(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b30:	40bc                	lw	a5,64(s1)
    80003b32:	dff1                	beqz	a5,80003b0e <iput+0x26>
    80003b34:	04a49783          	lh	a5,74(s1)
    80003b38:	fbf9                	bnez	a5,80003b0e <iput+0x26>
    acquiresleep(&ip->lock);
    80003b3a:	01048913          	addi	s2,s1,16
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	aa8080e7          	jalr	-1368(ra) # 800045e8 <acquiresleep>
    release(&itable.lock);
    80003b48:	0001b517          	auipc	a0,0x1b
    80003b4c:	60050513          	addi	a0,a0,1536 # 8001f148 <itable>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	304080e7          	jalr	772(ra) # 80000e54 <release>
    itrunc(ip);
    80003b58:	8526                	mv	a0,s1
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	ee2080e7          	jalr	-286(ra) # 80003a3c <itrunc>
    ip->type = 0;
    80003b62:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b66:	8526                	mv	a0,s1
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	cfc080e7          	jalr	-772(ra) # 80003864 <iupdate>
    ip->valid = 0;
    80003b70:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00001097          	auipc	ra,0x1
    80003b7a:	ac8080e7          	jalr	-1336(ra) # 8000463e <releasesleep>
    acquire(&itable.lock);
    80003b7e:	0001b517          	auipc	a0,0x1b
    80003b82:	5ca50513          	addi	a0,a0,1482 # 8001f148 <itable>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	21a080e7          	jalr	538(ra) # 80000da0 <acquire>
    80003b8e:	b741                	j	80003b0e <iput+0x26>

0000000080003b90 <iunlockput>:
{
    80003b90:	1101                	addi	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	1000                	addi	s0,sp,32
    80003b9a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	e54080e7          	jalr	-428(ra) # 800039f0 <iunlock>
  iput(ip);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	f42080e7          	jalr	-190(ra) # 80003ae8 <iput>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6105                	addi	sp,sp,32
    80003bb6:	8082                	ret

0000000080003bb8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bb8:	1141                	addi	sp,sp,-16
    80003bba:	e422                	sd	s0,8(sp)
    80003bbc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bbe:	411c                	lw	a5,0(a0)
    80003bc0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bc2:	415c                	lw	a5,4(a0)
    80003bc4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bc6:	04451783          	lh	a5,68(a0)
    80003bca:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bce:	04a51783          	lh	a5,74(a0)
    80003bd2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bd6:	04c56783          	lwu	a5,76(a0)
    80003bda:	e99c                	sd	a5,16(a1)
}
    80003bdc:	6422                	ld	s0,8(sp)
    80003bde:	0141                	addi	sp,sp,16
    80003be0:	8082                	ret

0000000080003be2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be2:	457c                	lw	a5,76(a0)
    80003be4:	0ed7e963          	bltu	a5,a3,80003cd6 <readi+0xf4>
{
    80003be8:	7159                	addi	sp,sp,-112
    80003bea:	f486                	sd	ra,104(sp)
    80003bec:	f0a2                	sd	s0,96(sp)
    80003bee:	eca6                	sd	s1,88(sp)
    80003bf0:	e8ca                	sd	s2,80(sp)
    80003bf2:	e4ce                	sd	s3,72(sp)
    80003bf4:	e0d2                	sd	s4,64(sp)
    80003bf6:	fc56                	sd	s5,56(sp)
    80003bf8:	f85a                	sd	s6,48(sp)
    80003bfa:	f45e                	sd	s7,40(sp)
    80003bfc:	f062                	sd	s8,32(sp)
    80003bfe:	ec66                	sd	s9,24(sp)
    80003c00:	e86a                	sd	s10,16(sp)
    80003c02:	e46e                	sd	s11,8(sp)
    80003c04:	1880                	addi	s0,sp,112
    80003c06:	8b2a                	mv	s6,a0
    80003c08:	8bae                	mv	s7,a1
    80003c0a:	8a32                	mv	s4,a2
    80003c0c:	84b6                	mv	s1,a3
    80003c0e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c10:	9f35                	addw	a4,a4,a3
    return 0;
    80003c12:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c14:	0ad76063          	bltu	a4,a3,80003cb4 <readi+0xd2>
  if(off + n > ip->size)
    80003c18:	00e7f463          	bgeu	a5,a4,80003c20 <readi+0x3e>
    n = ip->size - off;
    80003c1c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c20:	0a0a8963          	beqz	s5,80003cd2 <readi+0xf0>
    80003c24:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c26:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c2a:	5c7d                	li	s8,-1
    80003c2c:	a82d                	j	80003c66 <readi+0x84>
    80003c2e:	020d1d93          	slli	s11,s10,0x20
    80003c32:	020ddd93          	srli	s11,s11,0x20
    80003c36:	05890793          	addi	a5,s2,88
    80003c3a:	86ee                	mv	a3,s11
    80003c3c:	963e                	add	a2,a2,a5
    80003c3e:	85d2                	mv	a1,s4
    80003c40:	855e                	mv	a0,s7
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	9e4080e7          	jalr	-1564(ra) # 80002626 <either_copyout>
    80003c4a:	05850d63          	beq	a0,s8,80003ca4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c4e:	854a                	mv	a0,s2
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	5f4080e7          	jalr	1524(ra) # 80003244 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c58:	013d09bb          	addw	s3,s10,s3
    80003c5c:	009d04bb          	addw	s1,s10,s1
    80003c60:	9a6e                	add	s4,s4,s11
    80003c62:	0559f763          	bgeu	s3,s5,80003cb0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c66:	00a4d59b          	srliw	a1,s1,0xa
    80003c6a:	855a                	mv	a0,s6
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	8a2080e7          	jalr	-1886(ra) # 8000350e <bmap>
    80003c74:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c78:	cd85                	beqz	a1,80003cb0 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c7a:	000b2503          	lw	a0,0(s6)
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	496080e7          	jalr	1174(ra) # 80003114 <bread>
    80003c86:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c88:	3ff4f613          	andi	a2,s1,1023
    80003c8c:	40cc87bb          	subw	a5,s9,a2
    80003c90:	413a873b          	subw	a4,s5,s3
    80003c94:	8d3e                	mv	s10,a5
    80003c96:	2781                	sext.w	a5,a5
    80003c98:	0007069b          	sext.w	a3,a4
    80003c9c:	f8f6f9e3          	bgeu	a3,a5,80003c2e <readi+0x4c>
    80003ca0:	8d3a                	mv	s10,a4
    80003ca2:	b771                	j	80003c2e <readi+0x4c>
      brelse(bp);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	59e080e7          	jalr	1438(ra) # 80003244 <brelse>
      tot = -1;
    80003cae:	59fd                	li	s3,-1
  }
  return tot;
    80003cb0:	0009851b          	sext.w	a0,s3
}
    80003cb4:	70a6                	ld	ra,104(sp)
    80003cb6:	7406                	ld	s0,96(sp)
    80003cb8:	64e6                	ld	s1,88(sp)
    80003cba:	6946                	ld	s2,80(sp)
    80003cbc:	69a6                	ld	s3,72(sp)
    80003cbe:	6a06                	ld	s4,64(sp)
    80003cc0:	7ae2                	ld	s5,56(sp)
    80003cc2:	7b42                	ld	s6,48(sp)
    80003cc4:	7ba2                	ld	s7,40(sp)
    80003cc6:	7c02                	ld	s8,32(sp)
    80003cc8:	6ce2                	ld	s9,24(sp)
    80003cca:	6d42                	ld	s10,16(sp)
    80003ccc:	6da2                	ld	s11,8(sp)
    80003cce:	6165                	addi	sp,sp,112
    80003cd0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd2:	89d6                	mv	s3,s5
    80003cd4:	bff1                	j	80003cb0 <readi+0xce>
    return 0;
    80003cd6:	4501                	li	a0,0
}
    80003cd8:	8082                	ret

0000000080003cda <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cda:	457c                	lw	a5,76(a0)
    80003cdc:	10d7e863          	bltu	a5,a3,80003dec <writei+0x112>
{
    80003ce0:	7159                	addi	sp,sp,-112
    80003ce2:	f486                	sd	ra,104(sp)
    80003ce4:	f0a2                	sd	s0,96(sp)
    80003ce6:	eca6                	sd	s1,88(sp)
    80003ce8:	e8ca                	sd	s2,80(sp)
    80003cea:	e4ce                	sd	s3,72(sp)
    80003cec:	e0d2                	sd	s4,64(sp)
    80003cee:	fc56                	sd	s5,56(sp)
    80003cf0:	f85a                	sd	s6,48(sp)
    80003cf2:	f45e                	sd	s7,40(sp)
    80003cf4:	f062                	sd	s8,32(sp)
    80003cf6:	ec66                	sd	s9,24(sp)
    80003cf8:	e86a                	sd	s10,16(sp)
    80003cfa:	e46e                	sd	s11,8(sp)
    80003cfc:	1880                	addi	s0,sp,112
    80003cfe:	8aaa                	mv	s5,a0
    80003d00:	8bae                	mv	s7,a1
    80003d02:	8a32                	mv	s4,a2
    80003d04:	8936                	mv	s2,a3
    80003d06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d08:	00e687bb          	addw	a5,a3,a4
    80003d0c:	0ed7e263          	bltu	a5,a3,80003df0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d10:	00043737          	lui	a4,0x43
    80003d14:	0ef76063          	bltu	a4,a5,80003df4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d18:	0c0b0863          	beqz	s6,80003de8 <writei+0x10e>
    80003d1c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d22:	5c7d                	li	s8,-1
    80003d24:	a091                	j	80003d68 <writei+0x8e>
    80003d26:	020d1d93          	slli	s11,s10,0x20
    80003d2a:	020ddd93          	srli	s11,s11,0x20
    80003d2e:	05848793          	addi	a5,s1,88
    80003d32:	86ee                	mv	a3,s11
    80003d34:	8652                	mv	a2,s4
    80003d36:	85de                	mv	a1,s7
    80003d38:	953e                	add	a0,a0,a5
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	942080e7          	jalr	-1726(ra) # 8000267c <either_copyin>
    80003d42:	07850263          	beq	a0,s8,80003da6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d46:	8526                	mv	a0,s1
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	780080e7          	jalr	1920(ra) # 800044c8 <log_write>
    brelse(bp);
    80003d50:	8526                	mv	a0,s1
    80003d52:	fffff097          	auipc	ra,0xfffff
    80003d56:	4f2080e7          	jalr	1266(ra) # 80003244 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5a:	013d09bb          	addw	s3,s10,s3
    80003d5e:	012d093b          	addw	s2,s10,s2
    80003d62:	9a6e                	add	s4,s4,s11
    80003d64:	0569f663          	bgeu	s3,s6,80003db0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d68:	00a9559b          	srliw	a1,s2,0xa
    80003d6c:	8556                	mv	a0,s5
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	7a0080e7          	jalr	1952(ra) # 8000350e <bmap>
    80003d76:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d7a:	c99d                	beqz	a1,80003db0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d7c:	000aa503          	lw	a0,0(s5)
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	394080e7          	jalr	916(ra) # 80003114 <bread>
    80003d88:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d8a:	3ff97513          	andi	a0,s2,1023
    80003d8e:	40ac87bb          	subw	a5,s9,a0
    80003d92:	413b073b          	subw	a4,s6,s3
    80003d96:	8d3e                	mv	s10,a5
    80003d98:	2781                	sext.w	a5,a5
    80003d9a:	0007069b          	sext.w	a3,a4
    80003d9e:	f8f6f4e3          	bgeu	a3,a5,80003d26 <writei+0x4c>
    80003da2:	8d3a                	mv	s10,a4
    80003da4:	b749                	j	80003d26 <writei+0x4c>
      brelse(bp);
    80003da6:	8526                	mv	a0,s1
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	49c080e7          	jalr	1180(ra) # 80003244 <brelse>
  }

  if(off > ip->size)
    80003db0:	04caa783          	lw	a5,76(s5)
    80003db4:	0127f463          	bgeu	a5,s2,80003dbc <writei+0xe2>
    ip->size = off;
    80003db8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dbc:	8556                	mv	a0,s5
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	aa6080e7          	jalr	-1370(ra) # 80003864 <iupdate>

  return tot;
    80003dc6:	0009851b          	sext.w	a0,s3
}
    80003dca:	70a6                	ld	ra,104(sp)
    80003dcc:	7406                	ld	s0,96(sp)
    80003dce:	64e6                	ld	s1,88(sp)
    80003dd0:	6946                	ld	s2,80(sp)
    80003dd2:	69a6                	ld	s3,72(sp)
    80003dd4:	6a06                	ld	s4,64(sp)
    80003dd6:	7ae2                	ld	s5,56(sp)
    80003dd8:	7b42                	ld	s6,48(sp)
    80003dda:	7ba2                	ld	s7,40(sp)
    80003ddc:	7c02                	ld	s8,32(sp)
    80003dde:	6ce2                	ld	s9,24(sp)
    80003de0:	6d42                	ld	s10,16(sp)
    80003de2:	6da2                	ld	s11,8(sp)
    80003de4:	6165                	addi	sp,sp,112
    80003de6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de8:	89da                	mv	s3,s6
    80003dea:	bfc9                	j	80003dbc <writei+0xe2>
    return -1;
    80003dec:	557d                	li	a0,-1
}
    80003dee:	8082                	ret
    return -1;
    80003df0:	557d                	li	a0,-1
    80003df2:	bfe1                	j	80003dca <writei+0xf0>
    return -1;
    80003df4:	557d                	li	a0,-1
    80003df6:	bfd1                	j	80003dca <writei+0xf0>

0000000080003df8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003df8:	1141                	addi	sp,sp,-16
    80003dfa:	e406                	sd	ra,8(sp)
    80003dfc:	e022                	sd	s0,0(sp)
    80003dfe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e00:	4639                	li	a2,14
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	16a080e7          	jalr	362(ra) # 80000f6c <strncmp>
}
    80003e0a:	60a2                	ld	ra,8(sp)
    80003e0c:	6402                	ld	s0,0(sp)
    80003e0e:	0141                	addi	sp,sp,16
    80003e10:	8082                	ret

0000000080003e12 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e12:	7139                	addi	sp,sp,-64
    80003e14:	fc06                	sd	ra,56(sp)
    80003e16:	f822                	sd	s0,48(sp)
    80003e18:	f426                	sd	s1,40(sp)
    80003e1a:	f04a                	sd	s2,32(sp)
    80003e1c:	ec4e                	sd	s3,24(sp)
    80003e1e:	e852                	sd	s4,16(sp)
    80003e20:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e22:	04451703          	lh	a4,68(a0)
    80003e26:	4785                	li	a5,1
    80003e28:	00f71a63          	bne	a4,a5,80003e3c <dirlookup+0x2a>
    80003e2c:	892a                	mv	s2,a0
    80003e2e:	89ae                	mv	s3,a1
    80003e30:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e32:	457c                	lw	a5,76(a0)
    80003e34:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e36:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	e79d                	bnez	a5,80003e66 <dirlookup+0x54>
    80003e3a:	a8a5                	j	80003eb2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e3c:	00005517          	auipc	a0,0x5
    80003e40:	88450513          	addi	a0,a0,-1916 # 800086c0 <syscalls+0x230>
    80003e44:	ffffc097          	auipc	ra,0xffffc
    80003e48:	6fa080e7          	jalr	1786(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e4c:	00005517          	auipc	a0,0x5
    80003e50:	88c50513          	addi	a0,a0,-1908 # 800086d8 <syscalls+0x248>
    80003e54:	ffffc097          	auipc	ra,0xffffc
    80003e58:	6ea080e7          	jalr	1770(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5c:	24c1                	addiw	s1,s1,16
    80003e5e:	04c92783          	lw	a5,76(s2)
    80003e62:	04f4f763          	bgeu	s1,a5,80003eb0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e66:	4741                	li	a4,16
    80003e68:	86a6                	mv	a3,s1
    80003e6a:	fc040613          	addi	a2,s0,-64
    80003e6e:	4581                	li	a1,0
    80003e70:	854a                	mv	a0,s2
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	d70080e7          	jalr	-656(ra) # 80003be2 <readi>
    80003e7a:	47c1                	li	a5,16
    80003e7c:	fcf518e3          	bne	a0,a5,80003e4c <dirlookup+0x3a>
    if(de.inum == 0)
    80003e80:	fc045783          	lhu	a5,-64(s0)
    80003e84:	dfe1                	beqz	a5,80003e5c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e86:	fc240593          	addi	a1,s0,-62
    80003e8a:	854e                	mv	a0,s3
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	f6c080e7          	jalr	-148(ra) # 80003df8 <namecmp>
    80003e94:	f561                	bnez	a0,80003e5c <dirlookup+0x4a>
      if(poff)
    80003e96:	000a0463          	beqz	s4,80003e9e <dirlookup+0x8c>
        *poff = off;
    80003e9a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e9e:	fc045583          	lhu	a1,-64(s0)
    80003ea2:	00092503          	lw	a0,0(s2)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	750080e7          	jalr	1872(ra) # 800035f6 <iget>
    80003eae:	a011                	j	80003eb2 <dirlookup+0xa0>
  return 0;
    80003eb0:	4501                	li	a0,0
}
    80003eb2:	70e2                	ld	ra,56(sp)
    80003eb4:	7442                	ld	s0,48(sp)
    80003eb6:	74a2                	ld	s1,40(sp)
    80003eb8:	7902                	ld	s2,32(sp)
    80003eba:	69e2                	ld	s3,24(sp)
    80003ebc:	6a42                	ld	s4,16(sp)
    80003ebe:	6121                	addi	sp,sp,64
    80003ec0:	8082                	ret

0000000080003ec2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ec2:	711d                	addi	sp,sp,-96
    80003ec4:	ec86                	sd	ra,88(sp)
    80003ec6:	e8a2                	sd	s0,80(sp)
    80003ec8:	e4a6                	sd	s1,72(sp)
    80003eca:	e0ca                	sd	s2,64(sp)
    80003ecc:	fc4e                	sd	s3,56(sp)
    80003ece:	f852                	sd	s4,48(sp)
    80003ed0:	f456                	sd	s5,40(sp)
    80003ed2:	f05a                	sd	s6,32(sp)
    80003ed4:	ec5e                	sd	s7,24(sp)
    80003ed6:	e862                	sd	s8,16(sp)
    80003ed8:	e466                	sd	s9,8(sp)
    80003eda:	1080                	addi	s0,sp,96
    80003edc:	84aa                	mv	s1,a0
    80003ede:	8aae                	mv	s5,a1
    80003ee0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ee2:	00054703          	lbu	a4,0(a0)
    80003ee6:	02f00793          	li	a5,47
    80003eea:	02f70363          	beq	a4,a5,80003f10 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eee:	ffffe097          	auipc	ra,0xffffe
    80003ef2:	c88080e7          	jalr	-888(ra) # 80001b76 <myproc>
    80003ef6:	15053503          	ld	a0,336(a0)
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	9f6080e7          	jalr	-1546(ra) # 800038f0 <idup>
    80003f02:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f04:	02f00913          	li	s2,47
  len = path - s;
    80003f08:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f0a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f0c:	4b85                	li	s7,1
    80003f0e:	a865                	j	80003fc6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f10:	4585                	li	a1,1
    80003f12:	4505                	li	a0,1
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	6e2080e7          	jalr	1762(ra) # 800035f6 <iget>
    80003f1c:	89aa                	mv	s3,a0
    80003f1e:	b7dd                	j	80003f04 <namex+0x42>
      iunlockput(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	c6e080e7          	jalr	-914(ra) # 80003b90 <iunlockput>
      return 0;
    80003f2a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	60e6                	ld	ra,88(sp)
    80003f30:	6446                	ld	s0,80(sp)
    80003f32:	64a6                	ld	s1,72(sp)
    80003f34:	6906                	ld	s2,64(sp)
    80003f36:	79e2                	ld	s3,56(sp)
    80003f38:	7a42                	ld	s4,48(sp)
    80003f3a:	7aa2                	ld	s5,40(sp)
    80003f3c:	7b02                	ld	s6,32(sp)
    80003f3e:	6be2                	ld	s7,24(sp)
    80003f40:	6c42                	ld	s8,16(sp)
    80003f42:	6ca2                	ld	s9,8(sp)
    80003f44:	6125                	addi	sp,sp,96
    80003f46:	8082                	ret
      iunlock(ip);
    80003f48:	854e                	mv	a0,s3
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	aa6080e7          	jalr	-1370(ra) # 800039f0 <iunlock>
      return ip;
    80003f52:	bfe9                	j	80003f2c <namex+0x6a>
      iunlockput(ip);
    80003f54:	854e                	mv	a0,s3
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	c3a080e7          	jalr	-966(ra) # 80003b90 <iunlockput>
      return 0;
    80003f5e:	89e6                	mv	s3,s9
    80003f60:	b7f1                	j	80003f2c <namex+0x6a>
  len = path - s;
    80003f62:	40b48633          	sub	a2,s1,a1
    80003f66:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f6a:	099c5463          	bge	s8,s9,80003ff2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f6e:	4639                	li	a2,14
    80003f70:	8552                	mv	a0,s4
    80003f72:	ffffd097          	auipc	ra,0xffffd
    80003f76:	f86080e7          	jalr	-122(ra) # 80000ef8 <memmove>
  while(*path == '/')
    80003f7a:	0004c783          	lbu	a5,0(s1)
    80003f7e:	01279763          	bne	a5,s2,80003f8c <namex+0xca>
    path++;
    80003f82:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f84:	0004c783          	lbu	a5,0(s1)
    80003f88:	ff278de3          	beq	a5,s2,80003f82 <namex+0xc0>
    ilock(ip);
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	9a0080e7          	jalr	-1632(ra) # 8000392e <ilock>
    if(ip->type != T_DIR){
    80003f96:	04499783          	lh	a5,68(s3)
    80003f9a:	f97793e3          	bne	a5,s7,80003f20 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f9e:	000a8563          	beqz	s5,80003fa8 <namex+0xe6>
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	d3cd                	beqz	a5,80003f48 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fa8:	865a                	mv	a2,s6
    80003faa:	85d2                	mv	a1,s4
    80003fac:	854e                	mv	a0,s3
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	e64080e7          	jalr	-412(ra) # 80003e12 <dirlookup>
    80003fb6:	8caa                	mv	s9,a0
    80003fb8:	dd51                	beqz	a0,80003f54 <namex+0x92>
    iunlockput(ip);
    80003fba:	854e                	mv	a0,s3
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	bd4080e7          	jalr	-1068(ra) # 80003b90 <iunlockput>
    ip = next;
    80003fc4:	89e6                	mv	s3,s9
  while(*path == '/')
    80003fc6:	0004c783          	lbu	a5,0(s1)
    80003fca:	05279763          	bne	a5,s2,80004018 <namex+0x156>
    path++;
    80003fce:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	ff278de3          	beq	a5,s2,80003fce <namex+0x10c>
  if(*path == 0)
    80003fd8:	c79d                	beqz	a5,80004006 <namex+0x144>
    path++;
    80003fda:	85a6                	mv	a1,s1
  len = path - s;
    80003fdc:	8cda                	mv	s9,s6
    80003fde:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fe0:	01278963          	beq	a5,s2,80003ff2 <namex+0x130>
    80003fe4:	dfbd                	beqz	a5,80003f62 <namex+0xa0>
    path++;
    80003fe6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fe8:	0004c783          	lbu	a5,0(s1)
    80003fec:	ff279ce3          	bne	a5,s2,80003fe4 <namex+0x122>
    80003ff0:	bf8d                	j	80003f62 <namex+0xa0>
    memmove(name, s, len);
    80003ff2:	2601                	sext.w	a2,a2
    80003ff4:	8552                	mv	a0,s4
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	f02080e7          	jalr	-254(ra) # 80000ef8 <memmove>
    name[len] = 0;
    80003ffe:	9cd2                	add	s9,s9,s4
    80004000:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004004:	bf9d                	j	80003f7a <namex+0xb8>
  if(nameiparent){
    80004006:	f20a83e3          	beqz	s5,80003f2c <namex+0x6a>
    iput(ip);
    8000400a:	854e                	mv	a0,s3
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	adc080e7          	jalr	-1316(ra) # 80003ae8 <iput>
    return 0;
    80004014:	4981                	li	s3,0
    80004016:	bf19                	j	80003f2c <namex+0x6a>
  if(*path == 0)
    80004018:	d7fd                	beqz	a5,80004006 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	85a6                	mv	a1,s1
    80004020:	b7d1                	j	80003fe4 <namex+0x122>

0000000080004022 <dirlink>:
{
    80004022:	7139                	addi	sp,sp,-64
    80004024:	fc06                	sd	ra,56(sp)
    80004026:	f822                	sd	s0,48(sp)
    80004028:	f426                	sd	s1,40(sp)
    8000402a:	f04a                	sd	s2,32(sp)
    8000402c:	ec4e                	sd	s3,24(sp)
    8000402e:	e852                	sd	s4,16(sp)
    80004030:	0080                	addi	s0,sp,64
    80004032:	892a                	mv	s2,a0
    80004034:	8a2e                	mv	s4,a1
    80004036:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004038:	4601                	li	a2,0
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	dd8080e7          	jalr	-552(ra) # 80003e12 <dirlookup>
    80004042:	e93d                	bnez	a0,800040b8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004044:	04c92483          	lw	s1,76(s2)
    80004048:	c49d                	beqz	s1,80004076 <dirlink+0x54>
    8000404a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404c:	4741                	li	a4,16
    8000404e:	86a6                	mv	a3,s1
    80004050:	fc040613          	addi	a2,s0,-64
    80004054:	4581                	li	a1,0
    80004056:	854a                	mv	a0,s2
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	b8a080e7          	jalr	-1142(ra) # 80003be2 <readi>
    80004060:	47c1                	li	a5,16
    80004062:	06f51163          	bne	a0,a5,800040c4 <dirlink+0xa2>
    if(de.inum == 0)
    80004066:	fc045783          	lhu	a5,-64(s0)
    8000406a:	c791                	beqz	a5,80004076 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406c:	24c1                	addiw	s1,s1,16
    8000406e:	04c92783          	lw	a5,76(s2)
    80004072:	fcf4ede3          	bltu	s1,a5,8000404c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004076:	4639                	li	a2,14
    80004078:	85d2                	mv	a1,s4
    8000407a:	fc240513          	addi	a0,s0,-62
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	f2a080e7          	jalr	-214(ra) # 80000fa8 <strncpy>
  de.inum = inum;
    80004086:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000408a:	4741                	li	a4,16
    8000408c:	86a6                	mv	a3,s1
    8000408e:	fc040613          	addi	a2,s0,-64
    80004092:	4581                	li	a1,0
    80004094:	854a                	mv	a0,s2
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	c44080e7          	jalr	-956(ra) # 80003cda <writei>
    8000409e:	1541                	addi	a0,a0,-16
    800040a0:	00a03533          	snez	a0,a0
    800040a4:	40a00533          	neg	a0,a0
}
    800040a8:	70e2                	ld	ra,56(sp)
    800040aa:	7442                	ld	s0,48(sp)
    800040ac:	74a2                	ld	s1,40(sp)
    800040ae:	7902                	ld	s2,32(sp)
    800040b0:	69e2                	ld	s3,24(sp)
    800040b2:	6a42                	ld	s4,16(sp)
    800040b4:	6121                	addi	sp,sp,64
    800040b6:	8082                	ret
    iput(ip);
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	a30080e7          	jalr	-1488(ra) # 80003ae8 <iput>
    return -1;
    800040c0:	557d                	li	a0,-1
    800040c2:	b7dd                	j	800040a8 <dirlink+0x86>
      panic("dirlink read");
    800040c4:	00004517          	auipc	a0,0x4
    800040c8:	62450513          	addi	a0,a0,1572 # 800086e8 <syscalls+0x258>
    800040cc:	ffffc097          	auipc	ra,0xffffc
    800040d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800040d4 <namei>:

struct inode*
namei(char *path)
{
    800040d4:	1101                	addi	sp,sp,-32
    800040d6:	ec06                	sd	ra,24(sp)
    800040d8:	e822                	sd	s0,16(sp)
    800040da:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040dc:	fe040613          	addi	a2,s0,-32
    800040e0:	4581                	li	a1,0
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	de0080e7          	jalr	-544(ra) # 80003ec2 <namex>
}
    800040ea:	60e2                	ld	ra,24(sp)
    800040ec:	6442                	ld	s0,16(sp)
    800040ee:	6105                	addi	sp,sp,32
    800040f0:	8082                	ret

00000000800040f2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040f2:	1141                	addi	sp,sp,-16
    800040f4:	e406                	sd	ra,8(sp)
    800040f6:	e022                	sd	s0,0(sp)
    800040f8:	0800                	addi	s0,sp,16
    800040fa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040fc:	4585                	li	a1,1
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	dc4080e7          	jalr	-572(ra) # 80003ec2 <namex>
}
    80004106:	60a2                	ld	ra,8(sp)
    80004108:	6402                	ld	s0,0(sp)
    8000410a:	0141                	addi	sp,sp,16
    8000410c:	8082                	ret

000000008000410e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	e04a                	sd	s2,0(sp)
    80004118:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000411a:	0001d917          	auipc	s2,0x1d
    8000411e:	ad690913          	addi	s2,s2,-1322 # 80020bf0 <log>
    80004122:	01892583          	lw	a1,24(s2)
    80004126:	02892503          	lw	a0,40(s2)
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	fea080e7          	jalr	-22(ra) # 80003114 <bread>
    80004132:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004134:	02c92683          	lw	a3,44(s2)
    80004138:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000413a:	02d05763          	blez	a3,80004168 <write_head+0x5a>
    8000413e:	0001d797          	auipc	a5,0x1d
    80004142:	ae278793          	addi	a5,a5,-1310 # 80020c20 <log+0x30>
    80004146:	05c50713          	addi	a4,a0,92
    8000414a:	36fd                	addiw	a3,a3,-1
    8000414c:	1682                	slli	a3,a3,0x20
    8000414e:	9281                	srli	a3,a3,0x20
    80004150:	068a                	slli	a3,a3,0x2
    80004152:	0001d617          	auipc	a2,0x1d
    80004156:	ad260613          	addi	a2,a2,-1326 # 80020c24 <log+0x34>
    8000415a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000415c:	4390                	lw	a2,0(a5)
    8000415e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004160:	0791                	addi	a5,a5,4
    80004162:	0711                	addi	a4,a4,4
    80004164:	fed79ce3          	bne	a5,a3,8000415c <write_head+0x4e>
  }
  bwrite(buf);
    80004168:	8526                	mv	a0,s1
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	09c080e7          	jalr	156(ra) # 80003206 <bwrite>
  brelse(buf);
    80004172:	8526                	mv	a0,s1
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	0d0080e7          	jalr	208(ra) # 80003244 <brelse>
}
    8000417c:	60e2                	ld	ra,24(sp)
    8000417e:	6442                	ld	s0,16(sp)
    80004180:	64a2                	ld	s1,8(sp)
    80004182:	6902                	ld	s2,0(sp)
    80004184:	6105                	addi	sp,sp,32
    80004186:	8082                	ret

0000000080004188 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004188:	0001d797          	auipc	a5,0x1d
    8000418c:	a947a783          	lw	a5,-1388(a5) # 80020c1c <log+0x2c>
    80004190:	0af05d63          	blez	a5,8000424a <install_trans+0xc2>
{
    80004194:	7139                	addi	sp,sp,-64
    80004196:	fc06                	sd	ra,56(sp)
    80004198:	f822                	sd	s0,48(sp)
    8000419a:	f426                	sd	s1,40(sp)
    8000419c:	f04a                	sd	s2,32(sp)
    8000419e:	ec4e                	sd	s3,24(sp)
    800041a0:	e852                	sd	s4,16(sp)
    800041a2:	e456                	sd	s5,8(sp)
    800041a4:	e05a                	sd	s6,0(sp)
    800041a6:	0080                	addi	s0,sp,64
    800041a8:	8b2a                	mv	s6,a0
    800041aa:	0001da97          	auipc	s5,0x1d
    800041ae:	a76a8a93          	addi	s5,s5,-1418 # 80020c20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041b4:	0001d997          	auipc	s3,0x1d
    800041b8:	a3c98993          	addi	s3,s3,-1476 # 80020bf0 <log>
    800041bc:	a00d                	j	800041de <install_trans+0x56>
    brelse(lbuf);
    800041be:	854a                	mv	a0,s2
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	084080e7          	jalr	132(ra) # 80003244 <brelse>
    brelse(dbuf);
    800041c8:	8526                	mv	a0,s1
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	07a080e7          	jalr	122(ra) # 80003244 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d2:	2a05                	addiw	s4,s4,1
    800041d4:	0a91                	addi	s5,s5,4
    800041d6:	02c9a783          	lw	a5,44(s3)
    800041da:	04fa5e63          	bge	s4,a5,80004236 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041de:	0189a583          	lw	a1,24(s3)
    800041e2:	014585bb          	addw	a1,a1,s4
    800041e6:	2585                	addiw	a1,a1,1
    800041e8:	0289a503          	lw	a0,40(s3)
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	f28080e7          	jalr	-216(ra) # 80003114 <bread>
    800041f4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041f6:	000aa583          	lw	a1,0(s5)
    800041fa:	0289a503          	lw	a0,40(s3)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	f16080e7          	jalr	-234(ra) # 80003114 <bread>
    80004206:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004208:	40000613          	li	a2,1024
    8000420c:	05890593          	addi	a1,s2,88
    80004210:	05850513          	addi	a0,a0,88
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	ce4080e7          	jalr	-796(ra) # 80000ef8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	fe8080e7          	jalr	-24(ra) # 80003206 <bwrite>
    if(recovering == 0)
    80004226:	f80b1ce3          	bnez	s6,800041be <install_trans+0x36>
      bunpin(dbuf);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	0f2080e7          	jalr	242(ra) # 8000331e <bunpin>
    80004234:	b769                	j	800041be <install_trans+0x36>
}
    80004236:	70e2                	ld	ra,56(sp)
    80004238:	7442                	ld	s0,48(sp)
    8000423a:	74a2                	ld	s1,40(sp)
    8000423c:	7902                	ld	s2,32(sp)
    8000423e:	69e2                	ld	s3,24(sp)
    80004240:	6a42                	ld	s4,16(sp)
    80004242:	6aa2                	ld	s5,8(sp)
    80004244:	6b02                	ld	s6,0(sp)
    80004246:	6121                	addi	sp,sp,64
    80004248:	8082                	ret
    8000424a:	8082                	ret

000000008000424c <initlog>:
{
    8000424c:	7179                	addi	sp,sp,-48
    8000424e:	f406                	sd	ra,40(sp)
    80004250:	f022                	sd	s0,32(sp)
    80004252:	ec26                	sd	s1,24(sp)
    80004254:	e84a                	sd	s2,16(sp)
    80004256:	e44e                	sd	s3,8(sp)
    80004258:	1800                	addi	s0,sp,48
    8000425a:	892a                	mv	s2,a0
    8000425c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000425e:	0001d497          	auipc	s1,0x1d
    80004262:	99248493          	addi	s1,s1,-1646 # 80020bf0 <log>
    80004266:	00004597          	auipc	a1,0x4
    8000426a:	49258593          	addi	a1,a1,1170 # 800086f8 <syscalls+0x268>
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	aa0080e7          	jalr	-1376(ra) # 80000d10 <initlock>
  log.start = sb->logstart;
    80004278:	0149a583          	lw	a1,20(s3)
    8000427c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000427e:	0109a783          	lw	a5,16(s3)
    80004282:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004284:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004288:	854a                	mv	a0,s2
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	e8a080e7          	jalr	-374(ra) # 80003114 <bread>
  log.lh.n = lh->n;
    80004292:	4d34                	lw	a3,88(a0)
    80004294:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004296:	02d05563          	blez	a3,800042c0 <initlog+0x74>
    8000429a:	05c50793          	addi	a5,a0,92
    8000429e:	0001d717          	auipc	a4,0x1d
    800042a2:	98270713          	addi	a4,a4,-1662 # 80020c20 <log+0x30>
    800042a6:	36fd                	addiw	a3,a3,-1
    800042a8:	1682                	slli	a3,a3,0x20
    800042aa:	9281                	srli	a3,a3,0x20
    800042ac:	068a                	slli	a3,a3,0x2
    800042ae:	06050613          	addi	a2,a0,96
    800042b2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042b4:	4390                	lw	a2,0(a5)
    800042b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042b8:	0791                	addi	a5,a5,4
    800042ba:	0711                	addi	a4,a4,4
    800042bc:	fed79ce3          	bne	a5,a3,800042b4 <initlog+0x68>
  brelse(buf);
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	f84080e7          	jalr	-124(ra) # 80003244 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042c8:	4505                	li	a0,1
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	ebe080e7          	jalr	-322(ra) # 80004188 <install_trans>
  log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	9407a523          	sw	zero,-1718(a5) # 80020c1c <log+0x2c>
  write_head(); // clear the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	e34080e7          	jalr	-460(ra) # 8000410e <write_head>
}
    800042e2:	70a2                	ld	ra,40(sp)
    800042e4:	7402                	ld	s0,32(sp)
    800042e6:	64e2                	ld	s1,24(sp)
    800042e8:	6942                	ld	s2,16(sp)
    800042ea:	69a2                	ld	s3,8(sp)
    800042ec:	6145                	addi	sp,sp,48
    800042ee:	8082                	ret

00000000800042f0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	e426                	sd	s1,8(sp)
    800042f8:	e04a                	sd	s2,0(sp)
    800042fa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042fc:	0001d517          	auipc	a0,0x1d
    80004300:	8f450513          	addi	a0,a0,-1804 # 80020bf0 <log>
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	a9c080e7          	jalr	-1380(ra) # 80000da0 <acquire>
  while(1){
    if(log.committing){
    8000430c:	0001d497          	auipc	s1,0x1d
    80004310:	8e448493          	addi	s1,s1,-1820 # 80020bf0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004314:	4979                	li	s2,30
    80004316:	a039                	j	80004324 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004318:	85a6                	mv	a1,s1
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffe097          	auipc	ra,0xffffe
    80004320:	f02080e7          	jalr	-254(ra) # 8000221e <sleep>
    if(log.committing){
    80004324:	50dc                	lw	a5,36(s1)
    80004326:	fbed                	bnez	a5,80004318 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004328:	509c                	lw	a5,32(s1)
    8000432a:	0017871b          	addiw	a4,a5,1
    8000432e:	0007069b          	sext.w	a3,a4
    80004332:	0027179b          	slliw	a5,a4,0x2
    80004336:	9fb9                	addw	a5,a5,a4
    80004338:	0017979b          	slliw	a5,a5,0x1
    8000433c:	54d8                	lw	a4,44(s1)
    8000433e:	9fb9                	addw	a5,a5,a4
    80004340:	00f95963          	bge	s2,a5,80004352 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004344:	85a6                	mv	a1,s1
    80004346:	8526                	mv	a0,s1
    80004348:	ffffe097          	auipc	ra,0xffffe
    8000434c:	ed6080e7          	jalr	-298(ra) # 8000221e <sleep>
    80004350:	bfd1                	j	80004324 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004352:	0001d517          	auipc	a0,0x1d
    80004356:	89e50513          	addi	a0,a0,-1890 # 80020bf0 <log>
    8000435a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	af8080e7          	jalr	-1288(ra) # 80000e54 <release>
      break;
    }
  }
}
    80004364:	60e2                	ld	ra,24(sp)
    80004366:	6442                	ld	s0,16(sp)
    80004368:	64a2                	ld	s1,8(sp)
    8000436a:	6902                	ld	s2,0(sp)
    8000436c:	6105                	addi	sp,sp,32
    8000436e:	8082                	ret

0000000080004370 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004370:	7139                	addi	sp,sp,-64
    80004372:	fc06                	sd	ra,56(sp)
    80004374:	f822                	sd	s0,48(sp)
    80004376:	f426                	sd	s1,40(sp)
    80004378:	f04a                	sd	s2,32(sp)
    8000437a:	ec4e                	sd	s3,24(sp)
    8000437c:	e852                	sd	s4,16(sp)
    8000437e:	e456                	sd	s5,8(sp)
    80004380:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004382:	0001d497          	auipc	s1,0x1d
    80004386:	86e48493          	addi	s1,s1,-1938 # 80020bf0 <log>
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	a14080e7          	jalr	-1516(ra) # 80000da0 <acquire>
  log.outstanding -= 1;
    80004394:	509c                	lw	a5,32(s1)
    80004396:	37fd                	addiw	a5,a5,-1
    80004398:	0007891b          	sext.w	s2,a5
    8000439c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000439e:	50dc                	lw	a5,36(s1)
    800043a0:	e7b9                	bnez	a5,800043ee <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043a2:	04091e63          	bnez	s2,800043fe <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043a6:	0001d497          	auipc	s1,0x1d
    800043aa:	84a48493          	addi	s1,s1,-1974 # 80020bf0 <log>
    800043ae:	4785                	li	a5,1
    800043b0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	aa0080e7          	jalr	-1376(ra) # 80000e54 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043bc:	54dc                	lw	a5,44(s1)
    800043be:	06f04763          	bgtz	a5,8000442c <end_op+0xbc>
    acquire(&log.lock);
    800043c2:	0001d497          	auipc	s1,0x1d
    800043c6:	82e48493          	addi	s1,s1,-2002 # 80020bf0 <log>
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	9d4080e7          	jalr	-1580(ra) # 80000da0 <acquire>
    log.committing = 0;
    800043d4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffe097          	auipc	ra,0xffffe
    800043de:	ea8080e7          	jalr	-344(ra) # 80002282 <wakeup>
    release(&log.lock);
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	a70080e7          	jalr	-1424(ra) # 80000e54 <release>
}
    800043ec:	a03d                	j	8000441a <end_op+0xaa>
    panic("log.committing");
    800043ee:	00004517          	auipc	a0,0x4
    800043f2:	31250513          	addi	a0,a0,786 # 80008700 <syscalls+0x270>
    800043f6:	ffffc097          	auipc	ra,0xffffc
    800043fa:	148080e7          	jalr	328(ra) # 8000053e <panic>
    wakeup(&log);
    800043fe:	0001c497          	auipc	s1,0x1c
    80004402:	7f248493          	addi	s1,s1,2034 # 80020bf0 <log>
    80004406:	8526                	mv	a0,s1
    80004408:	ffffe097          	auipc	ra,0xffffe
    8000440c:	e7a080e7          	jalr	-390(ra) # 80002282 <wakeup>
  release(&log.lock);
    80004410:	8526                	mv	a0,s1
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	a42080e7          	jalr	-1470(ra) # 80000e54 <release>
}
    8000441a:	70e2                	ld	ra,56(sp)
    8000441c:	7442                	ld	s0,48(sp)
    8000441e:	74a2                	ld	s1,40(sp)
    80004420:	7902                	ld	s2,32(sp)
    80004422:	69e2                	ld	s3,24(sp)
    80004424:	6a42                	ld	s4,16(sp)
    80004426:	6aa2                	ld	s5,8(sp)
    80004428:	6121                	addi	sp,sp,64
    8000442a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442c:	0001ca97          	auipc	s5,0x1c
    80004430:	7f4a8a93          	addi	s5,s5,2036 # 80020c20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004434:	0001ca17          	auipc	s4,0x1c
    80004438:	7bca0a13          	addi	s4,s4,1980 # 80020bf0 <log>
    8000443c:	018a2583          	lw	a1,24(s4)
    80004440:	012585bb          	addw	a1,a1,s2
    80004444:	2585                	addiw	a1,a1,1
    80004446:	028a2503          	lw	a0,40(s4)
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	cca080e7          	jalr	-822(ra) # 80003114 <bread>
    80004452:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004454:	000aa583          	lw	a1,0(s5)
    80004458:	028a2503          	lw	a0,40(s4)
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	cb8080e7          	jalr	-840(ra) # 80003114 <bread>
    80004464:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004466:	40000613          	li	a2,1024
    8000446a:	05850593          	addi	a1,a0,88
    8000446e:	05848513          	addi	a0,s1,88
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	a86080e7          	jalr	-1402(ra) # 80000ef8 <memmove>
    bwrite(to);  // write the log
    8000447a:	8526                	mv	a0,s1
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	d8a080e7          	jalr	-630(ra) # 80003206 <bwrite>
    brelse(from);
    80004484:	854e                	mv	a0,s3
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	dbe080e7          	jalr	-578(ra) # 80003244 <brelse>
    brelse(to);
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	db4080e7          	jalr	-588(ra) # 80003244 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004498:	2905                	addiw	s2,s2,1
    8000449a:	0a91                	addi	s5,s5,4
    8000449c:	02ca2783          	lw	a5,44(s4)
    800044a0:	f8f94ee3          	blt	s2,a5,8000443c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	c6a080e7          	jalr	-918(ra) # 8000410e <write_head>
    install_trans(0); // Now install writes to home locations
    800044ac:	4501                	li	a0,0
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	cda080e7          	jalr	-806(ra) # 80004188 <install_trans>
    log.lh.n = 0;
    800044b6:	0001c797          	auipc	a5,0x1c
    800044ba:	7607a323          	sw	zero,1894(a5) # 80020c1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	c50080e7          	jalr	-944(ra) # 8000410e <write_head>
    800044c6:	bdf5                	j	800043c2 <end_op+0x52>

00000000800044c8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044c8:	1101                	addi	sp,sp,-32
    800044ca:	ec06                	sd	ra,24(sp)
    800044cc:	e822                	sd	s0,16(sp)
    800044ce:	e426                	sd	s1,8(sp)
    800044d0:	e04a                	sd	s2,0(sp)
    800044d2:	1000                	addi	s0,sp,32
    800044d4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044d6:	0001c917          	auipc	s2,0x1c
    800044da:	71a90913          	addi	s2,s2,1818 # 80020bf0 <log>
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	8c0080e7          	jalr	-1856(ra) # 80000da0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044e8:	02c92603          	lw	a2,44(s2)
    800044ec:	47f5                	li	a5,29
    800044ee:	06c7c563          	blt	a5,a2,80004558 <log_write+0x90>
    800044f2:	0001c797          	auipc	a5,0x1c
    800044f6:	71a7a783          	lw	a5,1818(a5) # 80020c0c <log+0x1c>
    800044fa:	37fd                	addiw	a5,a5,-1
    800044fc:	04f65e63          	bge	a2,a5,80004558 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004500:	0001c797          	auipc	a5,0x1c
    80004504:	7107a783          	lw	a5,1808(a5) # 80020c10 <log+0x20>
    80004508:	06f05063          	blez	a5,80004568 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000450c:	4781                	li	a5,0
    8000450e:	06c05563          	blez	a2,80004578 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004512:	44cc                	lw	a1,12(s1)
    80004514:	0001c717          	auipc	a4,0x1c
    80004518:	70c70713          	addi	a4,a4,1804 # 80020c20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000451c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000451e:	4314                	lw	a3,0(a4)
    80004520:	04b68c63          	beq	a3,a1,80004578 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004524:	2785                	addiw	a5,a5,1
    80004526:	0711                	addi	a4,a4,4
    80004528:	fef61be3          	bne	a2,a5,8000451e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000452c:	0621                	addi	a2,a2,8
    8000452e:	060a                	slli	a2,a2,0x2
    80004530:	0001c797          	auipc	a5,0x1c
    80004534:	6c078793          	addi	a5,a5,1728 # 80020bf0 <log>
    80004538:	963e                	add	a2,a2,a5
    8000453a:	44dc                	lw	a5,12(s1)
    8000453c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	da2080e7          	jalr	-606(ra) # 800032e2 <bpin>
    log.lh.n++;
    80004548:	0001c717          	auipc	a4,0x1c
    8000454c:	6a870713          	addi	a4,a4,1704 # 80020bf0 <log>
    80004550:	575c                	lw	a5,44(a4)
    80004552:	2785                	addiw	a5,a5,1
    80004554:	d75c                	sw	a5,44(a4)
    80004556:	a835                	j	80004592 <log_write+0xca>
    panic("too big a transaction");
    80004558:	00004517          	auipc	a0,0x4
    8000455c:	1b850513          	addi	a0,a0,440 # 80008710 <syscalls+0x280>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	fde080e7          	jalr	-34(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	1c050513          	addi	a0,a0,448 # 80008728 <syscalls+0x298>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004578:	00878713          	addi	a4,a5,8
    8000457c:	00271693          	slli	a3,a4,0x2
    80004580:	0001c717          	auipc	a4,0x1c
    80004584:	67070713          	addi	a4,a4,1648 # 80020bf0 <log>
    80004588:	9736                	add	a4,a4,a3
    8000458a:	44d4                	lw	a3,12(s1)
    8000458c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000458e:	faf608e3          	beq	a2,a5,8000453e <log_write+0x76>
  }
  release(&log.lock);
    80004592:	0001c517          	auipc	a0,0x1c
    80004596:	65e50513          	addi	a0,a0,1630 # 80020bf0 <log>
    8000459a:	ffffd097          	auipc	ra,0xffffd
    8000459e:	8ba080e7          	jalr	-1862(ra) # 80000e54 <release>
}
    800045a2:	60e2                	ld	ra,24(sp)
    800045a4:	6442                	ld	s0,16(sp)
    800045a6:	64a2                	ld	s1,8(sp)
    800045a8:	6902                	ld	s2,0(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret

00000000800045ae <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	e04a                	sd	s2,0(sp)
    800045b8:	1000                	addi	s0,sp,32
    800045ba:	84aa                	mv	s1,a0
    800045bc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045be:	00004597          	auipc	a1,0x4
    800045c2:	18a58593          	addi	a1,a1,394 # 80008748 <syscalls+0x2b8>
    800045c6:	0521                	addi	a0,a0,8
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	748080e7          	jalr	1864(ra) # 80000d10 <initlock>
  lk->name = name;
    800045d0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d8:	0204a423          	sw	zero,40(s1)
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6902                	ld	s2,0(sp)
    800045e4:	6105                	addi	sp,sp,32
    800045e6:	8082                	ret

00000000800045e8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045e8:	1101                	addi	sp,sp,-32
    800045ea:	ec06                	sd	ra,24(sp)
    800045ec:	e822                	sd	s0,16(sp)
    800045ee:	e426                	sd	s1,8(sp)
    800045f0:	e04a                	sd	s2,0(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045f6:	00850913          	addi	s2,a0,8
    800045fa:	854a                	mv	a0,s2
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	7a4080e7          	jalr	1956(ra) # 80000da0 <acquire>
  while (lk->locked) {
    80004604:	409c                	lw	a5,0(s1)
    80004606:	cb89                	beqz	a5,80004618 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004608:	85ca                	mv	a1,s2
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffe097          	auipc	ra,0xffffe
    80004610:	c12080e7          	jalr	-1006(ra) # 8000221e <sleep>
  while (lk->locked) {
    80004614:	409c                	lw	a5,0(s1)
    80004616:	fbed                	bnez	a5,80004608 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004618:	4785                	li	a5,1
    8000461a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000461c:	ffffd097          	auipc	ra,0xffffd
    80004620:	55a080e7          	jalr	1370(ra) # 80001b76 <myproc>
    80004624:	591c                	lw	a5,48(a0)
    80004626:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004628:	854a                	mv	a0,s2
    8000462a:	ffffd097          	auipc	ra,0xffffd
    8000462e:	82a080e7          	jalr	-2006(ra) # 80000e54 <release>
}
    80004632:	60e2                	ld	ra,24(sp)
    80004634:	6442                	ld	s0,16(sp)
    80004636:	64a2                	ld	s1,8(sp)
    80004638:	6902                	ld	s2,0(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
    8000464a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464c:	00850913          	addi	s2,a0,8
    80004650:	854a                	mv	a0,s2
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	74e080e7          	jalr	1870(ra) # 80000da0 <acquire>
  lk->locked = 0;
    8000465a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000465e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004662:	8526                	mv	a0,s1
    80004664:	ffffe097          	auipc	ra,0xffffe
    80004668:	c1e080e7          	jalr	-994(ra) # 80002282 <wakeup>
  release(&lk->lk);
    8000466c:	854a                	mv	a0,s2
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	7e6080e7          	jalr	2022(ra) # 80000e54 <release>
}
    80004676:	60e2                	ld	ra,24(sp)
    80004678:	6442                	ld	s0,16(sp)
    8000467a:	64a2                	ld	s1,8(sp)
    8000467c:	6902                	ld	s2,0(sp)
    8000467e:	6105                	addi	sp,sp,32
    80004680:	8082                	ret

0000000080004682 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004682:	7179                	addi	sp,sp,-48
    80004684:	f406                	sd	ra,40(sp)
    80004686:	f022                	sd	s0,32(sp)
    80004688:	ec26                	sd	s1,24(sp)
    8000468a:	e84a                	sd	s2,16(sp)
    8000468c:	e44e                	sd	s3,8(sp)
    8000468e:	1800                	addi	s0,sp,48
    80004690:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004692:	00850913          	addi	s2,a0,8
    80004696:	854a                	mv	a0,s2
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	708080e7          	jalr	1800(ra) # 80000da0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a0:	409c                	lw	a5,0(s1)
    800046a2:	ef99                	bnez	a5,800046c0 <holdingsleep+0x3e>
    800046a4:	4481                	li	s1,0
  release(&lk->lk);
    800046a6:	854a                	mv	a0,s2
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	7ac080e7          	jalr	1964(ra) # 80000e54 <release>
  return r;
}
    800046b0:	8526                	mv	a0,s1
    800046b2:	70a2                	ld	ra,40(sp)
    800046b4:	7402                	ld	s0,32(sp)
    800046b6:	64e2                	ld	s1,24(sp)
    800046b8:	6942                	ld	s2,16(sp)
    800046ba:	69a2                	ld	s3,8(sp)
    800046bc:	6145                	addi	sp,sp,48
    800046be:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c0:	0284a983          	lw	s3,40(s1)
    800046c4:	ffffd097          	auipc	ra,0xffffd
    800046c8:	4b2080e7          	jalr	1202(ra) # 80001b76 <myproc>
    800046cc:	5904                	lw	s1,48(a0)
    800046ce:	413484b3          	sub	s1,s1,s3
    800046d2:	0014b493          	seqz	s1,s1
    800046d6:	bfc1                	j	800046a6 <holdingsleep+0x24>

00000000800046d8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046d8:	1141                	addi	sp,sp,-16
    800046da:	e406                	sd	ra,8(sp)
    800046dc:	e022                	sd	s0,0(sp)
    800046de:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046e0:	00004597          	auipc	a1,0x4
    800046e4:	07858593          	addi	a1,a1,120 # 80008758 <syscalls+0x2c8>
    800046e8:	0001c517          	auipc	a0,0x1c
    800046ec:	65050513          	addi	a0,a0,1616 # 80020d38 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	620080e7          	jalr	1568(ra) # 80000d10 <initlock>
}
    800046f8:	60a2                	ld	ra,8(sp)
    800046fa:	6402                	ld	s0,0(sp)
    800046fc:	0141                	addi	sp,sp,16
    800046fe:	8082                	ret

0000000080004700 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000470a:	0001c517          	auipc	a0,0x1c
    8000470e:	62e50513          	addi	a0,a0,1582 # 80020d38 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	68e080e7          	jalr	1678(ra) # 80000da0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000471a:	0001c497          	auipc	s1,0x1c
    8000471e:	63648493          	addi	s1,s1,1590 # 80020d50 <ftable+0x18>
    80004722:	0001d717          	auipc	a4,0x1d
    80004726:	5ce70713          	addi	a4,a4,1486 # 80021cf0 <disk>
    if(f->ref == 0){
    8000472a:	40dc                	lw	a5,4(s1)
    8000472c:	cf99                	beqz	a5,8000474a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000472e:	02848493          	addi	s1,s1,40
    80004732:	fee49ce3          	bne	s1,a4,8000472a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004736:	0001c517          	auipc	a0,0x1c
    8000473a:	60250513          	addi	a0,a0,1538 # 80020d38 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	716080e7          	jalr	1814(ra) # 80000e54 <release>
  return 0;
    80004746:	4481                	li	s1,0
    80004748:	a819                	j	8000475e <filealloc+0x5e>
      f->ref = 1;
    8000474a:	4785                	li	a5,1
    8000474c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000474e:	0001c517          	auipc	a0,0x1c
    80004752:	5ea50513          	addi	a0,a0,1514 # 80020d38 <ftable>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	6fe080e7          	jalr	1790(ra) # 80000e54 <release>
}
    8000475e:	8526                	mv	a0,s1
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret

000000008000476a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000476a:	1101                	addi	sp,sp,-32
    8000476c:	ec06                	sd	ra,24(sp)
    8000476e:	e822                	sd	s0,16(sp)
    80004770:	e426                	sd	s1,8(sp)
    80004772:	1000                	addi	s0,sp,32
    80004774:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004776:	0001c517          	auipc	a0,0x1c
    8000477a:	5c250513          	addi	a0,a0,1474 # 80020d38 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	622080e7          	jalr	1570(ra) # 80000da0 <acquire>
  if(f->ref < 1)
    80004786:	40dc                	lw	a5,4(s1)
    80004788:	02f05263          	blez	a5,800047ac <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000478c:	2785                	addiw	a5,a5,1
    8000478e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004790:	0001c517          	auipc	a0,0x1c
    80004794:	5a850513          	addi	a0,a0,1448 # 80020d38 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	6bc080e7          	jalr	1724(ra) # 80000e54 <release>
  return f;
}
    800047a0:	8526                	mv	a0,s1
    800047a2:	60e2                	ld	ra,24(sp)
    800047a4:	6442                	ld	s0,16(sp)
    800047a6:	64a2                	ld	s1,8(sp)
    800047a8:	6105                	addi	sp,sp,32
    800047aa:	8082                	ret
    panic("filedup");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	fb450513          	addi	a0,a0,-76 # 80008760 <syscalls+0x2d0>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>

00000000800047bc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047bc:	7139                	addi	sp,sp,-64
    800047be:	fc06                	sd	ra,56(sp)
    800047c0:	f822                	sd	s0,48(sp)
    800047c2:	f426                	sd	s1,40(sp)
    800047c4:	f04a                	sd	s2,32(sp)
    800047c6:	ec4e                	sd	s3,24(sp)
    800047c8:	e852                	sd	s4,16(sp)
    800047ca:	e456                	sd	s5,8(sp)
    800047cc:	0080                	addi	s0,sp,64
    800047ce:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047d0:	0001c517          	auipc	a0,0x1c
    800047d4:	56850513          	addi	a0,a0,1384 # 80020d38 <ftable>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	5c8080e7          	jalr	1480(ra) # 80000da0 <acquire>
  if(f->ref < 1)
    800047e0:	40dc                	lw	a5,4(s1)
    800047e2:	06f05163          	blez	a5,80004844 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047e6:	37fd                	addiw	a5,a5,-1
    800047e8:	0007871b          	sext.w	a4,a5
    800047ec:	c0dc                	sw	a5,4(s1)
    800047ee:	06e04363          	bgtz	a4,80004854 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047f2:	0004a903          	lw	s2,0(s1)
    800047f6:	0094ca83          	lbu	s5,9(s1)
    800047fa:	0104ba03          	ld	s4,16(s1)
    800047fe:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004802:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004806:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000480a:	0001c517          	auipc	a0,0x1c
    8000480e:	52e50513          	addi	a0,a0,1326 # 80020d38 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	642080e7          	jalr	1602(ra) # 80000e54 <release>

  if(ff.type == FD_PIPE){
    8000481a:	4785                	li	a5,1
    8000481c:	04f90d63          	beq	s2,a5,80004876 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004820:	3979                	addiw	s2,s2,-2
    80004822:	4785                	li	a5,1
    80004824:	0527e063          	bltu	a5,s2,80004864 <fileclose+0xa8>
    begin_op();
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	ac8080e7          	jalr	-1336(ra) # 800042f0 <begin_op>
    iput(ff.ip);
    80004830:	854e                	mv	a0,s3
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	2b6080e7          	jalr	694(ra) # 80003ae8 <iput>
    end_op();
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	b36080e7          	jalr	-1226(ra) # 80004370 <end_op>
    80004842:	a00d                	j	80004864 <fileclose+0xa8>
    panic("fileclose");
    80004844:	00004517          	auipc	a0,0x4
    80004848:	f2450513          	addi	a0,a0,-220 # 80008768 <syscalls+0x2d8>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004854:	0001c517          	auipc	a0,0x1c
    80004858:	4e450513          	addi	a0,a0,1252 # 80020d38 <ftable>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	5f8080e7          	jalr	1528(ra) # 80000e54 <release>
  }
}
    80004864:	70e2                	ld	ra,56(sp)
    80004866:	7442                	ld	s0,48(sp)
    80004868:	74a2                	ld	s1,40(sp)
    8000486a:	7902                	ld	s2,32(sp)
    8000486c:	69e2                	ld	s3,24(sp)
    8000486e:	6a42                	ld	s4,16(sp)
    80004870:	6aa2                	ld	s5,8(sp)
    80004872:	6121                	addi	sp,sp,64
    80004874:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004876:	85d6                	mv	a1,s5
    80004878:	8552                	mv	a0,s4
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	34c080e7          	jalr	844(ra) # 80004bc6 <pipeclose>
    80004882:	b7cd                	j	80004864 <fileclose+0xa8>

0000000080004884 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004884:	715d                	addi	sp,sp,-80
    80004886:	e486                	sd	ra,72(sp)
    80004888:	e0a2                	sd	s0,64(sp)
    8000488a:	fc26                	sd	s1,56(sp)
    8000488c:	f84a                	sd	s2,48(sp)
    8000488e:	f44e                	sd	s3,40(sp)
    80004890:	0880                	addi	s0,sp,80
    80004892:	84aa                	mv	s1,a0
    80004894:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004896:	ffffd097          	auipc	ra,0xffffd
    8000489a:	2e0080e7          	jalr	736(ra) # 80001b76 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000489e:	409c                	lw	a5,0(s1)
    800048a0:	37f9                	addiw	a5,a5,-2
    800048a2:	4705                	li	a4,1
    800048a4:	04f76763          	bltu	a4,a5,800048f2 <filestat+0x6e>
    800048a8:	892a                	mv	s2,a0
    ilock(f->ip);
    800048aa:	6c88                	ld	a0,24(s1)
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	082080e7          	jalr	130(ra) # 8000392e <ilock>
    stati(f->ip, &st);
    800048b4:	fb840593          	addi	a1,s0,-72
    800048b8:	6c88                	ld	a0,24(s1)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	2fe080e7          	jalr	766(ra) # 80003bb8 <stati>
    iunlock(f->ip);
    800048c2:	6c88                	ld	a0,24(s1)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	12c080e7          	jalr	300(ra) # 800039f0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048cc:	46e1                	li	a3,24
    800048ce:	fb840613          	addi	a2,s0,-72
    800048d2:	85ce                	mv	a1,s3
    800048d4:	05093503          	ld	a0,80(s2)
    800048d8:	ffffd097          	auipc	ra,0xffffd
    800048dc:	f5a080e7          	jalr	-166(ra) # 80001832 <copyout>
    800048e0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048e4:	60a6                	ld	ra,72(sp)
    800048e6:	6406                	ld	s0,64(sp)
    800048e8:	74e2                	ld	s1,56(sp)
    800048ea:	7942                	ld	s2,48(sp)
    800048ec:	79a2                	ld	s3,40(sp)
    800048ee:	6161                	addi	sp,sp,80
    800048f0:	8082                	ret
  return -1;
    800048f2:	557d                	li	a0,-1
    800048f4:	bfc5                	j	800048e4 <filestat+0x60>

00000000800048f6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048f6:	7179                	addi	sp,sp,-48
    800048f8:	f406                	sd	ra,40(sp)
    800048fa:	f022                	sd	s0,32(sp)
    800048fc:	ec26                	sd	s1,24(sp)
    800048fe:	e84a                	sd	s2,16(sp)
    80004900:	e44e                	sd	s3,8(sp)
    80004902:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004904:	00854783          	lbu	a5,8(a0)
    80004908:	c3d5                	beqz	a5,800049ac <fileread+0xb6>
    8000490a:	84aa                	mv	s1,a0
    8000490c:	89ae                	mv	s3,a1
    8000490e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004910:	411c                	lw	a5,0(a0)
    80004912:	4705                	li	a4,1
    80004914:	04e78963          	beq	a5,a4,80004966 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004918:	470d                	li	a4,3
    8000491a:	04e78d63          	beq	a5,a4,80004974 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000491e:	4709                	li	a4,2
    80004920:	06e79e63          	bne	a5,a4,8000499c <fileread+0xa6>
    ilock(f->ip);
    80004924:	6d08                	ld	a0,24(a0)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	008080e7          	jalr	8(ra) # 8000392e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000492e:	874a                	mv	a4,s2
    80004930:	5094                	lw	a3,32(s1)
    80004932:	864e                	mv	a2,s3
    80004934:	4585                	li	a1,1
    80004936:	6c88                	ld	a0,24(s1)
    80004938:	fffff097          	auipc	ra,0xfffff
    8000493c:	2aa080e7          	jalr	682(ra) # 80003be2 <readi>
    80004940:	892a                	mv	s2,a0
    80004942:	00a05563          	blez	a0,8000494c <fileread+0x56>
      f->off += r;
    80004946:	509c                	lw	a5,32(s1)
    80004948:	9fa9                	addw	a5,a5,a0
    8000494a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000494c:	6c88                	ld	a0,24(s1)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	0a2080e7          	jalr	162(ra) # 800039f0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004956:	854a                	mv	a0,s2
    80004958:	70a2                	ld	ra,40(sp)
    8000495a:	7402                	ld	s0,32(sp)
    8000495c:	64e2                	ld	s1,24(sp)
    8000495e:	6942                	ld	s2,16(sp)
    80004960:	69a2                	ld	s3,8(sp)
    80004962:	6145                	addi	sp,sp,48
    80004964:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004966:	6908                	ld	a0,16(a0)
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	3c6080e7          	jalr	966(ra) # 80004d2e <piperead>
    80004970:	892a                	mv	s2,a0
    80004972:	b7d5                	j	80004956 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004974:	02451783          	lh	a5,36(a0)
    80004978:	03079693          	slli	a3,a5,0x30
    8000497c:	92c1                	srli	a3,a3,0x30
    8000497e:	4725                	li	a4,9
    80004980:	02d76863          	bltu	a4,a3,800049b0 <fileread+0xba>
    80004984:	0792                	slli	a5,a5,0x4
    80004986:	0001c717          	auipc	a4,0x1c
    8000498a:	31270713          	addi	a4,a4,786 # 80020c98 <devsw>
    8000498e:	97ba                	add	a5,a5,a4
    80004990:	639c                	ld	a5,0(a5)
    80004992:	c38d                	beqz	a5,800049b4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004994:	4505                	li	a0,1
    80004996:	9782                	jalr	a5
    80004998:	892a                	mv	s2,a0
    8000499a:	bf75                	j	80004956 <fileread+0x60>
    panic("fileread");
    8000499c:	00004517          	auipc	a0,0x4
    800049a0:	ddc50513          	addi	a0,a0,-548 # 80008778 <syscalls+0x2e8>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	b9a080e7          	jalr	-1126(ra) # 8000053e <panic>
    return -1;
    800049ac:	597d                	li	s2,-1
    800049ae:	b765                	j	80004956 <fileread+0x60>
      return -1;
    800049b0:	597d                	li	s2,-1
    800049b2:	b755                	j	80004956 <fileread+0x60>
    800049b4:	597d                	li	s2,-1
    800049b6:	b745                	j	80004956 <fileread+0x60>

00000000800049b8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049b8:	715d                	addi	sp,sp,-80
    800049ba:	e486                	sd	ra,72(sp)
    800049bc:	e0a2                	sd	s0,64(sp)
    800049be:	fc26                	sd	s1,56(sp)
    800049c0:	f84a                	sd	s2,48(sp)
    800049c2:	f44e                	sd	s3,40(sp)
    800049c4:	f052                	sd	s4,32(sp)
    800049c6:	ec56                	sd	s5,24(sp)
    800049c8:	e85a                	sd	s6,16(sp)
    800049ca:	e45e                	sd	s7,8(sp)
    800049cc:	e062                	sd	s8,0(sp)
    800049ce:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049d0:	00954783          	lbu	a5,9(a0)
    800049d4:	10078663          	beqz	a5,80004ae0 <filewrite+0x128>
    800049d8:	892a                	mv	s2,a0
    800049da:	8aae                	mv	s5,a1
    800049dc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049de:	411c                	lw	a5,0(a0)
    800049e0:	4705                	li	a4,1
    800049e2:	02e78263          	beq	a5,a4,80004a06 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049e6:	470d                	li	a4,3
    800049e8:	02e78663          	beq	a5,a4,80004a14 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ec:	4709                	li	a4,2
    800049ee:	0ee79163          	bne	a5,a4,80004ad0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049f2:	0ac05d63          	blez	a2,80004aac <filewrite+0xf4>
    int i = 0;
    800049f6:	4981                	li	s3,0
    800049f8:	6b05                	lui	s6,0x1
    800049fa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049fe:	6b85                	lui	s7,0x1
    80004a00:	c00b8b9b          	addiw	s7,s7,-1024
    80004a04:	a861                	j	80004a9c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a06:	6908                	ld	a0,16(a0)
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	22e080e7          	jalr	558(ra) # 80004c36 <pipewrite>
    80004a10:	8a2a                	mv	s4,a0
    80004a12:	a045                	j	80004ab2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a14:	02451783          	lh	a5,36(a0)
    80004a18:	03079693          	slli	a3,a5,0x30
    80004a1c:	92c1                	srli	a3,a3,0x30
    80004a1e:	4725                	li	a4,9
    80004a20:	0cd76263          	bltu	a4,a3,80004ae4 <filewrite+0x12c>
    80004a24:	0792                	slli	a5,a5,0x4
    80004a26:	0001c717          	auipc	a4,0x1c
    80004a2a:	27270713          	addi	a4,a4,626 # 80020c98 <devsw>
    80004a2e:	97ba                	add	a5,a5,a4
    80004a30:	679c                	ld	a5,8(a5)
    80004a32:	cbdd                	beqz	a5,80004ae8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a34:	4505                	li	a0,1
    80004a36:	9782                	jalr	a5
    80004a38:	8a2a                	mv	s4,a0
    80004a3a:	a8a5                	j	80004ab2 <filewrite+0xfa>
    80004a3c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	8b0080e7          	jalr	-1872(ra) # 800042f0 <begin_op>
      ilock(f->ip);
    80004a48:	01893503          	ld	a0,24(s2)
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	ee2080e7          	jalr	-286(ra) # 8000392e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a54:	8762                	mv	a4,s8
    80004a56:	02092683          	lw	a3,32(s2)
    80004a5a:	01598633          	add	a2,s3,s5
    80004a5e:	4585                	li	a1,1
    80004a60:	01893503          	ld	a0,24(s2)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	276080e7          	jalr	630(ra) # 80003cda <writei>
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	00a05763          	blez	a0,80004a7c <filewrite+0xc4>
        f->off += r;
    80004a72:	02092783          	lw	a5,32(s2)
    80004a76:	9fa9                	addw	a5,a5,a0
    80004a78:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a7c:	01893503          	ld	a0,24(s2)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	f70080e7          	jalr	-144(ra) # 800039f0 <iunlock>
      end_op();
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	8e8080e7          	jalr	-1816(ra) # 80004370 <end_op>

      if(r != n1){
    80004a90:	009c1f63          	bne	s8,s1,80004aae <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a94:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a98:	0149db63          	bge	s3,s4,80004aae <filewrite+0xf6>
      int n1 = n - i;
    80004a9c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aa0:	84be                	mv	s1,a5
    80004aa2:	2781                	sext.w	a5,a5
    80004aa4:	f8fb5ce3          	bge	s6,a5,80004a3c <filewrite+0x84>
    80004aa8:	84de                	mv	s1,s7
    80004aaa:	bf49                	j	80004a3c <filewrite+0x84>
    int i = 0;
    80004aac:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004aae:	013a1f63          	bne	s4,s3,80004acc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ab2:	8552                	mv	a0,s4
    80004ab4:	60a6                	ld	ra,72(sp)
    80004ab6:	6406                	ld	s0,64(sp)
    80004ab8:	74e2                	ld	s1,56(sp)
    80004aba:	7942                	ld	s2,48(sp)
    80004abc:	79a2                	ld	s3,40(sp)
    80004abe:	7a02                	ld	s4,32(sp)
    80004ac0:	6ae2                	ld	s5,24(sp)
    80004ac2:	6b42                	ld	s6,16(sp)
    80004ac4:	6ba2                	ld	s7,8(sp)
    80004ac6:	6c02                	ld	s8,0(sp)
    80004ac8:	6161                	addi	sp,sp,80
    80004aca:	8082                	ret
    ret = (i == n ? n : -1);
    80004acc:	5a7d                	li	s4,-1
    80004ace:	b7d5                	j	80004ab2 <filewrite+0xfa>
    panic("filewrite");
    80004ad0:	00004517          	auipc	a0,0x4
    80004ad4:	cb850513          	addi	a0,a0,-840 # 80008788 <syscalls+0x2f8>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
    return -1;
    80004ae0:	5a7d                	li	s4,-1
    80004ae2:	bfc1                	j	80004ab2 <filewrite+0xfa>
      return -1;
    80004ae4:	5a7d                	li	s4,-1
    80004ae6:	b7f1                	j	80004ab2 <filewrite+0xfa>
    80004ae8:	5a7d                	li	s4,-1
    80004aea:	b7e1                	j	80004ab2 <filewrite+0xfa>

0000000080004aec <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aec:	7179                	addi	sp,sp,-48
    80004aee:	f406                	sd	ra,40(sp)
    80004af0:	f022                	sd	s0,32(sp)
    80004af2:	ec26                	sd	s1,24(sp)
    80004af4:	e84a                	sd	s2,16(sp)
    80004af6:	e44e                	sd	s3,8(sp)
    80004af8:	e052                	sd	s4,0(sp)
    80004afa:	1800                	addi	s0,sp,48
    80004afc:	84aa                	mv	s1,a0
    80004afe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b00:	0005b023          	sd	zero,0(a1)
    80004b04:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	bf8080e7          	jalr	-1032(ra) # 80004700 <filealloc>
    80004b10:	e088                	sd	a0,0(s1)
    80004b12:	c551                	beqz	a0,80004b9e <pipealloc+0xb2>
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	bec080e7          	jalr	-1044(ra) # 80004700 <filealloc>
    80004b1c:	00aa3023          	sd	a0,0(s4)
    80004b20:	c92d                	beqz	a0,80004b92 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	f88080e7          	jalr	-120(ra) # 80000aaa <kalloc>
    80004b2a:	892a                	mv	s2,a0
    80004b2c:	c125                	beqz	a0,80004b8c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b2e:	4985                	li	s3,1
    80004b30:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b34:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b38:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b3c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b40:	00004597          	auipc	a1,0x4
    80004b44:	c5858593          	addi	a1,a1,-936 # 80008798 <syscalls+0x308>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	1c8080e7          	jalr	456(ra) # 80000d10 <initlock>
  (*f0)->type = FD_PIPE;
    80004b50:	609c                	ld	a5,0(s1)
    80004b52:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b56:	609c                	ld	a5,0(s1)
    80004b58:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b5c:	609c                	ld	a5,0(s1)
    80004b5e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b62:	609c                	ld	a5,0(s1)
    80004b64:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b68:	000a3783          	ld	a5,0(s4)
    80004b6c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b70:	000a3783          	ld	a5,0(s4)
    80004b74:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b78:	000a3783          	ld	a5,0(s4)
    80004b7c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b80:	000a3783          	ld	a5,0(s4)
    80004b84:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b88:	4501                	li	a0,0
    80004b8a:	a025                	j	80004bb2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b8c:	6088                	ld	a0,0(s1)
    80004b8e:	e501                	bnez	a0,80004b96 <pipealloc+0xaa>
    80004b90:	a039                	j	80004b9e <pipealloc+0xb2>
    80004b92:	6088                	ld	a0,0(s1)
    80004b94:	c51d                	beqz	a0,80004bc2 <pipealloc+0xd6>
    fileclose(*f0);
    80004b96:	00000097          	auipc	ra,0x0
    80004b9a:	c26080e7          	jalr	-986(ra) # 800047bc <fileclose>
  if(*f1)
    80004b9e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ba2:	557d                	li	a0,-1
  if(*f1)
    80004ba4:	c799                	beqz	a5,80004bb2 <pipealloc+0xc6>
    fileclose(*f1);
    80004ba6:	853e                	mv	a0,a5
    80004ba8:	00000097          	auipc	ra,0x0
    80004bac:	c14080e7          	jalr	-1004(ra) # 800047bc <fileclose>
  return -1;
    80004bb0:	557d                	li	a0,-1
}
    80004bb2:	70a2                	ld	ra,40(sp)
    80004bb4:	7402                	ld	s0,32(sp)
    80004bb6:	64e2                	ld	s1,24(sp)
    80004bb8:	6942                	ld	s2,16(sp)
    80004bba:	69a2                	ld	s3,8(sp)
    80004bbc:	6a02                	ld	s4,0(sp)
    80004bbe:	6145                	addi	sp,sp,48
    80004bc0:	8082                	ret
  return -1;
    80004bc2:	557d                	li	a0,-1
    80004bc4:	b7fd                	j	80004bb2 <pipealloc+0xc6>

0000000080004bc6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bc6:	1101                	addi	sp,sp,-32
    80004bc8:	ec06                	sd	ra,24(sp)
    80004bca:	e822                	sd	s0,16(sp)
    80004bcc:	e426                	sd	s1,8(sp)
    80004bce:	e04a                	sd	s2,0(sp)
    80004bd0:	1000                	addi	s0,sp,32
    80004bd2:	84aa                	mv	s1,a0
    80004bd4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	1ca080e7          	jalr	458(ra) # 80000da0 <acquire>
  if(writable){
    80004bde:	02090d63          	beqz	s2,80004c18 <pipeclose+0x52>
    pi->writeopen = 0;
    80004be2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004be6:	21848513          	addi	a0,s1,536
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	698080e7          	jalr	1688(ra) # 80002282 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bf2:	2204b783          	ld	a5,544(s1)
    80004bf6:	eb95                	bnez	a5,80004c2a <pipeclose+0x64>
    release(&pi->lock);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	25a080e7          	jalr	602(ra) # 80000e54 <release>
    kfree((char*)pi);
    80004c02:	8526                	mv	a0,s1
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	de6080e7          	jalr	-538(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c0c:	60e2                	ld	ra,24(sp)
    80004c0e:	6442                	ld	s0,16(sp)
    80004c10:	64a2                	ld	s1,8(sp)
    80004c12:	6902                	ld	s2,0(sp)
    80004c14:	6105                	addi	sp,sp,32
    80004c16:	8082                	ret
    pi->readopen = 0;
    80004c18:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c1c:	21c48513          	addi	a0,s1,540
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	662080e7          	jalr	1634(ra) # 80002282 <wakeup>
    80004c28:	b7e9                	j	80004bf2 <pipeclose+0x2c>
    release(&pi->lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	228080e7          	jalr	552(ra) # 80000e54 <release>
}
    80004c34:	bfe1                	j	80004c0c <pipeclose+0x46>

0000000080004c36 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c36:	711d                	addi	sp,sp,-96
    80004c38:	ec86                	sd	ra,88(sp)
    80004c3a:	e8a2                	sd	s0,80(sp)
    80004c3c:	e4a6                	sd	s1,72(sp)
    80004c3e:	e0ca                	sd	s2,64(sp)
    80004c40:	fc4e                	sd	s3,56(sp)
    80004c42:	f852                	sd	s4,48(sp)
    80004c44:	f456                	sd	s5,40(sp)
    80004c46:	f05a                	sd	s6,32(sp)
    80004c48:	ec5e                	sd	s7,24(sp)
    80004c4a:	e862                	sd	s8,16(sp)
    80004c4c:	1080                	addi	s0,sp,96
    80004c4e:	84aa                	mv	s1,a0
    80004c50:	8aae                	mv	s5,a1
    80004c52:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	f22080e7          	jalr	-222(ra) # 80001b76 <myproc>
    80004c5c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	140080e7          	jalr	320(ra) # 80000da0 <acquire>
  while(i < n){
    80004c68:	0b405663          	blez	s4,80004d14 <pipewrite+0xde>
  int i = 0;
    80004c6c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c6e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c70:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c74:	21c48b93          	addi	s7,s1,540
    80004c78:	a089                	j	80004cba <pipewrite+0x84>
      release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	1d8080e7          	jalr	472(ra) # 80000e54 <release>
      return -1;
    80004c84:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c86:	854a                	mv	a0,s2
    80004c88:	60e6                	ld	ra,88(sp)
    80004c8a:	6446                	ld	s0,80(sp)
    80004c8c:	64a6                	ld	s1,72(sp)
    80004c8e:	6906                	ld	s2,64(sp)
    80004c90:	79e2                	ld	s3,56(sp)
    80004c92:	7a42                	ld	s4,48(sp)
    80004c94:	7aa2                	ld	s5,40(sp)
    80004c96:	7b02                	ld	s6,32(sp)
    80004c98:	6be2                	ld	s7,24(sp)
    80004c9a:	6c42                	ld	s8,16(sp)
    80004c9c:	6125                	addi	sp,sp,96
    80004c9e:	8082                	ret
      wakeup(&pi->nread);
    80004ca0:	8562                	mv	a0,s8
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	5e0080e7          	jalr	1504(ra) # 80002282 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004caa:	85a6                	mv	a1,s1
    80004cac:	855e                	mv	a0,s7
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	570080e7          	jalr	1392(ra) # 8000221e <sleep>
  while(i < n){
    80004cb6:	07495063          	bge	s2,s4,80004d16 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004cba:	2204a783          	lw	a5,544(s1)
    80004cbe:	dfd5                	beqz	a5,80004c7a <pipewrite+0x44>
    80004cc0:	854e                	mv	a0,s3
    80004cc2:	ffffe097          	auipc	ra,0xffffe
    80004cc6:	804080e7          	jalr	-2044(ra) # 800024c6 <killed>
    80004cca:	f945                	bnez	a0,80004c7a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ccc:	2184a783          	lw	a5,536(s1)
    80004cd0:	21c4a703          	lw	a4,540(s1)
    80004cd4:	2007879b          	addiw	a5,a5,512
    80004cd8:	fcf704e3          	beq	a4,a5,80004ca0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cdc:	4685                	li	a3,1
    80004cde:	01590633          	add	a2,s2,s5
    80004ce2:	faf40593          	addi	a1,s0,-81
    80004ce6:	0509b503          	ld	a0,80(s3)
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	bd4080e7          	jalr	-1068(ra) # 800018be <copyin>
    80004cf2:	03650263          	beq	a0,s6,80004d16 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cf6:	21c4a783          	lw	a5,540(s1)
    80004cfa:	0017871b          	addiw	a4,a5,1
    80004cfe:	20e4ae23          	sw	a4,540(s1)
    80004d02:	1ff7f793          	andi	a5,a5,511
    80004d06:	97a6                	add	a5,a5,s1
    80004d08:	faf44703          	lbu	a4,-81(s0)
    80004d0c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d10:	2905                	addiw	s2,s2,1
    80004d12:	b755                	j	80004cb6 <pipewrite+0x80>
  int i = 0;
    80004d14:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d16:	21848513          	addi	a0,s1,536
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	568080e7          	jalr	1384(ra) # 80002282 <wakeup>
  release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	130080e7          	jalr	304(ra) # 80000e54 <release>
  return i;
    80004d2c:	bfa9                	j	80004c86 <pipewrite+0x50>

0000000080004d2e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d2e:	715d                	addi	sp,sp,-80
    80004d30:	e486                	sd	ra,72(sp)
    80004d32:	e0a2                	sd	s0,64(sp)
    80004d34:	fc26                	sd	s1,56(sp)
    80004d36:	f84a                	sd	s2,48(sp)
    80004d38:	f44e                	sd	s3,40(sp)
    80004d3a:	f052                	sd	s4,32(sp)
    80004d3c:	ec56                	sd	s5,24(sp)
    80004d3e:	e85a                	sd	s6,16(sp)
    80004d40:	0880                	addi	s0,sp,80
    80004d42:	84aa                	mv	s1,a0
    80004d44:	892e                	mv	s2,a1
    80004d46:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	e2e080e7          	jalr	-466(ra) # 80001b76 <myproc>
    80004d50:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	04c080e7          	jalr	76(ra) # 80000da0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d5c:	2184a703          	lw	a4,536(s1)
    80004d60:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d68:	02f71763          	bne	a4,a5,80004d96 <piperead+0x68>
    80004d6c:	2244a783          	lw	a5,548(s1)
    80004d70:	c39d                	beqz	a5,80004d96 <piperead+0x68>
    if(killed(pr)){
    80004d72:	8552                	mv	a0,s4
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	752080e7          	jalr	1874(ra) # 800024c6 <killed>
    80004d7c:	e941                	bnez	a0,80004e0c <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d7e:	85a6                	mv	a1,s1
    80004d80:	854e                	mv	a0,s3
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	49c080e7          	jalr	1180(ra) # 8000221e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d8a:	2184a703          	lw	a4,536(s1)
    80004d8e:	21c4a783          	lw	a5,540(s1)
    80004d92:	fcf70de3          	beq	a4,a5,80004d6c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d96:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d98:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9a:	05505363          	blez	s5,80004de0 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d9e:	2184a783          	lw	a5,536(s1)
    80004da2:	21c4a703          	lw	a4,540(s1)
    80004da6:	02f70d63          	beq	a4,a5,80004de0 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004daa:	0017871b          	addiw	a4,a5,1
    80004dae:	20e4ac23          	sw	a4,536(s1)
    80004db2:	1ff7f793          	andi	a5,a5,511
    80004db6:	97a6                	add	a5,a5,s1
    80004db8:	0187c783          	lbu	a5,24(a5)
    80004dbc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc0:	4685                	li	a3,1
    80004dc2:	fbf40613          	addi	a2,s0,-65
    80004dc6:	85ca                	mv	a1,s2
    80004dc8:	050a3503          	ld	a0,80(s4)
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	a66080e7          	jalr	-1434(ra) # 80001832 <copyout>
    80004dd4:	01650663          	beq	a0,s6,80004de0 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd8:	2985                	addiw	s3,s3,1
    80004dda:	0905                	addi	s2,s2,1
    80004ddc:	fd3a91e3          	bne	s5,s3,80004d9e <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004de0:	21c48513          	addi	a0,s1,540
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	49e080e7          	jalr	1182(ra) # 80002282 <wakeup>
  release(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	066080e7          	jalr	102(ra) # 80000e54 <release>
  return i;
}
    80004df6:	854e                	mv	a0,s3
    80004df8:	60a6                	ld	ra,72(sp)
    80004dfa:	6406                	ld	s0,64(sp)
    80004dfc:	74e2                	ld	s1,56(sp)
    80004dfe:	7942                	ld	s2,48(sp)
    80004e00:	79a2                	ld	s3,40(sp)
    80004e02:	7a02                	ld	s4,32(sp)
    80004e04:	6ae2                	ld	s5,24(sp)
    80004e06:	6b42                	ld	s6,16(sp)
    80004e08:	6161                	addi	sp,sp,80
    80004e0a:	8082                	ret
      release(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	046080e7          	jalr	70(ra) # 80000e54 <release>
      return -1;
    80004e16:	59fd                	li	s3,-1
    80004e18:	bff9                	j	80004df6 <piperead+0xc8>

0000000080004e1a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e1a:	1141                	addi	sp,sp,-16
    80004e1c:	e422                	sd	s0,8(sp)
    80004e1e:	0800                	addi	s0,sp,16
    80004e20:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e22:	8905                	andi	a0,a0,1
    80004e24:	c111                	beqz	a0,80004e28 <flags2perm+0xe>
      perm = PTE_X;
    80004e26:	4521                	li	a0,8
    if(flags & 0x2)
    80004e28:	8b89                	andi	a5,a5,2
    80004e2a:	c399                	beqz	a5,80004e30 <flags2perm+0x16>
      perm |= PTE_W;
    80004e2c:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e30:	6422                	ld	s0,8(sp)
    80004e32:	0141                	addi	sp,sp,16
    80004e34:	8082                	ret

0000000080004e36 <exec>:

int
exec(char *path, char **argv)
{
    80004e36:	de010113          	addi	sp,sp,-544
    80004e3a:	20113c23          	sd	ra,536(sp)
    80004e3e:	20813823          	sd	s0,528(sp)
    80004e42:	20913423          	sd	s1,520(sp)
    80004e46:	21213023          	sd	s2,512(sp)
    80004e4a:	ffce                	sd	s3,504(sp)
    80004e4c:	fbd2                	sd	s4,496(sp)
    80004e4e:	f7d6                	sd	s5,488(sp)
    80004e50:	f3da                	sd	s6,480(sp)
    80004e52:	efde                	sd	s7,472(sp)
    80004e54:	ebe2                	sd	s8,464(sp)
    80004e56:	e7e6                	sd	s9,456(sp)
    80004e58:	e3ea                	sd	s10,448(sp)
    80004e5a:	ff6e                	sd	s11,440(sp)
    80004e5c:	1400                	addi	s0,sp,544
    80004e5e:	892a                	mv	s2,a0
    80004e60:	dea43423          	sd	a0,-536(s0)
    80004e64:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	d0e080e7          	jalr	-754(ra) # 80001b76 <myproc>
    80004e70:	84aa                	mv	s1,a0

  begin_op();
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	47e080e7          	jalr	1150(ra) # 800042f0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	258080e7          	jalr	600(ra) # 800040d4 <namei>
    80004e84:	c93d                	beqz	a0,80004efa <exec+0xc4>
    80004e86:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	aa6080e7          	jalr	-1370(ra) # 8000392e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e90:	04000713          	li	a4,64
    80004e94:	4681                	li	a3,0
    80004e96:	e5040613          	addi	a2,s0,-432
    80004e9a:	4581                	li	a1,0
    80004e9c:	8556                	mv	a0,s5
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	d44080e7          	jalr	-700(ra) # 80003be2 <readi>
    80004ea6:	04000793          	li	a5,64
    80004eaa:	00f51a63          	bne	a0,a5,80004ebe <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004eae:	e5042703          	lw	a4,-432(s0)
    80004eb2:	464c47b7          	lui	a5,0x464c4
    80004eb6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eba:	04f70663          	beq	a4,a5,80004f06 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ebe:	8556                	mv	a0,s5
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	cd0080e7          	jalr	-816(ra) # 80003b90 <iunlockput>
    end_op();
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	4a8080e7          	jalr	1192(ra) # 80004370 <end_op>
  }
  return -1;
    80004ed0:	557d                	li	a0,-1
}
    80004ed2:	21813083          	ld	ra,536(sp)
    80004ed6:	21013403          	ld	s0,528(sp)
    80004eda:	20813483          	ld	s1,520(sp)
    80004ede:	20013903          	ld	s2,512(sp)
    80004ee2:	79fe                	ld	s3,504(sp)
    80004ee4:	7a5e                	ld	s4,496(sp)
    80004ee6:	7abe                	ld	s5,488(sp)
    80004ee8:	7b1e                	ld	s6,480(sp)
    80004eea:	6bfe                	ld	s7,472(sp)
    80004eec:	6c5e                	ld	s8,464(sp)
    80004eee:	6cbe                	ld	s9,456(sp)
    80004ef0:	6d1e                	ld	s10,448(sp)
    80004ef2:	7dfa                	ld	s11,440(sp)
    80004ef4:	22010113          	addi	sp,sp,544
    80004ef8:	8082                	ret
    end_op();
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	476080e7          	jalr	1142(ra) # 80004370 <end_op>
    return -1;
    80004f02:	557d                	li	a0,-1
    80004f04:	b7f9                	j	80004ed2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f06:	8526                	mv	a0,s1
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	d32080e7          	jalr	-718(ra) # 80001c3a <proc_pagetable>
    80004f10:	8b2a                	mv	s6,a0
    80004f12:	d555                	beqz	a0,80004ebe <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f14:	e7042783          	lw	a5,-400(s0)
    80004f18:	e8845703          	lhu	a4,-376(s0)
    80004f1c:	c735                	beqz	a4,80004f88 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f1e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f20:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f24:	6a05                	lui	s4,0x1
    80004f26:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f2a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f2e:	6d85                	lui	s11,0x1
    80004f30:	7d7d                	lui	s10,0xfffff
    80004f32:	a481                	j	80005172 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f34:	00004517          	auipc	a0,0x4
    80004f38:	86c50513          	addi	a0,a0,-1940 # 800087a0 <syscalls+0x310>
    80004f3c:	ffffb097          	auipc	ra,0xffffb
    80004f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f44:	874a                	mv	a4,s2
    80004f46:	009c86bb          	addw	a3,s9,s1
    80004f4a:	4581                	li	a1,0
    80004f4c:	8556                	mv	a0,s5
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	c94080e7          	jalr	-876(ra) # 80003be2 <readi>
    80004f56:	2501                	sext.w	a0,a0
    80004f58:	1aa91a63          	bne	s2,a0,8000510c <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f5c:	009d84bb          	addw	s1,s11,s1
    80004f60:	013d09bb          	addw	s3,s10,s3
    80004f64:	1f74f763          	bgeu	s1,s7,80005152 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004f68:	02049593          	slli	a1,s1,0x20
    80004f6c:	9181                	srli	a1,a1,0x20
    80004f6e:	95e2                	add	a1,a1,s8
    80004f70:	855a                	mv	a0,s6
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	2b4080e7          	jalr	692(ra) # 80001226 <walkaddr>
    80004f7a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f7c:	dd45                	beqz	a0,80004f34 <exec+0xfe>
      n = PGSIZE;
    80004f7e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f80:	fd49f2e3          	bgeu	s3,s4,80004f44 <exec+0x10e>
      n = sz - i;
    80004f84:	894e                	mv	s2,s3
    80004f86:	bf7d                	j	80004f44 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f88:	4901                	li	s2,0
  iunlockput(ip);
    80004f8a:	8556                	mv	a0,s5
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	c04080e7          	jalr	-1020(ra) # 80003b90 <iunlockput>
  end_op();
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	3dc080e7          	jalr	988(ra) # 80004370 <end_op>
  p = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	bda080e7          	jalr	-1062(ra) # 80001b76 <myproc>
    80004fa4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fa6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004faa:	6785                	lui	a5,0x1
    80004fac:	17fd                	addi	a5,a5,-1
    80004fae:	993e                	add	s2,s2,a5
    80004fb0:	77fd                	lui	a5,0xfffff
    80004fb2:	00f977b3          	and	a5,s2,a5
    80004fb6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fba:	4691                	li	a3,4
    80004fbc:	6609                	lui	a2,0x2
    80004fbe:	963e                	add	a2,a2,a5
    80004fc0:	85be                	mv	a1,a5
    80004fc2:	855a                	mv	a0,s6
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	616080e7          	jalr	1558(ra) # 800015da <uvmalloc>
    80004fcc:	8c2a                	mv	s8,a0
  ip = 0;
    80004fce:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fd0:	12050e63          	beqz	a0,8000510c <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fd4:	75f9                	lui	a1,0xffffe
    80004fd6:	95aa                	add	a1,a1,a0
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	826080e7          	jalr	-2010(ra) # 80001800 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fe2:	7afd                	lui	s5,0xfffff
    80004fe4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fe6:	df043783          	ld	a5,-528(s0)
    80004fea:	6388                	ld	a0,0(a5)
    80004fec:	c925                	beqz	a0,8000505c <exec+0x226>
    80004fee:	e9040993          	addi	s3,s0,-368
    80004ff2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ff6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ff8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	01e080e7          	jalr	30(ra) # 80001018 <strlen>
    80005002:	0015079b          	addiw	a5,a0,1
    80005006:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000500a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000500e:	13596663          	bltu	s2,s5,8000513a <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005012:	df043d83          	ld	s11,-528(s0)
    80005016:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000501a:	8552                	mv	a0,s4
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	ffc080e7          	jalr	-4(ra) # 80001018 <strlen>
    80005024:	0015069b          	addiw	a3,a0,1
    80005028:	8652                	mv	a2,s4
    8000502a:	85ca                	mv	a1,s2
    8000502c:	855a                	mv	a0,s6
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	804080e7          	jalr	-2044(ra) # 80001832 <copyout>
    80005036:	10054663          	bltz	a0,80005142 <exec+0x30c>
    ustack[argc] = sp;
    8000503a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000503e:	0485                	addi	s1,s1,1
    80005040:	008d8793          	addi	a5,s11,8
    80005044:	def43823          	sd	a5,-528(s0)
    80005048:	008db503          	ld	a0,8(s11)
    8000504c:	c911                	beqz	a0,80005060 <exec+0x22a>
    if(argc >= MAXARG)
    8000504e:	09a1                	addi	s3,s3,8
    80005050:	fb3c95e3          	bne	s9,s3,80004ffa <exec+0x1c4>
  sz = sz1;
    80005054:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005058:	4a81                	li	s5,0
    8000505a:	a84d                	j	8000510c <exec+0x2d6>
  sp = sz;
    8000505c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000505e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005060:	00349793          	slli	a5,s1,0x3
    80005064:	f9040713          	addi	a4,s0,-112
    80005068:	97ba                	add	a5,a5,a4
    8000506a:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd0d0>
  sp -= (argc+1) * sizeof(uint64);
    8000506e:	00148693          	addi	a3,s1,1
    80005072:	068e                	slli	a3,a3,0x3
    80005074:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005078:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000507c:	01597663          	bgeu	s2,s5,80005088 <exec+0x252>
  sz = sz1;
    80005080:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005084:	4a81                	li	s5,0
    80005086:	a059                	j	8000510c <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005088:	e9040613          	addi	a2,s0,-368
    8000508c:	85ca                	mv	a1,s2
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	7a2080e7          	jalr	1954(ra) # 80001832 <copyout>
    80005098:	0a054963          	bltz	a0,8000514a <exec+0x314>
  p->trapframe->a1 = sp;
    8000509c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050a0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050a4:	de843783          	ld	a5,-536(s0)
    800050a8:	0007c703          	lbu	a4,0(a5)
    800050ac:	cf11                	beqz	a4,800050c8 <exec+0x292>
    800050ae:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050b0:	02f00693          	li	a3,47
    800050b4:	a039                	j	800050c2 <exec+0x28c>
      last = s+1;
    800050b6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050ba:	0785                	addi	a5,a5,1
    800050bc:	fff7c703          	lbu	a4,-1(a5)
    800050c0:	c701                	beqz	a4,800050c8 <exec+0x292>
    if(*s == '/')
    800050c2:	fed71ce3          	bne	a4,a3,800050ba <exec+0x284>
    800050c6:	bfc5                	j	800050b6 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800050c8:	4641                	li	a2,16
    800050ca:	de843583          	ld	a1,-536(s0)
    800050ce:	158b8513          	addi	a0,s7,344
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	f14080e7          	jalr	-236(ra) # 80000fe6 <safestrcpy>
  oldpagetable = p->pagetable;
    800050da:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050de:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050e2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050e6:	058bb783          	ld	a5,88(s7)
    800050ea:	e6843703          	ld	a4,-408(s0)
    800050ee:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050f0:	058bb783          	ld	a5,88(s7)
    800050f4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050f8:	85ea                	mv	a1,s10
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	bdc080e7          	jalr	-1060(ra) # 80001cd6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005102:	0004851b          	sext.w	a0,s1
    80005106:	b3f1                	j	80004ed2 <exec+0x9c>
    80005108:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000510c:	df843583          	ld	a1,-520(s0)
    80005110:	855a                	mv	a0,s6
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	bc4080e7          	jalr	-1084(ra) # 80001cd6 <proc_freepagetable>
  if(ip){
    8000511a:	da0a92e3          	bnez	s5,80004ebe <exec+0x88>
  return -1;
    8000511e:	557d                	li	a0,-1
    80005120:	bb4d                	j	80004ed2 <exec+0x9c>
    80005122:	df243c23          	sd	s2,-520(s0)
    80005126:	b7dd                	j	8000510c <exec+0x2d6>
    80005128:	df243c23          	sd	s2,-520(s0)
    8000512c:	b7c5                	j	8000510c <exec+0x2d6>
    8000512e:	df243c23          	sd	s2,-520(s0)
    80005132:	bfe9                	j	8000510c <exec+0x2d6>
    80005134:	df243c23          	sd	s2,-520(s0)
    80005138:	bfd1                	j	8000510c <exec+0x2d6>
  sz = sz1;
    8000513a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000513e:	4a81                	li	s5,0
    80005140:	b7f1                	j	8000510c <exec+0x2d6>
  sz = sz1;
    80005142:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005146:	4a81                	li	s5,0
    80005148:	b7d1                	j	8000510c <exec+0x2d6>
  sz = sz1;
    8000514a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000514e:	4a81                	li	s5,0
    80005150:	bf75                	j	8000510c <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005152:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005156:	e0843783          	ld	a5,-504(s0)
    8000515a:	0017869b          	addiw	a3,a5,1
    8000515e:	e0d43423          	sd	a3,-504(s0)
    80005162:	e0043783          	ld	a5,-512(s0)
    80005166:	0387879b          	addiw	a5,a5,56
    8000516a:	e8845703          	lhu	a4,-376(s0)
    8000516e:	e0e6dee3          	bge	a3,a4,80004f8a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005172:	2781                	sext.w	a5,a5
    80005174:	e0f43023          	sd	a5,-512(s0)
    80005178:	03800713          	li	a4,56
    8000517c:	86be                	mv	a3,a5
    8000517e:	e1840613          	addi	a2,s0,-488
    80005182:	4581                	li	a1,0
    80005184:	8556                	mv	a0,s5
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	a5c080e7          	jalr	-1444(ra) # 80003be2 <readi>
    8000518e:	03800793          	li	a5,56
    80005192:	f6f51be3          	bne	a0,a5,80005108 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005196:	e1842783          	lw	a5,-488(s0)
    8000519a:	4705                	li	a4,1
    8000519c:	fae79de3          	bne	a5,a4,80005156 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800051a0:	e4043483          	ld	s1,-448(s0)
    800051a4:	e3843783          	ld	a5,-456(s0)
    800051a8:	f6f4ede3          	bltu	s1,a5,80005122 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051ac:	e2843783          	ld	a5,-472(s0)
    800051b0:	94be                	add	s1,s1,a5
    800051b2:	f6f4ebe3          	bltu	s1,a5,80005128 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800051b6:	de043703          	ld	a4,-544(s0)
    800051ba:	8ff9                	and	a5,a5,a4
    800051bc:	fbad                	bnez	a5,8000512e <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051be:	e1c42503          	lw	a0,-484(s0)
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	c58080e7          	jalr	-936(ra) # 80004e1a <flags2perm>
    800051ca:	86aa                	mv	a3,a0
    800051cc:	8626                	mv	a2,s1
    800051ce:	85ca                	mv	a1,s2
    800051d0:	855a                	mv	a0,s6
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	408080e7          	jalr	1032(ra) # 800015da <uvmalloc>
    800051da:	dea43c23          	sd	a0,-520(s0)
    800051de:	d939                	beqz	a0,80005134 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e0:	e2843c03          	ld	s8,-472(s0)
    800051e4:	e2042c83          	lw	s9,-480(s0)
    800051e8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051ec:	f60b83e3          	beqz	s7,80005152 <exec+0x31c>
    800051f0:	89de                	mv	s3,s7
    800051f2:	4481                	li	s1,0
    800051f4:	bb95                	j	80004f68 <exec+0x132>

00000000800051f6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f6:	7179                	addi	sp,sp,-48
    800051f8:	f406                	sd	ra,40(sp)
    800051fa:	f022                	sd	s0,32(sp)
    800051fc:	ec26                	sd	s1,24(sp)
    800051fe:	e84a                	sd	s2,16(sp)
    80005200:	1800                	addi	s0,sp,48
    80005202:	892e                	mv	s2,a1
    80005204:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005206:	fdc40593          	addi	a1,s0,-36
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	ad4080e7          	jalr	-1324(ra) # 80002cde <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005212:	fdc42703          	lw	a4,-36(s0)
    80005216:	47bd                	li	a5,15
    80005218:	02e7eb63          	bltu	a5,a4,8000524e <argfd+0x58>
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	95a080e7          	jalr	-1702(ra) # 80001b76 <myproc>
    80005224:	fdc42703          	lw	a4,-36(s0)
    80005228:	01a70793          	addi	a5,a4,26
    8000522c:	078e                	slli	a5,a5,0x3
    8000522e:	953e                	add	a0,a0,a5
    80005230:	611c                	ld	a5,0(a0)
    80005232:	c385                	beqz	a5,80005252 <argfd+0x5c>
    return -1;
  if(pfd)
    80005234:	00090463          	beqz	s2,8000523c <argfd+0x46>
    *pfd = fd;
    80005238:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523c:	4501                	li	a0,0
  if(pf)
    8000523e:	c091                	beqz	s1,80005242 <argfd+0x4c>
    *pf = f;
    80005240:	e09c                	sd	a5,0(s1)
}
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	64e2                	ld	s1,24(sp)
    80005248:	6942                	ld	s2,16(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret
    return -1;
    8000524e:	557d                	li	a0,-1
    80005250:	bfcd                	j	80005242 <argfd+0x4c>
    80005252:	557d                	li	a0,-1
    80005254:	b7fd                	j	80005242 <argfd+0x4c>

0000000080005256 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005256:	1101                	addi	sp,sp,-32
    80005258:	ec06                	sd	ra,24(sp)
    8000525a:	e822                	sd	s0,16(sp)
    8000525c:	e426                	sd	s1,8(sp)
    8000525e:	1000                	addi	s0,sp,32
    80005260:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005262:	ffffd097          	auipc	ra,0xffffd
    80005266:	914080e7          	jalr	-1772(ra) # 80001b76 <myproc>
    8000526a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000526c:	0d050793          	addi	a5,a0,208
    80005270:	4501                	li	a0,0
    80005272:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005274:	6398                	ld	a4,0(a5)
    80005276:	cb19                	beqz	a4,8000528c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005278:	2505                	addiw	a0,a0,1
    8000527a:	07a1                	addi	a5,a5,8
    8000527c:	fed51ce3          	bne	a0,a3,80005274 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005280:	557d                	li	a0,-1
}
    80005282:	60e2                	ld	ra,24(sp)
    80005284:	6442                	ld	s0,16(sp)
    80005286:	64a2                	ld	s1,8(sp)
    80005288:	6105                	addi	sp,sp,32
    8000528a:	8082                	ret
      p->ofile[fd] = f;
    8000528c:	01a50793          	addi	a5,a0,26
    80005290:	078e                	slli	a5,a5,0x3
    80005292:	963e                	add	a2,a2,a5
    80005294:	e204                	sd	s1,0(a2)
      return fd;
    80005296:	b7f5                	j	80005282 <fdalloc+0x2c>

0000000080005298 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005298:	715d                	addi	sp,sp,-80
    8000529a:	e486                	sd	ra,72(sp)
    8000529c:	e0a2                	sd	s0,64(sp)
    8000529e:	fc26                	sd	s1,56(sp)
    800052a0:	f84a                	sd	s2,48(sp)
    800052a2:	f44e                	sd	s3,40(sp)
    800052a4:	f052                	sd	s4,32(sp)
    800052a6:	ec56                	sd	s5,24(sp)
    800052a8:	e85a                	sd	s6,16(sp)
    800052aa:	0880                	addi	s0,sp,80
    800052ac:	8b2e                	mv	s6,a1
    800052ae:	89b2                	mv	s3,a2
    800052b0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	e3c080e7          	jalr	-452(ra) # 800040f2 <nameiparent>
    800052be:	84aa                	mv	s1,a0
    800052c0:	14050f63          	beqz	a0,8000541e <create+0x186>
    return 0;

  ilock(dp);
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	66a080e7          	jalr	1642(ra) # 8000392e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052cc:	4601                	li	a2,0
    800052ce:	fb040593          	addi	a1,s0,-80
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	b3e080e7          	jalr	-1218(ra) # 80003e12 <dirlookup>
    800052dc:	8aaa                	mv	s5,a0
    800052de:	c931                	beqz	a0,80005332 <create+0x9a>
    iunlockput(dp);
    800052e0:	8526                	mv	a0,s1
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	8ae080e7          	jalr	-1874(ra) # 80003b90 <iunlockput>
    ilock(ip);
    800052ea:	8556                	mv	a0,s5
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	642080e7          	jalr	1602(ra) # 8000392e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f4:	000b059b          	sext.w	a1,s6
    800052f8:	4789                	li	a5,2
    800052fa:	02f59563          	bne	a1,a5,80005324 <create+0x8c>
    800052fe:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd214>
    80005302:	37f9                	addiw	a5,a5,-2
    80005304:	17c2                	slli	a5,a5,0x30
    80005306:	93c1                	srli	a5,a5,0x30
    80005308:	4705                	li	a4,1
    8000530a:	00f76d63          	bltu	a4,a5,80005324 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000530e:	8556                	mv	a0,s5
    80005310:	60a6                	ld	ra,72(sp)
    80005312:	6406                	ld	s0,64(sp)
    80005314:	74e2                	ld	s1,56(sp)
    80005316:	7942                	ld	s2,48(sp)
    80005318:	79a2                	ld	s3,40(sp)
    8000531a:	7a02                	ld	s4,32(sp)
    8000531c:	6ae2                	ld	s5,24(sp)
    8000531e:	6b42                	ld	s6,16(sp)
    80005320:	6161                	addi	sp,sp,80
    80005322:	8082                	ret
    iunlockput(ip);
    80005324:	8556                	mv	a0,s5
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	86a080e7          	jalr	-1942(ra) # 80003b90 <iunlockput>
    return 0;
    8000532e:	4a81                	li	s5,0
    80005330:	bff9                	j	8000530e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005332:	85da                	mv	a1,s6
    80005334:	4088                	lw	a0,0(s1)
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	45c080e7          	jalr	1116(ra) # 80003792 <ialloc>
    8000533e:	8a2a                	mv	s4,a0
    80005340:	c539                	beqz	a0,8000538e <create+0xf6>
  ilock(ip);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	5ec080e7          	jalr	1516(ra) # 8000392e <ilock>
  ip->major = major;
    8000534a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000534e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005352:	4905                	li	s2,1
    80005354:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005358:	8552                	mv	a0,s4
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	50a080e7          	jalr	1290(ra) # 80003864 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005362:	000b059b          	sext.w	a1,s6
    80005366:	03258b63          	beq	a1,s2,8000539c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000536a:	004a2603          	lw	a2,4(s4)
    8000536e:	fb040593          	addi	a1,s0,-80
    80005372:	8526                	mv	a0,s1
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	cae080e7          	jalr	-850(ra) # 80004022 <dirlink>
    8000537c:	06054f63          	bltz	a0,800053fa <create+0x162>
  iunlockput(dp);
    80005380:	8526                	mv	a0,s1
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	80e080e7          	jalr	-2034(ra) # 80003b90 <iunlockput>
  return ip;
    8000538a:	8ad2                	mv	s5,s4
    8000538c:	b749                	j	8000530e <create+0x76>
    iunlockput(dp);
    8000538e:	8526                	mv	a0,s1
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	800080e7          	jalr	-2048(ra) # 80003b90 <iunlockput>
    return 0;
    80005398:	8ad2                	mv	s5,s4
    8000539a:	bf95                	j	8000530e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000539c:	004a2603          	lw	a2,4(s4)
    800053a0:	00003597          	auipc	a1,0x3
    800053a4:	42058593          	addi	a1,a1,1056 # 800087c0 <syscalls+0x330>
    800053a8:	8552                	mv	a0,s4
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	c78080e7          	jalr	-904(ra) # 80004022 <dirlink>
    800053b2:	04054463          	bltz	a0,800053fa <create+0x162>
    800053b6:	40d0                	lw	a2,4(s1)
    800053b8:	00003597          	auipc	a1,0x3
    800053bc:	41058593          	addi	a1,a1,1040 # 800087c8 <syscalls+0x338>
    800053c0:	8552                	mv	a0,s4
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	c60080e7          	jalr	-928(ra) # 80004022 <dirlink>
    800053ca:	02054863          	bltz	a0,800053fa <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ce:	004a2603          	lw	a2,4(s4)
    800053d2:	fb040593          	addi	a1,s0,-80
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	c4a080e7          	jalr	-950(ra) # 80004022 <dirlink>
    800053e0:	00054d63          	bltz	a0,800053fa <create+0x162>
    dp->nlink++;  // for ".."
    800053e4:	04a4d783          	lhu	a5,74(s1)
    800053e8:	2785                	addiw	a5,a5,1
    800053ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053ee:	8526                	mv	a0,s1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	474080e7          	jalr	1140(ra) # 80003864 <iupdate>
    800053f8:	b761                	j	80005380 <create+0xe8>
  ip->nlink = 0;
    800053fa:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053fe:	8552                	mv	a0,s4
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	464080e7          	jalr	1124(ra) # 80003864 <iupdate>
  iunlockput(ip);
    80005408:	8552                	mv	a0,s4
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	786080e7          	jalr	1926(ra) # 80003b90 <iunlockput>
  iunlockput(dp);
    80005412:	8526                	mv	a0,s1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	77c080e7          	jalr	1916(ra) # 80003b90 <iunlockput>
  return 0;
    8000541c:	bdcd                	j	8000530e <create+0x76>
    return 0;
    8000541e:	8aaa                	mv	s5,a0
    80005420:	b5fd                	j	8000530e <create+0x76>

0000000080005422 <sys_dup>:
{
    80005422:	7179                	addi	sp,sp,-48
    80005424:	f406                	sd	ra,40(sp)
    80005426:	f022                	sd	s0,32(sp)
    80005428:	ec26                	sd	s1,24(sp)
    8000542a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000542c:	fd840613          	addi	a2,s0,-40
    80005430:	4581                	li	a1,0
    80005432:	4501                	li	a0,0
    80005434:	00000097          	auipc	ra,0x0
    80005438:	dc2080e7          	jalr	-574(ra) # 800051f6 <argfd>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000543e:	02054363          	bltz	a0,80005464 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005442:	fd843503          	ld	a0,-40(s0)
    80005446:	00000097          	auipc	ra,0x0
    8000544a:	e10080e7          	jalr	-496(ra) # 80005256 <fdalloc>
    8000544e:	84aa                	mv	s1,a0
    return -1;
    80005450:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005452:	00054963          	bltz	a0,80005464 <sys_dup+0x42>
  filedup(f);
    80005456:	fd843503          	ld	a0,-40(s0)
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	310080e7          	jalr	784(ra) # 8000476a <filedup>
  return fd;
    80005462:	87a6                	mv	a5,s1
}
    80005464:	853e                	mv	a0,a5
    80005466:	70a2                	ld	ra,40(sp)
    80005468:	7402                	ld	s0,32(sp)
    8000546a:	64e2                	ld	s1,24(sp)
    8000546c:	6145                	addi	sp,sp,48
    8000546e:	8082                	ret

0000000080005470 <sys_read>:
{
    80005470:	7179                	addi	sp,sp,-48
    80005472:	f406                	sd	ra,40(sp)
    80005474:	f022                	sd	s0,32(sp)
    80005476:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005478:	fd840593          	addi	a1,s0,-40
    8000547c:	4505                	li	a0,1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	880080e7          	jalr	-1920(ra) # 80002cfe <argaddr>
  argint(2, &n);
    80005486:	fe440593          	addi	a1,s0,-28
    8000548a:	4509                	li	a0,2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	852080e7          	jalr	-1966(ra) # 80002cde <argint>
  if(argfd(0, 0, &f) < 0)
    80005494:	fe840613          	addi	a2,s0,-24
    80005498:	4581                	li	a1,0
    8000549a:	4501                	li	a0,0
    8000549c:	00000097          	auipc	ra,0x0
    800054a0:	d5a080e7          	jalr	-678(ra) # 800051f6 <argfd>
    800054a4:	87aa                	mv	a5,a0
    return -1;
    800054a6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054a8:	0007cc63          	bltz	a5,800054c0 <sys_read+0x50>
  return fileread(f, p, n);
    800054ac:	fe442603          	lw	a2,-28(s0)
    800054b0:	fd843583          	ld	a1,-40(s0)
    800054b4:	fe843503          	ld	a0,-24(s0)
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	43e080e7          	jalr	1086(ra) # 800048f6 <fileread>
}
    800054c0:	70a2                	ld	ra,40(sp)
    800054c2:	7402                	ld	s0,32(sp)
    800054c4:	6145                	addi	sp,sp,48
    800054c6:	8082                	ret

00000000800054c8 <sys_write>:
{
    800054c8:	7179                	addi	sp,sp,-48
    800054ca:	f406                	sd	ra,40(sp)
    800054cc:	f022                	sd	s0,32(sp)
    800054ce:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054d0:	fd840593          	addi	a1,s0,-40
    800054d4:	4505                	li	a0,1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	828080e7          	jalr	-2008(ra) # 80002cfe <argaddr>
  argint(2, &n);
    800054de:	fe440593          	addi	a1,s0,-28
    800054e2:	4509                	li	a0,2
    800054e4:	ffffd097          	auipc	ra,0xffffd
    800054e8:	7fa080e7          	jalr	2042(ra) # 80002cde <argint>
  if(argfd(0, 0, &f) < 0)
    800054ec:	fe840613          	addi	a2,s0,-24
    800054f0:	4581                	li	a1,0
    800054f2:	4501                	li	a0,0
    800054f4:	00000097          	auipc	ra,0x0
    800054f8:	d02080e7          	jalr	-766(ra) # 800051f6 <argfd>
    800054fc:	87aa                	mv	a5,a0
    return -1;
    800054fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005500:	0007cc63          	bltz	a5,80005518 <sys_write+0x50>
  return filewrite(f, p, n);
    80005504:	fe442603          	lw	a2,-28(s0)
    80005508:	fd843583          	ld	a1,-40(s0)
    8000550c:	fe843503          	ld	a0,-24(s0)
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	4a8080e7          	jalr	1192(ra) # 800049b8 <filewrite>
}
    80005518:	70a2                	ld	ra,40(sp)
    8000551a:	7402                	ld	s0,32(sp)
    8000551c:	6145                	addi	sp,sp,48
    8000551e:	8082                	ret

0000000080005520 <sys_close>:
{
    80005520:	1101                	addi	sp,sp,-32
    80005522:	ec06                	sd	ra,24(sp)
    80005524:	e822                	sd	s0,16(sp)
    80005526:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005528:	fe040613          	addi	a2,s0,-32
    8000552c:	fec40593          	addi	a1,s0,-20
    80005530:	4501                	li	a0,0
    80005532:	00000097          	auipc	ra,0x0
    80005536:	cc4080e7          	jalr	-828(ra) # 800051f6 <argfd>
    return -1;
    8000553a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000553c:	02054463          	bltz	a0,80005564 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005540:	ffffc097          	auipc	ra,0xffffc
    80005544:	636080e7          	jalr	1590(ra) # 80001b76 <myproc>
    80005548:	fec42783          	lw	a5,-20(s0)
    8000554c:	07e9                	addi	a5,a5,26
    8000554e:	078e                	slli	a5,a5,0x3
    80005550:	97aa                	add	a5,a5,a0
    80005552:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005556:	fe043503          	ld	a0,-32(s0)
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	262080e7          	jalr	610(ra) # 800047bc <fileclose>
  return 0;
    80005562:	4781                	li	a5,0
}
    80005564:	853e                	mv	a0,a5
    80005566:	60e2                	ld	ra,24(sp)
    80005568:	6442                	ld	s0,16(sp)
    8000556a:	6105                	addi	sp,sp,32
    8000556c:	8082                	ret

000000008000556e <sys_fstat>:
{
    8000556e:	1101                	addi	sp,sp,-32
    80005570:	ec06                	sd	ra,24(sp)
    80005572:	e822                	sd	s0,16(sp)
    80005574:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005576:	fe040593          	addi	a1,s0,-32
    8000557a:	4505                	li	a0,1
    8000557c:	ffffd097          	auipc	ra,0xffffd
    80005580:	782080e7          	jalr	1922(ra) # 80002cfe <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005584:	fe840613          	addi	a2,s0,-24
    80005588:	4581                	li	a1,0
    8000558a:	4501                	li	a0,0
    8000558c:	00000097          	auipc	ra,0x0
    80005590:	c6a080e7          	jalr	-918(ra) # 800051f6 <argfd>
    80005594:	87aa                	mv	a5,a0
    return -1;
    80005596:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005598:	0007ca63          	bltz	a5,800055ac <sys_fstat+0x3e>
  return filestat(f, st);
    8000559c:	fe043583          	ld	a1,-32(s0)
    800055a0:	fe843503          	ld	a0,-24(s0)
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	2e0080e7          	jalr	736(ra) # 80004884 <filestat>
}
    800055ac:	60e2                	ld	ra,24(sp)
    800055ae:	6442                	ld	s0,16(sp)
    800055b0:	6105                	addi	sp,sp,32
    800055b2:	8082                	ret

00000000800055b4 <sys_link>:
{
    800055b4:	7169                	addi	sp,sp,-304
    800055b6:	f606                	sd	ra,296(sp)
    800055b8:	f222                	sd	s0,288(sp)
    800055ba:	ee26                	sd	s1,280(sp)
    800055bc:	ea4a                	sd	s2,272(sp)
    800055be:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c0:	08000613          	li	a2,128
    800055c4:	ed040593          	addi	a1,s0,-304
    800055c8:	4501                	li	a0,0
    800055ca:	ffffd097          	auipc	ra,0xffffd
    800055ce:	754080e7          	jalr	1876(ra) # 80002d1e <argstr>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d4:	10054e63          	bltz	a0,800056f0 <sys_link+0x13c>
    800055d8:	08000613          	li	a2,128
    800055dc:	f5040593          	addi	a1,s0,-176
    800055e0:	4505                	li	a0,1
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	73c080e7          	jalr	1852(ra) # 80002d1e <argstr>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ec:	10054263          	bltz	a0,800056f0 <sys_link+0x13c>
  begin_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	d00080e7          	jalr	-768(ra) # 800042f0 <begin_op>
  if((ip = namei(old)) == 0){
    800055f8:	ed040513          	addi	a0,s0,-304
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	ad8080e7          	jalr	-1320(ra) # 800040d4 <namei>
    80005604:	84aa                	mv	s1,a0
    80005606:	c551                	beqz	a0,80005692 <sys_link+0xde>
  ilock(ip);
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	326080e7          	jalr	806(ra) # 8000392e <ilock>
  if(ip->type == T_DIR){
    80005610:	04449703          	lh	a4,68(s1)
    80005614:	4785                	li	a5,1
    80005616:	08f70463          	beq	a4,a5,8000569e <sys_link+0xea>
  ip->nlink++;
    8000561a:	04a4d783          	lhu	a5,74(s1)
    8000561e:	2785                	addiw	a5,a5,1
    80005620:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	23e080e7          	jalr	574(ra) # 80003864 <iupdate>
  iunlock(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	3c0080e7          	jalr	960(ra) # 800039f0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005638:	fd040593          	addi	a1,s0,-48
    8000563c:	f5040513          	addi	a0,s0,-176
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	ab2080e7          	jalr	-1358(ra) # 800040f2 <nameiparent>
    80005648:	892a                	mv	s2,a0
    8000564a:	c935                	beqz	a0,800056be <sys_link+0x10a>
  ilock(dp);
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	2e2080e7          	jalr	738(ra) # 8000392e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005654:	00092703          	lw	a4,0(s2)
    80005658:	409c                	lw	a5,0(s1)
    8000565a:	04f71d63          	bne	a4,a5,800056b4 <sys_link+0x100>
    8000565e:	40d0                	lw	a2,4(s1)
    80005660:	fd040593          	addi	a1,s0,-48
    80005664:	854a                	mv	a0,s2
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	9bc080e7          	jalr	-1604(ra) # 80004022 <dirlink>
    8000566e:	04054363          	bltz	a0,800056b4 <sys_link+0x100>
  iunlockput(dp);
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	51c080e7          	jalr	1308(ra) # 80003b90 <iunlockput>
  iput(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	46a080e7          	jalr	1130(ra) # 80003ae8 <iput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	cea080e7          	jalr	-790(ra) # 80004370 <end_op>
  return 0;
    8000568e:	4781                	li	a5,0
    80005690:	a085                	j	800056f0 <sys_link+0x13c>
    end_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	cde080e7          	jalr	-802(ra) # 80004370 <end_op>
    return -1;
    8000569a:	57fd                	li	a5,-1
    8000569c:	a891                	j	800056f0 <sys_link+0x13c>
    iunlockput(ip);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	4f0080e7          	jalr	1264(ra) # 80003b90 <iunlockput>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	cc8080e7          	jalr	-824(ra) # 80004370 <end_op>
    return -1;
    800056b0:	57fd                	li	a5,-1
    800056b2:	a83d                	j	800056f0 <sys_link+0x13c>
    iunlockput(dp);
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	4da080e7          	jalr	1242(ra) # 80003b90 <iunlockput>
  ilock(ip);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	26e080e7          	jalr	622(ra) # 8000392e <ilock>
  ip->nlink--;
    800056c8:	04a4d783          	lhu	a5,74(s1)
    800056cc:	37fd                	addiw	a5,a5,-1
    800056ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	190080e7          	jalr	400(ra) # 80003864 <iupdate>
  iunlockput(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	4b2080e7          	jalr	1202(ra) # 80003b90 <iunlockput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	c8a080e7          	jalr	-886(ra) # 80004370 <end_op>
  return -1;
    800056ee:	57fd                	li	a5,-1
}
    800056f0:	853e                	mv	a0,a5
    800056f2:	70b2                	ld	ra,296(sp)
    800056f4:	7412                	ld	s0,288(sp)
    800056f6:	64f2                	ld	s1,280(sp)
    800056f8:	6952                	ld	s2,272(sp)
    800056fa:	6155                	addi	sp,sp,304
    800056fc:	8082                	ret

00000000800056fe <sys_unlink>:
{
    800056fe:	7151                	addi	sp,sp,-240
    80005700:	f586                	sd	ra,232(sp)
    80005702:	f1a2                	sd	s0,224(sp)
    80005704:	eda6                	sd	s1,216(sp)
    80005706:	e9ca                	sd	s2,208(sp)
    80005708:	e5ce                	sd	s3,200(sp)
    8000570a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000570c:	08000613          	li	a2,128
    80005710:	f3040593          	addi	a1,s0,-208
    80005714:	4501                	li	a0,0
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	608080e7          	jalr	1544(ra) # 80002d1e <argstr>
    8000571e:	18054163          	bltz	a0,800058a0 <sys_unlink+0x1a2>
  begin_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	bce080e7          	jalr	-1074(ra) # 800042f0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000572a:	fb040593          	addi	a1,s0,-80
    8000572e:	f3040513          	addi	a0,s0,-208
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	9c0080e7          	jalr	-1600(ra) # 800040f2 <nameiparent>
    8000573a:	84aa                	mv	s1,a0
    8000573c:	c979                	beqz	a0,80005812 <sys_unlink+0x114>
  ilock(dp);
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	1f0080e7          	jalr	496(ra) # 8000392e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005746:	00003597          	auipc	a1,0x3
    8000574a:	07a58593          	addi	a1,a1,122 # 800087c0 <syscalls+0x330>
    8000574e:	fb040513          	addi	a0,s0,-80
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	6a6080e7          	jalr	1702(ra) # 80003df8 <namecmp>
    8000575a:	14050a63          	beqz	a0,800058ae <sys_unlink+0x1b0>
    8000575e:	00003597          	auipc	a1,0x3
    80005762:	06a58593          	addi	a1,a1,106 # 800087c8 <syscalls+0x338>
    80005766:	fb040513          	addi	a0,s0,-80
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	68e080e7          	jalr	1678(ra) # 80003df8 <namecmp>
    80005772:	12050e63          	beqz	a0,800058ae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005776:	f2c40613          	addi	a2,s0,-212
    8000577a:	fb040593          	addi	a1,s0,-80
    8000577e:	8526                	mv	a0,s1
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	692080e7          	jalr	1682(ra) # 80003e12 <dirlookup>
    80005788:	892a                	mv	s2,a0
    8000578a:	12050263          	beqz	a0,800058ae <sys_unlink+0x1b0>
  ilock(ip);
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	1a0080e7          	jalr	416(ra) # 8000392e <ilock>
  if(ip->nlink < 1)
    80005796:	04a91783          	lh	a5,74(s2)
    8000579a:	08f05263          	blez	a5,8000581e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000579e:	04491703          	lh	a4,68(s2)
    800057a2:	4785                	li	a5,1
    800057a4:	08f70563          	beq	a4,a5,8000582e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057a8:	4641                	li	a2,16
    800057aa:	4581                	li	a1,0
    800057ac:	fc040513          	addi	a0,s0,-64
    800057b0:	ffffb097          	auipc	ra,0xffffb
    800057b4:	6ec080e7          	jalr	1772(ra) # 80000e9c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b8:	4741                	li	a4,16
    800057ba:	f2c42683          	lw	a3,-212(s0)
    800057be:	fc040613          	addi	a2,s0,-64
    800057c2:	4581                	li	a1,0
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	514080e7          	jalr	1300(ra) # 80003cda <writei>
    800057ce:	47c1                	li	a5,16
    800057d0:	0af51563          	bne	a0,a5,8000587a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d4:	04491703          	lh	a4,68(s2)
    800057d8:	4785                	li	a5,1
    800057da:	0af70863          	beq	a4,a5,8000588a <sys_unlink+0x18c>
  iunlockput(dp);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	3b0080e7          	jalr	944(ra) # 80003b90 <iunlockput>
  ip->nlink--;
    800057e8:	04a95783          	lhu	a5,74(s2)
    800057ec:	37fd                	addiw	a5,a5,-1
    800057ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f2:	854a                	mv	a0,s2
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	070080e7          	jalr	112(ra) # 80003864 <iupdate>
  iunlockput(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	392080e7          	jalr	914(ra) # 80003b90 <iunlockput>
  end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	b6a080e7          	jalr	-1174(ra) # 80004370 <end_op>
  return 0;
    8000580e:	4501                	li	a0,0
    80005810:	a84d                	j	800058c2 <sys_unlink+0x1c4>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	b5e080e7          	jalr	-1186(ra) # 80004370 <end_op>
    return -1;
    8000581a:	557d                	li	a0,-1
    8000581c:	a05d                	j	800058c2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000581e:	00003517          	auipc	a0,0x3
    80005822:	fb250513          	addi	a0,a0,-78 # 800087d0 <syscalls+0x340>
    80005826:	ffffb097          	auipc	ra,0xffffb
    8000582a:	d18080e7          	jalr	-744(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582e:	04c92703          	lw	a4,76(s2)
    80005832:	02000793          	li	a5,32
    80005836:	f6e7f9e3          	bgeu	a5,a4,800057a8 <sys_unlink+0xaa>
    8000583a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583e:	4741                	li	a4,16
    80005840:	86ce                	mv	a3,s3
    80005842:	f1840613          	addi	a2,s0,-232
    80005846:	4581                	li	a1,0
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	398080e7          	jalr	920(ra) # 80003be2 <readi>
    80005852:	47c1                	li	a5,16
    80005854:	00f51b63          	bne	a0,a5,8000586a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005858:	f1845783          	lhu	a5,-232(s0)
    8000585c:	e7a1                	bnez	a5,800058a4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585e:	29c1                	addiw	s3,s3,16
    80005860:	04c92783          	lw	a5,76(s2)
    80005864:	fcf9ede3          	bltu	s3,a5,8000583e <sys_unlink+0x140>
    80005868:	b781                	j	800057a8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000586a:	00003517          	auipc	a0,0x3
    8000586e:	f7e50513          	addi	a0,a0,-130 # 800087e8 <syscalls+0x358>
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	ccc080e7          	jalr	-820(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000587a:	00003517          	auipc	a0,0x3
    8000587e:	f8650513          	addi	a0,a0,-122 # 80008800 <syscalls+0x370>
    80005882:	ffffb097          	auipc	ra,0xffffb
    80005886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>
    dp->nlink--;
    8000588a:	04a4d783          	lhu	a5,74(s1)
    8000588e:	37fd                	addiw	a5,a5,-1
    80005890:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	fce080e7          	jalr	-50(ra) # 80003864 <iupdate>
    8000589e:	b781                	j	800057de <sys_unlink+0xe0>
    return -1;
    800058a0:	557d                	li	a0,-1
    800058a2:	a005                	j	800058c2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	2ea080e7          	jalr	746(ra) # 80003b90 <iunlockput>
  iunlockput(dp);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	2e0080e7          	jalr	736(ra) # 80003b90 <iunlockput>
  end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	ab8080e7          	jalr	-1352(ra) # 80004370 <end_op>
  return -1;
    800058c0:	557d                	li	a0,-1
}
    800058c2:	70ae                	ld	ra,232(sp)
    800058c4:	740e                	ld	s0,224(sp)
    800058c6:	64ee                	ld	s1,216(sp)
    800058c8:	694e                	ld	s2,208(sp)
    800058ca:	69ae                	ld	s3,200(sp)
    800058cc:	616d                	addi	sp,sp,240
    800058ce:	8082                	ret

00000000800058d0 <sys_open>:

uint64
sys_open(void)
{
    800058d0:	7131                	addi	sp,sp,-192
    800058d2:	fd06                	sd	ra,184(sp)
    800058d4:	f922                	sd	s0,176(sp)
    800058d6:	f526                	sd	s1,168(sp)
    800058d8:	f14a                	sd	s2,160(sp)
    800058da:	ed4e                	sd	s3,152(sp)
    800058dc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058de:	f4c40593          	addi	a1,s0,-180
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	3fa080e7          	jalr	1018(ra) # 80002cde <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058ec:	08000613          	li	a2,128
    800058f0:	f5040593          	addi	a1,s0,-176
    800058f4:	4501                	li	a0,0
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	428080e7          	jalr	1064(ra) # 80002d1e <argstr>
    800058fe:	87aa                	mv	a5,a0
    return -1;
    80005900:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005902:	0a07c963          	bltz	a5,800059b4 <sys_open+0xe4>

  begin_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	9ea080e7          	jalr	-1558(ra) # 800042f0 <begin_op>

  if(omode & O_CREATE){
    8000590e:	f4c42783          	lw	a5,-180(s0)
    80005912:	2007f793          	andi	a5,a5,512
    80005916:	cfc5                	beqz	a5,800059ce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005918:	4681                	li	a3,0
    8000591a:	4601                	li	a2,0
    8000591c:	4589                	li	a1,2
    8000591e:	f5040513          	addi	a0,s0,-176
    80005922:	00000097          	auipc	ra,0x0
    80005926:	976080e7          	jalr	-1674(ra) # 80005298 <create>
    8000592a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000592c:	c959                	beqz	a0,800059c2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000592e:	04449703          	lh	a4,68(s1)
    80005932:	478d                	li	a5,3
    80005934:	00f71763          	bne	a4,a5,80005942 <sys_open+0x72>
    80005938:	0464d703          	lhu	a4,70(s1)
    8000593c:	47a5                	li	a5,9
    8000593e:	0ce7ed63          	bltu	a5,a4,80005a18 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	dbe080e7          	jalr	-578(ra) # 80004700 <filealloc>
    8000594a:	89aa                	mv	s3,a0
    8000594c:	10050363          	beqz	a0,80005a52 <sys_open+0x182>
    80005950:	00000097          	auipc	ra,0x0
    80005954:	906080e7          	jalr	-1786(ra) # 80005256 <fdalloc>
    80005958:	892a                	mv	s2,a0
    8000595a:	0e054763          	bltz	a0,80005a48 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000595e:	04449703          	lh	a4,68(s1)
    80005962:	478d                	li	a5,3
    80005964:	0cf70563          	beq	a4,a5,80005a2e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005968:	4789                	li	a5,2
    8000596a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000596e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005972:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005976:	f4c42783          	lw	a5,-180(s0)
    8000597a:	0017c713          	xori	a4,a5,1
    8000597e:	8b05                	andi	a4,a4,1
    80005980:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005984:	0037f713          	andi	a4,a5,3
    80005988:	00e03733          	snez	a4,a4
    8000598c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005990:	4007f793          	andi	a5,a5,1024
    80005994:	c791                	beqz	a5,800059a0 <sys_open+0xd0>
    80005996:	04449703          	lh	a4,68(s1)
    8000599a:	4789                	li	a5,2
    8000599c:	0af70063          	beq	a4,a5,80005a3c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a0:	8526                	mv	a0,s1
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	04e080e7          	jalr	78(ra) # 800039f0 <iunlock>
  end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	9c6080e7          	jalr	-1594(ra) # 80004370 <end_op>

  return fd;
    800059b2:	854a                	mv	a0,s2
}
    800059b4:	70ea                	ld	ra,184(sp)
    800059b6:	744a                	ld	s0,176(sp)
    800059b8:	74aa                	ld	s1,168(sp)
    800059ba:	790a                	ld	s2,160(sp)
    800059bc:	69ea                	ld	s3,152(sp)
    800059be:	6129                	addi	sp,sp,192
    800059c0:	8082                	ret
      end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	9ae080e7          	jalr	-1618(ra) # 80004370 <end_op>
      return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	b7e5                	j	800059b4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059ce:	f5040513          	addi	a0,s0,-176
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	702080e7          	jalr	1794(ra) # 800040d4 <namei>
    800059da:	84aa                	mv	s1,a0
    800059dc:	c905                	beqz	a0,80005a0c <sys_open+0x13c>
    ilock(ip);
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	f50080e7          	jalr	-176(ra) # 8000392e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059e6:	04449703          	lh	a4,68(s1)
    800059ea:	4785                	li	a5,1
    800059ec:	f4f711e3          	bne	a4,a5,8000592e <sys_open+0x5e>
    800059f0:	f4c42783          	lw	a5,-180(s0)
    800059f4:	d7b9                	beqz	a5,80005942 <sys_open+0x72>
      iunlockput(ip);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	198080e7          	jalr	408(ra) # 80003b90 <iunlockput>
      end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	970080e7          	jalr	-1680(ra) # 80004370 <end_op>
      return -1;
    80005a08:	557d                	li	a0,-1
    80005a0a:	b76d                	j	800059b4 <sys_open+0xe4>
      end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	964080e7          	jalr	-1692(ra) # 80004370 <end_op>
      return -1;
    80005a14:	557d                	li	a0,-1
    80005a16:	bf79                	j	800059b4 <sys_open+0xe4>
    iunlockput(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	176080e7          	jalr	374(ra) # 80003b90 <iunlockput>
    end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	94e080e7          	jalr	-1714(ra) # 80004370 <end_op>
    return -1;
    80005a2a:	557d                	li	a0,-1
    80005a2c:	b761                	j	800059b4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a2e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a32:	04649783          	lh	a5,70(s1)
    80005a36:	02f99223          	sh	a5,36(s3)
    80005a3a:	bf25                	j	80005972 <sys_open+0xa2>
    itrunc(ip);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	ffe080e7          	jalr	-2(ra) # 80003a3c <itrunc>
    80005a46:	bfa9                	j	800059a0 <sys_open+0xd0>
      fileclose(f);
    80005a48:	854e                	mv	a0,s3
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	d72080e7          	jalr	-654(ra) # 800047bc <fileclose>
    iunlockput(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	13c080e7          	jalr	316(ra) # 80003b90 <iunlockput>
    end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	914080e7          	jalr	-1772(ra) # 80004370 <end_op>
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	b7b9                	j	800059b4 <sys_open+0xe4>

0000000080005a68 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a68:	7175                	addi	sp,sp,-144
    80005a6a:	e506                	sd	ra,136(sp)
    80005a6c:	e122                	sd	s0,128(sp)
    80005a6e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	880080e7          	jalr	-1920(ra) # 800042f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a78:	08000613          	li	a2,128
    80005a7c:	f7040593          	addi	a1,s0,-144
    80005a80:	4501                	li	a0,0
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	29c080e7          	jalr	668(ra) # 80002d1e <argstr>
    80005a8a:	02054963          	bltz	a0,80005abc <sys_mkdir+0x54>
    80005a8e:	4681                	li	a3,0
    80005a90:	4601                	li	a2,0
    80005a92:	4585                	li	a1,1
    80005a94:	f7040513          	addi	a0,s0,-144
    80005a98:	00000097          	auipc	ra,0x0
    80005a9c:	800080e7          	jalr	-2048(ra) # 80005298 <create>
    80005aa0:	cd11                	beqz	a0,80005abc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	0ee080e7          	jalr	238(ra) # 80003b90 <iunlockput>
  end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	8c6080e7          	jalr	-1850(ra) # 80004370 <end_op>
  return 0;
    80005ab2:	4501                	li	a0,0
}
    80005ab4:	60aa                	ld	ra,136(sp)
    80005ab6:	640a                	ld	s0,128(sp)
    80005ab8:	6149                	addi	sp,sp,144
    80005aba:	8082                	ret
    end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	8b4080e7          	jalr	-1868(ra) # 80004370 <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	b7fd                	j	80005ab4 <sys_mkdir+0x4c>

0000000080005ac8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac8:	7135                	addi	sp,sp,-160
    80005aca:	ed06                	sd	ra,152(sp)
    80005acc:	e922                	sd	s0,144(sp)
    80005ace:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	820080e7          	jalr	-2016(ra) # 800042f0 <begin_op>
  argint(1, &major);
    80005ad8:	f6c40593          	addi	a1,s0,-148
    80005adc:	4505                	li	a0,1
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	200080e7          	jalr	512(ra) # 80002cde <argint>
  argint(2, &minor);
    80005ae6:	f6840593          	addi	a1,s0,-152
    80005aea:	4509                	li	a0,2
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	1f2080e7          	jalr	498(ra) # 80002cde <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005af4:	08000613          	li	a2,128
    80005af8:	f7040593          	addi	a1,s0,-144
    80005afc:	4501                	li	a0,0
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	220080e7          	jalr	544(ra) # 80002d1e <argstr>
    80005b06:	02054b63          	bltz	a0,80005b3c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b0a:	f6841683          	lh	a3,-152(s0)
    80005b0e:	f6c41603          	lh	a2,-148(s0)
    80005b12:	458d                	li	a1,3
    80005b14:	f7040513          	addi	a0,s0,-144
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	780080e7          	jalr	1920(ra) # 80005298 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b20:	cd11                	beqz	a0,80005b3c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	06e080e7          	jalr	110(ra) # 80003b90 <iunlockput>
  end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	846080e7          	jalr	-1978(ra) # 80004370 <end_op>
  return 0;
    80005b32:	4501                	li	a0,0
}
    80005b34:	60ea                	ld	ra,152(sp)
    80005b36:	644a                	ld	s0,144(sp)
    80005b38:	610d                	addi	sp,sp,160
    80005b3a:	8082                	ret
    end_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	834080e7          	jalr	-1996(ra) # 80004370 <end_op>
    return -1;
    80005b44:	557d                	li	a0,-1
    80005b46:	b7fd                	j	80005b34 <sys_mknod+0x6c>

0000000080005b48 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b48:	7135                	addi	sp,sp,-160
    80005b4a:	ed06                	sd	ra,152(sp)
    80005b4c:	e922                	sd	s0,144(sp)
    80005b4e:	e526                	sd	s1,136(sp)
    80005b50:	e14a                	sd	s2,128(sp)
    80005b52:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	022080e7          	jalr	34(ra) # 80001b76 <myproc>
    80005b5c:	892a                	mv	s2,a0
  
  begin_op();
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	792080e7          	jalr	1938(ra) # 800042f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b66:	08000613          	li	a2,128
    80005b6a:	f6040593          	addi	a1,s0,-160
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	1ae080e7          	jalr	430(ra) # 80002d1e <argstr>
    80005b78:	04054b63          	bltz	a0,80005bce <sys_chdir+0x86>
    80005b7c:	f6040513          	addi	a0,s0,-160
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	554080e7          	jalr	1364(ra) # 800040d4 <namei>
    80005b88:	84aa                	mv	s1,a0
    80005b8a:	c131                	beqz	a0,80005bce <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	da2080e7          	jalr	-606(ra) # 8000392e <ilock>
  if(ip->type != T_DIR){
    80005b94:	04449703          	lh	a4,68(s1)
    80005b98:	4785                	li	a5,1
    80005b9a:	04f71063          	bne	a4,a5,80005bda <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	e50080e7          	jalr	-432(ra) # 800039f0 <iunlock>
  iput(p->cwd);
    80005ba8:	15093503          	ld	a0,336(s2)
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	f3c080e7          	jalr	-196(ra) # 80003ae8 <iput>
  end_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	7bc080e7          	jalr	1980(ra) # 80004370 <end_op>
  p->cwd = ip;
    80005bbc:	14993823          	sd	s1,336(s2)
  return 0;
    80005bc0:	4501                	li	a0,0
}
    80005bc2:	60ea                	ld	ra,152(sp)
    80005bc4:	644a                	ld	s0,144(sp)
    80005bc6:	64aa                	ld	s1,136(sp)
    80005bc8:	690a                	ld	s2,128(sp)
    80005bca:	610d                	addi	sp,sp,160
    80005bcc:	8082                	ret
    end_op();
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	7a2080e7          	jalr	1954(ra) # 80004370 <end_op>
    return -1;
    80005bd6:	557d                	li	a0,-1
    80005bd8:	b7ed                	j	80005bc2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	fb4080e7          	jalr	-76(ra) # 80003b90 <iunlockput>
    end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	78c080e7          	jalr	1932(ra) # 80004370 <end_op>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	bfd1                	j	80005bc2 <sys_chdir+0x7a>

0000000080005bf0 <sys_exec>:

uint64
sys_exec(void)
{
    80005bf0:	7145                	addi	sp,sp,-464
    80005bf2:	e786                	sd	ra,456(sp)
    80005bf4:	e3a2                	sd	s0,448(sp)
    80005bf6:	ff26                	sd	s1,440(sp)
    80005bf8:	fb4a                	sd	s2,432(sp)
    80005bfa:	f74e                	sd	s3,424(sp)
    80005bfc:	f352                	sd	s4,416(sp)
    80005bfe:	ef56                	sd	s5,408(sp)
    80005c00:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c02:	e3840593          	addi	a1,s0,-456
    80005c06:	4505                	li	a0,1
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	0f6080e7          	jalr	246(ra) # 80002cfe <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c10:	08000613          	li	a2,128
    80005c14:	f4040593          	addi	a1,s0,-192
    80005c18:	4501                	li	a0,0
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	104080e7          	jalr	260(ra) # 80002d1e <argstr>
    80005c22:	87aa                	mv	a5,a0
    return -1;
    80005c24:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c26:	0c07c263          	bltz	a5,80005cea <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c2a:	10000613          	li	a2,256
    80005c2e:	4581                	li	a1,0
    80005c30:	e4040513          	addi	a0,s0,-448
    80005c34:	ffffb097          	auipc	ra,0xffffb
    80005c38:	268080e7          	jalr	616(ra) # 80000e9c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c3c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c40:	89a6                	mv	s3,s1
    80005c42:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c44:	02000a13          	li	s4,32
    80005c48:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c4c:	00391793          	slli	a5,s2,0x3
    80005c50:	e3040593          	addi	a1,s0,-464
    80005c54:	e3843503          	ld	a0,-456(s0)
    80005c58:	953e                	add	a0,a0,a5
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	fe6080e7          	jalr	-26(ra) # 80002c40 <fetchaddr>
    80005c62:	02054a63          	bltz	a0,80005c96 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c66:	e3043783          	ld	a5,-464(s0)
    80005c6a:	c3b9                	beqz	a5,80005cb0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	e3e080e7          	jalr	-450(ra) # 80000aaa <kalloc>
    80005c74:	85aa                	mv	a1,a0
    80005c76:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c7a:	cd11                	beqz	a0,80005c96 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c7c:	6605                	lui	a2,0x1
    80005c7e:	e3043503          	ld	a0,-464(s0)
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	010080e7          	jalr	16(ra) # 80002c92 <fetchstr>
    80005c8a:	00054663          	bltz	a0,80005c96 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c8e:	0905                	addi	s2,s2,1
    80005c90:	09a1                	addi	s3,s3,8
    80005c92:	fb491be3          	bne	s2,s4,80005c48 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c96:	10048913          	addi	s2,s1,256
    80005c9a:	6088                	ld	a0,0(s1)
    80005c9c:	c531                	beqz	a0,80005ce8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c9e:	ffffb097          	auipc	ra,0xffffb
    80005ca2:	d4c080e7          	jalr	-692(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	04a1                	addi	s1,s1,8
    80005ca8:	ff2499e3          	bne	s1,s2,80005c9a <sys_exec+0xaa>
  return -1;
    80005cac:	557d                	li	a0,-1
    80005cae:	a835                	j	80005cea <sys_exec+0xfa>
      argv[i] = 0;
    80005cb0:	0a8e                	slli	s5,s5,0x3
    80005cb2:	fc040793          	addi	a5,s0,-64
    80005cb6:	9abe                	add	s5,s5,a5
    80005cb8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cbc:	e4040593          	addi	a1,s0,-448
    80005cc0:	f4040513          	addi	a0,s0,-192
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	172080e7          	jalr	370(ra) # 80004e36 <exec>
    80005ccc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cce:	10048993          	addi	s3,s1,256
    80005cd2:	6088                	ld	a0,0(s1)
    80005cd4:	c901                	beqz	a0,80005ce4 <sys_exec+0xf4>
    kfree(argv[i]);
    80005cd6:	ffffb097          	auipc	ra,0xffffb
    80005cda:	d14080e7          	jalr	-748(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cde:	04a1                	addi	s1,s1,8
    80005ce0:	ff3499e3          	bne	s1,s3,80005cd2 <sys_exec+0xe2>
  return ret;
    80005ce4:	854a                	mv	a0,s2
    80005ce6:	a011                	j	80005cea <sys_exec+0xfa>
  return -1;
    80005ce8:	557d                	li	a0,-1
}
    80005cea:	60be                	ld	ra,456(sp)
    80005cec:	641e                	ld	s0,448(sp)
    80005cee:	74fa                	ld	s1,440(sp)
    80005cf0:	795a                	ld	s2,432(sp)
    80005cf2:	79ba                	ld	s3,424(sp)
    80005cf4:	7a1a                	ld	s4,416(sp)
    80005cf6:	6afa                	ld	s5,408(sp)
    80005cf8:	6179                	addi	sp,sp,464
    80005cfa:	8082                	ret

0000000080005cfc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cfc:	7139                	addi	sp,sp,-64
    80005cfe:	fc06                	sd	ra,56(sp)
    80005d00:	f822                	sd	s0,48(sp)
    80005d02:	f426                	sd	s1,40(sp)
    80005d04:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d06:	ffffc097          	auipc	ra,0xffffc
    80005d0a:	e70080e7          	jalr	-400(ra) # 80001b76 <myproc>
    80005d0e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d10:	fd840593          	addi	a1,s0,-40
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	fe8080e7          	jalr	-24(ra) # 80002cfe <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d1e:	fc840593          	addi	a1,s0,-56
    80005d22:	fd040513          	addi	a0,s0,-48
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	dc6080e7          	jalr	-570(ra) # 80004aec <pipealloc>
    return -1;
    80005d2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d30:	0c054463          	bltz	a0,80005df8 <sys_pipe+0xfc>
  fd0 = -1;
    80005d34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d38:	fd043503          	ld	a0,-48(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	51a080e7          	jalr	1306(ra) # 80005256 <fdalloc>
    80005d44:	fca42223          	sw	a0,-60(s0)
    80005d48:	08054b63          	bltz	a0,80005dde <sys_pipe+0xe2>
    80005d4c:	fc843503          	ld	a0,-56(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	506080e7          	jalr	1286(ra) # 80005256 <fdalloc>
    80005d58:	fca42023          	sw	a0,-64(s0)
    80005d5c:	06054863          	bltz	a0,80005dcc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d60:	4691                	li	a3,4
    80005d62:	fc440613          	addi	a2,s0,-60
    80005d66:	fd843583          	ld	a1,-40(s0)
    80005d6a:	68a8                	ld	a0,80(s1)
    80005d6c:	ffffc097          	auipc	ra,0xffffc
    80005d70:	ac6080e7          	jalr	-1338(ra) # 80001832 <copyout>
    80005d74:	02054063          	bltz	a0,80005d94 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d78:	4691                	li	a3,4
    80005d7a:	fc040613          	addi	a2,s0,-64
    80005d7e:	fd843583          	ld	a1,-40(s0)
    80005d82:	0591                	addi	a1,a1,4
    80005d84:	68a8                	ld	a0,80(s1)
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	aac080e7          	jalr	-1364(ra) # 80001832 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d90:	06055463          	bgez	a0,80005df8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d94:	fc442783          	lw	a5,-60(s0)
    80005d98:	07e9                	addi	a5,a5,26
    80005d9a:	078e                	slli	a5,a5,0x3
    80005d9c:	97a6                	add	a5,a5,s1
    80005d9e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005da2:	fc042503          	lw	a0,-64(s0)
    80005da6:	0569                	addi	a0,a0,26
    80005da8:	050e                	slli	a0,a0,0x3
    80005daa:	94aa                	add	s1,s1,a0
    80005dac:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005db0:	fd043503          	ld	a0,-48(s0)
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	a08080e7          	jalr	-1528(ra) # 800047bc <fileclose>
    fileclose(wf);
    80005dbc:	fc843503          	ld	a0,-56(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	9fc080e7          	jalr	-1540(ra) # 800047bc <fileclose>
    return -1;
    80005dc8:	57fd                	li	a5,-1
    80005dca:	a03d                	j	80005df8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005dcc:	fc442783          	lw	a5,-60(s0)
    80005dd0:	0007c763          	bltz	a5,80005dde <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dd4:	07e9                	addi	a5,a5,26
    80005dd6:	078e                	slli	a5,a5,0x3
    80005dd8:	94be                	add	s1,s1,a5
    80005dda:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dde:	fd043503          	ld	a0,-48(s0)
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	9da080e7          	jalr	-1574(ra) # 800047bc <fileclose>
    fileclose(wf);
    80005dea:	fc843503          	ld	a0,-56(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	9ce080e7          	jalr	-1586(ra) # 800047bc <fileclose>
    return -1;
    80005df6:	57fd                	li	a5,-1
}
    80005df8:	853e                	mv	a0,a5
    80005dfa:	70e2                	ld	ra,56(sp)
    80005dfc:	7442                	ld	s0,48(sp)
    80005dfe:	74a2                	ld	s1,40(sp)
    80005e00:	6121                	addi	sp,sp,64
    80005e02:	8082                	ret
	...

0000000080005e10 <kernelvec>:
    80005e10:	7111                	addi	sp,sp,-256
    80005e12:	e006                	sd	ra,0(sp)
    80005e14:	e40a                	sd	sp,8(sp)
    80005e16:	e80e                	sd	gp,16(sp)
    80005e18:	ec12                	sd	tp,24(sp)
    80005e1a:	f016                	sd	t0,32(sp)
    80005e1c:	f41a                	sd	t1,40(sp)
    80005e1e:	f81e                	sd	t2,48(sp)
    80005e20:	fc22                	sd	s0,56(sp)
    80005e22:	e0a6                	sd	s1,64(sp)
    80005e24:	e4aa                	sd	a0,72(sp)
    80005e26:	e8ae                	sd	a1,80(sp)
    80005e28:	ecb2                	sd	a2,88(sp)
    80005e2a:	f0b6                	sd	a3,96(sp)
    80005e2c:	f4ba                	sd	a4,104(sp)
    80005e2e:	f8be                	sd	a5,112(sp)
    80005e30:	fcc2                	sd	a6,120(sp)
    80005e32:	e146                	sd	a7,128(sp)
    80005e34:	e54a                	sd	s2,136(sp)
    80005e36:	e94e                	sd	s3,144(sp)
    80005e38:	ed52                	sd	s4,152(sp)
    80005e3a:	f156                	sd	s5,160(sp)
    80005e3c:	f55a                	sd	s6,168(sp)
    80005e3e:	f95e                	sd	s7,176(sp)
    80005e40:	fd62                	sd	s8,184(sp)
    80005e42:	e1e6                	sd	s9,192(sp)
    80005e44:	e5ea                	sd	s10,200(sp)
    80005e46:	e9ee                	sd	s11,208(sp)
    80005e48:	edf2                	sd	t3,216(sp)
    80005e4a:	f1f6                	sd	t4,224(sp)
    80005e4c:	f5fa                	sd	t5,232(sp)
    80005e4e:	f9fe                	sd	t6,240(sp)
    80005e50:	cbdfc0ef          	jal	ra,80002b0c <kerneltrap>
    80005e54:	6082                	ld	ra,0(sp)
    80005e56:	6122                	ld	sp,8(sp)
    80005e58:	61c2                	ld	gp,16(sp)
    80005e5a:	7282                	ld	t0,32(sp)
    80005e5c:	7322                	ld	t1,40(sp)
    80005e5e:	73c2                	ld	t2,48(sp)
    80005e60:	7462                	ld	s0,56(sp)
    80005e62:	6486                	ld	s1,64(sp)
    80005e64:	6526                	ld	a0,72(sp)
    80005e66:	65c6                	ld	a1,80(sp)
    80005e68:	6666                	ld	a2,88(sp)
    80005e6a:	7686                	ld	a3,96(sp)
    80005e6c:	7726                	ld	a4,104(sp)
    80005e6e:	77c6                	ld	a5,112(sp)
    80005e70:	7866                	ld	a6,120(sp)
    80005e72:	688a                	ld	a7,128(sp)
    80005e74:	692a                	ld	s2,136(sp)
    80005e76:	69ca                	ld	s3,144(sp)
    80005e78:	6a6a                	ld	s4,152(sp)
    80005e7a:	7a8a                	ld	s5,160(sp)
    80005e7c:	7b2a                	ld	s6,168(sp)
    80005e7e:	7bca                	ld	s7,176(sp)
    80005e80:	7c6a                	ld	s8,184(sp)
    80005e82:	6c8e                	ld	s9,192(sp)
    80005e84:	6d2e                	ld	s10,200(sp)
    80005e86:	6dce                	ld	s11,208(sp)
    80005e88:	6e6e                	ld	t3,216(sp)
    80005e8a:	7e8e                	ld	t4,224(sp)
    80005e8c:	7f2e                	ld	t5,232(sp)
    80005e8e:	7fce                	ld	t6,240(sp)
    80005e90:	6111                	addi	sp,sp,256
    80005e92:	10200073          	sret
    80005e96:	00000013          	nop
    80005e9a:	00000013          	nop
    80005e9e:	0001                	nop

0000000080005ea0 <timervec>:
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	e10c                	sd	a1,0(a0)
    80005ea6:	e510                	sd	a2,8(a0)
    80005ea8:	e914                	sd	a3,16(a0)
    80005eaa:	6d0c                	ld	a1,24(a0)
    80005eac:	7110                	ld	a2,32(a0)
    80005eae:	6194                	ld	a3,0(a1)
    80005eb0:	96b2                	add	a3,a3,a2
    80005eb2:	e194                	sd	a3,0(a1)
    80005eb4:	4589                	li	a1,2
    80005eb6:	14459073          	csrw	sip,a1
    80005eba:	6914                	ld	a3,16(a0)
    80005ebc:	6510                	ld	a2,8(a0)
    80005ebe:	610c                	ld	a1,0(a0)
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	30200073          	mret
	...

0000000080005eca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eca:	1141                	addi	sp,sp,-16
    80005ecc:	e422                	sd	s0,8(sp)
    80005ece:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ed0:	0c0007b7          	lui	a5,0xc000
    80005ed4:	4705                	li	a4,1
    80005ed6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ed8:	c3d8                	sw	a4,4(a5)
}
    80005eda:	6422                	ld	s0,8(sp)
    80005edc:	0141                	addi	sp,sp,16
    80005ede:	8082                	ret

0000000080005ee0 <plicinithart>:

void
plicinithart(void)
{
    80005ee0:	1141                	addi	sp,sp,-16
    80005ee2:	e406                	sd	ra,8(sp)
    80005ee4:	e022                	sd	s0,0(sp)
    80005ee6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	c62080e7          	jalr	-926(ra) # 80001b4a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ef0:	0085171b          	slliw	a4,a0,0x8
    80005ef4:	0c0027b7          	lui	a5,0xc002
    80005ef8:	97ba                	add	a5,a5,a4
    80005efa:	40200713          	li	a4,1026
    80005efe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f02:	00d5151b          	slliw	a0,a0,0xd
    80005f06:	0c2017b7          	lui	a5,0xc201
    80005f0a:	953e                	add	a0,a0,a5
    80005f0c:	00052023          	sw	zero,0(a0)
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret

0000000080005f18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f18:	1141                	addi	sp,sp,-16
    80005f1a:	e406                	sd	ra,8(sp)
    80005f1c:	e022                	sd	s0,0(sp)
    80005f1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	c2a080e7          	jalr	-982(ra) # 80001b4a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f28:	00d5179b          	slliw	a5,a0,0xd
    80005f2c:	0c201537          	lui	a0,0xc201
    80005f30:	953e                	add	a0,a0,a5
  return irq;
}
    80005f32:	4148                	lw	a0,4(a0)
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	addi	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f3c:	1101                	addi	sp,sp,-32
    80005f3e:	ec06                	sd	ra,24(sp)
    80005f40:	e822                	sd	s0,16(sp)
    80005f42:	e426                	sd	s1,8(sp)
    80005f44:	1000                	addi	s0,sp,32
    80005f46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	c02080e7          	jalr	-1022(ra) # 80001b4a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f50:	00d5151b          	slliw	a0,a0,0xd
    80005f54:	0c2017b7          	lui	a5,0xc201
    80005f58:	97aa                	add	a5,a5,a0
    80005f5a:	c3c4                	sw	s1,4(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret

0000000080005f66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f66:	1141                	addi	sp,sp,-16
    80005f68:	e406                	sd	ra,8(sp)
    80005f6a:	e022                	sd	s0,0(sp)
    80005f6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f6e:	479d                	li	a5,7
    80005f70:	04a7cc63          	blt	a5,a0,80005fc8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f74:	0001c797          	auipc	a5,0x1c
    80005f78:	d7c78793          	addi	a5,a5,-644 # 80021cf0 <disk>
    80005f7c:	97aa                	add	a5,a5,a0
    80005f7e:	0187c783          	lbu	a5,24(a5)
    80005f82:	ebb9                	bnez	a5,80005fd8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f84:	00451613          	slli	a2,a0,0x4
    80005f88:	0001c797          	auipc	a5,0x1c
    80005f8c:	d6878793          	addi	a5,a5,-664 # 80021cf0 <disk>
    80005f90:	6394                	ld	a3,0(a5)
    80005f92:	96b2                	add	a3,a3,a2
    80005f94:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f98:	6398                	ld	a4,0(a5)
    80005f9a:	9732                	add	a4,a4,a2
    80005f9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fa0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fa4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fa8:	953e                	add	a0,a0,a5
    80005faa:	4785                	li	a5,1
    80005fac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fb0:	0001c517          	auipc	a0,0x1c
    80005fb4:	d5850513          	addi	a0,a0,-680 # 80021d08 <disk+0x18>
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	2ca080e7          	jalr	714(ra) # 80002282 <wakeup>
}
    80005fc0:	60a2                	ld	ra,8(sp)
    80005fc2:	6402                	ld	s0,0(sp)
    80005fc4:	0141                	addi	sp,sp,16
    80005fc6:	8082                	ret
    panic("free_desc 1");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	84850513          	addi	a0,a0,-1976 # 80008810 <syscalls+0x380>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	56e080e7          	jalr	1390(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	84850513          	addi	a0,a0,-1976 # 80008820 <syscalls+0x390>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>

0000000080005fe8 <virtio_disk_init>:
{
    80005fe8:	1101                	addi	sp,sp,-32
    80005fea:	ec06                	sd	ra,24(sp)
    80005fec:	e822                	sd	s0,16(sp)
    80005fee:	e426                	sd	s1,8(sp)
    80005ff0:	e04a                	sd	s2,0(sp)
    80005ff2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ff4:	00003597          	auipc	a1,0x3
    80005ff8:	83c58593          	addi	a1,a1,-1988 # 80008830 <syscalls+0x3a0>
    80005ffc:	0001c517          	auipc	a0,0x1c
    80006000:	e1c50513          	addi	a0,a0,-484 # 80021e18 <disk+0x128>
    80006004:	ffffb097          	auipc	ra,0xffffb
    80006008:	d0c080e7          	jalr	-756(ra) # 80000d10 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000600c:	100017b7          	lui	a5,0x10001
    80006010:	4398                	lw	a4,0(a5)
    80006012:	2701                	sext.w	a4,a4
    80006014:	747277b7          	lui	a5,0x74727
    80006018:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000601c:	14f71c63          	bne	a4,a5,80006174 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006020:	100017b7          	lui	a5,0x10001
    80006024:	43dc                	lw	a5,4(a5)
    80006026:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006028:	4709                	li	a4,2
    8000602a:	14e79563          	bne	a5,a4,80006174 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	479c                	lw	a5,8(a5)
    80006034:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006036:	12e79f63          	bne	a5,a4,80006174 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000603a:	100017b7          	lui	a5,0x10001
    8000603e:	47d8                	lw	a4,12(a5)
    80006040:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006042:	554d47b7          	lui	a5,0x554d4
    80006046:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000604a:	12f71563          	bne	a4,a5,80006174 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604e:	100017b7          	lui	a5,0x10001
    80006052:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006056:	4705                	li	a4,1
    80006058:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605a:	470d                	li	a4,3
    8000605c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000605e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006060:	c7ffe737          	lui	a4,0xc7ffe
    80006064:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc92f>
    80006068:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000606a:	2701                	sext.w	a4,a4
    8000606c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606e:	472d                	li	a4,11
    80006070:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006072:	5bbc                	lw	a5,112(a5)
    80006074:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006078:	8ba1                	andi	a5,a5,8
    8000607a:	10078563          	beqz	a5,80006184 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006086:	43fc                	lw	a5,68(a5)
    80006088:	2781                	sext.w	a5,a5
    8000608a:	10079563          	bnez	a5,80006194 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	5bdc                	lw	a5,52(a5)
    80006094:	2781                	sext.w	a5,a5
  if(max == 0)
    80006096:	10078763          	beqz	a5,800061a4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000609a:	471d                	li	a4,7
    8000609c:	10f77c63          	bgeu	a4,a5,800061b4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	a0a080e7          	jalr	-1526(ra) # 80000aaa <kalloc>
    800060a8:	0001c497          	auipc	s1,0x1c
    800060ac:	c4848493          	addi	s1,s1,-952 # 80021cf0 <disk>
    800060b0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	9f8080e7          	jalr	-1544(ra) # 80000aaa <kalloc>
    800060ba:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	9ee080e7          	jalr	-1554(ra) # 80000aaa <kalloc>
    800060c4:	87aa                	mv	a5,a0
    800060c6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060c8:	6088                	ld	a0,0(s1)
    800060ca:	cd6d                	beqz	a0,800061c4 <virtio_disk_init+0x1dc>
    800060cc:	0001c717          	auipc	a4,0x1c
    800060d0:	c2c73703          	ld	a4,-980(a4) # 80021cf8 <disk+0x8>
    800060d4:	cb65                	beqz	a4,800061c4 <virtio_disk_init+0x1dc>
    800060d6:	c7fd                	beqz	a5,800061c4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800060d8:	6605                	lui	a2,0x1
    800060da:	4581                	li	a1,0
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	dc0080e7          	jalr	-576(ra) # 80000e9c <memset>
  memset(disk.avail, 0, PGSIZE);
    800060e4:	0001c497          	auipc	s1,0x1c
    800060e8:	c0c48493          	addi	s1,s1,-1012 # 80021cf0 <disk>
    800060ec:	6605                	lui	a2,0x1
    800060ee:	4581                	li	a1,0
    800060f0:	6488                	ld	a0,8(s1)
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	daa080e7          	jalr	-598(ra) # 80000e9c <memset>
  memset(disk.used, 0, PGSIZE);
    800060fa:	6605                	lui	a2,0x1
    800060fc:	4581                	li	a1,0
    800060fe:	6888                	ld	a0,16(s1)
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	d9c080e7          	jalr	-612(ra) # 80000e9c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006108:	100017b7          	lui	a5,0x10001
    8000610c:	4721                	li	a4,8
    8000610e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006110:	4098                	lw	a4,0(s1)
    80006112:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006116:	40d8                	lw	a4,4(s1)
    80006118:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000611c:	6498                	ld	a4,8(s1)
    8000611e:	0007069b          	sext.w	a3,a4
    80006122:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006126:	9701                	srai	a4,a4,0x20
    80006128:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000612c:	6898                	ld	a4,16(s1)
    8000612e:	0007069b          	sext.w	a3,a4
    80006132:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006136:	9701                	srai	a4,a4,0x20
    80006138:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000613c:	4705                	li	a4,1
    8000613e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006140:	00e48c23          	sb	a4,24(s1)
    80006144:	00e48ca3          	sb	a4,25(s1)
    80006148:	00e48d23          	sb	a4,26(s1)
    8000614c:	00e48da3          	sb	a4,27(s1)
    80006150:	00e48e23          	sb	a4,28(s1)
    80006154:	00e48ea3          	sb	a4,29(s1)
    80006158:	00e48f23          	sb	a4,30(s1)
    8000615c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006160:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006164:	0727a823          	sw	s2,112(a5)
}
    80006168:	60e2                	ld	ra,24(sp)
    8000616a:	6442                	ld	s0,16(sp)
    8000616c:	64a2                	ld	s1,8(sp)
    8000616e:	6902                	ld	s2,0(sp)
    80006170:	6105                	addi	sp,sp,32
    80006172:	8082                	ret
    panic("could not find virtio disk");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6cc50513          	addi	a0,a0,1740 # 80008840 <syscalls+0x3b0>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	6dc50513          	addi	a0,a0,1756 # 80008860 <syscalls+0x3d0>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006194:	00002517          	auipc	a0,0x2
    80006198:	6ec50513          	addi	a0,a0,1772 # 80008880 <syscalls+0x3f0>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	6fc50513          	addi	a0,a0,1788 # 800088a0 <syscalls+0x410>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800061b4:	00002517          	auipc	a0,0x2
    800061b8:	70c50513          	addi	a0,a0,1804 # 800088c0 <syscalls+0x430>
    800061bc:	ffffa097          	auipc	ra,0xffffa
    800061c0:	382080e7          	jalr	898(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800061c4:	00002517          	auipc	a0,0x2
    800061c8:	71c50513          	addi	a0,a0,1820 # 800088e0 <syscalls+0x450>
    800061cc:	ffffa097          	auipc	ra,0xffffa
    800061d0:	372080e7          	jalr	882(ra) # 8000053e <panic>

00000000800061d4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061d4:	7119                	addi	sp,sp,-128
    800061d6:	fc86                	sd	ra,120(sp)
    800061d8:	f8a2                	sd	s0,112(sp)
    800061da:	f4a6                	sd	s1,104(sp)
    800061dc:	f0ca                	sd	s2,96(sp)
    800061de:	ecce                	sd	s3,88(sp)
    800061e0:	e8d2                	sd	s4,80(sp)
    800061e2:	e4d6                	sd	s5,72(sp)
    800061e4:	e0da                	sd	s6,64(sp)
    800061e6:	fc5e                	sd	s7,56(sp)
    800061e8:	f862                	sd	s8,48(sp)
    800061ea:	f466                	sd	s9,40(sp)
    800061ec:	f06a                	sd	s10,32(sp)
    800061ee:	ec6e                	sd	s11,24(sp)
    800061f0:	0100                	addi	s0,sp,128
    800061f2:	8aaa                	mv	s5,a0
    800061f4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061f6:	00c52d03          	lw	s10,12(a0)
    800061fa:	001d1d1b          	slliw	s10,s10,0x1
    800061fe:	1d02                	slli	s10,s10,0x20
    80006200:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006204:	0001c517          	auipc	a0,0x1c
    80006208:	c1450513          	addi	a0,a0,-1004 # 80021e18 <disk+0x128>
    8000620c:	ffffb097          	auipc	ra,0xffffb
    80006210:	b94080e7          	jalr	-1132(ra) # 80000da0 <acquire>
  for(int i = 0; i < 3; i++){
    80006214:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006216:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006218:	0001cb97          	auipc	s7,0x1c
    8000621c:	ad8b8b93          	addi	s7,s7,-1320 # 80021cf0 <disk>
  for(int i = 0; i < 3; i++){
    80006220:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006222:	0001cc97          	auipc	s9,0x1c
    80006226:	bf6c8c93          	addi	s9,s9,-1034 # 80021e18 <disk+0x128>
    8000622a:	a08d                	j	8000628c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000622c:	00fb8733          	add	a4,s7,a5
    80006230:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006234:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006236:	0207c563          	bltz	a5,80006260 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000623a:	2905                	addiw	s2,s2,1
    8000623c:	0611                	addi	a2,a2,4
    8000623e:	05690c63          	beq	s2,s6,80006296 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006242:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006244:	0001c717          	auipc	a4,0x1c
    80006248:	aac70713          	addi	a4,a4,-1364 # 80021cf0 <disk>
    8000624c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000624e:	01874683          	lbu	a3,24(a4)
    80006252:	fee9                	bnez	a3,8000622c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006254:	2785                	addiw	a5,a5,1
    80006256:	0705                	addi	a4,a4,1
    80006258:	fe979be3          	bne	a5,s1,8000624e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000625c:	57fd                	li	a5,-1
    8000625e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006260:	01205d63          	blez	s2,8000627a <virtio_disk_rw+0xa6>
    80006264:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006266:	000a2503          	lw	a0,0(s4)
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	cfc080e7          	jalr	-772(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    80006272:	2d85                	addiw	s11,s11,1
    80006274:	0a11                	addi	s4,s4,4
    80006276:	ffb918e3          	bne	s2,s11,80006266 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000627a:	85e6                	mv	a1,s9
    8000627c:	0001c517          	auipc	a0,0x1c
    80006280:	a8c50513          	addi	a0,a0,-1396 # 80021d08 <disk+0x18>
    80006284:	ffffc097          	auipc	ra,0xffffc
    80006288:	f9a080e7          	jalr	-102(ra) # 8000221e <sleep>
  for(int i = 0; i < 3; i++){
    8000628c:	f8040a13          	addi	s4,s0,-128
{
    80006290:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006292:	894e                	mv	s2,s3
    80006294:	b77d                	j	80006242 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006296:	f8042583          	lw	a1,-128(s0)
    8000629a:	00a58793          	addi	a5,a1,10
    8000629e:	0792                	slli	a5,a5,0x4

  if(write)
    800062a0:	0001c617          	auipc	a2,0x1c
    800062a4:	a5060613          	addi	a2,a2,-1456 # 80021cf0 <disk>
    800062a8:	00f60733          	add	a4,a2,a5
    800062ac:	018036b3          	snez	a3,s8
    800062b0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062b2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800062b6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ba:	f6078693          	addi	a3,a5,-160
    800062be:	6218                	ld	a4,0(a2)
    800062c0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c2:	00878513          	addi	a0,a5,8
    800062c6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062ca:	6208                	ld	a0,0(a2)
    800062cc:	96aa                	add	a3,a3,a0
    800062ce:	4741                	li	a4,16
    800062d0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062d2:	4705                	li	a4,1
    800062d4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800062d8:	f8442703          	lw	a4,-124(s0)
    800062dc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e0:	0712                	slli	a4,a4,0x4
    800062e2:	953a                	add	a0,a0,a4
    800062e4:	058a8693          	addi	a3,s5,88
    800062e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800062ea:	6208                	ld	a0,0(a2)
    800062ec:	972a                	add	a4,a4,a0
    800062ee:	40000693          	li	a3,1024
    800062f2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062f4:	001c3c13          	seqz	s8,s8
    800062f8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062fa:	001c6c13          	ori	s8,s8,1
    800062fe:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006302:	f8842603          	lw	a2,-120(s0)
    80006306:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000630a:	0001c697          	auipc	a3,0x1c
    8000630e:	9e668693          	addi	a3,a3,-1562 # 80021cf0 <disk>
    80006312:	00258713          	addi	a4,a1,2
    80006316:	0712                	slli	a4,a4,0x4
    80006318:	9736                	add	a4,a4,a3
    8000631a:	587d                	li	a6,-1
    8000631c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006320:	0612                	slli	a2,a2,0x4
    80006322:	9532                	add	a0,a0,a2
    80006324:	f9078793          	addi	a5,a5,-112
    80006328:	97b6                	add	a5,a5,a3
    8000632a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000632c:	629c                	ld	a5,0(a3)
    8000632e:	97b2                	add	a5,a5,a2
    80006330:	4605                	li	a2,1
    80006332:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006334:	4509                	li	a0,2
    80006336:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000633a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000633e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006342:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006346:	6698                	ld	a4,8(a3)
    80006348:	00275783          	lhu	a5,2(a4)
    8000634c:	8b9d                	andi	a5,a5,7
    8000634e:	0786                	slli	a5,a5,0x1
    80006350:	97ba                	add	a5,a5,a4
    80006352:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006356:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000635a:	6698                	ld	a4,8(a3)
    8000635c:	00275783          	lhu	a5,2(a4)
    80006360:	2785                	addiw	a5,a5,1
    80006362:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006366:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000636a:	100017b7          	lui	a5,0x10001
    8000636e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006372:	004aa783          	lw	a5,4(s5)
    80006376:	02c79163          	bne	a5,a2,80006398 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000637a:	0001c917          	auipc	s2,0x1c
    8000637e:	a9e90913          	addi	s2,s2,-1378 # 80021e18 <disk+0x128>
  while(b->disk == 1) {
    80006382:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006384:	85ca                	mv	a1,s2
    80006386:	8556                	mv	a0,s5
    80006388:	ffffc097          	auipc	ra,0xffffc
    8000638c:	e96080e7          	jalr	-362(ra) # 8000221e <sleep>
  while(b->disk == 1) {
    80006390:	004aa783          	lw	a5,4(s5)
    80006394:	fe9788e3          	beq	a5,s1,80006384 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006398:	f8042903          	lw	s2,-128(s0)
    8000639c:	00290793          	addi	a5,s2,2
    800063a0:	00479713          	slli	a4,a5,0x4
    800063a4:	0001c797          	auipc	a5,0x1c
    800063a8:	94c78793          	addi	a5,a5,-1716 # 80021cf0 <disk>
    800063ac:	97ba                	add	a5,a5,a4
    800063ae:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063b2:	0001c997          	auipc	s3,0x1c
    800063b6:	93e98993          	addi	s3,s3,-1730 # 80021cf0 <disk>
    800063ba:	00491713          	slli	a4,s2,0x4
    800063be:	0009b783          	ld	a5,0(s3)
    800063c2:	97ba                	add	a5,a5,a4
    800063c4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063c8:	854a                	mv	a0,s2
    800063ca:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063ce:	00000097          	auipc	ra,0x0
    800063d2:	b98080e7          	jalr	-1128(ra) # 80005f66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063d6:	8885                	andi	s1,s1,1
    800063d8:	f0ed                	bnez	s1,800063ba <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063da:	0001c517          	auipc	a0,0x1c
    800063de:	a3e50513          	addi	a0,a0,-1474 # 80021e18 <disk+0x128>
    800063e2:	ffffb097          	auipc	ra,0xffffb
    800063e6:	a72080e7          	jalr	-1422(ra) # 80000e54 <release>
}
    800063ea:	70e6                	ld	ra,120(sp)
    800063ec:	7446                	ld	s0,112(sp)
    800063ee:	74a6                	ld	s1,104(sp)
    800063f0:	7906                	ld	s2,96(sp)
    800063f2:	69e6                	ld	s3,88(sp)
    800063f4:	6a46                	ld	s4,80(sp)
    800063f6:	6aa6                	ld	s5,72(sp)
    800063f8:	6b06                	ld	s6,64(sp)
    800063fa:	7be2                	ld	s7,56(sp)
    800063fc:	7c42                	ld	s8,48(sp)
    800063fe:	7ca2                	ld	s9,40(sp)
    80006400:	7d02                	ld	s10,32(sp)
    80006402:	6de2                	ld	s11,24(sp)
    80006404:	6109                	addi	sp,sp,128
    80006406:	8082                	ret

0000000080006408 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006408:	1101                	addi	sp,sp,-32
    8000640a:	ec06                	sd	ra,24(sp)
    8000640c:	e822                	sd	s0,16(sp)
    8000640e:	e426                	sd	s1,8(sp)
    80006410:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006412:	0001c497          	auipc	s1,0x1c
    80006416:	8de48493          	addi	s1,s1,-1826 # 80021cf0 <disk>
    8000641a:	0001c517          	auipc	a0,0x1c
    8000641e:	9fe50513          	addi	a0,a0,-1538 # 80021e18 <disk+0x128>
    80006422:	ffffb097          	auipc	ra,0xffffb
    80006426:	97e080e7          	jalr	-1666(ra) # 80000da0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000642a:	10001737          	lui	a4,0x10001
    8000642e:	533c                	lw	a5,96(a4)
    80006430:	8b8d                	andi	a5,a5,3
    80006432:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006438:	689c                	ld	a5,16(s1)
    8000643a:	0204d703          	lhu	a4,32(s1)
    8000643e:	0027d783          	lhu	a5,2(a5)
    80006442:	04f70863          	beq	a4,a5,80006492 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006446:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000644a:	6898                	ld	a4,16(s1)
    8000644c:	0204d783          	lhu	a5,32(s1)
    80006450:	8b9d                	andi	a5,a5,7
    80006452:	078e                	slli	a5,a5,0x3
    80006454:	97ba                	add	a5,a5,a4
    80006456:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006458:	00278713          	addi	a4,a5,2
    8000645c:	0712                	slli	a4,a4,0x4
    8000645e:	9726                	add	a4,a4,s1
    80006460:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006464:	e721                	bnez	a4,800064ac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006466:	0789                	addi	a5,a5,2
    80006468:	0792                	slli	a5,a5,0x4
    8000646a:	97a6                	add	a5,a5,s1
    8000646c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000646e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	e10080e7          	jalr	-496(ra) # 80002282 <wakeup>

    disk.used_idx += 1;
    8000647a:	0204d783          	lhu	a5,32(s1)
    8000647e:	2785                	addiw	a5,a5,1
    80006480:	17c2                	slli	a5,a5,0x30
    80006482:	93c1                	srli	a5,a5,0x30
    80006484:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006488:	6898                	ld	a4,16(s1)
    8000648a:	00275703          	lhu	a4,2(a4)
    8000648e:	faf71ce3          	bne	a4,a5,80006446 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006492:	0001c517          	auipc	a0,0x1c
    80006496:	98650513          	addi	a0,a0,-1658 # 80021e18 <disk+0x128>
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	9ba080e7          	jalr	-1606(ra) # 80000e54 <release>
}
    800064a2:	60e2                	ld	ra,24(sp)
    800064a4:	6442                	ld	s0,16(sp)
    800064a6:	64a2                	ld	s1,8(sp)
    800064a8:	6105                	addi	sp,sp,32
    800064aa:	8082                	ret
      panic("virtio_disk_intr status");
    800064ac:	00002517          	auipc	a0,0x2
    800064b0:	44c50513          	addi	a0,a0,1100 # 800088f8 <syscalls+0x468>
    800064b4:	ffffa097          	auipc	ra,0xffffa
    800064b8:	08a080e7          	jalr	138(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
