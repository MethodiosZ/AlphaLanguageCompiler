#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "hashtable.h"

unsigned programVarOffset = 0;
unsigned functionLocalOffset = 0;
unsigned formalArgOffset = 0;
unsigned scopeSpaceCounter = 1;
unsigned tempcounter = 0;
extern int scope;
extern Symbol *htbl[];

int gethash(char* name){
    int length = strlen(name);
    int hash = 0;
    for(int i=0; i<length;i++){
        hash += name[i];
        hash = hash * name[i];
        hash = hash % HASH_SIZE;
    }
    return hash;
}

Symbol * createSymbol(char *name,int type, int line, int scope){
    assert(name);
    Symbol *nsymb = malloc(sizeof(Symbol));
    Variable * var;
    Function * func;
    assert(nsymb);
    nsymb->type = type;
    nsymb->isActive = 1;
    nsymb->next = NULL;
    if(type >= 0 && type < 3){
       var = createVariable(name, line, scope);
       assert(var);
       nsymb->varVal = var;
       nsymb->funcVal = NULL;
    }
    else if(type == 3 || type == 4){
        func = createFunction(name,line,scope);
        assert(func);
        nsymb->funcVal = func;
        nsymb->varVal = NULL;
    }
    else{printf("Wrong type.\n"); exit(0);}
    return nsymb;  
}

Variable * createVariable(char *name, int line, int scope){
    assert(name);
    Variable *nvar = malloc(sizeof(Variable));
    assert(nvar);
    nvar->name = strdup(name);
    nvar->line = line;
    nvar->scope = scope;
    return nvar;
}

Function * createFunction(char *name, int line, int scope){
    assert(name);
    Function *nfunc = malloc(sizeof(Function));
    assert(nfunc);
    nfunc->name = strdup(name);
    nfunc->line = line;
    nfunc->scope = scope;
    return nfunc;
}

void insert(Symbol * hashtable[HASH_SIZE], Symbol * newsymbol){
    assert(newsymbol);
    Value val = getValue(newsymbol);
    int hash = gethash(val.name);
    Symbol *list = hashtable[hash];
    if(!list){hashtable[hash] = newsymbol;}
    else {
        while(list->next){list = list->next;}
        list->next = newsymbol;
    }
    return;
}

void hide(Symbol * hashtable[HASH_SIZE], int maxscope){
    for(int i=0;i<HASH_SIZE;i++){
        Symbol *list = hashtable[i];
        while(list){
            if(getValue(list).scope > maxscope){
                list->isActive = 0;
            }
            list = list->next;
        }
    }
    return;
}

Symbol * lookup(Symbol * hashtable[HASH_SIZE], char *name){
    int hash = gethash(name);
    Symbol *list = hashtable[hash];
    while(list && strcmp(getValue(list).name,name) != 0  && list->isActive > 0){
        list = list->next;
    }
    return list;
}

Symbol * lookupS(Symbol * hashtable[HASH_SIZE], char *name, int scope){
    int hash = gethash(name);
    Symbol *list = hashtable[hash];
    while(list && !(strcmp(getValue(list).name,name) == 0 && getValue(list).scope == scope) && list->isActive > 0){
        list = list->next;
    }
    return list;
}

void initializeTable(Symbol * hashtable[HASH_SIZE]){
    for(int i=0;i<HASH_SIZE;i++){
        hashtable[i] = NULL;
    }
    Symbol * tmp;
    tmp = createSymbol("print",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("input",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("objectmemberkeys",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("objecttotalmembers",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("objectcopy",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("totalarguments",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("argument",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("typeof",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("strtonum",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("sqrt",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("cos",4,0,0);
    insert(hashtable,tmp);
    tmp = createSymbol("sin",4,0,0);
    insert(hashtable,tmp);
    return;
}

void printTable(Symbol * hashtable[HASH_SIZE]){
    Symbol * list;
    int maxscope=0;
    printf("\nPrint hashtable start\n");
    printf("-----------     Scope #0     -----------\n");
    for(int i=0;i<HASH_SIZE;i++){
        list = hashtable[i];
        while(list){
            if(maxscope<getValue(list).scope) maxscope = getValue(list).scope;
            if(getValue(list).scope==0){
                printf(" \"%s\"  [ %s ]  (line %d)  (scope %d)\n",getValue(list).name
                ,getType(list),getValue(list).line,getValue(list).scope);
            }
            list = list->next;
        }
    }
    for(int j=1;j<=maxscope;j++){
        printf("\n-----------     Scope #%d     -----------\n",j);
        for(int i=0;i<HASH_SIZE;i++){
        list = hashtable[i];
            while(list){
                if(getValue(list).scope==j){
                    printf(" \"%s\"  [ %s ]  (line %d)  (scope %d)\n",getValue(list).name
                    ,getType(list),getValue(list).line,getValue(list).scope);
                }
                list = list->next;
            }
        }
    }
    printf("\nPrint hashtable end\n");
    return;
}

char * getType(Symbol *symb){
    char *str = NULL;
    assert(symb);
    int x = symb->type;
    switch(x){
        case 0: str = strdup("global variable"); break;
        case 1: str = strdup("local variable"); break;
        case 2: str = strdup("formal variable"); break;
        case 3: str = strdup("user function"); break;
        case 4: str = strdup("library function"); break;
        default: str = NULL;
    }
    return str;
}

Value getValue(Symbol *symb){
    Value val; val.name = "NA"; val.line = -1; val.scope = -1;
    if(symb->varVal != NULL){
        val.name = symb->varVal->name;
        val.line = symb->varVal->line;
        val.scope = symb->varVal->scope;
    }
    else if(symb->funcVal != NULL){
        val.name = symb->funcVal->name;
        val.line = symb->funcVal->line;
        val.scope = symb->funcVal->scope;
    }
    return val;
}

enum scopespace_t currscopespace(){
    if (scopeSpaceCounter == 1){
      return programvar;  
    } else if(scopeSpaceCounter % 2 == 0) {
        return formalarg;
    } else {
        return functionlocal;
    }
}

unsigned currscopeoffset(){
    switch (currscopespace()){
    case programvar: return programVarOffset;
    case functionlocal: return functionLocalOffset;
    case formalarg: return formalArgOffset;
    default: assert(0);
    }
}

void incurrscopeoffset(){
    switch (currscopespace()){
        case programvar: ++programVarOffset; break;
        case functionlocal: ++functionLocalOffset; break;
        case formalarg: ++formalArgOffset; break;
        default: assert(0);
    }
}

void enterscopespace(){
    ++scopeSpaceCounter;
}

void exitscopespace(){
    assert(scopeSpaceCounter>1);
    --scopeSpaceCounter;
}

void resetformalargoffset(){
    formalArgOffset = 0;
}

void resetfunctionlocaloffset(){
    functionLocalOffset = 0;
}

void restorecurrscopeoffset(unsigned n){
    switch (currscopespace()){
        case programvar: programVarOffset = n; break;
        case functionlocal: functionLocalOffset = n; break;
        case formalarg: formalArgOffset = n; break;
        default: assert(0);
    }
}

char *newtempname(){
    return "$"+tempcounter;
}

void resettemp(){
    tempcounter = 0;
}

Variable* newtemp(){
    char* name = newtempname();
    Symbol* sym = lookupS(htbl,name,scope);
    if (sym == NULL){
        return newsymbol(name);
    } else {
        return sym->varVal;
    }
}

Variable* newsymbol(char *name){
    Variable* e =  (Variable*) malloc(sizeof(Variable));
	memset(e, 0, sizeof(Variable));
	e->name = name;
	return e;
}