#include "server.h"

volatile int server_fd = 0;

pthread_mutex_t lock;

typedef struct pthread_arg_t {
	int new_socket_fd;
	struct sockaddr_in client_address;
	const char* handler;
} pthread_arg_t;

void sigint() {
	if (server_fd != 0) {
		printf("\nStopping server\n");
		close(server_fd);
	}
	statepool_close_states();
	pthread_mutex_destroy(&lock);
	exit(0);
}

static const struct luaL_Reg luaserver_funcs[] = {
	{"new", luaserver_new},
	{NULL, NULL}
};

static const struct luaL_Reg luaserver_meta[] = {
	{"Listen", luaserver_listen},
	{NULL, NULL}
};


static int luaserver_new(lua_State *L) {
	lua_newtable(L);
	lua_pushvalue(L, -2);
	lua_setfield(L, -2, "_handler");
	lua_pushboolean(L, 0);
	lua_setfield(L, -2, "_listening");
	luaL_setmetatable(L, LUASERVER_MT);
	return 1;
}

// Handle each request:
void *pthread_routine(void *arg) {

	#if DEBUG_LOG_REQUEST_TIME == 1
	clock_t start, end;
	double cpu_time_used;
	start = clock();
	#endif

	pthread_arg_t *pthread_arg = (pthread_arg_t *)arg;
	int new_socket_fd = pthread_arg->new_socket_fd;
	const char* handler = pthread_arg->handler;
	free(arg);
	char buffer[30000] = {0};
	read(new_socket_fd, buffer, 30000);

	// Drop empty requests:
	if (strlen(buffer) == 0) {
		close(new_socket_fd);
		return NULL;
	}

	// Lua:
	lua_State *L = statepool_get_state();
	lua_pushvalue(L, -1); // Function handler from script
	lua_pushstring(L, handler);
	lua_pushstring(L, buffer);
	lua_call(L, 2, 2);
	int result_size = lua_tointeger(L, -1);
	const char* result = lua_tostring(L, -2);
	
	// Write response and then repool Lua:
	write(new_socket_fd, result, result_size);
	lua_pop(L, 2);
	statepool_pool_state(L);

	#if DEBUG_LOG_REQUEST_TIME == 1
	end = clock();
	cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
	printf("Request took %.2fms to execute \n", cpu_time_used * 1000); 
	#endif

	close(new_socket_fd);
	return NULL;
	
}

static int luaserver_listen(lua_State *L) {
	int args = lua_gettop(L);
	if (args != 3) {
		luaL_error(L, "Expected 2 arguments");
		return 0;
	}
	lua_Integer port = luaL_checkinteger(L, -2);
	if (port < 1 || port > 65535) {
		luaL_error(L, "Port must be within range [1-65535]");
		return 0;
	}
	lua_getfield(L, -3, "_listening");
	int listening = lua_toboolean(L, -1);
	lua_pop(L, 1);
	if (listening) {
		luaL_error(L, "Server already listening");
		return 0;
	}
	lua_pushboolean(L, 1);
	lua_setfield(L, -4, "_listening");
	lua_pushvalue(L, -1);
	lua_call(L, 0, 0);
	lua_getfield(L, -6, "_handler");
	const char* handler = lua_tostring(L, -1);

	// Creating socket file descriptor
	int new_socket;
	struct sockaddr_in address;
	pthread_attr_t pthread_attr;
	pthread_arg_t *pthread_arg;
	pthread_t pthread;
	socklen_t client_address_len;

	if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
		luaL_error(L, "Failed to create socket");
		return 0;
	}
	int option = 1;
	setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &option, sizeof(option));

	signal(SIGINT, sigint);

	address.sin_family = AF_INET;
	address.sin_addr.s_addr = INADDR_ANY;
	address.sin_port = htons(port);
	memset(address.sin_zero, '\0', sizeof address.sin_zero);

	if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
		close(server_fd);
		luaL_error(L, "Failed to bind socket");
		return 0;
	}

	if (listen(server_fd, 10) < 0) {
		close(server_fd);
		luaL_error(L, "Failed to listen");
		return 0;
	}

	if (pthread_attr_init(&pthread_attr) != 0) {
		close(server_fd);
		luaL_error(L, "pthread_attr_init");
		return 0;
	}
	if (pthread_attr_setdetachstate(&pthread_attr, PTHREAD_CREATE_DETACHED) != 0) {
		close(server_fd);
		luaL_error(L, "pthread_attr_setdetachstate");
		return 0;
	}

	if (pthread_mutex_init(&lock, NULL) != 0) {
		close(server_fd);
		luaL_error(L, "pthread_mutex_init");
		return 0;
	}

	if (statepool_init() != STATEPOOL_OK) {
		close(server_fd);
		luaL_error(L, "statepool_init");
		return 0;
	}

	while(1) {
		pthread_arg = (pthread_arg_t *)malloc(sizeof(*pthread_arg));
		if (!pthread_arg) {
			perror("pthread_arg");
			continue;
		}
		client_address_len = sizeof(pthread_arg->client_address);
		if ((new_socket = accept(server_fd, (struct sockaddr *)&address, &client_address_len)) < 0) {
			perror("accept");
			close(server_fd);
			free(pthread_arg);
			continue;
		}
		pthread_arg->new_socket_fd = new_socket;
		pthread_arg->handler = handler;
		if (pthread_create(&pthread, &pthread_attr, pthread_routine, (void *)pthread_arg) != 0) {
			perror("pthread_create");
			free(pthread_arg);
			continue;
		}
		statepool_check_states_for_removal();
	}

	return 0;

}


LUALIB_API int luaopen_luaserver(lua_State *L) {
	luaL_newmetatable(L, LUASERVER_MT);
	lua_pushvalue(L, -1);
	lua_setfield(L, -1, "__index");
	luaL_setfuncs(L, luaserver_meta, 0);
	lua_pop(L, 1);
	luaL_newlib(L, luaserver_funcs);
	return 1;
}
