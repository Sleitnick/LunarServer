#!/bin/bash

echo "Test"

if [ ! -d /bin/lua/ ]; then
	cd /tmp
	curl -R -O http://www.lua.org/ftp/lua-5.4.2.tar.gz
	tar zxf lua-5.4.2.tar.gz
	cd lua-5.4.2
	make all test
	cd ..
	mv lua-5.4.2/ /bin/lua/
fi
