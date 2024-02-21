###################################################
#
# Makefile
# Compilers Phase 2
#
####################################################

all: compiler

parser.tab.c parser.tab.h: parser.y hashtable.h quad.h
	bison -v -d parser.y

scanner.c: scanner.l parser.tab.h quad.h
	flex --outfile=scanner.c scanner.l

compiler: parser.c scanner.c hashtable.c quad.c 
	gcc -g -o compiler parser.c scanner.c hashtable.c quad.c

clean:
	rm compiler parser.c parser.tab.h scanner.c parser.tab.c al.h
	rm parser.output