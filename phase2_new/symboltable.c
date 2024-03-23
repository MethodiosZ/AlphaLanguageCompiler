#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern SymTable *stbl[TABLE_SIZE];

Sym *createSymbol(char *name, int scope, int line, type_t type){
    Sym *new;
    new = (Sym*)malloc(sizeof(Sym)); 
    Var *newvar;
    Func *newfunc;
    new->type=type;
    if(type){
        newfunc=createFunction(name,scope,line,1);
        new->FuncVal=newfunc;
        new->VarVal=NULL;
    }
    else{
        newvar=createVariable(name,scope,line);
        new->VarVal=newvar;
        new->FuncVal=NULL;
    }
    return new;
}

Var* createVariable(char* name,int scope,int line){
    Var *new;
    new = (Var*)malloc(sizeof(Var));
    new->name=strdup(name);
    new->scope=scope;
    new->line=line;
    return new;
}

Func* createFunction(char* name,int scope,int line,func_t id){
    Func *new;
    new = (Func*)malloc(sizeof(Func));
    new->id = id;
    new->name = strdup(name);
    new->scope= scope;
    new->line = line;
    return new;
}

void Insert(Sym *nsymbol){
    int index;
    Sym *temp;
    SymTable *head;
    if(nsymbol->type) index=nsymbol->FuncVal->scope;
    else index=nsymbol->VarVal->scope;
    temp=(Sym*)malloc(sizeof(Sym));
    head=stbl[index];
}

Sym* Serch(char* name){

    return;
}

void InitTable(){
    int i;
    for (i=0;i<TABLE_SIZE;i++){
        stbl[i]=NULL;
    }
    Sym *libfunc;
    libfunc = createFunction("print",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("input",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("objectmemberkey",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("objecttotalmembers",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("objectcopy",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("totalarguments",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("argument",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("typeof",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("strtonum",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("sqrt",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("cos",0,0,0);
    Insert(libfunc);
    libfunc = createFunction("sin",0,0,0);
    Insert(libfunc);
    return;
}

void PrintTable(){

}
