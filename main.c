#include <stdio.h>
#include <stdlib.h>

#define text_size 1000

extern void Interpret(char* text); //expecting that at the end of every line there will be /r/n or /rEND

int main() {
    char text[text_size];

    FILE* raw_code;
    char ch;

    if ((raw_code = fopen("Lambda_Code.txt", "r")) == NULL) {
        printf("file can't be opened \n");
        exit(0);
    }

    do {
        ch = fgetc(raw_code);
    } while (ch <= 32);

    int t=0;
    text[t] = ch;

    do {
        if (t>=text_size-1) {
            printf("Code is too large, please increase text_size.");
        }

        ch = fgetc(raw_code);
        if (ch=='\n' && text[t]== '\n') continue;
        if (ch=='\r' && text[t]=='\n') continue;
        if (ch <= 32 && ch != '\r' && ch != '\n') continue ; //don't copy non-displayable characters or spaces
        text[++t] = ch;
    } while (ch != EOF);
    
    fclose(raw_code);

    text[t] = '\r';
    text[++t] = '\0';


    setbuf(stdout, 0);
    Interpret(text);
}
