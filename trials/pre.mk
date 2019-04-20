a.out:	lex.yy.c y.tab.c symtab.c ast.c
	gcc lex.yy.c y.tab.c symtab.c ast.c
y.tab.c: perltest.y
	yacc -d perltest.y
lex.yy.c: perl.l
	lex perl.l
