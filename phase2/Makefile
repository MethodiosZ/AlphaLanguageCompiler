###################################################
#
# Makefile
# Compilers Phase 2
#
####################################################

all: compiler

parser.tab.c parser.tab.h: parser.y symboltable.h
	bison -v -d parser.y

scanner.c: scanner.l parser.tab.h 
	flex --outfile=scanner.c scanner.l

compiler: parser.c scanner.c symboltable.c
	gcc -g -o compiler parser.c scanner.c  symboltable.c

clean:
	rm -f compiler parser.c parser.tab.h scanner.c parser.tab.c al.h
	rm -f parser.output
	clear