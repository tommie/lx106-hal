# Copyright (c) 2014-2015 Tommie Gannert
#
# See the LICENSE file.
#

include_xtensadir = $(includedir)/xtensa
include_xtensa_HEADERS = \
	include/xtensa/cacheasm.h \
	include/xtensa/coreasm.h \
	include/xtensa/corebits.h \
	include/xtensa/hal.h \
	include/xtensa/xtensa-xer.h

include_xtensa_configdir = $(include_xtensadir)/config
include_xtensa_config_HEADERS = \
	include/xtensa/config/core.h \
	include/xtensa/config/core-isa.h \
	include/xtensa/config/core-matmap.h \
	include/xtensa/config/defs.h \
	include/xtensa/config/specreg.h \
	include/xtensa/config/system.h \
	include/xtensa/config/tie-asm.h \
	include/xtensa/config/tie.h

lib_LIBRARIES = src/libhal.a

src_libhal_a_SOURCES = \
	src/attribute.c \
	src/cache.c \
	src/clock.S \
	src/coherence.c \
	src/debug.c \
	src/debug_hndlr.S \
	src/disass.c \
	src/memcopy.S \
	src/misc.c \
	src/mmu.c \
	src/mp_asm.S \
	src/syscache_asm.S \
	src/windowspill_asm.S

EXTRA_DIST = $(splittable_sources)
MOSTLYCLEANFILES = $(src_libhal_a_OBJECTS)
CLEANFILES = \
	$(split_sources) \
	$(split_makefiles)

# We split some files into chunks so the linker has really fine-grained
# linking abilities, while the code is not split up into too small chunks.
#
# Each splittable file has lines like
#
#   #[el]if defined(__SPLIT__tag)
#
# and we generate one object file per such section.

splittable_sources = \
	src/cache_asm.S \
	src/int_asm.S \
	src/interrupts.c \
	src/mem_ecc_parity.S \
	src/state_asm.S \
	src/state.c

# The name of our generated split source files.
# Used for CLEANFILES.

split_sources = $(shell cd $(top_srcdir) && $(AWK) -F '[()]' ' \
	/^\#.* defined\(__SPLIT__(\w+)\)/ { \
		sub(/__SPLIT__/, ""); \
		f = FILENAME; \
		sub(/\.[^.]+/, "--" $$2 "&", f); \
		print f; \
	}' $(splittable_sources))

# Generate one makefile per splittable source file.
# Each one contains rules to create one source file per split,
# and adds it to libhal as a dependency and to Automake's OBJECTS variable.
# (The former is needed because these includes are placed after the generated
# libhal.a rule expands *_OBJECTS for dependencies.

if XTENSA_CALL0_ABI
awk_ignore_nw := /__SPLIT__.*_nw/ && !/__SPLIT__get_intpending_nw/ { next; }
else
awk_ignore_nw :=
endif

.DELETE_ON_ERROR: %.splittmp
%-split.mk: % Makefile
	sort "$<" | uniq | $(AWK) -F '[()]' ' \
		$(awk_ignore_nw) \
		/^#.* defined\(__SPLIT__(\w+)\)/ { \
			tag = $$2; \
			sub(/__SPLIT__/, "", tag); \
			srcbase = "src/$(basename $(notdir $<))"; \
			srcsuffix = "$(suffix $<)"; \
			print srcbase "--" tag srcsuffix ": $< Makefile"; \
			print "\techo \"#define " $$2 "\" >\"$$@.splittmp\""; \
			print "\techo \"#include \\\"$<\\\"\" >>\"$$@.splittmp\""; \
			print "\tmv \"$$@.splittmp\" \"$$@\""; \
			print "src/libhal.a: " srcbase "--" tag ".$$(OBJEXT)"; \
			print "src_libhal_a_OBJECTS += " srcbase "--" tag ".$$(OBJEXT)"; \
		}' >"$@.splittmp"
	mv "$@.splittmp" "$@"

split_makefiles := $(patsubst %, %-split.mk, $(splittable_sources))

-include $(split_makefiles)
