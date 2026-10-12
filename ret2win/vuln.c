#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>


void win(void) {
    printf("You won!\n");
    fflush(stdout);
    exit(0);
}

void vuln(void) {
    char buf[64];
    printf("Enter an input:\n");
    read(0, buf, 256);
    printf("You entered: %s\n", buf);
}

int main(void) {
    vuln();
    return 0;
}
