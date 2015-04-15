#include "definition.h"
#include "stdlib.h"
#include "string.h"
#include "../bin/y.tab.h"

symbolTable * createTable( symbolTableEntry *parent)
{
	symbolTable *newTable = (symbolTable *)malloc(sizeof(symbolTable));
	newTable->entries = (symbolTableEntry *)malloc(100*sizeof(symbolTableEntry));
	newTable->numberEntries = 0;
	newTable->parent = parent;
	if(parent != NULL)
		parent->child = newTable;
	return newTable;
}

ASTnode * createNode(int n)
{
	ASTnode *newNode;
	newNode = (ASTnode *)malloc(sizeof(ASTnode));
	newNode->children = (ASTnode **) malloc(n*sizeof(ASTnode *));
		newNode->noChildren=n;
		newNode->pointer = 0;
		newNode->basetype = -1;
		newNode->arraydimension = 0;
		newNode->function = 0;
		newNode->structure = 0;
		newNode->address = 0;
		newNode->tx = -1;
		int i;
		for(i = 0; i<10; i++){
			newNode->dim[i] = 0;
		}

	return newNode;
}

symbolTableEntry *findSymbol(char *id, int n, int ownScope)
{
	symbolTable *currentSymbolTable = top(n);
	int number = currentSymbolTable->numberEntries;
		int i;
		for(i = number; i > 0; i--)
		{
				if(!strcmp(id, currentSymbolTable->entries[i-1].name))
				{
						return &(currentSymbolTable->entries[i-1]);
				}
		}
		if(!ownScope){
			if(top(n+1) != NULL){
				return findSymbol( id, n+1, ownScope);
			}
		}
		return NULL;
} 

symbolTableEntry * addSymbol(ASTnode *symbol, char *id, symbolTable *currentSymTable)
{
	currentSymTable->numberEntries++;
		symbolTableEntry *tableEntry = &(currentSymTable->entries[currentSymTable->numberEntries-1]);
		tableEntry->current = currentSymTable;
	strcpy( tableEntry->name, id);
		tableEntry->basetype = symbol->basetype;
	tableEntry->pointer = symbol->pointer;
	tableEntry->arraydimension = symbol->arraydimension;
	tableEntry->function = symbol->function;
	tableEntry->tx = symbol->tx;
		int i;
		for(i = 0 ; i <10 ; i++)
		{
			tableEntry->dim[i] = symbol->dim[i];
		}
	return tableEntry;
}

codeList * setType(ASTnode *node, int type) //return list of typecast instructions necessary
{
	codeList *newCode = NULL;
	if(node->symbolEntry != NULL)
	{
		if(node->symbolEntry->basetype != type )
		{
			if(node->symbolEntry->pointer == 0 && node->symbolEntry->arraydimension == 0 && node->symbolEntry->function == 0 && node->symbolEntry->basetype !=-1)
			{
				if(type == DOUBLE && (node->symbolEntry->basetype == FLOAT ||node->symbolEntry->basetype == CHAR || node->symbolEntry->basetype == BYTE ||
											node->symbolEntry->basetype == SHORT ||node->symbolEntry->basetype == INT || node->symbolEntry->basetype == LONG|| node->symbolEntry->basetype == UBYTE ||
											node->symbolEntry->basetype == USHORT ||node->symbolEntry->basetype == UINT || node->symbolEntry->basetype == ULONG))
				{
					node->symbolEntry->basetype = type;
					newCode = (codeList *)malloc(sizeof(codeList));
					newCode->tx1 = ++globaltx;
					newCode->tx2 = node->symbolEntry->tx;
					strcpy(newCode->codeString, "t%d = converttodouble(t%d)");
					newCode->numAddresses=2;
					node->symbolEntry->tx = globaltx;
					
				}
				else if(type == FLOAT && (node->symbolEntry->basetype == CHAR || node->symbolEntry->basetype == BYTE || node->symbolEntry->basetype == UBYTE ||
															node->symbolEntry->basetype == SHORT ||node->symbolEntry->basetype == INT || node->symbolEntry->basetype == LONG ||
															node->symbolEntry->basetype == USHORT ||node->symbolEntry->basetype == UINT || node->symbolEntry->basetype == ULONG))
				{

					node->symbolEntry->basetype = type;
					newCode = (codeList *)malloc(sizeof(codeList));
					newCode->tx1 = ++globaltx;
					newCode->tx2 = node->symbolEntry->tx;
					strcpy(newCode->codeString, "t%d = converttofloat(t%d)");
					newCode->numAddresses=2;
					node->symbolEntry->tx = globaltx;
				}
				else if((type == CHAR || type == BYTE || type == USHORT || type == UINT || type == ULONG ||
									type == SHORT ||type == INT || type == LONG || type == UBYTE) &&
								(node->symbolEntry->basetype == CHAR || node->symbolEntry->basetype == BYTE || node->symbolEntry->basetype == USHORT || 
								 node->symbolEntry->basetype == UINT || node->symbolEntry->basetype == ULONG || node->symbolEntry->basetype == SHORT ||
								 node->symbolEntry->basetype == INT || node->symbolEntry->basetype == LONG || node->symbolEntry->basetype == UBYTE))
					node->symbolEntry->basetype = type;
				else
				{
					printf("Error. Cannot convert from %d to %d\n", node->symbolEntry->basetype, type);
					return ((codeList *)-1);
				}
			}
			else
			{ node->symbolEntry->basetype = type; }
						
		}

		int i;
		for(i =0; i < node->noChildren; i++)
		{
			codeList *others = setType(node->children[i], type);
			if(others != NULL)
			{
				if(newCode == NULL)
					newCode = others;
				else
					newCode->next = others;
			}
		}      
	}
	return newCode;
}

void assignLineNumber(codeList *start)
{
		int i=0;
		while(start != NULL)
		{
				start->lineno = ++i;
				start = start->next;
		}   
}
void printCode(codeList * start)
{
		while(start != NULL)
		{
				printf("%d:\t", start->lineno);
				if(start->gotoStatement != 1)
				{
						if(start->numAddresses == 0)
								printf(start->codeString);
						if(start->numAddresses == 1)
								printf(start->codeString, start->tx1);
						if(start->numAddresses == 2)
								printf(start->codeString, start->tx1, start->tx2);
						if(start->numAddresses == 3)
								printf(start->codeString, start->tx1, start->tx2, start->tx3);
				}
				else
				{
						if(start->numAddresses == 0)
								printf(start->codeString, start->gotoAddress->lineno);
						if(start->numAddresses == 1)
								printf(start->codeString, start->tx1, start->gotoAddress->lineno);
						if(start->numAddresses == 2)
								printf(start->codeString, start->tx1, start->tx2, start->gotoAddress->lineno);
						if(start->numAddresses == 3)
								printf(start->codeString, start->tx1, start->tx2, start->tx3, start->gotoAddress->lineno);
				}
				printf("\n");
				start = start->next;
		}
}
				
void push(symbolTable *newSymbolTable)
{
		stack[++stack_head]=newSymbolTable;
}
symbolTable *pop()
{
		return stack[stack_head--];
}
symbolTable * top(int n)
{
	if(n<0)
			return NULL;
	else if(n > stack_head)
		return NULL;
	else
		return stack[stack_head-n];
}

void pushLoopEnd(codeList *loopEnd)
{
		loopEndStack[++loopEndStackHead]=loopEnd;
}
void popLoopEnd()
{
		loopEndStackHead--;
}
codeList *topLoopEnd()
{
		return loopEndStack[loopEndStackHead];
}

int resulttype(int type1, int type2, int operator)
{
	int sign = -1;
	if(operator == '+' || operator == '-' || operator == '*' || operator == '/' || operator == PLUS_EQ || operator == MIN_EQ || operator == MULT_EQ || operator == DIV_EQ)
	{
		if(type1 == STRING_LIT || type1 == VOID || type2 == STRING_LIT || type2 == VOID)
			return -1;
		else if(type1 == DOUBLE || type2 == DOUBLE) 
			return DOUBLE;
		else if(type1 == FLOAT || type2 == FLOAT)
			return FLOAT;
			
		if((type1 == LONG || type1 == INT || type1 == BYTE || type1 == SHORT) || (type2 == LONG || type2 == INT || type2 == BYTE || type2 == SHORT))
			sign = 1;
		else
			sign = 0;
		if(type1 == LONG || type2 == LONG || type1 == ULONG || type2 == ULONG)
		{
			if(sign)
				return LONG;
			else
				return ULONG;
		}
		if(type1 == INT || type2 == INT || type1 == UINT || type2 == UINT)
		{
			if(sign)
				return INT;
			else
				return UINT;
		}
		if(type1 == SHORT || type2 == SHORT || type1 == USHORT || type2 == USHORT)
		{
			if(sign)
				return SHORT;
			else
				return USHORT;
		}
		if(type1 == BYTE || type2 == BYTE || type1 == UBYTE || type2 == UBYTE)
		{
			if(sign)
				return BYTE;
			else
				return UBYTE;
		}
		else
			return CHAR;
	}
	else if(operator == '%' || operator == MOD_EQ)
	{
		if(type1 == STRING_LIT || type1 == VOID || type2 == CHAR || type2 == CHAR || type2 == STRING_LIT || type2 == VOID || type1 == DOUBLE || type2 == DOUBLE || type1 == FLOAT || type2 == FLOAT)
			return -1;
			
		if((type1 == LONG || type1 == INT || type1 == BYTE || type1 == SHORT) || (type2 == LONG || type2 == INT || type2 == BYTE || type2 == SHORT))
			sign = 1;
		else
			sign = 0;
		if(type1 == LONG || type2 == LONG || type1 == ULONG || type2 == ULONG)
		{
			if(sign)
				return LONG;
			else
				return ULONG;
		}
		if(type1 == INT || type2 == INT || type1 == UINT || type2 == UINT)
		{
			if(sign)
				return INT;
			else
				return UINT;
		}
		if(type1 == SHORT || type2 == SHORT || type1 == USHORT || type2 == USHORT)
		{
			if(sign)
				return SHORT;
			else
				return USHORT;
		}
		if(type1 == BYTE || type2 == BYTE || type1 == UBYTE || type2 == UBYTE)
		{
			if(sign)
				return BYTE;
			else
				return UBYTE;
		}
	}
	else if(operator == '=')
	{
		if(type1 == type2 || implicitCompatible(type1, type2))
					return type1;
	}
	else if(operator == '|' || operator == '&' || operator == '^' || operator == OR_EQ || operator == AND_EQ || operator == XOR_EQ)
	{
		if(type1 == BOOL && type2 == BOOL)
			return BOOL;
		else if( type1 == BOOL && implicitCompatible(INT, type2))
			return type1;
		else if(implicitCompatible(INT, type1) && type2 == BOOL)
			return type2;
		else if(implicitCompatible(INT, type1) && implicitCompatible(INT, type2))
			return resulttype(type1, type2, '+');
	}
	// else if(operator == OR_OR || operator == AND_AND)
	// {
	//   if((type1 == BOOL || implicitCompatible(INT, type1)) && (type2 == BOOL || implicitCompatible(INT, type2)))
	//     return BOOL;
	// }
	else if(operator == LSHIFT || operator == LSHIFT_EQ || operator == RSHIFT || operator == RSHIFT_EQ || operator == LOG_RSHIFT || operator == LOG_RSHIFT_EQ)
	{
		if((type1 == INT || type1 == UINT) && (type2 == INT || type2 == BYTE || type2 == SHORT || 
																		 type2 == UINT || type2 == UBYTE || type2 == USHORT || type2 == CHAR))
			return type1;
		else if((type1 == SHORT || type1 == USHORT) && (type2 == BYTE || type2 == SHORT || 
																	 type2 == UBYTE || type2 == USHORT || type2 == CHAR))
			return type1;
		else if((type1 == BYTE || type1 == UBYTE) && (type2 == BYTE ||  
																	 type2 == UBYTE || type2 == CHAR))
			return type1;
		else if(type1 == CHAR && type2 == CHAR)
			return type1;
	}
	else if(operator == POW || operator == POW_EQ)
	{
		if(implicitCompatible(DOUBLE, type1) && implicitCompatible(INT, type2))
			return type1;
	}
	else if(operator == EQ_EQ || operator == NEQ)
	{
				if(type1 == type2)
					return type1;
				else if(implicitCompatible(type1, type2))
					return type1;
				else if(implicitCompatible(type2, type1))
					 return type2;
								
	}
	else if(operator == ':')
	{
			if(type1 == type2)
					return type1;
			else if(implicitCompatible(type1, type2))
					return type1;
				else if(implicitCompatible(type2, type1))
					 return type2;
	}
	//If nothing
	return -1;
}

int comparisontype(int type1, int type2, int operator)
{
	int sign = -1;
	if(operator == '<' || operator == '>' || operator == '*' || operator == LEQ || operator == GEQ || operator == EQ_EQ || operator == NEQ )
	{
		if(type1 == STRING_LIT || type1 == VOID || type2 == STRING_LIT || type2 == VOID)
			return -1;
		else if(type1 == DOUBLE || type2 == DOUBLE) 
			return DOUBLE;
		else if(type1 == FLOAT || type2 == FLOAT)
			return FLOAT;
			
		if((type1 == LONG || type1 == INT || type1 == BYTE || type1 == SHORT) || (type2 == LONG || type2 == INT || type2 == BYTE || type2 == SHORT))
			sign = 1;
		else
			sign = 0;
		if(type1 == LONG || type2 == LONG || type1 == ULONG || type2 == ULONG)
		{
			if(sign)
				return LONG;
			else
				return ULONG;
		}
		if(type1 == INT || type2 == INT || type1 == UINT || type2 == UINT)
		{
			if(sign)
				return INT;
			else
				return UINT;
		}
		if(type1 == SHORT || type2 == SHORT || type1 == USHORT || type2 == USHORT)
		{
			if(sign)
				return SHORT;
			else
				return USHORT;
		}
		if(type1 == BYTE || type2 == BYTE || type1 == UBYTE || type2 == UBYTE)
		{
			if(sign)
				return BYTE;
			else
				return UBYTE;
		}
		else
			return CHAR;
	}
	//If nothing
	return -1;
}

int shifttype(int type1, int type2, int operator)
{
	int sign = -1;

	if(operator == LSHIFT || operator == LSHIFT_EQ || operator == RSHIFT || operator == RSHIFT_EQ || operator == LOG_RSHIFT || operator == LOG_RSHIFT_EQ)
	{
		if((type1 == INT || type1 == UINT) && (type2 == INT || type2 == BYTE || type2 == SHORT || 
																		 type2 == UINT || type2 == UBYTE || type2 == USHORT || type2 == CHAR))
			return type1;
		else if((type1 == SHORT || type1 == USHORT) && (type2 == BYTE || type2 == SHORT || 
																	 type2 == UBYTE || type2 == USHORT || type2 == CHAR))
			return type1;
		else if((type1 == BYTE || type1 == UBYTE) && (type2 == BYTE ||  
																	 type2 == UBYTE || type2 == CHAR))
			return type1;
		else if(type1 == CHAR && type2 == CHAR)
			return type1;
	}
	//If nothing
	return -1;
}

int implicitCompatible(int typeDestination, int typeSource)
{
		if(typeDestination == DOUBLE && (typeSource == DOUBLE || typeSource == FLOAT || typeSource == LONG || typeSource == INT || typeSource == BYTE || typeSource == SHORT || 
																	 typeSource == ULONG || typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == CHAR))
			return 1;
	else if (typeDestination == FLOAT && (typeSource == FLOAT || typeSource == LONG || typeSource == INT || typeSource == BYTE || typeSource == SHORT || 
																	 typeSource == ULONG || typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == CHAR))
			return 1;
	else if((typeDestination == LONG || typeDestination == ULONG) && (typeSource == LONG || typeSource == INT || typeSource == BYTE || typeSource == SHORT || 
																		 typeSource == ULONG || typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == CHAR))
			return 1; 
		else if((typeDestination == INT || typeDestination == UINT) && (typeSource == INT || typeSource == BYTE || typeSource == SHORT || 
																		 typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == CHAR))
			return 1;
		else if((typeDestination == SHORT || typeDestination == USHORT) && (typeSource == BYTE || typeSource == SHORT || 
																	 typeSource == UBYTE || typeSource == USHORT || typeSource == CHAR))
			return 1;
	else if((typeDestination == BYTE || typeDestination == UBYTE) && (typeSource == BYTE ||  
																	 typeSource == UBYTE || typeSource == CHAR))
			return 1;
		else if(typeDestination == CHAR && typeSource == CHAR)
			return 1;
		else
			return 0;
}

char *conversionFunction(int typeDestination, int typeSource)
{
	char *function = (char *)malloc(50*sizeof(char));
	int compatible = implicitCompatible(typeDestination, typeSource);
	if(compatible)
	{
		if(((typeSource == INT || typeSource == UINT) && (typeDestination == INT || typeDestination == UINT)) || 
			 ((typeSource == LONG || typeSource == ULONG) && (typeDestination == LONG || typeDestination == ULONG)) ||
			 ((typeSource == SHORT || typeSource == USHORT) && (typeDestination == SHORT || typeDestination == USHORT)) ||
			 ((typeSource == BYTE || typeSource == UBYTE) && (typeDestination == BYTE || typeDestination == UBYTE)))
		{
			strcpy(function, "t%d");
		}
		else
		{
			switch(typeSource)
			{
					case DOUBLE :   strcpy(function, "doubleto");
									break;
					case FLOAT :  strcpy(function, "floatto");
									break;
					case LONG :   strcpy(function, "intto");
									break;
					case INT :    strcpy(function, "intto");
									break;
					case SHORT :  strcpy(function, "intto");
									break;
					case BYTE :   strcpy(function, "intto");
									break;
					case CHAR :   strcpy(function, "intto");
									break;
					case ULONG :  strcpy(function, "intto");
									break;
					case UINT :   strcpy(function, "intto");
									break;
					case USHORT :   strcpy(function, "intto");
									break;
					case UBYTE :  strcpy(function, "intto");
									break;
			}
			switch(typeDestination)
			{
					case DOUBLE : strcat(function, "double(t%d)");
													break;
					case FLOAT :  strcat(function, "float(t%d)");
													break;
					case LONG :   strcat(function, "int(t%d)");
													break;
					case INT :  strcat(function, "int(t%d)");
													break;
					case SHORT :  strcat(function, "int(t%d)");
													break;
					case BYTE :   strcat(function, "int(t%d)");
													break;
					case CHAR :   strcat(function, "int(t%d)");
													break;
					case ULONG :  strcat(function, "int(t%d)");
													break;
					case UINT :   strcat(function, "int(t%d)");
													break;
					case USHORT :   strcat(function, "int(t%d)");
													break;
					case UBYTE :  strcat(function, "int(t%d)");
													break;
			}
		} 
		// if((typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == ULONG) && (typeDestination == INT || typeDestination == BYTE || typeDestination == SHORT || typeDestination == LONG || typeDestination == FLOAT || typeDestination == DOUBLE))  
		// {
		//   char *temp = (char *)malloc(50*sizeof(char));
		//   snprintf(temp, 50, function, "tosigned(t%d)");
		//   function = temp;
		// }
		// else if((typeSource == INT || typeSource == BYTE || typeSource == SHORT || typeSource == LONG || typeSource == FLOAT || typeSource == DOUBLE) && (typeDestination == UINT || typeDestination == UBYTE || typeDestination == USHORT || typeDestination == ULONG))  
		// {
		//   //char *temp = (char *)malloc(50*sizeof(char));
		//     snprintf(function, 50, "tounsigned(%s)", function);
		// }
		// int length = strlen(function);
		// if(length >= 4 && function[length-4] == '%')
		//   function[length-3]='d';
		// else if(length >= 3 && function[length-3] == '%')
		//   function[length-2]='d';
		// else if(length >= 2 && function[length-3] == '%')
		//   function[length-1]='d';

	}
	return function;
}

char *typeOperator(int type, int operator)
{
	char *op = (char *)malloc(16*sizeof(char));
	if(operator == '+' || operator == PLUS_EQ)
	{
		if(type == DOUBLE)
			strcpy(op, " double+ ");
		else if(type == FLOAT)
			strcpy(op, " float+ ");
		else if(type == LONG || type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " integer+ ");
		else
			op = NULL;
	}
	else if(operator == '-' || operator == MIN_EQ)
	{
		if(type == DOUBLE)
			strcpy(op, " double- ");
		else if(type == FLOAT)
			strcpy(op, " float- ");
		else if(type == LONG || type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " integer- ");
		else
			op = NULL;
	}
	else if(operator == '*' || operator == MULT_EQ)
	{
		if(type == DOUBLE)
			strcpy(op, " double* ");
		else if(type == FLOAT)
			strcpy(op, " float* ");
		else if(type == LONG || type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " integer* ");
		else
			op = NULL;
	}
	else if(operator == '/' || operator == DIV_EQ)
	{
		if(type == DOUBLE)
			strcpy(op, " double/ ");
		else if(type == FLOAT)
			strcpy(op, " float/ ");
		else if(type == LONG || type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " integer/ ");
		else
			op = NULL;
	}
	else if(operator == '%' || operator == MOD_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " %% ");
		else
			op = NULL;
	}
	else if(operator == '&' || operator == AND_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " & ");
		else
			op = NULL;
	}
	else if(operator == '|' || operator == OR_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " | ");
		else
			op = NULL;
	}
	else if(operator == '^' || operator == XOR_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " ^ ");
		else
			op = NULL;
	}
	else if(operator == LSHIFT || operator == LSHIFT_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " << ");
		else
			op = NULL;
	}
	else if(operator == RSHIFT || operator == RSHIFT_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " >> ");
		else
			op = NULL;
	}
	else if(operator == LOG_RSHIFT || operator == LOG_RSHIFT_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " >>> ");
		else
			op = NULL;
	}
	else if(operator == POW || operator == POW_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " ^^ ");
		else
			op = NULL;
	}
	else if(operator == EQ_EQ)
	{
		if(type == INT || type == BYTE || type == SHORT ||type == ULONG || type == UINT || type == UBYTE || type == USHORT || type == CHAR)
			strcpy(op, " == ");
		else
			op = NULL;
	}
	return op;
}

 void createEntries(ASTnode *n){
	fields *entryPoint = globalStructs[struct_head];
	fieldEntry *temp = entryPoint->node;
	if(temp == NULL)
	{
		fieldEntry *newnode = (fieldEntry *)malloc(sizeof(fieldEntry));
		newnode->type = n->basetype;
		newnode->pointer = n->pointer;
		newnode->id = n->lexeme;
//     printf("Adding %s\n", n->lexeme);
		newnode->arraydimension = n->arraydimension;
		newnode->next = NULL;
		int i;
		for(i = 0; i< 10; i++) 
		{ 
			newnode->dim[i] = n->dim[i];
		}
		entryPoint->node = newnode;
		return;
	}
	else 
	{
		while(temp->next != NULL)
		{
			temp = temp->next;
		}
		fieldEntry *newnode = (fieldEntry *)malloc(sizeof(fieldEntry));
		newnode->type = n->basetype;
		newnode->pointer = n->pointer;
		newnode->id = n->lexeme;
//     printf("Adding %s\n", n->lexeme);
		newnode->arraydimension = n->arraydimension;
		newnode->next = NULL;
		int i;
		for(i = 0; i< 10; i++) { 
				newnode->dim[i] = n->dim[i];
		}
		temp->next = newnode;
		return;
	}
 }
 
 void createStructEntry()
 {
	globalStructs[++struct_head] = (fields *)malloc(sizeof(fields));
	globalStructs[struct_head]->node = NULL;    
 }
 
 int checkFuncList(char *id, ASTnode *node)
 {
	int i;
	ASTnode *n = node;
	for(i =0; i<100; i++)
	{
		if(!strcmp(globalStructs[i]->id,id))
		{
//          printf("%s\n", id);
			break;
		}
	}
	if(globalStructs[i]->node == NULL && n == NULL)
	{
//       printf("no var passed!\n");
		return 1;
	}
	if(globalStructs[i]->node == NULL)
	{
		printf("No arguments expected!\n");
		return 0;
	}
	fieldEntry *var = globalStructs[i]->node;
//     while(var != NULL){
//       // printf("%s\n", var->id);
//       var = var->next;
//     }
//     var = globalStructs[i]->node;
	while(var->next != NULL)
	{
//       printf("> 1 var passed\n");

		if(strcmp(n->lexeme,","))
		{
			printf("Error. More arguments expected!\n");
			return 0;
		}
//       printf("%d %d\n", var->type , n->children[1]->basetype);
		if((var->type == n->children[1]->basetype) || implicitCompatible(var->type, n->children[1]->basetype)){
//         printf("%d %d %d %d \n",var->pointer,n->children[1]->pointer,var->arraydimension,n->children[1]->arraydimension );
				if((var->pointer == n->children[1]->pointer) && (var->arraydimension == n->children[1]->arraydimension))
				{
					int i;
					if(var->arraydimension)
					{
						for(i =0; i< 10; i++)
						{
							if(var->dim[i] != n->children[1]->dim[i])
							{
								printf("Error. Array Dimention check failed!\n");
								return 0;
							}
						}
					}
//                 printf("Pointer n dimension match!\n");
						//return 1;
				}
				else if((n->children[1]->pointer == 0) && (var->pointer == 1) && (var->arraydimension == n->children[1]->arraydimension - 1)){
					int i;
					for(i =1; i< 10; i++)
					{
						if(var->dim[i-1] != n->children[1]->dim[i])
						{
							printf("Error. Array Dimention check failed!\n");
							return 0;
						}
					}
//                 printf("Array -1 to pointer match!\n");
						//return 1;
				}
				else 
				{
					printf("Array n pointer mismatch!\n");
					return 0;
				}
			}
			else 
			{
				printf("definition mismatch!\n"); 
				return 0;
			}
			var = var->next;
			n = n->children[0];
	}
	if(var->next == NULL)
	{
//       printf("1 var passed\n");
		if(!strcmp(n->lexeme,","))
		{
			printf("Error. Less arguments expected!\n");
			return 0;
		}
//         printf("%d %d\n", var->type , n->basetype);
		if((var->type == n->basetype) || implicitCompatible(var->type, n->basetype))
		{
//           printf("%d %d %d %d \n",var->pointer,n->pointer,var->arraydimension,n->arraydimension );
			if((var->pointer == n->pointer) && (var->arraydimension == n->arraydimension))
			{
//             printf("checking arr dims\n");
				int i;
				if(var->arraydimension)
				{
					for(i =0; i< 10; i++)
					{
//                     printf("%d %d\n",var->dim[i] , n->dim[i] );
						if(var->dim[i] != n->dim[i])
						{
							printf("Error. Array Dimention check failed!\n");
							return 0;
						}
					}
				}
				return 1;
			}
			else if((n->pointer == 0) && (var->pointer == 1) && (var->arraydimension == (n->arraydimension - 1)))
			{
				int i;
				for(i =1; i< 10; i++)
				{
//                      printf("%d %d\n",var->dim[i-1] , n->dim[i] );
					if(var->dim[i-1] != n->dim[i])
					{
						printf("Error. Array Dimention check failed!\n");
						return 0;
					}
				}
				return 1;
			}
			else 
			{
				printf("Array n pointer mismatch!\n");
				return 0;
			}
		}
		else 
		{
			printf("definition mismatch!\n"); 
			return 0;
		}
	}
 }
 

evalExp evaluate(ASTnode *node)
{
	evalExp temp, temp1, temp2;
	temp.val = 0;
	temp.err = 0;
	temp1.val = 0;
	temp1.err = 0;
	temp2.val = 0;
	temp2.err = 0;

	if(node->noChildren == 0)
	{
		temp.val = atoi(node->lexeme);
		if(temp.val == 0)
			temp.err = 1;
		return temp;
	}
	if(strcmp(node->lexeme, "+") == 0)
	{
		temp1 = evaluate(node->children[0]);
		temp2 = evaluate(node->children[1]);
		temp.val = temp1.val + temp2.val;
		temp.err = temp1.err | temp2.err;
	}
	else if (strcmp(node->lexeme, "-") == 0)
	{
		temp1 = evaluate(node->children[0]);
		temp2 = evaluate(node->children[1]);
		temp.val = temp1.val - temp2.val;
		temp.err = temp1.err | temp2.err;
	}
	else if (strcmp(node->lexeme, "*") == 0)
	{
		temp1 = evaluate(node->children[0]);
		temp2 = evaluate(node->children[1]);
		temp.val = temp1.val * temp2.val;
		temp.err = temp1.err | temp2.err;
	}
	else
		temp.err = 1;
	return temp;
}

ASTCaseNode * createCaseNode(int n)
{
	ASTCaseNode *temp = (ASTCaseNode *)malloc(sizeof(ASTCaseNode));
	temp->statementsASTnode = createNode(n);
	temp->hasDefault = 0;
	temp->thisCase = (caseList *)malloc(sizeof(caseList));
	temp->thisCase->starting = NULL;
	temp->thisCase->codeStart = NULL;
	temp->thisCase->next =NULL;
	return temp;
}

void fixDanglingGoto(codeList * start)
{
	while(start != NULL)
	{
		if(start->gotoStatement == 1 && start->gotoAddress == NULL)
			start->gotoAddress = start->next;
		start = start->next;
	}
}

void createStructEntries(ASTnode *n1,ASTnode *n2)
{
	fields *entryPoint = globalStructs[struct_head];
	fieldEntry *temp = entryPoint->node;
	// ASTnode *childrenEntries = n->children[2];
	if(temp == NULL)
	{
		fieldEntry *newnode = (fieldEntry *)malloc(sizeof(fieldEntry));
		newnode->type = n2->basetype;
		newnode->pointer = n1->pointer;
		newnode->id = n1->lexeme;
		//     printf("Adding %s\n", n->lexeme);
		newnode->arraydimension = n1->arraydimension;
		newnode->next = NULL;
		int i;
		for(i = 0; i< 10; i++) 
		{ 
			newnode->dim[i] = n1->dim[i];
		}
		entryPoint->node = newnode;
		return;
	}
	else 
	{
		while(temp->next != NULL)
		{
			temp = temp->next;
		}
		fieldEntry *newnode = (fieldEntry *)malloc(sizeof(fieldEntry));
		newnode->type = n2->basetype;
		newnode->pointer = n1->pointer;
		newnode->id = n1->lexeme;
		//     printf("Adding %s\n", n->lexeme);
		newnode->arraydimension = n1->arraydimension;
		newnode->next = NULL;
		int i;
		for(i = 0; i< 10; i++) 
		{ 
			newnode->dim[i] = n1->dim[i];
		}
		temp->next = newnode;
		return;
	}
}

fields *searchStruct(char *id)
{
	int i;
	for(i =0; i<100; i++)
	{
		if(!strcmp(globalStructs[i]->id,id))
		{
//           printf("%s\n", id);
			break;
		}
	}
	if(i == 100)
	{
		printf("Struct %s not found.\n",id );
		return NULL;
	}
	if(globalStructs[i]->type == STRUCT)
	{
		return globalStructs[i];
	}
	else
	{
		printf("%s is not of Struct type\n",id );
		return NULL;
	}
}

useRegs *phyRegister(useRegs *regID, codeData ins) {
	int i;
//   bool destFlag,src1Flag,src2Flag; 
//   for(i = 0; i< 100; i++){

	// If registers are already allocated setting the flag
	if(txList[regID->rDest].reg != 0 && regID->rDest != 0)
	{
		regID->rDest = txList[regID->rDest].reg;
		pRegList[regID->rDest].flag = 1;
	}
	if(txList[regID->rSrc1].reg != 0 && regID->rSrc1 != 0)
	{
		regID->rSrc1 = txList[regID->rSrc1].reg;
		pRegList[regID->rSrc1].flag = 1;
	}
	if(txList[regID->rSrc2].reg != 0 && regID->rSrc2 != 0)
	{
		regID->rSrc2 = txList[regID->rSrc2].reg;
		pRegList[regID->rSrc2].flag = 1;
	}
	
	if(txList[regID->rSrc1].reg == 0 && regID->rSrc1 != 0)
	{
		int newReg = allocateReg();
		if(txList[regID->rSrc1].offset != 0)
		{
			printLoadStatement(newReg,txList[regID->rSrc1].offset);
			pRegList[newReg].tReg = regID->rSrc1;
			txList[regID->rSrc1].reg = newReg;
		}
		else if(txList[regID->rSrc1].globalName[0]!=0)
		{
			printGlobalLoad(newReg,txList[regID->rSrc1].globalName);
			pRegList[newReg].tReg = regID->rSrc1;
			txList[regID->rSrc1].reg = newReg;
		}
		else 
		{
			// printStoreStatement(newReg);
			// pRegList[newReg].tReg = regID->rSrc1;
			// txList[regID->rSrc1].reg = newReg;
			// printNewVariable()
			printf("Error. Variable not initialized before use.\n");
		}
		regID->rSrc1 = newReg;
		pRegList[regID->rSrc1].flag = 1;
	}
	if(txList[regID->rSrc2].reg == 0 && regID->rSrc2 != 0)
	{
		int newReg = allocateReg();
		if(txList[regID->rSrc2].offset != 0)
		{
			printLoadStatement(newReg,txList[regID->rSrc2].offset);
			pRegList[newReg].tReg = regID->rSrc2;
			txList[regID->rSrc2].reg = newReg;
		}
		else if(txList[regID->rSrc2].globalName[0]!=0)
		{
			printGlobalLoad(newReg,txList[regID->rSrc2].globalName);
			pRegList[newReg].tReg = regID->rSrc2;
			txList[regID->rSrc2].reg = newReg;
		}
		else 
		{
			// printStoreStatement(newReg);
			// pRegList[newReg].tReg = regID->rSrc2;
			// txList[regID->rSrc2].reg = newReg;
			// printNewVariable()
			printf("Error. Variable not initialized before use.\n");
		}
		regID->rSrc2 = newReg;
		pRegList[regID->rSrc2].flag = 1;
	}
	freeSrcReg(ins);
	if(txList[regID->rDest].reg == 0 && regID->rDest != 0)
	{
		int newReg = allocateReg();
		if(txList[regID->rDest].offset != 0)
		{
			// printLoadStatement(newReg,txList[regID->rDest].offset);
			pRegList[newReg].tReg = regID->rDest;
			txList[regID->rDest].reg = newReg;
		}
		else if(txList[regID->rDest].globalName[0]!=0)
		{
			// printGlobalLoad(newReg,txList[regID->rDest].globalName);
			pRegList[newReg].tReg = regID->rDest;
			txList[regID->rDest].reg = newReg;
		}
		else 
		{
			pRegList[newReg].tReg = regID->rDest;
			txList[regID->rDest].reg = newReg;
			// printNewVariable()
		}
		regID->rDest = newReg;
		pRegList[regID->rDest].flag = 1;
	}
	resetPhysicalRegisterFlags();
	return regID;
}

int allocateReg()
{
	int i;
	for(i = rrCount+1; i != rrCount; i=(i+1)%22)
	{
		// printf("%d\n",i);
		if(pRegList[i].free && !pRegList[i].flag)
		{
			pRegList[i].free = 0;
			// rrCount = (rrCount+1)%22;
			// if(txList[i].offset != 0)
			//   printStoreStatement(i,globalOffset);
			// else if (strcmp(txList[i].globalName,"\0"))
			//   printGlobalStore(i,txList[i].globalName);
			// else
			//   printStoreStatement(i,globalOffset);
			return i;
		}
	}
	while(i == rrCount)
	{
		if(pRegList[i].flag)
		{
			rrCount = (rrCount+1)%22;
			i = (i+1)%22;
		}
		else
		{
			pRegList[i].free = 0;
			rrCount = (rrCount+1)%22;
			if(txList[pRegList[i].tReg].offset != 0)
			{
				printStoreStatement(i,txList[pRegList[i].tReg].offset);
			}
			else if (strcmp(txList[pRegList[i].tReg].globalName,"\0"))
			{
				printGlobalStore(i,txList[pRegList[i].tReg].globalName);
			}
			else
			{
				printStoreStatement(i,globalOffset);
			}
			return i;
		}
	}
}

void printStoreStatement(int rx, int offset)
{
	printf("sw $r%d,%d($sp)\n", rx, offset);
}

void printGlobalStore(int rx, char *label)
{
	printf("sw $r%d,%s\n", rx, label);
}

void printLoadStatement(int rx, int offset)
{
	printf("lw $r%d,%d($sp)\n", rx, offset);
}

void printGlobalLoad(int rx, char *label)
{
	printf("lw $r%d,%s\n", rx, label);
}

void resetPhysicalRegisterFlags()
{
	int i;
	for(i=0;i<22;i++)
	{
		pRegList[i].flag = 0;
	}
}

void freeSrcReg(codeData ins)
{
	//printf("freeing %d %d\n", ins.tx1, ins.tx2);
	if(ins.isDead1)
		pRegList[txList[ins.tx1].reg].free = 1;
	if(ins.isDead2)
		pRegList[txList[ins.tx2].reg].free = 1;
	if(ins.isDead3)				// Sai: Ye wala kyon add nhi kia?
		pRegList[txList[ins.tx3].reg].free = 1;
}

// void copySymbolTableEntry(symbolTableEntry *symbolEntry, symbolTableEntry temp)
// {
// 	symbolEntry = (symbolTableEntry *)malloc(sizeof(symbolTableEntry));
// 	strcpy(symbolEntry->name, temp.name);
// 	symbolEntry->size = temp.size;
// 	symbolEntry->offset = temp.offset;
// 	symbolEntry->basetype = temp.basetype;
// 	symbolEntry->pointer = temp.pointer;
// 	symbolEntry->arraydimension = temp.arraydimension;
// 	symbolEntry->function = temp.function;
// 	symbolEntry->structure = temp.structure;
// 	int i = 0;
// 	for (i = 0; i < 10; ++i)
// 	{
// 		symbolEntry->dim[i] = temp.dim[i];
// 	}
// }

void fillTxList(symbolTable *table)
{
	int i;
	for(i=0;i<table->numberEntries;i++)
	{
		// symbolTableEntry temp = table->entries[numberEntries];    // sai: isko change kia h maine
		symbolTableEntry *temp = &(table->entries[i]);
		//printf("Symbol entry has name %s and tx %d\n", temp->name, temp->tx);
		//if child the search child
		if(temp->child!= NULL)
			fillTxList(temp->child);
		if(temp->tx < 1 || temp->tx > globaltx || temp->function == 1)
			continue;
		txList[temp->tx].symbolEntry = temp;      // sai: really yho karna h kya?? 
		if(temp->pointer == 1 || temp->arraydimension >0)
			txList[temp->tx].address = 1;
		if(temp->basetype == FLOAT)
			txList[temp->tx].floating = 1;
			
		
	}
}

void setBBLHeads(codeList *first)
{
	first->isBBLHead = 1;
	codeList *last = NULL;
	while(first != NULL)
	{
		if(first->gotoStatement == 1)
		{
			if(first->next != NULL)
					first->next->isBBLHead = 1;
			if(first->gotoAddress ==NULL)
				printf("Unresolved goto");
			else
				first->gotoAddress->isBBLHead = 1;
		}
		last = first;
		first = first->next;
		if(first != NULL)
			first->previous = last;
	}
	//add prev pointer
	// struct codeData *dataAnnotatedWithLines;                    // Need to make it global
	dataAnnotatedWithLines = (struct codeData *)malloc((last->lineno+1)*sizeof(struct codeData));
	int i = 0;
	for ( i = 0; i <= last->lineno; ++i)
	{
		dataAnnotatedWithLines[i].tx1 = 0;
		dataAnnotatedWithLines[i].tx2 = 0;
		dataAnnotatedWithLines[i].tx3 = 0;
		dataAnnotatedWithLines[i].lastUse1 = 0;
		dataAnnotatedWithLines[i].lastUse2 = 0;
		dataAnnotatedWithLines[i].lastUse3 = 0;
		dataAnnotatedWithLines[i].isDead1 = 1;
		dataAnnotatedWithLines[i].isDead2 = 1;
		dataAnnotatedWithLines[i].isDead3 = 1;
	}
	annotateCode(last);
}

void convertToWords(char *codeString, char words[10][50])
{
	int len = strlen(codeString);
	int j = 0;
	int count = 0;
	int i = 0;
	for ( i = 0; i < len; ++i)
	{
		if(i == 0 && codeString[i] == ' ')
		{
			continue;
		}
		if(codeString[i] == ' ')
		{
			if( codeString[i-1] != ' ')
			{
				words[count][j] = '\0';
				j = 0;
				count++;
			}
		}
		else
		{
			words[count][j] = codeString[i];
			j++;
		}
	}
	words[count][j] = '\0';         // last word ka end set kar rha hun
	return;
}

void annotateDataToLine(int src1, int src2, int dest, int lineno, struct tempRegDL *allReg)
{
	if(src1 != 0 && txList[src1].symbolEntry == NULL)
	{
		dataAnnotatedWithLines[lineno].tx1 = src1;
		dataAnnotatedWithLines[lineno].lastUse1 = allReg[src1].lastUse;
		dataAnnotatedWithLines[lineno].isDead1 = allReg[src1].isDead;
	}
	if(src2 != 0 && txList[src2].symbolEntry == NULL)
	{
		dataAnnotatedWithLines[lineno].tx2 = src2;
		dataAnnotatedWithLines[lineno].lastUse2 = allReg[src2].lastUse;
		dataAnnotatedWithLines[lineno].isDead2 = allReg[src2].isDead;
	}
	if(dest != 0 && txList[dest].symbolEntry == NULL)
	{
		dataAnnotatedWithLines[lineno].tx3 = dest;
		dataAnnotatedWithLines[lineno].lastUse3 = allReg[dest].lastUse;
		dataAnnotatedWithLines[lineno].isDead3 = allReg[dest].isDead;
	}
}

void updateDL(int src1, int src2, int dest, int lineno, struct tempRegDL *allReg)
{
	if(src1 != 0 && txList[src1].symbolEntry == NULL)
	{
		if(allReg[src1].lastUse == 0)
		{
			allReg[src1].lastUse = lineno;
		}
		allReg[src1].isDead = 0;
		// printf("%d is not dead above\n", src1);
	}
	if(src2 != 0 && txList[src2].symbolEntry == NULL)
	{
		if(allReg[src2].lastUse == 0)
		{
			allReg[src2].lastUse = lineno;
		}
		allReg[src2].isDead = 0;
		// printf("%d is not dead above\n", src2);
	}
	if(dest != 0 && txList[dest].symbolEntry == NULL)
	{
		if(allReg[dest].lastUse == 0)
		{
			allReg[dest].lastUse = lineno;
		}
		allReg[dest].isDead = 1;
		// printf("%d is dead above\n", dest);
	}
}

int check(struct tempRegDL *allReg, int totalTempReg)
{
	int i;
	for (i = 0; i < totalTempReg; ++i)
	{
		if(allReg[i].isDead != 1)
				return 0;
	}
	return 1;
}

void annotateCode(codeList *last)
{
	int totalTempReg = globaltx;          // Check if +1 should be there
	struct tempRegDL *allReg;
	allReg = (struct tempRegDL *)malloc(totalTempReg*sizeof(struct tempRegDL));
	int i;
	for ( i = 0; i < totalTempReg; ++i)
	{
		allReg[i].reg = i;
		allReg[i].isDead = 1;
		allReg[i].lastUse = 0;
	}
	do
	{
		char words[10][50];
		convertToWords(last->codeString, words);
		if(last->numAddresses == 3)
		{
			if(!strcmp(words[0], "if(t%d)") || !strcmp(words[0], "if(!t%d)") )
			{
				annotateDataToLine(last->tx1, last->tx3, last->tx2, last->lineno, allReg);
				updateDL(last->tx1, last->tx3, last->tx2, last->lineno, allReg);
				last->type = 1;
			}
			else if(!strcmp(words[0], "t%d"))
			{
				annotateDataToLine(last->tx2, last->tx3, last->tx1, last->lineno, allReg);
				updateDL(last->tx2, last->tx3, last->tx1, last->lineno, allReg);
				last->type = 2;
			}
				// test5 line 43
		}
		if(last->numAddresses == 2)
		{
			if(!strcmp(words[0], "t%d"))        // t1 = t2, t1 = coverttofloat(t2), 
			{
				annotateDataToLine(last->tx2, 0, last->tx1, last->lineno, allReg);
				updateDL(last->tx2, 0, last->tx1, last->lineno, allReg);
				if(strcmp(words[2],"memory(t%%d)") == 0)  //t1 = memory(t1)
				{
					last->type = 4;
				}
				else if(strcmp(words[2],"address(t%%d)") == 0)
				{//t1 = memory(t1)
					last->type = 15;
				}
				else//t1 = t2
				{
					last->type = 3;
				}
			}
		}
		if(last->numAddresses == 1)
		{
			if(!strcmp(words[0], "if(t%d)") || !strcmp(words[0], "if(!t%d)") )
			{
				annotateDataToLine(last->tx1, 0, 0, last->lineno, allReg);
				updateDL(last->tx1, 0, 0, last->lineno, allReg);
				last->type = 5;
			}
			else if(!strcmp(words[0], "return"))
			{
				annotateDataToLine(0, 0, last->tx1, last->lineno, allReg);
				updateDL(0, 0, last->tx1, last->lineno, allReg);
				last->type = 6;
			}
			else if(!strcmp(words[0], "param"))
			{
				annotateDataToLine(last->tx1, 0, 0, last->lineno, allReg);
				updateDL(last->tx1, 0, 0, last->lineno, allReg);
				last->type = 7;
			}
			else if(!strcmp(words[0], "t%d"))
			{
				annotateDataToLine(0, 0, last->tx1, last->lineno, allReg);
				updateDL(0, 0, last->tx1, last->lineno, allReg);
				if(strcmp(last->codeString, "t%d = return") == 0)
					last->type = 8;
				else if(strcmp(last->codeString, "t%d++") == 0 || strcmp(last->codeString, "t%d--") == 0)
					last->type = 13;
				else 
					last->type = 12;
			}
			else if(!strcmp(words[0], "writeln"))
			{
				annotateDataToLine(last->tx1, 0, 0, last->lineno, allReg);
				updateDL(last->tx1, 0, 0, last->lineno, allReg);
				last->type = 14;
			}
		}
		if(last->numAddresses == 0)
		{
			if(words[0][0] == 'g' && words[0][1] == 'o' && words[0][2]=='t' && words[0][3] == 'o')
				last->type = 11;
			else if(words[0][0] == 'c' && words[0][1] == 'a' && words[0][2]=='l' && words[0][3] == 'l')
				last->type = 10;
			else if(words[0][0] == 'r' && words[0][1] == 'e' && words[0][2]=='t' && words[0][3] == 'u')
				last->type = 9;
			else
			{
				printf("There does not exist any type for this\n");
			}
		}

		last = last->previous;
	}while( last != NULL && (last->next == NULL || last->next->isBBLHead != 1 ));
	if(last != NULL)
	{
		int a = check(allReg, totalTempReg);
		if(!a)
		{
			printf("I don't know why all the temp are not dead\n");
		}
		annotateCode(last);
	}
	else
	{
		int a = check(allReg, totalTempReg);
		if(!a)
		{
			printf("I don't know why all the temp are not dead\n");
		}
	}
	return;
}

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
					printf("goto lbl%d\n", labelN);
				}
				else
				{
					printf("goto %s\n", codeP->gotoAddress->label);
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
				char words[10][50];
				convertToWords(codeP->codeString, words);
				switch(strlen(words[3]))
				{
					case 1:
					switch(words[3][0])
					{
						case '|':   
						printf("or $t%d, $t%d, $t%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						printf("sw \n");
						break;

						case '&':   
						printf("and $t%d, $t%d, $t%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '^':   
						printf("xor $t%d, $t%d, $t%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

					}
					case 2: // oror, andand, neq, rshift
					switch(words[3][0])
					{
						case '!':
						if(words[3][1] == '=')
						{   
							printf("subu $t%d, $t%d, $t%d\nxori $t%d $t%d 1\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
						}
						break;

						case '=':
						if(words[3][1] == '=')
						{   
							printf("subu r%d, r%d, r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
						}
						break;

						case '<':
						if(words[3][1] == '=')
						{
							printf("slt r%d, r%d, r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
							break;
						}
						else if(words[3][1] == '<')
						{
							printf("sllv r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
							break;
						}

						case '>':
						if(words[3][1] == '=')
						{
							printf("slt r%d, r%d, r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc2, pregs->rSrc1, pregs->rDest, pregs->rDest);
							break;
						}
						else if(words[3][1] == '>')
						{
							printf("sra r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
							break;
						}
						
					}
					case 3:
					switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' )
						{
							printf("srlv r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						}
						break;
							
					}
					case 4:   
					switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' && words[3][3] == '=' )
						{
							printf("srlv r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						}
						break;
							
					}
					case 8: // integer+-*/
					switch(words[3][7])
					{
						case '+':   
						printf("add r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '-':   
						printf("sub r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '*':   
						printf("mult r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;  

						case '/':   
						printf("div r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;
					}
					case 9: 
					switch(words[3][8])//unsigned +/-*
					{
						case '+':
						printf("addu r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '-':
						printf("subu r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '*':
						printf("multu r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;

						case '/':
						printf("divu r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
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
					printf("Move r%d, r%d\n", pregs->rDest, pregs->rSrc1);
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
						printf("li r%d, %s\n", pregs->rDest, words[2]);
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
				break;

				case 2:
				//check for conversion
				//get regs
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = codeP->tx3;
				// printf("%d %d %d\n", codeP->tx1,codeP->tx2,codeP->tx3);
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				char words[10][50];
				convertToWords(codeP->codeString, words);
				switch(strlen(words[3]))
				{
					case 1:
					switch(words[3][0])
					{
						case '|':   
						printf("or r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '&':   
						printf("and r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '^':   
						printf("xor r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

					}
					case 2: // oror, andand, neq, rshift
					switch(words[3][0])
					{
						case '!':
						if(words[3][1] == '=')
						{   
							printf("subu r%d, r%d, r%d\nxori r%d r%d 1\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
						}
						break;

						case '=':
						if(words[3][1] == '=')
						{   
							printf("subu r%d,r%d,r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
						}
						break;

						case '<':
						if(words[3][1] == '=')
						{
							printf("slt r%d, r%d, r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2, pregs->rDest, pregs->rDest);
							break;
						}
						else if(words[3][1] == '<')
						{
							printf("sllv r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
							break;
						}

						case '>':
						if(words[3][1] == '=')
						{
							printf("slt r%d, r%d, r%d\nsubu r%d 1 r%d\n", pregs->rDest, pregs->rSrc2, pregs->rSrc1, pregs->rDest, pregs->rDest);
							break;
						}
						else if(words[3][1] == '>')
						{
							printf("sra r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
							break;
						}

					}
					case 3:   switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' )
						{
								printf("srlv r%d,r%d,r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						}
						break;

					}
					case 4:   switch(words[3][0])
					{
						case '>':
						if(words[3][1] == '>' && words[3][2] == '>' && words[3][3] == '=' )
						{
							printf("srlv r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						}
						break;

					}
					case 8: // integer+-*/
					switch(words[3][7])
					{
						case '+':   
						printf("add se pehle dekho r%d, r%d, r%d\n", codeP->tx1, codeP->tx2, codeP->tx3);
						printf("add r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '-':   
						printf("sub r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '*':   
						printf("mult r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;

						case '/':   
						printf("div r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;
					}
					case 9: switch(words[3][8])//unsigned +/-*
					{
						case '+':
						printf("addu r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '-':
						printf("subu r%d, r%d, r%d\n", pregs->rDest, pregs->rSrc1, pregs->rSrc2);
						break;

						case '*':
						printf("multu r%d,r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;

						case '/':
						printf("divu r%d, r%d\nmflo r%d\n", pregs->rSrc1,pregs->rSrc2, pregs->rDest);
						break;
					}
				}
				break;
				case 3:
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				if(txList[codeP->tx1].floating)
				{
					;
				}
				else
				{
					printf("Move r%d, r%d\n", pregs->rDest, pregs->rSrc1);
					//Manually store global vars to memory
				}
				break;

				case 4:
				txregs.rDest = codeP->tx1;
				txregs.rSrc1 = codeP->tx2;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				printf("la r%d, %d\n", pregs->rDest, pregs->rSrc1);
				break;

				case 5:
				txregs.rDest = 0;
				txregs.rSrc1 = codeP->tx1;
				txregs.rSrc2 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				if(codeP->codeString[3]== '!')
					printf("bneq r%d,1,%s\n",pregs->rSrc1,codeP->gotoAddress->label );
				else
					printf("beq r%d,1,%s \n",pregs->rSrc1,codeP->gotoAddress->label);
				break;

				case 6:
				//return this variable
				txregs.rDest = 0;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = codeP->tx1;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				printf("move $v0, r%d\naddu $sp, 1000\nj $ra\n", pregs->rSrc1);
				break;

				case 7: //Param statement, move data into $ax
				txregs.rDest = 0;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = codeP->tx1;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				//
				printf("move $a%d, r%d\n", paramN++, pregs->rSrc1);
				break;

				case 8:			// Sai: Error in here rSrc1 is 0
				txregs.rDest = codeP->tx1;
				txregs.rSrc2 = 0;
				txregs.rSrc1 = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				
				printf("move $r%d, $v0\n", pregs->rDest);
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
					printf("li $r%d, 0($sp)\n",pregs->rDest);

				}
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == INT_LIT)
				{
					printf("li r%d, %d\n",pregs->rDest,atoi(txList[codeP->tx1].symbolEntry->name));
				}
				else
				{
					char words[10][50];
					convertToWords(codeP->codeString, words);
					printf("li r%d, %s\n",pregs->rDest, words[2]);
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
					printf("addi r%d, r%d, 1\n", pregs->rDest, pregs->rDest);
					break;
				}
				else if(!strcmp(codeP->codeString, "t%d--\n"))
				{
					txregs.rSrc1 = 0;
					txregs.rSrc2 = 0;
					txregs.rDest = codeP->tx1;
					pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
					printf("addi r%d, r%d, -1\n", pregs->rDest, pregs->rDest);
					break;
				}

				case 14:// prateek : working
				txregs.rSrc1 = codeP->tx1;
				txregs.rSrc2 = 0;
				txregs.rDest = 0;
				pregs = phyRegister(&txregs, dataAnnotatedWithLines[codeP->lineno]);
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == STRING_LIT)
				{   
					printf("li $v0,4\n");
					printf("la $a0,r%d\n",pregs->rSrc1);
				}
				if(txList[codeP->tx1].symbolEntry != NULL && txList[codeP->tx1].symbolEntry->basetype == INT_LIT)
				{
					printf("li $v0,1\n");
					printf("move $a0,r%d\n",pregs->rSrc1);
				}
				else
				{
					printf("li $v0,1\n");
					printf("move $a0,r%d\n",pregs->rSrc1);
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
				break;
			}
			// pregs->
			//if function start, do stuff

			//if type 6 or type 

		}

		codeP = codeP->next;        
	}
}
																	 
char *regname(int num)
 {
		char *reg=NULL;
		reg=(char *)malloc(5*sizeof(char));
	 
		if(num <0)
				return NULL;
		else if(num<10)
			snprintf(reg,5, "$t%d",num);
		else if(num<18)
			snprintf(reg, 5, "$s%d", num-10);
		else if(num<22)
			snprintf(reg, 5, "$a%d", num-18);
		else
			return NULL;
		return reg;
 }

 void printDataSegment(){
	symbolTable *globalScope = top(stack_head);
	printf(".data\n");
	if(globalScope!=NULL){
		//printf("%d\n",stack_head);
		int i;
		for(i = 0 ; i< globalScope->numberEntries; i++){
			if(!(globalScope->entries[i].function) && !(globalScope->entries[i].label) && !(globalScope->entries[i].structure)){
				if(globalScope->entries[i].basetype == BYTE || globalScope->entries[i].basetype == CHAR){
					if(globalScope->entries[i].arraydimension>0){
						int j,space=1;
						for(j=0;j<10;j++){
							if(globalScope->entries[i].dim[j]>0)
								space = space*globalScope->entries[i].dim[j];
						}
						printf("%s:\t.space %d\n",globalScope->entries[i].name, space);
					}
					else
						printf("%s:\t.byte\n",globalScope->entries[i].name);
				}
				else{
					if(globalScope->entries[i].arraydimension>0){
						int j,space=1;
						for(j=0;j<10;j++){
							if(globalScope->entries[i].dim[j]>0)
								space = space*globalScope->entries[i].dim[j];
						}
						printf("%s:\t.space %d\n",globalScope->entries[i].name, space*4);
					}
					else
						printf("%s:\t.word\n",globalScope->entries[i].name);
				}
			}
		}
	}
 }