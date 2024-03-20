%{
#include <stdio.h>

int yyerror(char* yaccProvidedMessage);
int yylex(void);

extern int yylineno;
extern char* yytext;
extern FILE* yyin;
%}

%union{
    int intVal;
    char* string;
    double realVal;
}

%token <string>     STRING
%token <string>     ID
%token <intVal>     INTEGER 
%token <realVal>    FLOAT

%type <intVal>      expr

%start program

%destructor { free($$); } STRING

%right      ASSIGN
%left       OR
%left       AND
%nonassoc   EQ, NEQ
%nonassoc   LESS, MORE, MOREEQ, LESSEQ
%left       ADD, SUB
%left       MUL, DIV, MOD
%right      NOT, PPLUS, MMINUS
%left       DOT, DDOT
%left       LSQBRACE, RSQBRACE
%nonassoc   UMINUS
%left       LPAR, RPAR

%error-verbose

%%

program:        assignments expressions             {;}
                |                                   {;}
                ;

assignments:    assignments assignment              {;}
                |                                   {;}
                ;

assignment:     ID  ASSIGN  expression ';'          { assign($1,$3);}
                ;

expressions:    expressions expr                    {;}
                |   expr                              {;}
                ;

expr:           expression ';'                      { fprintf(stdout, "Result is: %d\n", $1);}
                |   error ';'                       { yyerrok;}
                ;

expression:     INTEGER                             { $$ = $1;}
                |   ID                              { $$ = lookup($1); free($1);}
                |   expression ADD expression       { $$ = $1 + $3;}
                |   expression SUB expression       { $$ = $1 - $3;}
                |   expression MUL expression       { $$ = $1 * $3;}
                |   expression DIV expression       { $$ = $1 / $3;}
                |   expression MOD expression       { $$ = $1 % $3;}
                |   LPAR expression RPAR            { $$ = $2;}
                |   SUB expression %prec UMINUS     { $$ = -$2;}
                ;

%%

int yyerror (char* yaccProvidedMessage){
    fprintf(stderr,"%s: at line %d, before token: %s\n",yaccProvidedMessage,yylineno,yytext);
    fprintf(stderr, "INPUT NOT VALID\n");
}

int main(int argc, char **argv){

    if(argc>1){
        if(!(yyin=fopen(argv[1],"r"))){
            fprintf(stderr,"Cannot read file: %s\n",argv[1]);
            return 1;
        }
    }
    else{
        yyin = stdin;
    }
    yyparse();
    return 0;
}