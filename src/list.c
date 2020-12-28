#include "list.h"
#include <stdlib.h>

struct list {
	size_t item_size;
	size_t length;
	size_t allocated;
	void **items;
};

list *list_new() {
	list *l;
	l = calloc(1, sizeof(*l));
	l->item_size = sizeof(void *);
	l->items = malloc(LIST_MIN_SIZE * l->item_size);
	l->allocated = LIST_MIN_SIZE;
	l->length = 0;
	return l;
}

void list_destroy(list *l) {
	if (l == NULL) {
		return;
	}
	free(l->items);
	free(l);
}

void list_realloc(list *l) {
	if (l == NULL) {
		return;
	}
	l->items = realloc(l->items, l->allocated * l->item_size);
}

void list_grow_if_needed(list *l) {
	if (l == NULL) {
		return;
	}
	if (l->length == l->allocated) {
		l->allocated <<= 1;
		if (l->allocated == 0) {
			l->allocated--;
		}
		list_realloc(l);
	}
}

void list_shrink_if_possible(list *l) {
	if (l == NULL || l->allocated <= LIST_MIN_SIZE) {
		return;
	}
	size_t try_alloc = l->allocated >> 1;
	if (try_alloc >= l->length) {
		l->allocated = try_alloc;
		list_realloc(l);
	}
}

void list_alloc(list *l, size_t len) {
	if (l == NULL || len <= l->allocated) {
		return;
	}
	while (l->allocated < len) {
		l->allocated <<= 1;
		if (l->allocated == 0) {
			l->allocated--;
			break;
		}
	}
	list_realloc(l);
}

void list_add(list *l, void *item) {
	if (l == NULL || item == NULL) {
		return;
	}
	list_grow_if_needed(l);
	l->items[l->length] = item;
	l->length++;
}

void list_insert(list *l, void *item, size_t index) {
	if (l == NULL || item == NULL || index < 0 || index > l->length) {
		return;
	}
	if (index == l->length) {
		list_add(l, item);
		return;
	}
	l->length++;
	list_grow_if_needed(l);
	size_t i;
	for (i = l->length; i < index; i--) {
		l->items[i] = l->items[i - 1];
	}
	l->items[index] = item;
}

void *list_get(list *l, size_t index) {
	return l->items[index];
}

void list_remove(list *l, size_t index) {
	if (l == NULL || index < 0 || index > (l->length - 1)) {
		return;
	}
	size_t i;
	l->length--;
	for (i = index; i < l->length ; i++) {
		l->items[i] = l->items[i + 1];
	}
	list_shrink_if_possible(l);
}

void list_fast_remove(list *l, size_t index) {
	if (l == NULL || index < 0 || index > (l->length - 1)) {
		return;
	}
	l->length--;
	void *last_item = l->items[l->length];
	void *item = l->items[index];
	l->items[index] = last_item;
	list_shrink_if_possible(l);
}

void *list_pop(list *l) {
	if (l == NULL || l->length == 0) {
		return NULL;
	}
	l->length--;
	void *item = l->items[l->length];
	list_shrink_if_possible(l);
	return item;
}

size_t list_find_first_index(list *l, void *item) {
	size_t i;
	for (i = 0; i < l->length; i++) {
		if (l->items[i] == item) {
			return i;
		}
	}
	return LIST_INDEX_NOT_FOUND;
}

size_t list_length(list *l) {
	if (l == NULL) {
		return 0;
	}
	return l->length;
}

void list_clear(list *l) {
	l->length = 0;
	l->items = realloc(l->items, LIST_MIN_SIZE * l->item_size);
	l->allocated = LIST_MIN_SIZE;
}