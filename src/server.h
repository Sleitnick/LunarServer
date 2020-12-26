#ifndef __LUNARSERVER_LIBSERVER__
#define __LUNARSERVER_LIBSERVER__

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <sys/socket.h>
#include <unistd.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <string.h>
#include <signal.h>
#include <pthread.h>
#include <regex.h>
#include <time.h>
#include "lunar.h"
#include "statepool.h"

#define LUASERVER_MT "luaserver_mt"

#define DEBUG_LOG_REQUEST_TIME 0

static int luaserver_new(lua_State *L);
static int luaserver_listen(lua_State *L);
LUALIB_API int luaopen_luaserver(lua_State *L);

#endif