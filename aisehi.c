void generateMIPS()
{
	printf(".text\n");
	//parse through code list
	codeList *codeP = codeStart;
	int globals = 1;
	useRegs txregs;
	txregs.rDest = 0;
	txregs.rSrc2 = 0;
	txregs.rSrc1 = 0;
	// useRegs *pregs;
	int paramN = 0;
	int i;
	int labelN = 0;

	for(i=0;i<22;i++)
	{
		pRegList[i].free = 1;
		pRegList[i].flag = 0;
	}
	while(codeP != NULL)
	{
		//printf("%s type = %d global = %d\n", codeP->codeString, codeP->type, globals);
		useRegs *pregs;
		if(globals == 1)
		{
			//printf("global");
			char *str = codeP->codeString;
			//if goto, end globals
			if(codeP->type == 11)
			{
				//TODO: generate call:
				if(codeP->gotoAddress == NULL)
					printf("Fake goto statement\n");
				else if(strcmp(codeP->gotoAddress->label, "") == 0)
				{
					snprintf(codeP->gotoAddress->label, 20, "lbl%d", ++labelN);
					printf("j lbl%d\n", labelN);
				}
				else
				{
					printf("j %s\n", codeP->gotoAddress->label);
				}
				globals = 0;
			}
			else if(codeP->type == 2) //else only type 3, 2 allowed
			{
				//check for conversion
				//get regs
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = codeP->tx3;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				char words[10][50];
				convertToWords(codeP->codeString, words);
				switch(strlen(words[3]))
				{
					case 1:
					switch(words[3][0])
					{
						case '|':
						printf("or $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						printf("sw \n");
						break;

						case '&':   
						printf("and $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '^':   
						printf("xor $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

					}
					case 2: // oror, andand, neq, rshift
					switch(words[3][0])
					{
						case '!':
						if(words[3][1] == '=')
						{   
							printf("subu $%s, $%s, $%s\nxori $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
						}
						break;

						case '=':
						if(words[3][1] == '=')
						{   
							printf("subu $%s, $%s, $%s\nsubu $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
						}
						break;

						case '<':
						if(words[3][1] == '=')
						{
							printf("slt $%s, $%s, $%s\nsubu $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
							break;
						}
						else if(words[3][1] == '<')
						{
							printf("sllv $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
							break;
						}

						case '>':
						if(words[3][1] == '=')
						{
							printf("slt $%s, $%s, r%d\nsubu $%s, $%s, 1\n", arr[0], arr[2], arr[1], arr[0], arr[0]);
							break;
						}
						else if(words[3][1] == '>')
						{
							printf("sra $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
							break;
						}
						
					}
					case 3:
					switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' )
						{
							printf("srlv $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						}
						break;
							
					}
					case 4:   
					switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' && words[3][3] == '=' )
						{
							printf("srlv $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						}
						break;
							
					}
					case 8: // integer+-*/
					switch(words[3][7])
					{
						case '+':   
						printf("add $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '-':   
						printf("sub $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '*':   
						printf("mult $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;  

						case '/':   
						printf("div $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;
					}
					case 9: 
					switch(words[3][8])//unsigned +/-*
					{
						case '+':
						printf("addu $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '-':
						printf("subu $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '*':
						printf("multu $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;

						case '/':
						printf("divu $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;

					}
				}
			}
			else if(codeP->type == 3)
			{
				if(txList[codeP->tx1].floating)
				{
					;
				}
				else
				{
					//get regs
					txregs.rDest = codeP->tx1;
					txregs.rSrc1 = codeP->tx2;
					txregs.rSrc2 = 0;
					pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
					int value[3];
					value[0] = pregs->rDest;
					value[1] = pregs->rSrc1;
					value[2] = pregs->rSrc2;
					char arr[3][10];
					numToReg(arr, value);
					printf("move $%s, $%s\n", arr[0], arr[1]);
					//Manually store global vars to memory
				}
			}
//             else if(codeP->type == 4)
//             {
//                  txregs.rDest = codeP->tx1;
//                  char *label = txList[codeP->tx2].globalName;
//                  pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
//                 printf("la r%d, 
//             }
			else if(codeP->type == 12)
			{
				//printf("Debug: type 12 statement\n");
				//get regs
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = 0;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				char words[10][50];
				convertToWords(codeP->codeString, words);
				if(words[2][0] == '\"')
					;//string init
				else
				{
					if(txList[codeP->tx1].floating)
						;//float init
					else
					{
						printf("li $%s, %s\n", arr[0], words[2]);
					}    
				}
						;//integer or float init
			}
			else
			{
					printf("Error: Illegal statement of type %d in global space\n", codeP->type);
			}
		}
		else
		{
			if(codeP->functionEntry != NULL)
			{
				printf("addi $sp, -1000\n");
				globalOffset = 1000;
			}
			if(codeP->isBBLHead)
			{
				if(strcmp(codeP->label,"") == 0)
					snprintf(codeP->label, 20, "lbl%d", ++labelN);
			}
			if(codeP->functionEntry != NULL || codeP->isBBLHead)
				printf("%s:\t", codeP->label);
			switch(codeP->type)
			{
				case 1: 
				txregs.rDest = codeP->tx2;
				txregs.rSrc1 = codeP->tx1;
				txregs.rSrc2 = codeP->tx3;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				break;

				case 2:
				//check for conversion
				//get regs
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = codeP->tx3;
				// printf("%d %d %d\n", codeP->tx1,codeP->tx2,codeP->tx3);
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				char words[10][50];
				convertToWords(codeP->codeString, words);
				switch(strlen(words[3]))
				{
					case 1:
					switch(words[3][0])
					{
						case '|':   
						printf("or $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '&':   
						printf("and $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '^':   
						printf("xor $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

					}
					case 2: // oror, andand, neq, rshift
					switch(words[3][0])
					{
						case '!':
						if(words[3][1] == '=')
						{   
							printf("subu $%s, $%s, $%s\nxori $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
						}
						break;

						case '=':
						if(words[3][1] == '=')
						{   
							printf("subu $%s,$%s,$%s\nsubu $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
						}
						break;

						case '<':
						if(words[3][1] == '=')
						{
							printf("slt $%s, $%s, $%s\nsubu $%s, $%s, 1\n", arr[0], arr[1], arr[2], arr[0], arr[0]);
							break;
						}
						else if(words[3][1] == '<')
						{
							printf("sllv $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
							break;
						}

						case '>':
						if(words[3][1] == '=')
						{
							printf("slt $%s, $%s, $%s\nsubu $%s, $%s, 1\n", arr[0], arr[2], arr[1], arr[0], arr[0]);
							break;
						}
						else if(words[3][1] == '>')
						{
							printf("sra $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
							break;
						}

					}
					case 3:   switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' )
						{
								printf("srlv $%s,$%s,$%s\n", arr[0], arr[1], arr[2]);
						}
						break;

					}
					case 4:   switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' && words[3][3] == '=' )
						{
							printf("srlv $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						}
						break;

					}
					case 8: // integer+-*/
					switch(words[3][7])
					{
						case '+':   
						// printf("add se pehle dekho $%s, $%s, $%s\n", codeP->tx1, codeP->tx2, codeP->tx3);
						printf("add $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '-':   
						printf("sub $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '*':   
						printf("mult $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;

						case '/':   
						printf("div $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;
					}
					case 9: switch(words[3][8])//unsigned +/-*
					{
						case '+':
						printf("addu $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '-':
						printf("subu $%s, $%s, $%s\n", arr[0], arr[1], arr[2]);
						break;

						case '*':
						printf("multu $%s,$%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;

						case '/':
						printf("divu $%s, $%s\nmflo $%s\n", arr[1],arr[2], arr[0]);
						break;
					}
				}
				break;
				case 3:
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				if(txList[codeP->tx1].floating)
				{
					;
				}
				else
				{
					printf("move $%s, $%s\n", arr[0], arr[1]);
					//Manually store global vars to memory
				}
				break;

				case 4:
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				printf("la $%s, %d\n", arr[0], arr[1]);
				break;

				case 5:
				txregs.rDest = 0;
				txregs.rSrc1 = codeP->tx1;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				if(codeP->codeString[3]== '!')
					printf("bneq $%s,1,%s\n",arr[1],codeP->gotoAddress->label );
				else
					printf("beq $%s,1,%s \n",arr[1],codeP->gotoAddress->label);
				break;

				case 6:
				//return this variable
				txregs.rDest = 0;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = codeP->tx1;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				printf("move $v0, $%s\naddu $sp, 1000\nj $ra\n", arr[1]);
				break;

				case 7: //Param statement, move data into $ax
				txregs.rDest = 0;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = codeP->tx1;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				//
				printf("move $a%d, $%s\n", paramN++, arr[1]);
				break;

				case 8:			// Sai: Error in here rSrc1 is 0
				txregs.rDest = codeP->tx1;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				
				printf("move $%s, $v0\n", arr[0]);
				break;
				case 9:
				printf("addu $sp, 1000\n j $ra\n");
				break;

				case 10:    
				printf("jal %s\n", codeP->gotoAddress->label);
				break;

				case 11:    
				printf("j %s\n", codeP->gotoAddress->label);
				break;

				case 12: 			// Sai: Error in here rSrc1 is 0
				txregs.rSrc2 = 0;
				txregs.rSrc1 = 0;
				txregs.rDest = codeP->tx1;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == STRING_LIT)
				{   
					int len = strlen(txList[codeP->tx1].symbolEntry->name);
					int i;
					printf("addi $sp, $sp, %d\n",-1*len);
					printf("lw $t0, -4($sp)\n");
					for(i = 0; i< 50;i++)
					{
						printf("li $t0, %d\n",txList[codeP->tx1].symbolEntry->name[i]); 
						printf("sw $t0, %d($sp)\n",i);
						if(txList[codeP->tx1].symbolEntry->name[i] == '\0')
							break;
					}
					printf("sw $t0, -4($sp)\n");
					printf("li $%s, 0($sp)\n",arr[0]);

				}
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == INT_LIT)
				{
					printf("li $%s, %d\n", arr[0],atoi(txList[codeP->tx1].symbolEntry->name));
				}
				else
				{
					char words[10][50];
					convertToWords(codeP->codeString, words);
					printf("li $%s, %s\n", arr[0], words[2]);
				}
//                         if(txList[codeP->tx1]->symbolEntry->basetype == FLOAT_LIT)
//                         {
//                           printf("move $f12,r%d\n",pregs.rSrc1);
//                         }
				break;

				case 13:
				if(!strcmp(codeP->codeString, "t%d++\n"))
				{
					txregs.rSrc1 = 0;
					txregs.rSrc2 = 0;
					txregs.rDest = codeP->tx1;
					pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
					int value[3];
					value[0] = pregs->rDest;
					value[1] = pregs->rSrc1;
					value[2] = pregs->rSrc2;
					char arr[3][10];
					numToReg(arr, value);
					printf("addi $%s, $%s, 1\n", arr[0], arr[0]);
					break;
				}
				else if(!strcmp(codeP->codeString, "t%d--\n"))
				{
					txregs.rSrc1 = 0;
					txregs.rSrc2 = 0;
					txregs.rDest = codeP->tx1;
					pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
					int value[3];
					value[0] = pregs->rDest;
					value[1] = pregs->rSrc1;
					value[2] = pregs->rSrc2;
					char arr[3][10];
					numToReg(arr, value);
					printf("addi $%s, $%s, -1\n", arr[0], arr[0]);
					break;
				}

				case 14:// prateek : working
				txregs.rSrc1 = codeP->tx1;
				txregs.rSrc2 = 0;
				txregs.rDest = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == STRING_LIT)
				{   
					printf("li $v0,4\n");
					printf("la $a0,$%s\n",arr[1]);
				}
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == INT_LIT)
				{
					printf("li $v0,1\n");
					printf("move $a0,$%s\n",arr[1]);
				}
				else
				{
					printf("li $v0,1\n");
					printf("move $a0,$%s\n",arr[1]);
				}
//                         if(txList[codeP->tx1]->symbolEntry->basetype == FLOAT_LIT)
//                         {
//                           printf("li $v0,2\n");
//                           printf("move $f12,r%d\n",pregs.rSrc1);
//                         }
//                           if(txList[codeP->tx1]->symbolEntry->basetype == STRING_LIT);
//                              printf("li $v0,4);
				printf("syscall\n");
				break;

				case 15:
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = codeP->tx3;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				int value[3];
				value[0] = pregs->rDest;
				value[1] = pregs->rSrc1;
				value[2] = pregs->rSrc2;
				char arr[3][10];
				numToReg(arr, value);
				break;
			}
			// pregs->
			//if function start, do stuff

			//if type 6 or type 

		}

		codeP = codeP->next;        
	}
}
