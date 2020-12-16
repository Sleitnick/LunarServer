#ifndef __LUNARSERVER_STATEPOOL__
#define __LUNARSERVER_STATEPOOL__

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include "lunar.h"

#define STATEPOOL_MAX_POOL 100

#define STATEPOOL_MAX_LIFETIME_SECONDS 5
#define MIN_LIFETIME_CHECK_INTERVAL_SECONDS 1

#define STATEPOOL_OK 0
#define STATEPOOL_ERROR_FAILED_TO_INIT_MUTEX 1

lua_State* statepool_get_state(void);
void statepool_pool_state(lua_State *L);
void statepool_check_states_for_removal(void);
int statepool_init(void);
void statepool_close_states(void);

#endif