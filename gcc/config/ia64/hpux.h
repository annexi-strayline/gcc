/* Definitions of target machine GNU compiler.  IA-64 version.
   Copyright (C) 1999-2025 Free Software Foundation, Inc.
   Contributed by Steve Ellcey <sje@cup.hp.com> and
                  Reva Cuthbertson <reva@cup.hp.com>

This file is part of GCC.

GCC is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GCC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GCC; see the file COPYING3.  If not see
<http://www.gnu.org/licenses/>.  */

/* Enable HPUX ABI quirks.  */
#undef  TARGET_HPUX
#define TARGET_HPUX 1

#undef WCHAR_TYPE
#define WCHAR_TYPE "unsigned int"

#undef WCHAR_TYPE_SIZE
#define WCHAR_TYPE_SIZE 32

/* Target OS builtins.  */
#define TARGET_OS_CPP_BUILTINS()			\
do {							\
	builtin_assert("system=hpux");			\
	builtin_assert("system=posix");			\
	builtin_assert("system=unix");			\
	builtin_define_std("hpux");			\
	builtin_define_std("unix");			\
	builtin_define("__IA64__");			\
	builtin_define("_LONGLONG");			\
	builtin_define("_INCLUDE_LONGLONG");		\
	builtin_define("__STDC_EXT__");			\
	builtin_define("_UINT128_T");			\
	if (c_dialect_cxx () || !flag_iso)		\
	  {						\
	    builtin_define("_HPUX_SOURCE");		\
	    builtin_define("__STDCPP__");		\
	    builtin_define("_INCLUDE__STDC_A1_SOURCE");	\
	  }						\
	if (TARGET_ILP32)				\
	  builtin_define("_ILP32");			\
} while (0)

#undef CPP_SPEC
#define CPP_SPEC \
  "%{mt|pthread:-D_REENTRANT -D_THREAD_SAFE -D_POSIX_C_SOURCE=199506L}"
/* aCC defines also -DRWSTD_MULTI_THREAD, -DRW_MULTI_THREAD.  These
   affect only aCC's C++ library (Rogue Wave-derived) which we do not
   use, and they violate the user's name space.  */

#undef  ASM_EXTRA_SPEC
#define ASM_EXTRA_SPEC "%{milp32:-milp32} %{mlp64:-mlp64}"

#ifndef USE_GAS
#define AS_NEEDS_DASH_FOR_PIPED_INPUT
#endif

#ifndef CROSS_DIRECTORY_STRUCTURE
#undef MD_EXEC_PREFIX
#define MD_EXEC_PREFIX "/usr/ccs/bin/"

#undef MD_STARTFILE_PREFIX
#define MD_STARTFILE_PREFIX "/usr/ccs/lib/"
#endif

#undef ENDFILE_SPEC

#undef STARTFILE_SPEC
#define STARTFILE_SPEC "%{!shared:%{static:crt0%O%s} \
			  %{mlp64:/usr/lib/hpux64/unix98%O%s} \
			  %{!mlp64:/usr/lib/hpux32/unix98%O%s}}"

#undef LINK_SPEC
#define LINK_SPEC \
  "-z +Accept TypeMismatch \
   %{shared:-b} \
   %{!shared: \
     -u main \
     %{static:-noshared}}"

#undef  LIB_SPEC
#define LIB_SPEC \
  "%{!shared: \
     %{mt|pthread:%{fopenacc|fopenmp|%:gt(%{ftree-parallelize-loops=*:%*} 1):-lrt} -lpthread} \
     %{p:%{!mlp64:-L/usr/lib/hpux32/libp} \
	 %{mlp64:-L/usr/lib/hpux64/libp} -lprof} \
     %{pg:%{!mlp64:-L/usr/lib/hpux32/libp} \
	  %{mlp64:-L/usr/lib/hpux64/libp} -lgprof} \
     %{!symbolic:-lc}}"

#define MULTILIB_DEFAULTS { "milp32" }

/* A C expression whose value is zero if pointers that need to be extended
   from being `POINTER_SIZE' bits wide to `Pmode' are sign-extended and
   greater then zero if they are zero-extended and less then zero if the
   ptr_extend instruction should be used.  */

#define POINTERS_EXTEND_UNSIGNED -1

#define JMP_BUF_SIZE  (8 * 76)

#undef TARGET_DEFAULT
#define TARGET_DEFAULT \
  (MASK_DWARF2_ASM | MASK_BIG_ENDIAN | MASK_ILP32)

/* ASM_OUTPUT_EXTERNAL_LIBCALL defaults to just a globalize_label call,
   but that doesn't put out the @function type information which causes
   shared library problems.  */

#undef ASM_OUTPUT_EXTERNAL_LIBCALL
#define ASM_OUTPUT_EXTERNAL_LIBCALL(FILE, FUN)			\
do {								\
  (*targetm.asm_out.globalize_label) (FILE, XSTR (FUN, 0));	\
  ASM_OUTPUT_TYPE_DIRECTIVE (FILE, XSTR (FUN, 0), "function");	\
} while (0)

#undef PAD_VARARGS_DOWN
#define PAD_VARARGS_DOWN (!AGGREGATE_TYPE_P (type))

#define REGISTER_TARGET_PRAGMAS() \
  c_register_pragma (0, "builtin", ia64_hpux_handle_builtin_pragma)

/* Tell ia64.cc that we are using the HP linker and we should delay output of
   function extern declarations so that we don't output them for functions
   which are never used (and may not be defined).  */

#undef TARGET_HPUX_LD
#define TARGET_HPUX_LD	1

/* The HPUX dynamic linker objects to weak symbols with no
   definitions, so do not use them in gthr-posix.h.  */
#define GTHREAD_USE_WEAK 0

#undef CTORS_SECTION_ASM_OP
#define CTORS_SECTION_ASM_OP  "\t.section\t.init_array,\t\"aw\",\"init_array\""

#undef DTORS_SECTION_ASM_OP
#define DTORS_SECTION_ASM_OP  "\t.section\t.fini_array,\t\"aw\",\"fini_array\""

/* The init_array/fini_array technique does not permit the use of
   initialization priorities.  */
#define SUPPORTS_INIT_PRIORITY 0

#undef READONLY_DATA_SECTION_ASM_OP
#define READONLY_DATA_SECTION_ASM_OP "\t.section\t.rodata,\t\"a\",\t\"progbits\""

#undef DATA_SECTION_ASM_OP
#define DATA_SECTION_ASM_OP "\t.section\t.data,\t\"aw\",\t\"progbits\""

#undef SDATA_SECTION_ASM_OP
#define SDATA_SECTION_ASM_OP "\t.section\t.sdata,\t\"asw\",\t\"progbits\""

#undef BSS_SECTION_ASM_OP
#define BSS_SECTION_ASM_OP "\t.section\t.bss,\t\"aw\",\t\"nobits\""

#undef SBSS_SECTION_ASM_OP
#define SBSS_SECTION_ASM_OP "\t.section\t.sbss,\t\"asw\",\t\"nobits\""

#undef TEXT_SECTION_ASM_OP
#define TEXT_SECTION_ASM_OP "\t.section\t.text,\t\"ax\",\t\"progbits\""

/* It is illegal to have relocations in shared segments on HPUX.
   Pretend flag_pic is always set.  */
#undef  TARGET_ASM_RELOC_RW_MASK
#define TARGET_ASM_RELOC_RW_MASK  ia64_hpux_reloc_rw_mask

/* ia64 HPUX has the float and long double forms of math functions.
   We redefine this hook so the version from elfos.h header won't be used.  */
#undef TARGET_LIBC_HAS_FUNCTION
#define TARGET_LIBC_HAS_FUNCTION default_libc_has_function

#undef TARGET_INIT_LIBFUNCS
#define TARGET_INIT_LIBFUNCS ia64_hpux_init_libfuncs

#define FLOAT_LIB_COMPARE_RETURNS_BOOL(MODE, COMPARISON) ((MODE) == TFmode)

/* HP-UX uses PROFILE_HOOK instead of FUNCTION_PROFILER but we need a
   FUNCTION_PROFILER defined because its use is not ifdefed.  When using
   PROFILE_HOOK, the profile call comes after the prologue.  */

#undef FUNCTION_PROFILER
#define FUNCTION_PROFILER(FILE, LABELNO) do { } while (0)

#undef PROFILE_HOOK
#define PROFILE_HOOK(LABEL) ia64_profile_hook (LABEL)

#undef  PROFILE_BEFORE_PROLOGUE

#undef NO_PROFILE_COUNTERS
#define NO_PROFILE_COUNTERS 0

/* The HP-UX linker has a bug that causes calls from functions in
   .text.unlikely to functions in .text to cause a segfault.  Until
   it is fixed, prevent code from being put into .text.unlikely or
   .text.hot.  */

#define TARGET_ASM_FUNCTION_SECTION ia64_hpux_function_section

#define TARGET_POSIX_IO

/* Define this to be nonzero if static stack checking is supported.  */
#define STACK_CHECK_STATIC_BUILTIN 1

/* Minimum amount of stack required to recover from an anticipated stack
   overflow detection.  */
#define STACK_CHECK_PROTECT (24 * 1024)
