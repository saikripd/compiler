.data
a:	.word
b:	.word
.text
li r1, 5
li r2, 2
add r3, r1, r2
goto lbl1
addi $sp, -1000
lbl1:	li r1, 11
li r1, 2
add r2, r4, r5
Move r4, r2
li $v0,1
move $a0,r4
syscall
