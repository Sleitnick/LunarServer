all: build

build:
	gcc -shared -fpic -Ilua/src -Llua/src -lpthread -ldl -lm luaserver.c -o luaserver.so

clean:
	rm -f luaserver.so
