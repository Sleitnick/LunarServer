#ifndef __LUNARSERVER_STRINGBUILDER__
#define __LUNARSERVER_STRINGBUILDER__

#include <stddef.h>

#define SB_MIN_SIZE 32
#define SB_CALC_STR_SIZE 0

struct string_builder;
typedef struct string_builder string_builder;

string_builder *sb_new(void);
void sb_destroy(string_builder *sb);

void sb_append(string_builder *sb, const char *str, size_t len);
void sb_append_str(string_builder *sb, const char *str);
void sb_append_char(string_builder *sb, char c);
void sb_append_newline(string_builder *sb);

void sb_clear(string_builder *sb);
char *sb_tostring(string_builder *sb, size_t *len_out);

#endif