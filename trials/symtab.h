#define MAX 100

struct symNode{
	char id[30];
	int conType;	// For variable of function name
	int dataType;
	long int firstLine, lastLine;
	long int strReq;	
	int scope, parentScope, funcScope;	// FuncScope is to know what the variables in the function are 
	int valid; // 1 for valid and 0 for invalid
	long startAddress; // For function it will be the Line number in three address code
	int params;		// Number of parameters in a function
};

struct scopeTable{
	int scopeNum;
	int num;
	struct symNode symArr[MAX];
	struct scopeTable *parent;
	struct scopeTable *children[100];
	int numChild;
};

int traverse(struct scopeTable *head);

int addSym(struct scopeTable *head, char* givenId, int lineno, int conType, int dataType, int scope, int parentScope, long startAddress);

int setVal(struct scopeTable *head, char *id, int lineno);

int addLookSym(struct scopeTable *head, char* givenId, int add, int lineno, int conType, int data);

int findLen(struct scopeTable *head, char *givenId); // To find the length of an array	

struct scopeTable* addScope(struct scopeTable *head);

struct scopeTable* delScope(struct scopeTable *head);

struct scopeTable* leaveScope(struct scopeTable *head);

struct symNode getVal(struct scopeTable *head, char *id, int *succ, int lineno);

