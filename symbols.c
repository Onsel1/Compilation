#include "symbols.h"


TABLE_SEMANTIQUE table, tableLocale;


NOEUD NOEUD_PROC, NOEUD_PROC_VERIF; // for inserting in function, and checking if function has the right nb of params, respectively
NOEUD SYMBOLS_LIST[100]; // list of all variables

TYPE_IDENTIFIANT VAR_TYPE; // type of a variable
int VAR_INDEX; // index for which variable we're currently processing
int IS_PROC; // true if inside procedure
int IN_PROC_PARAMETERS; // true if processing procedure parametres
int NB_PARAM; // number of function params
int valueIsVar; // true if a value is a variable (not a param)
int methodIsValid; // true if method is found

NOEUD createNoeud (const char* nom, TYPE_IDENTIFIANT type, CLASSE classe, NOEUD suivant){
    NOEUD noeud = (NOEUD)malloc(sizeof(struct NOEUD));
    noeud->nom = (char *)malloc(strlen(nom)+1);
    strcpy(noeud->nom, nom);
    noeud->type = type;
	noeud->classe = classe;
    noeud->suivant = suivant;
    noeud->sous_var = NULL;
    noeud->isInit = 0;
    noeud->isUsed = 0;
    return noeud;
}

NOEUD insertNoeud (NOEUD noeud, TABLE_SEMANTIQUE table) {
	if( !table ) {
		return noeud;
	}
	else {
		NOEUD last = table;
		while( last->suivant ) {
			last = last->suivant;
		}
		last->suivant = noeud;
		return table;
	}
}


NOEUD insertSousNoeud (NOEUD noeud, TABLE_SEMANTIQUE table, TYPE_IDENTIFIANT type, char* nom) {
      
	if( !table ) {
		return noeud;
	}
	
	else {
        
        if( !table->sous_var){
            table->sous_var = noeud;
            //createNoeud(nom, type, procedure, NULL);
        }
        
		NOEUD last = table->sous_var;
		while( last->suivant ) {
			last = last->suivant;
		}
		last->suivant = noeud;
		return table;
	}
}

NOEUD lastNoeud (TABLE_SEMANTIQUE table){
      if( !table ) {
		return table;
	}
	
	else {
		NOEUD last = table;
		while( last->suivant ) {
			last = last->suivant;
		}
		return last;
	}
	
}

NOEUD findSymbol (const char* nom, TABLE_SEMANTIQUE table) {
	if( !table )
		return NULL;
	NOEUD noeud = table;
	while( noeud && ( strcmp(nom, noeud->nom) != 0 ) ){       
		noeud = noeud->suivant;
    }
	return noeud;
}

void destructSymbolsTable( TABLE_SEMANTIQUE table )
{
	if( !table )
		return;
	NOEUD noeud = table;
	while( noeud )
	{
        NOEUD current = noeud;
		noeud = noeud->suivant;
		
		if(current->sous_var){
            NOEUD nd = current->sous_var;
            
            while(nd){
                NOEUD cr = nd;
                nd = nd->suivant;
                
                free(cr->nom);
                free(cr);
            }
                              
        }
		
		free(current->nom);
		free(current);
	}
}

void DisplaySymbolsTable( TABLE_SEMANTIQUE SymbolsTable, char* tabStr ){
	if( !SymbolsTable )
		return;
	NOEUD Node = SymbolsTable;
	
	while( Node )
	{
        printf(tabStr);
		switch( Node->type )
		{
			case tInt :
				printf("int ");
				break;
			
			case NODE_TYPE_UNKNOWN :
				switch (Node->classe)
				{
				case procedure:{
                     printf("procedure: '%s'\n", Node->nom);
                     printf(tabStr);
                     printf("sous-variables de la fonction %s: \n", Node->nom);
                     char tabStr2[256];
                     
                     sprintf(tabStr2, "%s___", tabStr);
                     
                     DisplaySymbolsTable(Node->sous_var, tabStr2);

                     
                    }
					break;
				
				default:
					break;
				}break;

			default :
				printf("Unknown ");
		}

		switch (Node->classe)
		{
			case variable:
				printf("variable ");
				break;

			case parametre:
				printf("parametre ");
				break;	

			default:
				break;
		}
        if(!(Node->classe == procedure)){
            printf(": '%s'", Node->nom);
            if(Node->isInit){
                printf(" initialised");
            }else{
                  printf(" Uninitialised");
            }
            if(Node->isUsed){
                printf(" used");
            }else{
                  printf(" Unusued");
            }
            printf("\n");
        }
		

		Node = Node->suivant;
	}
}


void checkIdentifier (char* nom, int ylineno){
	CLASSE classe;

	if (IS_PROC){
		if (IN_PROC_PARAMETERS){
			classe = parametre;
			NB_PARAM ++;
		}else{
			classe = variable;
		}
		if( findSymbol(nom, tableLocale) ){
			print_error("Identifier already defined",ylineno);
		}else{
			NOEUD noeud = createNoeud(nom, VAR_TYPE, classe ,NULL);
			tableLocale = insertNoeud(noeud, tableLocale);
			SYMBOLS_LIST[VAR_INDEX] = noeud;
			VAR_INDEX++;
		}
	}else{
		if( findSymbol(nom, table) ){
			print_error("Identifier already defined",ylineno);
		}else{
			NOEUD noeud = createNoeud(nom, VAR_TYPE, variable ,NULL);
			table = insertNoeud(noeud, table);
			SYMBOLS_LIST[VAR_INDEX] = noeud;
			VAR_INDEX++;
		}
	}
}

int checkIdentifierDeclared (char* nom, int ylineno){

	NOEUD noeud;

	if (IS_PROC){
		noeud = findSymbol(nom,tableLocale);
		if ( !noeud ){
			noeud = findSymbol(nom,table);
			if( !noeud ){
				print_error(strcat(nom, " Variable undeclared"),ylineno);
				return 0;
			}else
			{
				noeud->isUsed = 1;
			}
		}else
		{
			noeud->isUsed = 1;
		}
	}else{
		noeud = findSymbol(nom,table);
		if( !noeud ){
				print_error(strcat(nom, " Variable undeclared"),ylineno);
				return 0;
		}else
		{
			noeud->isUsed = 1;
		}
	}
	return 1;
}

void setVarInitialised (char* nom){

	NOEUD noeud;

	if (IS_PROC){
		noeud = findSymbol(nom,tableLocale);
		if ( !noeud )
			noeud = findSymbol(nom,table);
	}else{
		noeud = findSymbol(nom,table);
	}
    noeud->isInit = 1;
}

void checkVarInit (char* nom,int ylineno){

	NOEUD noeud;
	
	if (IS_PROC){
		noeud = findSymbol(nom,tableLocale);
		if ( !noeud )
			noeud = findSymbol(nom,table);
	}else{
		noeud = findSymbol(nom,table);
	}
	if(noeud && noeud->classe == variable && !noeud->isInit){
        if(noeud->type != NODE_TYPE_UNKNOWN){
           char msg[256];
           sprintf(msg, "Warning: Variable '%s' may have not been initialised ",noeud->nom);
		   print_error(msg,ylineno);
        }
    }
}

void finalizeNoeud(int ylineno)
{
	NOEUD tmp_table;
	if (IS_PROC == 1){
		// printf("*** Table Locale ***\n");
		// DisplaySymbolsTable( tableLocale );
		IS_PROC = 0;
		tmp_table = tableLocale;
		NOEUD finalNoeud = lastNoeud(table);
		finalNoeud->sous_var = tableLocale;
		tableLocale = NULL;
	}else{
		// printf("*** Table Globale ***\n");
		// DisplaySymbolsTable( table );
		tmp_table = table;
	}
	
	while( tmp_table ){
			if (tmp_table->classe == variable && !tmp_table->isUsed){
				char msg[256];
				sprintf(msg,"Warning: %s variable is unused", tmp_table->nom);
				print_error(msg,ylineno);

            }
			tmp_table = tmp_table->suivant;
	}
}

int print_error(char * msg, int ylineno) 
{
	fprintf(stderr,"%s, in line %d..\n", msg, ylineno);
	return(1);
}


