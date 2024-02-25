%{
    #define YY_DECL int alpha_yylex(void* yylval)

    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int yytokenid = 0;

    typedef struct alpha_token{
        int                     line;
        int                     token_id;
        char*                   content;
        char*                   category;
        int                     type;
        struct alpha_token*     next;
    }alpha_token_t;

    typedef enum keywords{IF,ELSE,WHILE,FOR,FUNCTION,RETURN,BREAK,CONTINUE,AND,NOT,OR,LOCAL,TRUE,FALSE,NIL}keywords_t;
    typedef enum operators{ASSIGN,PLUS,MINUS,MULTIPLY,DIV,MOD,EQUAL,NOT_EQUAL,PLUS_PLUS,MINUS_MINUS,LESSER,GREATER,GREATER_EQUAL,LESSER_EQUAL}operators_t;
    typedef enum punc{LEFT_BRACE,RIGHT_BRACE,LEFT_SQBRACE,RIGHT_SQBRACE,LEFT_PARENTHESIS,RIGHT_PARENTHESIS,SEMICOLON,COMA,COLON,COLON_COLON,DOT,DOT_DOT}punc_t;
    typedef enum comments{LINE_COMMENT,BLOCK_COMMENT}comments_t;

    void insert(alpha_token_t *head, int line, int token_id, char* content,char* category, int type);
    void print(alpha_token_t* head);
    int text_to_enum_keys(char* text);
    int text_to_enum_ops(char* text);
    int text_to_enum_puncs(char* text);
    int text_to_enum_comments(char* text);

%}

/* Flex options */
%option header-file="./scanner.h"
%option noyywrap 
%option yylineno

/* Flex macros */
keyword		    "if"|"else"|"while"|"for"|"function"|"return"|"break"|"continue"|"and"|"not"|"or"|"local"|"true"|"false"|"nil"
intconst 	    (0[xX][0-9a-fA-F]+)|[0-9]+
realconst       [0-9]*\.([0-9](e|E)?[0-9]*)
string          \"[^\n"]*\"
operator	    "="|"+"|"-"|"*"|"/"|"%"|"=="|"!="|"++"|"--"|">"|"<"|">="|"<="
ident           [a-zA-Z_][a-zA-Z_0-9]*
punctuation		"{"|"}"|"["|"]"|"("|")"|";"|","|":"|"::"|"."|".."
space           [\r\n \t\v]
comment		    ("//".*)

%%

{keyword}       { fprintf(stderr,"Recognised keyword with value: %s\n",yytext);
                  int key = text_to_enum_keys(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"KEYWORD",key);  }
{intconst}      { fprintf(stderr,"Recognised integer with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"INTCONST",NULL);   }
{realconst}     { fprintf(stderr,"Recognised real number with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"REALCONST",NULL);   }
{string}        { fprintf(stderr,"Recognised string with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"STRING",NULL);   }
{operator}      { fprintf(stderr,"Recognised operator with value: %s\n",yytext);
                  int op = text_to_enum_ops(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"OPERATOR",op);   }
{ident}         { fprintf(stderr,"Recognised id with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"IDENT",NULL);   }
{punctuation}   { fprintf(stderr,"Recognised punctuation mark with value: %s\n",yytext);
                  int mark = text_to_enum_puncs(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"PUNCTUATION",mark);   }
<<EOF>>         { fprintf(stderr,"\nAlanyzing Completed\n"); return 1;}  
{space}         { }
{comment}       { fprintf(stderr,"Recognised comment with value: %s\n",yytext);
                  int comm = text_to_enum_comments(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"COMMENT",comm);   }
.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%
/* user code */

int text_to_enum_keys(char* text){
    if(!strcmp(text,"if")) return IF;
    else if(!strcmp(text, "else")) return ELSE;
	else if(!strcmp(text, "while")) return WHILE;
	else if(!strcmp(text, "for")) return FOR;
	else if(!strcmp(text, "function")) return FUNCTION;
	else if(!strcmp(text, "return")) return RETURN;
	else if(!strcmp(text, "break")) return BREAK;
	else if(!strcmp(text, "continue")) return CONTINUE;
	else if(!strcmp(text, "and")) return AND;
	else if(!strcmp(text, "not")) return NOT;
	else if(!strcmp(text, "or")) return OR;	
	else if(!strcmp(text, "local")) return LOCAL;
	else if(!strcmp(text, "true")) return TRUE;
	else if(!strcmp(text, "false")) return FALSE;
	else if(!strcmp(text, "nil")) return NIL;
}

int text_to_enum_ops(char* text){
    if(!strcmp(text,"=")) return ASSIGN;
    else if(!strcmp(text, "+")) return PLUS;
	else if(!strcmp(text, "-")) return MINUS;
	else if(!strcmp(text, "*")) return MULTIPLY;
	else if(!strcmp(text, "/")) return DIV;
	else if(!strcmp(text, "%")) return MOD;
	else if(!strcmp(text, "==")) return EQUAL;
	else if(!strcmp(text, "!=")) return NOT_EQUAL;
	else if(!strcmp(text, "++")) return PLUS_PLUS;
	else if(!strcmp(text, "--")) return MINUS_MINUS;
	else if(!strcmp(text, ">")) return GREATER;	
	else if(!strcmp(text, "<")) return LESSER;
	else if(!strcmp(text, ">=")) return GREATER_EQUAL;
	else if(!strcmp(text, "<=")) return LESSER_EQUAL;
}

int text_to_enum_puncs(char* text){
    if(!strcmp(text,"{")) return LEFT_BRACE;
    else if(!strcmp(text, "}")) return RIGHT_BRACE;
	else if(!strcmp(text, "[")) return LEFT_SQBRACE;
	else if(!strcmp(text, "]")) return RIGHT_SQBRACE;
	else if(!strcmp(text, "(")) return LEFT_PARENTHESIS;
	else if(!strcmp(text, ")")) return RIGHT_PARENTHESIS;
	else if(!strcmp(text, ";")) return SEMICOLON;
	else if(!strcmp(text, ",")) return COMA;
	else if(!strcmp(text, ":")) return COLON;
	else if(!strcmp(text, "::")) return COLON_COLON;
	else if(!strcmp(text, ".")) return DOT;	
	else if(!strcmp(text, "..")) return DOT_DOT;
}

int text_to_enum_comments(char* text){
    if(!strcmp(text,"//")) return LINE_COMMENT;
    else if(!strcmp(text, "/*")) return BLOCK_COMMENT;
	else if(!strcmp(text, "*/")) return BLOCK_COMMENT;
}

void insert(alpha_token_t *head, int line, int token_id, char* content,char* category, int type){
    alpha_token_t *new_token,*temp;
    new_token=(alpha_token_t*)malloc(sizeof(alpha_token_t));
    new_token->line=line;
    new_token->token_id=token_id;
    new_token->content=strdup(content);
    new_token->category=strdup(category);
    new_token->type=type;
    new_token->next=NULL;
    temp=head;
    while(temp->next!=NULL){
        temp=temp->next;
    }
    temp->next=new_token;
    return;
}

void print(alpha_token_t* head){
    alpha_token_t* temp;
    temp=head->next;
    while(temp){
        printf("%d: #%d %s %s %d\n",temp->line,temp->token_id,temp->content,temp->category,temp->type);
        temp=temp->next;
    }
    return;
}

int main(int argc, char* argv[]) {
    system("clear");
    alpha_token_t* head = NULL;
    head = (alpha_token_t*)malloc(sizeof(alpha_token_t));
    head->next=NULL;
    if(argc > 1) {
        if(!(yyin = fopen(argv[1],"r"))) {
            fprintf(stderr, "Cannot read file:  %s\n", argv[1]);
            return -1;
        }
    }else {
        yyin = stdin;
    }
    alpha_yylex(head);
    print(head);
    return 0;
}
