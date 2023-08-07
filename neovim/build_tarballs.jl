# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "neovim"
version = v"0.9.1"

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://github.com/neovim/neovim/archive/refs/tags/v$(version).tar.gz", "8db17c2a1f4776dcda00e59489ea0d98ba82f7d1a8ea03281d640e58d8a3a00e")
    # 0.8.2
    GitSource("https://github.com/neovim/neovim.git", "1fa917f9a1585e3b87d41edaf74415505d1bceac")
]

dependencies = [
    Dependency("Gettext_jll"),

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd neovim/
mkdir .deps
cd .deps/
cmake ../cmake.deps/ -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make || true
cmake ../cmake.deps/ -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make

cd ..
apk add gettext-tiny-dev
mkdir build
cd build/
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("powerpc64le", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("x86_64", "macos"; ),
    # Platform("aarch64", "macos"; ),
    # Platform("x86_64", "freebsd"; ),
    # Platform("i686", "windows"; ),
    # Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("nvim", :nvim)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
