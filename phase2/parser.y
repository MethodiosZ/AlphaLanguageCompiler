%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hashtable.h"

int yyerror(char* yaccProvIDedMessage);
int yylex (void);

extern int yylineno;
extern  char* yytext;
extern FILE* yyin;
Symbol * htbl[HASH_SIZE];
Symbol * symb;

int scope = 0;
int named = 1;
%}

%error-verbose

%start program

%union{
    char* stringValue;
    int intValue;
    double doubleValue;
}

%token <stringValue>    ID
%token <stringValue>    LOCAL
%token <stringValue>    STRING
%token <doubleValue>    NUMBER
%token <intValue>       INTEGER
%token <stringValue>    NIL TRUE FALSE FUNCTION IF ELSE WHILE FOR RETURN
%token <stringValue>    L_PAR R_PAR L_SBRACKET R_SBRACKET L_BRACE R_BRACE DOT DDOT NOT 
%token <stringValue>    PPLUS MMINUS PLUS MINUS MUL DIV MOD GT GTEQ LT LTEQ EQ NEQ
%token <stringValue>    AND OR ASSIGN SEMI BREAK CONTINUE COLON CCOLON COMMA WRONG_ID

%right      ASSIGN
%left       OR
%left       AND
%nonassoc   EQ NEQ
%nonassoc   GT GTEQ LT LTEQ
%left       PLUS MINUS
%left       MUL DIV MOD
%right      NOT PPLUS MMINUS UMINUS
%left       DOT DDOT
%left       L_SBRACKET R_SBRACKET
%left       L_PAR R_PAR

%type <intValue>        expr
%type <stringValue>     stmt op term assignexpr primary lvalue member call callsuffix normcall methodcall
%type <stringValue>     elist objectdef indexed indexedelem block inblock funcdef funcid const idlist ifstmt whilestmt forstmt
%type <stringValue>     returnstmt program

%%

program: stmt program                  {printf("Found program\n");}
    | %empty
    ;
stmt: expr SEMI                 {printf("Found expr\n");}
    | ifstmt                    {printf("Found ifstmt\n");}
    | whilestmt                 {printf("Found whilestmt\n");}
    | forstmt                   {printf("Found forstmt\n");}
    | returnstmt                {printf("Found returnstmt\n");}
    | BREAK SEMI                {printf("Found break\n");}
    | CONTINUE SEMI             {printf("Found continue\n");}
    | block                     {printf("Found block\n");}
    | funcdef                   {printf("Found funcdef\n");}
    | SEMI                      {printf("Found semicolon\n");}
    ;
expr: assignexpr                {printf("Found assignexpr\n");}
    | expr PLUS expr              {printf("Found expr + expr\n"); $$=$1+$3;}
    | expr MINUS expr              {printf("Found expr - expr\n"); $$=$1-$3;}
    | expr MUL expr              {printf("Found expr * expr\n"); $$=$1*$3;}
    | expr DIV expr              {printf("Found expr / expr\n"); $$=$1/$3;}
    | expr MOD expr              {printf("Found expr MOD expr\n"); $$=$1%$3;}
    | expr GT expr              {printf("Found expr > expr\n"); $$=($1>$3)?1:0;}
    | expr GTEQ expr              {printf("Found expr >= expr\n"); $$=($1>=$3)?1:0;}
    | expr LT expr              {printf("Found expr < expr\n"); $$=($1<$3)?1:0;}
    | expr LTEQ expr              {printf("Found expr <= expr\n"); $$=($1<=$3)?1:0;}
    | expr EQ expr              {printf("Found expr == expr\n"); $$=($1==$3)?1:0;}
    | expr NEQ expr              {printf("Found expr != expr\n"); $$=($1!=$3)?1:0;}
    | expr AND expr              {printf("Found expr AND expr\n"); $$=($1 && $3)?1:0;}
    | expr OR expr              {printf("Found expr OR expr\n"); $$=($1 || $3)?1:0;}    
    | term                      {printf("Found term\n");}
    ;
op: PLUS | MINUS | MUL | DIV | MOD | GT | GTEQ | LT | LTEQ | EQ | NEQ | AND | OR
    ;
term: L_PAR expr R_PAR          {printf("Found ( expr )\n");}
    | MINUS expr %prec UMINUS   {printf("Found - expr\n");}
    | NOT expr                  {printf("Found not expr\n");}
    | PPLUS lvalue              {printf("Found ++lvalue\n");}
    | lvalue PPLUS              {printf("Found lvalue++\n");}
    | MMINUS lvalue             {printf("Found --lvalue\n");}
    | lvalue MMINUS             {printf("Found lvalue--\n");}
    | primary                   {printf("Found primary\n");}
    ;
assignexpr: lvalue ASSIGN expr  {printf("Found assignment\n");}
    ;
primary: lvalue                 {printf("Found lvalue\n");}
    | call                      {printf("Found call\n");}
    | objectdef                 {printf("Found objectdef\n");}
    | L_PAR funcdef R_PAR       {printf("Found ( funcdef )\n");}
    | const                     {printf("Found const\n");}
    ;
lvalue: ID      {
    if(lookupS(htbl,$1,scope)==NULL){
        if(scope == 0){symb = createSymbol($1,GLOBAL,yylineno,scope);} 
        else {symb = createSymbol($1,LOCALA,yylineno,scope);}
        insert(htbl,symb);
    }
}                {printf("Found ID\n");}
    | LOCAL ID   {
        if(lookupS(htbl,$2,scope)==NULL){
            symb = createSymbol($2,LOCALA,yylineno,scope);
            insert(htbl,symb);
        }
}               {printf("Found LOCAL ID\n");}
    | CCOLON ID    {
        if(lookupS(htbl,$2,scope)==NULL){
            symb = createSymbol($2,LOCALA,yylineno,scope);
            insert(htbl,symb);
        }
    }             {printf("Found ::ID\n");}
    | member                    {printf("Found member\n");}
    ;
member: lvalue DOT ID             {printf("Found lvalue .ID\n");}
    | lvalue L_SBRACKET expr R_SBRACKET  {printf("Found lvalue [ expr ]\n");}
    | call DOT ID                 {printf("Found call .ID\n");}
    | call L_SBRACKET expr R_SBRACKET    {printf("Found call [ expr ]\n");}
    ;
call: call L_PAR elist L_PAR    {printf("Found call ( elist )\n");}
    | lvalue callsuffix         {printf("Found lvalue callsuffix\n");}
    | L_PAR funcdef R_PAR L_PAR elist R_PAR  {printf("Found ( funcdef) ( elist )\n");}
    ;
callsuffix: normcall            {printf("Found normcall\n");}
    | methodcall                {printf("Found methodcall\n");}
    ;
normcall: L_PAR elist R_PAR     {printf("Found ( elist )\n");}
    ;
methodcall: DDOT ID L_PAR elist R_PAR     {printf("Found ..ID ( elist )\n");}
    ;
elist: expr             {printf("Found expr in list\n");}
    | elist COMMA expr  {printf("Found elist, expr in list\n");}
    | %empty            {printf("Empty elist\n");}
    ;
objectdef: L_SBRACKET elist R_SBRACKET   {printf("Found elist\n");}
    | L_SBRACKET indexed R_SBRACKET    {printf("Found indexed\n");}
    ;
indexed: indexedelem                 {printf("Found indexedelem\n");}
    | indexed COMMA indexedelem      {printf("Found indexedelem, indexedelem\n");}
    ;
indexedelem: L_BRACE expr COLON expr R_BRACE        {printf("Found indexed element\n");}
    ;
block: L_BRACE {scope++;} inblock R_BRACE  {scope--; hide(htbl,scope); printf("Found block\n");}
    ;
inblock: stmt inblock {printf("Found statement in block\n");}
    | %empty
;    
funcdef: FUNCTION funcid {
    if(!named){}
    else if(lookupS(htbl,$2,scope)==NULL){symb = createSymbol($2,USERFUNC,yylineno,scope);  insert(htbl,symb);}
    else{yyerror("Function to be defined already exists\n"); yyerrok;}
} 
    L_PAR {scope++;} idlist R_PAR {scope--;} block { hide(htbl,scope); printf("Found function definition\n");}
    ;
funcid: ID       {named = 1;}
    | %empty     {named = 0;}
    ;    
const: INTEGER | NUMBER | STRING | NIL | TRUE | FALSE 
    ;
idlist: ID  {
    if(lookupS(htbl,$1,scope)==NULL){symb = createSymbol($1,FORMAL,yylineno,scope);  insert(htbl,symb);}
    else{yyerror("Trying to redefine formal argument\n"); yyerrok;}
}            {printf("Found ID in list\n");}
    | idlist COMMA ID  {
        if(lookupS(htbl,$3,scope)==NULL){symb = createSymbol($3,FORMAL,yylineno,scope);  insert(htbl,symb);}
        else{yyerror("Trying to redefine formal argument\n"); yyerrok;}
}   {printf("Found ID in list, ID in list\n");}
    | %empty            {printf("Found empty idlist\n");}
    ;
ifstmt: IF L_PAR expr R_PAR {scope++;} stmt {scope--; hide(htbl,scope); printf("Found if statement\n");}
    | ifstmt ELSE {scope++;} stmt {scope--; hide(htbl,scope);} {printf("Found if statement\n");}
    ;
whilestmt: WHILE L_PAR expr R_PAR {scope++;} stmt            {scope--; hide(htbl,scope); printf("Found while statement\n");}
    ;
forstmt: FOR L_PAR elist SEMI expr SEMI elist R_PAR {scope++;} stmt   {scope--; hide(htbl,scope); printf("Found for statement\n");}
    ;
returnstmt: RETURN SEMI
    | RETURN expr SEMI              {printf("Found return statement\n");}
    ;

%%

int yyerror (char* yaccProvIDedMessage){
    fprintf(stderr,"%s: at line %d, before token: %s\n", yaccProvIDedMessage, yylineno, yytext);
    fprintf(stderr, "INPUT NOT VALID\n");
}

int main(int argc, char** argv){
    initializeTable(htbl);
    symb = malloc(sizeof(Symbol));
    if(argc>1){
        if(!(yyin = fopen(argv[1],"r"))){
            fprintf(stderr,"Cannot read file: %s\n", argv[1]);
            return 1;
        }
    }
    else yyin = stdin;

    yyparse();

    printTable(htbl);
    free(symb);
    return 0;     
}