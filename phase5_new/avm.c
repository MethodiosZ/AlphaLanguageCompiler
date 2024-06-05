#include "avm.h"

avm_memcell stack[AVM_STACKSIZE];
unsigned char   executionFinished = 0;
unsigned        pc = 0;
unsigned        currLine = 0;
unsigned        codeSize = 0;
instruction     *code = (instruction*)0;
avm_memcell     ax, bx, cx;
avm_memcell     retval;
unsigned        top, topsp;
unsigned        totalActuals = 0;
unsigned        N = 0;

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

avm_memcell *avm_translate_operand(vmarg *arg, avm_memcell *reg){
    switch(arg->type){
        case global_a: return &stack[AVM_STACKSIZE-1-arg->val];
        case local_a: return &stack[topsp-arg->val];
        case formal_a: return &stack[topsp+AVM_STACKENV_SIZE+1+arg->val];
        case retval_a: return &retval;
        case number_a: {
            reg->type = number_m;
            reg->data.numVal = consts_getnumber(arg->val);
            return reg;
        }
        case string_a: {
            reg->type = string_m;
            reg->data.strVal =  strdup(consts_getstring(arg->val));
            return reg;
        }
        case bool_a: {
            reg->type = bool_m;
            reg->data.boolVal = arg->val;
            return reg;
        }
        case nil_a: {
            reg->type=nil_m;
            return reg;
        }
        case userfunc_a: {
            reg->type = userfunc_m;
            reg->data.funcVal = arg->val;
            return reg;
        }
        case libfunc_a: {
            reg->type = libfunc_m;
            reg->data.libfuncVal = linfuncs_getused(arg->val);
            return reg;
        }
        default: assert(0);
    }
}

void execute_cycle(){
    if (executionFinished) return;
    else if (pc == AVM_ENDING_PC){
        executionFinished =1;
        return;
    } 
    else {
        assert(pc < AVM_ENDING_PC);
        instruction *t = code + pc;
        assert(t->opcode >=  0 && t->opcode <= AVM_MAX_INSTRUCTIONS);
        if (t->srcLine) currLine = t->srcLine;
        unsigned oldPC = pc;
        (*executeFuncs[t->opcode])(t);
        if (pc==oldPC) ++pc;
    }
}

void avm_memcellclear(avm_memcell*m){
    if(m->type != undef_m){
        memclear_func_t f = memclearFuncs[m->type];
        if(f) (*f)(m);
        m->type = undef_m;
    }
}

void memclear_string(avm_memcell *m){
    assert(m->data.strVal);
    free(m->data.strVal);
}

void memclear_table(avm_memcell *m){
    assert(m->data.tableVal);
    avm_tabledecrefcounter(m->data.tableVal);
}

void avm_assign(avm_memcell *lv, avm_memcell *rv){
    if(lv==rv) return;
    if(lv->type == table_m && rv->type ==table_m && 
    lv->data.tableVal == rv->data.tableVal) return;
    if(rv->type == undef_m) avm_warning("assigning from 'undef' content!");
    avm_memcellclear(lv);
    memcpy(lv,rv,sizeof(avm_memcell));
    if(lv->type == string_m) lv->data.strVal = strdup(rv->data.strVal);
    else if(lv->type == table_m) avm_tableincrefcounter(lv->data.tableVal);
}

void avm_call_functor(avm_table *t){
    cx.type = string_m;
    cx.data.strVal = "()";
    avm_memcell *f = avm_tablegetelem(t, &cx);
    if(!f) avm_error("in calling table: no '()' element found!");
    else if(f->type == table_m) avm_call_functor(f->data.tableVal);
    else if(f->type == userfunc_m){
        avm_push_table_arg(t);
        avm_callsaveenvironment();
        pc = f->data.funcVal;
        assert(pc < AVM_ENDING_PC && code[pc].opcode == funcenter_v);
    }
    else {
        avm_error("in calling table: illegal '()' element value!");
    }
}

void avm_dec_top(){
    if(!top){
        avm_error("Stack overflow!");
        executionFinished = 1;
    }
    else --top;
}

void avm_push_envvalue(unsigned val){
    stack[top].type = number_m;
    stack[top].data.numVal = val;
    avm_dec_top();
}

void avm_callsaveenvironment(){
    avm_push_envvalue(totalActuals);
    assert(code[pc].opcode == call_v);
    avm_push_envvalue(pc+1);
    avm_push_envvalue(top+totalActuals+2);
    avm_push_envvalue(topsp);
}

unsigned avm_get_envvalue(unsigned i){
    assert(stack[i].type == number_m);
    unsigned val = (unsigned) stack[i].data.numVal;
    assert(stack[i].data.numVal == (double)val);
    return val;
}

void avm_calllibfunc(char *id){
    library_func_t f = avm_getlibraryfunc(id);
    if(!f){
        //pass as one string
        avm_error("unsupported lib func s called!");
        executionFinished = 1;
    }
    else {
        avm_callsaveenvironment();
        topsp = top;
        totalActuals = 0;
        (*f)();
        if(!executionFinished) execute_funcexit((instruction*)0);
    }
}

unsigned avm_totalactuals(){
    return avm_get_envvalue(topsp + AVM_NUMACTUALS_OFFSET);
}

avm_memcell *avm_getactual(unsigned i){
    assert(i < avm_totalactuals());
    return &stack[topsp + AVM_STACKENV_SIZE + 1 + i];
}

void libfunc_print(){
    unsigned n = avm_totalactuals();
    for(unsigned i = 0; i < n; ++i){
        char *s = avm_tostring(avm_getactual(i));
        puts(s);
        free(s);
    }
}

void lifunc_typeof(){
    unsigned n = avm_totalactuals();
    if(n!=1) avm_error("one argument (not d) expected in 'typeof'!");
    else {
        avm_memcellclear(&retval);
        retval.type = string_m;
        retval.data.strval = strdup(typeStrings[avm_getactual(0)->type]);
    }
}

void libfunc_totalarguments(){
    unsigned p_topsp = avm_get_envvalue(topsp + AVM_SAVETOPSP_OFFSET);
    avm_memcellclear(&retval);
    if(!p_topsp) {
        avm_error("'totalarguments' called outside a function!");
        retval.type = nil_m;
    }
    else {
        retval.type = number_m;
        retval.data.numVal = avm_get_envvalue(p_topsp + AVM_NUMACTUALS_OFFSET);
    }
}

void avm_push_table_arg(avm_table *t){
    stack[top].type = table_m;
    avm_tableincrefcounter(stack[top].data.tableVal = t);
    ++totalActuals;
    avm_dec_top();
}

char *avm_tostring(avm_memcell *m){
    assert(m->type >= 0 && m->type <= undef_m);
    return(*tostringFuncs[m->type])(m);
}

void execute_assign(instruction *instr){
    avm_memcell *lv = avm_translate_operand(&instr->result, (avm_memcell*)0);
    avm_memcell *rv = avm_translate_operand(&instr->arg1, &ax);
    assert(lv && (&stack[N-1] >= lv && lv > &stack[top] || lv==&retval));
    assert(rv && (&stack[N-1] >= rv && rv > &stack[top] || rv==&retval));
    avm_assign(lv,rv);
}

void execute_call(instruction *instr){
    avm_memcell *func = avm_translate_operand(&instr->result, &ax);
    assert(func);
    switch(func->type){
        case userfunc_m: {
            avm_callsaveenvironment();
            pc = func->data.funcVal;
            assert(pc < AVM_ENDING_PC);
            assert(code[pc].opcode == funcenter_v);
            break;
        }
        case string_m:
            avm_calllibfunc(func->data.strVal);
            break;
        case libfunc_m:
            avm_calllibfunc(func->data.libfuncVal);
            break;
        case table_m:
            avm_call_functor(func->data.tableVal);
            break;
        default: {
            char *s = avm_tostring(func);
            avm_error("call: cannot bind to function!");
            free(s);
            executionFinished = 1;
        }
    }
}

void execute_funcenter(instruction *instr){
    avm_memcell *func = avm_translate_operand(&instr->result, &ax);
    assert(func);
    assert(pc == func->data.funcVal);
    totalActuals = 0;
    userfunc *funcInfo = avm_getfuncinfo(pc);
    topsp = top;
    top = top - funcInfo->localSize;
}

void execute_funcexit(instruction *unused){
    unsigned oldTop = top;
    top = avm_get_envvalue(topsp + AVM_SAVEDTOP_OFFSET);
    pc = avm_get_envvalue(topsp + AVM_SAVEDPC_OFFSET);
    topsp = avm_get_envvalue(topsp + AVM_SAVEDTOPSP_OFFSET);
    while(++oldTop <= top){
        avm_memcellclear(&stack[oldTop]);
    }
}

void execute_pusharg(instruction *instr){
    avm_memcell *arg = avm_translate_operand(&instr->arg1, &ax);
    assert(arg);
    avm_assign(&stack[top],arg);
    ++totalActuals;
    avm_dec_top();
}
