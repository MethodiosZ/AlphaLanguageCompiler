/* Definitions section */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int alpha_yylex (void* yylval)
%}

%option header-file="./al.h"
%option noyywrap /* for reading from one input like a file */
%option yylineno
%option case-insensitive /*auto giati to evales?*/

id          [a-zA-Z][a-zA-Z_0-9]*
integer     (0[xX][0-9A-Fa-f]+)|([0-9]+)
real        [0-9]*\.[0-9](e|E)?[0-9]*
string      \"[^\n"]*\"
comment     "//".*|"/*".*"*/"
keyword     if | else | while | for | function | return | break | continue | and | not | or | local | true | false | nil
operator    = | + | - | * | / | % | == | != | ++ | -- | < | > | >= | <=
mark        { | } | [ | ] | ( | ) | ; | , | : | :: | . | ..

%x COMMENT

%%


IF
ELSE
WHILE
FOR
IDENTIFIER


/* Rules section */


%%

void print(){

}

int main(int argc, char* argv[]) {
    system("clear");
    if(argc > 1) {
        if(!(yyin = fopen(argv[1],"r"))) {
            return -1;
        }
    }else {
        yyin = stdin;
    }
    return 0;
}
