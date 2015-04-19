// 
// cache_asm.S - assembly language cache management routines
//
// $Id: //depot/rel/Boreal/Xtensa/OS/hal/cache_asm.S#2 $

// Copyright (c) 1999-2010 Tensilica Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include <xtensa/cacheasm.h>
#include <xtensa/cacheattrasm.h>


#define GBL(x)   .global x
#define TYP(x)   .type x,@function
#define ALN(x)   .align x
#define SYMT(x)  GBL(x); TYP(x); ALN(4); x:
#define SYM(x)   GBL(x); ALN(4); x:

/* For Call0 ABI, the xthal... and xthal..._nw versions are identical,
 * so we define both labels for the same function body.  The Makefile
 * does not define any of the __SPLIT__..._nw macros if Call0 ABI.
 * Use SYM() when we don't want .type information. */

#if defined (__XTENSA_CALL0_ABI__)
# define SYMBOL(x)  SYMT(x); SYMT(x ## _nw)
#else
# define SYMBOL(x)  SYMT(x)
#endif



	.text

//----------------------------------------------------------------------
// Read CACHEATTR register
//----------------------------------------------------------------------

#if defined(__SPLIT__get_cacheattr)

//  unsigned xthal_get_cacheattr(void);

SYMBOL(xthal_get_cacheattr)
SYMBOL(xthal_get_dcacheattr)
# if XCHAL_HAVE_CACHEATTR	/* single CACHEATTR register used for both I and D */
SYMBOL(xthal_get_icacheattr)
# endif
	abi_entry
	dcacheattr_get
	abi_return

#elif defined(__SPLIT__get_cacheattr_nw)

SYM(xthal_get_cacheattr_nw)
SYM(xthal_get_dcacheattr_nw)
# if XCHAL_HAVE_CACHEATTR	/* single CACHEATTR register used for both I and D */
SYM(xthal_get_icacheattr_nw)
# endif
	dcacheattr_get
	ret

#elif defined(__SPLIT__get_icacheattr)

//  unsigned xthal_get_icacheattr(void);

# if !XCHAL_HAVE_CACHEATTR	/* possibly independent CACHEATTR states used for I and D */
SYMBOL(xthal_get_icacheattr)
	abi_entry
	icacheattr_get
	abi_return
# endif

#elif defined(__SPLIT__get_icacheattr_nw)

# if !XCHAL_HAVE_CACHEATTR	/* possibly independent CACHEATTR states used for I and D */
SYM(xthal_get_icacheattr_nw)
	icacheattr_get
	ret
# endif

#endif /*split*/


//----------------------------------------------------------------------
//  Write CACHEATTR register, or equivalent.
//----------------------------------------------------------------------

/*
 *  Set CACHEATTR register in a safe manner.
 *
 *	void  xthal_set_cacheattr( unsigned new_cacheattr );
 *	void  xthal_set_icacheattr( unsigned new_cacheattr );
 *	void  xthal_set_dcacheattr( unsigned new_cacheattr );
 */

#if defined(__SPLIT__set_cacheattr)

# if XCHAL_HAVE_CACHEATTR	/* single CACHEATTR register used for both I and D accesses */
SYMBOL(xthal_set_icacheattr)
SYMBOL(xthal_set_dcacheattr)
# endif
SYMBOL(xthal_set_cacheattr)
	abi_entry
	cacheattr_set
	abi_return


#elif defined(__SPLIT__set_cacheattr_nw)

#if XCHAL_HAVE_CACHEATTR	/* single CACHEATTR register used for both Instruction and Data accesses */
SYM(xthal_set_icacheattr_nw)
SYM(xthal_set_dcacheattr_nw)
#endif
SYM(xthal_set_cacheattr_nw)
	cacheattr_set
	ret

#endif /*split*/


#if XCHAL_HAVE_CACHEATTR

	/*
	 *  Already done above.
	 *
	 *  Since we can't enable/disable the icache and dcache independently,
	 *  and don't have a nice place to store a state which would enable
	 *  us to only enable them both when both have been requested to be
	 *  enabled, we simply enable both for any request to enable either,
	 *  and disable both for any request to disable either cache.
	 */

#elif XCHAL_HAVE_MIMIC_CACHEATTR || XCHAL_HAVE_XLT_CACHEATTR

# if defined(__SPLIT__set_icacheattr)

SYMBOL(xthal_set_icacheattr)
	abi_entry
	icacheattr_set
	isync_retw_nop
	abi_return

# elif defined(__SPLIT__set_icacheattr_nw)

SYM(xthal_set_icacheattr_nw)
	icacheattr_set
	ret

# elif defined(__SPLIT__set_dcacheattr)

SYMBOL(xthal_set_dcacheattr)
	abi_entry
	dcacheattr_set
	abi_return

# elif defined(__SPLIT__set_dcacheattr_nw)

	.align	4
SYM(xthal_set_dcacheattr_nw)
	dcacheattr_set
	ret

# endif /*split*/

#else /* full MMU: */

# if defined(__SPLIT__set_idcacheattr)

//  These functions aren't applicable to arbitrary MMU configurations.
//  Do nothing in this case.

SYMBOL(xthal_set_icacheattr)
SYMBOL(xthal_set_dcacheattr)
	abi_entry
	abi_return

# elif defined(__SPLIT__set_idcacheattr_nw)

SYM(xthal_set_icacheattr_nw)
SYM(xthal_set_dcacheattr_nw)
	ret

# endif /*split*/

#endif /* cacheattr/MMU type */


//----------------------------------------------------------------------
// Determine (guess) whether caches are "enabled"
//----------------------------------------------------------------------

/*
 *  There is no "cache enable" bit in the Xtensa architecture,
 *  but we can use CACHEATTR (if it or its equivalent exists)
 *  as an indication that caches have been enabled.
 */

#if XCHAL_HAVE_CACHEATTR

# if defined(__SPLIT__idcache_is_enabled)

SYMBOL(xthal_icache_is_enabled)
SYMBOL(xthal_dcache_is_enabled)
	abi_entry
	cacheattr_is_enabled	2f
	movi	a2, 0
	abi_return
2:	movi	a2, 1
	abi_return

# elif defined(__SPLIT__idcache_is_enabled_nw)

SYM(xthal_icache_is_enabled_nw)
SYM(xthal_dcache_is_enabled_nw)
	cacheattr_is_enabled	2f
	movi	a2, 0
	ret
2:	movi	a2, 1
	ret

# endif /*split*/

#elif XCHAL_HAVE_MIMIC_CACHEATTR || XCHAL_HAVE_XLT_CACHEATTR

# if defined(__SPLIT__icache_is_enabled)

SYMBOL(xthal_icache_is_enabled)
	abi_entry
	icacheattr_is_enabled	2f
	movi	a2, 0
	abi_return
2:	movi	a2, 1
	abi_return

# elif defined(__SPLIT__icache_is_enabled_nw)

SYM(xthal_icache_is_enabled_nw)
	icacheattr_is_enabled	2f
	movi	a2, 0
	ret
2:	movi	a2, 1
	ret

# elif defined(__SPLIT__dcache_is_enabled)

SYMBOL(xthal_dcache_is_enabled)
	abi_entry
	dcacheattr_is_enabled	2f
	movi	a2, 0
	abi_return
2:	movi	a2, 1
	abi_return

# elif defined(__SPLIT__dcache_is_enabled_nw)

SYM(xthal_dcache_is_enabled_nw)
	dcacheattr_is_enabled	2f
	movi	a2, 0
	ret
2:	movi	a2, 1
	ret

# endif /*split*/

#else

//  These functions aren't applicable to arbitrary MMU configurations.
//  Assume caches are enabled in this case (!).

# if defined(__SPLIT__idcache_is_enabled)

SYMBOL(xthal_icache_is_enabled)
SYMBOL(xthal_dcache_is_enabled)
	abi_entry
	movi	a2, 1
	abi_return

# elif defined(__SPLIT__idcache_is_enabled_nw)

SYM(xthal_icache_is_enabled_nw)
SYM(xthal_dcache_is_enabled_nw)
	movi	a2, 1
	ret

# endif /*split*/

#endif



//----------------------------------------------------------------------
// invalidate the icache
//----------------------------------------------------------------------

#if defined(__SPLIT__icache_all_invalidate)

// void xthal_icache_all_invalidate(void);

SYMBOL(xthal_icache_all_invalidate)
	abi_entry
	icache_invalidate_all	a2, a3
	isync_retw_nop
	abi_return

#elif defined(__SPLIT__icache_all_invalidate_nw)

// void xthal_icache_all_invalidate_nw(void);

SYM(xthal_icache_all_invalidate_nw)
	icache_invalidate_all	a2, a3
	ret


//----------------------------------------------------------------------
// invalidate the dcache
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_all_invalidate)

// void xthal_dcache_all_invalidate(void);

SYMBOL(xthal_dcache_all_invalidate)
	abi_entry
	dcache_invalidate_all	a2, a3
	abi_return

#elif defined(__SPLIT__dcache_all_invalidate_nw)

// void xthal_dcache_all_invalidate_nw(void);

SYM(xthal_dcache_all_invalidate_nw)
	dcache_invalidate_all	a2, a3
	ret


//----------------------------------------------------------------------
// write dcache dirty data
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_all_writeback)

// void xthal_dcache_all_writeback(void);

SYMBOL(xthal_dcache_all_writeback)
	abi_entry
	dcache_writeback_all	a2, a3
	abi_return

#elif defined(__SPLIT__dcache_all_writeback_nw)

// void xthal_dcache_all_writeback_nw(void);

SYM(xthal_dcache_all_writeback_nw)
	dcache_writeback_all	a2, a3
	ret


//----------------------------------------------------------------------
// write dcache dirty data and invalidate
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_all_writeback_inv)

// void xthal_dcache_all_writeback_inv(void);

SYMBOL(xthal_dcache_all_writeback_inv)
	abi_entry
	dcache_writeback_inv_all	a2, a3
	abi_return

#elif defined(__SPLIT__dcache_all_writeback_inv_nw)

// void xthal_dcache_all_writeback_inv_nw(void);

SYM(xthal_dcache_all_writeback_inv_nw)
	dcache_writeback_inv_all	a2, a3
	ret


//----------------------------------------------------------------------
// unlock instructions from icache
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_all_unlock)

// void xthal_icache_all_unlock(void);

SYMBOL(xthal_icache_all_unlock)
	abi_entry
	icache_unlock_all	a2, a3
	abi_return

#elif defined(__SPLIT__icache_all_unlock_nw)

// void xthal_icache_all_unlock_nw(void);

SYM(xthal_icache_all_unlock_nw)
	icache_unlock_all	a2, a3
	ret


//----------------------------------------------------------------------
// unlock data from dcache
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_all_unlock)

// void xthal_dcache_all_unlock(void);

SYMBOL(xthal_dcache_all_unlock)
	abi_entry
	dcache_unlock_all	a2, a3
	abi_return

#elif defined(__SPLIT__dcache_all_unlock_nw)

// void xthal_dcache_all_unlock_nw(void);

SYM(xthal_dcache_all_unlock_nw)
	dcache_unlock_all	a2, a3
	ret


//----------------------------------------------------------------------
// invalidate the address range in the icache
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_region_invalidate)

// void xthal_icache_region_invalidate( void *addr, unsigned size );

SYMBOL(xthal_icache_region_invalidate)
	abi_entry
	icache_invalidate_region	a2, a3, a4
	isync_retw_nop
	abi_return

#elif defined(__SPLIT__icache_region_invalidate_nw)

// void xthal_icache_region_invalidate_nw( void *addr, unsigned size );

SYM(xthal_icache_region_invalidate_nw)
	icache_invalidate_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// invalidate the address range in the dcache
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_region_invalidate)

// void xthal_dcache_region_invalidate( void *addr, unsigned size );

SYMBOL(xthal_dcache_region_invalidate)
	abi_entry
	dcache_invalidate_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__dcache_region_invalidate_nw)

// void xthal_dcache_region_invalidate_nw( void *addr, unsigned size );

SYM(xthal_dcache_region_invalidate_nw)
	dcache_invalidate_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// write dcache region dirty data
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_region_writeback)

// void xthal_dcache_region_writeback( void *addr, unsigned size );

SYMBOL(xthal_dcache_region_writeback)
	abi_entry
	dcache_writeback_region		a2, a3, a4
	abi_return

#elif defined(__SPLIT__dcache_region_writeback_nw)

// void xthal_dcache_region_writeback_nw( void *addr, unsigned size );

SYM(xthal_dcache_region_writeback_nw)
	dcache_writeback_region		a2, a3, a4
	ret


//----------------------------------------------------------------------
// write dcache region dirty data and invalidate
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_region_writeback_inv)

// void xthal_dcache_region_writeback_inv( void *addr, unsigned size );

SYMBOL(xthal_dcache_region_writeback_inv)
	abi_entry
	dcache_writeback_inv_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__dcache_region_writeback_inv_nw)

// void xthal_dcache_region_writeback_inv_nw( void *addr, unsigned size );

SYM(xthal_dcache_region_writeback_inv_nw)
	dcache_writeback_inv_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// lock instructions in icache region
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_region_lock)

// void xthal_icache_region_lock(void);

SYMBOL(xthal_icache_region_lock)
	abi_entry
	icache_lock_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__icache_region_lock_nw)

// void xthal_icache_region_lock_nw(void);

SYM(xthal_icache_region_lock_nw)
	icache_lock_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// lock data in dcache region
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_region_lock)

// void xthal_dcache_region_lock(void);

SYMBOL(xthal_dcache_region_lock)
	abi_entry
	dcache_lock_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__dcache_region_lock_nw)

// void xthal_dcache_region_lock_nw(void);

SYM(xthal_dcache_region_lock_nw)
	dcache_lock_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// unlock instructions from icache region
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_region_unlock)

// void xthal_icache_region_unlock(void);

SYMBOL(xthal_icache_region_unlock)
	abi_entry
	icache_unlock_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__icache_region_unlock_nw)

// void xthal_icache_region_unlock_nw(void);

SYM(xthal_icache_region_unlock_nw)
	icache_unlock_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// unlock data from dcache region
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_region_unlock)

// void xthal_dcache_region_unlock(void);

SYMBOL(xthal_dcache_region_unlock)
	abi_entry
	dcache_unlock_region	a2, a3, a4
	abi_return

#elif defined(__SPLIT__dcache_region_unlock_nw)

// void xthal_dcache_region_unlock_nw(void);

SYM(xthal_dcache_region_unlock_nw)
	dcache_unlock_region	a2, a3, a4
	ret


//----------------------------------------------------------------------
// invalidate single icache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_line_invalidate)

// void xthal_icache_line_invalidate(void *addr);

SYMBOL(xthal_icache_line_invalidate)
	abi_entry
	icache_invalidate_line	a2, 0
	isync_retw_nop
	abi_return

#elif defined(__SPLIT__icache_line_invalidate_nw)

// void xthal_icache_line_invalidate_nw(void *addr);

SYM(xthal_icache_line_invalidate_nw)
	icache_invalidate_line	a2, 0
	ret


//----------------------------------------------------------------------
// invalidate single dcache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_line_invalidate)

// void xthal_dcache_line_invalidate(void *addr);

SYMBOL(xthal_dcache_line_invalidate)
	abi_entry
	dcache_invalidate_line	a2, 0
	abi_return

#elif defined(__SPLIT__dcache_line_invalidate_nw)

// void xthal_dcache_line_invalidate_nw(void *addr);

SYM(xthal_dcache_line_invalidate_nw)
	dcache_invalidate_line	a2, 0
	ret


//----------------------------------------------------------------------
// write single dcache line dirty data
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_line_writeback)

// void xthal_dcache_line_writeback(void *addr);

SYMBOL(xthal_dcache_line_writeback)
	abi_entry
	dcache_writeback_line	a2, 0
	abi_return

#elif defined(__SPLIT__dcache_line_writeback_nw)

// void xthal_dcache_line_writeback_nw(void *addr);

SYM(xthal_dcache_line_writeback_nw)
	dcache_writeback_line	a2, 0
	ret


//----------------------------------------------------------------------
// write single dcache line dirty data and invalidate
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_line_writeback_inv)

// void xthal_dcache_line_writeback_inv(void *addr);

SYMBOL(xthal_dcache_line_writeback_inv)
	abi_entry
	dcache_writeback_inv_line	a2, 0
	abi_return

#elif defined(__SPLIT__dcache_line_writeback_inv_nw)

// void xthal_dcache_line_writeback_inv_nw(void *addr);

SYM(xthal_dcache_line_writeback_inv_nw)
	dcache_writeback_inv_line	a2, 0
	ret


//----------------------------------------------------------------------
// lock instructions in icache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_line_lock)

// void xthal_icache_line_lock(void);

SYMBOL(xthal_icache_line_lock)
	abi_entry
	icache_lock_line	a2, 0
	abi_return

#elif defined(__SPLIT__icache_line_lock_nw)

// void xthal_icache_line_lock_nw(void);

SYM(xthal_icache_line_lock_nw)
	icache_lock_line	a2, 0
	ret


//----------------------------------------------------------------------
// lock data in dcache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_line_lock)

// void xthal_dcache_line_lock(void);

SYMBOL(xthal_dcache_line_lock)
	abi_entry
	dcache_lock_line	a2, 0
	abi_return

#elif defined(__SPLIT__dcache_line_lock_nw)

// void xthal_dcache_line_lock_nw(void);

SYM(xthal_dcache_line_lock_nw)
	dcache_lock_line	a2, 0
	ret


//----------------------------------------------------------------------
// unlock instructions from icache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_line_unlock)

// void xthal_icache_line_unlock(void);

SYMBOL(xthal_icache_line_unlock)
	abi_entry
	icache_unlock_line	a2, 0
	abi_return

#elif defined(__SPLIT__icache_line_unlock_nw)

// void xthal_icache_line_unlock_nw(void);

SYM(xthal_icache_line_unlock_nw)
	icache_unlock_line	a2, 0
	ret


//----------------------------------------------------------------------
// unlock data from dcache line
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_line_unlock)

// void xthal_dcache_line_unlock(void);

SYMBOL(xthal_dcache_line_unlock)
	abi_entry
	dcache_unlock_line	a2, 0
	abi_return

#elif defined(__SPLIT__dcache_line_unlock_nw)

// void xthal_dcache_line_unlock_nw(void);

SYM(xthal_dcache_line_unlock_nw)
	dcache_unlock_line	a2, 0
	ret


//----------------------------------------------------------------------
// sync icache and memory (???)
//----------------------------------------------------------------------

#elif defined(__SPLIT__icache_sync)

// void xthal_icache_sync(void);

SYMBOL(xthal_icache_sync)
	abi_entry
	icache_sync	a2
	isync_retw_nop
	abi_return

#elif defined(__SPLIT__icache_sync_nw)

// void xthal_icache_sync_nw(void);

SYM(xthal_icache_sync_nw)
	icache_sync	a2
	ret


//----------------------------------------------------------------------
// sync dcache and memory (???)
//----------------------------------------------------------------------

#elif defined(__SPLIT__dcache_sync)

// void xthal_dcache_sync(void);

SYMBOL(xthal_dcache_sync)
	abi_entry
	dcache_sync	a2
	abi_return

#elif defined(__SPLIT__dcache_sync_nw)

// void xthal_dcache_sync_nw(void)

SYM(xthal_dcache_sync_nw)
	dcache_sync	a2
	ret

//----------------------------------------------------------------------
// opt into and out of coherence
//----------------------------------------------------------------------

#elif defined(__SPLIT__cache_coherence_on)

// The opt-in routine assumes cache was initialized at reset,
// so it's equivalent to the low-level coherence_on routine.

// void xthal_cache_coherence_optin(void)
// void xthal_cache_coherence_on(void)

SYMBOL(xthal_cache_coherence_optin)
SYMBOL(xthal_cache_coherence_on)
	abi_entry
	cache_coherence_on	a2, a3
	abi_return
	
#elif defined(__SPLIT__cache_coherence_on_nw)

// void xthal_cache_coherence_on_nw(void)

SYM(xthal_cache_coherence_on_nw)
	cache_coherence_on	a2, a3
	ret
	
#elif defined(__SPLIT__cache_coherence_off)

// The coherence_off routines should not normally be called directly.
// Use the xthal_cache_coherence_optout() C routine instead
// (which first empties the cache).

// void xthal_cache_coherence_off

SYMBOL(xthal_cache_coherence_off)
	abi_entry
	cache_coherence_off	a2, a3
	abi_return
	
#elif defined(__SPLIT__cache_coherence_off_nw)

// void xthal_cache_coherence_on_nw

SYM(xthal_cache_coherence_off_nw)
	cache_coherence_off	a2, a3
	ret

//----------------------------------------------------------------------
// Control cache prefetch
//----------------------------------------------------------------------

#elif defined(__SPLIT__set_cache_prefetch)

// #define XTHAL_PREFETCH_ENABLE   -1
// #define XTHAL_PREFETCH_DISABLE  0

// Set cache prefetch state, and return previous one.

// int  xthal_set_cache_prefetch( int )

SYMBOL(xthal_set_cache_prefetch)
	abi_entry
# if XCHAL_HAVE_PREFETCH
	movi	a3, XCHAL_CACHE_PREFCTL_DEFAULT
	movltz	a2, a3, a2	// if a2==XTHAL_PREFETCH_ENABLE, set it to XCHAL_CACHE_PREFCTL_DEFAULT
	xsr.prefctl a2
# else
	movi	a2, 0
# endif
	abi_return
	
#elif defined(__SPLIT__set_cache_prefetch_nw)

// int  xthal_set_cache_prefetch_nw( int )

SYM(xthal_set_cache_prefetch_nw)
# if XCHAL_HAVE_PREFETCH
	movi	a3, XCHAL_CACHE_PREFCTL_DEFAULT
	movltz	a2, a3, a2	// if a2==XTHAL_PREFETCH_ENABLE, set it to XCHAL_CACHE_PREFCTL_DEFAULT
	xsr.prefctl a2
# else
	movi	a2, 0
# endif
	ret
	
#elif defined(__SPLIT__get_cache_prefetch)

// Return current cache prefetch state.

// int  xthal_get_cache_prefetch( void )

SYMBOL(xthal_get_cache_prefetch)
	abi_entry
# if XCHAL_HAVE_PREFETCH
	rsr.prefctl a2
# else
	movi	a2, 0
# endif
	abi_return
	
#elif defined(__SPLIT__get_cache_prefetch_nw)

// int  xthal_get_cache_prefetch_nw( void )

SYM(xthal_get_cache_prefetch_nw)
# if XCHAL_HAVE_PREFETCH
	rsr.prefctl a2
# else
	movi	a2, 0
# endif
	ret

//----------------------------------------------------------------------
// Misc configuration info
//----------------------------------------------------------------------
	
// Eventually these will move to their own file:
#elif defined(__SPLIT__hw_configid0)
	.set	xthals_hw_configid0, XCHAL_HW_CONFIGID0
#elif defined(__SPLIT__hw_configid1)
	.set	xthals_hw_configid1, XCHAL_HW_CONFIGID1
#elif defined(__SPLIT__release_major)
	.set	xthals_release_major, XTHAL_RELEASE_MAJOR
#elif defined(__SPLIT__release_minor)
	.set	xthals_release_minor, XTHAL_RELEASE_MINOR

#endif /*split*/

	.global	xthals_hw_configid0, xthals_hw_configid1
	.global	xthals_release_major, xthals_release_minor

//----------------------------------------------------------------------

