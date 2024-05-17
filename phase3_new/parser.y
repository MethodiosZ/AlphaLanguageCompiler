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
int *if_jump_index; 
int else_jump_index = 0;
int *whilestartquad;
int *whileendjump;
int *forstartquad;
int *forjumpend;
int ifcounter=0;
int whilecounter=0;
int forcounter=0;
int breakquad=0;
expr *funcname;
int *funcendjump;
int funccounter=0;
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


%type <exprValue>       lvalue expr assignexpr term primary const 
%type <exprValue>       ifstmt whilestmt forstmt member elist call objectdef
%type <exprValue>       indexed indexedelem 
%type <exprValue>       funcdef idlist
%type <callValue>       methodcall normcall callsuffix  
%type <string>          program stmt returnstmt 
%type <string>          block inblock 

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

stmt:           expr SEMI                                {printf("Found expression\n");
                                                          resettemp();
                                                         }
                | ifstmt                                 {printf("Found if statement\n");
                                                          resettemp();
                                                         }
                | whilestmt                              {printf("Found while statement\n");
                                                          resettemp();
                                                         }
                | forstmt                                {printf("Found for statement\n");
                                                          resettemp();
                                                         }
                | returnstmt                            {if(funccounter==0) printf("Syntax Error in line %d cannot return outside of function\n",yylineno);
                                                         printf("Found return statement\n");
                                                         resettemp();
                                                        }
                | BREAK SEMI                            {if(whilecounter!=scope && forcounter != scope){
                                                            printf("Syntax Error in line %d cannot break outside of loop\n",yylineno);
                                                         }
                                                         if(whilecounter>0 || forcounter>0){
                                                            breakquad = nextquad();
                                                            emit(jump,NULL,NULL,NULL,0,yylineno);           
                                                         }
                                                         else{
                                                            printf("Syntax Error in line %d cannot break outside of loop\n",yylineno);
                                                         }
                                                         printf("Found break\n");
                                                         resettemp();
                                                        }
                | CONT SEMI                             {if(whilecounter!=scope && forcounter != scope){
                                                            printf("Syntax Error in line %d cannot continue outside of loop\n",yylineno);
                                                         }
                                                         if(whilecounter>0){
                                                            emit(jump,NULL,NULL,NULL,whilestartquad[whilecounter-1],yylineno);            
                                                         }
                                                         else if(forcounter>0){
                                                            emit(jump,NULL,NULL,NULL,forstartquad[forcounter-1],yylineno);
                                                         }
                                                         else{
                                                            printf("Syntax Error in line %d cannot continue outside of loop\n",yylineno);
                                                         }
                                                        printf("Found continue\n");
                                                        resettemp();
                                                        }
                | block                                  {printf("Found block\n");
                                                          resettemp();
                                                         }
                | funcdef                                {printf("Found function definition\n");
                                                          resettemp();
                                                         }
                | SEMI                                   {printf("Found semicolon\n");
                                                          resettemp();
                                                         }                       
                ;

expr:           assignexpr                              {printf("Found assignment expression\n");}
                | expr ADD expr                         {printf("Found expression + expression\n");
                                                         check_arith($1,"");
                                                         check_arith($3,"");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         } 
                                                         else{
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(add,$1,$3,$$,0,yylineno);
                                                        }
                | expr SUB expr                         {printf("Found expression - expression\n");
                                                         check_arith($1,"");
                                                         check_arith($3,"");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(sub,$1,$3,$$,0,yylineno);
                                                        }
                | expr MUL expr                         {printf("Found expression * expression\n");
                                                         check_arith($1,"");
                                                         check_arith($3,"");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(mul,$1,$3,$$,0,yylineno);
                                                        }
                | expr DIV expr                         {printf("Found expression / expression\n");
                                                         check_arith($1,"");
                                                         check_arith($3,"");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(divd,$1,$3,$$,0,yylineno);
                                                        }
                | expr MOD expr                         {printf("Found expression MOD expression\n");
                                                         check_arith($1,"");
                                                         check_arith($3,"");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(mod,$1,$3,$$,0,yylineno);
                                                        }
                | expr MORE expr                        {printf("Found expression > expression\n");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_greater,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr MOREEQ expr                      {printf("Found expression >= expression\n"); 
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_greatereq,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr LESS expr                        {printf("Found expression < expression\n"); 
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_less,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr LESSEQ expr                      {printf("Found expression <= expression\n"); 
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_lesseq,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr EQ expr                          {printf("Found expression == expression\n");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_eq,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr NEQ expr                         {printf("Found expression != expression\n");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_noteq,$1,$3,NULL,nextquad()+3,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+4,yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL,$$,0,yylineno);
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$,0,yylineno);
                                                        }
                | expr AND expr                         {printf("Found expression and expression\n");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_eq,newexpr_constbool('T'),NULL,$1, nextquad()+3, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+6, yylineno);
                                                         emit(if_eq,newexpr_constbool('T'),NULL,$3, nextquad()+3, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+4, yylineno);
                                                         emit(assign, newexpr_constbool('T'),NULL,$$, 0, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+3, yylineno);
                                                         emit(assign,newexpr_constbool('F'),NULL,$$, 0, yylineno);
                                                        }
                | expr OR expr                          {printf("Found expression or expression\n");
                                                         if(istempexpr($1)){
                                                            $$ = $1;
                                                         }
                                                         else if(istempexpr($3)){
                                                            $$ = $3;
                                                         }  
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_eq, newexpr_constbool('T'),NULL,$1, nextquad()+5, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+2, yylineno);
                                                         emit(if_eq, newexpr_constbool('T'),NULL,$3, nextquad()+3, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+4, yylineno);
                                                         emit(assign, newexpr_constbool('T'),NULL,$$, 0, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+3, yylineno);
                                                         emit(assign, newexpr_constbool('F'),NULL,$$, 0, yylineno);
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
                | NOT expr                              {printf("Found not expression\n"); 
                                                         if(istempexpr($2)){
                                                            $$ = $2;
                                                         }
                                                         else{
                                                            $$ = newexpr(boolexpr_e);
                                                            $$->sym = newtemp(); 
                                                         }
                                                         emit(if_eq, newexpr_constbool('T'), NULL,$2, nextquad()+5, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+2, yylineno);
                                                         emit(assign,newexpr_constbool('T'),NULL, $$, 0, yylineno);
                                                         emit(jump, NULL, NULL, NULL, nextquad()+3, yylineno);
                                                         emit(assign,newexpr_constbool('F'), NULL,$$, 0, yylineno);
                                                        }
                | PPLUS lvalue                          {printf("Found ++lvalue\n"); 
                                                         check_arith($2,NULL);
                                                         if($2->type == tableitem_e){
                                                            $$ = emit_iftableitem($2);
                                                            emit(add,$$, newexpr_constint(1),$$,0,yylineno);
                                                            emit(tablesetelem,$2->index,$$,$2,0,yylineno);
                                                         } else {
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp();
                                                            emit(add,$2,newexpr_constint(1),$2,0,yylineno);
                                                            emit(assign,$2,NULL,$$,0,yylineno);
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
                                                            emit(tablesetelem,$1->index,val,$1,0,yylineno);
                                                         } else {
                                                            emit(assign,$1,NULL,$$,0,yylineno);
                                                            emit(add,$1,newexpr_constint(1),$1,0,yylineno);
                                                         }
                                                        }
                | MMINUS lvalue                         {printf("Found --lvalue\n"); 
                                                         check_arith($2,NULL);
                                                         if($2->type == tableitem_e){
                                                            $$ = emit_iftableitem($2);
                                                            emit(sub,$$, newexpr_constint(1),$$,0,yylineno);
                                                            emit(tablesetelem,$2->index,$$,$2,0,yylineno);
                                                         } else {
                                                            $$ = newexpr(arithexpr_e);
                                                            $$->sym = newtemp();
                                                            emit(sub,$2,newexpr_constint(1),$2,0,yylineno);
                                                            emit(assign,$2,NULL,$$,0,yylineno);
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
                                                            emit(tablesetelem,$1->index,val,$1,0,yylineno);
                                                         } else {
                                                            emit(assign,$1,NULL,$$,0,yylineno);
                                                            emit(sub,$1,newexpr_constint(1),$1,0,yylineno);
                                                         }
                                                        }
                | primary                               {printf("Found primary\n"); 
                                                         $$ = $1;
                                                        }
                ;

assignexpr:     lvalue ASSIGN expr                      {printf("Found lvalue=expression\n");
                                                         if($1->type==tableitem_e){
                                                            emit(tablesetelem,$1->index,$3,$1,0,yylineno);
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
                                                         else{
                                                            symbol = Search($1,scope,GLOBAL);
                                                            var = SymTableItemtoQuadItem(symbol);
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
                                                         if($1==NULL){
                                                            printf("lvalue at line %d not declared\n",yylineno);
                                                         }
                                                         else if($1->sym->type == programfunc_s || $1->sym->type == libraryfunc_s ){
                                                            printf("Invalid member call at line %d, function name \n",yylineno);
                                                         }
                                                         $$ = member_item($1,$3);
                                                        }
                | lvalue LSQBRACE expr RSQBRACE         {printf("Found lvalue[expression]\n"); 
                                                         if($1==NULL){
                                                            printf("lvalue at line %d not declared\n",yylineno);
                                                         }
                                                         else if($1->sym->type == programfunc_s || $1->sym->type == libraryfunc_s ){
                                                            printf("Invalid lvalue array at line %d, function name \n",yylineno);
                                                         }
                                                         $1 = emit_iftableitem($1);
                                                         $$ = newexpr(tableitem_e);
                                                         $$->sym = $1->sym;
                                                         $$->index = $3;
                                                        }
                | call DOT ID                            {printf("Found call.id\n"); 
                                                          $$ = member_item($1,$3);
                                                         }
                | call LSQBRACE expr RSQBRACE            {printf("Found call[expression]\n"); 
                                                          $1 = emit_iftableitem($1);
                                                          $$ = newexpr(tableitem_e);
                                                          $$->sym = $1->sym;
                                                          $$->index = $3;
                                                         }
                ;

call:           call LPAR elist RPAR                    {printf("Found call(elist)\n");
                                                         $1 = make_call($1,$3);
                                                        }
                | lvalue callsuffix                     {printf("Found lvalue callsuffix\n"); 
                                                         $1 = emit_iftableitem($1);
                                                         if($2->method){
                                                            expr *t = $1;
                                                            $1 = emit_iftableitem(member_item(t,$2->name));
                                                            expr *tmp;
                                                            if($2->elist != NULL){
                                                               tmp = $2->elist;
                                                               while(tmp->next != NULL){
                                                                  tmp = tmp->next;
                                                               }
                                                               tmp->next = NULL;
                                                               t->next = $2->elist;
                                                               $2->elist = t;
                                                            }
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
                                                         $$  = malloc(sizeof(fcall));
                                                         $$->elist = $2;
                                                         $$->method = 0;
                                                         $$->name = NULL;
                                                        }
                ;

methodcall:     DDOT ID LPAR elist RPAR                 {printf("Found ..id(elist)\n"); 
                                                         $$  = malloc(sizeof(fcall));
                                                         $$->elist= $4;
                                                         $$->method = 1;
                                                         $$->name = $2;
                                                        }
                ;

elist:          expr                                     {printf("Found expression\n"); 
                                                          $$ = $1;
                                                          $$->next = NULL;
                                                         } 
                | elist COMMA expr                       {printf("Found elist,expression\n"); 
                                                          expr *t;
                                                          if($1!=NULL&&$3!=NULL){
                                                            t=$1;
                                                            while(t->next){
                                                               t=t->next;
                                                            }
                                                            t->next=$3;
                                                            $3->next=NULL;
                                                            $$=$1;
                                                          }
                                                         }
                | %empty                                 {$$=NULL;}
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
                                                          $$ = newexpr_constbool('T');
                                                         }
                | FALSE                                  {printf("Found false\n"); 
                                                          $$ = newexpr_constbool('F');
                                                         }
                ;

objectdef:      LSQBRACE elist RSQBRACE                 {printf("Found [elist]\n"); 
                                                         expr* t = newexpr(newtable_e);
                                                         t->sym = newtemp();
                                                         emit(tablecreate,NULL,NULL,t,0,yylineno);
                                                         for(int i=0;$2;$2=$2->next){
                                                            emit(tablesetelem,newexpr_constint(i++),$2,t,0,yylineno);
                                                         }
                                                         $$ = t;
                                                        }
                | LSQBRACE indexed RSQBRACE             {printf("Found [indexed]\n"); 
                                                         expr* t = newexpr(newtable_e);
                                                         t->sym = newtemp();
                                                         emit(tablecreate,NULL,NULL,t,0,yylineno);
                                                         for(int i=0;$2;$2=$2->next){
                                                            emit(tablesetelem,$2->index,$2,t,0,yylineno);
                                                         }
                                                         $$ = t;
                                                        }
                ;

indexed:        indexedelem                              {printf("Found indexed element\n"); 
                                                          $$ = $1;
                                                         }
                | indexed COMMA indexedelem              {printf("Found indexed, indexed element\n"); 
                                                          while($1->next){
                                                            $1 = $1->next;
                                                          }
                                                          $1->next = $3;
                                                         }
                | %empty                                
                ;

indexedelem:    LBRACE expr COLON expr RBRACE            {printf("Found {expression:expression}\n");
                                                          $4->index = $2;
                                                          $$ = $4;
                                                         }
                ;



funcdef:        FUNC ID {if(funccounter==0){
                           funcendjump = (int*)calloc(1,sizeof(int));
                         }
                         else if(funccounter>0){
                           funcendjump = realloc(funcendjump,sizeof(int)*funccounter+1);
                         }
                         if(Search($2,scope,USERFUNC)==NULL){
                            symbol = createSymbol($2,scope,yylineno,USERFUNC);
                            Insert(symbol);
                            var = newsymbol($2);
                            var->space = currscopespace();
                            var->offset = currscopeoffset();
                            incurrscopeoffset();
                            funcname = newexpr(programfunc_e);
                            funcname->sym = var;
                            funcendjump[funccounter++]=nextquad();
                            emit(jump,NULL,NULL,NULL,0,yylineno);
                            emit(funcstart,NULL,NULL,funcname,0,yylineno);
                         }
                         else{
                            yyerror("Function already exists\n");
                            yyerrok;
                            symbol = Search($2,scope,USERFUNC);
                            var = SymTableItemtoQuadItem(symbol);
                            funcname = newexpr(programfunc_e);
                            funcname->sym = var;
                            funcendjump[funccounter++]=nextquad();
                            emit(jump,NULL,NULL,NULL,0,yylineno);
                            emit(funcstart,NULL,NULL,funcname,0,yylineno);
                         }
                        }
                LPAR {scope++;} idlist RPAR {scope--;} block   {emit(funcend,NULL,NULL,funcname,0,yylineno);
                                                                patchlabel(funcendjump[--funccounter],nextquad()+1);
                                                                $$=funcname;
                                                                printf("Found function id(id list) block\n"); 
                                                               }

                | FUNC {if(funccounter==0){
                           funcendjump = (int*)calloc(1,sizeof(int));
                         }
                         else if(funccounter>0){
                           funcendjump = realloc(funcendjump,sizeof(int)*funccounter+1);
                         }
                        snprintf(buffer,sizeof(buffer),"$%d",anonymfcounter++);
                        symbol = createSymbol(buffer,scope,yylineno,USERFUNC);
                        Insert(symbol);
                        var = SymTableItemtoQuadItem(symbol);
                        funcname = newexpr(programfunc_e);
                        funcname->sym = var;
                        funcendjump[funccounter++]=nextquad();
                        emit(jump,NULL,NULL,NULL,0,yylineno);
                        emit(funcstart,NULL,NULL,funcname,0,yylineno);
                       }
                LPAR {scope++;} idlist RPAR {scope--;} block {emit(funcend,NULL,NULL,funcname,0,yylineno);
                                                              patchlabel(funcendjump[--funccounter],nextquad()+1);
                                                              $$=funcname;
                                                              printf("Found function(id list) block\n"); 
                                                             }
                ;

idlist:         ID                                      {if(Search($1,scope,FORMAL)==NULL){
                                                            symbol=createSymbol($1,scope,yylineno,FORMAL);
                                                            Insert(symbol);
                                                            var = newsymbol($1);
                                                            var->space = currscopespace();
                                                            var->offset = currscopeoffset();
                                                            incurrscopeoffset();
                                                            $$ = newexpr(var_e);
                                                            $$->sym = var;
                                                         }
                                                         else{
                                                            yyerror("Formal argument already exists\n");
                                                            yyerrok;
                                                            symbol=Search($1,scope,FORMAL);
                                                            var = SymTableItemtoQuadItem(symbol);
                                                            $$ = newexpr(var_e);
                                                            $$->sym = var;
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

ifstmt:         IF LPAR expr RPAR                        {scope++;
                                                          emit(if_eq,$3,newexpr_constbool('T'),NULL,nextquad()+3,yylineno);
                                                          if(ifcounter==0){
                                                            if_jump_index = (int*)calloc(1,sizeof(int));
                                                          }
                                                          else if(ifcounter>0){
                                                            if_jump_index = realloc(if_jump_index,sizeof(int)*ifcounter+1);
                                                          }
                                                          if_jump_index[ifcounter++] = nextquad();
                                                          emit(jump,NULL,NULL,NULL,0,yylineno); 
                                                         }
               stmt                                      {Hide(scope);
                                                         scope--;
                                                         printf("Found if(expression) statement\n");
                                                         patchlabel(if_jump_index[--ifcounter],nextquad()+1); 
                                                         }
                | ifstmt ELSE                            {scope++;
                                                          else_jump_index = nextquad();
                                                          emit(jump,NULL,NULL,NULL,0,yylineno);
                                                          patchlabel(if_jump_index[ifcounter],nextquad()+1); 
                                                         } 
                stmt                                     {Hide(scope);
                                                         patchlabel(else_jump_index,nextquad()+1); 
                                                         scope--;
                                                         printf("Found if(expression) statement else statement\n"); 
                                                        }
                ;

whilestmt:      WHILE LPAR                              {if(whilecounter==0){
                                                            whilestartquad = (int*)calloc(1,sizeof(int));
                                                            whileendjump = (int*)calloc(1,sizeof(int));
                                                          }
                                                          else if(whilecounter>0){
                                                            whilestartquad = realloc(whilestartquad,sizeof(int)*whilecounter+1);
                                                            whileendjump = realloc(whileendjump,sizeof(int)*whilecounter+1);
                                                          }
                                                         whilestartquad[whilecounter]=nextquad()+1;
                                                        }
                expr RPAR                               {scope++;
                                                         emit(if_eq,newexpr_constbool('T'),NULL,$4,nextquad()+3,yylineno);
                                                         whileendjump[whilecounter++]=nextquad();
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                        } 
                stmt                                    {Hide(scope);
                                                         scope--;
                                                         printf("Found while(expression) statement\n");
                                                         emit(jump,NULL,NULL,NULL,whilestartquad[--whilecounter],yylineno);
                                                         patchlabel(whileendjump[whilecounter],nextquad()+1);
                                                         if(breakquad!=0){
                                                            patchlabel(breakquad,nextquad()+1);
                                                            breakquad=0;
                                                         }
                                                        }
                ;

forstmt:        FOR LPAR elist SEMI expr SEMI           {if(forcounter==0){
                                                            forstartquad = (int*)calloc(1,sizeof(int));
                                                            forjumpend = (int*)calloc(1,sizeof(int));
                                                          }
                                                          else if(forcounter>0){
                                                            forstartquad = realloc(forstartquad,sizeof(int)*forcounter+1);
                                                            forjumpend = realloc(forjumpend,sizeof(int)*forcounter+1);
                                                          }
                                                         emit(if_eq,newexpr_constbool('T'),NULL,$5,nextquad()+5,yylineno);
                                                         forjumpend[forcounter]=nextquad();
                                                         emit(jump,NULL,NULL,NULL,nextquad()+3,yylineno);
                                                         forstartquad[forcounter++]=nextquad()+1;
                                                        }
                elist RPAR                              {scope++;
                                                         emit(jump,NULL,NULL,NULL,nextquad()-2,yylineno);
                                                        } 
                stmt                                    {Hide(scope);
                                                         scope--;
                                                         emit(jump,NULL,NULL,NULL,forstartquad[--forcounter],yylineno);
                                                         patchlabel(forjumpend[forcounter],nextquad()+1);
                                                         if(breakquad!=0) {
                                                            patchlabel(breakquad,nextquad()+1);
                                                            breakquad=0;
                                                         }
                                                         printf("Found for(elist;expression;elist) statement\n"); 
                                                        }
                ;

returnstmt:     RET SEMI                                {printf("Found return;\n"); 
                                                         emit(ret,NULL,NULL,NULL,0,yylineno);
                                                        }
                | RET expr SEMI                         {printf("Found return expression;\n"); 
                                                         emit(ret,NULL,NULL,$2,0,yylineno);
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