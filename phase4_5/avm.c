#include <assert.h>
#include <string.h>
#include <stdio.h>
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

extern double   *numConsts;
extern char     **stringConsts;
extern char     **namedLibFuncs;
extern userfunc *userFuncs;

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
    execute_return,
    execute_getretval,
    execute_funcenter,
    execute_funcexit,
    execute_newtable,
    execute_tablegetelem,
    execute_tablesetelem,
    execute_jump,
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

tosting_func_t tostringFuncs[]={
    number_tostring,
    string_tostring,
    bool_tostring,
    table_tostring,
    userfunc_tostring,
    libfunc_tostring,
    nil_tostring,
    undef_tostring
};

arithmetic_func_t arithmeticFuncs[] = {
    add_impl,
    sub_impl,
    mul_impl,
    div_impl,
    mod_impl
};

tobool_func_t toboolFuncs[] = {
    number_tobool,
    string_tobool,
    bool_tobool,
    table_tobool,
    userfunc_tobool,
    libfunc_tobool,
    nil_tobool,
    undef_tobool
};

char *typeStrings[] = {
    "number", "string", "bool", "table", "userfunc", "libfunc", "nil", "undef"
};

void avm_initialize(){
    avm_initstack();
    top = AVM_STACKSIZE-2;
    topsp = AVM_STACKSIZE-1;
}

void avm_initstack(){
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

avm_memcell *avm_tablegetelem(avm_table *table, avm_memcell *index){
    assert(table);
    assert(index);
    avm_memcell *result = (avm_memcell*)0;
    avm_table_bucket *tmp = avm_tablelookup(table,index);
    if(tmp == NULL) avm_error("Table not existent!");
    else result = tmp->value;
    return result;
}

void avm_tablesetelem(avm_table *table, avm_memcell *index, avm_memcell *value){
    avm_table_bucket *new;
    avm_table_bucket *head;
    assert(table);
    assert(index);
    assert(value);
    if(index->type != number_m && index->type != string_m){
        avm_error("Index can only be string or number!");
    }
    else if(index->type == number_m){
        int key = HashN(index->data.numVal);
        avm_table_bucket *tmp = avm_tablelookup(table,index);
        if(value->type == nil_m){
            if(tmp != NULL){
                avm_memcellclear(tmp->key);
                avm_memcellclear(tmp->value);
            }
            if(table->total > 0) table->total--;
            return;
        }
        if(tmp == NULL){
            head = table->numIndexed[key];
            new = (avm_table_bucket*)malloc(sizeof(avm_table_bucket));
            if(!new) avm_error("Not enough space \n");
            new->key = index;
            new->value = value;
            new->next = head;
            table->numIndexed[key] = new; 
        }
        else avm_assign(tmp->value, value);
        table->total++;
    }
    else{
        int key = HashS(index->data.strVal);
        avm_table_bucket *tmp = avm_tablelookup(table,index);
        if(value->type == nil_m){
		    if(tmp != NULL) {
            		avm_memcellclear(tmp->key);
            		avm_memcellclear(tmp->value);
        	}
		    if(table->total > 0) table->total--;
        	return;
	    }
        if(tmp == NULL){
		    head = table->strIndexed[key];
            new = (avm_table_bucket*)malloc(sizeof(avm_table_bucket));
		    if(!new) avm_error("Not enough space \n");
		    new->key= index;
        	new->value= value;
            new->next = head;
		    table->strIndexed[key] = new;
        }
        else avm_assign(tmp->value, value);
	    table->total++;
    }
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

void avm_warning(char *format){
    printf("Warning: %s\n",format);
}

void avm_assign(avm_memcell *lv, avm_memcell *rv)
{
    if(lv==rv) return;
    if(lv->type == table_m && rv->type ==table_m && 
    lv->data.tableVal == rv->data.tableVal) return;
    if(rv->type == undef_m) avm_warning("assigning from 'undef' content!");
    avm_memcellclear(lv);
    memcpy(lv,rv,sizeof(avm_memcell));
    if(lv->type == string_m) lv->data.strVal = strdup(rv->data.strVal);
    else if(lv->type == table_m) avm_tableincrefcounter(lv->data.tableVal);
}

void avm_error(char *format){
    printf("Error!: %s\n",format);
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

double consts_getnumber(unsigned index){
    return numConsts[index];
}

char *consts_getstring(unsigned index){
    return stringConsts[index];
}

char *linfuncs_getused(unsigned index){
    return namedLibFuncs[index];
}

userfunc *userfuncs_getfunc(unsigned index){
    return &userFuncs[index];
}

unsigned avm_get_envvalue(unsigned i){
    assert(stack[i].type == number_m);
    unsigned val = (unsigned) stack[i].data.numVal;
    assert(stack[i].data.numVal == (double)val);
    return val;
}

userfunc *avm_getfuncinfo(unsigned address){
    return &userFuncs[address];
}

library_func_t avm_getlibraryfunc(char *id){
    int key = HashL(id);
    if(key<12) return namedLibFuncs[key]; 
    return (library_func_t)0;
}

void avm_calllibfunc(char *id)
{
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

void avm_registerlibfunc(char *id, library_func_t addr){
    return;
}

void lifunc_typeof(){
    unsigned n = avm_totalactuals();
    if(n!=1) avm_error("one argument (not d) expected in 'typeof'!");
    else {
        avm_memcellclear(&retval);
        retval.type = string_m;
        retval.data.strVal = strdup(typeStrings[avm_getactual(0)->type]);
    }
}

void libfunc_totalarguments(){
    unsigned p_topsp = avm_get_envvalue(topsp + AVM_SAVEDTOPSP_OFFSET);
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

char *number_tostring(avm_memcell *m){
    int n;
    n = getNumberOfDigits(m->data.numVal);
    char* buffer = malloc(40*sizeof(char));
    sprintf(buffer,"%0.3f",m->data.numVal);
    return buffer;
}

int getNumberOfDigits(int a){
	int count = 0;
	while(a > 0){
		count++;
		a = a/10;
	}
	return count;
}

char *string_tostring(avm_memcell *m){
    char* buffer =strdup(m->data.strVal);
	return buffer;
}

char *bool_tostring(avm_memcell *m){
    if(m->data.boolVal == 0)
		return strdup("False");
	else
		return strdup("True");
}

char *table_tostring(avm_memcell *m){
    return ;
}

char *userfunc_tostring(avm_memcell *m){
    char* buff;
	buff = strdup(userFuncs[m->data.funcVal].id);	
	return buff;
}

char *libfunc_tostring(avm_memcell *m){
    char* buff;
	buff = strdup(m->data.libfuncVal);	
	return buff;
}

char *nil_tostring(avm_memcell *m){
   return strdup("nil");
}

char *undef_tostring(avm_memcell *m){
    return strdup("undef");
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
    avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell*)0);
    avm_memcell *rv = avm_translate_operand(instr->arg1, &ax);
    assert(lv && (&stack[N-1] >= lv && lv > &stack[top] || lv==&retval));
    assert(rv && (&stack[N-1] >= rv && rv > &stack[top] || rv==&retval));
    avm_assign(lv,rv);
}

void execute_call(instruction *instr){
    avm_memcell *func = avm_translate_operand(instr->result, &ax);
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
    avm_memcell *func = avm_translate_operand(instr->result, &ax);
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
    avm_memcell *arg = avm_translate_operand(instr->arg1, &ax);
    assert(arg);
    avm_assign(&stack[top],arg);
    ++totalActuals;
    avm_dec_top();
}

void execute_return(instruction *instr){
    assert(0);
    return;
}

void execute_getretval(instruction *instr){
    assert(0);
    return;
}

void execute_jeq(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell *rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell *rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if(rv1->type == undef_m || rv2->type == undef_m){
        avm_error("'undef' involved in equality!");
    }
    else if(rv1->type == nil_m || rv2->type == nil_m){
        result = rv1->type == nil_m && rv2->type == nil_m;
    }
    else if(rv1->type == bool_m || rv2->type == bool_m){
        result = (avm_tobool(rv1) == avm_tobool(rv2));
    }
    else if(rv1->type != rv2->type){
        avm_error("Illegal equality check!");
    }
    else{
        result = (avm_toarithm(rv1) == avm_toarithm(rv2)); 
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_jne(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell* rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell* rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
        avm_error("undef involved in inequality");
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m){
        result = (avm_tobool(rv1) != avm_tobool(rv2)); 
	}
    else if(rv1->type != rv2->type){
        avm_error("Illegal inequality check!");
    }
    else {
        result = (avm_toarithm(rv1) != avm_toarithm(rv2)); 
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_jle(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell* rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell* rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
        avm_error("undef involved in jle");
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result =(avm_tobool(rv1) <= avm_tobool(rv2));
    else if(rv1->type != rv2->type){
        avm_error("Illegal less or equal check!");
    }
    else {
        result = (avm_toarithm(rv1) <= avm_toarithm(rv2));
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_jge(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell* rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell* rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
        avm_error("undef involved in jge");
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result =(avm_tobool(rv1) >= avm_tobool(rv2));
    else if(rv1->type != rv2->type){
        avm_error("Illegal greater or equal check!");
    }
    else {
        result = (avm_toarithm(rv1) >= avm_toarithm(rv2));
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_jlt(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell* rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell* rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
        avm_error("undef involved in jlt");
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result =(avm_tobool(rv1) < avm_tobool(rv2));
    else if(rv1->type != rv2->type){
        avm_error("Illegal less check!");
    }
    else {
        result = (avm_toarithm(rv1) < avm_toarithm(rv2));
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_jgt(instruction *instr){
    assert(instr->result->type == label_a);
    avm_memcell* rv1 = avm_translate_operand(instr->arg1, &ax);
    avm_memcell* rv2 = avm_translate_operand(instr->arg2, &bx);
    unsigned char result = 0;
    if (rv1->type == undef_m || rv2->type == undef_m)
        avm_error("undef involved in jgt");
    else if (rv1->type == nil_m || rv2->type == nil_m)
        result = rv1->type == nil_m && rv2->type == nil_m;
    else if (rv1->type == bool_m || rv2->type == bool_m)
        result =(avm_tobool(rv1) > avm_tobool(rv2));
    else if(rv1->type != rv2->type){
        avm_error("Illegal greater check!");
    }
    else {
        result = (avm_toarithm(rv1) > avm_toarithm(rv2));
    }
    if(!executionFinished && result) pc = instr->result->val-1;
}

void execute_newtable(instruction *instr){
    avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell*)0);
    assert(lv && (&stack[0] <= lv && &stack[top] > lv || lv==&retval));
    avm_memcellclear(lv);
    lv->type = table_m;
    lv->data.tableVal = avm_tablenew();
    avm_tableincrefcounter(lv->data.tableVal);
}

void execute_tablegetelem(instruction *instr){
    avm_memcell *lv = avm_translate_operand(instr->result,(avm_memcell*)0);
    avm_memcell *t = avm_translate_operand(instr->arg1,(avm_memcell*)0);
    avm_memcell *i = avm_translate_operand(instr->arg2,&ax);
    assert(lv && (&stack[0] <= lv && &stack[top] > lv || lv==&retval));
    assert(t && &stack[0] <= t && &stack[top] > t);
    assert(i);
    avm_memcellclear(lv);
    lv->type = nil_m;
    if(t->type != table_m){
        avm_error("illegal use of type as table!");
    }
    else{
        avm_memcell *content = avm_tablegetelem(t->data.tableVal,i);
        if(content) avm_assign(lv, content);
        else{
            char *ts = avm_tostring(t);
            char *is = avm_tostring(i);
            avm_warning("table not found!");
            free(ts);
            free(is);
        }
    }
}

void execute_tablesetelem(instruction *instr){
    avm_memcell *t = avm_translate_operand(instr->result, (avm_memcell*)0);
    avm_memcell *i = avm_translate_operand(instr->arg1, &ax);
    avm_memcell *c = avm_translate_operand(instr->arg2, &bx);
    assert(t && &stack[0] <= t && &stack[top] > t);
    assert(i && c);
    if(t->type != table_m) avm_error("Illegal use of type as table!");
    else avm_tablesetelem(t->data.tableVal,i,c);
}

void execute_jump(instruction *instr){
    assert(instr->result->type == label_a);
    if(!executionFinished) pc = instr->result->val-1;
}

void execute_nop(instruction *instr){
    assert(0);
    return;
}

double add_impl(double x, double y){
    return x+y;
}

double sub_impl(double x, double y){
    return x-y;
}

double mul_impl(double x, double y){
    return x*y;
}

double div_impl(double x, double y){
    if(y!=0) return x/y;
    else avm_error("Division with zero!");
}

double mod_impl(double x, double y){
    if(y!=0) return ((unsigned)x) % ((unsigned)y);
    else avm_error("Division with zero!");
}

void execute_arithmetic(instruction *instr){
    avm_memcell *lv = avm_translate_operand(instr->result, (avm_memcell*)0);
    avm_memcell *rv1 = avm_translate_operand(instr->arg1,&ax);
    avm_memcell *rv2 = avm_translate_operand(instr->arg2,&bx);
    assert(lv && (&stack[0] <= lv && &stack[top] > lv || lv==&retval));
    assert(rv1 && rv2);
    if(rv1->type != number_m || rv2->type != number_m){
        avm_error("not a number in arithmetic!");
        executionFinished = 1;
    }
    else {
        arithmetic_func_t op = arithmeticFuncs[instr->opcode-add_v];
        avm_memcellclear(lv);
        lv->type = number_m;
        lv->data.numVal = (*op)(rv1->data.numVal, rv2->data.numVal);
    }
}

void execute_add(instruction *instr){
    execute_arithmetic(instr);
    return;
}

void execute_sub(instruction *instr){
    execute_arithmetic(instr);
    return;
}

void execute_mul(instruction *instr){
    execute_arithmetic(instr);
    return;
}

void execute_div(instruction *instr){
    execute_arithmetic(instr);
    return;
}

void execute_mod(instruction *instr){
    execute_arithmetic(instr);
    return;
}

unsigned char number_tobool(avm_memcell *m){
    return m->data.numVal != 0;
}

unsigned char string_tobool(avm_memcell *m){
    return m->data.strVal[0] != 0;
}

unsigned char bool_tobool(avm_memcell *m){
    return m->data.boolVal;
}

unsigned char table_tobool(avm_memcell *m){
    return 1;
}

unsigned char userfunc_tobool(avm_memcell *m){
    return 1;
}

unsigned char libfunc_tobool(avm_memcell *m){
    return 1;
}

unsigned char nil_tobool(avm_memcell *m){
    return 0;
}

unsigned char undef_tobool(avm_memcell *m){
    assert(0);
    return 0;
}

unsigned char avm_tobool(avm_memcell *m){
    assert(m->type >= 0 && m->type < undef_m);
    return (*toboolFuncs[m->type])(m);
}

void execute_uminus(instruction *instr){
    assert(0);
    return;
}

void execute_and(instruction *instr){
    assert(0);
    return;
}

void execute_or(instruction *instr){
    assert(0);
    return;
}

void execute_not(instruction *instr){
    assert(0);
    return;
}
