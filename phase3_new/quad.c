#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "quad.h"
#include "assert.h"

#define EXPAND_SIZE 1024
#define CURR_SIZE   (total*sizeof(quad))
#define NEW_SIZE    (EXPAND_SIZE*sizeof(quad)+CURR_SIZE)

quad *quads = (quad*)0;
unsigned total = 0;
unsigned int currQuad = 0;
unsigned programVarOffset = 0;
unsigned functionLocalOffset = 0;
unsigned formalArgOffset = 0;
unsigned scopeSpaceCounter = 1;
int tempcounter = 0;

void expand(){
    assert(total==currQuad);
    quad *p = (quad*)malloc(NEW_SIZE);
    if(quads){
        memcpy(p,quads,CURR_SIZE);
        free(quads);
    }
    quads=p;
    total += EXPAND_SIZE;
}

void emit(iopcode op,expr *arg1,expr *arg2,expr *result, unsigned label,unsigned line){
    if(currQuad==total) expand();
    quad *p = quads+currQuad++;
    p->op = op;
    p->arg1 = arg1;
    p->arg2 = arg2;
    p->result = result;
    p->label = label;
    p->line = line;
}

scopespace_t currscopespace(){
    if(scopeSpaceCounter==1){
        return programvar;
    }
    else if(scopeSpaceCounter%2==0){
        return formalarg;
    }
    else{
        return functionlocal;
    }
}

unsigned currscopeoffset(){
    switch(currscopespace()){
        case programvar:
            return programVarOffset;
        case functionlocal:
            return functionLocalOffset;
        case formalarg:
            return formalArgOffset;
        default: assert(0);
    }
}

void incurrscopeoffset(){
    switch(currscopespace()){
        case programvar:
            ++programVarOffset;
            break;
        case functionlocal:
            ++functionLocalOffset;
            break;
        case formalarg:
            ++formalArgOffset;
            break;
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

expr* emit_iftableitem(expr* e){
    if(e->type != tableitem_e) return e;
    else {
        expr *result = newexpr(var_e);
        result->sym = newtemp();
        emit(tablegetelem,e,e->index,result,0,0);
        return result;
    }
}

void resetformalargoffset(){
    formalArgOffset = 0;
}

void resetfunctionlocaloffset(){
    functionLocalOffset = 0;
}

void restorecurrscopeoffset(unsigned n){
    switch(currscopespace()){
        case programvar:
            programVarOffset = n;
            break;
        case functionlocal:
            functionLocalOffset = n;
            break;
        case formalarg:
            formalArgOffset = n;
            break;
        default:
            assert(0);
    }
}

unsigned nextquad(){
    return currQuad;
}

void patchlabel(unsigned quadNo,unsigned label){
    assert(quadNo < currQuad && !quads[quadNo].label);
    quads[quadNo].label = label;
}

expr* newexpr(expr_t t){
    expr *e = (expr*)malloc(sizeof(expr));
    memset(e,0,sizeof(expr));
    e->type = t;
    return e;
}

expr* newexpr_conststring(char *s){
    expr *e = newexpr(conststring_e);
    e->strConst = strdup(s);
    return e;
}

expr* newexpr_constint(int i){
    expr *e = newexpr(constint_e);
    e->intConst = i;
    return e;
}

expr* newexpr_constdouble(double i){
    expr *e = newexpr(constdouble_e);
    e->doubleConst = i;
    return e;
}

expr* newexpr_constnil(){
    expr *e = newexpr(nil_e);
    e->sym=NULL;
    return e;
}

expr* newexpr_constbool(unsigned char b){
    expr *e = newexpr(constbool_e);
    e->boolConst = !!b;
    return e;
}

expr* lvalue_expr(symb *sym){
    assert(sym);
    expr *e = (expr*)malloc(sizeof(expr));
    memset(e,0,sizeof(expr));
    e->next = (expr*)0;
    e->sym = sym;
    switch(sym->type){
        case var_s:
            e->type = var_e;
            break;
        case programfunc_s:
            e->type = programfunc_e;
            break;
        case libraryfunc_s:
            e->type = libraryfunc_e;
            break;
        default:
            assert(0);
    }
    return e;
}

expr* member_item(expr *lv,char *name){
    lv = emit_iftableitem(lv);
    expr *ti = newexpr(tableitem_e);
    ti->sym = lv->sym;
    ti->index = newexpr_conststring(name);
    return ti;
}

expr* make_call(expr *lv, expr *reversed_elist){
    expr *func = emit_iftableitem(lv);
    while(reversed_elist){
        emit(param,reversed_elist,NULL,NULL,0,0);
        reversed_elist = reversed_elist->next;
    }
    emit(call,func,NULL,NULL,0,0);
    expr *result = newexpr(var_e);
    result->sym = newtemp();
    emit(getretval,NULL,NULL,result,0,0);
    return result;
}

void comperror(char *format,const char* context){

}
void check_arith(expr *e,const char *context){
    if(e->type==constbool_e||e->type==conststring_e||e->type==nil_e||
    e->type==newtable_e||e->type==programfunc_e||e->type==libraryfunc_e||
    e->type==boolexpr_e){
        comperror("Illegal expr used in %s!",context);
    }
}

unsigned int istempname(char *s){
    return *s == '_';
}

unsigned int istempexpr(expr *e){
    return e->sym && istempname(e->sym->name);
}

void make_stmt(stmt_t *s){
    s->breakList = 0;
    s->contList = 0;
}

int newlist(int i){
    quads[i].label = 0;
    return i;
}

int mergelist(int l1,int l2){
    if(!l1) return l2;
    else if(!l2) return l1;
    else{
        int i = l1;
        while(quads[i].label){
            i=quads[i].label;
        }
        quads[i].label = l2;
        return l1;
    }
}

void pathclist(int list,int label){
    while(list){
        int next = quads[list].label;
        quads[next].label = label;
        list=next;
    }
}

void printQuads(){
    int i;
    printf("quad#\topcode\t\tresult\t\targ1\t\targ2\t\tlabel\n");
    printf("------------------------------------------------------------------------------\n");
    for(i=0;i<currQuad;i++){
        printf("%d:\t%s\t\t",i+1,getopcode(quads[i].op));
        if(quads[i].op==assign){
            printexpr(quads[i].result);
            printexpr(quads[i].arg1);
            printf("\t\t%s\n",getlabel(quads[i].label));
        }
        else if(quads[i].op==add){
            printexpr(quads[i].result);
            printexpr(quads[i].arg1);
            printexpr(quads[i].arg2);
            printf("\t\t%s\n",getlabel(quads[i].label));
        }
    }
    printf("------------------------------------------------------------------------------\n");
}

const char* getopcode(iopcode op){
    switch (op)
	{
		case assign: return "assign";
		case add: return "add";
		case sub: return "sub";
		case mul: return "mul";
		case divd: return "div";
		case mod: return "mod";
		case uminus: return "uminus";
		case and: return "and";
		case or: return "or";
		case not: return "not";
		case if_eq: return "if_eq";
		case if_noteq: return "if_noteq";
		case if_lesseq: return "if_lesseq";
		case if_greatereq: return "if_greatereq";
		case if_less: return "if_less";
		case if_greater: return "if_greater";
		case call: return "call";
		case param: return "param";
		case ret: return "ret";
		case getretval: return "getredval";
		case funcstart: return "funcstart";
		case funcend: return "funcend";
		case tablecreate: return "tablecreate";
		case tablegetelem: return "tablegetelem";
		case tablesetelem: return "tablesetelem";
        case jump: return "jump";
	}
}

const char* getlabel(unsigned label){
    char *str = (char*)malloc(10*sizeof(char));
    sprintf(str,"%d",label);
    if(label==0 || label==(int)NULL) return " ";
    else return (char*)str;
}

symb* newtemp(){
    char *name = (char*)malloc(10*sizeof(char));
    sprintf(name,"^%d",tempcounter++);
    return newsymbol(name);
}

symb* newsymbol(char *name){
    symb* e = (symb*)malloc(sizeof(symb));
    memset(e,0,sizeof(symb));
    e->name = name;
    return e;
}

void printexpr(expr *item){
    if(item==NULL){
        printf("  \t\t");
    } 
    else{
        if(item->type==var_e){
            printf("%s\t\t",item->sym->name);
        }
        else if(item->type==assignexpr_e){
            printf("%s\t\t",item->sym->name);
        }
        else if(item->type==constint_e){
            printf("%d\t\t",item->intConst);
        }
        else if(item->type==constdouble_e){
            printf("%f\t\t",item->doubleConst);
        }
    }
}