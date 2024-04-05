%{
#include <stdio.h>
#include <stdlib.h>
#include "symboltable.h"

int yyerror(char* yaccProvidedMessage);
int alpha_yylex(void);

extern int yylineno;
extern char* yytext;
extern FILE* yyin;

SymTable **stbl; 
Sym *symbol;

int table_size=0;
int scope=0;
int counter=0;
char buffer[8];
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
%token <string>     IF ELSE WHILE FOR BREAK CONT RET TRUE FALSE NIL FUNC LOCAL
%token <string>     LPAR RPAR LBRACE RBRACE LSQBRACE RSQBRACE 
%token <string>     ADD SUB MUL DIV MOD PPLUS MMINUS UMINUS
%token <string>     ASSIGN EQ NEQ AND OR NOT MORE MOREEQ LESS LESSEQ
%token <string>     SEMI DOT DDOT COLON CCOLON COMMA

%type <intVal>      expr term
%type <string>      program stmt assignexpr primary lvalue member
%type <string>      call callsuffix normcall methodcall elist objectdef
%type <string>      indexed indexedelem block inblock funcdef const idlist 
%type <string>      ifstmt whilestmt forstmt returnstmt

%start program

%right      ASSIGN
%left       OR
%left       AND
%nonassoc   EQ NEQ
%nonassoc   LESS MORE MOREEQ LESSEQ
%left       ADD SUB
%left       MUL DIV MOD
%right      NOT PPLUS MMINUS
%left       DOT DDOT
%left       LSQBRACE RSQBRACE
%nonassoc   UMINUS
%left       LPAR RPAR

%error-verbose

%%

program:        stmt program                            {printf("Found statement\n");}
                | %empty                                
                ;

stmt:           expr SEMI                               {printf("Found expression\n");}
                | ifstmt                                {printf("Found if statement\n");}
                | whilestmt                             {printf("Found while statement\n");}
                | forstmt                               {printf("Found for statement\n");}
                | returnstmt                            {printf("Found return statement\n");}
                | BREAK SEMI                            {printf("Found break\n");}
                | CONT SEMI                             {printf("Found continue\n");}
                | block                                 {printf("Found block\n");}
                | funcdef                               {printf("Found function definition\n");}
                | SEMI                                  {printf("Found semicolon\n");}                       
                ;

expr:           assignexpr                              {printf("Found assignment expression\n");}
                | expr ADD expr                         {printf("Found expression + expression\n"); $$=$1+$3;}
                | expr SUB expr                         {printf("Found expression - expression\n"); $$=$1-$3;}
                | expr MUL expr                         {printf("Found expression * expression\n"); $$=$1*$3;}
                | expr DIV expr                         {printf("Found expression / expression\n"); $$=$1/$3;}
                | expr MOD expr                         {printf("Found expression MOD expression\n"); $$=$1%$3;}
                | expr MORE expr                        {printf("Found expression > expression\n"); $$=($1>$3)?1:0;}
                | expr MOREEQ expr                      {printf("Found expression >= expression\n"); $$=($1>=$3)?1:0;}
                | expr LESS expr                        {printf("Found expression < expression\n"); $$=($1<$3)?1:0;}
                | expr LESSEQ expr                      {printf("Found expression <= expression\n"); $$=($1<=$3)?1:0;}
                | expr EQ expr                          {printf("Found expression == expression\n"); $$=($1==$3)?1:0;}
                | expr NEQ expr                         {printf("Found expression != expression\n"); $$=($1!=$3)?1:0;}
                | expr AND expr                         {printf("Found expression && expression\n"); $$=($1 && $3)?1:0;}
                | expr OR expr                          {printf("Found expression || expression\n"); $$=($1 || $3)?1:0;}
                | term                                  {printf("Found term\n"); }
                ;

term:           LPAR expr RPAR                          {printf("Found (expression)\n"); $$ = $2;}
                | SUB expr %prec UMINUS                 {printf("Found -expression\n"); $$ = -$2;}
                | NOT expr                              {printf("Found !expression\n"); $$= $2?0:1; }
                | PPLUS lvalue                          {printf("Found ++lvalue\n"); /*$$=$2+1;*/ }
                | lvalue PPLUS                          {printf("Found lvalue++\n"); /*$$=$1+1;*/}
                | MMINUS lvalue                         {printf("Found --lvalue\n"); /*$$=$2-1;*/}
                | lvalue MMINUS                         {printf("Found lvalue--\n"); /*$$=$1-1;*/}
                | primary                               {printf("Found primary\n"); }
                ;

assignexpr:     lvalue ASSIGN expr                      {printf("Found lvalue=expression\n"); /*$1=$3;*/}
                ;

primary:        lvalue                                  {printf("Found lvalue\n"); }         
                | call                                  {printf("Found call\n"); }
                | objectdef                             {printf("Found object definition\n"); }
                | LPAR funcdef RPAR                     {printf("Found (function definition)\n"); }
                | const                                 {printf("Found const\n"); }
                ;

lvalue:         ID                                      {if(Search($1,scope,LLOCAL)==NULL){
                                                            if(scope) symbol = createSymbol($1,scope,yylineno,LLOCAL);
                                                            else symbol = createSymbol($1,scope,yylineno,GLOBAL);
                                                            Insert(symbol);
                                                         }
                                                         printf("Found id\n");
                                                        }
                | LOCAL ID                              {symbol=createSymbol($2,scope,yylineno,LLOCAL);
                                                         Insert(symbol);
                                                         printf("Found local id\n"); 
                                                        }
                | CCOLON ID                             {if(Search($2,0,LLOCAL)==NULL){
                                                            symbol=createSymbol($2,scope,yylineno,LLOCAL);
                                                            Insert(symbol);
                                                         }
                                                         printf("Found ::id\n"); 
                                                        }
                | member                                {printf("Found member\n"); }
                ;

member:         lvalue DOT ID                           {printf("Found lvalue.id\n"); }
                | lvalue LSQBRACE expr RSQBRACE         {printf("Found lvalue[expression]\n"); }
                | call DOT ID                           {printf("Found call.id\n"); }
                | call LSQBRACE expr RSQBRACE           {printf("Found call[expression]\n"); }
                ;

call:           call LPAR elist RPAR                    {printf("Found call(elist)\n"); }
                | lvalue callsuffix                     {printf("Found lvalue call suffix\n"); }
                | LPAR funcdef RPAR LPAR elist RPAR     {printf("Found (function definition)(elist)\n"); }
                ;

callsuffix:     normcall                                {printf("Found normal call\n"); }
                | methodcall                            {printf("Found method call\n"); }
                ;

normcall:       LPAR elist RPAR                         {printf("Found (elist)\n"); }
                ;

methodcall:     DDOT ID LPAR elist RPAR                 {printf("Found ..id(elist)\n"); }
                ;

elist:          expr                                    {printf("Found expression\n"); } 
                | elist COMMA expr                      {printf("Found elist,expression\n"); }
                | %empty                                
                ;

objectdef:      LSQBRACE elist RSQBRACE                 {printf("Found [elist]\n"); }
                | LSQBRACE indexed RSQBRACE             {printf("Found [indexed]\n"); }
                | LSQBRACE RSQBRACE                     {printf("Found []\n"); }
                ;

indexed:        indexedelem                             {printf("Found indexed element\n"); }
                | indexed COMMA indexedelem             {printf("Found indexed, indexed element\n"); }
                | %empty                                
                ;

indexedelem:    LBRACE expr COLON expr RBRACE           {printf("Found {expression:expression}\n"); }
                ;

block:          LBRACE {scope++;} inblock RBRACE        {scope--;
                                                         Hide(scope);                                                    
                                                         printf("Found {statement}\n"); 
                                                        }
                ;

inblock:        inblock stmt                            {printf("Found statement in block\n");}
                | %empty
                ;

funcdef:        FUNC ID {if(Search($2,scope,USERFUNC)==NULL){
                            symbol = createSymbol($2,scope,yylineno,USERFUNC);
                            Insert(symbol);
                         }
                         else{
                            yyerror("Function already exists\n");
                            yyerrok;
                         }
                        }
                LPAR {scope++;} idlist RPAR {scope--;} block {Hide(scope);
                                                              printf("Found function id(id list) block\n"); 
                                                             }
                | FUNC {snprintf(buffer,sizeof(buffer),"$%d",counter++);
                        symbol = createSymbol(buffer,scope,yylineno,USERFUNC);
                        Insert(symbol);
                       }
                LPAR {scope++;} idlist RPAR {scope--;} block {Hide(scope);
                                                              printf("Found function(id list) block\n"); 
                                                             }
                ;

const:          INTEGER                                 {printf("Found integer\n"); }
                | FLOAT                                 {printf("Found float\n"); }
                | STRING                                {printf("Found string\n"); }
                | NIL                                   {printf("Found nil\n"); }
                | TRUE                                  {printf("Found true\n"); }
                | FALSE                                 {printf("Found false\n"); }
                ;

idlist:         ID                                      {if(Search($1,scope,FORMAL)==NULL){
                                                            symbol=createSymbol($1,scope,yylineno,FORMAL);
                                                            Insert(symbol);
                                                         }
                                                         else{
                                                            yyerror("Formal argument already exists\n");
                                                            yyerrok;
                                                         }
                                                         printf("Found id\n"); 
                                                        }
                | idlist COMMA ID                       {if(Search($3,scope,FORMAL)==NULL){
                                                            symbol=createSymbol($3,scope,yylineno,FORMAL);
                                                            Insert(symbol);
                                                         }
                                                         else{
                                                            yyerror("Formal argument already exists\n");
                                                            yyerrok;
                                                         }
                                                         printf("Found id list, id\n"); 
                                                        }
                | %empty                                
                ;

ifstmt:         IF LPAR expr RPAR {scope++;} stmt       {scope--;
                                                         Hide(scope);
                                                         printf("Found if(expression) statement\n"); 
                                                        }
                | ifstmt ELSE {scope++;} stmt           {scope--;
                                                         Hide(scope);
                                                         printf("Found if(expression) statement else statement\n"); 
                                                        }
                ;

whilestmt:      WHILE LPAR expr RPAR {scope++;} stmt    {scope--;
                                                         Hide(scope);
                                                         printf("Found while(expression) statement\n"); 
                                                        }
                ;

forstmt:        FOR LPAR elist SEMI expr SEMI elist RPAR {scope++;} stmt    {scope--;
                                                                             Hide(scope);
                                                                             printf("Found for(elist;expression;elist) statement\n"); 
                                                                            }
                ;

returnstmt:     RET SEMI                                {printf("Found return;\n"); }
                | RET expr SEMI                         {printf("Found return expression;\n"); }
                ;

%%

int yyerror (char* yaccProvidedMessage){
    fprintf(stderr,"%s: at line %d, before token: %s\n",yaccProvidedMessage,yylineno,yytext);
    fprintf(stderr, "INPUT NOT VALID\n");
}

int main(int argc, char **argv){
    InitTable();
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

    PrintTable();
    return 0;
}