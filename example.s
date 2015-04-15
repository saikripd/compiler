.data
msg:   .asciiz "Hello World"
	.extern foobar 4

        .text
        .globl main
main:   li $t0, 1       # syscall 4 (print_str)
        # la $a0, msg     # argument: string
        add
        syscall         # print the string
        lw $t1, foobar
        
        jr $ra          # retrun to caller