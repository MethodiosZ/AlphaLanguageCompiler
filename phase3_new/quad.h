#ifndef QUAD_H_
#define QUAD_H_

#include "symboltable.h"

typedef enum opcode{
	assign, 	add,		sub,
	mul,		divd,		mod,
	uminus,		and,		or,
	not,		if_eq,		if_noteq,
	if_lesseq,	if_greatereq,	if_less,
	if_greater,	call,		param,
	ret,		getretval,	funcstart,
	funcend,		tablecreate,	
	tablegetelem,	tablesetelem, jump
} iopcode;

typedef enum expr_t{
	var_e,
	tableitem_e,
	programfunc_e,
	libraryfunc_e,
	arithexpr_e,
	boolexpr_e,
	assignexpr_e,
	newtable_e,
	constint_e,
	constdouble_e,
	constbool_e,
	conststring_e,
	nil_e
} expr_t;

typedef enum scopespace{
	programvar, functionlocal, formalarg
} scopespace_t;

typedef enum symbol_t{
	var_s, programfunc_s, libraryfunc_s
} symbol_t;

typedef struct symbol{
	symbol_t		type;
	char 			*name;
	scopespace_t	space;
	unsigned		offset;
	unsigned		scope;
	unsigned		line;
} symb;

typedef struct expr{
	expr_t 	        type;
	symb            *sym;
	struct expr     *index;
	int				intConst;
	double	        doubleConst;
	char 	        *strConst;
	unsigned char   boolConst;
	struct expr	    *next;
} expr;

typedef struct quad{
	iopcode	        op;
	expr            *result;	
	expr            *arg1;
	expr            *arg2;
	unsigned int    label;
	unsigned int    line;
}quad;

typedef struct funccall{
	expr			*elist;
	unsigned char	method;
	char			*name;
} fcall;

typedef struct stmt{
	int breakList;
	int contList;
} stmt_t;

void expand();
void emit(iopcode op,expr *arg1,expr *arg2,expr *result, unsigned label,unsigned line);
expr* emit_iftableitem(expr* e);
scopespace_t currscopespace();
unsigned currscopeoffset();
void incurrscopeoffset();
void enterscopespace();
void exitscopespace();
void resetformalargoffset();
void resetfunctionlocaloffset();
void restorecurrscopeoffset(unsigned n);
unsigned nextquad();
void patchlabel(unsigned quadNo,unsigned label);
expr* newexpr(expr_t t);
expr* newexpr_conststring(char *s);
expr* newexpr_constint(int i);
expr* newexpr_constdouble(double d);
expr* newexpr_constnil();
expr* newexpr_constbool(unsigned char b);
expr* lvalue_expr(symb *sym);
expr* member_item(expr *lv,char *name);
expr* make_call(expr *lv, expr *reversed_elist);
void comperror(char *format,const char* context);
void check_arith(expr *e,const char *context);
unsigned int istempname(char *s);
unsigned int istempexpr(expr *e);
void make_stmt(stmt_t *s);
int newlist(int i);
int mergelist(int l1,int l2);
void patchlist(int list,int label);
void printQuads();
const char* getopcode(iopcode op);
const char* getlabel(unsigned label);
symb* newtemp();
void resettemp();
symb* newsymbol(char *name);
void printexpr(expr *item);
symb* SymTableItemtoQuadItem(Sym *item);
expr* emitifboolean(expr *e);

#endif