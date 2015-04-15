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

codeList * setType(ASTnode *node, int type)
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
          printf("Error. Cannot convert from %d to %d", node->symbolEntry->basetype, type);
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
      strcpy(function, "%s");
    }
    else
    {
      switch(typeSource)
      {
          case DOUBLE :   strcpy(function, "doubleto");
                  break;
          case FLOAT :  strcpy(function, "floatto");
                  break;
          case LONG :   strcpy(function, "longto");
                  break;
          case INT :    strcpy(function, "intto");
                  break;
          case SHORT :  strcpy(function, "shortto");
                  break;
          case BYTE :   strcpy(function, "byteto");
                  break;
          case CHAR :   strcpy(function, "charto");
                  break;
          case ULONG :  strcpy(function, "longto");
                  break;
          case UINT :   strcpy(function, "intto");
                  break;
          case USHORT :   strcpy(function, "shortto");
                  break;
          case UBYTE :  strcpy(function, "byteto");
                  break;
      }
      switch(typeDestination)
      {
          case DOUBLE : strcat(function, "double(%s)");
                          break;
          case FLOAT :  strcat(function, "float(%s)");
                          break;
          case LONG :   strcat(function, "long(%s)");
                          break;
          case INT :  strcat(function, "int(%s)");
                          break;
          case SHORT :  strcat(function, "short(%s)");
                          break;
          case BYTE :   strcat(function, "byte(%s)");
                          break;
          case CHAR :   strcat(function, "char(%s)");
                          break;
          case ULONG :  strcat(function, "long(%s)");
                          break;
          case UINT :   strcat(function, "int(%s)");
                          break;
          case USHORT :   strcat(function, "short(%s)");
                          break;
          case UBYTE :  strcat(function, "byte(%s)");
                          break;
      }
    } 
    if((typeSource == UINT || typeSource == UBYTE || typeSource == USHORT || typeSource == ULONG) && (typeDestination == INT || typeDestination == BYTE || typeDestination == SHORT || typeDestination == LONG || typeDestination == FLOAT || typeDestination == DOUBLE))  
    {
      char *temp = (char *)malloc(50*sizeof(char));
      snprintf(temp, 50, function, "tosigned(t%d)");
      function = temp;
    }
    else if((typeSource == INT || typeSource == BYTE || typeSource == SHORT || typeSource == LONG || typeSource == FLOAT || typeSource == DOUBLE) && (typeDestination == UINT || typeDestination == UBYTE || typeDestination == USHORT || typeDestination == ULONG))  
    {
      //char *temp = (char *)malloc(50*sizeof(char));
        snprintf(function, 50, "tounsigned(%s)", function);
    }
    int length = strlen(function);
    if(length >= 4 && function[length-4] == '%')
      function[length-3]='d';
    else if(length >= 3 && function[length-3] == '%')
      function[length-2]='d';
    else if(length >= 2 && function[length-3] == '%')
      function[length-1]='d';
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
    for(i = 0; i< 10; i++) { 
        newnode->dim[i] = n->dim[i];
    }
    entryPoint->node = newnode;
    return;
  }
  else {
    while(temp->next != NULL){
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
 
 void createStructEntry(){
  globalStructs[++struct_head] = (fields *)malloc(sizeof(fields));
    globalStructs[struct_head]->node = NULL;    
 }
 
 int checkFuncList(char *id, ASTnode *node){
  int i;
    ASTnode *n = node;
    for(i =0; i<100; i++){
      if(!strcmp(globalStructs[i]->id,id)){
//           printf("%s\n", id);
          break;
        }
    }
    if(globalStructs[i]->node == NULL && n == NULL){
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
    while(var->next != NULL){
//       printf("> 1 var passed\n");

      if(strcmp(n->lexeme,",")){
          printf("Error. More arguments expected!\n");
          return 0;
      }
//       printf("%d %d\n", var->type , n->children[1]->basetype);
      if((var->type == n->children[1]->basetype) || implicitCompatible(var->type, n->children[1]->basetype)){
//         printf("%d %d %d %d \n",var->pointer,n->children[1]->pointer,var->arraydimension,n->children[1]->arraydimension );
            if((var->pointer == n->children[1]->pointer) && (var->arraydimension == n->children[1]->arraydimension)){
                int i;
                if(var->arraydimension){
                  for(i =0; i< 10; i++){
                      if(var->dim[i] != n->children[1]->dim[i]){
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
                for(i =1; i< 10; i++){
                    if(var->dim[i-1] != n->children[1]->dim[i]){
                        printf("Error. Array Dimention check failed!\n");
                        return 0;
                      }
                }
//                 printf("Array -1 to pointer match!\n");
                //return 1;
            }
            else {
              printf("Array n pointer mismatch!\n");
              return 0;
            }
        }
        else {
          printf("definition mismatch!\n"); 
          return 0;
        }
        var = var->next;
        n = n->children[0];
    }
    if(var->next == NULL){
//       printf("1 var passed\n");
      if(!strcmp(n->lexeme,",")){
          printf("Error. Less arguments expected!\n");
          return 0;
        }
//         printf("%d %d\n", var->type , n->basetype);
      if((var->type == n->basetype) || implicitCompatible(var->type, n->basetype)){
//           printf("%d %d %d %d \n",var->pointer,n->pointer,var->arraydimension,n->arraydimension );
          if((var->pointer == n->pointer) && (var->arraydimension == n->arraydimension)){
//             printf("checking arr dims\n");
                int i;
                if(var->arraydimension){
                  for(i =0; i< 10; i++){
//                     printf("%d %d\n",var->dim[i] , n->dim[i] );
                      if(var->dim[i] != n->dim[i]){
                          printf("Error. Array Dimention check failed!\n");
                          return 0;
                        }
                  }
                }
                return 1;
            }
            else if((n->pointer == 0) && (var->pointer == 1) && (var->arraydimension == (n->arraydimension - 1))){
              int i;
                for(i =1; i< 10; i++){
//                     printf("%d %d\n",var->dim[i-1] , n->dim[i] );
                    if(var->dim[i-1] != n->dim[i]){
                        printf("Error. Array Dimention check failed!\n");
                        return 0;
                      }
                }
                return 1;
            }
            else {
              printf("Array n pointer mismatch!\n");
              return 0;
            }
        }
        else {
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

void createStructEntries(ASTnode *n1,ASTnode *n2){
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
    for(i = 0; i< 10; i++) { 
        newnode->dim[i] = n1->dim[i];
    }
    entryPoint->node = newnode;
    return;
    }
    else {
    while(temp->next != NULL){
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
    for(i = 0; i< 10; i++) { 
        newnode->dim[i] = n1->dim[i];
    }
    temp->next = newnode;
    return;
    }
}

fields *searchStruct(char *id){
    int i;
    for(i =0; i<100; i++){
      if(!strcmp(globalStructs[i]->id,id)){
    //           printf("%s\n", id);
          break;
        }
    }
    if(i == 100){
        printf("Struct %s not found.\n",id );
        return NULL;
    }
    if(globalStructs[i]->type == STRUCT){
        return globalStructs[i];
    }
    else{
        printf("%s is not of Struct type\n",id );
        return NULL;
    }
}