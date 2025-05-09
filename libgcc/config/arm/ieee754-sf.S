/* ieee754-sf.S single-precision floating point support for ARM

   Copyright (C) 2003-2025 Free Software Foundation, Inc.
   Contributed by Nicolas Pitre (nico@fluxnic.net)

   This file is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any
   later version.

   This file is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   Under Section 7 of GPL version 3, you are granted additional
   permissions described in the GCC Runtime Library Exception, version
   3.1, as published by the Free Software Foundation.

   You should have received a copy of the GNU General Public License and
   a copy of the GCC Runtime Library Exception along with this program;
   see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
   <http://www.gnu.org/licenses/>.  */

/*
 * Notes:
 *
 * The goal of this code is to be as fast as possible.  This is
 * not meant to be easy to understand for the casual reader.
 *
 * Only the default rounding mode is intended for best performances.
 * Exceptions aren't supported yet, but that can be added quite easily
 * if necessary without impacting performances.
 *
 * In the CFI related comments, 'previousOffset' refers to the previous offset
 * from sp used to compute the CFA.
 */

#ifdef L_arm_negsf2
	
ARM_FUNC_START negsf2
ARM_FUNC_ALIAS aeabi_fneg negsf2
	CFI_START_FUNCTION

	eor	r0, r0, #0x80000000	@ flip sign bit
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_fneg
	FUNC_END negsf2

#endif

#ifdef L_arm_addsubsf3

ARM_FUNC_START aeabi_frsub
	CFI_START_FUNCTION

	eor	r0, r0, #0x80000000	@ flip sign bit of first arg
	b	1f

ARM_FUNC_START subsf3
ARM_FUNC_ALIAS aeabi_fsub subsf3

	eor	r1, r1, #0x80000000	@ flip sign bit of second arg
#if defined(__INTERWORKING_STUBS__)
	b	1f			@ Skip Thumb-code prologue
#endif

ARM_FUNC_START addsf3
ARM_FUNC_ALIAS aeabi_fadd addsf3

1:	@ Look for zeroes, equal values, INF, or NAN.
	movs	r2, r0, lsl #1
	do_it	ne, ttt
	COND(mov,s,ne)	r3, r1, lsl #1
	teqne	r2, r3
	COND(mvn,s,ne)	ip, r2, asr #24
	COND(mvn,s,ne)	ip, r3, asr #24
	beq	LSYM(Lad_s)

	@ Compute exponent difference.  Make largest exponent in r2,
	@ corresponding arg in r0, and positive exponent difference in r3.
	mov	r2, r2, lsr #24
	rsbs	r3, r2, r3, lsr #24
	do_it	gt, ttt
	addgt	r2, r2, r3
	eorgt	r1, r0, r1
	eorgt	r0, r1, r0
	eorgt	r1, r0, r1
	do_it	lt
	rsblt	r3, r3, #0

	@ If exponent difference is too large, return largest argument
	@ already in r0.  We need up to 25 bit to handle proper rounding
	@ of 0x1p25 - 1.1.
	cmp	r3, #25
	do_it	hi
	RETc(hi)

	@ Convert mantissa to signed integer.
	tst	r0, #0x80000000
	orr	r0, r0, #0x00800000
	bic	r0, r0, #0xff000000
	do_it	ne
	rsbne	r0, r0, #0
	tst	r1, #0x80000000
	orr	r1, r1, #0x00800000
	bic	r1, r1, #0xff000000
	do_it	ne
	rsbne	r1, r1, #0

	@ If exponent == difference, one or both args were denormalized.
	@ Since this is not common case, rescale them off line.
	teq	r2, r3
	beq	LSYM(Lad_d)
LSYM(Lad_x):

	@ Compensate for the exponent overlapping the mantissa MSB added later
	sub	r2, r2, #1

	@ Shift and add second arg to first arg in r0.
	@ Keep leftover bits into r1.
	shiftop adds r0 r0 r1 asr r3 ip
	rsb	r3, r3, #32
	shift1	lsl, r1, r1, r3

	@ Keep absolute value in r0-r1, sign in r3 (the n bit was set above)
	and	r3, r0, #0x80000000
	bpl	LSYM(Lad_p)
#if defined(__thumb2__)
	negs	r1, r1
	sbc	r0, r0, r0, lsl #1
#else
	rsbs	r1, r1, #0
	rsc	r0, r0, #0
#endif

	@ Determine how to normalize the result.
LSYM(Lad_p):
	cmp	r0, #0x00800000
	bcc	LSYM(Lad_a)
	cmp	r0, #0x01000000
	bcc	LSYM(Lad_e)

	@ Result needs to be shifted right.
	movs	r0, r0, lsr #1
	mov	r1, r1, rrx
	add	r2, r2, #1

	@ Make sure we did not bust our exponent.
	cmp	r2, #254
	bhs	LSYM(Lad_o)

	@ Our result is now properly aligned into r0, remaining bits in r1.
	@ Pack final result together.
	@ Round with MSB of r1. If halfway between two numbers, round towards
	@ LSB of r0 = 0. 
LSYM(Lad_e):
	cmp	r1, #0x80000000
	adc	r0, r0, r2, lsl #23
	do_it	eq
	biceq	r0, r0, #1
	orr	r0, r0, r3
	RET

	@ Result must be shifted left and exponent adjusted.
LSYM(Lad_a):
	movs	r1, r1, lsl #1
	adc	r0, r0, r0
	subs	r2, r2, #1
	do_it	hs
	cmphs	r0, #0x00800000
	bhs	LSYM(Lad_e)

	@ No rounding necessary since r1 will always be 0 at this point.
LSYM(Lad_l):

#if !defined (__ARM_FEATURE_CLZ)

	movs	ip, r0, lsr #12
	moveq	r0, r0, lsl #12
	subeq	r2, r2, #12
	tst	r0, #0x00ff0000
	moveq	r0, r0, lsl #8
	subeq	r2, r2, #8
	tst	r0, #0x00f00000
	moveq	r0, r0, lsl #4
	subeq	r2, r2, #4
	tst	r0, #0x00c00000
	moveq	r0, r0, lsl #2
	subeq	r2, r2, #2
	cmp	r0, #0x00800000
	movcc	r0, r0, lsl #1
	sbcs	r2, r2, #0

#else

	clz	ip, r0
	sub	ip, ip, #8
	subs	r2, r2, ip
	shift1	lsl, r0, r0, ip

#endif

	@ Final result with sign
	@ If exponent negative, denormalize result.
	do_it	ge, et
	addge	r0, r0, r2, lsl #23
	rsblt	r2, r2, #0
	orrge	r0, r0, r3
#if defined(__thumb2__)
	do_it	lt, t
	lsrlt	r0, r0, r2
	orrlt	r0, r3, r0
#else
	orrlt	r0, r3, r0, lsr r2
#endif
	RET

	@ Fixup and adjust bit position for denormalized arguments.
	@ Note that r2 must not remain equal to 0.
LSYM(Lad_d):
	teq	r2, #0
	eor	r1, r1, #0x00800000
	do_it	eq, te
	eoreq	r0, r0, #0x00800000
	addeq	r2, r2, #1
	subne	r3, r3, #1
	b	LSYM(Lad_x)

LSYM(Lad_s):
	mov	r3, r1, lsl #1

	mvns	ip, r2, asr #24
	do_it	ne
	COND(mvn,s,ne)	ip, r3, asr #24
	beq	LSYM(Lad_i)

	teq	r2, r3
	beq	1f

	@ Result is x + 0.0 = x or 0.0 + y = y.
	teq	r2, #0
	do_it	eq
	moveq	r0, r1
	RET

1:	teq	r0, r1

	@ Result is x - x = 0.
	do_it	ne, t
	movne	r0, #0
	RETc(ne)

	@ Result is x + x = 2x.
	tst	r2, #0xff000000
	bne	2f
	movs	r0, r0, lsl #1
	do_it	cs
	orrcs	r0, r0, #0x80000000
	RET
2:	adds	r2, r2, #(2 << 24)
	do_it	cc, t
	addcc	r0, r0, #(1 << 23)
	RETc(cc)
	and	r3, r0, #0x80000000

	@ Overflow: return INF.
LSYM(Lad_o):
	orr	r0, r3, #0x7f000000
	orr	r0, r0, #0x00800000
	RET

	@ At least one of r0/r1 is INF/NAN.
	@   if r0 != INF/NAN: return r1 (which is INF/NAN)
	@   if r1 != INF/NAN: return r0 (which is INF/NAN)
	@   if r0 or r1 is NAN: return NAN
	@   if opposite sign: return NAN
	@   otherwise return r0 (which is INF or -INF)
LSYM(Lad_i):
	mvns	r2, r2, asr #24
	do_it	ne, et
	movne	r0, r1
	COND(mvn,s,eq)	r3, r3, asr #24
	movne	r1, r0
	movs	r2, r0, lsl #9
	do_it	eq, te
	COND(mov,s,eq)	r3, r1, lsl #9
	teqeq	r0, r1
	orrne	r0, r0, #0x00400000	@ quiet NAN
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_frsub
	FUNC_END aeabi_fadd
	FUNC_END addsf3
	FUNC_END aeabi_fsub
	FUNC_END subsf3

ARM_FUNC_START floatunsisf
ARM_FUNC_ALIAS aeabi_ui2f floatunsisf
	CFI_START_FUNCTION
		
	mov	r3, #0
	b	1f

ARM_FUNC_START floatsisf
ARM_FUNC_ALIAS aeabi_i2f floatsisf
	
	ands	r3, r0, #0x80000000
	do_it	mi
	rsbmi	r0, r0, #0

1:	movs	ip, r0
	do_it	eq
	RETc(eq)

	@ Add initial exponent to sign
	orr	r3, r3, #((127 + 23) << 23)

	.ifnc	ah, r0
	mov	ah, r0
	.endif
	mov	al, #0
	b	2f

	CFI_END_FUNCTION
	FUNC_END aeabi_i2f
	FUNC_END floatsisf
	FUNC_END aeabi_ui2f
	FUNC_END floatunsisf

ARM_FUNC_START floatundisf
ARM_FUNC_ALIAS aeabi_ul2f floatundisf
	CFI_START_FUNCTION

	orrs	r2, r0, r1
	do_it	eq
	RETc(eq)

	mov	r3, #0
	b	1f

ARM_FUNC_START floatdisf
ARM_FUNC_ALIAS aeabi_l2f floatdisf

	orrs	r2, r0, r1
	do_it	eq
	RETc(eq)

	ands	r3, ah, #0x80000000	@ sign bit in r3
	bpl	1f
#if defined(__thumb2__)
	negs	al, al
	sbc	ah, ah, ah, lsl #1
#else
	rsbs	al, al, #0
	rsc	ah, ah, #0
#endif
1:
	movs	ip, ah
	do_it	eq, tt
	moveq	ip, al
	moveq	ah, al
	moveq	al, #0

	@ Add initial exponent to sign
	orr	r3, r3, #((127 + 23 + 32) << 23)
	do_it	eq
	subeq	r3, r3, #(32 << 23)
2:	sub	r3, r3, #(1 << 23)

#if !defined (__ARM_FEATURE_CLZ)

	mov	r2, #23
	cmp	ip, #(1 << 16)
	do_it	hs, t
	movhs	ip, ip, lsr #16
	subhs	r2, r2, #16
	cmp	ip, #(1 << 8)
	do_it	hs, t
	movhs	ip, ip, lsr #8
	subhs	r2, r2, #8
	cmp	ip, #(1 << 4)
	do_it	hs, t
	movhs	ip, ip, lsr #4
	subhs	r2, r2, #4
	cmp	ip, #(1 << 2)
	do_it	hs, e
	subhs	r2, r2, #2
	sublo	r2, r2, ip, lsr #1
	subs	r2, r2, ip, lsr #3

#else

	clz	r2, ip
	subs	r2, r2, #8

#endif

	sub	r3, r3, r2, lsl #23
	blt	3f

	shiftop add r3 r3 ah lsl r2 ip
	shift1	lsl, ip, al, r2
	rsb	r2, r2, #32
	cmp	ip, #0x80000000
	shiftop adc r0 r3 al lsr r2 r2
	do_it	eq
	biceq	r0, r0, #1
	RET

3:	add	r2, r2, #32
	shift1	lsl, ip, ah, r2
	rsb	r2, r2, #32
	orrs	al, al, ip, lsl #1
	shiftop adc r0 r3 ah lsr r2 r2
	do_it	eq
	biceq	r0, r0, ip, lsr #31
	RET

	CFI_END_FUNCTION
	FUNC_END floatdisf
	FUNC_END aeabi_l2f
	FUNC_END floatundisf
	FUNC_END aeabi_ul2f

#endif /* L_addsubsf3 */

#if defined(L_arm_mulsf3) || defined(L_arm_muldivsf3)

@ Define multiplication as weak in _arm_mulsf3.o so that it can be overriden
@ by the global definition in _arm_muldivsf3.o.  This allows a program only
@ using multiplication to take the weak definition which does not contain the
@ division code. Programs using only division or both division and
@ multiplication will pull _arm_muldivsf3.o from which both the multiplication
@ and division are taken thanks to the override.
#ifdef L_arm_mulsf3
WEAK mulsf3
WEAK aeabi_fmul
#endif

ARM_FUNC_START mulsf3
ARM_FUNC_ALIAS aeabi_fmul mulsf3
	CFI_START_FUNCTION

	@ Mask out exponents, trap any zero/denormal/INF/NAN.
	mov	ip, #0xff
	ands	r2, ip, r0, lsr #23
	do_it	ne, tt
	COND(and,s,ne)	r3, ip, r1, lsr #23
	teqne	r2, ip
	teqne	r3, ip
	beq	LSYM(Lml_s)
LSYM(Lml_x):

	@ Add exponents together
	add	r2, r2, r3

	@ Determine final sign.
	eor	ip, r0, r1

	@ Convert mantissa to unsigned integer.
	@ If power of two, branch to a separate path.
	@ Make up for final alignment.
	movs	r0, r0, lsl #9
	do_it	ne
	COND(mov,s,ne)	r1, r1, lsl #9
	beq	LSYM(Lml_1)
	mov	r3, #0x08000000
	orr	r0, r3, r0, lsr #5
	orr	r1, r3, r1, lsr #5

	@ The actual multiplication.
	@ This code works on architecture versions >= 4
	umull	r3, r1, r0, r1

	@ Put final sign in r0.
	and	r0, ip, #0x80000000

	@ Adjust result upon the MSB position.
	cmp	r1, #(1 << 23)
	do_it	cc, tt
	movcc	r1, r1, lsl #1
	orrcc	r1, r1, r3, lsr #31
	movcc	r3, r3, lsl #1

	@ Add sign to result.
	orr	r0, r0, r1

	@ Apply exponent bias, check for under/overflow.
	sbc	r2, r2, #127
	cmp	r2, #(254 - 1)
	bhi	LSYM(Lml_u)

	@ Round the result, merge final exponent.
	cmp	r3, #0x80000000
	adc	r0, r0, r2, lsl #23
	do_it	eq
	biceq	r0, r0, #1
	RET

	@ Multiplication by 0x1p*: let''s shortcut a lot of code.
LSYM(Lml_1):
	teq	r0, #0
	and	ip, ip, #0x80000000
	do_it	eq
	moveq	r1, r1, lsl #9
	orr	r0, ip, r0, lsr #9
	orr	r0, r0, r1, lsr #9
	subs	r2, r2, #127
	do_it	gt, tt
	COND(rsb,s,gt)	r3, r2, #255
	orrgt	r0, r0, r2, lsl #23
	RETc(gt)

	@ Under/overflow: fix things up for the code below.
	orr	r0, r0, #0x00800000
	mov	r3, #0
	subs	r2, r2, #1

LSYM(Lml_u):
	@ Overflow?
	bgt	LSYM(Lml_o)

	@ Check if denormalized result is possible, otherwise return signed 0.
	cmn	r2, #(24 + 1)
	do_it	le, t
	bicle	r0, r0, #0x7fffffff
	RETc(le)

	@ Shift value right, round, etc.
	rsb	r2, r2, #0
	movs	r1, r0, lsl #1
	shift1	lsr, r1, r1, r2
	rsb	r2, r2, #32
	shift1	lsl, ip, r0, r2
	movs	r0, r1, rrx
	adc	r0, r0, #0
	orrs	r3, r3, ip, lsl #1
	do_it	eq
	biceq	r0, r0, ip, lsr #31
	RET

	@ One or both arguments are denormalized.
	@ Scale them leftwards and preserve sign bit.
LSYM(Lml_d):
	teq	r2, #0
	and	ip, r0, #0x80000000
1:	do_it	eq, tt
	moveq	r0, r0, lsl #1
	tsteq	r0, #0x00800000
	subeq	r2, r2, #1
	beq	1b
	orr	r0, r0, ip
	teq	r3, #0
	and	ip, r1, #0x80000000
2:	do_it	eq, tt
	moveq	r1, r1, lsl #1
	tsteq	r1, #0x00800000
	subeq	r3, r3, #1
	beq	2b
	orr	r1, r1, ip
	b	LSYM(Lml_x)

LSYM(Lml_s):
	@ Isolate the INF and NAN cases away
	and	r3, ip, r1, lsr #23
	teq	r2, ip
	do_it	ne
	teqne	r3, ip
	beq	1f

	@ Here, one or more arguments are either denormalized or zero.
	bics	ip, r0, #0x80000000
	do_it	ne
	COND(bic,s,ne)	ip, r1, #0x80000000
	bne	LSYM(Lml_d)

	@ Result is 0, but determine sign anyway.
LSYM(Lml_z):
	eor	r0, r0, r1
	bic	r0, r0, #0x7fffffff
	RET

1:	@ One or both args are INF or NAN.
	teq	r0, #0x0
	do_it	ne, ett
	teqne	r0, #0x80000000
	moveq	r0, r1
	teqne	r1, #0x0
	teqne	r1, #0x80000000
	beq	LSYM(Lml_n)		@ 0 * INF or INF * 0 -> NAN
	teq	r2, ip
	bne	1f
	movs	r2, r0, lsl #9
	bne	LSYM(Lml_n)		@ NAN * <anything> -> NAN
1:	teq	r3, ip
	bne	LSYM(Lml_i)
	movs	r3, r1, lsl #9
	do_it	ne
	movne	r0, r1
	bne	LSYM(Lml_n)		@ <anything> * NAN -> NAN

	@ Result is INF, but we need to determine its sign.
LSYM(Lml_i):
	eor	r0, r0, r1

	@ Overflow: return INF (sign already in r0).
LSYM(Lml_o):
	and	r0, r0, #0x80000000
	orr	r0, r0, #0x7f000000
	orr	r0, r0, #0x00800000
	RET

	@ Return a quiet NAN.
LSYM(Lml_n):
	orr	r0, r0, #0x7f000000
	orr	r0, r0, #0x00c00000
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_fmul
	FUNC_END mulsf3

#ifdef L_arm_muldivsf3

ARM_FUNC_START divsf3
ARM_FUNC_ALIAS aeabi_fdiv divsf3
	CFI_START_FUNCTION

	@ Mask out exponents, trap any zero/denormal/INF/NAN.
	mov	ip, #0xff
	ands	r2, ip, r0, lsr #23
	do_it	ne, tt
	COND(and,s,ne)	r3, ip, r1, lsr #23
	teqne	r2, ip
	teqne	r3, ip
	beq	LSYM(Ldv_s)
LSYM(Ldv_x):

	@ Subtract divisor exponent from dividend''s
	sub	r2, r2, r3

	@ Preserve final sign into ip.
	eor	ip, r0, r1

	@ Convert mantissa to unsigned integer.
	@ Dividend -> r3, divisor -> r1.
	movs	r1, r1, lsl #9
	mov	r0, r0, lsl #9
	beq	LSYM(Ldv_1)
	mov	r3, #0x10000000
	orr	r1, r3, r1, lsr #4
	orr	r3, r3, r0, lsr #4

	@ Initialize r0 (result) with final sign bit.
	and	r0, ip, #0x80000000

	@ Ensure result will land to known bit position.
	@ Apply exponent bias accordingly.
	cmp	r3, r1
	do_it	cc
	movcc	r3, r3, lsl #1
	adc	r2, r2, #(127 - 2)

	@ The actual division loop.
	mov	ip, #0x00800000
1:	cmp	r3, r1
	do_it	cs, t
	subcs	r3, r3, r1
	orrcs	r0, r0, ip
	cmp	r3, r1, lsr #1
	do_it	cs, t
	subcs	r3, r3, r1, lsr #1
	orrcs	r0, r0, ip, lsr #1
	cmp	r3, r1, lsr #2
	do_it	cs, t
	subcs	r3, r3, r1, lsr #2
	orrcs	r0, r0, ip, lsr #2
	cmp	r3, r1, lsr #3
	do_it	cs, t
	subcs	r3, r3, r1, lsr #3
	orrcs	r0, r0, ip, lsr #3
	movs	r3, r3, lsl #4
	do_it	ne
	COND(mov,s,ne)	ip, ip, lsr #4
	bne	1b

	@ Check exponent for under/overflow.
	cmp	r2, #(254 - 1)
	bhi	LSYM(Lml_u)

	@ Round the result, merge final exponent.
	cmp	r3, r1
	adc	r0, r0, r2, lsl #23
	do_it	eq
	biceq	r0, r0, #1
	RET

	@ Division by 0x1p*: let''s shortcut a lot of code.
LSYM(Ldv_1):
	and	ip, ip, #0x80000000
	orr	r0, ip, r0, lsr #9
	adds	r2, r2, #127
	do_it	gt, tt
	COND(rsb,s,gt)	r3, r2, #255
	orrgt	r0, r0, r2, lsl #23
	RETc(gt)

	orr	r0, r0, #0x00800000
	mov	r3, #0
	subs	r2, r2, #1
	b	LSYM(Lml_u)

	@ One or both arguments are denormalized.
	@ Scale them leftwards and preserve sign bit.
LSYM(Ldv_d):
	teq	r2, #0
	and	ip, r0, #0x80000000
1:	do_it	eq, tt
	moveq	r0, r0, lsl #1
	tsteq	r0, #0x00800000
	subeq	r2, r2, #1
	beq	1b
	orr	r0, r0, ip
	teq	r3, #0
	and	ip, r1, #0x80000000
2:	do_it	eq, tt
	moveq	r1, r1, lsl #1
	tsteq	r1, #0x00800000
	subeq	r3, r3, #1
	beq	2b
	orr	r1, r1, ip
	b	LSYM(Ldv_x)

	@ One or both arguments are either INF, NAN, zero or denormalized.
LSYM(Ldv_s):
	and	r3, ip, r1, lsr #23
	teq	r2, ip
	bne	1f
	movs	r2, r0, lsl #9
	bne	LSYM(Lml_n)		@ NAN / <anything> -> NAN
	teq	r3, ip
	bne	LSYM(Lml_i)		@ INF / <anything> -> INF
	mov	r0, r1
	b	LSYM(Lml_n)		@ INF / (INF or NAN) -> NAN
1:	teq	r3, ip
	bne	2f
	movs	r3, r1, lsl #9
	beq	LSYM(Lml_z)		@ <anything> / INF -> 0
	mov	r0, r1
	b	LSYM(Lml_n)		@ <anything> / NAN -> NAN
2:	@ If both are nonzero, we need to normalize and resume above.
	bics	ip, r0, #0x80000000
	do_it	ne
	COND(bic,s,ne)	ip, r1, #0x80000000
	bne	LSYM(Ldv_d)
	@ One or both arguments are zero.
	bics	r2, r0, #0x80000000
	bne	LSYM(Lml_i)		@ <non_zero> / 0 -> INF
	bics	r3, r1, #0x80000000
	bne	LSYM(Lml_z)		@ 0 / <non_zero> -> 0
	b	LSYM(Lml_n)		@ 0 / 0 -> NAN

	CFI_END_FUNCTION
	FUNC_END aeabi_fdiv
	FUNC_END divsf3

#endif /* L_muldivsf3 */
#endif /* L_arm_mulsf3 || L_arm_muldivsf3 */

#ifdef L_arm_cmpsf2

	@ The return value in r0 is
	@
	@   0  if the operands are equal
	@   1  if the first operand is greater than the second, or
	@      the operands are unordered and the operation is
	@      CMP, LT, LE, NE, or EQ.
	@   -1 if the first operand is less than the second, or
	@      the operands are unordered and the operation is GT
	@      or GE.
	@
	@ The Z flag will be set iff the operands are equal.
	@
	@ The following registers are clobbered by this function:
	@   ip, r0, r1, r2, r3

ARM_FUNC_START gtsf2
ARM_FUNC_ALIAS gesf2 gtsf2
	CFI_START_FUNCTION
	mov	ip, #-1
	b	1f

ARM_FUNC_START ltsf2
ARM_FUNC_ALIAS lesf2 ltsf2
	mov	ip, #1
	b	1f

ARM_FUNC_START cmpsf2
ARM_FUNC_ALIAS nesf2 cmpsf2
ARM_FUNC_ALIAS eqsf2 cmpsf2
	mov	ip, #1			@ how should we specify unordered here?

1:	str	ip, [sp, #-4]!
	.cfi_adjust_cfa_offset 4  @ CFA is now sp + previousOffset + 4.
	@ We're not adding CFI for ip as it's pushed into the stack only because
	@ it may be popped off later as a return value (i.e. we're not preserving
	@ it anyways).

	@ Trap any INF/NAN first.
	mov	r2, r0, lsl #1
	mov	r3, r1, lsl #1
	mvns	ip, r2, asr #24
	do_it	ne
	COND(mvn,s,ne)	ip, r3, asr #24
	beq	3f
	.cfi_remember_state
	@ Save the current CFI state. This is done because the branch is conditional,
	@ and if we don't take it we'll issue a .cfi_adjust_cfa_offset and return.
	@ If we do take it, however, the .cfi_adjust_cfa_offset from the non-branch
	@ code will affect the branch code as well. To avoid this we'll restore
	@ the current state before executing the branch code.

	@ Compare values.
	@ Note that 0.0 is equal to -0.0.
2:	add	sp, sp, #4
	.cfi_adjust_cfa_offset -4       @ CFA is now sp + previousOffset.

	orrs	ip, r2, r3, lsr #1	@ test if both are 0, clear C flag
	do_it	ne
	teqne	r0, r1			@ if not 0 compare sign
	do_it	pl
	COND(sub,s,pl)	r0, r2, r3		@ if same sign compare values, set r0

	@ Result:
	do_it	hi
	movhi	r0, r1, asr #31
	do_it	lo
	mvnlo	r0, r1, asr #31
	do_it	ne
	orrne	r0, r0, #1
	RET

3:	@ Look for a NAN.

	@ Restore the previous CFI state (i.e. keep the CFI state as it was
	@ before the branch).
	.cfi_restore_state

	mvns	ip, r2, asr #24
	bne	4f
	movs	ip, r0, lsl #9
	bne	5f			@ r0 is NAN
4:	mvns	ip, r3, asr #24
	bne	2b
	movs	ip, r1, lsl #9
	beq	2b			@ r1 is not NAN

5:	ldr	r0, [sp], #4		@ return unordered code.
	.cfi_adjust_cfa_offset -4       @ CFA is now sp + previousOffset.
	RET

	CFI_END_FUNCTION
	FUNC_END gesf2
	FUNC_END gtsf2
	FUNC_END lesf2
	FUNC_END ltsf2
	FUNC_END nesf2
	FUNC_END eqsf2
	FUNC_END cmpsf2

ARM_FUNC_START aeabi_cfrcmple
	CFI_START_FUNCTION

	mov	ip, r0
	mov	r0, r1
	mov	r1, ip
	b	6f

ARM_FUNC_START aeabi_cfcmpeq
ARM_FUNC_ALIAS aeabi_cfcmple aeabi_cfcmpeq

	@ The status-returning routines are required to preserve all
	@ registers except ip, lr, and cpsr.
6:	do_push	{r0, r1, r2, r3, lr}
	.cfi_adjust_cfa_offset 20  @ CFA is at sp + previousOffset + 20
	.cfi_rel_offset r0, 0      @ Registers are saved from sp to sp + 16
	.cfi_rel_offset r1, 4
	.cfi_rel_offset r2, 8
	.cfi_rel_offset r3, 12
	.cfi_rel_offset lr, 16

	ARM_CALL cmpsf2
	@ Set the Z flag correctly, and the C flag unconditionally.
	cmp	r0, #0
	@ Clear the C flag if the return value was -1, indicating
	@ that the first operand was smaller than the second.
	do_it	mi
	cmnmi	r0, #0
	RETLDM	"r0, r1, r2, r3"

	CFI_END_FUNCTION
	FUNC_END aeabi_cfcmple
	FUNC_END aeabi_cfcmpeq
	FUNC_END aeabi_cfrcmple

ARM_FUNC_START	aeabi_fcmpeq
	CFI_START_FUNCTION

	str	lr, [sp, #-8]!    @ sp -= 8
	.cfi_adjust_cfa_offset 8  @ CFA is now sp + previousOffset + 8
	.cfi_rel_offset lr, 0     @ lr is at sp

	ARM_CALL aeabi_cfcmple
	do_it	eq, e
	moveq	r0, #1	@ Equal to.
	movne	r0, #0	@ Less than, greater than, or unordered.
	RETLDM

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmpeq

ARM_FUNC_START	aeabi_fcmplt
	CFI_START_FUNCTION

	str	lr, [sp, #-8]!    @ sp -= 8
	.cfi_adjust_cfa_offset 8  @ CFA is now sp + previousOffset + 8
	.cfi_rel_offset lr, 0     @ lr is at sp

	ARM_CALL aeabi_cfcmple
	do_it	cc, e
	movcc	r0, #1	@ Less than.
	movcs	r0, #0	@ Equal to, greater than, or unordered.
	RETLDM

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmplt

ARM_FUNC_START	aeabi_fcmple
	CFI_START_FUNCTION

	str	lr, [sp, #-8]!    @ sp -= 8
	.cfi_adjust_cfa_offset 8  @ CFA is now sp + previousOffset + 8
	.cfi_rel_offset lr, 0     @ lr is at sp

	ARM_CALL aeabi_cfcmple
	do_it	ls, e
	movls	r0, #1  @ Less than or equal to.
	movhi	r0, #0	@ Greater than or unordered.
	RETLDM

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmple

ARM_FUNC_START	aeabi_fcmpge
	CFI_START_FUNCTION

	str	lr, [sp, #-8]!    @ sp -= 8
	.cfi_adjust_cfa_offset 8  @ CFA is now sp + previousOffset + 8
	.cfi_rel_offset lr, 0     @ lr is at sp

	ARM_CALL aeabi_cfrcmple
	do_it	ls, e
	movls	r0, #1	@ Operand 2 is less than or equal to operand 1.
	movhi	r0, #0	@ Operand 2 greater than operand 1, or unordered.
	RETLDM

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmpge

ARM_FUNC_START	aeabi_fcmpgt
	CFI_START_FUNCTION

	str	lr, [sp, #-8]!    @ sp -= 8
	.cfi_adjust_cfa_offset 8  @ CFA is now sp + previousOffset + 8
	.cfi_rel_offset lr, 0     @ lr is at sp

	ARM_CALL aeabi_cfrcmple
	do_it	cc, e
	movcc	r0, #1	@ Operand 2 is less than operand 1.
	movcs	r0, #0  @ Operand 2 is greater than or equal to operand 1,
			@ or they are unordered.
	RETLDM

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmpgt

#endif /* L_cmpsf2 */

#ifdef L_arm_unordsf2

ARM_FUNC_START unordsf2
ARM_FUNC_ALIAS aeabi_fcmpun unordsf2
	CFI_START_FUNCTION

	mov	r2, r0, lsl #1
	mov	r3, r1, lsl #1
	mvns	ip, r2, asr #24
	bne	1f
	movs	ip, r0, lsl #9
	bne	3f			@ r0 is NAN
1:	mvns	ip, r3, asr #24
	bne	2f
	movs	ip, r1, lsl #9
	bne	3f			@ r1 is NAN
2:	mov	r0, #0			@ arguments are ordered.
	RET
3:	mov	r0, #1			@ arguments are unordered.
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_fcmpun
	FUNC_END unordsf2

#endif /* L_unordsf2 */

#ifdef L_arm_fixsfsi

ARM_FUNC_START fixsfsi
ARM_FUNC_ALIAS aeabi_f2iz fixsfsi
	CFI_START_FUNCTION

	@ check exponent range.
	mov	r2, r0, lsl #1
	cmp	r2, #(127 << 24)
	bcc	1f			@ value is too small
	mov	r3, #(127 + 31)
	subs	r2, r3, r2, lsr #24
	bls	2f			@ value is too large

	@ scale value
	mov	r3, r0, lsl #8
	orr	r3, r3, #0x80000000
	tst	r0, #0x80000000		@ the sign bit
	shift1	lsr, r0, r3, r2
	do_it	ne
	rsbne	r0, r0, #0
	RET

1:	mov	r0, #0
	RET

2:	cmp	r2, #(127 + 31 - 0xff)
	bne	3f
	movs	r2, r0, lsl #9
	bne	4f			@ r0 is NAN.
3:	ands	r0, r0, #0x80000000	@ the sign bit
	do_it	eq
	moveq	r0, #0x7fffffff		@ the maximum signed positive si
	RET

4:	mov	r0, #0			@ What should we convert NAN to?
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_f2iz
	FUNC_END fixsfsi

#endif /* L_fixsfsi */

#ifdef L_arm_fixunssfsi

ARM_FUNC_START fixunssfsi
ARM_FUNC_ALIAS aeabi_f2uiz fixunssfsi
	CFI_START_FUNCTION

	@ check exponent range.
	movs	r2, r0, lsl #1
	bcs	1f			@ value is negative
	cmp	r2, #(127 << 24)
	bcc	1f			@ value is too small
	mov	r3, #(127 + 31)
	subs	r2, r3, r2, lsr #24
	bmi	2f			@ value is too large

	@ scale the value
	mov	r3, r0, lsl #8
	orr	r3, r3, #0x80000000
	shift1	lsr, r0, r3, r2
	RET

1:	mov	r0, #0
	RET

2:	cmp	r2, #(127 + 31 - 0xff)
	bne	3f
	movs	r2, r0, lsl #9
	bne	4f			@ r0 is NAN.
3:	mov	r0, #0xffffffff		@ maximum unsigned si
	RET

4:	mov	r0, #0			@ What should we convert NAN to?
	RET

	CFI_END_FUNCTION
	FUNC_END aeabi_f2uiz
	FUNC_END fixunssfsi

#endif /* L_fixunssfsi */
