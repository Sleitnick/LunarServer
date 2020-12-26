#include "stringbuilder.h"
#include <stdlib.h>
#include <string.h>

struct string_builder {
	char *str;
	size_t length;
	size_t allocated;
};

string_builder *sb_new() {
	string_builder *sb;
	sb = calloc(1, sizeof(*sb));
	sb->str = malloc(SB_MIN_SIZE);
	sb->length = 0;
	sb->allocated = SB_MIN_SIZE;
	*sb->str = '\0';
	return sb;
}

void sb_destroy(string_builder *sb) {
	if (sb == NULL) {
		return;
	}
	free(sb->str);
	free(sb);
}

void sb_truncate(string_builder *sb, size_t new_len) {
	if (sb == NULL || new_len >= sb->length) {
		return;
	}
	sb->length = new_len;
	sb->str[sb->length] = '\0';
}

void sb_clear(string_builder *sb) {
	if (sb == NULL) {
		return;
	}
	sb_truncate(sb, 0);
}

void sb_ensure_space(string_builder *sb, size_t add_len) {
	if (sb == NULL || add_len == 0 || sb->allocated >= (sb->length + add_len + 1)) {
		return;
	}
	while (sb->allocated < (sb->length + add_len + 1)) {
		sb->allocated <<= 1;
		if (sb->allocated == 0) {
			sb->allocated--;
		}
	}
	sb->str = realloc(sb->str, sb->allocated);
}

void sb_append(string_builder *sb, const char* str, size_t len) {
	if (sb == NULL || str == NULL || *str == '\0') {
		return;
	}
	if (len == 0) {
		len = strlen(str);
	}
	sb_ensure_space(sb, len);
	memmove(sb->str + sb->length, str, len);
	sb->length += len;
	sb->str[sb->length] = '\0';
}

void sb_append_str(string_builder *sb, const char* str) {
	sb_append(sb, str, SB_CALC_STR_SIZE);
}

void sb_append_char(string_builder *sb, char c) {
	if (sb == NULL) {
		return;
	}
	sb_ensure_space(sb, 1);
	sb->str[sb->length] = c;
	sb->length++;
	sb->str[sb->length] = '\0';
}

void sb_append_newline(string_builder *sb) {
	sb_append_str(sb, "\n");
}

char *sb_tostring(string_builder *sb, size_t *len_out) {
	if (sb == NULL) {
		return NULL;
	}
	char *out;
	if (len_out != NULL) {
		*len_out = sb->length;
	}
	out = malloc(sb->length + 1);
	memcpy(out, sb->str, sb->length + 1);
	return out;
}