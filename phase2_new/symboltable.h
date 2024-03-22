#define HASH_SIZE 256
typedef enum {
    var,func
} type_t;
typedef enum {
    library_function,user_function
} func_t;
typedef struct Variable{
    char* name;
    int scope;
    int line;
} Var;
typedef struct Function{
    char* name;
    int scope;
    int line;
    func_t id;
} Func;
typedef struct Symbol{
    Var *VarVal;
    Func *FuncVal;
    type_t type;
} Sym;
typedef struct Symbol_Table{
    Sym symbol;
    struct SymTable *next;
} SymTable;
int hash(char* name);
Sym* createSymbol(char* name,int scope,int line,type_t type);
Var* createVariable(char* name,int scope,int line);
Func* createFunction(char* name,int scope,int line,func_t id);
void Insert(Sym *nsymbol);
Sym* Serch(char* name);
void InitTable();
void PrintTable();