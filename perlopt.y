%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>
#include"symtab.h"

struct scopeTable *symTab = NULL;

int scopeNumber = 0;
int succ = 0;
int yylex();
int yyerror (char const *s);

char temp1[32];
char temp2[32];
char temp3[32];
char temp4[32];

extern int yylineno;
extern char *yytext;

union mulvalue{
    long int i;
    double f;
    char s[32];
};

struct quad
    {
        char op[10];
        char arg1[32];
        char arg2[32];
        char result[32];
    }QUAD[100];
/*
struct value{
    union mulvalue val;
    int valtype;
};
*/
char tempArrName[32];

//Quad Table Index Variable
int quadindex = 0;

// parameter count
int paramCount = 0;

//stack
char st[1000][10];
int top=0;
int i=0;

// To know the number of array elements to iterate through
int numEle = 0;

// To maintain array and param element number
int arrNum = 0;
int paramNum = 0;
int arrCount = 0;

//For functions return type
int hasReturnType = 0;

//temporary variable for t0,t1 ...
char tempVar[10]="t";

//array of labels used
int label[200];
int lnum=0; //label number
int ltop=0; //keep track of label at top (might help in scope .. not sure)
int outGoto [30];
int goTop = 0;

void AddQuadruple(char op[10],char* arg1,char* arg2,char result[32]);
void constantPropagation(int index, struct quad* arr);
void constantFolding(struct quad* arr);
int compute(char *, char *, char *);
int checkForDigits(char *ch);


//copy to top of stack
void push()
{
	strcpy(st[++top],yytext);
}

//temp(top-2) =(top-1) b (top)
void codegen_assign()
{
 	//fprintf(f1,"%s\t=\t%s\n",st[top-1],st[top]);
 	top-=2;
}

void codegen_func_def()
{
	//fprintf(f1,"func\tbegin\t%s\n",st[top]);
	top-=1;
}

 //a ( </>/+/* ...) b
void codegen_logical()
{
	sprintf(tempVar,"t%d",i);
	//fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
    if(st[top-1][0] == '='){
        AddQuadruple(st[top-1], st[top], "", st[top-2]);
    }
    else{
        AddQuadruple(st[top-1], st[top-2], st[top], tempVar);
    }
	top-=2;
	strcpy(st[top],tempVar);
	i++;
}

void codegen_param(int n)
{
	int l = n;
	while(l--)
	{
		//fprintf(f1,"param\t%s\n", st[top-l]);
	}
	top=top-n;
}

void codegen_function_name(char* funcname, int n,int hasReturnType) 
{
	/*if(ISFUNCCALL > 0) {*/
		if(hasReturnType) {
			//fprintf(f1,"%s\t=\tcall %s,%d\n",st[top-1],st[top],n);
            sprintf(temp3, "%d", n);
            AddQuadruple("call", funcname, temp3, "");
			top-=2;
		} else {
			//fprintf(f1,"call %s,%d\n",st[top],n);
            sprintf(temp3, "%d", n);
            AddQuadruple("call", funcname, temp3, "");
			top-=1;
		}
	/*}*/  	
}

void codegen_array_indexing(char* idName, int n/*, int dataType*/){
    /*if(dataType == 1)
        size = 4;
    else
        size = 8;*/
    int size = 4; //Placeholder
    sprintf(temp2, "%d", n);
    sprintf(temp3, "%d", size);
    sprintf(temp4, "t%d", i);
    AddQuadruple("*", temp2, temp3, temp4);
    sprintf(temp3, "t%d", i);
    sprintf(temp4, "t%d", ++i);
    AddQuadruple("+", idName, temp3, temp4);
    i++;
}

void codegen_array_assignment(char* arrName){
    sprintf(temp3, "%d", arrNum);
    AddQuadruple("[]=", arrName, temp3, yytext);
    arrNum++;
}

void codegen_paramlist(){
    sprintf(temp1, "Param %d", paramNum);
    AddQuadruple(temp1, yytext, "", "");
    paramNum++;
}

%}

%union {
    long int ival;
    double doub;
    char *str;
    char name[32];
    //struct value val;
};

%start S

%token SUB FOREACH IF ELSEIF ELSE AND OR LAST NEXT RETURN NOT BREAK
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
    {symTab = addScope(symTab, scopeNumber++);} STMTLIST 
    ;

STMTLIST:
    | STMT ';' STMTLIST
    | FOREACH {sprintf(temp1, "L%d", ++lnum); AddQuadruple(temp1, "","",""); label[ltop++] = lnum; label[ltop++] = ++lnum;} '$' ID '(' '@' ID ')' 
    { numEle = findLen(symTab, $7); if (numEle==-1){printf("Not an array");} /*temp = codegen_array_indexing($7, index);*/ AddQuadruple("=", tempVar, "", $4);} { 
      sprintf(temp4, "L%d", lnum);
      outGoto[goTop++] = label[ltop-1]; } 
      '{' STMTFOR '}'
     { sprintf(temp4, "t%d", i);
       sprintf(temp3, "%d", numEle);
       AddQuadruple("<", "index", temp3, temp4);
       sprintf(temp4, "L%d", outGoto[--goTop]);
       sprintf(temp2, "t%d", i);
       AddQuadruple("ifFalse", temp2, "", temp4);
       sprintf(temp2, "L%d", label[ltop-2]);
       AddQuadruple("goto", temp2, "", ""); 
       strcpy(temp1, temp4); 
       AddQuadruple(temp1, "","","");
       ltop-=2; i++;} 
     STMTLIST
    | SUB ID { AddQuadruple("proc", $2, "", ""); }             
    '(' PARAM
     ')' FUNCSTMTBLK {  printf("\nDummy");} 
    STMTLIST
    ;

STMTFOR:
    | STMT ';' STMTFOR
    | FOREACH {sprintf(temp1, "L%d", ++lnum); AddQuadruple(temp1, "","",""); label[ltop++] = lnum; label[ltop++] = ++lnum;} '$' ID '(' '@' ID ')' 
    { numEle = findLen(symTab, $7); if (numEle==-1){printf("Not an array");} /*temp = codegen_array_indexing($7, index);*/ AddQuadruple("=", tempVar, "", $4);} { 
      sprintf(temp4, "L%d", lnum);
      outGoto[goTop++] = label[ltop-1]; } 
      '{' STMTFOR '}'
     { sprintf(temp4, "t%d", i);
       sprintf(temp3, "%d", numEle);
       AddQuadruple("<", "index", temp3, temp4);
       sprintf(temp4, "L%d", outGoto[--goTop]);
       sprintf(temp2, "t%d", i);
       AddQuadruple("ifFalse", temp2, "", temp4);
       sprintf(temp2, "L%d", label[ltop-2]);
       AddQuadruple("goto", temp2, "", ""); 
       strcpy(temp1, temp4); 
       AddQuadruple(temp1, "","","");
       ltop-=2; i++;} 
     STMTFOR 
    | BREAK ';'  { sprintf(temp2, "L%d", label[ltop-1]); AddQuadruple("goto", temp2, "","");  ltop -= 2;}
    ;

STMT:
    ASSIGNMENT 
    | FUNCCALL      { hasReturnType=0; }
    | RET           { AddQuadruple("","","","stack top"); }
    ;

RET:
    RETURN
    | RETURN primary_expression
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
    | '@' ID '=' '(' { arrCount = 0; strcpy(tempArrName, $2); arrNum = 0;} ARRELE ')' { addSym(symTab, $2, yylineno, 2, 1, arrCount*4);}   
    ;

primary_expression:
     '$' ID {push();}
	| INT {push();}
    | DOUBLE {push();}
	| '(' assignment_expression ')'
    | FUNCCALL  { hasReturnType = 1;}
	;

postfix_expression:
     primary_expression
	| postfix_expression '[' assignment_expression ']'
	;

unary_expression:
     postfix_expression
	| unary_operator unary_expression {codegen_logical();}
	;

unary_operator:
     '&' {push();}
	| '*' {push();}
	| '+' {push();}
	| '-' {push();}
	| '~' {push();}
	| '!' {push();}
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
	| equality_expression NE {push();} relational_expression {codegen_logical();}
	;

and_expression:
     equality_expression
	| and_expression '&' {push();} equality_expression {codegen_logical();}
	;

exclusive_or_expression:
     and_expression
	| exclusive_or_expression '^' {push();} and_expression {codegen_logical();}
	;

inclusive_or_expression: 
     exclusive_or_expression
	| inclusive_or_expression '|' {push();} exclusive_or_expression {codegen_logical();}
	;

logical_and_expression:
     inclusive_or_expression
	| logical_and_expression AND {push();} inclusive_or_expression {codegen_logical();}
	;

logical_or_expression:
     logical_and_expression
	| logical_or_expression OR {push();} logical_and_expression {codegen_logical();}
	;

assignment_expression:
     logical_or_expression
	| postfix_expression '=' {push();} assignment_expression {codegen_logical();}
	;

ARRELE:
    ARRELE ',' primary_expression  { arrCount += 1; codegen_array_assignment(tempArrName);}
    | primary_expression {arrCount += 1; codegen_array_assignment(tempArrName);}
    ;

PARAMLIST:
    PARAMLIST {codegen_paramlist();}',' primary_expression  { paramCount += 1; }
    | primary_expression { paramCount += 1; codegen_paramlist();}
    ;
%%

int yyerror (char const *s) {
   fprintf (stderr, "%s\n", s);
   return 1;
 }

void AddQuadruple(char op[10],char* arg1,char* arg2,char result[32])
{
    strcpy(QUAD[quadindex].op,op);
    strcpy(QUAD[quadindex].arg1,arg1);
    strcpy(QUAD[quadindex].arg2,arg2);
    strcpy(QUAD[quadindex].result,result);
    quadindex++;
}

//Optimization functions
void constantPropagation(int index, struct quad* arr)
{
    char val[50], var[50];
    int i=index;

    strcpy(var, arr[i].result);
    strcpy(val, arr[i].arg1);

    for(i=i+1; i<quadindex; i++)
    {
        if (strcmp(arr[i].op, "if")!=0 && strcmp(arr[i].op, "goto")!=0 && strcmp(arr[i].op, "call")!=0 && strcmp(arr[i].op, "proc")!=0 && arr[i].op[0]!='L'&&strcmp(arr[i].result, "stack top")!=0){    
            if(strcmp(arr[i].result, var)==0)
            {
                return;
            }
            else if(arr[i].arg2[0]!='\0' && strcmp(arr[i].arg2, var)==0)
            {
                strcpy(arr[i].arg2, val);
            }
            else if(arr[i].arg1[0]!='\0' && strcmp(arr[i].arg1, var)==0)
            {
                strcpy(arr[i].arg1, val);
            }
        }
    }
    // printTable();
}

int checkForDigits(char *ch)
{
    //printf("ch is %s\n", ch);
    while(*ch)
    {
        if(isdigit(*ch++)==0)
        {
          return 0;
        }
        return 1;
    }
}

int compute(char *x, char *y, char *op)
{
    //printf("value of x is %s\n", x);
    int res=0;
    //convert x and y to integers
    int xx=atoi(x);
    //printf("xx is %d\n", xx);
    int yy=atoi(y);

    switch(*op)
    {
      case '+':
        res=xx+yy;
        return res;
      case '-':
        res=xx-yy;
        return res;
      case '*':
        res=xx*yy;
        return res;
      case '/':
        res=xx/yy;
        return res;
    }
}

void constantFolding(struct quad* arr)
{
  int i=0, res=0, flag=0;
  //printf("n is %d\n", n);

  while(i<quadindex)
  {
    //printf("arg1 is %s, arg2 is %s\n", arr[i].arg1, arr[i].arg2);

    //first check if arg2 exists
    if(strcmp(arr[i].arg2, "")==0)
    {
      //printf("arg2 not there\n");
      flag=1;
      constantPropagation(i, arr);
    }
    int ch1=checkForDigits(arr[i].arg1);
    int ch2=checkForDigits(arr[i].arg2);

    char stringres[50];
    //printf("ch1 is %d, ch2 is %d\n", ch1, ch2);
    if(ch1==1 && ch2==1) //if arg1 AND arg2 are digits
    {
      //compute the value, pass 2, 3, + and return 5
      res=compute(arr[i].arg1, arr[i].arg2, arr[i].op);
      //printf("Res is %d\n", res);
      sprintf(stringres, "%d", res);
      //after computing result, op=, arg1 is 5 and result is a
      strcpy(arr[i].op, "=");
      strcpy(arr[i].arg1, stringres);
      strcpy(arr[i].arg2, " ");

      constantPropagation(i, arr); 
    }
    i++;
  }
  printf("\n\n-----AFTER CONSTANT FOLDING and PROPOGATION-----");
}

int main(){
    yyparse();
    printf("Three Address Code Quadruple");
    printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s","pos","op","arg1","arg2","result");
    printf("\n\t-----------------------------------------------------------------------");
    for(i=0;i<quadindex;i++)
    {
        printf("\n\t%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s", i,QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
    }
    printf("\n\n");
    FILE* csvFile = fopen("quadcsv.csv", "w");
    for(i=0;i<quadindex;i++)
    {
        fprintf(csvFile, "%s,%s,%s,%s\n", QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
    }
    constantFolding(QUAD);
    printf("\n\t-----------------------------------------------------------------------\t\n");
    printf("Optimized Three Address Code");
    printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s","pos","op","arg1","arg2","result");
    printf("\n\t-----------------------------------------------------------------------");
    for(i=0;i<quadindex;i++)
    {
        printf("\n\t%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s", i,QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
    }
    printf("\n\n");
    FILE* csvFileOpt = fopen("optimizedcsv.csv", "w");
    for(i=0;i<quadindex;i++)
    {
        fprintf(csvFileOpt, "%s,%s,%s,%s\n", QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
    }

}
