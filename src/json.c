#include "json.h"
#include "stringbuilder.h"
#include "list.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// -------------------------------------------------------------------------------
// PARSE

static int json_parse(lua_State *L) {
	// Do the thing
	return 1;
}

// END PARSE
// -------------------------------------------------------------------------------
// STRINGIFY

static const char json_lua_tbl_map_key = 't';

const char *json_str_rep(char *original, char *replace, char *replace_with) {
	char *result;
	char *insert;
	char *tmp;
	int len_rep;
	int len_with;
	int len_front;
	int count;
	if (!original || !replace) {
		return NULL;
	}
	len_rep = strlen(replace);
	if (len_rep == 0) {
		return NULL;
	}
	if (!replace_with) {
		replace_with = "";
	}
	len_with = strlen(replace_with);
	insert = original;
	for (count = 0; tmp = strstr(insert, replace); ++count) {
		insert = (tmp + len_rep);
	}
	tmp = result = malloc(strlen(original) + (len_with - len_rep) * count + 1);
	if (!result) {
		return NULL;
	}
	while (count--) {
		insert = strstr(original, replace);
		len_front = (insert - original);
		tmp = strncpy(tmp, original, len_front) + len_front;
		tmp = strcpy(tmp, replace_with) + len_with;
		original += (len_front + len_rep);
	}
	strcpy(tmp, original);
	return result;
}

const char* json_to_json_string(lua_State *L, int index) {
	char *str = lua_tostring(L, index);
	lua_Unsigned str_len = lua_rawlen(L, index);
	char *result = json_str_rep(str, "\"", "\\");
	size_t result_len = strlen(result) + 3;
	char *buffer;
	buffer = (char *)malloc(result_len * sizeof(char));
	snprintf(buffer, result_len, "\"%s\"", result);
	free(result);
	return buffer;
}

void json_table_dict_to_json(lua_State *L, string_builder *sb) {
	lua_pushnil(L);
	if (lua_next(L, -2) == 0) {
		sb_append_str(sb, "[]");
		return;
	}
	lua_pop(L, 2);
	sb_append_char(sb, '{');
	lua_pushnil(L);
	int first = 1;
	while (lua_next(L, -2) != 0) {
		char *key = json_to_json_string(L, -2);
		if (first) {
			first = 0;
		} else {
			sb_append_char(sb, ',');
		}
		sb_append_str(sb, key);
		sb_append_char(sb, ':');
		json_value_to_json(L, sb);
		lua_pop(L, 1);
	}
	sb_append_char(sb, '}');
}

void json_table_array_to_json(lua_State *L, string_builder *sb) {
	lua_Unsigned tbl_len = lua_rawlen(L, -1);
	int i;
	sb_append_char(sb, '[');
	for (i = 0; i < tbl_len; i++) {
		lua_rawgeti(L, -1, i + 1);
		if (i > 0) {
			sb_append_char(sb, ',');
		}
		json_value_to_json(L, sb);
		lua_pop(L, 1);
	}
	sb_append_char(sb, ']');
}

void json_table_to_json(lua_State *L, string_builder *sb) {
	lua_Unsigned tbl_len = lua_rawlen(L, -1);
	if (tbl_len == 0) {
		json_table_dict_to_json(L, sb);
	} else {
		json_table_array_to_json(L, sb);
	}
}

int json_has_table_or_add(lua_State *L) {
	lua_pushlightuserdata(L, (void *)&json_lua_tbl_map_key);
	lua_gettable(L, LUA_REGISTRYINDEX);
	lua_pushvalue(L, -2);
	lua_gettable(L, -2);
	if (lua_isnil(L, -1)) {
		lua_pushvalue(L, -3);
		lua_pushboolean(L, 1);
		lua_settable(L, -4);
		lua_pop(L, 2);
		return 0;
	} else {
		lua_pop(L, 2);
		return 1;
	}
}

void json_value_to_json(lua_State *L, string_builder *sb) {
	int type = lua_type(L, -1);
	if (type == LUA_TSTRING) {
		const *str = json_to_json_string(L, -1);
		sb_append_str(sb, str);
	} else if (type == LUA_TNUMBER) {
		const *str = lua_tostring(L, -1);
		sb_append_str(sb, str);
	} else if (type == LUA_TNIL) {
		sb_append_str(sb, "nil");
	} else if (type == LUA_TBOOLEAN) {
		int b = lua_toboolean(L, -1);
		sb_append_str(sb, (b ? "true" : "false"));
	} else if (type == LUA_TTABLE) {
		if (json_has_table_or_add(L)) {
			luaL_error(L, "JSON Stringify does not support cyclical tables");
		} else {
			json_table_to_json(L, sb);
		}
	} else {
		luaL_error(L, "JSON Stringify does not support type %s", lua_typename(L, type));
	}
}

static int json_stringify(lua_State *L) {
	string_builder *sb = sb_new();
	lua_pushlightuserdata(L, (void *)&json_lua_tbl_map_key);
	lua_newtable(L);
	lua_settable(L, LUA_REGISTRYINDEX);
	json_value_to_json(L, sb);
	char *sb_out = sb_tostring(sb, NULL);
	lua_pushstring(L, sb_out);
	free(sb_out);
	sb_destroy(sb);
	lua_pushlightuserdata(L, (void *)&json_lua_tbl_map_key);
	lua_pushnil(L);
	lua_settable(L, LUA_REGISTRYINDEX);
	return 1;
}

// END STRINGIFY
// -------------------------------------------------------------------------------

static const luaL_Reg jsonlib[] = {
	{"stringify", json_stringify},
	{"parse", json_parse},
	{NULL, NULL}
};

LUALIB_API int luaopen_json(lua_State *L) {
	luaL_newlib(L, jsonlib);
	return 1;
}