FROM alpine:edge
WORKDIR /root
COPY src/ src/
COPY ffi/ ffi/
COPY bin/ bin/
COPY cr/ cr/
COPY shard.yml .
COPY Makefile .
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk update
RUN apk add make gcc crystal=0.35.1-r0 shards=0.12.0-r0 readline-static musl-dev ncurses-libs ncurses-static llvm
RUN cd cr/ && make libcrystal && cd ..
RUN export CRYSTAL_PATH="$(pwd)/cr/src:$(pwd)/lib" && make sdx
ENTRYPOINT /root/bin/sdx