%{
	#include <string.h>
	#include <stdlib.h>
	#include <string.h>
	#include "parser.tab.h"
	#include "quad.h"

	int yytokenno = 0;
	int yycount = 0;
	int string_size; 
	int string_curr;
	char* string_from_token;
	char* string_to_node;
	char* new_memory;

	extern YYSTYPE yylval;

	//typedef enum 	type{ID, INTCONST, REALCONST, PUNCT, OPERATOR, WHITESPACE, KEYWORD, NOMATCH, COMMENTS, STR}types;
	//typedef enum	key{IF, ELSE, WHILE, FOR, FUNCTION, RETURN, BREAK, CONTINUE, AND, NOT, OR, LOCAL, TRUE, FALSE, NIL, NTHNG}keywords;

	typedef struct node alpha_token_t;

	struct node{
		int line_number;
		int token_number;
		char* token;
		//types type;
		char* ch_value;
		float num_value;
		//keywords key;
		alpha_token_t* next;
	};

	/*void insert_node(alpha_token_t *head, int line_number, int token_number, char* token, types type, char* ch_value, float num_value, keywords key);
	keywords keywords_to_enum(char* text);
	void print_results(alpha_token_t *head);*/
    	void allocate_str_memory();
	
%}

%option noyywrap
%option yylineno
%option header-file="./al.h"


id				[a-zA-Z_][a-zA-Z_0-9]*

intconst		[0-9]+

realconst		([0-9]+)\.([0-9](e|E)?[0-9]*)

whitespace		[\r\n\t\v ]

commentline		"//".*

wrong_id		[0-9$_][a-zA-Z_0-9]*

%x COMMENT
%x STRING

%% 

\"		{
			string_from_token="";
			string_size=1; 
			string_curr=0; 
			string_from_token=malloc(sizeof(char)*string_size);
			string_to_node=string_from_token; 
			BEGIN(STRING);
		}
<STRING>\"	{
			allocate_str_memory();
			*string_from_token='\0';
			//insert_node(yval, yylineno, ++yytokenno, string_to_node, STR, string_to_node, -1, NTHNG);
			yylval.stringValue = strdup(string_from_token);
			BEGIN(INITIAL);
			return STRING;
		}
<STRING>\\n	{
			allocate_str_memory();
			*string_from_token='\n';
			string_from_token++;
			string_curr++;
		}
<STRING>[\n]	{
			allocate_str_memory();
			*string_from_token='\n'; 
			string_from_token++; 
			string_curr++;
		}			
<STRING>\\t	{
			allocate_str_memory();
			*string_from_token='\t'; 
			string_from_token++; 
			string_curr++;
		}
<STRING>[\t]	{
			allocate_str_memory();
			*string_from_token='\t'; 
			string_from_token++; 
			string_curr++;
		}		
<STRING>\\r	{
			allocate_str_memory();
			*string_from_token='\r'; 
			string_from_token++; 
			string_curr++;
		}
<STRING>[\r]	{
			allocate_str_memory();
			*string_from_token='\r'; 
			string_from_token++; 
			string_curr++;
		}		
<STRING>\\v	{
			allocate_str_memory();
			*string_from_token='\v'; 
			string_from_token++; 
			string_curr++;
		}
<STRING>[\v]	{
			allocate_str_memory();
			*string_from_token='\v'; 
			string_from_token++; 
			string_curr++;
		}		
<STRING>\\b	{
			allocate_str_memory();
			*string_from_token='\b'; 
			string_from_token++; 
			string_curr++;
		}
<STRING>[\b]	{
			allocate_str_memory();
			*string_from_token='\b'; 
			string_from_token++; 
			string_curr++;
		}									
<STRING>\\\" 	{
			allocate_str_memory();
			*string_from_token='\"';
			string_from_token++; 
			string_curr++;
		}
<STRING>\\\\ 	{
			allocate_str_memory();
			*string_from_token='\\';
			string_from_token++; 
			string_curr++;
		}
<STRING>[^\\\n\"\\\t]+	{
				char* tmp=yytext;
				while(*tmp){
					allocate_str_memory();
					*string_from_token=*tmp;
					string_from_token++;
					tmp++;
					string_curr++;
				}
			}
<STRING><<EOF>> {
			printf("Lexical: STRING ERROR <<Open String Left>>. \n");
			return EOF;
		}


"/*"	yycount++; BEGIN(COMMENT);
<COMMENT>[^*^/]*
<COMMENT>"/"+[^*]*
<COMMENT>"/"+"*"	yycount++;
<COMMENT>"*"+[^*/]*
<COMMENT>"*"+"/" {
			yycount--;
			if(yycount==0) {	
				BEGIN(INITIAL);
			}
		}
<COMMENT><<EOF>> 	{ printf("COMMENT ERROR IN LEXICAL ANALYSIS <<Open Comment >>. \n"); 
			return EOF; }




"if" 		{return IF;}
"else" 		{return ELSE;}
"while" 	{return WHILE;}
"for" 		{return FOR;}
"break" 	{return BREAK;}
"continue" 	{return CONTINUE;}
"function" 	{return FUNCTION;}
"return" 	{return RETURN;}
"local" 	{return LOCAL;}

"&&"		{return AND;}
"||"		{return OR;}
"!"			{return NOT;}
"true" 		{return TRUE;}
"false" 	{return FALSE;}
"nil" 		{return NIL;}
"and"    	{return AND;}
"or" 		{return OR;}
"not"    	{return NOT;}

"+"		{return PLUS;}
"-"		{return MINUS;}
"*"		{return MUL;}
"/"		{return DIV;}
"%"		{return MOD;}
"++"	{return PPLUS;}
"--"	{return MMINUS;}
"="		{return ASSIGN;}
"=="	{return EQ;}
"!="	{return NEQ;}
">"		{return GT;}
">="	{return GTEQ;}
"<"		{return LT;}
"<="	{return LTEQ;}

"{"		{return L_BRACE;}
"}"		{return R_BRACE;}
"("		{return L_PAR;}
")"		{return R_PAR;}
"["		{return L_SBRACKET;}
"]"		{return R_SBRACKET;}
";"		{return SEMI;}
":"		{return COLON;}
"::"	{return CCOLON;}
","		{return COMMA;}
"."		{return DOT;}
".."	{return DDOT;}

{commentline}		{}

{whitespace}		{}
	/*
{keyword}		{ keywords keywrd = keywords_to_enum(yytext); insert_node(yval, yylineno, ++yytokenno, yytext, KEYWORD, yytext, -5, keywrd); }
*/			  
{id}			{yylval.stringValue = strdup(yytext); return ID;}

{intconst}		{yylval.intValue = atoi(yytext); return INTEGER;}

{realconst}		{yylval.numValue = atof(yytext); return NUMBER;}
	/*
{punct}			{ insert_node(yval, yylineno, ++yytokenno, yytext, PUNCT, yytext, -7, NTHNG); }

{operator}		{ insert_node(yval, yylineno, ++yytokenno, yytext, OPERATOR, yytext, -8, NTHNG); }
*/
<<EOF>>			{return EOF;}

{wrong_id}		{printf("Line %d:  Lexical Error. Identifiers can't start with a number.\n",yylineno); return WRONG_ID; }



%%

void allocate_str_memory() {
	if (string_size==string_curr) {
		string_size = string_size*4; 
		new_memory = (char *)malloc(sizeof(char)*string_size);
		strcpy(new_memory, string_to_node);
		string_to_node = new_memory;
		new_memory =&(new_memory[strlen(new_memory)]);
		string_from_token = new_memory;
	}

}

	/*
void insert_node(alpha_token_t *head, int line_number, int token_number, char* token, types type, char* ch_value, float num_value, keywords key) {

	alpha_token_t *new_node, *tmp, *here;

	new_node=(alpha_token_t *)malloc(sizeof(alpha_token_t));
	new_node->line_number = line_number;
	new_node->token_number = token_number;
	new_node->token = strdup(token);
	new_node->type = type;
	new_node->key = key;
	new_node->next = NULL;
	if (ch_value != (char *)NULL){
		new_node->ch_value = strdup(ch_value);
	}
	else if (num_value >= 0){
		new_node->num_value = num_value;
	}
	tmp = head;
	while(tmp) {
		here = tmp;
		tmp = tmp->next;
	}
	here->next = new_node;
	
	return;
}

keywords keywords_to_enum(char* text) {

	if(!strcmp(text, "if")) return IF;
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


void print_results(alpha_token_t *head) {
	alpha_token_t* tmp;
	char* token;
	tmp = head->next;
	int integer;
	
	while(tmp) {
		integer = tmp->num_value;
		switch(tmp->type) {
			case OPERATOR: printf("%d:  #%d\t'%s'\tOPERATOR\t%s\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case INTCONST: printf("%d:  #%d\t'%s'\tINTCONST\t%d\n",tmp->line_number, tmp->token_number, tmp->token, integer); break;
			case REALCONST: printf("%d:  #%d\t'%s'\tREALCONST\t%f\n",tmp->line_number, tmp->token_number, tmp->token, tmp->num_value); break;
			case PUNCT: printf("%d:  #%d\t'%s'\tPUNCTUATION\t%s\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case ID: printf("%d:  #%d\t'%s'\tIDENTIFIER\t'%s'\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case KEYWORD:
				switch (tmp->key) {
					case IF: token = strdup("IF"); break;
					case ELSE: token = strdup("ELSE"); break;
					case WHILE: token = strdup("WHILE"); break;
					case FOR: token = strdup("FOR"); break;
					case FUNCTION: token = strdup("FUNCTION"); break;
					case RETURN: token = strdup("RETURN"); break;
					case BREAK: token = strdup("BREAK"); break;
					case CONTINUE: token = strdup("CONTINUE"); break;
					case AND: token = strdup("AND"); break;
					case NOT: token = strdup("NOT"); break;
					case OR: token = strdup("OR"); break;
					case LOCAL: token = strdup("LOCAL"); break;
					case TRUE: token = strdup("TRUE"); break;
					case FALSE: token = strdup("FALSE"); break;
					case NIL: token = strdup("NIL"); break;
					case NTHNG: token = strdup("NTHING"); break;
					default: printf("Print results defaulted on case KEYWORD.\n");
				}
				printf("%d:  #%d\t'%s'\tKEYWORD\t\t%s\n",tmp->line_number, tmp->token_number, tmp->token, token); break;
			case WHITESPACE: printf("%d:  #%d\t'%s'\tWHITESPACE\t'%s'\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case COMMENTS: printf("%d:  #%d\t'%s'\tCOMMENT\t'%s'\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case STR: printf("%d:  #%d\t'%s'\tSTRING\t'%s'\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			case NOMATCH: printf("%d:  #%d\t'%s'\tNOMATCH\t'%s'\n",tmp->line_number, tmp->token_number, tmp->token, tmp->ch_value); break;
			default: printf("Print results defaulted on type switch.\n");
		}
		tmp = tmp->next;
	}
}
*/