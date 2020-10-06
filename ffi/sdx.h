#ifndef _SDX
#define _SDX

typedef enum {
    SDX_INT,
    SDX_STR
} SDXId;

typedef union {
    int sdx_int;
    char* sdx_str;
} SDXValI;

typedef struct {
    SDXId id;
    SDXValI val;
} SDXVal;

#endif