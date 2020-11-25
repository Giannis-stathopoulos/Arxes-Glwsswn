json: lex.yy.c y.tab.c
	gcc -g lex.yy.c json.tab.c -o json

lex.yy.c: y.tab.c json.l
	lex json.l

y.tab.c: json.y
	bison -d json.y

clean: 
	rm -rf lex.yy.c json.tab.c json.tab.h json json.dSYM
