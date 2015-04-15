#include <stdio.h>
typedef struct symbolTable symbolTable;
typedef struct symbolTableEntry symbolTableEntry;
typedef struct ASTnode ASTnode;
typedef struct codeList codeList;
typedef struct fieldEntry fieldEntry;
typedef struct fields fields;
typedef struct evalExp evalExp;
typedef struct ASTCaseNode ASTCaseNode;  
typedef struct caseList caseList;
typedef struct arrayDimList arrayDimList;

extern symbolTable * stack[]; 
extern int stack_head;
extern int globaltx;
extern fields * globalStructs[];
extern int struct_head;
extern codeList *loopEndStack[];
extern int loopEndStackHead;
extern arrayDimList *arrayList;

struct arrayDimList
{
	int tx;
	arrayDimList *next;
};

struct caseList
{
	ASTnode *starting;
	codeList *codeStart;
	caseList *next;
};

struct symbolTable
{
	//pointer to parent
	symbolTableEntry *parent;

	//list of entries
	 symbolTableEntry *entries;
	int numberEntries;

};

struct symbolTableEntry
{
	/* data */
	char name[50];

	int size;		//size of variable
	int offset;		//offset from beginning

	int basetype;
	int pointer;
	int arraydimension;
	int function;
  	int structure;
  	char structureName[50];

	int dim[10];		//list/array of array dimensions

  	int tx;
  	int label;
  	struct codeList *codeStart;
	// void value;

	//pointer to child
	 symbolTable *child;

	 symbolTable *current;
};

struct codeList
{
  	int lineno;
	int tx1;
  	int tx2;
  	int tx3;
  	codeList *gotoAddress;
  	int gotoStatement;
  	char codeString[50];
  	int numAddresses;
	codeList *next;
};

struct fields
{
  int type;
  char *id;
  fieldEntry *node;
};

struct fieldEntry
{
  int type;
  char *id;
  int pointer;
  int arraydimension;
  int dim[10];
  fieldEntry *next;
};

struct ASTnode
{
	char lexeme[50];
	
	//int intval;
	//float floatval;
	int basetype;		// Sai: I have used -1 for none of the defined types
	int pointer;
	int arraydimension;
	int dim[10];
	int function;
  	int structure;
	int address;
  	char structureName[50];
	codeList *codeStart;
  	codeList *codeEnd;
    int tx;

	 symbolTableEntry *symbolEntry;
//	 symbolTable *currentTable;
	 ASTnode **children;
  	 int noChildren;
	 ASTnode *parent;

};

struct ASTCaseNode
{
	ASTnode *statementsASTnode;
	caseList *thisCase;
	int hasDefault;
};

struct evalExp
{
  	int val;
  	int err;
};

ASTnode * createNode(int n);

ASTCaseNode * createCaseNode(int n);

symbolTable * createTable( symbolTableEntry *parent);

symbolTableEntry *findSymbol(char *id, int n, int ownScope);

codeList * setType(ASTnode *node, int type);
	
symbolTableEntry * addSymbol(ASTnode *symbol, char *id, symbolTable * currentSymbolTable);

void printCode(codeList * start);

void push(symbolTable *newSymbolTable);

symbolTable *pop();

symbolTable * top(int n);

int resulttype(int type1, int type2, int operator);

int comparisontype(int type1, int type2, int operator);

int shifttype(int type1, int type2, int operator);

int implicitCompatible(int typeDestination, int typeSource);

char *conversionFunction(int typeDestination, int typeSource);

char *typeOperator(int type, int operator);

void assignLineNumber(codeList *start);

void createEntries(ASTnode *n);

void createStructEntry();

evalExp evaluate(ASTnode *node);

void popLoopEnd();

void pushLoopEnd(codeList *newLoopEnd);

codeList *topLoopEnd();

void fixDanglingGoto(codeList * start);

void createStructEntries(ASTnode *n1,ASTnode *n2);

fields *searchStruct(char *id);