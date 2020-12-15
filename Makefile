all: build

run: build
	#docker run --rm -it --mount 'type=bind,src=${PWD},dst=/app' -p 8080:8080 lunarserver /bin/lua/src/lua /app/runtime.lua
	docker run --rm -it --mount 'type=bind,src=${PWD}/apptest,dst=/app' -p 8080:8080 lunarserver lunarserver /app/config.lua

build: lua
	docker build -t lunarserver -f DockerfileLunarServer .

lua:
	docker build -t lua54 -f Dockerfile .

clean:
	rm -f luaserver.so
