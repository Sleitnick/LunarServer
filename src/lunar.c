#include "lunar.h"
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static const luaL_Reg lunar_loadedlibs[] = {
	{"json", luaopen_json},
	{NULL, NULL}
};

int lunar_append_package_path(lua_State *L, const char* path, int is_cpath) {
	const char* field_name = (is_cpath ? "cpath" : "path");
	lua_getglobal(L, "package");
	lua_getfield(L, -1, field_name);
	lua_pushstring(L, path);
	lua_concat(L, 2);
	lua_setfield(L, -2, field_name);
	lua_pop(L, 1);
	return 0;
}

int lunar_runscript(lua_State *L, const char* path, int args, int rets) {
	if (luaL_loadfile(L, path) != LUA_OK) {
		return luaL_error(L, "Error loading %s: %s", path, lua_tostring(L, -1));
	}
	if (lua_pcall(L, args, rets, 0) != LUA_OK) {
		return luaL_error(L, "Error calling %s: %s", path, lua_tostring(L, -1));
	}
}

void lunar_openlibs(lua_State *L) {
	luaL_openlibs(L);
	const luaL_Reg *lib;
	for (lib = lunar_loadedlibs; lib->func; lib++) {
		luaL_requiref(L, lib->name, lib->func, 1);
		lua_pop(L, 1);
	}
}

lua_State* lunar_newstate() {
	lua_State *L = luaL_newstate();
	lunar_openlibs(L);
	lunar_append_package_path(L, ";/lib/?.so", 1);
	lunar_append_package_path(L, ";/src/scripts/?.lua", 0);
	return L;
}
