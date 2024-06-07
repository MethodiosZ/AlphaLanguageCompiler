#include "finalcode.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

extern quad* quads;
extern int currQuad;

double          *numConsts;
unsigned        totalNumConsts = 0;
char            **stringConsts;
unsigned        totalStringConsts = 0;
char            **namedLibFuncs;
unsigned        totalNamedLibFuncs = 0;
userfunc        *userFuncs;
unsigned        totalUserFuncs = 0;
unsigned        currInstruction = 0;
incomplete_jump *ij_head = (incomplete_jump*)0;
unsigned        ij_total = 0;
instruction     *vmargs = (instruction*)0;
unsigned        totalVmargs = 0;
instruction     *instrs;
int             user=0,str=0,num=0,fun=0,insr_s=0,poffset=0;
userfunc        *userfs;
char            **str_c;
char            **lib_f;
instruction     *instrs;
double          *numbers;

char vmopcode_array[27][23]={
	"assign_v", "add_v", "sub_v", "mul_v", "div_v", "mod_v", "uminus_v",
    "and_v", "or_v", "not_v", "jeq_v", "jne_v", "jle_v", "jge_v", "jlt_v",
	"jgt_v", "call_v", "pusharg_v", "ret_v", "getretval_v", "funcenter_v",
	"funcexit_v", "newtable_v", "tablegetelem_v", "tablesetelem_v",
    "jump_v","nop_v"
};

generator_func_t generators[] = {
    generate_ASSIGN,
    generate_ADD,
    generate_SUB,
    generate_MUL,
    generate_DIV,
    generate_MOD,
    generate_UMINUS,
    generate_AND,
    generate_OR,
    generate_NOT,
    generate_IF_EQ,
    generate_IF_NOTEQ,
    generate_IF_LESSEQ,
    generate_IF_GREATEREQ,
    generate_IF_LESS,
    generate_IF_GREATER,
    generate_CALL,
    generate_PARAM,
    generate_RETURN,
    generate_GETRETVAL,
    generate_FUNCSTART,
    generate_FUNCEND,
    generate_NEWTABLE,
    generate_TABLEGETELEM,
    generate_TABLESETELEM,
    generate_JUMP,
    generate_NOP 
};

void GenerateFinal(){
    for(int i =0;i<currQuad;i++){
        (*generators[quads[i].op])(quads);
    }
    return;
}

void make_operand(expr *e, vmarg *arg)
{
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
    q->taddress = nextinstructionlabel();
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
    q->taddress = nextinstructionlabel();
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
    q->taddress = nextinstructionlabel();
    instruction *t;
    t->opcode = jeq_v;
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    make_booloperand(t->arg2,0);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+3;
    emit_v(t);
    
    t->opcode = assign_v;
    make_booloperand(t->arg1,0);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);

    t->opcode = jump_v;
    reset_operand(t->arg1);
    reset_operand(t->arg2);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+2;
    emit_v(t);

    t->opcode = assign_v;
    make_booloperand(t->arg1,1);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
}

void generate_OR(quad* q){
    q->taddress = nextinstructionlabel();
    instruction *t;
    t->opcode = jeq_v;
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    make_booloperand(t->arg2,1);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+4;
    emit_v(t);
    
    if(q->arg2!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg2, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    t->result->val = nextinstructionlabel()+3;
    emit_v(t);

    t->opcode = assign_v;
    make_booloperand(t->arg1,0);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);

    t->opcode = jump_v;
    reset_operand(t->arg1);
    reset_operand(t->arg2);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+2;
    emit_v(t);

    t->opcode = assign_v;
    make_booloperand(t->arg1,1);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
} 

void generate_AND(quad* q){
    q->taddress = nextinstructionlabel();
    instruction *t;
    t->opcode = jeq_v;
    if(q->arg1!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg1, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    make_booloperand(t->arg2,0);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+4;
    emit_v(t);
    
    if(q->arg2!=NULL) {
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->arg2, t->arg1);
    }
    else{
        t->arg1 = NULL;
    }
    t->result->val = nextinstructionlabel()+3;
    emit_v(t);

    t->opcode = assign_v;
    make_booloperand(t->arg1,1);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);

    t->opcode = jump_v;
    reset_operand(t->arg1);
    reset_operand(t->arg2);
    t->result->type = label_a;
    t->result->val = nextinstructionlabel()+2;
    emit_v(t);

    t->opcode = assign_v;
    make_booloperand(t->arg1,0);
    reset_operand(t->arg2);
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
} 

void generate_UMINUS(quad* q){
    q->taddress = nextinstructionlabel();
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

void generate_PARAM(quad* q) {
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = pusharg_v;
    t->srcLine=q->line;
    t->arg1 = NULL;
    t->arg2 = NULL;
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
}

void generate_CALL(quad* q) {
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = call_v;
    t->srcLine=q->line;
    t->arg1 = NULL;
    t->arg2 = NULL;
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
}

void generate_GETRETVAL(quad* q) {
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = assign_v;
    t->srcLine=q->line;
    t->arg1 = malloc(sizeof(vmarg));
    make_retvaloperand(t->arg1);
    t->arg2 = NULL;
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
}

void  generate_FUNCSTART(quad* q){
    symb* f = q->result->sym;
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = funcenter_v;
    t->srcLine=q->line;
    t->arg1 = NULL;
    t->arg2 = NULL;
    if(q->result!=NULL) {
        t->result = malloc(sizeof(vmarg));
        make_operand(q->result, t->result);
    }
    else{
        t->result = NULL;
    }
    emit_v(t);
}

void generate_RETURN(quad* q){
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = assign_v;
    t->srcLine=q->line;  
    if(q->result!=NULL){
        t->arg1 = malloc(sizeof(vmarg));
        make_operand(q->result , t->arg1 );
    }else{
        t->arg1 = malloc(sizeof(vmarg));
		t->arg1->type=nil_a;
	}
    t->arg2 = NULL;
    t->result = malloc(sizeof(vmarg));
    make_retvaloperand(t->result);
    emit_v(t);
}

void generate_FUNCEND(quad* q){   
    q->taddress = nextinstructionlabel();
    instruction *t=malloc(sizeof(instruction)); 
    t->opcode = funcexit_v;
    t->srcLine=q->line;
    t->arg1 = NULL;
    t->arg2 = NULL;
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

unsigned userfuncs_newfunc(symb *sym){
    unsigned index;
    for(unsigned i=0; i<totalUserFuncs;i++){ 
        if(userFuncs[i].address == sym->address && !strcmp(userFuncs[i].id, sym->name))
            return i;
    } 
    if (totalUserFuncs==0)
        userFuncs = malloc(sizeof(userfunc));
    else 
        userFuncs = realloc(userFuncs, sizeof(userfunc)*(totalUserFuncs+1));
    
    userFuncs[totalUserFuncs].address = sym->address;
    userFuncs[totalUserFuncs].localSize = sym->offset; 
    userFuncs[totalUserFuncs].id = sym->name;  
    index=totalUserFuncs++;
    return index;
}

void emit_v(instruction* t){
	assert(t);
	if(totalVmargs==currInstruction){
		expand_v();
    }
    instruction * v=malloc (sizeof(instruction));
    v=vmargs+(currInstruction++);
    v->opcode=t->opcode;
    v->result=t->result;
    v->arg1=t->arg1;
    v->arg2=t->arg2;
    v->srcLine=t->srcLine;
}

void expand_v(){
    assert(totalVmargs==currInstruction);
    instruction *t = (instruction*)malloc(NEW_SIZE_V);
    if(vmargs){
        memcpy(t,vmargs,CURR_SIZE_V);
        free(vmargs);
    }
    vmargs = t;
    totalVmargs += EXPAND_SIZE_V;
}

void reset_operand(vmarg *arg){
    arg->type =  7;
    arg->val = 0;
}

void printVmarg(vmarg* arg){
	if(arg==NULL){
		printf("%-*s \t",10,"\t");
	}
    else{
        if(arg->type == nil_a){
			printf("%-*s \t",20,"NIL");
        }
        else{
        printf(" %d,",arg->type);
        printf("%d",arg->val);
		printf("%-*s",20,"");
        }
	}
}

void printInstructions(){
    int line_for_print = 1;
    printf("\n-----------------------------------------------------------------------------------------------------------------------------\n");    
    printf("\t\t\t\t\t\t\tINSTRUCTIONS\t\t\t\t\t\t\t\t\n");
    printf("------------------------------------------------------------------------------------------------------------------------------\n");    
    printf("#instr\t\t\topcode\t\t\tresult\t\t\targ1\t\t\targ2\t\t\tsrcLine\t\t\n");
    printf("------------------------------------------------------------------------------------------------------------------------------\n");    
    for(int i = 0; i < currInstruction; i++){
        printf("%-*d \t",20,line_for_print++);
        printf("%-*s \t", 20, vmopcode_array[vmargs[i].opcode]);
		if(vmargs[i].opcode== assign_v){
			printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printf("%-*s \t",10,"\t");
        }else if(vmargs[i].opcode == add_v || vmargs[i].opcode== sub_v || vmargs[i].opcode == mul_v || vmargs[i].opcode == div_v || vmargs[i].opcode== mod_v){
           	printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printVmarg(vmargs[i].arg2);
	    }else if(vmargs[i].opcode == uminus_v || vmargs[i].opcode == not_v){
            printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printf("%-*s \t",10,"\t");
	    }else if(vmargs[i].opcode == and_v ||vmargs[i].opcode== or_v ){
		    printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printVmarg(vmargs[i].arg2);
	    }else if(vmargs[i].opcode== jeq_v || vmargs[i].opcode== jne_v || vmargs[i].opcode == jle_v || vmargs[i].opcode== jge_v || vmargs[i].opcode == jlt_v || vmargs[i].opcode == jgt_v){
            printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printVmarg(vmargs[i].arg2);
        }else if(vmargs[i].opcode == call_v || vmargs[i].opcode == return_v || vmargs[i].opcode == jump_v || vmargs[i].opcode == newtable_v || vmargs[i].opcode == funcexit_v || vmargs[i].opcode == getretval_v || vmargs[i].opcode== pusharg_v){
		        printVmarg(vmargs[i].result);
			printf("%-*s \t",10,"\t");
			printf("%-*s \t",10,"\t");
	    }else if(vmargs[i].opcode == funcenter_v){
            printVmarg(vmargs[i].result);
			printf("%-*s \t",10,"\t");
			printf("%-*s \t",10,"\t");
        }else if(vmargs[i].opcode == tablegetelem_v){
            printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printVmarg(vmargs[i].arg2);       
        }else if(vmargs[i].opcode == tablesetelem_v){
           	printVmarg(vmargs[i].result);
			printVmarg(vmargs[i].arg1);
			printVmarg(vmargs[i].arg2);  
	    }
		printf(" %-*d \t",20,vmargs[i].srcLine);
        printf("\n");
    }
}

void InstrToBin(){
	FILE *exe;
	int i;
	int  length;
	int temp;
	int magic_num = 161282016;
	exe= fopen("exe.bi","wb");
	fwrite(&magic_num,sizeof(int),1,exe);
	fwrite(&totalUserFuncs,sizeof(int),1,exe);
	for(i=0;i<totalUserFuncs;i++){
		--userFuncs[i].address;
		fwrite(&userFuncs[i].address,sizeof(int),1,exe);
		fwrite(&userFuncs[i].localSize,sizeof(int),1,exe);
		length = strlen(userFuncs[i].id);
		fwrite(&length,sizeof(int),1,exe);
		fwrite(userFuncs[i].id,length+1,1,exe);
	}
	fwrite(&totalStringConsts,sizeof(int),1,exe);
	for(i=0;i<totalStringConsts;++i){
		length = strlen(stringConsts[i]);
		fwrite(&length,sizeof(int),1,exe);
		fwrite(stringConsts[i],length+1,1,exe);
	}
	fwrite(&totalNumConsts,sizeof(int),1,exe);
	for(i=0;i<totalNumConsts;i++){
		fwrite(&numConsts[i],sizeof(double),1,exe);
	}
	fwrite(&totalNamedLibFuncs,sizeof(int),1,exe);
	for(i=0;i<totalNamedLibFuncs;i++){
		length = strlen(namedLibFuncs[i]);
		fwrite(&length,sizeof(int),1,exe);
		fwrite(namedLibFuncs[i],length+1,1,exe);
	}
	fwrite(&currInstruction,sizeof(int),1,exe);
	for (i = 0; i < currInstruction; i++) {
		int rv=-1,rt=-1,av1=-1,at1=-1,av2=-1,at2=-1;
		instruction instr = vmargs[i];
        fwrite(&instr.opcode, sizeof(int), 1, exe);
		if(instr.result){
        	fwrite(&instr.result->type, sizeof(int), 1, exe);
        	fwrite(&instr.result->val, sizeof(int), 1, exe);
		}else{
			fwrite(&rt, sizeof(int), 1, exe);
        	fwrite(&rv, sizeof(int), 1, exe);
		}
		if(instr.arg1){
        	fwrite(&instr.arg1->type, sizeof(int), 1, exe);
        	fwrite(&instr.arg1->val, sizeof(int), 1, exe);
		}else{
			fwrite(&at1, sizeof(int), 1, exe);
        	fwrite(&av1, sizeof(int), 1, exe);
		}
		if(instr.arg2){
        	fwrite(&instr.arg2->type, sizeof(int), 1, exe);
        	fwrite(&instr.arg2->val, sizeof(int), 1, exe);
		}else{
			fwrite(&at2, sizeof(int), 1, exe);
        	fwrite(&av2, sizeof(int), 1, exe);

		}
        fwrite(&instr.srcLine, sizeof(unsigned), 1, exe);
	}
	fclose(exe);
}

void readBin(){
	FILE *executable;
	executable= fopen("exe.bi","r");
	int magic_number,i,length,temp;
    fread(&magic_number, sizeof(int), 1, executable);
	printf("Magic number: %ld\n", magic_number);
	if(magic_number!=161282016){
		return ;
	}
   	fread(&user, sizeof(int), 1, executable); printf("userfuncs %d\n", user);
	if(user!=0){
		userfs =(userfunc*) malloc(user*sizeof(userfunc));
		for(i=0;i<user;i++){
			//temp=userfs[i].address-1;
			fread(&userfs[i].address, sizeof(int), 1, executable);
			printf("%u ", userfs[i].address);
			fread(&userfs[i].localSize, sizeof(int), 1, executable);
			printf("%u ", userfs[i].localSize);
			fread(&length, sizeof(int), 1, executable);
			
        	userfs[i].id = (char*) malloc(sizeof(char)*(length+1));
        	fread((char*)userfs[i].id, length+1, 1, executable);
			printf("%s\n", userfs[i].id);
		}
	}
	fread(&str, sizeof(int), 1, executable); printf("strings %d\n", str);
	if(str!=0){
		str_c = (char**) malloc(sizeof(char*)*str);
		for(i=0;i<str;i++){
			 fread(&length, sizeof(int), 1, executable);
        	str_c[i] = (char*) malloc(sizeof(char)*(length+1));
       		 fread(str_c[i], length+1, 1, executable);			

		}
	}
	 fread(&num, sizeof(int), 1, executable); printf("numbers %d\n", num);
	 if(num!=0){
		numbers= (double*)malloc(sizeof(double) * num);
		for(i=0;i<num;i++){
			fread(&numbers[i], sizeof(double), 1, executable);
            		printf("%lf\n", numbers[i]);

		}
	}
	fread(&fun, sizeof(int), 1, executable); printf("functions %d\n", fun); 
	if(fun!=0){
		lib_f = (char**) malloc(sizeof(char*)*fun);
		for(i=0;i<fun;i++){
			 fread(&length, sizeof(int), 1, executable);
       		 lib_f[i] = (char*) malloc(sizeof(char)*(length+1));
       		 fread(lib_f[i], length+1, 1, executable);
		}
	}
	fread(&insr_s, sizeof(int), 1, executable); printf("instructions %d\n", insr_s); 
	if(insr_s!=0){
		instrs = (instruction*) malloc((insr_s+1)*sizeof(instruction));
		for(i=0;i<insr_s;i++){
		
			instrs[i].result =(vmarg*) malloc(sizeof(vmarg));
			instrs[i].arg1 =(vmarg*) malloc(sizeof(vmarg));
			instrs[i].arg2 =(vmarg*) malloc(sizeof(vmarg));
			
			fread(&instrs[i].opcode, sizeof(int), 1, executable);
			printf("opcode %d\n", instrs[i].opcode); 
			fread(&instrs[i].result->type, sizeof(int), 1, executable);
			printf("res type %d\n", instrs[i].result->type); 
			fread(&instrs[i].result->val, sizeof(int), 1, executable);
			printf("res val %d\n", instrs[i].result->val); 
			fread(&instrs[i].arg1->type, sizeof(int), 1, executable);
			printf("arg1 type %d\n", instrs[i].arg1->type);
			fread(&instrs[i].arg1->val, sizeof(int), 1, executable);
			printf("arg1 val %d\n", instrs[i].arg1->val);
			fread(&instrs[i].arg2->type, sizeof(int), 1, executable);
			printf("arg2 type %d\n", instrs[i].arg2->type);
			fread(&instrs[i].arg2->val, sizeof(int), 1, executable);
			printf("arg2 val %d\n",instrs[i].arg2->val);
			fread(&instrs[i].srcLine, sizeof(unsigned), 1, executable);
			printf("srcline type %d\n", instrs[i].srcLine);

		}
		
	}
	fread(&poffset,sizeof(int),1,executable);
	printf("total globals %d\n", poffset); 
	fclose(executable);
}

void add_incomplete_jump(unsigned instrNo, unsigned iaddress){
    if(ij_total<instrNo){
        ij_head = (incomplete_jump*)realloc(ij_head,ij_total+1*sizeof(incomplete_jump));
    }
    ij_head[instrNo].iaddress = iaddress;
}

void patch_incomplete_jumps(){
    
}