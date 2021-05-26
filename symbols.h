#include "stdio.h"
#include <stdlib.h>
#include <string.h>

typedef enum {
	NODE_TYPE_UNKNOWN,
	tInt,
	tChar,
	tFloat
} TYPE_IDENTIFIANT;

typedef enum {
	CLASSE_UNKNOWN,
	variable,
	procedure,
	parametre
} CLASSE;

struct NOEUD
{ 
    char* nom;
    TYPE_IDENTIFIANT type;
	CLASSE classe;
    int isInit; 
    int isUsed;
    int nbParam;
    
    struct NOEUD * suivant;
    struct NOEUD * sous_var;
};

typedef struct NOEUD * NOEUD;
typedef NOEUD TABLE_SEMANTIQUE;

NOEUD createNoeud (const char* nom, TYPE_IDENTIFIANT type, CLASSE classe, NOEUD suivant);
NOEUD insertNoeud (NOEUD noeud, TABLE_SEMANTIQUE table);
NOEUD insertSousNoeud (NOEUD noeud, TABLE_SEMANTIQUE table, TYPE_IDENTIFIANT type, char* nom);
NOEUD findSymbol (const char* nom, TABLE_SEMANTIQUE table);
NOEUD lastNoeud (TABLE_SEMANTIQUE table);

void checkIdentifier(char* nom, int ylineno);
int checkIdentifierDeclared(char* nom, int ylineno);
void setVarInitialised (char* nom);
void checkVarInit(char * nom, int ylineno);
void finalizeNoeud(int ylineno);
void destructSymbolsTable( TABLE_SEMANTIQUE SymbolsTable );
int print_error(char* msg, int ylineno);

