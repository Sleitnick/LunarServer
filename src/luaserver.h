#include <lualib.h>

#define LUASERVER_MT "luaserver_mt"

static int luaserver_new(lua_State *L);
static int luaserver_listen(lua_State *L);
LUALIB_API int luaopen_luaserver(lua_State *L);