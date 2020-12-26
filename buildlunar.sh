#!/bin/bash

gcc -shared -fpic -I/bin/lua/src -L/bin/lua/src -lpthread -ldl -lm /src/server.c -o /lib/luaserver.so
gcc -shared -fpic -I/bin/lua/src -L/bin/lua/src -lpthread -ldl -lm /src/json.c -o /lib/json.so
gcc /src/lunarserver.c /src/lunar.c /src/statepool.c /src/stringbuilder.c /lib/luaserver.so /lib/json.so -o /bin/lunarserver -I/bin/lua/src -L/bin/lua/src -llua -ldl -lm
chmod +x /bin/lunarserver
