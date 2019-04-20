%{
#include<stdio.h>
#include<stdlib.h>
#include"symtab.h"
#include"ast.h"

struct scopeTable *symTab = NULL;
/*
symTab= (struct scopeTable*)malloc(sizeof(struct scopeTable));
symTab->num=0;
symTab->outer = NULL;
*/
void yyerror (char const *s);
int succ = 0;
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
    {symTab = addScope(symTab);} STMTLIST {traverse(symTab);}
    ;

STMTLIST:
    | STMT ';' STMTLIST
    | FOREACH {symTab = addScope(symTab);} '$' ID '(' '@' ID ')' { succ=0; getVal(symTab, $7, &succ, 1); addLookSym(symTab, $4, 1, 5, 1, 0);} '{' STMTFOR '}' {printf("should del here: %s", symTab->symArr[0].id);} STMTLIST 
    | SUB ID '{' FUNCSTMTBLK '}' STMTLIST
    ;

STMTFOR:
    | STMT ';' STMTFOR
    | FOREACH '$' ID '(' '@' ID ')' '{' STMTFOR '}' STMTFOR
    ;

STMT:
    ASSIGNMENT 
    | NOTINITASSIGN
    | FUNCCALL
    | RET
    ;

FUNCSTMTBLK:
    '{' PARAM ';' STMTLIST ';' RET '}'
    ;

PARAM:
    '(' IDLIST ')' '=' '@' ID 
    ;

IDLIST:
    '$' ID  {succ=0; getVal(symTab, $2, &succ, 1);}
    |'$' ID '[' INT ']'
    | '@' ID {succ=0; getVal(symTab, $2, &succ, 1);}
    | '$' ID ',' IDLIST {succ=0; getVal(symTab, $2, &succ, 1);}
    | '$' ID '[' INT ']' ',' IDLIST 
    | '@' ID ',' IDLIST {succ=0; getVal(symTab, $2, &succ, 1);}
    ;

RET:
    RETURN
    |RETURN VALUE
    ;

FUNCCALL:
    ID '(' PARAMLIST ')' 
    ;

PARAMLIST:
    VALUE
    | VALUE ',' PARAMLIST
    ;

ASSIGNMENT:
    L '=' R 
    | LARR '=' RARR 
    ;

NOTINITASSIGN:
    LASSIGN '=' R
    | LARRASSIGN '=' RARR
    ;

L:
    TYPE '$' ID  { addLookSym(symTab, $3, 1, 5, 1, 0);}
    ;

R: 
    REL %prec "statement end"
    | ARITHMETIC
    | FUNCCALL
    ;

LARR:
    TYPE '@' ID { addLookSym(symTab, $3, 1, 5, 2, 0);}
    ;

RARR:
    '(' PARAMLIST ')'
    ;

LASSIGN:
    '$' ID  { addLookSym(symTab, $2, 1, 5, 1, 0);}
    | '$' ID '[' INT ']'
    ;

LARRASSIGN:
    '@' ID { addLookSym(symTab, $2, 1, 5, 2, 0);}
    ;

REL:
    REL AND REL
    | REL OR REL
    | '(' REL ')'
    | NOT '(' REL ')'
    | ARITHMETIC LE ARITHMETIC
    | ARITHMETIC LT ARITHMETIC
    | ARITHMETIC GE ARITHMETIC
    | ARITHMETIC GT ARITHMETIC
    | ARITHMETIC EQ ARITHMETIC
    | ARITHMETIC NE ARITHMETIC
    ;

ARITHMETIC:
    VALUE '/' ARITHMETIC
    | VALUE '*' ARITHMETIC
    | VALUE '+' ARITHMETIC
    | VALUE '-' ARITHMETIC
    | '(' ARITHMETIC ')'
    | VALUE
    ;


VALUE:
    INT         {$$.val = {$1}; $$.valtype = 0;}
    | DOUBLE    {$$.val = {$1}; $$.valtype = 1;}
    | '$' ID    { succ=0; getVal(symTab, $2, &succ, 1); strcpy($$.val.name, $2); $$.valtype = 2;}
    | '$' ID '[' INT ']'    
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
