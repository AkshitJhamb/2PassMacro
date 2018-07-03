%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "1.h"
extern FILE * yyin;
extern FILE * yyout;
int num = 1, inside_macro = 0, inside_macro_invoc = 0, num_of_arg, total_args, val;
char store[300];

NAMTAB * nam_head = NULL;
DEFTAB * def_head = NULL;
ARGTAB * arg_head = NULL;

DEFTAB * def_node = NULL;
DEFTAB * temp = NULL;

void create_def_tab()
{
    def_node = (DEFTAB*)malloc(sizeof(DEFTAB));
    def_node->pos = num++;
    def_node->num_of_arg = 0;
    def_node->arg = NULL;
    def_node->next = NULL;
}

void arg_def_tab(char * s)
{
    ARGLIST * temp = (ARGLIST*)malloc(sizeof(ARGLIST));
    strcpy(temp->name, s);
    temp->posn = ++def_node->num_of_arg;
    temp->next = NULL;
    if(def_node->arg == NULL)
        def_node->arg = temp;
    else
    {
        ARGLIST * p = def_node->arg;
        while(p->next)
            p = p->next;
        p->next = temp;
    }
}

void accumulate(char * s)
{
    ARGLIST * temp = def_node->arg;
    char buf[10];
    while(temp)
    {
        if(strcmp(temp->name, s)==0)
        {
            sprintf(buf, "%d", temp->posn);
            strcat(store, buf);
            strcat(store, " ");
            return;
        }
        temp = temp->next;
    }
    strcat(store, s);
    strcat(store, " ");
    //printf("\nInside Accumulate %s\n",store);
}

void add_def_tab()
{
    strcpy(def_node->array, store);
    if(def_head == NULL)
        def_head = def_node;
    else
    {
        def_node->next = def_head;
        def_head = def_node;
    }
    strcpy(store, "");
    def_node = NULL;
}

DEFTAB * get_def_node(int val)
{
    DEFTAB * temp = def_head;
    while(temp)
    {
        if(temp->pos == val)
            return temp;
        temp = temp->next;
    }
    return NULL;
}

int get_arg_number(int val)
{
    DEFTAB * temp = def_head;
    while(temp)
    {
        if(temp->pos == val)
            return temp->num_of_arg;
        temp = temp->next;
    }
    return -1;
}

void add_nam_tab(char * str)
{
    NAMTAB * temp = (NAMTAB*) malloc(sizeof(NAMTAB));
    strcpy(temp->name, str);
    temp->pos = num;
    temp->next = NULL;
    if(nam_head == NULL)
        nam_head = temp;
    else
    {
        temp->next = nam_head;
        nam_head = temp;
    }
}

void add_arg_tab(char * str)
{
    ARGTAB * temp = (ARGTAB*) malloc(sizeof(ARGTAB));
    strcpy(temp->args, str);
    temp->next = NULL;
    if(arg_head == NULL)
        arg_head = temp;
    else
    {
        ARGTAB * p = arg_head;
        while(p->next)
            p = p->next;
        p->next = temp;
    }
}

int check_nam_tab(char * str)
{
    NAMTAB * temp = nam_head;
    while(temp)
    {
        if(strcmp(temp->name, str) == 0)
            return temp->pos;
        temp = temp->next;
    }
    return 0;
}

%}

%union
{
    int ival;
	float fval;
	char *sval;
}

%token MEND END COMMA NEWLINE
%token <sval> MACRO MACRO_BODY MACRO_PARAM MACRO_INVOC CMD VAR DOT
%start SS

%%

SS : S END { fprintf(yyout, "%s", "END");} NEWLINE;

S : DOT1 NEWLINE1 S
    | MACRO1 PARAM NEWLINE1 S
    | MACRO_INVOC {
        val = check_nam_tab($1);
        inside_macro_invoc = 1;
        if(!val) {
            printf("\nMacro Not Present!\n");
            exit(0);
        }
        else
        {
            num_of_arg = get_arg_number(val);
            total_args = num_of_arg;
        }
    } PARAM {
        if(num_of_arg!=0) {
            printf("\nArguments Mismatch\n");
            exit(0);
        }
        else
        {
            temp = get_def_node(val);
            for(int i=0;i<strlen(temp->array)-2;i++)
            {
                if(temp->array[i] == ' ' && temp->array[i+1] <= temp->num_of_arg+48 && temp->array[i+1]>48 && (temp->array[i+2] == ' ' || temp->array[i+2] == '\n'))
                {
                    int x = temp->array[i+1]-48;
                    ARGTAB * p = arg_head;
                    while(--x)
                        p = p->next;
                    fprintf(yyout, " %s", p->args);
                    i++;
                }
                else
                    fprintf(yyout, "%c", temp->array[i]);
            }
            free(arg_head);
            arg_head = NULL;
        }
    } NEWLINE1 S
    | BODY S
    | MEND1 S
    | NEWLINE1 S
    | ;

MACRO1 : MACRO { inside_macro = 1; add_nam_tab($1); create_def_tab(); } ;

MEND1 : MEND { inside_macro = 0; add_def_tab(); } ;

PARAM : MACRO_PARAM {
            if(inside_macro)
            {
                arg_def_tab($1);
            }
            else
            {
                num_of_arg--;
                add_arg_tab($1);
            }
        } COMMA1 PARAM
        | MACRO_PARAM {
            if(inside_macro)
            {
                arg_def_tab($1);
            }
            else
            {
                num_of_arg--;
                add_arg_tab($1);
            }
        }
        | ;

BODY : CMD1 NEWLINE1 BODY
     | CMD1 VAR1 NEWLINE1 BODY
     | CMD1 VAR1 COMMA1 VAR1 NEWLINE1 BODY
     | ;

DOT1 : DOT { fprintf(yyout, "%s", $1); } ;

CMD1 : CMD { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); } ;

VAR1 : VAR { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); } ;

COMMA1 : COMMA {
    if(!inside_macro_invoc && !inside_macro)
        fprintf(yyout, ",");
} ;

NEWLINE1 : NEWLINE {
    if(inside_macro)
        accumulate("\n");
    else
        fprintf(yyout, "\n");
} ;

%%

void disp_nam_tab()
{
    printf("\nNAME TABLE-:");
    NAMTAB * temp = nam_head;
    while(temp)
    {
        printf("\n%d-%s", temp->name, temp->pos);
        temp=temp->next;
    }
}

void disp_def_tab()
{
    printf("\nDEFINITION TABLE-:");
    DEFTAB * temp = def_head;
    while(temp)
    {
        printf("\nPos = %d",temp->pos);
        printf("\nParameters:");
        ARGLIST * temp2 = temp->arg;
        while(temp2)
        {
            printf("%s ",temp2->name);
            temp2 = temp2->next;
        }
        printf("\nBody:%s\n", temp->array);
        temp=temp->next;
    }
}

int main(int argc,char* argv[])
{
    if(argc < 2){
        printf("Give input file name");
        exit(0);
    }
    yyin = fopen(argv[1], "r");
    yyout = fopen("outtext.txt", "w");
    yyparse();
    printf("\nValid\n");
    disp_nam_tab();
    printf("\n");
    disp_def_tab();
    printf("\n");
}

yyerror()
{
    printf("\nInvalid\n");
    exit(0);
}
