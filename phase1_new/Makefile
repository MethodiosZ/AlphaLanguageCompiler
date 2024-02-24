# Compiler
CC = gcc -g -w

# Flex compiler
FL = flex

# Executable name
EXECUTABLE = scanner

# Default rule
all: $(EXECUTABLE)

# Compile
$(EXECUTABLE): scanner.l
	$(FL) -o lex.yy.c scanner.l
	$(CC) -o scanner lex.yy.c

# Clean generated files
clean:
	rm -f lex.yy.c $(EXECUTABLE)
	rm -f scanner
	rm -f scanner.h