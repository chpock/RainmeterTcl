# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

NAME = RainmeterTcl

DLLNAME = $(NAME).dll

DEBUG ?= 0
AMD64 ?= 1

CC     = $(_ODB_)-w64-mingw32-gcc
RC     = $(_ODB_)-w64-mingw32-windres
AR     = $(_ODB_)-w64-mingw32-ar
RUNLIB = $(_ODB_)-w64-mingw32-ranlib
CPP    = $(CC)

ifeq ($(DEBUG),1)
_ODN_ = debug
else
_ODN_ = final
endif

ifeq ($(AMD64),1)
_ODB_         = x86_64
CFLAGS        += -m64 -D_AMD64_
TCLCONFPARAM  = --enable-64bit
LDFLAGS       += -m64
RCFLAGS       += -F pe-x86-64
RMLIBS        = $(BLDDIR)/src/rainmeter-plugin-sdk/API/x64/Rainmeter.lib
else
_ODB_         = i686
CFLAGS        += -m32
TCLCONFPARAM  = --disable-64bit
LDFLAGS       += -m32
RCFLAGS       += -F pe-i386
RMLIBS        = $(BLDDIR)/src/rainmeter-plugin-sdk/API/x32/Rainmeter.lib
endif

BLDDIR := $(shell pwd)

TCLVER       = 86
TCLVERX      = 8.6
TCLDIR       = $(BLDDIR)/src/tcl
TCLLIBDIR    = $(BLDDIR)/src/tcllib
TCLSH        = $(TCLDIR)/win/tclsh$(TCLVER).exe
TCLCONFFLAGS = CC="$(CC)" AR="$(AR)" RC="$(RC)" RUNLIB="$(RUNLIB)"
TCLLIBS      = $(TCLDIR)/win/libtcl$(TCLVER).$(LIBEXT) $(TCLDIR)/win/libtclstub$(TCLVER).$(LIBEXT)

TKDIR        = $(BLDDIR)/src/tk
TKLIBDIR     = $(BLDDIR)/src/tklib
TKLIBS       = $(TKDIR)/win/libtk$(TCLVER).$(LIBEXT) $(TKDIR)/win/libtkstub$(TCLVER).$(LIBEXT)

TCLVFSDIR    = $(BLDDIR)/src/tcl-vfs
TCLVFSLIBS   = $(TCLVFSDIR)/vfs142.$(LIBEXT)

METAKITDIR   = $(BLDDIR)/src/metakit
METAKITLIBS  = $(METAKITDIR)/Mk4tcl2498.$(LIBEXT)

TWAPIDIR     = $(BLDDIR)/src/twapi
TWAPILIBS    = $(TWAPIDIR)/libtwapi4212.$(LIBEXT)
ifeq ($(AMD64),1)
TWAPILIBS2   = $(TWAPIDIR)/dyncall/dyncall-0.9/lib/release_amd64/libdyncall_s.lib
else
TWAPILIBS2   = $(TWAPIDIR)/dyncall/dyncall-0.9/lib/release_x86/libdyncall_s.lib
endif

THREADDIR    = $(BLDDIR)/src/thread
THREADLIBS   = $(THREADDIR)/libthread2.9a1.$(LIBEXT)

OUTDIR = $(BLDDIR)/out.$(_ODN_).$(_ODB_)

OBJDIR = $(OUTDIR)/obj
INCLUDE = $(TCLDIR)/generic:$(TKDIR)/generic:$(TKDIR)/xlib
DLLFULLNAME = $(OUTDIR)/$(DLLNAME)
MAP = $(OUTDIR)/$(NAME).map
KIT = $(OUTDIR)/$(NAME).kit

EXEEXT		= .exe
OBJEXT		= o
LIBEXT          = a
SHLIB_LD_LIBS	= $(LIBS)
SHLIB_CFLAGS	=
SHLIB_SUFFIX	= .dll
LIBS            = -lrpcrt4 -lcrypt32 -luxtheme -lcredui -lmpr -lsetupapi -lpsapi -lsecur32 -lpdh -liphlpapi \
                  -lwintrust -lwtsapi32 -lnetapi32 -lkernel32 -luser32 -ladvapi32 -luserenv -lws2_32 -lgdi32 \
                  -lwinmm -lpowrprof -lversion -lwinspool -lcomdlg32 -limm32 -lcomctl32 -lshell32 -luuid -lole32 -loleaut32 \
                  -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic

# warning flags
#CFLAGS          += -Wall -Wwrite-strings -Wsign-compare -Wdeclaration-after-statement
CFLAGS          += -O2 -fomit-frame-pointer

CFLAGS          += -fno-rtti -fno-exceptions -DUNICODE -D_UNICODE -std=gnu++0x

ifeq ($(DEBUG),1)
CFLAGS        += -g
LDFLAGS       += -Wl,-Map=$(MAP)
TCLCONFPARAM  += --enable-symbols
else
LDFLAGS       += -s -Wl,--exclude-all-symbols
TCLCONFPARAM  += --disable-symbols
endif

TCLCONFPARAM += --enable-threads --disable-shared --enable-static

LINK_OBJS = $(OBJDIR)/$(NAME).$(OBJEXT) \
            $(RMLIBS) \
            $(THREADLIBS) \
            $(TWAPILIBS) \
            $(TWAPILIBS2) \
            $(TKLIBS) \
            $(TCLLIBS) \
            $(TCLVFSLIBS) \
            $(METAKITLIBS) \
            $(OBJDIR)/$(NAME).res.$(OBJEXT)

SETUP_NAME = setupvfs
SETUP_LINK_OBJS = $(OBJDIR)/$(SETUP_NAME).$(OBJEXT) \
                  $(TCLLIBS) \
                  $(TCLVFSLIBS) \
                  $(METAKITLIBS)
SETUP_SOURCES = $(SETUP_NAME).cpp
SETUP_EXE = $(OUTDIR)/$(SETUP_NAME).exe
SETUP_TCL = $(BLDDIR)/$(SETUP_NAME).tcl

VER_MAJOR = $(shell grep "define VER_MAJOR" version.hpp | grep -oE "[[:digit:]]+")
VER_MINOR = $(shell grep "define VER_MINOR" version.hpp | grep -oE "[[:digit:]]+")
VER_REVIS = $(shell grep "define VER_REVIS" version.hpp | grep -oE "[[:digit:]]+")
VER_BUILD = $(shell grep "define VER_BUILD" version.hpp | grep -oE "[[:digit:]]+")
VER_FULL  = $(VER_MAJOR).$(VER_MINOR).$(VER_REVIS).$(VER_BUILD)

VER_BUILD_INCR = $(shell expr 1 + `grep "define VER_BUILD" version.hpp | grep -oE "[[:digit:]]+"`)

SOURCES = RainmeterTcl.cpp \
          version.hpp \
          Makefile

# $(TCLLIBDIR)/modules/uev $(TCLLIBDIR)/modules/log
ADDONS = src/procarg \
	 $(TWAPIDIR)/twapi/tcl $(TWAPIDIR)/pkgIndex.tcl $(TWAPIDIR)/twapi_entry.tcl \
         addons/boot.tcl addons/rm/rm.tcl addons/rm/pkgIndex.tcl

all: build

$(OBJDIR)/$(SETUP_NAME).$(OBJEXT): $(SETUP_SOURCES) $(TCLDIR)/generic/tcl.h
	CPATH=$(INCLUDE) $(CPP) $(CFLAGS) -c -o $@ $<

$(SETUP_EXE): $(SETUP_LINK_OBJS)
	$(CC) $(LDFLAGS) -o $@ -pipe -static-libgcc $(SETUP_LINK_OBJS) $(SHLIB_LD_LIBS)

$(KIT): $(SETUP_EXE) $(SETUP_TCL) $(ADDONS)
	tools/nagelfar_sh.exe -exitcode -s syntaxdb86.tcl addons\rm\rm.tcl src\procarg\procarg.tcl
	$(SETUP_EXE) $(shell cygpath -w $(BLDDIR)/$(SETUP_NAME).tcl) \
	             $(shell cygpath -w $(KIT)) \
	             --tcl=$(shell cygpath -w $(TCLDIR)) \
	             --tk=$(shell cygpath -w $(TKDIR))

$(OBJDIR)/$(NAME).$(OBJEXT): $(SOURCES) src/rainmeter-plugin-sdk/API/RainmeterAPI.h $(TCLDIR)/generic/tcl.h $(TKDIR)/generic/tk.h
	sed -i 's/define VER_BUILD .*/define VER_BUILD $(VER_BUILD_INCR)/' version.hpp
	CPATH=$(INCLUDE) $(CPP) $(CFLAGS) -c -o $@ $<

$(OBJDIR)/$(NAME).res.$(OBJEXT): $(NAME).rc version.hpp
	$(RC) $(RCFLAGS) -o $@ --include "include" $<

$(DLLFULLNAME).base: $(LINK_OBJS)
	@#@rm -f "$@"
	@#${SHLIB_LD} $(CC) $(LDFLAGS) -o $@ -pipe -static-libgcc -municode -Wl,--kill-at $(LINK_OBJS) $(SHLIB_LD_LIBS)
	$(CC) -shared $(LDFLAGS) -o "$@" -pipe -static-libgcc -municode $(LINK_OBJS) $(SHLIB_LD_LIBS)

$(DLLFULLNAME): $(DLLFULLNAME).base $(KIT)
	rm -f "$@"
ifeq ($(DEBUG),1)
	tools/cv2pdb $(shell cygpath -w $(DLLFULLNAME).base) $(shell cygpath -w $@)
	cat $(KIT) >> "$@"
else
	cat $^ >> "$@"
endif

$(OBJDIR): $(OUTDIR)
	mkdir -p "$(OBJDIR)"

$(OUTDIR):
	mkdir -p "$(OUTDIR)"

$(OUTDIR)/lib: $(OUTDIR)
	mkdir -p "$(OUTDIR)/lib"

$(OUTDIR)/lib/tcl$(TCLVERX): $(OUTDIR)/lib $(OUTDIR)/lib/logger $(OUTDIR)/lib/uev
	mkdir -p "$@"
	cd "$(TCLDIR)/library" && cp -r * "$@"

$(TCLSH) $(TCLLIBS):
	cd $(TCLDIR)/win && $(TCLCONFFLAGS) ./configure  $(TCLCONFPARAM)
	make -C $(TCLDIR)/win all

$(TKLIBS): $(TCLLIBS)
	cd $(TKDIR)/win && $(TCLCONFFLAGS) ./configure $(TCLCONFPARAM)
	make -C $(TKDIR)/win all

$(TCLVFSLIBS): $(TCLLIBS)
	cd $(TCLVFSDIR) && $(TCLCONFFLAGS) ./configure --with-tcl=$(TCLDIR)/win $(TCLCONFPARAM)
	make -C $(TCLVFSDIR) all

$(METAKITLIBS): $(TCLLIBS)
	cd $(METAKITDIR) && $(TCLCONFFLAGS) ./tcl/configure --with-tcl=$(TCLDIR)/win $(TCLCONFPARAM)
	make -C $(METAKITDIR) all

$(TWAPILIBS): $(TCLLIBS)
	cd $(TWAPIDIR) && $(TCLCONFFLAGS) CC="$(CC) -DTWAPI_STATIC_BUILD=1" ./configure --with-tcl=$(TCLDIR)/win $(TCLCONFPARAM)
	make -C $(TWAPIDIR) all

$(THREADLIBS): $(TCLLIBS)
	# workaround for configure's bug
	mkdir -p $(THREADDIR)/tclconfig
	touch $(THREADDIR)/tclconfig/install.sh
	cd $(THREADDIR) && $(TCLCONFFLAGS) ./configure --with-tcl=$(TCLDIR)/win $(TCLCONFPARAM)
	make -C $(THREADDIR) all

build: $(OBJDIR) $(DLLFULLNAME)
	@echo Build DONE.

clean:
	rm -rf out.*/*
	make -C $(TCLDIR)/win clean || echo "Nothing to do"
	make -C $(TKDIR)/win clean || echo "Nothing to do"
	make -C $(TWAPIDIR) clean
	make -C $(METAKITDIR) clean
	make -C $(TCLVFSDIR) clean
	make -C $(TWAPIDIR) clean
	make -C $(THREADDIR) clean
