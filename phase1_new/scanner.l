/* Flex definitions */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int alpha_yylex (void* yylval)

    typedef struct alpha_token{
        int line;
        int token_id;
        char* content;
        char* type;
    }alpha_token_t;
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
{comment}       { fprintf(stderr,"Recognised comment with value: %s\n",yytext); }
.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%

/* user code */
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
    yylex();
    return 0;
}
