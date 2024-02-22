/* Flex definitions */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int alpha_yylex (void* yylval)

    typedef struct alpha_token{
        int             line;
        int             token_id;
        char*           content;
        char*           type;
        alpha_token_t*  next;
    }alpha_token_t;

    void insert(alpha_token_t *head, int line, int token_id, char* content, char* type);
    void print(alpha_token_t* head);

    typedef enum keywords{IF,ELSE,WHILE,FOR,FUNCTION,RETURN,BREAK,CONTINUE,AND,NOT,OR,LOCAL,TRUE,FALSE,NIL}keywords_t;
    typedef enum operators{ASSIGN,PLUS,MINUS,MULT,DIV,MOD,EQUAL,NOT_EQUAL,PLUS_PLUS,MINUS_MINUS,LESSER,GREATER,GREATER_EQUAL,LESSER_EQUAL}operators_t;
    typedef enum punc{LEFT_BRACE,RIGHT_BRACE,LEFT_SQBRACE,RIGHT_SQBRACE,LEFT_PARENTHESIS,RIGHT_PARENTHESIS,SEMICOLON,COMA,COLON,COLON_COLON,DOT,DOT_DOT}punc_t;
    typedef enum comments{LINE_COMMENT,BLOCK_COMMENT}comments_t;
%}

/* Flex options */

%option header-file="./scanner.h"
%option noyywrap 
%option yylineno

/* Flex macros */
KEYWORD		    "if"|"else"|"while"|"for"|"function"|"return"|"break"|"continue"|"and"|"not"|"or"|"local"|"true"|"false"|"nil"
INTCONST 	    (0[xX][0-9a-fA-F]+)|[0-9]+
REALCONST       [0-9]*\.([0-9](e|E)?[0-9]*)
STRING          \"[^\n"]*\"
OPERATOR	    "="|"+"|"-"|"*"|"/"|"%"|"=="|"!="|"++"|"--"|">"|"<"|">="|"<="
IDENT           [a-zA-Z_][a-zA-Z_0-9]*
PUNCTUATION		"{"|"}"|"["|"]"|"("|")"|";"|","|":"|"::"|"."|".."
SPACE           [\r\n \t\v]
COMMENT		    ("//".*)|("/*".*?"*/")

%x COMMENT

%%

{KEYWORD}       { fprintf(stderr,"Recognised keyword with value: %s\n",yytext); }
{INTCONST}      { fprintf(stderr,"Recognised integer with value: %s\n",yytext); }
{REALCONST}     { fprintf(stderr,"Recognised real number with value: %s\n",yytext); }
{STRING}        { fprintf(stderr,"Recognised string with value: %s\n",yytext); }
{OPERATOR}      { fprintf(stderr,"Recognised operator with value: %s\n",yytext); }
{IDENT}         { fprintf(stderr,"Recognised id with value: %s\n",yytext); }
{PUNCTUATION}   { fprintf(stderr,"Recognised punctuation mark with value: %s\n",yytext); }
{SPACE}         { }
{COMMENT}       { fprintf(stderr,"Recognised comment with value: %s\n",yytext); }
.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%
/* user code */

void insert(alpha_token_t *head, int line, int token_id, char* content, char* type){
    alpha_token_t *new_token,*temp;
    new_token=(alpha_token_t*)malloc(sizeof(alpha_token_t));
    new_token->line=line;
    new_token->token_id=token_id;
    strcpy(new_token->content,content);
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
    head->type=NULL;
    head->next=NULL;
    alpha_yylex(head);
    return 0;
}
