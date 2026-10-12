#include <stdio.h>
#include <unistd.h>

void vuln(void) {
    char buf[64];
    printf("buf is at %p\n", buf);   /* address leak */
    read(0, buf, 256);               /* binary-safe: raw shellcode bytes pass through */
}

int main(void) {
    setreuid(geteuid(), geteuid());
    vuln();
    return 0;
}
