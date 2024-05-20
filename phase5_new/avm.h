#include "exec.h"

#define AVM_STACKSIZE   4096
#define AVM_WIPEOUT(m)  memset(&(m),0,sizeof(m))
#define AVM_TABLE_HASHSIZE  211

avm_memcell stack[AVM_STACKSIZE];

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