	.text
	.file	"MicroC"
	.globl	main                    # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movl	$2, %edi
	movl	$14, %esi
	callq	gcd@PLT
	movl	%eax, %ecx
	leaq	.Lfmt(%rip), %rbx
	xorl	%eax, %eax
	movq	%rbx, %rdi
	movl	%ecx, %esi
	callq	printf@PLT
	movl	$3, %edi
	movl	$15, %esi
	callq	gcd@PLT
	movl	%eax, %ecx
	xorl	%eax, %eax
	movq	%rbx, %rdi
	movl	%ecx, %esi
	callq	printf@PLT
	movl	$99, %edi
	movl	$121, %esi
	callq	gcd@PLT
	movl	%eax, %ecx
	xorl	%eax, %eax
	movq	%rbx, %rdi
	movl	%ecx, %esi
	callq	printf@PLT
	xorl	%eax, %eax
	popq	%rbx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.globl	gcd                     # -- Begin function gcd
	.p2align	4, 0x90
	.type	gcd,@function
gcd:                                    # @gcd
	.cfi_startproc
# %bb.0:                                # %entry
	movl	%edi, -8(%rsp)
	movl	%esi, -4(%rsp)
	jmp	.LBB1_1
	.p2align	4, 0x90
.LBB1_4:                                # %else
                                        #   in Loop: Header=BB1_1 Depth=1
	movl	-8(%rsp), %eax
	subl	%eax, -4(%rsp)
.LBB1_1:                                # %while
                                        # =>This Inner Loop Header: Depth=1
	movl	-8(%rsp), %eax
	cmpl	-4(%rsp), %eax
	je	.LBB1_5
# %bb.2:                                # %while_body
                                        #   in Loop: Header=BB1_1 Depth=1
	movl	-8(%rsp), %eax
	cmpl	-4(%rsp), %eax
	jle	.LBB1_4
# %bb.3:                                # %then
                                        #   in Loop: Header=BB1_1 Depth=1
	movl	-4(%rsp), %eax
	subl	%eax, -8(%rsp)
	jmp	.LBB1_1
.LBB1_5:                                # %merge14
	movl	-8(%rsp), %eax
	retq
.Lfunc_end1:
	.size	gcd, .Lfunc_end1-gcd
	.cfi_endproc
                                        # -- End function
	.type	.Lfmt,@object           # @fmt
	.section	.rodata.str1.1,"aMS",@progbits,1
.Lfmt:
	.asciz	"%d\n"
	.size	.Lfmt, 4

	.type	.Lfmt.1,@object         # @fmt.1
.Lfmt.1:
	.asciz	"%g\n"
	.size	.Lfmt.1, 4

	.type	.Lfmt.2,@object         # @fmt.2
.Lfmt.2:
	.asciz	"%d\n"
	.size	.Lfmt.2, 4

	.type	.Lfmt.3,@object         # @fmt.3
.Lfmt.3:
	.asciz	"%g\n"
	.size	.Lfmt.3, 4


	.section	".note.GNU-stack","",@progbits
