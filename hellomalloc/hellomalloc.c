#include <stdlib.h>
#include <stdio.h>

#define NUM_ALLOCS 1000

struct foo {
    char a;
    int  b;
    long c;
};

int main (int argc, char **argv) {
    volatile struct foo* ptrs[NUM_ALLOCS];
    unsigned i;

    for (i = 0; i < NUM_ALLOCS; i++) {
        ptrs[i] = (struct foo *)malloc(sizeof(struct foo));
    }
    printf("Allocated %d things.\n", NUM_ALLOCS);

    for (i = 0; i < NUM_ALLOCS; i++) {
        free(ptrs[i]);
    }
    printf("Freed %d things.\n", NUM_ALLOCS);

    return 0;
}
