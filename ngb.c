/* Ngb ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Copyright (c) 2018,        Chris White
   Copyright (c) 2008 - 2016, Charles Childers
   Copyright (c) 2009 - 2010, Luke Parrish
   Copyright (c) 2010,        Marc Simpson
   Copyright (c) 2010,        Jay Skeer
   Copyright (c) 2011,        Kenneth Keating
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

// TODO: add `in8` and `out8` to read/write a UTF8 codepoint.
// Decoder for in8: http://bjoern.hoehrmann.de/utf-8/decoder/dfa/
// Encoder for out8: https://github.com/JuliaStrings/utf8proc/blob/master/utf8proc.h#L446

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <setjmp.h>
#include <termios.h>

// General globals

int Debugging = 0;

// VM machine definitions and constraints

#define VM_TRUE     (-1)
#define VM_FALSE    (0)
#define CELL        int32_t
#define IMAGE_SIZE  262144
#define ADDRESSES   128
#define STACK_DEPTH 32
#define CELLSIZE    32

enum vm_opcode {  // Note: NOP must always be instruction 0.
  VM_NOP,  VM_LIT,    VM_DUP,   VM_DROP,    VM_SWAP,   VM_PUSH,  VM_POP,
  VM_JUMP, VM_CALL,   VM_CCALL, VM_RETURN,  VM_EQ,     VM_NEQ,   VM_LT,
  VM_GT,   VM_FETCH,  VM_STORE, VM_ADD,     VM_SUB,    VM_MUL,   VM_DIVMOD,
  VM_AND,  VM_OR,     VM_XOR,   VM_SHIFT,   VM_ZRET,   VM_END,

  // Not in nga
  VM_IN,    // getc
  VM_OUT,   // putc
  VM_CJUMP,
  VM_ISEOF,
  VM_NUMIN,
  VM_NUMOUT,
  VM_PULL,

  NUM_OPS
};

// VM memory and registers

CELL sp, rp, ip;
CELL data[STACK_DEPTH] = {0};
CELL address[ADDRESSES] = {0};
CELL memory[IMAGE_SIZE] = {0};

int stats[NUM_OPS] = {0};
int max_sp, max_rp;

#define TOS  (data[sp])
#define NOS  (data[sp-1])
#define TORS (address[rp])

// Interactions with the OS

static jmp_buf DONE;
#define DONE_OK (-1)
  // Flag: longjmp(DONE, DONE_OK) triggers a non-error exit

static struct termios new_termios, old_termios;

void init_terminal() {
  if(!isatty(STDIN_FILENO)) return;
  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT|ISTRIP|IXON|IXOFF);
  new_termios.c_iflag |= (IGNBRK|IGNPAR);
  new_termios.c_lflag &= ~(ICANON|ISIG|IEXTEN|ECHO);
  new_termios.c_cc[VMIN] = 1;
  //new_termios.c_cc[VTIME] = 0;  // blocking reads
  tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);
}

void shutdown_terminal() {
  if(!isatty(STDIN_FILENO)) return;
  tcsetattr(STDIN_FILENO, TCSANOW, &old_termios);
}

CELL ngbLoadImage(char *imageFile) {
  FILE *fp;
  CELL imageSize;
  long fileLen;

  if ((fp = fopen(imageFile, "rb")) != NULL) {
    /* Determine length (in cells) */
    fseek(fp, 0, SEEK_END);
    fileLen = ftell(fp) / sizeof(CELL);
    rewind(fp);

    /* Read the file into memory */
    imageSize = fread(&memory, sizeof(CELL), fileLen, fp);
    fclose(fp);
  }
  else {
    printf("Unable to find the ngbImage!\n");
    exit(1);
  }
  return imageSize;
}

void ngbPrepare() {
  ip = sp = rp = max_sp = max_rp = 0;
  // The VM memory was already zero-intialized

  // Check endianness.  TODO support big-endian CPUs.
  union {
    unsigned char chars[4];
    CELL cell;
  } u;

  u.cell = 1;
  if(u.chars[0] != 1) {
    fprintf(stderr, "ngb does not yet know how to run on a big-endian machine\n");
    exit(1);
  }

}

void ngbStatsCheckMax() {
  if (max_sp < sp)
    max_sp = sp;
  if (max_rp < rp)
    max_rp = rp;
}

void ngbDisplayStats()
{
  int s, i;

  printf("Runtime Statistics\n");
  printf("NOP:     %d\n", stats[VM_NOP]);
  printf("LIT:     %d\n", stats[VM_LIT]);
  printf("DUP:     %d\n", stats[VM_DUP]);
  printf("DROP:    %d\n", stats[VM_DROP]);
  printf("SWAP:    %d\n", stats[VM_SWAP]);
  printf("PUSH:    %d\n", stats[VM_PUSH]);
  printf("POP:     %d\n", stats[VM_POP]);
  printf("JUMP:    %d\n", stats[VM_JUMP]);
  printf("CALL:    %d\n", stats[VM_CALL]);
  printf("CCALL:   %d\n", stats[VM_CCALL]);
  printf("RETURN:  %d\n", stats[VM_RETURN]);
  printf("EQ:      %d\n", stats[VM_EQ]);
  printf("NEQ:     %d\n", stats[VM_NEQ]);
  printf("LT:      %d\n", stats[VM_LT]);
  printf("GT:      %d\n", stats[VM_GT]);
  printf("FETCH:   %d\n", stats[VM_FETCH]);
  printf("STORE:   %d\n", stats[VM_STORE]);
  printf("ADD:     %d\n", stats[VM_ADD]);
  printf("SUB:     %d\n", stats[VM_SUB]);
  printf("MUL:     %d\n", stats[VM_MUL]);
  printf("DIVMOD:  %d\n", stats[VM_DIVMOD]);
  printf("AND:     %d\n", stats[VM_AND]);
  printf("OR:      %d\n", stats[VM_OR]);
  printf("XOR:     %d\n", stats[VM_XOR]);
  printf("SHIFT:   %d\n", stats[VM_SHIFT]);
  printf("ZRET:    %d\n", stats[VM_ZRET]);
  printf("END:     %d\n", stats[VM_END]);
  printf("IN:      %d\n", stats[VM_IN]);
  printf("OUT:     %d\n", stats[VM_OUT]);
  printf("CJUMP:   %d\n", stats[VM_CJUMP]);
  printf("ISEOF:   %d\n", stats[VM_ISEOF]);
  printf("NUMIN:   %d\n", stats[VM_NUMIN]);
  printf("NUMOUT:   %d\n", stats[VM_NUMOUT]);
  printf("PULL:     %d\n", stats[VM_PULL]);
  printf("Max sp:  %d\n", max_sp);
  printf("Max rp:  %d\n", max_rp);

  for (s = i = 0; s < NUM_OPS; s++)
    i += stats[s];
  printf("Total opcodes processed: %d\n", i);
}

// VM instructions =========================================================

void inst_nop() {
}

void inst_lit() {
  sp++;
  ip++;
  TOS = memory[ip];
  ngbStatsCheckMax();
}

void inst_dup() {
  sp++;
  data[sp] = NOS;
  ngbStatsCheckMax();
}

void inst_drop() {
  data[sp] = 0;
   if (--sp < 0)
     ip = IMAGE_SIZE;
}

void inst_swap() {
  CELL a;
  a = TOS;
  TOS = NOS;
  NOS = a;
}

void inst_push() {
  rp++;
  TORS = TOS;
  inst_drop();
  ngbStatsCheckMax();
}

void inst_pop() {
  sp++;
  TOS = TORS;
  rp--;
}

void inst_jump() {
  ip = TOS - 1;
  inst_drop();
}

void inst_call() {
  rp++;
  TORS = ip;
  ip = TOS - 1;
  inst_drop();
  ngbStatsCheckMax();
}

void inst_ccall() {
  CELL a, b;
  rp++;
  TORS = ip;
  a = TOS; inst_drop();  /* Destination address */
  b = TOS; inst_drop();  /* Flag  */
  if (b != VM_FALSE)
    ip = a - 1;
}

void inst_return() {
  ip = TORS;
  rp--;
}

void inst_eq() {
  if (NOS == TOS)
    NOS = VM_TRUE;
  else
    NOS = VM_FALSE;
  inst_drop();
}

void inst_neq() {
  if (NOS != TOS)
    NOS = VM_TRUE;
  else
    NOS = VM_FALSE;
  inst_drop();
}

void inst_lt() {
  if (NOS < TOS)
    NOS = VM_TRUE;
  else
    NOS = VM_FALSE;
  inst_drop();
}

void inst_gt() {
  if (NOS > TOS)
    NOS = VM_TRUE;
  else
    NOS = VM_FALSE;
  inst_drop();
}

void inst_fetch() {
  TOS = memory[TOS];
}

void inst_store() {
  memory[TOS] = NOS;
  inst_drop();
  inst_drop();
}

void inst_add() {
  NOS += TOS;
  inst_drop();
}

void inst_sub() {
  NOS -= TOS;
  inst_drop();
}

void inst_mul() {
  NOS *= TOS;
  inst_drop();
}

void inst_divmod() {
  CELL a, b;
  a = TOS;
  b = NOS;
  TOS = b / a;
  NOS = b % a;
}

void inst_and() {
  NOS &= TOS;
  inst_drop();
}

void inst_or() {
  NOS |= TOS;
  inst_drop();
}

void inst_xor() {
  NOS ^= TOS;
  inst_drop();
}

void inst_shift() {
  if (TOS < 0)
    NOS <<= (-TOS);
  else
    NOS >>= TOS;
  inst_drop();
}

void inst_zret() {
  if (TOS == 0) {
    inst_drop();
    ip = TORS;
    rp--;
  }
}

void inst_end() {
  ip = IMAGE_SIZE;  // ... which the main loop uses as the termination test.
}

// Not in nga

void inst_in() {
  sp++;
  TOS = getc(stdin);
  if(Debugging)
    printf("\nGot char %d %c\n", TOS, (TOS>=32 && TOS<127) ? TOS : '.');
  ngbStatsCheckMax();
}

void inst_out() {
  if(Debugging)
    printf("\n==> ");
  printf("%c", (char)(data[sp]&0xff));
  sp--;
}

void inst_cjump() {
  CELL a, b;

  a = TOS; inst_drop();  /* Destination address */
  b = TOS; inst_drop();  /* Flag  */
  if (b != 0) {
    ip = a - 1;
  }
}

void inst_iseof() {
    sp++;
    TOS = ( (NOS == -1) || (NOS == 4) ? -1 : 0);
        // Ctl-D (4) is also EOF
    if(Debugging)
      printf("\nCharacter %s EOF\n", TOS ? "was" : "was not");    // DEBUG
}

// Output the number on the top of the stack in base 26, self-marking.
void inst_numin() {
  CELL val = 0;
  int c;

  // Read MSB to LSB
  while(1) {
    val *= 26;
    c = getc(stdin);
    if(c == -1) {
      // EOF => done, and discard value.  TODO handle this better.
      val = -1;
      break;
    }

    val += c - (c < 'a' ? 'A' : 'a');

    if(c < 'a') break;  // Uppercase char => done

  }

  if(Debugging)
    printf("\ngot num %d\n", val);

  sp++;
  TOS = val;
  ngbStatsCheckMax();
} //inst_numin

void inst_numout() {
  CELL val = TOS;
  sp--;
  if(Debugging)
    printf("\nnum ==> %d\n", val);

  char buf[32] = {0}; // long enough for the base-26 representation of any int
  char *curr = buf;

  // Generate LSB to MSB
  do {
    *curr++ = (val % 26) + (curr==buf ? 'A' : 'a');   // last char is uppercase
    val /= 26;
  } while(val>0 && ((curr-buf) < sizeof(buf)));

  // Print MSB to LSB
  --curr;   // undo the last curr++, which pushed us off the end
  while(curr>=buf) {
    printf("%c", *curr--);
  }
} //inst_numout

void inst_pull() {
  CELL which = TOS;
  TOS = data[sp-which];
}

// Instruction table
typedef void (*Handler)(void);

Handler instructions[NUM_OPS] = {
  inst_nop, inst_lit, inst_dup, inst_drop, inst_swap, inst_push, inst_pop,
  inst_jump, inst_call, inst_ccall, inst_return, inst_eq, inst_neq, inst_lt,
  inst_gt, inst_fetch, inst_store, inst_add, inst_sub, inst_mul, inst_divmod,
  inst_and, inst_or, inst_xor, inst_shift, inst_zret, inst_end,
  inst_in,
  inst_out,
  inst_cjump,
  inst_iseof,
  inst_numin,
  inst_numout,
  inst_pull,
};

char *instr_names[NUM_OPS] = {
  "nop", "lit", "dup", "drop", "swap", "push", "pop",
  "jump", "call", "ccall", "return", "eq", "neq", "lt",
  "gt", "fetch", "store", "add", "sub", "mul", "divmod",
  "and", "or", "xor", "shift", "zret", "end",
  "in",
  "out",
  "cjump",
  "iseof",
  "numin",
  "numout",
  "pull",
};

// Interpreter =============================================================

void ngbProcessOpcode() {
  stats[memory[ip]]++;
  instructions[memory[ip]]();
}

#ifndef NO_MAIN

int main(int argc, char **argv) {
  char *filename = "ngbImage";  // default
  ngbPrepare();

  // Check command line
  if (argc>1 && strcmp(argv[1], "-g")==0) {
    Debugging = 1;
    if(argc>2) filename = argv[2];

  } else if (argc>1) {
    filename = argv[1];
  }

  ngbLoadImage(filename);

  CELL opcode, i;

  init_terminal();

  int retval = setjmp(DONE);

  if(retval == 0) {   // First time through: run it
    if(Debugging)
      printf("addr\topcode\tname\tpreTOS\tpostTOS\n");

    ip = 0;
    while (ip < IMAGE_SIZE) {
      opcode = memory[ip];
      if (opcode >= 0 && opcode < NUM_OPS) {
        if(Debugging)
          printf("%d\t%d\t%s\t%d", ip, opcode, instr_names[opcode], TOS);

        ngbProcessOpcode();

        if(Debugging)
          printf("\t%d\n", TOS);

      } else {
        printf("Invalid instruction!\n");
        printf("At %d, opcode %d\n", ip, opcode);
        retval = 1;
        break;
      }
      ip++;
    }

  } //endif first time through

  if(retval == DONE_OK) { retval = 0; }
    //because longjmp can't provide a 0 value

  shutdown_terminal();

  if(Debugging) {
    int bot = sp-100;   // print up to the top 100 stack entries
    if(bot<1) { bot = 1; }

    for (i = bot; i <= sp; i++) {
      printf("%8d: %d ", i, data[i]);
    }

    printf("\n");
  }

  exit(retval);
}

#endif
