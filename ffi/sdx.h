#ifndef _SDX
#define _SDX

typedef enum {
    SDX_INT,
    SDX_STR,
    SDX_BOOL,
    SDX_NUM,
    SDX_NIL
} SDXId;

typedef union {
    int sdx_int;
    char* sdx_str;
    int sdx_bool;
    double sdx_num;
    int sdx_nil;
} SDXValI;

typedef struct {
    SDXId id;
    SDXValI val;
} SDXVal;

#endif