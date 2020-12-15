#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include "lunar.h"

int main(int argc, char *argv[]) {

	if (argc < 2) {
		printf("Must pass a config file to lunarserver (e.g. lunarserver config.lua)\n");
		exit(1);
	}

	// Initialize Lua:
	lua_State *L = lunar_newstate();

	// Load config:
	lunar_runscript(L, argv[1], 0, 1);
	if (!lua_istable(L, -1)) {
		return luaL_error(L, "Config file must return a table; got %s\n", lua_typename(L, lua_type(L, -1)));
	}

	// Load runtime:
	lunar_runscript(L, "/src/scripts/internal_runtime.lua", 0, 1);

	// Call runtime:
	lua_pushvalue(L, -2); // Config
	if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
		return luaL_error(L, "Runtime error: %s", lua_tostring(L, -1));
	}

	return 0;

}