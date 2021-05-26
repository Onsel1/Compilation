%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbols.c"

int yyerror(char const *msg);
int yylex(void);
extern int yylineno;
extern int yyleng;
extern int yydebug;

char nom[256];
char methodName[256];
int yydebug = 0;

%}

%token PROGRAM
%token _BEGIN
%token _END
%token PROC
%token FUNC
%token WRITE
%token READ
%token ARRAY
%token OF
%token VAR
%token IF
%token ELSE
%token THEN
%token WHILE
%token DO
%token REAL
%token INTEGER
%token CHAR
%token IDENT
%token NUMBER
%token INT_LITERAL

%token BRACKET_OPEN
%token BRACKET_CLOSE
%token PAREN_OPEN
%token PAREN_CLOSE
%token OP_AFFECT
%token EQUALS
%token PLUS
%token MINUS
%token MULTIP
%token DIVIDE
%token SEMI_COL
%token COL
%token COMMA
%token DOUBLE_DOT
%token DOUBLE_QUOTE
%token SINGLE_QUOTE

%start PROGRAM_BODY

%%



PROGRAM_HEAD:
        PROGRAM IDENT SEMI_COL 
        | error IDENT SEMI_COL                    { yyerror("'program' expected"); }
        | PROGRAM error SEMI_COL                  { yyerror("identifier expected"); }
        | PROGRAM IDENT error                     { yyerror("; expected"); }
        ;
		
PROGRAM_BODY: 
        PROGRAM_HEAD DECL_VAR DECL_FUNCS COMPOSITE_INSTRUCTION 
        | PROGRAM_HEAD DECL_FUNCS COMPOSITE_INSTRUCTION 
        | PROGRAM_HEAD DECL_VAR COMPOSITE_INSTRUCTION 
        | PROGRAM_HEAD COMPOSITE_INSTRUCTION 
        ;

DECL_VAR:
        DECL_VAR DECLARATION
        | DECLARATION
        ;

DECL_FUNCS:
        FUNCTION_DECLARATION SEMI_COL DECL_FUNCS 
        | FUNCTION_DECLARATION SEMI_COL
        | FUNCTION_DECLARATION error  {yyerror("; expected")}
        ;

FUNCTION_DECLARATION:
        FUNCTION_HEAD DECL_VAR COMPOSITE_INSTRUCTION 
        | FUNCTION_HEAD COMPOSITE_INSTRUCTION
        ;

FUNCTION_HEAD:
        FUNC_TYPE IDENT {yycreatemethodnoeud()} FUNCTION_SIGNATURE {NOEUD_PROC_VERIF->nbParam = NB_PARAM; NB_PARAM = 0;} SEMI_COL 
        | FUNC_TYPE IDENT {yycreatemethodnoeud()} SEMI_COL {NOEUD_PROC_VERIF->nbParam = 0; IN_PROC_PARAMETERS = 0;}
        | error IDENT                    { yyerror("'procedure' or 'function' expected"); }
        | FUNC_TYPE error 	        	 { IS_PROC = 0; yyerror("identifier expected"); }
        | FUNC_TYPE IDENT error        	 { IS_PROC = 0; yyerror("arguments expected"); }
        ;
		
FUNC_TYPE:
	PROC {IS_PROC =1}
	| FUNC {IS_PROC =1}

FUNCTION_SIGNATURE:
		PAREN_OPEN PARAMS { IN_PROC_PARAMETERS = 0; } PAREN_CLOSE
        | error PARAMS { IN_PROC_PARAMETERS = 0; } PAREN_CLOSE        							{ yyerror("( expected"); NB_PARAM =0;}
        | PAREN_OPEN PARAMS { IN_PROC_PARAMETERS = 0; } error         { yyerror(") expected"); }
        ;

PARAMS:
        PARAMS SEMI_COL DECLARATION_BODY 
        | DECLARATION_BODY 
        ;

COMPOSITE_INSTRUCTION:
        _BEGIN INSTRUCTION_CHAIN _END {finalizeNoeud(yylineno);}
        | _BEGIN _END 
        | error _END         { yyerror("'begin' expected"); }
        | _BEGIN INSTRUCTION_CHAIN error      {yyerror("'end' expected");finalizeNoeud(yylineno);}
        ;

INSTRUCTION_CHAIN:
        INSTRUCTION_CHAIN INSTRUCTION SEMI_COL 
        | INSTRUCTION SEMI_COL 
        | INSTRUCTION error { yyerror("; expected"); }
        | INSTRUCTION_CHAIN INSTRUCTION error { yyerror("; expected"); }
        ;


INSTRUCTION:
        VALUE OP_AFFECT {if(valueIsVar&&checkIdentifierDeclared(nom,yylineno)) {setVarInitialised (nom);valueIsVar=0;}}EXPRESSION
        | FUNCTION_CALL
        | COMPOSITE_INSTRUCTION
        | IF EXPRESSION THEN INSTRUCTION ELSE INSTRUCTION
        | IF PAREN_OPEN EXPRESSION PAREN_CLOSE {NB_PARAM = 0;} THEN INSTRUCTION ELSE INSTRUCTION
        | WHILE EXPRESSION DO INSTRUCTION
        | WRITE PAREN_OPEN PAREN_CLOSE {NB_PARAM = 0;}
        | WRITE PAREN_OPEN EXPRESSION_CHAIN PAREN_CLOSE {NB_PARAM = 0;}
        | READ PAREN_OPEN IDENT_LIST PAREN_CLOSE {NB_PARAM = 0;}
        | VALUE error EXPRESSION                               { yyerror(":= expected"); }
        | error OP_AFFECT EXPRESSION                               { yyerror("variable for affectation expected"); }
        | IF error THEN INSTRUCTION ELSE INSTRUCTION            { yyerror("expression expected"); }
        | IF PAREN_OPEN error PAREN_CLOSE THEN INSTRUCTION ELSE INSTRUCTION            { yyerror("expression expected"); }
        | error EXPRESSION THEN INSTRUCTION ELSE INSTRUCTION    { yyerror("'if' expected"); }
        | IF EXPRESSION error INSTRUCTION ELSE INSTRUCTION      { yyerror("'then' expected"); }
        | IF EXPRESSION THEN INSTRUCTION error INSTRUCTION      { yyerror("'else' expected"); }
        | error EXPRESSION DO INSTRUCTION                       { yyerror("'while' expected"); }
        | WHILE EXPRESSION error INSTRUCTION                    { yyerror("'do' expected"); }
        ;

VALUE:
        IDENT {valueIsVar = 1}
        | IDENT BRACKET_OPEN EXPRESSION BRACKET_CLOSE {valueIsVar = 0}
        | IDENT error EXPRESSION BRACKET_CLOSE        { yyerror("[ expected"); }
        | IDENT BRACKET_OPEN EXPRESSION error          { yyerror("] expected"); }
		| IDENT error EXPRESSION error {yyerror("not a statement or expression")}
        ;

FUNCTION_CALL:
        FUNCTION_PAREN_OPEN PAREN_CLOSE {yyverifmethodparams();}
        | FUNCTION_PAREN_OPEN EXPRESSION_CHAIN PAREN_CLOSE {yyverifmethodparams();}
        | FUNCTION_PAREN_OPEN EXPRESSION_CHAIN error          { yyerror(") expected");}
        ;
FUNCTION_PAREN_OPEN:
		IDENT PAREN_OPEN {yyverifmethod();}
		| IDENT error { yyerror("( expected"); NB_PARAM = 0; }

EXPRESSION_CHAIN:
        EXPRESSION {NB_PARAM ++;}
        | EXPRESSION_CHAIN COMMA EXPRESSION {NB_PARAM ++;}
		| EXPRESSION_CHAIN error EXPRESSION {yyerror("faulty expression"); NB_PARAM++;}

EXPRESSION:
		CALCULATABLE_VALUE {valueIsVar=0;}
        | CALCULATABLE_VALUE ADD CALCULATABLE_VALUE {valueIsVar=0;}
        | CALCULATABLE_VALUE MUL CALCULATABLE_VALUE {valueIsVar=0;}

CALCULATABLE_VALUE:
			VALUE {if(checkIdentifierDeclared(nom,yylineno)) {
								checkVarInit(nom, yylineno);
							}valueIsVar=0;}
			| FACTOR


ADD:
        PLUS
        | MINUS
        ;

MUL:
        MULTIP
        | DIVIDE
        ;
		

FACTOR:
		INT_LITERAL
        | PAREN_OPEN EXPRESSION PAREN_CLOSE
        ;

DECLARATION:
        VAR DECLARATION_BODY SEMI_COL 
        | error DECLARATION_BODY SEMI_COL       { yyerror("'var' expected"); }
        | VAR DECLARATION_BODY error            { yyerror("; expected"); }
        ;

DECLARATION_BODY:
        IDENT_LIST COL TYPE {yysavetypes();}
        | IDENT_LIST error TYPE         { yyerror(": expected"); yysavetypes(); }
        ;

IDENT_LIST:
        | IDENT {checkIdentifier(nom,yylineno);} COMMA IDENT_LIST 
        | IDENT {checkIdentifier(nom,yylineno);}
        ;

TYPE:
        ELEMEN_TYPE
        | ARRAY BRACKET_OPEN INT_LITERAL DOUBLE_DOT INT_LITERAL BRACKET_CLOSE OF ELEMEN_TYPE { VAR_TYPE = NODE_TYPE_UNKNOWN; }
        ;

ELEMEN_TYPE: 
        INTEGER{ VAR_TYPE = tInt; }
        | REAL { VAR_TYPE = tFloat; }
        | CHAR { VAR_TYPE = tChar; }
        | error         { yyerror("invalid type");	 } { VAR_TYPE = NODE_TYPE_UNKNOWN; }
        ;

%% 

int yyerror(char const *msg) {
    if (*msg != 's') {
        fprintf(stderr, "%s, in line %d..\n\n", msg, yylineno);
    }
}

extern FILE *yyin;

int main() {

	table = NULL;
	tableLocale = NULL;

	VAR_TYPE = NODE_TYPE_UNKNOWN;

	VAR_INDEX = 0;
	NB_PARAM = 0;

	IS_PROC = 0 ;
    IN_PROC_PARAMETERS = 0 ;
	
	methodIsValid = 0;
	
	valueIsVar = 0;

    yyparse();
	
	printf("\n\n Displaying symbols table \n\n");
	DisplaySymbolsTable(table, "|__");
}

int yywrap() {
    return 1;
}

int yysavetypes(){
	while( VAR_INDEX > 0 ) {
		VAR_INDEX-- ;
		SYMBOLS_LIST[VAR_INDEX]->type = VAR_TYPE;
	}
	VAR_INDEX = 0 ;
}

int yycreatemethodnoeud(){
	if( findSymbol(nom, table) ){
		yyerror("Procedure already defined");
	}else{
		NOEUD_PROC_VERIF = createNoeud(nom, NODE_TYPE_UNKNOWN, procedure, NULL);
		table = insertNoeud(NOEUD_PROC_VERIF, table);
	}
	IN_PROC_PARAMETERS = 1;
}

int yyverifmethod(){
	methodIsValid = 1;
	

	if (!findSymbol(nom, table)){
		yyerror (strcat(nom, ": Procedure not declared"));
		methodIsValid = 0;
		
	}
	else{
	
		NOEUD_PROC = findSymbol(nom,table);
		
		strcpy(methodName, nom);
		
	}

}

int yyverifmethodparams(){
	if(methodIsValid){
		if ( NOEUD_PROC->nbParam != NB_PARAM){
			char msg[256];
			sprintf(msg, "method '%s' expects %d parameters, found %d instead", methodName, NOEUD_PROC->nbParam, NB_PARAM);
			yyerror(msg);
		}
	
	}
	NB_PARAM = 0;
	methodIsValid = 0;
}