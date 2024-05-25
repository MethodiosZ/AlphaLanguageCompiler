#include "exec.h"

#define AVM_STACKSIZE 4096
#define AVM_WIPEOUT(m) memset(&(m),0,sizeof(m))
#define AVM_TABLE_HASHSIZE 211
#define AVM_ENDING_PC codeSize
#define AVM_STACKENV_SIZE 4
#define AVM_MAX_INSTRUCTIONS (unsigned) nop_v

execute_func_t executeFuncs[] = {
    execute_assign,
    execute_add,
    execute_sub,
    execute_mul,
    execute_div,
    execute_mod,
    execute_uminus,
    execute_and,
    execute_or,
    execute_not,
    execute_jeq,
    execute_jne,
    execute_jle,
    execute_jge,
    execute_jlt,
    execute_jgt,
    execute_call,
    execute_pusharg,
    execute_funcenter,
    execute_funcexit,
    execute_newtable,
    execute_tablegetelem,
    execute_tablesetelem,
    execute_nop
};

memclear_func_t memclearFuncs[] = {
    0,
    0,
    memclear_string,
    0,
    memclear_table,
    0,
    0,
    0,
    0
};

typedef void (*execute_func_t)(instruction*);
typedef void (*memclear_func_t)(avm_memcell*); 

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
avm_memcell *avm_translate_operand(vmarg *arg, avm_memcell *reg);
void execute_cycle();
void avm_callsaveenvironment();
double  consts_getnumber(unsigned index);
char *consts_getstring(unsigned index);
char *linfuncs_getused(unsigned index);
userfunc *userfuncs_getfunc(unsigned index);

typedef void (*library_func_t)();
library_func_t avm_getlibraryfunc(char *id);
void avm_calllibfunc(char *id);

void execute_assign(instruction *instr);
void execute_add(instruction *instr);
void execute_sub(instruction *instr);
void execute_mul(instruction *instr);
void execute_div(instruction *instr);
void execute_mod(instruction *instr);
void execute_uminus(instruction *instr);
void execute_and(instruction *instr);
void execute_or(instruction *instr);
void execute_not(instruction *instr);
void execute_jeq(instruction *instr);
void execute_jne(instruction *instr);
void execute_jle(instruction *instr);
void execute_jge(instruction *instr);
void execute_jlt(instruction *instr);
void execute_jgt(instruction *instr);
void execute_call(instruction *instr);
void execute_pusharg(instruction *instr);
void execute_funcenter(instruction *instr);
void execute_funcexit(instruction *instr);
void execute_newtable(instruction *instr);
void execute_tablegetelem(instruction *instr);
void execute_tablesetelem(instruction *instr);
void execute_nop(instruction *instr);

memclear_string(avm_memcell *m);
memclear_table(avm_memcell *m);