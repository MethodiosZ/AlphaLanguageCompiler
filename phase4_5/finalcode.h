#include "quad.h"
#include "stdlib.h"

#define EXPAND_SIZE_V 1024
#define CURR_SIZE_V (totalVmargs*sizeof(instruction))
#define NEW_SIZE_V (EXPAND_SIZE_V*sizeof(instruction)+CURR_SIZE_V)

typedef void (*generator_func_t)(quad*);

typedef enum Vmopcode_t{
    assign_v, add_v, sub_v, mul_v, div_v, mod_v, uminus_v, and_v, or_v,
    not_v, jeq_v, jne_v, jle_v, jge_v, jlt_v, jgt_v, call_v, pusharg_v,
    return_v, getretval_v, funcenter_v, funcexit_v, newtable_v, 
    tablegetelem_v, tablesetelem_v, jump_v, nop_v
} vmopcode_t;

typedef enum Vmarg_t{
    label_a, global_a, formal_a, local_a, number_a, string_a,
    bool_a, nil_a, userfunc_a, libfunc_a, retval_a
} vmarg_t;

typedef struct Vmarg{
    vmarg_t     type;
    unsigned    val;
}vmarg;

typedef struct Instruction{
    vmopcode_t  opcode;
    vmarg       *result;
    vmarg       *arg1;
    vmarg       *arg2;
    unsigned    srcLine;
} instruction;

typedef struct Userfunc{
    unsigned    address;
    unsigned    localSize;
    char        *id;
} userfunc;

typedef struct Incomplete_jump{
    unsigned                instrNo;
    unsigned                iaddress;
    struct incomplete_jump  *next;
} incomplete_jump;

void GenerateFinal();
void make_operand(expr *e, vmarg *arg);
void make_numberoperand(vmarg *arg, double val);
void make_booloperand(vmarg *arg, unsigned val);
void make_retvaloperand(vmarg *arg);
void add_incomplete_jump(unsigned instrNo, unsigned iaddress);
unsigned int nextinstructionlabel();
void emit_v(instruction *t);
void patch_incomplete_jumps();
void expand_v();
void printInstructions();
void printVmarg(vmarg* arg);
void InstrToBin();
void readBin();

unsigned consts_newstring(char *s);
unsigned consts_newnumber(double n);
unsigned libfuncs_newused(char *s);
unsigned userfuncs_newfunc(symb *sym);

void generate(vmopcode_t op,quad *q);
void generate_relational(vmopcode_t op, quad *q);
void generate_ADD(quad* q);
void generate_SUB(quad* q);
void generate_MUL(quad* q);
void generate_DIV(quad* q);
void generate_MOD(quad* q);
void generate_NEWTABLE(quad* q);
void generate_TABLEGETELEM(quad* q);
void generate_TABLESETELEM(quad* q );
void generate_ASSIGN(quad* q);
void generate_NOP();
void generate_JUMP(quad* q);
void generate_IF_EQ(quad* q);
void generate_IF_NOTEQ(quad* q);
void generate_IF_GREATER(quad* q);
void generate_IF_GREATEREQ(quad* q);
void generate_IF_LESS(quad* q);
void generate_IF_LESSEQ(quad* q);
void generate_NOT(quad* q);
void generate_OR(quad* q);
void generate_AND(quad* q);
void generate_UMINUS(quad* q);
void generate_PARAM(quad* q);
void generate_CALL(quad* q);
void generate_GETRETVAL(quad* q);
void generate_FUNCSTART(quad* q);
void generate_FUNCEND(quad* q);
void generate_RETURN(quad* q);
void reset_operand(vmarg *arg);