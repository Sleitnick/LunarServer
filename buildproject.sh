#!/bin/bash

gcc -shared -fpic -I/bin/lua/src -L/bin/lua/src -lpthread -ldl -lm /src/server.c -o /lib/luaserver.so
gcc /src/lunarserver.c /src/lunar.c /lib/luaserver.so -o /bin/lunarserver -I/bin/lua/src -L/bin/lua/src -llua -ldl -lm
chmod +x /bin/lunarserver