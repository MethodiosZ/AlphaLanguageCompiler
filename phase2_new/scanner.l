%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "parser.h"

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
intconst 	    (0[xX][0-9a-fA-F]+)|[0-9]+
realconst       [0-9]*\.([0-9](e|E)?[0-9]*)
ident           [a-zA-Z_][a-zA-Z_0-9]*
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
    insert(yylval, yylineno, ++yytokenid, strdup(string_build), "STRING", -1);
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

<STRING>\\\" {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\"");
}

<STRING>\\\\ {
    string_build = (char*)realloc(string_build, strlen(string_build) + 2);
    strcat(string_build, "\\");
}

<STRING>[^\"\\\n]+ {
    string_build = (char*)realloc(string_build, strlen(string_build) + strlen(yytext) + 1);
    strcat(string_build, yytext);
}

"/*"            { fprintf(stderr,"Recognised block comment beginning with value: %s\n",yytext);
                  commentbegin=yylineno;  
                  BEGIN(BLOCK_COMMENT);  
                  }   /* Start of block comment */

<BLOCK_COMMENT>{
    "/*" {  fprintf(stderr,"Recognised nested comment beginning with value: %s\n",yytext);
            nestedcommentbegin[commentnestlvl]=yylineno;
            commentnestlvl++;
            BEGIN(NESTED_COMMENT);  }
    "*/" {  fprintf(stderr,"Recognised block comment ending with value: %s\n",yytext);
            snprintf(commentlines,10,"%d - %d",commentbegin,yylineno);
            insert(yylval,commentbegin,++yytokenid,commentlines,"COMMENT",1);
            BEGIN(INITIAL);}        /* End of block comment */
            return COMMENT;
    "\n"    { }
    .       { }
}

<NESTED_COMMENT>{
    "/*" {  fprintf(stderr,"Recognised nested comment beginning with value: %s\n",yytext);
            nestedcommentbegin[commentnestlvl]=yylineno;
            commentnestlvl++;  
            BEGIN(NESTED_COMMENT);  }
    "*/" {  if(commentnestlvl == 1) {
                commentnestlvl--;
                fprintf(stderr,"Recognised block comment ending with value: %s\n",yytext);
                snprintf(commentlines,10,"%d - %d",nestedcommentbegin[commentnestlvl],yylineno);
                insert(yylval,nestedcommentbegin[commentnestlvl],++yytokenid,commentlines,"COMMENT",2);
                BEGIN(BLOCK_COMMENT);        /* End of block comment */ 
            }else {
                fprintf(stderr,"Recognised nested comment ending with value: %s\n",yytext);
                commentnestlvl--;
                snprintf(commentlines,10,"%d - %d",nestedcommentbegin[commentnestlvl],yylineno);
                insert(yylval,nestedcommentbegin[commentnestlvl],++yytokenid,commentlines,"COMMENT",2);
                BEGIN(NESTED_COMMENT); /* End of nested comment */
            }
        } 
    "\n"    { }
    .       { }
}

{intconst}      { yylval.intVal = atoi(yytext);
                  return INTEGER;}

{realconst}     { yylval.realVal = atof(yytext);
                  return FLOAT; }

{ident}         { yylval.string = strdup(yytext);
                  return ID;}

{space}         { }    

{comment}       { return COMMENT;  }

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

"{"             {return MMINUS;}
"}"             {return MMINUS;}
";"             {return MMINUS;}
","             {return MMINUS;}

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


<<EOF>>  {  if (YY_START == BLOCK_COMMENT){
                fprintf(stderr, "Error: Block comment not closed at end of file\n");
            } else if(YY_START == NESTED_COMMENT){
                fprintf(stderr, "Error: Nested comment not closed at end of file\n");
            } else {
                    return EOF;
            }
            return 1; 
}

.               { fprintf(stderr,"Cannot match character '%s' with any rule\n",yytext);}

%%