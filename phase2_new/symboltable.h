#define TABLE_SIZE 16
typedef enum {
    var,func
} type_t;
typedef enum {
    library_function,user_function
} func_t;
typedef enum{
    global_variable,local_variable,formal_argument
} var_t;
typedef struct Variable{
    char* name;
    int scope;
    int line;
    var_t id;
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
    Sym *symbol;
    struct Symbol_Table *next;
} SymTable;
Sym* createSymbol(char* name,int scope,int line,type_t type,int id);
Var* createVariable(char* name,int scope,int line,var_t id);
Func* createFunction(char* name,int scope,int line,func_t id);
void Insert(Sym *nsymbol);
Sym* Search(char* name);
void InitTable();
void PrintTable();