###################################################
#
# Makefile
# Compilers Phase 1
#
####################################################

CC=gcc -g
FL=flex
FFLAGS= --outfile
OFLAGS=-o
REM=rm -f
XF=.out
CF=.c
HF=.h

all: al.c
	$(CC) $(OFLAGS) scanner.out al.c

al.c:	scanner.l
	$(FL) $(FFLAGS)=al.c scanner.l

clean:	scanner.out al.c al.h
	$(REM) *$(XF) *$(CF) *$(HF)
