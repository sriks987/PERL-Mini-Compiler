%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #include"y.tab.h"
	
    extern YYSTYPE yylval;
	
    void count(void);
    int countvar = 0;
%}

digit [0-9]
id [a-zA-Z_]([a-zA-Z_]|[0-9])*
string \"[.]*\"
comment "#"[^\n]*

%%

{comment} {;}
"sub"     { count(); return(SUB); }
"foreach" { count(); return(FOREACH); }
"if"      { count(); return(IF); }
"elseif"  { count(); return(ELSEIF); }
"else"    { count(); return(ELSE); }

([0-9])*  				{ count(); yylval.ival = atoi(yytext); return(INT);}
([0-9])+([Ee][+-]?([0-9])+)		{ count(); yylval.doub = atof(yytext); return(DOUBLE); }
([0-9])*"."([0-9])+([Ee][+-]?([0-9])+)?	{ count(); yylval.doub = atof(yytext); return(DOUBLE); }
([0-9])+"."([0-9])*([Ee][+-]?([0-9])+)?	{ count(); yylval.doub = atof(yytext); return(DOUBLE); }

">"  { count(); return(RELOP); }
"<"  { count(); return(RELOP); }
">=" { count(); return(RELOP); }
"<=" { count(); return(RELOP); }
"==" { count(); return(EQ); }
"!=" { count(); return(NE); }

"&&" { count(); return(AND); }
"||" { count(); return(OR); }

"last"   { count(); return(LAST); } 
"next"   { count(); return(NEXT); }
"return" { count(); return(RETURN); }

"int"	{ count(); return(TYPE_INT);}
"double"	{ count(); return(TYPE_DOUBLE);}
"String"	{ count(); return(TYPE_STRING);}

{id}      { count(); 
		if(yyleng > 31){
			printf("Identifer too long\n");
			yytext[31] = '\0';
		}
		strcpy(yylval.name, yytext); return(ID); }
{string}  { count(); strcpy(yylval.str, yytext); return(STRING); }

"$"     { count(); return('$'); }
"@"     { count(); return('@'); }
";"	{ count(); return(';'); }
"}"     { count(); return('}'); }
","	{ count(); return(','); }
"="	{ count(); return('='); }
")"	{ count(); return(')'); }
"-"	{ count(); return('-'); }
"+"	{ count(); return('+'); }
"*"	{ count(); return('*'); }
"/"	{ count(); return('/'); }
"("	{ count(); return('('); }
"{"	{ count(); return('{'); }
"["	{ count(); return('['); }
"]"	{ count(); return(']'); }

%%

void count(void){
	ECHO;
	printf(" ");
	countvar +=1;
}

int yywrap(void){
	return 1;
}

