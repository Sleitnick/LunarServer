#include "json.h"
#include "stringbuilder.h"
#include "list.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

// -------------------------------------------------------------------------------
// PARSE

// UTF-8 processing adapted from: https://www.lua.org/source/5.4/lutf8lib.c.html
#if (UINT_MAX >> 30) >= 1
typedef unsigned int utfint;
#else
typedef unsigned long utfint;
#endif
#define JSON_MAXUNICODE 0x10FFFFu
#define JSON_MAXUTF 0x7FFFFFFFu
#define JSON_UTF8BUFFSZ 8
#define JSON_ISCONT(p) ((*(p) & 0xC0) == 0x80)

typedef enum json_token_type {
	Null, Bool, Str, Obj, Arr, Num
} json_token_type;

typedef struct json_token {
	const char* str;
	json_token_type type;
} json_token;

typedef struct codepoints_data {
	list *codepoints;
	size_t length;
	size_t index;
} codepoints_data;

json_token *json_create_token(const char* str, size_t str_len, json_token_type type) {
	json_token *jt;
	jt = malloc(sizeof(*jt));
	memcpy(&jt->str, str, str_len);
	return jt;
}

const char *json_utf8_decode(const char *s, utfint *val) {
	static const utfint limits[] = {~(utfint)0, 0x80, 0x800, 0x10000u, 0x200000u, 0x4000000u};
	unsigned int c = (unsigned char)s[0];
	utfint res = 0;
	if (c < 0x80) {
		res = c;
	} else {
		int count = 0;
		for (; c & 0x40; c <<= 1) {
			unsigned int cc = (unsigned char)s[++count];
			if ((cc & 0xC0) != 0x80) {
				return NULL;
			}
			res = (res << 6) | (cc & 0x3F);
		}
		res |= (utfint)(c & 0x7F) << (count * 5);
		if (count > 5 || res > JSON_MAXUTF || res < limits[count]) {
			return NULL;
		}
		s += count;
	}
	if (res > JSON_MAXUNICODE || (0xD800u <= res && res <= 0xDFFFu)) {
		return NULL;
	}
	if (val) {
		*val = res;
	}
	return (s + 1);
}

int json_utf8_esc(char *buff, unsigned long x) {
	int n = 1;
	if (x < 0x80) {
		buff[JSON_UTF8BUFFSZ - 1] = (char)x;
	} else {
		unsigned int mfb = 0x3f;
		do {
			buff[JSON_UTF8BUFFSZ - (n++)] = (char)(0x80 | (x & 0x3f));
			x >>= 6;
			mfb >>= 1;
		} while (x > mfb);
		buff[JSON_UTF8BUFFSZ - n] = (char)((~mfb << 1) | x);
	}
	return n;
}

const char *json_get_str_from_codepoint(utfint code, size_t *out_len) {
	char bf[JSON_UTF8BUFFSZ + 1];
	bf[JSON_UTF8BUFFSZ] = '\0';
	int len = json_utf8_esc(bf, code);
	const char *codepoint_str = (bf + JSON_UTF8BUFFSZ - len + 0);
	if (out_len != NULL) {
		*out_len = len;
	}
	return codepoint_str;
}

int json_cmp_codepoints_to_string(list *codepoints, int start, int len, const char *str) {
	int result;
	int i;
	string_builder *sb = sb_new();
	for (i = start; i < start + len; i++) {
		utfint c = *((utfint *)list_get(codepoints, i));
		size_t l;
		const char *s = json_get_str_from_codepoint(c, &l);
		sb_append(sb, s, l);
	}
	const char *res = sb_tostring(sb, NULL);
	sb_destroy(sb);
	result = strcmp(res, str);
	return result;
}

list *json_get_codepoints(lua_State *L, const char *str, size_t str_len) {
	list *codepoints = list_new();
	list_alloc(codepoints, str_len / 2);
	const char *se;
	se = (str + str_len);
	char buffer[100];
	while (str < se) {
		utfint code;
		str = json_utf8_decode(str, &code);
		if (str == NULL) {
			luaL_error(L, "Invalid UTF-8 code");
			return NULL;
		}
		utfint *c;
		c = malloc(sizeof(*c));
		*c = code;
		list_add(codepoints, (void *)c);
	}
	return codepoints;
}

void json_tokenize_object(list *tokens, codepoints_data *data) {

}

void json_tokenize_array(list *tokens, codepoints_data *data) {

}

void json_tokenize_string(list *tokens, codepoints_data *data) {

}

void json_tokenize_number(list *tokens, codepoints_data *data) {

}

void json_tokenize_value(lua_State *L, list *tokens, codepoints_data *data, int is_top) {
	size_t codepoints_len = data->length;
	size_t *codepoints_index = &data->index;
	while (*codepoints_index < codepoints_len) {
		utfint code = *((utfint *)list_get(data->codepoints, *codepoints_index));
		size_t len;
		const char *s = json_get_str_from_codepoint(code, &len);
		char c = s[0];
		if (is_top && isspace(c)) {
			*codepoints_index++;
		} else if (c == '{') {
			json_tokenize_object(tokens, data);
		} else if (c == '[') {
			json_tokenize_array(tokens, data);
		} else if (c == '"') {
			json_tokenize_string(tokens, data);
		} else if (c == '-' || isdigit(c)) {
			json_tokenize_number(tokens, data);
		} else if (c == 't' && json_cmp_codepoints_to_string(data->codepoints, *codepoints_index, 4, "true") == 0) {
			json_token *token = json_create_token("true", 4, Bool);
			list_add(tokens, (void *)token);
			*codepoints_index += 4;
		} else if (c == 'f' && json_cmp_codepoints_to_string(data->codepoints, *codepoints_index, 5, "false") == 0) {
			json_token *token = json_create_token("false", 5, Bool);
			list_add(tokens, (void *)token);
			*codepoints_index += 5;
		} else if (is_top) {
			luaL_error(L, "Unknown symbol \"%s\"", s);
			break;
		} else {
			break;
		}
	}
}

list *json_tokenize(lua_State *L, const char *str, size_t str_len) {
	list *codepoints = json_get_codepoints(L, str, str_len);
	size_t codepoints_len = list_length(codepoints);
	list *tokens = list_new();
	size_t i = 0;
	codepoints_data data;
	data.codepoints = codepoints;
	data.length = list_length(codepoints);
	data.index = 0;
	json_tokenize_value(L, tokens, &data, 1);
	// for (i = 0; i < codepoints_len; i++) {
	// 	utfint c = *((utfint *)list_get(codepoints, i));
	// 	size_t len;
	// 	const char *s = json_get_str_from_codepoint(c, &len);
	// 	json_tokenize_value(tokens, s, len, 1);
	// }
	list_destroy_all(codepoints);
	return tokens;
}

static int json_parse(lua_State *L) {
	size_t str_len;
	const char *str = luaL_checklstring(L, 1, &str_len);
	list *tokens = json_tokenize(L, str, str_len);
	if (tokens == NULL) {
		return 0;
	}
	// TODO: Parse tokens
	list_destroy_all(tokens);
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