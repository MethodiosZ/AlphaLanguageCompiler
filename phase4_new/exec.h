#include "quad.h"
#include "stdlib.h"

#define EXPAND_SIZE_V 1024
#define CURR_SIZE_V (totalVmargs*sizeof(instruction))
#define NEW_SIZE_V (EXPAND_SIZE_V*sizeof(instruction)+CURR_SIZE_V)

generator_func_t generators[] = {
    generate_ADD,
    generate_SUB,
    generate_MUL,
    generate_DIV,
    generate_MOD,
    generate_NEWTABLE,
    generate_TABLEGETELEM,
    generate_TABLESETELEM,
    generate_ASSIGN,
    generate_NOP,
    generate_JUMP,
    generate_IF_EQ,
    generate_IF_NOTEQ,
    generate_IF_GREATER,
    generate_IF_GREATEREQ,
    generate_IF_LESS,
    generate_IF_LESSEQ,
    generate_NOT,
    generate_OR,
    generate_AND,
    generate_PARAM,
    generate_CALL,
    generate_GETRETVAL,
    generate_FUNCSTART,
    generate_FUNCEND,
    generate_RETURN
};

typedef void (*generator_func_t)(quad*);

typedef enum vmopcode_t{
    assign_v, add_v, sub_v, mul_v, div_v, mod_v, uminus_v, and_v, or_v,
    not_v, jeq_v, jne_v, jle_v, jge_v, jlt_v, jgt_v, call_v, pusharg_v,
    return_v, getretval_v, funcenter_v, funcexit_v, newtable_v, 
    tablegetelem_v, tablesetelem_v, jump_v, nop_v
} vmopcode_t;

typedef enum vmarg_t{
    label_a, global_a, formal_a, local_a, number_a, string_a,
    bool_a, nil_a, userfunc_a, libfunc_a, retval_a
} vmarg_t;

typedef struct vmarg{
    vmarg_t     type;
    unsigned    val;
}vmarg;

typedef struct instruction{
    vmopcode_t  opcode;
    vmarg       *result;
    vmarg       *arg1;
    vmarg       *arg2;
    unsigned    srcLine;
} instruction;

typedef struct userfunc{
    unsigned    address;
    unsigned    localSize;
    char        *id;
} userfunc;

typedef struct incomplete_jump{
    unsigned                instrNo;
    unsigned                iaddress;
    struct incomplete_jump  *next;
} incomplete_jump;

void make_operand(expr *e, vmarg *arg);
void make_numberoperand(vmarg *arg, double val);
void make_booloperand(vmarg *arg, unsigned val);
void make_retvaloperand(vmarg *arg);
void add_incomplete_jumo(unsigned instrNo, unsigned iaddress);
unsigned int nextinstructionlabel();
void emit_v(instruction *t);
void patch_incomplete_jumps();
void expand_v();
void printInstructions();
void InstrToBin();

unsigned consts_newstring(char *s);
unsigned consts_newnumber(double n);
unsigned libfuncs_newused(char *s);
unsigned userfuncs_newfunc(symb *sym);

void generate(vmopcode_t op,quad *q);
void generate_relational(vmopcode_t op, quad *q);
void generate_ADD(quad*);
void generate_SUB(quad*);
void generate_MUL(quad*);
void generate_DIV(quad*);
void generate_MOD(quad*);
void generate_NEWTABLE(quad*);
void generate_TABLEGETELEM(quad*);
void generate_TABLESETELEM(quad*);
void generate_ASSIGN(quad*);
void generate_NOP();
void generate_JUMP(quad*);
void generate_IF_EQ(quad*);
void generate_IF_NOTEQ(quad*);
void generate_IF_GREATER(quad*);
void generate_IF_GREATEREQ(quad*);
void generate_IF_LESS(quad*);
void generate_IF_LESSEQ(quad*);
void generate_NOT(quad*);
void generate_OR(quad*);
void generate_AND(quad*);
void generate_PARAM(quad*);
void generate_CALL(quad*);
void generate_GETRETVAL(quad*);
void generate_FUNCSTART(quad*);
void generate_FUNCEND(quad*);
void generate_RETURN(quad*);
void reset_operand(vmarg *arg);
