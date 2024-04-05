#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern SymTable **stbl;
extern int table_size;

Sym *createSymbol(char *name, int scope, int line, type_t type){
    Sym *new;
    new = (Sym*)malloc(sizeof(Sym)); 
    Var *newvar;
    Func *newfunc;
    new->type=type;
    new->isActive=1;
    if(type<3){
        newvar=createVariable(name,scope,line);
        new->value.VarVal=newvar;
    }
    else{
        newfunc=createFunction(name,scope,line);
        new->value.FuncVal=newfunc;
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

Func* createFunction(char* name,int scope,int line){
    Func *new;
    new = (Func*)malloc(sizeof(Func));
    new->name = strdup(name);
    new->scope= scope;
    new->line = line;
    return new;
}

void Insert(Sym *nsymbol){
    int index;
    SymTable *head,*temp;
    temp=(SymTable*)malloc(sizeof(SymTable));
    if(nsymbol->value.FuncVal) index=nsymbol->value.FuncVal->scope;
    else index=nsymbol->value.VarVal->scope;
    if(index>table_size) TableAlloc();
    head=stbl[index];
    temp->symbol=nsymbol;
    temp->next=NULL;
    if(stbl[index]==NULL){
        stbl[index]=temp;
    }
    else{
        while(head->next!=NULL){
            head=head->next;
        }
        head->next=temp;
    }
}

Sym* Search(char* name,int scope,type_t type){
    int i;
    Sym *temp;
    SymTable *head;
    if(type==2){
        return NULL;
    }
    for(i=0;i<=scope;i++){
        if(i>table_size) return NULL;
        head=stbl[i];
        while(head!=NULL){
            if(head->symbol->type<3){
                if(!strcmp(head->symbol->value.VarVal->name,name)){
                    if(head->symbol->isActive){
                        temp=head->symbol;
                        return temp;
                    }
                    else{
                        head->symbol->isActive=1;
                        return NULL;
                    }
                }
            }
            else if(head->symbol->type==3&&type==3){
                if(!strcmp(head->symbol->value.FuncVal->name,name)){
                    return NULL;
                }
            }
            else if(head->symbol->type==4){
                if(!strcmp(head->symbol->value.FuncVal->name,name)){
                    printf("Error trying to redefine library function\n");
                    temp=head->symbol;
                    return temp;
                }
            }
            head=head->next;
        }
    }
    return NULL;
}

void Hide(int scope){
    int i;
    SymTable *list;
    for(i=scope;i<=table_size;i++){
        list=stbl[i];
        while(list!=NULL){
            list->symbol->isActive=0;
            list=list->next;
        }
    }
    return;
}

void InitTable(){
    int i;
    Func *nfunc;
    Sym *libfunc;
    stbl = (SymTable**)malloc(sizeof(SymTable*));
    stbl[0]=NULL;
    libfunc = createSymbol("print",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("input",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("objectmemberkey",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("objecttotalmembers",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("objectcopy",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("totalarguments",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("argument",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("typeof",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("strtonum",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("sqrt",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("cos",0,0,4);
    Insert(libfunc);
    libfunc = createSymbol("sin",0,0,4);
    Insert(libfunc);
    return;
}

void PrintTable(){
    int i;
    SymTable *temp;
    for(i=0;i<=table_size;i++){
        temp=stbl[i];
        printf("\n---------------     Scope #%d       ---------------\n",i);
        while(temp!=NULL){
            if(temp->symbol->type>2){
                printf("\"%s\" ",temp->symbol->value.FuncVal->name);
                if(temp->symbol->type==3){
                    printf("[user function] ");
                }
                else{
                    printf("[library function] ");
                }
                printf("(line %d) (scope %d)\n",temp->symbol->value.FuncVal->line,temp->symbol->value.FuncVal->scope);
            }
            else{
                printf("\"%s\" ",temp->symbol->value.VarVal->name);
                if(temp->symbol->type==0){
                    printf("[global variable] ");
                }
                else if(temp->symbol->type==1){
                    printf("[local variable] ");
                }
                else{
                    printf("[formal argument] ");
                }
                printf("(line %d) (scope %d)\n",temp->symbol->value.VarVal->line,temp->symbol->value.VarVal->scope);
            }
            temp=temp->next;
        }
    }
}

void TableAlloc(){
    table_size++;
    stbl=realloc(stbl,sizeof(SymTable*)*table_size+1);
    stbl[table_size]=NULL;
}