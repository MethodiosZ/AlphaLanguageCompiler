# Compiler
CC = gcc

# Flex compiler
FLEX = flex

# Executable name
EXECUTABLE = scanner

# Default rule
all: $(EXECUTABLE)

# Compile lexer
$(EXECUTABLE): scanner.l
	$(FLEX) -o lex.yy.c scanner.l
	$(CC) -o $@ lex.yy.c -lfl

# Clean generated files
clean:
	rm -f lex.yy.c $(EXECUTABLE)
	rm -f a.out
	rm -f scanner.h