/* Flex definitions */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define YY_DECL int alpha_yylex (void* yylval);

    int yytokenid = 0;

    typedef struct alpha_token{
        int                     line;
        int                     token_id;
        char*                   content;
        char*                   category;
        char*                   type:
        struct alpha_token*     next;
    }alpha_token_t;

    typedef enum keywords{IF,ELSE,WHILE,FOR,FUNCTION,RETURN,BREAK,CONTINUE,AND,NOT,OR,LOCAL,TRUE,FALSE,NIL}keywords_t;
    typedef enum operators{ASSIGN,PLUS,MINUS,MULTIPLY,DIV,MOD,EQUAL,NOT_EQUAL,PLUS_PLUS,MINUS_MINUS,LESSER,GREATER,GREATER_EQUAL,LESSER_EQUAL}operators_t;
    typedef enum punc{LEFT_BRACE,RIGHT_BRACE,LEFT_SQBRACE,RIGHT_SQBRACE,LEFT_PARENTHESIS,RIGHT_PARENTHESIS,SEMICOLON,COMA,COLON,COLON_COLON,DOT,DOT_DOT}punc_t;
    typedef enum comments{LINE_COMMENT,BLOCK_COMMENT}comments_t;

    void insert(alpha_token_t *head, int line, int token_id, char* content,char* category, char* type);
    void print(alpha_token_t* head);
    keywords_t text_to_enum_keys(char* text);
    operators_t text_to_enum_ops(char* text);
    punc_t text_to_enum_puncs(char* text);
    comments_t text_to_enum_comments(char* text);

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
comment		    ("//".*)|("/*".*?"*/")

%x COMMENT

%%

{keyword}       { fprintf(stderr,"Recognised keyword with value: %s\n",yytext);
                  keywords_t key = text_to_enum_keys(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"KEYWORD",key);  }
{intconst}      { fprintf(stderr,"Recognised integer with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"INTCONST",yytext);   }
{realconst}     { fprintf(stderr,"Recognised real number with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"REALCONST",yytext);   }
{string}        { fprintf(stderr,"Recognised string with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"STRING",yytext);   }
{operator}      { fprintf(stderr,"Recognised operator with value: %s\n",yytext);
                  operators_t op = text_to_enum_ops(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"OPERATOR",op);   }
{ident}         { fprintf(stderr,"Recognised id with value: %s\n",yytext); 
                  insert(yylval,yylineno,++yytokenid,yytext,"IDENT",yytext);   }
{punctuation}   { fprintf(stderr,"Recognised punctuation mark with value: %s\n",yytext);
                  punc_t mark = text_to_enum_puncs(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"PUNCTUATION",mark);   }
{space}         { }
{comment}       { fprintf(stderr,"Recognised comment with value: %s\n",yytext);
                  comments_t comm = text_to_enum_comments(yytext);  
                  insert(yylval,yylineno,++yytokenid,yytext,"COMMENT",comm);   }
.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%
/* user code */

keywords_t text_to_enum_keys(char* text){
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

operators_t text_to_enum_ops(char* text){
    if(!strcmp(text,"=")) return ASSIGN;
    else if(!strcmp(text, "=")) return PLUS;
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

punc_t text_to_enum_puncs(char* text){
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

comments_t text_to_enum_comments(char* text){
    if(!strcmp(text,"//")) return LINE_COMMENT;
    else if(!strcmp(text, "/*")) return BLOCK_COMMENT;
	else if(!strcmp(text, "*/")) return BLOCK_COMMENT;
}

void insert(alpha_token_t *head, int line, int token_id, char* content,char* category, char* type){
    alpha_token_t *new_token,*temp;
    new_token=(alpha_token_t*)malloc(sizeof(alpha_token_t));
    new_token->line=line;
    new_token->token_id=token_id;
    strcpy(new_token->content,content);
    strcpy(new_token->category,category);
    strcpy(new_token->type,type);
    new_token->next=NULL;
    temp=head;
    while(temp->next!=NULL){
        temp=temp->next;
    }
    temp->next=new_token;
    return;
}

void print(alpha_token_t* head){
    while(head){
        printf("%d: #%d %s %s %s",head->line,head->token_id,head->content,head->category,head->type);
        head=head->next;
    }
    return;
}

int main(int argc, char* argv[]) {
    system("clear");
    if(argc > 1) {
        if(!(yyin = fopen(argv[1],"r"))) {
            fprintf(stderr, "Cannot read file:  %s\n", argv[1]);
            return -1;
        }
    }else {
        yyin = stdin;
    }
    alpha_token_t* head = NULL;
    head = (alpha_token_t*)malloc(sizeof(alpha_token_t));
    head->line=0;
    head->token_id=0;
    head->content=NULL;
    head->category=NULL;
    head->type=NULL;
    head->next=NULL;
    alpha_yylex(head);
    print(head);
    return 0;
}
