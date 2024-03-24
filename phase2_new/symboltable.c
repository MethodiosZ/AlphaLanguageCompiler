#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern SymTable *stbl[TABLE_SIZE];

Sym *createSymbol(char *name, int scope, int line, type_t type, int id){
    Sym *new;
    new = (Sym*)malloc(sizeof(Sym)); 
    Var *newvar;
    Func *newfunc;
    new->type=type;
    if(type){
        newfunc=createFunction(name,scope,line,id);
        new->FuncVal=newfunc;
        new->VarVal=NULL;
    }
    else{
        newvar=createVariable(name,scope,line,id);
        new->VarVal=newvar;
        new->FuncVal=NULL;
    }
    return new;
}

Var* createVariable(char* name,int scope,int line,var_t id){
    Var *new;
    new = (Var*)malloc(sizeof(Var));
    new->name=strdup(name);
    new->scope=scope;
    new->line=line;
    new->id=id;
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
    SymTable *head,*temp;
    temp=(SymTable*)malloc(sizeof(SymTable));
    if(nsymbol->type) index=nsymbol->FuncVal->scope;
    else index=nsymbol->VarVal->scope;
    head=stbl[index];
    temp->symbol=nsymbol;
    temp->next=NULL;
    if(head==NULL){
        head=temp;
    }
    else{
        while(head->next!=NULL){
            head=head->next;
        }
        head->next=temp;
    }
}

Sym* Search(char* name){
    int i;
    Sym *temp;
    SymTable *head;
    for(i=0;i<TABLE_SIZE;i++){
        head=stbl[i];
        while(head!=NULL){
            if(head->symbol->type){
                if(!strcmp(head->symbol->FuncVal->name,name)){
                    temp=head->symbol;
                    return temp;
                }
            }
            else{
                if(!strcmp(head->symbol->VarVal->name,name)){
                    temp=head->symbol;
                    return temp;
                }

            }
            head=head->next;
        }
    }
    printf("Symbol not found!\n");
    return NULL;
}

void InitTable(){
    int i;
    Func *nfunc;
    Sym *libfunc;
    for (i=0;i<TABLE_SIZE;i++){
        stbl[i]=NULL;
    }
    libfunc = createSymbol("print",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("input",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("objectmemberkey",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("objecttotalmembers",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("objectcopy",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("totalarguments",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("argument",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("typeof",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("strtonum",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("sqrt",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("cos",0,0,1,0);
    Insert(libfunc);
    libfunc = createSymbol("sin",0,0,1,0);
    Insert(libfunc);
    return;
}

void PrintTable(){
    int i;
    SymTable *temp;
    for(i=0;i<TABLE_SIZE;i++){
        temp=stbl[i];
        printf("---------------     Scope #%d       ---------------\n",i);
        while(temp!=NULL){
            if(temp->symbol->type){
                printf("\"%s\" ",temp->symbol->FuncVal->name);
                if(temp->symbol->FuncVal->id){
                    printf("[user function] ");
                }
                else{
                    printf("[library function] ");
                }
                printf("(line %d) (scope %d)\n",temp->symbol->FuncVal->line,temp->symbol->FuncVal->scope);
            }
            else{
                printf("\"%s\" ",temp->symbol->VarVal->name);
                if(temp->symbol->VarVal->id==0){
                    printf("[global variable] ");
                }
                else if(temp->symbol->VarVal->id==1){
                    printf("[local variable] ");
                }
                else{
                    printf("[formal argument] ");
                }
                printf("(line %d) (scope %d)\n",temp->symbol->VarVal->line,temp->symbol->VarVal->scope);
            }
        }
    }
}