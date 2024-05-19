#include "exec.h"

void make_operand(expr *e, vmarg *arg){
    switch(e->type){
        case var_e:
        case tableitem_e:
        case arithexpr_e:
        case boolexpr_e:
        case newtable_e:
            arg->val = e->sym->offset;
            switch(e->sym->space){
                case programvar:
                    arg->type = global_a;
                    break;
                case functionlocal:
                    arg->type = local_a;
                    break;
                case formalarg:
                    arg->type = formal_a;
                    break;
                default:
                    assert(0);
            }
            break;
        case constbool_e:
            arg->val = e->boolConst;
            arg->type = bool_a;
            break;
        case conststring_e:
            arg->val = consts_newstring(e->strConst);
            arg->type = string_a;
            break;
        //case constnum
        case nil_e:
            arg->type = nil_a;
            break;
        case programfunc_e:
            arg->type = userfunc_a;
            arg->val = userfuncs_newfunc(e->sym);
            break;
        case libraryfunc_e:
            arg->type = libfunc_a;
            arg->val = libfuncs_newused(e->sym->name);
            break;
        default:
            assert(0);
    }
}

void generate(){
    for(unsigned i=0;i<ij_total;++i){
        (*generators[quads[i].op])(quads+i);
    }
}

static void avm_initstack(){
    for(unsigned i=0;i<AVM_STACKSIZE;++i){
        AVM_WIPEOUT(stack[i]);
        stack[i].type = undef_m;
    }
}

avm_table *avm_tablenew(){
    avm_table *t = (avm_table*)malloc(sizeof(avm_table));
    AVM_WIPEOUT(*t);
    t->refCounter = t->total = 0;
    avm_tablebucketsinit(t->numIndexed);
    avm_tablebucketsinit(t->strIndexed);
    return t;
}

void avm_tableincrefcounter(avm_table *t){
    ++t->refCounter;
}

void avm_tabledecrefcounter(avm_table *t){
    assert(t->refCounter>0);
    if(!--t->refCounter) avm_tabledestroy(t);
}

void avm_tablebucketsinit(avm_table_bucket **p){
    for(unsigned i=0;i<AVM_TABLE_HASHSIZE;++i){
        p[i] = (avm_table_bucket*)0;
    }
}

void avm_tabledestroy(avm_table *t){
    avm_tablebucketsdestroy(t->strIndexed);
    avm_tablebucketsdestroy(t->numIndexed);
    free(t);
}

void avm_tablebucketsdestroy(avm_table_bucket **p){
    for(unsigned i=0; i<AVM_STACKSIZE;++i,++p){
        for(avm_table_bucket *b = *p;b;){
            avm_table_bucket *del = b;
            b = b->next;
            avm_memcellclear(&del->key);
            avm_memcellclear(&del->value);
            free(del);
        }
        p[i] = (avm_table_bucket*)0;
    }
}

void make_numberoperand(vmarg *arg, double val){
    arg->val = consts_newnumber(val);
    arg->type = number_a;
}

void make_booloperand(vmarg *arg, unsigned val){
    arg->val = val;
    arg->type = bool_a;
}

void make_retvaloperand(vmarg *arg){
    arg->type = retval_a;
}