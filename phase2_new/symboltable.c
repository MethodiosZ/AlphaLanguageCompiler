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
    SymTable *head,*temp;;
    head=(SymTable*)malloc(sizeof(SymTable));
    temp=(SymTable*)malloc(sizeof(SymTable));
    if(nsymbol->type) index=nsymbol->FuncVal->scope;
    else index=nsymbol->VarVal->scope;
    head=stbl[index];
    temp->symbol=nsymbol;
    if(head==NULL){
        temp->next=NULL;
        head=temp;
    }
    else{
        while(head->next!=NULL){
            head=head->next;
        }

    }
    
}

Sym* Search(char* name){
    Sym *temp;
    return temp;
}

void InitTable(){
    int i;
    Func *nfunc;
    Sym *libfunc;
    for (i=0;i<TABLE_SIZE;i++){
        stbl[i]=NULL;
    }
    
    nfunc = createFunction("print",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("input",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("objectmemberkey",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("objecttotalmembers",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("objectcopy",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("totalarguments",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("argument",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("typeof",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("strtonum",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("sqrt",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("cos",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    nfunc = createFunction("sin",0,0,0);
    libfunc->FuncVal=nfunc;
    libfunc->type=func;
    libfunc->VarVal=NULL;
    Insert(libfunc);
    return;
}

void PrintTable(){

}
