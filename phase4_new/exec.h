#include "quad.h"

#define AVM_STACKSIZE   4096
#define AVM_WIPEOUT(m)  memset(&(m),0,sizeof(m))
#define AVM_TABLE_HASHSIZE  211

double      *numConsts;
unsigned    totalNumConsts;
char        **stringConsts;
unsigned    totalStringConsts;
char        **namedLibFuncs;
unsigned    totalNamedLibFuncs;
userfunc    *userFuncs;
unsigned    totalUserFuncs;

incomplete_jump *ij_head = (incomplete_jump*)0;
unsigned        ij_total = 0;
avm_memcell     stack[AVM_STACKSIZE];
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

extern quad* quads;
extern void generate_ADD(quad*);
extern void generate_SUB(quad*);
extern void generate_MUL(quad*);
extern void generate_DIV(quad*);
extern void generate_MOD(quad*);
extern void generate_NEWTABLE(quad*);
extern void generate_TABLEGETELEM(quad*);
extern void generate_TABLESETELEM(quad*);
extern void generate_ASSIGN(quad*);
extern void generate_NOP(quad*);
extern void generate_JUMP(quad*);
extern void generate_IF_EQ(quad*);
extern void generate_IF_NOTEQ(quad*);
extern void generate_IF_GREATER(quad*);
extern void generate_IF_GREATEREQ(quad*);
extern void generate_IF_LESS(quad*);
extern void generate_IF_LESSEQ(quad*);
extern void generate_NOT(quad*);
extern void generate_OR(quad*);
extern void generate_AND(quad*);
extern void generate_PARAM(quad*);
extern void generate_CALL(quad*);
extern void generate_GETRETVAL(quad*);
extern void generate_FUNCSTART(quad*);
extern void generate_FUNCEND(quad*);
extern void generate_RETURN(quad*);

typedef void (*generator_func_t)(quad*);

typedef enum vmopcode_t{
    assign_v, add_v, sub_v, mul_v, div_v, mod_v, uminus_v, and_v, or_v,
    not_v, jeq_v, jne_v, jle_v, jge_v, jlt_v, jgt_v, call_v, pusharg_v,
    funcenter_v, funcexit_v, newtable_v, tablegetelem_v, tablesetelem_v,
    nop_v
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
    vmarg       result;
    vmarg       arg1;
    vmarg       arg2;
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

typedef enum avm_memcell_t{
    number_m, string_m, bool_m, table_m, userfunc_m, libfunc_m,
    nil_m, undef_m
} avm_memcell_t;

typedef struct avm_table_bucket{
    avm_memcell             key;
    avm_memcell             value;
    struct avm_table_bucket *next;
} avm_table_bucket;

typedef struct avm_table{
    unsigned            refCounter;
    avm_table_bucket    *strIndexed[AVM_TABLE_HASHSIZE];
    avm_table_bucket    *numIndexed[AVM_TABLE_HASHSIZE];
    unsigned            total;
} avm_table;

typedef struct avm_memcell{
    avm_memcell_t   type;
    union{
        double          numVal;
        char            *strVal;
        unsigned char   boolVal;
        avm_table       *tableVal;
        unsigned        funcVal;
        char            *libfuncVal;
    } data;
} avm_memcell;

unsigned consts_newstring(char *s);
unsigned consts_newnumber(double n);
unsigned libfuncs_newused(char *s);
void make_operand(expr *e, vmarg *arg);
void add_incomplete_jumo(unsigned instrNo, unsigned iaddress);
void generate();
static void avm_initstack();
avm_table *avm_tablenew();
void avm_tabledestroy(avm_table *t);
avm_memcell *avm_tablegetelem(avm_memcell *key);
void avm_tablesetelem(avm_memcell *key, avm_memcell *value);
void avm_tableincrefcounter(avm_table *t);
void avm_tabledecrefcounter(avm_table *t);
void avm_tablebucketsinit(avm_table_bucket **p);
void avm_memcellclear(avm_memcell *m);
void avm_tablebucketsdestroy(avm_table_bucket **p);
void make_numberoperand(vmarg *arg, double val);
void make_booloperand(vmarg *arg, unsigned val);
void make_retvaloperand(vmarg *arg);