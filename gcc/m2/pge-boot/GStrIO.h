/* do not edit automatically generated by mc from StrIO.  */
/* StrIO.def Provides simple string input output routines.

Copyright (C) 2001-2025 Free Software Foundation, Inc.
Contributed by Gaius Mulley <gaius.mulley@southwales.ac.uk>.

This file is part of GNU Modula-2.

GNU Modula-2 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GNU Modula-2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

Under Section 7 of GPL version 3, you are granted additional
permissions described in the GCC Runtime Library Exception, version
3.1, as published by the Free Software Foundation.

You should have received a copy of the GNU General Public License and
a copy of the GCC Runtime Library Exception along with this program;
see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
<http://www.gnu.org/licenses/>.  */


#if !defined (_StrIO_H)
#   define _StrIO_H

#   ifdef __cplusplus
extern "C" {
#   endif
#include <stdbool.h>
#   if !defined (PROC_D)
#      define PROC_D
       typedef void (*PROC_t) (void);
       typedef struct { PROC_t proc; } PROC;
#   endif


#   if defined (_StrIO_C)
#      define EXTERN
#   else
#      define EXTERN extern
#   endif


/*
   WriteLn - writes a carriage return and a newline
             character.
*/

EXTERN void StrIO_WriteLn (void);

/*
   ReadString - reads a sequence of characters into a string.
                Line editing accepts Del, Ctrl H, Ctrl W and
                Ctrl U.
*/

EXTERN void StrIO_ReadString (char *a, unsigned int _a_high);

/*
   WriteString - writes a string to the default output.
*/

EXTERN void StrIO_WriteString (const char *a_, unsigned int _a_high);
#   ifdef __cplusplus
}
#   endif

#   undef EXTERN
#endif
