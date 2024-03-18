%{
#include <stdio.h>

int yylex();

extern int lineno;
%}

%union{
    int intVal;
    char* string;
    symrec* tptr;
}

%token <string>     STRING 

%type <intVal>      expr

%start symbol

%destructor { free($$); } STRING

%right      ASSIGN
%left       OR
%left       AND
%nonassoc   EQUAL, NOT_EQUAL
%nonassoc   LESSER, GREATER, GREATER_EQUAL, LESSER_EQUAL
%left       PLUS, MINUS
%left       MULTIPLY, DIV, MOD
%right      NOT, PLUS_PLUS, MINUS_MINUS
%left       DOT, DOT_DOT
%left       LEFT_SQBRACE, RIGHT_SQBRACE
%left       LEFT_PARENTHESIS, RIGHT_PARENTHESIS

%error-verbose

%%


%%

int main(int argc, char **argv){
    yyparse();

    return 0;
}