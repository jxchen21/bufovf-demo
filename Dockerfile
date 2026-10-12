FROM ubuntu:22.04

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    gcc \
    gcc-multilib \
    libc6-dev-i386 \
    make \
    gdb \
    gdbserver \
    tmux \
    python3 \
    python3-pip \
    file \
    checksec \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir pwntools

RUN mkdir -p /etc/gdb && printf '%s\n' \
    'set startup-quietly on' \
    'set confirm off' \
    'set verbose off' \
    'set pagination off' \
    'set sysroot /' \
    'set debuginfod enabled off' \
    > /etc/gdb/gdbinit

# --- challenge boundary: unprivileged user, protected flag, setuid binary ---

# Low-privilege user the student operates as
RUN useradd -m -s /bin/bash student

# Secret flag: owned by root, readable only by root (student cannot cat it directly).
# base64-obfuscated so it isn't readable at a glance in the repo (NOT real
# secrecy -- it's still recoverable from the image / docker history).
#   to change it:  printf '%s' 'CS3210{your_flag}' | base64
RUN echo 'Q1MzMjEwe0k8M3B3bn0=' | base64 -d > /flag.txt \
    && chown root:root /flag.txt \
    && chmod 400 /flag.txt

# Graded challenge binaries, built setuid-root OUTSIDE the bind mount.
# Flags match each challenge's Makefile so addresses line up with local builds.

# ret2win: NX left ON (no -z execstack) -> must return into win()
COPY ret2win/vuln.c /ret2win/vuln.c
RUN gcc -m32 -fno-stack-protector -no-pie -fno-pic -g -w \
        /ret2win/vuln.c -o /ret2win/vuln \
    && rm /ret2win/vuln.c \
    && chown root:root /ret2win/vuln \
    && chmod 4755 /ret2win/vuln

# shellcode: executable stack (NX OFF) -> inject shellcode on the stack
COPY shellcode-injection/vuln.c /shellcode-injection/vuln.c
RUN gcc -m32 -fno-stack-protector -no-pie -fno-pic -z execstack -g -w \
        /shellcode-injection/vuln.c -o /shellcode-injection/vuln \
    && rm /shellcode-injection/vuln.c \
    && chown root:root /shellcode-injection/vuln \
    && chmod 4755 /shellcode-injection/vuln

WORKDIR /bufovf-demo

# Drop privileges for the interactive session
USER student