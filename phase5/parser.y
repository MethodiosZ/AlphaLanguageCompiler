%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "quad.h"

int yyerror(const char* yaccProvIDedMessage);
int yylex (void);

extern int yylineno;
extern  char* yytext;
extern FILE* yyin;
Symbol * htbl[HASH_SIZE];
Symbol * symb;
Variable *sym;
extern quad* quads;
extern unsigned int total;
extern unsigned int currQuad;

int scope = 0;
int named = 1;
%}

%error-verbose

%start program

%union{
    char* stringValue;
    int intValue;
    double numValue;
    struct expression* exprValue;
    struct call* callValue;
}

%token <stringValue>    ID
%token <stringValue>    LOCAL
%token <stringValue>    STRING
%token <intValue>       INTEGER
%token <numValue>       NUMBER
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

%type <exprValue>       lvalue expr assignexpr term primary const funcdef member elist 
%type <callValue>       methodcall normcall callsuffix     
%type <stringValue>     stmt op call objectdef indexed indexedelem block inblock funcid idlist   
%type <stringValue>     returnstmt program 
%type <exprValue>       ifstmt whilestmt forstmt

%%

program: stmt program                  
{
    printf("Found program\n");
}
    | %empty
    ;
stmt: expr SEMI                 
{
    printf("Found expr\n");
}
    | ifstmt                    
{
    printf("Found ifstmt\n");
}
    | whilestmt                 
{
    printf("Found whilestmt\n");
}
    | forstmt                   
{
    printf("Found forstmt\n");
}
    | returnstmt                
{
    printf("Found returnstmt\n");
}
    | BREAK SEMI                
{
    printf("Found break\n");
}
    | CONTINUE SEMI             
{
    printf("Found continue\n");
}
    | block                     
{
    printf("Found block\n");
}
    | funcdef                   
{
    printf("Found funcdef\n");
}
    | SEMI                      
{
    printf("Found semicolon\n");
}
    ;
expr: assignexpr                
{
    printf("Found assignexpr\n");
}
    | expr PLUS expr              
{
    $$ = newexpr(arithexpr_e);
    $$->sym = newtemp();
    emit(add,$1,$3,$$,NULL,yylineno);
    printf("Found expr + expr\n");  
}
    | expr MINUS expr              
{
    $$ = newexpr(arithexpr_e);
    $$->sym = newtemp();
    emit(sub,$1,$3,$$,NULL,yylineno);
    printf("Found expr - expr\n");  
}
    | expr MUL expr              
{
    $$ = newexpr(arithexpr_e);
    $$->sym = newtemp();
    emit(mul,$1,$3,$$,NULL,yylineno);
    printf("Found expr * expr\n");  
}
    | expr DIV expr              
{
    $$ = newexpr(arithexpr_e);
    $$->sym = newtemp();
    emit(divide,$1,$3,$$,NULL,yylineno);
    printf("Found expr / expr\n");  
}
    | expr MOD expr              
{
    $$ = newexpr(arithexpr_e);
    $$->sym = newtemp(); 
    emit(mod,$1,$3,$$,NULL,yylineno);
    printf("Found expr MOD expr\n"); 
}
    | expr GT expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_greater,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr > expr\n");  
}
    | expr GTEQ expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_greatereq,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr >= expr\n");
}
    | expr LT expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_less,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr < expr\n");
}
    | expr LTEQ expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_lesseq,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr <= expr\n"); 
}
    | expr EQ expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_eq,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr == expr\n");
}
    | expr NEQ expr             
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(if_noteq,$1,$3,$$,NULL,yylineno);
    emit(assign,newexpr_constbool(0),NULL,$$,NULL,yylineno);
    emit(jump,NULL,NULL,NULL,nextquad()+2,yylineno);
    emit(assign,newexpr_constbool(1),NULL,$$,NULL,yylineno);
    printf("Found expr != expr\n"); 
}
    | expr AND expr              
{
    $$  = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(and,$1,$3,$$,NULL,yylineno);
    printf("Found expr AND expr\n");  
}
    | expr OR expr              
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(or,$1,$3,$$,NULL,yylineno);
    printf("Found expr OR expr\n");  
}
    | term                      
{
    $$=$1;
    printf("Found term\n"); 
}
    ;

op:   PLUS | MINUS | MUL | DIV | MOD | GT | GTEQ | LT | LTEQ | EQ | NEQ | AND | OR
    ;

term: L_PAR expr R_PAR          
{
    $$= $2;
    printf("Found ( expr )\n");  
}
    | MINUS expr %prec UMINUS   
{
    check_arith($2,NULL);
    $$ = newexpr(arithexpr_e);
    $$->sym = istempexpr($2) ? $2->sym : newtemp();
    emit(uminus,$2,NULL,$$,NULL,yylineno);
    printf("Found - expr\n"); 
}
    | NOT expr                  
{
    $$ = newexpr(boolexpr_e);
    $$->sym = newtemp();
    emit(not,$2,NULL,$$,NULL,yylineno);
    printf("Found not expr\n"); 
}
    | PPLUS lvalue             
{
    check_arith($2,NULL);
    if($2->type == tableitem_e){
        $$ = emit_iftableitem($2);
        emit(add,$2, newexpr_constnum(1),$$,NULL,yylineno);
        emit(tablesetelem,$2,$2->index,$$,NULL,yylineno);
    } else {
        emit(add,$2,newexpr_constnum(1),$1,NULL,yylineno);
        $$ = newexpr(arithexpr_e);
        $$->sym = newtemp();
        emit(assign,$2,NULL,$2,NULL,yylineno);
    }
    printf("Found ++lvalue\n");
}
    | lvalue PPLUS              
{
    check_arith($1,NULL);
    $$ = newexpr(var_e);
    $$->sym = newtemp();
    if($1->type == tableitem_e){
        expr* val = emit_iftableitem($1);
        emit(assign, val, NULL, $$, NULL, yylineno);
        emit(add, val, newexpr_constnum(1), val, NULL,yylineno);
        emit(tablesetelem,$1,$1->index,val,NULL,yylineno);
    } else {
        emit(assign,$1,NULL,$1,NULL,yylineno);
        emit(add,$1,newexpr_constnum(1),$1,NULL,yylineno);
    }
    printf("Found lvalue++\n");
}
    | MMINUS lvalue             
{
    check_arith($2,NULL);
    if($2->type == tableitem_e){
        $$ = emit_iftableitem($2);
        emit(sub,$2, newexpr_constnum(1),$$,NULL,yylineno);
        emit(tablesetelem,$2,$2->index,$$,NULL,yylineno);
    } else {
        emit(sub,$2,newexpr_constnum(1),$2,NULL,yylineno);
        $$ = newexpr(arithexpr_e);
        $$->sym = newtemp();
        emit(assign,$2,NULL,$2,NULL,yylineno);
    }
    printf("Found --lvalue\n");
}
    | lvalue MMINUS             
{
    check_arith($1,NULL);
    $$ = newexpr(var_e);
    $$->sym = newtemp();
    if($1->type == tableitem_e){
        expr* val = emit_iftableitem($1);
        emit(assign, val, NULL, $$, NULL, yylineno);
        emit(sub, val, newexpr_constnum(1), val, NULL,yylineno);
        emit(tablesetelem,$1,$1->index,val,NULL,yylineno);
    } else {
        emit(assign,$1,NULL,$1,NULL,yylineno);
        emit(sub,$1,newexpr_constnum(1),$1,NULL,yylineno);
    }
    printf("Found lvalue--\n");
}
    | primary                   
{
    $$ = $1;
    printf("Found primary\n");
}
    ;
assignexpr: lvalue ASSIGN expr  
{
    if($1->type==tableitem_e){
        emit(tablesetelem,$1,$1->index,$3,NULL,yylineno);
        $$=emit_iftableitem($1);
        $$->type = assignexpr_e;
    } else {
        emit(assign,$3,NULL,$1,NULL,yylineno);
        $$ = newexpr(assignexpr_e);
        $$->sym = newtemp();
        emit(assign,$1,NULL,$$,NULL,yylineno);
    }
    printf("Found assignment\n");
}
    ;
primary: lvalue                
{
    $$ = emit_iftableitem($1);
    printf("Found lvalue\n");
}
    | call                      
{
    printf("Found call\n");
}
    | objectdef                 
{
    printf("Found objectdef\n");
}
    | L_PAR funcdef R_PAR       
{
    $$ = newexpr(programfunc_e);
    $$->sym = $2;
    printf("Found ( funcdef )\n");
}
    | const                     
{
    printf("Found const\n");
}
    ;
lvalue: ID      
{
    if(lookupS(htbl,$1,scope)==NULL){
        if(scope == 0){symb = createSymbol($1,GLOBAL,yylineno,scope);} 
        else {symb = createSymbol($1,LOCALA,yylineno,scope);}
        insert(htbl,symb);
        sym = newsymbol($1);
        sym->scopespace = currscopespace();
        sym->offset = currscopeoffset();
        incurrscopeoffset();
    }
    $1 = lvalue_expr(sym);
    printf("Found ID\n");
}               
    | LOCAL ID   
{
        if(lookupS(htbl,$2,scope)==NULL){
            symb = createSymbol($2,LOCALA,yylineno,scope);
            insert(htbl,symb);
            sym = newsymbol($2);
            sym->scopespace = currscopespace();
            sym->offset = currscopeoffset();
            incurrscopeoffset();
        } else { printf("Warning function symbol"); }
        $2 = lvalue_expr(sym);
        printf("Found LOCAL ID\n");
}
    | CCOLON ID    
{
        if(lookupS(htbl,$2,scope)==NULL){
            symb = createSymbol($2,LOCALA,yylineno,scope);
            insert(htbl,symb); 
            sym = newsymbol($2);
            sym->scopespace = currscopespace();
            sym->offset = currscopeoffset();
            incurrscopeoffset();
        }
        $2 = lvalue_expr(sym);
        printf("Found ::ID\n");
}
    | member                    
{
        $$ = $1;
        printf("Found member\n");
}
    ;
member: lvalue DOT ID             
{

    $$ = member_item($1,$3);
    printf("Found lvalue .ID\n");
}
    | lvalue L_SBRACKET expr R_SBRACKET  
{
    $1 = emit_iftableitem($1);
    $$ = newexpr(tableitem_e);
    $$->sym = $1->sym;
    $$->index = $3;
    printf("Found lvalue [ expr ]\n");
}
    | call DOT ID                 
{
    printf("Found call .ID\n");
}
    | call L_SBRACKET expr R_SBRACKET    
{
    printf("Found call [ expr ]\n");
}
    ;
call: call L_PAR elist L_PAR    
{
    $1 = make_call($1,$3);
    printf("Found call ( elist )\n");
}
    | lvalue callsuffix         
{
    $1 = emit_iftableitem($1);
    if($2->method){
        expr* t = $1;
        $1 = emit_iftableitem(member_item(t,$2->name));
        $2->elist->next = t;
    }
    $$ = make_call($1,$2->elist);
    printf("Found lvalue callsuffix\n");
}
    | L_PAR funcdef R_PAR L_PAR elist R_PAR  
{
    expr* func = newexpr(programfunc_e);
    func->sym = $2;
    $$ = make_call(func,$5);
    printf("Found ( funcdef) ( elist )\n");
}
    ;
callsuffix: normcall            
{
    $$ = $1;
    printf("Found normcall\n");
}
    | methodcall                
{
    $$ = $1;
    printf("Found methodcall\n");
}
    ;
normcall: L_PAR elist R_PAR     
{
    $$->elist = $2;
    $$->method = 0;
    $$->name = NULL;
    printf("Found ( elist )\n");
}
    ;
methodcall: DDOT ID L_PAR elist R_PAR     
{   
    $$->elist = $4;
    $$->method  = 1;
    $$->name = $2;
    printf("Found ..ID ( elist )\n");
}
    ;
elist: expr             
{
    printf("Found expr in list\n");
}
    | elist COMMA expr  
{
    printf("Found elist, expr in list\n");
}
    | %empty            
{
    printf("Empty elist\n");
}
    ;
objectdef: L_SBRACKET elist R_SBRACKET   
{
    expr* t = newexpr(newtable_e);
    t->sym = newtemp();
    emit(tablecreate, t, NULL, NULL, NULL, yylineno);
    for(int i = 0; $2 ; $2=$2->next){
        emit(tablesetelem,t,newexpr_constnum(i++),$2,NULL,yylineno);
    }
    $$ = t; 
    printf("Found elist\n");
}
    | L_SBRACKET indexed R_SBRACKET    
{
    expr* t = newexpr(newtable_e);
    t->sym = newtemp();
    emit(tablecreate, t, NULL, NULL, NULL, yylineno);
    for(int i=0;i<$2;i++){
        emit(tablesetelem,t,i,$2,NULL,yylineno);
    }
    $$ = t;
    printf("Found indexed\n");
}
    ;
indexed: indexedelem                 
{
    printf("Found indexedelem\n");
}
    | indexed COMMA indexedelem      
{
    printf("Found indexedelem, indexedelem\n");
}
    ;
indexedelem: L_BRACE expr COLON expr R_BRACE        
{
    printf("Found indexed element\n");
}
    ;
block: L_BRACE 
{
    scope++;
}   inblock R_BRACE  
{
    scope--; 
    hide(htbl,scope); 
    printf("Found block\n");
}
    ;
inblock: stmt inblock 
{
    printf("Found statement in block\n");
}
    | %empty
    ;    
funcdef: FUNCTION funcid 
{
    if(!named){}
    else if(lookupS(htbl,$2,scope)==NULL){symb = createSymbol($2,USERFUNC,yylineno,scope);  insert(htbl,symb);}
    else{yyerror("Function to be defined already exists\n"); yyerrok;}
} 
    L_PAR 
{
    scope++;
} 
    idlist R_PAR 
{
    scope--;
} 
    block 
{ 
    hide(htbl,scope); 
    printf("Found function definition\n");
}
    ;
funcid: ID       
{
    named = 1;
}
    | %empty     
{
    named = 0;
}
    ;    
const: INTEGER | NUMBER | STRING | NIL | TRUE | FALSE 
    ;
idlist: ID  
{
    if(lookupS(htbl,$1,scope)==NULL){symb = createSymbol($1,FORMAL,yylineno,scope);  insert(htbl,symb);}
    else{yyerror("Trying to redefine formal argument\n"); yyerrok;}
    printf("Found ID in list\n");
}
    | idlist COMMA ID  
{
    if(lookupS(htbl,$3,scope)==NULL){symb = createSymbol($3,FORMAL,yylineno,scope);  insert(htbl,symb);}
    else{yyerror("Trying to redefine formal argument\n"); yyerrok;}
    printf("Found ID in list, ID in list\n");
} 
    | %empty            
{
    printf("Found empty idlist\n");
}
    ;
ifstmt: IF L_PAR expr R_PAR 
{
    /*scope++;
    emit(if_eq,$3, newexpr_constbool(1),NULL,nextquad()+2,yylineno);
    $$ = nextquad();
    emit(jump,NULL,NULL,NULL,0,yylineno);*/
} stmt 
{
    /*scope--; 
    hide(htbl,scope);
    patchlabel($$,nextquad()); 
    printf("Found if statement\n");*/
}
    | ifstmt ELSE 
{
    scope++;
    $1 = nextquad();
    emit(jump,NULL,NULL,NULL,0,yylineno);
} stmt 
{
    /*scope--; 
    hide(htbl,scope);
    patchlabel($1,$3+1);
    patchlabel($3,nextquad());
    printf("Found if statement\n");*/
}
    ;
whilestmt: WHILE
{
    //$$ = nextquad();
}
 L_PAR expr R_PAR 
{
    /*scope++;
    emit(if_eq,$3,newexpr_constbool(1),NULL,nextquad()+2,yylineno);
    $1 = nextquad();
    emit(jump,NULL,NULL,NULL,0,yylineno);*/
} stmt            
{
    /*scope--; 
    hide(htbl,scope); 
    emit(jump,NULL,NULL,NULL,$$,yylineno);
    patchlabel($1, nextquad());
    printf("Found while statement\n");*/
}
    ;
forstmt: FOR L_PAR elist SEMI expr SEMI
{
    /*scope++;
    $$.test = nextquad();
    $$.enter = nextquad();
    emit(if_eq,$5,newexpr_constbool(1),NULL,0,yylineno);*/
} elist R_PAR stmt   
{
    /*scope--; 
    hide(htbl,scope); 
    patchlabel($$->enter,$8+1);
    patchlabel($6,nextquad());
    patchlabel($8,$$->test);
    patchlabel($9,$6+1);
    printf("Found for statement\n");*/
}
    ;
returnstmt: RETURN SEMI
{
    emit(ret,NULL,NULL,NULL,NULL,yylineno);
}
    | RETURN expr SEMI              
{
    emit(ret,$2,NULL,NULL,NULL,yylineno);
    printf("Found return statement\n");
}
    ;

%%

int yyerror (const char* yaccProvIDedMessage){
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
    //printTable(htbl);
    printQuads();

    free(symb);
    return 0;     
}