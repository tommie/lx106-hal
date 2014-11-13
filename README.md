Hardware Abstraction Library for Xtensa LX106
=============================================
2014-11-13

This is the libhal part of the SDK.


Requirements
------------
The following things are assumed to be true before you start:

- You have GNU autotools installed.
- You have a cross-compiler in `~/x-tools/xtensa-lx106-elf/bin`.
- The programs in `~/x-tools/xtensa-lx106-elf/bin` are all prefixed with `xtensa-lx106-elf-`,
  so adding the directory to `$PATH` will not interfere with other programs.


Building
--------
To build, install a cross-compiler for Xtensa LX106, e.g. using crosstool-NG. Then run

    autoreconf -i
    PATH=~/x-tools/xtensa-lx106-elf/bin:$PATH
    mkdir build
    cd build
    ../configure --host=xtensa-lx106-elf
    make


License
-------
Distributed under the MIT license. See the LICENSE file.
