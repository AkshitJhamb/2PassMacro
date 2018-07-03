%{
#include "y.tab.h"
#include<string.h>
#include<stdio.h>
int macro_body = 0, after_macro_def = 0, after_instr = 0, after_macro_call = 0;
int i;
char str[50];
%}
%%
"COPY START 0" {
    strcpy(str, yytext);
    yylval.sval = str;
    return DOT;
}

[a-zA-Z0-9]+" MACRO" {
    printf("\nFound MACRO:");
    after_macro_def = 1;
    for(i=0;yytext[i]!=' ';i++)
        str[i] = yytext[i];
    str[i] = '\0';
    yylval.sval = str;
    return MACRO;
}

"END COPY" {
    printf("\nFound END\n");
    return END;
}

"MEND" {
    printf("\nFound MEND\n");
    macro_body = 0;
    after_macro_def = 0;
    after_macro_call = 0;
    after_instr = 0;
    return MEND;
}

"ADD"|"COMPR"|"COMP"|"CLEAR"|"STX"|"ADDR"|"+JSUB"|"LDA"|"LDT"|"TIXR"|"FIX" {
        after_instr=1;
        strcpy(str,yytext);
        //printf("\nFound CMD\n");
        return CMD;
}

[a-zA-Z0-9]+(" WORD"|" RESW"|" RESB"|" BYTE") {
        after_instr=1;
        strcpy(str,yytext);
        //printf("\nFound CMD\n");
        return CMD;
}

[&#]*[a-zA-Z0-9']+ {
    if(after_macro_def == 1 || after_macro_call == 1)
    {
        strcpy(str,yytext);
        yylval.sval = str;
        printf("\nFound MACRO_PARAM:%s",yytext);
        return MACRO_PARAM;
    }
    else if(after_instr == 1)
    {
        strcpy(str,yytext);
        //printf("\nFound VAR\n");
        return VAR;
    }
    else if(macro_body == 0)
    {
        strcpy(str,yytext);
        yylval.sval = str;
        printf("\n\nFound Macro Invocation:%s",yytext);
        after_macro_call = 1;
        return MACRO_INVOC;
    }
}

,       return COMMA;

\n {
        after_instr = 0;
        if(after_macro_def == 1)
        {
            macro_body = 1;
            after_macro_def = 0;
        }
        else if(after_macro_call == 1)
        {
            after_macro_call = 0;
        }
        return NEWLINE;
    }

%%
int yywrap() { return 1;}