%{
#include<stdio.h>
#include<stdlib.h>
#include"symtab.h"
#include"ast.h"

struct scopeTable *symTab = NULL;

int scopeNumber = 0;
int succ = 0;
int yyerror (char const *s);

extern int yylineno;
extern char *yytext;

union mulvalue{
    long int i;
    double f;
    char s[32];
}

struct quad
    {
        char op[10];
        union mulvalue arg1;
        union mulvalue arg2;
        char result[32];
    }QTABLE[100];

struct value{
    union mulvalue val;
    int valtype;
}

// parameter count
int paramCount = 0;

//stack
char st[1000][10];
int top=0;
int i=0;

//temporary variable for t0,t1 ...
char temp[2]="t";

//array of labels used
int label[200];
int lnum=0; //label number
int ltop=0; //keep track of label at top (might help in scope .. not sure)

//copy to top of stack
void push()
{
	strcpy(st[++top],yytext);
}

//temp(top-2) =(top-1) b (top)
void codegen_assign()
{
 	fprintf(f1,"%s\t=\t%s\n",st[top-1],st[top]);
 	top-=2;
}

//a ( </>/+/* ...) b
void codegen_logical()
{
	sprintf(temp,"t%d",i);
	fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
	top-=2;
    strcpy(st[top],temp);
	i++;
}

void codegen_param(int n)
{
    int l = n;
    while(l--)
    {
      fprintf(f1,"param\t%s\n", st[top-l]);
    }
    top=top-n;
}

%}

%union {
    long int ival;
    double doub;
    char *str;
    char name[32];
    struct value val;
};

%start S

%token SUB FOREACH IF ELSEIF ELSE AND OR LAST NEXT RETURN NOT
%token <name> ID
%left '+' '-' 
%left '*' '/' 
%right '!' '$' '@'
%right "statement end" AND OR 
%token '=' ';' ',' 
%token '(' ')' '{' '}' '[' ']'
%token GT LT GE LE EQ NE
%token <ival> INT TYPE
%token <str> STRING
%token <doub> DOUBLE
%type <val> VALUE

%%
S:
    {symTab = addScope(symTab,scopeNumber);} STMTLIST {traverse(symTab);}
    ;

STMTLIST:
    | STMT ';' STMTLIST
    | FOREACH {symTab = addScope(symTab, scopeNumber);} '$' ID '(' '@' ID ')' { succ=0; getVal(symTab, $7, &succ, 1); addLookSym(symTab, $4, 1, 5, 1, 0);} '{' STMTFOR '}' { symTab = leaveScope(symTab);} STMTLIST 
    | SUB ID { 
            addSym(symTab, $2, 3, ); 
            paramCount=0; 
            symTab = addScope(symTab, scopeNumber);}             
    '(' PARAM { 
            if (lookSym($2)==1){
                printf("Identifier redeclared");
            }
            else{
                addSym(symTab, $2, yylineno, 3, 0, 0)     /* ConTypes 1- Scalar, 2- Array, 3- Function*/
            }    
            symTab = addScope(symTab);}
     ')' '{' FUNCSTMTBLK '}' { 
         symTab = leaveScope(symTab); } 
    STMTLIST
    ;

STMTFOR:
    | STMT ';' STMTFOR
    | FOREACH '$' ID '(' '@' ID ')' '{' STMTFOR '}' STMTFOR
    ;

STMT:
    ASSIGNMENT 
    | FUNCCALL      
    | RET
    ;

PARAM:
    TYPESPECIFIER '$' ID ',' PARAM      { addSym(symTab, $3, 1, $1); paramCount += 1; }
    | TYPESPECIFIER '@' ID ',' PARAM    { addSym(symTab, $3, 2, ); paramCount += 1; }
    | TYPESPECIFIER '$' ID              { addSym(symTab, $3, 1, ); paramCount += 1; }
    | TYPESPECIFIER '@' ID              { addSym(symTab, $3, 2, ); paramCount += 1;}
    ;

FUNCSTMTBLK:
    '{' STMTLIST '}'
    ;

FUNCCALL:
    ID '(' PARAMLIST ')'                { }
    ;

%%

void yyerror (char const *s) {
   fprintf (stderr, "%s\n", s);
 }

void AddQuadruple(char op[10],union mulvalue arg1,union mulvalue arg2,char result[32])
{
    strcpy(QUAD[Index].op,op);
    strcpy(QUAD[Index].arg1,arg1);
    strcpy(QUAD[Index].arg2,arg2);
    sprintf(QUAD[Index].result,result);
}

int main(){
    yyparse();
    printf("Three Address Code Quadruple");
    printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s","pos","op","arg1","arg2","result");
    printf("\n\t-----------------------------------------------------------------------");
    for(i=0;i<Index;i++)
    {
        printf("\n\t%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s", i,QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
    }
    printf("\n\n");
}
