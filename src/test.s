.data
.text
j main
addi $sp, -1000
main:
li $t1, 1
li $t2, 0
Error. Variable not initialized before use.
move $t4, $t3
lbl2:
li $t2, 10
slt $t5, $t4, $t2
bne $t5, 1, lbl3
lbl4:
li $t2, 1
add $t5, $t1, $t2
move $t1, $t5
li $t2, 1
add $t5, $t4, $t2
move $t4, $t5
j lbl2
lbl3:
li $v0,1
move $a0,$t1
syscall
jr $ra
