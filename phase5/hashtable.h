#define HASH_SIZE 1024

enum scopespace_t{
    programvar,
    functionlocal,
    formalarg
};

enum symbol_t {
    var_s,
    programfunc_s,
    libraryfunc_s
};

typedef struct Value {
    char *name;
    int scope;
    int line;
} Value;

typedef struct Variable {
    const char *name;
    int scope;
    int line;
    enum scopespace_t scopespace;
    int offset;
    enum symbol_t type;
} Variable;

typedef struct Function {
    const char *name;
    //List of arguments
    int scope;
    int line;
} Function;

enum SymbolType {
    GLOBAL, LOCALA, FORMAL,
    USERFUNC, LIBFUNC
};

typedef struct Symbol {
    int isActive;
    Variable *varVal;
    Function *funcVal;
    enum SymbolType type;
    struct Symbol *next;
} Symbol;

enum scopespace_t currscopespace();
unsigned currscopeoffset();
void incurrscopeoffset();
void enterscopespace();
void exitscopespace();
void resetformalargoffset();
void resetfunctionlocaloffset();
void restorecurrscopeoffset(unsigned n);
char* newtempname();
void resettemp();
Variable* newtemp();
Variable * newsymbol(char* name);


int gethash(char* name);

Symbol * createSymbol(char *name,int type, int line, int scope);
Variable * createVariable(char *name,int line, int scope);
Function * createFunction(char *name, int line, int scope);
void insert(Symbol * hashtable[HASH_SIZE], Symbol * newsymbol);
void hide(Symbol * hashtable[HASH_SIZE], int maxscope);
Symbol * lookupS(Symbol * hashtable[HASH_SIZE], char *name, int scope);
Symbol * lookup(Symbol * hashtable[HASH_SIZE], char *name);

void initializeTable(Symbol * hashtable[HASH_SIZE]);
void printTable(Symbol * hashtable[HASH_SIZE]);
char * getType(Symbol *symb);
Value getValue(Symbol *symb);