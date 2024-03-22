%{
#include <stdio.h>
#include "symboltable.h"

int yyerror(char* yaccProvidedMessage);
int alpha_yylex(void);

extern int yylineno;
extern char* yytext;
extern FILE* yyin;

SymTable *stbl[HASH_SIZE];
Sym *symbol;
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

program:        stmt*                               {;}
                |                                   {;}
                ;

stmt:           expr SEMI
                | ifstmt
                | whilestmt
                | forstmt
                | returnstmt
                | BREAK SEMI
                | CONT SEMI
                | block
                | funcdef
                |                                   {;}                       
                ;

expr:           assignexpr                    
                | expr op expr
                | term                     
                ;

op              ADD | SUB | MUL | DIV | MOD | MORE | MOREEQ | LESS | LESSEQ
                | EQ |  NEQ | AND | OR
                ;

term            LPAR expr RPAR
                | SUB expr
                | NOT expr
                | PPLUS lvalue
                | lvalue PPLUS
                | MMINUS lvalue
                | lvalue MMINUS
                | primary
                ;

assignexpr:     lvalue ASSIGN expr SEMI             { assign($1,$3);}
                ;

primary:        lvalue
                | call
                | objectdef
                | LPAR funcdef RPAR
                | const
                ;

lvalue:         ID
                | LOCAL ID
                | CCOLON ID
                | member
                ;

member:         lvalue DOT ID
                | lvalue LSQBRACE expr RSQBRACE
                | call DOT ID
                | call LSQBRACE expr RSQBRACE
                ;

call:           call LPAR elist RPAR
                | lvalue callsuffix
                | LPAR funcdef RPAR LPAR elist RPAR
                ;

callsuffix:     normcall
                | methodcall
                ;

normcall:       LPAR elist RPAR
                ;

methodcall:     DDOT ID LPAR elist RPAR
                ;

elist:          expr COMMA expr* 
                ;

objectdef:      LSQBRACE elist | indexed RSQBRACE
                ;

indexed:        indexedelem COMMA indexedelem*
                ;

indexedelem:    LBRACE expr COLON expr RBRACE
                ;

block:          LBRACE stmt* RBRACE
                ;

funcdef:        FUNC ID LPAR idlist RPAR block
                ;

const:          INTEGER | FLOAT | STRING | NIL | TRUE | FALSE
                ;

idlist:         ID COMMA ID*
                ;

ifstmt:         IF LPAR expr RPAR stmt ELSE stmt
                ;

whilestmt:      WHILE LPAR expr RPAR stmt
                ;

forstmt:        FOR LPAR elist SEMI expr SEMI elist RPAR stmt
                ;

returnstmt:     RET expr SEMI

/*expression:     INTEGER                             { $$ = $1;}
                |   ID                              { $$ = lookup($1); free($1);}
                |   expression ADD expression       { $$ = $1 + $3;}
                |   expression SUB expression       { $$ = $1 - $3;}
                |   expression MUL expression       { $$ = $1 * $3;}
                |   expression DIV expression       { $$ = $1 / $3;}
                |   expression MOD expression       { $$ = $1 % $3;}
                |   LPAR expression RPAR            { $$ = $2;}
                |   SUB expression %prec UMINUS     { $$ = -$2;}
                ;
*/
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