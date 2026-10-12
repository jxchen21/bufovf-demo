#include <stdio.h>
#include <unistd.h>

/* Shellcode-injection challenge (with address leak).
 *
 * The program prints the address of buf, so students can jump to their
 * injected shellcode regardless of ASLR. The stack is executable (built
 * with -z execstack). Overflow buf, overwrite the saved return address
 * with the leaked buf address, and execution lands in your shellcode.
 */

void vuln(void) {
    char buf[64];
    printf("buf is at %p\n", buf);   /* address leak */
    read(0, buf, 256);               /* binary-safe: raw shellcode bytes pass through */
}

int main(void) {
    setreuid(geteuid(), geteuid());
    setvbuf(stdout, NULL, _IONBF, 0);   /* unbuffered: the leak reaches the pipe immediately */
    vuln();
    return 0;
}
