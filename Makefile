libsdxdl: ffi/sdxdl.c
	@echo Building libsdxdl.so...
	@gcc -static -o bin/libsdxdl.so -fPIC ffi/sdxdl.c -ldl -c

sdx: libsdxdl src/*.cr
	@echo Building bin/sdx...
	@shards install
	@crystal build --static -p --release --no-debug src/sdx.cr -o bin/sdx
