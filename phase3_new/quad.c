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
        //emit(tablegetelem,e,e->index,result);
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

expr* newexpr_constnum(double i){
    expr *e = newexpr(constnum_e);
    e->numConst = i;
    return e;
}

expr* newexpr_constbool(unsigned int b){
    expr *e = newexpr(constbool_e);
    e->boolConst = !!b;
    return e;
}

expr* lvalue_expr(symbol *sym){
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
        //emit(param,reversed_elist,NULL,NULL);
        reversed_elist = reversed_elist->next;
    }
    //emit(call,func,NULL,NULL);
    expr *result = newexpr(var_e);
    result->sym = newtemp();
    //emit(getretval,NULL,NULL,result);
    return result;
}

void comperror(char *format,...){

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