#ifndef	EXEC_H_
#define EXEC_H_

#include "quad.h"

#define AVM_STACKSIZE       4096
#define AVM_WIPEOUT(m)      memset (&(m), 0, sizeof(m))
#define AVM_TABLE_HASHSIZE  211

//Definitions
typedef enum Vmopcode vmopcode;
typedef enum Vmarg_t vmarg_t;
typedef enum Avm_memcell_t avm_memcell_t;
typedef struct Vmarg vmarg;
typedef struct Instruction instruction;
typedef struct Userfunc userfunc;
typedef struct Avm_table avm_table;
typedef struct Avm_memcell avm_memcell;
typedef struct Avm_table_bucket avm_table_bucket;

//Declarations
avm_memcell stack[AVM_STACKSIZE];

double*     numConsts;
unsigned    totalNumConsts;
char**      stringConsts;
unsigned    totalStringConsts;
char**      namedLibfuncs;
unsigned    totalNamedLibfuncs;
userfunc*   userFuncs;
unsigned    totalUserFuncs;

//Enums
enum Vmopcode {
    assign_v,       add_v,          sub_v,
    mul_v,          div_v,          mod_v,
    uminus_v,       and_v,          or_v,
    not_v,          jeq_v,          jne_v,
    jle_v,          jge_v,          jlt_v,
    jgt_v,          call_v,         pusharg_v,
    funcenter_v,    funcexit_v,     newtable_v,
    tablegetelem_v, tablesetelem_v, nop_v
};

enum Vmarg_t {
    label_a,    global_a,   formal_a,
    local_a,    number_a,   string_a,
    bool_a,     nil_a,      userfunc_a,
    libfunc_a,  retval_a
};

enum Avm_memcell_t {
    number_m,   string_m,   bool_m,
    table_m,    userfunc_m, libfunc_m,
    nil_m,      undef_m
};

//Structs
struct Vmarg {
    vmarg_t     type;
    unsigned    val;
};

struct  Instruction {
    vmopcode    opcode;
    vmarg       result;
    vmarg       arg1;
    vmarg       arg2;
    unsigned    srcLine;
};

struct Userfunc {
    unsigned    address;
    unsigned    localsize;
    char*       id;
};

struct Avm_table{
    unsigned            refCounter;
    avm_table_bucket*   strIndexed[AVM_TABLE_HASHSIZE];
    avm_table_bucket*   numIndexed[AVM_TABLE_HASHSIZE];
    unsigned            total;
};

struct Avm_memcell {
    avm_memcell_t type;
    union {
        double          numVal;
        char*           strVal;
        unsigned char   boolVal;
        avm_table*      tableVal;
        unsigned        funcVal;
        char*           libfuncVal;
    } data;
};

struct Avm_table_bucket {
    avm_memcell         key;
    avm_memcell         value;
    avm_table_bucket*   next;
};

//Functions
static void     avm_initstack();
avm_table*      avm_tablenew();
void            avm_tabledestroy (avm_table* t);
avm_memcell*    avm_tablegetelem (avm_memcell* key);
void            avm_tablesetelem (avm_memcell* key, avm_memcell* value);
void            avm_tableincrefcounter (avm_table* t);
void            avm_tabledecrefcounter (avm_table* t);
void            avm_tablebucketsinit (avm_table_bucket** p);
void            avm_memcellclear (avm_memcell* m);
void            avm_tablebucketsdestroy (avm_table_bucket** p);
unsigned        consts_newstring (char* s);
unsigned        consts_newnumber (double n);
unsigned        libfuncs_newused (char* s);
unsigned        userfuncs_newfunc (Variable* sym);
void            make_operand (expr* e, vmarg* arg);
void            make_numberoperand (vmarg* arg, double val);
void            make_booloperand (vmarg* arg, unsigned val);
void            make_retvaloperand (vmarg* arg);

#endif