#define TABLE_SIZE 16
typedef enum {
    GLOBAL, LOCAL, FORMAL, USERFUNC, LIBFUNC
} type_t;
typedef struct Variable{
    const char* name;
    unsigned int scope;
    unsigned int line;
} Var;
typedef struct Function{
    const char* name;
    unsigned int scope;
    unsigned int line;
} Func;
typedef struct Symbol{
    int isActive;
    union{
        Var *VarVal;
        Func *FuncVal;
    } value;
    type_t type;
} Sym;
typedef struct Symbol_Table{
    Sym *symbol;
    struct Symbol_Table *next;
} SymTable;
Sym* createSymbol(char* name,int scope,int line,type_t type);
Var* createVariable(char* name,int scope,int line);
Func* createFunction(char* name,int scope,int line);
void Insert(Sym *nsymbol);
Sym* Search(char* name);
void InitTable();
void PrintTable();