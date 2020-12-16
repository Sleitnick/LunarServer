#include "statepool.h"

typedef struct statepool_item {
	lua_State *L;
	clock_t last_used;
} statepool_item_t;

int statepool_num_items = 0;
statepool_item_t *statepool_items;

pthread_mutex_t statepool_lock;

time_t last_lifetime_check;

void _statepool_resize() {
	statepool_items = (statepool_item_t*)realloc(statepool_items, sizeof(statepool_item_t) * statepool_num_items);
}

lua_State* _statepool_pop_from_pool() {
	statepool_item_t *top_item = &statepool_items[statepool_num_items - 1];
	lua_State *L = top_item->L;
	statepool_num_items--;
	_statepool_resize();
	return L;
}

lua_State* statepool_get_state() {
	lua_State *L;
	pthread_mutex_lock(&statepool_lock);
	if (statepool_num_items == 0) {
		L = lunar_newstate();
		luaL_loadfile(L, "/src/scripts/internal_handler.lua");
		lua_call(L, 0, 1);
	} else {
		L = _statepool_pop_from_pool();
	}
	pthread_mutex_unlock(&statepool_lock);
	return L;
}

void statepool_pool_state(lua_State *L) {
	pthread_mutex_lock(&statepool_lock);
	if (statepool_num_items < STATEPOOL_MAX_POOL) {
		statepool_num_items++;
		_statepool_resize();
		statepool_item_t item;
		item.L = L;
		item.last_used = time(NULL);
		// Shift all up and insert at beginning:
		int i;
		for (i = (statepool_num_items - 1); i > 0; i--) {
			statepool_items[i] = statepool_items[i - 1];
		}
		statepool_items[0] = item;
	} else {
		lua_close(L);
	}
	pthread_mutex_unlock(&statepool_lock);
}

void statepool_check_states_for_removal() {
	pthread_mutex_lock(&statepool_lock);
	time_t now = time(NULL);
	time_t since_last = (now - last_lifetime_check);
	if (since_last > MIN_LIFETIME_CHECK_INTERVAL_SECONDS) {
		last_lifetime_check = now;
		int i;
		for (i = 0; i < statepool_num_items; i++) {
			statepool_item_t *item = &statepool_items[i];
			time_t lifetime = (now - item->last_used);
			if (lifetime > STATEPOOL_MAX_LIFETIME_SECONDS) {
				break;
			}
		}
		if (i >= 0) {
			int j = 0;
			for (j = i; j < statepool_num_items; j++) {
				statepool_item_t *old_item = &statepool_items[j];
				lua_close(old_item->L);
			}
			statepool_num_items = i;
			_statepool_resize();
		}
	}
	pthread_mutex_unlock(&statepool_lock);
}

int statepool_init() {
	statepool_items = (statepool_item_t*)calloc(0, sizeof(statepool_item_t));
	last_lifetime_check = time(NULL);
	if (pthread_mutex_init(&statepool_lock, NULL) != 0) {
		return STATEPOOL_ERROR_FAILED_TO_INIT_MUTEX;
	}
	return STATEPOOL_OK;
}

void statepool_close_states() {
	pthread_mutex_lock(&statepool_lock);
	int i;
	for (i = 0; i < statepool_num_items; i++) {
		statepool_item_t *item = &statepool_items[i];
		lua_close(item->L);
	}
	free(statepool_items);
	pthread_mutex_unlock(&statepool_lock);
	pthread_mutex_destroy(&statepool_lock);
}
