%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "quad.h"

int yyerror(char* yaccProvidedMessage);
int alpha_yylex(void);

extern int yylineno;
extern char* yytext;
extern FILE* yyin;
extern quad* quads;
extern unsigned int total;
extern unsigned int currQuad;

SymTable **stbl; 
Sym *symbol;
symb *var;

int table_size=0;
int scope=0;
int anonymfcounter=0;
int status;
char buffer[64];
%}

%union{
    int intVal;
    char* string;
    double realVal;
    struct expr* exprValue;
    struct funccall* callValue;
    struct stmt* stmtValue;
}

%token <string>     STRING
%token <string>     ID
%token <intVal>     INTEGER 
%token <realVal>    FLOAT
%token <stmtValue>   BREAK CONT
%token <string>     IF ELSE WHILE FOR RET TRUE FALSE NIL FUNC LOCAL
%token <string>     LPAR RPAR LBRACE RBRACE LSQBRACE RSQBRACE 
%token <string>     ADD SUB MUL DIV MOD PPLUS MMINUS UMINUS
%token <string>     ASSIGN EQ NEQ AND OR NOT MORE MOREEQ LESS LESSEQ
%token <string>     SEMI DOT DDOT COLON CCOLON COMMA


%type <exprValue>       lvalue expr assignexpr term primary const funcdef
%type <exprValue>       ifstmt whilestmt forstmt member elist call objectdef
%type <exprValue>       indexed
%type <callValue>       methodcall normcall callsuffix  
%type <string>          program stmt returnstmt idlist
%type <string>          indexedelem block inblock 

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
                | returnstmt                            {if(scope==0) printf("Syntax Error in line %d cannot return outside of function\n",yylineno);
                                                         printf("Found return statement\n");
                                                        }
                | BREAK SEMI                            {if(scope==0) printf("Syntax Error in line %d cannot break outside of loop\n",yylineno);
                                                        printf("Found break\n");
                                                        }
                | CONT SEMI                             {if(scope==0) printf("Syntax Error in line %d cannot continue outside of function\n",yylineno);
                                                        printf("Found continue\n");
                                                        }
                | block                                 {printf("Found block\n");}
                | funcdef                               {printf("Found function definition\n");}
                | SEMI                                  {printf("Found semicolon\n");}                       
                ;

expr:           assignexpr                              {printf("Found assignment expression\n");}
                | expr ADD expr                         {printf("Found expression + expression\n");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = newtemp(); 
                                                         emit(add,$1,$3,$$,0,yylineno);
                                                        }
                | expr SUB expr                         {printf("Found expression - expression\n");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = newtemp(); 
                                                         emit(sub,$1,$3,$$,0,yylineno);
                                                        }
                | expr MUL expr                         {printf("Found expression * expression\n");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = newtemp(); 
                                                         emit(mul,$1,$3,$$,0,yylineno);
                                                        }
                | expr DIV expr                         {printf("Found expression / expression\n");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = newtemp(); 
                                                         emit(divd,$1,$3,$$,0,yylineno);
                                                        }
                | expr MOD expr                         {printf("Found expression MOD expression\n");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = newtemp(); 
                                                         emit(mod,$1,$3,$$,0,yylineno);
                                                        }
                | expr MORE expr                        {printf("Found expression > expression\n");
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_greater,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr MOREEQ expr                      {printf("Found expression >= expression\n"); 
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_greatereq,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr LESS expr                        {printf("Found expression < expression\n"); 
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_less,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr LESSEQ expr                      {printf("Found expression <= expression\n"); 
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_lesseq,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr EQ expr                          {printf("Found expression == expression\n");
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_eq,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr NEQ expr                         {printf("Found expression != expression\n");
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(if_noteq,$1,$3,$$,0,yylineno);
                                                         emit(assign,newexpr_constbool(0),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
                                                         emit(assign,newexpr_constbool(1),NULL,$$,0,yylineno);
                                                        }
                | expr AND expr                         {printf("Found expression && expression\n");
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(and,$1,$3,$$,0,yylineno);
                                                        }
                | expr OR expr                          {printf("Found expression || expression\n");
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(or,$1,$3,$$,0,yylineno);
                                                        }
                | term                                  {printf("Found term\n"); 
                                                         $$ = $1;
                                                        }
                ;

term:           LPAR expr RPAR                          {printf("Found (expression)\n");
                                                         $$ = $2;
                                                        }
                | SUB expr %prec UMINUS                 {printf("Found -expression\n");
                                                         check_arith($2,"");
                                                         $$ = newexpr(arithexpr_e);
                                                         $$->sym = istempexpr($2) ? $2->sym : newtemp();
                                                         emit(uminus,$2,NULL,$$,0,yylineno);
                                                        }
                | NOT expr                              {printf("Found !expression\n"); 
                                                         $$ = newexpr(boolexpr_e);
                                                         $$->sym = newtemp();
                                                         emit(not,$2,NULL,$$,0,yylineno);
                                                        }
                | PPLUS lvalue                          {printf("Found ++lvalue\n"); 
                                                         check_arith($2,NULL);
                                                         if($2->type == tableitem_e){
                                                            $$ = emit_iftableitem($2);
                                                            emit(add,$2, newexpr_constint(1),$$,0,yylineno);
                                                            emit(tablesetelem,$2,$2->index,$$,0,yylineno);
                                                         } else {
                                                            emit(add,$2,newexpr_constint(1),$$,0,yylineno);
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp();
                                                            emit(assign,$2,NULL,$2,0,yylineno);
                                                         }
                                                        }
                | lvalue PPLUS                          {printf("Found lvalue++\n"); 
                                                         check_arith($1,NULL);
                                                         $$ = newexpr(var_e);
                                                         $$->sym = newtemp();
                                                         if($1->type == tableitem_e){
                                                            expr* val = emit_iftableitem($1);
                                                            emit(assign, val, NULL, $$, 0, yylineno);
                                                            emit(add, val, newexpr_constint(1), val, 0,yylineno);
                                                            emit(tablesetelem,$1,$1->index,val,0,yylineno);
                                                         } else {
                                                            emit(assign,$1,NULL,$1,0,yylineno);
                                                            emit(add,$1,newexpr_constint(1),$1,0,yylineno);
                                                         }
                                                        }
                | MMINUS lvalue                         {printf("Found --lvalue\n"); 
                                                         check_arith($2,NULL);
                                                         if($2->type == tableitem_e){
                                                            $$ = emit_iftableitem($2);
                                                            emit(sub,$2, newexpr_constint(1),$$,0,yylineno);
                                                            emit(tablesetelem,$2,$2->index,$$,0,yylineno);
                                                         } else {
                                                            emit(sub,$2,newexpr_constint(1),$$,0,yylineno);
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp();
                                                            emit(assign,$2,NULL,$2,0,yylineno);
                                                         }
                                                        }
                | lvalue MMINUS                         {printf("Found lvalue--\n"); 
                                                         check_arith($1,NULL);
                                                         $$ = newexpr(var_e);
                                                         $$->sym = newtemp();
                                                         if($1->type == tableitem_e){
                                                            expr* val = emit_iftableitem($1);
                                                            emit(assign, val, NULL, $$, 0, yylineno);
                                                            emit(sub, val, newexpr_constint(1), val, 0,yylineno);
                                                            emit(tablesetelem,$1,$1->index,val,0,yylineno);
                                                         } else {
                                                            emit(assign,$1,NULL,$1,0,yylineno);
                                                            emit(sub,$1,newexpr_constint(1),$1,0,yylineno);
                                                         }
                                                        }
                | primary                               {printf("Found primary\n"); 
                                                         $$ = $1;
                                                        }
                ;

assignexpr:     lvalue ASSIGN expr                      {printf("Found lvalue=expression\n");
                                                         if($1->type==tableitem_e){
                                                            emit(tablesetelem,$1,$1->index,$3,0,yylineno);
                                                            $$=emit_iftableitem($1);
                                                            $$->type = assignexpr_e;
                                                         } else {
                                                            emit(assign,$3,NULL,$1,0,yylineno);
                                                            $$ = newexpr(assignexpr_e);
                                                            $$->sym = newtemp();
                                                            emit(assign,$1,NULL,$$,0,yylineno);
                                                         }
                                                        }
                ;

primary:        lvalue                                  {printf("Found lvalue\n"); 
                                                         $$ = emit_iftableitem($1);
                                                        }         
                | call                                  {printf("Found call\n"); }
                | objectdef                             {printf("Found object definition\n"); }
                | LPAR funcdef RPAR                     {printf("Found (function definition)\n"); 
                                                         $$ = newexpr(programfunc_e);
                                                         $$->sym = $2->sym;
                                                        }
                | const                                 {printf("Found const\n"); }
                ;

lvalue:         ID                                      {if(Search($1,scope,GLOBAL)==NULL){
                                                            if(scope) symbol = createSymbol($1,scope,yylineno,LLOCAL);
                                                            else symbol = createSymbol($1,scope,yylineno,GLOBAL);
                                                            Insert(symbol);
                                                            var = newsymbol($1);
                                                            var->space = currscopespace();
                                                            var->offset = currscopeoffset();
                                                            incurrscopeoffset();
                                                            $$ = lvalue_expr(var);
                                                         }
                                                         printf("Found id\n");
                                                        }
                | LOCAL ID                              {if(Search($2,scope,LLOCAL)==NULL){
                                                            symbol=createSymbol($2,scope,yylineno,LLOCAL);
                                                            Insert(symbol);
                                                            var = newsymbol($2);
                                                            var->space = currscopespace();
                                                            var->offset = currscopeoffset();
                                                            incurrscopeoffset();
                                                            $$ = lvalue_expr(var);
                                                         }
                                                         printf("Found local id\n"); 
                                                        }
                | CCOLON ID                             {if(Search($2,0,GLOBAL)==NULL){
                                                            snprintf(buffer,sizeof(buffer),"Error: No global variable %s exists\n",$2);
                                                            yyerror(buffer);
                                                            yyerrok;
                                                         }
                                                         else{
                                                            var = newsymbol($2);
                                                            var->space = currscopespace();
                                                            var->offset = currscopeoffset();
                                                            incurrscopeoffset();
                                                            $$  = lvalue_expr(var);
                                                         }
                                                         printf("Found ::id\n"); 
                                                        }
                | member                                {printf("Found member\n"); 
                                                         $$ = $1;
                                                        }
                ;

member:         lvalue DOT ID                           {printf("Found lvalue.id\n"); 
                                                         $$ = member_item($1,$3);
                                                        }
                | lvalue LSQBRACE expr RSQBRACE         {printf("Found lvalue[expression]\n"); 
                                                         $1 = emit_iftableitem($1);
                                                         $$ = newexpr(tableitem_e);
                                                         $$->sym = $1->sym;
                                                         $$->index = $3;
                                                        }
                | call DOT ID                           {printf("Found call.id\n"); }
                | call LSQBRACE expr RSQBRACE           {printf("Found call[expression]\n"); }
                ;

call:           call LPAR elist RPAR                    {printf("Found call(elist)\n");
                                                         $1 = make_call($1,$3);
                                                        }
                | lvalue callsuffix                     {printf("Found lvalue callsuffix\n"); 
                                                         $1 = emit_iftableitem($1);
                                                         if($2->method){
                                                            expr* t = $1;
                                                            $1 = emit_iftableitem(member_item(t,$2->name));
                                                            $2->elist->next = t;
                                                         }
                                                         $$ = make_call($1,$2->elist);
                                                        }
                | LPAR funcdef RPAR LPAR elist RPAR     {printf("Found (function definition)(elist)\n"); 
                                                         expr* func = newexpr(programfunc_e);
                                                         func->sym = $2->sym;
                                                         $$ = make_call(func,$5);
                                                        }
                ;

callsuffix:     normcall                                {printf("Found normal call\n"); 
                                                         $$ = $1;
                                                        }
                | methodcall                            {printf("Found method call\n"); 
                                                         $$ = $1;
                                                        }
                ;

normcall:       LPAR elist RPAR                         {printf("Found (elist)\n"); 
                                                         $$->elist = $2;
                                                         $$->method = 0;
                                                         $$->name = NULL;
                                                        }
                ;

methodcall:     DDOT ID LPAR elist RPAR                 {printf("Found ..id(elist)\n"); 
                                                         $$->elist= $4;
                                                         $$->method = 1;
                                                         $$->name = $2;
                                                        }
                ;

elist:          expr                                    {printf("Found expression\n"); } 
                | elist COMMA expr                      {printf("Found elist,expression\n"); }
                | %empty                                
                ;

const:          INTEGER                                  {printf("Found integer\n"); 
                                                          $$ = newexpr_constint($1); 
                                                         }
                | FLOAT                                  {printf("Found float\n"); 
                                                          $$ = newexpr_constdouble($1);
                                                         }
                | STRING                                 {printf("Found string\n"); 
                                                          $$ = newexpr_conststring($1);
                                                         }
                | NIL                                    {printf("Found nil\n"); 
                                                          $$ = newexpr_constnil();
                                                         }
                | TRUE                                   {printf("Found true\n"); 
                                                          $$ = newexpr_constbool('t');
                                                         }
                | FALSE                                  {printf("Found false\n"); 
                                                          $$ = newexpr_constbool('f');
                                                         }
                ;

objectdef:      LSQBRACE elist RSQBRACE                 {printf("Found [elist]\n"); 
                                                         expr* t = newexpr(newtable_e);
                                                         t->sym = newtemp();
                                                         emit(tablecreate,t,NULL,NULL,0,yylineno);
                                                         for(int i=0;$2;$2=$2->next){
                                                            emit(tablesetelem,t,newexpr_constint(i++),$2,0,yylineno);
                                                         }
                                                         $$ = t;
                                                        }
                | LSQBRACE indexed RSQBRACE             {printf("Found [indexed]\n"); 
                                                         expr* t = newexpr(newtable_e);
                                                         t->sym = newtemp();
                                                         emit(tablecreate,t,NULL,NULL,0,yylineno);
                                                         emit(tablesetelem,t,newexpr_constint(1),$2,0,yylineno);
                                                         /*for(int i=0;i<$2;i++){
                                                            
                                                         }*/
                                                         $$ = t;
                                                        }
                ;

indexed:        indexedelem                             {printf("Found indexed element\n"); }
                | indexed COMMA indexedelem             {printf("Found indexed, indexed element\n"); }
                | %empty                                
                ;

indexedelem:    LBRACE expr COLON expr RBRACE           {printf("Found {expression:expression}\n"); }
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
                LPAR {scope++;} idlist RPAR {scope--;} block {
                                                              printf("Found function id(id list) block\n"); 
                                                             }
                | FUNC {snprintf(buffer,sizeof(buffer),"$%d",anonymfcounter++);
                        symbol = createSymbol(buffer,scope,yylineno,USERFUNC);
                        Insert(symbol);
                       }
                LPAR {scope++;} idlist RPAR {scope--;} block {
                                                              printf("Found function(id list) block\n"); 
                                                             }
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

inblock:        inblock stmt                            {printf("Found statement in block\n");}
                | %empty
                ;

block:          LBRACE {scope++;} inblock RBRACE        {Hide(scope); 
                                                         scope--;                                                 
                                                         printf("Found {statement}\n"); 
                                                        }
                ;

ifstmt:         IF LPAR expr RPAR {scope++;} stmt       {Hide(scope);
                                                         scope--;
                                                         printf("Found if(expression) statement\n"); 
                                                        }
                | ifstmt ELSE {scope++;} stmt           {Hide(scope);
                                                         scope--;
                                                         printf("Found if(expression) statement else statement\n"); 
                                                        }
                ;

whilestmt:      WHILE LPAR expr RPAR {scope++;} stmt    {Hide(scope);
                                                         scope--;
                                                         printf("Found while(expression) statement\n"); 
                                                        }
                ;

forstmt:        FOR LPAR elist SEMI expr SEMI elist RPAR {scope++;} stmt    {Hide(scope);
                                                                             scope--;
                                                                             printf("Found for(elist;expression;elist) statement\n"); 
                                                                            }
                ;

returnstmt:     RET SEMI                                {printf("Found return;\n"); 
                                                         emit(ret,NULL,NULL,NULL,0,yylineno);
                                                        }
                | RET expr SEMI                         {printf("Found return expression;\n"); 
                                                         emit(ret,$2,NULL,NULL,0,yylineno);
                                                        }
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

    //PrintTable();
    printQuads();
    return 0;
}