%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "parser.tab.h"

    extern YYSTYPE yylval;

    int yytokenid           = 0;
    int commentbegin        = 0;
    int commentnestlvl      = 0;
    int nestedcommentbegin[10] = {0,0,0,0,0,0,0,0,0,0};
    char commentlines[10];
    char* string_build;
%}

/* Flex options */
%option noyywrap 
%option yylineno

/* Flex macros */
ident           [a-zA-Z_][a-zA-Z_0-9]*
intconst 	    [0-9]+
realconst       [0-9]*\.([0-9](e|E)?[0-9]*)
space           [\r\n \t\v]
comment		    ("//".*)

%x BLOCK_COMMENT
%x NESTED_COMMENT
%x STRING
%%

\"  {
    string_build = (char*)malloc(1);
    string_build[0] = '\0';
    BEGIN(STRING);
}

<STRING>\\\" {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\\\"");
}

<STRING>\" {
    free(string_build);
    BEGIN(INITIAL);
    return STRING;
}

<STRING>\\n {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\n");
}

<STRING>\\t {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\t");
}

<STRING>\\\\ {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\\");
}

<STRING>[^\"\\\n]+ {
    string_build = (char*)realloc(string_build, strlen(string_build) + strlen(yytext) + 1);
    strcat(string_build, yytext);
}

"/*"            { commentbegin=yylineno;  
                  BEGIN(BLOCK_COMMENT);  
                  }   /* Start of block comment */

<BLOCK_COMMENT>{
    "/*" {  nestedcommentbegin[commentnestlvl]=yylineno;
            commentnestlvl++;
            BEGIN(NESTED_COMMENT);  }
    "*/" {  BEGIN(INITIAL);}        /* End of block comment */
    "\n"    { }
    .       { }
}

<NESTED_COMMENT>{
    "/*" {  nestedcommentbegin[commentnestlvl]=yylineno;
            commentnestlvl++;  
            BEGIN(NESTED_COMMENT);  }
    "*/" {  if(commentnestlvl == 1) {
                commentnestlvl--;
                BEGIN(BLOCK_COMMENT);        /* End of block comment */ 
            }else {
                commentnestlvl--;
                BEGIN(NESTED_COMMENT); /* End of nested comment */
            }
        } 
    "\n"    { }
    .       { }
}

"true"          {return TRUE;}
"false"         {return FALSE;}
"nil"           {return NIL;}
"if"            {return IF;}
"else"          {return ELSE;}
"while"         {return WHILE;}
"for"           {return FOR;}
"break"         {return BREAK;}
"continue"      {return CONT;}
"function"      {return FUNC;}
"return"        {return RET;}
"local"         {return LOCAL;}

"{"             {return LBRACE;}
"}"             {return RBRACE;}
";"             {return SEMI;}
","             {return COMMA;}

"("             {return LPAR;}
")"             {return RPAR;}
"["             {return LSQBRACE;}
"]"             {return RSQBRACE;}
".."            {return DDOT;}
"."             {return DOT;}
"::"            {return CCOLON;}
":"             {return COLON;}

"+"             {return ADD;}
"-"             {return SUB;}
"*"             {return MUL;}
"/"             {return DIV;}
"%"             {return MOD;}
"++"            {return PPLUS;}
"--"            {return MMINUS;}

">="            {return MOREEQ;}
"<="            {return LESSEQ;}
">"             {return MORE;}
"<"             {return LESS;}
"=="            {return EQ;}
"!="            {return NEQ;}
"not"           {return NOT;}
"and"           {return AND;}
"or"            {return OR;}
"="             {return ASSIGN;}

{ident}         { yylval.string = strdup(yytext);
                  return ID;}

{intconst}      { yylval.intVal = atoi(yytext);
                  return INTEGER;}

{realconst}     { yylval.realVal = atof(yytext);
                  return FLOAT; }

{space}         { }    

{comment}       { }

<<EOF>>  {  if (YY_START == BLOCK_COMMENT){
                fprintf(stderr, "Error: Block comment not closed at end of file\n");
            } else if(YY_START == NESTED_COMMENT){
                fprintf(stderr, "Error: Nested comment not closed at end of file\n");
            }
            else{
                return EOF;
            }
}

.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%