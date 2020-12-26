#ifndef __LUNARSERVER_LIBJSON__
#define __LUNARSERVER_LIBJSON__

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

LUALIB_API int luaopen_json(lua_State *L);

#endif