%{	
#include "pascal.tab.h"		
#include <stdlib.h>
#include <string.h>
#include <math.h>

extern char nom[];
%}

%option yylineno
underscore			  "_"
whitespace            [ \t]
blank                 {whitespace}*
digit                 [0-9]
number                ("-")?{digit}+("."{digit}+)?(("E"|"e")"-"?{digit}+)?
literal_int           {digit}+
letter                [a-zA-Z]
ident                 {letter}({letter}|{digit}|{underscore})*
illegal_ident         {digit}{letter}({letter}|{digit})*
line_comment          "//".*
block_comment         "/*"([^*]|"*"[^/]|"\n")*"*/"
illegal_comment_start "/*"
illegal_comment_end   "*/"


%%                                                              ;
"\n"                                                                 ;

"program"                                                            return PROGRAM;
"begin"                                                              return _BEGIN;
"end"                                                                return _END;

"["                                                                  return BRACKET_OPEN;
"]"                                                                  return BRACKET_CLOSE;
"("                                                                  return PAREN_OPEN;
")"                                                                  return PAREN_CLOSE;
":="	                                                             return OP_AFFECT;
"="																	 return EQUALS;
"+"                                                                  return PLUS;
"-"                                                                  return MINUS;
"*"                                                                  return MULTIP;
"/"                                                                  return DIVIDE;
";"                                                                  return SEMI_COL;
":"                                                                  return COL;
","                                                                  return COMMA;
".."                                                                 return DOUBLE_DOT;
"'"																	 return SINGLE_QUOTE;
"\""																 return DOUBLE_QUOTE;

"program"                                                            return PROGRAM;
"begin"                                                              return _BEGIN;
"end"                                                                return _END;
"procedure"                                                          return PROC;
"function"                                                           return FUNC;
"write"                                                              return WRITE;
"read"                                                               return READ;
"array"                                                              return ARRAY;
"of"                                                                 return OF;
"var"                                                                return VAR;
"if"                                                                 return IF;
"else"                                                               return ELSE;
"then"                                                               return THEN;
"while"                                                              return WHILE;
"do"                                                                 return DO;
"real"                                                               return REAL;
"integer"                                                            return INTEGER;
"char"                                                               return CHAR;
{illegal_ident}                                                      printf("illegal identifier '%s', in line %d..\n", yytext, yylineno);
({ident}|{illegal_ident})                                            {
																		strcpy(nom, yytext); 
																		return IDENT;
																	 }
{literal_int}                                                        return INT_LITERAL;

{block_comment}                                                      ;
{line_comment}                                                       ;
{blank}
{illegal_comment_start}                                              printf("unclosed comment, in line %d..\n", yylineno);
{illegal_comment_end}                                                printf("comment block end found but no block start, in line %d..\n", yylineno);

.                                                                    printf("unexpected or unrecognised symbol '%s', in line %d..\n", yytext, yylineno);
%%