%{
void yyerror (char *s);
#include <stdio.h>     /* C declarations used in actions */
#include <stdlib.h>
#include <string.h>
#include "../src/definition.h"
extern FILE *yyin; 
extern FILE* yyout;
extern int yylineno;
symbolTable * stack[100];
fields * globalStructs[100];
codeList *loopEndStack[100];
arrayDimList *arrayList = NULL;
int loopEndStackHead = -1;
int struct_head=-1;
int stack_head=-1;
int globaltx = 0;
codeList *codeStart; 
symbolTable * globalSymbolTable; 
%}
%token INT_LIT, FLOAT_LIT, CHAR_LIT, STRING_LIT, IDENTIFIER

%token DIV_EQ, AND_EQ, AND_AND, OR_EQ, OR_OR, MIN_EQ, MIN_MIN, PLUS_EQ, PLUS_PLUS, LEQ, LSHIFT, LSHIFT_EQ, LESS_GREAT, GEQ, RSHIFT_EQ, LOG_RSHIFT_EQ, RSHIFT, LOG_RSHIFT, NEQ, NLESS_GREAT, NLT, NLEQ, NGT, NGEQ, EQ_EQ, MULT_EQ, MOD_EQ, XOR_EQ, POW, POW_EQ, INV_EQ

%token ASM, ASSERT, AUTO, BOOL, BODY, BREAK, BYTE, CASE, CATCH, CHAR, CLASS, CONST, CONTINUE, DEFAULT, DELETE, DO, DOUBLE, ELSE, ENUM, FALSE, FINAL, FINALLY, FLOAT, FOR, FOREACH, FUNCTION, GOTO, IF, IMPORT, IN, INT, LONG, NEW, NULLTOKEN, OUT, PRIVATE, PROTECTED, PUBLIC, RETURN, SHORT, SIZEOF, STATIC, STRUCT, SUPER, SWITCH, THIS, THROW, TRUE, TRY, TYPEOF, UBYTE, UINT, ULONG, USHORT, VOID, WHILE
%start Declarations
%union{
        struct ASTnode *node;   //non-token
        struct ASTCaseNode *caseNode;
        struct terminal{    //token
                        char *text;
                        int type;
        } token;
}

%type <token> INT_LIT, FLOAT_LIT, CHAR_LIT, STRING_LIT, IDENTIFIER
%type <token> DIV_EQ, AND_EQ, AND_AND, OR_EQ, OR_OR, MIN_EQ, MIN_MIN, PLUS_EQ, PLUS_PLUS, LEQ, LSHIFT, LSHIFT_EQ, LESS_GREAT, GEQ
%type <token> RSHIFT_EQ, LOG_RSHIFT_EQ, RSHIFT, LOG_RSHIFT, NEQ, NLESS_GREAT, NLT, NLEQ, NGT, NGEQ, EQ_EQ, MULT_EQ, MOD_EQ, XOR_EQ, POW
%type <token> POW_EQ, INV_EQ
%type <token> ASM, ASSERT, AUTO, BOOL, BODY, BREAK, BYTE, CASE, CATCH, CHAR, CLASS, CONST, CONTINUE, DEFAULT, DELETE, DO, DOUBLE, ELSE
%type <token> ENUM, FALSE, FINAL, FINALLY, FLOAT, FOR, FOREACH, FUNCTION, GOTO, IF, IMPORT, IN, INT, LONG, NEW, NULLTOKEN, OUT, PRIVATE
%type <token> RETURN, SHORT, SIZEOF, STATIC, STRUCT, SUPER, SWITCH, THIS, THROW, TRUE, TRY, TYPEOF, UBYTE, UINT, ULONG, USHORT, VOID, WHILE

%type <node> ArraySuffix, ArraySuffixes, Declarations, IdentifierWithoutDot, Identifier, Type1, Type, ArrayDeclarator, IdentifierList, IdentifierDeclaration
%type <node> Declaration, VarDeclarations, FuncDeclaration, FuncScopeDummy, FunctionBody, BlockStatement, AggregateDeclaration, StructDeclaration
%type <node> VarDeclarationList, VarDeclarationsList, AggregateBody, DeclDefs, DeclDef, Constructor, Destructor
%type <node> StatementList, Statement, NonEmptyStatement, NonEmptyStatementNoCaseNoDefault, LabeledStatement, ExpressionStatement
%type <node> Expression, ConditionalExpression, OrOrExpression, AndAndExpression, OrExpression, XorExpression, AndExpression
%type <node> EqualNotEqual, LtGtLteGte, Shift, PlusMinus, MulDivMod, UnaryExpression, PointerExpression, UnaryOperator, MainExpression, ExpressionList
%type <node> Starting, AssignmentOperator, DeclarationStatement, IfStatement, WhileStatement, DoStatement
%type <node> ForStatement, SwitchStatement, ContinueStatement, BreakStatement
%type <node> ReturnStatement, GotoStatement, StatementNoCaseNoDefault
%type <node> StatementListNoCaseNoDefault, Initialize, StructScopeDummy
%type <node> IfScopeDummy1, IfScopeDummy2, WhileScopeDummy, DoScopeDummy, ForScopeDummy, IfEndScopeDummy, FuncScopeDummy
%type <node> CaseStatementDummy, SwitchStatement, SwitchDummy
%type <caseNode> CaseStatement, DefaultStatement, CaseDefaultStatement

%%
Declarations    :   Declaration                 {//DONE
                                                    $$ = $1;
                                                    codeStart = $$->codeStart;
                                                }
                |   Declarations Declaration    {
                                                    $$ = createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $2;
                                                    $1->parent = $$;
                                                    $2->parent = $$;
                                                    if($1->codeStart == NULL)
                                                    {
                                                        if($2->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $2->codeStart;
                                                            $$->codeEnd = $2->codeEnd;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        $$->codeStart = $1->codeStart;
                                                        if($2->codeStart == NULL)
                                                        {
                                                            $$->codeEnd = $1->codeEnd; 
                                                        }
                                                        else
                                                        {
                                                            $$->codeEnd = $2->codeEnd;
                                                            $1->codeEnd->next = $2->codeStart; 
                                                        }
                                                    } 
                                                    codeStart = $$->codeStart;
                                                }
    
IdentifierWithoutDot     :
        IDENTIFIER                          {//DONE
                                                    $$ = createNode(0);
                                                    strcpy($$->lexeme, $1.text);
                                            }
    |   IDENTIFIER ArrayDeclarator          {
                                                    $$ = createNode(1);
                                                    $$->children[0] = $2;       // It might contain expressions
                                                    $$->children[0]->parent = $$;
                                                    strcpy($$->lexeme,$1.text);
//                                                     $$->pointer = 0;
                                                    $$->arraydimension = $2->arraydimension;
                                                    int i = 0;
                                                    for(i = 0; i < $$->arraydimension; ++i)
                                                    {
                                                        $$->dim[i] = $2->dim[i];
                                                    }
                                            }
    |   '*' IDENTIFIER                      {
                                                    $$ = createNode(0);
                                                    strcpy($$->lexeme, $2.text);
                                                    $$->pointer = 1;
                                            }
    ;  

Identifier      :
        IdentifierWithoutDot                    {//DONE
                                                    $$ = $1;
                                                }
    |   IdentifierWithoutDot '.' Identifier     {
                                                    symbolTableEntry *id = findSymbol(strcat($1->lexeme, strcat(".", $3->lexeme)), 0, 0);
                                                    if(id == NULL)
                                                    {
                                                        printf("ERROR: Variable not found");
                                                    }
                                                    else
                                                    {
                                                        $$ = createNode(0);
                                                        strcpy($$->lexeme, id->name);
                                                        $$->basetype = id->basetype;
                                                        $$->pointer = id->pointer;
                                                        $$->arraydimension = id->arraydimension;
                                                        $$->function = id->function;
                                                        strcpy($$->structureName, id->structureName);
                                                        $$->structure = id->structure;
                                                        int i = 0;
                                                        for (i = 0; i < 10; ++i)
                                                        {
                                                            $$->dim[i] = id->dim[i];
                                                        }
                                                        $$->tx = id->tx;
                                                        strcpy($$->lexeme, strcat($1->lexeme, strcat(".", $3->lexeme)));
                                                    }

                                                }
    ;

Type           :    // Obviously basetype k sath sath array bhi defined hai but pointer yaha $$ me koi use nhi h 
        Type1                               {//DONE
                                                $$ = $1;
                                            }
    |   Type1 ArrayDeclarator               {
                                                $$ = createNode(1);
                                                $$->children[0] = $2;
                                                strcpy($$->lexeme, $1->lexeme);
                                                $$->basetype = $1->basetype;
//                                                  $$->pointer = 0;
                                                $$->arraydimension = $2->arraydimension;
                                                int i = 0;
                                                for (i = 0; i < 10;++i)
                                                {
                                                    $$->dim[i] = $2->dim[i];
                                                }
                                            }
    ;

Type1           :           // yaha array dimension to nhi h but basic type defined hona chahie always
        BOOL                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text); 
                                            }
    |   BYTE                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   UBYTE                               {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   SHORT                               {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   USHORT                              {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   INT                                 {//DONE
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   UINT                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   LONG                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   ULONG                               {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   CHAR                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   FLOAT                               {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   DOUBLE                              {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    |   VOID                                {
                                                $$ = createNode(0);
                                                $$->basetype = $1.type;
                                                strcpy($$->lexeme, $1.text);
                                            }
    ;

ArrayDeclarator :
            '[' Shift ']'                   {
                                                if(implicitCompatible(LONG, $2->basetype) && $2->pointer == 0 && $2->arraydimension == 0)
                                                {
                                                    $$ = createNode(1);
                                                    strcpy($$->lexeme, "[ ]");

                                                    $$->arraydimension = 1;
                                                    $$->children[0] = $2;
                                                    $$->children[0]->parent = $$;
                                                    $$->pointer = 0;
                                                    int i = 0;
                                                    for (i = 0; i < 10;++i)
                                                    {
                                                        $$->dim[i] = 0;
                                                    }
                                                    evalExp expVal= evaluate($2);
                                                    if(!expVal.err && expVal.val >0)
                                                        $$->dim[$$->arraydimension - 1] = expVal.val;
                                                }
                                                else
                                                {
                                                    printf("ERROR in type of shift\n");
                                                }
                                            }
    |   '[' Shift ']' ArrayDeclarator       {
                                                if(implicitCompatible(LONG, $2->basetype) && $2->pointer == 0 && $2->arraydimension == 0)
                                                {
                                                    $$ = createNode(2);
                                                    strcpy($$->lexeme, "[ ]");
                                                    $$->arraydimension = $4->arraydimension + 1;
                                                    $$->children[0] = $2;
                                                    $$->children[0]->parent = $$;
                                                    $$->children[1] = $4;
                                                    $$->children[1]->parent = $$;
                                                    // $$->dim[0] = atoi($2->lexeme);
                                                    // $$->dim[0] = atoi($2->lexeme);  
                                                    int i = 0;
                                                    for (i = 0; i < 10; ++i)
                                                    {
                                                        $$->dim[i] = $4->dim[i];
                                                    }  
                                                    evalExp expVal= evaluate($2);
                                                    if(!expVal.err && expVal.val >0)
                                                        $$->dim[$$->arraydimension - 1] = expVal.val;
                                                    $$->pointer = 0;  
                                                }
                                                else
                                                {
                                                    printf("ERROR in type of shift\n");
                                                }
                                            }
    ;

IdentifierDeclaration :             // pointer , arraydimension, defined here .... sometimes basetype is also defined
        IdentifierWithoutDot                              {//DONE
                                                                if(findSymbol($1->lexeme, 0, 1) == NULL)
                                                                {  
                                                                    $$ = $1;
                                                                    $$->symbolEntry = addSymbol($$, $1->lexeme, top(0));
                                                                    $$->symbolEntry->tx=++globaltx;
                                                                }
                                                                else
                                                                {
                                                                    printf("Redeclaration of variable %s\n", $1->lexeme);
                                                                }
                                                          }
    |   IdentifierWithoutDot '=' ConditionalExpression    {//DONE Prateek
                                                                if(findSymbol($1->lexeme, 0, 1) == NULL)
                                                                {          
                                                                    if( $1->arraydimension == 0)
                                                                    {
                                                                        if($1->pointer == 1 && (implicitCompatible(LONG, $3->basetype)))
                                                                        {
                                                                            printf("Error. Address value must be an intger.\n");
                                                                        }
                                                                        else {
                                                                            $$ = createNode(2);
                                                                            $$->pointer = $1->pointer;
                                                                            strcpy($$->lexeme, "=");
                                                                            $$->basetype = $3->basetype;
                                                                            $$->children[0] = $1;
                                                                            $$->children[1] = $3;
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;

                                                                            //generate code for basic declaration
                                                                            if($3->codeStart != NULL)
                                                                            {                                                                    
                                                                                $$->codeStart = $3->codeStart;
                                                                                $$->codeEnd = $3->codeEnd;
                                                                                $$->tx = $3->tx;
                                                                            }
                                                                            else
                                                                            {
                                                                                $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                                                                $$->codeEnd = $$->codeStart;
                                                                                $$->tx = ++globaltx;
                                                                                $$->codeStart->tx1 = globaltx; 
                                                                                $$->codeStart->tx2 = $3->tx;
                                                                                $$->codeStart->numAddresses = 2;
                                                                                strcpy($$->codeStart->codeString, "t%d = t%d");
                                                                                $$->codeStart->next = NULL;
                                                                            }
                                                                            //insert into symbol table
                                                                            $$->symbolEntry = addSymbol($$, $1->lexeme, top(0));
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        printf("array ko ham log assign nhi kar sakte hai while declaration");
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    printf("Redeclaration of variable %s\n", $1->lexeme);
                                                                }
                                                          }
// Array ko initialize kar sakte  h using '{' INT_LIT list '}'
    ;

IdentifierList :            // yaha $$->pointer does not make sense as well as array dimensions
        IdentifierDeclaration                       {//DONE
                                                        $$ = $1;
                                                        $$->pointer = 0;
                                                        $$->arraydimension = 0;
                                                        int i = 0;
                                                        for(i = 0; i < 10; i++)
                                                        {
                                                          $$->dim[i] = 0;
                                                        }
                                                    }
    |   IdentifierList ',' IdentifierDeclaration    {
                                                        if(implicitCompatible($1->basetype, $3->basetype) || implicitCompatible($3->basetype, $1->basetype) || $1->basetype == -1 || $3->basetype == -1)
                                                        {
                                                            $$ = createNode(2);
                                                            $$->pointer = 0;
                                                            $$->arraydimension = 0;
                                                            int i = 0;
                                                            for(i = 0; i < 10; i++)
                                                            {
                                                              $$->dim[i] = 0;
                                                            }
                                                            strcpy($$->lexeme, ",");
                                                            $$->children[0] =  $1;
                                                            $$->children[1] =  $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            if($1->basetype == -1)
                                                                $$->basetype = $3->basetype;
                                                            else if($3->basetype == -1 )
                                                                $$->basetype = $1->basetype;
                                                            else if(implicitCompatible($1->basetype, $3->basetype))
                                                                $$->basetype = $1->basetype;
                                                            else
                                                                $$->basetype = $3->basetype;
                                                            
                                                            if($1->basetype == -1)
                                                            {
                                                              $$->children[0]->basetype = $$->basetype;
                                                            }
                                                            if($3->basetype == -1)
                                                            {
                                                              $$->children[1]->basetype = $$->basetype;
                                                            }
                                                            $$->codeStart = $1->codeStart; 
                                                            $$->codeEnd = $3->codeEnd; 
                                                            $1->codeEnd->next = $3->codeStart;
                                                        }
                                                        else
                                                        {
                                                          printf("Error check that all the identifiers are of the same type");
                                                        }
                                                    }
    ; 

Declaration:
        FuncDeclaration                     {//DONE
                                                $$ = $1;
                                            }
    |   VarDeclarations                     {//DONE
                                                $$ = $1;
                                            }
    |   AggregateDeclaration                {//DONE
                                                $$ = $1;
                                            }
    ;

VarDeclarations     :
        Type IdentifierList  ';'                {//DONE//DONE Prateek
                                                    
                                                    $$ = createNode(2);
                                                    $$->basetype = $1->basetype;
                                                    $$->children[0] =  $1;
                                                    $$->children[1] =  $2;
                                                    $$->children[0]->parent = $$;
                                                    $$->children[1]->parent = $$;
                                                    
                                                    codeList * typecastList = setType($2, $1->basetype);
                                                    if((long)typecastList != -1) 
                                                    {
                                                        $$->codeStart = $2->codeStart;
                                                        $$->codeEnd = $2->codeEnd;
                                                        
                                                        if(typecastList != NULL)
                                                        {
                                                            if($$->codeStart != NULL)
                                                            {
                                                                $$->codeEnd->next = typecastList;
                                                            }
                                                            else
                                                            {
                                                                $$->codeStart = typecastList;
                                                            }
                                                            while(typecastList != NULL)
                                                            {
                                                                $$->codeEnd = typecastList;
                                                                typecastList = typecastList->next;
                                                            }
                                                        }
                                                    }

                                                }
    |   STRUCT IDENTIFIER IDENTIFIER ';'          {
                                                                if(findSymbol($2.text, 0, 1) != NULL)
                                                                { 
                                                                    // Temporarily out of service
                                                                    $$ = createNode(0);
                                                                    $$->structure = 1;
                                                                    $$->basetype = STRUCT;
                                                                    strcpy($$->structureName, $2.text);
                                                                    strcpy($$->lexeme, $3.text);
                                                                    $$->symbolEntry = addSymbol($$, $3.text, top(0));
                                                                    // $$->symbolEntry->tx=++globaltx;
                                                                    fields *entries1 = searchStruct($2.text);
                                                                    if(entries1 != NULL)
                                                                    {
                                                                        fieldEntry *next = entries1->node;
                                                                        while(next != NULL)
                                                                        {
                                                                            ASTnode *node1 = createNode(0);
                                                                            node1->basetype = next->type;
                                                                            strcpy(node1->lexeme, strcat($$->structureName, strcat(".", next->id)));
                                                                            $$->symbolEntry = addSymbol(node1, node1->lexeme, top(0));
                                                                            $$->symbolEntry->tx=++globaltx;
                                                                            next = next->next;
                                                                        }
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    printf("Error: Structure %s name not defined\n", $2.text);
                                                                }
                                                            }
    ;

FuncDeclaration:
// change type to type1 as we are not returning arrays
        Type IDENTIFIER '(' FuncScopeDummy VarDeclarationList ')' FunctionBody              {
                                                                                                pop();
                                                                                                if(findSymbol($2.text, stack_head, 0) == NULL)
                                                                                                {
                                                                                                    
                                                                                                    //$2->symbolEntry->child = $4->currentTable;
                                                                                                    //$4->currentTable->parent = $2->symbolEntry;
                                                                                                    //$$->currentTable = $4->currentTable;
                                                                                                    $$ = createNode(2);
                                                                                                    $$->basetype = $1->basetype;
                                                                                                    $$->function = 1;
                                                                                                    $$->pointer = 0;
                                                                                                    strcpy($$->lexeme, $2.text);
                                                                                                    $$->children[0] = $5;
                                                                                                    $$->children[1] = $7;
                                                                                                    $$->children[0]->parent = $$;
                                                                                                    $$->children[1]->parent = $$;
                                                                                                    $$->symbolEntry = addSymbol($$, $$->lexeme, top(0));
                                                                                                    $$->symbolEntry->tx=++globaltx;
                                                                                                    $$->symbolEntry->child = top(0);
                                                                                                    $$->symbolEntry->codeStart = $7->codeStart;
                                                                                                    top(0)->parent = $$->symbolEntry;
                                                                                                    $$->codeStart = $7->codeStart;
                                                                                                    $$->codeEnd = $7->codeEnd;
                                                                                                    globalStructs[struct_head]->type=FUNCTION;
                                                                                                    globalStructs[struct_head]->id = $2.text;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    printf("Redeclaration of an identifier");
                                                                                                }
                                                                                            }// add to papa symbol table
    |   Type '*' IDENTIFIER '(' FuncScopeDummy VarDeclarationList ')' FunctionBody          {
                                                                                                pop();
                                                                                                if(findSymbol($3.text, stack_head, 0) == NULL)
                                                                                                {
//                                                                                                     $3->symbolEntry->child = $5->currentTable;
//                                                                                                     $5->currentTable->parent = $3->symbolEntry;
//                                                                                                     $$->currentTable = $5->currentTable;
                                                                                                    $$ = createNode(2);
                                                                                                    $$->basetype = $1->basetype;
                                                                                                    $$->function = 1;
                                                                                                    $$->pointer = 1;
                                                                                                    strcpy($$->lexeme, $3.text);
                                                                                                    $$->children[0] = $6;
                                                                                                    $$->children[1] = $8;
                                                                                                    $$->children[0]->parent = $$;
                                                                                                    $$->children[1]->parent = $$;
                                                                                                    $$->symbolEntry = addSymbol($$, $$->lexeme, top(0));
                                                                                                    $$->symbolEntry->tx=++globaltx;
                                                                                                    $$->symbolEntry->child = top(0);
                                                                                                    top(0)->parent = $$->symbolEntry;
                                                                                                    $$->symbolEntry->codeStart = $8->codeStart;
                                                                                                    $$->codeStart = $8->codeStart;
                                                                                                    $$->codeEnd = $8->codeEnd;
                                                                                                    globalStructs[struct_head]->type=FUNCTION;
                                                                                                    globalStructs[struct_head]->id = $3.text;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    printf("Redeclaration of an identifier");
                                                                                                }
                                                                                            }
    |   Type IDENTIFIER '(' FuncScopeDummy  ')' FunctionBody                                {
                                                                                                pop();
                                                                                                if(findSymbol($2.text, stack_head, 0) == NULL)
                                                                                                {
//                                                                                                      $2->symbolEntry->child = $4->currentTable;
//                                                                                                      $4->currentTable->parent = $2->symbolEntry;
//                                                                                                      $$->currentTable = $4->currentTable;
                                                                                                    $$ = createNode(1);
                                                                                                    $$->basetype = $1->basetype;
                                                                                                    $$->function = 1;
                                                                                                    $$->pointer = 0;
                                                                                                    strcpy($$->lexeme, $2.text);
//                                                                                                     $$->children[0] = $5;
                                                                                                    $$->children[0] = $6;
                                                                                                    $$->children[0]->parent = $$;
//                                                                                                     $$->children[1]->parent = $$;
                                                                                                    $$->symbolEntry = addSymbol($$, $$->lexeme, top(0));
                                                                                                    $$->symbolEntry->tx=++globaltx;
                                                                                                    $$->symbolEntry->child = top(0);
                                                                                                    top(0)->parent = $$->symbolEntry;
                                                                                                    $$->symbolEntry->codeStart = $6->codeStart;
                                                                                                    $$->codeStart = $6->codeStart;
                                                                                                    $$->codeEnd = $6->codeEnd;
                                                                                                    globalStructs[struct_head]->type=FUNCTION;
                                                                                                    globalStructs[struct_head]->id = $2.text;
                                                                                                    globalStructs[struct_head]->node = NULL;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    printf("Redeclaration of an identifier");
                                                                                                }
                                                                                            }
    |   Type '*' IDENTIFIER '(' FuncScopeDummy ')' FunctionBody                             {
                                                                                                pop();
                                                                                                if(findSymbol($3.text, stack_head, 0) == NULL)
                                                                                                {
//                                                                                                      $3->symbolEntry->child = $5->currentTable;
//                                                                                                      $5->currentTable->parent = $3->symbolEntry;
//                                                                                                      $$->currentTable = $5->currentTable;
                                                                                                    $$ = createNode(1);
                                                                                                    $$->basetype = $1->basetype;
                                                                                                    $$->function = 1;
                                                                                                    $$->pointer = 1;
                                                                                                    strcpy($$->lexeme, $3.text);
//                                                                                                     $$->children[0] = $5;
                                                                                                    $$->children[0] = $7;
                                                                                                    $$->children[0]->parent = $$;
//                                                                                                     $$->children[1]->parent = $$;
                                                                                                    $$->symbolEntry = addSymbol($$, $$->lexeme, top(0));
                                                                                                    $$->symbolEntry->tx=++globaltx;
                                                                                                    $$->symbolEntry->child = top(0);
                                                                                                    top(0)->parent = $$->symbolEntry;
                                                                                                    $$->symbolEntry->codeStart = $7->codeStart;
                                                                                                    $$->codeStart = $7->codeStart;
                                                                                                    $$->codeEnd = $7->codeEnd;
                                                                                                    globalStructs[struct_head]->type=FUNCTION;
                                                                                                    globalStructs[struct_head]->id = $3.text;
                                                                                                    globalStructs[struct_head]->node = NULL;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    printf("Redeclaration of an identifier");
                                                                                                }
                                                                                            }
    ;

FuncScopeDummy:
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                        createStructEntry();
                                                    }//create new scope //keep in some stack
    ;

IfScopeDummy1:
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                    }//create new scope //keep in some stack
    ;

IfScopeDummy2:
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                    }//create new scope //keep in some stack
    ;

FunctionBody:
        BlockStatement                      {//DONE
                                                $$ = $1;
                                                //pop();
                                            }
    ;

BlockStatement:                             // sai check it. by sahu
        '{' '}'                             {
                                                    $$ = createNode(0);
                                                    strcpy($$->lexeme, "{ }");
//                                                  $$->basetype = 0;   
                                            }
    |   '{' StatementList '}'               {
                                                $$ = $2;
                                            }
    ;

AggregateDeclaration :
        StructDeclaration                   {//DONE
                                                $$ = $1;
                                            }
    ;

StructDeclaration   :
        STRUCT IDENTIFIER '{' StructScopeDummy VarDeclarationsList '}' ';'      {
                                                                                    // symbolTableEntry *id = findSymbol($2.text, stack_head, 0);
                                                                                    // if(id == NULL)
                                                                                    // {
                                                                                        $$ = createNode(1);
                                                                                        $$->children[0] = $5;
                                                                                        $$->children[0]->parent = $$;
                                                                                        strcpy($$->lexeme, ($2.text));
                                                                                        $$->structure = 1;
                                                                                        strcpy($$->structureName, $2.text);
                                                                                        globalStructs[struct_head]->type=STRUCT;
                                                                                        globalStructs[struct_head]->id = $2.text;
                                                                                    // }

                                                                                }
    ;

StructScopeDummy :
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        // push(createTable(NULL));
                                                        createStructEntry();
                                                        // codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                        // strcpy(nop->codeString, "nop");
                                                        // nop->numAddresses = 0;
                                                        // pushLoopEnd(nop);
                                                        // $$->codeStart = nop;
                                                        // $$->codeEnd = nop;
                                                    }//create new scope //keep in some stack
    ;

VarDeclarationsList     :
        Type IdentifierWithoutDot ';'                       {//DONE
                                                                $$ = $1;
                                                                createStructEntries($1,$2);
                                                            }
    |   Type IdentifierWithoutDot ';' VarDeclarationsList   {// Defined by Sahu in half neend. sai check it.
                                                                $$ = createNode(2);
                                                                strcpy($$->lexeme,"StructDef");
                                                                $$->children[0] = $1;
                                                                $$->children[1] = $2;
                                                                $$->children[0]->parent = $$;
                                                                $$->children[1]->parent = $$;
                                                                createStructEntries($1,$2);
                                                            }
    ;

VarDeclarationList     :
// Isko Type1 bhi kar sakte hai but functions hamara aray leta hai vaise but not from here
    Type Identifier                                     {
                                                            if(findSymbol($2->lexeme, 0, 1) == NULL)
                                                            {
                                                              $$ = createNode(2);
                                                              $$->children[0] = $1;
                                                              $$->children[1] = $2;
                                                              $2->basetype = $1->basetype;
                                                              $$->children[0]->parent = $$;
                                                              $$->children[1]->parent = $$;
                                                              $$->symbolEntry = addSymbol($2, $2->lexeme, top(0));
                                                              $$->symbolEntry->tx=++globaltx;
                                                              createEntries($2);
                                                            }
                                                            else
                                                            {
                                                              printf("Error: Redeclaration of the same variable");
                                                            }
                                                            
                                                        }
    |   Type Identifier ',' VarDeclarationList          {
                                                            if(findSymbol($2->lexeme, 0, 1) == NULL)
                                                            {
                                                              $$ = createNode(3);
                                                              $$->children[0] = $1;
                                                              $$->children[1] = $2;
                                                              $$->children[2] = $4;
                                                              $2->basetype = $1->basetype;
                                                              $$->children[0]->parent = $$;
                                                              $$->children[1]->parent = $$;
                                                              $$->children[2]->parent = $$;
                                                              $$->symbolEntry = addSymbol($2, $2->lexeme, top(0));
                                                              $$->symbolEntry->tx=++globaltx;
                                                              createEntries($2);
                                                            }
                                                            else
                                                            {
                                                              printf("Error: Redeclaration of the same variable");
                                                            }
                                                        }
    ;

AggregateBody:
       '{' DeclDefs '}'                                 {// Temporarily out of service
                                                            $$ = $2;
                                                        }
   |   '{' '}'                                          {// Temporarily out of service
                                                            $$ = createNode(0);
                                                            strcpy($$->lexeme, "{ }");
                                                        }
   ;

DeclDefs:
       DeclDef                              {//DONE
                                                $$ = $1;
                                            }
   |   DeclDef DeclDefs                     {
                                                $$ = createNode(2);
                                                $$->children[0] = $1;
                                                $$->children[1] = $2;
                                                $$->children[0]->parent = $$;
                                                $$->children[1]->parent = $$;
                                            }
   ;

DeclDef:
        Declaration                         {//DONE
                                                $$ = $1;
                                            }
    |   Constructor                         {//DONE
                                                $$ = $1;
                                            }
    |   Destructor                          {//DONE
                                                $$ = $1;
                                            }
    |   ';'                                 {//DONE
                                                $$ = createNode(0);
                                                strcpy($$->lexeme, ";");            // otherwise error will be produced
                                            }
    ;

Constructor :
        THIS '(' Shift ')' FunctionBody     {
                                                $$ = createNode(3);
                                            }
    ;

Destructor :
        '~' THIS '(' ')' FunctionBody       {
                                                $$ = createNode(3);
                                            }
    ;

StatementList:                              // Sai Check it. by sahu
        Statement                           {
                                                $$ = $1;
                                            }
    |   Statement StatementList             {
                                                if($1->basetype == 0)
                                                {
                                                  $$ = $2;
                                                }
                                                else
                                                {
                                                  $$ = createNode(2);
                                                  $$->children[0] = $1;
                                                  $$->children[1] = $2;
                                                  $1->parent = $$;
                                                  $2->parent = $$;

                                                  if($1->codeStart == NULL)
                                                    {
                                                        if($2->codeStart != NULL)
                                                        {    
                                                            $$->codeStart = $2->codeStart;
                                                            $$->codeEnd = $2->codeEnd;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        $$->codeStart = $1->codeStart;
                                                        if($2->codeStart == NULL)
                                                        {
                                                            $$->codeEnd = $1->codeEnd; 
                                                        }
                                                        else
                                                        {
                                                            $$->codeEnd = $2->codeEnd;
                                                            $1->codeEnd->next = $2->codeStart; 
                                                        }
                                                    } 
                                                }
                                            }
    ;

Statement:
        ';'                                 {
                                                $$ = createNode(0);
                                                strcpy($$->lexeme, ";");
                                                $$->basetype = 0;
                                            }
    |   NonEmptyStatement                   {
                                                $$ = $1;
                                            }
    ;

NonEmptyStatement:
        NonEmptyStatementNoCaseNoDefault    {
                                                $$ = $1;
                                            } 
    ;

NonEmptyStatementNoCaseNoDefault:
        LabeledStatement                    {
                                                $$ = $1;
                                            }
    |   ExpressionStatement                 {
                                                $$ = $1;
                                            }
    |   DeclarationStatement                {
                                                $$ = $1;
                                            }
    |   IfStatement                         {
                                                $$ = $1;
                                            }
    |   WhileStatement                      {
                                                $$ = $1;
                                            }
    |   DoStatement                         {
                                                $$ = $1;
                                            }
    |   ForStatement                        {
                                                $$ = $1;
                                            }
    |   SwitchStatement                     {
                                                $$ = $1;
                                            }
    |   ContinueStatement                   {
                                                $$ = $1;
                                            }
    |   BreakStatement                      {
                                                $$ = $1;
                                            }
    |   ReturnStatement                     {
                                                $$ = $1;
                                            }
    |   GotoStatement                       {
                                                $$ = $1;
                                            }
    ;

LabeledStatement    :
        IDENTIFIER ':' Statement            {
                                                if(findSymbol($1.text, 0, 0) == NULL)
                                                {
                                                    $$ = createNode(1);
                                                    strcpy($$->lexeme, ":");
    //                                                  $1 = createNode(0);
    //                                                  strcpy($1->lexeme, $1.text);
                                                    $$->children[0] = $3;
    //                                                  $$->children[1] = $3;
                                                    $$->children[0]->parent = $$;
    //                                                  $$->children[0]->parent = $$;
                                                    $$->symbolEntry = addSymbol($$, $1.text, top(0));
    //                                                 $$->symbolEntry->tx=++globaltx;
                                                    $$->symbolEntry->label = 1;
                                                    $$->symbolEntry->codeStart = $3->codeStart;
                                                }
                                                else
                                                {
                                                    printf("redeclaration of variable");
                                                }
                                            }
    ;

ExpressionStatement:                        // Sai check it. By sahu
        Expression ';'                                  {
                                                            $$ = $1;
                                                        }
    ;

Expression :
        ConditionalExpression                           {
                                                            $$ = $1;
                                                        }
    |   MulDivMod AssignmentOperator Expression         {
                                                            $$ = $2;
                                                            $$->children[0] = $1;
                                                            $$->children[1] = $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            //check operator, and hence check compatibility
                                                            int exptype; 
                                                            char *op;
                                                            char *s2=(char *)malloc(10*sizeof(char));
                                                            strcpy(s2, "t%d");
                                                            if(strcmp($2->lexeme, "=") == 0)
                                                            {
                                                                exptype = resulttype($1->basetype, $3->basetype, '=');
                                                                if(exptype != -1)
                                                                {
                                                                    $$->basetype = exptype;
                                                                    if($3->basetype != exptype)
                                                                        s2=conversionFunction(exptype, $3->basetype);
                                                                    codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                                    temp->tx1 = $1->tx;
                                                                    temp->tx2 = $3->tx;
                                                                    $$->tx = $1->tx;
                                                                    temp->numAddresses = 2;
                                                                    strcpy(temp->codeString, "t%d = ");
                                                                    strcat(temp->codeString, s2);
                                                                    if($1->codeStart != NULL)
                                                                    {
                                                                        $$->codeStart = $1->codeStart;
                                                                        if($3->codeStart != NULL)
                                                                        {
                                                                            $1->codeEnd->next = $3->codeStart;
                                                                            $3->codeEnd->next = temp;
                                                                        }
                                                                        else
                                                                            $1->codeEnd->next = temp;
                                                                    }
                                                                    else if($3->codeStart != NULL)
                                                                    {
                                                                        $$->codeStart = $3->codeStart;
                                                                        $3->codeEnd->next = temp;
                                                                    }
                                                                    else
                                                                        $$->codeStart = temp;
                                                                    $$->codeEnd = temp;
                                                                }
                                                            }
                                                            else 
                                                            {
                                                                if(strcmp($2->lexeme, "+=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, PLUS_EQ);
                                                                    op = typeOperator(exptype, PLUS_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "-=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, MIN_EQ);
                                                                    op = typeOperator(exptype, MIN_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "*=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, MULT_EQ);
                                                                    op = typeOperator(exptype, MULT_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "/=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, DIV_EQ);
                                                                    op = typeOperator(exptype, DIV_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "%=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, MOD_EQ);
                                                                    op = typeOperator(exptype, MOD_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != INT)
                                                                          s2=conversionFunction(INT, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "&=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, AND_EQ);
                                                                    op = typeOperator(exptype, AND_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "|=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, OR_EQ);
                                                                    op = typeOperator(exptype, OR_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "^=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, XOR_EQ);
                                                                    op = typeOperator(exptype, XOR_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != exptype)
                                                                          s2=conversionFunction(exptype, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "<<=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, LSHIFT_EQ);
                                                                    op = typeOperator(exptype, LSHIFT_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != INT)
                                                                          s2=conversionFunction(INT, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, ">>=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, RSHIFT_EQ);
                                                                    op = typeOperator(exptype, RSHIFT_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != INT)
                                                                          s2=conversionFunction(INT, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, ">>>=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, LOG_RSHIFT_EQ);
                                                                    op = typeOperator(exptype, LOG_RSHIFT_EQ);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != INT)
                                                                          s2=conversionFunction(INT, $3->basetype);
                                                                }
                                                                else if(strcmp($2->lexeme, "^^=") == 0)
                                                                {
                                                                    exptype = resulttype($1->basetype, $3->basetype, POW_EQ);
                                                                    op = typeOperator(exptype, POW);
                                                                    if(exptype != -1)
                                                                      if($3->basetype != INT)
                                                                          s2=conversionFunction(INT, $3->basetype);
                                                                }
                                                                if(exptype != -1)
                                                                {
                                                                    $$->basetype = exptype;
                                                                    codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                                    temp->tx1 = $1->tx;
                                                                    temp->tx2 = $1->tx;
                                                                    temp->tx3 = $3->tx;
                                                                    $$->tx = $1->tx;
                                                                    temp->numAddresses = 3;
                                                                    strcpy(temp->codeString, "t%d = t%d ");
                                                                    strcat(temp->codeString, op);
                                                                    strcat(temp->codeString, s2);
                                                                    if($1->codeStart != NULL)
                                                                    {
                                                                        $$->codeStart = $1->codeStart;
                                                                        if($3->codeStart != NULL)
                                                                        {
                                                                            $1->codeEnd->next = $3->codeStart;
                                                                            $3->codeEnd->next = temp;
                                                                        }
                                                                        else
                                                                            $1->codeEnd->next = temp;
                                                                    }
                                                                    else if($3->codeStart != NULL)
                                                                    {
                                                                        $$->codeStart = $3->codeStart;
                                                                        $3->codeEnd->next = temp;
                                                                    }
                                                                    else
                                                                        $$->codeStart = temp;
                                                                    $$->codeEnd = temp;
                                                                }
                                                            }   
                                                        }
    ;

ConditionalExpression :
        OrOrExpression      {//DONE
                                $$ = $1;
                            }
    |   OrOrExpression '?' Expression ':' ConditionalExpression     {
                                                                        int result = resulttype($3->basetype, $5->basetype, ':');
                                                                        // Check that the OrOrExpression is a BOOL expression if not error
                                                                        if(result != -1 && ($1->basetype == BOOL || implicitCompatible(INT,$1->basetype)))
                                                                        {
                                                                            $$->basetype = result;
                                                                            $$ = createNode(3);
                                                                            $$->children[0] = $1;
                                                                            strcpy($$->lexeme, "?");
                                                                            $$->children[1] = $3;
                                                                            $$->children[2] = $5;
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
                                                                            $$->children[2]->parent = $$;
                                                                            if($1->codeStart != NULL)
                                                                            {
                                                                                $$->codeStart = $1->codeStart;
                                                                                $$->codeEnd = $1->codeEnd;
                                                                            }
                                                                            if($3->codeStart != NULL)
                                                                            {
                                                                                if($$->codeStart == NULL)
                                                                                {
                                                                                    $$->codeStart = $3->codeStart;
                                                                                }
                                                                                else
                                                                                    $$->codeEnd->next = $3->codeStart;
                                                                                $$->codeEnd = $3->codeEnd;
                                                                            }

                                                                            if($5->codeStart != NULL)
                                                                            {
                                                                                if($$->codeStart == NULL)
                                                                                {
                                                                                    $$->codeStart = $5->codeStart;
                                                                                }
                                                                                else
                                                                                    $$->codeEnd->next = $5->codeStart;
                                                                                $$->codeEnd = $5->codeEnd;
                                                                            }
                                                                            $$->basetype = result;
                                                                            $$->tx = ++globaltx;
                                                                            codeList *temp1 = (codeList *)malloc(sizeof(codeList));
                                                                            temp1->tx1 = $1->tx;
                                                                            temp1->tx2 = $$->tx;
                                                                            temp1->tx3 = $3->tx;
                                                                            strcpy(temp1->codeString, "if(t%d) t%d = t%d");
                                                                            temp1->gotoStatement = 0;
                                                                            temp1->numAddresses = 3;
                                                                            codeList *temp2 = (codeList *)malloc(sizeof(codeList));
                                                                            temp2->tx1 = $1->tx;
                                                                            temp2->tx2 = $$->tx;
                                                                            temp2->tx3 = $5->tx;
                                                                            strcpy(temp2->codeString, "if(!t%d) t%d = t%d");
                                                                            temp2->gotoStatement = 0;
                                                                            temp2->numAddresses = 3;
                                                                            temp1->next = temp2;
                                                                            if($$->codeStart == NULL)
                                                                            {
                                                                                $$->codeStart = temp1;
                                                                            }
                                                                            else
                                                                                $$->codeEnd->next = temp1;
                                                                            $$->codeEnd = temp2;
                                                                            

                                                                        }
                                                                        else
                                                                        {
                                                                            printf("Error: Type Mismatch in Conditional expression\n");
                                                                        }
                                                                    }
    ;

OrOrExpression :
        AndAndExpression                        {//DONE
                                                    $$ = $1;
                                                }
    |   OrOrExpression OR_OR AndAndExpression   {
                                                    int result = resulttype($1->basetype, $3->basetype, OR_OR);
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "||");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

AndAndExpression :
        OrExpression                    {//DONE
                                            $$ = $1;
                                        }
    |   AndAndExpression AND_AND OrExpression   {
                                                    int result = resulttype($1->basetype, $3->basetype, AND_AND);
                                                
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "&&");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

OrExpression :
        XorExpression                   {//DONE
                                            $$ = $1;
                                        }
    |   OrExpression '|' XorExpression      {
                                                    int result = resulttype($1->basetype, $3->basetype, '|');
                                                
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "|");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

XorExpression :
        AndExpression                   {//DONE
                                            $$ = $1;
                                        }
    |   XorExpression '^' AndExpression         {
                                                    int result = resulttype($1->basetype, $3->basetype, '^');
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "^");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

AndExpression :
        EqualNotEqual               {//DONE
                                        $$ = $1;
                                    }
    |   AndExpression '&' EqualNotEqual         {
                                                    int result = resulttype($1->basetype, $3->basetype, '&');
                                                
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "&");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

EqualNotEqual :
        LtGtLteGte                      {//DONE
                                            $$ = $1;
                                        }
    |   EqualNotEqual EQ_EQ LtGtLteGte          {
                                                    int result = comparisontype($1->basetype, $3->basetype, EQ_EQ);
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = BOOL;
                                                        strcpy($$->lexeme, "==");
                                                      
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != result)
                                                          s1=conversionFunction(result, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "t%d");
                                                        if($3->basetype != result)
                                                          s2=conversionFunction(result, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        temp->tx1 = ++globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        $$->tx = globaltx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(result, EQ_EQ));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                          {
                                                              $$->codeStart = $1->codeStart;
                                                              if($3->codeStart != NULL)
                                                              {
                                                                  $1->codeEnd->next = $3->codeStart;
                                                                  $3->codeEnd->next = temp;
                                                              }
                                                              else
                                                                  $1->codeEnd->next = temp;
                                                          }
                                                          else if($3->codeStart != NULL)
                                                          {
                                                              $$->codeStart = $3->codeStart;
                                                              $3->codeEnd->next = temp;
                                                          }
                                                          else
                                                              $$->codeStart = temp;
                                                          $$->codeEnd = temp;
                                                      
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    |   EqualNotEqual NEQ LtGtLteGte            {
                                                    int result = comparisontype($1->basetype, $3->basetype, NEQ);
                                                
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = BOOL;
                                                        strcpy($$->lexeme, "!=");
                                                      
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != result)
                                                          s1=conversionFunction(result, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "t%d");
                                                        if($3->basetype != result)
                                                          s2=conversionFunction(result, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        temp->tx1 = ++globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        $$->tx = globaltx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(result, NEQ));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                          {
                                                              $$->codeStart = $1->codeStart;
                                                              if($3->codeStart != NULL)
                                                              {
                                                                  $1->codeEnd->next = $3->codeStart;
                                                                  $3->codeEnd->next = temp;
                                                              }
                                                              else
                                                                  $1->codeEnd->next = temp;
                                                          }
                                                          else if($3->codeStart != NULL)
                                                          {
                                                              $$->codeStart = $3->codeStart;
                                                              $3->codeEnd->next = temp;
                                                          }
                                                          else
                                                              $$->codeStart = temp;
                                                          $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

LtGtLteGte  :
        Shift                       {//DONE
                                        $$ = $1;
                                    }
    |   LtGtLteGte '<' Shift                    {
                                                    if($1->pointer == 1 || $3->pointer == 1)
                                                    {
                                                        printf("Error: Cannot compare addresses\n");
                                                    }
                                                    else
                                                    {
                                                        int result = comparisontype($1->basetype, $3->basetype, '<');
                                                        if(result != -1)
                                                        {
                                                            $$ = createNode(2);
                                                            $$->children[0] = $1;
                                                            $$->children[1] = $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            $$->basetype = BOOL;            // why are we doing this??
                                                            strcpy($$->lexeme, "<");
                                                            char *s1=(char *)malloc(10*sizeof(char));
                                                            strcpy(s1, "t%d");
                                                            if($1->basetype != result)
                                                              s1=conversionFunction(result, $1->basetype);
                                                            char *s2=(char *)malloc(10*sizeof(char));
                                                            strcpy(s2, "t%d");
                                                            if($3->basetype != result)
                                                              s2=conversionFunction(result, $3->basetype);
                                                            codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                            temp->tx1 = ++globaltx;
                                                            temp->tx2 = $1->tx;
                                                            temp->tx3 = $3->tx;
                                                            $$->tx = globaltx;
                                                            temp->numAddresses = 3;
                                                            strcpy(temp->codeString, "t%d = ");
                                                            strcat(temp->codeString, s1);
                                                            strcat(temp->codeString, "<");
                                                            strcat(temp->codeString, s2);
                                                            if($1->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $1->codeStart;
                                                                if($3->codeStart != NULL)
                                                                {
                                                                    $1->codeEnd->next = $3->codeStart;
                                                                    $3->codeEnd->next = temp;
                                                                }
                                                                else
                                                                    $1->codeEnd->next = temp;
                                                            }
                                                            else if($3->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                            printf("Type mismatch at < operator");
                                                            $$->basetype = -1;
                                                        }
                                                    }
        
                                                }
    |   LtGtLteGte '>' Shift                    {
                                                    if($1->pointer == 1 || $3->pointer == 1)
                                                    {
                                                        printf("Error: Cannot compare addresses\n");
                                                    }
                                                    else
                                                    {
                                                        int result = comparisontype($1->basetype, $3->basetype, '>');
                                                        if(result != -1)
                                                        {
                                                            $$ = createNode(2);
                                                            $$->children[0] = $1;
                                                            $$->children[1] = $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            $$->basetype = BOOL;            // why are we doing this??
                                                            strcpy($$->lexeme, ">");
                                                            char *s1=(char *)malloc(10*sizeof(char));
                                                            strcpy(s1, "t%d");
                                                            if($1->basetype != result)
                                                              s1=conversionFunction(result, $1->basetype);
                                                            char *s2=(char *)malloc(10*sizeof(char));
                                                            strcpy(s2, "t%d");
                                                            if($3->basetype != result)
                                                              s2=conversionFunction(result, $3->basetype);
                                                            codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                            temp->tx1 = ++globaltx;
                                                            temp->tx2 = $1->tx;
                                                            temp->tx3 = $3->tx;
                                                            $$->tx = globaltx;
                                                            temp->numAddresses = 3;
                                                            strcpy(temp->codeString, "t%d = ");
                                                            strcat(temp->codeString, s1);
                                                            strcat(temp->codeString, ">");
                                                            strcat(temp->codeString, s2);
                                                            if($1->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $1->codeStart;
                                                                if($3->codeStart != NULL)
                                                                {
                                                                    $1->codeEnd->next = $3->codeStart;
                                                                    $3->codeEnd->next = temp;
                                                                }
                                                                else
                                                                    $1->codeEnd->next = temp;
                                                            }
                                                            else if($3->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                            printf("Type mismatch at > operator");
                                                            $$->basetype = -1;
                                                        }
                                                    }
                                                }                 
    |   LtGtLteGte LEQ Shift                    {
                                                    if($1->pointer == 1 || $3->pointer == 1)
                                                    {
                                                        printf("Error: Cannot compare addresses\n");
                                                    }
                                                    else
                                                    {
                                                        int result = comparisontype($1->basetype, $3->basetype, LEQ);
                                                        if(result != -1)
                                                        {
                                                            $$ = createNode(2);
                                                            $$->children[0] = $1;
                                                            $$->children[1] = $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            $$->basetype = BOOL;            // why are we doing this??
                                                            strcpy($$->lexeme, "<=");
                                                            char *s1=(char *)malloc(10*sizeof(char));
                                                            strcpy(s1, "t%d");
                                                            if($1->basetype != result)
                                                              s1=conversionFunction(result, $1->basetype);
                                                            char *s2=(char *)malloc(10*sizeof(char));
                                                            strcpy(s2, "t%d");
                                                            if($3->basetype != result)
                                                              s2=conversionFunction(result, $3->basetype);
                                                            codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                            temp->tx1 = ++globaltx;
                                                            temp->tx2 = $1->tx;
                                                            temp->tx3 = $3->tx;
                                                            $$->tx = globaltx;
                                                            temp->numAddresses = 3;
                                                            strcpy(temp->codeString, "t%d = ");
                                                            strcat(temp->codeString, s1);
                                                            strcat(temp->codeString, "<=");
                                                            strcat(temp->codeString, s2);
                                                            if($1->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $1->codeStart;
                                                                if($3->codeStart != NULL)
                                                                {
                                                                    $1->codeEnd->next = $3->codeStart;
                                                                    $3->codeEnd->next = temp;
                                                                }
                                                                else
                                                                    $1->codeEnd->next = temp;
                                                            }
                                                            else if($3->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                            printf("Type mismatch at <= operator");
                                                            $$->basetype = -1;
                                                        }
                                                    }
                                                }
    |   LtGtLteGte GEQ Shift                    {
                                                    if($1->pointer == 1 || $3->pointer == 1)
                                                    {
                                                        printf("Error: Cannot compare addresses\n");
                                                    }
                                                    else
                                                    {
                                                        int result = comparisontype($1->basetype, $3->basetype, GEQ);
                                                        if(result != -1)
                                                        {
                                                            $$ = createNode(2);
                                                            $$->children[0] = $1;
                                                            $$->children[1] = $3;
                                                            $$->children[0]->parent = $$;
                                                            $$->children[1]->parent = $$;
                                                            $$->basetype = BOOL;            // why are we doing this??
                                                            strcpy($$->lexeme, ">=");
                                                            char *s1=(char *)malloc(10*sizeof(char));
                                                            strcpy(s1, "t%d");
                                                            if($1->basetype != result)
                                                              s1=conversionFunction(result, $1->basetype);
                                                            char *s2=(char *)malloc(10*sizeof(char));
                                                            strcpy(s2, "t%d");
                                                            if($3->basetype != result)
                                                              s2=conversionFunction(result, $3->basetype);
                                                            codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                            temp->tx1 = ++globaltx;
                                                            temp->tx2 = $1->tx;
                                                            temp->tx3 = $3->tx;
                                                            $$->tx = globaltx;
                                                            temp->numAddresses = 3;
                                                            strcpy(temp->codeString, "t%d = ");
                                                            strcat(temp->codeString, s1);
                                                            strcat(temp->codeString, ">=");
                                                            strcat(temp->codeString, s2);
                                                            if($1->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $1->codeStart;
                                                                if($3->codeStart != NULL)
                                                                {
                                                                    $1->codeEnd->next = $3->codeStart;
                                                                    $3->codeEnd->next = temp;
                                                                }
                                                                else
                                                                    $1->codeEnd->next = temp;
                                                            }
                                                            else if($3->codeStart != NULL)
                                                            {
                                                                $$->codeStart = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                            printf("Type mismatch at >= operator");
                                                            $$->basetype = -1;
                                                        }
                                                    }
                                                }
    ;

Shift   :
        PlusMinus                   {//DONE
                                        $$ = $1;
                                    }
    |   Shift LSHIFT PlusMinus                  {
                                                    int result = shifttype($1->basetype, $3->basetype, LSHIFT);
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, "<<");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    |   Shift RSHIFT PlusMinus                  {
                                                    int result = shifttype($1->basetype, $3->basetype, RSHIFT);
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, ">>");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    |   Shift LOG_RSHIFT PlusMinus              {
                                                    int result = shifttype($1->basetype, $3->basetype, LOG_RSHIFT);
                                                    if(result != -1)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = $1;
                                                        $$->children[1] = $3;
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->basetype = result;
                                                        strcpy($$->lexeme, ">>>");
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        strcpy(temp->codeString , "t%d = t%d ");
                                                        strcat(temp->codeString, $$->lexeme);
                                                        strcat(temp->codeString, " t%d");
                                                        temp->numAddresses = 3;
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = -1;
                                                        printf("Error: Type Mismatch\n");
                                                    }
                                                }
    ;

PlusMinus :
        MulDivMod               {//DONE
                                    $$ = $1;
                                }
      |   PlusMinus '+' MulDivMod               {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "+");
                                                    int exptype = resulttype($1->basetype, $3->basetype, '+');
                                                    if(exptype != -1)
                                                    {
                                                      $$->basetype = exptype;
                                                      char *s1=(char *)malloc(10*sizeof(char));
                                                      strcpy(s1, "t%d");
                                                      if($1->basetype != exptype)
                                                        s1=conversionFunction(exptype, $1->basetype);
                                                      char *s2=(char *)malloc(10*sizeof(char));
                                                      strcpy(s2, "t%d");
                                                      if($3->basetype != exptype)
                                                        s2=conversionFunction(exptype, $3->basetype);
                                                      codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                      temp->tx1 = ++globaltx;
                                                      temp->tx2 = $1->tx;
                                                      temp->tx3 = $3->tx;
                                                      $$->tx = globaltx;
                                                      temp->numAddresses = 3;
                                                      strcpy(temp->codeString, "t%d = ");
                                                      strcat(temp->codeString, s1);
                                                      strcat(temp->codeString, typeOperator(exptype, '+'));
                                                      strcat(temp->codeString, s2);
                                                      if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                      printf("Type mismatch at + operator");
                                                      $$->basetype = -1;
                                                    }
                                                    
                                                }
    |   PlusMinus '-' MulDivMod                 {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "-");
                                                    int exptype = resulttype($1->basetype, $3->basetype, '-');
                                                    if(exptype != -1)
                                                    {
                                                      $$->basetype = exptype;
                                                      char *s1=(char *)malloc(10*sizeof(char));
                                                      strcpy(s1, "t%d");
                                                      if($1->basetype != exptype)
                                                        s1=conversionFunction(exptype, $1->basetype);
                                                      char *s2=(char *)malloc(10*sizeof(char));
                                                      strcpy(s2, "t%d");
                                                      if($3->basetype != exptype)
                                                        s2=conversionFunction(exptype, $3->basetype);
                                                      codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                      temp->tx1 = ++globaltx;
                                                      temp->tx2 = $1->tx;
                                                      temp->tx3 = $3->tx;
                                                      $$->tx = globaltx;
                                                      temp->numAddresses = 3;
                                                      strcpy(temp->codeString, "t%d = ");
                                                      strcat(temp->codeString, s1);
                                                      strcat(temp->codeString, typeOperator(exptype, '-'));
                                                      strcat(temp->codeString, s2);
                                                      if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                    else
                                                    {
                                                      printf("Type mismatch at - operator");
                                                      $$->basetype = -1;
                                                    }
                                                    
                                                }
    ;

MulDivMod   :
        UnaryExpression                     {//DONE
                                                $$ = $1;
                                            }
    |   UnaryExpression PLUS_PLUS           {
                                                if(implicitCompatible(LONG, $1->basetype))
                                                {
                                                    {
                                                        $$=createNode(0);
                                                        $$->children[0] = $1;
                                                        $1->parent = $$;
                                                        strcpy($$->lexeme, "++");
                                                        int exptype = comparisontype($1->basetype, $1->basetype, '+');
                                                        if(exptype != -1)
                                                        {
                                                          $$->basetype = exptype;
                                                          char *s1=(char *)malloc(10*sizeof(char));
                                                          strcpy(s1, "t%d");
                                                          if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                          char *s2=(char *)malloc(10*sizeof(char));
                                                          strcpy(s2, "1");
                                                          codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                          temp->tx1 = ++globaltx;
                                                          temp->tx2 = $1->tx;
//                                                           temp->tx3 = $3->tx;
                                                          $$->tx = globaltx;
                                                          temp->numAddresses = 2;
                                                          strcpy(temp->codeString, "t%d = ");
                                                          strcat(temp->codeString, s1);
                                                          strcat(temp->codeString, typeOperator(exptype, '+'));
                                                          strcat(temp->codeString, s2);
                                                          if($1->codeStart != NULL)
                                                          {
                                                                $$->codeStart = $1->codeStart;
                                                                $1->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                          printf("Type mismatch at + operator");
                                                          $$->basetype = -1;
                                                        }

                                                    }
                                                }
                                                else
                                                {
                                                    printf("Incompatible operator and type\n");
                                                }
                                            }
    |   UnaryExpression MIN_MIN             {
                                                if(implicitCompatible(LONG, $1->basetype))
                                                {
                                                    {
                                                        $$=createNode(0);
                                                        $$->children[0] = $1;
                                                        $1->parent = $$;
                                                        strcpy($$->lexeme, "--");
                                                        int exptype = comparisontype($1->basetype, $1->basetype, '-');
                                                        if(exptype != -1)
                                                        {
                                                          $$->basetype = exptype;
                                                          char *s1=(char *)malloc(10*sizeof(char));
                                                          strcpy(s1, "t%d");
                                                          if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                          char *s2=(char *)malloc(10*sizeof(char));
                                                          strcpy(s2, "1");
                                                          codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                          temp->tx1 = ++globaltx;
                                                          temp->tx2 = $1->tx;
//                                                           temp->tx3 = $3->tx;
                                                          $$->tx = globaltx;
                                                          temp->numAddresses = 2;
                                                          strcpy(temp->codeString, "t%d = ");
                                                          strcat(temp->codeString, s1);
                                                          strcat(temp->codeString, typeOperator(exptype, '-'));
                                                          strcat(temp->codeString, s2);
                                                          if($1->codeStart != NULL)
                                                          {
                                                                $$->codeStart = $1->codeStart;
                                                                $1->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $$->codeStart = temp;
                                                            $$->codeEnd = temp;
                                                        }
                                                        else
                                                        {
                                                          printf("Type mismatch at - operator");
                                                          $$->basetype = -1;
                                                        }

                                                    }
                                                }
                                                else
                                                {
                                                    printf("Incompatible operator and type\n");
                                                }
                                            }
    |   MulDivMod '*' UnaryExpression       {   
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "*");
                                                    char operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '*');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot multiply incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(exptype, '*'));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    |   MulDivMod '/' UnaryExpression           {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "/");
                                                    char s1[40] = "t%d " ,s2[40] = "t%d ", operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '/');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot divide incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(exptype, '/'));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    |   MulDivMod '%' UnaryExpression           {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "%");
                                                    char s1[40] = "t%d " ,s2[40] = "t%d ", operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '%');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot mod incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, "%");
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    |   PointerExpression                       {
                                                    $$ = $1;
                                                }
    |   MulDivMod '*' PointerExpression         {   
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "*");
                                                    char operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '*');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot multiply incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "*t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(exptype, '*'));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    |   MulDivMod '/' PointerExpression         {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "/");
                                                    char s1[40] = "t%d " ,s2[40] = "t%d ", operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '/');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot divide incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "*t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, typeOperator(exptype, '/'));
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    |   MulDivMod '%' PointerExpression         {
                                                    $$=createNode(2);
                                                    $$->children[0] = $1;
                                                    $$->children[1] = $3;
                                                    $1->parent = $$;
                                                    $3->parent = $$;
                                                    strcpy($$->lexeme, "%");
                                                    char s1[40] = "t%d " ,s2[40] = "t%d ", operator[10];
                                                    int exptype = resulttype($1->basetype, $3->basetype, '%');
                                                    if(exptype == -1)
                                                    {
                                                      printf("Cannot mod incompatible types %d and %d", $1->basetype, $3->basetype);
                                                      $$->basetype = -1;
                                                    }
                                                    else
                                                    {
                                                        $$->basetype = exptype;
                                                        char *s1=(char *)malloc(10*sizeof(char));
                                                        strcpy(s1, "t%d");
                                                        if($1->basetype != exptype)
                                                            s1=conversionFunction(exptype, $1->basetype);
                                                        char *s2=(char *)malloc(10*sizeof(char));
                                                        strcpy(s2, "*t%d");
                                                        if($3->basetype != exptype)
                                                            s2=conversionFunction(exptype, $3->basetype);
                                                        codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                        $$->tx = ++globaltx;
                                                        temp->tx1 = globaltx;
                                                        temp->tx2 = $1->tx;
                                                        temp->tx3 = $3->tx;
                                                        temp->numAddresses = 3;
                                                        strcpy(temp->codeString, "t%d = ");
                                                        strcat(temp->codeString, s1);
                                                        strcat(temp->codeString, "%");
                                                        strcat(temp->codeString, s2);
                                                        if($1->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $1->codeStart;
                                                            if($3->codeStart != NULL)
                                                            {
                                                                $1->codeEnd->next = $3->codeStart;
                                                                $3->codeEnd->next = temp;
                                                            }
                                                            else
                                                                $1->codeEnd->next = temp;
                                                        }
                                                        else if($3->codeStart != NULL)
                                                        {
                                                            $$->codeStart = $3->codeStart;
                                                            $3->codeEnd->next = temp;
                                                        }
                                                        else
                                                            $$->codeStart = temp;
                                                        $$->codeEnd = temp;
                                                    }
                                                }
    ;

UnaryExpression     :
        MainExpression                      {//DONE
                                                $$ = $1;
                                            }
    |   UnaryOperator UnaryExpression       {
                                                if($2->pointer == 1 || $2->arraydimension != 0)
                                                {
                                                    printf("Arrays and pointers are not allowed in this position\n");
                                                }
                                                else
                                                {
                                                    if((!strcmp($1->lexeme, "+") || !strcmp($1->lexeme, "-")) && implicitCompatible(DOUBLE, $2->basetype))
                                                    {
                                                        if( ( (!strcmp($1->lexeme, "!") || !strcmp($1->lexeme, "~")) && implicitCompatible(INT, $2->basetype) )|| $2->basetype == BOOL)
                                                        {
                                                            if(( !strcmp($1->lexeme, "++") || !strcmp($1->lexeme, "--")) && implicitCompatible(LONG, $2->basetype))
                                                            {
                                                                if(!strcmp($1->lexeme, "&"))
                                                                {
                                                                    $$->pointer = 1;
                                                                }
                                                                $$ = createNode(1);
                                                                $$->children[0] = $2;
                                                                $$->children[0]->parent = $$;
                                                                strcpy($$->lexeme, $1->lexeme);
                                                            }
                                                            else
                                                            {
                                                                printf("Error: operator not compatible with type\n");
                                                            }
                                                        }
                                                        else
                                                        {
                                                            printf("Error: operator not compatible with type\n");
                                                        }
                                                    }
                                                    else
                                                    {
                                                        printf("Error: operator not compatible with type\n");
                                                    }
                                                }
                                            }
    |   UnaryOperator PointerExpression     {
                                        // pointerExpression me thora type checking ho chuka hai
                                                $$=  createNode(1);
                                                $$->children[0] = $2;
                                                $$->children[0]->parent = $$;
                                                strcpy($$->lexeme, $1->lexeme);
                                            }
    |   SIZEOF '(' Type ')'                 {
                                                $$ = createNode(2);
                                                $$->children[0] = createNode(0);
                                                strcpy($$->children[0]->lexeme, $1.text);
                                                $$->children[1] = $3;
                                                $$->children[0]->parent = $$;
                                                $$->children[1]->parent = $$;
                                            }
    ;
     
PointerExpression   :
        '*' UnaryExpression                 {
                                                if($2->pointer != 1 || $2->arraydimension != 0)
                                                {
                                                    printf("Arrays and non-pointers are not allowed in this position\n");
                                                }
                                                else
                                                {
                                                    $$=createNode(1);
                                                    $$->children[0] = $2;
                                                    $2->parent = $$;
                                                    $$->tx = ++globaltx;
                                                    strcpy($$->lexeme, "*");
                                                    $$->basetype = $2->basetype;
                                                    $$->pointer = 0;

                                                    codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                    temp->tx1 = $$->tx;
                                                    temp->tx2 = $2->tx;
                                                    strcpy(temp->codeString, "t%d = load(t%d);");

                                                    $$->codeEnd = temp;
                                                    if($2->codeStart != NULL)
                                                    {
                                                        $$->codeStart = $2->codeStart;
                                                        $2->codeEnd->next = temp;
                                                    }
                                                    else
                                                        $$->codeStart = temp;
                                                }
                                            }
                                        
    ;

UnaryOperator   :
        '+'                     {
                                    $$ = createNode(0);
//                                     $$->basetype = '+';
                                    strcpy($$->lexeme, "+");
                                }
    |   '-'                     {
                                    $$ = createNode(0);
//                                     $$->basetype = '-';
                                    strcpy($$->lexeme, "-");
                                }
    |   '!'                     {
                                    $$ = createNode(0);
//                                     $$->basetype = '!';
                                    strcpy($$->lexeme, "!");
                                }
    |   '~'                     {
                                    $$ = createNode(0);
//                                     $$->basetype = '~';
                                    strcpy($$->lexeme,"~");
                                }
    |   '&'                     {
                                    $$ = createNode(0);
//                                     $$->basetype = '&';
                                    strcpy($$->lexeme, "&");
                                }
    |   PLUS_PLUS               {
                                    $$ = createNode(0);
//                                     $$->basetype = PLUS_PLUS;
                                    strcpy($$->lexeme, $1.text);
                                }
    |   MIN_MIN                 {
                                    $$ = createNode(0);
//                                     $$->basetype = MIN_MIN;
                                    strcpy($$->lexeme, $1.text);
                                }
    ;
MainExpression  :
        Starting                            {//DONE
                                                $$ = $1;
                                            }
    |   IDENTIFIER ArraySuffixes            {
                                                symbolTableEntry *id = findSymbol($1.text, 0, 0);
                                                if( id != NULL && id-> pointer == 0 && id->arraydimension == $2->arraydimension)
                                                {
                                                    $$ = createNode(1);
                                                    $$->children[0] = $2;
                                                    $$->children[0]->parent = $$;
                                                    strcpy($$->lexeme, $1.text);
                                                    $$->pointer = 0;
                                                    $$->arraydimension = 0;
                                                    int i = 0;
                                                    $$->basetype = id->basetype;

                                                    codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                    temp->tx1 = ++globaltx;
                                                    temp->tx2 = $2->dim[id->arraydimension -1] ;
                                                    temp->gotoStatement = 0;
                                                    temp->numAddresses = 2;
                                                    strcpy(temp->codeString, " t%d = t%d");
                                                    $$->dim[id->arraydimension - 1] = $2->dim[id->arraydimension - 1];
                                                    if($2->codeStart != NULL)
                                                    {
                                                        $$->codeStart = $2->codeStart;
                                                        $2->codeEnd->next = temp;
                                                    }
                                                    else
                                                        $$->codeStart = temp;
                                                    $$->codeEnd = temp;
                                                    for(i = id->arraydimension - 2; i>=0; i--)
                                                    {
                                                        $$->dim[i] = $2->dim[i];
                                                        codeList *temp1 = (codeList *)malloc(sizeof(codeList));
                                                        temp1->tx1 = ++globaltx;
                                                        temp1->tx2 = globaltx - 1;
                                                        strcpy(temp1->codeString, "t%d = t%d * ");
                                                        char *s = (char *)malloc(10*sizeof(char));
                                                        snprintf(s, 10, "%d", id->dim[i+1]);
                                                        strcat(temp1->codeString, s);
                                                        temp1->gotoStatement = 0;
                                                        temp1->numAddresses = 2;
                                                        $$->codeEnd->next = temp1;
                                                        $$->codeEnd = temp1;
                                                        codeList *temp2 = (codeList *)malloc(sizeof(codeList));
                                                        temp2->tx1 = ++globaltx;
                                                        temp2->tx2 = globaltx - 1;
                                                        temp2->tx3 = $2->dim[i];
                                                        strcpy(temp2->codeString, "t%d = t%d + t%d");
                                                        temp2->gotoStatement = 0;
                                                        temp2->numAddresses = 3;
                                                        $$->codeEnd->next = temp2;
                                                        $$->codeEnd = temp2;
                                                    }
                                                    codeList *temp4 = (codeList *)malloc(sizeof(codeList));
                                                    temp4->tx1 = ++globaltx;
                                                    temp4->tx2 = globaltx - 1;
                                                    snprintf(temp4->codeString, 50, "t%%d = t%%d + address(%s)", $1.text);
                                                    temp4->gotoStatement = 0;
                                                    temp4->numAddresses = 2;
                                                    $$->codeEnd->next = temp4;
                                                    $$->codeEnd = temp4;
                                                    $$->function = 0;
                                                    $$->address = 1;
                                                    codeList *temp3 = (codeList *)malloc(sizeof(codeList));
                                                    temp3->tx1 = ++globaltx;
                                                    temp3->tx2 = globaltx - 1;
                                                    strcpy(temp3->codeString, "t%d = memory(t%d)");
                                                    temp3->gotoStatement = 0;
                                                    temp3->numAddresses = 2;
                                                    $$->codeEnd->next = temp3;
                                                    $$->codeEnd = temp3;
                                                    $$->tx = globaltx;
                                                }
                                                else
                                                {
                                                    printf("Error Variable not found or the array types are different\n");
                                                }
                                            }
    |   IDENTIFIER '(' ')'                  {
                                                symbolTableEntry *id= findSymbol($1.text, stack_head, 0);
                                                if( id != NULL && id->function == 1)
                                                {
//                                                   Check that the variable is a function(done) and the number of arguments accepted are also same and also in the same form
                                                    int accept = checkFuncList($1.text, NULL);
                                                    if(accept)
                                                    {
                                                        $$ = createNode(1);
                                                        $$->children[0] = createNode(0);
                                                        strcpy($$->children[0]->lexeme, $1.text);
                                                        $$->children[0]->parent = $$;
                                                        $$->pointer = 0;
                                                        $$->arraydimension = 0;
                                                        int i = 0;
                                                        for(i = 0; i < 10; ++i)
                                                        {
                                                            $$->dim[i] = 0;
                                                        }
                                                        $$->function = 0;
                                                        codeList *funcCall = (codeList *)malloc(sizeof(codeList));
                                                        funcCall->gotoAddress = id->codeStart;
                                                        funcCall->gotoStatement = 1;
                                                        strcpy(funcCall->codeString, "call %d");
                                                        funcCall->numAddresses = 0;
                                                        $$->codeStart = funcCall;
                                                        if(id->basetype != VOID)
                                                        {
                                                            codeList *ret = (codeList *)malloc(sizeof(codeList));
                                                            ret->tx1 = ++globaltx;
                                                            $$->tx = globaltx;
                                                            $$->basetype = id->basetype;
                                                            strcpy(ret->codeString, "t%d = return");
                                                            ret->numAddresses = 1;
                                                            funcCall->next = ret;
                                                            $$->codeEnd = ret;
                                                        }
                                                        else
                                                        {
                                                            $$->basetype = -1;
                                                            $$->codeEnd = funcCall;
                                                        }
                                                    }
                                                    else
                                                        printf("Check failed\n");
                                                }
                                                else
                                                {
                                                    printf("Error Function %s not found", $1.text);
                                                }
                                            }
    |   IDENTIFIER '(' ExpressionList ')'       {
                                                    symbolTableEntry *id = findSymbol($1.text, stack_head, 0);
                                                    if(id != NULL)
                                                    {
//                                                   Check that the variable is a function and the number of arguments accepted are also same and also in the same form
                                                    int accept = checkFuncList($1.text, $3);
                                                    if(accept)
                                                    {
                                                        $$ = createNode(2);
                                                        $$->children[0] = createNode(0);
                                                        $$->children[1] = $3;
                                                        strcpy($$->children[0]->lexeme, $1.text);
                                                        $$->children[0]->parent = $$;
                                                        $$->children[1]->parent = $$;
                                                        $$->pointer = 0;
                                                        $$->arraydimension = 0;
                                                        int i = 0;
                                                        for(i = 0; i < 10; ++i)
                                                        {
                                                          $$->dim[i] = 0;
                                                        }
                                                        $$->function = 0;
                                                        codeList *funcCall = (codeList *)malloc(sizeof(codeList));
                                                        funcCall->gotoAddress = id->codeStart;
                                                        funcCall->gotoStatement = 1;
                                                        strcpy(funcCall->codeString, "call %d");
                                                        funcCall->numAddresses = 0;
                                                        $$->codeStart = $3->codeStart;
                                                        $3->codeEnd->next = funcCall;
                                                        if(id->basetype != VOID)
                                                        {
                                                            codeList *ret = (codeList *)malloc(sizeof(codeList));
                                                            ret->tx1 = ++globaltx;
                                                            $$->tx = globaltx;
                                                            $$->basetype = id->basetype;
                                                            strcpy(ret->codeString, "t%d = return");
                                                            ret->numAddresses = 1;
                                                            funcCall->next = ret;
                                                            $$->codeEnd = ret;
                                                        }
                                                        else
                                                        {
                                                            $$->basetype = -1;
                                                            $$->codeEnd = funcCall;
                                                        }
                                                    }  
                                                    else
                                                        printf("Check failed\n");
                                                  }
                                                  else
                                                  {
                                                    printf("Error Function %s not found", $1.text);
                                                  }
                                              }
    |   IDENTIFIER '.' MainExpression           {
                                                    symbolTableEntry *id = findSymbol(strcat($1.text, strcat(".", $3->lexeme)), 0, 0);
                                                    if(id == NULL)
                                                    {
                                                        printf("ERROR: Variable not found");
                                                    }
                                                    else
                                                    {
                                                        $$ = createNode(0);
                                                        strcpy($$->lexeme, id->name);
                                                        $$->basetype = id->basetype;
                                                        $$->pointer = id->pointer;
                                                        $$->arraydimension = id->arraydimension;
                                                        $$->function = id->function;
                                                        strcpy($$->structureName, id->structureName);
                                                        $$->structure = id->structure;
                                                        int i = 0;
                                                        for (i = 0; i < 10; ++i)
                                                        {
                                                            $$->dim[i] = id->dim[i];
                                                        }
                                                        $$->tx = id->tx;
                                                        strcpy($$->lexeme, strcat($1.text, strcat(".", $3->lexeme)));
                                                    }

                                                }
   // |   IDENTIFIER ArraySuffixes '.' MainExpression     
    //                                             {
    //                                                 symbolTableEntry *id = findSymbol(strcat($1.text, strcat(".", $3->lexeme)), 0, 0);
    //                                                 if(id == NULL)
    //                                                 {
    //                                                     printf("ERROR: Variable not found");
    //                                                 }
    //                                                 else
    //                                                 {
    //                                                     $$ = id;
    //                                                     strcpy($$->lexeme, strcat($1->lexeme, strcat(".", $3->lexeme)));
    //                                                 }

    //                                             }
    ;

ArraySuffixes :
        ArraySuffix                         {
                                                $$ = $1;
                                            }
    |   ArraySuffix ArraySuffixes           {
                                                $$ = createNode(0);
                                                $$->arraydimension = $2->arraydimension + 1;
                                                strcpy($$->lexeme, "[]");
                                                int i = 0;
                                                for(i = 0; i < 10;i++)
                                                {
                                                    $$->dim[i] = $2->dim[i];
                                                }
                                                $$->dim[$$->arraydimension - 1] = $1->dim[0];
                                                if($1->codeStart == NULL)
                                                {
                                                    if($2->codeStart != NULL)
                                                    {
                                                        $$->codeStart = $2->codeStart;
                                                        $$->codeEnd = $2->codeEnd;
                                                    }
                                                }
                                                else
                                                {
                                                    $$->codeStart = $1->codeStart;
                                                    if($2->codeStart == NULL)
                                                    {
                                                        $$->codeEnd = $1->codeEnd; 
                                                    }
                                                    else
                                                    {
                                                        $$->codeEnd = $2->codeEnd;
                                                        $1->codeEnd->next = $2->codeStart; 
                                                    }
                                                }
                                                
                                            }
    ;

ArraySuffix : 
        '['Expression']'                    {
                                                $$ = $2;
                                                $$->dim[0] = $2->tx;
                                                $$->arraydimension = 1;
                                            }
    ;

ExpressionList  :
        Expression                          {
                                                $$ = $1;
                                                if($1->basetype != -1)
                                                {
                                                    codeList *parameter = (codeList *)malloc(sizeof(codeList));
                                                    parameter->tx1 = $1->tx;
                                                    strcpy(parameter->codeString, "param t%d");
                                                    parameter->numAddresses = 1;
                                                    if($1->codeStart == NULL)
                                                    {
                                                        $$->codeStart = parameter;
                                                        $$->codeEnd = parameter;
                                                    }
                                                    else
                                                    {
                                                        $$->codeEnd->next = parameter;
                                                        $$->codeEnd = parameter;
                                                    }
                                                }
                                                

                                            }
    |   ExpressionList ',' Expression       {
                                                $$ = createNode(2);
                                                $$->children[0] = $1; $$->children[1] = $3;
                                                $1->parent = $$; $3->parent = $$;
                                                strcpy($$->lexeme,",");
                                                if($3->basetype != -1)
                                                {
                                                    codeList *parameter = (codeList *)malloc(sizeof(codeList));
                                                    parameter->tx1 = $3->tx;
                                                    strcpy(parameter->codeString, "param t%d");
                                                    parameter->numAddresses = 1;
                                                    $$->codeStart = $1->codeStart;
                                                    if($3->codeStart != NULL)
                                                    {
                                                        $1->codeEnd->next = $3->codeStart;
                                                        $3->codeEnd->next = parameter;
                                                    }
                                                    else
                                                        $1->codeEnd->next = parameter;
                                                    $$->codeEnd = parameter;
                                                }
                                            }
    ;

Starting    :
        IDENTIFIER                  {
                                        symbolTableEntry *identifier = findSymbol($1.text, 0, 0);
                                        if(identifier != NULL)
                                        { 
                                          $$ = createNode(0);
                                          $$->basetype = identifier->basetype;
                                          $$->pointer=identifier->pointer;
                                          $$->arraydimension = identifier->arraydimension;
                                          int i;
                                          for (i =0 ; i< 10; i++){
                                            $$->dim[i] = identifier->dim[i];
                                          }
                                          strcpy($$->lexeme, $1.text);
                                          $$->tx = identifier->tx;
                                          $$->symbolEntry = identifier;
                                          $$->codeStart = NULL;
                                          $$->codeEnd = NULL;
                                        }
                                    }
    |   INT_LIT                     {//DONE//DONE Prateek
                                        $$ = createNode(0);
                                        int length = strlen($1.text);
                                        if($1.text[length-1] == 'u' || $1.text[length-1] == 'U')
                                            if($1.text[length-2] == 'l' || $1.text[length-2] == 'L')
                                            {   
                                                $$->basetype = ULONG;
                                                $1.text[length-2] = '\0';
                                            }
                                            else
                                            {   
                                                $$->basetype = UINT;
                                                $1.text[length-1] = '\0';
                                            }
                                        else if($1.text[length-1] == 'l' || $1.text[length-1] == 'L')
                                            if($1.text[length-2] == 'u' || $1.text[length-2] == 'U')
                                            {   
                                                $$->basetype = ULONG;
                                                $1.text[length-2] = '\0';
                                            }
                                            else
                                            {   
                                                $$->basetype = LONG;
                                                $1.text[length-1] = '\0';
                                            }
                                        else
                                            $$->basetype = $1.type;
                                        strcpy($$->lexeme,$1.text);
      
                                        $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                        $$->codeEnd = $$->codeStart;
                                        $$->codeStart->tx1 = ++globaltx;
                                        $$->codeStart->numAddresses = 1;
                                        $$->codeStart->next = NULL;
                                        
                                        strcpy($$->codeStart->codeString, "t%d =");
                                        strcat($$->codeStart->codeString, $1.text);
                                        $$->tx = $$->codeStart->tx1;
                                    }
    |   FLOAT_LIT                     {//DONE//DONE Prateek
                                        $$ = createNode(0);
                                        int length = strlen($1.text);
                                        if($1.text[length-1] == 'f' || $1.text[length-1] == 'F')
                                        {   
                                            $$->basetype = $1.type;
                                            $1.text[length-1] = '\0';
                                        }
                                        else
                                            $$->basetype = DOUBLE;
                                        strcpy($$->lexeme,$1.text);
      
                                        $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                        $$->codeEnd = $$->codeStart;
                                        $$->codeStart->tx1 = ++globaltx;
                                        $$->codeStart->numAddresses = 1;
                                        $$->codeStart->next = NULL;
                                        
                                        strcpy($$->codeStart->codeString, "t%d =");
                                        strcat($$->codeStart->codeString, $1.text);
                                        $$->tx = $$->codeStart->tx1;
                                    }
    |   STRING_LIT                  {
                                        $$ = createNode(0);
                                        $$->basetype = $1.type;
                                        strcpy($$->lexeme,$1.text);
                                    }
    |   CHAR_LIT                    {//DONE//DONE Prateek
                                        $$ = createNode(0);
                                        $$->basetype = $1.type;
                                        strcpy($$->lexeme,$1.text);
      
                                        $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                        $$->codeEnd = $$->codeStart;
                                        $$->codeStart->tx1 = ++globaltx;
                                        $$->codeStart->numAddresses = 1;
                                        $$->codeStart->next = NULL;
                                        
                                        strcpy($$->codeStart->codeString, "t%d =");
                                        strcat($$->codeStart->codeString, $1.text);
                                        $$->tx = $$->codeStart->tx1;
                                    }
    |   TRUE                        {//DONE//DONE Prateek
                                        $$ = createNode(0);
                                        $$->basetype = BOOL;
                                        strcpy($$->lexeme,$1.text);
      
                                        $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                        $$->codeEnd = $$->codeStart;
                                        $$->codeStart->tx1 = ++globaltx;
                                        $$->codeStart->numAddresses = 1;
                                        $$->codeStart->next = NULL;
                                        
                                        strcpy($$->codeStart->codeString, "t%d =");
                                        strcat($$->codeStart->codeString, $1.text);
                                        $$->tx = $$->codeStart->tx1;
                                    }
    |   FALSE                       {//DONE//DONE Prateek
                                        $$ = createNode(0);
                                        $$->basetype = BOOL;
                                        strcpy($$->lexeme,$1.text);
      
                                        $$->codeStart = (codeList *)malloc(sizeof(codeList));
                                        $$->codeEnd = $$->codeStart;
                                        $$->codeStart->tx1 = ++globaltx;
                                        $$->codeStart->numAddresses = 1;
                                        $$->codeStart->next = NULL;
                                        
                                        strcpy($$->codeStart->codeString, "t%d =");
                                        strcat($$->codeStart->codeString, $1.text);
                                        $$->tx = $$->codeStart->tx1;
                                    }
    |   '(' Expression ')'          {
                                        $$=$2;
                                    }
    ;

AssignmentOperator  :
        '='                             {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,"=");
                                        }
    |   PLUS_EQ                         {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   MIN_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   MULT_EQ                         {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   DIV_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   MOD_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   AND_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   OR_EQ                           {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   XOR_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   INV_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   LSHIFT_EQ                       {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   RSHIFT_EQ                       {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   LOG_RSHIFT_EQ                   {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    |   POW_EQ                          {   
                                          $$ = createNode(2);
                                          strcpy($$->lexeme,$1.text);
                                        }
    ;

DeclarationStatement    :
       Declaration                         {
                                                $$ = $1;
                                            }
    ;

IfStatement     :
        IF '(' Expression ')' IfScopeDummy1 BlockStatement              {
                                                                            $$ = createNode(2);    //Changed from 3 children to 2
                                                                            //$$->children[0] = createNode(0);
                                                                            strcpy($$->lexeme, $1.text);
                                                                            //$$->children[0]->parent = $$;
                                                                            $$->children[0] = $3;
                                                                            $$->children[1] = $6;
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
                                                                            pop();
                                                                            if($6->codeStart != NULL && ($3->basetype == BOOL || implicitCompatible($3->basetype, INT)))
                                                                            {
                                                                                codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                                                strcpy(nop->codeString, "nop");
                                                                                codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                ifcode->tx1 = $3->tx;
                                                                                ifcode->gotoStatement = 1;
                                                                                ifcode->numAddresses = 1;
                                                                                ifcode->gotoAddress = nop;
                                                                                strcpy(ifcode->codeString, "if(!t%d) goto %d");
                                                                                if($3->codeStart != NULL)
                                                                                {
                                                                                    $$->codeStart = $3->codeStart;
                                                                                    $3->codeEnd->next = ifcode;
                                                                                }
                                                                                else
                                                                                    $$->codeStart = ifcode;
                                                                                ifcode->next = $6->codeStart;
                                                                                $6->codeEnd->next = nop;
                                                                                $$->codeEnd = nop;
                                                                            }
                                                                        }
    |   IF '(' Expression ')' IfScopeDummy1 BlockStatement IfEndScopeDummy ELSE IfScopeDummy2 BlockStatement    {
                                                                                        $$ = createNode(3); //5 to 2 children
                                                                                        //$$->children[0] = createNode(0);
                                                                                        strcpy($$->lexeme, strcat($1.text,$8.text));
                                                                                        //$$->children[0]->parent = $$;
                                                                                        $$->children[0] = $3;
                                                                                        $$->children[1] = $6;
                                                                                        //$$->children[3] = createNode(0);
                                                                                        $$->children[2] = $10;
                                                                                        //strcpy($$->children[3]->lexeme, $$7.text);
                                                                                        $$->children[0]->parent = $$;
                                                                                        $$->children[1]->parent = $$;
                                                                                        $$->children[2]->parent = $$;
                                                                                        //$$->children[4]->parent = $$;
                                                                                        pop();
                                                                                        if($6->codeStart != NULL || $10->codeStart != NULL && ($3->basetype == BOOL || implicitCompatible($3->basetype, INT)))
                                                                                        {
                                                                                            codeList *nop = (codeList *)malloc(sizeof(codeList));
                                                                                            strcpy(nop->codeString, "nop");
                                                                                            codeList *gotoThen = (codeList *)malloc(sizeof(codeList));
                                                                                            gotoThen->numAddresses=0;
                                                                                            gotoThen->gotoStatement = 1;
                                                                                            gotoThen->gotoAddress = nop;
                                                                                            strcpy(gotoThen->codeString , "goto %d");
                                                                                            codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                            ifcode->tx1 = $3->tx;
                                                                                            ifcode->gotoStatement = 1;
                                                                                            ifcode->numAddresses = 1;
                                                                                            strcpy(ifcode->codeString, "if(!t%d) goto %d");
                                                                                            if($3->codeStart != NULL)
                                                                                            {
                                                                                                $$->codeStart = $3->codeStart;
                                                                                                $3->codeEnd->next = ifcode;
                                                                                            }
                                                                                            else
                                                                                                $$->codeStart = ifcode;
                                                                                            if($6->codeStart != NULL)
                                                                                            {
                                                                                                ifcode->next = $6->codeStart;
                                                                                                $6->codeEnd->next = gotoThen;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                ifcode->next = gotoThen;
                                                                                            }
                                                                                            if($10->codeStart != NULL)
                                                                                            {
                                                                                                ifcode->gotoAddress = $10->codeStart;
                                                                                                gotoThen->next = $10->codeStart;
                                                                                                $10->codeEnd->next = nop;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                ifcode->gotoAddress = nop;
                                                                                                gotoThen->next = nop;
                                                                                            }
                                                                                            $$->codeEnd = nop;
                                                                                        }
         ;                                                                           }
IfEndScopeDummy : 
                                                                               {
                                                                                 pop();
                                                                               }
    ;
WhileStatement  :
        WHILE '(' WhileScopeDummy Expression ')' BlockStatement         {
                                                                            $$ = createNode(2); //5 to 2 children
                                                                            //$$->children[0] = createNode(0);
                                                                            strcpy($$->lexeme, $1.text);
                                                                            //$$->children[0]->parent = $$;
                                                                            $$->children[0] = $4;
                                                                            $$->children[1] = $6;
                                                                            //$$->children[3] = createNode(0);
//                                                                             $$->children[2] = $10;
                                                                            //strcpy($$->children[3]->lexeme, $$7.text);
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
//                                                                             $$->children[2]->parent = $$;
                                                                            //$$->children[4]->parent = $$;
                                                                            pop();
                                                                            popLoopEnd();
                                                                            if($6->codeStart != NULL && ($4->basetype == BOOL || implicitCompatible($4->basetype, INT)))
                                                                            {
                                                                                codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                ifcode->tx1 = $4->tx;
                                                                                ifcode->gotoStatement = 1;
                                                                                ifcode->numAddresses = 1;
                                                                                ifcode->gotoAddress = $3->codeStart;
                                                                                strcpy(ifcode->codeString, "if(!t%d) goto %d");
                                                                                codeList *gotoexp = (codeList *)malloc(sizeof(codeList));
                                                                                gotoexp->numAddresses=0;
                                                                                gotoexp->gotoStatement = 1;
                                                                                strcpy(gotoexp->codeString , "goto %d");
                                                                                if($4->codeStart != NULL)
                                                                                {
                                                                                    gotoexp->gotoAddress = $4->codeStart;
                                                                                    $$->codeStart = $4->codeStart;
                                                                                    $4->codeEnd->next = ifcode;
                                                                                }
                                                                                else
                                                                                {
                                                                                    gotoexp->gotoAddress = ifcode;
                                                                                    $$->codeStart = ifcode;
                                                                                }
                                                                                ifcode->next = $6->codeStart;
                                                                                $6->codeEnd->next = gotoexp;
                                                                                gotoexp->next = $3->codeStart;
                                                                                $$->codeEnd = $3->codeStart;
                                                                            }
                                                                        }
    ;

WhileScopeDummy :
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                        codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                        strcpy(nop->codeString, "nop");
                                                        nop->numAddresses = 0;
                                                        pushLoopEnd(nop);
                                                        $$->codeStart = nop;
                                                        $$->codeEnd = nop;
                                                    }//create new scope //keep in some stack
    ;

DoScopeDummy :
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                        codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                        strcpy(nop->codeString, "nop");
                                                        nop->numAddresses = 0;
                                                        pushLoopEnd(nop);
                                                        $$->codeStart = nop;
                                                        $$->codeEnd = nop;
                                                    }//create new scope //keep in some stack
    ;

ForScopeDummy :
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        $$ = createNode(0);
                                                        push(createTable(NULL));
                                                        codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                        strcpy(nop->codeString, "nop");
                                                        nop->numAddresses = 0;
                                                        pushLoopEnd(nop);
                                                        $$->codeStart = nop;
                                                        $$->codeEnd = nop;
                                                    }//create new scope //keep in some stack
    ;

DoStatement     :
        DO DoScopeDummy BlockStatement WHILE '(' Expression ')' ';'     {
                                                                            $$ = createNode(2); //5 to 2 children
                                                                            //$$->children[0] = createNode(0);
                                                                            strcpy($$->lexeme, strcat($1.text, $4.text));
                                                                            //$$->children[0]->parent = $$;
                                                                            $$->children[0] = $3;
                                                                            $$->children[1] = $6;
                                                                            //$$->children[3] = createNode(0);
//                                                                             $$->children[2] = $10;
                                                                            //strcpy($$->children[3]->lexeme, $$7.text);
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
//                                                                             $$->children[2]->parent = $$;
                                                                            //$$->children[4]->parent = $$;
                                                                            pop();
                                                                            popLoopEnd();
                                                                            if($3->codeStart != NULL && ($6->basetype == BOOL || implicitCompatible($6->basetype, INT)))
                                                                            {
                                                                                codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                ifcode->tx1 = $6->tx;
                                                                                ifcode->gotoStatement = 1;
                                                                                ifcode->numAddresses = 1;
                                                                                ifcode->gotoAddress = $3->codeStart;
                                                                                strcpy(ifcode->codeString, "if(t%d) goto %d");
                                                                                $$->codeStart = $3->codeStart;
                                                                                $$->codeEnd = ifcode;
                                                                                if($6->codeStart != NULL)
                                                                                {
                                                                                    $3->codeEnd->next = $6->codeEnd->next;
                                                                                    $6->codeEnd->next = ifcode;
                                                                                }
                                                                                else
                                                                                {
                                                                                    $3->codeEnd->next = ifcode;
                                                                                }
                                                                                $$->codeEnd->next = $2->codeStart;
                                                                                $$->codeEnd = $2->codeStart;
                                                                            }
                                                                        }
    ;

ForStatement    :
        FOR '(' ForScopeDummy Initialize Initialize ')' BlockStatement              {
                                                                            $$ = createNode(3); //5 to 2 children
                                                                            //$$->children[0] = createNode(0);
                                                                            strcpy($$->lexeme, $1.text);
                                                                            //$$->children[0]->parent = $$;
                                                                            $$->children[0] = $4;
                                                                            $$->children[1] = $5;
                                                                            $$->children[2] = $7;
                                                                            //$$->children[3] = createNode(0);
//                                                                             $$->children[2] = $10;
                                                                            //strcpy($$->children[3]->lexeme, $$7.text);
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
                                                                            $$->children[2]->parent = $$;
//                                                                             $$->children[2]->parent = $$;
                                                                            //$$->children[4]->parent = $$;
                                                                            pop();
                                                                            popLoopEnd();
                                                                            if($7->codeStart != NULL && ($5->basetype == BOOL || implicitCompatible($5->basetype, INT)))
                                                                            {
                                                                                codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                codeList *gotoexp2 = (codeList *)malloc(sizeof(codeList));
                                                                                ifcode->tx1 = $5->tx;
                                                                                ifcode->gotoAddress = $3->codeStart;
                                                                                ifcode->gotoStatement = 1;
                                                                                ifcode->numAddresses =1;
                                                                                strcpy(ifcode->codeString, "if(!t%d) goto %d ");
                                                                                //
                                                                                gotoexp2->gotoStatement = 1;
                                                                                strcpy(gotoexp2->codeString, "goto %d");
                                                                                gotoexp2->numAddresses = 0;
                                                                                if($4->codeStart != NULL)
                                                                                {
                                                                                    $$->codeStart = $4->codeStart;
                                                                                    if($5->codeStart != NULL)
                                                                                    {
                                                                                        $4->codeEnd->next = $5->codeStart;
                                                                                        gotoexp2->gotoAddress = $5->codeStart;
                                                                                        $5->codeEnd->next = ifcode;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        $4->codeEnd->next = ifcode;
                                                                                        gotoexp2->gotoAddress = ifcode;
                                                                                    }
                                                                                }
                                                                                else
                                                                                {

                                                                                    if($5->codeStart != NULL)
                                                                                    {
                                                                                        $$->codeStart = $5->codeStart;
                                                                                        gotoexp2->gotoAddress = $5->codeStart;
                                                                                        $5->codeEnd->next = ifcode;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        $$->codeStart = ifcode;
                                                                                        gotoexp2->gotoAddress = ifcode;
                                                                                    }   
                                                                                }
                                                                                ifcode->next = $7->codeStart;
                                                                                $7->codeEnd->next = gotoexp2;
                                                                                gotoexp2->next = $3->codeStart;
                                                                                $$->codeEnd = $3->codeStart;
                                                                                
                                                                            }
                                                                        }
    |   FOR '(' ForScopeDummy Initialize Initialize Expression ')' BlockStatement                         {
                                                                            $$ = createNode(4); //5 to 2 children
                                                                            //$$->children[0] = createNode(0);
                                                                            strcpy($$->lexeme, $1.text);
                                                                            //$$->children[0]->parent = $$;
                                                                            $$->children[0] = $4;
                                                                            $$->children[1] = $5;
                                                                            $$->children[2] = $6;
                                                                            $$->children[3] = $8;
                                                                            //$$->children[3] = createNode(0);
//                                                                             $$->children[2] = $10;
                                                                            //strcpy($$->children[3]->lexeme, $$7.text);
                                                                            $$->children[0]->parent = $$;
                                                                            $$->children[1]->parent = $$;
                                                                            $$->children[2]->parent = $$;
                                                                            $$->children[3]->parent = $$;
//                                                                             $$->children[2]->parent = $$;
                                                                            //$$->children[4]->parent = $$;
                                                                            pop();
                                                                            popLoopEnd();
                                                                            if($8->codeStart != NULL && ($5->basetype == BOOL || implicitCompatible($5->basetype, INT)))
                                                                            {
                                                                                codeList *ifcode = (codeList *)malloc(sizeof(codeList));
                                                                                codeList *gotoexp2 = (codeList *)malloc(sizeof(codeList));
                                                                                ifcode->tx1 = $5->tx;
                                                                                ifcode->gotoAddress = $3->codeStart;
                                                                                ifcode->gotoStatement = 1;
                                                                                ifcode->numAddresses =1;
                                                                                strcpy(ifcode->codeString, "if(!t%d) goto %d ");
                                                                                //
                                                                                gotoexp2->gotoStatement = 1;
                                                                                strcpy(gotoexp2->codeString, "goto %d");
                                                                                gotoexp2->numAddresses = 0;
                                                                                if($4->codeStart != NULL)
                                                                                {
                                                                                    $$->codeStart = $4->codeStart;
                                                                                    if($5->codeStart != NULL)
                                                                                    {
                                                                                        $4->codeEnd->next = $5->codeStart;
                                                                                        gotoexp2->gotoAddress = $5->codeStart;
                                                                                        $5->codeEnd->next = ifcode;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        $4->codeEnd->next = ifcode;
                                                                                        gotoexp2->gotoAddress = ifcode;
                                                                                    }
                                                                                }
                                                                                else
                                                                                {

                                                                                    if($5->codeStart != NULL)
                                                                                    {
                                                                                        $$->codeStart = $5->codeStart;
                                                                                        gotoexp2->gotoAddress = $5->codeStart;
                                                                                        $5->codeEnd->next = ifcode;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        $$->codeStart = ifcode;
                                                                                        gotoexp2->gotoAddress = ifcode;
                                                                                    }   
                                                                                }
                                                                                ifcode->next = $8->codeStart;
                                                                                if($6->codeStart != NULL)
                                                                                {
                                                                                    $8->codeEnd->next = $6->codeStart;
                                                                                    $6->codeEnd->next = gotoexp2;
                                                                                }
                                                                                else
                                                                                {
                                                                                    $8->codeEnd->next = gotoexp2;
                                                                                }
                                                                                gotoexp2->next =  $3->codeStart;
                                                                                $$->codeEnd =  $3->codeStart;
                                                                                
                                                                            }
                                                                        }
    ;

Initialize  :
        ';'                                     { 
                                                    $$ = createNode(0); 
                                                    $$->basetype = BOOL;
                                                    $$->tx = ++globaltx;
                                                    codeList *temp = (codeList *)malloc(sizeof(codeList));
                                                    $$->codeStart= temp;
                                                    $$->codeEnd=temp;
                                                    temp->tx1=$$->tx;
                                                    strcpy(temp->codeString, "t%d = TRUE");
                                                    temp->numAddresses = 1;
                                                }
    |   ExpressionStatement                     { $$ = $1;}
    ;

ContinueStatement   :
         CONTINUE ';'                        {
                                                $$ = createNode(0);
                                                strcpy($$->lexeme, $1.text);
                                            }
    ;

BreakStatement  :
       BREAK ';'                           {
                                                $$ = createNode(0);
                                                strcpy($$->lexeme, $1.text);
                                            }
    ;

ReturnStatement:
        RETURN Expression ';'               {
                                                $$ = createNode(1);
                                                $$->children[0] = $2;
//                                                  $$->children[1] = createNode(0);
                                                $$->children[0]->parent = $$;
//                                                  $$->children[1]->parent = $$;
                                                strcpy($$->lexeme, $1.text);
//                                                  strcpy($$->children[1]->lexeme, $2.text);
                                                codeList *ret = (codeList *)malloc(sizeof(codeList));
                                                ret->numAddresses = 1;
                                                ret->tx1 = $2->tx;
                                                ret->gotoStatement = 0;
                                                strcpy(ret->codeString, "return t%d");
                                                if($2->codeStart != NULL)
                                                {
                                                    $$->codeStart = $2->codeStart;
                                                    $2->codeEnd->next = ret;
                                                }
                                                else
                                                    $$->codeStart = ret;
                                                $$->codeEnd = ret;
                                            }
    |   RETURN ';'                          {
                                                $$ = createNode(0);
                                                strcpy($$->lexeme, $1.text);
                                                codeList *ret = (codeList *)malloc(sizeof(codeList));
                                                ret->numAddresses = 0;
                                                strcpy(ret->codeString, "return");
                                                $$->codeStart = ret;
                                                $$->codeEnd = ret;
                                            }
    ;

GotoStatement:
        GOTO IDENTIFIER ';'                 {
                                                symbolTableEntry *id = findSymbol($2.text, 0, 0);
                                                if(id != NULL && id->label == 1)
                                                {
                                                    $$ = createNode(2);
                                                    $$->children[0] = createNode(0);
                                                    $$->children[1] = createNode(0);
                                                    $$->children[0]->parent = $$;
                                                    $$->children[1]->parent = $$;
                                                    strcpy($$->children[0]->lexeme, $1.text);
                                                    strcpy($$->children[1]->lexeme, $2.text);
                                                }
                                            }
    ;  

SwitchStatement:
        SWITCH SwitchDummy '(' Expression ')' '{' CaseDefaultStatement '}'
                                            {
                                                $$ = createNode(2);
                                                popLoopEnd();
                                                if($7 != NULL)
                                                {
                                                    //create code for expression
                                                    caseList *defaultCase = NULL;

                                                    caseList *temp = $7->thisCase;
                                                    while(temp != NULL)
                                                    {
                                                        if(temp->starting == NULL)
                                                            defaultCase = temp;
                                                        else
                                                        {
                                                            $$->basetype = resulttype($4->basetype, temp->starting->basetype, EQ_EQ);
                                                            if($$->basetype != -1)
                                                            {
                                                                //comparison node
                                                                codeList *comparison = (codeList *)malloc(sizeof(codeList));
                                                                comparison->tx1 = ++globaltx;
                                                                comparison->tx2 = $4->tx;
                                                                comparison->tx3 = temp->starting->tx;
                                                                char s1[50] = "t%d";
                                                                char s2[50] = "t%d";
                                                                if($$->basetype != $4->basetype)
                                                                    strcpy(s1, conversionFunction($$->basetype, $4->basetype));
                                                                if($$->basetype != temp->starting->basetype)
                                                                    strcpy(s2, conversionFunction($$->basetype, temp->starting->basetype));
                                                                strcpy(comparison->codeString, "t%d = ");
                                                                strcat(comparison->codeString, s1);
                                                                strcat(comparison->codeString, " == ");
                                                                strcat(comparison->codeString, s2);
                                                                comparison->gotoStatement = 0;
                                                                comparison->numAddresses = 3;
                                                                //goto node
                                                                codeList *gotoNode = (codeList *)malloc(sizeof(codeList));
                                                                gotoNode->gotoStatement = 1;
                                                                gotoNode->numAddresses = 1;
                                                                gotoNode->tx1 = comparison->tx1;
                                                                strcpy(gotoNode->codeString, "if(t%d) goto %d");
                                                                gotoNode->gotoAddress = temp->codeStart;
                                                                comparison->next = gotoNode;
                                                                //add nodes to current
                                                                if(temp->starting->codeStart != NULL)
                                                                {
                                                                    if($$->codeStart != NULL)
                                                                    {
                                                                        $$->codeEnd->next = temp->starting->codeStart;
                                                                        $$->codeEnd = temp->starting->codeStart;
                                                                    }
                                                                    else
                                                                    {
                                                                        $$->codeStart = temp->starting->codeStart;
                                                                        $$->codeEnd = temp->starting->codeEnd;
                                                                    }
                                                                }
                                                                if($$->codeStart != NULL)
                                                                    $$->codeEnd->next = comparison;
                                                                else
                                                                    $$->codeStart = comparison;
                                                                $$->codeEnd = gotoNode;
                                                            }
                                                            else
                                                                printf("Incompatible types in case statement\n");

                                                        }
                                                        temp = temp->next;
                                                    }

                                                    if(defaultCase != NULL)
                                                    {
                                                        //create empty goto statement to next 
                                                        codeList *Defgoto = (codeList *)malloc(sizeof(codeList));
                                                        Defgoto->gotoStatement = 1;
                                                        Defgoto->gotoAddress = defaultCase->codeStart;
                                                        Defgoto->numAddresses = 0;
                                                        strcpy(Defgoto->codeString, "goto %d");
                                                        if($$->codeStart == NULL)
                                                            $$->codeStart = Defgoto;
                                                        else
                                                            $$->codeEnd->next = Defgoto;
                                                        $$->codeEnd = Defgoto;
                                                    } 
                                                    $$->codeEnd->next = $7->statementsASTnode->codeStart;
                                                    $$->codeEnd = $7->statementsASTnode->codeEnd;
                                                    $$->codeEnd->next = $2->codeStart;
                                                    $$->codeEnd = $2->codeStart;

                                                }

                                            }
;

CaseDefaultStatement : 
        CaseStatement                                               {
                                                                        $$ = $1;
                                                                    }
    |   DefaultStatement                                            {
                                                                        $$ = $1;
                                                                    }
    |   CaseStatement CaseDefaultStatement                          {
                                                                        if($2 != NULL)
                                                                        {
                                                                            $$= createCaseNode(2);
                                                                            $$->statementsASTnode->children[0] = $1->statementsASTnode;
                                                                            $$->statementsASTnode->children[1] = $2->statementsASTnode;
                                                                            $$->statementsASTnode->children[0]->parent = $$->statementsASTnode;
                                                                            $$->statementsASTnode->children[1]->parent = $$->statementsASTnode;
                                                                            //manage $$->statementsASTnode code
                                                                            $$->statementsASTnode->codeStart = $1->statementsASTnode->codeStart;
                                                                            $1->statementsASTnode->codeEnd->next = $2->statementsASTnode->codeStart;
                                                                            $$->statementsASTnode->codeEnd = $2->statementsASTnode->codeEnd;
                                                                            $$->hasDefault = $2->hasDefault;
                                                                            //manage thiscase
                                                                            $$->thisCase = $1->thisCase;
                                                                            $$->thisCase->next = $2->thisCase; 
                                                                        }
                                                                        
                                                                    }
    |   DefaultStatement CaseDefaultStatement                       {
                                                                        if($2->hasDefault == 1)
                                                                        {
                                                                            printf("Cannot have more than one default statement\n");
                                                                            $$ = NULL;
                                                                        }
                                                                        else if($2 != NULL)
                                                                        {
                                                                            $$= createCaseNode(2);
                                                                            $$->statementsASTnode->children[0] = $1->statementsASTnode;
                                                                            $$->statementsASTnode->children[1] = $2->statementsASTnode;
                                                                            $$->statementsASTnode->children[0]->parent = $$->statementsASTnode;
                                                                            $$->statementsASTnode->children[1]->parent = $$->statementsASTnode;
                                                                            //manage $$->statementsASTnode code
                                                                            $$->statementsASTnode->codeStart = $1->statementsASTnode->codeStart;
                                                                            $1->statementsASTnode->codeEnd->next = $2->statementsASTnode->codeStart;
                                                                            $$->statementsASTnode->codeEnd = $2->statementsASTnode->codeEnd;
                                                                            $$->hasDefault = $2->hasDefault;
                                                                            //manage thiscase
                                                                            $$->thisCase = $1->thisCase;
                                                                            $$->thisCase->next = $2->thisCase;
                                                                        
                                                                        }   
                                                                    }
    ;

CaseStatement:
    CASE Starting ':' CaseStatementDummy StatementListNoCaseNoDefault   {
                                                                            $$= createCaseNode(2);
                                                                            $$->statementsASTnode->children[0] = $2;
                                                                            $$->statementsASTnode->children[1] = $5;
                                                                            $$->statementsASTnode->children[0]->parent = $$->statementsASTnode;
                                                                            $$->statementsASTnode->children[1]->parent = $$->statementsASTnode;
                                                                            strcpy($$->statementsASTnode->lexeme, "CASE :");
                                                                            $$->thisCase->starting = $2;
                                                                            $$->hasDefault = 0;
                                                                            if($5->codeStart != NULL)
                                                                            {
                                                                                //$$ code management, possibly basetype
                                                                                $$->statementsASTnode->codeStart = $5->codeStart;
                                                                                $$->statementsASTnode->codeEnd = $5->codeEnd;
                                                                                $$->thisCase->codeStart = $$->statementsASTnode->codeStart;
                                                                            }
                                                                            else
                                                                            {
                                                                                //create empty goto statement to next 
                                                                                codeList *gotoNext = (codeList *)malloc(sizeof(codeList));
                                                                                gotoNext->gotoStatement = 1;
                                                                                gotoNext->gotoAddress = NULL;
                                                                                gotoNext->numAddresses = 0;
                                                                                $$->statementsASTnode->codeStart = gotoNext;
                                                                                $$->statementsASTnode->codeEnd = gotoNext;

                                                                            }
                                                                            $$->thisCase->codeStart = $$->statementsASTnode->codeStart;
                                                                        }
;
DefaultStatement:
        DEFAULT ':' CaseStatementDummy StatementListNoCaseNoDefault {
                                                                            $$= createCaseNode(1);
                                                                            $$->statementsASTnode->children[0] = $4;
                                                                            $$->statementsASTnode->children[0]->parent = $$->statementsASTnode;
                                                                            strcpy($$->statementsASTnode->lexeme, "DEFAULT :");
                                                                            $$->hasDefault = 1;
                                                                            if($4->codeStart != NULL)
                                                                            {
                                                                                //$$ code management, possibly basetype
                                                                                $$->statementsASTnode->codeStart = $4->codeStart;
                                                                                $$->statementsASTnode->codeEnd = $4->codeEnd;
                                                                                $$->thisCase->codeStart = $$->statementsASTnode->codeStart;
                                                                            }
                                                                            else
                                                                            {
                                                                                //create empty goto statement to next 
                                                                                codeList *gotoNext = (codeList *)malloc(sizeof(codeList));
                                                                                gotoNext->gotoStatement = 1;
                                                                                gotoNext->gotoAddress = NULL;
                                                                                gotoNext->numAddresses = 0;
                                                                                $$->statementsASTnode->codeStart = gotoNext;
                                                                                $$->statementsASTnode->codeEnd = gotoNext;

                                                                            }
                                                                            $$->thisCase->codeStart = $$->statementsASTnode->codeStart;
                                                                        }
;

CaseStatementDummy :
                                                    {
                                                      // decide how to create a new symbol table and store the previous symbol table and also take the global variables
                                                        //$$ = createNode(0);
                                                        push(createTable(NULL));
                                                    }
        ;

SwitchDummy:        
                                                    {
                                                        $$ = createNode(0);
                                                        codeList *nop  = (codeList *)malloc(sizeof(codeList));
                                                        strcpy(nop->codeString, "nop");
                                                        nop->numAddresses = 0;
                                                        pushLoopEnd(nop);
                                                        $$->codeStart = nop;
                                                        $$->codeEnd = nop;
                                                    }
;

StatementListNoCaseNoDefault:
        StatementNoCaseNoDefault                                    {
                                                                        $$ = $1;
                                                                    }
    |   StatementNoCaseNoDefault StatementListNoCaseNoDefault       {
                                                                        $$= createNode(2);
                                                                        $$->children[0] = $1;
                                                                        $$->children[1] = $2;
                                                                        $$->children[0]->parent = $$;
                                                                        $$->children[1]->parent = $$;
                                                                        if($1->codeStart == NULL)
                                                                        {
                                                                            if($2->codeStart != NULL)
                                                                            {
                                                                                $$->codeStart = $2->codeStart;
                                                                                $$->codeEnd = $2->codeEnd;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            $$->codeStart = $1->codeStart;
                                                                            if($2->codeStart == NULL)
                                                                            {
                                                                                $$->codeEnd = $1->codeEnd; 
                                                                            }
                                                                            else
                                                                            {
                                                                                $$->codeEnd = $2->codeEnd;
                                                                                $1->codeEnd->next = $2->codeStart; 
                                                                            }
                                                                        } 
                                                                    }
;
StatementNoCaseNoDefault:
        ';'                                 {
                                                $$ = createNode(0);
                                                $$->basetype = 0;
                                                strcpy($$->lexeme, ";");
                                            }
    |   NonEmptyStatementNoCaseNoDefault    {
                                                $$ = $1;
                                            }
    |   BlockStatement                      {
                                                $$ = $1;
                                            }
;
%%
int main (int argc, char*argv[]) {
    /* init symbol table */
    int i;
    for(i=0; i<100; i++) {
        stack[i]=0;
    }
    FILE *err = fopen("error", "w");
    fclose(err);
    //yydebug = 1;
    yyin = fopen(argv[1], "r");

    
    globalSymbolTable = (symbolTable *)malloc(sizeof(symbolTable));
    globalSymbolTable->parent = NULL;
    globalSymbolTable->entries = (symbolTableEntry *)malloc(100*sizeof(symbolTableEntry));
    globalSymbolTable->numberEntries = 0;
    push(globalSymbolTable);

    yyparse ();
    assignLineNumber(codeStart);
    fixDanglingGoto(codeStart);
    //search for main, check for type
    symbolTableEntry *mainEntry =findSymbol("main", 0, 0); 
    //parse until first function
    int count=0, firstFunctionIndex=1;
    for(i=0;i<globalSymbolTable->numberEntries;i++)
    {
        if(globalSymbolTable->entries[i].function == 1)
        {
            if(count == 0)
                firstFunctionIndex = globalSymbolTable->entries[i].codeStart->lineno;
            else if(globalSymbolTable->entries[i].codeStart->lineno < firstFunctionIndex)
                firstFunctionIndex = globalSymbolTable->entries[i].codeStart->lineno;
            count++;
        }
    }
    if(mainEntry == NULL || mainEntry->codeStart == NULL)
        printf("No main defined\n");
    else
    {
        codeList *temp = codeStart;
        codeList *gotoCode = (codeList *)malloc(sizeof(codeList));
        gotoCode->gotoAddress = mainEntry->codeStart;
        gotoCode->gotoStatement = 1;
        strcpy(gotoCode->codeString, "goto %d");
        gotoCode->numAddresses = 0;
        if(firstFunctionIndex == 1)
        {
            gotoCode->next = codeStart;
            codeStart = gotoCode;
        }   
        else
        {
            while(temp != NULL && temp->lineno < firstFunctionIndex-1)
                temp=temp->next;
            gotoCode->next = temp->next;
            temp->next = gotoCode;
        } 
    }
    //insert goto main in front

    assignLineNumber(codeStart);    //Do not remove
    printCode(codeStart);
    fclose(yyin);
}
void yyerror (char *s) 
{
    FILE *err = fopen("error", "a");
    //fprintf (err, "%s\n", s);
    fprintf (err, "error at line %d\n", yylineno);
    fclose(err);
} 