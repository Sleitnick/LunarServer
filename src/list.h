#ifndef __LUNAR_LIST__
#define __LUNAR_LIST__

#include <stddef.h>

#define LIST_MIN_SIZE 1
#define LIST_INDEX_NOT_FOUND -1

struct list;
typedef struct list list;

list *list_new();
void list_destroy(list *l);

void list_alloc(list *l, size_t len);
void list_add(list *l, void *item);
void list_insert(list *l, void *item, size_t index);
void *list_get(list *l, size_t index);
void list_remove(list *l, size_t index);
void list_fast_remove(list *l, size_t index);
void *list_pop(list *l);
size_t list_find_first_index(list *l, void *item);
size_t list_length(list *l);
void list_clear(list *l);

#endif