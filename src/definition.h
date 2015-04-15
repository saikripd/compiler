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
typedef struct txInfo txInfo; 
typedef struct useRegs useRegs;
typedef struct tempRegDL tempRegDL;
typedef struct codeData codeData;
typedef struct pRegInfo pRegInfo;


extern symbolTable * stack[]; 
extern int stack_head;
extern int globaltx;
extern fields * globalStructs[];
extern int struct_head;
extern codeList *loopEndStack[];
extern int loopEndStackHead;
extern arrayDimList *arrayList;
extern struct codeData *dataAnnotatedWithLines;
extern txInfo *txList;
extern int globalOffset;
extern int rrCount;
extern codeList *codeStart; 

struct pRegInfo
{
	int free;					// if the register (tx1) (with the same value) might be used in the future
	int flag;					// to set the current instruction registers
	int tReg;					// stores the value of the temporary register
};
extern pRegInfo pRegList[];

struct txInfo
{
	unsigned int offset; 		// Will contain the offset wrt current stack pointer if local variable (zero if global)
  	char globalName[50];		// Will contain absolute address of variable if it is a global
  	int reg;					// Holds number of MIPS register if its value is in a reg
  	int valid;					// 1 if it var tx has been assigned space in reg or stack or global space
  	symbolTableEntry *symbolEntry;	//For declared variable, this will hold a pointer to its symbol table entry
  	int address;
  	int floating;
};

struct tempRegDL
{
	int reg;
	int isDead;
	int lastUse;
};

struct codeData
{
	int tx1, tx2, tx3;
	int lastUse1, lastUse2, lastUse3;
	int isDead1, isDead2, isDead3;
};

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
	codeList *previous;
  	symbolTableEntry *functionEntry;
  	int isBBLHead;
  	int type;
  	int src1dl, src2dl, destlu;
  	char label[20];
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
	symbolTableEntry *symbolEntry;
};

struct evalExp
{
  	int val;
  	int err;
};

struct useRegs
{
  	int rDest;
  	int rSrc1;
  	int rSrc2;
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

void fillTxList(symbolTable *table);

void setBBLHeads(codeList *codeStart);

void annotateCode(codeList *last);

void convertToWords(char *codeString, char words[10][50]);

void annotateDataToLine(int src1, int src2, int dest, int lineno, struct tempRegDL *allReg);

void updateDL(int src1, int src2, int dest, int lineno, struct tempRegDL *allReg);

int check(struct tempRegDL *allReg, int totalTempReg);

void printStoreStatement(int rx, int offset);

void printGlobalStore(int rx, char *label);

void printLoadStatement(int rx, int offset);

void printGlobalLoad(int rx, char *label);

void resetPhysicalRegisterFlags();

void freeSrcReg(codeData ins);

void generateMIPS();

useRegs *phyRegister(useRegs *regID,codeData ins);

int allocateReg();

void printDataSegment();

void numToReg(char array[3][10], int n[3]);
