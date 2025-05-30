/**********************************************************************
  Copyright(c) 2019 Arm Corporation All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name of Arm Corporation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********************************************************************/
	.arch armv8-a+crypto
	.text
	.align	2
	.p2align 3,,7

/*
Macros
*/

.macro	declare_var_vector_reg name:req,reg:req
	\name\()_q	.req	q\reg
	\name\()_v	.req	v\reg
	\name\()_s	.req	s\reg
.endm
/**
maros for round 48-63
*/
.macro sha256_4_rounds_high msg:req,tmp0:req,tmp1:req
	ldr		key_q , [tmp]
	mov		l0_tmp2_v.16b,l0_abcd_v.16b
	mov		l1_tmp2_v.16b,l1_abcd_v.16b
	mov		l2_tmp2_v.16b,l2_abcd_v.16b
	add		tmp,tmp,16
	add		l0_\tmp1\()_v.4s,l0_\msg\()_v.4s,key_v.4s
	add		l1_\tmp1\()_v.4s,l1_\msg\()_v.4s,key_v.4s
	add		l2_\tmp1\()_v.4s,l2_\msg\()_v.4s,key_v.4s
	sha256h		l0_abcd_q,l0_efgh_q,l0_\tmp0\()_v.4s
	sha256h		l1_abcd_q,l1_efgh_q,l1_\tmp0\()_v.4s
	sha256h		l2_abcd_q,l2_efgh_q,l2_\tmp0\()_v.4s
	sha256h2	l0_efgh_q,l0_tmp2_q,l0_\tmp0\()_v.4s
	sha256h2	l1_efgh_q,l1_tmp2_q,l1_\tmp0\()_v.4s
	sha256h2	l2_efgh_q,l2_tmp2_q,l2_\tmp0\()_v.4s

.endm
/**
maros for round 0-47
*/
.macro sha256_4_rounds_low msg0:req,msg1:req,msg2:req,msg3:req,tmp0:req,tmp1:req
	sha256su0		l0_\msg0\()_v.4s,l0_\msg1\()_v.4s
	sha256su0		l1_\msg0\()_v.4s,l1_\msg1\()_v.4s
	sha256su0		l2_\msg0\()_v.4s,l2_\msg1\()_v.4s
	sha256_4_rounds_high	\msg1,\tmp0,\tmp1
	sha256su1		l0_\msg0\()_v.4s,l0_\msg2\()_v.4s,l0_\msg3\()_v.4s
	sha256su1		l1_\msg0\()_v.4s,l1_\msg2\()_v.4s,l1_\msg3\()_v.4s
	sha256su1		l2_\msg0\()_v.4s,l2_\msg2\()_v.4s,l2_\msg3\()_v.4s
.endm


/*
Variable list
*/

	declare_var_vector_reg	key,31


/*
digest variables
*/
	declare_var_vector_reg	l0_abcd,0
	declare_var_vector_reg	l0_efgh,1
	declare_var_vector_reg	l1_abcd,2
	declare_var_vector_reg	l1_efgh,3
	declare_var_vector_reg	l2_abcd,4
	declare_var_vector_reg	l2_efgh,5
	declare_var_vector_reg	l1_abcd_saved,16
	declare_var_vector_reg	l1_efgh_saved,17
	declare_var_vector_reg	l0_abcd_saved,20
	declare_var_vector_reg	l0_efgh_saved,21
	declare_var_vector_reg	l2_abcd_saved,24
	declare_var_vector_reg	l2_efgh_saved,25
/*
Temporary variables
*/
	declare_var_vector_reg	l0_tmp0,6
	declare_var_vector_reg	l0_tmp1,7
	declare_var_vector_reg	l0_tmp2,8
	declare_var_vector_reg	l1_tmp0,9
	declare_var_vector_reg	l1_tmp1,10
	declare_var_vector_reg	l1_tmp2,11
	declare_var_vector_reg	l2_tmp0,12
	declare_var_vector_reg	l2_tmp1,13
	declare_var_vector_reg	l2_tmp2,14
/*
Message variables
*/
	declare_var_vector_reg	l0_msg0,16
	declare_var_vector_reg	l0_msg1,17
	declare_var_vector_reg	l0_msg2,18
	declare_var_vector_reg	l0_msg3,19
	declare_var_vector_reg	l1_msg0,20
	declare_var_vector_reg	l1_msg1,21
	declare_var_vector_reg	l1_msg2,22
	declare_var_vector_reg	l1_msg3,23
	declare_var_vector_reg	l2_msg0,24
	declare_var_vector_reg	l2_msg1,25
	declare_var_vector_reg	l2_msg2,26
	declare_var_vector_reg	l2_msg3,27



/*
	void sha256_mb_ce_x3(ISAL_SHA256_JOB *, ISAL_SHA256_JOB *, ISAL_SHA256_JOB *, int);
*/
/*
Arguments list
*/
	l0_job 	.req	x0
	l1_job 	.req	x1
	l2_job 	.req	x2
	len	.req	w3
	l0_data	.req	x4
	l1_data	.req	x5
	l2_data	.req	x6
	tmp	.req	x7
	.global	sha256_mb_ce_x3
	.type	sha256_mb_ce_x3, %function
sha256_mb_ce_x3:
	//push d8~d15
	stp 	d8,d9,[sp,-192]!
	stp 	d10,d11,[sp,16]
	stp 	d12,d13,[sp,32]
	stp 	d14,d15,[sp,48]
	ldr	l0_data, [l0_job]
	ldr	l0_abcd_q, [l0_job, 64]
	ldr	l0_efgh_q, [l0_job, 80]
	ldr	l1_data,   [l1_job]
	ldr	l1_abcd_q, [l1_job, 64]
	ldr	l1_efgh_q, [l1_job, 80]
	ldr	l2_data,   [l2_job]
	ldr	l2_abcd_q, [l2_job, 64]
	ldr	l2_efgh_q, [l2_job, 80]



start_loop:

	//load key addr
	adrp	tmp, KEY
	add	tmp, tmp, :lo12:KEY
	//load msgs
	ld1	{l0_msg0_v.4s-l0_msg3_v.4s},[l0_data]
	ld1	{l1_msg0_v.4s-l1_msg3_v.4s},[l1_data]
	ld1	{l2_msg0_v.4s-l2_msg3_v.4s},[l2_data]
	ldr	key_q,[tmp]
	add	tmp,tmp,16
	//adjust loop parameter
	add	l0_data,l0_data,64
	add	l1_data,l1_data,64
	add	l2_data,l2_data,64
	sub	len, len, #1
	cmp	len, 0
/*
	//backup digest
	mov	l0_abcd_saved_v.16b,l0_abcd_v.16b
	mov	l0_efgh_saved_v.16b,l0_efgh_v.16b
	mov	l1_abcd_saved_v.16b,l1_abcd_v.16b
	mov	l1_efgh_saved_v.16b,l1_efgh_v.16b
	mov	l2_abcd_saved_v.16b,l2_abcd_v.16b
	mov	l2_efgh_saved_v.16b,l2_efgh_v.16b
*/

	rev32	l0_msg0_v.16b,l0_msg0_v.16b
	rev32	l0_msg1_v.16b,l0_msg1_v.16b
	add	l0_tmp0_v.4s, l0_msg0_v.4s,key_v.4s
	rev32	l0_msg2_v.16b,l0_msg2_v.16b
	rev32	l0_msg3_v.16b,l0_msg3_v.16b

	rev32	l1_msg0_v.16b,l1_msg0_v.16b
	rev32	l1_msg1_v.16b,l1_msg1_v.16b
	add	l1_tmp0_v.4s, l1_msg0_v.4s,key_v.4s
	rev32	l1_msg2_v.16b,l1_msg2_v.16b
	rev32	l1_msg3_v.16b,l1_msg3_v.16b

	rev32	l2_msg0_v.16b,l2_msg0_v.16b
	rev32	l2_msg1_v.16b,l2_msg1_v.16b
	add	l2_tmp0_v.4s, l2_msg0_v.4s,key_v.4s
	rev32	l2_msg2_v.16b,l2_msg2_v.16b
	rev32	l2_msg3_v.16b,l2_msg3_v.16b



	sha256_4_rounds_low	msg0,msg1,msg2,msg3,tmp0,tmp1    /* rounds 0-3 */
	sha256_4_rounds_low	msg1,msg2,msg3,msg0,tmp1,tmp0
	sha256_4_rounds_low	msg2,msg3,msg0,msg1,tmp0,tmp1
	sha256_4_rounds_low	msg3,msg0,msg1,msg2,tmp1,tmp0

	sha256_4_rounds_low	msg0,msg1,msg2,msg3,tmp0,tmp1    /* rounds 16-19 */
	sha256_4_rounds_low	msg1,msg2,msg3,msg0,tmp1,tmp0
	sha256_4_rounds_low	msg2,msg3,msg0,msg1,tmp0,tmp1
	sha256_4_rounds_low	msg3,msg0,msg1,msg2,tmp1,tmp0
	sha256_4_rounds_low	msg0,msg1,msg2,msg3,tmp0,tmp1    /* rounds 32-35 */
	sha256_4_rounds_low	msg1,msg2,msg3,msg0,tmp1,tmp0
	sha256_4_rounds_low	msg2,msg3,msg0,msg1,tmp0,tmp1
	sha256_4_rounds_low	msg3,msg0,msg1,msg2,tmp1,tmp0



	sha256_4_rounds_high	msg1,tmp0,tmp1			/* rounds 48-51 */

	/* msg0 msg1 is free , share with digest regs */
	ldr	l0_abcd_saved_q, [l0_job, 64]
	ldr	l1_abcd_saved_q, [l1_job, 64]
	ldr	l2_abcd_saved_q, [l2_job, 64]
	ldr	l0_efgh_saved_q, [l0_job, 80]
	ldr	l1_efgh_saved_q, [l1_job, 80]
	ldr	l2_efgh_saved_q, [l2_job, 80]

	sha256_4_rounds_high	msg2,tmp1,tmp0
	sha256_4_rounds_high	msg3,tmp0,tmp1

	/* rounds 60-63 */
	mov		l0_tmp2_v.16b,l0_abcd_v.16b
	sha256h		l0_abcd_q,l0_efgh_q,l0_tmp1_v.4s
	sha256h2	l0_efgh_q,l0_tmp2_q,l0_tmp1_v.4s

	mov		l1_tmp2_v.16b,l1_abcd_v.16b
	sha256h		l1_abcd_q,l1_efgh_q,l1_tmp1_v.4s
	sha256h2	l1_efgh_q,l1_tmp2_q,l1_tmp1_v.4s

	mov		l2_tmp2_v.16b,l2_abcd_v.16b
	sha256h		l2_abcd_q,l2_efgh_q,l2_tmp1_v.4s
	sha256h2	l2_efgh_q,l2_tmp2_q,l2_tmp1_v.4s

	/* combine state */
	add     l0_abcd_v.4s,l0_abcd_v.4s,l0_abcd_saved_v.4s
	add     l0_efgh_v.4s,l0_efgh_v.4s,l0_efgh_saved_v.4s
	add     l1_abcd_v.4s,l1_abcd_v.4s,l1_abcd_saved_v.4s
	add     l1_efgh_v.4s,l1_efgh_v.4s,l1_efgh_saved_v.4s
	add     l2_abcd_v.4s,l2_abcd_v.4s,l2_abcd_saved_v.4s
	add     l2_efgh_v.4s,l2_efgh_v.4s,l2_efgh_saved_v.4s

	str	l0_abcd_q,	[l0_job, 64]
	str	l0_efgh_q, 	[l0_job, 80]
	str	l1_abcd_q,	[l1_job, 64]
	str	l1_efgh_q, 	[l1_job, 80]
	str	l2_abcd_q,	[l2_job, 64]
	str	l2_efgh_q, 	[l2_job, 80]

	bgt	start_loop


	ldp 	d10,d11,[sp,16]
	ldp 	d12,d13,[sp,32]
	ldp 	d14,d15,[sp,48]
	ldp     d8, d9, [sp], 192
	ret

	.size	sha256_mb_ce_x3, .-sha256_mb_ce_x3
	.section	.rol0_data.cst16,"aM",@progbits,16
	.align	4
KEY:
	.word 0x428A2F98
	.word 0x71374491
	.word 0xB5C0FBCF
	.word 0xE9B5DBA5
	.word 0x3956C25B
	.word 0x59F111F1
	.word 0x923F82A4
	.word 0xAB1C5ED5
	.word 0xD807AA98
	.word 0x12835B01
	.word 0x243185BE
	.word 0x550C7DC3
	.word 0x72BE5D74
	.word 0x80DEB1FE
	.word 0x9BDC06A7
	.word 0xC19BF174
	.word 0xE49B69C1
	.word 0xEFBE4786
	.word 0x0FC19DC6
	.word 0x240CA1CC
	.word 0x2DE92C6F
	.word 0x4A7484AA
	.word 0x5CB0A9DC
	.word 0x76F988DA
	.word 0x983E5152
	.word 0xA831C66D
	.word 0xB00327C8
	.word 0xBF597FC7
	.word 0xC6E00BF3
	.word 0xD5A79147
	.word 0x06CA6351
	.word 0x14292967
	.word 0x27B70A85
	.word 0x2E1B2138
	.word 0x4D2C6DFC
	.word 0x53380D13
	.word 0x650A7354
	.word 0x766A0ABB
	.word 0x81C2C92E
	.word 0x92722C85
	.word 0xA2BFE8A1
	.word 0xA81A664B
	.word 0xC24B8B70
	.word 0xC76C51A3
	.word 0xD192E819
	.word 0xD6990624
	.word 0xF40E3585
	.word 0x106AA070
	.word 0x19A4C116
	.word 0x1E376C08
	.word 0x2748774C
	.word 0x34B0BCB5
	.word 0x391C0CB3
	.word 0x4ED8AA4A
	.word 0x5B9CCA4F
	.word 0x682E6FF3
	.word 0x748F82EE
	.word 0x78A5636F
	.word 0x84C87814
	.word 0x8CC70208
	.word 0x90BEFFFA
	.word 0xA4506CEB
	.word 0xBEF9A3F7
	.word 0xC67178F2
