/* Definitions section */
%{
    #include <stdio.h>:
    #include <stdlib.h>
    #include <string.h>


%}

%option header-file="./scanner.h"
%option noyywrap /* for reading from one input like a file */
%option yylineno
%option case-insensitive

//WORK IN PROGRESS HERE
IF
ELSE
WHILE
FOR
IDENTIFIER


/* Rules section */




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
