%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include "symnode.h"

	struct scopeTable *symtab = NULL;
	int succ = 0;

	extern int yylineno;
	extern char *yytext;

	char gvar[15] = "";
	int gscope = 0;
	int yylex(void);
	int yyerror(const char *s);
  	int param_count;
	int ISFUNCCALL = 0;
	int ISCONDCALL = 0;
	int ISITERCALL = 0;

  // f1 -> output for the irc
	FILE * f1;


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

	void codegen_func_def()
	{
		fprintf(f1,"func\tbegin\t%s\n",st[top]);
		top-=1;
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

	void codegen_function_name(int n,int hasReturnType) 
	{
		if(ISFUNCCALL > 0) {
			if(hasReturnType) {
				fprintf(f1,"%s\t=\tcall %s,%d\n",st[top-1],st[top],n);
				top-=2;
			} else {
				fprintf(f1,"call %s,%d\n",st[top],n);
				top-=1;
			}
		}  	
	}

	void codegen_conditional_if()
	{
		lnum++;
		label[ltop] = lnum;
		ltop++;
		fprintf(f1, "ifFalse %s goto L%d\n", temp, lnum);
		top-=1;
	}
	void codegen_conditional_else()
	{
		lnum++;
		fprintf(f1, "goto L%d\n", lnum);
		fprintf(f1, "L%d:\n", label[ltop-1]);
		label[ltop] = lnum;
	}
	void codegen_conditional_end()
	{
		fprintf(f1, "L%d:\n", label[ltop-1]);
		ltop-=1;
	}
%}

%union
{
	int ival;
	long int lival;
	double dval;
	float fval;
	char* idname;
}

%token HEADER
%token IF ELSE WHILE DO BREAK CONTINUE
%token RETURN
%token SHORTHANDADD SHORTHANDSUB SHORTHANDMULT SHORTHANDDIV
%token INCREMENT DECREMENT

%token <idname> IDENTIFIER
%token <ival> CONSTANT
%token TYPE_NAME
%token <idname> CHAR INT LONG FLOAT DOUBLE VOID SHORT UNSIGNED SIGNED
%token <idname> STRUCT
%token RELOP AND OR NOT
%token STATIC EXTERN REGISTER AUTO
%token ARRTYPE
%token '=' ';' ','
%token '(' ')' '{' '}'
%type <idname> type_specifier
%type <idname> declarator

%left '+' '-'
%left '*' '/'

%start start_state


%%

start_state
	: HEADER start_state
	| translation_unit
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;


external_declaration
	: function_definition
	| declaration
	;

/*FUNCTIONS*/

function_definition
	: type_specifier declarator {codegen_func_def();} '('{ param_count=0; } params { codegen_param(param_count); param_count=0; } ')' compound_statement
	;

params
	: param_decl ',' params {param_count++;}
	| param_decl {param_count++;}
	;

param_decl
	: type_specifier declarator
	| type_specifier
	;

function_call
	: declarator '(' {param_count=0;} varList {codegen_param(param_count);} ')'
	;

varList
	: varList ',' declarator {param_count++;}
	| declarator {param_count++;}
	;


/*DECLARATIONS*/

declarator
	: IDENTIFIER { push(); }
	;

declaration
	: type_specifier init_declarator_list ';'
	| type_specifier ';'
	;

init_declarator_list
	: init_declarator {if(ISFUNCCALL) {codegen_function_name(param_count,1); param_count = 0;} else codegen_assign();}
	| init_declarator_list ',' init_declarator {if(ISFUNCCALL){codegen_function_name(param_count,1); param_count = 0;} else codegen_assign();} 
	;

init_declarator
	: declarator '=' primary_expression
	| declarator '=' simple_expression
	| declarator '=' function_call {ISFUNCCALL = 1;}
	| declarator
	;

type_specifier
	: VOID
	| CHAR
	| INT
	| LONG
	| FLOAT
	| DOUBLE
	| UNSIGNED INT
	| UNSIGNED SHORT INT
	| UNSIGNED LONG INT
	| UNSIGNED LONG LONG INT
	| SIGNED INT
	| SIGNED SHORT INT
	| SIGNED LONG INT
	| SIGNED LONG LONG INT
	;

primary_expression
	: declarator
	| CONSTANT
		{
			push();
		}
	;

simple_expression
	: simple_expression OR and_expression
	| and_expression
	;

and_expression
	: and_expression AND unary_rel_expression
	| unary_rel_expression
	;

unary_rel_expression
	: NOT factor
	| rel_expression 
	;

rel_expression
	: sum_expression
	| sum_expression RELOP {push();} sum_expression 
	;

sum_expression
	: sum_expression sumop {push();} term {codegen_logical();}
	| term 
	;

sumop
	: '+'
	| '-'
	;

logop
	: OR {push();}
	| AND {push();}
	;

term
	: term mulop {push();} factor {codegen_logical();}
	| factor 
	;

mulop
	: '*'
	| '/'
	;

factor
	: primary_expression
	| '(' simple_expression ')'
	;


compound_statement
	: '{' '}'
	| '{' block_scope_list '}'
	;

block_scope_list
	: block_item
	| block_item block_scope_list
	;

block_item
	: declaration 
	| statement
	;

statement
	: expression_statement
	| compound_statement
	| conditional_statement
	| iteration_statement
	| break_statement
	| continue_statement
	| return_statement
	| statement ';' statement
	| function_call {codegen_function_name(param_count,0); param_count = 0;}
	;

expression_statement
	: expression ';' {if(ISFUNCCALL){codegen_function_name(param_count,1); param_count = 0;} else {codegen_assign();} } 
	| ';' 
	;

expression
	: declarator '=' expression {ISFUNCCALL = 0;}
	| simple_expression {ISFUNCCALL = 0;}
	| declarator '=' function_call {ISFUNCCALL = 1;}
	;

conditional_statement
	: IF '(' condition {codegen_conditional_if(); }')' compound_statement ELSE {codegen_conditional_else();} compound_statement {codegen_conditional_end();}
	| IF '(' condition {codegen_conditional_if(); }')' compound_statement {codegen_conditional_end();}
	;

condition
	: expression logop expression 
	| expression {codegen_logical();}
	;

iteration_statement
	: DO  compound_statement  WHILE '(' condition ')' ';'
	;

break_statement
	: BREAK ';'
	;

continue_statement
	: CONTINUE ';'
	;

return_statement
	: RETURN ';' 
	| RETURN simple_expression ';'
	;

%%


void main()
{
  f1=fopen("output","w");
	yyparse();
	//printsymtab(symtab);
}


int yyerror(char const *s)
{
	extern int yylineno;
	printf("\nParse Failed\n");
	printf("Error Line Number: %d %s", yylineno, s);
	fflush(stdout);
	return 0;
}
