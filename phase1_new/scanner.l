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

    void insert();
    void print();
%}

/* Flex options */

%option header-file="./scanner.h"
%option noyywrap 
%option yylineno

/* Flex macros */
keyword		"if"|"else"|"while"|"for"|"function"|"return"|"break"|"continue"|"and"|"not"|"or"|"local"|"true"|"false"|"nil"
integer 	(0[xX][0-9a-fA-F]+)|[0-9]+
real    	[0-9]*\.([0-9](e|E)?[0-9]*)
string      \"[^\n"]*\"
operator	"="|"+"|"-"|"*"|"/"|"%"|"=="|"!="|"++"|"--"|">"|"<"|">="|"<="
id			[a-zA-Z_][a-zA-Z_0-9]*
mark		"{"|"}"|"["|"]"|"("|")"|";"|","|":"|"::"|"."|".."
space       [\r\n \t\v]
comment		("//".*)|("/*".*?"*/")

%x COMMENT

%%

{keyword}       { fprintf(stderr,"Recognised keyword with value: %s\n",yytext); }
{integer}       { fprintf(stderr,"Recognised integer with value: %s\n",yytext); }
{real}          { fprintf(stderr,"Recognised real number with value: %s\n",yytext); }
{string}        { fprintf(stderr,"Recognised string with value: %s\n",yytext); }
{operator}      { fprintf(stderr,"Recognised operator with value: %s\n",yytext); }
{id}            { fprintf(stderr,"Recognised id with value: %s\n",yytext); }
{mark}          { fprintf(stderr,"Recognised punctuation mark with value: %s\n",yytext); }
{space}         { }
{comment}       { fprintf(stderr,"Recognised comment with value: %s\n",yytext); }
.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%
/* user code */

void insert(){

}

void print(){
    
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
    yylex(head);
    return 0;
}
