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

// To know the number of array elements to iterate through
int numEle = 0;

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

void codegen_func_def()
{
	fprintf(f1,"func\tbegin\t%s\n",st[top]);
	top-=1;
}

 //a ( </>/+/* ...) b
void codegen_logical()
{
	sprintf(temp,"t%d",i);
	//fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
    AddQuadruple(st[top-1], st[top-2], st[top], temp);
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

void codegen_function_name(char* funcname, int n,int hasReturnType) 
{
	if(ISFUNCCALL > 0) {
		if(hasReturnType) {
			//fprintf(f1,"%s\t=\tcall %s,%d\n",st[top-1],st[top],n);
            AddQuadruple("funccall", n, "", )
			top-=2;
		} else {
			//fprintf(f1,"call %s,%d\n",st[top],n);
			top-=1;
		}
	}  	
}

void codegen_array_indexing(char* idName, int n, int dataType){
    if(dataType == 1)
        size = 4;
    else
        size = 8;
    AddQuadruple("*", sprintf("%d", n), sprintf("%d", size), sprintf("t%d", i));
    AddQuadruple("+", idName, sprintf("t%d", i), sprintf("t%d", ++i));
    i++;
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
%token <ival> INT TYPESPECIFIER
%token <str> STRING
%token <doub> DOUBLE


%%
S:
    {symTab = addScope(symTab);} STMTLIST 
    ;

STMTLIST:
    | STMT ';' STMTLIST
    | FOREACH {AddQuadruple(sprintf("L%d", ++lnum), "","",""); label[ltop] = lnum; } '$' ID '(' '@' ID ')' 
    { numEle = findLen(symTab, $7); if numEle==-1{printf("Not an array");}} { temp = arrayindex($7, index); AddQuadruple("=", temp, "", $4);} '{' STMTFOR '}' 
    { AddQuadruple("<", "index", "numLen", sprintf("t%d", i)); 
      AddQuadruple("ifFalse", "t1", "", sprintf("L%d", lnum));
      AddQuadruple("goto", sprintf("L%d", lable[ltop]), "", "");} STMTLIST 
    | SUB ID { AddQuadruple("proc", $2, "", "") }             
    '(' PARAM { }
     ')' FUNCSTMTBLK {  printf("\nDummy");} 
    STMTLIST
    ;

STMTFOR:
    | STMT ';' STMTFOR
    | FOREACH '$' ID '(' '@' ID ')' '{' STMTFOR '}' STMTFOR
    ;

STMT:
    ASSIGNMENT 
    | FUNCCALL      { hasReturnType=0; }
    | RET           { AddQuadruple("","","","stack top"); }
    ;

RET:
    RETURN primary_expression
    ;

PARAM:
    TYPESPECIFIER '$' ID ',' PARAM      { printf("\nDummy2");}
    | TYPESPECIFIER '@' ID ',' PARAM    { printf("\nDummy3");}
    | TYPESPECIFIER '$' ID              { printf("\nDummy4");}
    | TYPESPECIFIER '@' ID              { printf("\nDummy5");}
    ;

FUNCSTMTBLK:
    '{' STMTLIST '}'
    ;

FUNCCALL:
    ID '(' PARAMLIST ')'                { codegen_function_name($1, paramCount, hasReturnType);}
    ;

ASSIGNMENT:
    assignment_expression
    | '@' ID '=' '(' { arrCount = 0;} ARRELE ')' { if(lookSym($2))}   
    ;

primary_expression:
     '$' ID 
	| INT
    | DOUBLE
	| '(' assignment_expression ')'
    | FUNCCALL  { hasReturnType = 1;}
	;

postfix_expression:
     primary_expression
	| postfix_expression '[' assignment_expression ']'
	;

unary_expression:
     postfix_expression
	| unary_operator unary_expression
	;

unary_operator:
     '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

multiplicative_expression:
     unary_expression
	| multiplicative_expression '*' {push();} postfix_expression {codegen_logical();}
	| multiplicative_expression '/' {push();} postfix_expression {codegen_logical();}
	| multiplicative_expression '%' {push();} postfix_expression {codegen_logical();}
	;

additive_expression:
     multiplicative_expression
	| additive_expression '+' {push();} multiplicative_expression {codegen_logical();}
	| additive_expression '-' {push();} multiplicative_expression {codegen_logical();}
	;

relational_expression:
     additive_expression
	| relational_expression '<' {push();} additive_expression {codegen_logical();}
	| relational_expression '>' {push();} additive_expression {codegen_logical();}
	| relational_expression LE {push();} additive_expression {codegen_logical();}
	| relational_expression GE {push();} additive_expression {codegen_logical();}
	;

equality_expression:
     relational_expression
	| equality_expression EQ {push();} relational_expression {codegen_logical();}
	| equality_expression NE {push();}relational_expression {codegen_logical();}
	;

and_expression:
     equality_expression
	| and_expression '&' equality_expression
	;

exclusive_or_expression:
     and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression: 
     exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;

logical_and_expression:
     inclusive_or_expression
	| logical_and_expression AND inclusive_or_expression
	;

logical_or_expression:
     logical_and_expression
	| logical_or_expression OR logical_and_expression
	;

assignment_expression:
     logical_or_expression
	| postfix_expression '=' assignment_expression
	;

ARRELE:
    ARRELE ',' primary_expression  { arrCount += 1; }
    | primary_expression {arrCount += 1;}
    ;

PARAMLIST:
    ARRELE ',' primary_expression  { paramCount += 1; }
    | primary_expression { paramCount += 1;}
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
