#ifndef	QUAD_H_
#define QUAD_H_

#include "hashtable.h"

typedef enum opcode iopcode; 
typedef enum Expr_t expr_t; 
typedef struct expression expr;
typedef struct call call_t;

enum opcode{
	assign, 	add,		sub,
	mul,		divide,		mod,
	uminus,		and,		or,
	not,		if_eq,		if_noteq,
	if_lesseq,	if_greatereq,	if_less,
	if_greater,	call,		param,
	ret,		getretval,	funcstart,
	funcend,	jump,		tablecreate,	
	tablegetelem,	tablesetelem
};

enum Expr_t{
	var_e,
	tableitem_e,
	programfunc_e,
	libraryfunc_e,
	arithexpr_e,
	boolexpr_e,
	assignexpr_e,
	newtable_e,
	constnum_e,
	constbool_e,
	conststring_e,
	nil_e
};

struct expression{
	expr_t 	type;
	Variable *sym;
	expr    *index;
	double	numConst;
	char 	*strConst;
	unsigned char boolConst;
	expr	*next;
};

typedef struct Quad{
	iopcode	op;
	expr *	result;	
	expr *	arg1;
	expr *	arg2;
	unsigned int label;
	unsigned int line;
}quad;

struct call {
	expr* elist;
	unsigned char method;
	char* name;
};

void expand();
void emit(iopcode op,expr * arg1, expr * arg2, expr * result, unsigned label, unsigned line);
void printQuads(); 
unsigned nextquadlabel();
void patchlabel(unsigned quadNo, unsigned label);
expr* lvalue_expr(Variable *sym);
expr* newexpr(expr_t t);
expr* emit_iftableitem(expr* e);
expr* make_call(expr* lv, expr* reversed_elist);
expr* newexpr_constnum(double i);
void comperror(char* format, const char* context);
void check_arith(expr* e, const char* context);
unsigned int istempname(char* s);
unsigned int istempexpr(expr* e);
expr* newexpr_constbool(unsigned int b);
expr* newexpr_conststring(char *name);
unsigned nextquad();
expr* member_item(expr* lv, char* name);
int newlist(int i);
int mergelist(int l1,int l2);
void patchlist(int list, int label);
const char* getopcode(iopcode op);
const char* getlabel(unsigned label);

#endif 