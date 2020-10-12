#include <dlfcn.h>
#include <stdio.h>
#include "sdx.h"

typedef void*(fun)(void*);

fun* sdxdlsym(void* handle, char* sym) {
    return (fun*) dlsym(handle, sym);
}

SDXVal add(SDXVal val) {
    SDXVal out = { 
        .id = SDX_INT, 
        .val = val.val.sdx_int + 5 
    };
    return out;
}