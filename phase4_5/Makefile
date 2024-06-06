###################################################
#
# Makefile
# Compilers Phase 4_5
#
####################################################

all: compiler

parser.tab.c parser.tab.h: parser.y symboltable.h quad.h finalcode.h avm.h
	bison -v -d parser.y

scanner.c: scanner.l parser.tab.h quad.h finalcode.h avm.h
	flex --outfile=scanner.c scanner.l

compiler: parser.c scanner.c symboltable.c quad.c finalcode.c avm.c
	gcc -g -o compiler parser.c scanner.c symboltable.c quad.c finalcode.c avm.c

clean:
	rm -f compiler parser.c parser.tab.h scanner.c parser.tab.c al.h
	rm -f parser.output
	clear