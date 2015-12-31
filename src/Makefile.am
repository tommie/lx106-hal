# Copyright (c) 2014-2015 Tommie Gannert
#
# See the LICENSE file.
#

lib_LIBRARIES = libhal.a

libhal_a_SOURCES = \
	attribute.c \
	cache.c \
	clock.S \
	coherence.c \
	debug.c \
	debug_hndlr.S \
	disass.c \
	memcopy.S \
	misc.c \
	mmu.c \
	mp_asm.S \
	syscache_asm.S \
	windowspill_asm.S

EXTRA_DIST = $(splittable_sources)
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
	cache_asm.S \
	int_asm.S \
	interrupts.c \
	mem_ecc_parity.S \
	state_asm.S \
	state.c

# The name of our generated split source files.
# Used for CLEANFILES.

split_sources = $(shell cd $(top_srcdir)/src && $(AWK) -F '[()]' ' \
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
			srcbase = "$(basename $(notdir $<))"; \
			srcsuffix = "$(suffix $<)"; \
			print srcbase "--" tag srcsuffix ": $< Makefile"; \
			print "\techo \"#define " $$2 "\" >\"$$@.splittmp\""; \
			print "\techo \"#include \\\"$<\\\"\" >>\"$$@.splittmp\""; \
			print "\tmv \"$$@.splittmp\" \"$$@\""; \
			print "libhal.a: " srcbase "--" tag ".$$(OBJEXT)"; \
			print "libhal_a_OBJECTS += " srcbase "--" tag ".$$(OBJEXT)"; \
		}' >"$@.splittmp"
	mv "$@.splittmp" "$@"

split_makefiles := $(patsubst %, %-split.mk, $(splittable_sources))

-include $(split_makefiles)
