#include <stdio.h>
#include <unistd.h>

void vuln(void) {
    char buf[64];
    printf("buf is at %p\n", buf);
    read(0, buf, 256);
}

int main(void) {
    setreuid(geteuid(), geteuid());
    vuln();
    return 0;
}
