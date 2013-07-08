#include <stdio.h>

extern int yylex (void);

int main(int argc, char *argv[]) {
        printf("Howdy!\n");
        yylex();
        return 0;
}
