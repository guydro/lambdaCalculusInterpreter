CC = gcc
NASM = nasm
FLAGS = -ggdb -Wall -m64 -O0
ASMFLAGS = -f elf64 -g -Wall -F dwarf

asms := $(wildcard *.asm)
asm_objs := $(asms:%.asm=%.o)

all: main

%.o: %.c
		$(CC) $(FLAGS) $< -c

%.o : %.asm
		$(NASM) $(ASMFLAGS) $< -o $@

main : $(asm_objs) main.c
		$(CC) $(FLAGS) -o $@ $^


clean:
		-rm *.o