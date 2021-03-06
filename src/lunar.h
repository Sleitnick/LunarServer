#ifndef __LUNARSERVER_LUNAR__
#define __LUNARSERVER_LUNAR__

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include "json.h"

int lunar_append_package_path(lua_State *L, const char* path, int is_cpath);
int lunar_runscript(lua_State *L, const char* path, int args, int rets);
lua_State* lunar_newstate();

#endif