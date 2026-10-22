## CS3210 Buffer Overflow Demo

In this demo, you will learn about the fundamentals of buffer overflow attacks and write a few of your own!

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

Resources: 
- [Smashing the Stack](https://phrack.org/issues/49/smashing-the-stack-for-fun-and-profit)
- [CS 6265 Tutorials](https://tc.gts3.org/cs6265/tut/)
