#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "quad.h"
#include "assert.h"

#define EXPAND_SIZE 1024
#define CURR_SIZE (total*sizeof(quad))
#define NEW_SIZE  (EXPAND_SIZE*sizeof(quad)+CURR_SIZE)

quad *quads=(quad*)0;
unsigned int total= 0;
unsigned int currQuad = 0;
int i;

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

void emit(iopcode op, expr * arg1, expr * arg2, expr * result,unsigned label, unsigned line){
	if(currQuad==total){
		expand();
	}			
	quad* p =  quads+currQuad++;
	p->op = op;
	p->arg1 = arg1;
	p->arg2 = arg2;
	p->result = result;
	p->label = label;
	p->line = line;
}

void printQuads()
{
    printf("quad#\topcode\t\tresult\t\targ1\t\targ2\t\tlabel\n");
	printf("--------------------------------------------------------------------------------\n");
	for(i=0;i<currQuad;i++){
		printf("%d:\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n",i+1,getopcode(quads[i].op),quads[i].result,
		quads[i].arg1,quads[i].arg2,getlabel(quads[i].label));
	}
	printf("--------------------------------------------------------------------------------\n");
}

unsigned nextquadlabel(){
	return currQuad;
}

void patchlabel(unsigned quadNo, unsigned label){
	assert(quadNo < currQuad  && !quads[quadNo].label);
	quads[quadNo].label = label;
}

expr *lvalue_expr(Variable *sym){
    assert(sym);
	expr* e = (expr*) malloc(sizeof(expr));
	memset(e, 0, sizeof(expr));
	e->next = (expr*)0;
	e->sym = sym;
	switch(sym->type){
		case var_s: e->type = var_e; break;
		case programfunc_s: e->type = programfunc_e; break;
		case libraryfunc_s: e->type = libraryfunc_e; break;
		default: assert(0);
	}
	return e;
}

expr *newexpr(expr_t t){
    expr* e = (expr*) malloc(sizeof(expr));
	memset(e, 0, sizeof(expr));
	e->type = t;
	return e;
}

expr *emit_iftableitem(expr *e){
    if(e->type != tableitem_e){
		return e;
	} else {
		expr* result = newexpr(var_e);
		//result->sym = new
		emit(tablegetelem,e,e->index,result,NULL,NULL);
		return result;
	}
}

expr *make_call(expr *lv, expr *reversed_elist){
    expr* func = emit_iftableitem(lv);
	while(reversed_elist){
		emit(param,reversed_elist,NULL,NULL,NULL,NULL);
		reversed_elist = reversed_elist->next;
	}
	emit(call,func,NULL,NULL,NULL,NULL);
	expr* result = newexpr(var_e);
	//result->sym = newtemp();
	emit(getretval, NULL, NULL, result, NULL, NULL);
	return result;
}

expr *newexpr_constnum(double i){
    expr* e =  newexpr(constnum_e);
	e->numConst = i;
	return e; 
}

void comperror(char* format, const char* context){
	fprintf(stderr,"%s %s\n",format,context);
}

void check_arith(expr *e, const char *context){
	if(e->type == constbool_e ||
	   e->type == conststring_e ||
	   e->type == nil_e ||
	   e->type == newtable_e ||
	   e->type == programfunc_e ||
	   e->type == libraryfunc_e ||
	   e->type == boolexpr_e){
		comperror("Illegal expr used in %s!",context);
	}
}

unsigned int istempname(char *s){
    return *s == '$';
}

unsigned int istempexpr(expr *e){
    return e->sym && istempname(e->sym->name);
}

expr *newexpr_constbool(unsigned int b){
	expr* e = newexpr(constbool_e);
	e->boolConst = !!b;
	return e;
}

expr *newexpr_conststring(char *name){
	expr* e = newexpr(conststring_e);
	e->strConst = name;
	return e;
}

unsigned nextquad(){ return currQuad; }

expr *member_item(expr *lv, char *name){
    lv = emit_iftableitem(lv);
	expr* ti = newexpr(tableitem_e);
	ti->sym = lv->sym;
	ti->index = newexpr_conststring(name);
	return ti;
}

int newlist(int i){
    quads[i].label = 0;
	return i;
}

int mergelist(int l1, int l2){
    if(!l1) return l2;
	else if (!l2) return l1;
	else{
		int i = l1;
		while(quads[i].label){
			i = quads[i].label;
		}
		quads[i].label = l2;
		return l1;
	}
}

void patchlist(int list, int label){
	while(list){
		int next = quads[list].label;
		quads[list].label = label;
		list = next;
	}
}

const char *getopcode(iopcode op){
    switch (op)
	{
		case assign: return "assign";
		case add: return "add";
		case sub: return "sub";
		case mul: return "mul";
		case divide: return "div";
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
		case jump: return "jump";
		case tablecreate: return "tablecreate";
		case tablegetelem: return "tablegetelem";
		case tablesetelem: return "tablesetelem";
	}
}

const char *getlabel(unsigned label){
	char * str = (char*)malloc(10*sizeof(char));
	sprintf(str,"%d",label);
    if(label==0) return " ";
	else return (char*) str;
}
