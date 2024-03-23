#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern SymTable *stbl[HASH_SIZE];

int hash(char* name){
    int length=0,i=0,hashnum=0;
    length = strlen(name);
    for(i=0;i<length;i++){
        hashnum += name[i];
        hashnum = hashnum % HASH_SIZE;
    }
    return hashnum;
}

Sym *createSymbol(char *name, int scope, int line, type_t type,func_t funcid){
    Sym *new;
    new = (Sym*)malloc(sizeof(Sym)); 
    Var *newvar;
    Func *newfunc;
    new->type=type;
    if(type){
        newfunc=createFunction(name,scope,line,funcid);
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

}

Sym* Serch(char* name){

    return;
}

void InitTable(){
    int i;
    for (i=0;i<HASH_SIZE;i++){
        stbl[i]=NULL;
    }
    
}

void PrintTable(){

}
