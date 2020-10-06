libsdxdl: ffi/sdxdl.c
	@echo Building libsdxdl.so...
	@gcc -shared -o bin/libsdxdl.so -fPIC ffi/sdxdl.c

sdx: libsdxdl src/*.cr
	@echo Building bin/sdx...
	@crystal build --release --no-debug src/sdx.cr -o bin/sdx