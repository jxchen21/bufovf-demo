### CS3210 Buffer Overflow Demo

In this demo, you will learn about the fundamentals of buffer overflow attacks and write a few of your own!

## Challenge 1: ret2win

Can you exploit a vulnerable user input to redirect the execution flow of the program? 

Lower addresses
  ┌──────────────────────────┐
  │                           │
  │   char buf[64]            │ 
  │                           │   
  ├──────────────────────────┤  
  │   saved EBP               │ 
  ├──────────────────────────┤
  │   return address          │ 
  ├──────────────────────────┤
  │   previous stack frames   │
  │        ...                │
  └──────────────────────────┘
Higher addresses
