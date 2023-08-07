**WARNING**: This was built using BinaryBuilderBase#sf/glibc_v2.17: https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/318

This is a lazy approach to a building neovim. A better approach would be to use LibUV_jll, but I've struggled to get that to work.

This probably shouldn't be merged until this PR is merged, upgrading glibc
https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/318

Neovim's build process automatically builds all of its dependencies, including LibUV. My first attempt was to exclude LibUV, and instead rely on LibUV_jll. I was able to get neovim to build with LibUV_jll, but haven't been able to get neovim's Lua dependency "luv", libuv bindings from Lua, to use the shared libuv dependency, as it still builds its own libuv dep and fails; libuv doesn't build with glibc 2.12.

Thus, building with glibc 2.17 does work, albeit by rebuilding LibUV instead of using a shared instance.

`luv` [docs](https://github.com/luvit/luv#linking-with-shared-libuv) say it can be built with a shared libuv like so:

`WITH_SHARED_LIBUV=ON make`

So that would be another way to do this.




The issue


I originally attempted 
https://github.com/neovim/neovim/archive/refs/tags/v0.9.1.tar.gz
https://github.com/neovim/neovim/archive/refs/tags/v0.8.3.tar.gz

deps:
- Libtool

cd neovim.vxxx
mkdir .deps
cd .deps
export LDFLAGS="-L${libdir}"
cmake ../cmake.deps/ -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
# error with libuv
sed -i 's/CLOCK_BOOTTIME/CLOCK_MONOTONIC/g' build/src/libuv/src/unix/linux.c
sed -i 's/CLOCK_BOOTTIME/CLOCK_MONOTONIC/g' build/src/libuv/src/unix/linux-core.c

export CFLAGS="-I${includedir}"
cmake ../cmake.deps/ -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DUSE_BUNDLED_LIBUV=OFF
cmake ../cmake.deps/ -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
sed -i 's/CLOCK_BOOTTIME/CLOCK_MONOTONIC/g' build/src/libuv/src/unix/linux.c
make

apk add gettext-tiny-dev

cd ../
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make

sed -i 's/#include <stdlib.h>/#include <linux\/stdlib.h>/g' build/src/libuv/src/unix/udp.c

Add deps
- LibUV
- Lua#5.1

# install luarocks
wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
# install LUA 5.1

tar zxpf luarocks-3.8.0.tar.gz
cd luarocks-3.8.0

./configure --with-lua-include=/workspace/destdir/include
./configure --with-lua-include=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/local/include
make
make install



luarocks build mpack
luarocks build lpeg
luarocks build inspect
luarocks build luabitop
luarocks install luv

cmake ../cmake.deps/ -DUSE_BUNDLED_LIBUV=off -DUSE_BUNDLED_LUV=off -DLIBUV_INCLUDE_DIR=/workspace/destdir/include -DLIBUV_LIBRARIES=${libdir}

cmake .. -DUSE_BUNDLED_LIBUV=off -DUSE_BUNDLED_LUV=off -DLIBUV_INCLUDE_DIR=/workspace/destdir/include -DLIBUV_LIBRARY=${libdir}

cmake ../cmake.deps/ -DUSE_BUNDLED_LIBUV=off -DLIBUV_INCLUDE_DIR=/workspace/destdir/include -DLIBUV_LIBRARIES=${libdir}
make LIBUV_LIBRARIES=${libdir} LIBUV_INCLUDE_DIR=/workspace/destdir/include

cmake ../cmake.deps -DUSE_BUNDLED_LIBUV=OFF -DLIBUV_INCLUDE_DIR=${libdir}

cmake ../cmake.deps -DUSE_BUNDLED_LIBUV=OFF -DLIBUV_LIBRARY=${libdir} -DCMAKE_PREFIX_PATH=${$libdir}

../neovim-0.9.1/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DUSE_BUNDLED_LIBUV=OFF 

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DUSE_BUNDLED_LIBUV=OFF -DCURRENT_LUA_PRG=/workspace/destdir/lua -DUSE_BUNDLED_LPEG=OFF -DUSE_BUNDLED_LUA=off -DLUA_PRG=/workspace/destdir/lua

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DUSE_BUNDLED_LIBUV=OFF -DCURRENT_LUA_PRG=/workspace/destdir/lua

