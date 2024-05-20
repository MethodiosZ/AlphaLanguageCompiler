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
            arg->val = ((e->boolConst=='T')?1:0);
            arg->type = bool_a;
            break;
        case conststring_e:
            arg->val = consts_newstring(e->strConst);
            arg->type = string_a;
            break;
        case constint_e:
            arg->val = consts_newnumber(e->intConst);
            arg->type = number_a;
            break;
        case constdouble_e:
            arg->val = consts_newnumber(e->doubleConst);
            arg->type = number_a;
            break;
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

void generate(vmopcode_t op,quad* q){
    instruction *t = malloc(sizeof(instruction));
    t->opcode = op;
    t->srcLine = q->line;
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    if(q->arg2!=NULL) {
        t->arg2 = malloc(sizeof(vmarg));
        make_operand(q->arg2, t->arg2);
    }
    else{
        t->arg2 = NULL;
    }
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    q->label = nextinstructionlabel();
    emit_v(t);
}

void generate_ADD(quad* q){ 
    generate(add_v, q); 
}

void generate_SUB(quad* q){ 
    generate(sub_v, q); 
}

void generate_MUL(quad* q){ 
    generate(mul_v, q); 
}

void generate_DIV(quad* q){ 
    generate(div_v, q); 
}

void generate_MOD(quad* q){
    generate(mod_v, q); 
}

void generate_NEWTABLE(quad* q){ 
    generate(newtable_v, q); 
}

void generate_TABLEGETELEM(quad* q){ 
    generate(tablegetelem_v, q); 
}

void generate_TABLESETELEM(quad* q){ 
    generate(tablesetelem_v, q); 
}

void generate_ASSIGN(quad* q){  
    generate(assign_v, q); 
}

void generate_NOP(){ 
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode=nop_v; 
    t->arg1 = NULL;
    t->arg2 = NULL;
    t->result = NULL;
    emit_v(t);
}

void generate_relational(vmopcode_t op,quad* q){
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = op;
    t->srcLine=q->line;
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    if(q->arg2!=NULL) {
        t->arg2 = malloc(sizeof(vmarg));
        make_operand(q->arg2, t->arg2);
    }
    else{
        t->arg2 = NULL;
    }
    t->result = malloc(sizeof(vmarg));
    t->result->type=label_a;
    t->result->val=q->label;
    q->label = nextinstructionlabel();
    emit_v(t);
}

void generate_JUMP(quad* q){ 
    generate_relational(jump_v, q); 
}

void generate_IF_EQ(quad* q){ 
    generate_relational(jeq_v, q); 
}

void generate_IF_NOTEQ(quad* q){ 
    generate_relational(jne_v, q); 
}

void generate_IF_GREATER(quad* q){ 
    generate_relational(jgt_v, q); 
}

void generate_IF_GREATEREQ(quad* q){ 
    generate_relational(jge_v, q); 
}

void generate_IF_LESS(quad* q){ 
    generate_relational(jlt_v, q); 
}

void generate_IF_LESSEQ(quad* q){ 
    generate_relational(jle_v, q); 
}

void generate_NOT(quad* q){
    return;
}

void generate_OR(quad* q){
    return;
} 

void generate_AND(quad* q){
    return;
} 

void generate_UMINUS(quad* q){
    instruction* t = malloc(sizeof(instruction));
    t->opcode = mul_v;
    t->srcLine = q->line;  
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    t->arg2 = malloc(sizeof(vmarg));
    make_numberoperand(t->arg2, -1);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
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

unsigned int nextinstructionlabel(){
	return currInstruction ;
}

unsigned consts_newstring(char* s){
    unsigned index;
    for(unsigned i=0; i<totalStringConsts; ++i) {
        if(strcmp(stringConsts[i], s)==0)
            return i;
    }
    if (totalStringConsts==0)
        stringConsts = malloc(sizeof(char*));
    else 
        stringConsts = realloc(stringConsts, sizeof(char*)*(totalStringConsts+1));

    stringConsts[totalStringConsts] = strdup(s);
    index=totalStringConsts++;
    return index;
}

unsigned consts_newnumber(double n){
    unsigned index;
    for(unsigned i=0;i<totalNumConsts;i++){
        if(numConsts[i]==n) return i;
    }
    if(totalNumConsts==0){
        numConsts=malloc(sizeof(double));
    }else numConsts= realloc(numConsts,sizeof(double)*(totalNumConsts+1));
    
    numConsts[totalNumConsts]=n;
    index=totalNumConsts++;
    return index;
}

unsigned libfuncs_newused(char* s){
    unsigned index;
    for(unsigned i=0; i<totalNamedLibFuncs; ++i) {
        if(strcmp(namedLibFuncs[i], s)==0)
            return i;
    }
    if (totalNamedLibFuncs==0)
        namedLibFuncs = malloc(sizeof(char*));
    else 
        namedLibFuncs = realloc(namedLibFuncs, sizeof(char*)*(totalNamedLibFuncs+1));

    namedLibFuncs[totalNamedLibFuncs] = strdup(s);
    index=totalNamedLibFuncs++;
    return index;
}

unsigned userfuncs_newfunc(Sym *sym){
    /*unsigned index;
    for(unsigned i=0; i<totalUserFuncs;i++){ 
        if(userFuncs[i].address == sym. && !strcmp(userFuncs[i].id, (sym->value).funcVal->name))
            return i;
    } 
    if (totalUserFuncs==0)
        userFuncs = malloc(sizeof(userfunc));
    else 
        userFuncs = realloc(userFuncs, sizeof(userfunc)*(totalUserFuncs+1));
    
    userFuncs[totalUserFuncs].address = sym->address; //na to valw sto funcprefix ston parser $$->sym->address= ..;
    userFuncs[totalUserFuncs].localSize = sym->value.funcVal->totalLocals; 
    userFuncs[totalUserFuncs].id = sym->value.funcVal->name;  
    index=totalUserFuncs++;
    return index;*/
}

void emit_v(instruction* t){
	/*assert(t);
	if(totalVmargs==currInstruction)
		expand_v();
    instruction * v=malloc (sizeof(instruction));
    v=vmargs+(currInstruction++);
    v->opcode=t->opcode;
    v->result=t->result;
    v->arg1=t->arg1;
    v->arg2=t->arg2;
    v->srcLine=t->srcLine;*/
}